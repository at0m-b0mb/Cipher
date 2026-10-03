import Foundation

/// Standalone hands-on labs — Foundations.
/// See `Labs` in LabLibrary.swift for how these are surfaced.
///
/// These are the ground floor. Every wrong option here is a misconception a real
/// beginner holds — that `chmod 777` is a fix, that Base64 is encryption, that a
/// file extension decides a file's type, that a salt makes a hash unbreakable —
/// and each one's feedback corrects the *belief*, not just the command.
enum LabsFoundations {
    static let labs: [InteractiveLab] = [

        // MARK: 1 — Filesystem recon (foundational)

        InteractiveLab(
            id: "lab-fs-recon",
            title: "Find the misconfigured file",
            goal: "Walk a Linux box you've just landed on and find the one file whose permissions put root at risk.",
            track: .fundamentals,
            difficulty: .foundational,
            minutes: 7,
            scenario: "You built this VM yourself and you're practising on it. You have a shell as the low-privilege service account `svc-web`, no password, no documentation. Everything you learn from here, you learn by asking the filesystem questions.",
            debrief: "A permission is never dangerous on its own — it becomes dangerous when something privileged *trusts* it. A world-writable file nobody reads is a shrug; the same file read every night by a root cron job is a root shell. That pairing — who can write it, who trusts it — is the whole shape of Linux privilege escalation, and you found it with four read-only commands.\n\nFrom the defender's side this is cheap to catch: `find / -xdev -perm -0002 -type f` lists every world-writable file on a host, and a config file living in a user's home directory while a root job reads it is a design smell long before it's an exploit. The attacker is looking for exactly the thing your inventory should already know about.",
            tools: ["bash", "ls", "grep", "find"],
            relatedLessonID: "fund-linux",
            steps: [
                LabStep(
                    instruction: "You have a fresh shell. Before touching anything, establish **which identity you are acting as**.",
                    hint: "One command tells you your user, your primary group, and every supplementary group you inherit.",
                    options: [
                        LabOption("id",
                                  correct: true,
                                  output: "uid=1001(svc-web) gid=1001(svc-web) groups=1001(svc-web),4(adm)",
                                  feedback: "Start here, always. You are `svc-web` — and note the second group: `adm`. Group membership is invisible in a filename but it decides what you can read, and `adm` traditionally grants read access to `/var/log`. Your permissions are the union of your user *and* every group you're in."),
                        LabOption("ls -la",
                                  output: "total 32\ndrwxr-x--- 4 svc-web svc-web 4096 Oct  1 09:14 .\n-rw-r--r-- 1 svc-web svc-web 3771 Sep 28 11:02 .bashrc",
                                  feedback: "Not wrong, just premature — and you'll want it in a moment. A listing tells you what is *here*; it doesn't tell you who you are. A permission string like `drwxr-x---` is meaningless until you know which of those three triples applies to you."),
                        LabOption("sudo -i",
                                  output: "[sudo] password for svc-web:\nsudo: a password is required",
                                  feedback: "The beginner reflex: reach for root first. You have no password, and you don't yet know whether sudo is even configured for this account. Reaching for privilege before you've enumerated is how you learn nothing and generate a failed-auth log line at the same time.")
                    ]),
                LabStep(
                    instruction: "Now list your home directory — **everything** in it, with owners and permission bits.",
                    hint: "Two flags. One makes the listing long, the other stops dotfiles from hiding.",
                    options: [
                        LabOption("ls -la /home/svc-web",
                                  correct: true,
                                  output: "total 32\ndrwxr-x--- 4 svc-web svc-web 4096 Oct  1 09:14 .\ndrwxr-xr-x 4 root    root    4096 Sep 28 11:02 ..\n-rw-r--r-- 1 svc-web svc-web  220 Sep 28 11:02 .bash_logout\n-rw-r--r-- 1 svc-web svc-web 3771 Sep 28 11:02 .bashrc\ndrwx------ 2 svc-web svc-web 4096 Sep 28 11:40 .ssh\n-rw-rw-rw- 1 root    root     412 Oct  1 09:14 db_backup.conf",
                                  feedback: "`-l` gives you the permission and ownership columns; `-a` stops the dotfiles hiding. Both matter — without `-a` you'd never have seen `.ssh`. And read that last line twice: `db_backup.conf` is owned by **root**, sitting in **your** home directory, with mode `-rw-rw-rw-`."),
                        LabOption("ls -l /home/svc-web",
                                  output: "total 4\n-rw-rw-rw- 1 root root 412 Oct  1 09:14 db_backup.conf",
                                  feedback: "Half right — you got the permission column, which is the important half. But without `-a`, every dotfile is invisible: `.ssh`, `.bash_history`, `.config`. On Linux a leading dot is the entire hiding mechanism, and it fools nothing but plain `ls`."),
                        LabOption("ls -a /home/svc-web",
                                  output: ".  ..  .bash_logout  .bashrc  .ssh  db_backup.conf",
                                  feedback: "The other half. You can see every entry now, but you have no idea who owns them or who can write them — and permissions are the entire question you're here to answer. `-a` without `-l` is a list of names."),
                    ]),
                LabStep(
                    instruction: "`db_backup.conf` is root-owned with mode `-rw-rw-rw-`. Which part of that string is the problem?",
                    hint: "Owner, group, other. Which class of user is the one you should worry about?",
                    options: [
                        LabOption("The third triple — `rw-` for *other* means any user on this box can rewrite a root-owned file",
                                  correct: true,
                                  output: "# -rw-rw-rw-  =  666\n#  ^^^         owner  rw-   root\n#     ^^^      group  rw-   root\n#        ^^^   other  rw-   EVERY other account, including svc-web",
                                  feedback: "Correct, and this is the habit to build: when you read a mode string, go straight to the **last** triple. It's the one granted to the least-trusted class — every account on the host, every compromised service, every process that isn't root or in root's group. The owner having `rw-` is normal; `other` having `w` on a root-owned file almost never is."),
                        LabOption("Nothing — there's no `x` bit, so the file can't be executed and is harmless",
                                  output: "# -rw-rw-rw-  : no execute bit anywhere\n# the file is not a program and never runs",
                                  feedback: "A very common misreading. `x` matters for *programs*; this is a config file, and nothing will ever execute it. Its danger is that something privileged **reads** it and acts on what it says. For data, `w` is the bit that gets you owned — control the input to a root process and you control the root process."),
                        LabOption("The first triple — root having `rw-` is too much power for one account",
                                  output: "# -rw-rw-rw-\n#  ^^^  owner (root) rw-",
                                  feedback: "The owner having read and write on its own file is the baseline, not a finding — strip it and root couldn't maintain its own configuration. Permissions are only interesting where they're granted to someone who shouldn't have them, and that is almost always the `other` triple.")
                    ]),
                LabStep(
                    instruction: "A writable file only matters if something privileged reads it. Find out what consumes `db_backup.conf`.",
                    hint: "It isn't running right now. Where does a Linux box keep work that runs *later*, as root?",
                    options: [
                        LabOption("grep -r db_backup.conf /etc/cron.d /etc/crontab 2>/dev/null",
                                  correct: true,
                                  output: "/etc/cron.d/db-backup:0 2 * * * root /usr/local/sbin/dbdump.sh --config /home/svc-web/db_backup.conf",
                                  feedback: "There's the whole chain. Every night at 02:00, **root** runs a script that reads a file **you** can rewrite. That is privilege escalation — not a theoretical weakness but a scheduled one, with a time on it. This is why you always ask \"who trusts this file?\" rather than stopping at \"this file is writable\"."),
                        LabOption("ps aux | grep dbdump",
                                  output: "svc-web   2311  0.0  0.0   6300  2208 pts/0    S+   09:21   0:00 grep --color=auto dbdump",
                                  feedback: "Reasonable instinct, wrong time window — and note the only match is your own `grep` seeing itself, which is the classic confusing result. `ps` is a snapshot of *this instant*. Scheduled work is invisible to it; cron, systemd timers and at-jobs are where you look for things that run later."),
                        LabOption("find / -perm -4000 -type f 2>/dev/null",
                                  output: "/usr/bin/sudo\n/usr/bin/su\n/usr/bin/passwd\n/usr/bin/chfn\n/usr/bin/mount\n/usr/bin/pkexec",
                                  feedback: "A good habit and a sweep you'll run on every box — but look at the result: that's the stock distro set, nothing unexpected. You already have a concrete lead in hand. Starting a fresh broad sweep instead of chasing a specific finding is how enumeration turns into procrastination.")
                    ]),
                LabStep(
                    instruction: "Write the remediation for the VM's owner. What actually fixes this?",
                    hint: "The file holds a database password and a root job reads it. Who needs *read*, and who needs *write*?",
                    options: [
                        LabOption("chown root:root db_backup.conf && chmod 640 db_backup.conf && mv it out of /home",
                                  correct: true,
                                  output: "-rw-r----- 1 root root 412 Oct  1 09:14 /etc/db-backup/db_backup.conf\n# owner root rw- , group root r-- , other ---",
                                  feedback: "Three things, and all three are needed. `640` gives root write, root's group read, and everyone else **nothing** — which closes both the privesc *and* the credential leak. And the file never belonged in a user's home: a directory `svc-web` controls is a directory where `svc-web` can delete, replace or symlink the file regardless of the mode you set on it."),
                        LabOption("chmod 644 db_backup.conf",
                                  output: "-rw-r--r-- 1 root root 412 Oct  1 09:14 db_backup.conf",
                                  feedback: "You killed the privilege escalation — the world-write bit is gone, which was the urgent half. But `644` leaves the file **world-readable**, and it contains a database password. You fixed \"any user can become root\" and left \"any user can read the database credentials\". Strip the `other` triple entirely when the contents are secret."),
                        LabOption("chmod 777 db_backup.conf",
                                  output: "chmod: changing permissions of 'db_backup.conf': Operation not permitted",
                                  feedback: "Two separate problems, and the second one matters far more than the first. You don't own the file, so `chmod` fails — fine. But `777` is the **opposite** of a fix: it means read, write *and* execute for every user on the system. `chmod 777` is the most common reflex in Linux because it makes permission errors stop appearing — it does that by deleting the control that was producing them. If 777 ever looks like the answer, the real question is \"which single user or group actually needs this, and which bit?\""),
                        LabOption("mv db_backup.conf .db_backup.conf and update the cron path",
                                  output: "-rw-rw-rw- 1 root root 412 Oct  1 09:14 .db_backup.conf",
                                  feedback: "Look at the mode: it travelled with the file. A leading dot hides an entry from plain `ls` and from nothing else — `ls -a`, any glob, any script, and every attacker's first command still see it. Hiding a file is not a permission on it. Obscurity can buy time against a human skimming a directory; it buys exactly zero against the `find` command.")
                    ])
            ]),

        // MARK: 2 — Permission repair (foundational)

        InteractiveLab(
            id: "lab-permission-repair",
            title: "Repair dangerous permissions",
            goal: "Audit a web directory on your own lab VM and fix a world-writable secret, a world-writable directory and a stray SUID binary.",
            track: .fundamentals,
            difficulty: .foundational,
            minutes: 8,
            scenario: "You're hardening an internal lab web server you own before your class uses it. The person who built it fixed every permission error they hit by widening access until the error went away. You're root on the box, so every repair you choose will actually apply.",
            debrief: "Every finding here came from the same instinct: make the error stop. World-writable config, world-writable upload directory, a helper made SUID root so it would \"just work\". None of them were malicious and all three were exploitable — which is why permissions are audited rather than trusted to the person who was in a hurry.\n\nThe transferable rule is least privilege stated precisely: name the one user or group that needs access, name the one bit they need, grant that, stop. And keep the three questions separate — **who owns it** (`chown`), **what the bits say** (`chmod`), and **where it lives** (a writable directory undoes a careful file mode). Conflating ownership with permission is the single most common beginner error on Linux.",
            tools: ["ls", "stat", "chmod", "chown"],
            relatedLessonID: "fund-permissions",
            steps: [
                LabStep(
                    instruction: "Audit `/var/www/app`. You need every entry's mode bits, including inside subdirectories.",
                    hint: "You want the long format, and you want it to walk down the tree.",
                    options: [
                        LabOption("ls -lR /var/www/app",
                                  correct: true,
                                  output: """
/var/www/app:
total 28
-rw-rw-rw- 1 www-data www-data   264 Sep 30 14:02 config.php
-rw-r--r-- 1 www-data www-data  1842 Sep 30 14:02 index.php
-rwsr-xr-x 1 root     root     16608 Sep 30 14:11 logrotate-helper
drwxrwxrwx 2 www-data www-data  4096 Sep 30 14:05 uploads

/var/www/app/uploads:
total 0
""",
                                  feedback: "Three of those four entries are findings, and they're three different *kinds* of finding. `-rw-rw-rw-` on a file that holds a secret. `drwxrwxrwx` on a directory inside the web root. And an `s` where you'd expect an `x`, on a root-owned binary. Read mode strings left to right and the anomalies announce themselves."),
                        LabOption("stat /var/www/app",
                                  output: "  File: /var/www/app\n  Size: 4096       Blocks: 8          IO Block: 4096   directory\nAccess: (0755/drwxr-xr-x)  Uid: (   33/www-data)   Gid: (   33/www-data)",
                                  feedback: "`stat` is excellent for *one* path — it even prints the octal and the symbolic mode side by side, which is the fastest way to confirm you've converted correctly. But it stops at the path you gave it. You need to walk the tree, and nothing inside `/var/www/app` has been examined yet."),
                        LabOption("ls -R /var/www/app",
                                  output: "/var/www/app:\nconfig.php  index.php  logrotate-helper  uploads\n\n/var/www/app/uploads:",
                                  feedback: "You walked the tree and discarded the only data you came for. Without `-l` there are no mode bits, no owner and no group — just names. The permission string is the entire subject of a permissions audit.")
                    ]),
                LabStep(
                    instruction: "`config.php` holds the database password and is `-rw-rw-rw-`. Set it correctly.",
                    hint: "The web server runs as `www-data` and only needs to read it. Who else needs anything at all?",
                    options: [
                        LabOption("chmod 640 config.php",
                                  correct: true,
                                  output: "-rw-r----- 1 www-data www-data 264 Sep 30 14:02 config.php",
                                  feedback: "`6` owner (read + write, so the app's own user can still update it), `4` group (read), `0` other — nothing. Every other account on the host, including any service that gets compromised tomorrow, now cannot read the database password. That empty third digit is the whole point of the fix."),
                        LabOption("chmod 777 config.php",
                                  output: "-rwxrwxrwx 1 www-data www-data 264 Sep 30 14:02 config.php",
                                  feedback: "This is the single most common wrong answer in Linux, so it's worth being blunt about what it does. `777` is **maximum exposure**: every account on the host can now read the database password, rewrite the file to point at a server you control, and the pointless `x` bit invites tooling to treat a config file as a program. People reach for 777 because it makes a permission error disappear — it does, by removing the thing that was enforcing the rule. A permission error is information. The fix is to work out which one principal needs which one bit."),
                        LabOption("chmod 444 config.php",
                                  output: "-r--r--r-- 1 www-data www-data 264 Sep 30 14:02 config.php",
                                  feedback: "You removed every write bit, which is a real instinct and sometimes exactly right — but you also made the file **world-readable**, and the secret in it was the thing you were protecting. Read access *is* the leak here. You've also locked the app's own user out of ever updating its configuration. Write wasn't the dangerous bit on this file; `other` was.")
                    ]),
                LabStep(
                    instruction: "`uploads` is `drwxrwxrwx` and sits inside the web root. Fix the directory.",
                    hint: "On a directory, `w` doesn't mean \"edit the directory\" — it means something more dangerous.",
                    options: [
                        LabOption("chmod 755 uploads",
                                  correct: true,
                                  output: "drwxr-xr-x 2 www-data www-data 4096 Sep 30 14:05 uploads",
                                  feedback: "On a directory the bits shift meaning: `r` lists it, `x` traverses into it, and `w` means **create and delete entries inside**. World-writable meant any local account could plant a file in your web root — or delete the application's. `755` leaves everyone able to list and traverse, and only the owner able to write."),
                        LabOption("chown root:root uploads",
                                  output: "drwxrwxrwx 2 root root 4096 Sep 30 14:05 uploads",
                                  feedback: "Look at the mode: it did not change. You changed **who the owner is**, not **who is allowed in** — the nine bits still read `rwxrwxrwx`, so every account on the box can still write into your web root, and you've additionally broken the app's ability to manage its own upload folder. Ownership and permission are two independent questions, and running them together is the most common conceptual slip in this whole topic. `chown` answers \"whose?\"; `chmod` answers \"who may?\""),
                        LabOption("chmod 1777 uploads",
                                  output: "drwxrwxrwt 2 www-data www-data 4096 Sep 30 14:05 uploads",
                                  feedback: "You've reached for a real tool at the wrong target. The leading `1` sets the **sticky bit** (`t`), which is genuinely the right fix for a *shared* directory like `/tmp`: it stops users deleting each other's files. But it leaves the directory world-writable, so anybody can still *create* a file in your web root — and creation, not deletion, is the attack here. Sticky constrains deletion only.")
                    ]),
                LabStep(
                    instruction: "`logrotate-helper` shows `-rwsr-xr-x`, owner root. What is that `s`?",
                    hint: "It's in the owner's execute position. What happens when a non-root user runs this file?",
                    options: [
                        LabOption("The SUID bit — anyone who runs it runs as root, regardless of who they are",
                                  correct: true,
                                  output: "# -rwsr-xr-x  =  4755\n#    ^ setuid: the process takes the FILE OWNER's identity, not the caller's\n# owner is root, and group+other both have x -> any user can trigger it",
                                  feedback: "Exactly, and note the compounding problem: the `x` in the group and other triples means **everyone** can launch it, and the `s` means it runs as root when they do. That's legitimate for a handful of system tools like `passwd`, which must edit root-owned files. It is almost never legitimate for a helper script in a web directory — and if an upload could ever replace that file, you'd have handed out root."),
                        LabOption("It marks a shared library that other programs link against",
                                  output: "# file logrotate-helper\nlogrotate-helper: ELF 64-bit LSB executable, x86-64, dynamically linked",
                                  feedback: "Plausible-sounding and wrong — `s` in the owner's execute slot is **setuid**, nothing to do with linking. Shared libraries are `.so` files identified by their own ELF type (`shared object`), and their mode strings look ordinary. The ten characters of a mode string only ever describe type and permissions; they never describe what kind of program a file is."),
                        LabOption("It means \"secure\" — only root is permitted to execute it",
                                  output: "# -rwsr-xr-x\n#       ^ group x      ^ other x",
                                  feedback: "Backwards, and this inversion is worth fixing now because it recurs. Both the group and other triples carry `x`, so *every* user can execute this file; the `s` then grants them root while it runs. SUID only ever **widens** effective privilege — it has no narrowing form. If you want \"only root may run this\", that's `chmod 700` with root as owner.")
                    ]),
                LabStep(
                    instruction: "Clear the dangerous bit without breaking whatever the helper does.",
                    hint: "You want to remove one bit from one class, not rewrite the whole mode.",
                    options: [
                        LabOption("chmod u-s logrotate-helper",
                                  correct: true,
                                  output: "-rwxr-xr-x 1 root root 16608 Sep 30 14:11 logrotate-helper",
                                  feedback: "`u-s` subtracts exactly the setuid bit and touches nothing else — the file is still executable, now with the caller's own privileges. Symbolic modes (`u-s`, `g+w`, `o-rwx`) are safer than octal when you're changing one thing, because octal rewrites all nine bits and quietly reverts anything you forgot. If the helper genuinely needs root, the answer is a root-owned cron entry or a narrowly-scoped sudoers rule, not a setuid file in a web directory."),
                        LabOption("chmod 4755 logrotate-helper",
                                  output: "-rwsr-xr-x 1 root root 16608 Sep 30 14:11 logrotate-helper",
                                  feedback: "You just re-set the bit you were asked to remove. In a four-digit octal mode the leading digit *is* the special-bits triple: `4` = setuid, `2` = setgid, `1` = sticky. `4755` is a precise, deliberate way to spell the exact problem you found. Worth memorising, because you'll see `4755` in audit output and need to recognise it instantly."),
                        LabOption("rm logrotate-helper",
                                  output: "# removed 'logrotate-helper'\n# 02:00 cron run: /usr/local/sbin/rotate.sh: line 7: logrotate-helper: not found",
                                  feedback: "The bit is certainly gone, along with whatever depended on it — and you destroyed the evidence of how it got there. On a system you're hardening for someone else, deleting a binary you don't understand converts a permissions finding into an outage plus an unanswerable question. Neutralise the dangerous property, keep the artefact, then ask the owner what it was for.")
                    ])
            ]),

        // MARK: 3 — Encoding vs encryption vs hashing (foundational)

        InteractiveLab(
            id: "lab-encoding-triage",
            title: "Encoding, encryption or hash?",
            goal: "Classify four unfamiliar strings correctly, and work out which of them actually protect anything.",
            track: .fundamentals,
            difficulty: .foundational,
            minutes: 7,
            scenario: "A teammate pulls four values out of your own lab application's database and config and sends them over with one sentence: \"they're all encrypted, so we're fine.\" Your job is to classify each one and tell them which of those four words is doing real work.",
            debrief: "Three distinct operations get collapsed into the word \"encrypted\" constantly, and the distinction is not pedantry — it decides whether a leak matters.\n\n**Encoding** (Base64, hex, URL) is a change of costume. No key, fully reversible by anyone, zero confidentiality. **Hashing** is one-way: you cannot reverse it, but you can *guess* at it, so its strength is entirely a function of how predictable the input is and how slow the function is. **Encryption** is the only one of the three that depends on a secret you hold — and it's the only one whose failure mode is \"the key leaked\" rather than \"the input was guessable\".\n\nThe tell is almost always structural: a charset, a length, a prefix. `=` padding and `A–Za-z0-9+/` means Base64. Exactly 32, 40 or 64 hex characters means a fixed-size digest, which means a hash. A `$`-delimited prefix like `$2b$` or `$argon2id$` is a deliberate, self-describing format. Learn to read the shape and you stop guessing.",
            tools: ["base64", "xxd", "openssl"],
            relatedLessonID: "fund-encoding",
            steps: [
                LabStep(
                    instruction: "**String A**, from a stored session record: `YWRtaW46c3VwZXJzZWNyZXQ=`. What is it, and what do you do with it?",
                    hint: "Look at the character set and the last character before you reach for any crypto.",
                    options: [
                        LabOption("echo 'YWRtaW46c3VwZXJzZWNyZXQ=' | base64 -d",
                                  correct: true,
                                  output: "admin:supersecret",
                                  feedback: "Base64, decoded in one command with **no key involved**. Two tells gave it away before you ran anything: the charset is exactly `A–Z a–z 0–9 + /`, and it ends in `=`, which is Base64's padding for an input length that isn't a multiple of three. The credential in that session record was never protected — it was transported. Encoding is for channels that can only carry text; it is not, and has never been, a confidentiality control."),
                        LabOption("openssl enc -d -aes-256-cbc -in A.txt",
                                  output: "enter AES-256-CBC decryption password:\nbad magic number",
                                  feedback: "You assumed a key exists. It doesn't, and the string told you so — a value you can decode without any secret is by definition not encrypted. Reaching for a cipher first is how encoded secrets get filed as \"protected\" in real assessments. Guess the encoding before you theorise about crypto; it's free and it's usually right."),
                        LabOption("Treat it as a hash and look it up in a cracking database",
                                  output: "# no match: not a known digest format\n# length 24, charset includes '=' and mixed case",
                                  feedback: "A hash has a fixed length determined by its algorithm (MD5 32 hex chars, SHA-1 40, SHA-256 64) and a hex-only charset. This value is 24 characters, mixed case, with `=` padding — none of which any digest produces. Length and charset are the cheapest discriminator you have.")
                    ]),
                LabStep(
                    instruction: "**String B**, from the `users` table: `5f4dcc3b5aa765d61d8327deb882cf99`. Classify it.",
                    hint: "Count the characters. What algorithm produces exactly that many hex digits?",
                    options: [
                        LabOption("32 hex characters = 128 bits = an MD5 digest — a hash, so it can be guessed but not reversed",
                                  correct: true,
                                  output: "# length: 32   charset: 0-9a-f only\n# 32 hex digits = 128 bits = MD5\n# (SHA-1 = 40 hex digits, SHA-256 = 64)\n$ printf '%s' password | md5sum\n5f4dcc3b5aa765d61d8327deb882cf99  -",
                                  feedback: "Length is the discriminator, and it works because a hash function compresses **any** input to a **fixed** output size. That's also why reversal is off the table: countless inputs map to each digest, so there is nothing to run backwards. What *is* on the table is guessing — and this particular digest is the MD5 of `password`, one of the most published values in computing. Irreversible and trivially recovered are not contradictions."),
                        LabOption("echo '5f4dcc3b5aa765d61d8327deb882cf99' | xxd -r -p",
                                  output: "_M<CC>;Z<A7>e<D6><1D><83>'<DE><B8><82><CF><99>",
                                  feedback: "A genuinely reasonable guess — the charset *is* `0-9a-f`, so hex is the right family — but watch what came out: 16 bytes of binary garbage, not text. That's the signature of a digest rather than hex-encoded text. Hex-encoded text decodes to something readable and can be any length; a digest decodes to noise and is always exactly its algorithm's size."),
                        LabOption("echo '5f4dcc3b5aa765d61d8327deb882cf99' | base64 -d | xxd -p",
                                  output: "e5fe1d71cddbe5a6bbeb977ad5df37dbb75e6fcf3671ff7d",
                                  feedback: "It ran, and that is the trap. Every hex character is **also** a Base64 character — `0-9a-f` sits entirely inside Base64's alphabet — so the decoder cheerfully reinterprets 32 hex characters as 24 bytes of noise. Charset can never rule Base64 *out*; the only structural constraint is that the length is a multiple of 4, and 32 is. A decoder exiting 0 is not a classification. Judge the output, not the exit code.")
                    ]),
                LabStep(
                    instruction: "**String C**, from a backup script's output: `U2FsdGVkX1+p3kRm9bXoZw4tQe8KdLvN...`. Classify it.",
                    hint: "It decodes as Base64 cleanly. Look at what comes out, not at what goes in.",
                    options: [
                        LabOption("base64 -d C.b64 | xxd | head -2",
                                  correct: true,
                                  output: "00000000: 5361 6c74 6564 5f5f a9de 4466 f5b5 e867  Salted__..Df...g\n00000010: 0e2d 41ef 0a74 bbcd 4ef1 9a3b 7c20 d64a  .-A..t..N..;| .J",
                                  feedback: "This is the one that catches people, because **both** answers are true at once. It genuinely is Base64 — and what comes out is not text. The first eight bytes decode to the literal ASCII `Salted__`, OpenSSL's header, followed by an 8-byte salt and then AES ciphertext. The layers stack: encryption did the protecting, Base64 was only the envelope that let ciphertext travel through a text channel. You can strip the envelope all day; without the key you stop here."),
                        LabOption("base64 -d C.b64",
                                  output: "Salted__<A9><DE>Df<F5><B5><E8>g<0E>-A<EF>\nt<BB><CD>N<F1><9A>;| <D6>J",
                                  feedback: "The right command, read too quickly. You decoded it and got unreadable bytes — and the mistake is concluding \"the decode failed\". It succeeded perfectly; the *plaintext underneath* is ciphertext. Pipe binary through `xxd` rather than straight to your terminal and the `Salted__` header is right there in the ASCII column, telling you exactly what you're holding."),
                        LabOption("It's a hash — the output is unreadable, so it's one-way",
                                  output: "# length: 48+ characters and variable with input size\n# charset includes '+' and '/'",
                                  feedback: "Unreadable-to-a-human is not a property that distinguishes anything; ciphertext, digests and raw binary all look the same to your eyes. Two structural facts rule out a hash: the charset includes `+`, which no hex digest uses, and the length **grows with the input**, where a digest is fixed-size forever. Judge by shape, never by unreadability.")
                    ]),
                LabStep(
                    instruction: "**String D**, from a web server log: `%2e%2e%2fetc%2fpasswd`. Classify it.",
                    hint: "One character repeats in a pattern. What does it introduce?",
                    options: [
                        LabOption("URL (percent) encoding — reversible with no key, and it decodes to a path traversal",
                                  correct: true,
                                  output: "$ python3 -c \"import urllib.parse as u;print(u.unquote('%2e%2e%2fetc%2fpasswd'))\"\n../etc/passwd\n# %2e -> '.'   %2f -> '/'",
                                  feedback: "Percent-encoding: `%` followed by the byte's two hex digits. It exists so that characters with special meaning in a URL can travel as data, and like every encoding it's keyless and instant to reverse. Which is also why it's an attacker's favourite — `%2e%2e%2f` is `../` wearing a costume, and a filter that greps for the literal `../` on the raw string never sees it. Normalise first, then decide."),
                        LabOption("A hash fragment — the `%` values are part of the digest",
                                  output: "# charset includes '%', '.', '/' and letters outside a-f",
                                  feedback: "No digest format contains `%`, `.` or `/` — hex digests are strictly `0-9a-f` and Base64 digests are strictly the Base64 alphabet. A stray character outside the expected charset is usually the fastest way to eliminate a candidate format."),
                        LabOption("An encrypted parameter — the server decrypts it with a key",
                                  output: "# every %XX pair maps to one byte with no key material involved\n# %2e=46='.'  %2f=47='/'",
                                  feedback: "The mapping is a published table, not a secret: `%2e` is always `.` for everyone, everywhere. If a transformation is reversible by anyone who reads the specification, there is no key, and if there is no key, it is encoding. That test — *is a secret required?* — separates encoding from encryption every single time.")
                    ]),
                LabStep(
                    instruction: "Your teammate said all four were encrypted. Write the reply.",
                    hint: "Count how many of the four actually depend on a secret you hold.",
                    options: [
                        LabOption("Only C is encrypted. A and D are encodings — public. B is a hash, but an unsalted MD5 of a common word, so it's a lookup away.",
                                  correct: true,
                                  output: "A  YWRtaW46c3Vw...   encoding (Base64)   -> admin:supersecret   NO protection\nB  5f4dcc3b5aa7...   hash (MD5, unsalted) -> 'password'          BROKEN in practice\nC  U2FsdGVkX1+p...   encryption (AES)     -> needs the key        protected\nD  %2e%2e%2fetc...   encoding (URL)       -> ../etc/passwd        NO protection",
                                  feedback: "That's the triage, and notice the two failures are different in kind. A and D never offered protection — nothing was broken, nothing was claimed. B *attempted* protection and failed because the input was guessable and the function was fast. Only C's security rests on a secret, which means only C's risk conversation is about key management. Three different words, three different threat models; collapsing them into \"encrypted\" hides the one that matters."),
                        LabOption("They're right — all four are unreadable, so the data is protected",
                                  output: "$ echo 'YWRtaW46c3VwZXJzZWNyZXQ=' | base64 -d\nadmin:supersecret",
                                  feedback: "One command just produced a plaintext credential, so this cannot be right — but it's worth naming *why* the reasoning felt sound. \"I can't read it\" is a statement about you, not about the data. Protection is a claim that a specific adversary, with specific capability, cannot read it. An adversary with `base64 -d` defeats two of these four instantly."),
                        LabOption("None of them are safe — hashes and ciphertext are both reversible with enough CPU",
                                  output: "# AES-256 keyspace: 2^256\n# MD5 of a word in a 14-million-entry list: one lookup",
                                  feedback: "The overcorrection, and it's as unhelpful as the original error because it flattens an enormous difference. AES-256 with a properly random key is not brute-forceable with any imaginable amount of compute. MD5 of `password` falls to a single lookup. \"Everything is breakable eventually\" stops you from doing the only useful thing: ranking what to fix first.")
                    ])
            ]),

        // MARK: 4 — Peeling layered encodings (foundational)

        InteractiveLab(
            id: "lab-layered-blob",
            title: "Peel a layered blob",
            goal: "Strip three stacked encodings off a config value one layer at a time, and name each layer as you remove it.",
            track: .fundamentals,
            difficulty: .foundational,
            minutes: 7,
            scenario: "You're reviewing your own lab app before you hand it to a study group. A query-string parameter carries a long opaque value, and the developer's comment in the source says `// triple-encrypted, safe to ship`. You have the value and nothing else.",
            debrief: "Three layers, zero keys, one credential. Every transformation involved — percent, Base64, hex — is published, deterministic and reversible by anyone, so stacking them multiplies the *inconvenience* for an attacker and changes the security of the value by exactly nothing. The developer wasn't lying about the three layers; they were wrong about the word \"encrypted\".\n\nThe method is the lasting part: peel **one** layer, look at what you have, name it, repeat. Each layer announces itself if you read it — `%XX` triples mean percent-encoding, `A–Za-z0-9+/` with `=` padding means Base64, an even-length run of `0-9a-f` means hex. And know when to stop: when a decode yields bytes that aren't a recognisable format, you've reached either real ciphertext or the plaintext.\n\nThe defender's version of this is just as useful. Pipelines that decode nested layers before inspecting are how mail filters and WAFs catch payloads hidden one costume deep — and why a detection that matches only the raw string is one `%2e` away from blind.",
            tools: ["base64", "xxd", "python3"],
            relatedLessonID: "fund-encoding",
            steps: [
                LabStep(
                    instruction: "Here's the value, lifted straight from the URL:\n\n`NjQ2MjVmNzA2MTczNzMzZDUzNzU2ZTczNjU3NDIzMzIzMDMyMzY%3D`\n\nPeel the outermost layer.",
                    hint: "One short sequence in there doesn't belong to the alphabet of the layer underneath.",
                    options: [
                        LabOption("python3 -c \"import sys,urllib.parse as u;print(u.unquote(sys.argv[1]))\" 'NjQ2...MzY%3D'",
                                  correct: true,
                                  output: "NjQ2MjVmNzA2MTczNzMzZDUzNzU2ZTczNjU3NDIzMzIzMDMyMzY=",
                                  feedback: "The `%3D` was the tell: a percent followed by two hex digits, and `0x3D` is `=`. That's percent-encoding, present because `=` has reserved meaning in a query string and had to be escaped to travel there. One layer off, and the layer underneath has just revealed itself — the value now ends in `=`."),
                        LabOption("echo 'NjQ2...MzY%3D' | base64 -d",
                                  output: "base64: invalid input",
                                  feedback: "You skipped a layer and the decoder told you so. `%` is not in the Base64 alphabet, so the parser hits it and stops. This failure is useful rather than annoying: a decoder rejecting your input usually means there's an outer costume you haven't removed yet. Peel from the outside in, one at a time."),
                        LabOption("echo 'NjQ2...MzY%3D' | xxd -r -p",
                                  output: "xxd: iteration 1: unexpected char\n# aborted",
                                  feedback: "Hex decoding needs a pure `0-9a-f` input, and this string is full of upper case, lower case and `%`. Reaching for the wrong decoder is harmless and informative — but the fix is to read the charset first and let it tell you which decoder to pick, instead of trying each in turn.")
                    ]),
                LabStep(
                    instruction: "Now you have `NjQ2MjVmNzA2MTczNzMzZDUzNzU2ZTczNjU3NDIzMzIzMDMyMzY=`. Peel the next layer.",
                    hint: "Mixed case, digits, and trailing `=`. There's only one format that looks like that.",
                    options: [
                        LabOption("echo 'NjQ2MjVmNzA2MTczNzMzZDUzNzU2ZTczNjU3NDIzMzIzMDMyMzY=' | base64 -d",
                                  correct: true,
                                  output: "64625f706173733d53756e7365742332303236",
                                  feedback: "Base64, confirmed by the two things you looked at: the charset and the `=` padding. And look at the output — it did *not* decode to readable text, it decoded to another encoded string. That's the moment most people stop too early and declare the value \"encrypted\". The charset of what came out is now strictly `0-9a-f`, which names your next layer for you."),
                        LabOption("openssl enc -d -aes-256-cbc -a -in blob.b64",
                                  output: "enter AES-256-CBC decryption password:\nbad magic number",
                                  feedback: "`bad magic number` is OpenSSL saying \"after Base64-decoding this, the first bytes aren't my `Salted__` header\" — so it isn't OpenSSL ciphertext. Worth knowing as a positive test: OpenSSL's own encrypted output always carries that header, so its absence is real evidence rather than a shrug."),
                        LabOption("Base64-decode it twice in a row",
                                  output: "64625f706173733d53756e7365742332303236\n# second pass (macOS): eb8eb6e5fef4eb5e...  ·  (GNU coreutils): base64: invalid input",
                                  feedback: "The first decode worked. The second does something worse than fail: on macOS it **succeeds** and hands you 27 bytes of noise, because hex characters are all valid Base64; GNU coreutils rejects it only because 38 is not a multiple of 4. Applying the same decoder blindly is a bad habit precisely because the failure is platform-dependent — read each intermediate result and let *it* choose the next tool.")
                    ]),
                LabStep(
                    instruction: "You're holding `64625f706173733d53756e7365742332303236`. Last layer.",
                    hint: "Even length, characters only `0-9a-f`. Two characters per byte.",
                    options: [
                        LabOption("echo '64625f706173733d53756e7365742332303236' | xxd -r -p",
                                  correct: true,
                                  output: "db_pass=Sunset#2026",
                                  feedback: "Hex, decoded. `-r` reverses a dump and `-p` says the input is plain hex with no offsets or ASCII column. The tells were the charset and the even length — 38 characters, so 19 bytes. And there's the payload: a database password, shipped to every client that loads that page, wearing three costumes that cost an attacker about four seconds to remove."),
                        LabOption("echo '64625f706173733d53756e7365742332303236' | base64 -d",
                                  output: "eb8eb6e5fef4eb5ef7ef7ddde77ef9e9eef7eb9ef8db7df6df4df6",
                                  feedback: "This one is worth dwelling on, because on macOS it \"worked\" and produced garbage. Hex characters are all inside the Base64 alphabet, so the decoder accepts the input happily and reinterprets the bits under the wrong rules. (GNU `base64` would refuse this particular string — not because it spotted hex, but because 38 is not a multiple of 4. Give it 40 hex characters and it decodes the nonsense too.) A decoder that runs without error is **not** confirmation you picked the right one — only output that makes sense is."),
                        LabOption("echo '64625f706173733d53756e7365742332303236' | xxd",
                                  output: "00000000: 3634 3632 3566 3730 3631 3733 3733 3364  64625f706173733d\n00000010: 3533 3735 3665 3733 3635 3734 3233 3332  53756e7365742332\n00000020: 3330 3332 3336                           303236",
                                  feedback: "You dumped the hex *of the hex*. `xxd` without `-r` shows you the bytes of its input, and its input here was 38 ASCII characters — hence `36 34` for the characters `6` and `4`. This is the single most common `xxd` confusion: a hex **dump** is a way of displaying bytes, while hex **encoding** is a layer you decode. `-r -p` is the decoder.")
                    ]),
                LabStep(
                    instruction: "The developer's comment says `// triple-encrypted, safe to ship`. What goes in your review?",
                    hint: "How many keys did you need across those three layers?",
                    options: [
                        LabOption("Zero of the three layers is encryption — no key was involved at any step, so the password is public",
                                  correct: true,
                                  output: "layer 1  percent-encoding  reversible, published table, no key\nlayer 2  Base64            reversible, published alphabet, no key\nlayer 3  hex               reversible, published mapping, no key\n--------------------------------------------------------------\nsecret material required: none",
                                  feedback: "That's the finding, and the one-line test that produces it is **did I need a secret?** You needed none, three times. Note what the layers genuinely did accomplish: they made the value survive a URL, which is what encoding is for. The defect isn't the encoding, it's the belief that stacking it created confidentiality — and the credential sitting in client-reachable code regardless."),
                        LabOption("Three layers is reasonable defence in depth — attacking it takes real effort",
                                  output: "# time to peel all three layers, by hand: ~4 seconds\n# by script: once, then free forever",
                                  feedback: "Defence in depth means **independent** controls, so that defeating one leaves another standing. These three aren't independent and they aren't controls: each is a published, deterministic mapping, and removing one costs nothing and reveals the next. Stacking reversible transformations adds steps to a script, never resistance. One real control beats any number of costumes."),
                        LabOption("It's acceptable as long as the layer order stays secret",
                                  output: "# every layer self-identifies from its charset:\n#   '%XX'              -> percent-encoding\n#   'A-Za-z0-9+/' + '=' -> Base64\n#   even-length 0-9a-f   -> hex",
                                  feedback: "The order isn't secret — it's printed on the data. You worked it out yourself, in order, from nothing but the character sets, without being told anything. Any scheme whose only secret is its own structure fails the moment someone looks at the output, and the people most likely to look are the ones you least want succeeding. A secret has to be *separable* from the thing it protects; that's what a key is.")
                    ]),
                LabStep(
                    instruction: "Last call: what should the app actually do with that database password?",
                    hint: "Ask where the secret should *live*, not how it should be dressed.",
                    options: [
                        LabOption("Don't ship it at all — keep it server-side, read it from the environment or a secrets store at runtime",
                                  correct: true,
                                  output: "# server-side only, injected at runtime:\nDB_PASS=$(cat /run/secrets/db_pass)   # file mode 0400, root-owned\n# nothing in the URL, nothing in client-reachable source, nothing in git",
                                  feedback: "The right question was never \"how do I obscure this secret\" but \"why is this secret going to the client at all\". A database password belongs to the server; anything the browser receives is public by construction, whatever it's wrapped in. Keep it out of source control and out of responses, inject it at runtime, scope the credential so a leak is survivable, and make rotation routine."),
                        LabOption("Add a fourth layer — ROT13 the whole thing before encoding",
                                  output: "# ROT13: a published substitution, its own inverse, no key\n# layers: 4   keys: 0",
                                  feedback: "A fourth keyless transformation leaves you exactly where you started, with a longer peeling script. This is the trap the whole lab exists to close: the instinct to answer \"it's not secret enough\" with \"add another transformation\". Protection comes from a secret the attacker doesn't have, and no number of reversible steps manufactures one."),
                        LabOption("Encrypt it with AES and ship the key in the JavaScript bundle",
                                  output: "# the client needs the key to decrypt\n# the client is the attacker\n# -> key is public -> ciphertext is public",
                                  feedback: "Real encryption this time, and still broken — because of where the key had to go. If the browser must decrypt the value, the browser must hold the key, and anything the browser holds the user can read. This is a genuinely important generalisation: client-side encryption protects data *in transit to* and *at rest on* the client, never *from* the client.")
                    ])
            ]),

        // MARK: 5 — Magic bytes vs file extension (intermediate)

        InteractiveLab(
            id: "lab-magic-bytes",
            title: "The extension is lying",
            goal: "Identify a file's real type from its bytes when its name says something else, and name the upload flaw that let it in.",
            track: .fundamentals,
            difficulty: .intermediate,
            minutes: 8,
            scenario: "You're testing the upload endpoint on your own lab web app. Something called `quarterly-invoice.pdf` is sitting in the upload directory, 180 KB, and the app's only check was that the filename ends in `.pdf`. You have a shell on the box and you haven't opened the file.",
            debrief: "A filename is a label a user chose; the bytes are the only statement a file makes about itself. Nothing in any filesystem — Linux, macOS or Windows — validates that the two agree, which is why \"check the extension\" is not a security control but a naming convention.\n\nYou confirmed the real type twice over, and that's the habit worth keeping: `file` matched a signature for you, then you read the bytes yourself and found a second, independent signature (`PE\\0\\0`) exactly where the first header's offset field pointed. Agreement between independent checks is how you move from \"the tool says\" to \"I know\" — and the pointer you followed was little-endian, which is why `80 00 00 00` meant 128 and not two billion.\n\nThe defender's fix is content-based, layered and boring: validate by magic bytes against an allow-list, store uploads outside the web root under a server-generated name, serve them with a fixed non-executable content type and `Content-Disposition: attachment`, and strip execute permission on the directory. The attacker's side of this is the file-upload bypass you'll meet again in the Red Team track — and polyglot files that satisfy *two* signatures at once are the reason even magic-byte checks need an allow-list rather than a blocklist.",
            tools: ["file", "xxd", "strings"],
            relatedLessonID: "fund-number-systems",
            steps: [
                LabStep(
                    instruction: "Establish what `quarterly-invoice.pdf` actually is. Don't open it.",
                    hint: "One standard tool ignores the filename completely and reads the leading bytes instead.",
                    options: [
                        LabOption("file quarterly-invoice.pdf",
                                  correct: true,
                                  output: "quarterly-invoice.pdf: PE32+ executable (GUI) x86-64, for MS Windows",
                                  feedback: "`file` never looks at the extension. It reads the leading bytes and matches them against its *magic* database — a catalogue of known signatures. The name claims PDF; the content is a 64-bit Windows executable. That's your answer in one command, and the next step is to verify it yourself rather than take a tool's word for it."),
                        LabOption("ls -l quarterly-invoice.pdf",
                                  output: "-rw-r--r-- 1 www-data www-data 184320 Oct  1 11:42 quarterly-invoice.pdf",
                                  feedback: "Size, owner, mode, timestamp — everything except what the file *is*. This is worth stating plainly because the assumption runs deep: the extension is just the last few characters of a filename, chosen by whoever uploaded it, and no filesystem on any operating system checks it against the contents. `.pdf` is a claim, not a fact."),
                        LabOption("xdg-open quarterly-invoice.pdf",
                                  output: "# the desktop hands the file to the handler registered for '.pdf'\n# (this is the one step you don't take on an unidentified file)",
                                  feedback: "This is the move the renamer is counting on. Opening a file routes it to whichever application the *extension* is registered to, which means you've let the untrusted part of the filename decide which parser receives untrusted bytes. Identify first, always, with a tool that only reads. Never execute or open something to find out what it is."),
                    ]),
                LabStep(
                    instruction: "`file` says PE32+. Verify it from the raw bytes yourself.",
                    hint: "You want the first bytes, in order, with their offsets.",
                    options: [
                        LabOption("xxd quarterly-invoice.pdf | head -8",
                                  correct: true,
                                  output: """
00000000: 4d5a 9000 0300 0000 0400 0000 ffff 0000  MZ..............
00000010: b800 0000 0000 0000 4000 0000 0000 0000  ........@.......
00000020: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000030: 0000 0000 0000 0000 0000 0000 8000 0000  ................
00000040: 0e1f ba0e 00b4 09cd 21b8 014c cd21 5468  ........!..L.!Th
00000050: 6973 2070 726f 6772 616d 2063 616e 6e6f  is program canno
00000060: 7420 6265 2072 756e 2069 6e20 444f 5320  t be run in DOS
00000070: 6d6f 6465 2e0d 0d0a 2400 0000 0000 0000  mode....$.......
""",
                                  feedback: "Three columns: byte offset, the bytes in hex, and their printable ASCII. Everything you need is visible. The file opens `4d 5a`. At offset `0x3c` sits `80 00 00 00`. And from `0x4e` onward there's a human-readable string that no PDF would ever contain. A hex dump is the ground truth for file identification — it shows you what's there with no interpretation in the way."),
                        LabOption("strings quarterly-invoice.pdf | head -6",
                                  output: "!This program cannot be run in DOS mode.\n.text\n.rdata\n.data\n.reloc\nKERNEL32.dll",
                                  feedback: "Genuinely useful and strongly suggestive — PE section names and a `KERNEL32.dll` import are not things that appear in invoices. But `strings` discards every byte that isn't printable and throws away all the offsets, so you cannot tell *where* anything sits. For identification you need position: signatures are defined by both their value and their offset."),
                        LabOption("cat quarterly-invoice.pdf",
                                  output: "MZ<90>^@^C^@^@^@^D^@^@^@<FF><FF>^@^@<B8>^@^@^@...!..L.!This program cannot be run in DOS mode.$...",
                                  feedback: "You can just about read `MZ` before it degenerates, and that's the best case. `cat` writes raw bytes straight to your terminal, where any escape sequence in the file is interpreted as a terminal command — a corrupted display at best, and a known trick for abusing terminal emulators at worst. `xxd` and `hexdump` render bytes as text, which is exactly why they exist.")
                    ]),
                LabStep(
                    instruction: "The first two bytes are `4d 5a`. What are you looking at?",
                    hint: "Check the ASCII column of the dump for those two bytes.",
                    options: [
                        LabOption("ASCII `MZ` — the DOS/Windows executable signature",
                                  correct: true,
                                  output: "# 0x4d = 'M'   0x5a = 'Z'\n# every Windows .exe/.dll/.sys still begins with these two bytes\n# a PDF would begin:  25 50 44 46 2d   ->  '%PDF-'",
                                  feedback: "`MZ` are the initials of Mark Zbikowski, an MS-DOS architect, and every Windows executable has carried them at offset 0 since 1983 for backwards compatibility. Compare what a PDF must begin with: `25 50 44 46 2d`, the ASCII `%PDF-`. The first few bytes are the only honest statement this file makes about its type, and they say Windows binary."),
                        LabOption("Part of the PDF header, just shifted a few bytes along",
                                  output: "$ grep -c '%PDF-' quarterly-invoice.pdf\n0",
                                  feedback: "Worth testing rather than assuming, and the test comes back empty — `%PDF-` appears nowhere in the file, at any offset. The reasoning is tempting because some readers *do* tolerate junk before the header, so \"maybe it's further in\" feels safe. But notice what it's doing: talking you out of a positive match (`4d 5a` is a signature for something specific) on the strength of a hypothetical. Trust the match you have over the one you're hoping for."),
                        LabOption("Hex-encoded data — decode `4d 5a` to get the real content",
                                  output: "# 4d 5a IS the file's first two bytes, shown in hex by xxd\n# there is no encoding layer to remove",
                                  feedback: "This is the confusion worth untangling. A hex **dump** is a *display format*: `xxd` shows you each byte as two hex digits so you can read them. Hex **encoding** is a *layer in the data*, where the file's actual bytes are the ASCII characters `'4'`, `'d'`, `'5'`, `'a'`. Here the bytes are `0x4d 0x5a` and the dump is just how they're printed. Nothing to decode — something to recognise.")
                    ]),
                LabStep(
                    instruction: "Offset `0x3c` holds `80 00 00 00`. In a PE file that field points at the real PE header. Go read it.",
                    hint: "x86 is little-endian. Which byte of `80 00 00 00` is the least significant?",
                    options: [
                        LabOption("xxd -s 0x80 -l 16 quarterly-invoice.pdf",
                                  correct: true,
                                  output: "00000080: 5045 0000 6486 0600 1ab2 fd68 0000 0000  PE..d......h....",
                                  feedback: "`80 00 00 00` read little-endian is `0x00000080` = 128, so you seek there — and find `50 45 00 00`, the ASCII `PE\\0\\0`. That's a second, independent signature, located by following a pointer from the first. The two bytes after it, `64 86`, are little-endian `0x8664`: the machine type for x86-64, which is precisely what `file` reported. Three facts now agree, which is what certainty looks like."),
                        LabOption("xxd -s 0x3c -l 16 quarterly-invoice.pdf",
                                  output: "0000003c: 8000 0000 0e1f ba0e 00b4 09cd 21b8 014c  ............!..L",
                                  feedback: "You re-read the pointer instead of following it. The four bytes at `0x3c` are an **address** — the DOS header's `e_lfanew` field — not the header itself. Dereferencing is the step: read the value, then seek to the offset the value names. Confusing a pointer with its target is a mistake that scales all the way up to exploitation work."),
                        LabOption("Read `80 00 00 00` as big-endian and seek to offset 0x80000000",
                                  output: "# xxd -s 0x80000000 -l 16 quarterly-invoice.pdf\n# (no output — the seek is past the end of a 184320-byte file)",
                                  feedback: "The endianness trap, and everybody falls in once. x86 and x86-64 are **little-endian**: the least-significant byte is stored first, so `80 00 00 00` is `0x00000080` (128), not `0x80000000` (over two billion). The rule of thumb that saves you: when a multi-byte value in a dump looks absurdly large or absurdly small, reverse the bytes before you suspect corruption. Network protocols are big-endian, your CPU almost certainly isn't, and that mismatch is a lifelong source of confusion.")
                    ]),
                LabStep(
                    instruction: "Write the finding. What is the actual defect in your lab app?",
                    hint: "The file got in. Which check did it pass, and what did that check actually measure?",
                    options: [
                        LabOption("The upload validates the filename's extension, not the file's content — so renaming anything to `.pdf` gets it in",
                                  correct: true,
                                  output: "# accepted because:   name.endswith('.pdf')  ->  True\n# content:            PE32+ executable, x86-64\n# the check measured a string the uploader chose",
                                  feedback: "That's the defect stated at the right level: the validation examines a value the attacker supplies. Fix it at the content layer — read the leading bytes and match against an allow-list of permitted types, store uploads outside the web root under a server-generated name, serve them with a fixed non-executable content type and `Content-Disposition: attachment`, and cap the size. Allow-list rather than blocklist, because you can enumerate what you accept and never what you don't."),
                        LabOption("The file is malware — add its hash to the blocklist and move on",
                                  output: "# sha256 added to blocklist\n# flip one byte of the payload -> new hash -> accepted again",
                                  feedback: "You've fixed exactly one file. Hash blocklisting is a real control with a real place, but it is inherently retrospective: it recognises samples it has already seen, and a single changed byte produces a hash it hasn't. Meanwhile the hole you were asked about — validation that trusts the uploader's filename — is still open and will accept the next renamed binary just as happily. Fix the logic, not the instance."),
                        LabOption("Nothing serious — it's a Windows binary and the server runs Linux, so it can't execute",
                                  output: "# GET /uploads/quarterly-invoice.pdf  ->  200 OK\n# Content-Type: application/pdf\n# served to any client that asks",
                                  feedback: "The server isn't the target; it's the delivery mechanism. That file now sits at a URL on a host your study group trusts, labelled as a PDF, ready to be downloaded by someone on Windows — which is a far better phishing position than an attacker's own domain. And the structural point stands regardless of operating system: a filter you defeat by renaming a file is not a filter, and the next upload might be a `.php` that the web server is perfectly willing to execute.")
                    ])
            ]),

        // MARK: 6 — Cracking an unsalted hash, then meeting a salt (intermediate)

        InteractiveLab(
            id: "lab-hash-crack-salt",
            title: "Crack a hash, then meet a salt",
            goal: "Recover passwords from an unsalted MD5 dump, then work out precisely what a salt takes away from you.",
            track: .fundamentals,
            difficulty: .intermediate,
            minutes: 9,
            scenario: "You've dumped the `users` table from a deliberately-weak app you built for practice on your own machine. Three rows, three password hashes, no salt column. Your own lab, your own data — and afterwards you'll patch it and attack it again.",
            debrief: "Nothing here was reversed. Hashes are one-way and stayed one-way; what cracked them was *guessing* — hashing millions of candidates and comparing. That reframe matters, because it tells you what actually governs whether a hash survives a leak: how predictable the input is, and how expensive one guess is.\n\nA salt attacks neither of those. It attacks **amortisation**. Unsalted, one pass over a wordlist tests every user at once and a precomputed table tests them for free; salted, every user costs a separate pass and precomputation is impossible because the attacker can't know the salt in advance. The salt is stored in plaintext beside the hash and was never meant to be secret. What makes a single guess expensive is a *slow* hash — bcrypt, scrypt, Argon2 — and you need both: the salt so the work doesn't amortise, the slow function so the work hurts.\n\nFrom the defender's seat, the dump itself is the detection opportunity. An application account issuing a full-table `SELECT` on a credentials table is a rare, high-signal event: alert on it, keep a honey-user row whose hash nobody should ever crack, and rate-limit. By the time cracking starts, the attacker is offline and you have no further say.",
            tools: ["hashcat", "md5sum", "rockyou.txt"],
            relatedLessonID: "fund-hashing",
            steps: [
                LabStep(
                    instruction: "Here is `hashes.txt` — four users:\n\n`5f4dcc3b5aa765d61d8327deb882cf99`\n`5f4dcc3b5aa765d61d8327deb882cf99`\n`0d107d09f5bbe40cade3de5c71e9e9b7`\n`f9c1faceed16494614ed3f3a56dcb2fb`\n\nBefore you crack anything — what does the dump already tell you?",
                    hint: "Compare the values to each other before you compare them to a wordlist.",
                    options: [
                        LabOption("sort hashes.txt | uniq -c | sort -rn",
                                  correct: true,
                                  output: "   2 5f4dcc3b5aa765d61d8327deb882cf99\n   1 f9c1faceed16494614ed3f3a56dcb2fb\n   1 0d107d09f5bbe40cade3de5c71e9e9b7",
                                  feedback: "Two users share a hash, so they share a password — and you learned that **without cracking anything**. Identical inputs producing identical outputs is exactly what a hash function is for; the problem is that a credentials table should never expose it. That duplicate is the fingerprint of a missing salt, and in a real dump the most-repeated hash is also your best first cracking target, because it unlocks the most accounts per guess."),
                        LabOption("awk '{print length($0)}' hashes.txt | sort -u",
                                  output: "32",
                                  feedback: "A fact you'll need in about thirty seconds — 32 hex characters is 128 bits, which is MD5 (SHA-1 is 40, SHA-256 is 64). But it's a fact about the *format*, and you were asked what the dump tells you about the *data*. Look at the values in relation to each other first; it's free and here it's the bigger finding."),
                        LabOption("cat hashes.txt | base64 -d | xxd -p | head -1",
                                  output: "e5fe1d71cddbe5a6bbeb977ad5df37dbb75e6fcf3671ff7d",
                                  feedback: "The wrong mental model, and note that it did not even have the courtesy to fail — hex characters are all valid Base64, so the decoder happily turned your digests into noise. That is the useful thing to catch early: these values aren't *encoded*, so there is nothing to decode, and a digest has no inverse to compute regardless. Reversal is permanently off the table. Guessing is the only move, and that reframe is what the rest of this lab is about.")
                    ]),
                LabStep(
                    instruction: "Crack them. MD5, straight dictionary attack, `rockyou.txt`.",
                    hint: "Two flags matter: the hash mode and the attack mode.",
                    options: [
                        LabOption("hashcat -m 0 -a 0 hashes.txt rockyou.txt",
                                  correct: true,
                                  output: "5f4dcc3b5aa765d61d8327deb882cf99:password\n0d107d09f5bbe40cade3de5c71e9e9b7:letmein\n\nSession..........: hashcat\nStatus...........: Exhausted\nHash.Mode........: 0 (MD5)\nRecovered........: 2/3 (66.66%) Digests",
                                  feedback: "`-m 0` selects MD5 and `-a 0` is a straight wordlist attack. Note the status: `Exhausted`, not `Cracked` — two of the three distinct digests fell and one survived the entire wordlist. Be precise about what happened: hashcat did not reverse anything. It hashed every line of the wordlist and compared the results to your digests. Both passwords were in a list of roughly fourteen million human-chosen passwords that has been public since 2009 — so the \"irreversible\" protection was defeated by the input being predictable, not by the function being broken."),
                        LabOption("hashcat -m 1000 -a 0 hashes.txt rockyou.txt",
                                  output: "Session..........: hashcat\nStatus...........: Exhausted\nHash.Mode........: 1000 (NTLM)\nRecovered........: 0/3 (0.00%) Digests",
                                  feedback: "An excellent trap to fall into once. `-m 1000` is NTLM, which is *also* a 32-hex-digit digest — so hashcat accepts your file without complaint, runs the entire wordlist, and recovers nothing. Same length, different algorithm. Note the lesson in the status line: `Exhausted` means \"I tried everything and found nothing\", which is very different from an error. A clean run is not evidence that you configured it correctly."),
                        LabOption("hashcat -m 0 -a 3 hashes.txt '?a?a?a?a?a?a?a?a'",
                                  output: "Session..........: hashcat\nStatus...........: Running\nGuess.Mask.......: ?a?a?a?a?a?a?a?a [8]\nProgress.........: 1398784/6634204312890625 (0.00%)",
                                  feedback: "`-a 3` is a brute-force mask attack, and `?a` is all 95 printable ASCII characters — so eight positions is 95⁸, about 6.6 quadrillion candidates. It would eventually find both of these, and it's still the wrong first move: real passwords come from human habits, not from a uniform distribution over the keyspace. Attack the distribution. A wordlist finishes in under a second where a mask grinds for days, and no mask of practical length reaches a long passphrase anyway.")
                    ]),
                LabStep(
                    instruction: "You patch the app to store `sha256(password + salt)` with a unique random salt per user. Re-dump: Alice and Bob still both use `password`, but their hashes now differ. Which of your techniques survives?",
                    hint: "The salt is stored in the table next to the hash. What did it actually cost you?",
                    options: [
                        LabOption("Wordlists still work, but one user at a time — you must re-hash the whole list with that user's salt",
                                  correct: true,
                                  output: "alice  salt=9f2c1a7b  sha256('password'+salt) = c2a17f688ce6495ab8feb57571fbe082c81ff6babb5c0aa9ae800f2930fb18f0\nbob    salt=4e81d035  sha256('password'+salt) = 3c1428c3eab99dfad90910fbcbf712df39739a069466642bc66fb42fcff8c592\n# same password, different digests -> the duplicate is gone\n# one wordlist pass no longer covers both users",
                                  feedback: "This is the precise answer and it's narrower than people expect. A salt does not stop guessing — it stops **amortising**. Unsalted, one pass over the wordlist tested every row simultaneously and a rainbow table tested them for free. Salted, your work multiplies by the number of users, and precomputation dies because you can't know the salt before you see the dump. That's the salt's entire job, and it's a big one: it turns \"cracked the table overnight\" into \"cracked the weakest accounts, slowly\"."),
                        LabOption("Neither — salting makes the hashes unbreakable",
                                  output: "$ printf '%s' 'password9f2c1a7b' | sha256sum\nc2a17f688ce6495ab8feb57571fbe082c81ff6babb5c0aa9ae800f2930fb18f0  -\n# matches alice. one guess, using the salt from her own row.",
                                  feedback: "The overcorrection, and it's a dangerous one because it stops people adding the control that *does* raise the cost. The salt sits in plaintext in the same table as the hash — it was never a secret and isn't meant to be one. Hand an attacker the salt and `password` is still one guess away, as that command shows. Salt kills precomputation and cross-user reuse. It does nothing about a weak password or a fast hash."),
                        LabOption("Only the duplicate-detection trick still works",
                                  output: "$ sort hashes_salted.txt | uniq -c\n   1 3c1428c3eab99dfad90910fbcbf712df39739a069466642bc66fb42fcff8c592\n   1 c2a17f688ce6495ab8feb57571fbe082c81ff6babb5c0aa9ae800f2930fb18f0",
                                  feedback: "Backwards — the duplicate is precisely what the salt destroyed, and that was the first thing it fixed. Alice and Bob still share a password, but their digests no longer match, so the dump no longer leaks that they do. The wordlist, meanwhile, still works fine; it just costs you one pass per user now.")
                    ]),
                LabStep(
                    instruction: "Your write-up needs the real remediation. The salt is in place — what else does the app need?",
                    hint: "A salt makes each user's guessing independent. What makes each individual guess expensive?",
                    options: [
                        LabOption("Store Argon2id (or bcrypt/scrypt) with a tuned cost — a deliberately slow, memory-hard hash",
                                  correct: true,
                                  output: "$argon2id$v=19$m=65536,t=3,p=4$c29tZXNhbHQ$<digest>\n#        ^ algorithm  ^ memory 64 MiB  ^ 3 passes  ^ 4 lanes  ^ salt\n# algorithm, parameters and salt all carried in one self-describing string",
                                  feedback: "Two different jobs, two different controls. The salt makes each user's guessing independent; a **slow** hash makes each individual guess expensive. SHA-256 is a general-purpose hash designed to be fast — billions per second on a GPU — which is exactly the wrong property for a password. Argon2id with a tuned memory cost drops that to a handful per second per core, and memory-hardness specifically blunts GPU and ASIC parallelism. Note the format too: algorithm, parameters and salt all travel in the string, so you can raise the cost later without a schema migration."),
                        LabOption("Switch to SHA-512 with the per-user salt",
                                  output: "# SHA-512, single GPU, rough order of magnitude: billions of guesses/sec\n# digest length: 128 hex chars (and irrelevant to cracking cost)",
                                  feedback: "Longer is not slower, and this conflation is extremely common. SHA-512 is another *fast* general-purpose hash; on a GPU it's the same order of magnitude as SHA-256, and on 64-bit hardware it can be faster. Digest length affects collision resistance, not the cost of one guess — which is the only quantity that matters when an attacker is grinding a wordlist. You need a function *designed* to be expensive, not a bigger output."),
                        LabOption("Encrypt the password column with AES and keep the key in the app config",
                                  output: "# app.config: DB_CRYPT_KEY=...\n# same host as the database -> one compromise yields every password in cleartext",
                                  feedback: "You've replaced a one-way function with a reversible one, and put the key on the same host as the data it protects — so a single compromise yields every password in plaintext, which is strictly worse than the salted-hash position you started from. The principle: a password should be **verifiable, not recoverable**. You only encrypt a credential when you genuinely need it back later (a third-party API key, say), and then the key belongs in a KMS or HSM, never in a config file beside the database.")
                    ]),
                LabStep(
                    instruction: "One digest in the unsalted dump — `f9c1faceed16494614ed3f3a56dcb2fb` — survived the whole wordlist. That user's password was `correct-horse-battery-staple-7`. Why did fourteen million candidates miss it?",
                    hint: "What does a wordlist actually contain?",
                    options: [
                        LabOption("It simply isn't in the list — length and unpredictability beat a dictionary, not character variety",
                                  correct: true,
                                  output: "$ grep -ic 'correct-horse-battery-staple-7' rockyou.txt\n0\n$ printf '%s' 'correct-horse-battery-staple-7' | md5sum\nf9c1faceed16494614ed3f3a56dcb2fb  -\n# 30 characters, never published -> outside the guessed distribution",
                                  feedback: "Cracking is sampling from a distribution of *likely* passwords, and a wordlist is a record of what humans have actually chosen and leaked. A long passphrase nobody has published sits outside that distribution, so no wordlist contains it — and at 30 characters no brute-force mask reaches it either, because the keyspace grows exponentially with length. This is precisely why guidance moved from \"eight characters with a symbol\" to \"long, unique per site\": the first fights character variety, the second fights predictability, and only the second is what attackers exploit."),
                        LabOption("Because it contains hyphens, and hashcat struggles with punctuation",
                                  output: "$ grep -c -- '-' rockyou.txt\n# hundreds of thousands of entries contain hyphens\n# ?a masks include all 33 ASCII punctuation characters",
                                  feedback: "Hashcat handles any byte, wordlists are full of punctuation, and `?a` masks cover all of it. The character *set* was never the obstacle — which is the point worth taking away, because \"add a symbol\" is the advice everyone remembers and it's the weakest of the levers. `P@ssw0rd!` has four character classes and is in every wordlist on earth."),
                        LabOption("Because that row was salted and the other two weren't",
                                  output: "# schema at this point: users(username, password_hash)\n# no salt column exists",
                                  feedback: "All three rows in this dump are unsalted — that was the finding you opened with, and there's no salt column in the schema yet. This password survived on its own merits: it wasn't in the list and it was too long to brute-force. Worth separating in your head, because they're independent properties. A salt protects a *weak* password from cheap bulk cracking; length protects it from being guessed at all.")
                    ])
            ]),

        // MARK: 7 — Precise grep / regex on a messy log (intermediate)

        InteractiveLab(
            id: "lab-grep-log",
            title: "Grep the signal out of a log",
            goal: "Write patterns precise enough to answer four questions about a 2 GB access log, and spot the one regex that is a denial-of-service bug.",
            track: .fundamentals,
            difficulty: .intermediate,
            minutes: 9,
            scenario: "You own a small lab web server and its nginx access log has reached about 2.1 million lines — roughly 300 MB. No SIEM, no log pipeline, just a shell. Every line is in the combined format:\n\n`198.51.100.10 - - [01/Oct/2026:11:42:07 +0000] \"GET /index.php HTTP/1.1\" 200 1842 \"-\" \"Mozilla/5.0\"`",
            debrief: "Every wrong answer here was a pattern that *ran* and returned a number. That's what makes regex dangerous in analysis work: there's no error to warn you, just a count you have no reason to doubt. Three habits fix it.\n\n**Anchor to structure.** A log line has fields. `\" 5[0-9]{2} ` finds the status code because it says *where* the code sits; a bare `500` finds the digits anywhere, including in byte counts and paths. **Escape what you mean literally** — an unescaped `.` is a wildcard, so `.php` matches `graphphp`. **Prefer a negated class to `.*`** — `[^ \"]+` stops exactly at the delimiter, where a greedy `.*` runs to the last match on the line and swallows four fields you didn't want.\n\nAnd a regex is code, with a complexity cost as well as a meaning. `^([a-zA-Z0-9_]+)+$` accepts exactly the same strings as `^[a-zA-Z0-9_]+$` and takes exponential time to **reject** input, so one crafted request can pin a CPU. If a pattern runs on untrusted data, the input an attacker controls is a parameter of its runtime.\n\nThe red and blue sides of this are the same skill pointed differently: an attacker greps a source dump for secrets with these patterns, and a defender writes the same patterns into Sigma rules and SIEM queries to catch the request you found at step four. Which is also the warning in that step — a filter matching the raw string misses `%2e%2e`, so normalise first, then decide.",
            tools: ["grep", "awk", "sort", "uniq"],
            relatedLessonID: "fund-regex",
            steps: [
                LabStep(
                    instruction: "Count the requests that returned a 5xx server error.",
                    hint: "In the combined format the status code always appears in exactly one place. Describe that place, not just the digits.",
                    options: [
                        LabOption("grep -cE '\" 5[0-9]{2} ' access.log",
                                  correct: true,
                                  output: "184",
                                  feedback: "The status code sits in a fixed position — immediately after the closing quote of the request line, with a space either side — so the pattern states that structure: quote, space, `5`, two digits, space. `5[0-9]{2}` covers 500–599, and the surrounding literals are what stop it matching digits anywhere else on the line. Anchoring to structure is the whole difference between a count you can report and a count you can't."),
                        LabOption("grep -c 500 access.log",
                                  output: "9412",
                                  feedback: "Fifty times too many, and every extra is a false positive. `500` matches anywhere on the line: inside a `1500`-byte response size, inside a path like `/product/5004`, inside a timestamp. A bare number is one of the weakest patterns you can write, because it specifies a value and says nothing about position — and in a structured log, position carries the meaning."),
                        LabOption("grep -cE '5[0-9][0-9]' access.log",
                                  output: "11208",
                                  feedback: "You fixed the wrong half. The character classes are right — any three digits starting with 5 — but with nothing anchoring them they now match *more* than the bare string did, including every byte count in that range and any three-digit run inside a longer number. Making a pattern more expressive without making it more positioned makes it worse.")
                    ]),
                LabStep(
                    instruction: "Produce the most-requested paths, with counts.",
                    hint: "The path is bounded by a space on one side and a space on the other. Say that, rather than using `.*`.",
                    options: [
                        LabOption("grep -oE '\"[A-Z]+ [^ \"]+' access.log | cut -d' ' -f2 | sort | uniq -c | sort -rn | head -4",
                                  correct: true,
                                  output: "   8431 /index.php\n   2190 /static/app.css\n    607 /login\n     12 /admin/../../etc/passwd",
                                  feedback: "`[^ \"]+` is a **negated** character class — \"a run of characters that is neither a space nor a quote\" — so it stops dead at the end of the path. That's the idiom to reach for instead of `.*` whenever you're extracting a delimited field. And look at the bottom of the frequency count: the top entries are traffic, the long tail is where the interesting requests live. Always read both ends of a `sort -rn`."),
                        LabOption("grep -oE '\".*\"' access.log | head -2",
                                  output: """
"GET /index.php HTTP/1.1" 200 1842 "-" "Mozilla/5.0 (X11; Linux x86_64)"
"GET /login HTTP/1.1" 200 2304 "-" "curl/8.5.0"
""",
                                  feedback: "Greedy. `.*` matches as much as it can, so it runs to the **last** quote on the line and you've captured the request, the status, the byte count, the referrer and the user agent as one lump. A lazy quantifier (`\".*?\"`, which needs `grep -P` — POSIX `-E` has no lazy form) would stop at the first closing quote, but the negated class is clearer, faster and works in plain `-E`."),
                        LabOption("grep -oE 'GET .*' access.log | head -2",
                                  output: """
GET /index.php HTTP/1.1" 200 1842 "-" "Mozilla/5.0 (X11; Linux x86_64)"
GET /login HTTP/1.1" 200 2304 "-" "curl/8.5.0"
""",
                                  feedback: "Same greedy over-capture, plus a second bug that's quieter and worse: you've silently dropped every POST, PUT, DELETE and HEAD from the answer. Hard-coding one value where the format allows several narrows your data without telling you it did — and a missing row looks exactly like a row that was never there.")
                    ]),
                LabStep(
                    instruction: "Count the requests for `.php` files — and only those.",
                    hint: "What does an unescaped `.` mean? And what stops your pattern at the end of the extension?",
                    options: [
                        LabOption("grep -cE '\"[A-Z]+ [^ \"]+\\.php[ ?]' access.log",
                                  correct: true,
                                  output: "8597",
                                  feedback: "Two fixes in one pattern. `\\.` escapes the dot so it matches a literal `.` rather than any character. And `[ ?]` states the boundary — the extension must be followed by a space (end of path) or a `?` (start of a query string) — which is what keeps `.phps` and `.php.bak` out. Regex has no concept of a \"file extension\"; if you want a boundary you have to write one."),
                        LabOption("grep -cE '.php' access.log",
                                  output: "9980",
                                  feedback: "Two bugs in four characters. `.` is a wildcard, so this matches *any* character followed by `php` — including the `hphp` inside `/graphphp/widget`. And with no positioning it searches the whole line, so a user agent like `php-curl/1.0` in the last field counts as a PHP request. The unescaped dot is the most common regex mistake there is, precisely because the pattern still looks right."),
                        LabOption("grep -cE '\\.php' access.log",
                                  output: "9655",
                                  feedback: "The escape is correct and that's the important half — `/graphphp` is gone. But you still match `/app.phps`, `/config.php.bak`, and any `.php` appearing in the referrer or user-agent field, because nothing says where the match must sit or what may follow it. Escaping fixes *meaning*; position and boundary fix *precision*, and you usually need all three.")
                    ]),
                LabStep(
                    instruction: "That `/admin/../../etc/passwd` in the frequency tail is worth isolating — including any encoded variants.",
                    hint: "The same attack has more than one spelling. One of them contains no dots at all.",
                    options: [
                        LabOption("grep -iE '\\.\\./|%2e%2e' access.log",
                                  correct: true,
                                  output: """
203.0.113.47 - - [01/Oct/2026:11:58:22 +0000] "GET /admin/../../etc/passwd HTTP/1.1" 404 162 "-" "curl/8.5.0"
203.0.113.47 - - [01/Oct/2026:11:58:31 +0000] "GET /view?f=%2e%2e%2f%2e%2e%2fetc%2fshadow HTTP/1.1" 403 153 "-" "curl/8.5.0"
""",
                                  feedback: "Two spellings of one attack, from one host. `\\.\\./` is the literal traversal with both dots escaped; `%2e%2e` is the same two dots percent-encoded to walk past a filter that only looks for the literal form. `-i` matters because `%2E%2E` is equally valid and equally effective. Which is the real lesson: pattern-matching raw input is fragile, because one input has many encodings. Normalise — decode, then resolve the path — and *then* decide."),
                        LabOption("grep -c '../' access.log",
                                  output: "2147882\n# effectively every line in the file",
                                  feedback: "Unescaped dots again, and this time the blast radius is obvious. `../` reads as \"any character, any character, a slash\", which almost every line in an HTTP log contains — `ET /` alone satisfies it. When a pattern returns nearly the whole file, suspect a wildcard you didn't mean before you suspect the data. You wanted `\\.\\./`."),
                        LabOption("grep -F '../' access.log",
                                  output: """
203.0.113.47 - - [01/Oct/2026:11:58:22 +0000] "GET /admin/../../etc/passwd HTTP/1.1" 404 162 "-" "curl/8.5.0"
""",
                                  feedback: "`-F` treats the pattern as a fixed string, so the dots are literal with no escaping needed — a genuinely good habit when you want no regex semantics at all, and it found the literal attempt cleanly. But a fixed string can only ever match one spelling, so the `%2e%2e` request walked straight past it. You found one of the two, and the one you missed was the more deliberate of the pair.")
                    ]),
                LabStep(
                    instruction: "A teammate wants to block traversal at the app layer with this input validator: `^([a-zA-Z0-9_]+)+$`. What do you raise?",
                    hint: "Think about how long it takes to decide a *non-matching* string doesn't match.",
                    options: [
                        LabOption("Nested quantifiers — rejecting a long non-matching input backtracks exponentially (ReDoS), so one request can pin a CPU",
                                  correct: true,
                                  output: "input: 'a' x N  followed by '!'   (never matches)\n  N=14    0.0005 s\n  N=18    0.0066 s\n  N=22    0.1027 s\n# ~4x per 2 extra characters -> doubling per character\n# fix: ^[a-zA-Z0-9_]+$   (same language, linear time)",
                                  feedback: "The inner `+` and the outer `+` can divide the same input in exponentially many ways, and a backtracking engine tries every division before it will concede there's no match. Note it's the **reject** path that explodes, which is why this survives testing: every valid input returns instantly. Dropping the redundant group gives an identical language in linear time. A regex is code, and this one has a complexity bug that an attacker chooses the input to."),
                        LabOption("Nothing — it's equivalent to `^[a-zA-Z0-9_]+$`",
                                  output: "# same language accepted\n# 'aaaaaaaaaaaaaaaaaaaaaa!' :  simple form ~0.000002 s   nested form ~0.1 s",
                                  feedback: "Equivalent in what it *matches*, catastrophically different in what it *costs*. Both accept exactly the same strings — so a correctness test suite passes — and only one of them returns promptly when the string should be rejected. Correctness and complexity are separate properties of the same pattern, and untrusted input probes the second one. That's the whole class of bug."),
                        LabOption("The class should be `\\w` for safety",
                                  output: "# ^(\\w+)+$  -- still nested, still exponential on reject\n# and \\w is Unicode-aware in some engines: WIDENS what is accepted",
                                  feedback: "Shorter, and in most engines the same set — but it leaves the nested quantifier completely untouched, which was the actual defect. Worse, `\\w` is Unicode-aware in several engines (Python, .NET, PCRE with the right flags), so it can *widen* what you accept to include characters you never intended. Shorthand classes are convenient; they're a poor instrument for tightening a security boundary.")
                    ])
            ]),

        // MARK: 8 — Deciding whether to trust a certificate (advanced)

        InteractiveLab(
            id: "lab-cert-trust",
            title: "Should you trust this certificate?",
            goal: "Diagnose three different certificate failures, decide what each one actually means, and name the risk you take on when you trust a new root.",
            track: .fundamentals,
            difficulty: .advanced,
            minutes: 9,
            scenario: "You're bringing up an internal dashboard on your own lab network at `https://dash.lab.local` and the browser is refusing it. Two more hosts in the same lab have certificate oddities of their own. Everything here is yours, so you can fix it properly rather than clicking through.",
            debrief: "Certificate validation is four independent checks, and treating them as one blurry \"is it valid\" is what makes warnings feel arbitrary. Does the signature chain reach a root in **this** trust store? Does the **subjectAltName** cover the hostname you typed? Is it inside its **validity window**? Has it been **revoked**? Each can fail alone, each means something different, and only reading them separately tells you whether you're looking at sloppy operations or an actual interception.\n\nThen the ceiling: even all four passing proves only that you have a private channel to whoever controls that exact name. Domain-validated certificates are free and automated, so a look-alike domain gets a perfectly valid one in seconds. TLS answers *am I talking privately to the holder of this name* — never *is this name the one I meant*. The controls that answer the second question are origin-bound by construction: HSTS, pinning, and FIDO2/passkeys that refuse to sign for the wrong origin.\n\nAnd the move that fixed your lab is the one an attacker wants most. A root in your trust store can mint a valid certificate for **any** hostname, silently. That's how corporate TLS inspection works and how an adversary-in-the-middle proxy wants to work, which is why \"install our root certificate\" deserves the same scrutiny as \"run this installer\" — and why `-k` and *Advanced → Proceed* turn a working detection into a permanent blind spot.",
            tools: ["openssl", "curl"],
            relatedLessonID: "fund-pki",
            steps: [
                LabStep(
                    instruction: "The browser won't load `https://dash.lab.local`. Find out everything the certificate claims, in one go.",
                    hint: "You want the subject, the issuer, the dates and the SAN — four separate facts from one fetch.",
                    options: [
                        LabOption("openssl s_client -connect dash.lab.local:443 -servername dash.lab.local </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates",
                                  correct: true,
                                  output: "subject= /CN=dash.lab.local\nissuer= /CN=dash.lab.local\nnotBefore=Apr  2 09:11:00 2024 GMT\nnotAfter=Apr  2 09:11:00 2025 GMT",
                                  feedback: "Three questions answered at once, and you should read them as three. *Who does it claim to be?* `dash.lab.local`. *Who vouches for that?* Itself — subject and issuer are identical, which is the definition of self-signed. *When is it valid?* It expired in April 2025. Two independent failures, which is why reading the fields beats reading the warning: a browser shows you the first problem it hits, and there was a second one behind it. (`-servername` sends SNI, without which a shared host may hand you the wrong certificate entirely.)"),
                        LabOption("curl -I https://dash.lab.local",
                                  output: "curl: (60) SSL certificate problem: self-signed certificate\nMore details here: https://curl.se/docs/sslcerts.html",
                                  feedback: "Useful, and it even names a cause — but it stops at the first failure and shows you none of the certificate's actual fields. You'd have concluded \"self-signed\" and never discovered that it's also eighteen months expired. When you're diagnosing rather than monitoring, fetch the fields and judge them yourself; a validator's first complaint is rarely the whole story."),
                        LabOption("curl -k https://dash.lab.local",
                                  output: "<!doctype html><title>Lab Dashboard</title><h1>Lab Dashboard</h1>",
                                  feedback: "`-k` didn't answer the question, it **silenced** it — and that distinction is the single most consequential habit in this topic. You've turned off the only check that would tell you whether the host on the other end is the one you meant, so from now on an interception attempt looks exactly like this success. `-k`, `verify=False` and *Advanced → Proceed* are how certificate warnings actually get resolved in practice, and each one converts a working detection into a permanent blind spot. Identify the certificate out-of-band first; then you don't need the flag.")
                    ]),
                LabStep(
                    instruction: "Self-signed **and** expired. What's the right repair for a lab you control?",
                    hint: "What's actually missing from a self-signed certificate? It isn't the encryption.",
                    options: [
                        LabOption("Stand up a small internal CA, trust its root on the lab machines once, and issue properly-dated certs from it",
                                  correct: true,
                                  output: "openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \\\n  -keyout labCA.key -out labCA.crt \\\n  -subj \"/CN=Lab Root CA\" \\\n  -addext \"basicConstraints=critical,CA:TRUE\" \\\n  -addext \"keyUsage=critical,keyCertSign,cRLSign\"\n# then issue leaf certs from labCA, each with a SAN for its hostname",
                                  feedback: "\"Self-signed\" is not a cryptographic weakness — the encryption is byte-for-byte identical to a publicly-trusted certificate. What's missing is **anyone vouching for the name**. An internal CA supplies exactly that: trust the root once per machine, and every certificate you issue afterwards validates normally. The real win is that warnings stay meaningful, because a warning now means something is genuinely wrong instead of \"it's Tuesday\". Make the extensions explicit rather than relying on defaults that vary between OpenSSL versions."),
                        LabOption("The key is still fine — the expiry date is cosmetic for an internal host, so ignore it",
                                  output: "# clients enforce notAfter unconditionally\n# an expired cert cannot be distinguished from an abandoned one",
                                  feedback: "The validity window is a contract, and it's the only revocation mechanism that works without network access — CRLs and OCSP both need a fetch that can be blocked, while an expiry date is checked offline every time. An expired certificate tells every client \"nobody is maintaining this any more\", which is precisely the state a stolen key ends up in. Treating dates as advisory on internal hosts is how teams train themselves to click through warnings everywhere else."),
                        LabOption("Add the server's own leaf certificate directly to each machine's trust store",
                                  output: "# works today\n# cert rotates -> every machine breaks -> repeat on every host, every renewal",
                                  feedback: "It works, and it's the wrong *shape* of fix. Trusting a leaf means redoing the work on every machine at every rotation, so rotation becomes something your team avoids — and it trains everyone that adding things to the trust store is routine maintenance, which is a habit an attacker only needs to exploit once. Trust the CA, which is designed to be long-lived and to delegate; don't trust the leaf, which is designed to be replaced.")
                    ]),
                LabStep(
                    instruction: "Second host. `https://api.lab.example.net` has a current certificate that chains cleanly to a public root — and the browser still warns. Find out why.",
                    hint: "Validation checks more than the chain. Which field carries the hostnames?",
                    options: [
                        LabOption("openssl x509 -noout -subject -in api.crt && openssl x509 -noout -text -in api.crt | grep -A1 'Subject Alternative Name'",
                                  correct: true,
                                  output: "subject= /CN=lab-internal-01.example.net\n            X509v3 Subject Alternative Name:\n                DNS:lab-internal-01.example.net, DNS:www.lab-internal-01.example.net",
                                  feedback: "There's the failure: you connected to `api.lab.example.net` and the SAN lists neither that name nor a wildcard covering it. Two details worth carrying forward. Modern clients match the hostname against **subjectAltName**, not the CN — CN-based matching has been deprecated for years, so a certificate whose CN \"looks right\" can still fail outright. And a wildcard covers exactly one label: `*.example.net` matches `api.example.net` but **not** `api.lab.example.net`."),
                        LabOption("openssl x509 -noout -issuer -in api.crt",
                                  output: "issuer= /C=US/O=Let's Encrypt/CN=R11\n# (Let's Encrypt rotates its intermediates — yours will show whichever is current)",
                                  feedback: "A real public CA, so the chain is genuinely fine — and that's exactly why this answer doesn't help. A valid chain to a trusted root says nothing about whether the *name* matches; they're two independent checks and either can fail while the other passes. You've confirmed the half that was already working. Check the field the error is actually about."),
                        LabOption("ping api.lab.example.net",
                                  output: "PING api.lab.example.net (198.51.100.23): 56 data bytes\n64 bytes from 198.51.100.23: icmp_seq=0 ttl=57 time=12.4 ms",
                                  feedback: "The name resolves and the host answers, so DNS and routing are healthy — which rules nothing in or out. A TLS identity failure is about what the certificate **says**, not about whether the host is reachable; you'd get the same ping from the correct server and from an interception proxy. Reachability and identity are different layers, and this warning lives entirely in the second one.")
                    ]),
                LabStep(
                    instruction: "Third host. `https://lab-dash-login.example.com` presents a flawless certificate: trusted root, in date, SAN matches. A teammate says the padlock proves it's your dashboard. Respond.",
                    hint: "What exactly did those four checks establish? Name the thing they can't.",
                    options: [
                        LabOption("A valid certificate proves control of that exact domain and nothing more — and that domain isn't yours",
                                  correct: true,
                                  output: "subject= /CN=lab-dash-login.example.com\nissuer= /C=US/O=Let's Encrypt/CN=R11   # intermediate names rotate\nnotBefore=Oct  1 14:22:31 2026 GMT\nnotAfter=Dec 30 14:22:31 2026 GMT\n# every check passes. the name is simply not the one you own.",
                                  feedback: "This is the ceiling the padlock cannot raise. Domain-validated certificates are free and fully automated, so anyone who controls a name has a valid certificate for it within seconds — including a look-alike built to be misread. TLS answers *am I talking privately to the holder of this name?* It never answers *is this name the one I meant?* That second question is yours, and the only controls that answer it mechanically are bound to the origin: HSTS, certificate pinning, and FIDO2/passkeys, which simply refuse to sign for the wrong origin no matter how convinced the human is."),
                        LabOption("Check for Extended Validation — reject it if the certificate is only DV",
                                  output: "# browsers removed the EV identity indicator from the URL bar years ago\n# no certificate tier asserts 'this is the domain the user intended'",
                                  feedback: "A reasonable-sounding instinct that the industry tried and abandoned. Browsers removed the EV identity indicator because users didn't read it and its presence didn't predict fraud — and crucially, no validation tier has ever claimed to tell you a domain is the one you *intended*. EV asserts facts about an organisation, not about your intent. There is no certificate property that catches a look-alike."),
                        LabOption("Compare this certificate's fingerprint against the real dashboard's",
                                  output: "$ openssl x509 -noout -fingerprint -sha256 -in presented.crt\nsha256 Fingerprint=<differs from the known-good value>",
                                  feedback: "This one genuinely works, and it's the right idea at the wrong altitude. If you already hold the real fingerprint out-of-band you're doing manual pinning — fine for a handful of hosts, unmanageable across an estate, and it still depends on a human remembering to check every time. The scalable version is the same idea enforced automatically: let HSTS, pinning or an origin-bound authenticator do the comparison, because it will do it on the occasion you're distracted.")
                    ]),
                LabStep(
                    instruction: "Your lab CA's root is now in your laptop's trust store and the dashboard loads cleanly. What risk did you just accept?",
                    hint: "What is the full scope of what that root can now vouch for on this machine?",
                    options: [
                        LabOption("That root can now mint a valid certificate for **any** hostname on this machine — so `labCA.key` is as sensitive as everything it could impersonate",
                                  correct: true,
                                  output: "# labCA.key can sign a leaf for ANY name, not just *.lab.local\n# this laptop will accept those leaves silently, padlock and all\n# blast radius = every HTTPS site this machine visits",
                                  feedback: "Adding a root is the most powerful single act of trust available on a machine, and its scope is total: that key can sign a certificate for any name, and your browser will accept it with no warning and a padlock. So treat `labCA.key` accordingly — keep it off the machines that trust it, protect it with a passphrase, scope the root to the lab hosts that actually need it, and remove it when the lab is done. This is exactly the mechanism a corporate TLS-inspection proxy uses, and exactly the mechanism an adversary-in-the-middle wants, which is why \"install our root certificate\" deserves the same scrutiny as \"run this installer\"."),
                        LabOption("None worth noting — I generated the CA myself and I'm the only one who controls it",
                                  output: "# risk is not 'will I misuse it'\n# risk is 'what happens if labCA.key leaks'\n# answer: valid certs for any hostname, accepted silently, on every machine that trusts the root",
                                  feedback: "You control it today, and that was never the risk. Trust decisions are assessments of what happens **when the thing you trusted is compromised** — and if `labCA.key` leaks from a backup, a repo, or a laptop, whoever holds it can present a valid certificate for any hostname to every machine trusting that root, with a padlock and no warning. Good intentions don't reduce blast radius; scope, key protection and removal do."),
                        LabOption("Only `*.lab.local` names, since that's all I intend to issue",
                                  output: "# intent is not encoded in the certificate\n# scope requires the X.509 nameConstraints extension -- absent here\n# and client enforcement of nameConstraints is inconsistent",
                                  feedback: "Intent isn't a certificate field. Unless the root carries an X.509 **nameConstraints** extension restricting it to a DNS suffix, it can sign anything — and even with it, client enforcement is inconsistent enough that you can't rely on it alone. This is a good general principle for PKI: if you want a limit, it has to be written into the certificate *and* enforced by the verifier. A constraint that exists only in your head constrains nothing.")
                    ])
            ])
    ]
}
