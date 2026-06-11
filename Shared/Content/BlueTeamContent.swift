import Foundation

/// The Blue Team track — the defender's craft: building layered defenses,
/// turning telemetry into detections, hunting for what slipped through,
/// responding to incidents, and the forensic/malware skills behind it all.
enum BlueTeamContent {

    static let track = Track(
        id: "blue-team",
        kind: .blueTeam,
        title: "Blue Team",
        tagline: "Detect, respond, and outlast the adversary.",
        modules: [foundations, detection, response, forensics]
    )

    // MARK: B1 — Defensive foundations

    private static let foundations = Module(
        id: "blue-foundations",
        title: "Defensive Foundations",
        summary: "How defenders structure protection in layers, segment the network, harden Active Directory, and turn raw telemetry into alerts.",
        systemImage: "shield.lefthalf.filled",
        lessons: [defenseLesson, networkDefenseLesson, adDefenseLesson, siemLesson]
    )

    private static let defenseLesson = Lesson(
        id: "blue-defense-in-depth",
        title: "Defense in Depth & the SOC",
        subtitle: "No single wall holds — security is layers, watched by people and process.",
        minutes: 9,
        difficulty: .foundational,
        blocks: [
            .heading("Assume any one control will fail"),
            .paragraph("Defense in depth accepts that every individual control can be bypassed, so it stacks independent layers: an attacker must defeat all of them in sequence. Perimeter, network, endpoint, application, identity, and data each get their own protections — and crucially, their own *detection*. The goal isn't a perfect wall; it's making intrusion slow, noisy, and survivable."),
            .animation(.defenseInDepth, caption: "An attack probes concentric layers — perimeter, network, endpoint, identity, data — each adding friction and a chance to detect."),
            .keyPoints([
                "Perimeter — firewalls, email filtering, attack-surface reduction.",
                "Network — segmentation, IDS/IPS, zero-trust between segments.",
                "Endpoint — EDR, application allow-listing, patching.",
                "Identity — MFA, least privilege, tiered admin.",
                "Data — encryption, DLP, backups (your ransomware insurance).",
                "People & process — the SOC that monitors, and the playbooks they follow."
            ]),
            .definition(term: "SOC (Security Operations Center)", meaning: "The team (and tooling) that monitors an organization 24/7, triages alerts, and drives incident response. Typically tiered: T1 triage, T2 investigation, T3 hunting/engineering."),
            .callout(.tip, "Prevention reduces incidents; detection limits their damage. Mature programs invest in both — and measure themselves on mean time to detect (MTTD) and mean time to respond (MTTR)."),
            .definition(term: "Zero trust", meaning: "“Never trust, always verify.” Drop the idea of a safe internal network; authenticate and authorize every request as if it came from the open internet. Directly counters lateral movement."),
            .checkpoint(QuizQuestion(
                "What is the core philosophy behind defense in depth?",
                options: [
                    "One very strong firewall is enough",
                    "Assume each control can fail, so layer many independent ones",
                    "Detection matters more than prevention",
                    "Only endpoints need protection"
                ],
                correct: 1,
                why: "Defense in depth assumes any single layer can be bypassed and stacks independent controls so an attacker must defeat all of them — while each layer also offers a detection opportunity."))
        ],
        quiz: [
            QuizQuestion(
                "Network segmentation primarily frustrates which attacker activity?",
                options: ["Phishing", "Lateral movement", "Password cracking", "OSINT"],
                correct: 1,
                why: "Segmentation limits which hosts can talk to which, so a foothold in one zone can't freely pivot across the whole network — directly impeding lateral movement."),
            QuizQuestion(
                "MTTD and MTTR measure a SOC's…",
                options: [
                    "Budget and headcount",
                    "Mean time to detect and mean time to respond to incidents",
                    "Number of firewalls",
                    "Password length policy"
                ],
                correct: 1,
                why: "MTTD/MTTR quantify how quickly the team detects and contains incidents — core effectiveness metrics for security operations.")
        ]
    )

    private static let adDefenseLesson = Lesson(
        id: "blue-ad-defense",
        title: "Defending Active Directory",
        subtitle: "The other side of the AD attacks — tiered admin, hardening, and the events that catch each one.",
        minutes: 12,
        difficulty: .advanced,
        blocks: [
            .heading("Defending the thing attackers want most"),
            .paragraph("The Red Team track turns Active Directory inside out — Kerberoasting, AS-REP Roasting, DCSync, Golden Tickets, ACL attack paths, NTLM relay. Defending AD isn't about patching those away; most are protocol features. It's about **architecture that limits them** and **telemetry that catches them**. Get the structure right and a single compromised laptop stops being a straight line to Domain Admin."),
            .animation(.adTiering, caption: "Admin tiers keep Tier 0 (DCs, Domain Admins) credentials off lower-tier machines, so a stolen workstation credential can't climb to the domain's core."),
            .heading("Architecture: the tiered model"),
            .paragraph("The single highest-impact control is **tiered administration**. Split admin identities into tiers — Tier 0 (domain controllers, Domain Admins), Tier 1 (servers), Tier 2 (workstations) — and forbid a higher-tier credential from ever logging on to a lower tier. Now compromising a workstation can't yield Domain Admin creds, because they're never exposed there. It's the structural answer to credential theft and lateral movement."),
            .keyPoints([
                "Tiered admin — Tier 0 credentials never touch Tier 1/2 machines; separate accounts per tier.",
                "LAPS — unique, rotating local-admin passwords per machine, killing pass-the-hash reuse.",
                "gMSAs — long, auto-rotated service-account passwords that defeat Kerberoasting.",
                "Protected Users group + Credential Guard — keep credentials out of memory and reach.",
                "Disable LLMNR/NBT-NS and enforce SMB signing — shut down Responder and NTLM relay.",
                "Least privilege on ACLs — prune the GenericAll/WriteDACL edges BloodHound would find."
            ]),
            .heading("Detection: the events that betray each attack"),
            .paragraph("Each AD attack leaves a fingerprint if you're watching. The discipline is knowing which event maps to which technique — and alerting on the anomaly, not the everyday."),
            .terminal(prompt: "splunk-spl",
                      command: "index=wineventlog EventCode=4769 RC4_encryption | stats dc(Service) by Account",
                      output: """
Account        distinct_services
svc_helpdesk   42     <-- one account requesting many RC4 service tickets → Kerberoasting
"""),
            .keyPoints([
                "4769 (TGS requested), many services / RC4 from one account → Kerberoasting.",
                "4768 AS-REQ without pre-auth → AS-REP Roasting attempt.",
                "4662 replication (DRS) from a non-DC host → DCSync.",
                "4624/4625 patterns, unusual logon types across hosts → lateral movement / spraying.",
                "A honeypot account (fake SPN, never used) firing any event → a roaster caught red-handed."
            ]),
            .definition(term: "Tier 0", meaning: "The set of assets that control identity in the domain — Domain Controllers, the Domain Admins group, AD itself, and anything that can take over them. The entire defensive game is keeping Tier 0 credentials and access isolated from everything else."),
            .callout(.tip, "Honeypot (deceptive) accounts are cheap and high-signal: create a tempting fake service account with an SPN and a weak-looking password that no legitimate process ever uses. Any ticket request or logon for it is almost certainly an attacker enumerating or roasting."),
            .callout(.warning, "After a confirmed domain compromise, normal cleanup isn't enough. Golden Tickets persist until krbtgt is rotated twice, and DCSync rights may have been granted as backdoors. Recovery means resetting krbtgt (twice), auditing replication rights, and hunting for rogue ACLs and accounts."),
            .checkpoint(QuizQuestion(
                "Why does a tiered administration model blunt lateral movement to Domain Admin so effectively?",
                options: [
                    "It encrypts all passwords",
                    "High-tier credentials are never exposed on lower-tier machines, so compromising a workstation can't harvest Domain Admin creds",
                    "It blocks all network traffic",
                    "It disables Kerberos"
                ],
                correct: 1,
                why: "Lateral movement relies on finding privileged credentials on the machines you compromise. Tiering ensures Tier 0 creds never land on Tier 1/2 hosts, so a foothold there yields nothing that reaches the domain core."))
        ],
        quiz: [
            QuizQuestion(
                "Which control most directly defeats Kerberoasting of service accounts?",
                options: [
                    "Disabling DNS",
                    "Group Managed Service Accounts (gMSAs) with long, auto-rotated passwords",
                    "A longer screensaver timeout",
                    "Blocking ICMP"
                ],
                correct: 1,
                why: "Kerberoasting ends in offline cracking of a service account's password. gMSAs give 120+ character auto-rotated passwords, making the recovered ticket effectively uncrackable."),
            QuizQuestion(
                "Replication (event 4662 / DRS) originating from a host that isn't a Domain Controller most likely indicates…",
                options: [
                    "A normal backup",
                    "A DCSync attack — something is impersonating a DC to pull hashes",
                    "A failed login",
                    "A DNS update"
                ],
                correct: 1,
                why: "Only DCs should perform directory replication. A replication request from a workstation or server is a hallmark of DCSync and warrants immediate investigation."),
            QuizQuestion(
                "Disabling LLMNR/NBT-NS and enforcing SMB signing primarily defends against…",
                options: [
                    "Buffer overflows",
                    "Responder-style poisoning and NTLM relay",
                    "Phishing emails",
                    "SQL injection"
                ],
                correct: 1,
                why: "LLMNR/NBT-NS poisoning feeds Responder its captured hashes, and SMB signing blocks relaying them. Disabling the legacy fallbacks and enforcing signing removes both wins.")
        ]
    )

    private static let siemLesson = Lesson(
        id: "blue-siem",
        title: "Logging, Telemetry & the SIEM",
        subtitle: "You can't catch what you can't see — turning logs into detections.",
        minutes: 11,
        difficulty: .intermediate,
        blocks: [
            .heading("Visibility is the whole game"),
            .paragraph("Detection starts with telemetry: endpoint process events, authentication logs, DNS queries, network flows, cloud audit trails. A **SIEM** (Security Information and Event Management) centralizes this flood, normalizes it, and runs detection logic to raise alerts. Garbage in, garbage out — weak logging means blind defenders."),
            .animation(.siemPipeline, caption: "Logs stream from endpoints and servers into the SIEM, get normalized, match a detection rule, and fire a prioritized alert to an analyst."),
            .keyPoints([
                "Sources — Windows Event Logs, Sysmon, EDR, firewall, DNS, cloud (CloudTrail), auth (Okta/AD).",
                "Sysmon is the single highest-value free Windows telemetry source (process creation, network, image loads).",
                "Normalization maps every source into common fields so one rule covers many log types.",
                "Correlation links events across sources (a logon + a new service + an outbound connection).",
                "Alert fatigue is the enemy — tuning and prioritization keep analysts effective."
            ]),
            .terminal(prompt: "splunk-spl",
                      command: "index=win EventCode=4625 | stats count by src_ip | where count > 20",
                      output: """
src_ip          count
198.51.100.7    214     <-- 214 failed logons from one IP → brute force / spray
"""),
            .definition(term: "EDR (Endpoint Detection & Response)", meaning: "Agent software on endpoints that records detailed activity, detects malicious behavior, and lets responders isolate or remediate a host remotely. The modern successor to signature-only antivirus."),
            .callout(.warning, "Log retention matters: attackers often dwell for weeks or months. If you only keep 7 days of logs, you can't investigate a breach discovered on day 30. Aim for enough retention to cover realistic dwell time."),
            .checkpoint(QuizQuestion(
                "Why is Sysmon so valued by defenders on Windows?",
                options: [
                    "It blocks all malware automatically",
                    "It provides rich, detailed telemetry (process creation, network, image loads) that default logs lack",
                    "It encrypts the event log",
                    "It replaces the SIEM"
                ],
                correct: 1,
                why: "Sysmon greatly enriches Windows logging with the granular events (full command lines, parent/child processes, network connections) detections depend on — far beyond default auditing."))
        ],
        quiz: [
            QuizQuestion(
                "A SIEM's job is best described as…",
                options: [
                    "Centralizing and analyzing telemetry to detect and alert on threats",
                    "Encrypting all company data",
                    "Replacing the firewall",
                    "Cracking password hashes"
                ],
                correct: 0,
                why: "A SIEM aggregates and normalizes logs from many sources and applies detection logic to surface alerts for analysts — it's the SOC's analytical core."),
            QuizQuestion(
                "Event ID 4625 spiking from a single source IP most likely indicates…",
                options: [
                    "A successful login",
                    "Failed logon attempts — a brute-force or password-spray in progress",
                    "A software update",
                    "A DNS query"
                ],
                correct: 1,
                why: "4625 is the Windows failed-logon event. A burst from one IP across accounts is a classic brute-force/spray signature.")
        ]
    )

    private static let networkDefenseLesson = Lesson(
        id: "blue-network-defense",
        title: "Network Security & Firewalls",
        subtitle: "Shape the battlefield: segment the network so one foothold isn't game over.",
        minutes: 11,
        difficulty: .foundational,
        blocks: [
            .heading("Architecture is a control"),
            .paragraph("Detection catches attackers; architecture *limits* them. How you carve up a network decides how far a single compromised laptop can reach. The defender's goal is to make the easy attacker moves — scanning the whole network, pivoting host to host — slow, noisy, and walled off. You met this from the attacker's side as lateral movement; this is how the blue team strangles it."),
            .animation(.defenseInDepth, caption: "An intruder pushes inward through layered controls — and gets detected and contained before reaching the crown-jewel data."),
            .heading("Firewalls: the default-deny rule"),
            .paragraph("A firewall decides which traffic is allowed between zones. The single most important principle is **default deny**: block everything, then explicitly permit only what's needed. A rule set that ends in 'allow any any' has thrown away most of its value. Equally important — and far more often forgotten — is **egress filtering**: controlling what can leave. Most C2 and data exfiltration walks straight out an unrestricted outbound connection."),
            .terminal(prompt: "fw-admin",
                      command: "iptables -L OUTPUT -v --line-numbers",
                      output: """
Chain OUTPUT (policy DROP)
num  target  prot  dpt     comment
1    ACCEPT  tcp   443     /* allow HTTPS to update servers */
2    ACCEPT  udp   53      /* allow DNS to internal resolver */
3    DROP    all   --      /* everything else leaves nothing */
"""),
            .keyPoints([
                "Default deny — start by blocking all, then allowlist required flows only.",
                "Egress filtering — restrict outbound traffic; it's how you starve C2 and exfil.",
                "Stateful inspection — track connection state so replies are allowed but unsolicited inbound is not.",
                "A firewall is necessary but not sufficient — it doesn't see encrypted payloads or inside-the-perimeter movement."
            ]),
            .heading("Segmentation: blast-radius control"),
            .paragraph("A flat network — where every device can reach every other — means one phished workstation can talk directly to the domain controller, the database, and the backups. **Segmentation** splits the network into zones (user VLANs, server tiers, a DMZ for internet-facing services) with firewalls between them. Now an attacker who lands in the user zone hits a wall trying to reach the servers, and every attempt crosses a chokepoint you can monitor."),
            .definition(term: "DMZ (Demilitarized Zone)", meaning: "An isolated network segment for systems that must be reachable from the internet (web servers, mail). If one is compromised, segmentation stops the attacker from reaching the trusted internal network behind it."),
            .definition(term: "Zero Trust", meaning: "A model that drops the idea of a trusted 'inside'. Every request is authenticated and authorized regardless of network location — 'never trust, always verify' — so being on the LAN grants nothing by itself."),
            .callout(.tip, "Microsegmentation takes this to the extreme: policy per workload, so even two servers in the same tier can't talk unless explicitly allowed. It's the architectural answer to lateral movement."),
            .callout(.warning, "Segmentation is only real if it's enforced and tested. 'VLANs exist' is not segmentation if the firewall between them permits any-to-any. Validate it: try to reach the server zone from the user zone and confirm it's blocked."),
            .checkpoint(QuizQuestion(
                "An attacker phishes a user in the corporate VLAN and immediately tries to RDP to a database server in a separate, firewalled server zone — and fails. Which control stopped them?",
                options: [
                    "Antivirus on the workstation",
                    "Network segmentation between the user and server zones",
                    "A stronger password policy",
                    "Disk encryption"
                ],
                correct: 1,
                why: "The firewall between segments blocked the cross-zone connection. Segmentation contains the blast radius so a foothold in one zone can't freely reach another."))
        ],
        quiz: [
            QuizQuestion(
                "Why is egress (outbound) filtering so valuable against an active intrusion?",
                options: [
                    "It speeds up the network",
                    "It restricts the outbound channels attackers use for C2 and data exfiltration",
                    "It encrypts internal traffic",
                    "It replaces the need for logging"
                ],
                correct: 1,
                why: "Implants beacon out and stolen data leaves over outbound connections. Tightly controlling what's allowed to egress starves C2 and blocks exfiltration, even after a host is compromised."),
            QuizQuestion(
                "What is the core principle of a well-configured firewall rule set?",
                options: [
                    "Allow everything, then block known-bad",
                    "Default deny — block all, then explicitly permit only what's required",
                    "Only filter inbound traffic",
                    "Trust any device on the local network"
                ],
                correct: 1,
                why: "Default deny minimizes attack surface: nothing is permitted unless there's an explicit, justified rule. 'Allow then blocklist' inevitably misses something."),
            QuizQuestion(
                "The 'never trust, always verify' approach that grants no implicit trust based on network location is called…",
                options: ["Defense in depth", "Zero Trust", "A DMZ", "Default allow"],
                correct: 1,
                why: "Zero Trust authenticates and authorizes every request regardless of where it originates, removing the assumption that being 'inside' the network confers trust.")
        ]
    )

    // MARK: B2 — Detection

    private static let detection = Module(
        id: "blue-detection",
        title: "Detection Engineering",
        summary: "Model adversary behavior with MITRE ATT&CK, then write the rules that catch it.",
        systemImage: "scope",
        lessons: [mitreLesson, detEngLesson]
    )

    private static let mitreLesson = Lesson(
        id: "blue-mitre",
        title: "MITRE ATT&CK for Defenders",
        subtitle: "A shared map of how adversaries operate — and where your blind spots are.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("A common language for adversary behavior"),
            .paragraph("MITRE ATT&CK is a continuously-updated knowledge base of real-world adversary **Tactics** (the goal — e.g. Persistence) and **Techniques** (how they achieve it — e.g. Scheduled Task). It gives red and blue teams a shared vocabulary, and gives defenders a way to measure coverage: which techniques can we actually detect?"),
            .animation(.mitreAttack, caption: "An intrusion is plotted across the ATT&CK matrix tactic by tactic; mapped detections light up the techniques you can see — and expose the gaps you can't."),
            .keyPoints([
                "Tactics = the adversary's objectives (Initial Access, Execution, Persistence, Privilege Escalation, Defense Evasion, Credential Access, Discovery, Lateral Movement, Collection, C2, Exfiltration, Impact).",
                "Techniques/sub-techniques = the specific methods (T1059 Command & Scripting Interpreter, T1003 OS Credential Dumping…).",
                "Map your detections to the matrix to see coverage and prioritize gaps.",
                "Threat-intel reports describe actors in ATT&CK terms — so you can emulate exactly what targets you."
            ]),
            .definition(term: "ATT&CK Navigator", meaning: "A free tool for coloring the matrix — overlaying what a specific threat group uses, what you can detect, and where the overlap (and the dangerous gaps) sit. The backbone of coverage-driven defense."),
            .callout(.tip, "Don't chase 100% coverage. Prioritize the techniques used by the actors who realistically target your sector, and the choke points (like credential access) that many attack paths pass through."),
            .checkpoint(QuizQuestion(
                "In ATT&CK terms, “Kerberoasting” is a Technique. Which Tactic (goal) does it serve?",
                options: ["Initial Access", "Credential Access", "Exfiltration", "Impact"],
                correct: 1,
                why: "Kerberoasting harvests crackable credentials, so it falls under the Credential Access tactic — the 'why', with the technique being the 'how'."))
        ],
        quiz: [
            QuizQuestion(
                "What is the difference between a Tactic and a Technique in ATT&CK?",
                options: [
                    "They're the same thing",
                    "A Tactic is the adversary's goal; a Technique is the specific method to achieve it",
                    "A Technique is the goal; a Tactic is the tool",
                    "Tactics are for red teams, Techniques for blue teams"
                ],
                correct: 1,
                why: "Tactics are the 'why' (objectives like Persistence); Techniques are the 'how' (e.g. creating a scheduled task). Each technique maps to one or more tactics."),
            QuizQuestion(
                "How do defenders use the ATT&CK Navigator most effectively?",
                options: [
                    "To launch attacks",
                    "To visualize detection coverage and prioritize gaps against relevant threats",
                    "To store passwords",
                    "To replace their SIEM"
                ],
                correct: 1,
                why: "Overlaying threat-actor techniques against your own detection coverage reveals where you're blind and what to build next.")
        ]
    )

    private static let detEngLesson = Lesson(
        id: "blue-detection-engineering",
        title: "Detection Engineering",
        subtitle: "Write durable detections that catch behavior, not just yesterday's hash.",
        minutes: 11,
        difficulty: .advanced,
        blocks: [
            .heading("Signatures break; behavior persists"),
            .paragraph("Detecting a specific file hash catches one sample and nothing else — change a byte and it's invisible. Strong detection engineering targets **behavior** an attacker can't easily avoid: a Word document spawning PowerShell, `lsass` being accessed for memory, a service account suddenly requesting dozens of tickets. Sigma is a vendor-neutral rule format that compiles to many SIEM query languages."),
            .code(language: "yaml", """
title: Office App Spawning PowerShell (T1059.001)
logsource:
  category: process_creation
  product: windows
detection:
  selection:
    ParentImage|endswith:
      - '\\\\winword.exe'
      - '\\\\excel.exe'
    Image|endswith: '\\\\powershell.exe'
  condition: selection
level: high
"""),
            .keyPoints([
                "Detect behavior/TTPs, not static IOCs — it survives the attacker re-tooling.",
                "Map every rule to an ATT&CK technique for coverage tracking.",
                "Balance true positives vs false positives — a noisy rule gets ignored.",
                "Test detections by emulating the technique (Atomic Red Team) and confirming they fire.",
                "The Pyramid of Pain: forcing attackers to change TTPs hurts them far more than blocking a hash or IP."
            ]),
            .definition(term: "IOC vs TTP", meaning: "Indicators of Compromise (hashes, IPs, domains) are cheap for attackers to change. Tactics, Techniques & Procedures describe behavior — costly to change. Detections built on TTPs age far better."),
            .callout(.tip, "A great detection-engineering loop: pick an ATT&CK technique → emulate it with Atomic Red Team on a test host → confirm the telemetry exists → write & tune the rule → deploy → measure. Repeat across the matrix."),
            .checkpoint(QuizQuestion(
                "Why is detecting `winword.exe` spawning `powershell.exe` a strong detection?",
                options: [
                    "PowerShell is always malicious",
                    "It targets a behavior common to macro-based attacks that's rare in normal use, so it survives attacker re-tooling",
                    "It matches a specific file hash",
                    "Word never runs on real machines"
                ],
                correct: 1,
                why: "Office apps launching script interpreters is a hallmark of malicious macros and uncommon in benign activity. Being behavior-based, it keeps working even when the attacker changes their payload."))
        ],
        quiz: [
            QuizQuestion(
                "According to the Pyramid of Pain, which is MOST painful for an attacker to change?",
                options: ["A file hash", "An IP address", "A domain name", "Their tools, tactics and procedures (TTPs)"],
                correct: 3,
                why: "Hashes, IPs and domains are trivially swapped. Forcing attackers to change how they operate (TTPs) imposes real cost — the top of the pyramid."),
            QuizQuestion(
                "What does the Sigma format provide?",
                options: [
                    "A vendor-neutral detection rule that compiles to many SIEM query languages",
                    "An exploit framework",
                    "A password cracker",
                    "An encryption standard"
                ],
                correct: 0,
                why: "Sigma is to logs what Snort is to packets: a generic, shareable rule format that converts into Splunk, Elastic, Sentinel and other backends.")
        ]
    )

    // MARK: B3 — Hunting & response

    private static let response = Module(
        id: "blue-response",
        title: "Threat Hunting & Incident Response",
        summary: "Proactively hunt for what alerts missed, then run a disciplined response when something's real.",
        systemImage: "magnifyingglass",
        lessons: [huntingLesson, irLesson]
    )

    private static let huntingLesson = Lesson(
        id: "blue-threat-hunting",
        title: "Threat Hunting",
        subtitle: "Assume breach. Go looking for the adversary your alerts didn't catch.",
        minutes: 10,
        difficulty: .advanced,
        blocks: [
            .heading("Hunting starts with a hypothesis"),
            .paragraph("Alerting is reactive — it waits for a rule to fire. Threat hunting is proactive: you *assume* an attacker is already inside and go searching. Good hunts start from a hypothesis (“if an adversary used Kerberoasting, I'd see one account requesting many service tickets”) and test it against your telemetry. Findings either uncover an intrusion or become a brand-new detection rule."),
            .animation(.threatHunting, caption: "The hunt loop: form a hypothesis from ATT&CK, query the data, investigate outliers, then harden it into an automated detection."),
            .keyPoints([
                "Hypothesis-driven — pick a technique and predict the evidence it leaves.",
                "Intel-driven — hunt for the TTPs of an actor known to target your sector.",
                "Anomaly-driven — surface statistical outliers (rare parent/child processes, odd beacon timing).",
                "Every successful hunt should graduate into an automated detection so you never hunt the same thing twice."
            ]),
            .terminal(prompt: "kql",
                      command: "DeviceProcessEvents | where InitiatingProcessFileName in ('winword.exe','excel.exe') and FileName == 'powershell.exe'",
                      output: """
Timestamp            DeviceName   InitiatingProcess  FileName
2026-06-09 14:22:11  HR-LT-08     winword.exe        powershell.exe   <-- investigate
"""),
            .definition(term: "Dwell time", meaning: "How long an attacker remains undetected in an environment. Hunting exists to drive this number down — finding intruders who evaded automated detection before they reach their objective."),
            .callout(.tip, "Hunting and detection engineering are two halves of one wheel: hunts discover new adversary behavior, and that behavior becomes tomorrow's automated detection. Over time your blind spots shrink."),
            .checkpoint(QuizQuestion(
                "How is threat hunting fundamentally different from alerting?",
                options: [
                    "Hunting is automated; alerting is manual",
                    "Hunting proactively assumes a breach and searches for it, rather than waiting for a rule to fire",
                    "Hunting only uses antivirus",
                    "They are identical"
                ],
                correct: 1,
                why: "Alerting is reactive — it triggers on known rules. Hunting is proactive and hypothesis-driven, deliberately searching for adversaries that evaded those rules."))
        ],
        quiz: [
            QuizQuestion(
                "What should ideally happen after a successful threat hunt finds a new adversary behavior?",
                options: [
                    "Nothing; the hunt is over",
                    "It's turned into an automated detection so it's caught next time",
                    "The logs are deleted",
                    "The hunter stops hunting"
                ],
                correct: 1,
                why: "Findings should graduate into detection rules, continuously expanding automated coverage and shrinking the team's blind spots."),
            QuizQuestion(
                "“Dwell time” refers to…",
                options: [
                    "How long a scan takes",
                    "How long an attacker stays undetected in the environment",
                    "Log retention period",
                    "Time to crack a password"
                ],
                correct: 1,
                why: "Dwell time is the window between compromise and detection. Reducing it limits how far an attacker can progress — a key objective of hunting.")
        ]
    )

    private static let irLesson = Lesson(
        id: "blue-incident-response",
        title: "Incident Response Lifecycle",
        subtitle: "When it's real, calm process beats panic — the six-phase playbook.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("A repeatable process for the worst day"),
            .paragraph("Incident response is what turns a breach from a catastrophe into a managed event. The SANS/NIST lifecycle gives a disciplined loop so responders act deliberately under pressure instead of improvising. Each phase has a clear goal, and the cycle feeds back: every incident makes you better prepared for the next."),
            .animation(.incidentResponse, caption: "Move through the IR lifecycle — Preparation, Identification, Containment, Eradication, Recovery, Lessons Learned — as a cycle that feeds back into readiness."),
            .keyPoints([
                "Preparation — tooling, playbooks, training, and backups before anything happens.",
                "Identification — confirm it's a real incident and scope it.",
                "Containment — stop the bleeding (isolate hosts, disable accounts) without tipping off the attacker prematurely.",
                "Eradication — remove the foothold: malware, persistence, attacker accounts.",
                "Recovery — restore systems and verify they're clean before returning to production.",
                "Lessons Learned — the post-incident review that improves Preparation."
            ]),
            .callout(.warning, "Resist the urge to “pull the plug” instantly. Premature, sloppy containment can tip off the attacker (who burns you down) or destroy volatile forensic evidence in memory. Contain deliberately, preserving evidence."),
            .definition(term: "Containment strategy", meaning: "The decision of how and when to cut the attacker off — balancing stopping damage against preserving evidence and not alerting them. Short-term (isolate a host) vs long-term (rebuild) containment."),
            .definition(term: "Order of volatility", meaning: "Collect evidence from most to least volatile — memory and network state first (they vanish on reboot), disk and logs later. Critical to forensic integrity during Containment."),
            .checkpoint(QuizQuestion(
                "During Containment, why shouldn't you always immediately power off a compromised machine?",
                options: [
                    "It wastes electricity",
                    "You may destroy volatile evidence in memory and tip off the attacker",
                    "It's never possible",
                    "Power-off makes things worse for the attacker only"
                ],
                correct: 1,
                why: "A hard power-off wipes RAM (where live malware, keys and network state live) and can alert the adversary. Deliberate containment preserves volatile evidence and timing."))
        ],
        quiz: [
            QuizQuestion(
                "Which IR phase produces the post-incident review that improves future readiness?",
                options: ["Identification", "Containment", "Recovery", "Lessons Learned"],
                correct: 3,
                why: "Lessons Learned closes the loop, feeding findings back into Preparation so the team handles the next incident better."),
            QuizQuestion(
                "Removing the attacker's malware, persistence mechanisms and rogue accounts is which phase?",
                options: ["Containment", "Eradication", "Recovery", "Identification"],
                correct: 1,
                why: "Eradication is the removal of the root cause and all attacker artifacts. Recovery then restores clean systems to operation.")
        ]
    )

    // MARK: B4 — Forensics & malware

    private static let forensics = Module(
        id: "blue-forensics",
        title: "Forensics & Malware Analysis",
        summary: "Reconstruct what happened from the evidence, and safely dissect malicious code.",
        systemImage: "doc.text.magnifyingglass",
        lessons: [forensicsLesson, malwareLesson]
    )

    private static let forensicsLesson = Lesson(
        id: "blue-forensics-essentials",
        title: "Digital Forensics Essentials",
        subtitle: "Every action leaves a trace — learn to read the evidence.",
        minutes: 10,
        difficulty: .advanced,
        blocks: [
            .heading("Reconstructing the story"),
            .paragraph("Digital forensics recovers and interprets the artifacts a system records so you can answer: what happened, when, by whom, and what was taken? Done right it stands up in court, which means evidence handling — imaging, hashing, chain of custody — is as important as the analysis itself."),
            .keyPoints([
                "Image first — work on a verified copy (hash it before and after), never the original.",
                "Memory forensics (Volatility) — running processes, injected code, network connections, keys.",
                "Disk artifacts — file system timelines (MFT), deleted files, shadow copies.",
                "Windows gold mines — Event Logs, Prefetch, ShimCache/AmCache, registry run keys, browser history.",
                "Build a timeline — correlate artifacts into a single sequence of events."
            ]),
            .terminal(prompt: "kali@lab",
                      command: "vol.py -f memory.raw windows.pslist; vol.py -f memory.raw windows.netscan",
                      output: """
PID   PPID  ImageFileName
4012  664   svchost.exe
4188  4012  powershell.exe   <-- spawned by svchost? suspicious
ForeignAddr      State        Owner
45.77.x.x:443    ESTABLISHED  powershell.exe   <-- beaconing
"""),
            .definition(term: "Chain of custody", meaning: "A documented, unbroken record of who handled evidence, when, and how — proving it wasn't altered. Without it, even perfect technical findings can be inadmissible."),
            .callout(.warning, "Always hash evidence (e.g. SHA-256) immediately after acquisition and verify the hash matches before and after analysis. A mismatch means the evidence was modified — and its integrity is gone."),
            .definition(term: "Order of volatility", meaning: "Capture the most ephemeral data first: CPU/registers and RAM, then network state, then disk, then backups. Memory vanishes on power-off, so it's collected before imaging disk."),
            .checkpoint(QuizQuestion(
                "Why hash a forensic disk image immediately after creating it?",
                options: [
                    "To compress it",
                    "To prove integrity — any later change to the evidence would alter the hash",
                    "To encrypt the data",
                    "To speed up analysis"
                ],
                correct: 1,
                why: "A cryptographic hash fingerprints the image. Re-hashing later and matching the original proves the evidence wasn't altered — central to admissibility."))
        ],
        quiz: [
            QuizQuestion(
                "Which evidence should be collected first, following the order of volatility?",
                options: ["A disk image", "RAM / memory", "Backup tapes", "Printed logs"],
                correct: 1,
                why: "Memory is the most volatile — it's lost on power-off and holds live processes, keys and network state. Capture it before the less-volatile disk."),
            QuizQuestion(
                "Finding `powershell.exe` with an ESTABLISHED connection to an unknown external IP in a memory dump suggests…",
                options: [
                    "A Windows update",
                    "Possible C2 beaconing from a malicious process",
                    "A printer driver",
                    "Normal browsing"
                ],
                correct: 1,
                why: "PowerShell maintaining an external connection — especially if oddly parented — is a hallmark of fileless malware/C2 and warrants immediate investigation.")
        ]
    )

    private static let malwareLesson = Lesson(
        id: "blue-malware",
        title: "Intro to Malware Analysis",
        subtitle: "Safely figure out what a malicious sample does — without letting it loose.",
        minutes: 11,
        difficulty: .expert,
        blocks: [
            .heading("Static vs dynamic"),
            .paragraph("Malware analysis answers: what does this thing do, how do we detect it, and how do we clean it up? **Static analysis** examines the sample without running it (strings, headers, disassembly). **Dynamic analysis** detonates it in an isolated sandbox and watches its behavior — files dropped, registry changes, network callbacks. The two complement each other."),
            .keyPoints([
                "Isolate first — analyze in a disposable VM with no path to real networks. Malware escapes carelessness.",
                "Static: `strings`, file headers (PE), packers, hashes, import tables, disassembly (Ghidra/IDA).",
                "Dynamic: run in a sandbox (Cuckoo/ANY.RUN-style), watch process/file/registry/network behavior.",
                "Extract IOCs and, better, behavioral signatures to feed detection.",
                "Watch for evasion — malware that detects VMs/sandboxes and stays dormant."
            ]),
            .terminal(prompt: "kali@vm",
                      command: "strings -n 8 sample.bin | grep -Ei 'http|\\.exe|cmd|powershell'",
                      output: """
http://45.77.x.x/gate.php      <-- C2 URL
powershell -enc JABz...        <-- encoded payload
schtasks /create /tn Updater   <-- persistence (scheduled task)
"""),
            .definition(term: "Detonation sandbox", meaning: "An instrumented, isolated environment that runs a sample and records everything it does. Gives behavioral intelligence quickly — but must be isolated, because you are deliberately executing live malware."),
            .callout(.danger, "Never analyze live malware on your real machine or a network that can reach production or the internet unfiltered. Use a snapshot-able, isolated VM you can revert — and assume the sample is actively trying to escape and detect you."),
            .checkpoint(QuizQuestion(
                "What's the key difference between static and dynamic malware analysis?",
                options: [
                    "Static runs the malware; dynamic does not",
                    "Static examines the sample without executing it; dynamic observes its behavior while it runs in a sandbox",
                    "They are the same",
                    "Dynamic only works on Linux"
                ],
                correct: 1,
                why: "Static analysis inspects the file at rest (strings, headers, disassembly); dynamic analysis executes it in isolation and records its runtime behavior. Used together they give the full picture."))
        ],
        quiz: [
            QuizQuestion(
                "Why must dynamic analysis happen in an isolated, revertible VM?",
                options: [
                    "It runs faster there",
                    "You're executing live malware that may spread, exfiltrate, or detect its environment",
                    "Sandboxes are free",
                    "Windows requires it"
                ],
                correct: 1,
                why: "Detonating real malware risks infection, lateral spread and data theft. Isolation plus snapshots contains the damage and lets you reset between runs."),
            QuizQuestion(
                "Running `strings` on a sample and finding a URL and a `schtasks /create` command reveals…",
                options: [
                    "Nothing useful",
                    "Likely C2 infrastructure and a persistence mechanism — useful IOCs/behaviors",
                    "The author's name",
                    "The encryption key only"
                ],
                correct: 1,
                why: "Readable strings often leak C2 URLs, commands and techniques (here, scheduled-task persistence) — fast, valuable leads even before disassembly.")
        ]
    )
}
