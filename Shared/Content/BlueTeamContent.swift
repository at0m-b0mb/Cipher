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
        modules: [foundations, detection, nsm, response, modernDefense, appcloud, forensics]
    )

    // MARK: B1 — Defensive foundations

    private static let foundations = Module(
        id: "blue-foundations",
        title: "Defensive Foundations",
        summary: "How defenders structure protection in layers, segment the network, harden Active Directory, and turn raw telemetry into alerts.",
        systemImage: "shield.lefthalf.filled",
        lessons: [defenseLesson, networkDefenseLesson, emailAuthLesson, adDefenseLesson, siemLesson]
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

    // MARK: B-MOD — Modern Defense

    private static let modernDefense = Module(
        id: "blue-modern",
        title: "Modern Defense",
        summary: "Defending today's environment — turning adversary data into intelligence, prioritising the vulnerabilities that matter, and the zero-trust model that assumes the perimeter has already failed.",
        systemImage: "shield.checkerboard",
        lessons: [threatIntelLesson, vulnMgmtLesson, deceptionLesson, zeroTrustLesson]
    )

    private static let threatIntelLesson = Lesson(
        id: "blue-threat-intel",
        title: "Cyber Threat Intelligence",
        subtitle: "Raw data isn't intelligence. Intelligence is data, analysed and aimed at a decision.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("Knowing your adversary"),
            .paragraph("Cyber Threat Intelligence (CTI) is the discipline of collecting and analysing information about threats so defenders can act *before* they're hit — or respond faster when they are. The point isn't to hoard indicators; it's to answer a decision-maker's question. A feed of a million IPs is data. 'This ransomware crew is targeting our sector via this technique, so prioritise these detections' is intelligence."),
            .animation(.threatIntel, caption: "The intelligence lifecycle as a loop: direction → collection → processing → analysis → dissemination → feedback, then around again."),
            .heading("Three altitudes of intel"),
            .keyPoints([
                "Strategic — big-picture risk for leadership: who targets our industry, and why. Drives budget and posture.",
                "Operational — campaigns and adversary TTPs (tactics, techniques, procedures); feeds threat hunting and detection.",
                "Tactical — the technical specifics: IOCs like hashes, domains, IPs; feeds the SIEM and EDR directly.",
                "The Pyramid of Pain — hashes/IPs are trivial for an attacker to change; TTPs are painful. Detect on behaviour to hurt them most.",
                "Frameworks — MITRE ATT&CK for TTPs, STIX/TAXII to share it, the Diamond Model to structure an intrusion."
            ]),
            .definition(term: "IOC vs TTP", meaning: "An Indicator of Compromise is an artifact of a specific attack — a file hash, C2 domain, IP. A TTP is the adversary's behaviour — how they phish, escalate, persist. IOCs are easy to detect but easy for the attacker to change; TTPs are harder to detect but far harder for them to alter, so behaviour-based detection has lasting value."),
            .terminal(prompt: "analyst",
                      command: "# enrich an observable seen in the SIEM before acting on it\nvt lookup 3aa1f... ; whois evil-c2[.]net ; check-misp 185.x.x.x",
                      output: """
hash 3aa1f...   -> 48/72 vendors: Qakbot loader
domain evil-c2  -> registered 3 days ago, fast-flux
185.x.x.x       -> in 2 threat-intel feeds, tagged 'Qakbot C2'
# verdict: active campaign IOC — hunt for this TTP across the fleet
"""),
            .callout(.tip, "Climb the Pyramid of Pain: blocking a hash stops one file; detecting the *behaviour* (e.g. Office spawning PowerShell that beacons out) stops the whole technique no matter how the attacker repackages it."),
            .callout(.warning, "Intelligence has a shelf life and a source-reliability problem. An IOC can be stale or shared (a CDN IP) and cause false positives; always weigh source confidence and context before you block or alert on it."),
            .checkpoint(QuizQuestion(
                "According to the Pyramid of Pain, why is detecting an adversary's TTPs more valuable than blocking their file hashes?",
                options: [
                    "Hashes are illegal to store",
                    "Hashes and IPs are trivial for the attacker to change; TTPs describe behaviour that's painful for them to alter, so behavioural detection lasts",
                    "TTPs are easier to collect",
                    "Hashes can't be detected"
                ],
                correct: 1,
                why: "An attacker can recompile a file or rotate an IP in seconds, but changing how they operate is costly. Detecting on TTPs/behaviour forces real effort on them and keeps working across campaigns."))
        ],
        quiz: [
            QuizQuestion(
                "What distinguishes intelligence from raw data?",
                options: [
                    "Intelligence is encrypted",
                    "Intelligence is data that's been analysed and aimed at supporting a specific decision",
                    "Intelligence is always free",
                    "There is no difference"
                ],
                correct: 1,
                why: "A feed of indicators is data. Intelligence applies analysis and context to answer a decision-maker's question — what to prioritise, block, or hunt for."),
            QuizQuestion(
                "Which intel level feeds IOCs directly into a SIEM/EDR for automated matching?",
                options: ["Strategic", "Operational", "Tactical", "Executive"],
                correct: 2,
                why: "Tactical intelligence is the technical, machine-consumable layer — hashes, domains, IPs — that tooling ingests to match against telemetry automatically.")
        ]
    )

    private static let vulnMgmtLesson = Lesson(
        id: "blue-vuln-mgmt",
        title: "Vulnerability Management",
        subtitle: "You can't patch everything at once. The skill is knowing what to fix first.",
        minutes: 9,
        difficulty: .intermediate,
        blocks: [
            .heading("A program, not a scan"),
            .paragraph("Running a scanner is easy; managing what it finds is the job. Vulnerability management is the continuous loop of **discovering** assets, **assessing** them for weaknesses, **prioritising** by real risk, **remediating**, and **verifying** — then doing it again. An enterprise scan returns tens of thousands of findings; success is fixing the handful that actually expose you, fast, not drowning in a CSV."),
            .animation(.defenseInDepth, caption: "Patching is one layer among many — defense in depth keeps you covered for the window before a fix lands."),
            .heading("Prioritisation: severity ≠ risk"),
            .paragraph("A CVSS 10 on an internal printer nobody can reach matters less than a CVSS 7 on your internet-facing login. Real prioritisation blends the base **severity** with **exploitability** and **exposure**: Is there a public exploit? Is it being exploited *right now* in the wild? Is the asset internet-facing and business-critical? Modern programs lean on **CISA KEV** (known exploited) and **EPSS** (probability of exploitation) — not raw CVSS alone."),
            .keyPoints([
                "Asset inventory first — you can't protect or patch what you don't know exists.",
                "CVSS gives base severity; it is an input, not the whole decision.",
                "EPSS estimates the probability a CVE will be exploited soon — focus effort where it's likely.",
                "CISA KEV lists vulns known to be exploited in the wild — treat these as drop-everything.",
                "Exposure & context — internet-facing + business-critical + public exploit = top of the queue.",
                "Compensating controls — if you can't patch now, reduce risk: restrict access, add detection, virtually patch at the WAF."
            ]),
            .definition(term: "EPSS", meaning: "The Exploit Prediction Scoring System — a data-driven probability (0–1) that a given CVE will be exploited in the near term. Paired with CVSS severity and CISA KEV, it lets teams patch by likelihood of attack rather than by raw score, cutting an unmanageable list down to what truly matters."),
            .callout(.tip, "A 'patch everything CVSS ≥ 7' policy sounds rigorous and fails in practice — it buries teams. Prioritise by KEV + EPSS + exposure, and you fix the few that attackers will actually use first."),
            .callout(.warning, "The clock is the adversary. The window between a vulnerability becoming public and mass exploitation is often days. Vulnerability management is a race; an accurate inventory and fast, prioritised patching are how you win it."),
            .checkpoint(QuizQuestion(
                "Two findings: CVE-A is CVSS 9.8 on an isolated internal device with no known exploit; CVE-B is CVSS 7.5 on your internet-facing portal and appears on CISA's KEV list. Which do you remediate first?",
                options: [
                    "CVE-A — it has the higher CVSS score",
                    "CVE-B — it's internet-facing and known to be actively exploited, so its real risk is higher",
                    "Neither is urgent",
                    "Whichever is alphabetically first"
                ],
                correct: 1,
                why: "Risk = severity × exploitability × exposure. CVE-B is exposed to the internet and actively exploited in the wild (KEV), making it the real, present danger despite a lower CVSS than the unreachable CVE-A."))
        ],
        quiz: [
            QuizQuestion(
                "Why is raw CVSS score an insufficient way to prioritise patching?",
                options: [
                    "CVSS is always wrong",
                    "It measures base severity but ignores whether the vuln is actually being exploited and how exposed the asset is",
                    "CVSS scores change hourly",
                    "Only attackers use CVSS"
                ],
                correct: 1,
                why: "CVSS captures intrinsic severity, not real-world risk. Exploitability (EPSS/KEV) and exposure (internet-facing, critical asset) determine what an attacker will actually hit — so they must factor into the order."),
            QuizQuestion(
                "You can't patch a critical internet-facing vulnerability immediately. What's a sound interim step?",
                options: [
                    "Ignore it until the maintenance window",
                    "Apply compensating controls — restrict access, virtually patch at the WAF, and add detection — to reduce risk now",
                    "Take the whole company offline",
                    "Lower its CVSS score"
                ],
                correct: 1,
                why: "When immediate patching isn't possible, compensating controls shrink the exposure and exploitability in the meantime — buying time without leaving the risk wide open.")
        ]
    )

    private static let zeroTrustLesson = Lesson(
        id: "blue-zero-trust",
        title: "Zero Trust Architecture",
        subtitle: "Stop trusting the network. Verify every request as if it came from an open internet.",
        minutes: 11,
        difficulty: .advanced,
        blocks: [
            .heading("The castle wall already fell"),
            .paragraph("The old model was a hard perimeter around a soft, trusting interior: get inside the firewall and you were treated as friendly. Every breach in this app's Red track shows why that fails — phishing, VPN footholds and lateral movement all exploit that implicit interior trust. **Zero Trust** discards it. Its mantra: **never trust, always verify.** There is no trusted network; every request is authenticated, authorised, and inspected as if it came straight off the open internet."),
            .animation(.zeroTrust, caption: "Every request is scored live on identity, device posture and risk before the policy engine grants the least access needed — for that session only."),
            .heading("Verify explicitly, every time"),
            .paragraph("A Zero Trust **policy engine** sits in front of resources and decides each request dynamically, weighing **who** (strongly-authenticated identity, ideally phishing-resistant MFA), **what** (is the device managed, patched, healthy?), and **context** (location, time, behaviour, risk score). Access granted is the **least privilege** needed, **just-in-time**, and re-evaluated continuously — not a standing all-areas pass handed out once at the VPN."),
            .keyPoints([
                "Never trust, always verify — network location grants nothing; identity and posture do.",
                "Verify explicitly — strong auth (passkeys/FIDO2) + device health on every access decision.",
                "Least privilege & JIT — grant the minimum, for as short as possible; re-check continuously.",
                "Microsegmentation — break the flat network into small zones so a foothold can't roam freely.",
                "Assume breach — design as if an attacker is already inside; limit blast radius by default.",
                "It blunts lateral movement — the technique that turns one compromised host into a domain takeover."
            ]),
            .definition(term: "Microsegmentation", meaning: "Dividing the network into small, individually-policed zones (down to per-workload) so that compromising one host doesn't grant free movement to others. It directly attacks lateral movement: every hop must pass a policy check, instead of a flat internal network where one foothold reaches everything."),
            .callout(.danger, "Zero Trust's prime target is lateral movement. In a flat trusted network, one phished laptop is a launchpad to the whole domain; under Zero Trust, that laptop's credentials still face explicit verification and segmentation at every step — turning a breach into a contained incident."),
            .callout(.tip, "Zero Trust is a strategy, not a product you buy. It's implemented incrementally: start with strong identity (MFA everywhere), add device-health checks, then microsegment the crown-jewel systems. Identity is the foundation everything else builds on."),
            .checkpoint(QuizQuestion(
                "Under a Zero Trust model, an attacker steals a valid laptop and its session inside the corporate network. Why is their lateral movement still hard?",
                options: [
                    "The network is faster",
                    "There's no trusted interior — each further access is re-verified on identity, device posture and risk, and microsegmentation forces a policy check at every hop",
                    "Zero Trust deletes all credentials hourly",
                    "Internal traffic is never allowed at all"
                ],
                correct: 1,
                why: "Zero Trust removes implicit network trust. Even from inside, every additional resource access is explicitly evaluated and segmented, so a single foothold can't freely pivot the way it can on a flat, trusting network."))
        ],
        quiz: [
            QuizQuestion(
                "What is the core principle of Zero Trust?",
                options: [
                    "Trust everything inside the firewall",
                    "Never trust, always verify — authenticate and authorise every request regardless of network location",
                    "Block all internet traffic",
                    "Use one very strong perimeter firewall"
                ],
                correct: 1,
                why: "Zero Trust eliminates implicit trust based on network position. Every request is verified on identity, device and context, treated as if it originated on the open internet."),
            QuizQuestion(
                "How does microsegmentation limit an attacker?",
                options: [
                    "It encrypts all disks",
                    "It splits the network into small policed zones so a single foothold can't move freely to other systems",
                    "It speeds up the VPN",
                    "It hides the network from scans"
                ],
                correct: 1,
                why: "Microsegmentation forces a policy check between zones, so compromising one host doesn't grant reach to the rest — directly constraining lateral movement and shrinking the blast radius.")
        ]
    )

    // MARK: B1+ — Email authentication (defensive foundations)

    private static let emailAuthLesson = Lesson(
        id: "blue-email-auth",
        title: "Email Authentication: SPF, DKIM & DMARC",
        subtitle: "Email had no built-in proof of sender — these three records add it, and shut the door on domain spoofing.",
        minutes: 9,
        difficulty: .intermediate,
        blocks: [
            .heading("Email was born trusting everyone"),
            .paragraph("The `From:` address on an email is just text the sender writes — by default nothing stops anyone claiming to be `ceo@yourbank.com`. That's the root of so much phishing and business email compromise. Three layered DNS-based controls fix it: **SPF**, **DKIM**, and **DMARC**. Together they let a receiving server verify a message really came from a domain's authorized infrastructure — the direct counter to the phishing you studied on the offensive side."),
            .animation(.emailAuth, caption: "A spoofed message claiming to be from corp.com fails SPF, then DKIM, and DMARC's reject policy drops it before it ever reaches the inbox."),
            .heading("The three records, in plain terms"),
            .keyPoints([
                "SPF (Sender Policy Framework) — a DNS list of IPs/servers allowed to send mail for the domain. Receiver checks the sending IP is on it.",
                "DKIM (DomainKeys Identified Mail) — the sending server cryptographically signs the message; the receiver verifies the signature with a public key in DNS, proving integrity and origin.",
                "DMARC — ties SPF/DKIM to the visible From: domain (alignment) and tells receivers what to do on failure: none, quarantine, or reject — plus sends the domain owner reports.",
                "Defense in depth: SPF can break on forwarding; DKIM survives it; DMARC makes the policy enforceable and visible.",
                "Set DMARC to p=reject once you've confirmed legitimate mail passes — that's what actually stops spoofing."
            ]),
            .definition(term: "DMARC alignment", meaning: "DMARC requires that the domain validated by SPF or DKIM matches the domain in the visible From: header. This stops an attacker from passing SPF/DKIM for a domain they control while spoofing a different From: address — closing the gap the older two controls left open."),
            .terminal(prompt: "analyst",
                      command: "dig +short TXT _dmarc.corp.com",
                      output: """
\"v=DMARC1; p=reject; rua=mailto:dmarc@corp.com; adkim=s; aspf=s\"
# p=reject → receivers DROP mail that fails alignment; reports go to rua
"""),
            .callout(.tip, "p=none is monitor-only — it reports but blocks nothing. Many domains stall there for fear of dropping real mail. The protection only kicks in at quarantine/reject, so use the reports to fix legitimate senders, then enforce."),
            .callout(.warning, "These authenticate the *domain*, not the human, and don't stop look-alike domains (corp-support.com) or a genuinely compromised account. They're a powerful layer against exact-domain spoofing — not a complete anti-phishing solution on their own."),
            .checkpoint(QuizQuestion(
                "What does setting a domain's DMARC policy to `p=reject` accomplish?",
                options: [
                    "It encrypts all outgoing email",
                    "It tells receiving servers to drop messages that fail SPF/DKIM alignment — blocking spoofed mail from that domain",
                    "It hides the From: address",
                    "It disables SPF and DKIM"
                ],
                correct: 1,
                why: "DMARC reject instructs receivers to discard mail that isn't authenticated and aligned to the From: domain, which is what actually prevents attackers from spoofing that domain into inboxes."))
        ],
        quiz: [
            QuizQuestion(
                "What does DKIM provide that SPF does not?",
                options: [
                    "A list of allowed sending IPs",
                    "A cryptographic signature proving the message's integrity and that it came from the domain — and it survives forwarding",
                    "A faster delivery path",
                    "Encryption of the mailbox"
                ],
                correct: 1,
                why: "SPF authorises sending IPs; DKIM signs the message itself, so the receiver verifies origin and integrity via a DNS public key — and unlike SPF, the signature still validates after forwarding."),
            QuizQuestion(
                "Why is DMARC needed on top of SPF and DKIM?",
                options: [
                    "It replaces them",
                    "It enforces alignment with the visible From: domain and defines an enforcement policy (reject/quarantine) plus reporting",
                    "It encrypts DNS",
                    "It scans attachments for malware"
                ],
                correct: 1,
                why: "SPF/DKIM can pass for a domain the attacker controls while spoofing another From:. DMARC closes that by requiring alignment to the From: domain and telling receivers how to act on failure — making the protection enforceable.")
        ]
    )

    // MARK: B-MOD+ — Deception (modern defense)

    private static let deceptionLesson = Lesson(
        id: "blue-deception",
        title: "Deception: Honeypots & Canary Tokens",
        subtitle: "Plant tripwires no legitimate user would ever touch — so the alert that fires is almost never wrong.",
        minutes: 9,
        difficulty: .intermediate,
        blocks: [
            .heading("Turning the attacker's curiosity against them"),
            .paragraph("Most detection drowns in false positives. **Deception** flips the economics: you scatter attractive traps — fake servers, files, accounts and credentials — that have **no legitimate use**. Nobody normal opens `Q4_Salaries_FINAL.xlsx` on the file server or logs in as the dormant `backup_admin`. So when something touches one, it's almost certainly an intruder. Deception produces extremely **high-signal, low-false-positive** alerts."),
            .animation(.honeyToken, caption: "An intruder opens a planted canary file; it silently beacons out, and the SOC gets a high-confidence tripwire alert — with the attacker none the wiser."),
            .heading("From honeypots to canary tokens"),
            .keyPoints([
                "Honeypot — a decoy system that looks real and exists only to be attacked; any interaction is suspicious.",
                "Honey account / honey credentials — a tempting unused account (or creds left in a file) whose every use is an alert; pairs with the honeypot AD account you met in Defending AD.",
                "Canary token — a tiny tripwire embedded in a document, URL, AWS key or DNS name that 'phones home' the instant it's opened or used.",
                "Deception is most powerful *inside* the network — it shines a light on the lateral-movement and recon phases that evade prevention.",
                "Low cost, low noise: a handful of well-placed tokens can catch an intruder who beat every other control."
            ]),
            .definition(term: "Canary token", meaning: "A unique, embedded tripwire (in a file, link, API key, QR code or DNS record) that triggers a silent alert the moment it is accessed or used. Because it has no real purpose, an alert is near-certain evidence of unauthorized activity — and the attacker usually doesn't realise they tripped it."),
            .callout(.tip, "Place tokens where an attacker will look but a user won't: a 'passwords' spreadsheet on a share, fake AWS keys in a repo or config, a honey admin account with a tempting name. Free services (e.g. Canarytokens) make minting them trivial."),
            .callout(.warning, "Deception complements, never replaces, prevention and detection. Tokens must be realistic and maintained — a stale, obvious decoy is ignored, and a token that legitimate automation touches becomes just another false positive."),
            .checkpoint(QuizQuestion(
                "Why do canary tokens and honeypots generate such high-confidence alerts?",
                options: [
                    "They use machine learning",
                    "They have no legitimate purpose, so any interaction is almost certainly an intruder — near-zero false positives",
                    "They block the attacker automatically",
                    "They scan all network traffic"
                ],
                correct: 1,
                why: "Because nobody legitimate has any reason to touch a decoy file, account, or token, an access event is strong evidence of malicious activity — the opposite of noisy, ambiguous alerts."))
        ],
        quiz: [
            QuizQuestion(
                "Where is deception (honeypots/tokens) most valuable in catching an intrusion?",
                options: [
                    "At the public website's homepage only",
                    "Inside the network — surfacing the recon and lateral-movement that slip past preventive controls",
                    "On the attacker's own machine",
                    "In the SPF record"
                ],
                correct: 1,
                why: "Internal decoys catch attackers who already have a foothold and are exploring or moving laterally — exactly the post-breach phases that prevention tends to miss."),
            QuizQuestion(
                "What is a honey account?",
                options: [
                    "An admin's real account",
                    "A deceptive, unused account whose every login attempt is high-signal evidence of an attacker",
                    "A shared service account",
                    "A backup of the domain controller"
                ],
                correct: 1,
                why: "A honey account exists only as bait. Since no legitimate user signs into it, any authentication attempt strongly indicates an intruder probing or using harvested credentials.")
        ]
    )

    // MARK: B-NSM — Network security monitoring

    private static let nsm = Module(
        id: "blue-nsm",
        title: "Network Security Monitoring",
        summary: "Watching the wire — IDS/IPS, signatures vs anomalies, and the packet-level visibility that catches what endpoints miss.",
        systemImage: "antenna.radiowaves.left.and.right",
        lessons: [nsmLesson]
    )

    private static let nsmLesson = Lesson(
        id: "blue-nsm-monitoring",
        title: "IDS, IPS & Network Visibility",
        subtitle: "The network never lies — detect intrusions in the traffic itself.",
        minutes: 11,
        difficulty: .intermediate,
        blocks: [
            .heading("Why watch the network at all"),
            .paragraph("Endpoints can be blinded — an attacker who kills the EDR agent goes dark on that host. But to do anything useful they still have to talk on the network: scan, move laterally, beacon to C2, exfiltrate. **Network Security Monitoring (NSM)** watches that traffic, giving you a vantage point the attacker can't simply switch off."),
            .animation(.idsDetection, caption: "Traffic streams past a sensor; a malicious request matches a signature and fires an alert — an IPS would block it inline."),
            .heading("IDS vs IPS, signatures vs anomalies"),
            .paragraph("An **IDS** (Intrusion Detection System) inspects a *copy* of traffic and **alerts**; an **IPS** sits *inline* and can **block**. Both detect two ways: **signatures** match known-bad patterns (a specific exploit string) — precise but blind to novelty; **anomaly** detection flags deviations from normal — catches the unknown but generates more noise. Mature shops run both, plus a **NDR** layer for behavioural analytics."),
            .keyPoints([
                "IDS — out-of-band, alerts on a copy of traffic (fed by a SPAN port or network tap).",
                "IPS — inline, can drop malicious packets in real time.",
                "Signature detection — Snort/Suricata rules matching known-bad; precise, but misses novel attacks.",
                "Anomaly detection — flags deviations from a baseline; catches the unknown, noisier.",
                "Zeek — turns raw traffic into rich connection logs (who talked to whom, DNS, certs, files)."
            ]),
            .terminal(prompt: "soc@sensor",
                      command: "cat /var/log/suricata/fast.log",
                      output: """
[**] [1:2010935:3] ET WEB_SERVER Possible /etc/passwd via Directory Traversal [**]
[Classification: Web Application Attack] [Priority: 1]
10.10.10.40:51544 -> 10.0.0.8:80
"""),
            .definition(term: "Full packet capture vs flow", meaning: "Full PCAP records every byte — perfect for investigation but storage-heavy. Flow/metadata (NetFlow, Zeek logs) records who-talked-to-whom and how much, not the contents — far cheaper and still hugely valuable, especially when traffic is encrypted."),
            .callout(.warning, "Most traffic is now encrypted (TLS), so signatures can't read payloads. Modern NSM leans on metadata — JA3/JA4 TLS fingerprints, certificate details, destination reputation, beacon timing — to spot malicious encrypted flows without decrypting them."),
            .callout(.tip, "Sensor placement is everything: you can only monitor traffic you can see. Position taps/SPAN at choke points — the internet egress and between network segments — so lateral movement and exfiltration cross a sensor."),
            .checkpoint(QuizQuestion(
                "What is the core difference between an IDS and an IPS?",
                options: [
                    "An IDS is software, an IPS is hardware",
                    "An IDS alerts on a copy of traffic; an IPS sits inline and can block traffic in real time",
                    "An IDS is for Windows, an IPS for Linux",
                    "They are the same thing"
                ],
                correct: 1,
                why: "An IDS detects and alerts out-of-band; an IPS is positioned inline so it can actively drop or block malicious traffic as it passes."))
        ],
        quiz: [
            QuizQuestion(
                "What is the main weakness of purely signature-based detection?",
                options: [
                    "It's too slow",
                    "It can only catch known patterns, so novel or modified attacks slip past",
                    "It blocks legitimate traffic",
                    "It can't run on Linux"
                ],
                correct: 1,
                why: "Signatures match known-bad. A new or sufficiently altered attack has no signature yet, so anomaly/behavioural detection is needed to catch the unknown."),
            QuizQuestion(
                "Why does network monitoring increasingly rely on metadata like JA3 fingerprints?",
                options: [
                    "Metadata is bigger than the payload",
                    "Most traffic is encrypted, so the payload can't be read — metadata still reveals malicious patterns",
                    "It's required by law",
                    "Signatures are no longer used at all"
                ],
                correct: 1,
                why: "TLS hides payloads from signature inspection. TLS fingerprints, certificate data, destinations and timing let analysts spot malicious encrypted flows without decryption."),
            QuizQuestion(
                "Why is sensor placement critical to NSM?",
                options: [
                    "Sensors look nicer in the data center",
                    "You can only detect traffic that actually crosses a sensor, so they belong at choke points like egress and between segments",
                    "It reduces electricity use",
                    "Placement doesn't matter"
                ],
                correct: 1,
                why: "Monitoring only sees traffic that passes the sensor. Placing taps at the internet egress and between segments ensures lateral movement and exfiltration are visible.")
        ]
    )

    // MARK: B-AC — Securing apps & the cloud

    private static let appcloud = Module(
        id: "blue-appcloud",
        title: "Securing Apps & the Cloud",
        summary: "Building security in — catching vulnerabilities in the pipeline before they ship, and defending the cloud where the attacks from the Red Team track land.",
        systemImage: "cloud.fill",
        lessons: [appsecLesson, cloudDefenseLesson]
    )

    private static let appsecLesson = Lesson(
        id: "blue-appsec",
        title: "Application Security & the Secure SDLC",
        subtitle: "The cheapest bug to fix is the one caught before it ships — shift security left.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("Security as part of building, not an afterthought"),
            .paragraph("The web attacks in the Red Team track all exist because a vulnerability shipped to production. **Application security** moves the defense earlier — “shift left” — so flaws are caught while they're cheap to fix: during design, coding and the build pipeline, not after a breach. The goal is a **Secure SDLC**, where every change passes automated security gates before it can deploy."),
            .animation(.secureSdlc, caption: "A CI/CD pipeline with security gates — SAST, dependency and DAST checks — where a vulnerable dependency fails the build before it ships."),
            .heading("The testing toolbox"),
            .keyPoints([
                "Threat modeling — at design time, ask how this feature could be abused.",
                "SAST — static analysis reads source code for vulnerable patterns (no running app).",
                "DAST — dynamic analysis attacks the running app from the outside, like a scanner.",
                "SCA — software composition analysis flags known-vulnerable third-party libraries.",
                "Secrets scanning — catch hard-coded API keys and passwords before they hit the repo."
            ]),
            .definition(term: "SBOM (Software Bill of Materials)", meaning: "A complete inventory of every component and dependency in your software. When the next Log4j-style flaw drops, an SBOM lets you answer “are we affected, and where?” in minutes instead of weeks — the lesson the industry learned the hard way."),
            .callout(.tip, "Most modern code is dependencies, not your own lines — so SCA is often the highest-value gate. The majority of real-world app risk hides in a vulnerable library someone pulled in years ago and forgot."),
            .callout(.danger, "Security gates only help if a failing gate actually blocks the deploy. A SAST scan whose findings everyone ignores is theatre. The control is the *enforcement* — build fails, merge blocked — not the scan itself."),
            .checkpoint(QuizQuestion(
                "What is the difference between SAST and DAST?",
                options: [
                    "SAST runs the app and attacks it; DAST reads the code",
                    "SAST analyzes source code without running it; DAST tests the running application from the outside",
                    "They are two names for the same scan",
                    "SAST is for cloud, DAST is for mobile"
                ],
                correct: 1,
                why: "SAST inspects source statically for risky patterns; DAST exercises the live application like an attacker would. They find different classes of bug and complement each other."))
        ],
        quiz: [
            QuizQuestion(
                "What does “shift left” mean in application security?",
                options: [
                    "Move servers to a left-hand data center",
                    "Catch security issues earlier in development, where they're cheaper to fix",
                    "Write code right-to-left",
                    "Delay security testing until after release"
                ],
                correct: 1,
                why: "Shifting left moves security into design, coding and the build pipeline so defects are found and fixed early — far cheaper than after a production breach."),
            QuizQuestion(
                "Why is software composition analysis (SCA) so important?",
                options: [
                    "It speeds up the build",
                    "Most applications are mostly third-party dependencies, where known-vulnerable libraries often hide",
                    "It replaces the need for a firewall",
                    "It encrypts the source code"
                ],
                correct: 1,
                why: "Modern apps are largely assembled from libraries. SCA flags components with known CVEs — frequently the largest and most overlooked source of risk."),
            QuizQuestion(
                "A SAST scan flags issues but nobody is required to fix them before deploy. What's the problem?",
                options: [
                    "Nothing — scanning is enough",
                    "Without enforcement (a failing gate that blocks the deploy), the scan is just theatre",
                    "SAST should run after deploy",
                    "The scanner is misconfigured by definition"
                ],
                correct: 1,
                why: "A security gate only reduces risk if a failure actually stops the release. Findings that don't block anything change nothing.")
        ]
    )

    private static let cloudDefenseLesson = Lesson(
        id: "blue-cloud",
        title: "Cloud Security & Shared Responsibility",
        subtitle: "The cloud secures the infrastructure; securing what you put on it is your job.",
        minutes: 11,
        difficulty: .intermediate,
        blocks: [
            .heading("Who secures what"),
            .paragraph("Moving to the cloud doesn't outsource security — it splits it. Under the **shared responsibility model**, the provider secures the cloud *itself* (hardware, hypervisor, managed services); **you** secure what you put *in* it — your data, identities, configurations and access rules. Most cloud breaches aren't the provider being hacked; they're a customer **misconfiguration**."),
            .animation(.zeroTrust, caption: "Every request scored on identity, device and context before least-privilege access is granted — the model cloud security is built on."),
            .heading("Where cloud breaches actually come from"),
            .keyPoints([
                "Identity is the new perimeter — IAM least privilege matters more than network firewalls.",
                "Public storage — world-readable buckets/blobs are the classic data-leak headline.",
                "Over-permissive roles — broad IAM policies let one compromised key reach everything.",
                "Exposed metadata — lock down the instance metadata service (IMDSv2) to blunt SSRF-to-credentials.",
                "Logging — CloudTrail / activity logs are how you detect and reconstruct what happened."
            ]),
            .definition(term: "CSPM (Cloud Security Posture Management)", meaning: "Tooling that continuously scans cloud accounts for misconfigurations and policy violations — public buckets, unused over-privileged roles, disabled logging, open security groups — and flags drift from a secure baseline. It's how teams keep up with cloud that changes by the minute."),
            .callout(.danger, "This is the defensive mirror of the Red Team cloud module: the IMDS SSRF, IAM privilege escalation and public-bucket attacks you learned to *perform* are all defeated here by least-privilege IAM, IMDSv2, blocking public access, and watching CloudTrail. Attack and defense are the same map read from opposite sides."),
            .callout(.tip, "Default-deny applies in the cloud too: grant the minimum IAM permission needed, scope it to specific resources, and prefer short-lived credentials over long-lived keys. Most cloud privilege escalation dies against tight, scoped roles."),
            .checkpoint(QuizQuestion(
                "Under the shared responsibility model, who is responsible for a publicly-exposed storage bucket full of customer data?",
                options: [
                    "The cloud provider — it's their infrastructure",
                    "The customer — securing data and configuration in the cloud is their responsibility",
                    "Nobody — buckets are private by default forever",
                    "It's split 50/50 by contract"
                ],
                correct: 1,
                why: "The provider secures the underlying cloud; the customer secures what they put in it — including storage access settings. A public bucket is a customer misconfiguration."))
        ],
        quiz: [
            QuizQuestion(
                "In the shared responsibility model, what does the cloud provider secure?",
                options: [
                    "Your data and access policies",
                    "The underlying infrastructure — hardware, hypervisor and managed services",
                    "Everything, so you don't have to",
                    "Only the billing system"
                ],
                correct: 1,
                why: "The provider secures the cloud itself (physical, virtualization, managed service internals). The customer secures their data, identities and configuration on top of it."),
            QuizQuestion(
                "Why is IAM least privilege central to cloud security?",
                options: [
                    "It makes logins faster",
                    "Identity is the primary perimeter; tightly-scoped permissions stop one compromised key from reaching everything",
                    "It's only relevant on-premises",
                    "It replaces encryption"
                ],
                correct: 1,
                why: "In the cloud, access is gated by identity more than network location. Minimal, resource-scoped permissions contain the blast radius of any leaked credential."),
            QuizQuestion(
                "What does a CSPM tool do?",
                options: [
                    "Encrypts all cloud traffic",
                    "Continuously scans cloud accounts for misconfigurations and drift from a secure baseline",
                    "Replaces the need for IAM",
                    "Runs penetration tests automatically"
                ],
                correct: 1,
                why: "CSPM continuously checks cloud configuration — public storage, over-broad roles, disabled logging — and alerts on violations, keeping pace with fast-changing environments.")
        ]
    )
}
