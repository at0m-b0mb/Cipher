import Foundation

/// Standalone hands-on labs — Networking.
/// See `Labs` in LabLibrary.swift for how these are surfaced.
///
/// These eight labs drill **network troubleshooting**: the ordered bisection a
/// practitioner walks when something does not work. The repeated lesson is that
/// a diagnostic tool is only as good as its position in the sequence — reaching
/// for `nslookup` before you know the host has a route is the single most common
/// way a competent engineer wastes an hour.
enum LabsNetworking {
    static let labs: [InteractiveLab] = [

        // MARK: 1 — Bisect a dead connection (foundational)

        InteractiveLab(
            id: "lab-net-outage-bisect",
            title: "Bisect a Dead Connection",
            goal: "Walk the stack bottom-up — link, address, neighbour, route, name — and find the one broken rung.",
            track: .networking,
            difficulty: .foundational,
            minutes: 7,
            scenario: "You own the lab segment `10.20.5.0/24`. A workstation on it, `10.20.5.48`, reports “the internet is down”. Nobody else is complaining. The internal resolver lives at `10.20.9.10` and the segment's router is `10.20.5.1`. You have a shell on the workstation and nothing else.",
            debrief: "The fault was a missing **default route** — a static profile pushed without a gateway. Notice what that one gap did to the *symptoms*: the browser failed, names stopped resolving, and ping to the internet died. Three different-looking failures, one cause, four rungs down from where the user pointed.\n\nThat is why you bisect bottom-up. Every rung you confirm shrinks the search space and, crucially, makes the next rung's result *interpretable*. A `nslookup` timeout means nothing until you know the host can reach the resolver at all. Run top-down and every tool lies to you by omission.\n\nThe flip side: an attacker who has quietly broken your routing gets exactly this confusion for free. Defenders who can state “link up, address valid, segment reachable, no default route” in sixty seconds are the ones who notice when a route *changed* rather than vanished — which is what a routing hijack or a rogue DHCP server looks like from the host.",
            tools: ["ip", "ping", "dig", "nmcli"],
            relatedLessonID: "net-switch-router",
            steps: [
                LabStep(
                    instruction: "The user says the internet is down. What is your **first** command?",
                    hint: "The lowest rung first. If the cable or the radio is not up, nothing above it can possibly work — and every tool above it will produce a misleading error.",
                    options: [
                        LabOption("ip -br link show", correct: true,
                                  output: "lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>\nenp0s3           UP             08:00:27:3f:a1:94 <BROADCAST,MULTICAST,UP,LOWER_UP>",
                                  feedback: "Correct — start at layer 1/2. `UP` is the administrative state and `LOWER_UP` is carrier: the cable is physically live. Rung one is cleared, so every failure above it is now meaningful rather than ambiguous."),
                        LabOption("nslookup intranet.lab.example",
                                  output: ";; communications error to 10.20.9.10#53: timed out\n;; communications error to 10.20.9.10#53: timed out\n;; communications error to 10.20.9.10#53: timed out\n;; no servers could be reached",
                                  feedback: "`nslookup` is a perfectly good tool used four rungs too early. “No servers could be reached” is consistent with a dead resolver, a filtered port, a missing route, a bad address, *or* an unplugged cable — it cannot distinguish any of them. You have spent a command and learned nothing you can act on."),
                        LabOption("sudo systemctl restart NetworkManager",
                                  output: "# (no output) — the user reports it is still broken",
                                  feedback: "Restarting the stack is the most common first move and the worst one for diagnosis: it is a blind fix that destroys the state you were about to read. If it works you never learn why, and if it does not you have changed the system before measuring it.")
                    ]),
                LabStep(
                    instruction: "The link is up. Next rung: does the host actually have a usable address?",
                    hint: "Before anything can be routed, the host needs a valid layer-3 identity on this segment. Read it; do not infer it.",
                    options: [
                        LabOption("ip -4 addr show enp0s3", correct: true,
                                  output: "2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000\n    inet 10.20.5.48/24 brd 10.20.5.255 scope global enp0s3\n       valid_lft forever preferred_lft forever",
                                  feedback: "Correct. `10.20.5.48/24`, `scope global` — a real, correctly-masked address on the right segment. Note what you have *also* ruled out: this is not a `169.254.x.x` link-local address, so DHCP did not fail silently. Rung two cleared."),
                        LabOption("ping -c 2 8.8.8.8",
                                  output: "ping: connect: Network is unreachable",
                                  feedback: "This is a genuinely useful clue — “Network is unreachable” comes from the *local routing table*, before a packet ever leaves. But it is a symptom test, not a layer test: it cannot tell you whether you lack an address, lack a route, or have the wrong mask. You will still have to walk the ladder, so walk it in order."),
                        LabOption("dig +short intranet.lab.example",
                                  output: ";; communications error to 10.20.9.10#53: timed out\n;; no servers could be reached",
                                  feedback: "Still the name-resolution rung, still too early. The resolver sits at `10.20.9.10` — off this /24. Asking it anything presumes routing works, which is the very thing you have not yet checked.")
                    ]),
                LabStep(
                    instruction: "Address is valid. Rung three: does the local segment itself work? `10.20.5.60` is a file server you know is healthy.",
                    hint: "You want one test that exercises ARP plus layer-3 delivery inside the subnet, with no router and no name involved.",
                    options: [
                        LabOption("ping -c 2 10.20.5.60", correct: true,
                                  output: "PING 10.20.5.60 (10.20.5.60) 56(84) bytes of data.\n64 bytes from 10.20.5.60: icmp_seq=1 ttl=64 time=0.412 ms\n64 bytes from 10.20.5.60: icmp_seq=2 ttl=64 time=0.388 ms\n\n--- 10.20.5.60 ping statistics ---\n2 packets transmitted, 2 received, 0% packet loss, time 1001ms\nrtt min/avg/max/mdev = 0.388/0.400/0.412/0.012 ms",
                                  feedback: "Correct — and look at `ttl=64`. The reply arrived with the sender's initial TTL intact, which proves no router decremented it: that was a direct, on-link exchange. ARP worked, the switch port works, layer 3 works inside the subnet. The break is above the local segment."),
                        LabOption("ping -c 2 intranet.lab.example",
                                  output: "ping: intranet.lab.example: Temporary failure in name resolution",
                                  feedback: "This folds two unknowns into one test. The failure could be the name or the network, and the message cannot tell you which — so whatever it returns, you learn nothing. Never introduce DNS into a test until DNS is the thing you are testing."),
                        LabOption("arp -a",
                                  output: "? (10.20.5.1) at <incomplete> on enp0s3",
                                  feedback: "The neighbour table shows what was resolved *at some point in the past*, not whether the segment works now — and an `<incomplete>` entry can simply mean nothing has talked to that address recently. Generate traffic first, then read the table; reading a cold cache invites a wrong conclusion.")
                    ]),
                LabStep(
                    instruction: "The segment is healthy. Rung four: can this host leave the subnet at all?",
                    hint: "Off-subnet traffic needs somewhere to go. Read the forwarding decisions the kernel actually has, rather than testing a destination and guessing.",
                    options: [
                        LabOption("ip route show", correct: true,
                                  output: "10.20.5.0/24 dev enp0s3 proto kernel scope link src 10.20.5.48 metric 100",
                                  feedback: "There it is — **one line, and no `default` route**. The kernel knows how to reach its own /24 and nothing else. Every destination outside `10.20.5.0/24` is unreachable before a single packet is emitted, including the resolver at `10.20.9.10`."),
                        LabOption("nslookup intranet.lab.example",
                                  output: ";; communications error to 10.20.9.10#53: timed out\n;; no servers could be reached",
                                  feedback: "You are one rung away from the answer and reaching past it. The resolver is off-subnet; if routing is broken this timeout is guaranteed and tells you nothing about DNS. Clear routing first and this command becomes informative instead of noise."),
                        LabOption("sudo ethtool enp0s3",
                                  output: "Settings for enp0s3:\n        Supported ports: [ TP ]\n        Speed: 1000Mb/s\n        Duplex: Full\n        Link detected: yes",
                                  feedback: "`ethtool` re-answers the question you settled at step one. Going back *down* the ladder after clearing a rung is as wasteful as skipping up it — it feels like progress because a command ran and output appeared.")
                    ]),
                LabStep(
                    instruction: "No default route. Which diagnosis is consistent with **all** the evidence you have gathered?",
                    hint: "One cause must explain three symptoms at once: the browser, the name lookups, and the failed internet ping.",
                    options: [
                        LabOption("No default route — every off-subnet destination is unreachable, including the resolver, so the DNS symptom is a consequence, not a cause", correct: true,
                                  output: "# evidence: link UP, addr 10.20.5.48/24, on-link ping OK, no default route",
                                  feedback: "Correct. One missing line explains all three symptoms. This is the payoff of bottom-up bisection: you end up with a single cause that accounts for everything, rather than a list of plausible ones."),
                        LabOption("The DNS server at 10.20.9.10 is down",
                                  output: "# (from this host, a dead resolver and an unreachable resolver are indistinguishable)",
                                  feedback: "It fits the DNS symptom and nothing else — it does not explain why `ping 8.8.8.8` failed with a *local* routing error. And from this host you cannot even test the claim: with no route, a dead resolver and an unreachable resolver look identical. That is precisely why you do not start at DNS."),
                        LabOption("An outbound firewall rule is dropping UDP/53 and ICMP",
                                  output: "# ping reported: connect: Network is unreachable",
                                  feedback: "A filter *drops* packets; it does not make the kernel refuse to send them. `connect: Network is unreachable` is generated locally by the routing lookup before netfilter is ever consulted. Reading error text precisely is half of troubleshooting.")
                    ]),
                LabStep(
                    instruction: "Restore service now. The segment's router is `10.20.5.1`.",
                    hint: "Point the default route at a device that actually forwards packets — and change exactly one thing.",
                    options: [
                        LabOption("sudo ip route add default via 10.20.5.1 dev enp0s3", correct: true,
                                  output: "$ ping -c 1 8.8.8.8\n64 bytes from 8.8.8.8: icmp_seq=1 ttl=115 time=12.4 ms\n\n$ dig +short intranet.lab.example\n10.20.9.80",
                                  feedback: "Correct, and note the ordering of the proof: internet reachability came back *and* name resolution started working, with no DNS change at all. That retroactively confirms the diagnosis — the resolver was never broken."),
                        LabOption("sudo ip route add default via 10.20.5.60 dev enp0s3",
                                  output: "$ ping -c 1 8.8.8.8\n\n--- 8.8.8.8 ping statistics ---\n1 packets transmitted, 0 received, 100% packet loss",
                                  feedback: "The command succeeds and the symptom stays. A default route must point at something that *forwards* — `10.20.5.60` is a file server, so it accepts the frame and discards the packet. “The command did not error” is not the same as “it worked”."),
                        LabOption("echo nameserver 8.8.8.8 | sudo tee /etc/resolv.conf",
                                  output: "nameserver 8.8.8.8\n\n$ dig +short intranet.lab.example\n;; communications error to 8.8.8.8#53: timed out",
                                  feedback: "Swapping the resolver cannot help a host that has no route to *any* resolver — and you have just discarded the correct internal resolver, so internal names will keep failing even after the route is fixed. Blind fixes often leave a second fault behind.")
                    ]),
                LabStep(
                    instruction: "The user is working again. Is the job done?",
                    hint: "Ask where the change you made is actually stored.",
                    options: [
                        LabOption("sudo nmcli con mod Office-Static ipv4.gateway 10.20.5.1 && sudo nmcli con up Office-Static", correct: true,
                                  output: "Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/4)",
                                  feedback: "Correct. `ip route add` writes to the running kernel only; the profile that will be applied on the next boot still has no gateway. Persisting the fix in the connection profile is what actually closes the ticket."),
                        LabOption("Nothing — the route is permanent now",
                                  output: "# after a reboot:\n$ ip route show\n10.20.5.0/24 dev enp0s3 proto kernel scope link src 10.20.5.48 metric 100",
                                  feedback: "Runtime routes live in the kernel's table and nowhere else. A reboot, an interface bounce, or a NetworkManager restart wipes it and the ticket reopens — usually at a less convenient hour, and usually to someone who has not read your notes."),
                        LabOption("echo sudo ip route add default via 10.20.5.1 dev enp0s3 >> ~/.bashrc",
                                  output: "# runs only when this one user opens an interactive shell",
                                  feedback: "It fires only for one user's interactive shells, needs sudo without a terminal, and leaves the real configuration still wrong. Configuration belongs in the configuration system — a shell profile is a hiding place, not a fix.")
                    ])
            ]),

        // MARK: 2 — Prove a host is not on your subnet (foundational)

        InteractiveLab(
            id: "lab-net-subnet-proof",
            title: "Prove a Host Is Not on Your Subnet",
            goal: "Size a subnet to a stated requirement, then prove from the host's own stack whether a second address is on-link.",
            track: .networking,
            difficulty: .foundational,
            minutes: 7,
            scenario: "You are building out a new lab segment from the allocation `10.4.12.0/24`. The design brief says: carve the **smallest** subnet that holds 100 workstations, starting at the bottom of the range. Days later a ticket arrives — the workstation `10.4.12.37` keeps losing its session with the NAS at `10.4.12.70`, and the ticket asserts “they are on different networks”. You have a shell on the workstation.",
            debrief: "Two ideas did the work here. First, **block arithmetic**: a /26 steps in blocks of 64, so `.37` and `.70` land in different blocks even though the first three octets match. Reading the first three octets and calling it the same network is /24 thinking applied to a /26 — the most common subnetting error there is.\n\nSecond, and more valuable: **reachability and on-link are different questions**. The ping succeeded. If you had stopped there you would have closed the ticket with the mask still wrong, and the intermittent failures would have continued — because the traffic was hairpinning through the router, with a stateful device in the path that had never been designed to see it.\n\n`ip route get` is the tool that settles it, because it asks the kernel for its *forwarding decision* rather than for a result. A defender uses the same question in reverse: if a host suddenly starts routing traffic it used to deliver on-link, something changed its mask or its routes — which is what a rogue DHCP server or an ARP-spoofing man-in-the-middle looks like from inside.",
            tools: ["ip", "ping", "ipcalc"],
            relatedLessonID: "net-subnetting",
            steps: [
                LabStep(
                    instruction: "Design first. From `10.4.12.0/24`, what is the **smallest** subnet that holds 100 workstations, starting at the bottom?",
                    hint: "Usable hosts = 2^(host bits) − 2. Walk up from the smallest prefix until the count clears 100.",
                    options: [
                        LabOption("10.4.12.0/25 — hosts .1 to .126, broadcast .127", correct: true,
                                  output: "$ ipcalc 10.4.12.0/25\nAddress:   10.4.12.0\nNetmask:   255.255.255.128 = 25\nNetwork:   10.4.12.0/25\nBroadcast: 10.4.12.127\nHostMin:   10.4.12.1     HostMax: 10.4.12.126   (126 hosts)",
                                  feedback: "Correct. 7 host bits = 128 addresses, minus network and broadcast = 126 usable. It clears 100 with room to grow, and it leaves `10.4.12.128/25` free for the server and guest segments the plan also needs."),
                        LabOption("10.4.12.0/26 — hosts .1 to .62, broadcast .63",
                                  output: "$ ipcalc 10.4.12.0/26\nHostMin:   10.4.12.1     HostMax: 10.4.12.62    (62 hosts)",
                                  feedback: "62 usable addresses does not hold 100 workstations. This is the right *style* of answer and the wrong size — and remember it, because it is exactly the mask that turns up later in this lab."),
                        LabOption("10.4.12.0/24 — hosts .1 to .254, broadcast .255",
                                  output: "$ ipcalc 10.4.12.0/24\nHostMin:   10.4.12.1     HostMax: 10.4.12.254   (254 hosts)",
                                  feedback: "It satisfies the host count by consuming the entire allocation, which the brief ruled out by asking for the smallest fit. Oversizing a subnet is not free: it enlarges the broadcast domain and leaves no room for the segmentation the design depends on.")
                    ]),
                LabStep(
                    instruction: "Now the ticket. The workstation `10.4.12.37` cannot hold a session with the NAS at `10.4.12.70`. What do you check first?",
                    hint: "The ticket makes a claim about subnets. Verify the input to that claim before testing its conclusion.",
                    options: [
                        LabOption("ip -4 addr show enp0s3", correct: true,
                                  output: "2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000\n    inet 10.4.12.37/26 brd 10.4.12.63 scope global enp0s3\n       valid_lft forever preferred_lft forever",
                                  feedback: "Correct — and the finding is immediate: the host is configured **/26**, not the /25 the design called for. The broadcast address `10.4.12.63` confirms the block. Read the actual configuration before you test behaviour; the mask is the input to every question that follows."),
                        LabOption("ping -c 2 10.4.12.70",
                                  output: "64 bytes from 10.4.12.70: icmp_seq=1 ttl=63 time=1.24 ms\n64 bytes from 10.4.12.70: icmp_seq=2 ttl=63 time=1.19 ms",
                                  feedback: "A ping result cannot answer the question that was asked. Success is compatible with “on-link” *and* with “off-link but routed”, so whichever way it comes out you still do not know. Worse, a success here tempts you to close the ticket with the real fault untouched."),
                        LabOption("nslookup nas.lab.example",
                                  output: "Name:   nas.lab.example\nAddress: 10.4.12.70",
                                  feedback: "The ticket already handed you the IP address. Resolving the name adds a dependency on DNS to a question that is purely about layer 3 — you have confirmed something you already knew and introduced a system that could fail for unrelated reasons.")
                    ]),
                LabStep(
                    instruction: "The host is `10.4.12.37/26`. Which block is it in, and is `10.4.12.70` inside it?",
                    hint: "A /26 has 6 host bits. How large is each block, and where does the first one end?",
                    options: [
                        LabOption("Block 10.4.12.0/26 covers .0 to .63 — so .70 is in the next block, 10.4.12.64/26, and is off-link", correct: true,
                                  output: "10.4.12.0/26    .0  - .63    <-- the host (.37) is here\n10.4.12.64/26   .64 - .127   <-- the NAS (.70) is here\n10.4.12.128/26  .128- .191\n10.4.12.192/26  .192- .255",
                                  feedback: "Correct. 6 host bits = 64 addresses per block, so the boundaries fall at .0, .64, .128 and .192. `.37` and `.70` straddle the .64 boundary: under this mask they are on different networks, and the ticket's claim is right for the wrong reason."),
                        LabOption("They are on the same network — both addresses start 10.4.12",
                                  output: "# this is only true if the mask is /24",
                                  feedback: "That is /24 reasoning applied to a /26. The mask, not the dotted notation, decides where the network part ends — and with 26 network bits part of the fourth octet belongs to the network too. This is the single most common subnetting mistake."),
                        LabOption("Block 10.4.12.32/26 covers .32 to .95 — so .70 is on-link",
                                  output: "# /26 blocks are 64 addresses wide and start at multiples of 64, not 32",
                                  feedback: "The block size is right-ish but the alignment is wrong: /26 blocks are 64 wide and begin at multiples of 64, so there is no block starting at .32 (that would be a /27). Blocks always start at a multiple of their own size.")
                    ]),
                LabStep(
                    instruction: "Prove it from the host's own stack rather than by arithmetic. What settles the forwarding decision?",
                    hint: "Ask the kernel what it would *do* with a packet for that address, not what happens when you send one.",
                    options: [
                        LabOption("ip route get 10.4.12.70", correct: true,
                                  output: "10.4.12.70 via 10.4.12.1 dev enp0s3 src 10.4.12.37 uid 1000\n    cache\n\n$ ip route get 10.4.12.40\n10.4.12.40 dev enp0s3 src 10.4.12.37 uid 1000\n    cache",
                                  feedback: "Correct, and the contrast is the whole proof. For `.70` the kernel reports `via 10.4.12.1` — it will hand the frame to the router. For `.40`, an address inside the same /26, there is no `via` at all: direct delivery. One command, an unambiguous answer, and nothing sent on the wire."),
                        LabOption("arp -a",
                                  output: "? (10.4.12.1) at 52:54:00:9a:1b:04 [ether] on enp0s3\n? (10.4.12.19) at 52:54:00:3c:88:f1 [ether] on enp0s3",
                                  feedback: "The neighbour table reflects history, not policy. The absence of `.70` is suggestive but not proof — it might simply have aged out, and a stale entry could survive a mask change and mislead you in the other direction."),
                        LabOption("ping -b 10.4.12.63",
                                  output: "PING 10.4.12.63 (10.4.12.63) 56(84) bytes of data.\n\n--- 10.4.12.63 ping statistics ---\n2 packets transmitted, 0 received, 100% packet loss",
                                  feedback: "Broadcast pings are ignored by default on most modern hosts, so the silence tells you nothing. And even if it answered, it would describe the broadcast domain rather than this host's forwarding decision for one specific destination.")
                    ]),
                LabStep(
                    instruction: "Out of curiosity you ping the NAS anyway — it replies, and the TTL looks perfectly normal. Does that close the ticket?",
                    hint: "One of your two measurements describes *your* forwarding decision. Does the TTL of a reply describe yours, or the NAS's?",
                    options: [
                        LabOption("No — `ip route get` already said `via`, and a reply's TTL describes the NAS's return path, not mine", correct: true,
                                  output: "PING 10.4.12.70 (10.4.12.70) 56(84) bytes of data.\n64 bytes from 10.4.12.70: icmp_seq=1 ttl=64 time=1.24 ms\n64 bytes from 10.4.12.70: icmp_seq=2 ttl=64 time=1.19 ms\n\n--- 10.4.12.70 ping statistics ---\n2 packets transmitted, 2 received, 0% packet loss, time 1001ms",
                                  feedback: "Correct, and this is the trap. The NAS is correctly configured with the `/25`, so *it* considers you on-link and replies directly — the reply arrives undecremented at `ttl=64`. But your own outbound packets still leave via the gateway, because your mask is wrong. **The path is asymmetric**, and a reply's TTL can only ever tell you about the direction it travelled. `ip route get` is the measurement that describes *your* forwarding decision, and it already told you the truth."),
                        LabOption("No — the reply would come back `ttl=63`, and a decrement proves my traffic is hairpinning",
                                  output: "# expected ttl=63 — but the capture above shows ttl=64",
                                  feedback: "Reasonable instinct, wrong direction. A decremented reply TTL would tell you a router stood in the **return** path, which the NAS's own routing table decides — not yours. Rely on this and you get a false negative in exactly this case: the TTL looks clean, you close the ticket, and the outbound half is still hairpinning."),
                        LabOption("Yes — it replies, so they are on the same subnet",
                                  output: "# reachable, via 10.4.12.1",
                                  feedback: "Reachability and on-link are different properties. Routers exist precisely so that networks which are not directly reachable become reachable; a successful ping says a path exists, and says nothing at all about whether that path should have a router in it."),
                        LabOption("No — move the NAS into 10.4.12.0/26",
                                  output: "# re-addressing 1 host to fit a mask that is itself wrong",
                                  feedback: "This makes the symptom go away by conforming to the error. The design called for one /25 covering both hosts; re-addressing the NAS bakes the wrong mask into the topology and you will repeat the work for every host added later.")
                    ]),
                LabStep(
                    instruction: "Fix it and verify on the workstation.",
                    hint: "Change the mask the design asked for, then re-ask the kernel the same question you asked before.",
                    options: [
                        LabOption("sudo ip addr del 10.4.12.37/26 dev enp0s3 && sudo ip addr add 10.4.12.37/25 dev enp0s3", correct: true,
                                  output: "$ ip route get 10.4.12.70\n10.4.12.70 dev enp0s3 src 10.4.12.37 uid 1000\n    cache\n\n$ ping -c 1 10.4.12.70\n64 bytes from 10.4.12.70: icmp_seq=1 ttl=64 time=0.31 ms",
                                  feedback: "Correct. Verify with the measurement that actually describes your own forwarding decision: the `via` is gone from `ip route get`, so your packets now go straight to the NAS, and the round trip drops to a third of the time. The reply TTL reads `ttl=64` — just as it did *before* the fix, which is precisely why it was never the measurement to trust. Re-running your original probe is what turns a plausible fix into a confirmed one. (Then persist it in the interface profile, exactly as you would a route.)"),
                        LabOption("sudo ip route add 10.4.12.64/26 dev enp0s3",
                                  output: "$ ip route get 10.4.12.70\n10.4.12.70 dev enp0s3 src 10.4.12.37 uid 1000\n    cache",
                                  feedback: "It does make the kernel treat that block as on-link, so the `via` disappears and it looks fixed. But the interface still has the wrong mask, the broadcast address is still `.63`, and you now need this hack on every host on the segment. A route is not a repair for an addressing error."),
                        LabOption("sudo ip neigh add 10.4.12.70 lladdr 52:54:00:71:0b:2a dev enp0s3",
                                  output: "# static neighbour entry added",
                                  feedback: "A static ARP entry supplies a MAC address, but the kernel never asks for one here — under /26 it has already decided to send the frame to the router. You have pinned an answer to a question that is not being asked, and created an entry that will be wrong the day the NAS's NIC changes.")
                    ])
            ]),

        // MARK: 3 — Find the break in a traceroute (intermediate)

        InteractiveLab(
            id: "lab-net-traceroute-break",
            title: "Find the Break in a Traceroute",
            goal: "Read a traceroute correctly — tell a silent hop from a broken path, and a probe problem from an outage.",
            track: .networking,
            difficulty: .intermediate,
            minutes: 6,
            scenario: "Your team integrates with a partner API in your own test environment, `api.partner.example` (`203.0.113.42`). Three people report it is “unreachable from the office” and a ticket has been raised against the network team — yours. You have a traceroute they attached and a shell on an office workstation.",
            debrief: "Three misreadings were on the table and all three are everyday mistakes.\n\n`* * *` **in the middle of a path is not a break.** A router that rate-limits or suppresses ICMP TTL-exceeded still forwards your traffic perfectly; the proof is that hops resume below it. Only a run of timeouts that never recovers, all the way to the hop limit, marks the end of what you can see.\n\nA **latency spike at one hop that does not persist** is not congestion. Routers generate ICMP errors on a low-priority path, so hop 5 can report 88 ms while hop 6 reports 22 ms. Real path latency is monotonic: it can only accumulate. Judge latency by the *last* hops, never a middle one.\n\nAnd **silence is not an outage**. The path was fine; ICMP was filtered. Because `ping` and default `traceroute` use a different 5-tuple from the traffic you care about, a policy that permits one and denies the other produces a confident false negative. Probe the service on its own port and protocol — `traceroute -T -p 443`, `nc -vz`, `curl` — and your diagnostic matches reality.\n\nFrom the other side of the fence: filtering ICMP is a deliberate, defensible hardening choice, and that is exactly why an attacker scanning you cannot trust a silent host either. The lesson cuts both ways — never let one probe type be your only evidence.",
            tools: ["traceroute", "nc", "curl"],
            relatedLessonID: "net-routing-traceroute",
            steps: [
                LabStep(
                    instruction: "Here is the attached traceroute. Where does the path actually break?",
                    hint: "Look for the last hop that answered *and* whether anything answers after it. A gap that recovers is not a break.",
                    options: [
                        LabOption("At or just past hop 6 (203.0.113.1) — the last hop that answered, with nothing after it", correct: true,
                                  output: "traceroute to api.partner.example (203.0.113.42), 30 hops max, 60 byte packets\n 1  10.20.5.1  0.842 ms  0.801 ms  0.779 ms\n 2  100.64.0.1  7.114 ms  6.998 ms  7.203 ms\n 3  * * *\n 4  198.51.100.9  14.602 ms  14.880 ms  14.551 ms\n 5  198.51.100.33  88.401 ms  91.772 ms  89.104 ms\n 6  203.0.113.1  22.009 ms  21.884 ms  22.117 ms\n 7  * * *\n 8  * * *\n...\n30  * * *",
                                  feedback: "Correct. The useful phrase is “at or just past” — hop 6 is the last device that identified itself, so the visibility ends there. It may be hop 6 dropping, hop 7 not answering, or the destination filtering. You have localised the problem without yet knowing its nature."),
                        LabOption("At hop 3 — the first row of asterisks",
                                  output: " 3  * * *\n 4  198.51.100.9  14.602 ms   <-- hops resume",
                                  feedback: "Hops resume at 4, so hop 3 forwarded your packets fine and simply did not send back an ICMP TTL-exceeded — commonly because it rate-limits them or is configured not to. A single silent hop mid-path is normal and almost never the fault."),
                        LabOption("At hop 5 — the 88 ms latency spike",
                                  output: " 5  198.51.100.33  88.401 ms  91.772 ms  89.104 ms\n 6  203.0.113.1    22.009 ms  21.884 ms  22.117 ms",
                                  feedback: "Hop 6 reports 22 ms. Latency cannot *decrease* further along a path, so the 88 ms is not real transit time — it is how long hop 5 took to generate a low-priority ICMP reply. Only a spike that persists through every later hop reflects genuine path latency.")
                    ]),
                LabStep(
                    instruction: "Nothing answers after hop 6. Does that prove the API server is down?",
                    hint: "Ask what traceroute actually measures, and what it needs the far end to do for it.",
                    options: [
                        LabOption("No — it proves nothing beyond 203.0.113.1 returns ICMP TTL-exceeded to you; the service may be perfectly healthy", correct: true,
                                  output: "# traceroute needs each hop to CHOOSE to send an ICMP error\n# a device that forwards but stays silent is invisible to it",
                                  feedback: "Correct. Traceroute depends on the cooperation of every hop and on the destination replying to a probe it may not want to answer. Absence of evidence is routine here — treat it as “cannot see”, never as “is down”."),
                        LabOption("Yes — the destination never answered, so the server is down",
                                  output: "# a down host usually produces an ICMP unreachable from the last router — absent here",
                                  feedback: "The evidence points the other way. A genuinely dead host normally has its last router return ICMP host-unreachable, which would appear in the output as `!H`. Pure silence is the signature of filtering, not of absence."),
                        LabOption("No — DNS is broken, which is why the hops stopped",
                                  output: "traceroute to api.partner.example (203.0.113.42), 30 hops max, 60 byte packets",
                                  feedback: "The header line already resolved the name to `203.0.113.42`, so DNS worked before the first probe left. Read the header: it rules DNS out for free, and it tells you which address the rest of the output is about.")
                    ]),
                LabStep(
                    instruction: "You need to distinguish “path broken” from “ICMP filtered”. Which probe does that?",
                    hint: "Probe with the same protocol and port as the traffic you actually care about.",
                    options: [
                        LabOption("sudo traceroute -T -p 443 api.partner.example", correct: true,
                                  output: "traceroute to api.partner.example (203.0.113.42), 30 hops max, 60 byte packets\n 1  10.20.5.1  0.901 ms  0.874 ms  0.860 ms\n 2  100.64.0.1  7.221 ms  7.104 ms  7.318 ms\n 3  * * *\n 4  198.51.100.9  14.710 ms  14.662 ms  14.901 ms\n 5  198.51.100.33  90.114 ms  87.552 ms  88.330 ms\n 6  203.0.113.1  22.114 ms  22.004 ms  21.980 ms\n 7  203.0.113.42  23.551 ms  23.402 ms  23.610 ms",
                                  feedback: "Correct — `-T` sends TCP SYN probes and `-p 443` aims them at the real service port, so a policy that permits 443 lets them through. Hop 7 is the destination. The path was never broken; only your probe type was being dropped."),
                        LabOption("sudo traceroute -I api.partner.example",
                                  output: " 6  203.0.113.1  22.088 ms  21.904 ms  22.201 ms\n 7  * * *\n 8  * * *",
                                  feedback: "`-I` swaps UDP probes for ICMP echo — a different probe, but still ICMP, which is the family you suspect is filtered. You have changed the variable least likely to matter and confirmed your own blind spot."),
                        LabOption("traceroute -q 10 api.partner.example",
                                  output: " 6  203.0.113.1  22.114 ms  22.077 ms  ...  (10 probes)\n 7  * * * * * * * * * *",
                                  feedback: "Ten probes per hop instead of three is more of the same evidence down the same filtered path. Repeating a measurement increases confidence in a result you have already obtained; it does not test a new hypothesis.")
                    ]),
                LabStep(
                    instruction: "TCP/443 reaches the destination. Confirm the service itself answers, then decide what to report.",
                    hint: "One cheap probe that opens a real TCP connection to the port the application uses.",
                    options: [
                        LabOption("nc -vz api.partner.example 443", correct: true,
                                  output: "Connection to api.partner.example 443 port [tcp/https] succeeded!",
                                  feedback: "Correct. A completed TCP handshake on the service port is the measurement that matters: the network path, the destination host and the listening socket are all confirmed in one line. Whatever the three reporters experienced, it was not a network-layer outage."),
                        LabOption("ping -c 4 api.partner.example",
                                  output: "PING api.partner.example (203.0.113.42) 56(84) bytes of data.\n\n--- api.partner.example ping statistics ---\n4 packets transmitted, 0 received, 100% packet loss, time 3052ms",
                                  feedback: "This is the measurement that started the whole misdiagnosis. You already know ICMP is filtered on this path, so 100% loss is the expected result and carries no information about the service. Never re-run the probe you have just invalidated."),
                        LabOption("Ask the partner to permit ICMP so traceroute works",
                                  output: "# request filed; path unchanged",
                                  feedback: "Tempting, and it would make your tooling more comfortable — but you are asking someone to enlarge their exposed surface to compensate for a probe you could simply have changed. Fix your diagnostic habit before you ask for a policy change.")
                    ]),
                LabStep(
                    instruction: "What goes in the ticket update?",
                    hint: "The finding is about measurement, not about the network. Say what the team should run next time.",
                    options: [
                        LabOption("Network path and service verified on TCP/443; ICMP is filtered on this path, so ping and default traceroute will always appear to fail — probe the service port instead", correct: true,
                                  output: "# status: not a network fault\n# repro guidance: nc -vz api.partner.example 443  /  traceroute -T -p 443",
                                  feedback: "Correct. You close the ticket with a verified result *and* you change what the team measures, so the same false alarm does not come back next month. Teaching the probe is worth more than fixing the ticket."),
                        LabOption("Escalate to the ISP — the path breaks after hop 6",
                                  output: "# escalation raised against a path you have proven works on 443",
                                  feedback: "You now hold evidence that TCP/443 traverses the whole path to hop 7. Escalating a routing fault you have disproven burns credibility with the people you will need next time there is a real one."),
                        LabOption("Close as user error — the API works fine",
                                  output: "# closed, no guidance given",
                                  feedback: "The measurement is right and the conclusion is uncharitable. The reporters used the standard tool and it told them something false; the gap is in the diagnostic, not the people. A close with no guidance guarantees a repeat.")
                    ])
            ]),

        // MARK: 4 — DNS triage: resolver, record or propagation (intermediate)

        InteractiveLab(
            id: "lab-net-dns-triage",
            title: "DNS Triage: Resolver, Record or Propagation",
            goal: "Separate a caching problem from a zone-content problem from a zone-transfer problem — without flushing the evidence.",
            track: .networking,
            difficulty: .intermediate,
            minutes: 7,
            scenario: "You run the zone `lab.example` for your own test environment, served by two authoritative nameservers you control: `ns1` at `198.51.100.53` and `ns2` at `198.51.100.54`. Yesterday you added `app.lab.example` pointing at `198.51.100.40`. Today some of the team reach the new service and the rest get “server not found”, and the same person can get either answer on different days. Everyone is behind the same corporate resolver.",
            debrief: "DNS failures split into three families and they need three different fixes, so naming the family *is* the diagnosis.\n\n**Resolver** — the path to or the health of the recursive server; a stale cache entry living out its TTL belongs here. **Record** — the zone genuinely says the wrong thing, or nothing. **Propagation** — the authoritative servers disagree, because a secondary never received the updated zone. Only the third one produces the signature you saw: two servers, both answering with the `aa` (authoritative) flag, giving contradictory answers.\n\nThe discipline that made it findable was refusing to flush. A cached record with its remaining TTL, and an NXDOMAIN carrying the zone's SOA in the AUTHORITY section, are measurements. Flushing a cache is the DNS equivalent of restarting the service: it may paper over today's symptom and it certainly destroys the data that would have told you why.\n\nAnd note the serial was visible in the *very first* command's AUTHORITY section — `2026093002`, a day old. Experienced operators read whole `dig` output rather than `dig +short`, precisely because the answer is often already on screen.\n\nThe attacker's view: an authoritative server serving stale or divergent data is also how cache poisoning and subdomain takeover get their foothold. A zone where you cannot state with confidence which servers are in sync is a zone you cannot defend.",
            tools: ["dig", "nslookup", "named"],
            relatedLessonID: "net-dns",
            steps: [
                LabStep(
                    instruction: "You are on an affected machine. What is your first command?",
                    hint: "Read the full answer, including the header status and the TTLs. Do not change anything yet.",
                    options: [
                        LabOption("dig app.lab.example A", correct: true,
                                  output: ";; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 52011\n;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1\n\n;; QUESTION SECTION:\n;app.lab.example.               IN  A\n\n;; AUTHORITY SECTION:\nlab.example.           3600    IN  SOA ns1.lab.example. hostmaster.lab.example. 2026093002 7200 3600 1209600 3600\n\n;; Query time: 31 msec\n;; SERVER: 10.20.9.10#53(10.20.9.10) (UDP)",
                                  feedback: "Correct, and there is more here than the status line. `NXDOMAIN` with `AUTHORITY: 1` means some server with the zone answered definitively that the name does not exist — and it attached the zone's SOA, whose serial is `2026093002`. Hold on to that number."),
                        LabOption("sudo resolvectl flush-caches",
                                  output: "# caches flushed",
                                  feedback: "This destroys your best evidence before you have read it. A cached record's *remaining* TTL tells you when it was learned, and whether caching can even explain a split team. Flushing also fixes nothing durable: if the authoritative data is wrong, the next lookup re-learns the same wrong answer."),
                        LabOption("echo 198.51.100.40 app.lab.example | sudo tee -a /etc/hosts",
                                  output: "198.51.100.40 app.lab.example",
                                  feedback: "A local override makes one machine work and hides the fault from everyone measuring it — including you. It will also outlive the incident by months and quietly break the day the service moves. Never debug DNS by stepping around it.")
                    ]),
                LabStep(
                    instruction: "The status is `NXDOMAIN`. What does that tell you, as opposed to `SERVFAIL`?",
                    hint: "One of these is an answer. The other is a failure to produce one.",
                    options: [
                        LabOption("NXDOMAIN is an authoritative answer that the name does not exist — the query path worked, so the zone content is the suspect", correct: true,
                                  output: "NXDOMAIN  -> a server holding the zone says: no such name\nSERVFAIL  -> the resolver could not complete the lookup at all\nNOERROR + ANSWER: 0 -> the name exists, but has no record of that type",
                                  feedback: "Correct. NXDOMAIN is a *successful* transaction with a negative result, which is why it is so much more informative than SERVFAIL: resolution, the delegation and at least one authoritative server all worked. Point your next command at the zone."),
                        LabOption("NXDOMAIN means the resolver is broken or unreachable",
                                  output: ";; SERVER: 10.20.9.10#53(10.20.9.10) (UDP)\n;; Query time: 31 msec",
                                  feedback: "The resolver answered in 31 ms and set `ra` (recursion available). A broken or unreachable resolver gives you `SERVFAIL`, a timeout, or `no servers could be reached` — never a crisp NXDOMAIN with the zone's SOA attached."),
                        LabOption("NXDOMAIN means the name exists but has no A record",
                                  output: "# that case is NOERROR with ANSWER: 0 — commonly called NODATA",
                                  feedback: "That case is `NOERROR` with an empty answer section, known as NODATA — it is what you get asking for an A record on a name that only has, say, MX. The distinction matters: NODATA points at a missing record type, NXDOMAIN at a missing name.")
                    ]),
                LabStep(
                    instruction: "The zone is the suspect. How do you find out what it actually says right now?",
                    hint: "Every recursive resolver is a cache. Go to the source, and tell it not to recurse.",
                    options: [
                        LabOption("dig +norecurse @198.51.100.53 app.lab.example A — then the same against 198.51.100.54", correct: true,
                                  output: "$ dig +norecurse @198.51.100.53 app.lab.example A\n;; ->>HEADER<<- status: NOERROR, ANSWER: 1\n;; flags: qr aa\napp.lab.example.     3600   IN  A   198.51.100.40\n\n$ dig +norecurse @198.51.100.54 app.lab.example A\n;; ->>HEADER<<- status: NXDOMAIN, ANSWER: 0, AUTHORITY: 1\n;; flags: qr aa\nlab.example.         3600   IN  SOA ns1.lab.example. hostmaster.lab.example. 2026093002 7200 3600 1209600 3600",
                                  feedback: "Correct, and this is the finding. Both servers set `aa`, so both claim to be authoritative — and they give opposite answers. `ns1` has the record; `ns2` insists the name does not exist. Querying each source directly, with no cache in the way, is the only way to see this."),
                        LabOption("dig @1.1.1.1 app.lab.example A",
                                  output: ";; ->>HEADER<<- status: NXDOMAIN, ANSWER: 0, AUTHORITY: 1\n;; flags: qr rd ra",
                                  feedback: "A second public resolver is a second cache. You learn what *that* cache currently holds, which depends on which authoritative server it happened to ask and when — so it corroborates your symptom while telling you nothing about the zone. Note the missing `aa` flag: this answer is not authoritative."),
                        LabOption("dig +short app.lab.example",
                                  output: "# (no output)",
                                  feedback: "`+short` throws away the header, the flags, the TTLs and the AUTHORITY section — every field you have been using to reason. It is a scripting convenience, not a diagnostic. Empty output here is indistinguishable from NXDOMAIN, NODATA and SERVFAIL.")
                    ]),
                LabStep(
                    instruction: "Two authoritative servers disagree. What does that mean?",
                    hint: "Both set `aa`. Neither is a cache. So what makes one of them wrong?",
                    options: [
                        LabOption("The secondary never received the updated zone — this is a propagation problem, so compare the SOA serials", correct: true,
                                  output: "# ns1: has app.lab.example -> newer zone\n# ns2: NXDOMAIN + SOA serial 2026093002 -> older zone",
                                  feedback: "Correct. A secondary serves a copy of the zone it transferred from the primary; if that transfer never happens it keeps answering authoritatively from yesterday's data — not forever, but until the SOA **expire** timer runs out, at which point it stops answering for the zone entirely. That is the `1209600` in the SOA you are about to read: 14 days of confidently serving stale data before it gives up. The serial is the version number — go and read both."),
                        LabOption("A cache somewhere is still stale",
                                  output: ";; flags: qr aa   <-- authoritative, not cached",
                                  feedback: "Both replies carry the `aa` flag and were obtained with `+norecurse` straight from the authoritative servers, so no cache was involved in either. Caching is a real DNS failure family — it is just definitively not this one."),
                        LabOption("The record was entered incorrectly on the primary",
                                  output: "app.lab.example.  3600  IN  A  198.51.100.40   <-- from ns1, exactly as intended",
                                  feedback: "The primary holds precisely the record you meant to create. A record-content fault would show a *wrong* value on the authoritative source, not a correct value on one server and a missing name on the other.")
                    ]),
                LabStep(
                    instruction: "Confirm the version gap.",
                    hint: "The SOA record carries the zone's serial. Ask both servers for it.",
                    options: [
                        LabOption("dig +noall +answer +norecurse @198.51.100.53 lab.example SOA — then against 198.51.100.54", correct: true,
                                  output: "$ dig +noall +answer +norecurse @198.51.100.53 lab.example SOA\nlab.example.   3600  IN  SOA  ns1.lab.example. hostmaster.lab.example. 2026100101 7200 3600 1209600 3600\n\n$ dig +noall +answer +norecurse @198.51.100.54 lab.example SOA\nlab.example.   3600  IN  SOA  ns1.lab.example. hostmaster.lab.example. 2026093002 7200 3600 1209600 3600",
                                  feedback: "Confirmed: `2026100101` on the primary against `2026093002` on the secondary — the secondary is a day behind and has not transferred since. And this serial was already sitting in the AUTHORITY section of your very first `dig`; reading full output would have put you here in one command."),
                        LabOption("dig +norecurse @198.51.100.54 lab.example AXFR",
                                  output: "; Transfer failed.",
                                  feedback: "A full zone transfer from an arbitrary client is refused by any sanely configured server — as it should be, since an open AXFR hands an attacker your entire internal naming. And you do not need the whole zone to compare one version number."),
                        LabOption("dig +norecurse @198.51.100.54 lab.example ANY",
                                  output: ";; ->>HEADER<<- status: NOERROR, ANSWER: 2\nlab.example.  3600  IN  NS  ns1.lab.example.\nlab.example.  3600  IN  NS  ns2.lab.example.\n# the NS set at the apex — but no SOA, so no serial to compare",
                                  feedback: "`ANY` is the one query whose answer depends on **which server you asked** rather than on the zone. Many resolvers and public authoritative services minimise it to a single record set (RFC 8482), because open `ANY` is a DNS amplification vector — while a stock BIND authoritative server does not minimise by default (`minimal-any` is off) and would hand back more. A diagnostic whose output varies with the implementation cannot tell you whether *this* zone is stale. Ask for the record type you actually want: `SOA`."),
                    ]),
                LabStep(
                    instruction: "Why did the secondary never transfer? You have the primary's config.",
                    hint: "A secondary can only pull a zone the primary is willing to hand it.",
                    options: [
                        LabOption("Check allow-transfer on the primary — the secondary is being refused the zone transfer", correct: true,
                                  output: "# /etc/bind/named.conf.local  (primary, ns1)\nzone lab.example {\n    type primary;\n    file /var/lib/bind/db.lab.example;\n    allow-transfer { 198.51.100.55; };   # <-- ns2 is .54, not .55\n};",
                                  feedback: "There it is — a one-digit typo in the transfer ACL. `ns2` has been refused every refresh since the zone was built, so it has only ever served the copy it was seeded with. Nothing about the record, the resolver or the delegation was ever wrong."),
                        LabOption("Lower the A record's TTL to 60 and wait",
                                  output: "# TTL reduced; ns2 still answers NXDOMAIN",
                                  feedback: "TTL governs how long *caches* may keep an answer; it has no bearing on whether a secondary ever receives the zone. A shorter TTL here just makes clients ask more often — and half of those questions still land on a server with yesterday's data."),
                        LabOption("Delete the record from the secondary and let it resync",
                                  output: "# hand-editing a secondary zone file",
                                  feedback: "A secondary's zone file is replaced wholesale by the next successful transfer, so hand-edits are either overwritten or — worse — persist and leave the two servers differently wrong. Fix the replication, never the replica.")
                    ]),
                LabStep(
                    instruction: "Fix it and verify.",
                    hint: "Correct the ACL, reload the primary, then re-ask the one question that exposed the gap.",
                    options: [
                        LabOption("Correct allow-transfer to 198.51.100.54, rndc reconfig on the primary, then rndc retransfer on the secondary", correct: true,
                                  output: "# on ns1 — reconfig re-reads named.conf without touching loaded zone data\n$ sudo rndc reconfig\n\n# on ns2, force the transfer now rather than waiting for refresh\n$ sudo rndc retransfer lab.example\n\n$ dig +noall +answer +norecurse @198.51.100.54 lab.example SOA\nlab.example.   3600  IN  SOA  ns1.lab.example. hostmaster.lab.example. 2026100101 7200 3600 1209600 3600\n\n$ dig +noall +answer +norecurse @198.51.100.54 app.lab.example A\napp.lab.example.  3600  IN  A  198.51.100.40",
                                  feedback: "Correct. On the command choice: **either** works here — `rndc reload` re-reads `named.conf` *and* reloads zone files, while `rndc reconfig` re-reads the config and loads only newly-added zones. Since you changed an option rather than zone data, `reconfig` is the lighter touch, but `reload` would have picked it up too. The serials now match and `ns2` serves the record. The remaining split clears as the negative cache entries expire, and you can say exactly how long that takes: it is the last field of the SOA."),
                        LabOption("Lower the A record TTL to 60 so clients pick up the change faster",
                                  output: "# clients re-query sooner; ns2 still answers NXDOMAIN",
                                  feedback: "This treats a propagation fault as a caching one. Clients will now ask more frequently, and roughly half of those queries still reach a server that denies the name exists — you have made the flapping faster, not the answer right."),
                        LabOption("Remove ns2 from the delegation at the parent zone",
                                  output: "# lab.example now delegated to ns1 only",
                                  feedback: "This genuinely stops the wrong answers, which is why people reach for it under pressure — but it leaves the zone with a single nameserver and the broken transfer still in place. Acceptable only as a deliberate, time-boxed mitigation that you write down and reverse.")
                    ])
            ]),

        // MARK: 5 — Wi-Fi: association versus lease (intermediate)

        InteractiveLab(
            id: "lab-net-wifi-dhcp",
            title: "Wi-Fi: Association Versus Lease",
            goal: "Separate the radio link from the DHCP exchange, and read each one's own evidence instead of guessing.",
            track: .networking,
            difficulty: .intermediate,
            minutes: 7,
            scenario: "You are testing a new access point in your own home lab — SSID `LAB-WIFI`, WPA2-PSK, the AP's LAN is `192.168.50.0/24`. A laptop will not get onto it. You have a shell on the laptop and physical access to the AP.",
            debrief: "“Joining Wi-Fi” is at least four separate things stacked on top of each other: the AP must be on the air, the client must authenticate and associate, the WPA handshake must derive keys, and only then does DHCP run. Each stage leaves its own evidence, and each one's failure is cured by a different action — which is why “it will not connect” is not a diagnosis.\n\nTwo discriminations did the work. First, *association succeeded and the 4-way handshake failed* is the fingerprint of a wrong PSK specifically. MAC filtering rejects you earlier, at association, with an `ASSOC-REJECT`; a WPA3-only AP never gets that far either. The log distinguishes them for free if you read where in the sequence it stopped.\n\nSecond, a packet capture that shows your DISCOVER broadcasts leaving and nothing coming back localises the fault to the server side of the bridge. That inference is sound because `tcpdump` taps the device layer — *before* the host's own firewall sees inbound packets. If a local filter were eating the offers, you would still have captured them. Knowing where your tools sit in the stack is what lets you turn a capture into a conclusion.\n\nFor a defender, this is also the anatomy of an evil twin: an attacker's AP will happily complete association and hand you a lease. The fact that you got an address proves nothing about who gave it to you.",
            tools: ["iw", "wpa_supplicant", "ip", "tcpdump"],
            relatedLessonID: "net-wifi",
            steps: [
                LabStep(
                    instruction: "The laptop will not connect. First command?",
                    hint: "Before anything else, establish that the AP is actually transmitting and that this radio can hear it.",
                    options: [
                        LabOption("sudo iw dev wlan0 scan | grep -E 'SSID|signal'", correct: true,
                                  output: "        signal: -54.00 dBm\n        SSID: LAB-WIFI\n        signal: -81.00 dBm\n        SSID: NEIGHBOUR-2G\n        signal: -67.00 dBm\n        SSID: LAB-WIFI",
                                  feedback: "Correct. `LAB-WIFI` is on the air and audible twice (both bands) at a healthy -54 dBm. You have established the physical layer in one command — and ruled out the mundane causes, a powered-off AP and a client out of range."),
                        LabOption("ping 192.168.50.1",
                                  output: "ping: connect: Network is unreachable",
                                  feedback: "There is no link yet, so there is nothing to ping over. This is the most common wrong first move in wireless troubleshooting: it presumes association, addressing and routing all succeeded, which is exactly what is in question."),
                        LabOption("sudo dhclient -v wlan0",
                                  output: "DHCPDISCOVER on wlan0 to 255.255.255.255 port 67 interval 5\nDHCPDISCOVER on wlan0 to 255.255.255.255 port 67 interval 11\nNo DHCPOFFERS received.",
                                  feedback: "You asked for a lease before establishing a link, so this failure was guaranteed and is uninformative — and it is actively misleading, because the identical output appears later in this lab when the link *is* up and the cause is completely different.")
                    ]),
                LabStep(
                    instruction: "The AP is audible. You trigger a connection attempt. What do you read?",
                    hint: "The supplicant narrates every stage of the join. Read the sequence, not just the end state.",
                    options: [
                        LabOption("sudo journalctl -u wpa_supplicant -n 15 --no-pager", correct: true,
                                  output: "wlan0: SME: Trying to authenticate with 04:18:d6:9a:11:c0 (SSID='LAB-WIFI' freq=2412 MHz)\nwlan0: Trying to associate with 04:18:d6:9a:11:c0 (SSID='LAB-WIFI' freq=2412 MHz)\nwlan0: Associated with 04:18:d6:9a:11:c0\nwlan0: WPA: 4-Way Handshake failed - pre-shared key may be incorrect\nwlan0: CTRL-EVENT-SSID-TEMP-DISABLED id=0 ssid=LAB-WIFI auth_failures=1 duration=10 reason=WRONG_KEY\nwlan0: CTRL-EVENT-DISCONNECTED bssid=04:18:d6:9a:11:c0 reason=3 locally_generated=1",
                                  feedback: "Correct, and the sequence is the diagnosis. Authenticate — succeeded. Associate — succeeded. 4-way handshake — failed. The log tells you not just that it failed but exactly how far it got, which is what narrows the cause to one candidate."),
                        LabOption("iwconfig wlan0",
                                  output: "wlan0     IEEE 802.11  ESSID:off/any\n          Mode:Managed  Access Point: Not-Associated   Tx-Power=22 dBm",
                                  feedback: "This shows the current state — not associated — which you already knew from the symptom. It is also the deprecated tooling, and critically it has no history: it cannot tell you *where* in the join sequence the attempt died."),
                        LabOption("ip -4 addr show wlan0",
                                  output: "3: wlan0: <BROADCAST,MULTICAST> mtu 1500 qdisc noqueue state DOWN group default qlen 1000",
                                  feedback: "An addressing question asked while the link state is still unknown. The interface is `DOWN` with no address, which is the expected consequence of a failed join rather than a cause — you are one rung too high.")
                    ]),
                LabStep(
                    instruction: "Associate succeeded, then the 4-way handshake failed with `reason=WRONG_KEY`. Which cause fits?",
                    hint: "Each candidate fails at a *different* point in the join sequence. Match the candidate to where this one stopped.",
                    options: [
                        LabOption("The PSK is wrong — authentication and association both completed, so only the key derivation failed", correct: true,
                                  output: "wlan0: Associated with 04:18:d6:9a:11:c0        <-- got this far\nwlan0: WPA: 4-Way Handshake failed            <-- died here",
                                  feedback: "Correct. The 4-way handshake is where both sides prove they hold the same pre-shared key; a mismatch cannot be detected before it, and nothing after it has been attempted. `reason=WRONG_KEY` is the supplicant stating this directly."),
                        LabOption("MAC filtering on the AP is rejecting this client",
                                  output: "# a MAC filter denial looks like:\nwlan0: CTRL-EVENT-ASSOC-REJECT status_code=1",
                                  feedback: "A MAC filter rejects you earlier, at the association stage, with an `ASSOC-REJECT` — you would never see `Associated with`. (hostapd denies a filtered MAC with status 1, *unspecified failure*; 12 also appears. Status **17** is a different thing entirely: the AP is at capacity and out of association IDs.) Plausible as a cause of “will not connect”, but the log already rules it out by showing association completing."),
                        LabOption("The AP is WPA3-only and this client offered WPA2",
                                  output: "# an AKM mismatch looks like:\nwlan0: CTRL-EVENT-NETWORK-NOT-FOUND  (no suitable network)",
                                  feedback: "A key-management mismatch is settled during the scan and association, so the client reports no suitable network rather than associating and then failing a WPA2 handshake. Right family of problem, wrong stage of the sequence.")
                    ]),
                LabStep(
                    instruction: "Correct PSK entered; the link associates and stays up. Next rung?",
                    hint: "The link is proven. Move exactly one step up — do not skip to the internet.",
                    options: [
                        LabOption("ip -4 addr show wlan0", correct: true,
                                  output: "3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000\n    inet 169.254.112.6/16 brd 169.254.255.255 scope link wlan0\n       valid_lft forever preferred_lft forever",
                                  feedback: "Correct — and `169.254.112.6` with `scope link` is a specific, unmistakable fingerprint. That is a self-assigned link-local address, which a host only takes when no DHCP server ever answered. The radio is fine; the lease is not."),
                        LabOption("ping -c 2 1.1.1.1",
                                  output: "ping: connect: Network is unreachable",
                                  feedback: "Two rungs skipped at once. The error is a local routing failure, which is consistent with no address, no gateway, a wrong mask or several other things — so it narrows nothing. Confirm the address before you test what the address can reach."),
                        LabOption("dig +short lab.example",
                                  output: ";; no servers could be reached",
                                  feedback: "Name resolution needs an address, a route and a reachable resolver, none of which you have established. It is the last thing to test and the first thing people reach for, because it is what the user complained about.")
                    ]),
                LabStep(
                    instruction: "A link-local address means no lease. Watch the exchange itself.",
                    hint: "Capture the DHCP ports on the wireless interface and see which direction the traffic flows.",
                    options: [
                        LabOption("sudo tcpdump -i wlan0 -n -e 'port 67 or port 68'", correct: true,
                                  output: "14:08:11.402118 9c:b6:d0:1e:22:af > ff:ff:ff:ff:ff:ff, ethertype IPv4 (0x0800), length 342: 0.0.0.0.68 > 255.255.255.255.67: BOOTP/DHCP, Request from 9c:b6:d0:1e:22:af, length 300\n14:08:16.518904 9c:b6:d0:1e:22:af > ff:ff:ff:ff:ff:ff, ethertype IPv4 (0x0800), length 342: 0.0.0.0.68 > 255.255.255.255.67: BOOTP/DHCP, Request from 9c:b6:d0:1e:22:af, length 300\n14:08:24.771230 9c:b6:d0:1e:22:af > ff:ff:ff:ff:ff:ff, ethertype IPv4 (0x0800), length 342: 0.0.0.0.68 > 255.255.255.255.67: BOOTP/DHCP, Request from 9c:b6:d0:1e:22:af, length 300",
                                  feedback: "Correct. Broadcasts are leaving with a backing-off retry interval and absolutely nothing is coming back. (`BOOTP/DHCP, Request` is the BOOTP operation field — add `-v` and you will see the DHCP message type itself, `Discover`, from option 53.) The client is doing its job."),
                        LabOption("sudo systemctl restart wpa_supplicant",
                                  output: "wlan0: Associated with 04:18:d6:9a:11:c0\nwlan0: WPA: Key negotiation completed",
                                  feedback: "You have restarted the one layer you already proved healthy, and the log confirms it comes back up exactly as before. Re-fixing a working rung is how a twenty-minute problem becomes a two-hour one."),
                        LabOption("sudo ip addr add 192.168.50.20/24 dev wlan0",
                                  output: "$ ping -c 1 192.168.50.1\n64 bytes from 192.168.50.1: icmp_seq=1 ttl=64 time=3.11 ms",
                                  feedback: "This may well get you online, and that is precisely the danger: it hides a DHCP fault that will hit every other device on the AP, and a hand-picked address can collide with the pool later. A workaround applied before the diagnosis usually prevents the diagnosis.")
                    ]),
                LabStep(
                    instruction: "DISCOVERs leave, nothing returns. Which conclusion does the capture support?",
                    hint: "Think about where in the stack `tcpdump` taps, and therefore what its silence does and does not rule out.",
                    options: [
                        LabOption("The fault is on the server side of the bridge — the AP's DHCP service is off or exhausted, or it bridges to a segment with no DHCP server or relay", correct: true,
                                  output: "# client: transmitting broadcasts, correct ports, backing off normally\n# wire:   zero inbound DHCP frames",
                                  feedback: "Correct. The client is confirmed to be on the air and broadcasting properly, so the missing half of the conversation is upstream of it. On the AP you would now check that the DHCP server is enabled, that the pool is not exhausted, and which VLAN the SSID bridges to."),
                        LabOption("The PSK is still wrong",
                                  output: "wlan0: WPA: Key negotiation completed   <-- handshake succeeded",
                                  feedback: "A wrong key means no usable link, and therefore no frames on the wire at all. You captured the client's own broadcasts being transmitted, which can only happen after key negotiation completed — this is already ruled out twice over."),
                        LabOption("The laptop's local firewall is dropping the DHCP offers",
                                  output: "# tcpdump taps the device layer, BEFORE the host firewall sees inbound packets",
                                  feedback: "A sharp guess that the tool itself disproves. `tcpdump` attaches at the device layer, so an offer dropped later by the host firewall would still have been captured. Zero inbound frames means nothing arrived on the wire, not that something ate it afterwards.")
                    ])
            ]),

        // MARK: 6 — Read a capture, name the failing layer (intermediate)

        InteractiveLab(
            id: "lab-net-pcap-layer",
            title: "Read a Capture, Name the Failing Layer",
            goal: "Use a packet excerpt to say which layers are proven healthy and which is the lowest one still failing.",
            track: .networking,
            difficulty: .intermediate,
            minutes: 7,
            scenario: "In your own lab, a client at `10.60.2.15` cannot load an internal app at `10.60.9.40:443`. The two segments sit either side of a Linux firewall you administer — `eth1` faces the clients, `eth2` faces the app. You have captures available on the client, the server and the firewall.",
            debrief: "A capture is powerful because it turns “it does not work” into a statement about *layers*. Reading the first excerpt bottom-up: ARP resolved, so layer 2 is healthy. An IP datagram was emitted with a sane 5-tuple, so the client's layer 3 is healthy. A SYN was retransmitted with no SYN-ACK and no RST, so **transport** is the lowest unproven layer — and everything above it is simply not in evidence yet. There is no DNS in the capture and no TLS ClientHello, so neither can be blamed.\n\nThe second big idea is **silence versus refusal**. A `Flags [R.]` means something actively said no: a closed port, or a REJECT rule. Total silence across retransmissions means a DROP, a black hole, or a path that never carried the packet. They feel similar and they point at different fixes.\n\nThen the sequencing trap. `ping` and `traceroute` ride different protocols and ports from the traffic you care about, so a policy that permits ICMP and denies TCP/443 draws you a perfect path to a destination you cannot reach. Probing with the wrong 5-tuple is not a slightly weaker test — it is a test of a different question, and it will answer confidently.\n\nAn attacker uses the same asymmetry deliberately, tunnelling over whatever the policy happens to permit. The defender who captures on both sides of a control, and who always probes with the real 5-tuple, is the one who notices.",
            tools: ["tcpdump", "nmap", "openssl"],
            relatedLessonID: "net-packets-layers",
            steps: [
                LabStep(
                    instruction: "Here is the capture from the client. Which layers are proven healthy, and which is the lowest one still failing?",
                    hint: "Work bottom-up through the excerpt. Every frame present proves something; anything absent from the capture cannot be blamed.",
                    options: [
                        LabOption("Layer 2 and the client's layer 3 are proven; transport is the lowest unproven layer — a SYN with no SYN-ACK and no RST", correct: true,
                                  output: "16:11:02.118422 ARP, Request who-has 10.60.2.1 tell 10.60.2.15, length 28\n16:11:02.118901 ARP, Reply 10.60.2.1 is-at 52:54:00:8c:1d:77, length 28\n16:11:02.119488 IP 10.60.2.15.44218 > 10.60.9.40.443: Flags [S], seq 1992847110, win 64240, options [mss 1460,sackOK,TS val 882114 ecr 0,nop,wscale 7], length 0\n16:11:03.141077 IP 10.60.2.15.44218 > 10.60.9.40.443: Flags [S], seq 1992847110, win 64240, length 0\n16:11:05.161930 IP 10.60.2.15.44218 > 10.60.9.40.443: Flags [S], seq 1992847110, win 64240, length 0",
                                  feedback: "Correct. ARP resolved the gateway, so layer 2 works. An IP datagram left with the right source, destination and port, so the client's layer 3 works. The TCP handshake never completes — that is the lowest rung still in question, and it bounds everything above it."),
                        LabOption("DNS is failing — the client cannot resolve the app's name",
                                  output: "# the capture contains no port 53 traffic at all",
                                  feedback: "There is not a single DNS packet in the excerpt, and the client is connecting to a literal address. Blaming a system that does not appear in your evidence is the most common way a capture gets misread — if it is not in the frames, it is not your fault candidate."),
                        LabOption("TLS is failing — the handshake to 443 is not completing",
                                  output: "# no ClientHello is present: TLS has no connection to run over",
                                  feedback: "Port 443 implies TLS, but TLS runs *inside* an established TCP connection and no connection exists. The absence of a ClientHello is a consequence of the transport failure, not an independent fault. Port numbers suggest layers; they do not prove them.")
                    ]),
                LabStep(
                    instruction: "The SYN is retransmitted and nothing comes back at all. What does that silence mean, as opposed to an `[R.]`?",
                    hint: "Compare what a DROP looks like on the wire with what a REJECT or a closed port looks like.",
                    options: [
                        LabOption("Silence points at a filter DROPping the packet or a black-holed path; an [R.] would mean something actively refused it", correct: true,
                                  output: "no reply at all  -> DROP rule, or the packet never arrived\nFlags [R.]       -> active refusal: nothing listening, or a REJECT rule\nICMP unreachable -> a router could not deliver it",
                                  feedback: "Correct, and this is the single most useful distinction in TCP troubleshooting. A closed port on a reachable host answers with a reset almost instantly. Silence across three retransmissions means the packet is being discarded without comment, somewhere you have not yet identified."),
                        LabOption("No response means the destination host is down",
                                  output: "# a dead host usually draws an ICMP host-unreachable from its last router — absent here",
                                  feedback: "A genuinely dead host normally has the last router on the path return ICMP host-unreachable, which `tcpdump` would show. Pure silence is the fingerprint of a deliberate drop, which is a very different thing to fix."),
                        LabOption("The MTU is too large and the packets are being black-holed",
                                  output: "# the SYN is: length 0  (a 74-byte frame)",
                                  feedback: "A real and commonly misdiagnosed problem, but not this one: a SYN carries no payload, so it fits any MTU. An MTU black hole lets the handshake complete and *then* stalls once large data frames flow — the opposite shape to what you are seeing.")
                    ]),
                LabStep(
                    instruction: "Something is dropping it. Narrow down where, starting at the far end.",
                    hint: "Capture at the destination at the same time. Whether the packet arrives at all splits the problem in half.",
                    options: [
                        LabOption("On 10.60.9.40: sudo tcpdump -i any -n 'tcp port 443 and host 10.60.2.15'", correct: true,
                                  output: "tcpdump: data link type LINUX_SLL2\nlistening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes\n\n0 packets captured\n0 packets received by filter\n0 packets dropped by kernel",
                                  feedback: "Correct — and `0 packets captured` is a decisive result. Nothing reaches the server at all, so neither the server's socket nor the server's firewall can be responsible. The drop is somewhere on the path, which is a much smaller search space."),
                        LabOption("nmap -Pn -p 443 10.60.9.40",
                                  output: "PORT    STATE    SERVICE\n443/tcp filtered https",
                                  feedback: "`filtered` is nmap restating exactly what your capture already showed — a SYN with no answer. Same probe, same source, same result, no new information about *where*. A second opinion from the same vantage point is not a second measurement."),
                        LabOption("openssl s_client -connect 10.60.9.40:443",
                                  output: "connect:errno=110\nconnect: Connection timed out",
                                  feedback: "You have reached for a layer-6 tool while transport is unproven, so all it can report is the transport failure you already have. Working down from the application layer wastes the most time precisely when the fault is lowest.")
                    ]),
                LabStep(
                    instruction: "Nothing reaches the server. Walk the path toward the firewall.",
                    hint: "Capture on both sides of the device in the middle. The side the packet does *not* come out of is your answer.",
                    options: [
                        LabOption("On the firewall: sudo tcpdump -i eth1 -n 'tcp port 443 and host 10.60.2.15' — then repeat on eth2", correct: true,
                                  output: "# eth1 (client side)\n16:14:22.880114 IP 10.60.2.15.44402 > 10.60.9.40.443: Flags [S], seq 3391028471, win 64240, length 0\n16:14:23.902550 IP 10.60.2.15.44402 > 10.60.9.40.443: Flags [S], seq 3391028471, win 64240, length 0\n\n# eth2 (app side)\n0 packets captured",
                                  feedback: "Correct, and this is the whole diagnosis in two captures. The packets arrive on the inside interface and never leave the outside one, so the firewall is consuming them. Capturing either side of a device is the cleanest way to attribute a drop to it."),
                        LabOption("traceroute 10.60.9.40",
                                  output: "traceroute to 10.60.9.40 (10.60.9.40), 30 hops max, 60 byte packets\n 1  10.60.2.1  0.688 ms  0.641 ms  0.702 ms\n 2  10.60.9.40  1.204 ms  1.188 ms  1.230 ms",
                                  feedback: "A perfect path to a destination you cannot reach — the classic false negative. Default traceroute uses UDP probes on high ports, a completely different 5-tuple from TCP/443, so a policy that permits one and denies the other draws you a clean map and a wrong conclusion."),
                        LabOption("ping -c 3 10.60.9.40",
                                  output: "64 bytes from 10.60.9.40: icmp_seq=1 ttl=63 time=1.09 ms\n64 bytes from 10.60.9.40: icmp_seq=2 ttl=63 time=1.02 ms\n64 bytes from 10.60.9.40: icmp_seq=3 ttl=63 time=1.11 ms",
                                  feedback: "Same false negative, cheaper. ICMP is reaching the host and coming back, which proves layers 1 to 3 along the path and says nothing whatsoever about TCP/443. The reachability a probe demonstrates is only ever the reachability of that probe.")
                    ]),
                LabStep(
                    instruction: "State the finding. Which layer is failing, and what kind of control is responsible?",
                    hint: "Name the lowest layer the evidence actually implicates — no higher, no lower.",
                    options: [
                        LabOption("Layers 1 to 3 are healthy end to end; the failure is a layer-3/4 policy decision — a filter silently dropping TCP/443 between the segments", correct: true,
                                  output: "# proven: ARP, IP delivery, ICMP round-trip across both segments\n# failing: TCP/443 forwarding, inside the firewall",
                                  feedback: "Correct, and note how tightly the claim is bounded: a specific protocol and port, dropped by a specific device, with captures on both interfaces as evidence. That is a finding someone can act on — and it hands you the next lab, which is why the rule did not match."),
                        LabOption("Layer 2 is failing between the two segments",
                                  output: "ARP, Reply 10.60.2.1 is-at 52:54:00:8c:1d:77",
                                  feedback: "ARP resolved on the client side and ICMP crossed both segments successfully, so layer 2 is demonstrably working. Also worth remembering: the two segments are separate broadcast domains, so no single layer-2 path spans them anyway."),
                        LabOption("Layer 7 is failing — the application is not responding",
                                  output: "# zero packets ever reached the application host",
                                  feedback: "Not a single frame reached the server, so the application has had no opportunity to respond or fail. You cannot attribute a fault to a layer that never received any data — and this is the misdiagnosis that sends tickets to the wrong team.")
                    ]),
            ]),

        // MARK: 7 — NAT problem or routing problem? (advanced)

        InteractiveLab(
            id: "lab-net-nat-or-routing",
            title: "NAT Problem or Routing Problem?",
            goal: "Use rule counters and a two-sided capture to tell a translation failure from a missing return path.",
            track: .networking,
            difficulty: .advanced,
            minutes: 8,
            scenario: "Your lab has a Linux router with `eth0` on the test WAN `192.0.2.0/24` (`192.0.2.1`) and `eth1` on the internal `10.50.1.0/24` (`10.50.1.1`). Outbound masquerading works — internal hosts reach the WAN fine. You published a web app with a port forward from `192.0.2.1:8080` to `10.50.1.80:80`, and from a WAN host `192.0.2.50` it times out. By design, back-end hosts on `10.50.1.0/24` have **no default route**: they are reachable only from their own segment.",
            debrief: "The discriminator between NAT and routing is a question about *reach and return*. A NAT fault means the translation did not happen, happened wrongly, or expired — the packet never arrives, or arrives with the wrong addresses. A routing fault means it arrived correctly and the reply has nowhere to go. They present identically from the client: a timeout.\n\nTwo cheap measurements separated them. The PREROUTING rule's **packet counter was incrementing**, which proves the DNAT matched — a single number that eliminates the entire NAT hypothesis in one command. Then the inside capture showed the correctly translated SYN delivered to the server. At that point the only remaining possibility is the return path.\n\nNotice the trap in the middle: `nmap` from the router succeeded, because the router's own source address is on the server's segment and therefore needs no return route. A probe whose source address differs from the real traffic's tests a different path. When you are debugging asymmetric reachability, the source address is part of the test.\n\nThe fix is full NAT rather than giving the server a default route — because the segment's design is that back-end hosts are not routable. That is a real security posture, and the right repair preserves it instead of quietly dismantling it. The attacker's view is the mirror image: a back-end host with no route out cannot be made to beacon to the internet, which is exactly why that design exists.",
            tools: ["iptables", "tcpdump", "ip", "curl"],
            relatedLessonID: "net-nat",
            steps: [
                LabStep(
                    instruction: "`curl http://192.0.2.1:8080` from `192.0.2.50` times out. What first?",
                    hint: "Before you touch any rule, establish whether the traffic is even arriving at the router.",
                    options: [
                        LabOption("On the router: sudo tcpdump -i eth0 -n 'tcp port 8080'", correct: true,
                                  output: "15:02:11.004812 IP 192.0.2.50.51422 > 192.0.2.1.8080: Flags [S], seq 2847119204, win 64240, options [mss 1460,sackOK,TS val 318402 ecr 0,nop,wscale 7], length 0\n15:02:12.021144 IP 192.0.2.50.51422 > 192.0.2.1.8080: Flags [S], seq 2847119204, win 64240, length 0\n15:02:14.041977 IP 192.0.2.50.51422 > 192.0.2.1.8080: Flags [S], seq 2847119204, win 64240, length 0",
                                  feedback: "Correct. SYNs are arriving on the WAN interface and nothing is going back. You have established that the WAN path and the client are fine, so the fault is inside your router or beyond it — and you have changed nothing."),
                        LabOption("sudo iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to 10.50.1.80:80",
                                  output: "# rule appended (a matching rule already existed)",
                                  feedback: "You have added a rule before checking whether one exists, so the chain now holds two — and the second will never be evaluated. Adding configuration before measuring is how a one-fault problem becomes a two-fault problem."),
                        LabOption("From an internal host: curl http://10.50.1.80/",
                                  output: "<html><title>Lab App</title>...",
                                  feedback: "This proves the web server is alive, which is worth knowing but was never in doubt from the symptom. It exercises none of the WAN path, none of the translation and none of the return path — every part that could actually be broken.")
                    ]),
                LabStep(
                    instruction: "SYNs arrive at the router. Is the translation happening?",
                    hint: "Rules carry packet counters. A counter answers “did this rule match?” with no inference at all.",
                    options: [
                        LabOption("sudo iptables -t nat -L PREROUTING -n -v --line-numbers", correct: true,
                                  output: "Chain PREROUTING (policy ACCEPT 1482 packets, 98K bytes)\nnum   pkts bytes target     prot opt in     out     source               destination\n1       18  1080 DNAT       tcp  --  eth0   *       0.0.0.0/0            192.0.2.1            tcp dpt:8080 to:10.50.1.80:80",
                                  feedback: "Correct, and `pkts 18` is the measurement that matters: the rule exists and it is matching. One number has just eliminated the entire “NAT is broken” hypothesis. Counters are the ground truth of any ruleset — read them before you read the rules."),
                        LabOption("sudo iptables -L -n -v",
                                  output: "Chain INPUT (policy DROP 0 packets, 0 bytes)\nChain FORWARD (policy ACCEPT 142301 packets, 61M bytes)\nChain OUTPUT (policy ACCEPT 90412 packets, 12M bytes)",
                                  feedback: "This lists the `filter` table, which holds no NAT rules at all. Seeing nothing about your port forward here invites exactly the wrong conclusion — that no rule exists. NAT lives in its own table and you must ask for it with `-t nat`."),
                        LabOption("sudo systemctl restart nftables",
                                  output: "# ruleset reloaded; all counters now zero",
                                  feedback: "A reload re-applies the same configuration and zeroes every counter — the evidence you were about to read. Restarting a component is the one action guaranteed to destroy the history that would have told you whether it was working.")
                    ]),
                LabStep(
                    instruction: "The DNAT is matching. Is the translated packet reaching the server, and is the server answering?",
                    hint: "Capture on the inside interface, filtered to the translated 5-tuple.",
                    options: [
                        LabOption("sudo tcpdump -i eth1 -n 'tcp port 80 and host 10.50.1.80'", correct: true,
                                  output: "15:02:11.005101 IP 192.0.2.50.51422 > 10.50.1.80.80: Flags [S], seq 2847119204, win 64240, length 0\n15:02:12.021502 IP 192.0.2.50.51422 > 10.50.1.80.80: Flags [S], seq 2847119204, win 64240, length 0",
                                  feedback: "Correct, and look closely at the source address: still `192.0.2.50`. The destination was translated and the source was not, which is normal for a plain DNAT — and it means the server must route its reply back to a WAN address. No SYN-ACK is coming back."),
                        LabOption("From the router: nmap -p 80 10.50.1.80",
                                  output: "PORT   STATE SERVICE\n80/tcp open  http",
                                  feedback: "It succeeds, and that is exactly why it is dangerous. The router's own source address is `10.50.1.1` — on the server's segment — so the reply needs no route at all. A probe whose source differs from the real traffic tests a different path and will confidently reassure you."),
                        LabOption("sudo conntrack -L | grep 8080",
                                  output: "tcp 6 118 SYN_SENT src=192.0.2.50 dst=192.0.2.1 sport=51422 dport=8080 [UNREPLIED] src=10.50.1.80 dst=192.0.2.50 sport=80 dport=51422 mark=0 use=1",
                                  feedback: "Genuinely useful — `[UNREPLIED]` confirms the flow is tracked and translated but never answered, which agrees with everything else. It is still inference about the packet rather than the packet itself, though, and at this point you want to see the frame the server received.")
                    ]),
                LabStep(
                    instruction: "On the server, `tcpdump` shows the SYN arriving and no SYN-ACK emitted. The socket is listening. What single check settles filter versus routing?",
                    hint: "Ask the server's kernel whether it can even build a route back to that source address.",
                    options: [
                        LabOption("On 10.50.1.80: ip route get 192.0.2.50", correct: true,
                                  output: "RTNETLINK answers: Network is unreachable",
                                  feedback: "Correct and decisive. The kernel cannot construct a reply route to `192.0.2.50`, so the SYN-ACK is never emitted. An INPUT DROP would look identical on the wire, which is exactly why you ask this first: one non-destructive command, an unambiguous answer, no ruleset to read."),
                        LabOption("sudo iptables -F && retry the request",
                                  output: "# all filter rules flushed",
                                  feedback: "This changes many things at once, on a host whose security posture you have just dismantled, to test one hypothesis. Even if it worked you would not know which rule mattered — and on a server you do not own it is simply not yours to do."),
                        LabOption("Add MASQUERADE on the router's forward path and see if it fixes it",
                                  output: "# rule added before the cause is known",
                                  feedback: "This is very likely the correct *fix*, applied before you have earned it. Fix-by-experiment leaves you unable to say what was wrong, which matters when the same symptom returns on a host where the real cause is different.")
                    ]),
                LabStep(
                    instruction: "Name it. Is this a NAT problem or a routing problem?",
                    hint: "Match each hypothesis against the evidence you now hold, and see which one survives all of it.",
                    options: [
                        LabOption("A routing problem — the DNAT matched and delivered correctly; what is missing is a return path from the server to 192.0.2.0/24", correct: true,
                                  output: "# DNAT counter incrementing      -> translation works\n# translated SYN seen on eth1     -> delivery works\n# ip route get -> unreachable      -> return path missing",
                                  feedback: "Correct. Three measurements, and only one hypothesis survives all three. Naming the family matters because it selects the fix: a translation fault would be repaired in the NAT table, while a return-path fault is repaired by changing either the routing or the source address the server sees."),
                        LabOption("A NAT problem — the port forward is not translating",
                                  output: "pkts 18 ... DNAT tcp dpt:8080 to:10.50.1.80:80\n15:02:11.005101 IP 192.0.2.50.51422 > 10.50.1.80.80: Flags [S]",
                                  feedback: "The counter and the inside capture both contradict this. The translation is demonstrably happening and the rewritten packet is demonstrably being delivered — this is the hypothesis you spent two steps eliminating."),
                        LabOption("A firewall problem — something is dropping the SYN-ACK",
                                  output: "# there is no SYN-ACK to drop: the server never emitted one",
                                  feedback: "There is no SYN-ACK anywhere in the evidence, so nothing can be dropping it. `ip route get` showed the kernel unable to build a reply route, which happens before any output filtering is consulted.")
                    ]),
                LabStep(
                    instruction: "Fix it. Remember the design: back-end hosts deliberately have no default route.",
                    hint: "If the server may only answer hosts on its own segment, make the traffic appear to come from its own segment.",
                    options: [
                        LabOption("sudo iptables -t nat -A POSTROUTING -o eth1 -p tcp -d 10.50.1.80 --dport 80 -j SNAT --to-source 10.50.1.1", correct: true,
                                  output: "$ curl -s -o /dev/null -w '%{http_code}\\n' http://192.0.2.1:8080\n200\n\n# on eth1, the SYN now reads:\nIP 10.50.1.1.51422 > 10.50.1.80.80: Flags [S], ...\nIP 10.50.1.80.80 > 10.50.1.1.51422: Flags [S.], ...",
                                  feedback: "Correct. Translating the source as well as the destination — full NAT — means the server only ever sees an on-link peer and replies directly to the router, which undoes the translation on the way back. The design holds: the back-end still has no route off its segment."),
                        LabOption("On 10.50.1.80: sudo ip route add default via 10.50.1.1",
                                  output: "$ curl -s -o /dev/null -w '%{http_code}\\n' http://192.0.2.1:8080\n200",
                                  feedback: "It works, and it quietly deletes the control you were given. The segment's stated design is that back-end hosts are not routable off-segment — that is what stops a compromised app server from reaching the internet. Never repair a symptom by removing a deliberate restriction."),
                        LabOption("sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8080 -j DNAT --to 10.50.1.80:80",
                                  output: "# a second, identical DNAT rule appended; symptom unchanged",
                                  feedback: "This duplicates a rule whose counter you already watched incrementing. The first match terminates evaluation, so the new rule is dead configuration — and next quarter someone will spend an hour working out why there are two.")
                    ])
            ]),

        // MARK: 8 — Why the firewall rule is not matching (advanced)

        InteractiveLab(
            id: "lab-net-firewall-nomatch",
            title: "Why the Firewall Rule Is Not Matching",
            goal: "Use counters and chain order to find out why a correct-looking rule never sees the traffic it was written for.",
            track: .networking,
            difficulty: .advanced,
            minutes: 8,
            scenario: "Same lab firewall as before: `eth1` faces the clients on `10.60.2.0/24`, `eth2` faces the app segment `10.60.9.0/24`, and a third segment `10.60.3.0/24` hangs off `eth3`. You have already proven that TCP/443 from `10.60.2.15` to `10.60.9.40` is being dropped here. You added a rule to permit exactly that, and it changed nothing.",
            debrief: "A rule that does not match is almost never a rule with the wrong *contents*. It is a rule in the wrong place, in the wrong chain, or behind something broader — and a packet counter tells you which in one command. `pkts 0` on a rule that should be matching is the whole diagnosis: it is not being reached, so look at what is above it.\n\nThree mechanisms came up and all three are everyday faults. **Order** — iptables evaluates top-down and stops at the first terminating match, so a broad DROP above a specific ACCEPT makes the ACCEPT dead configuration. **Scope** — `-s 10.60.2.0/24 -i eth1` plainly does not cover a client on another segment arriving on another interface, however correct the rule looks. **Chain** — forwarded traffic traverses FORWARD and never touches INPUT, so an identical rule in INPUT is a no-op for routed packets. INPUT is only for traffic addressed to the firewall itself.\n\nTwo habits generalise. Resist the fix that widens: deleting the broad DROP, dropping the interface match, or inserting a wildcard ACCEPT at position 1 all make the symptom vanish while demolishing the default-deny design — and they are seductive precisely because they work. And trust conntrack for return traffic: a single `ESTABLISHED,RELATED` accept is what keeps a stateful ruleset small, where a mirror rule permitting anything claiming source port 443 is a stateless hole an attacker can walk through.\n\nFor an attacker, a misordered ruleset is a gift, and so is one that has been widened under pressure. Every emergency `-I FORWARD 1` is a hole that outlives the incident.",
            tools: ["iptables", "ip", "tcpdump"],
            relatedLessonID: "net-firewall-vpn",
            steps: [
                LabStep(
                    instruction: "You added the ACCEPT rule and nothing changed. First move?",
                    hint: "Read the whole chain in evaluation order, with counters. Do not add anything yet.",
                    options: [
                        LabOption("sudo iptables -L FORWARD -n -v --line-numbers", correct: true,
                                  output: "Chain FORWARD (policy DROP 0 packets, 0 bytes)\nnum   pkts bytes target     prot opt in     out     source               destination\n1     9842 1240K ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED\n2      184 11040 DROP       tcp  --  eth1   eth2    10.60.2.0/24         10.60.9.0/24\n3        0     0 ACCEPT     tcp  --  eth1   eth2    10.60.2.0/24         10.60.9.40           tcp dpt:443",
                                  feedback: "Correct, and the two counters tell the whole story. Your rule at position 3 has matched `0` packets, while the DROP at position 2 is at `184` and climbing. The rule is not wrong — it is never being reached."),
                        LabOption("sudo iptables -I FORWARD 1 -p tcp --dport 443 -j ACCEPT",
                                  output: "# inserted at the top; the client now connects",
                                  feedback: "It works instantly, which is the problem. You have permitted TCP/443 from anywhere to anywhere across this firewall, learned nothing about the original fault, and left a hole that will long outlive the ticket. The fix that works fastest is often the one that costs most."),
                        LabOption("sudo systemctl restart nftables",
                                  output: "# ruleset reloaded; all counters zeroed",
                                  feedback: "A reload re-applies the same rules and wipes every counter. Those counters were about to tell you, with no inference required, which rule is handling the traffic — and you cannot get them back without reproducing the fault.")
                    ]),
                LabStep(
                    instruction: "Your rule shows `pkts 0`. Why?",
                    hint: "How does iptables evaluate a chain, and what happens when a packet matches a terminating target?",
                    options: [
                        LabOption("The chain is evaluated top-down and stops at the first terminating match — the broader DROP at position 2 matches the same traffic first", correct: true,
                                  output: "packet: 10.60.2.15:* -> 10.60.9.40:443, in eth1, out eth2\n  rule 1  ctstate RELATED,ESTABLISHED  -> no match (this is a new SYN)\n  rule 2  10.60.2.0/24 -> 10.60.9.0/24 -> MATCH, target DROP, evaluation ends\n  rule 3  never evaluated",
                                  feedback: "Correct. `10.60.9.40` is inside `10.60.9.0/24`, so rule 2 matches your traffic and DROP terminates evaluation. Rule 3 is unreachable configuration. A zero counter never means “wrong rule” — it means “not reached”, and the chain above it says why."),
                        LabOption("The rule's syntax is wrong",
                                  output: "3  0  0  ACCEPT  tcp  --  eth1  eth2  10.60.2.0/24  10.60.9.40  tcp dpt:443",
                                  feedback: "The listing shows the rule exactly as intended — protocol, both interfaces, source, destination, port. A malformed rule would have been rejected at insertion time, not accepted and listed. When the rule reads correctly and matches nothing, the question is about position."),
                        LabOption("The chain's default policy DROP is what blocks it",
                                  output: "Chain FORWARD (policy DROP 0 packets, 0 bytes)",
                                  feedback: "The policy counter is `0 packets`: nothing has reached the end of the chain. A policy only applies to packets that fall through every rule, and these are being consumed at rule 2. Reading the chain header's counters alongside the rules' saves you this mistake.")
                    ]),
                LabStep(
                    instruction: "Fix the ordering without weakening the design.",
                    hint: "The specific permit has to be evaluated before the broad deny. Put it there explicitly.",
                    options: [
                        LabOption("sudo iptables -I FORWARD 2 -i eth1 -o eth2 -s 10.60.2.0/24 -d 10.60.9.40 -p tcp --dport 443 -j ACCEPT — then delete the unreachable duplicate", correct: true,
                                  output: "Chain FORWARD (policy DROP 0 packets, 0 bytes)\nnum   pkts bytes target     prot opt in     out     source               destination\n1     9961 1301K ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED\n2        6   360 ACCEPT     tcp  --  eth1   eth2    10.60.2.0/24         10.60.9.40           tcp dpt:443\n3      184 11040 DROP       tcp  --  eth1   eth2    10.60.2.0/24         10.60.9.0/24",
                                  feedback: "Correct — the specific exception now sits above the broad deny, and its counter is moving. Note that cleaning up the orphaned rule is part of the fix: a ruleset nobody can read is a ruleset nobody will maintain safely."),
                        LabOption("sudo iptables -D FORWARD 2",
                                  output: "# the broad DROP is gone; all traffic from 10.60.2.0/24 to 10.60.9.0/24 now passes",
                                  feedback: "This permits the entire client segment to reach the entire app segment on every port. You have not fixed a default-deny design, you have deleted the deny — and the one rule that documented the intended boundary has gone with it."),
                        LabOption("sudo iptables -A FORWARD -i eth1 -o eth2 -s 10.60.2.0/24 -d 10.60.9.40 -p tcp --dport 443 -j ACCEPT",
                                  output: "4  0  0  ACCEPT  tcp  --  eth1  eth2  10.60.2.0/24  10.60.9.40  tcp dpt:443",
                                  feedback: "`-A` appends, so the rule lands *after* the DROP again — the exact mistake you have just spent two steps diagnosing, with a fresh zero counter to prove it. `-A` and `-I` differ by position, and position is the whole problem here."),
                    ]),
                LabStep(
                    instruction: "The client connects. Does the return traffic need its own rule?",
                    hint: "Look at what rule 1 matches on.",
                    options: [
                        LabOption("No — rule 1 accepts RELATED,ESTABLISHED, so conntrack lets the SYN-ACK and the rest of the flow back", correct: true,
                                  output: "1  9961  1301K  ACCEPT  all  --  *  *  0.0.0.0/0  0.0.0.0/0  ctstate RELATED,ESTABLISHED",
                                  feedback: "Correct. Connection tracking recognises the reply as belonging to a flow you already permitted, so one rule at the top of the chain covers the return direction for every permitted service. That is what keeps a stateful ruleset small and readable."),
                        LabOption("Yes — add a mirror ACCEPT for traffic with source port 443",
                                  output: "# ACCEPT tcp -- eth2 eth1 10.60.9.40 10.60.2.0/24 tcp spt:443",
                                  feedback: "It would work, and it is a stateless hole: any packet *claiming* source port 443 is now permitted inbound, including unsolicited ones crafted to look like replies. This is the modern form of the old “allow high ports” mistake, and conntrack exists precisely so you do not need it."),
                        LabOption("No — firewalls only filter inbound traffic anyway",
                                  output: "# FORWARD sees both directions of every routed flow",
                                  feedback: "FORWARD is traversed by routed packets in both directions, so replies are absolutely filtered here. The right answer is right for the wrong reason, and the wrong reason will bite you the first time you write an egress policy.")
                    ]),
                LabStep(
                    instruction: "A client at `10.60.3.9` still fails. Your ACCEPT reads `-i eth1 -s 10.60.2.0/24`. Next action?",
                    hint: "Find out which interface that segment actually arrives on before you edit anything.",
                    options: [
                        LabOption("On the firewall: ip route get 10.60.3.9", correct: true,
                                  output: "10.60.3.9 dev eth3 src 10.60.3.1 uid 0\n    cache",
                                  feedback: "Correct. That segment lives on `eth3`, so your rule excludes the new client twice over — wrong source range *and* wrong ingress interface. Establish the real values, then write a second specific rule for that segment rather than loosening the first."),
                        LabOption("Widen the rule to -s 10.60.0.0/16 and drop the -i match",
                                  output: "# ACCEPT tcp -- * eth2 10.60.0.0/16 10.60.9.40 tcp dpt:443",
                                  feedback: "It would fix both clients and sixty thousand others. Dropping the interface match is the worse half: a rule that no longer cares which interface traffic arrives on can be satisfied by a spoofed source from any segment, including an untrusted one."),
                        LabOption("The rule is fine — 10.60.3.9 must have an unrelated fault",
                                  output: "ACCEPT  tcp  --  eth1  eth2  10.60.2.0/24  10.60.9.40  tcp dpt:443",
                                  feedback: "The rule is printed in front of you and `10.60.2.0/24` plainly does not contain `10.60.3.9`. Reaching for a second, unknown fault when the listed configuration already explains the symptom is how hours disappear.")
                    ]),
                LabStep(
                    instruction: "A colleague adds an identical ACCEPT to the INPUT chain and reports it has no effect. Why?",
                    hint: "Which chain does a routed packet actually traverse?",
                    options: [
                        LabOption("Forwarded traffic never traverses INPUT — routed packets go PREROUTING, FORWARD, POSTROUTING; INPUT is only for traffic addressed to the firewall itself", correct: true,
                                  output: "client -> app:   PREROUTING -> [routing] -> FORWARD -> POSTROUTING\nclient -> firewall: PREROUTING -> [routing] -> INPUT",
                                  feedback: "Correct. The routing decision picks the chain: packets destined for the box go to INPUT, packets being routed through it go to FORWARD. A rule in the wrong chain is not weak or misordered — it is simply never consulted."),
                        LabOption("INPUT rules apply to everything arriving on any interface",
                                  output: "# INPUT is selected only for packets whose destination is the firewall itself",
                                  feedback: "This is the most common misconception about netfilter, and it is worth naming out loud. “Inbound” is not a chain: INPUT means *locally destined*. Traffic merely passing through arrives on an interface and still never touches INPUT."),
                        LabOption("It also needs a matching rule in OUTPUT",
                                  output: "# OUTPUT handles packets generated BY the firewall",
                                  feedback: "OUTPUT handles traffic the firewall itself originates, so it is no more relevant here than INPUT. Both answers come from imagining the chains as directions rather than as positions in the packet's path through the box.")
                    ])
            ])
    ]
}
