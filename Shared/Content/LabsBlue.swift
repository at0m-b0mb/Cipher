import Foundation

/// Standalone hands-on labs — Blue.
/// See `Labs` in LabLibrary.swift for how these are surfaced.
///
/// House rule for this file: the correct option is the correct *priority*, not
/// merely a correct action. Several steps put two legitimate moves side by side
/// and grade on sequencing — contain before you clean, preserve before you
/// reboot, confirm scope before you declare an incident closed. The wrong
/// options are deliberately things a real analyst does, just not yet.
enum LabsBlue {

    // MARK: - 1. Email authentication (foundational)

    private static let dmarcVerdict = InteractiveLab(
        id: "lab-dmarc-verdict",
        title: "Call the verdict on a mail header",
        goal: "Decide whether a message claiming to come from your own domain is authentic — and justify the call.",
        track: .blueTeam,
        difficulty: .foundational,
        minutes: 6,
        scenario: "A finance clerk forwards you a payment-change request that appears to come from `cfo@corp.example` — your own domain. It landed in her inbox, not junk. You have the full header set from your own gateway and read access to your own DNS. Nobody has paid anything yet.",
        debrief: "Two `pass` results, and the message was still a forgery. SPF and DKIM each authenticate a domain the **sender** chose; only DMARC **alignment** ties that back to the `From:` a human actually reads. That gap is the entire play: pass authentication for a domain you legitimately control, and let the recipient's eye supply the trust. From the attacker's side the win condition was your `p=none` — a monitoring policy that reports forgeries and delivers them anyway. The fix was a DNS change, not a user-awareness poster.",
        tools: ["mail headers", "dig"],
        relatedLessonID: "blue-email-auth",
        steps: [
            LabStep(instruction: "Here is the gateway's verdict block:\n\n`spf=pass smtp.mailfrom=bounce@mailer-7.example`\n`dkim=pass header.d=mailer-7.example`\n`dmarc=fail (p=NONE dis=NONE) header.from=corp.example`\n\nWhich line decides whether this is a spoof?",
                    hint: "Two of the three results authenticate a domain. Only one of them compares that domain to the address the clerk saw.",
                    options: [
                        LabOption("spf=pass — the sending IP is authorised, so the sender is genuine",
                                  output: "spf=pass smtp.mailfrom=bounce@mailer-7.example",
                                  feedback: "SPF checked the **envelope** sender (`smtp.mailfrom`), which is `mailer-7.example` — a domain the attacker controls and published an SPF record for. Passing SPF for your own domain is easy when the domain being checked is yours."),
                        LabOption("dkim=pass — the message is cryptographically signed, so it was not tampered with",
                                  output: "dkim=pass header.d=mailer-7.example",
                                  feedback: "The signature is valid, and it proves integrity — for `header.d=mailer-7.example`. A valid signature from the wrong domain proves the wrong thing. DKIM tells you *who signed*; it does not tell you they were entitled to write that `From:`."),
                        LabOption("dmarc=fail — the authenticated domain does not align with header.from",
                                  correct: true,
                                  output: "dmarc=fail (p=NONE dis=NONE) header.from=corp.example\n# authenticated: mailer-7.example   visible From: corp.example   -> not aligned",
                                  feedback: "Correct. DMARC is the only check that compares the domain SPF/DKIM validated against the `From:` the human reads. `mailer-7.example` never equals `corp.example`, so alignment fails — this is a forgery wearing two genuine passes.")
                    ]),
            LabStep(instruction: "DMARC failed. So why was it delivered to her inbox instead of being dropped?",
                    hint: "Read the parenthesised part of the DMARC result. It is quoting your own published policy back at you.",
                    options: [
                        LabOption("The gateway is misconfigured and ignoring DMARC results",
                                  output: "gateway policy: honour published DMARC policy  [enabled]",
                                  feedback: "The gateway did exactly what it was told. Before blaming your tooling, read what your own DNS instructed it to do on failure."),
                        LabOption("corp.example publishes p=none, so receivers report failures but deliver anyway",
                                  correct: true,
                                  output: "dig +short TXT _dmarc.corp.example\n\"v=DMARC1; p=none; rua=mailto:dmarc@corp.example\"\n# p=none -> monitor only. Nothing is quarantined, nothing is rejected.",
                                  feedback: "Correct. `p=none` is monitor-only: it generates the aggregate reports that go to `rua` and blocks nothing. The detection worked perfectly and the enforcement was switched off — which is the state a surprising number of domains sit in for years."),
                        LabOption("DKIM passed, and a DKIM pass overrides a DMARC failure",
                                  output: "dmarc=fail (p=NONE dis=NONE) header.from=corp.example",
                                  feedback: "There is no override. DMARC passes when SPF **or** DKIM passes *and is aligned to the From: domain*. An unaligned pass is not a pass as far as DMARC is concerned — that is the whole reason DMARC exists on top of the other two.")
                    ]),
            LabStep(instruction: "You have the verdict. What is the right containment action for *this* message, right now?",
                    hint: "One of these actions reaches every copy of the message. One reaches an IP address the attacker is renting by the hour.",
                    options: [
                        LabOption("Block the sending IP 203.0.113.44 at the gateway",
                                  output: "rule added: deny smtp from 203.0.113.44\n# note: 203.0.113.44 is shared outbound infrastructure for mailer-7.example",
                                  feedback: "A real action, and almost worthless here. That IP is shared bulk-sender infrastructure — the attacker moves off it for free, and you may have just blocked a legitimate tenant on the same relay. You blocked a rented address, not the technique."),
                        LabOption("Search-and-purge every copy of the message from all mailboxes, then warn the clerk's team",
                                  correct: true,
                                  output: "search: header.from=cfo@corp.example AND reply-to!=*@corp.example\n7 recipients matched, 7 copies removed, 1 already read\nfinance-team notified: do not action payment changes from this thread",
                                  feedback: "Correct priority. The live risk is a payment being made, so you remove the message from every inbox it reached and tell the humans who could act on it. Containment that reaches the actual exposure beats containment that reaches an IP."),
                        LabOption("Reply to the message asking the sender to confirm their identity",
                                  output: "message sent to reply-to: cfo.corp@mailer-7.example",
                                  feedback: "Note where the `Reply-To:` actually goes — straight to the attacker. You have confirmed the mailbox is live, monitored and worth another attempt, and you have taught them which of your staff engage.")
                    ]),
            LabStep(instruction: "Contained. The CFO asks what stops the next one. What do you tell her?",
                    hint: "Something in your own DNS is currently set to the value that let this through. Changing it badly breaks real mail, so there is an order to this.",
                    options: [
                        LabOption("Run security-awareness training on spotting spoofed senders",
                                  output: "training module scheduled: Q3",
                                  feedback: "Worth doing, and the wrong answer to this question. You are asking a human to out-perform a cryptographic check that your own DNS told the receiver to ignore. Fix the control you own before you ask people to compensate for it."),
                        LabOption("Use the rua reports to fix every legitimate sender, then move DMARC to p=reject",
                                  correct: true,
                                  output: "aggregate reports (30d): 11 sending sources\n  9 aligned (pass)\n  2 failing: marketing platform, legacy print-vendor relay\n# fix those two -> then p=quarantine -> then p=reject",
                                  feedback: "Correct, and note the sequencing. Jumping to `p=reject` with two broken senders drops real invoices and gets the policy rolled back within a day. The reports exist precisely so you can enumerate your own senders first, align them, and *then* enforce. Enforcement is the control; the reports are how you earn the right to turn it on."),
                        LabOption("Set DMARC to p=reject tonight — the policy is the whole point",
                                  output: "updated: \"v=DMARC1; p=reject; rua=mailto:dmarc@corp.example\"\n[next morning] 2 legitimate senders now rejected: invoices and print-vendor mail bouncing",
                                  feedback: "Right destination, wrong order. Unaligned legitimate senders are extremely common, and the first thing a business does when real invoices bounce is make you revert the record — leaving you back at `p=none` with less political capital. Align first, enforce second."),
                        LabOption("Add an SPF record with -all and call it done",
                                  output: "dig +short TXT corp.example\n\"v=spf1 include:_spf.corp.example -all\"\n# attacker's From: forgery still passes SPF for mailer-7.example",
                                  feedback: "A hard-fail SPF record is good hygiene and does nothing against this attack. The attacker never claimed to send *as* your SPF-listed infrastructure — they passed SPF for their own domain and forged only the visible header. Only alignment closes that.")
                    ]),
            LabStep(instruction: "Last thing: what does `p=reject` still *not* protect you from?",
                    hint: "Think about what exactly is being authenticated. It is a domain string, compared character for character.",
                    options: [
                        LabOption("Nothing — exact-domain spoofing was the only gap",
                                  output: "",
                                  feedback: "Overstating the control is how it gets trusted past its limits. DMARC authenticates one thing: the domain in `From:`. Anything that does not need to forge *your exact domain* walks straight past it."),
                        LabOption("A look-alike domain, or a genuinely compromised mailbox on your own domain",
                                  correct: true,
                                  output: "cfo@corp-example.com      -> different domain: passes its own DMARC\ncfo@corp.example (hijacked) -> aligned, signed, authentic, and malicious",
                                  feedback: "Correct. `corp-example.com` is a domain someone bought; it authenticates perfectly for itself. And a real account taken over by an attacker sends mail that is genuinely aligned and signed. DMARC kills exact-domain spoofing — which is a large, cheap win — and leaves look-alikes to detection and account takeover to identity controls."),
                        LabOption("Attachments carrying malware",
                                  output: "",
                                  feedback: "True but trivially so — nobody expects an authentication record to scan files. The interesting limit is the one that still produces a *perfectly authenticated* malicious email, because that is the one that fools an analyst who has learned to trust the pass.")
                    ])
        ])

    // MARK: - 2. Acquisition order (foundational)

    private static let evidenceOrder = InteractiveLab(
        id: "lab-evidence-order",
        title: "Acquire the evidence in the right order",
        goal: "Collect what you need from a live compromised workstation before the act of responding destroys it.",
        track: .blueTeam,
        difficulty: .foundational,
        minutes: 7,
        scenario: "EDR flags `powershell.exe` on WS-FIN-14 with an outbound connection to an address nobody recognises. The host is still powered on, the user is sitting in front of it, and she has already asked you twice whether she should just restart it. You have a trusted USB with your acquisition kit and roughly fifteen minutes before her next meeting.",
        debrief: "Every response action is also a destructive action. A reboot clears RAM, an AV scan rewrites timestamps and may quarantine the only copy of the sample, a power-off throws away the network state that tells you where the implant calls home. The order of volatility is not forensic ceremony — it is the cheapest way to make sure the artefacts that answer *what did they take* still exist when you get round to asking. The attacker benefits from every minute of panic: their best outcome here is a well-meaning reboot that destroys the memory image and leaves their scheduled task untouched.",
        tools: ["EDR", "winpmem", "Get-FileHash", "volatility"],
        relatedLessonID: "blue-forensics-essentials",
        steps: [
            LabStep(instruction: "The user asks again: *should I just restart it?* What do you say?",
                    hint: "Ask yourself what a restart removes, and what it leaves behind. Both halves of that answer matter.",
                    options: [
                        LabOption("Yes — restart it, that will kill the malicious process",
                                  output: "host rebooted.\nRAM contents: gone\nactive connections: gone\nHKCU\\...\\Run value \"Updater\": still present",
                                  feedback: "It removes the one thing you cannot get back and leaves the one thing that matters. Volatile memory holds the injected code, the decrypted configuration and the live connection; persistence survives the reboot and simply runs again. You have paid full price for nothing."),
                        LabOption("No — leave it powered on, stop using it, and do not lock or log off",
                                  correct: true,
                                  output: "user stepped away, screen left as-is\nhost remains powered, session intact\nEDR telemetry continuing to stream",
                                  feedback: "Correct. Powered on preserves memory and network state; not logging off preserves the session, the mounted shares and the process tree. \"Stop using it\" also stops the user from overwriting the very artefacts you are about to collect — which is the half of this answer people forget."),
                        LabOption("Run a full antivirus scan first so we know what we are dealing with",
                                  output: "scan started: 412,900 files\nquarantined: 1 item (C:\\Users\\Public\\svc.exe)\nlast-access timestamps rewritten across scanned volume",
                                  feedback: "A real analyst reflex, and here it is actively harmful. The scan walks the whole disk rewriting access times, and quarantine may be the last place your only copy of the sample ever lived. You scan *after* you have an image, not instead of one.")
                    ]),
            LabStep(instruction: "You are collecting. What comes off this host first?",
                    hint: "Order by how quickly each thing stops existing, not by how useful it looks.",
                    options: [
                        LabOption("A full disk image, so the collection is complete and defensible",
                                  output: "imaging 512 GB at ~90 MB/s -> est. 1h35m\n(memory contents continue to change throughout)",
                                  feedback: "Complete, defensible, and ninety minutes too slow. The disk is not going anywhere; RAM is being overwritten while you wait, and the host may be remotely isolated or lose power mid-image. Least-volatile-last is the whole point."),
                        LabOption("A RAM image, then the live network and process state, then the disk",
                                  correct: true,
                                  output: "[1/3] memory image  -> E:\\IR\\WS-FIN-14.mem   (16 GB, 6m12s)\n[2/3] netstat/process/service snapshot -> E:\\IR\\live-triage\\\n[3/3] disk image queued",
                                  feedback: "Correct order of volatility: memory first because power or a reboot destroys it, then live state that dies with the session, then the disk which survives both. Note the image lands on *your* external drive, not the suspect volume."),
                        LabOption("The browser history and recent-documents list, since this started with a download",
                                  output: "browser history exported (profile files read in place)",
                                  feedback: "A sensible lead and the wrong moment to chase it. Those artefacts are on disk and will still be there in an hour; reading them live also touches the files you are about to image. Follow the lead after you have captured what expires.")
                    ]),
            LabStep(instruction: "The memory image is on your drive. What do you do before you open it in Volatility?",
                    hint: "Think about what question a sceptical reader will ask you in three months' time.",
                    options: [
                        LabOption("Hash it and record the hash with the time, tool and your name",
                                  correct: true,
                                  output: "Get-FileHash E:\\IR\\WS-FIN-14.mem -Algorithm SHA256\n\nAlgorithm  Hash                                                              Path\n---------  ----                                                              ----\nSHA256     9F2C4A17E0B35D8C41A6FB2E7D90C5831B4E6A2F08D77C19A3B5E4C62D1F8097  E:\\IR\\WS-FIN-14.mem\n\nlogged to chain-of-custody: 2026-10-02 09:41, winpmem, K. Parshad",
                                  feedback: "Correct. The hash taken *at acquisition* is what later lets you prove the image you analysed is the image you collected. Taken afterwards it proves only that the file has not changed since you finished poking at it — which is not the claim anyone needs."),
                        LabOption("Start analysing immediately; hash it later if the case goes legal",
                                  output: "vol.py -f WS-FIN-14.mem windows.pstree\n# analysis proceeds. image now opened, parsed, and partially cached.",
                                  feedback: "The hash is cheap now and worthless later. \"Hash it if it goes legal\" fails because you never know at the start which incident ends up in front of a regulator, an insurer or a court — and by then the moment that the hash was supposed to capture has passed."),
                        LabOption("Compress and encrypt it first to protect the user's data, then hash the archive",
                                  output: "WS-FIN-14.mem.7z created (4.1 GB)\nsha256 of archive recorded",
                                  feedback: "Protecting the data is right; hashing only the archive is not. You now have a hash of a container, which proves nothing about the image inside it once it is extracted. Hash the image, then compress and encrypt the hashed artefact.")
                    ]),
            LabStep(instruction: "Collection done, image hashed. The implant is still beaconing. How do you cut it off?",
                    hint: "You still want the host in the state you captured it in. One of these options achieves the same network effect without any of the cost.",
                    options: [
                        LabOption("Pull the power cable — fastest and most certain",
                                  output: "host powered off.\nremaining volatile state: lost\npartially written files on disk: inconsistent",
                                  feedback: "Certain and expensive. You already have a memory image, but you lose the ability to go back for anything you missed, you lose live triage, and a hard cut during disk writes can leave files in an inconsistent state. Reach for the least destructive action that achieves the goal."),
                        LabOption("Network-isolate the host from the EDR console, leaving it powered on",
                                  correct: true,
                                  output: "WS-FIN-14: network containment ENABLED\n  allowed: EDR management channel only\n  blocked: all other inbound/outbound\nbeacon to 192.0.2.61:443 -> no route",
                                  feedback: "Correct. EDR containment severs the C2 channel in seconds while keeping the host powered, the session intact and your management channel alive for further collection. Same effect on the attacker, none of the collateral on your evidence."),
                        LabOption("Unplug the network cable",
                                  output: "link down. beacon fails.\n(host also now unreachable for any further remote collection)",
                                  feedback: "It works, and it is the version of the right idea that costs you your remote access — on a laptop it also leaves Wi-Fi up unless you remember to kill it. Containment from the EDR is the same move done once, logged, and reversible.")
                    ]),
            LabStep(instruction: "Your manager asks for the one-line status. Which is the honest one?",
                    hint: "Be precise about which of these you have *evidence* for versus which you merely have not disproved.",
                    options: [
                        LabOption("Host is clean — the malicious process is no longer running",
                                  output: "",
                                  feedback: "The process is not running because you cut its network and the user stopped working. \"No longer running\" is an observation; \"clean\" is a conclusion you have not earned and cannot support until eradication is verified."),
                        LabOption("Contained and preserved; scope unknown until the image is analysed",
                                  correct: true,
                                  output: "status: WS-FIN-14 network-isolated, memory + live state acquired and hashed.\nunknowns: initial access vector, persistence, whether credentials were exposed,\n          whether other hosts contacted 192.0.2.61.\nnext: analyse image; query fleet for the same destination.",
                                  feedback: "Correct. It states what you did, what you have, and what you do not know yet — including the question that decides whether this is one host or forty. Naming the unknowns is what stops a manager closing the incident on your behalf."),
                        LabOption("We have a confirmed breach with data exfiltration",
                                  output: "",
                                  feedback: "Over-calling it has a cost too. \"Exfiltration\" triggers legal, comms and possibly regulatory clocks; you have an outbound connection and no volume analysis yet. Report the beacon as a beacon until the data says otherwise.")
                    ])
        ])

    // MARK: - 3. Standing up a false positive (intermediate)

    private static let fpStandDown = InteractiveLab(
        id: "lab-fp-standdown",
        title: "Stand down a false positive",
        goal: "Work an intel-match alert to a defensible not-an-incident verdict, and make it stop recurring.",
        track: .blueTeam,
        difficulty: .intermediate,
        minutes: 7,
        scenario: "Queue alert, priority high: *Threat-intel match — internal host 10.20.4.55 contacted 198.51.100.23, feed OSINT-C2-Aggregate, tag \"Cobalt Strike\".* It is 14:10 on a Tuesday. The same alert has fired eleven times this month and every previous analyst escalated it to the IR channel, where it died without a conclusion.",
        debrief: "Not every alert is an incident, and over-escalation is a real failure mode — it burns the IR team's attention, trains the SOC to treat the queue as a conveyor belt, and makes the one genuine alert indistinguishable from the eleven before it. The skill on display is not scepticism; it is **evidence**. You did not decide this was benign because it felt benign, you decided it because a signed vendor binary resolved a vendor hostname, pulled 14 KB, and did so on four hundred other hosts. The attacker's interest in this alert is real, though: a stale, shared-infrastructure indicator that everyone has learned to ignore is excellent cover.",
        tools: ["Zeek", "EDR", "threat intel platform"],
        relatedLessonID: "blue-threat-intel",
        steps: [
            LabStep(instruction: "You have an IP, a feed name and a scary tag. What is your first move?",
                    hint: "An IP address on its own is not a behaviour. Find out what the connection actually *was* before you decide what it means.",
                    options: [
                        LabOption("Isolate 10.20.4.55 immediately — a C2 match is not something to sit on",
                                  output: "10.20.4.55 (BUILD-AGENT-03): network containment ENABLED\n[14:19] 46 CI pipelines failed\n[14:21] engineering asking why the build farm is down",
                                  feedback: "Defensible on a confirmed C2 match, and you have not confirmed anything — you have an IP on a feed. Containment is cheap on a laptop and expensive on shared infrastructure, and acting before enrichment is how a SOC earns a reputation that gets its containment rights taken away."),
                        LabOption("Pull the connection context: which process, which hostname, how many bytes",
                                  correct: true,
                                  output: "zeek ssl.log  id.orig_h=10.20.4.55 id.resp_h=198.51.100.23\n  server_name    telemetry.buildtools-cdn.example\n  validation_status  ok\n  issuer         CN=R11,O=Let's Encrypt,C=US\nzeek conn.log  duration 0.41s  orig_bytes 980  resp_bytes 14233  conn_state SF\nEDR process    C:\\Program Files\\BuildTools\\bt-agent.exe  (signed, BuildTools Inc)",
                                  feedback: "Correct. In one pass you now know the destination had a name, a valid certificate, a signed owning process and a 14 KB response that finished cleanly. None of that is proof yet, but all of it is evidence — and it cost you ninety seconds."),
                        LabOption("Ask the user of 10.20.4.55 what they were doing at 14:10",
                                  output: "10.20.4.55 = BUILD-AGENT-03 (no interactive user)\n",
                                  feedback: "A good habit on a workstation, and there is no human here — it is a build agent. Checking what the asset *is* before you look for someone to ask is part of the same first step.")
                    ]),
            LabStep(instruction: "Signed process, valid cert, tiny transfer. Before you call it, what do you check about the *indicator*?",
                    hint: "The alert asserts something about an IP address. Ask the feed when it learned that, and what else lives there.",
                    options: [
                        LabOption("Nothing — the process evidence is enough to close it",
                                  output: "",
                                  feedback: "You are probably right and you cannot yet show your work. A verdict that does not address *why the indicator fired* leaves the next analyst with the same alert and no reason to trust your note. Close the loop on the indicator, not just the host."),
                        LabOption("Look up the indicator's provenance: first seen, last confirmed, and infrastructure type",
                                  correct: true,
                                  output: "198.51.100.23\n  feed            OSINT-C2-Aggregate\n  first_seen      2025-07-14\n  last_confirmed  2025-08-02   (14 months ago)\n  confidence      not scored by this feed\n  asn             AS64501  shared cloud/CDN range\n  passive DNS     2025: 2 malware C2 names (both NXDOMAIN now)\n                  2026: 31 names incl. telemetry.buildtools-cdn.example",
                                  feedback: "Correct, and now the whole alert makes sense. The IP genuinely hosted C2 fourteen months ago, the address was released back into a shared cloud range, and a legitimate CDN now has it. The indicator was true once and the feed never expired it."),
                        LabOption("Submit the IP to a public multi-scanner to get a second opinion",
                                  output: "198.51.100.23  -> 3/88 vendors flag as malicious (all citing the same 2025 OSINT list)",
                                  feedback: "Circular. Those three vendors are reading the same aged OSINT list your feed is, so you have not added an independent source — you have counted one source three times. Provenance beats a vote count."),
                        LabOption("Check whether other hosts contacted the same IP",
                                  output: "417 internal hosts contacted 198.51.100.23 in the last 7 days",
                                  feedback: "Useful, and dangerously ambiguous on its own. Four hundred hosts is either ubiquitous benign software or a very bad day — the number only means something once you know what the traffic is and how old the indicator is. Good second question, wrong first one.")
                    ]),
            LabStep(instruction: "Make the call.",
                    hint: "You have positive evidence of a benign explanation, not an absence of evidence. Those are different situations and they take different verdicts.",
                    options: [
                        LabOption("False positive — stale indicator on recycled shared infrastructure",
                                  correct: true,
                                  output: "verdict: FALSE POSITIVE\nbasis: signed vendor binary -> SNI under the vendor's published CDN domain\n       (name control, not identity — a DV cert proves only the former) ->\n       980B up / 14KB down / 0.4s / clean close; identical pattern on 417 hosts;\n       indicator last confirmed 14 months ago on a shared cloud range since reassigned.",
                                  feedback: "Correct, and note what makes it defensible: a chain of positive findings, not a shrug. Standing up a false-positive call is a skill in its own right — the write-up has to be strong enough that nobody needs to redo it."),
                        LabOption("Inconclusive — escalate to IR so someone more senior decides",
                                  output: "escalated to #ir-oncall (12th time this month)\nIR: \"any evidence of compromise?\"  analyst: \"not really\"  -> case idles 3 days, auto-closed",
                                  feedback: "This is the valuable wrong answer. Escalation exists for genuine uncertainty, and you are not uncertain — you have four independent lines of benign evidence. Passing a resolved question upward spends the IR team's attention, and a SOC that escalates everything has effectively stopped triaging. Escalate unknowns, not discomfort."),
                        LabOption("True positive — the CDN has been compromised and is serving C2",
                                  output: "",
                                  feedback: "Nothing supports that. A supply-chain compromise of a CDN would show as anomalous content or volume, not a 14 KB telemetry response matching four hundred other hosts. Inventing a severe explanation to justify a severe alert is how an analyst talks themselves into an outage."),
                        LabOption("Benign — the process is digitally signed",
                                  output: "",
                                  feedback: "Right verdict, wrong reasoning, and the reasoning is what you are being graded on. Signed binaries are abused constantly: stolen certificates, legitimate-tool abuse, DLL side-loading into a signed host process. The signature is one strand of the evidence, never the whole rope.")
                    ]),
            LabStep(instruction: "Now make it stop firing. What do you actually change?",
                    hint: "The goal is to silence this specific benign pattern without creating a hole the next attacker can park in.",
                    options: [
                        LabOption("Add 198.51.100.23 to the global allowlist",
                                  output: "global allowlist += 198.51.100.23\n# all future detections involving this address are now suppressed, for every\n# host, every process, every port, indefinitely.",
                                  feedback: "This is the move that quietly costs you an incident two years from now. It is a shared cloud range — the next tenant of that address may be genuinely hostile, and you will be blind to it across the whole estate. Never allowlist an address you do not control."),
                        LabOption("Suppress the match scoped to the owning process and destination name, and expire the indicator upstream",
                                  correct: true,
                                  output: "tuning:\n  suppress  intel-match WHERE process=bt-agent.exe (signed)\n                           AND ssl.server_name=telemetry.buildtools-cdn.example\n  expiry    90 days, owner: soc-detections\nupstream:\n  indicator 198.51.100.23 -> flagged stale to feed owner, confidence downgraded\n  note attached to all 11 prior alerts",
                                  feedback: "Correct on both halves. The suppression is bounded by the specific benign behaviour, so a different process talking to that address still alerts. And fixing the indicator upstream is what stops the next eleven alerts, and the ones aimed at every other team using that feed."),
                        LabOption("Close it as a false positive with a clear note and move on",
                                  output: "case closed: false positive. notes attached.\n[next Tuesday 14:10] alert fires again, assigned to a different analyst.",
                                  feedback: "Good hygiene, incomplete work. A note helps the next analyst do the investigation faster; it does not stop them doing it. Alert fatigue is built one unsuppressed known-benign alert at a time."),
                        LabOption("Disable the intel-match rule — it is clearly too noisy to be useful",
                                  output: "rule \"threat-intel IP match\" DISABLED\n# matches against all 2.1M current indicators now stop, including fresh ones.",
                                  feedback: "You have fixed the symptom by removing the sense organ. One bad indicator in a feed of millions is an indicator problem, not a rule problem — and disabled rules are almost never re-enabled.")
                    ]),
            LabStep(instruction: "Retrospective: what class of detection produced eleven wasted investigations, and what is the durable lesson?",
                    hint: "Think about where this kind of indicator sits on the pyramid you were taught — and what a well-chosen indicator at the *other* end would have cost you.",
                    options: [
                        LabOption("Atomic network indicators age badly; weight them by provenance and prefer behavioural detection",
                                  correct: true,
                                  output: "feed policy updated:\n  intel-match alerts now carry indicator age + confidence in the alert body\n  indicators with no confirmation in 180 days -> informational, not high\n  escalation path unchanged for behavioural detections (beaconing, rare-parent,\n  deception tripwires), which do not decay this way",
                                  feedback: "Correct. An IP or hash describes one moment of one campaign; the moment passes and the address gets resold, but the indicator lives on in a feed forever. Surfacing age and confidence in the alert itself means the analyst gets the context before the adrenaline, and keeps high priority for detections that describe behaviour instead of real estate."),
                        LabOption("The feed was low quality; buy a commercial one",
                                  output: "",
                                  feedback: "Commercial feeds carry stale and shared-infrastructure indicators too — the decay is a property of the indicator type, not the vendor. If your only fix is a procurement request, the same lab repeats with a bigger invoice."),
                        LabOption("The analysts were the problem; retrain them on escalation criteria",
                                  output: "",
                                  feedback: "Eleven analysts made the same call, which is a signal about the alert, not about the analysts. When a process fails identically for everyone who touches it, fix the information the process hands them — here, an alert that shouted \"Cobalt Strike\" and never mentioned that the evidence was fourteen months old.")
                    ])
        ])

    // MARK: - 4. Mapping behaviour to ATT&CK (intermediate)

    private static let attackMapping = InteractiveLab(
        id: "lab-attack-mapping",
        title: "Map the behaviour to ATT&CK",
        goal: "Turn three raw observations into the right techniques — specific enough to measure coverage against.",
        track: .blueTeam,
        difficulty: .intermediate,
        minutes: 7,
        scenario: "You are writing up a contained intrusion on a single workstation. Your manager wants the report mapped to ATT&CK so it can be overlaid in Navigator against what the SOC can currently detect. You have three clean observations from Sysmon and Zeek, and a strong urge to write \"malware\" in all three boxes.",
        debrief: "Mapping is only worth doing at the resolution where it changes a decision. \"Modify Registry\" and \"Registry Run Keys\" are both true of the same event, but only the second one tells you which detection you are missing and which tactic the adversary was serving. The discipline is to name the most specific technique the evidence actually supports — not the vaguest one that is safely correct, and not a more exciting one the evidence does not reach. The attacker's side of this: every technique you can name, you can hunt for across the fleet; every one you leave as \"malware\" stays a blind spot they can reuse next quarter.",
        tools: ["Sysmon", "Zeek", "ATT&CK Navigator"],
        relatedLessonID: "blue-mitre",
        steps: [
            LabStep(instruction: "Observation 1 — Sysmon Event ID 13 (registry value set):\n\n`TargetObject: HKU\\...\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\Updater`\n`Details: rundll32.exe C:\\Users\\Public\\svc.dll,StartW`\n`Image: C:\\Windows\\System32\\reg.exe`\n\nWhich technique?",
                    hint: "Two of these are genuinely true of this event. Pick the one that tells a defender what to go and build.",
                    options: [
                        LabOption("T1112 — Modify Registry",
                                  output: "T1112  Modify Registry  (tactics: Defense Impairment, Persistence)",
                                  feedback: "True, and too coarse to be useful. T1112 covers any registry change for any purpose — you reach for it when a value is altered to disable or impair a control. It *is* also carried under Persistence, so this is not strictly a wrong tactic; it is a wrong **altitude**. Mapping a specific, well-known persistence mechanism to the generic technique loses the one fact a detection engineer needs: *which* registry location, and therefore which rule to write."),
                        LabOption("T1547.001 — Boot or Logon Autostart Execution: Registry Run Keys / Startup Folder",
                                  correct: true,
                                  output: "T1547.001  Registry Run Keys / Startup Folder  (tactic: Persistence)\ncoverage check: no active detection on CurrentVersion\\Run writes  -> GAP",
                                  feedback: "Correct, and specific. The sub-technique names the exact mechanism, so the coverage gap it exposes is actionable: you can write one rule on writes to the Run keys and close it. That is the difference between a mapped report and a decorated one."),
                        LabOption("T1053.005 — Scheduled Task/Job: Scheduled Task",
                                  output: "T1053.005  Scheduled Task  (tactic: Persistence/Execution/Privilege Escalation)",
                                  feedback: "Right tactic, wrong mechanism. Scheduled tasks are a different artefact entirely — `schtasks.exe` or the Task Scheduler API, with task XML on disk. Mapping to the wrong mechanism sends your detection engineer to build a rule that would never have fired on this.")
                    ]),
            LabStep(instruction: "Observation 2 — Sysmon Event ID 1 (process create):\n\n`Image: C:\\Windows\\System32\\rundll32.exe`\n`CommandLine: rundll32.exe C:\\Users\\Public\\svc.dll,StartW`\n`ParentImage: C:\\Program Files\\Microsoft Office\\root\\Office16\\WINWORD.EXE`\n\nWhich technique best describes the rundll32 line?",
                    hint: "Ask what rundll32 is doing *for* the attacker here. It is not the interpreter and it is not the download.",
                    options: [
                        LabOption("T1059.001 — Command and Scripting Interpreter: PowerShell",
                                  output: "no powershell.exe or pwsh.exe in this process tree",
                                  feedback: "There is no PowerShell in this tree. It is the reflex mapping for \"something ran something\", and mapping a technique you did not observe is worse than leaving the cell blank — it inflates your reported coverage of a technique you have no evidence for."),
                        LabOption("T1218.011 — System Binary Proxy Execution: Rundll32",
                                  correct: true,
                                  output: "T1218.011  System Binary Proxy Execution: Rundll32  (tactic: Stealth)\nalso worth recording: WINWORD.EXE as parent -> macro-borne execution",
                                  feedback: "Correct. The point of rundll32 is that a signed, expected Microsoft binary carries the attacker's DLL, so allow-listing and naive reputation checks see a trusted process. That is proxy execution, and it sits under Defense Evasion."),
                        LabOption("T1105 — Ingress Tool Transfer",
                                  output: "T1105  Ingress Tool Transfer  (tactic: Command and Control)",
                                  feedback: "That is how `svc.dll` *arrived*, which is a separate observation you do not have evidence for in this event. Keep the download and the execution as distinct techniques — conflating them means neither detection gets built."),
                        LabOption("T1566.001 — Phishing: Spearphishing Attachment",
                                  output: "T1566.001  Spearphishing Attachment  (tactic: Initial Access)",
                                  feedback: "A reasonable inference from the Word parent, and an inference is not an observation. If you can produce the delivering email, map it and cite it; if you cannot, record Word as the parent process and say the initial access vector is unconfirmed.")
                    ]),
            LabStep(instruction: "Observation 3 — Zeek `dns.log`: 540 TXT queries over 9 hours, every one a unique 52-character label under a single registered zone, all `NOERROR` with answers, 60 s apart, total query-name volume 27 KB.\n\nWhich technique?",
                    hint: "Low volume, fixed interval, answers coming back. Decide whether the data is going out or the instructions are coming in.",
                    options: [
                        LabOption("T1048.003 — Exfiltration Over Unencrypted Non-C2 Protocol",
                                  output: "upstream in query names: 27 KB over 9 hours",
                                  feedback: "The closest wrong answer, and the one worth arguing about. Exfiltration over DNS looks like *volume* — megabytes of query names, sustained, often bursty. 94 KB with answers returning on a metronome is a control channel, not a shipment. Same protocol, different purpose, different detection and different impact in your report."),
                        LabOption("T1071.004 — Application Layer Protocol: DNS",
                                  correct: true,
                                  output: "T1071.004  Application Layer Protocol: DNS  (tactic: Command and Control)\nevidence: fixed 60s cadence, bidirectional, low volume, answers present\n-> C2 over DNS. (If upstream volume spikes, re-map/add T1048.)",
                                  feedback: "Correct. The tell is the shape: regular cadence plus answers coming back means the channel is carrying tasking, and the 27 KB is beacon chatter rather than stolen data. Note the honest caveat in the output — if volume later spikes, you add the exfiltration technique rather than rewriting history."),
                        LabOption("T1568.002 — Dynamic Resolution: Domain Generation Algorithms",
                                  output: "540 unique LABELS under 1 registered zone; 0 NXDOMAIN",
                                  feedback: "This is the distinction that catches people. A DGA produces many *different registered domains*, most of which do not exist, so you see a wall of NXDOMAIN. Here there is one zone, resolving successfully, with varying subdomains — that is tunnelling, not domain generation."),
                        LabOption("T1090 — Proxy",
                                  output: "",
                                  feedback: "Proxy describes routing traffic through an intermediary to hide its origin. Nothing here shows a relay — the host is talking to its own resolver, which is simply how DNS works.")
                    ]),
            LabStep(instruction: "You have T1547.001, T1218.011 and T1071.004. What do you do with the mapping?",
                    hint: "The mapping is an input to a decision. Which decision?",
                    options: [
                        LabOption("Check which of the three you already detect, then build the rule for the gap",
                                  correct: true,
                                  output: "Navigator overlay vs current ruleset:\n  T1218.011  rundll32 w/ Office parent   -> DETECTED (rule DE-0041, fired)\n  T1071.004  DNS C2                      -> PARTIAL (volume rule only, did not fire)\n  T1547.001  Run key persistence         -> NOT DETECTED\nqueued: DE-0088 Run-key write by non-allowlisted process",
                                  feedback: "Correct — that is the only reason to map anything. Note the honest middle row: a volume-threshold DNS rule exists and this beacon stayed under it, which is \"partial\", not \"covered\". Grading your own coverage generously is how a Navigator layer becomes a comfort blanket."),
                        LabOption("Add the three techniques to the threat-intel platform as indicators",
                                  output: "",
                                  feedback: "Techniques are not indicators. An indicator is an artefact you can match (a hash, a domain, a Run-key value); a technique is a behaviour you write a detection for. Filing TTPs in an IOC store means nothing will ever match them."),
                        LabOption("Block the hashes of svc.dll and rundll32.exe",
                                  output: "rundll32.exe is a signed Microsoft system binary present on every host",
                                  feedback: "One half does nothing and the other half breaks Windows. You just finished identifying durable behaviours and then reached for the most brittle indicator available — and for a hash of a system binary at that."),
                        LabOption("Report the three techniques to leadership as evidence of an advanced actor",
                                  output: "",
                                  feedback: "Run-key persistence and rundll32 proxy execution are commodity tradecraft, present in off-the-shelf loaders. Attribution inflation makes a report feel weightier and makes every future assessment less credible. Map the behaviour; let the behaviour speak.")
                    ]),
            LabStep(instruction: "Final sanity check — the Run-key write served which tactic?",
                    hint: "Tactics are the adversary's goal. Ask what the attacker gets from that registry value.",
                    options: [
                        LabOption("Stealth",
                                  output: "# ATT&CK renamed this tactic: TA0005 “Defense Evasion” is now “Stealth”,\n# and impairing a control is its own tactic, TA0112 Defense Impairment.",
                                  feedback: "Tempting because the registry is often where concealment happens — and disabling Defender would now map to the separate *Defense Impairment* tactic. But nothing about writing a Run value hides anything; it is noisy and easy to find. The goal was survival, not concealment. (Worth knowing the catalogue moves: if your reports still say “Defense Evasion”, they are on an older version of ATT&CK.)"),
                        LabOption("Persistence",
                                  correct: true,
                                  output: "T1547.001 -> Persistence\nwhy it matters: survives reboot, so containment that only kills the process\nleaves the foothold intact.",
                                  feedback: "Correct, and it is the tactic that changes your response. Persistence means the host is not clean when the process dies — eradication has to remove the Run value too, or the implant returns at next logon."),
                        LabOption("Execution",
                                  output: "",
                                  feedback: "Code does eventually run, which is why this is a near miss. Execution covers the techniques that run the code *now*; autostart entries are classified by their purpose of surviving a restart, which is Persistence.")
                    ])
        ])

    // MARK: - 5. Writing the detection (intermediate)

    private static let sigmaRule = InteractiveLab(
        id: "lab-sigma-rule",
        title: "Write the detection that catches it",
        goal: "Build a Sigma rule for shadow-copy destruction that fires on the technique and not on your backup team.",
        track: .blueTeam,
        difficulty: .intermediate,
        minutes: 8,
        scenario: "A purple-team exercise ran ransomware pre-encryption behaviour on a test host and your SOC saw nothing. Your job this sprint is one rule: catch an operator destroying Volume Shadow Copies before they encrypt. You have Sysmon process-creation telemetry, a test host, and a backup team who will escalate loudly if you page them at 02:00 for their own job.",
        debrief: "Shadow-copy destruction is close to the perfect detection target: it is a near-mandatory step for ransomware, it is rare in normal operations, and it happens *minutes* before encryption — so the alert still has time to be useful. What makes or breaks the rule is not the strings, it is the three things around them: covering the alternative binaries, requiring a combination rather than any single match, and proving the telemetry field you depend on is actually being collected. A rule that cannot fire is indistinguishable from a quiet network. The attacker's read on this: they do not need to defeat your rule if the field it keys on was never in your Sysmon config.",
        tools: ["Sigma", "Sysmon", "Atomic Red Team"],
        relatedLessonID: "blue-detection-engineering",
        steps: [
            LabStep(instruction: "Start with the obvious candidate: `vssadmin.exe delete shadows /all /quiet`. What do you key the rule on?",
                    hint: "Your backup team runs vssadmin every night. Think about what distinguishes their invocation from the attacker's.",
                    options: [
                        LabOption("Image|endswith: '\\vssadmin.exe' — the binary itself",
                                  output: """
test against 30 days of telemetry:
  matches: 9,412
  of which 'vssadmin list shadows' (backup verification): 9,380
  of which 'delete shadows': 0
""",
                                  feedback: "Nine thousand alerts for a tool that is mostly used legitimately. The binary is not the behaviour — `vssadmin list shadows` is a backup health check and `vssadmin delete shadows` is an attack, and your rule cannot tell them apart."),
                        LabOption("CommandLine|contains: 'vssadmin delete shadows /all /quiet' — the exact string",
                                  output: """
evades:
  vssadmin.exe delete shadows /quiet /all      (flag order)
  vssadmin  delete  shadows /all               (whitespace)
  "C:\\Windows\\System32\\vssadmin.exe" delete shadows  (quoted path)
  wmic shadowcopy delete                       (different binary entirely)
""",
                                  feedback: "Matching a literal command line is the string-equality trap. Flag order, extra whitespace, quoting and a different LOLBin all walk past it, and none of those are evasion techniques — they are just how people type."),
                        LabOption("Image on the binary AND CommandLine containing both 'delete' and 'shadow'",
                                  correct: true,
                                  output: """
detection:
    selection_img:
        Image|endswith: '\\vssadmin.exe'
    selection_cli:
        CommandLine|contains|all:
            - 'delete'
            - 'shadow'
    condition: all of selection_*

30-day backtest: 0 matches   purple-team replay: FIRES
""",
                                  feedback: "Correct. Keying on the binary plus an unordered set of substrings survives flag order, spacing and quoting, while `list shadows` no longer matches. `contains|all` is doing the real work here — it is a set test, not a string test.")
                    ]),
            LabStep(instruction: "The purple team re-runs the exercise with `wmic shadowcopy delete` and your rule stays silent. How do you fix it?",
                    hint: "The behaviour is \"destroy recovery points\". Enumerate the tools that can do that, not the one you saw first.",
                    options: [
                        LabOption("Add a second rule for wmic.exe",
                                  output: "rules: DE-0091 (vssadmin), DE-0092 (wmic)\n# next exercise uses diskshadow.exe -> DE-0093 ...",
                                  feedback: "It works and it does not scale. One behaviour spread across N rules means N backtests, N tuning records and N chances for one to silently break. Group the binaries inside one rule and you tune the behaviour once."),
                        LabOption("Extend the image list to the other binaries that can destroy recovery points",
                                  correct: true,
                                  output: """
title: Shadow Copy Destruction via System Utilities
logsource:
    category: process_creation
    product: windows
detection:
    selection_img:
        - Image|endswith:
            - '\\vssadmin.exe'
            - '\\wmic.exe'
            - '\\diskshadow.exe'
            - '\\wbadmin.exe'
            - '\\powershell.exe'
        - OriginalFileName:
            - 'VSSADMIN.EXE'
            - 'wmic.exe'
            - 'diskshadow.exe'
            - 'WBADMIN.EXE'
            - 'PowerShell.EXE'
    selection_cli:
        CommandLine|contains|all:
            - 'delete'
            - 'shadow'
    condition: all of selection_*
tags:
    - attack.impact
    - attack.t1490
level: critical
""",
                                  feedback: "Correct, and note the `OriginalFileName` branch: it is read from the PE version resource, so a renamed copy of vssadmin still matches. Catching the technique means enumerating the tools that implement it — vssadmin, wmic, diskshadow, wbadmin and PowerShell's Win32_ShadowCopy."),
                        LabOption("Drop the Image condition and match the command line alone",
                                  output: """
30-day backtest: 1,106 matches
  git commit -m \"delete shadow dom test\"          -> match
  msbuild ... /t:Clean  (logs 'delete' + 'shadowcache') -> match
  robocopy /purge  logs containing both words      -> match
""",
                                  feedback: "Now any command line that happens to contain both words fires. Removing the anchor makes the rule broader, not stronger — the substrings were only meaningful in the context of a tool that can actually destroy shadow copies.")
                    ]),
            LabStep(instruction: "Your `condition:` currently reads `all of selection_*`. A colleague suggests `1 of selection_*` so you catch more. Your call?",
                    hint: "Work out what `1 of` actually matches when only the image branch is satisfied.",
                    options: [
                        LabOption("Switch to 1 of selection_* — broader is safer for a critical technique",
                                  output: """
condition: 1 of selection_*
30-day backtest: 41,388 matches
  every powershell.exe launch in the estate                -> match
  every wmic.exe inventory query                           -> match
  every command line containing 'delete' + 'shadow'        -> match
""",
                                  feedback: "`1 of` makes the branches alternatives instead of requirements, so the rule now fires on PowerShell existing. Forty thousand alerts a month is not broader coverage — it is the rule being switched off by the people who have to read it."),
                        LabOption("Keep all of selection_* — both the tool and the intent must be present",
                                  correct: true,
                                  output: "condition: all of selection_*\n30-day backtest: 0 matches\npurple-team replay (vssadmin / wmic / powershell): FIRES 3/3\n  wbadmin, diskshadow:  NO MATCH  -> see feedback",
                                  feedback: "Correct. The precision comes from the conjunction: a capable binary *and* a command line expressing destruction. Zero false positives over thirty days is the shape of a rule you are allowed to page someone at 02:00 with.\n\nNow read the replay line you did **not** expect: `wbadmin` and `diskshadow` are in your image list but never fire. `wbadmin`'s destructive verb is `delete catalog` — no ‘shadow’ — and `diskshadow` takes its commands from a script file (`/s script.txt`), so its command line carries neither word. A conjunction that is right for one tool can be structurally unsatisfiable for another. This is exactly why the real SigmaHQ rule for T1490 uses **separate selections** per tool rather than one shared command-line test. Listing a binary in your rule is not the same as covering it — replay every tool you claim."),
                        LabOption("Use all of selection_* but add a filter excluding the backup service account",
                                  output: "filter:\n    User: 'CORP\\svc_backup'\n# svc_backup is a privileged account and a standard credential-theft target",
                                  feedback: "A sensible-sounding exclusion that hands the attacker a bypass. The backup service account is high-privilege and frequently stolen precisely because it can touch recovery points — excluding it blinds you to the most dangerous version of this event. And you already backtested at zero, so there was nothing to exclude.")
                    ]),
            LabStep(instruction: "Before you ship: how do you prove the rule can actually fire?",
                    hint: "A rule can be perfect and still never trigger. What has to be true of your telemetry for `CommandLine` to be there at all?",
                    options: [
                        LabOption("Deploy it and watch production for a month",
                                  output: "30 days later: 0 alerts.\n(indistinguishable from: nobody attacked us / the rule is broken /\n CommandLine is not logged / the rule never deployed)",
                                  feedback: "Zero alerts is not evidence of anything. This is the single most common way a detection programme fools itself — a wall of green rules, none of which has ever been observed to fire, and no way to tell the healthy ones from the dead ones."),
                        LabOption("Emulate the technique on the test host and confirm the alert appears end to end",
                                  correct: true,
                                  output: """
atomic test T1490 (shadow copy deletion) -> executed on TEST-W11-02
Sysmon EID 1 captured: CommandLine populated (config includes ProcessCreate)
SIEM: index -> field mapping ok -> rule DE-0091 MATCHED
alert -> on-call page received, 41s end to end
""",
                                  feedback: "Correct, and note what the test actually validated: not just the rule logic, but that Sysmon is configured to log process creation, that `CommandLine` survived ingestion and field mapping, and that the alert reached a human. Any one of those breaking makes a perfect rule invisible."),
                        LabOption("Replay the backtest against historical data — if it matched nothing, it is clean",
                                  output: "backtest confirms 0 historical matches\n# but historical data would also show 0 if CommandLine was never indexed",
                                  feedback: "A backtest proves the rule does not produce noise. It cannot prove the rule produces signal, and it shares the blind spot you are trying to rule out: if the field is missing from your telemetry, both the backtest and the live rule return nothing."),
                        LabOption("Peer-review the YAML against the SigmaHQ equivalent",
                                  output: "review: logic sound, field names correct, tags correct",
                                  feedback: "Worth doing, and it validates the rule in isolation. It says nothing about whether *your* Sysmon config, *your* ingestion pipeline and *your* alert routing carry the event from the endpoint to a pager.")
                    ]),
            LabStep(instruction: "It fires. What severity and what response do you attach?",
                    hint: "How long do you have between this behaviour and the thing it precedes?",
                    options: [
                        LabOption("Low, for a month, so you can observe the real false-positive rate first",
                                  output: "alert severity: low -> dashboard only, reviewed next business day\n[02:14] rule fires on FS-01\n[02:31] encryption begins across 9 file servers\n[09:05] analyst opens the dashboard",
                                  feedback: "This is sound practice applied to the wrong rule. Baselining before alerting is exactly right for a noisy behavioural rule — and this one backtested at zero over thirty days and precedes mass encryption by minutes. Your observation window is longer than the attack."),
                        LabOption("Critical, page immediately, with host isolation pre-staged for one-click approval",
                                  correct: true,
                                  output: """
severity: critical   route: page on-call immediately, 24x7
playbook DE-0091:
  auto   enrich host, user, parent process, recent 4624/4672 for the account
  auto   list hosts where the same account authenticated in the last 2h
  human  one-click: isolate host + disable account   (gated, not automatic)
""",
                                  feedback: "Correct on both halves. Critical and 24x7 because the window to act is minutes, and the containment is pre-staged but gated — the enrichment runs automatically while a human approves the destructive step. That is the balance SOAR is for."),
                        LabOption("Critical, with fully automatic isolation of any host that fires",
                                  output: "auto-isolate enabled.\n[later] rule fires on BACKUP-SRV-01 during a storage migration\nbackup infrastructure isolated mid-job at 02:00, unattended",
                                  feedback: "Closer to defensible than the others, and still the wrong trade. Fully automatic destructive action on a rule this new, with no human in the path, means your worst case is a self-inflicted outage on exactly the infrastructure you need during a real event. Gate it until the rule has a track record."),
                        LabOption("Medium, and add it to the morning triage queue",
                                  output: "",
                                  feedback: "A medium-severity queue item is a decision to read it during office hours. Ransomware operators pick the small hours and the long weekend precisely because that is when your queue is a queue and not a person.")
                    ])
        ])

    // MARK: - 6. Containing an account compromise (intermediate)

    private static let accountContainment = InteractiveLab(
        id: "lab-account-containment",
        title: "Contain an account compromise",
        goal: "Cut an attacker out of a cloud identity completely — not just out of the password.",
        track: .blueTeam,
        difficulty: .intermediate,
        minutes: 8,
        scenario: "An impossible-travel alert fires on `kavya@corp.example`, a finance manager. Two interactive sign-ins forty minutes apart from two continents, both marked successful, both with MFA satisfied. She is at her desk and says she has not travelled. You have full admin on the identity tenant and the authority to contain.",
        debrief: "Password reset is the action everyone reaches for and the one that does the least. A modern cloud compromise lives in **tokens** and **persistence inside the identity**: a refresh token already issued, a second authenticator the attacker registered, an inbox rule quietly forwarding the finance thread, an OAuth app consented to with mail scopes. Reset the password and the attacker's session carries on untouched, and even if you kill it they walk back in through the authenticator they added. The sequencing lesson is the whole lab: revoke the sessions, strip the persistence, *then* confirm scope — and do not declare it closed because the alert stopped firing.",
        tools: ["identity provider", "Microsoft Graph PowerShell", "Exchange Online"],
        relatedLessonID: "blue-incident-response",
        steps: [
            LabStep(instruction: "Sign-in log, trimmed:\n\n`09:02  SUCCESS  MFA: Authenticator (push)  AS64500  corp VPN egress  Edge/Windows`\n`09:41  SUCCESS  MFA: Authenticator (push)  AS64502  unseen ASN        Chrome/Windows`\n`08:55  SUCCESS  (audit) Authentication method registered: Authenticator app`\n\nWhich line makes this a compromise rather than a travelling user?",
                    hint: "Impossible travel alone has a long list of boring explanations. One of these lines has none.",
                    options: [
                        LabOption("The 09:41 sign-in is from an ASN with no prior sign-ins in this tenant",
                                  output: "AS64502: 0 prior sign-ins, 0 prior tenants\n(also consistent with: travel, a new mobile carrier, a consumer VPN, a hotel)",
                                  feedback: "Suspicious, not conclusive. New networks appear constantly — VPNs, hotel Wi-Fi, a phone hotspot on a roaming carrier. On its own this is the alert, not the finding."),
                        LabOption("A new authenticator was registered at 08:55, seven minutes before the first sign-in",
                                  correct: true,
                                  output: "audit: Authentication method registered\n  method   Microsoft Authenticator (push)\n  actor    kavya@corp.example\n  ip       198.51.100.88  (AS64502 — same ASN as the 09:41 sign-in)\n  time     08:55\nuser confirms: did not register a new authenticator",
                                  feedback: "Correct — and notice what it explains. Both sign-ins show \"MFA satisfied\" because the attacker approved their *own* push. Registering a second factor is how a credential compromise becomes a durable one, and it is the single highest-value line in this log."),
                        LabOption("Both sign-ins succeeded with MFA, so MFA has been bypassed entirely",
                                  output: "",
                                  feedback: "MFA was not bypassed; it was *enrolled in*. That distinction matters because the fix is different — you are not looking for a protocol weakness, you are looking for an attacker-controlled authenticator to remove."),
                        LabOption("The user agent differs between the two sign-ins",
                                  output: "09:02 Edge/Windows   09:41 Chrome/Windows",
                                  feedback: "Almost meaningless on its own. People use two browsers, two machines, a phone and a tablet. Chasing user-agent deltas is how an analyst spends an afternoon and produces nothing.")
                    ]),
            LabStep(instruction: "Confirmed compromise, attacker possibly active right now. First containment action?",
                    hint: "Ask what is currently keeping the attacker signed in. It is not the password.",
                    options: [
                        LabOption("Reset her password and force a change at next sign-in",
                                  output: "password reset: OK\n[09:58] session from 198.51.100.88 still active — refresh token issued 09:41 remains valid\n[10:04] attacker downloads 3 mailbox folders",
                                  feedback: "The move everyone makes, and by itself it is the move the attacker is counting on. A refresh token already in their hands keeps minting access tokens for hours regardless of the new password. You have inconvenienced her and not touched them."),
                        LabOption("Reset the password and revoke all refresh tokens and active sessions",
                                  correct: true,
                                  output: "Revoke-MgUserSignInSession -UserId kavya@corp.example\n  refresh tokens invalidated\n  NOTE: access tokens already issued remain valid until they expire (~1h)\n        unless Continuous Access Evaluation is enabled\npassword reset: OK (out-of-band confirmation with Kavya by phone)\n[10:01] session from 198.51.100.88 -> 401, re-auth required",
                                  feedback: "Correct, and it has to be both. The reset closes the credential, the revocation closes the sessions already issued from it — and you confirmed the reset with her by phone rather than by email, because her mailbox is the thing you do not trust."),
                        LabOption("Block the IP 198.51.100.88 and the ASN at conditional access",
                                  output: "named location blocked.\n[09:59] same session resumes from a different address in minutes",
                                  feedback: "Addresses are rented and rotated in seconds, and the attacker already holds a valid token so they are not re-authenticating anyway. Geographic and IP blocks are a hardening measure, not a containment action."),
                        LabOption("Disable the account outright",
                                  output: "account disabled.\nKavya locked out mid-quarter-close; attacker's existing token still functions for ~1h\nuntil it expires; her mailbox now inaccessible to responders too.",
                                  feedback: "The nuclear option, and strangely weaker than it looks: on some platforms a disabled account's already-issued access token keeps working until it expires, so you may lock out the user and not the intruder. Revoke the sessions — that is the action that is immediate for both."),
                        LabOption("Have her run a full antivirus scan on her laptop",
                                  output: "scan: no threats found",
                                  feedback: "This is the valuable wrong answer. The endpoint is a legitimate thing to check — a token could have been stolen by malware — but the compromise you can see is in the cloud identity, and a scan does nothing about a live session. Endpoint triage is step four, not step one.")
                    ]),
            LabStep(instruction: "Sessions revoked. You have not finished containing. What is still outstanding?",
                    hint: "Two kinds of persistence live inside an identity rather than on a machine. One of them you already saw in the audit log.",
                    options: [
                        LabOption("Nothing — with the password changed and sessions killed, the account is secure",
                                  output: "[11:20] sign-in SUCCESS, MFA: Authenticator (push), AS64502\n# the authenticator registered at 08:55 is still enrolled. They walked back in.",
                                  feedback: "They registered their own second factor at 08:55. Resetting the password just means they use the new one you set — or trigger a self-service reset, approve it with their own authenticator, and set a password you do not know."),
                        LabOption("Remove the attacker-registered authenticator, then audit app consents and inbox rules",
                                  correct: true,
                                  output: """
auth methods: removed Authenticator registered 08:55 from 198.51.100.88
              remaining: 1 (hardware key, registered 2024, retained)
Get-InboxRule -Mailbox kavya@corp.example
  Name           "..."              (hidden, blank display name)
  ForwardTo      ext-archive@mailer-7.example
  Conditions     SubjectContains: invoice, payment, IBAN, remittance
  -> removed, rule exported to evidence first
OAuth grants: 1 added 09:44 — "PDF Converter Pro", scopes Mail.Read offline_access
  -> consent revoked, app blocked tenant-wide
""",
                                  feedback: "Correct, and this is where the real damage was hiding. The forwarding rule is a silent exfiltration channel scoped to exactly the finance keywords, and the OAuth grant with `offline_access` is a token source that survives every password reset you will ever do. Note that you exported the rule before deleting it."),
                        LabOption("Re-enable normal access and monitor the account closely for a week",
                                  output: "monitoring enabled.\n[11:20] attacker signs back in via their own authenticator. Monitored, not prevented.",
                                  feedback: "Monitoring a route you have chosen not to close is not a control. Watch-and-wait has a place in scoping a wide intrusion, but not as a substitute for removing persistence you have already identified."),
                        LabOption("Rotate her Kerberos and on-premises credentials as well",
                                  output: "on-prem password synchronised; no evidence of on-prem authentication by the attacker",
                                  feedback: "Sensible if the identity is hybrid and in scope, and it is still the wrong next action. You have concrete, observed cloud persistence sitting in the audit log — close what you can see before you widen to what you cannot.")
                    ]),
            LabStep(instruction: "One account is clean. Can you close the incident?",
                    hint: "Ask the question the attacker's own behaviour suggests: what would they have done with mailbox access to a finance manager?",
                    options: [
                        LabOption("Yes — the compromised account is contained and the alert has stopped",
                                  output: "case closed 12:10.\n[two weeks later] a supplier is paid into an attacker-controlled account after a\nthread that was never reported, from a second finance mailbox compromised 09:50.",
                                  feedback: "The alert stopping tells you your containment worked on the thing that alerted. Business email compromise is almost never one mailbox — a mailbox is a platform for reaching the next one, and internal mail from a trusted colleague is the most effective phish in the estate."),
                        LabOption("No — scope it first: the same ASN, user agent and consented app across all accounts, plus every forwarding rule created in the window",
                                  correct: true,
                                  output: """
tenant-wide sweep, 08:00-12:00:
  sign-ins from AS64502           -> 3 accounts (kavya + 2 in accounts-payable)
  consent to "PDF Converter Pro"  -> 3 accounts, all in the same window
  inbox rules created             -> 4 (3 forwarding, 1 moving replies to RSS Feeds)
  internal mail sent from kavya   -> 11 messages, 2 with a credential-harvest link
-> incident re-scoped: 3 accounts, 11 internal phishes to recall
""",
                                  feedback: "Correct. The indicators you earned from one account are the query that finds the rest — the ASN, the consented app, the rule pattern, the window. Note the fourth rule: moving replies into a folder nobody reads is how the victim never sees the bounce-backs."),
                        LabOption("No — notify all 4,000 staff immediately that the tenant is compromised",
                                  output: "company-wide email sent 12:10.\n# sent via the mail system the attacker still has access to in 2 other mailboxes;\n# 400 replies in 20 minutes; 2 genuine reports buried.",
                                  feedback: "Premature mass notification tips the attacker, buries the signal in panic, and in this case is sent over infrastructure you have not finished containing. Targeted warnings to the people actually at risk, through a channel you trust, then broad comms once you know scope."),
                        LabOption("No — engage external forensics before taking any further action",
                                  output: "",
                                  feedback: "Over-correcting the other way. Calling in help is right for a large or legally sensitive incident, but scoping a cloud identity compromise is routine work you can do now, and the forwarding rules are exfiltrating while you wait for a contract to be signed.")
                    ]),
            LabStep(instruction: "Three accounts contained, rules removed, consent revoked. What has to be true before you call it closed?",
                    hint: "Closure is a claim about eradication and about the vector. Which of these actually tests both?",
                    options: [
                        LabOption("All three accounts re-enabled and the users back at work",
                                  output: "",
                                  feedback: "That is recovery, not closure. Restoring service says nothing about whether the way in is still open or whether a fourth mailbox is still forwarding."),
                        LabOption("Vector identified and closed, no remaining rules or grants tenant-wide, and heightened monitoring held for an agreed period",
                                  correct: true,
                                  output: """
eradication verified:
  initial access  adversary-in-the-middle phish, 06:10, link in a shared-document lure
                  -> URL blocked, 2 other recipients identified and reset
  persistence     0 attacker auth methods, 0 forwarding rules, 0 attacker consents
                  (re-run as a scheduled tenant query, not a one-off check)
  hardening       phishing-resistant MFA enforced for finance; admin consent required
                  for all apps requesting Mail.* scopes
  monitoring      heightened for 30 days on the 3 accounts + the consent audit
""",
                                  feedback: "Correct. Closure needs the vector (so it does not recur tomorrow), verified absence of persistence *as a repeatable query* rather than a one-time look, and a monitoring tail — because identity attackers routinely come back through a path you did not enumerate. The hardening item is what turns an incident into an improvement."),
                        LabOption("A post-incident report written and circulated",
                                  output: "",
                                  feedback: "The report is how the lesson survives; it is not evidence of eradication. Plenty of beautifully documented incidents were closed with an attacker still holding a refresh token."),
                        LabOption("Thirty days with no further alerts from the same ASN",
                                  output: "",
                                  feedback: "You are measuring the attacker's choice of exit node. They change ASN for free; and an absence of alerts from one indicator is the weakest possible evidence of absence. Verify the persistence is gone, do not wait to see whether it announces itself.")
                    ])
        ])

    // MARK: - 7. Exfiltration over DNS (advanced)

    private static let dnsExfil = InteractiveLab(
        id: "lab-dns-exfil",
        title: "Find the exfil in the Zeek logs",
        goal: "Separate DNS tunnelling from DGA and from noise, then cut the channel without blinding yourself.",
        track: .blueTeam,
        difficulty: .advanced,
        minutes: 9,
        scenario: "Overnight anomaly: `10.20.7.31`, a Legal workstation, generated more DNS traffic in six hours than the rest of its floor did all week. There is no endpoint alert, no intel hit, and the host looks ordinary in the EDR console. You have Zeek logs from the egress sensor and the internal resolver's query log.",
        debrief: "DNS is the protocol defenders leave open because everything breaks without it, which is exactly why it carries data out of networks that block everything else. The shape is what identifies it: the question is not \"is this domain bad\" but \"how many unique labels under one zone, in which direction is the volume, and does it resolve\". That last pair separates tunnelling from a domain-generation algorithm, and upstream-versus-downstream volume separates exfiltration from command and control. The attacker's assumption was that your egress filtering stops at TCP and that nobody aggregates query names per parent domain — which, in most networks, is a correct assumption.",
        tools: ["Zeek", "zeek-cut", "DNS resolver logs"],
        relatedLessonID: "blue-nsm-monitoring",
        steps: [
            LabStep(instruction: "You have a volume anomaly and nothing else. Where do you look first?",
                    hint: "You need to know *what was asked*, not just how much. Pick the log that carries the question.",
                    options: [
                        LabOption("conn.log, filtered to port 53, to quantify the traffic",
                                  output: "cat conn.log | zeek-cut id.orig_h id.resp_h id.resp_p proto service orig_bytes resp_bytes\n10.20.7.31  10.20.1.10  53  udp  dns  41289114  3174882\n# one peer: the internal resolver. Which is where every host's DNS goes.",
                                  feedback: "It confirms the volume and tells you nothing about the content — and the only peer is your own resolver, as it should be. You already knew the volume was anomalous; that is what put the ticket in your queue."),
                        LabOption("dns.log, aggregated by registered parent domain and unique label count",
                                  correct: true,
                                  output: """
cat dns.log | zeek-cut id.orig_h query qtype_name rcode_name | grep ^10.20.7.31
  ...  7KQ2XB4FLZ3NVA6TMWJ...s3-sync.cdn-metrics.example  TXT  NOERROR
  ...  QD9PRH1YCX8KEB2SNUT...s3-sync.cdn-metrics.example  TXT  NOERROR
  ...  M4VJ7ZTA0LWQ6RXCB9F...s3-sync.cdn-metrics.example  TXT  NOERROR

aggregate, last 6h, host 10.20.7.31:
  parent zone              queries   unique labels   qtype   rcode
  cdn-metrics.example      214,061   214,061         TXT     NOERROR (100%)
  all other zones            1,208       402         mixed   mixed
""",
                                  feedback: "Correct, and the aggregation is what makes it obvious. Two hundred thousand queries, every single label unique, one parent zone, all TXT, all resolving successfully. Unique-labels-per-parent-domain is the single most useful DNS aggregation a defender can build."),
                        LabOption("Full packet capture for the host, to see the payloads",
                                  output: "pcap for 10.20.7.31, 6h: 2.9 GB retrieved",
                                  feedback: "The right tool at the wrong point in the investigation. PCAP is expensive to pull and search, and you do not yet know what you are looking for — ten seconds with `dns.log` tells you which zone to carve out of it."),
                        LabOption("The EDR process timeline for the host",
                                  output: "no unsigned processes, no new services, no unusual parents in the last 7 days",
                                  feedback: "A fair instinct given there is no endpoint alert, and it comes back clean — which is precisely why the network is your vantage point here. Come back to the endpoint once the network tells you what process to look for.")
                    ]),
            LabStep(instruction: "Two hundred thousand unique labels under one zone, all TXT, all NOERROR. What is this?",
                    hint: "Compare it to what a domain-generation algorithm would look like in the same log. The difference is in two columns.",
                    options: [
                        LabOption("A domain-generation algorithm searching for its C2",
                                  output: "DGA signature: many distinct REGISTERED domains, most NXDOMAIN\nobserved here:  one registered zone, 100% NOERROR\n",
                                  feedback: "This is the confusion worth fixing permanently. A DGA generates many *different second-level domains* and nearly all of them are unregistered, so your log fills with NXDOMAIN. Here it is one registered zone resolving every time, with the variation in the subdomain — the opposite shape."),
                        LabOption("DNS tunnelling: data encoded into query labels under an attacker-controlled zone",
                                  correct: true,
                                  output: """
whois cdn-metrics.example
  created        2026-09-26  (6 days ago)
  nameservers    ns1.cdn-metrics.example  ->  192.0.2.117
  registrar      privacy-protected
qname analysis
  mean qname len 189 bytes   (3 labels, each <= 63 — the RFC 1035 label cap)
  charset        A-Z 0-9 (base32-like)        entropy  4.98 bits/char
  authoritative NS answers every query -> the zone's own server is the endpoint
""",
                                  feedback: "Correct. The attacker owns the zone, so their nameserver receives every label your resolver dutifully forwards — the resolver is the courier and the labels are the cargo. A zone registered six days ago with privacy-protected registration and base32 labels is not a CDN."),
                        LabOption("A misconfigured application retrying a failed lookup",
                                  output: "214,061 queries, 214,061 DISTINCT labels",
                                  feedback: "A retry loop asks the *same* question repeatedly — high volume, near-zero unique labels. Every label here is different, which means each one is carrying new information. Uniqueness is the discriminator between a bug and a channel."),
                        LabOption("Legitimate TXT lookups — SPF, DMARC and certificate validation all use TXT",
                                  output: "legitimate TXT lookups: _dmarc.<domain>, _acme-challenge.<domain>, v=spf1 records\nobserved: 189-byte random labels, 214,061 of them, one zone",
                                  feedback: "A genuinely important point in the wrong place. TXT really is used heavily by SPF, DMARC and ACME, which is why \"alert on TXT queries\" is a terrible rule — but legitimate TXT lookups use a handful of predictable names, not two hundred thousand random ones.")
                    ]),
            LabStep(instruction: "Tunnelling confirmed. Is this command and control, or exfiltration?",
                    hint: "The answer is a ratio. Work out which direction the bytes are going and how many of them there are.",
                    options: [
                        LabOption("Command and control — tunnelled DNS with a regular cadence is a beacon",
                                  output: "inter-arrival: mean 0.10s, highly irregular, bursty\nupstream (query names): 40.4 MB    downstream (answers): 3.0 MB",
                                  feedback: "Cadence is the C2 tell and this has none — ten queries a second in bursts is a transfer, not a heartbeat. The shape of C2 over DNS is low volume on a metronome with answers carrying tasking; this is the mirror image."),
                        LabOption("Exfiltration — the volume is overwhelmingly upstream, in the query names",
                                  correct: true,
                                  output: """
direction analysis, 6h window
  upstream   214,061 queries x mean 189 B of label  =  40.4 MB
  downstream 214,061 answers x mean 14 B           =   3.0 MB
  ratio      13:1 outbound
  sustained throughput ~15 kbit/s, consistent with a DNS tunnelling client
endpoint pivot: 10.20.7.31 read 1,902 files under \\\\fs-legal\\Contracts in the
same window (service account access, user session idle)
""",
                                  feedback: "Correct, and note what settled it: a thirteen-to-one outbound ratio with the payload carried in the labels. The answers are tiny because they are only acknowledgements. Pairing that with the file reads on the Legal share turns \"odd DNS\" into \"forty megabytes of contracts left the building\"."),
                        LabOption("Cannot tell without decoding the payload",
                                  output: "",
                                  feedback: "You can tell, and you should, before you spend a day on decoding. Direction and volume are available from the log you already have, and they are what your incident commander needs in the next five minutes. Decode later for the detail of *what* left."),
                        LabOption("Exfiltration — the queries are TXT, and TXT is how data is carried out",
                                  output: "",
                                  feedback: "Right answer, wrong reason, and the reason is what you will be asked to defend. TXT is convenient for the *answers*, but tunnelling works over A, AAAA, CNAME, NULL and MX records too. The direction ratio is the evidence; the record type is incidental.")
                    ]),
            LabStep(instruction: "Forty megabytes are gone and the channel is still open. First move?",
                    hint: "One of these stops the channel for every host at once. One of them does nothing at all, for a reason worth understanding.",
                    options: [
                        LabOption("Block outbound UDP/53 from 10.20.7.31 at the perimeter firewall",
                                  output: "rule added: deny udp/53 from 10.20.7.31 to any\nexfiltration continues: the host queries 10.20.1.10 (internal resolver), which\nis permitted, and the resolver makes the external query on its behalf.",
                                  feedback: "This is the trap, and it catches experienced people. The workstation never talks to the internet on port 53 — it talks to your internal resolver, which is allowed, and the resolver does the external lookup. Blocking the client's egress changes nothing because the client was never the one leaving."),
                        LabOption("Sinkhole the zone at the internal resolver, keeping the queries logged",
                                  correct: true,
                                  output: """
resolver policy: cdn-metrics.example -> sinkhole 10.20.1.250, log all queries
  10.20.7.31  queries now answered by sinkhole -> channel dead
  all other hosts covered by the same policy, immediately
  queries still recorded -> any other infected host reveals itself by asking
""",
                                  feedback: "Correct, and it does three things at once: the channel dies for every host in the estate, you keep full visibility of who asks (which is how you find the hosts you have not identified yet), and the infected process sees a resolution failure rather than an obvious containment event."),
                        LabOption("Isolate 10.20.7.31 from the EDR console right now",
                                  output: "10.20.7.31: containment ENABLED\nexfiltration from this host stops.\n[resolver log, next 40 min] 2 other hosts continue querying cdn-metrics.example",
                                  feedback: "A legitimate action, and the sequencing is wrong — this is the lab's real lesson. Isolating one host stops one host and announces to the operator that they are detected while their other footholds keep running. The resolver sinkhole contains everyone in the same move, and *then* you isolate."),
                        LabOption("Take the internal resolver offline until the zone can be analysed",
                                  output: "resolver down. all DNS resolution fails estate-wide.",
                                  feedback: "You have stopped the exfiltration and everything else. Self-inflicted outages are a real response failure mode, and a targeted sinkhole achieves the containment with none of the blast radius.")
                    ]),
            LabStep(instruction: "Channel sinkholed. What do you build so the next zone does not need a volume anomaly to be noticed?",
                    hint: "The zone is disposable. Write the detection against what the technique cannot avoid doing.",
                    options: [
                        LabOption("Add cdn-metrics.example and 192.0.2.117 to the blocklist",
                                  output: "blocklist updated.\n# next zone: registered for the price of a coffee, operational the same day.",
                                  feedback: "Necessary cleanup, useless as detection. You have blocked the one zone the attacker has already finished using, and the bottom of the pyramid is exactly where you were when this started."),
                        LabOption("Alert on unique-label count per parent domain per host, with label length and entropy as supporting signals",
                                  correct: true,
                                  output: """
detection DE-0104  DNS tunnelling (T1071.004 / T1048)
  for each (src_host, registered_parent_domain) per hour:
      unique_labels    > 200
  AND mean_label_len   > 40 bytes
  AND NOERROR_ratio    > 0.9
  AND parent_domain first seen in the environment < 30 days ago
backtest, 90 days:  4 matches
  3 = known: endpoint security vendor's reputation lookups  -> allowlisted by
      vendor-owned parent domain (not by IP)
  1 = this incident, first detectable 5h41m before the volume anomaly fired
""",
                                  feedback: "Correct. Every one of those conditions is something tunnelling must do: many unique labels because the data is in the labels, long labels because short ones are inefficient, successful resolution because the channel needs answers, and a young domain because the infrastructure is disposable. Note that the backtest found it nearly six hours earlier than the volume threshold did — and that the allowlist is keyed to a vendor-owned domain, not an address."),
                        LabOption("Alert on all TXT queries leaving the environment",
                                  output: "estimated volume: 61,000 alerts/day (SPF, DMARC, DKIM selector and ACME lookups)",
                                  feedback: "A false-positive storm by construction. TXT is load-bearing for mail authentication and certificate issuance — the very controls this course spends a lesson on. The record type is not the anomaly."),
                        LabOption("Alert on any host whose DNS query volume exceeds three standard deviations from its baseline",
                                  output: "this incident: would fire at 05:41 elapsed (it did — that is the ticket you were given)\nslow-and-low variant at 2 queries/sec: never fires",
                                  feedback: "This is the detection you already have, and it is the one that let forty megabytes leave before it tripped. Volume thresholds are defeated by patience; shape-based detection is not.")
                    ])
        ])

    // MARK: - 8. Hunting a beacon (advanced)

    private static let beaconHunt = InteractiveLab(
        id: "lab-beacon-hunt",
        title: "Hunt a beacon from one weak signal",
        goal: "Turn a timing oddity into a scoped intrusion, then make the isolate-or-observe call correctly.",
        track: .blueTeam,
        difficulty: .advanced,
        minutes: 9,
        scenario: "Nothing has alerted. You have a hunt day and a hypothesis borrowed from ATT&CK: *if an operator has a foothold here, something is calling home on a schedule.* You have ninety days of Zeek `conn.log` and `ssl.log`, EDR process telemetry, and no indicators at all.",
        debrief: "A hunt is a hypothesis plus a discriminator. The hypothesis was easy — implants beacon. The discriminator is what made it tractable: **regularity times rarity**. Regular traffic alone is mostly your own software phoning its vendor; rare destinations alone are mostly a user visiting an obscure site once. Insist on both and a ninety-day haystack collapses to a handful of candidates. Then comes the decision the lab is really about: with a nine-day dwell and an interactive operator, isolating the first host you find tells them they are burned while their other footholds survive. Scope fast, contain everything at once. The attacker's defence against you was jitter and a long interval — which is exactly why you measured variance rather than looking for an exact period.",
        tools: ["Zeek", "EDR", "JA3"],
        relatedLessonID: "blue-threat-hunting",
        steps: [
            LabStep(instruction: "Your hypothesis is \"something beacons on a schedule\". What is the query?",
                    hint: "You have no indicators, so you cannot look anything up. You have to describe the behaviour statistically.",
                    options: [
                        LabOption("Check every external destination in conn.log against the threat-intel feeds",
                                  output: "90 days, 412,000 distinct external destinations -> 19 intel hits\n  17 stale/shared-infrastructure (see the false-positive lab)\n  2 ad-network domains on a tracker blocklist\nactive C2 infrastructure registered this quarter: 0 hits",
                                  feedback: "This is hunting with the alerting you already have. Live C2 infrastructure is usually too new to be in any feed — that is the whole reason a hunt exists. If feeds could find it, it would have alerted on Tuesday."),
                        LabOption("Group by source and destination pair, then flag low variance in inter-arrival time over a long-lived, low-volume relationship",
                                  correct: true,
                                  output: """
for each (id.orig_h, id.resp_h): stddev of inter-arrival, span, mean bytes
filter: stddev/mean < 0.25  AND span > 72h  AND mean_bytes < 8 KB
  -> 340 candidate pairs
""",
                                  feedback: "Correct. You cannot name the destination, so you describe the *relationship*: a connection that repeats on a tight schedule, persists for days, and carries almost nothing. Low variance, long span, small payload is the statistical fingerprint of a heartbeat."),
                        LabOption("Search for known C2 user-agent strings and JA3 hashes",
                                  output: "0 matches for published C2 JA3 hashes\n(operators randomise TLS fingerprints and mimic browser user-agents by default)",
                                  feedback: "Signature hunting, and it fails for the same reason signature detection fails: the published fingerprints belong to last year's tooling. JA3 is still useful to you here — but as a *rarity* measure within your own environment, not as a lookup against a public list."),
                        LabOption("Look for connections to high-numbered ports and uncommon protocols",
                                  output: "candidates: 11,400 pairs (NTP, SIP, game clients, peer-to-peer updaters, VPNs)",
                                  feedback: "A reasonable instinct about a decade out of date. Competent implants beacon over 443 because 443 is always open and always encrypted. Hunting unusual ports finds unusual software, not adversaries.")
                    ]),
            LabStep(instruction: "340 candidate pairs, almost all benign. How do you cut it down without cutting out the real one?",
                    hint: "What do your software updaters, telemetry agents and licence checks have in common that an implant does not?",
                    options: [
                        LabOption("Tighten the variance threshold to near-zero to keep only exact intervals",
                                  output: "stddev/mean < 0.02  ->  61 pairs\n  all 61 are scheduled tasks and update checks (exact intervals by design)\n  the implant beacons at 300s +/- 10% jitter  ->  FILTERED OUT",
                                  feedback: "Backwards. Your own software keeps time perfectly because a scheduler runs it; implants deliberately jitter so they do not look like a metronome. Tightening the filter keeps the benign population and discards the target."),
                        LabOption("Stack by destination and keep the destinations contacted by very few internal hosts",
                                  correct: true,
                                  output: """
340 pairs -> group by id.resp_h, count distinct internal hosts
  1,204 hosts  updates.os-vendor.example      benign (ubiquitous + regular)
    918 hosts  telemetry.edr-vendor.example   benign
    640 hosts  ntp pool                       benign
      ...
      1 host   203.0.113.77                   <-- regular AND rare
  -> 3 pairs with fewer than 5 hosts
""",
                                  feedback: "Correct — rarity is the second axis. Legitimate beaconing software is installed everywhere, so it is regular *and* ubiquitous. An implant on one workstation is regular and seen by almost nobody. Regularity finds the shape; rarity finds the intruder."),
                        LabOption("Drop destinations that have no reverse DNS record",
                                  output: "no PTR: 2,100 of 412,000 destinations, including large cloud providers\nhas PTR: plenty of malicious infrastructure (PTR is free to set)",
                                  feedback: "A weak discriminator in both directions. Vast swathes of legitimate cloud infrastructure has no PTR, and setting one costs an attacker nothing. You would discard good candidates and keep bad ones."),
                        LabOption("Keep only destinations in countries where you have no business presence",
                                  output: "candidates reduced to 44\n203.0.113.77 geolocates to the same country as your head office -> EXCLUDED",
                                  feedback: "Geography is not a trust boundary. Hosting is available everywhere for pennies, and competent operators deliberately choose infrastructure in your own region precisely because teams filter this way. You just excluded the answer.")
                    ]),
            LabStep(instruction: "One pair survives: `10.20.9.14 -> 203.0.113.77:443`, every ~300 s for nine days, one host only, ~1.2 KB each way. What do you pull next?",
                    hint: "It is TLS. There is a Zeek log that describes the handshake without needing to decrypt anything.",
                    options: [
                        LabOption("ssl.log for that pair — the certificate, SNI and TLS fingerprint",
                                  correct: true,
                                  output: """
# ja3 column requires the zeek/salesforce/ja3 package (not stock Zeek)\ncat ssl.log | zeek-cut id.resp_h server_name version subject issuer validation_status ja3
203.0.113.77  -            TLSv12  CN=localhost  CN=localhost  self signed certificate  51c6...
summary over 9 days
  server_name       empty on every connection (no SNI sent)
  subject/issuer    CN=localhost, self-signed, validity 2026-09-22 .. 2036-09-19
  ja3 51c6...       seen on 1 internal host, 0 other destinations
""",
                                  feedback: "Correct, and every line is a finding. No SNI at all is abnormal for anything browser-like; a self-signed `CN=localhost` certificate with a ten-year validity is a default from a C2 framework nobody bothered to change; and a JA3 unique to one host in your whole estate is as rare as it gets."),
                        LabOption("Request a decryption capability for that destination",
                                  output: "TLS interception for a single external IP: 3-day change request, requires a\nproxy policy change and legal sign-off",
                                  feedback: "A three-day change request against an active intrusion, for information the metadata already gives you. Decryption has its place, and it is not the next ninety seconds of a hunt."),
                        LabOption("Query the WHOIS and hosting history for 203.0.113.77",
                                  output: "203.0.113.77: AS64505, VPS provider, allocated 2026-09-21",
                                  feedback: "Genuinely useful context and not the next step. Infrastructure allocated eleven days ago strengthens the case, but it is a fact about the attacker's supplier. The handshake tells you about the *implant*, which is what you need to find the other hosts running it."),
                        LabOption("Retrieve full packet capture for the nine-day period",
                                  output: "retention: 96h of full packet capture (9 days exceeds it)",
                                  feedback: "A fair reflex, defeated by retention — which is the everyday reality the SIEM lesson warns about. Metadata is kept for months precisely because payloads cannot be, and in this case the metadata is sufficient.")
                    ]),
            LabStep(instruction: "Pivot to the endpoint. What do you ask the EDR for?",
                    hint: "A network connection belongs to a process, and a process has ancestors. The ancestry is the part that explains how this started.",
                    options: [
                        LabOption("A full disk scan of 10.20.9.14 with updated signatures",
                                  output: "scan complete: 0 detections\n(the implant has been resident 9 days without detection by the same engine)",
                                  feedback: "An engine that has missed this for nine days will miss it on the two hundred and sixteenth hour as well. You have a specific question — who owns that socket — and a scan does not answer it."),
                        LabOption("The owning process for the connection, plus its full parent chain and first-execution time",
                                  correct: true,
                                  output: """
connection 203.0.113.77:443 owner
  C:\\Users\\dmehta\\AppData\\Local\\Temp\\oneDriveSetup.exe   (unsigned)
  first executed  2026-09-23 11:04
parent chain
  WINWORD.EXE  ->  rundll32.exe  ->  oneDriveSetup.exe
persistence
  HKCU\\...\\CurrentVersion\\Run\\OneDriveSync -> that path, written 11:05
also observed, 2026-09-23 11:12
  net use \\\\fs-hr\\share   (succeeded, dmehta credentials)
""",
                                  feedback: "Correct, and the parent chain is the whole story in one line: Word spawned rundll32 which dropped and ran an unsigned binary from a user temp path, with a Run key written a minute later. Note the share access twelve minutes in — this is no longer only about one workstation."),
                        LabOption("Keystroke and screen recording on the host to observe the operator",
                                  output: "",
                                  feedback: "Surveillance of an employee's session is an intrusive step with consent, privacy and legal implications, and it buys you nothing the process telemetry does not already provide. Reach for the least intrusive evidence that answers the question."),
                        LabOption("The host's installed-software inventory",
                                  output: "inventory: no unexpected installed products (the implant was never installed)",
                                  feedback: "It comes back clean because nothing was installed — the binary runs from a user-writable temp directory and persists through a registry value. Inventory describes what the estate *manages*, which is the opposite of where implants live.")
                    ]),
            LabStep(instruction: "Nine-day dwell, credential use, lateral share access. Isolate 10.20.9.14 now, or keep watching?",
                    hint: "There is a third answer, and the clue is in what you learned at the endpoint: you now have indicators specific enough to query the whole fleet in minutes.",
                    options: [
                        LabOption("Isolate immediately — contain first, always",
                                  output: """
10.20.9.14: containment ENABLED 14:02
14:09  beacon from 10.20.3.51 to 203.0.113.77 stops
14:11  new beacon: 10.20.3.51 -> 198.51.100.202 (fresh infrastructure)
14:18  interactive logon, svc_backup, on BACKUP-SRV-02
""",
                                  feedback: "The instinct is right in most incidents and wrong in this one. Against a human operator with multiple footholds, isolating one node is a notification — they switch infrastructure, accelerate, and reach for the backup server while you are still writing the first ticket. \"Contain first\" means contain the *intrusion*, not the host you happened to find first."),
                        LabOption("Scope the fleet with the indicators you now have, then contain everything simultaneously",
                                  correct: true,
                                  output: """
fleet query (4 minutes) — any of:
  ja3 = 51c6...                       -> 3 hosts
  Run value name = OneDriveSync       -> 3 hosts
  WINWORD.EXE -> rundll32.exe chain    -> 4 hosts (1 unrelated, benign add-in)
  destination 203.0.113.77             -> 3 hosts
confirmed: 10.20.9.14, 10.20.3.51, 10.20.14.6  + 2 accounts used for lateral access
14:21 simultaneous: 3 hosts isolated, 2 accounts disabled, sessions revoked,
      203.0.113.77 sinkholed  -> no fallback observed
""",
                                  feedback: "Correct. The endpoint pivot handed you four independent indicators, and four minutes of querying turned one host into three plus two accounts. Containing them in one action removes the operator's ability to react — and note the fourth row, where one of the four hits was a benign Word add-in you checked rather than isolated."),
                        LabOption("Keep observing for a week to collect intelligence on the operator's objectives",
                                  output: "",
                                  feedback: "Monitored dwell time is still dwell time, and the data they take during it is real. Extended observation is a decision for a legal or law-enforcement engagement with an explicit mandate, not something a hunter chooses alone with an actor who is already touching HR shares."),
                        LabOption("Isolate 10.20.9.14 and disable dmehta's account, then scope",
                                  output: """
14:02 host isolated, dmehta disabled
14:07 10.20.3.51 beacon continues under a different account
14:09 operator notices the account disable and rotates infrastructure
""",
                                  feedback: "The closest wrong answer, and worth sitting with. Half-containment is the worst of both: enough to alert the operator, not enough to stop them. Either you can contain the whole intrusion now or you keep quiet until you can — and here, scoping took four minutes.")
                    ]),
            LabStep(instruction: "Contained. The hunt found something your alerting did not. What do you owe the next shift?",
                    hint: "A hunt that does not graduate has to be run again by hand. Pick the thing that makes it automatic without making it noisy.",
                    options: [
                        LabOption("Add 203.0.113.77, the JA3 and the file hash to the blocklist and write up the incident",
                                  output: "blocklist updated, report filed.\n# the next operator uses a new VPS, a new build and a randomised JA3.",
                                  feedback: "All three of those are indicators from one campaign, and the report is the bare minimum. You discovered a durable *behaviour* and are banking only the disposable artefacts of it."),
                        LabOption("Graduate the discriminator into a scheduled detection: regular-and-rare, with the endpoint pivots pre-joined",
                                  correct: true,
                                  output: """
detection DE-0117  Rare periodic external destination (T1071.001)
  nightly over the trailing 7 days, per (src, dst):
      stddev/mean inter-arrival < 0.3  AND  span > 48h
      AND mean_bytes < 8 KB
      AND distinct internal hosts contacting dst <= 3
      AND dst first seen in environment < 45 days ago
  auto-enrich: owning process + parent chain + JA3 rarity + cert validation_status
  expected volume (90-day backtest): 2-4 candidates/week for analyst review
  -> queue item, not a page: this is a hunt lead, not a confirmed detection
""",
                                  feedback: "Correct, and note the last line. Low-variance-plus-rarity produces leads, not verdicts, so it belongs in a reviewed queue with the enrichment already attached rather than on a pager. Two to four a week is a hunt you can actually sustain — and it is the hunt you just did, automated."),
                        LabOption("Deploy a rule alerting on any Word process spawning rundll32",
                                  output: "backtest: 1,900/month (document-automation add-ins, mail-merge tooling, 2 line-of-business macros)",
                                  feedback: "A good detection in principle — it is the house example in the detection-engineering lesson — and it needs its own tuning pass against your estate's real add-in population before it is shippable. Deploying it raw as a byproduct of this hunt just moves your noise problem."),
                        LabOption("Recommend blocking all macro-enabled documents from the internet",
                                  output: "",
                                  feedback: "A strong preventive control and not an answer to this question. You were asked what the next shift needs to *detect* what your alerting missed; hardening recommendations belong in the lessons-learned, alongside this, not instead of it.")
                    ])
        ])

    // MARK: - 9. Tuning a noisy rule (advanced)

    private static let ruleTuning = InteractiveLab(
        id: "lab-rule-tuning",
        title: "Tune a noisy rule without going blind",
        goal: "Cut 1,400 weekly alerts down to signal while keeping the detection able to catch the technique.",
        track: .blueTeam,
        difficulty: .advanced,
        minutes: 8,
        scenario: "Detection DE-0012, \"PowerShell with encoded command\", fires about 1,400 times a week. The SOC closes them in bulk without reading them, and the shift lead has formally asked for the rule to be switched off. You have one sprint, the full firing history, and the authority to change the rule — but not to delete it.",
        debrief: "A rule that nobody reads is already disabled; the only question is whether it is disabled honestly. Tuning is not reducing the number — you can reduce the number to zero by deleting the rule. Tuning is raising the proportion of firings that deserve a human, which means stacking the history to find the generator, bounding the exclusion by identity rather than by payload, and then reading what is left, because that is where the signal was the whole time. The part people skip is the fail-safe: an exclusion that silently swallows an attack, or a logging pipeline that quietly stops, both look exactly like a well-tuned rule. Alert on the absence of your baseline and you can tell the difference.",
        tools: ["SIEM", "Sysmon", "Atomic Red Team"],
        relatedLessonID: "blue-siem",
        steps: [
            LabStep(instruction: "1,400 alerts a week, all closed unread. What do you do first?",
                    hint: "You are being asked to change a rule you have not yet looked at the output of.",
                    options: [
                        LabOption("Disable the rule while you design a better one",
                                  output: "DE-0012 DISABLED\n# encoded-command PowerShell is now undetected. Average time a disabled\n# detection stays disabled, per your own change log: 14 months.",
                                  feedback: "The shift lead's request, granted. Encoded PowerShell is a technique attackers genuinely use, and \"temporarily\" disabled detections have a documented habit of becoming permanent. You have traded noise for blindness without measuring either."),
                        LabOption("Stack the 1,400 firings by host, parent process and command-line prefix",
                                  correct: true,
                                  output: """
stats count by ParentImage, Image, host_group, substr(CommandLine,1,60)
  1,361  ccmexec.exe -> powershell.exe   SERVERS-MANAGED   "-NonInteractive -EncodedCommand JABwcm9n..."
     38  cmd.exe     -> powershell.exe   DEV-WORKSTATIONS  "-enc JABidWlsZC..."
      1  w3wp.exe    -> powershell.exe   WEB-DMZ           "-enc JABjAD0A..."
""",
                                  feedback: "Correct, and the stack has already done the work. Ninety-seven percent of the volume is one parent process on one host group with one command-line prefix — that is a tuning problem with a known generator, not a bad rule. And look at the bottom row."),
                        LabOption("Raise the alert threshold so only hosts firing more than ten times a day are shown",
                                  output: "alerts/week: 1,400 -> 19\nsuppressed by the threshold: the single w3wp.exe firing (1 occurrence)",
                                  feedback: "This is hiding dressed as tuning. A frequency threshold preferentially discards the rare firings, and rare is exactly what an attacker's one-off looks like. You would have made the queue pleasant and thrown away the only interesting event in it."),
                        LabOption("Escalate to the detection engineering team as a rule-quality defect",
                                  output: "",
                                  feedback: "You are the person with the history, the authority and the sprint. Handing the ticket on without stacking the data once means the next person starts from the same place you did — and the stack takes two minutes.")
                    ]),
            LabStep(instruction: "1,361 of the firings are the configuration-management agent running its own signed scripts. How do you exclude it?",
                    hint: "Ask what each candidate exclusion would also let through if an attacker found it.",
                    options: [
                        LabOption("Exclude powershell.exe with -EncodedCommand on all servers",
                                  output: "excluded population: 4,100 servers — including the domain controllers,\nthe backup infrastructure and the DMZ web tier.",
                                  feedback: "You have exempted the systems you care most about. Servers are where an intrusion becomes an incident; an exclusion that covers the whole server estate is a documented blind spot with your signature on it."),
                        LabOption("Exclude on the specific base64 payload, since it is byte-identical every time",
                                  output: "excluded: CommandLine contains 'JABwcm9nPSdDOlxQ...'\n# the exact string is readable in any process-creation log on 1,361 hosts a week,\n# and prepending it to a malicious command is free.",
                                  feedback: "A value-based exclusion on a value the attacker can read and reuse. That blob appears in telemetry thousands of times a week, so the bypass is literally copy-and-paste. Never allowlist a string an adversary can obtain and replay."),
                        LabOption("Exclude the combination of parent process and managed-host group, and add a second rule watching that same combination for anything off-baseline",
                                  correct: true,
                                  output: """
DE-0012  filter:
    ParentImage|endswith: '\\ccmexec.exe'
    host_group: SERVERS-MANAGED
    CommandLine|startswith: '-NonInteractive -EncodedCommand'
  condition: selection and not filter
  review_by: 2027-01-15   owner: soc-detections

DE-0012b (new, severity medium):
    ParentImage|endswith: '\\ccmexec.exe'
    AND NOT CommandLine|startswith: '-NonInteractive -EncodedCommand'
  -> catches anything hiding behind the exclusion's own parent process

alerts/week after tuning: 39
""",
                                  feedback: "Correct on both halves. The exclusion is bounded by *who is running it and where* rather than by what they typed, and the companion rule watches the inside of the exclusion — so an attacker who learns to parent under `ccmexec.exe` lands in a detection instead of a hole. The review date stops this becoming permanent by default."),
                        LabOption("Exclude the service account the agent runs as",
                                  output: "excluded: NT AUTHORITY\\SYSTEM on managed servers\n# which is the context most post-exploitation activity runs in anyway.",
                                  feedback: "The agent runs as SYSTEM, and so does almost everything an attacker achieves after privilege escalation. Identity-bounded exclusions are the right idea; this particular identity is the worst possible choice of boundary.")
                    ]),
            LabStep(instruction: "Thirty-nine alerts a week remain. What do you do with them?",
                    hint: "The whole justification for tuning was that nobody could read 1,400. Thirty-nine is readable.",
                    options: [
                        LabOption("Tune them out too — the goal was a quiet queue",
                                  output: "",
                                  feedback: "A quiet queue was never the goal; a readable one was. Thirty-nine a week is roughly six a day, which is a normal analyst workload — and tuning past the point where you have read the output is how a detection programme produces silence and calls it coverage."),
                        LabOption("Read them",
                                  correct: true,
                                  output: """
38  DEV-WORKSTATIONS, cmd.exe -> powershell.exe -enc, 3 developers, a build helper
    -> second filter added, scoped to the dev host group + that script's prefix
 1  WEB-DMZ-02, w3wp.exe -> powershell.exe -enc  (IIS worker process as parent)
    decoded: downloads and runs a second stage from an external host
    -> INCIDENT. first seen 11 days ago. the alert fired every day and was
       bulk-closed with the other 1,399.
""",
                                  feedback: "Correct, and this is the lab. The rule was not broken — it was unstacked. A real intrusion had been firing this detection daily for eleven days inside a crowd of benign noise, which is precisely the mechanism by which alert fatigue becomes a breach. A web worker process spawning encoded PowerShell is close to unambiguous."),
                        LabOption("Lower the severity to informational now that the volume is manageable",
                                  output: "",
                                  feedback: "Severity is a statement about what the firing means, not about how many there are. You have just increased the rule's fidelity enormously; downgrading it at that exact moment is the opposite of what the evidence supports."),
                        LabOption("Route them to a weekly report for trend analysis",
                                  output: "next report due: Monday.\nthe w3wp.exe firing is 11 days old and ongoing.",
                                  feedback: "Trend reporting is a fine supplement and a poor primary route. The thing in that queue is a live foothold; a weekly cadence means a detection that works is still answered too late to matter.")
                    ]),
            LabStep(instruction: "Incident raised separately. Back to the rule: how do you make sure your exclusion never silently swallows an attack?",
                    hint: "Two different failures look identical from the dashboard: nothing is happening, and nothing is being reported.",
                    options: [
                        LabOption("Document the exclusion in the detection wiki with the rationale",
                                  output: "wiki updated. exclusion rationale, owner and date recorded.",
                                  feedback: "Necessary and not sufficient — this is the \"real thing an analyst does, but not enough\" option. Documentation tells a human why the gap exists if they go looking. It does not notice when the telemetry stops arriving, and nobody reads the wiki on the day it matters."),
                        LabOption("Alert on the disappearance of the baseline, and expire the exclusion on a date",
                                  correct: true,
                                  output: """
DE-0012-health  (severity medium, routed to detections team)
  expected: ~1,361 ccmexec-parented EncodedCommand events/week on SERVERS-MANAGED
  alert if  weekly count < 400   (agent broken, Sysmon config changed, or
                                  ingestion/field mapping silently failed)
  alert if  weekly count = 0     (page: telemetry loss, not an absence of activity)
exclusion DE-0012.filter expires 2027-01-15 -> reverts to alerting unless renewed
""",
                                  feedback: "Correct. If the stream you are deliberately ignoring goes quiet, something upstream has broken and your rule has stopped being able to fire at all — so you monitor your own blind spot's heartbeat. The expiry turns the exclusion into a decision somebody has to re-make rather than an inheritance."),
                        LabOption("Review all exclusions at the annual detection audit",
                                  output: "next audit: 11 months",
                                  feedback: "Better than never, and eleven months is a long time to hold a gap you created in an afternoon. Annual review is a backstop behind per-exclusion expiry dates, not a replacement for them."),
                        LabOption("Add a comment in the rule YAML pointing at the companion rule",
                                  output: "",
                                  feedback: "Helpful for the next engineer reading the file and invisible to the system. Comments do not detect anything.")
                    ]),
            LabStep(instruction: "The shift lead asks how you will prove the tuning worked. What do you measure?",
                    hint: "One of these numbers can be driven to its best possible value by deleting the rule.",
                    options: [
                        LabOption("Alert volume before and after",
                                  output: "1,400/week -> 39/week  (-97%)\n# the same chart would show -100% if you had deleted the rule.",
                                  feedback: "The metric everyone reaches for and the one that cannot distinguish tuning from switching the rule off. Volume reduction is a side effect you report, never the result you claim."),
                        LabOption("Alert-to-incident ratio, plus a re-test that the rule still fires on the technique",
                                  correct: true,
                                  output: """
DE-0012, 30 days post-tuning
  firings                  31
  investigated             31  (100%, previously ~0% read)
  escalated to incident      2
  alert-to-incident       1:16  (previously 1:~6,000 and unread)
atomic re-test T1059.001 encoded command, TEST-W11-02 and TEST-SRV-04
  fires 2/2, including from a ccmexec.exe parent with a non-baseline command line
""",
                                  feedback: "Correct, and it is deliberately two numbers. The ratio shows the queue became worth reading; the re-test proves the detection can still catch the thing it exists for, including through the exclusion you added. Either number alone is gameable; together they are the honest claim."),
                        LabOption("Analyst satisfaction with the queue",
                                  output: "",
                                  feedback: "Worth knowing, and it is a measure of comfort rather than coverage. A deleted rule produces the happiest queue in the SOC."),
                        LabOption("Mean time to close for DE-0012 alerts",
                                  output: "MTTC: 4s (bulk close) -> 6m12s (actually investigated)\n# the number got WORSE, and the rule got better.",
                                  feedback: "A genuinely instructive trap: the metric moved the wrong way precisely because analysts started doing the work. Any efficiency metric that rewards closing alerts faster will reward not reading them.")
                    ])
        ])

    // MARK: - 10. Static triage of an unknown binary (advanced)

    private static let malwareStatic = InteractiveLab(
        id: "lab-malware-static",
        title: "Static-triage an unknown binary",
        goal: "Decide what a sample does and how urgent it is, without detonating it and without leaking it.",
        track: .blueTeam,
        difficulty: .advanced,
        minutes: 9,
        scenario: "A quarantined attachment, `Invoice_8841.pdf.exe`, pulled from the mail gateway. You have an isolated analysis VM with no route to any network, a clean snapshot, and your usual static toolkit. The sample has not run anywhere that you know of. Somebody will ask you within the hour whether this matters.",
        debrief: "Static triage is a sequence of cheap questions asked in the right order: what is it, is it packed, what does the unpacked code reference, and does any of that change the urgency? The sequencing matters because each answer tells you whether the next step is worth taking — and because the expensive, irreversible steps (detonating it, publishing it) should come after the free ones, not instead of them. The decisive moment here was a single string: once `vssadmin delete shadows` appears, you are not analysing a loader any more, you are racing a pre-encryption checklist. The attacker's assumption was that an empty `strings` output reads as \"probably nothing\" to a tired analyst.",
        tools: ["file", "pefile", "strings", "upx", "YARA"],
        relatedLessonID: "blue-malware",
        steps: [
            LabStep(instruction: "The sample is on the analysis VM. What is your first action?",
                    hint: "One of these is free and reversible. Two of them are decisions you cannot take back.",
                    options: [
                        LabOption("Hash it and check the hash against intel — without uploading the file",
                                  correct: true,
                                  output: """
sha256  c41d8f2b9a07e63d5c18ba4f2097e31d6b85cf0a4473e129d8a5b7c60e4f3912
intel lookup by HASH only: no record in any feed (first-seen anywhere: unknown)
original snapshot retained; working copy created for analysis
""",
                                  feedback: "Correct. The hash is free, reversible, and discloses nothing — and \"no record anywhere\" is itself a finding: this is either brand new or targeted, which raises rather than lowers the priority. Note that you worked on a copy and kept the original untouched."),
                        LabOption("Upload the file to a public multi-scanner for an instant verdict",
                                  output: "upload accepted. sample now retrievable by other subscribers of the platform.\nnote: the attachment came from a finance mailbox and may embed customer data.",
                                  feedback: "The single most common unforced error in malware triage. Public submission can republish whatever the file contains — documents, customer data, internal paths — and actors routinely monitor these platforms for their own samples, so you may have told them the campaign landed and is being investigated. Hash first; submit the file only as a deliberate decision with data-classification sign-off."),
                        LabOption("Run it in the VM and watch what it does — the snapshot makes it safe",
                                  output: "",
                                  feedback: "Dynamic analysis before static is the wrong order even in a perfect sandbox: you are spending the one irreversible action first, before you know whether the sample is sandbox-aware, whether it needs arguments, or whether a thirty-second look at its strings would have answered the question."),
                        LabOption("Rename it to .pdf and open it in a PDF reader to see what the lure looks like",
                                  output: "",
                                  feedback: "The extension is the lie, not the file. It is a PE executable; renaming changes nothing about what it is, and double-clicking it is exactly what the attacker designed the double extension to achieve.")
                    ]),
            LabStep(instruction: "Hash is unknown. What do you establish next?",
                    hint: "Before you interpret any content, settle what the file actually is. One command.",
                    options: [
                        LabOption("Open it in a hex editor and read the header bytes manually",
                                  output: "offset 0: 4D 5A ...   offset 0x80: 50 45 00 00",
                                  feedback: "You will get the right answer slowly. `MZ` and `PE\\0\\0` are there to be read, and a tool reads them, parses the optional header and tells you the subsystem and architecture in one line. Save the hex editor for the question a parser cannot answer."),
                        LabOption("Identify the format and architecture",
                                  correct: true,
                                  output: """
file Invoice_8841.pdf.exe
  PE32 executable (GUI) Intel 80386, for MS Windows, UPX compressed

pe header
  Machine          0x014c  I386        Subsystem  2 (GUI)
  TimeDateStamp    1970-01-01 00:00:00  (zeroed)
  Sections         3       Entry point in section UPX1
  Signature        none
""",
                                  feedback: "Correct, and three facts fall out at once: a 32-bit GUI executable (not a PDF, and not a console tool), UPX-compressed, and a zeroed compile timestamp. The zeroed timestamp is itself deliberate — it is a cheap anti-analysis touch that removes a pivot you would otherwise have."),
                        LabOption("Run strings on it and start reading",
                                  output: "strings -n 8 Invoice_8841.pdf.exe | wc -l\n41\n# LoadLibraryA GetProcAddress VirtualProtect ExitProcess ...\n# (the UPX0/UPX1/UPX! section markers are only 4 chars — below the -n 8 cutoff;\n#  drop to -n 4, or read the section table, to see them)",
                                  feedback: "Right tool, wrong moment — and the output is about to mislead you. Forty-one strings from a 116 KB executable is not a sample with nothing in it; it is a sample whose contents are compressed. Establish the format first and that result becomes interpretable instead of discouraging."),
                        LabOption("Submit the hash to a sandbox service for behavioural reports from previous submissions",
                                  output: "no report exists for this hash",
                                  feedback: "Reasonable and already answered — nothing in any feed knows this hash. You have no choice but to look at the file yourself.")
                    ]),
            LabStep(instruction: "`strings` gives you 41 results and nothing useful. What do you conclude?",
                    hint: "The header already told you why. Confirm it with two more measurements rather than drawing a conclusion about the sample's intent.",
                    options: [
                        LabOption("Low string count and no readable indicators — likely benign or a broken file",
                                  output: "",
                                  feedback: "This is the conclusion the packer exists to produce. An absence of readable content is a property of the *container*, not evidence about the payload — and reporting \"probably benign\" on a packed, unsigned, zero-timestamped executable is how a sample gets released back into the estate."),
                        LabOption("It is packed — confirm with section entropy and the import table",
                                  correct: true,
                                  output: """
section   virt size    raw size     entropy
UPX0      0x0004A000   0x00000000   n/a      (empty on disk: unpack destination)
UPX1      0x0001D000   0x0001C600   7.91     (compressed payload)
.rsrc     0x00001000   0x00000600   4.33

imports: 1 library, 4 functions
  KERNEL32.dll -> LoadLibraryA, GetProcAddress, VirtualProtect, ExitProcess
""",
                                  feedback: "Correct, and this is the signature of packing in two numbers. Entropy of 7.91 is near the theoretical maximum for a byte stream — compressed or encrypted data. And four imports is far too few for a program that does anything: the real import resolution happens at runtime through `LoadLibraryA`/`GetProcAddress`, which is why the import table is empty of anything interesting."),
                        LabOption("It is encrypted, so nothing further can be learned statically",
                                  output: "",
                                  feedback: "Over-pessimistic, and it stops the triage one command before the answer. High entropy means the bytes are compressed or encrypted; UPX is a compressor with a documented, reversible format, and the header has already named it."),
                        LabOption("Rebuild the import table with an import reconstruction tool",
                                  output: "",
                                  feedback: "A real technique for a dumped or custom-packed binary, and significant overkill here. The header says UPX, which decompresses with one command — exhaust the cheap path before reaching for reconstruction.")
                    ]),
            LabStep(instruction: "Packed with UPX. How do you get at the payload?",
                    hint: "Keep the evidence intact, and prefer the reversible method.",
                    options: [
                        LabOption("Decompress a copy with upx -d, leaving the original and its hash untouched",
                                  correct: true,
                                  output: """
cp Invoice_8841.pdf.exe work/sample_packed.bin
upx -d -o work/sample_unpacked.bin work/sample_packed.bin

        File size         Ratio      Format      Name
   --------------------   ------   -----------   -----------
     284672 <-    118784   41.73%    win32/pe     work/sample_unpacked.bin

Unpacked 1 file.
sha256 (unpacked) 7b21e4af08c936d5172ae0b4cc8f351d9e62a704b58d1f3c6e90a2d7f418b35c
""",
                                  feedback: "Correct, and note the discipline: you worked on a copy, so the original's hash still matches the one in your chain of custody, and you recorded a separate hash for the unpacked artefact. Standard UPX is self-identifying and reverses cleanly, which is why it is always worth trying before anything heavier."),
                        LabOption("Run it and dump the unpacked image from memory",
                                  output: "",
                                  feedback: "The right technique for a custom or modified packer, and it requires executing live malware — the one irreversible step. Reach for it when `upx -d` fails, not before."),
                        LabOption("Decompress the original file in place to save a step",
                                  output: "upx -d Invoice_8841.pdf.exe\n# original overwritten. hash c41d8f... no longer reproducible from the artefact\n# you were given.",
                                  feedback: "You have destroyed the evidential copy for the sake of one `cp`. The hash you recorded now refers to a file that no longer exists, and the sample as-delivered is gone — which matters the moment anyone else needs to verify your work."),
                        LabOption("Load it straight into a disassembler and work through the unpacking stub",
                                  output: "",
                                  feedback: "Technically possible and a poor use of your hour. Reversing a stub by hand to reach a payload that one command will hand you is effort spent in the wrong place — and you were asked for triage, not a full reverse-engineering report.")
                    ]),
            LabStep(instruction: "Unpacked. Run strings again — what do you do with the result?",
                    hint: "Read it for *behaviour*, and notice which single line changes how urgent this is.",
                    options: [
                        LabOption("Collect the URL and the hash as indicators for the blocklist",
                                  output: "",
                                  feedback: "Incomplete, and it discards the most valuable half of what you just recovered. The URL and hashes are the disposable parts; the commands describe what the sample *does*, which is what you can hunt and detect across the whole estate."),
                        LabOption("Read it as a behavioural inventory — persistence, recovery destruction, key material",
                                  correct: true,
                                  output: """
strings -n 8 work/sample_unpacked.bin | grep -Ei 'http|schtasks|vssadmin|bcdedit|BEGIN|mtx'

http://192.0.2.141/gate.php
schtasks /create /tn "OneDriveSync" /tr "%LOCALAPPDATA%\\odsync.exe" /sc minute /mo 10 /f
vssadmin delete shadows /all /quiet
bcdedit /set {default} recoveryenabled No
-----BEGIN PUBLIC KEY-----
Global\\mtx_od_8841

reading:
  T1105/T1071  staging + C2 over HTTP
  T1053.005    scheduled-task persistence, 10-minute interval
  T1490        shadow copy deletion + recovery disabled
  embedded RSA public key + mutex  ->  encryptor, not just a loader
""",
                                  feedback: "Correct, and one line reclassifies the whole sample. `vssadmin delete shadows` plus `bcdedit /set recoveryenabled No` plus an embedded RSA public key is not a generic loader — those three together are the pre-encryption checklist of a ransomware payload. The urgency just changed from \"interesting attachment\" to \"find out whether this ran anywhere\"."),
                        LabOption("Note that the sample is clearly malicious and write it up",
                                  output: "",
                                  feedback: "True and useless to the people who have to act. \"Malicious\" does not tell the SOC what to hunt for, the IR team what to contain, or the detection engineer what to write. The specifics are the deliverable."),
                        LabOption("Extract the RSA public key and look for a corresponding private key",
                                  output: "",
                                  feedback: "There is no private key to find — that is the entire design of asymmetric ransomware, and the operator holds the other half. Chasing it burns the hour you have while the behavioural indicators sit unhunted.")
                    ]),
            LabStep(instruction: "You have ten minutes left of your hour. What do you do with what you have?",
                    hint: "Ask which action reduces risk fastest, and whether the information you are still missing changes it.",
                    options: [
                        LabOption("Detonate it in the sandbox first, to confirm the behaviour before escalating",
                                  output: """
sandbox run queued. typical completion: 25-40 min including report generation.
meanwhile, unanswered: did Invoice_8841.pdf.exe run on any endpoint?
""",
                                  feedback: "This is the valuable wrong answer, because dynamic analysis genuinely is the right next *analytical* step. It is not the right next *response* step. The static findings are already specific and already actionable, and the open question is not \"what does it do\" but \"did it run here\" — which forty minutes of sandboxing does not answer."),
                        LabOption("Escalate the behavioural indicators now and hunt the fleet for them in parallel",
                                  correct: true,
                                  output: """
escalated 10:52, severity high: confirmed encryptor capability in quarantined mail.
hunt queries issued immediately (no sandbox needed):
  scheduled task named "OneDriveSync"            -> 0 hosts
  %LOCALAPPDATA%\\odsync.exe present or executed  -> 0 hosts
  mutex Global\\mtx_od_8841                       -> 0 hosts
  any connection to 192.0.2.141                  -> 0 hosts
  other recipients of the same message            -> 14 mailboxes, all quarantined
existing coverage check: shadow-copy rule DE-0091 would fire on this -> yes
sandbox run started in the background for the full report.
""",
                                  feedback: "Correct, and note that nothing was skipped — the sandbox is still running, just not on the critical path. Four static indicators let you clear the fleet in minutes, confirm the fourteen other recipients are contained, and verify that your own shadow-copy detection would catch this sample if a copy ever executes."),
                        LabOption("Write a YARA rule on the unpacked file's hash and deploy it",
                                  output: "rule matches: the unpacked artefact YOU created.\nthe packed sample in the wild has a different hash; any rebuild changes both.",
                                  feedback: "Doubly broken: a hash is the most brittle indicator available, and it is a hash of a file that only exists on your analysis VM. If you write YARA here, write it on durable content from the unpacked payload — the mutex string, the task name, the embedded key — not on a digest."),
                        LabOption("Hold the findings until the full reverse-engineering write-up is complete",
                                  output: "",
                                  feedback: "Analytical completeness at the cost of response time. The write-up matters, and it matters after the SOC knows there is an encryptor in the mail queue and has been given something to hunt.")
                    ])
        ])

    // MARK: - 11. Timeline against an anti-forensic adversary (expert)

    private static let timelineTamper = InteractiveLab(
        id: "lab-timeline-tamper",
        title: "Build a timeline the attacker tried to break",
        goal: "Establish when a compromise really began, through cleared logs and forged timestamps.",
        track: .blueTeam,
        difficulty: .expert,
        minutes: 10,
        scenario: "A file server, FS-LEGAL-02, is suspected compromised. You have a verified disk image and a memory capture taken before shutdown. The Security event log looks oddly short, the suspect binary claims to be seven years old, and the business wants to know one thing: what was taken, and when. Your findings will go to counsel.",
        debrief: "Anti-forensics is rarely erasure; it is usually an attempt to make one source of truth say something convenient. The counter is not a better tool, it is **corroboration** — artefacts the attacker did not know about, could not reach from user mode, or could not keep consistent with each other. A cleared log leaves a record of being cleared. A forged `$STANDARD_INFORMATION` timestamp contradicts the `$FILE_NAME` copy the OS maintains. A deleted archive leaves a journal entry and a byte count in a usage database nobody thinks about. From the attacker's side, each of these steps was an hour well spent against a responder who checks one source; against a super-timeline they are three extra pieces of evidence, and two of them prove intent.",
        tools: ["$MFT", "$UsnJrnl", "Prefetch", "AmCache", "SRUM", "plaso"],
        relatedLessonID: "blue-forensics-essentials",
        steps: [
            LabStep(instruction: "You need a timeline. What do you build it from?",
                    hint: "Assume at least one source has been tampered with. Design for that from the start.",
                    options: [
                        LabOption("The Security event log — it is the authoritative record of account and object activity",
                                  output: "Security.evtx: 1,204 records, earliest 2026-09-18 02:14:07\n(the server has been in production since 2023)",
                                  feedback: "It is authoritative right up until someone clears it, and the earliest record being three weeks old on a three-year-old server is the shape of exactly that. Building on a single source an attacker can write to is the mistake the rest of this lab corrects."),
                        LabOption("A super-timeline from multiple independent artefact sources",
                                  correct: true,
                                  output: """
sources ingested
  $MFT                 file metadata ($STANDARD_INFORMATION and $FILE_NAME)
  $UsnJrnl:$J          change journal: creates, renames, deletes
  Prefetch (*.pf)      execution evidence, run counts, last-run times\n                       (enabled on this host — Server disables Prefetch by default,\n                        so confirm before you rely on it)
  Amcache.hve          first-seen inventory + SHA-1 per binary
  Security/System/     event logs (including records about the logs themselves)
    Application .evtx
  SRUDB.dat (SRUM)     per-application network bytes sent/received
  registry hives       Run keys, services, shellbags, USB history
-> 2.1M events, correlated on time, cross-checked for disagreement
""",
                                  feedback: "Correct. The point of a super-timeline is not volume, it is that these sources are maintained by different parts of the OS for different reasons — so an attacker has to tamper with all of them consistently, and almost nobody does. Disagreement between sources becomes a finding rather than a problem."),
                        LabOption("File Modified timestamps from a recursive directory listing",
                                  output: "listing exported. (Modified/Created shown here are $STANDARD_INFORMATION values,\nwhich any process can set via SetFileTime.)",
                                  feedback: "This is the one view that is trivially forgeable from user mode, and it is the view Explorer and `dir` show you. Starting here means starting with the attacker's preferred version of events."),
                        LabOption("The EDR's historical process timeline for the host",
                                  output: "EDR retention: 30 days. suspected compromise window: unknown, possibly longer.\nagent install date: 2024. agent service stopped 2026-09-18 02:11, restarted 02:19.",
                                  feedback: "Valuable and not sufficient — and look at the last line, which is itself evidence. A thirty-day retention window cannot establish a start date you have not bounded yet, and the agent was stopped for eight minutes during the period you care about.")
                    ]),
            LabStep(instruction: "The Security log starts at `2026-09-18 02:14:07`. The first record is Event ID 1102. What does that mean for your investigation?",
                    hint: "Event 1102 is not a gap in the evidence. It is a piece of it.",
                    options: [
                        LabOption("The log was cleared, so activity before 02:14 is unrecoverable",
                                  output: "",
                                  feedback: "Clearing the Security log destroys those records and not the other six sources in your timeline. Treating a cleared log as the end of the investigation is precisely the outcome the clearing was meant to buy."),
                        LabOption("The clearing is itself evidence — and it dates the tampering, so pivot to sources the attacker did not clear",
                                  correct: true,
                                  output: """
Security.evtx  record 1 of 1204
  EventID    1102   "The audit log was cleared."
  Time       2026-09-18 02:14:07Z
  SubjectUserName  svc_backup      SubjectLogonId  0x4A91E3
System.evtx
  EventID    104    log file cleared: Application      02:14:11
  EventID    7036   Service entered stopped state: <EDR agent>   02:11:52
-> anchor: deliberate tampering at 02:11-02:14 by svc_backup.
   now rebuild the window from $UsnJrnl, Prefetch, AmCache and SRUM.
""",
                                  feedback: "Correct. Windows logs the clearing of its own log, so you get a timestamp, an account and an intent — and the adjacent service-stop and Application-log clear turn one event into a three-minute window of deliberate evasion. The attacker has handed you an anchor point and told you which account to follow."),
                        LabOption("The log rolled over because its maximum size was reached",
                                  output: "retention policy: 'overwrite events as needed'; 1102 is not emitted on rollover.",
                                  feedback: "A fair alternative hypothesis, and 1102 rules it out: rollover silently overwrites the oldest records and emits no such event. Testing the boring explanation is right; accepting it against the evidence is not."),
                        LabOption("Assume no attacker activity occurred before 02:14 since there is no record of any",
                                  output: "",
                                  feedback: "Absence of evidence inside the window somebody deliberately emptied is the least informative fact in the case. Reporting it as an absence of activity would be an error with counsel reading over your shoulder.")
                    ]),
            LabStep(instruction: "The suspect binary `C:\\Windows\\Temp\\mssrv.exe` shows Created `2019-03-04 08:12:44`. The host was imaged in 2026. Which do you trust?",
                    hint: "NTFS stores two independent sets of timestamps for a file. Only one of them is writable from user mode.",
                    options: [
                        LabOption("Trust the Created date — 2019 means it predates the incident and is probably a legitimate system file",
                                  output: "mssrv.exe: unsigned, not present in the vendor's file inventory, 61 KB,\nnot referenced by any installed product.",
                                  feedback: "That is the conclusion the forged timestamp was planted to produce. An old creation date on an unsigned binary in `Windows\\Temp` that belongs to no installed product should raise your suspicion of the *timestamp*, not lower your suspicion of the file."),
                        LabOption("Compare the $STANDARD_INFORMATION and $FILE_NAME timestamps in the $MFT",
                                  correct: true,
                                  output: """
$MFT record for \\Windows\\Temp\\mssrv.exe
  $STANDARD_INFORMATION   created 2019-03-04 08:12:44.0000000
                          modified 2019-03-04 08:12:44.0000000
                          mft-modified 2019-03-04 08:12:44.0000000
                          accessed 2019-03-04 08:12:44.0000000
  $FILE_NAME              created 2026-09-18 01:47:33.6291840
                          modified 2026-09-18 01:47:33.6291840
-> SI and FN disagree by 7 years. All four SI values identical, sub-second
   precision zeroed. FN values retain full precision.
""",
                                  feedback: "Correct, and the mismatch is conclusive. `$STANDARD_INFORMATION` is writable from user mode through `SetFileTime`, which is what timestomping tools change; the `$FILE_NAME` copy is maintained by the OS and is far harder to forge. Four identical values with zeroed sub-second precision is the tool's fingerprint — real file operations do not produce timestamps that tidy."),
                        LabOption("Check the file's digital signature timestamp",
                                  output: "signature: none (file is unsigned)",
                                  feedback: "There is nothing to check, and even on a signed file a countersignature tells you when something was *signed*, not when it arrived on this host. Signing timestamps are also forgeable with a stolen certificate."),
                        LabOption("Re-hash the file and compare against the image hash to prove it has not been altered",
                                  output: "image hash verified. file hash matches the image.",
                                  feedback: "A precise but different claim. That proves *your* handling was sound — the evidence has not changed since acquisition. It says nothing about when the attacker put the file there, which is the question on the table.")
                    ]),
            LabStep(instruction: "You believe the real date is `2026-09-18 01:47`. How do you corroborate it from sources the attacker did not touch?",
                    hint: "Execution and inventory artefacts are written by the OS for performance and telemetry reasons, not for you — which is why they are rarely cleaned up.",
                    options: [
                        LabOption("Prefetch and AmCache for first execution, and $UsnJrnl for the file-create record",
                                  correct: true,
                                  output: """
Prefetch  MSSRV.EXE-4F7A21C3.pf
  created      2026-09-18 01:48:02
  last run     2026-09-18 02:38:19      run count  6
Amcache.hve  InventoryApplicationFile
  path         c:\\windows\\temp\\mssrv.exe
  sha1         a7f3...   first seen  2026-09-18
$UsnJrnl:$J
  01:47:33  FileCreate   \\Windows\\Temp\\mssrv.exe
  01:47:34  DataExtend|DataTruncation|Close
  02:41:50  FileDelete   \\Windows\\Temp\\stage.7z
-> three independent sources agree on 2026-09-18. The 2019 date is forged.
""",
                                  feedback: "Correct. Prefetch exists so Windows can load programs faster, AmCache exists for application inventory, and the change journal exists so indexers can see what changed — none of them exist for you, which is exactly why they survive. Three sources agreeing to the minute is what turns a suspicion of timestomping into a finding you can put in front of counsel."),
                        LabOption("Browser history and recent-documents artefacts for user activity around that time",
                                  output: "FS-LEGAL-02 is a file server; no interactive browsing, no recent-docs entries.",
                                  feedback: "A good instinct on a workstation and inapplicable to a server with no interactive user. Match the artefact to the role of the host."),
                        LabOption("The file's internal PE compile timestamp",
                                  output: "TimeDateStamp: 2019-03-04 08:12:44  (identical to the forged $SI value)",
                                  feedback: "Note what just happened: the compile timestamp matches the forgery, because the attacker set the file timestamps *from* the PE header to make them agree. A field inside a file the attacker controls is not independent corroboration of anything."),
                        LabOption("Ask the system owner when they last patched the server",
                                  output: "owner: 'patched monthly, nothing unusual noticed.'",
                                  feedback: "Human recollection is not corroboration, and here it is actively misleading — the attacker went to some trouble to ensure nothing was noticed. Use interviews to generate leads, artefacts to establish facts.")
                    ]),
            LabStep(instruction: "The journal shows a `stage.7z` created and deleted inside the cleared window. Did data actually leave?",
                    hint: "Your packet capture does not go back three weeks. Something on the host counts bytes per application anyway.",
                    options: [
                        LabOption("Cannot be determined without network capture from that date",
                                  output: "",
                                  feedback: "The conclusion most responders reach, and it is wrong on this platform. A Windows host maintains its own per-application network accounting, independently of anything on the wire, and it is sitting in the image you already have."),
                        LabOption("Check SRUM for per-application bytes sent in that window",
                                  correct: true,
                                  output: """
$UsnJrnl:$J
  02:19:41  FileCreate  \\Windows\\Temp\\stage.7z
  02:19:41 - 02:38:02   DataExtend x 4,119  (archive being written)
  02:41:50  FileDelete  \\Windows\\Temp\\stage.7z
file-share audit gap: Security 5145 (file-share access) cleared at 02:41\n  -> read evidence reconstructed from $UsnJrnl + SRUM volume, not from $MFT
SRUM (SRUDB.dat) network usage, 2026-09-18 02:00-03:00
  mssrv.exe      bytes sent 2,418,903,114   bytes received 1,204,882
  <EDR agent>    (no records 02:11-02:19)
-> ~2.4 GB sent by mssrv.exe, concurrent with the archive write and deletion.
""",
                                  feedback: "Correct, and it is the finding that changes the legal posture of the case. The journal shows collection and staging, the MFT shows which share was read, and SRUM independently attributes 2.4 GB of outbound traffic to the implant in the same hour. The cleared log was hiding exfiltration, not just access."),
                        LabOption("Recover the deleted stage.7z from unallocated space and measure it",
                                  output: "carving: partial recovery, 180 MB of 2.4 GB; remainder overwritten.",
                                  feedback: "Worth attempting for *content*, and a poor measure of volume — what you recover is bounded by what has not been overwritten, so the number you get is a floor with no stated relationship to the truth. Use SRUM for the volume and carving for what was inside."),
                        LabOption("Infer the volume from the size of the Legal share",
                                  output: "\\Shares\\Legal total size: 1.1 TB",
                                  feedback: "An upper bound of a terabyte tells counsel nothing and would be indefensible in a notification decision. Report measured bytes with the artefact that measured them.")
                    ]),
            LabStep(instruction: "Writing it up for counsel. How do you present the anti-forensic findings?",
                    hint: "Think about which version of each fact a sceptical reader can check, and what the tampering itself tells them.",
                    options: [
                        LabOption("Present the timeline using the tool's default export, which shows the $STANDARD_INFORMATION dates",
                                  output: "exported timeline shows mssrv.exe created 2019-03-04.\n# a document stating, on your authority, the date you proved to be forged.",
                                  feedback: "A tooling default becoming a factual claim in your name. Whatever your tools export by default, the timeline you sign has to carry the dates you can defend — with the forged values shown as forged, not as fact."),
                        LabOption("Report the corroborated dates, cite the artefact behind each claim, and flag the clearing and timestomping as deliberate evasion",
                                  correct: true,
                                  output: """
finding 1  Implant placed 2026-09-18 01:47:33
           [$FILE_NAME; Prefetch 01:48:02; AmCache first-seen; $UsnJrnl FileCreate]
           $STANDARD_INFORMATION reports 2019-03-04 and is assessed as forged
           (all four values identical, sub-second precision zeroed).
finding 2  Collection 02:16-02:38: ~1,900 files staged from \\Shares\\Legal\\Contracts\n           (per-file read auditing was cleared; volume corroborated by SRUM).
           [$MFT $FILE_NAME access records; $UsnJrnl]
finding 3  Exfiltration ~2.42 GB attributed to mssrv.exe, 02:19-02:41.
           [SRUM network usage; corroborated by archive write/delete in $UsnJrnl]
finding 4  Deliberate anti-forensics: EDR service stopped 02:11:52; Security log
           cleared 02:14:07 and Application log 02:14:11 by svc_backup;
           file timestamps forged. [System 7036; Security 1102; System 104; $MFT]
assessment Tampering was deliberate and targeted at specific artefacts. Scope
           should be assumed wider than the artefacts that survived; sources the
           actor did not reach were decisive and may be incomplete elsewhere.
""",
                                  feedback: "Correct. Every claim carries the artefact that supports it, so a sceptical reader can check your work rather than take your word. And finding 4 is not a footnote: deliberate, targeted tampering raises the assumed sophistication of the actor and justifies widening scope — it is an analytical conclusion, not a complaint."),
                        LabOption("Omit the cleared-log gap so the timeline reads as a clean sequence",
                                  output: "",
                                  feedback: "Omitting the gap removes the evidence of intent and misrepresents your confidence. A timeline with a documented hole and a stated reason for it is stronger than a smooth one, because the hole is a finding."),
                        LabOption("State that the attacker is an advanced persistent threat given the anti-forensic tradecraft",
                                  output: "",
                                  feedback: "Clearing logs and running a timestomp utility are commodity capabilities available in off-the-shelf toolkits. Describe the observed tradecraft precisely and let the reader draw sophistication conclusions; attribution language you cannot support undermines the findings you can.")
                    ])
        ])

    // MARK: - 12. The first hour of a ransomware detonation (expert)

    private static let ransomwareHour = InteractiveLab(
        id: "lab-ransomware-hour",
        title: "The first hour of a ransomware detonation",
        goal: "Sequence containment, evidence, backups and notification correctly while the encryption is still running.",
        track: .blueTeam,
        difficulty: .expert,
        minutes: 11,
        scenario: "03:41 on a Saturday. EDR: mass file renames across nine file servers, `vssadmin delete shadows` on three of them, a ransom note dropped to every share root. Around 1,100 endpoints in the estate. You are the on-call IR lead; you have the console, the playbook, and nobody else awake yet. Every option in front of you is a real action somebody will later ask why you did not take first.",
        debrief: "Every decision in this hour is a trade between stopping damage, keeping the ability to recover, and keeping the ability to explain. The order that survives review is: stop the spread with the least destructive action that works, protect the recovery path before you touch it, preserve the evidence before you rebuild, notify through a channel you still trust, and refuse to put a number on recovery until you have tested a restore. What makes it hard is that every wrong answer here is a legitimate action in a different hour — restoring from backup, powering hosts off, calling in forensics, briefing the business. Doing them in the wrong order is how a contained incident becomes a second one. The operator's entire business model assumes you will skip containment to start restoring, and encrypt your restore target while you do it.",
        tools: ["EDR", "firewall", "backup console", "IR playbook"],
        relatedLessonID: "blue-ransomware",
        steps: [
            LabStep(instruction: "03:41. Encryption is in progress. First action?",
                    hint: "Pick the least destructive action that actually stops propagation. Two of these stop it and cost you something you will need.",
                    options: [
                        LabOption("Power off all nine file servers immediately",
                                  output: """
9 servers powered off 03:44.
lost: memory on every host (encryptor process context, injected code, C2 state,
      and any key material resident in RAM)
volumes: 3 servers were mid-write; partially encrypted files left inconsistent
spread: the account doing the encrypting is still enabled and still has sessions
        on hosts that are still up
""",
                                  feedback: "It stops those nine and leaves the mechanism intact. You have destroyed the memory of every affected host — including whatever key material or process context was resident — risked inconsistent volumes mid-write, and not touched the credential the encryptor is authenticating with. Hard power-off is a last resort, not a first move."),
                        LabOption("Network-isolate the affected hosts and disable the account the encryptor is authenticating with, revoking its sessions",
                                  correct: true,
                                  output: """
03:43  svc_backup disabled, refresh tokens revoked, computer account reset\n       NOTE: existing Kerberos TGTs stay valid until they expire (<=10h) —\n       disabling the account does not kill tickets already issued
03:44  9 file servers network-isolated via EDR (hosts remain powered)
03:45  SMB between the user VLAN and the server tier blocked at the firewall
03:48  no new file-rename events estate-wide; no new authentications by svc_backup
status: spread halted. hosts powered. memory intact. evidence preserved.
""",
                                  feedback: "Correct, and it is three actions aimed at one thing: propagation. Isolation stops the hosts talking, disabling the account stops the mechanism reaching new hosts, and the VLAN block catches anything you have not identified yet — all while leaving every machine powered so the volatile evidence survives. This is what \"contain before you clean\" means in practice."),
                        LabOption("Start restoring the first file server from backup so the business has something on Monday",
                                  output: """
restore started 03:47 to FS-01.
04:12  restored files begin re-encrypting: the encryptor is still running and
       svc_backup still has access to the restore target.
04:20  the restore point is now the newest thing the actor has encrypted.
""",
                                  feedback: "Recovery before containment, which is the single most expensive mistake available in this hour. You restored clean data into a live encryption event and lost both the data and the time. Nothing gets restored until the spread is stopped and the path is verified clean."),
                        LabOption("Call the CISO and wait for direction before acting",
                                  output: "call placed 03:42. CISO reached 03:58. encryption continued for 17 minutes.",
                                  feedback: "You are the on-call lead and the playbook gives you containment authority precisely so this does not happen. Notify in parallel, do not serialise behind it — seventeen minutes of mass encryption is hundreds of gigabytes."),
                        LabOption("Block the ransomware's C2 addresses at the perimeter",
                                  output: "3 addresses blocked. encryption continues (the encryptor needs no network to encrypt).",
                                  feedback: "A reasonable action with almost no effect on the thing that is happening. Encryption is local; the operator's C2 mattered during the days of staging that preceded this, not during the payload's run.")
                    ]),
            LabStep(instruction: "03:50. Spread halted. What do you do before anybody touches the backups?",
                    hint: "The backups are the only route out. Treat them as a target that may already have been attacked.",
                    options: [
                        LabOption("Verify the backup repository is unreachable from the affected hosts and confirm the immutability lock on the offline copy",
                                  correct: true,
                                  output: """
backup console (accessed from an out-of-band admin host, separate credentials)
  on-prem repository   reachable from server VLAN  -> ISOLATED, admin creds rotated
  last 3 nightly jobs  deleted 02:58 by svc_backup  <-- they went for the backups
  immutable copy       object-lock retained, 14 days, last good 2026-09-25 22:00
                       verified present, verified locked, NOT mounted
restore source identified and protected. no restore attempted yet.
""",
                                  feedback: "Correct, and look at what you found: three nightly jobs deleted forty minutes before the encryption started. Attackers hunt backups first, so the first thing you do is establish which copy survived, confirm it cannot be reached or altered, and leave it unmounted. Protect the recovery path before you use it."),
                        LabOption("Start a fresh full backup of the file servers so you have a current copy",
                                  output: """
full backup started 03:52.
  backing up: encrypted files and ransom notes
  retention policy: rotates out the oldest copy on completion
  oldest copy currently held: 2026-09-25 22:00  <-- the last clean one
""",
                                  feedback: "A panic reflex that destroys the thing you are panicking about. You would be backing up ciphertext and rotating your last clean restore point out of retention to make room for it. Never run a backup job during an active encryption event without checking what the rotation will discard."),
                        LabOption("Mount the immutable copy to verify the data is intact",
                                  output: "mounting immutable snapshot to FS-01 (an affected, isolated host)...",
                                  feedback: "The right question and a dangerous way to ask it. Mounting your surviving copy onto a host you have not cleared exposes it to whatever is still resident there — and on some platforms a mounted copy is a writable copy. Verify it from a clean, isolated system, later in the process."),
                        LabOption("Change every backup administrator password",
                                  output: "credentials rotated.",
                                  feedback: "Correct instinct, incomplete action, and it is part of the right answer rather than a substitute for it. Rotating credentials does nothing about a repository that is network-reachable from the encrypting hosts, nor does it tell you which copy survived.")
                    ]),
            LabStep(instruction: "04:05. The ops lead wants to start re-imaging FS-01 immediately. Your call?",
                    hint: "Ask what re-imaging destroys, and what the first hour is the only chance to collect.",
                    options: [
                        LabOption("Yes — re-image now; speed of recovery is the priority",
                                  output: """
FS-01 re-imaged 04:10.
lost: memory capture, the encryptor binary, the ransom note as dropped, the
      process ancestry showing how it arrived, and the variant identification
      that determines whether a free decryptor exists
remaining 8 servers: same artefacts still present, same risk of being wiped next
""",
                                  feedback: "Recovery pressure is real and this is still the wrong call. The encryptor binary and the host's memory are the only things that identify the variant — which decides whether a public decryptor exists, what the actor's known behaviour is, and what else to hunt for. Re-imaging before collection makes those questions permanently unanswerable."),
                        LabOption("Not yet — capture memory, the encryptor binary and a disk image from one representative host first, then release the rest for rebuild",
                                  correct: true,
                                  output: """
04:08  FS-03 designated evidence host (earliest detection, still powered)
       memory captured (192 GB), hashed, logged to chain of custody
       encryptor binary + ransom note + a sample of encrypted files acquired
       disk image started; FS-03 remains isolated and is NOT rebuilt
04:22  FS-01, FS-02, FS-04..09 released to the rebuild queue
       (artefact collection scripted across all 9 before release: notes, binary
        hashes, event logs, scheduled tasks, local accounts)
""",
                                  feedback: "Correct, and note the shape of it: one host is held for full forensics, lightweight artefacts are scripted off all nine, and the rest go to rebuild straight away. You do not have to choose between evidence and recovery across the whole estate — you choose one representative host and let the business have the others."),
                        LabOption("No rebuilds until the external forensics firm arrives on Monday",
                                  output: """
estate frozen 60 hours. volatile evidence on all 9 hosts continues to decay.
business impact: nine file servers down across two business days.
""",
                                  feedback: "Over-preservation, and it costs you the very evidence it claims to protect — memory does not keep for sixty hours, and the hosts may be rebooted or lose power meanwhile. Engage the firm now by all means, and collect the volatile evidence yourself today."),
                        LabOption("Re-image the servers but keep the encrypted files for later analysis",
                                  output: "encrypted files retained. memory, binary and process ancestry lost with the rebuild.",
                                  feedback: "Closer, and it keeps the least informative artefact. Encrypted files tell you the extension and the note; the binary and the memory tell you the variant, the delivery and the actor's tooling.")
                    ]),
            LabStep(instruction: "04:30. Notification. Who, and through what channel?",
                    hint: "Two independent constraints apply: who needs to know at discovery rather than at understanding, and which channel you can still trust.",
                    options: [
                        LabOption("Post a detailed status in the main company Teams channel so everyone is informed",
                                  output: """
posted 04:31, 1,100 recipients, on the estate's own collaboration platform.
# the actor's access to that platform has not been ruled out. the post names
# your evidence host, your surviving backup copy and your containment steps.
""",
                                  feedback: "You have handed the operator your incident plan. Until you have established what they can still see, assume your internal platforms are readable by them — and broad detail to 1,100 people also guarantees it reaches outside the company within the hour."),
                        LabOption("Activate the playbook's notification list over the out-of-band channel: incident commander, exec sponsor, legal, and the cyber insurer",
                                  correct: true,
                                  output: """
04:32  out-of-band bridge opened (pre-agreed, independent of corporate identity)
       incident commander appointed (not you — you keep technical lead)
       legal/privacy counsel engaged: potential personal-data exposure flagged
       cyber insurer notified per policy terms (notice obligations commonly begin
       at discovery, not at full understanding)
       comms prepared, not sent, pending scope
04:40  targeted, low-detail notice to IT staff via the out-of-band channel only
""",
                                  feedback: "Correct on both constraints. The channel is one the actor is not inside, and the recipients are the ones whose clocks start at discovery — insurers typically require prompt notice as a condition of cover, and regulatory regimes such as GDPR run their 72-hour window from the point of awareness. Note the split: an incident commander owns the response so you can stay on the technical problem."),
                        LabOption("Hold all notification until you can describe the full scope accurately",
                                  output: """
notification deferred pending scope.
day 3: scope established. insurer queries the 54-hour delay against the policy's
prompt-notice condition; counsel now assessing a notification window that began
on day 1.
""",
                                  feedback: "Professionally tempting and the most expensive wrong answer in the list. Waiting for certainty before notifying inverts how these obligations work: the clock starts when you become aware, and a late notice can affect both regulatory position and insurance cover. Notify with what you know and update as scope firms up."),
                        LabOption("Notify customers immediately that their data may be affected",
                                  output: "",
                                  feedback: "Right that external notification may be required, wrong on sequence and ownership. Customer notification is a decision for counsel and the business based on established scope, and an inaccurate early notice is extremely difficult to correct.")
                    ]),
            LabStep(instruction: "05:10. The exec sponsor asks two things: should we pay, and when will we be back?",
                    hint: "One of these is not your decision. The other is one you cannot answer honestly yet — and both answers depend on the same missing fact.",
                    options: [
                        LabOption("Tell them recovery will take about three days, and that paying is usually faster",
                                  output: """
\"three days\" becomes the plan: communicated to staff, customers and the board.
day 3: first restore test completed. throughput implies 9 days for the full estate.
""",
                                  feedback: "Both halves are wrong in the same way: you answered from intuition. An uninformed estimate given to an executive stops being an estimate within the hour — it becomes the commitment everyone else plans around. And recommending payment is not a technical judgement to volunteer."),
                        LabOption("Payment is a business decision for leadership with legal and insurer input; meanwhile establish whether a clean restore path actually works, because that is the input the decision needs",
                                  correct: true,
                                  output: """
05:15  position stated: payment is a leadership decision with counsel and the
       insurer (sanctions exposure, no guarantee of a working decryptor, and it
       does not undo the data theft if this is double extortion).
       technical input promised: a tested restore rate, by 09:00.
06:40  restore test, one crown-jewel share, from the immutable copy to clean
       hardware, on an isolated network:
         integrity verified against pre-incident hashes
         720 GB in 94 min -> measured throughput, not an estimate
       -> first credible recovery projection, with the assumptions written down
""",
                                  feedback: "Correct, and the two answers are connected: whether to pay turns almost entirely on whether you can restore, so the useful thing you can do for that decision is test a restore and report a measured rate. Note the restore went to clean hardware on an isolated network and was verified against pre-incident hashes — an unverified restore is not a recovery."),
                        LabOption("Tell them you never pay under any circumstances",
                                  output: "",
                                  feedback: "A defensible organisational policy and not yours to declare in the moment. The honest technical position is about what recovery is possible; stating a policy you do not own pre-empts counsel and the board and may not survive contact with the facts."),
                        LabOption("Contact the actor through the note's portal to get the price and buy time",
                                  output: """
portal contacted 05:20 from an analyst workstation.
# unauthorised engagement: confirms a live, paying-capable victim, starts the
# actor's pressure timeline, and may create sanctions exposure. counsel and the
# insurer's negotiator were not consulted.
""",
                                  feedback: "Never your call to make, and it materially damages the organisation's position. Any contact with the actor goes through counsel and, where cover applies, the insurer's appointed negotiator — unilateral engagement confirms you are worth pressuring and can create legal exposure of its own.")
                    ]),
            LabStep(instruction: "Day 4. Servers restored, users working, EDR quiet. Can you close the incident?",
                    hint: "Ask what you have verified versus what you have merely stopped observing.",
                    options: [
                        LabOption("Yes — the business is operational and there have been no alerts for 48 hours",
                                  output: """
closed day 4.
day 19: re-encryption. the initial access vector, an unpatched VPN appliance, was
never identified or closed; the actor re-entered with credentials harvested
before the first event and never rotated.
""",
                                  feedback: "Restored service plus silence is the most common premature closure in ransomware response, and re-victimisation within weeks is the documented consequence. Operational is not eradicated, and absence of alerts is not absence of the actor — especially when they demonstrated they can stop your EDR agent."),
                        LabOption("No — not until the access vector is closed, persistence is removed, credentials are rotated estate-wide including krbtgt twice, and the restored estate has run on heightened monitoring",
                                  correct: true,
                                  output: """
eradication checklist
  initial access     unpatched VPN appliance, exploited 2026-09-11 -> patched,
                     appliance credentials and certificates rotated, logs retained
  dwell              11 days of staging before detonation -> hunted across the
                     whole window, not just the encryption hour
  persistence        3 scheduled tasks, 2 local accounts, 1 rogue service removed;
                     golden-ticket risk assumed -> krbtgt reset twice, 12h apart
  credentials        all privileged accounts rotated; svc_backup retired and
                     replaced with a scoped, non-interactive account
  recovery integrity restored hosts rebuilt from known-good images, not cleaned
                     in place; restores verified against pre-incident hashes
  monitoring         heightened 30 days; detection added for the vector and for
                     shadow-copy destruction (DE-0091)
  lessons learned    immutable backups confirmed as the control that saved this;
                     3 nightly jobs were deleted and would have been the only copy
""",
                                  feedback: "Correct. Every line answers a way the actor could still be present: the vector, the dwell window before detonation, identity persistence, and the restore path itself. The two krbtgt resets matter because a golden ticket survives a single rotation, and rebuilding from images rather than cleaning in place is what stops a missed implant coming back with the data."),
                        LabOption("No — keep it open until the forensic report is delivered",
                                  output: "",
                                  feedback: "The report documents the incident; it does not eradicate anything. You can close a properly eradicated incident with the report still in draft, and you must not close an un-eradicated one because the report looks finished."),
                        LabOption("No — keep it open until the insurer has settled the claim",
                                  output: "",
                                  feedback: "A commercial milestone, unrelated to whether the actor still has access. Incident closure is a technical and risk judgement; the claim runs on its own track.")
                    ])
        ])

    // MARK: - Registry

    /// Ordered foundational -> expert, so the hub presents a ramp.
    static let labs: [InteractiveLab] = [
        dmarcVerdict,
        evidenceOrder,
        fpStandDown,
        attackMapping,
        sigmaRule,
        accountContainment,
        dnsExfil,
        beaconHunt,
        ruleTuning,
        malwareStatic,
        timelineTamper,
        ransomwareHour
    ]
}
