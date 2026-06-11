import Foundation

/// Bite-size term ⇄ definition cards. Powers the Apple Watch daily drill and
/// "term of the day", plus the iPhone glossary. Categorised so the UI can tint
/// them red/blue/teal to match the track they come from.
struct Flashcard: Identifiable {
    let id: String
    let term: String
    let definition: String
    let category: TrackKind

    init(_ term: String, _ definition: String, _ category: TrackKind) {
        self.id = term.lowercased().replacingOccurrences(of: " ", with: "-")
        self.term = term
        self.definition = definition
        self.category = category
    }
}

enum Flashcards {

    static let deck: [Flashcard] = [
        // Fundamentals
        Flashcard("CIA Triad", "Confidentiality, Integrity, Availability — the three properties security exists to protect.", .fundamentals),
        Flashcard("Encapsulation", "Each network layer wrapping data in its own header as it travels down the stack.", .fundamentals),
        Flashcard("3-Way Handshake", "TCP's SYN → SYN-ACK → ACK exchange that establishes a reliable connection.", .fundamentals),
        Flashcard("Port", "A numbered endpoint (0–65535) identifying a specific service on a host. SSH=22, HTTP=80, HTTPS=443.", .fundamentals),
        Flashcard("Symmetric Encryption", "One shared key encrypts and decrypts. Fast — used for bulk data (AES).", .fundamentals),
        Flashcard("Asymmetric Encryption", "A public/private key pair. Solves key exchange and enables digital signatures (RSA, ECC).", .fundamentals),
        Flashcard("Hashing", "A one-way function turning input into a fixed-size fingerprint. Irreversible by design.", .fundamentals),
        Flashcard("Salt", "Unique random data added per password before hashing — defeats rainbow tables.", .fundamentals),
        Flashcard("Digital Signature", "A message hash encrypted with a private key; verified with the public key for authenticity + integrity.", .fundamentals),
        Flashcard("Promiscuous Mode", "A NIC setting that captures all frames it sees, not just its own — enables sniffing.", .fundamentals),
        Flashcard("RST Packet", "A TCP reset that aborts a connection; a closed port answers a SYN with RST.", .fundamentals),
        Flashcard("ARP Spoofing", "A Layer-2 attack mapping the attacker's MAC to another host's IP for man-in-the-middle.", .fundamentals),
        Flashcard("HTTP", "The stateless request/response protocol of the web: a method, path and headers in, a status code and body back.", .fundamentals),
        Flashcard("Session Cookie", "A token the server sets after login and the browser returns on every request — it IS the logged-in session.", .fundamentals),
        Flashcard("Same-Origin Policy", "The browser rule that script from one origin can't read another's responses — the boundary XSS, CSRF and CORS revolve around.", .fundamentals),
        Flashcard("Active Directory", "Microsoft's central directory of users, computers and groups for a Windows domain — the prize in most internal tests.", .fundamentals),
        Flashcard("Domain Controller", "The server running AD; it authenticates logons and holds NTDS.dit — every account's password hash.", .fundamentals),
        Flashcard("Kerberos TGT", "A Ticket Granting Ticket issued at logon that proves your identity and is exchanged for per-service tickets.", .fundamentals),

        // Red team
        Flashcard("OSINT", "Open-source intelligence — recon from public data with no contact to the target's systems.", .redTeam),
        Flashcard("Attack Surface", "Every point an attacker could try to enter: domains, services, people, integrations.", .redTeam),
        Flashcard("Enumeration", "Squeezing every service for versions, config and functionality. 'Enumerate, enumerate, enumerate.'", .redTeam),
        Flashcard("Banner Grabbing", "Reading the identifying text a service announces, mapping versions to known CVEs.", .redTeam),
        Flashcard("Reverse Shell", "A shell where the victim connects out to the attacker — slipping past inbound firewall rules.", .redTeam),
        Flashcard("Bind Shell", "A shell listening on a port on the victim; usually blocked by inbound firewalls.", .redTeam),
        Flashcard("SQL Injection", "User input altering a database query's meaning. Fixed by parameterized queries.", .redTeam),
        Flashcard("XSS", "Injecting script that runs in victims' browsers with the site's privileges. Fixed by output encoding.", .redTeam),
        Flashcard("Privilege Escalation", "Climbing from a low-privilege foothold to root/SYSTEM via misconfigurations or bugs.", .redTeam),
        Flashcard("SUID Binary", "A program that runs as its owner; an exploitable SUID-root binary yields root.", .redTeam),
        Flashcard("Pass-the-Hash", "Authenticating with an NTLM hash directly — no need to crack the password.", .redTeam),
        Flashcard("Kerberoasting", "Requesting service tickets and cracking the service account's password offline.", .redTeam),
        Flashcard("Lateral Movement", "Reusing credentials/trust to hop host-to-host toward the objective.", .redTeam),
        Flashcard("Pivoting", "Tunneling tools through a compromised host to reach otherwise-unreachable networks.", .redTeam),
        Flashcard("Password Spraying", "Trying one common password against many accounts to dodge lockout thresholds.", .redTeam),
        Flashcard("Buffer Overflow", "Overrunning a buffer to overwrite the return address and hijack execution.", .redTeam),
        Flashcard("NOP Sled", "A run of no-op instructions giving an imprecise jump room to slide into shellcode.", .redTeam),
        Flashcard("C2 Beacon", "An implant's periodic, jittered check-in to its command-and-control server.", .redTeam),
        Flashcard("Spear Phishing", "A highly targeted phish personalized to one individual using gathered intel.", .redTeam),
        Flashcard("IDOR", "Insecure Direct Object Reference — change an object id in a request to read data that isn't yours. No ownership check.", .redTeam),
        Flashcard("Broken Access Control", "Logged-in but under-restricted: the app forgets to check what you're authorized to do. OWASP's #1 risk.", .redTeam),
        Flashcard("Path Traversal", "Using ../ to climb out of an intended folder and read arbitrary files the web process can access.", .redTeam),
        Flashcard("LFI", "Local File Inclusion — the app loads and runs a file you choose; combined with log/upload poisoning it becomes RCE.", .redTeam),
        Flashcard("SSTI", "Server-Side Template Injection — input the template engine evaluates ({{7*7}}→49), escalating to code execution.", .redTeam),
        Flashcard("XXE", "XML External Entity — a permissive XML parser resolves entities to read local files or reach internal URLs (SSRF).", .redTeam),
        Flashcard("Insecure Deserialization", "Rebuilding attacker-controlled bytes into live objects, letting a gadget chain reach remote code execution.", .redTeam),
        Flashcard("AS-REP Roasting", "Requesting and cracking the AS-REP of accounts with Kerberos pre-auth disabled — often without any domain creds.", .redTeam),
        Flashcard("DCSync", "Abusing directory-replication rights to ask a DC for any account's hash, including krbtgt. No code runs on the DC.", .redTeam),
        Flashcard("Golden Ticket", "A forged TGT signed with the stolen krbtgt hash — valid as any user, domain-wide, until krbtgt is rotated twice.", .redTeam),
        Flashcard("BloodHound", "Graphs AD users, groups and permissions to compute the shortest attack path to Domain Admin.", .redTeam),
        Flashcard("ACL Abuse", "Exploiting over-permissive AD rights (GenericAll, WriteDACL, ForceChangePassword) as direct, patch-proof attack steps.", .redTeam),
        Flashcard("AMSI Bypass", "Patching the in-process Antimalware Scan Interface so a payload it would block reports clean and runs.", .redTeam),
        Flashcard("Process Injection", "Running shellcode inside a trusted process (e.g. explorer.exe) to inherit its identity and dodge detection.", .redTeam),
        Flashcard("LOLBin", "A signed, built-in OS binary (certutil, rundll32, mshta) repurposed for attacker work so it blends in.", .redTeam),
        Flashcard("Evil Twin", "A rogue access point cloning a trusted SSID to lure clients, harvest the passphrase and enable MITM.", .redTeam),
        Flashcard("WPA2 Handshake", "The 4-way handshake captured on connect; cracked offline to recover a Wi-Fi pre-shared key.", .redTeam),
        Flashcard("ARP Poisoning", "Forging IP→MAC replies so a victim's traffic to the gateway flows through the attacker — a LAN man-in-the-middle.", .redTeam),
        Flashcard("Responder / LLMNR", "Answering unauthenticated LLMNR/NBT-NS name broadcasts to capture NetNTLMv2 hashes for cracking or relay.", .redTeam),
        Flashcard("NTLM Relay", "Forwarding a captured authentication to another host (where SMB signing is off) to act as the victim — no cracking needed.", .redTeam),
        Flashcard("ROP", "Return-Oriented Programming — chaining existing code 'gadgets' (each ending in ret) to bypass a non-executable stack (DEP).", .redTeam),
        Flashcard("DEP / NX", "Marks the stack and heap non-executable so injected shellcode won't run — the mitigation that forces ROP.", .redTeam),
        Flashcard("ASLR", "Randomizes module/stack base addresses so exploits can't hard-code targets; defeated with an info leak.", .redTeam),

        // Blue team
        Flashcard("Defense in Depth", "Layering independent controls so an attacker must defeat all of them.", .blueTeam),
        Flashcard("Zero Trust", "'Never trust, always verify' — authenticate every request as if from the open internet.", .blueTeam),
        Flashcard("SOC", "Security Operations Center — the team and tooling monitoring and responding 24/7.", .blueTeam),
        Flashcard("SIEM", "Centralizes and analyzes telemetry, running detection logic to raise alerts.", .blueTeam),
        Flashcard("EDR", "Endpoint Detection & Response — agent recording endpoint activity and enabling remote remediation.", .blueTeam),
        Flashcard("Sysmon", "High-value free Windows telemetry: process creation, network connections, image loads.", .blueTeam),
        Flashcard("MITRE ATT&CK", "A knowledge base of adversary Tactics (goals) and Techniques (methods).", .blueTeam),
        Flashcard("IOC vs TTP", "Indicators (hashes/IPs) are cheap to change; behaviors (TTPs) are costly — build detections on TTPs.", .blueTeam),
        Flashcard("Pyramid of Pain", "Forcing attackers to change TTPs hurts them far more than blocking a hash or IP.", .blueTeam),
        Flashcard("Sigma Rule", "A vendor-neutral detection format that compiles to many SIEM query languages.", .blueTeam),
        Flashcard("Threat Hunting", "Proactively assuming breach and searching for adversaries that evaded alerts.", .blueTeam),
        Flashcard("Dwell Time", "How long an attacker stays undetected — the number hunting aims to shrink.", .blueTeam),
        Flashcard("IR Lifecycle", "Preparation, Identification, Containment, Eradication, Recovery, Lessons Learned.", .blueTeam),
        Flashcard("Order of Volatility", "Collect the most ephemeral evidence first: memory, then network state, then disk.", .blueTeam),
        Flashcard("Chain of Custody", "A documented, unbroken record proving evidence wasn't altered — key to admissibility.", .blueTeam),
        Flashcard("Static Analysis", "Examining malware without running it: strings, headers, disassembly.", .blueTeam),
        Flashcard("Dynamic Analysis", "Detonating malware in an isolated sandbox to observe its behavior.", .blueTeam),
        Flashcard("MTTD / MTTR", "Mean time to detect / respond — core SOC effectiveness metrics.", .blueTeam),
        Flashcard("Tiered Administration", "Isolating admin credentials by tier (Tier 0 = DCs/Domain Admins) so high-tier creds never land on low-tier hosts.", .blueTeam),
        Flashcard("LAPS", "Local Administrator Password Solution — unique, rotating local-admin passwords per machine that defeat pass-the-hash reuse.", .blueTeam),
        Flashcard("gMSA", "Group Managed Service Account — a service account with a long, auto-rotated password that makes Kerberoasting infeasible.", .blueTeam),
        Flashcard("Honeypot Account", "A deceptive, never-used account (often with a tempting SPN) whose every login or ticket request is high-signal evidence of an attacker.", .blueTeam)
    ]

    static func cards(for category: TrackKind) -> [Flashcard] {
        deck.filter { $0.category == category }
    }

    /// A stable card for the current day — same for everyone, changes at midnight.
    static func termOfTheDay(for date: Date = Date()) -> Flashcard {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return deck[day % deck.count]
    }

    /// A shuffled drill of `count` cards seeded by the day so a day's drill is
    /// consistent if revisited, but fresh tomorrow.
    static func dailyDrill(count: Int = 7, for date: Date = Date()) -> [Flashcard] {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        var rng = SeededGenerator(seed: UInt64(day))
        return Array(deck.shuffled(using: &rng).prefix(count))
    }
}

/// Tiny deterministic RNG so "today's drill" is reproducible within a day.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
