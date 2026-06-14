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
        modules: [mindset, shell, networking, encoding, crypto, web, windows]
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
        lessons: [encodingLesson]
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
        lessons: [encryptionLesson, hashingLesson]
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
        summary: "HTTP, cookies and sessions — the request/response machinery every web attack in the Red Team track builds on.",
        systemImage: "globe",
        lessons: [webBasicsLesson]
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
}
