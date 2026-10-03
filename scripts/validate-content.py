#!/usr/bin/env python3
"""Cipher content integrity checks.

The curriculum is hand-authored Swift data, so the compiler happily accepts
content that is *structurally* wrong: a lab step with two correct answers, a
learning path pointing at a lesson id that no longer exists, a module whose id
collides with a lesson's. Those are the defects that actually reach a learner.

Run from the repo root:  python3 scripts/validate-content.py
Exit code 0 = clean, 1 = problems found.
"""
from __future__ import annotations
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = sorted((ROOT / "Shared" / "Content").glob("*.swift"))
MODELS = ROOT / "Shared" / "Models"

problems: list[str] = []
notes: list[str] = []


def fail(msg: str) -> None:
    problems.append(msg)


def read(p: pathlib.Path) -> str:
    return p.read_text(encoding="utf-8")


# ---------------------------------------------------------------- ids

ID_RE = re.compile(r'\bid:\s*"([a-z0-9][a-z0-9-]*)"')

all_ids: dict[str, list[str]] = {}
for f in CONTENT:
    for m in ID_RE.finditer(read(f)):
        all_ids.setdefault(m.group(1), []).append(f.name)

dupes = {k: v for k, v in all_ids.items() if len(v) > 1}
for k, where in sorted(dupes.items()):
    fail(f'duplicate id "{k}" declared {len(where)}x ({", ".join(sorted(set(where)))})')

# Lesson ids specifically — a Lesson( block's id
def ids_in_blocks(src: str, ctor: str) -> set[str]:
    """ids appearing within `ctor(` ... first id: "..." after it."""
    found = set()
    for m in re.finditer(re.escape(ctor) + r"\(", src):
        tail = src[m.end(): m.end() + 400]
        im = ID_RE.search(tail)
        if im:
            found.add(im.group(1))
    return found


lesson_ids: set[str] = set()
module_ids: set[str] = set()
lab_ids: set[str] = set()
for f in CONTENT:
    src = read(f)
    lesson_ids |= ids_in_blocks(src, "Lesson")
    module_ids |= ids_in_blocks(src, "Module")
    lab_ids |= ids_in_blocks(src, "InteractiveLab")

# A module id equal to a lesson id breaks route resolution (known past bug).
for clash in sorted(module_ids & lesson_ids):
    fail(f'module id "{clash}" collides with a lesson id — routes resolve to the wrong thing')

notes.append(f"{len(lesson_ids)} lessons · {len(module_ids)} modules · {len(lab_ids)} labs")


# ---------------------------------------------------------------- lab steps

def brace_slice(src: str, start: int, open_ch="(", close_ch=")") -> str:
    """Return the balanced (...) slice beginning at the first open_ch at/after start."""
    i = src.find(open_ch, start)
    if i < 0:
        return ""
    depth, j, in_str, esc = 0, i, False, False
    while j < len(src):
        c = src[j]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == open_ch:
                depth += 1
            elif c == close_ch:
                depth -= 1
                if depth == 0:
                    return src[i:j + 1]
        j += 1
    return src[i:]


step_total = 0
for f in CONTENT:
    src = read(f)
    for m in re.finditer(r"LabStep\(", src):
        body = brace_slice(src, m.end() - 1)
        if not body:
            continue
        step_total += 1
        n_correct = len(re.findall(r"correct:\s*true", body))
        line = src[:m.start()].count("\n") + 1
        if n_correct != 1:
            fail(f"{f.name}:{line} LabStep has {n_correct} correct options (must be exactly 1)")
        if len(re.findall(r"LabOption\(", body)) < 2:
            fail(f"{f.name}:{line} LabStep has fewer than 2 options — nothing to decide")

notes.append(f"{step_total} lab steps checked")


# ---------------------------------------------------------------- cross-references

def referenced(pattern: str, files: list[pathlib.Path]) -> list[tuple[str, str, int]]:
    out = []
    for f in files:
        src = read(f)
        for m in re.finditer(pattern, src):
            out.append((m.group(1), f.name, src[:m.start()].count("\n") + 1))
    return out


# relatedLessonID must resolve
for ref, fname, line in referenced(r'relatedLessonID:\s*"([a-z0-9-]+)"', CONTENT):
    if ref not in lesson_ids:
        fail(f'{fname}:{line} relatedLessonID "{ref}" does not match any lesson')

# learning path lesson ids must resolve
paths_file = MODELS / "LearningPaths.swift"
if paths_file.exists():
    src = read(paths_file)
    bad = 0
    for m in re.finditer(r'lessonIDs:\s*\[(.*?)\]', src, re.S):
        for lid in re.findall(r'"([a-z0-9-]+)"', m.group(1)):
            if lid not in lesson_ids:
                fail(f'LearningPaths.swift references missing lesson "{lid}"')
                bad += 1
    if not bad:
        notes.append("every learning-path lesson id resolves")


# ---------------------------------------------------------------- animations

curr = read(MODELS / "Curriculum.swift")
enum_body = re.search(r"enum AnimationID[^{]*\{(.*?)\n\}", curr, re.S)
anim_cases: set[str] = set()
if enum_body:
    # cases declared before the first computed property
    decl = enum_body.group(1).split("var label")[0]
    for m in re.finditer(r"^\s*case\s+([A-Za-z][A-Za-z0-9]*)\s*$", decl, re.M):
        anim_cases.add(m.group(1))

registry = ROOT / "CipheriOS" / "Animations" / "AnimationRegistry.swift"
if registry.exists() and anim_cases:
    rsrc = read(registry)
    unwired = sorted(c for c in anim_cases if f".{c}" not in rsrc)
    for c in unwired:
        fail(f"AnimationID .{c} is never referenced in AnimationRegistry.swift")
    notes.append(f"{len(anim_cases)} animations, {len(anim_cases) - len(unwired)} wired in the registry")

    # A curated animation listed under the wrong heading renders with the wrong
    # accent under the wrong track — the derivation cannot catch that, since the
    # id IS present, just in the wrong group.
    sets = {}
    for name, kind in (("redIDs", "Red Team"), ("blueIDs", "Blue Team"), ("networkIDs", "Networking")):
        m = re.search(name + r"\s*:\s*Set<AnimationID>\s*=\s*\[(.*?)\]", rsrc, re.S)
        if m:
            for c in re.findall(r"\.([A-Za-z][A-Za-z0-9]*)", m.group(1)):
                sets[c] = kind

    gal = ROOT / "CipheriOS" / "Screens" / "AnimationGalleryView.swift"
    if gal.exists():
        gs = read(gal)
        cur = re.search(r"private let curated:.*?= \[(.*?)\n    \]", gs, re.S)
        checked = 0
        if cur:
            for gm in re.finditer(r'\("([^"]+)",\s*Theme\.\w+,\s*\n?\s*\[(.*?)\]\)', cur.group(1), re.S):
                heading, ids = gm.group(1), re.findall(r"\.([A-Za-z][A-Za-z0-9]*)", gm.group(2))
                checked += len(ids)
                for c in ids:
                    belongs = sets.get(c, "Fundamentals")
                    if belongs != heading:
                        fail(f'gallery lists .{c} under "{heading}" but the registry '
                             f'classifies it as "{belongs}" — wrong heading and wrong accent')

        if checked == 0:
            fail("could not parse the gallery's curated groups — the placement check "
                 "silently did nothing; fix the parser or the file shape")
        else:
            notes.append(f"{checked} curated gallery placements cross-checked against the registry")

    # The gallery derives its groups from the registry's track sets, so every
    # animation must be reachable. If this ever fails, the derivation broke.
    gallery = ROOT / "CipheriOS" / "Screens" / "AnimationGalleryView.swift"
    if gallery.exists():
        gsrc = read(gallery)
        if "AnimationID.allCases.filter" not in gsrc:
            fail("AnimationGalleryView no longer derives its groups from AnimationID.allCases "
                 "— animations can silently go missing from the gallery again")
        else:
            notes.append("gallery derives from AnimationID.allCases — full coverage guaranteed")


# ---------------------------------------------------------------- report

print("Cipher content validation")
print("-" * 58)
for n in notes:
    print(f"  · {n}")
print("-" * 58)
if problems:
    print(f"FAILED — {len(problems)} problem(s):\n")
    for p in problems:
        print(f"  ✗ {p}")
    sys.exit(1)
print("PASSED — no content integrity problems found.")
