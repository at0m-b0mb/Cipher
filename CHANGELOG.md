# Changelog

All notable changes to Cipher are documented here.
This project follows [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-10-02

The first tagged release. Cipher has been built in the open across many content
waves; this is the point at which it became a finished, browsable course rather
than a growing pile of lessons.

### Added — hands-on labs

- **A Labs hub.** Labs existed before but were reachable only by stumbling across
  one inside a lesson. They are now a destination: a new **Practice** tab
  (Labs ⇄ Animations) with filtering by track, an "unfinished only" toggle, a
  completion ring and per-track counters.
- **44 hands-on labs**, up from 4 — across Fundamentals, Networking,
  Red Team and Blue Team. Each is a tap-to-play decision exercise: pick the
  command or the call you would actually make, with a simulated terminal that
  accumulates as you go.
- **Richer lab format.** Labs now carry a track, a difficulty, an estimated
  duration, the tools they exercise, a **briefing** that sets the scene, and a
  **debrief** that flips perspective — a red lab explains how a defender catches
  it, a blue lab explains what the attacker wanted. Every step has a **hint** for
  when you are stuck.
- **Lab progress tracking.** Finished labs are recorded, worth 75 XP each, and
  surfaced on the dashboard and profile. Existing saved progress still loads —
  the new fields are optional.
- **A labs carousel on the dashboard**, suggesting unfinished labs easiest-first.

### Fixed

- **39 of 133 animations never appeared in the Animation Gallery.** Nearly a
  third of the app's signature feature was invisible unless you happened to open
  the lesson that used it. The gallery now derives its groups from
  `AnimationID.allCases` and the animation registry's own track sets, so coverage
  is structural rather than a hand-maintained list, and the content validator
  fails if anyone un-derives it.
- **The ethics gate's primary button was unreadable while disabled** — black text
  on a dark surface. It now follows its background and reads "Accept to continue"
  until the pledge is accepted.
- The lab title no longer renders three times on one screen.

### Added — project health

- **`scripts/validate-content.py`** — catches what the Swift compiler cannot:
  duplicate ids, a module id colliding with a lesson id, a lab step with the
  wrong number of correct answers, a learning path or lab referencing a lesson
  that no longer exists, an animation wired nowhere, and an animation curated
  under the wrong track heading.
- **`scripts/generate-readme.py`** — the README's counts, curriculum tree, lab
  table and animation list are now generated from the source. They had drifted
  badly: the README advertised 3 tracks, 25 modules and 72 lessons for an app
  that shipped 4, 49 and 147, and omitted the Networking track entirely.
- **`CONTRIBUTING.md`** — how to add a lesson, lab, animation, path or flashcard,
  with the wire-up steps and the gotchas (chiefly: a new `.swift` file is
  invisible to the build until you re-run `xcodegen generate`).
- **`SECURITY.md`** — responsible-use guidance, and how to report a
  vulnerability or, just as importantly, a factual error in the content.
- **`LICENSE`** — MIT. The repository previously shipped without one.

### Changed

- The tab bar's "Animations" tab became **Practice**, with Labs and Animations as
  segments. A sixth tab would have collapsed into an iOS "More" tab, so the two
  "things you do" share one.
- Profile stats now include labs completed and saved lessons.
- The social preview card and README counts reflect the real curriculum.

---

## Earlier (untagged) development

Cipher was developed in content waves before it was versioned. In summary:

- **Foundations** — three tracks (Fundamentals, Red Team, Blue Team), the
  animation engine with play/pause/scrub/speed, quizzes, XP and the rank ladder,
  the Apple Watch flashcard companion, and the first-launch ethics pledge.
- **OffSec-aligned expansion** — web attacks, Active Directory, evasion, wireless
  and exploit development, mapped to professional curricula.
- **Modern topics** — cloud and container attacks, API/GraphQL, OAuth token
  theft, mobile, supply chain, AiTM phishing and LLM prompt injection; on the
  defensive side threat intel, vulnerability management and zero trust.
- **The Networking track** — computer networking taught properly, from what a
  network is through subnetting, DNS, routing, NAT, TCP/UDP, Wi-Fi and VPNs.
- **Deeper foundations** — number systems, character encodings, file permissions,
  boolean logic and salted hashing, so the ground floor is genuinely approachable.
- **Learning paths, interactive labs and bookmarks** — goal-oriented routes
  through the curriculum, the first four hands-on labs, and saved lessons.
