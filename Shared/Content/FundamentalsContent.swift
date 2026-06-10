import Foundation

/// The Fundamentals track — the shared bedrock every operator (red or blue)
/// needs: the mindset and ethics, how networks really move data, and the
/// cryptography that protects (and betrays) it.
enum FundamentalsContent {

    static let track = Track(
        id: "fundamentals",
        kind: .fundamentals,
        title: "Fundamentals",
        tagline: "Mindset, networks & crypto — the ground floor of everything.",
        modules: [mindset, networking, crypto]
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
}
