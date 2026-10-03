# Security & responsible use

## What this project is

Cipher is a **teaching app**. It contains no exploits, no payloads, no network
code and no attack tooling. Every "terminal" in the app is a scripted
simulation rendered in SwiftUI; every lab is a decision exercise. The app makes
no network requests at all and stores nothing but your own progress, locally, in
`UserDefaults`.

That is deliberate. You cannot attack anything with Cipher, and nothing you type
into it leaves your phone.

## Responsible use of what it teaches

Cipher teaches offensive technique because you cannot defend a system you do not
understand how to attack. The techniques themselves are real, and the law does
not care that you learned them from a teaching app.

**Practise only on:**

- machines and networks **you own**;
- a lab you built yourself (see the companion `CipherLabs` repo);
- a platform that exists for it — Hack The Box, TryHackMe, PortSwigger Web
  Security Academy, OverTheWire, SEED Labs;
- a scope you have **written, current authorization** to test.

Unauthorized access to a computer system is a crime in essentially every
jurisdiction — the Computer Fraud and Abuse Act in the US, the Computer Misuse
Act in the UK, the IT Act in India, and their equivalents elsewhere. "I was
learning" has never been a defence. The app gates first launch behind an
authorization pledge for exactly this reason.

If you are a student with no lab: build one. That is what the
**Operator's Field Manual → Build Your Own Lab** lesson is for.

## Reporting a vulnerability in the app itself

Cipher has a very small attack surface — no network, no accounts, no server, no
third-party dependencies — but it is still software.

If you find a security issue in the app (for example, a way for one app on the
device to read or tamper with another user's progress data, or a crash that
corrupts stored state), please report it privately rather than opening a public
issue:

- Open a **GitHub Security Advisory** on this repository
  (`Security` → `Report a vulnerability`), or
- open a regular issue **only** if the problem is clearly non-sensitive.

Please include the iOS/watchOS version, the device, and the steps to reproduce.
There is no bounty — this is a free educational project — but you will be
credited in the changelog unless you ask not to be.

## Reporting a content error

A **wrong technical claim is a bug in this project**, and in a teaching app it is
a more serious one than a crash: a learner who trusts a wrong explanation carries
it into real work. If a lesson, lab, animation or glossary entry is inaccurate,
misleading, or out of date, please open an issue with the lesson or lab id and
what the correct account is. Accuracy reports are the most valuable
contributions this project receives.
