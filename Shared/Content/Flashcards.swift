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
        Flashcard("Hexadecimal", "Base-16 (0–9, a–f). One byte = two hex digits, so hex maps cleanly onto raw bytes — used in hashes, dumps and packet captures.", .fundamentals),
        Flashcard("Base64", "Encodes arbitrary bytes into 64 printable characters (3 bytes → 4 chars, often '='-padded) so binary survives text channels. Reversible, not secret.", .fundamentals),
        Flashcard("URL Encoding", "Percent-encoding that escapes unsafe characters for URLs: space→%20, !→%21, ../→%2e%2e%2f. Reversible representation, no key.", .fundamentals),
        Flashcard("Encoding vs Encryption", "Encoding (hex/Base64/URL) is reversible re-representation with no key; encryption needs a key. No key means no confidentiality — a classic mix-up.", .fundamentals),
        Flashcard("ECB Mode", "The naive block-cipher mode: each block encrypts independently, so identical plaintext blocks → identical ciphertext. Leaks patterns (the 'ECB penguin'). Never use it.", .fundamentals),
        Flashcard("AEAD / GCM", "Authenticated encryption (e.g. AES-GCM) provides confidentiality AND integrity, detecting tampering. The modern default — used with a unique nonce per message.", .fundamentals),

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
        Flashcard("CSRF", "Cross-Site Request Forgery — an attacker page makes the victim's browser fire a state-changing request using their cookie.", .redTeam),
        Flashcard("Anti-CSRF Token", "A secret per-session value embedded in the app's own forms; a cross-site page can't read it, so forged requests are rejected.", .redTeam),
        Flashcard("JWT", "JSON Web Token — a signed header.payload.signature blob. Header/payload are base64 (readable); security rests on the signature.", .redTeam),
        Flashcard("alg:none", "A JWT attack: set the algorithm to 'none' and strip the signature; weak libraries accept the forged, unsigned token.", .redTeam),
        Flashcard("Source vs Sink", "White-box review: a source is where untrusted input enters, a sink is a dangerous operation; a flow between them unsanitized is the bug.", .redTeam),
        Flashcard("Client-Side Attack", "Attacking the user's application (Office, PDF, browser) so opening a crafted file runs code in their context.", .redTeam),
        Flashcard("Mark-of-the-Web", "A flag Windows adds to downloaded files that blocks macros and warns the user; container formats (ISO) are abused to bypass it.", .redTeam),
        Flashcard("Kerberos Delegation", "A feature letting a service reuse your identity to reach a back-end; misconfigured (unconstrained/constrained/RBCD) it enables impersonation.", .redTeam),
        Flashcard("Unconstrained Delegation", "A host that caches the TGT of anyone who authenticates to it; coerce a DC to connect and steal a domain-owning ticket.", .redTeam),
        Flashcard("RBCD", "Resource-Based Constrained Delegation — set on the target; write access to its delegation attribute lets an attacker impersonate users to it.", .redTeam),
        Flashcard("SID History", "A ticket field for migrations, abused to smuggle a privileged SID (Enterprise Admins) across an intra-forest trust that doesn't filter SIDs.", .redTeam),
        Flashcard("Forest Trust", "Trust links between domains; because the forest (not the domain) is the boundary, compromising one domain often cascades to the forest.", .redTeam),
        Flashcard("AppLocker Bypass", "Defeating application whitelisting by running code through an already-approved signed binary (a LOLBin) instead of your own.", .redTeam),
        Flashcard("SEH Overflow", "A Windows overflow that clobbers the exception-handler chain; a pop-pop-ret gadget makes a thrown exception jump to shellcode.", .redTeam),
        Flashcard("Egghunter", "Tiny shellcode that scans memory for a tagged 'egg' marking your larger payload — used when the controlled buffer is too small.", .redTeam),
        Flashcard("Format String", "printf(user_input) lets the user control specifiers: %x/%s read memory, %n writes it — an arbitrary read/write from one bug.", .redTeam),
        Flashcard("Use-After-Free", "Memory freed but still pointed to; reclaim the slot with attacker data (a fake vtable) so the dangling call runs your code.", .redTeam),
        Flashcard("BOLA", "Broken Object-Level Authorization — the API's IDOR. Swap an object id and the server returns it without checking ownership. The #1 API vulnerability.", .redTeam),
        Flashcard("GraphQL Introspection", "A built-in query that returns the API's full schema — every type, query and mutation, including ones the UI hides. Often left on in production.", .redTeam),
        Flashcard("Mass Assignment", "Sending extra fields a client never should (\"role\":\"admin\") that the server blindly binds to an object — granting properties you were never meant to set.", .redTeam),
        Flashcard("OAuth 2.0", "A delegated-access protocol (the engine behind 'Sign in with…'). The authorization-code flow returns a short-lived code via a browser redirect.", .redTeam),
        Flashcard("redirect_uri Abuse", "Loose validation of OAuth's redirect target lets an attacker craft a login link that delivers the victim's auth code to attacker-controlled infrastructure.", .redTeam),
        Flashcard("Bearer Token", "An access token valid for whoever holds it, like cash. Leaked via URLs, logs or referrers, it's replayable and survives a password reset until revoked.", .redTeam),
        Flashcard("Consent Phishing", "Tricking a user into clicking 'Allow' on a malicious OAuth app, granting it standing access (mailbox/files) — no password or MFA ever stolen.", .redTeam),
        Flashcard("IMDS", "Instance Metadata Service (169.254.169.254) — hands a cloud VM its config and its IAM role's temporary credentials. SSRF reaches it; IMDSv2 blunts that.", .redTeam),
        Flashcard("IAM Privilege Escalation", "Chaining cloud permissions (iam:PassRole, policy attachment, key creation) from a low-privilege role up to account admin.", .redTeam),
        Flashcard("Container Escape", "Breaking a container's namespace/cgroup isolation to run on the shared host kernel — via a mounted Docker socket, --privileged, capabilities or a host mount.", .redTeam),
        Flashcard("Docker Socket", "/var/run/docker.sock — control of it is root on the host. Mounted into a container, it lets you start a new container mounting the host's filesystem.", .redTeam),
        Flashcard("K8s Service-Account Token", "A pod's identity to the Kubernetes API server. With over-permissive RBAC it lists secrets, creates pods, or schedules a host-mounting pod — owning the cluster.", .redTeam),
        Flashcard("Subdomain Takeover", "A dangling DNS record points to a deprovisioned third-party service; claim that service and you control content on the victim's trusted subdomain.", .redTeam),
        Flashcard("HTTP Request Smuggling", "Front-end and back-end disagree on a request's length (CL vs TE), so smuggled bytes prepend to the next user's request — poisoning their traffic.", .redTeam),
        Flashcard("Race Condition (TOCTOU)", "Parallel requests slip through the gap between check and act (time-of-check to time-of-use), so a one-time action fires several times. Fix: atomicity/locks.", .redTeam),
        Flashcard("Web Shell", "A script an attacker uploads to a web server that runs OS commands over HTTP — interactive control of the host through the browser. Often via insecure file upload.", .redTeam),
        Flashcard("Certificate Pinning", "A mobile app hard-codes its server's certificate to block interception — but the check runs client-side, so Frida/Objection can hook it out on a rooted device.", .redTeam),

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
        Flashcard("Honeypot Account", "A deceptive, never-used account (often with a tempting SPN) whose every login or ticket request is high-signal evidence of an attacker.", .blueTeam),
        Flashcard("CTI", "Cyber Threat Intelligence — data about adversaries, analysed and aimed at a decision. Tiers: strategic (leadership), operational (TTPs), tactical (IOCs).", .blueTeam),
        Flashcard("STIX / TAXII", "Standard formats (STIX) and transport (TAXII) for sharing threat intelligence between organisations and tools in a machine-readable way.", .blueTeam),
        Flashcard("EPSS", "Exploit Prediction Scoring System — a probability (0–1) that a CVE will be exploited soon. Patch by likelihood, not just raw CVSS severity.", .blueTeam),
        Flashcard("CISA KEV", "The Known Exploited Vulnerabilities catalog — CVEs confirmed exploited in the wild. Treat anything on it as drop-everything, regardless of CVSS.", .blueTeam),
        Flashcard("Vulnerability Management", "The continuous loop of discover → assess → prioritise (by risk, not raw score) → remediate → verify. Success is fixing what matters, fast.", .blueTeam),
        Flashcard("Microsegmentation", "Splitting the network into small, individually-policed zones so one foothold can't roam — the Zero Trust control that directly blunts lateral movement.", .blueTeam),
        Flashcard("SPF", "Sender Policy Framework — a DNS list of IPs authorised to send mail for a domain; receivers reject mail from IPs not on it. Anti-spoofing layer one.", .blueTeam),
        Flashcard("DKIM", "DomainKeys Identified Mail — the sender cryptographically signs each message; receivers verify it with a DNS public key, proving origin and integrity (survives forwarding).", .blueTeam),
        Flashcard("DMARC", "Ties SPF/DKIM to the visible From: domain (alignment) and sets the policy on failure — none/quarantine/reject — plus reporting. p=reject is what actually stops domain spoofing.", .blueTeam),
        Flashcard("Canary Token", "A tripwire embedded in a file, link, API key or DNS name that silently alerts when accessed. No legitimate use → near-zero false positives; the attacker rarely knows they tripped it.", .blueTeam)
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
