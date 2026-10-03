#!/usr/bin/env python3
"""Regenerate the data-driven sections of README.md from the curriculum source.

The README used to list the curriculum by hand. It drifted badly — it advertised
3 tracks, 25 modules and 72 lessons when the app shipped 4, 49 and 147, and the
Networking track was missing entirely. Anything countable or listable is now
generated from `Shared/` and spliced between HTML markers, so it cannot go stale
again.

    python3 scripts/generate-readme.py          # rewrite README.md in place
    python3 scripts/generate-readme.py --check  # fail if it would change anything
"""
from __future__ import annotations
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT_DIR = ROOT / "Shared" / "Content"
README = ROOT / "README.md"

TRACK_FILES = [
    ("FundamentalsContent.swift", "🟩"),
    ("NetworkingContent.swift", "🟪"),
    ("RedTeamContent.swift", "🟥"),
    ("BlueTeamContent.swift", "🟦"),
]


def balanced(src: str, start: int) -> str:
    """The balanced (...) slice beginning at the first '(' at/after `start`."""
    i = src.find("(", start)
    if i < 0:
        return ""
    depth, j, in_str, esc = 0, i, False, False
    while j < len(src):
        c = src[j]
        if in_str:
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == '"': in_str = False
        else:
            if c == '"': in_str = True
            elif c == "(": depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    return src[i:j + 1]
        j += 1
    return src[i:]


def field(body: str, name: str) -> str:
    m = re.search(name + r':\s*"((?:[^"\\]|\\.)*)"', body)
    return m.group(1).replace('\\"', '"') if m else ""


def list_field(body: str, name: str) -> list[str]:
    m = re.search(name + r":\s*\[([^\]]*)\]", body, re.S)
    if not m:
        return []
    return [x.strip() for x in m.group(1).split(",") if x.strip()]


def parse(path: pathlib.Path):
    src = path.read_text(encoding="utf-8")
    lessons, modules = {}, {}
    for m in re.finditer(r"(?:private\s+)?static\s+let\s+(\w+)\s*=\s*Lesson", src):
        body = balanced(src, m.end())
        lessons[m.group(1)] = {
            "id": field(body, "id"), "title": field(body, "title"),
            "subtitle": field(body, "subtitle"),
            "minutes": int((re.search(r"minutes:\s*(\d+)", body) or [0, 0])[1] or 0),
        }
    for m in re.finditer(r"(?:private\s+)?static\s+let\s+(\w+)\s*=\s*Module", src):
        body = balanced(src, m.end())
        modules[m.group(1)] = {
            "id": field(body, "id"), "title": field(body, "title"),
            "summary": field(body, "summary"), "lessons": list_field(body, "lessons"),
        }
    tm = re.search(r"static\s+let\s+track\s*=\s*Track", src)
    tbody = balanced(src, tm.end()) if tm else ""
    track = {"title": field(tbody, "title"), "tagline": field(tbody, "tagline"),
             "modules": list_field(tbody, "modules")}
    return track, modules, lessons


def parse_labs():
    labs = []
    for f in sorted(CONTENT_DIR.glob("*.swift")):
        src = f.read_text(encoding="utf-8")
        for m in re.finditer(r"InteractiveLab\(", src):
            body = balanced(src, m.end() - 1)
            if not body:
                continue
            tk = re.search(r"track:\s*\.(\w+)", body)
            df = re.search(r"difficulty:\s*\.(\w+)", body)
            labs.append({
                "id": field(body, "id"), "title": field(body, "title"),
                "goal": field(body, "goal"),
                "track": tk.group(1) if tk else "fundamentals",
                "difficulty": df.group(1) if df else "intermediate",
                "steps": len(re.findall(r"LabStep\(", body)),
                "minutes": int((re.search(r"minutes:\s*(\d+)", body) or [0, 0])[1] or 0),
            })
    return labs


def parse_animation_labels() -> list[str]:
    src = (ROOT / "Shared" / "Models" / "Curriculum.swift").read_text(encoding="utf-8")
    block = re.search(r"enum AnimationID.*?\n\}", src, re.S)
    if not block:
        return []
    return re.findall(r'case\s+\.(?:\w+):\s*return\s+"([^"]+)"', block.group(0))


TRACK_LABEL = {"fundamentals": "Fundamentals", "networking": "Networking",
               "redTeam": "Red Team", "blueTeam": "Blue Team"}
DIFF_LABEL = {"foundational": "Foundational", "intermediate": "Intermediate",
              "advanced": "Advanced", "expert": "Expert"}


def build():
    tracks, n_modules, n_lessons, minutes = [], 0, 0, 0
    for fname, emoji in TRACK_FILES:
        p = CONTENT_DIR / fname
        if not p.exists():
            continue
        track, modules, lessons = parse(p)
        mods = []
        for mname in track["modules"]:
            mod = modules.get(mname)
            if not mod:
                continue
            ls = [lessons[x] for x in mod["lessons"] if x in lessons]
            minutes += sum(l["minutes"] for l in ls)
            n_lessons += len(ls)
            mods.append((mod, ls))
        n_modules += len(mods)
        tracks.append((emoji, track, mods))

    labs = parse_labs()
    anims = parse_animation_labels()

    # --- stats -------------------------------------------------------------
    hours = round(minutes / 60)
    stats = (
        f"![Content](https://img.shields.io/badge/{len(tracks)}%20tracks%20%C2%B7%20"
        f"{n_modules}%20modules%20%C2%B7%20{n_lessons}%20lessons-9B8CFF?style=flat-square)\n"
        f"![Labs](https://img.shields.io/badge/{len(labs)}%20hands--on%20labs-3CE88B?style=flat-square)\n"
        f"![Animations](https://img.shields.io/badge/{len(anims)}%20animated%20explainers-2BE6C0?style=flat-square)"
    )

    summary = (
        f"| | |\n|---|---|\n"
        f"| **{len(tracks)} tracks · {n_modules} modules · {n_lessons} lessons** "
        f"| About **{hours} hours** of written material, modelled on professional curricula "
        f"(OSCP/OSWA/OSWE/OSEP/OSED/OSEE/OSWP) and extended with cloud, container, API, "
        f"mobile, AI and modern-defence topics. |\n"
        f"| **{len(labs)} hands-on labs** | Tap-to-play decision labs with a simulated terminal, "
        f"browsable in the **Practice** tab, filterable by track and difficulty. |\n"
        f"| **{len(anims)} animated explainers** | Every one plays, pauses, **scrubs** and changes speed. |\n"
    )

    # --- curriculum --------------------------------------------------------
    out = []
    for emoji, track, mods in tracks:
        out.append(f"### {emoji} {track['title']} — *{track['tagline']}*\n")
        out.append(f"<sub>{len(mods)} modules · "
                   f"{sum(len(ls) for _, ls in mods)} lessons</sub>\n")
        for mod, ls in mods:
            titles = " · ".join(l["title"] for l in ls)
            out.append(f"- **{mod['title']}** — {titles}")
        out.append("")
    curriculum = "\n".join(out).rstrip()

    # --- labs --------------------------------------------------------------
    rows = ["| Lab | Track | Level | Steps |", "|---|---|---|---|"]
    order = {"fundamentals": 0, "networking": 1, "redTeam": 2, "blueTeam": 3}
    dorder = {"foundational": 0, "intermediate": 1, "advanced": 2, "expert": 3}
    for lab in sorted(labs, key=lambda l: (order.get(l["track"], 9),
                                           dorder.get(l["difficulty"], 9), l["title"])):
        rows.append(f"| **{lab['title']}** — {lab['goal']} "
                    f"| {TRACK_LABEL.get(lab['track'], lab['track'])} "
                    f"| {DIFF_LABEL.get(lab['difficulty'], lab['difficulty'])} | {lab['steps']} |")
    labs_md = "\n".join(rows)

    # --- animations --------------------------------------------------------
    anims_md = " · ".join(f"`{a}`" for a in anims)

    return {"STATS": stats, "SUMMARY": summary, "CURRICULUM": curriculum,
            "LABS": labs_md, "ANIMATIONS": anims_md}, \
           dict(tracks=len(tracks), modules=n_modules, lessons=n_lessons,
                labs=len(labs), anims=len(anims), hours=hours)


def splice(text: str, sections: dict) -> str:
    for key, value in sections.items():
        pat = re.compile(rf"(<!-- BEGIN:{key} -->)(.*?)(<!-- END:{key} -->)", re.S)
        if not pat.search(text):
            print(f"  ! no <!-- BEGIN:{key} --> marker in README.md — skipped", file=sys.stderr)
            continue
        text = pat.sub(lambda m: f"{m.group(1)}\n{value}\n{m.group(3)}", text)
    return text


if __name__ == "__main__":
    sections, counts = build()
    print("Parsed: " + " · ".join(f"{v} {k}" for k, v in counts.items()))
    if not README.exists():
        sys.exit("README.md not found")
    before = README.read_text(encoding="utf-8")
    after = splice(before, sections)
    if "--check" in sys.argv:
        if before != after:
            sys.exit("README.md is out of date — run: python3 scripts/generate-readme.py")
        print("README.md is up to date.")
    else:
        README.write_text(after, encoding="utf-8")
        print("README.md regenerated." if before != after else "README.md already current.")
