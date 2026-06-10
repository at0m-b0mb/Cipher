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
        Flashcard("MTTD / MTTR", "Mean time to detect / respond — core SOC effectiveness metrics.", .blueTeam)
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
