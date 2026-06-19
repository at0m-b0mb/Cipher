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
        Flashcard("Process vs Program", "A program is a file on disk; a process is that program loaded into memory and executing, with its own isolated virtual memory.", .fundamentals),
        Flashcard("Stack vs Heap", "The stack grows down, one frame per function call (locals + return address); the heap grows up with dynamic allocations (malloc/new).", .fundamentals),
        Flashcard("User vs Kernel Mode", "Apps run in restricted user mode; the kernel runs with full hardware control. A system call is the controlled doorway between them.", .fundamentals),
        Flashcard("System Call", "The interface a user-mode program uses to ask the kernel for privileged work — file, memory, process and network operations.", .fundamentals),
        Flashcard("PKI", "Public Key Infrastructure — binds public keys to identities via certificates signed by trusted Certificate Authorities.", .fundamentals),
        Flashcard("Certificate Authority", "A trusted org that verifies an identity and signs its certificate. Browsers ship with a trust store of root CAs.", .fundamentals),
        Flashcard("Chain of Trust", "Root CA signs intermediate signs the server's leaf cert; the browser validates the chain up to a trusted root.", .fundamentals),
        Flashcard("Self-Signed Cert", "A certificate signed by its own key, not a CA. It encrypts but proves no identity, so browsers warn. Fine for internal testing only.", .fundamentals),

        // Networking
        Flashcard("Node & Link", "A node is any device on a network (laptop, phone, server, router); a link is the connection between nodes — copper, fibre or radio.", .networking),
        Flashcard("LAN vs WAN", "A LAN is a local network in one place (your home Wi-Fi); a WAN spans distance. The internet is a global WAN of WANs.", .networking),
        Flashcard("Packet", "The small unit data is chopped into for transport. Packets travel independently and are reassembled at the destination — only lost ones need resending.", .networking),
        Flashcard("Encapsulation", "Each layer wrapping the data above it in its own header as it heads down the stack: a segment inside a packet inside a frame. Reversed on receipt.", .networking),
        Flashcard("IPv4 / IPv6", "IPv4 is a 32-bit address in four dotted octets (192.168.1.42); IPv6 is 128-bit in hex groups (2001:db8::1) to escape IPv4 exhaustion.", .networking),
        Flashcard("MAC Address", "A 48-bit hardware address burned into a network card, unique per device. Used for delivery on the local link; unlike the IP, it doesn't change network to network.", .networking),
        Flashcard("Private IP Ranges", "10.0.0.0/8, 172.16.0.0/12 and 192.168.0.0/16 — reused inside every LAN and never routed on the public internet. NAT bridges them outward.", .networking),
        Flashcard("Subnet Mask", "Marks which bits of an IP are the network part (1s) and which are the host part (0s) — defining who is on the same local network.", .networking),
        Flashcard("CIDR", "Slash notation for the number of network bits: 192.168.1.0/24 = first 24 bits network, 8 host bits = 254 usable hosts.", .networking),
        Flashcard("DNS", "The internet's phonebook: resolves a name (shop.com) to an IP. A resolver walks root → TLD → authoritative, then caches the answer for its TTL.", .networking),
        Flashcard("A Record / CNAME", "An A record maps a name to an IPv4 address (AAAA = IPv6); a CNAME aliases one name to another, which is followed until it lands on an address.", .networking),
        Flashcard("Switch vs Router", "A switch forwards frames by MAC inside one LAN (L2); a router forwards packets by IP between networks (L3).", .networking),
        Flashcard("Default Gateway", "The router IP a device sends all off-subnet traffic to. Same-subnet traffic goes direct via the switch; everything else exits via the gateway.", .networking),
        Flashcard("ARP", "Address Resolution Protocol — the 'who has this IP? tell me your MAC' broadcast that maps a known IP to a hardware address on the local network.", .networking),
        Flashcard("TTL", "Time To Live — a hop counter every router decrements; at zero the packet is dropped, preventing loops. Traceroute exploits it to map each hop.", .networking),
        Flashcard("Traceroute", "Maps the routers between you and a destination by sending packets with increasing TTL, so each expires one hop further and reveals itself.", .networking),
        Flashcard("NAT", "Network Address Translation — many private devices share one public IP as the router rewrites address+port outbound and reverses it inbound.", .networking),
        Flashcard("Port Forwarding", "A manual router rule that sends a chosen inbound public port to a specific internal device — poking a hole through NAT to self-host a service.", .networking),
        Flashcard("DHCP (DORA)", "Auto-assigns a device its IP, gateway and DNS in four steps — Discover, Offer, Request, Acknowledge — so joining a network just works.", .networking),
        Flashcard("TCP vs UDP", "TCP is reliable, ordered and acknowledged (web, files, email); UDP is fast, connectionless and best-effort (video, voice, gaming, DNS).", .networking),
        Flashcard("Port", "A 16-bit number (0–65535) identifying a service on a host so one IP runs many: HTTP 80, HTTPS 443, SSH 22, DNS 53.", .networking),
        Flashcard("HTTP vs HTTPS", "HTTP is the plaintext request/response protocol of the web; HTTPS is the same wrapped in TLS encryption — the browser padlock.", .networking),
        Flashcard("SSID", "The broadcast name of a Wi-Fi network you select from the list. Securing the air link is the separate job of WPA2/WPA3.", .networking),
        Flashcard("WPA2 / WPA3", "The encryption protecting a Wi-Fi link's radio traffic. Open (passwordless) Wi-Fi leaves that link unencrypted — hence the need for a VPN.", .networking),
        Flashcard("Firewall", "A gatekeeper that allows or drops packets against a ruleset (by IP and port). Best practice is default-deny: block all, allow only what's needed.", .networking),
        Flashcard("VPN", "A Virtual Private Network builds an encrypted tunnel to a VPN server, hiding your traffic from the network in between and masking your IP. Not full anonymity.", .networking),

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
        Flashcard("Metasploit", "The best-known exploitation framework: a library of exploit, payload, auxiliary and post modules wired together to go from vulnerability to shell quickly.", .redTeam),
        Flashcard("Staged Payload", "A payload split in two: a tiny stager lands first and calls back to download the full second stage (e.g. Meterpreter) — useful when buffer space is tight.", .redTeam),
        Flashcard("Meterpreter", "Metasploit's in-memory, extensible post-exploitation agent — file access, pivoting, keylogging and more, without writing a binary to disk.", .redTeam),
        Flashcard("msfvenom", "Metasploit's standalone payload generator and encoder — builds reverse shells and other payloads as exe/elf/scripts for use outside the console.", .redTeam),
        Flashcard("GTFOBins", "A catalog of legit Unix binaries (find, vim, awk, tar…) that can be abused — when SUID or sudo-runnable — to break out, read/write files, or get root.", .redTeam),
        Flashcard("SUID Abuse", "A SUID binary runs as its owner (often root). If it can run commands or read/write files, it becomes a direct privilege-escalation path.", .redTeam),
        Flashcard("sudo -l", "Lists what the current user may run via sudo. NOPASSWD entries and exploitable binaries here are a primary Linux privesc lead.", .redTeam),
        Flashcard("SeImpersonatePrivilege", "A Windows privilege held by service accounts that allows impersonating a token — the basis of the 'Potato' attacks that escalate to SYSTEM.", .redTeam),
        Flashcard("Potato Attacks", "JuicyPotato/PrintSpoofer/RoguePotato — coerce a SYSTEM service to authenticate, then impersonate its token, turning a service account into SYSTEM.", .redTeam),
        Flashcard("Unquoted Service Path", "A Windows service path with spaces and no quotes; Windows may run an attacker binary planted earlier in the path, as the service's account.", .redTeam),
        Flashcard("NT AUTHORITY\\SYSTEM", "The most privileged local Windows account (services run as it) — the usual objective of Windows privilege escalation.", .redTeam),
        Flashcard("DNS Tunneling", "Exfiltration that encodes stolen data into DNS query names (chunk.evil.com) so it leaves via the almost-always-allowed port 53 to the attacker's name server.", .redTeam),
        Flashcard("Covert Channel", "A communication path that hides data in something normally trusted (DNS, ICMP, HTTPS to a clean domain) to evade egress filtering and DLP.", .redTeam),
        Flashcard("Beaconing & Jitter", "An implant's scheduled C2 check-in; random jitter (e.g. 60s ±40%) breaks the clockwork pattern that detection analytics flag.", .redTeam),
        Flashcard("Supply Chain Attack", "Compromise something the target trusts — a library, update or build system — so malicious code arrives signed and expected (e.g. SolarWinds).", .redTeam),
        Flashcard("Dependency Confusion", "Publish a public package matching an internal name with a higher version; misconfigured resolvers pick it and run the attacker's code in CI.", .redTeam),
        Flashcard("Typosquatting", "Registering a package/domain name a typo away from a popular one (reqeusts vs requests) so a slip installs malware.", .redTeam),
        Flashcard("Reverse Engineering", "Working out what a compiled program does with no source — static disassembly (Ghidra/IDA) plus dynamic debugging (gdb/x64dbg).", .redTeam),
        Flashcard("Patching a Jump", "The classic crack: overwrite a conditional branch (jne→nop/jmp) so a license/auth check's result no longer matters and the protected path always runs.", .redTeam),
        Flashcard("Padding Oracle", "A server leaking valid/invalid CBC padding becomes a decryption oracle — recovering plaintext one byte at a time with no key. Fixed by AEAD.", .redTeam),
        Flashcard("Nonce/IV Reuse", "Reusing a nonce in GCM or a stream cipher breaks the mode's guarantees, potentially leaking plaintext relationships or the auth key.", .redTeam),
        Flashcard("AiTM Phishing", "Adversary-in-the-Middle: a reverse proxy (Evilginx) relays the live login AND the MFA code, then steals the session cookie — bypassing MFA.", .redTeam),
        Flashcard("Session Cookie Theft", "Stealing the post-login cookie that IS the authenticated session lets an attacker replay it as the user — no password, no MFA prompt — until it's revoked.", .redTeam),
        Flashcard("Phishing-Resistant MFA", "FIDO2/WebAuthn passkeys bind authentication to the real site's origin, so an AiTM proxy on another domain can't complete the login. The counter to AiTM.", .redTeam),
        Flashcard("Prompt Injection", "Hiding instructions in data an LLM ingests so it follows them — the AI-era SQL injection. Indirect injection plants them in fetched web/email/files.", .redTeam),
        Flashcard("Indirect Prompt Injection", "Adversarial instructions planted in third-party content (a page, PDF, invite) that an AI later processes — hijacking it without ever talking to the model.", .redTeam),

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
        Flashcard("Canary Token", "A tripwire embedded in a file, link, API key or DNS name that silently alerts when accessed. No legitimate use → near-zero false positives; the attacker rarely knows they tripped it.", .blueTeam),
        Flashcard("NSM", "Network Security Monitoring — watching the wire for intrusions the endpoint missed. Attackers can blind an EDR agent, but they still have to talk on the network.", .blueTeam),
        Flashcard("IDS vs IPS", "An IDS inspects a copy of traffic and ALERTS (out-of-band); an IPS sits inline and can BLOCK malicious traffic in real time.", .blueTeam),
        Flashcard("Signature vs Anomaly", "Signature detection matches known-bad patterns (precise, blind to novelty); anomaly detection flags deviation from a baseline (catches the unknown, noisier).", .blueTeam),
        Flashcard("Zeek", "A network monitor that turns raw traffic into rich connection logs — who talked to whom, DNS, certs, files — invaluable for hunting and investigation.", .blueTeam),
        Flashcard("JA3 / JA4", "A fingerprint of a TLS client's handshake. Because payloads are encrypted, these fingerprints help spot malicious encrypted traffic without decrypting it.", .blueTeam),
        Flashcard("Shift Left", "Catch security issues early in development — design, code, build pipeline — where they're far cheaper to fix than after a production breach.", .blueTeam),
        Flashcard("SAST vs DAST", "SAST analyzes source code statically (no run); DAST attacks the running application from the outside. Different bug classes — used together.", .blueTeam),
        Flashcard("SCA", "Software Composition Analysis — flags known-vulnerable third-party libraries. Often the highest-value gate, since most code is dependencies.", .blueTeam),
        Flashcard("SBOM", "Software Bill of Materials — a full inventory of components/dependencies so you can answer 'are we affected?' fast when the next Log4j drops.", .blueTeam),
        Flashcard("Shared Responsibility", "The cloud provider secures the infrastructure; the customer secures their data, identities and configuration. Most cloud breaches are customer misconfigurations.", .blueTeam),
        Flashcard("CSPM", "Cloud Security Posture Management — continuously scans cloud accounts for misconfigurations (public buckets, over-broad roles, disabled logging) and drift from a secure baseline.", .blueTeam),
        Flashcard("IAM Least Privilege", "Grant the minimum permissions needed, scoped to specific resources. Identity is the cloud's perimeter — it contains the blast radius of any leaked key.", .blueTeam)
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
