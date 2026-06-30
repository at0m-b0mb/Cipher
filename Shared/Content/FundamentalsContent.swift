import Foundation

/// The Fundamentals track — the shared bedrock every operator (red or blue)
/// needs: the mindset and ethics, how networks really move data, and the
/// cryptography that protects (and betrays) it.
enum FundamentalsContent {

    static let track = Track(
        id: "fundamentals",
        kind: .fundamentals,
        title: "Fundamentals",
        tagline: "Mindset, the shell, networks & crypto — the ground floor of everything.",
        modules: [mindset, shell, os, networking, encoding, crypto, web, windows, code, identity, machine]
    )

    // MARK: F6 — Code & data foundations

    private static let code = Module(
        id: "fund-code",
        title: "Code & Data",
        summary: "The literacy under every exploit: bitwise logic and XOR, how databases answer questions in SQL, and the regular expressions that find structure in text.",
        systemImage: "chevron.left.forwardslash.chevron.right",
        lessons: [bitwiseLesson, databasesLesson, regexLesson]
    )

    private static let bitwiseLesson = Lesson(
        id: "fund-bitwise",
        title: "Bits, Bytes & XOR",
        subtitle: "The bitwise operations that underpin crypto, exploitation and every clever trick.",
        minutes: 10,
        difficulty: .foundational,
        blocks: [
            .heading("Everything is bits"),
            .paragraph("Underneath every file, packet and password is a string of bits — 1s and 0s, grouped into 8-bit **bytes**. Security work constantly means manipulating data at this level: masking flags, combining keys, flipping a single bit to corrupt a structure. The four **bitwise operators** are the tools for that, and one of them — XOR — is the quiet workhorse of cryptography."),
            .keyPoints([
                "AND (&) — 1 only if both bits are 1. Used to mask: keep some bits, zero the rest.",
                "OR (|) — 1 if either bit is 1. Used to set flags on.",
                "XOR (^) — 1 if the bits differ. Self-inverse: a ^ b ^ b == a.",
                "NOT (~) — flips every bit. Shifts (<< >>) move bits left/right, multiplying or dividing by powers of two."
            ]),
            .heading("Why XOR is everywhere in crypto"),
            .paragraph("XOR has a magical property: applying the same value twice cancels out. So if you XOR plaintext with a key to get ciphertext, XOR-ing the ciphertext with the *same* key returns the plaintext. That single fact is the heart of stream ciphers, one-time pads, and a thousand CTF challenges."),
            .animation(.xorCipher, caption: "Plaintext XOR key gives ciphertext; XOR-ing again with the same key reverses it perfectly back to the original byte."),
            .definition(term: "XOR (exclusive or)", meaning: "A bitwise operation that outputs 1 only when its two input bits differ: 0⊕0=0, 1⊕1=0, 0⊕1=1, 1⊕0=1. Its self-inverse property (x ⊕ k ⊕ k = x) makes it the basis of symmetric stream encryption and the simplest reversible 'scrambler'."),
            .terminal(prompt: "kali@lab",
                      command: "python3 -c \"print(bytes([b ^ 0x42 for b in b'Hi']).hex())\"",
                      output: """
0a2b
# XOR each byte of 'Hi' with the key 0x42 → ciphertext 0a2b
# repeat the same XOR on 0a2b → back to 'Hi'
"""),
            .callout(.warning, "XOR with a single repeating byte is trivially breakable — frequency analysis or a known-plaintext guess recovers the key instantly. XOR is a building block of strong ciphers, not a cipher by itself. If you ever see 'encryption' that's just XOR with a fixed key, treat the data as effectively plaintext."),
            .callout(.tip, "Hex is the natural way to read bytes: one byte = exactly two hex digits, so 0x48 = 0100 1000 = 'H'. Fluently flipping between binary, hex and ASCII is a skill you'll use in every hash dump, packet capture and exploit."),
            .checkpoint(QuizQuestion(
                "You XOR a secret byte with key 0x3C and get 0x7A. What do you get if you XOR 0x7A with 0x3C again?",
                options: [
                    "A new random byte",
                    "The original secret byte",
                    "0x00",
                    "0xFF"
                ],
                correct: 1,
                why: "XOR is self-inverse: (secret ⊕ key) ⊕ key = secret. Applying the same key a second time cancels it out and recovers the original byte."))
        ],
        quiz: [
            QuizQuestion(
                "Which property makes XOR the basis of symmetric stream ciphers?",
                options: [
                    "It always outputs zero",
                    "Applying the same key twice cancels out, so the same operation encrypts and decrypts",
                    "It is impossible to reverse",
                    "It compresses data"
                ],
                correct: 1,
                why: "Because x ⊕ k ⊕ k = x, XOR-ing plaintext with a keystream produces ciphertext, and XOR-ing that ciphertext with the same keystream restores the plaintext — one operation for both directions."),
            QuizQuestion(
                "What does the AND operator (&) let you do to a byte?",
                options: [
                    "Turn bits on",
                    "Mask bits — keep selected bits and force the others to zero",
                    "Reverse the byte",
                    "Add two bytes"
                ],
                correct: 1,
                why: "ANDing with a mask keeps bits where the mask is 1 and zeros bits where the mask is 0 — the standard way to extract or clear specific fields."),
            QuizQuestion(
                "Why is 'encryption' that's just XOR with one fixed byte insecure?",
                options: [
                    "It's too slow",
                    "A repeating single-byte key is trivially recovered with frequency analysis or known plaintext",
                    "It can't be decrypted at all",
                    "It changes the file size"
                ],
                correct: 1,
                why: "A short repeating key leaks structure: statistical analysis of the ciphertext, or a single known plaintext/ciphertext pair, recovers the key immediately. XOR needs a long, non-repeating keystream to be secure.")
        ]
    )

    private static let databasesLesson = Lesson(
        id: "fund-databases",
        title: "Databases & SQL",
        subtitle: "How apps store and ask for data — the query language behind the web's #1 injection bug.",
        minutes: 11,
        difficulty: .foundational,
        blocks: [
            .heading("Where the data lives"),
            .paragraph("Almost every application keeps its data in a **database**: tables of rows and columns, like a spreadsheet with rules. The app talks to it in **SQL** (Structured Query Language) — a remarkably English-like language for asking questions and making changes. You can't understand SQL injection until you can read a SQL query, so let's read one."),
            .animation(.sqlQuery, caption: "SELECT picks the columns; the WHERE clause filters rows. The scan keeps the rows that satisfy the condition and drops the rest."),
            .heading("The four verbs"),
            .paragraph("Most of SQL is four operations on rows. Learn these and you can follow what nearly any app is doing to its data."),
            .keyPoints([
                "SELECT … FROM … WHERE — read rows that match a condition. The bread and butter.",
                "INSERT INTO … VALUES — add a new row.",
                "UPDATE … SET … WHERE — change existing rows.",
                "DELETE FROM … WHERE — remove rows. (Forget the WHERE and you delete the whole table.)"
            ]),
            .terminal(prompt: "sql>",
                      command: "SELECT name, email FROM users WHERE role = 'admin';",
                      output: """
 name   | email
--------+------------------
 alice  | alice@corp.lab
(1 row)
"""),
            .definition(term: "Primary key & foreign key", meaning: "A primary key uniquely identifies each row (e.g. a user id). A foreign key in another table references it (an order's user_id points at a user) — that's how relational databases link data together without duplicating it."),
            .heading("Why this matters for security"),
            .paragraph("Look closely at a query built by gluing strings together: `\"SELECT * FROM users WHERE name = '\" + input + \"'\"`. If the attacker's input contains a quote, it breaks out of the string and becomes part of the *command*. That's **SQL injection** — the entire Red Team web module's most famous bug — and it only makes sense once you see that the query is just text the database executes."),
            .callout(.danger, "The fix is **parameterized queries** (prepared statements): the SQL structure and the user data travel separately, so input is always treated as a value, never as code. Never build SQL by concatenating user input — that's the root cause of injection."),
            .callout(.tip, "`ORDER BY`, `LIMIT`, `JOIN` and `GROUP BY` show up constantly. A JOIN combines rows from two tables on a matching key — exactly how an app shows you 'your orders' by joining the orders table to your user row."),
            .checkpoint(QuizQuestion(
                "What does the WHERE clause do in `SELECT name FROM users WHERE age > 30`?",
                options: [
                    "Chooses which columns to return",
                    "Filters which rows are returned — only those satisfying the condition",
                    "Sorts the results",
                    "Deletes rows over 30"
                ],
                correct: 1,
                why: "WHERE is the filter: it keeps only rows matching the condition (age > 30). SELECT chooses the columns; WHERE chooses the rows."))
        ],
        quiz: [
            QuizQuestion(
                "Which SQL statement reads data without changing it?",
                options: ["INSERT", "UPDATE", "SELECT", "DELETE"],
                correct: 2,
                why: "SELECT queries (reads) rows. INSERT adds, UPDATE modifies and DELETE removes — those three change the data."),
            QuizQuestion(
                "Why does building a query by concatenating user input cause SQL injection?",
                options: [
                    "It's too slow",
                    "Input like a quote can break out of the data and become part of the executed command",
                    "It uses too much memory",
                    "It only happens in old databases"
                ],
                correct: 1,
                why: "When data is glued into the query string, a crafted input (e.g. a quote plus SQL) escapes the intended value and is executed as code — the essence of injection."),
            QuizQuestion(
                "What is the correct defence against SQL injection?",
                options: [
                    "Hiding the database",
                    "Parameterized queries (prepared statements) that keep SQL and data separate",
                    "Making passwords longer",
                    "Blocking the SELECT keyword"
                ],
                correct: 1,
                why: "Prepared statements send the query structure and the user values separately, so input is bound as a value and can never be interpreted as SQL — closing the injection path structurally.")
        ]
    )

    private static let regexLesson = Lesson(
        id: "fund-regex",
        title: "Regular Expressions",
        subtitle: "The pattern language for finding needles in text — used by red and blue alike.",
        minutes: 9,
        difficulty: .intermediate,
        blocks: [
            .heading("Patterns, not exact text"),
            .paragraph("A **regular expression** (regex) describes the *shape* of text rather than its exact content. Instead of searching for one fixed string, you describe a pattern — 'three digits, a dash, four digits' — and it finds every phone number. Regex is everywhere in security: hunting secrets in source code, writing detection rules, scraping data from tool output, and validating input."),
            .animation(.regexMatch, caption: "Character classes, quantifiers and literals sweep the input; when the pattern lines up, the matching span is captured."),
            .heading("The core building blocks"),
            .keyPoints([
                "Character classes — [a-z] any lowercase letter, \\d a digit, \\w a word char, . any character.",
                "Quantifiers — + one or more, * zero or more, ? optional, {3} exactly three.",
                "Anchors — ^ start of line, $ end of line; \\b a word boundary.",
                "Groups & alternation — (…) captures a part, a|b matches a or b.",
                "Literals — most characters match themselves; escape special ones with a backslash (\\. for a real dot)."
            ]),
            .terminal(prompt: "kali@lab",
                      command: "grep -rEo '[A-Za-z0-9+/]{40}' . | head -3   # hunt for base64-ish secrets",
                      output: """
config.py:AKIA8EXAMPLEKEY1234567890ABCDEFGH1234
backup.env:c2VjcmV0LXRva2VuLXZhbHVlLWRvLW5vdC1jb21t
"""),
            .definition(term: "Greedy vs lazy", meaning: "By default quantifiers are greedy — they match as much as possible. Adding ? makes them lazy (as little as possible): .* grabs everything to the last match, while .*? stops at the first. Getting this wrong is the classic regex bug."),
            .callout(.tip, "Red team uses regex to grep secrets (API keys, JWTs, hashes) out of source dumps and responses. Blue team uses the very same patterns in Sigma/YARA rules and SIEM queries to detect them. Same skill, both sides of the fence."),
            .callout(.warning, "A poorly written regex can hang on crafted input — 'catastrophic backtracking' (ReDoS) — turning a validation routine into a denial-of-service bug. Avoid nested quantifiers like (a+)+ on untrusted input."),
            .checkpoint(QuizQuestion(
                "What does the pattern `\\d{3}-\\d{4}` match?",
                options: [
                    "Any three letters",
                    "Three digits, a dash, then four digits — like 555-1234",
                    "Exactly the text d3-d4",
                    "Any word of length 7"
                ],
                correct: 1,
                why: "\\d is a digit and {n} means exactly n of them, with the dash a literal. So it matches three digits, a hyphen, and four digits — a classic phone-number shape."))
        ],
        quiz: [
            QuizQuestion(
                "What does the `+` quantifier mean in a regex?",
                options: [
                    "Exactly one",
                    "One or more of the preceding element",
                    "Zero or more",
                    "Addition"
                ],
                correct: 1,
                why: "`+` matches one or more repetitions of the preceding token. (`*` is zero or more, `?` is optional.)"),
            QuizQuestion(
                "Why might both red and blue teams use the same regex patterns?",
                options: [
                    "They never do",
                    "Red uses them to find secrets in data; blue uses them in detection rules to catch the same patterns",
                    "Regex only works for attackers",
                    "Regex is only for formatting"
                ],
                correct: 1,
                why: "A pattern that recognises an API key or a malicious command is equally useful for offensive hunting and defensive detection — the skill transfers directly between the two roles."),
            QuizQuestion(
                "What is 'catastrophic backtracking' (ReDoS)?",
                options: [
                    "A regex that matches too little",
                    "A pathological pattern that takes exponential time on crafted input, causing a denial of service",
                    "A typo in the pattern",
                    "A way to speed up matching"
                ],
                correct: 1,
                why: "Certain patterns (e.g. nested quantifiers) can explode into exponential work on adversarial input, hanging the matcher — a real availability risk when regex runs on untrusted data.")
        ]
    )

    // MARK: F-S — Systems & the shell

    private static let shell = Module(
        id: "fund-shell",
        title: "Systems & the Shell",
        summary: "The Linux command line is the cockpit of security work — learn to move, inspect and control a system from the terminal.",
        systemImage: "terminal",
        lessons: [linuxLesson]
    )

    private static let linuxLesson = Lesson(
        id: "fund-linux",
        title: "Linux & the Command Line",
        subtitle: "Why hackers live in the terminal — and the commands that get you everywhere.",
        minutes: 12,
        difficulty: .foundational,
        blocks: [
            .heading("The terminal is a superpower"),
            .paragraph("Almost every server on earth runs Linux, almost every security tool is built for it, and almost everything you'll do in this course happens at a shell prompt. A graphical desktop hides the system from you; the command line hands you the controls. Learn to read and drive it and the rest of cybersecurity stops feeling like magic."),
            .definition(term: "The shell", meaning: "A program (commonly bash or zsh) that reads commands you type and asks the operating system to run them. The `$` prompt means it's your turn; `#` means you're running as root — the all-powerful admin user."),
            .heading("Finding your way around"),
            .paragraph("The filesystem is a single tree starting at `/` (root). You're always sitting in one directory — three commands tell you where you are and what's around you."),
            .terminal(prompt: "kali@lab",
                      command: "pwd && ls -la /etc | head -4",
                      output: """
/home/kali
total 1112
drwxr-xr-x 133 root root 12288 Jun  9 10:02 .
-rw-r--r--   1 root root  2981 Apr 18 09:11 passwd
-rw-r-----   1 root shadow 1810 Apr 18 09:11 shadow
"""),
            .keyPoints([
                "pwd — print working directory (where am I?).",
                "ls -la — list everything, including hidden dotfiles, with permissions and owners.",
                "cd /path — change directory; `cd ..` goes up, `cd ~` goes home.",
                "cat / less — read a file; `less` lets you scroll and search large ones."
            ]),
            .heading("Reading permissions"),
            .paragraph("That `drwxr-xr-x` string is the single most useful thing to understand on a Linux box. The first character is the type (`d` directory, `-` file, `l` link). The next nine are three groups of read/write/execute permissions — for the **owner**, the **group**, and **everyone else**. Misconfigured permissions are one of the most common ways a low-privilege foothold becomes root."),
            .definition(term: "rwx", meaning: "read (view contents), write (modify), execute (run as a program / enter a directory). Shown per owner/group/other, e.g. `rwxr-xr--` = owner full, group read+execute, others read-only."),
            .callout(.tip, "`chmod` changes permissions and `chown` changes ownership. The numeric shorthand is worth memorizing: 7=rwx, 6=rw-, 5=r-x, 4=r--. So `chmod 644 file` means owner rw-, group and others r--."),
            .heading("Finding things and chaining commands"),
            .paragraph("The real power of the shell is composition: small tools piped together. `grep` filters lines, `find` locates files, and the pipe `|` feeds one command's output into the next. This one habit — chaining — is what makes the terminal faster than any GUI."),
            .terminal(prompt: "kali@lab",
                      command: "find / -perm -4000 -type f 2>/dev/null | grep -v snap",
                      output: """
/usr/bin/sudo
/usr/bin/passwd
/usr/bin/pkexec
/usr/bin/find          <-- unusual SUID — a privesc lead!
"""),
            .keyPoints([
                "grep pattern — keep only lines that match; add -i for case-insensitive, -r to recurse.",
                "find / -name '*.conf' — search the whole tree by name, type, size or permission.",
                "cmd | other — pipe output into the next command; stack as many as you like.",
                "2>/dev/null — throw away error noise so the real results stand out.",
                "man cmd — the built-in manual for any command; your first stop when stuck."
            ]),
            .callout(.danger, "That `find` command searches for SUID binaries — programs that run as their owner (often root) regardless of who launches them. A SUID binary that shouldn't be one is a classic privilege-escalation path you'll exploit in the Red Team track."),
            .checkpoint(QuizQuestion(
                "A file shows permissions `-rwxr-xr--`. What can a user who is *not* the owner and *not* in the file's group do with it?",
                options: [
                    "Read, write and execute it",
                    "Read and execute it",
                    "Only read it",
                    "Nothing at all"
                ],
                correct: 2,
                why: "The last three characters `r--` apply to 'others'. They grant read only — no write, no execute. The owner (rwx) and group (r-x) have more."))
        ],
        quiz: [
            QuizQuestion(
                "A shell prompt ending in `#` instead of `$` tells you that…",
                options: [
                    "The command failed",
                    "You are running as the root (administrator) user",
                    "You are in a comment",
                    "The shell is bash, not zsh"
                ],
                correct: 1,
                why: "By convention `$` is an unprivileged user prompt and `#` is root. Seeing `#` means commands run with full administrative power — handle with care."),
            QuizQuestion(
                "What does the pipe character `|` do in `cat log.txt | grep error`?",
                options: [
                    "Runs the two commands at the same time independently",
                    "Sends the output of the first command as the input to the second",
                    "Saves the output to a file named grep",
                    "Comments out the second command"
                ],
                correct: 1,
                why: "A pipe connects commands: the left command's standard output becomes the right command's standard input. Here, every line of log.txt is filtered down to those containing 'error'."),
            QuizQuestion(
                "Which command would you use to locate every file named `config.php` under `/var/www`?",
                options: [
                    "grep -r config.php /var/www",
                    "find /var/www -name config.php",
                    "ls -la config.php",
                    "cat /var/www/config.php"
                ],
                correct: 1,
                why: "`find <path> -name <pattern>` walks a directory tree searching by filename. grep searches *inside* files for text; ls and cat only act on paths you already know.")
        ]
    )

    // MARK: F1 — Security mindset & ethics

    private static let mindset = Module(
        id: "fund-mindset",
        title: "Mindset & Ethics",
        summary: "What hacking actually is, who the players are, and the rules that keep you on the right side of the law.",
        systemImage: "brain.head.profile",
        lessons: [ethicsLesson, killChainLesson]
    )

    private static let ethicsLesson = Lesson(
        id: "fund-ethics",
        title: "Hacking, Ethically",
        subtitle: "The CIA triad, red vs blue, and the line you never cross.",
        minutes: 9,
        difficulty: .foundational,
        blocks: [
            .heading("What “hacking” actually means"),
            .paragraph("Strip away the hoodies and green text and hacking is one thing: understanding a system so deeply that you can make it do something its designers never intended. That skill is morally neutral. The same port scan runs in a criminal breach and in a sanctioned penetration test. What separates a felony from a paycheck is **authorization**."),
            .definition(term: "The CIA Triad", meaning: "The three properties security exists to protect — Confidentiality (only the right people can read data), Integrity (data isn't tampered with), and Availability (systems are up when needed). Every attack violates at least one; every defense protects them."),
            .heading("Red, blue, purple"),
            .keyPoints([
                "Red team — emulates real adversaries to find what's exploitable before criminals do.",
                "Blue team — builds detection and response so attacks are caught and contained.",
                "Purple team — red and blue working in the same room, each making the other sharper.",
                "This course teaches you to think as all three: you can't defend what you don't understand offensively, and vice-versa."
            ]),
            .callout(.danger, "Only ever test systems you own or have explicit, written permission to attack. In most countries unauthorized access is a serious crime (US Computer Fraud and Abuse Act, UK Computer Misuse Act, etc.). Skill is not a defense in court — authorization is."),
            .definition(term: "Rules of Engagement (RoE)", meaning: "The signed contract that defines a professional engagement: which IPs/domains are in scope, what techniques are allowed, time windows, and who to call if something breaks. Your get-out-of-jail document. No RoE, no testing."),
            .heading("Where to practice — legally"),
            .paragraph("Everything you learn here is meant for lab targets you're allowed to break: your own virtual machines, and intentionally-vulnerable platforms built for it. Build a lab once and you can practice every technique in this app safely."),
            .callout(.lab, "Minimum home lab: Kali Linux as your attack box, plus a deliberately-vulnerable target VM (e.g. Metasploitable, or rooms on Hack The Box / TryHackMe). Run them on an isolated host-only network so nothing leaks onto the real internet."),
            .checkpoint(QuizQuestion(
                "A friend asks you to “just check if their ex's Instagram is hackable.” You have the skills. What's the correct move?",
                options: [
                    "Do it quietly — it's a favour, not a crime",
                    "Decline; you have no authorization over that account or Instagram's systems",
                    "Only look, don't touch — read access is legal",
                    "Do it but don't save anything"
                ],
                correct: 1,
                why: "There is no scope, no owner consent, and no authorization. Accessing someone else's account is unauthorized access regardless of intent or how little you 'touch'. The skill being legal doesn't make the act legal."))
        ],
        quiz: [
            QuizQuestion(
                "Encrypting a hard drive primarily protects which property of the CIA triad?",
                options: ["Availability", "Integrity", "Confidentiality", "Authentication"],
                correct: 2,
                why: "Encryption stops unauthorized parties from reading the data — that's Confidentiality. Integrity is about tamper-detection; Availability is about uptime."),
            QuizQuestion(
                "A ransomware attack that encrypts files and demands payment most directly attacks…",
                options: ["Availability", "Confidentiality", "Non-repudiation", "Authorization"],
                correct: 0,
                why: "The victim can no longer access their own data, so Availability is hit hardest. (Modern ransomware often steals data too, adding a Confidentiality hit.)"),
            QuizQuestion(
                "What is the single document that authorizes a penetration test and defines its scope?",
                options: ["The exploit", "Rules of Engagement", "The NDA", "The vulnerability report"],
                correct: 1,
                why: "Rules of Engagement define scope, allowed techniques, timing and contacts. Without it, you have no legal authorization to test.")
        ]
    )

    private static let killChainLesson = Lesson(
        id: "fund-kill-chain",
        title: "How Attacks Actually Happen",
        subtitle: "The Cyber Kill Chain — the seven steps behind nearly every breach.",
        minutes: 11,
        difficulty: .foundational,
        blocks: [
            .heading("Attacks are a process, not a moment"),
            .paragraph("Movies show hacking as one furious burst of typing. Reality is a patient, repeatable process. Lockheed Martin's **Cyber Kill Chain** breaks that process into seven stages. Understanding it does two things at once: it gives red teamers a checklist, and it gives blue teamers seven separate chances to catch an intruder."),
            .animation(.cyberKillChain, caption: "Watch an intrusion advance through all seven stages — and see where defenders can break the chain."),
            .keyPoints([
                "Reconnaissance — research the target (people, tech, exposed services).",
                "Weaponization — pair an exploit with a payload (e.g. a malicious document).",
                "Delivery — get it to the victim (phishing email, USB, watering-hole site).",
                "Exploitation — the payload triggers and code runs.",
                "Installation — a foothold is made persistent (backdoor, scheduled task).",
                "Command & Control (C2) — the implant phones home for orders.",
                "Actions on Objectives — the actual goal: steal data, deploy ransomware, pivot."
            ]),
            .callout(.tip, "Defenders love this model because it's about breaking the chain. You don't have to stop every stage — interrupt any single link and the attack fails. Block the C2 callback and the foothold is deaf and useless."),
            .heading("Defense is cheaper earlier"),
            .paragraph("The further right an attacker gets, the more expensive they are to evict. Catching a phishing email (Delivery) is a click of a delete button. Catching them at Actions on Objectives means they already have your data. This is why blue teams invest so heavily in early-stage detection — email filtering, user training, and attack-surface reduction."),
            .definition(term: "MITRE ATT&CK", meaning: "A more granular, modern companion to the kill chain: a giant matrix of the specific Tactics (the 'why') and Techniques (the 'how') real adversaries use. You'll meet it properly in the Blue Team track."),
            .checkpoint(QuizQuestion(
                "A SOC analyst blocks the domain an implant is beaconing to. Which kill-chain stage did they disrupt?",
                options: ["Reconnaissance", "Delivery", "Command & Control", "Weaponization"],
                correct: 2,
                why: "Beaconing to an attacker-controlled domain is Command & Control. Cut it and the malware can't receive instructions or exfiltrate — the operator goes blind."))
        ],
        quiz: [
            QuizQuestion(
                "Crafting a malicious Word document that bundles an exploit with a reverse shell is which stage?",
                options: ["Delivery", "Weaponization", "Exploitation", "Installation"],
                correct: 1,
                why: "Pairing an exploit with a payload into a deliverable is Weaponization. Delivery is the act of sending it; Exploitation is when it runs."),
            QuizQuestion(
                "Why do defenders prefer to detect attacks as early in the kill chain as possible?",
                options: [
                    "Early stages are the only ones that are illegal",
                    "It's cheaper and less damaging to stop an attacker before they reach their objective",
                    "Late stages can't be detected at all",
                    "The kill chain only has early stages"
                ],
                correct: 1,
                why: "Cost and damage rise the further right an attacker gets. Stopping a phishing email is trivial; recovering from exfiltration or ransomware is not.")
        ]
    )

    // MARK: F2 — Networking for hackers

    private static let networking = Module(
        id: "fund-networking",
        title: "Networking for Hackers",
        summary: "How data really crosses a wire — the models, the handshake, and what's inside a packet you can attack.",
        systemImage: "network",
        lessons: [osiLesson, tcpLesson, packetLesson]
    )

    private static let osiLesson = Lesson(
        id: "fund-osi",
        title: "The OSI & TCP/IP Models",
        subtitle: "Seven layers that turn “send a message” into electrons on a wire.",
        minutes: 10,
        difficulty: .foundational,
        blocks: [
            .heading("Why layers?"),
            .paragraph("Networking is overwhelming until you slice it into layers, each handling one job and trusting the layer below it. The OSI model has seven; the TCP/IP model collapses them into four. Attackers care about layers because **every layer is its own attack surface** — you can poison ARP at layer 2, spoof IPs at layer 3, hijack TCP at layer 4, or inject SQL at layer 7."),
            .animation(.osiModel, caption: "Send a message down the stack and watch each layer wrap it in a new header — then unwrap on the far side."),
            .keyPoints([
                "L7 Application — HTTP, DNS, SSH. What humans and apps speak.",
                "L6 Presentation — encoding, encryption (TLS lives around here).",
                "L5 Session — setting up and tearing down conversations.",
                "L4 Transport — TCP/UDP, ports, reliability. (Port scanning lives here.)",
                "L3 Network — IP addresses and routing between networks.",
                "L2 Data Link — MAC addresses, switches, ARP. (LAN attacks live here.)",
                "L1 Physical — cables, radio, voltage. The literal bits."
            ]),
            .definition(term: "Encapsulation", meaning: "As your data goes down the stack, each layer adds its own header (and L2 adds a trailer). Your HTTP request becomes a TCP segment, inside an IP packet, inside an Ethernet frame. The receiver reverses it on the way up."),
            .callout(.tip, "A memory hook for L7→L1: “All People Seem To Need Data Processing.” It maps to Application, Presentation, Session, Transport, Network, Data link, Physical."),
            .paragraph("When you troubleshoot or attack, naming the layer focuses you instantly. “The site won't load” could be DNS (L7), a routing problem (L3), or a dead cable (L1) — and you test them in order."),
            .checkpoint(QuizQuestion(
                "ARP spoofing lets an attacker associate their MAC address with another host's IP on a LAN. Which layer is being abused?",
                options: ["Layer 2 (Data Link)", "Layer 3 (Network)", "Layer 4 (Transport)", "Layer 7 (Application)"],
                correct: 0,
                why: "ARP maps IP addresses to MAC addresses and operates at Layer 2, the Data Link layer. Poisoning that mapping is a classic L2 attack enabling man-in-the-middle."))
        ],
        quiz: [
            QuizQuestion(
                "At which layer do TCP and UDP — and therefore ports — operate?",
                options: ["Layer 2", "Layer 3", "Layer 4", "Layer 5"],
                correct: 2,
                why: "TCP and UDP are Transport-layer (Layer 4) protocols. Port numbers are a Layer 4 concept, which is why port scanning is a Layer 4 activity."),
            QuizQuestion(
                "An IP address identifies a host at which layer?",
                options: ["Layer 2 (Data Link)", "Layer 3 (Network)", "Layer 4 (Transport)", "Layer 7 (Application)"],
                correct: 1,
                why: "IP addressing and routing between networks is the job of Layer 3, the Network layer. MAC addresses (L2) are local; IP addresses (L3) are global.")
        ]
    )

    private static let tcpLesson = Lesson(
        id: "fund-tcp",
        title: "TCP, Ports & the 3-Way Handshake",
        subtitle: "How two machines agree to talk — and why scanners exploit that ritual.",
        minutes: 9,
        difficulty: .foundational,
        blocks: [
            .heading("Ports: a building with 65,535 doors"),
            .paragraph("An IP address gets you to the right machine; a **port** gets you to the right service on it. Web servers listen on 80/443, SSH on 22, RDP on 3389. There are 65,535 TCP ports. Reconnaissance is largely the art of knocking on each door to see which services answer."),
            .heading("The 3-way handshake"),
            .paragraph("TCP is reliable because both sides synchronize before sending data. That setup is the famous three-way handshake — SYN, SYN-ACK, ACK. It's also the mechanism a port scanner abuses: how a port *responds* to a SYN tells you whether it's open, closed, or filtered by a firewall."),
            .animation(.tcpHandshake, caption: "Client and server exchange SYN → SYN-ACK → ACK, then a port-scan probe reveals open vs closed vs filtered."),
            .terminal(prompt: "kali@lab",
                      command: "nmap -sS -p 22,80,443,3389 10.10.10.5",
                      output: """
PORT     STATE    SERVICE
22/tcp   open     ssh
80/tcp   open     http
443/tcp  closed   https
3389/tcp filtered ms-wbt-server
"""),
            .keyPoints([
                "open — a service is listening and completed the handshake.",
                "closed — host is up but nothing is listening (it sent a RST).",
                "filtered — a firewall ate the probe; you got no answer.",
                "A -sS 'SYN scan' sends SYN, reads the reply, then tears down before completing — fast and stealthier."
            ]),
            .definition(term: "RST (Reset)", meaning: "A TCP packet that immediately aborts a connection. A closed port answers a SYN with a RST — which is itself information: the host is alive, just not offering that service."),
            .callout(.warning, "“filtered” is the interesting one. It usually means a firewall is silently dropping packets. That tells you something is being protected — and that you may need a different path or port."),
            .checkpoint(QuizQuestion(
                "You SYN-scan a port and receive a RST back. What does that mean?",
                options: [
                    "The port is open",
                    "The port is closed but the host is alive",
                    "A firewall is dropping your packets",
                    "The host is offline"
                ],
                correct: 1,
                why: "A RST in response to a SYN means the host is reachable but no service is listening on that port — i.e. closed. Silence (no reply) is what usually indicates filtering."))
        ],
        quiz: [
            QuizQuestion(
                "What are the three messages of the TCP handshake, in order?",
                options: ["SYN → ACK → SYN-ACK", "SYN → SYN-ACK → ACK", "ACK → SYN → SYN-ACK", "SYN → RST → ACK"],
                correct: 1,
                why: "The initiator sends SYN, the server replies SYN-ACK, and the initiator confirms with ACK. Only then does data flow."),
            QuizQuestion(
                "Default port for SSH?",
                options: ["21", "22", "80", "3389"],
                correct: 1,
                why: "SSH listens on TCP 22 by default. 21 is FTP, 80 is HTTP, 3389 is RDP.")
        ]
    )

    private static let packetLesson = Lesson(
        id: "fund-packet",
        title: "Anatomy of a Packet",
        subtitle: "What's actually inside the data crossing the wire — and why sniffers see it.",
        minutes: 8,
        difficulty: .intermediate,
        blocks: [
            .heading("Headers all the way down"),
            .paragraph("A packet on the wire is a set of nested envelopes. Peel the Ethernet frame to find an IP packet; peel that to find a TCP segment; inside that sits your actual data — maybe an HTTP request in plain text. Tools like Wireshark and tcpdump let you read every layer."),
            .animation(.packetTravel, caption: "Inspect a single packet field by field — Ethernet, IP, TCP, then the payload."),
            .terminal(prompt: "kali@lab",
                      command: "sudo tcpdump -i eth0 -A 'tcp port 80'",
                      output: """
12:04:55.118 IP 10.10.10.8.51544 > 93.184.216.34.80: Flags [P.]
GET /login HTTP/1.1
Host: shop.example.com
Cookie: session=8f3b...   <-- plaintext over HTTP!
"""),
            .keyPoints([
                "Ethernet header — source & destination MAC (L2).",
                "IP header — source & destination IP, TTL (L3).",
                "TCP header — source & destination port, flags, sequence numbers (L4).",
                "Payload — the actual content (L7): an HTTP request, DNS query, etc."
            ]),
            .callout(.danger, "Anything sent over plain HTTP, FTP or Telnet travels as readable text. On a network you can sniff, that includes session cookies and passwords. This is the entire reason HTTPS/TLS exists — and why public Wi-Fi is dangerous."),
            .definition(term: "Promiscuous mode", meaning: "A network interface setting that captures all frames it sees, not just those addressed to it. Combined with a position on the network (e.g. via ARP spoofing), it's how attackers sniff other hosts' traffic."),
            .checkpoint(QuizQuestion(
                "You capture traffic and can read a victim's login password in clear text. What protocol were they almost certainly using?",
                options: ["HTTPS", "SSH", "HTTP", "TLS 1.3"],
                correct: 2,
                why: "HTTP sends everything in plaintext. HTTPS, SSH and TLS all encrypt the payload, so a sniffer would see only ciphertext."))
        ],
        quiz: [
            QuizQuestion(
                "Which header carries the source and destination port numbers?",
                options: ["Ethernet (L2)", "IP (L3)", "TCP (L4)", "HTTP (L7)"],
                correct: 2,
                why: "Ports live in the TCP (or UDP) header at Layer 4. IP carries addresses; Ethernet carries MACs."),
            QuizQuestion(
                "Why is sending credentials over Telnet dangerous on an untrusted network?",
                options: [
                    "Telnet is slow",
                    "Telnet transmits everything, including passwords, in plaintext",
                    "Telnet uses UDP",
                    "Telnet only works on Windows"
                ],
                correct: 1,
                why: "Telnet has no encryption — credentials cross the wire as readable text, trivially captured by any sniffer in path. SSH replaced it for exactly this reason.")
        ]
    )

    // MARK: F3 — Cryptography essentials

    // MARK: F-ENC — Data & encoding

    private static let encoding = Module(
        id: "fund-data",
        title: "Data & Encoding",
        summary: "Bits, bytes, hex and Base64 — how data is dressed up for transport, and why recognizing an encoding is a daily hacking skill.",
        systemImage: "number",
        lessons: [encodingLesson, stegoLesson]
    )

    private static let stegoLesson = Lesson(
        id: "fund-stego",
        title: "Steganography & Data Hiding",
        subtitle: "Encryption hides what a message says; steganography hides that there is a message at all.",
        minutes: 8,
        difficulty: .foundational,
        blocks: [
            .heading("Hiding in plain sight"),
            .paragraph("Cryptography makes data *unreadable*; **steganography** makes it *unnoticed*. A scrambled blob screams \"secret\" and invites scrutiny; a holiday photo does not. The two are complementary — encrypt first so the payload is meaningless even if found, then hide the ciphertext inside an innocent-looking carrier. Carriers are anything with spare, low-importance bits: images, audio, video, network packets, even whitespace in a text file."),
            .animation(.steganography, caption: "A reading head sweeps a cover image and peels the least-significant bit off each pixel — reassembling a hidden byte the eye never saw change."),
            .heading("The classic trick: least-significant bit (LSB)"),
            .paragraph("In a 24-bit image each pixel is three bytes (red, green, blue). Flipping the *last* bit of a byte changes its value by 1 out of 255 — a colour shift no human eye can detect. Overwrite those last bits with your secret, eight pixels per character, and a photo silently carries a whole document. Extraction is just reading those same bits back."),
            .terminal(prompt: "kali@lab",
                      command: "steghide embed -cf cat.jpg -ef secret.txt -p hunter2\nsteghide extract -sf cat.jpg -p hunter2",
                      output: """
embedding "secret.txt" in "cat.jpg"... done
...
wrote extracted data to "secret.txt".
"""),
            .keyPoints([
                "Carrier (cover) — the innocent file the data hides in: image, audio, PDF, packet.",
                "Payload — the secret being hidden (ideally already encrypted).",
                "LSB encoding — overwrite the lowest bit of each byte; invisible to perception.",
                "Capacity vs detectability — the more you hide, the more statistical noise you add.",
                "Tools — steghide, zsteg, binwalk, exiftool, stegsolve, OpenStego."
            ]),
            .definition(term: "Steganalysis", meaning: "The blue-team counterpart: detecting hidden data by spotting statistical anomalies (e.g. unusually uniform LSBs), file-size mismatches, or appended data after a file's logical end (`binwalk`, chi-square tests)."),
            .callout(.tip, "On CTFs, steganography is everywhere. Reflex checklist for any media file: run `file`, `exiftool`, `strings`, `binwalk`, and `zsteg`/`steghide` before anything else — the flag is often appended after the image data or sitting in the metadata."),
            .callout(.warning, "Steganography hides existence, not meaning. If the carrier is found and the method is known, the payload is recovered. Real operations encrypt the payload first — so finding it still yields nothing."),
            .checkpoint(QuizQuestion(
                "What is the core difference between encryption and steganography?",
                options: [
                    "Encryption is faster",
                    "Encryption hides the meaning of a message; steganography hides its existence",
                    "They are the same thing",
                    "Steganography always uses a key and encryption never does"
                ],
                correct: 1,
                why: "Encryption makes a message unreadable but obvious; steganography conceals that a message is present at all. They're often layered: encrypt, then hide."))
        ],
        quiz: [
            QuizQuestion(
                "Why does flipping the least-significant bit of an image's pixels go unnoticed?",
                options: [
                    "Because images ignore the last bit",
                    "Because it changes each colour value by at most 1/255 — below human perception",
                    "Because the bits are encrypted",
                    "Because JPEG deletes them"
                ],
                correct: 1,
                why: "The LSB carries the least weight, so altering it shifts a colour channel by a single step out of 256 — imperceptible to the eye while still encoding usable data."),
            QuizQuestion(
                "You're given a suspicious PNG in a CTF. The single best first move is to…",
                options: [
                    "Open it and look harder",
                    "Run tooling like strings, exiftool and binwalk to surface hidden or appended data",
                    "Re-encrypt it",
                    "Delete the metadata"
                ],
                correct: 1,
                why: "Hidden flags are routinely tucked in metadata or appended after the image data. strings/exiftool/binwalk reveal those instantly — far faster than eyeballing pixels.")
        ]
    )

    private static let encodingLesson = Lesson(
        id: "fund-encoding",
        title: "Bytes, Hex, Base64 & Encoding",
        subtitle: "Spot and reverse the costumes data wears — and never confuse encoding with encryption.",
        minutes: 9,
        difficulty: .foundational,
        blocks: [
            .heading("Everything is bytes"),
            .paragraph("Underneath every password, packet and token is the same thing: **bytes** — numbers from 0 to 255. A character like `H` is just the byte `72`. We rarely look at raw bytes, though; we dress them in more readable *encodings*. Reading those costumes — and knowing they're costumes, not locks — is a skill you'll use in almost every challenge and engagement."),
            .animation(.encodingLayers, caption: "Watch the message `Hi!` re-dressed as hex, then Base64, then URL encoding — every layer fully reversible."),
            .heading("Hex: bytes for humans"),
            .paragraph("Each byte is eight bits, which is exactly two **hexadecimal** digits (base-16, `0`–`9` then `a`–`f`). So one byte = two hex characters. `H` (72 in decimal) is `0x48`. Hex is everywhere — memory dumps, hashes, MAC addresses, packet captures — because it maps so cleanly onto bytes."),
            .terminal(prompt: "kali@lab",
                      command: "echo -n 'Hi!' | xxd",
                      output: """
00000000: 4869 21                                  Hi!
# 48=H  69=i  21=!   — three bytes, six hex digits
"""),
            .heading("Base64: binary that survives text channels"),
            .paragraph("Email headers, JSON, cookies and JWTs can only carry text safely. **Base64** packs arbitrary bytes into 64 printable characters (`A–Z a–z 0–9 + /`), three bytes becoming four characters — that's the `=` padding you see trailing tokens. It is *not* secret: anyone can decode it instantly."),
            .terminal(prompt: "kali@lab",
                      command: "echo -n 'Hi!' | base64   # SGkh\necho 'SGkh' | base64 -d   # Hi!",
                      output: """
SGkh
Hi!
# round-trips perfectly — no key involved
"""),
            .keyPoints([
                "Bit → byte (8 bits) → hex (2 digits/byte) → Base64 (4 chars/3 bytes).",
                "URL/percent encoding escapes unsafe characters: space→%20, !→%21.",
                "Recognize Base64 by its charset and trailing `=`; hex by `0-9a-f` pairs.",
                "`xxd`, `base64 -d`, CyberChef and `urldecode` flip them back in seconds.",
                "Encodings stack — a token may be URL-encoded Base64 of JSON. Peel one layer at a time."
            ]),
            .callout(.warning, "Encoding is **not** encryption. Base64 and hex hide nothing — they're reversible with no key. Treating an encoded secret as 'protected' is a classic, dangerous mistake you'll find on real targets."),
            .definition(term: "Encoding vs encryption", meaning: "Encoding is a reversible re-representation of data for transport or display, with no secret involved (hex, Base64, URL). Encryption transforms data using a key so only key-holders can reverse it. If there's no key, it's encoding — and offers no confidentiality."),
            .callout(.tip, "When a value looks like gibberish, guess the encoding before assuming crypto. A string of `a-f0-9` is probably hex; one ending in `=` is probably Base64; `%`-sprinkled text is URL-encoded. Decoding it often reveals the next clue for free."),
            .checkpoint(QuizQuestion(
                "You find the cookie value `YWRtaW4=` in a request. What's the right first move?",
                options: [
                    "Try to brute-force the encryption key",
                    "Base64-decode it — the trailing `=` suggests encoding, not encryption",
                    "Report it as a buffer overflow",
                    "Ignore it; cookies are always random"
                ],
                correct: 1,
                why: "The trailing `=` and printable charset scream Base64. Decoding `YWRtaW4=` yields `admin` — no key needed. Encoded values are reversible representations, not protected secrets."))
        ],
        quiz: [
            QuizQuestion(
                "How many hexadecimal digits represent a single byte?",
                options: ["One", "Two", "Four", "Eight"],
                correct: 1,
                why: "A byte is 8 bits; each hex digit encodes 4 bits, so two hex digits represent one byte (e.g. `H` = `0x48`)."),
            QuizQuestion(
                "What is the main reason data is Base64-encoded?",
                options: [
                    "To encrypt it so attackers can't read it",
                    "To safely carry arbitrary bytes through text-only channels like JSON, cookies and email",
                    "To compress it smaller",
                    "To hash it irreversibly"
                ],
                correct: 1,
                why: "Base64 represents binary data using printable ASCII so it survives text-only transports. It adds no secrecy and actually grows the data by ~33%."),
            QuizQuestion(
                "A URL parameter contains `%2e%2e%2f`. Decoded, that is…",
                options: ["admin", "../", "a hash", "a NOP sled"],
                correct: 1,
                why: "Percent-encoding maps %2e→`.` and %2f→`/`, so `%2e%2e%2f` is `../` — exactly the path-traversal sequence, smuggled past naive filters by URL-encoding it.")
        ]
    )

    private static let crypto = Module(
        id: "fund-crypto",
        title: "Cryptography Essentials",
        summary: "Symmetric vs public-key encryption, and why hashing is what stands between a database leak and your password.",
        systemImage: "lock.shield",
        lessons: [encryptionLesson, blockModesLesson, hashingLesson, pkiLesson]
    )

    private static let encryptionLesson = Lesson(
        id: "fund-encryption",
        title: "Symmetric & Public-Key Encryption",
        subtitle: "One shared secret vs a key everyone can see — and why we need both.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("Symmetric: one key locks and unlocks"),
            .paragraph("In symmetric encryption the same key both encrypts and decrypts. It's fast and used for the heavy lifting — AES protects disks, files and the bulk of every TLS session. The catch is distribution: how do you get the shared key to the other side without an eavesdropper grabbing it?"),
            .animation(.symmetricEncryption, caption: "Plaintext + key → ciphertext → plaintext. Change one bit of the key and the output is garbage."),
            .heading("Public-key: solving the key-sharing problem"),
            .paragraph("Asymmetric (public-key) cryptography gives everyone a **key pair**: a public key you hand out freely and a private key you never share. Anything encrypted with the public key can only be decrypted by the matching private key. Now two strangers can establish a shared secret over an open network — which is exactly what happens at the start of every HTTPS connection."),
            .animation(.publicKeyExchange, caption: "Alice locks a message with Bob's public key; only Bob's private key opens it — even though everyone saw the public key."),
            .keyPoints([
                "Symmetric (AES) — fast, one shared key, great for bulk data.",
                "Asymmetric (RSA, ECC) — slow, key pair, solves key exchange and enables signatures.",
                "TLS uses both: asymmetric to agree on a key, then symmetric for the actual traffic.",
                "Reverse the keys and you get digital signatures: sign with your private key, anyone verifies with your public key."
            ]),
            .definition(term: "Digital signature", meaning: "Encrypt a hash of a message with your private key. Anyone can decrypt it with your public key and confirm both that it came from you and that it wasn't altered — providing authenticity and integrity."),
            .callout(.tip, "Rule of thumb: public key for confidentiality others send to you, private key for proving identity. The padlock in your browser is this dance happening in milliseconds."),
            .checkpoint(QuizQuestion(
                "You want people to send you encrypted messages only you can read. Which key do you publish?",
                options: ["Your private key", "Your public key", "Your symmetric key", "Both keys"],
                correct: 1,
                why: "Publish your public key. Others encrypt with it; only your matching private key can decrypt. Never share the private key."))
        ],
        quiz: [
            QuizQuestion(
                "Why does TLS use asymmetric crypto only at the start, then switch to symmetric?",
                options: [
                    "Asymmetric is insecure for long sessions",
                    "Symmetric is much faster, so it's used for bulk data after the key is safely exchanged",
                    "Browsers don't support asymmetric crypto",
                    "Symmetric crypto can't be intercepted"
                ],
                correct: 1,
                why: "Asymmetric solves the key-exchange problem but is computationally expensive. Once a shared symmetric key is agreed, the fast symmetric cipher handles the actual data."),
            QuizQuestion(
                "A digital signature is created by encrypting a message's hash with the sender's…",
                options: ["public key", "private key", "shared AES key", "session cookie"],
                correct: 1,
                why: "Signing uses the private key; verification uses the public key. This proves the message came from the holder of the private key and wasn't modified.")
        ]
    )

    private static let blockModesLesson = Lesson(
        id: "fund-block-modes",
        title: "Block Cipher Modes & Their Pitfalls",
        subtitle: "AES encrypts one block at a time — how you chain those blocks decides whether your secret stays secret.",
        minutes: 9,
        difficulty: .advanced,
        blocks: [
            .heading("A block cipher only encrypts one block"),
            .paragraph("AES doesn't encrypt a whole message — it encrypts a single fixed-size **block** (16 bytes) at a time. To protect anything longer, you apply it repeatedly under a **mode of operation**, and the mode you pick matters enormously. The same key and the same AES can be secure or catastrophically broken depending on how the blocks are chained."),
            .heading("ECB: the mode that leaks"),
            .paragraph("The naive mode, **ECB** (Electronic Codebook), encrypts each block completely independently. That means **identical plaintext blocks produce identical ciphertext blocks** — so the structure of the data survives encryption. Encrypt a bitmap of a penguin under ECB and you can still see the penguin in the ciphertext. ECB hides values but not *patterns*, which is why it must never be used for real data."),
            .animation(.blockCipherModes, caption: "A patterned plaintext encrypted under ECB keeps its shape — identical blocks map to identical output — while CBC/GCM scramble it into noise."),
            .heading("CBC, and why we add randomness"),
            .paragraph("Better modes break that pattern by mixing each block with the previous one (or a counter) plus a random **IV** (initialization vector), so encrypting the same plaintext twice yields different ciphertext. **CBC** chains blocks together; modern **AEAD** modes like **GCM** go further and add built-in *authentication* so tampering is detected. The lesson: encryption needs the right mode *and* integrity, not just a strong cipher."),
            .keyPoints([
                "A block cipher (AES) encrypts fixed-size blocks; a mode applies it across a message.",
                "ECB encrypts blocks independently → identical blocks leak as identical ciphertext (patterns survive).",
                "CBC chains blocks with an IV so repetition is hidden — but it provides no integrity by itself.",
                "GCM (AEAD) gives confidentiality AND authentication — the modern default.",
                "A unique, unpredictable IV/nonce per message is essential; reusing one breaks the guarantees."
            ]),
            .definition(term: "Mode of operation", meaning: "The scheme that applies a block cipher (like AES) repeatedly to encrypt data longer than one block. ECB is insecure because it leaks patterns; CBC chains blocks with an IV; GCM adds authentication. The cipher can be strong while the mode makes the system weak."),
            .callout(.danger, "ECB is a real-world finding, not a museum piece: developers reach for the 'default' AES call and get ECB, then encrypted-but-patterned data (database fields, tokens, images) leaks structure an attacker can exploit. Seeing repeating ciphertext blocks is a tell."),
            .callout(.tip, "Modern guidance: use an authenticated mode (AES-GCM or ChaCha20-Poly1305) with a unique nonce per message, via a vetted library — never hand-roll crypto, and never select ECB."),
            .checkpoint(QuizQuestion(
                "Why can you still 'see' a simple image after encrypting it with AES in ECB mode?",
                options: [
                    "AES is a weak cipher",
                    "ECB encrypts each block independently, so identical plaintext blocks become identical ciphertext blocks — the pattern is preserved",
                    "The image wasn't really encrypted",
                    "The key was too short"
                ],
                correct: 1,
                why: "ECB lacks chaining, so repeated input blocks map to repeated output blocks. The pixel patterns (large areas of one colour) repeat identically in the ciphertext, leaving the image's structure visible despite strong AES."))
        ],
        quiz: [
            QuizQuestion(
                "What is the core weakness of ECB mode?",
                options: [
                    "It's too slow",
                    "Identical plaintext blocks encrypt to identical ciphertext blocks, leaking the data's structure",
                    "It can't use AES",
                    "It requires two keys"
                ],
                correct: 1,
                why: "Because ECB encrypts each block independently with no chaining or IV, repetition in the plaintext shows up as repetition in the ciphertext — patterns survive encryption."),
            QuizQuestion(
                "Which mode provides both confidentiality and built-in integrity/authentication?",
                options: ["ECB", "CBC", "AES-GCM (AEAD)", "Plain AES"],
                correct: 2,
                why: "GCM is an authenticated (AEAD) mode: it encrypts and produces an authentication tag, so tampering is detected. ECB leaks patterns and CBC alone offers no integrity.")
        ]
    )

    private static let hashingLesson = Lesson(
        id: "fund-hashing",
        title: "Hashing, Salting & Leaked Passwords",
        subtitle: "Why a good hash is a one-way street — and how attackers still win.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("A hash is a one-way fingerprint"),
            .paragraph("A cryptographic hash (SHA-256, bcrypt…) turns any input into a fixed-size fingerprint. It's deterministic (same input → same hash) but irreversible (you can't run it backwards). That's why servers store the *hash* of your password, not the password itself — a leak of the database shouldn't reveal what you typed."),
            .animation(.hashing, caption: "Feed inputs through a hash function: tiny changes produce wildly different digests, and you can't run the arrows backwards."),
            .terminal(prompt: "kali@lab",
                      command: "echo -n 'password123' | sha256sum",
                      output: """
ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f  -
"""),
            .heading("So why do passwords still leak?"),
            .paragraph("Because humans reuse weak passwords and attackers don't reverse the hash — they *guess*. They hash millions of candidate passwords and compare. Worse, identical passwords produce identical hashes, so attackers precompute giant lookup tables (rainbow tables). The defense is a **salt**: a unique random value mixed into each password before hashing, so the same password yields a different hash for every user — killing precomputation."),
            .keyPoints([
                "Salt — unique random data per user; defeats rainbow tables and reveals nothing if two users share a password.",
                "Slow hashes — bcrypt, scrypt, Argon2 are deliberately expensive, so guessing is painfully slow.",
                "Never use fast hashes (MD5, SHA-1, raw SHA-256) for passwords — they let attackers try billions/sec on a GPU.",
                "Pepper — an extra secret stored separately from the database for defense in depth."
            ]),
            .callout(.danger, "MD5 and SHA-1 are cryptographically broken for collision resistance and far too fast for password storage. Finding them protecting passwords in a real app is an immediate, high-severity finding."),
            .definition(term: "Rainbow table", meaning: "A precomputed table mapping hashes back to their plaintext, trading disk space for cracking speed. A per-user salt makes them useless because every hash would need its own table."),
            .checkpoint(QuizQuestion(
                "Two users both choose the password “summer2024”. With proper per-user salting, their stored hashes will be…",
                options: [
                    "Identical, which is fine",
                    "Different, because each has a unique salt",
                    "Identical, which is a vulnerability",
                    "Impossible to store"
                ],
                correct: 1,
                why: "A unique salt per user means the same password hashes to different values, so an attacker can't tell the passwords match or reuse precomputed tables."))
        ],
        quiz: [
            QuizQuestion(
                "Why are bcrypt and Argon2 preferred over SHA-256 for storing passwords?",
                options: [
                    "They produce shorter hashes",
                    "They are deliberately slow and memory-hard, making mass guessing impractical",
                    "They are reversible when needed",
                    "They don't need a salt"
                ],
                correct: 1,
                why: "Password hashes should be slow. bcrypt/scrypt/Argon2 add work factors (and memory cost) so an attacker can only try a handful of guesses per second instead of billions."),
            QuizQuestion(
                "What is the primary purpose of a salt?",
                options: [
                    "To encrypt the password",
                    "To make the hash reversible",
                    "To ensure identical passwords hash differently and defeat precomputed tables",
                    "To speed up hashing"
                ],
                correct: 2,
                why: "A unique per-user salt guarantees identical passwords produce different hashes and renders rainbow tables useless. It doesn't encrypt or reverse anything.")
        ]
    )

    // MARK: F4 — Web foundations

    private static let web = Module(
        id: "fund-web",
        title: "How the Web Works",
        summary: "HTTP, cookies and sessions — plus the TLS handshake that turns plain HTTP into the padlock — the machinery every web attack builds on.",
        systemImage: "globe",
        lessons: [webBasicsLesson, tlsLesson]
    )

    private static let webBasicsLesson = Lesson(
        id: "fund-web-basics",
        title: "HTTP, Cookies & Sessions",
        subtitle: "The request/response cycle — and how a stateless protocol still remembers who you are.",
        minutes: 11,
        difficulty: .intermediate,
        blocks: [
            .heading("Everything is a request and a response"),
            .paragraph("The web runs on HTTP: your browser sends a **request** (a method, a path, some headers, maybe a body) and the server sends back a **response** (a status code, headers, and content). That's the entire conversation. Every web attack you'll learn — SQL injection, XSS, IDOR, SSRF — is just a crafted request that makes the server do something it shouldn't. Reading raw HTTP is the single most useful web-hacking skill."),
            .animation(.httpRequest, caption: "A browser requests /login, the server replies and sets a cookie, then the browser proves who it is on the next request."),
            .keyPoints([
                "Methods — GET (read), POST (submit), PUT/PATCH (update), DELETE (remove).",
                "Status codes — 200 OK, 301/302 redirect, 401/403 auth/forbidden, 404 missing, 500 server error.",
                "Headers — metadata: Host, Cookie, Authorization, Content-Type, User-Agent.",
                "Body — the payload (form fields, JSON) on POST/PUT requests.",
                "An intercepting proxy (Burp Suite, OWASP ZAP) lets you pause and rewrite every request — your primary web-testing tool."
            ]),
            .terminal(prompt: "kali@lab",
                      command: "curl -v https://shop.lab/login -d 'user=alice&pass=hunter2'",
                      output: """
> POST /login HTTP/1.1
> Host: shop.lab
> Content-Type: application/x-www-form-urlencoded
< HTTP/1.1 302 Found
< Set-Cookie: session=8f3b1c..; HttpOnly; Secure; SameSite=Lax
< Location: /account
"""),
            .definition(term: "HTTP is stateless", meaning: "Each request stands alone — the server doesn't inherently remember your last one. To create a logged-in 'session', the server issues a cookie the browser sends back on every subsequent request. That cookie is your identity."),
            .heading("Cookies & sessions — how the web remembers you"),
            .paragraph("After you log in, the server replies with `Set-Cookie: session=…`. Your browser stores it and automatically attaches it to every future request to that site. The server looks up that random session ID to know you're Alice. This is why **stealing the session cookie is as good as stealing the password** — it *is* the logged-in session."),
            .callout(.danger, "Three cookie flags are your defense: HttpOnly (JavaScript can't read it, blunting XSS theft), Secure (only sent over HTTPS), and SameSite (not sent on cross-site requests, blunting CSRF). A session cookie missing HttpOnly is a finding."),
            .definition(term: "Same-Origin Policy (SOP)", meaning: "The browser rule that script from one origin (scheme + host + port) can't read responses from another. It's what stops evil.com's JavaScript from reading your bank's pages — and the boundary that CORS, XSS and CSRF all revolve around."),
            .callout(.tip, "Learn to read a request like a sentence. 'GET /invoice?id=1042 with cookie session=… ' tells you the action (read), the object (invoice 1042), and the identity (the session). Web bugs live in the gap between what you're allowed to do and what the request lets you ask for."),
            .checkpoint(QuizQuestion(
                "An attacker steals a victim's `session` cookie via XSS. What can they do with it?",
                options: [
                    "Nothing — they still need the password",
                    "Replay it to the site and act as the logged-in victim",
                    "Only read the victim's email address",
                    "Decrypt the victim's HTTPS traffic"
                ],
                correct: 1,
                why: "The session cookie *is* the authenticated session. Replaying it makes the server treat the attacker as the victim — no password needed. HttpOnly exists precisely to stop script from reading it."))
        ],
        quiz: [
            QuizQuestion(
                "Why does a web app need cookies at all if it has user accounts?",
                options: [
                    "To make pages load faster",
                    "Because HTTP is stateless — the cookie carries the session identity across separate requests",
                    "To encrypt the connection",
                    "Cookies are only for advertising"
                ],
                correct: 1,
                why: "HTTP doesn't remember prior requests. The session cookie is what lets the server tie many independent requests to one logged-in user."),
            QuizQuestion(
                "Which HTTP status code tells you a resource exists but you're not allowed to access it?",
                options: ["200 OK", "301 Moved", "403 Forbidden", "500 Server Error"],
                correct: 2,
                why: "403 Forbidden means authenticated-but-unauthorized (or blocked). 401 is unauthenticated; 404 hides existence; 500 is a server fault."),
            QuizQuestion(
                "What does an intercepting proxy like Burp Suite let you do?",
                options: [
                    "Crack password hashes",
                    "Pause, inspect and rewrite every HTTP request and response before it's sent",
                    "Scan ports faster",
                    "Encrypt your traffic"
                ],
                correct: 1,
                why: "An intercepting proxy sits between browser and server so you can tamper with any request — the core workflow for finding and exploiting web vulnerabilities.")
        ]
    )

    private static let tlsLesson = Lesson(
        id: "fund-tls",
        title: "How HTTPS Works: TLS",
        subtitle: "The handshake that turns plaintext HTTP into the padlock — and why the lock means private, not safe.",
        minutes: 12,
        difficulty: .intermediate,
        blocks: [
            .heading("The padlock is a handshake"),
            .paragraph("HTTP sends everything in the clear — anyone on the path can read or rewrite it. **HTTPS is just HTTP carried inside TLS** (Transport Layer Security), the protocol behind the browser padlock. Before any page loads, the client and server run a short negotiation — the **handshake** — that agrees a shared secret key and proves the server's identity. After that, every byte is encrypted and tamper-evident."),
            .animation(.tlsHandshake, caption: "ClientHello and ServerHello each carry a key share, so TLS 1.3 derives a shared secret in a single round trip — then encrypts the certificate and everything after it."),
            .heading("What the handshake achieves"),
            .paragraph("TLS gives you three guarantees at once. It's worth separating them, because each defeats a different attack and each can fail independently."),
            .keyPoints([
                "Confidentiality — a key agreed via ephemeral Diffie-Hellman (ECDHE) encrypts the traffic, so an eavesdropper sees only ciphertext.",
                "Integrity — every record carries an authentication tag (AEAD), so flipping a bit in transit is detected and rejected.",
                "Authenticity — the server presents a certificate signed by a CA your device trusts, proving you're really talking to the named host.",
                "Forward secrecy — because the DH key is ephemeral, stealing the server's private key later still can't decrypt yesterday's recorded traffic."
            ]),
            .definition(term: "Cipher suite", meaning: "The agreed bundle of algorithms for a connection — key exchange, the bulk cipher (e.g. AES-GCM or ChaCha20-Poly1305) and the hash. TLS 1.3 pruned the list to only modern, safe suites, which is a big part of why it's faster and harder to misconfigure."),
            .terminal(prompt: "kali@lab",
                      command: "openssl s_client -connect shop.lab:443 -tls1_3 </dev/null 2>/dev/null | grep -E 'Protocol|Cipher|verify'",
                      output: """
verify return:1
Protocol  : TLSv1.3
Cipher    : TLS_AES_256_GCM_SHA384
"""),
            .heading("Identity rests on the certificate chain"),
            .paragraph("Encryption alone is worthless if you've encrypted a channel to an attacker. That's what the **certificate** prevents: the server proves it owns the name by presenting a chain that links its leaf certificate up to a **root CA** already in your device's trust store. Break or skip that check and TLS gives you a beautifully encrypted line to the wrong party."),
            .animation(.certChain, caption: "The leaf certificate is signed by an intermediate, signed by a root the browser already trusts — validated link by link up to that anchor."),
            .callout(.warning, "The padlock means *private*, not *safe*. A phishing site at paypa1-login.com can get a perfectly valid certificate for its own name — the lock just proves the channel is encrypted to whoever owns that domain. Always read the actual hostname, not the icon."),
            .callout(.danger, "An adversary-in-the-middle proxy (Evilginx, mitmproxy) terminates TLS at the attacker and opens a fresh TLS connection onward — so the victim still sees a valid padlock. The defence isn't TLS, it's certificate/origin binding: HSTS, certificate pinning and phishing-resistant FIDO2 keys."),
            .callout(.tip, "TLS 1.3 dropped the older 2-round-trip handshake, RSA key transport (no forward secrecy) and all the legacy ciphers behind attacks like BEAST and POODLE. If you ever see TLS 1.0/1.1 or RC4 in a scan, that's a finding — recommend TLS 1.2+ with AEAD suites."),
            .checkpoint(QuizQuestion(
                "A user reaches a phishing page and the browser shows a valid padlock. What does that padlock actually prove?",
                options: [
                    "The site is legitimate and safe to trust",
                    "The connection is encrypted to whoever owns that exact domain — nothing about their honesty",
                    "The server has no vulnerabilities",
                    "The user's antivirus has scanned the page"
                ],
                correct: 1,
                why: "TLS proves confidentiality, integrity and that you're talking to the holder of *that* certificate's name. An attacker can obtain a valid cert for their own look-alike domain, so the lock says 'private', never 'trustworthy'."))
        ],
        quiz: [
            QuizQuestion(
                "What is the main thing the TLS handshake produces before encrypted data flows?",
                options: [
                    "A compressed copy of the web page",
                    "A shared secret key (and a verified server identity)",
                    "A new IP address for the server",
                    "A username and password"
                ],
                correct: 1,
                why: "The handshake's job is to agree a symmetric key (via ECDHE) and authenticate the server with its certificate. Only then does encrypted application data begin."),
            QuizQuestion(
                "Why does TLS 1.3 with ephemeral Diffie-Hellman give 'forward secrecy'?",
                options: [
                    "It never stores any keys",
                    "Each session's key is temporary, so stealing the server's long-term private key can't decrypt past recorded sessions",
                    "It uses a longer password",
                    "It changes the server's IP each session"
                ],
                correct: 1,
                why: "Ephemeral DH generates a throwaway key per session that isn't derivable from the server's long-term key. So a future key compromise can't retroactively decrypt traffic an attacker recorded earlier."),
            QuizQuestion(
                "During a test you find a server still offering TLS 1.0 and RC4. What's the right call?",
                options: [
                    "Ignore it — any TLS is fine",
                    "Flag it: legacy protocol/cipher with known attacks; recommend TLS 1.2+ and AEAD suites",
                    "Recommend turning encryption off for speed",
                    "It only matters for email servers"
                ],
                correct: 1,
                why: "TLS 1.0/1.1 and RC4 are deprecated and carry known weaknesses (BEAST, POODLE, RC4 biases). Supporting them weakens every client, so it's a legitimate finding with a clear remediation.")
        ]
    )

    // MARK: F5 — Windows & Active Directory

    private static let windows = Module(
        id: "fund-windows",
        title: "Windows & Active Directory",
        summary: "How enterprise Windows networks are structured — the domain model every AD attack in the Red Team track exploits.",
        systemImage: "building.2.fill",
        lessons: [adBasicsLesson]
    )

    private static let adBasicsLesson = Lesson(
        id: "fund-ad-basics",
        title: "Active Directory Foundations",
        subtitle: "Domains, the DC, and how Kerberos logs you in — the map for every enterprise attack.",
        minutes: 12,
        difficulty: .intermediate,
        blocks: [
            .heading("Why almost every enterprise runs Active Directory"),
            .paragraph("Walk into any large company and the Windows machines are almost certainly joined to an **Active Directory (AD)** domain. AD is a central directory of every user, computer and group, plus the rules binding them. One login works everywhere, and admins manage thousands of machines from one place. That centralization is also exactly why AD is the prize in nearly every internal penetration test: compromise the domain, and you compromise everything in it."),
            .animation(.adForest, caption: "A domain nests inside a forest, organized into OUs — and the Domain Controller at the centre stores every account's secrets."),
            .keyPoints([
                "Domain — a boundary of users, computers and groups under one authority (e.g. corp.local).",
                "Domain Controller (DC) — the server running AD; it authenticates logons and holds the NTDS.dit database of every password hash.",
                "Forest — one or more domains sharing trust; the true security boundary.",
                "OU (Organizational Unit) — a folder for grouping objects and applying Group Policy.",
                "Domain Admins — the god-mode group; owning it owns the domain."
            ]),
            .definition(term: "NTDS.dit", meaning: "The database on every Domain Controller holding all domain accounts and their password hashes (including krbtgt). Extracting it — physically or via DCSync — yields the keys to the entire domain. It is the crown jewel."),
            .heading("How Kerberos logs you in"),
            .paragraph("Modern AD authenticates with **Kerberos**, a ticket system. When you log on, the DC (acting as the Key Distribution Center) issues you a **Ticket Granting Ticket (TGT)**. To use a service — a file share, a database — you exchange the TGT for a **service ticket (TGS)** for that specific service. You never resend your password; you present tickets. This elegant design is also what AS-REP Roasting, Kerberoasting and Golden Tickets all abuse."),
            .terminal(prompt: "PS C:\\>",
                      command: "whoami /groups; nltest /dsgetdc:corp.local",
                      output: """
GROUP INFORMATION
  CORP\\Domain Users        Group
  CORP\\IT-Support          Group
DC: \\\\DC01.corp.local
Address: 10.10.10.10        <-- the Domain Controller
"""),
            .definition(term: "Kerberos TGT vs TGS", meaning: "The TGT proves who you are (issued at logon); a TGS grants access to one specific service. You trade your TGT to the DC for whatever service tickets you need — without ever re-entering your password."),
            .callout(.tip, "Enumeration is the whole game in AD too. With one low-privileged domain account you can list every user, group, computer and trust — feeding tools like BloodHound that map the hidden paths from your account to Domain Admin."),
            .callout(.warning, "AD security is about relationships, not just passwords. A normal user with the right to reset another user's password, or admin rights over the wrong machine, can be a direct stepping stone to the entire domain — even with everything 'patched'."),
            .checkpoint(QuizQuestion(
                "Why is the Domain Controller such a high-value target?",
                options: [
                    "It's the fastest server",
                    "It authenticates logons and stores every account's password hash in NTDS.dit",
                    "It hosts the company website",
                    "It's the only machine with internet access"
                ],
                correct: 1,
                why: "The DC is the authority for the whole domain and holds NTDS.dit — every hash, including krbtgt. Control it and you can authenticate as anyone in the domain."))
        ],
        quiz: [
            QuizQuestion(
                "In Kerberos, what does a Ticket Granting Ticket (TGT) prove?",
                options: [
                    "That you are an administrator",
                    "Your identity — it's issued at logon and exchanged for service tickets",
                    "That a service is online",
                    "That your password is strong"
                ],
                correct: 1,
                why: "The TGT establishes who you are after logon. You present it to the DC to obtain service tickets (TGS) without resending your password."),
            QuizQuestion(
                "What is the security boundary in Active Directory?",
                options: ["A single user", "An OU", "The forest", "A single computer"],
                correct: 2,
                why: "The forest — not the domain — is AD's true security boundary. Trusts within a forest mean compromising one domain can often lead to others."),
            QuizQuestion(
                "Owning which group is effectively game over for a domain?",
                options: ["Domain Users", "Remote Desktop Users", "Domain Admins", "Authenticated Users"],
                correct: 2,
                why: "Domain Admins have full control over the domain. Reaching that group (or the DC itself) is the standard objective of an internal engagement.")
        ]
    )

    // MARK: F-OS — How programs run

    private static let os = Module(
        id: "fund-os",
        title: "How Programs Run",
        summary: "What actually happens when a program runs — processes, the way memory is laid out, and the user/kernel boundary that all of security sits on top of.",
        systemImage: "cpu",
        lessons: [processesLesson]
    )

    private static let processesLesson = Lesson(
        id: "fund-processes",
        title: "Processes, Memory & the OS",
        subtitle: "The model under every exploit and privilege escalation: how code, memory and privilege fit together.",
        minutes: 11,
        difficulty: .intermediate,
        blocks: [
            .heading("A program becomes a process"),
            .paragraph("A **program** is a file on disk; a **process** is that program brought to life — loaded into memory and executing. The operating system gives each process the illusion that it owns the whole machine: its own private memory, its own slice of CPU time. That illusion, called **virtual memory**, is also a security boundary: one process can't simply reach into another's memory and read its secrets."),
            .definition(term: "Process vs thread", meaning: "A process is an isolated running program with its own memory. A thread is a single line of execution within a process; a process can have many threads that share its memory. Isolation is between processes, not between threads of the same process."),
            .heading("How a process's memory is laid out"),
            .paragraph("Inside a process, memory is organized into regions. At the bottom sits the **text** segment (the read-only machine code) and the **data/BSS** (global variables). Above them, the **heap** grows upward as the program asks for memory (`malloc`/`new`). And from the top, the **stack** grows downward — one **frame** pushed for every function call, holding its local variables and, crucially, the **return address** it should jump back to when it finishes."),
            .animation(.processMemory, caption: "Stack frames push downward on each call; the heap grows upward with each allocation — toward each other, with code and data fixed below."),
            .keyPoints([
                "Text — the program's machine code, read-only and shared.",
                "Data / BSS — global and static variables.",
                "Heap — dynamically allocated memory (malloc/new); grows up.",
                "Stack — one frame per function call: locals + the saved return address; grows down.",
                "The instruction pointer (EIP/RIP) holds the address of the next instruction to run."
            ]),
            .callout(.danger, "That saved **return address** on the stack is the prize behind a classic exploit. If a program copies attacker input past the end of a local buffer (a stack buffer overflow), it can overwrite the return address and redirect execution — the foundation of the binary exploitation you'll meet in the Red Team track."),
            .heading("User mode vs kernel mode"),
            .paragraph("The CPU runs in two privilege levels. Your apps run in **user mode**, walled off from the hardware. The **kernel** — the core of the OS — runs in **kernel mode** with full control. When an app needs something privileged (open a file, send a packet), it makes a **system call**, a controlled doorway into the kernel. Most privilege-escalation attacks are about crossing this boundary: getting user-mode code to run with kernel or administrator authority."),
            .definition(term: "System call", meaning: "The controlled interface a user-mode program uses to ask the kernel to do privileged work — read/write files, allocate memory, create processes, talk to the network. It's the only legitimate way to cross from user mode into the kernel."),
            .callout(.tip, "Tools like `ps`, `top` (Linux/macOS) and Task Manager (Windows) list running processes with their owner and privilege. Spotting *which user* a process runs as — and which run as root/SYSTEM — is the first thing both attackers and defenders look at on a box."),
            .checkpoint(QuizQuestion(
                "In a stack buffer overflow, what makes overwriting the stack so dangerous?",
                options: [
                    "It deletes the program from disk",
                    "It can overwrite the saved return address, letting the attacker redirect execution",
                    "It changes the program's file permissions",
                    "It frees the heap"
                ],
                correct: 1,
                why: "Each call frame stores the address to return to. Overflowing a local buffer can clobber that return address, so when the function returns it jumps wherever the attacker chose — hijacking control flow."))
        ],
        quiz: [
            QuizQuestion(
                "What is the difference between a program and a process?",
                options: [
                    "Nothing — they're the same",
                    "A program is a file on disk; a process is that program loaded into memory and executing",
                    "A process is smaller than a program",
                    "A program runs in the kernel; a process runs in user mode"
                ],
                correct: 1,
                why: "A program is static (a file). A process is a live instance of it — loaded into memory with its own resources and a thread of execution."),
            QuizQuestion(
                "Which way does the stack grow, and what does each frame contain?",
                options: [
                    "Upward; only global variables",
                    "Downward; a function's locals and its saved return address",
                    "It doesn't grow",
                    "Upward; the program's machine code"
                ],
                correct: 1,
                why: "The stack grows downward, pushing a frame per call that holds local variables and the return address — which is exactly what overflow attacks target."),
            QuizQuestion(
                "Why does an application use a system call?",
                options: [
                    "To run faster",
                    "To ask the kernel to perform a privileged operation it can't do directly in user mode",
                    "To encrypt its memory",
                    "To create a new programming language"
                ],
                correct: 1,
                why: "User-mode code is walled off from the hardware. A system call is the controlled doorway into the kernel for privileged actions like file, memory and network operations.")
        ]
    )

    // MARK: F-PKI — Certificates & trust (part of Cryptography Essentials)

    private static let pkiLesson = Lesson(
        id: "fund-pki",
        title: "PKI, Certificates & TLS Trust",
        subtitle: "How your browser decides a stranger's server is really who it claims to be.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("Encryption isn't enough — you need identity"),
            .paragraph("Public-key crypto lets two strangers encrypt to each other, but it leaves one gap: how do you know the public key you received really belongs to `bank.com` and not an attacker in the middle? **PKI** (Public Key Infrastructure) answers that with **certificates** — a public key bound to an identity and **signed** by an authority your browser already trusts."),
            .definition(term: "Certificate Authority (CA)", meaning: "A trusted organization that verifies an identity and signs its certificate. Your operating system and browser ship with a built-in list of trusted **root** CAs (the trust store). Anything chaining back to one of those roots is trusted automatically."),
            .heading("The chain of trust"),
            .paragraph("Trust flows down a chain. A **root CA** (offline and heavily protected) signs **intermediate** CAs, which sign the **leaf** certificate on an actual server. When you connect, the server presents its leaf cert plus the intermediates, and your browser walks the chain *upward* until it reaches a root in its trust store. If every signature checks out and nothing is expired or revoked, the chain is valid."),
            .animation(.certChain, caption: "Root signs Intermediate signs the server's leaf cert — and the browser validates the chain back up to a trusted root."),
            .keyPoints([
                "Leaf cert — the server's own certificate (e.g. for shop.com).",
                "Intermediate CA — signs leaf certs; bridges to the root.",
                "Root CA — self-signed, in the browser/OS trust store; the anchor of trust.",
                "Validation checks — signature chain, hostname match, expiry, and revocation (CRL/OCSP).",
                "TLS uses the cert to authenticate the server and agree on the session keys (the HTTPS handshake)."
            ]),
            .terminal(prompt: "kali@lab",
                      command: "openssl s_client -connect shop.com:443 -servername shop.com </dev/null 2>/dev/null | openssl x509 -noout -issuer -subject -dates",
                      output: """
issuer= /C=US/O=Let's Encrypt/CN=R3
subject= /CN=shop.com
notBefore=... notAfter=...   <-- validity window the browser checks
"""),
            .callout(.warning, "The padlock proves the connection is encrypted and the server controls that domain — **not** that the site is honest or safe. Phishing sites get free valid certificates too. HTTPS secures the channel; it does not vouch for the content."),
            .definition(term: "Self-signed certificate", meaning: "A certificate signed by its own key rather than a trusted CA. It still encrypts, but nothing vouches for the identity, so browsers warn loudly. Fine for internal testing; never for a public site users must trust."),
            .callout(.tip, "When a browser screams “your connection is not private,” read the reason: expired cert, hostname mismatch, or an untrusted issuer. Each points at a specific broken link in the chain — and occasionally at a real man-in-the-middle."),
            .checkpoint(QuizQuestion(
                "Your browser trusts shop.com's certificate. What did it actually verify?",
                options: [
                    "That shop.com is a safe, honest business",
                    "That the cert chains to a trusted root CA, matches the hostname, and is in its validity window",
                    "That the server's password is strong",
                    "That the site has no vulnerabilities"
                ],
                correct: 1,
                why: "Validation confirms the cryptographic chain to a trusted root, a matching hostname, and current validity — proving control of the domain and a secure channel. It says nothing about the site's honesty or security."))
        ],
        quiz: [
            QuizQuestion(
                "What problem does a certificate authority solve?",
                options: [
                    "It encrypts the traffic faster",
                    "It vouches that a public key really belongs to the named identity, by signing its certificate",
                    "It stores the website's password",
                    "It assigns IP addresses"
                ],
                correct: 1,
                why: "Encryption alone doesn't prove identity. A CA verifies and signs the certificate, so a key can be tied to a domain your browser can trust."),
            QuizQuestion(
                "How does a browser validate a server's certificate?",
                options: [
                    "It trusts any certificate presented",
                    "It walks the signature chain up to a trusted root CA and checks hostname, expiry and revocation",
                    "It asks the user to approve every time",
                    "It compares the certificate to the IP address"
                ],
                correct: 1,
                why: "The browser verifies each signature up the chain to a root in its trust store, and checks the hostname matches, the cert is unexpired, and it isn't revoked."),
            QuizQuestion(
                "Does the HTTPS padlock mean a website is trustworthy?",
                options: [
                    "Yes, it guarantees the site is safe",
                    "No — it proves encryption and domain control, but phishing sites can have valid certs too",
                    "Yes, CAs vet every site's content",
                    "Only if it's a green padlock"
                ],
                correct: 1,
                why: "The padlock secures the channel and proves control of the domain. It does not certify the site's intentions — attackers obtain valid certificates routinely.")
        ]
    )

    // MARK: F7 — Identity & isolation

    private static let identity = Module(
        id: "fund-identity",
        title: "Identity & Isolation",
        summary: "Two pillars of modern security: how we prove who someone is (passwords, MFA, passkeys) and how we keep workloads apart (virtual machines and containers).",
        systemImage: "person.badge.key.fill",
        lessons: [authLesson, virtualizationLesson]
    )

    private static let authLesson = Lesson(
        id: "fund-auth",
        title: "Authentication & MFA",
        subtitle: "How systems prove you're you — and why a password alone stopped being enough.",
        minutes: 11,
        difficulty: .foundational,
        blocks: [
            .heading("Authentication vs authorization"),
            .paragraph("Two words that get muddled constantly. **Authentication** answers *who are you?* — proving identity. **Authorization** answers *what are you allowed to do?* — granting access. You authenticate once (log in), then every action is authorized against your permissions. Most of the attacks in this course target one or the other: stealing identity, or escaping the limits of your permissions."),
            .heading("The three factors"),
            .paragraph("Authentication evidence falls into three categories. Strong authentication combines factors from **different** categories — that's what 'multi-factor' means. Two passwords aren't MFA; a password plus a phone code is."),
            .keyPoints([
                "Something you KNOW — a password, PIN or passphrase. Cheap, but phishable and reusable.",
                "Something you HAVE — a phone (TOTP app), a hardware key, a smart card. Possession is harder to steal remotely.",
                "Something you ARE — a fingerprint or face (biometrics). Convenient, but can't be changed if compromised.",
                "MFA = two or more from DIFFERENT categories — so one stolen factor isn't enough.",
                "Passwordless / passkeys (FIDO2) — a private key on your device, unlocked by biometric, that proves identity without a shared secret to phish."
            ]),
            .animation(.mfaFactors, caption: "Factor one (password) then factor two (a time-based code) are each verified — a phished password alone is stopped cold at the second factor."),
            .definition(term: "TOTP", meaning: "Time-based One-Time Password — a 6-digit code that both your authenticator app and the server compute from a shared seed plus the current time, so it changes every 30 seconds. It proves you hold the seed without transmitting a reusable secret."),
            .heading("Storing passwords the right way"),
            .paragraph("Servers must never store passwords in plaintext. They store a **salted hash**: run the password through a slow, one-way hashing function (bcrypt, scrypt, Argon2) with a unique random **salt** per user. A breach then leaks hashes, not passwords, and the unique salt defeats precomputed 'rainbow table' attacks."),
            .terminal(prompt: "kali@lab",
                      command: "echo -n 'hunter2' | argon2 $(openssl rand -hex 8) -id -t 3 -m 16 | grep Encoded",
                      output: """
Encoded: $argon2id$v=19$m=65536,t=3,p=1$NWE3Y2…$Jt0c…hash…
# slow + salted: each guess costs real time, and the salt is unique per user
"""),
            .callout(.danger, "Not all second factors are equal. SMS codes can be phished or SIM-swapped, and push prompts invite 'MFA fatigue' (spam until the user taps Approve). Phishing-resistant FIDO2/passkeys bind the login to the real site's origin, so even an adversary-in-the-middle proxy can't replay it."),
            .callout(.tip, "Reuse is the real enemy: one breached password unlocks every site where it was reused (credential stuffing). A password manager + unique passwords + MFA is the single highest-value security setup for any person or org."),
            .checkpoint(QuizQuestion(
                "Which of these is genuine multi-factor authentication?",
                options: [
                    "A password plus a security question",
                    "A password (something you know) plus a code from your phone (something you have)",
                    "Two different passwords",
                    "A longer password"
                ],
                correct: 1,
                why: "MFA requires factors from different categories. A password and a phone code combine 'know' and 'have'; passwords plus security questions are both 'know', so that's still single-factor in spirit."))
        ],
        quiz: [
            QuizQuestion(
                "What is the difference between authentication and authorization?",
                options: [
                    "They are the same",
                    "Authentication proves who you are; authorization determines what you're allowed to do",
                    "Authorization happens first",
                    "Authentication is only for admins"
                ],
                correct: 1,
                why: "Authentication establishes identity (login); authorization governs permitted actions afterward. Many attacks target one or the other — stealing identity, or exceeding granted permissions."),
            QuizQuestion(
                "Why do servers store a salted hash of a password instead of the password?",
                options: [
                    "To save space",
                    "So a breach leaks irreversible hashes, and the unique salt defeats precomputed rainbow tables",
                    "To make login faster",
                    "Because hashing encrypts the password"
                ],
                correct: 1,
                why: "A slow salted hash can't be reversed to the password, and a per-user salt means identical passwords hash differently — neutralising rainbow-table and bulk-cracking shortcuts."),
            QuizQuestion(
                "Why are FIDO2 passkeys considered phishing-resistant?",
                options: [
                    "They use longer passwords",
                    "The private key is bound to the real site's origin, so a look-alike phishing site can't complete the login",
                    "They are stored on the server",
                    "They never expire"
                ],
                correct: 1,
                why: "Passkeys cryptographically tie authentication to the legitimate origin. An adversary-in-the-middle on a different domain can't satisfy that binding, so the stolen interaction is useless.")
        ]
    )

    private static let virtualizationLesson = Lesson(
        id: "fund-virtualization",
        title: "Virtual Machines & Containers",
        subtitle: "How one physical server safely runs many isolated workloads — two ways, two trade-offs.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("Why isolate at all"),
            .paragraph("Running every app on its own physical box is wasteful and slow to scale. Virtualization lets one machine host many **isolated** workloads — each believing it has its own computer — so resources are shared safely and a problem in one workload doesn't sink the others. There are two dominant approaches, and the difference matters enormously for security."),
            .animation(.vmContainer, caption: "A VM ships a full guest OS on a hypervisor (strong isolation, heavy); a container shares the host kernel through a runtime (light and instant, thinner boundary)."),
            .heading("Virtual machines"),
            .paragraph("A **hypervisor** (VMware, Hyper-V, KVM) carves the hardware into virtual machines, each running a complete **guest operating system**. The isolation is strong because each VM has its own kernel — escaping to the host means defeating the hypervisor, a high bar. The cost is weight: gigabytes of disk, minutes to boot, real overhead."),
            .heading("Containers"),
            .paragraph("A **container** (Docker, containerd) packages just an app and its dependencies, and they all **share the host's kernel** through a runtime using Linux namespaces and cgroups. That makes them tiny and near-instant to start — perfect for microservices and CI. But the shared kernel is a thinner boundary: a kernel bug or a misconfiguration (a privileged container, a mounted Docker socket) can become a host compromise — the 'container escape' you'll meet in the Red Team track."),
            .keyPoints([
                "VM — full guest OS per instance, isolated by the hypervisor. Strong boundary, heavy (GBs, slow boot).",
                "Container — shares the host kernel via namespaces/cgroups. Light (MBs, instant), thinner boundary.",
                "Image — a read-only template a container is started from; layered and reproducible.",
                "Orchestration — Kubernetes schedules and scales containers across many hosts.",
                "Defence in depth — run containers unprivileged, drop capabilities, and isolate sensitive workloads in their own VMs."
            ]),
            .terminal(prompt: "kali@lab",
                      command: "docker run --rm alpine cat /proc/1/cgroup | head -1   # am I in a container?",
                      output: """
0::/docker/3f9a…   ← the cgroup path reveals the container runtime
"""),
            .definition(term: "Namespaces & cgroups", meaning: "The Linux kernel features that make containers possible. Namespaces give a container its own view of processes, network and filesystem (isolation); cgroups limit how much CPU/memory it can use (resource control). They run on the one shared kernel — which is exactly why container isolation is weaker than a VM's."),
            .callout(.warning, "'It's in a container, so it's safe' is a dangerous assumption. Containers are an isolation *convenience*, not a strong security boundary by default. A --privileged container or one with the host's Docker socket mounted is effectively root on the host."),
            .callout(.tip, "Rule of thumb: containers for packaging and scaling trusted workloads; a VM (or stronger sandbox like gVisor/Firecracker) when you must run untrusted code with a hard isolation guarantee."),
            .checkpoint(QuizQuestion(
                "What is the key isolation difference between a container and a virtual machine?",
                options: [
                    "Containers use more memory",
                    "Containers share the host's kernel, while each VM runs its own full guest OS",
                    "VMs can't run Linux",
                    "Containers can't be networked"
                ],
                correct: 1,
                why: "A VM virtualizes the hardware and runs a separate kernel per guest (strong isolation); containers share the single host kernel, making them lightweight but giving a thinner security boundary."))
        ],
        quiz: [
            QuizQuestion(
                "Why do containers start almost instantly compared to VMs?",
                options: [
                    "They use a faster CPU",
                    "They share the running host kernel instead of booting a whole guest OS",
                    "They have no filesystem",
                    "They skip authentication"
                ],
                correct: 1,
                why: "A container just starts a process group on the already-running host kernel, so there's no OS to boot — unlike a VM, which must start a complete guest operating system."),
            QuizQuestion(
                "Why is a VM generally a stronger isolation boundary than a container?",
                options: [
                    "It uses encryption",
                    "Each VM has its own kernel, so escaping requires defeating the hypervisor — a much higher bar than a shared kernel",
                    "VMs are newer technology",
                    "Containers have no network"
                ],
                correct: 1,
                why: "Containers share the host kernel, so a kernel flaw or misconfiguration can breach the boundary. A VM's separate kernel means an attacker must break the hypervisor itself to escape — substantially harder."),
            QuizQuestion(
                "What makes a `--privileged` container dangerous?",
                options: [
                    "It runs slower",
                    "It removes the usual restrictions, so compromising it is effectively root on the host",
                    "It can't access the network",
                    "It uses more disk"
                ],
                correct: 1,
                why: "A privileged container drops the capability and device restrictions that normally contain it, so an attacker inside it can reach the host kernel and devices directly — a straight path to host compromise.")
        ]
    )

    // MARK: F8 — Inside the machine

    private static let machine = Module(
        id: "fund-machine",
        title: "Inside the Machine",
        summary: "What's really happening under your code: how source becomes the instructions a CPU runs, and why true randomness is a security-critical resource.",
        systemImage: "cpu.fill",
        lessons: [compilationLesson, entropyLesson]
    )

    private static let compilationLesson = Lesson(
        id: "fund-compilation",
        title: "How Code Runs: Source to CPU",
        subtitle: "From the text you type to the binary instructions a processor actually executes.",
        minutes: 10,
        difficulty: .foundational,
        blocks: [
            .heading("The CPU only speaks binary"),
            .paragraph("You write code in a human-friendly language, but a CPU understands only **machine code** — raw binary instructions. A **compiler** bridges that gap, translating your source into the specific instruction set of the target processor. Interpreted languages (Python, JavaScript) take a different route — a runtime executes them on the fly — but in every case, something turns your text into operations a chip can run."),
            .animation(.compilePipeline, caption: "Source is translated by the compiler into machine code, which the CPU then runs one instruction at a time in a fetch-decode-execute loop."),
            .heading("The build pipeline"),
            .paragraph("For a compiled language like C, the journey has distinct stages — and knowing them demystifies a huge amount of security work, from reverse engineering to exploit development."),
            .keyPoints([
                "Source code — the human-readable text you write (main.c).",
                "Compiler — parses, optimises and emits assembly for the target CPU architecture.",
                "Assembler & linker — turn assembly into object code and stitch in libraries to make an executable.",
                "Machine code — the binary instructions in the final program file.",
                "CPU — fetches each instruction, decodes it, executes it, and moves to the next — billions of times a second."
            ]),
            .definition(term: "Fetch-decode-execute", meaning: "The fundamental cycle a CPU repeats endlessly: fetch the next instruction from memory (tracked by the program counter), decode what it means, execute it (arithmetic, memory access, a jump), then repeat. Hijacking control of a program — the goal of memory-corruption exploits — means hijacking what gets fetched next."),
            .terminal(prompt: "kali@lab",
                      command: "gcc hello.c -o hello && objdump -d hello | grep -A4 '<main>:'",
                      output: """
0000000000001139 <main>:
    1139:  55                 push   %rbp
    113a:  48 89 e5           mov    %rsp,%rbp
    113d:  bf 00 20 00 00     mov    $0x2000,%edi
"""),
            .callout(.tip, "Those hex bytes on the left ARE the machine code; the text on the right is the assembly the disassembler recovered. Reverse engineers (Red Team track) live in this view — reading a program with no source by turning its bytes back into instructions."),
            .callout(.info, "Compiled vs interpreted matters for attackers: a compiled binary must be disassembled to understand, while interpreted source often ships readable. Just-in-time (JIT) compilers blur the line and introduce their own exploitable surface."),
            .checkpoint(QuizQuestion(
                "What does a compiler do?",
                options: [
                    "Runs the program faster",
                    "Translates human-readable source code into the CPU's machine instructions",
                    "Encrypts the source code",
                    "Connects to the internet"
                ],
                correct: 1,
                why: "A compiler converts source into machine code for a target architecture. The CPU can then execute those binary instructions directly — it can't run the original text."))
        ],
        quiz: [
            QuizQuestion(
                "What is the CPU's fetch-decode-execute cycle?",
                options: [
                    "A way to encrypt data",
                    "The repeating loop of fetching the next instruction, decoding it, and executing it",
                    "A network protocol",
                    "A compiler optimisation"
                ],
                correct: 1,
                why: "It's the fundamental operation of a processor: read the next instruction, work out what it is, carry it out, repeat — billions of times per second."),
            QuizQuestion(
                "Why must a reverse engineer disassemble a compiled program?",
                options: [
                    "To make it run faster",
                    "Because it ships as machine code, not readable source — disassembly turns bytes back into instructions",
                    "To encrypt it",
                    "Because compiled code is always malware"
                ],
                correct: 1,
                why: "Compilation discards the source; the binary is just machine code. Disassemblers reconstruct the assembly so the program's logic can be studied without the original source."),
            QuizQuestion(
                "How do interpreted languages like Python differ from compiled ones?",
                options: [
                    "They can't be run",
                    "A runtime executes the source on the fly rather than producing a standalone machine-code binary",
                    "They don't use a CPU",
                    "They are always faster"
                ],
                correct: 1,
                why: "Interpreted languages are executed by a runtime/interpreter at run time, so they typically ship as (readable) source rather than as a pre-compiled machine-code executable.")
        ]
    )

    private static let entropyLesson = Lesson(
        id: "fund-entropy",
        title: "Randomness & Entropy",
        subtitle: "Why 'pick a random number' is one of the hardest — and most security-critical — things a computer does.",
        minutes: 9,
        difficulty: .intermediate,
        blocks: [
            .heading("Computers are bad at random"),
            .paragraph("A CPU is deterministic — same input, same output — which makes genuine randomness surprisingly hard. Yet almost all of cryptography depends on it: keys, tokens, session ids, password salts and nonces must be **unpredictable**. Get the randomness wrong and the strongest cipher in the world collapses, because the attacker can simply predict the secret."),
            .animation(.entropyRng, caption: "A seeded PRNG produces a predictable sequence an attacker can foresee; a CSPRNG fed by hardware entropy produces output that can't be guessed."),
            .heading("PRNG vs CSPRNG"),
            .paragraph("There are two kinds of random-number generator, and confusing them is a classic, catastrophic bug. A plain **PRNG** is fast and fine for simulations or games. A **CSPRNG** is the only acceptable source for anything security-related."),
            .keyPoints([
                "PRNG — pseudo-random: a deterministic formula from a seed. Predictable if you know (or guess) the seed.",
                "CSPRNG — cryptographically secure: seeded from real entropy and built so outputs can't be predicted or reversed.",
                "Entropy — true unpredictability the OS harvests from hardware: timing jitter, interrupts, mouse/keyboard input.",
                "Seeding — a CSPRNG mixes in entropy so its starting state can't be reproduced.",
                "Use the right API — /dev/urandom, getrandom(), os.urandom, crypto.randomBytes — never rand() or Math.random() for secrets."
            ]),
            .definition(term: "Entropy", meaning: "A measure of unpredictability — how much genuine uncertainty there is in a value. Operating systems collect entropy from physical, hard-to-predict events (hardware timing, interrupt jitter, sensor noise) into a pool that seeds the CSPRNG. Low entropy at boot is a real risk for devices that generate keys early."),
            .callout(.danger, "Predictable randomness has broken real systems: guessable session tokens that let attackers hijack accounts, password-reset links an attacker could foresee, and crypto keys recreated because the RNG was seeded with the current time. If you can predict the 'random', there is no security."),
            .callout(.tip, "Rule of thumb: if a random value protects anything, it must come from the platform's cryptographic RNG. Reaching for a general-purpose rand() for a token, key or salt is a security bug, full stop."),
            .checkpoint(QuizQuestion(
                "Why is a plain PRNG unsafe for generating a session token?",
                options: [
                    "It's too slow",
                    "It's deterministic from its seed, so an attacker who learns or guesses the seed can predict the tokens",
                    "It uses too much memory",
                    "It only makes even numbers"
                ],
                correct: 1,
                why: "A PRNG's output is a fixed function of its seed. If the seed is guessable (e.g. the time), the whole sequence — including 'random' tokens — can be reproduced by an attacker. Tokens need a CSPRNG."))
        ],
        quiz: [
            QuizQuestion(
                "What is the key difference between a PRNG and a CSPRNG?",
                options: [
                    "Speed only",
                    "A CSPRNG is seeded from real entropy and built so its output can't be predicted or reversed",
                    "A PRNG is newer",
                    "There is no difference"
                ],
                correct: 1,
                why: "Both are algorithmic, but a CSPRNG is designed for unpredictability — properly seeded with entropy and resistant to output prediction — which a general-purpose PRNG is not."),
            QuizQuestion(
                "Where does an operating system get entropy?",
                options: [
                    "From the system clock only",
                    "From hard-to-predict physical events: timing jitter, interrupts, input and sensor noise",
                    "From the user's password",
                    "From the internet"
                ],
                correct: 1,
                why: "The OS harvests unpredictability from physical sources (hardware timing, interrupts, I/O jitter) into an entropy pool that seeds its cryptographic RNG."),
            QuizQuestion(
                "Which function is appropriate for generating a cryptographic key?",
                options: [
                    "rand() / Math.random()",
                    "A cryptographic RNG such as getrandom(), os.urandom or crypto.randomBytes",
                    "The current timestamp",
                    "A fixed seed for reproducibility"
                ],
                correct: 1,
                why: "Only a cryptographically secure RNG provides the unpredictability keys require. General-purpose rand()/Math.random() are predictable and must never be used for secrets.")
        ]
    )
}
