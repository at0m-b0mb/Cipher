# Contributing to Cipher

Cipher is a cybersecurity course that happens to be an app. The content *is* the
product, so the most valuable contributions are **accuracy fixes** and **new
teaching material** — not refactors.

Everything here is hand-authored Swift data. There is no CMS, no JSON, no
dependencies. That is a deliberate trade: content is type-checked by the
compiler, ships offline, and can be reviewed as a diff.

---

## Before you start

```bash
brew install xcodegen          # the project file is generated, never hand-edited
xcodegen generate
open Cipher.xcodeproj
```

Two targets: `Cipher` (iOS 17+) and `Cipher Watch App` (watchOS 10+, product
name `CipherWatch`, embedded in the iOS app).

**`Shared/` compiles into both targets, so it must stay UIKit-free.** Anything
that imports UIKit or references an iOS-only API belongs in `CipheriOS/`.

Run the content checks before and after your change:

```bash
python3 scripts/validate-content.py
```

It catches the defects the compiler cannot: duplicate ids, a lab step with two
correct answers, a learning path pointing at a lesson that no longer exists, an
animation that is wired nowhere.

---

## The one gotcha that will waste your afternoon

**If you add a new `.swift` file, you must run `xcodegen generate` before
building.** The committed `Cipher.xcodeproj` uses explicit file references, not
synchronized groups, so a new file is invisible to the build until the project is
regenerated. Editing an *existing* file needs no regeneration.

If Xcode reports that your brand-new type "cannot be found in scope", this is
why, every time.

---

## Adding a lesson

Lessons live in `Shared/Content/<Track>Content.swift`. A lesson is data: an id, a
title, a difficulty, an array of `LessonBlock`s, and a quiz.

```swift
private static let myLesson = Lesson(
    id: "red-my-topic",            // stable slug — this is what progress is keyed on
    title: "Request Smuggling",
    subtitle: "One connection, two disagreeing parsers.",
    minutes: 10,
    difficulty: .advanced,
    blocks: [
        .heading("Why it works"),
        .paragraph("Front-end and back-end disagree about where a request **ends**…"),
        .keyPoints(["CL.TE and TE.CL are the two classic desync shapes.", "…"]),
        .animation(.requestSmuggling, caption: "Two parsers, one byte stream."),
        .terminal(prompt: "$", command: "…", output: "…"),
        .callout(.warning, "Smuggling can corrupt other users' requests…"),
        .definition(term: "Desync", meaning: "…"),
        .checkpoint(QuizQuestion("…", options: [...], correct: 1, why: "…")),
    ],
    quiz: [ QuizQuestion("…", options: [...], correct: 0, why: "…") ])
```

Then add it to its module's `lessons:` array. **A lesson id must never equal a
module id** — route resolution breaks and you get the wrong screen. The
validator checks this.

### Content standards

- **Be correct before you are interesting.** A confidently wrong explanation is
  worse than no lesson. If you are not sure of a tool's exact output, don't
  invent it.
- **Teach the reasoning, not the command.** "Run `-p-`" is trivia; "a fast scan
  checks 1000 of 65,535 ports, so the foothold is often on a high port" is a
  lesson.
- **Frame offence honestly and ethically.** Targets are the learner's own lab, a
  named practice platform, or an authorized scope. Never a real third party.
- **Say what the other side sees.** A red lesson that never mentions the log line
  it generates is half a lesson.
- Prose supports inline markdown: `**bold**`, `*italic*`, `` `code` ``.

---

## Adding a hands-on lab

Labs are the app's most effective teaching device. They live in
`Shared/Content/Labs<Track>.swift` and appear automatically in the **Practice →
Labs** hub — no UI wiring needed.

```swift
InteractiveLab(
    id: "lab-my-technique",        // "lab-" prefix, globally unique
    title: "Escalate via a writable service binary",
    goal: "Get root from an unprivileged shell.",
    track: .redTeam,
    difficulty: .advanced,
    minutes: 7,
    scenario: "You have a shell as `www-data` on a box you are authorized to test…",
    debrief: "The misconfiguration was not the service — it was the file mode…",
    tools: ["systemctl", "find"],
    relatedLessonID: "red-privesc-deep",   // must resolve to a real lesson, or nil
    steps: [
        LabStep(instruction: "Where do you look first?",
                hint: "Writable things that run as root.",
                options: [
                    LabOption("find / -perm -4000 2>/dev/null", correct: true,
                              output: "/usr/bin/…",
                              feedback: "SUID binaries run as their owner…"),
                    LabOption("sudo su", feedback: "You have no sudo rights yet…"),
                ])
    ])
```

Rules the validator enforces:

- **exactly one `correct: true` per step** — zero or two is a bug;
- **at least two options per step** — otherwise there is no decision;
- `relatedLessonID` must resolve to a real lesson, or be `nil`.

Rules it cannot enforce, which reviewers will:

- **Every wrong option must be plausible** — the thing a real learner would
  actually try. Never a joke option. Its `feedback` must explain *why the
  reasoning fails*; a wrong pick is a teaching moment, not a buzzer.
- **Outputs must look like the real tool's real output.** Correct flags,
  plausible versions, real CVE ids, documentation-range IPs.
- **The debrief must flip perspective** — a red lab says how a defender catches
  it; a blue lab says what the attacker wanted.
- 4–7 steps. Fewer is thin, more is a slog on a phone.

---

## Adding an animation

1. Add a case to `AnimationID` in `Shared/Models/Curriculum.swift`, plus its
   `label`.
2. Write the view in a new or existing `CipheriOS/Animations/Animations*.swift`.
   Reuse `AnimationKit` helpers (`FlowStage`, `SequenceStage`, `CycleStage`,
   `TokenChip`) — a new animation should look like it belongs.
3. In `AnimationRegistry.swift`: add the case to the `AnimationView` switch, to
   the right accent set (`redIDs` / `blueIDs` / `networkIDs`, or none for
   Fundamentals teal), and give it a `height` and a `blurb`.
4. If the file is new, `xcodegen generate`.

**You do not need to touch `AnimationGalleryView`** — it derives its groups from
`AnimationID.allCases` and the registry's track sets, so every animation appears
automatically. (It did not always; 39 animations were once invisible there.)

Animations must **play, pause, scrub and change speed** — that is the app's
signature. Build on the existing transport, don't hand-roll a timer.

---

## Adding a learning path or flashcards

- **Paths**: `Shared/Models/LearningPaths.swift`. An ordered list of existing
  lesson ids with a goal. Paths use `compactMap`, so a stale id degrades quietly
  — run the validator, which fails loudly instead.
- **Flashcards**: `Shared/Content/Flashcards.swift`. These feed the Apple Watch
  daily drill, so keep definitions to one or two sentences.

---

## Pull requests

- One topic per PR. A new module is fine; a new module plus a refactor is not.
- Confirm **both** targets build:
  ```bash
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
    -project Cipher.xcodeproj -scheme Cipher \
    -sdk iphonesimulator27.0 -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO build
  ```
  (and the `Cipher Watch App` scheme against `watchsimulator27.0`)
- Run `python3 scripts/validate-content.py` and paste the output.
- For new content, say **where you verified the technical claims**. "I know this"
  is not a source; a vendor doc, an RFC, a CVE entry or the tool's own man page
  is.
- Screenshot new UI. There are debug deep-link hooks to make that easy:
  `CIPHER_DEMO=1` seeds progress, `CIPHER_TAB=n` selects a tab,
  `CIPHER_LESSON=<id>` opens a lesson, `CIPHER_LAB=<id>` opens a lab.

  ```bash
  xcrun simctl terminate booted com.at0mb0mb.cipher   # a warm relaunch ignores new env vars
  SIMCTL_CHILD_CIPHER_LAB=lab-nmap-enum xcrun simctl launch booted com.at0mb0mb.cipher
  ```

## Reporting a content error

Open an issue with the lesson or lab id and the correction. **Accuracy reports
are the most valuable contribution this project gets** — see `SECURITY.md`.
