# Cipher — Red & Blue Team Academy 🛡️⚔️

A complete, animated cybersecurity course for **iPhone** and **Apple Watch**.
Cipher teaches both sides of the craft — **red team** (the attacker's playbook,
recon → root) and **blue team** (detection, response, forensics) — through
custom SwiftUI animations, hands-on terminal walkthroughs, and quizzes. It
covers the same ground professional programs (OSCP-style offense, SOC/IR-style
defense) charge thousands for, framed throughout as **ethical, authorized**
security education.

Built entirely in **SwiftUI**, no external dependencies, fully offline. Every
complex idea is taught with a purpose-built animation.

## Screenshots

| Home | Curriculum | Animations | Lesson | Profile | Watch |
|:----:|:----------:|:----------:|:------:|:-------:|:-----:|
| <img src="Screenshots/01-home.png" width="150"> | <img src="Screenshots/02-learn.png" width="150"> | <img src="Screenshots/03-animations.png" width="150"> | <img src="Screenshots/04-lesson.png" width="150"> | <img src="Screenshots/05-profile.png" width="150"> | <img src="Screenshots/06-watch-home.png" width="150"> |

---

## What's inside

- **3 tracks · 13 modules · 27 lessons** of real, accurate content — not
  placeholders.
- **22 custom animated explainers.** TCP handshakes, port scans, SQL injection,
  Kerberoasting, buffer overflows, the cyber kill chain, MITRE ATT&CK, the
  incident-response lifecycle, and more — each one a hand-built SwiftUI
  animation, replayable on tap.
- **Simulated terminals** that type out real commands (`nmap`, `hashcat`,
  `GetUserSPNs.py`, `tcpdump`…) and reveal their output.
- **Quizzes & knowledge checks** with explanations, scored and tracked.
- **Progress system** — XP, a 7-tier hacker rank ladder (Initiate → Elite
  Operator), per-track completion, and a daily streak.
- **Apple Watch companion** — a seeded daily flashcard drill, a "term of the
  day", and your streak/rank, sharing the same curriculum engine.
- **49-term searchable glossary.**
- **Ethics first** — a first-launch authorization pledge and reminders that
  everything here is for systems you own or are authorized to test.

---

## Curriculum

### 🟩 Fundamentals — *mindset, networks & crypto*
- **Mindset & Ethics** — Hacking, Ethically (CIA triad, RoE) · How Attacks Actually Happen (the Cyber Kill Chain)
- **Networking for Hackers** — The OSI & TCP/IP Models · TCP, Ports & the 3-Way Handshake · Anatomy of a Packet
- **Cryptography Essentials** — Symmetric & Public-Key Encryption · Hashing, Salting & Leaked Passwords

### 🟥 Red Team — *think like the adversary*
- **Reconnaissance** — Passive Recon & OSINT · Active Scanning & Enumeration
- **Initial Access & Exploitation** — Phishing & Social Engineering · Exploiting Services & Getting a Shell
- **Web Application Attacks** — SQL Injection · Cross-Site Scripting (XSS)
- **Post-Exploitation** — Privilege Escalation · Password Attacks & Cracking
- **Active Directory & Lateral Movement** — Kerberoasting · Pivoting & Lateral Movement
- **Advanced Exploitation & C2** — Stack Buffer Overflows · Command & Control

### 🟦 Blue Team — *detect, respond, outlast*
- **Defensive Foundations** — Defense in Depth & the SOC · Logging, Telemetry & the SIEM
- **Detection Engineering** — MITRE ATT&CK for Defenders · Detection Engineering
- **Threat Hunting & Incident Response** — Threat Hunting · Incident Response Lifecycle
- **Forensics & Malware** — Digital Forensics Essentials · Intro to Malware Analysis

### The 22 animations
`OSI Model` · `TCP Handshake` · `Anatomy of a Packet` · `Symmetric Encryption` ·
`Public-Key Exchange` · `Hashing` · `Cyber Kill Chain` · `Port Scanning` ·
`Phishing → Initial Access` · `SQL Injection` · `Cross-Site Scripting` ·
`Privilege Escalation` · `Password Cracking` · `Kerberoasting` ·
`Lateral Movement` · `Buffer Overflow` · `C2 Beacon` · `Defense in Depth` ·
`SIEM Pipeline` · `Incident Response Lifecycle` · `MITRE ATT&CK` · `Threat Hunting`

---

## Build & run

Requires **Xcode 16+** (developed on Xcode 26.5, iOS 26.5 / watchOS 26.5 SDKs)
and **[XcodeGen](https://github.com/yonyz/XcodeGen)** to generate the project.

```bash
brew install xcodegen        # one time
cd Cipher
xcodegen generate            # builds Cipher.xcodeproj from project.yml
open Cipher.xcodeproj
```

> The `Cipher.xcodeproj` is already generated and committed, so you can skip
> straight to `open` if you don't add new files. **Re-run `xcodegen generate`
> whenever you add or remove source files** (the project lists sources
> explicitly).

### Run the iPhone app
1. Pick an **iPhone** simulator in Xcode's toolbar and press **⌘R**.
2. On first launch you'll accept the ethics pledge, then land on the dashboard.

### Run the Apple Watch app
1. Switch the scheme to **Cipher Watch App** (it's also embedded in the iPhone
   app, so installing on a paired device installs both).
2. Pick an **Apple Watch** simulator and press **⌘R**.
   - No watch simulators? Install a runtime via **Xcode ▸ Settings ▸
     Components ▸ watchOS**.

### Command-line build check
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project Cipher.xcodeproj -scheme Cipher \
  -sdk iphonesimulator26.5 -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```
Both the `Cipher` (iOS) and `Cipher Watch App` (watchOS) schemes build clean.

### Demo mode (for screenshots)
A **Debug-only** hook seeds believable progress and can deep-link a screen,
gated behind launch environment variables (compiled out of Release):
```bash
SIMCTL_CHILD_CIPHER_DEMO=1 \
SIMCTL_CHILD_CIPHER_TAB=2 \
SIMCTL_CHILD_CIPHER_LESSON=red-sqli \
xcrun simctl launch booted com.at0mb0mb.cipher
```

---

## Project layout

```
Cipher/
├─ project.yml                  # XcodeGen: two app targets + shared sources
├─ Cipher.xcodeproj
├─ Screenshots/
├─ Shared/                      # compiles into BOTH iOS + watchOS (pure SwiftUI)
│  ├─ Models/
│  │  ├─ Curriculum.swift         # Track / Module / Lesson / LessonBlock / Quiz / AnimationID
│  │  └─ Progress.swift           # ProgressStore: XP, ranks, streak (UserDefaults)
│  ├─ DesignSystem/Theme.swift    # palette, gradients, type
│  └─ Content/
│     ├─ FundamentalsContent.swift
│     ├─ RedTeamContent.swift
│     ├─ BlueTeamContent.swift
│     └─ Flashcards.swift         # glossary + watch drill deck
├─ CipheriOS/                   # iPhone app
│  ├─ CipherApp.swift             # @main, ethics gate → RootView
│  ├─ Screens/                    # Dashboard, Tracks, TrackDetail, Lesson, Quiz, Gallery, Glossary, Profile, Ethics
│  ├─ Animations/                 # the 22 explainers + reusable engines + registry
│  ├─ Components/                 # terminal, callouts, code, rings, cards
│  └─ Assets.xcassets
└─ CipherWatch/                 # Apple Watch app
   ├─ CipherWatchApp.swift
   ├─ WatchRootView.swift
   ├─ Screens/                    # DailyDrill, TermOfDay, Progress
   └─ Assets.xcassets
```

### How it's architected
- The **curriculum is data.** A `Lesson` is an ordered list of `LessonBlock`
  cases (`.heading`, `.paragraph`, `.terminal`, `.callout`, `.animation`,
  `.checkpoint`…). The lesson player just maps over them. Adding content never
  touches UI code.
- The **animation engine** is built from a few reusable stages — `FlowStage`
  (node-to-node messaging), `SequenceStage` (staged reveals), `CycleStage`
  (looping rings), `LadderStage` (privilege climb) — plus bespoke views, all
  wrapped in a common `AnimatedExplainer` chrome and resolved by
  `AnimationRegistry`.
- The **`Shared` folder is strictly cross-platform** (SwiftUI + Foundation, no
  UIKit) so the iPhone and Watch apps share the same models, content, theme and
  progress store.

### Extending it
- **Add a lesson:** append a `Lesson` to a `Module` in the relevant
  `*Content.swift`. It appears automatically in the dashboard, track detail,
  progress and search.
- **Add an animation:** add a case to `AnimationID`, build its view, and wire it
  in `AnimationRegistry`. Reference it from any lesson with
  `.animation(.yourID, caption: "…")`.

---

## A note on ethics & the law

Cipher teaches offensive techniques **so you can defend, and test with
authorization.** Practise only on systems you own or have explicit written
permission to assess — your own lab VMs, or platforms built for it like
[Hack The Box](https://www.hackthebox.com) and
[TryHackMe](https://tryhackme.com). Unauthorized access to computer systems is a
crime in nearly every country (US CFAA, UK Computer Misuse Act, and equivalents).
The skill being legal does not make the act legal — **authorization does.**

---

*Built with SwiftUI. iOS 17+ / watchOS 10+.*
