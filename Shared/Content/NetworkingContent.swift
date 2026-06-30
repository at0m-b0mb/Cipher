import Foundation

/// The Networking track — computer networks taught properly, for everyone. It
/// starts from "what even is a network?" and builds, lesson by lesson, to a
/// real working mental model: addresses and names, how a packet finds its way
/// across the world, the protocols behind the apps you use, and how Wi-Fi and
/// the controls that keep it safe actually work. Approachable for total
/// beginners, but accurate enough to stand on for the security tracks.
enum NetworkingContent {

    static let track = Track(
        id: "networking",
        kind: .networking,
        title: "Networking",
        tagline: "How computers really talk — addresses, routing, DNS, Wi-Fi and the protocols that run the internet.",
        modules: [foundations, addressing, routing, protocols, wireless, modern, infra, webtech]
    )

    // MARK: N1 — Networking foundations

    private static let foundations = Module(
        id: "net-foundations",
        title: "Networking Foundations",
        summary: "What a network actually is, and the single most important idea in all of networking: data travels in small, layered packets.",
        systemImage: "globe",
        lessons: [whatIsLesson, packetsLayersLesson]
    )

    private static let whatIsLesson = Lesson(
        id: "net-what-is",
        title: "What Is a Network?",
        subtitle: "From two computers with a cable between them to the entire internet.",
        minutes: 9,
        difficulty: .foundational,
        blocks: [
            .heading("A network is just things that can talk"),
            .paragraph("A **network** is nothing more exotic than two or more devices connected so they can exchange data. Two laptops joined by a cable are a network. Your phone, laptop and TV on the same Wi-Fi are a network. The connected devices are called **nodes**, and the connections between them — cable, fibre or radio — are **links**. Everything else in this track is just detail layered on top of that one idea."),
            .animation(.internetMap, caption: "Follow a single request leave your laptop, cross your home network, your ISP and the internet backbone, and arrive at a server."),
            .heading("Local networks vs the internet"),
            .paragraph("Networks come in sizes. The one in your home or office is a **LAN** (Local Area Network) — a small group of devices in one place, usually behind a single router. When networks in different places are joined across distance, that's a **WAN** (Wide Area Network). The **internet** is the biggest WAN of all: not one giant network, but millions of independent networks agreeing to pass each other's traffic."),
            .keyPoints([
                "Node — any device on the network (laptop, phone, server, printer, router).",
                "Link — the connection between nodes: copper, fibre or wireless radio.",
                "LAN — a Local Area Network: devices in one location, e.g. your home Wi-Fi.",
                "WAN — a Wide Area Network spanning distance; the internet is a WAN of WANs.",
                "ISP — your Internet Service Provider: the company that links your LAN to the internet."
            ]),
            .definition(term: "The internet vs the web", meaning: "The **internet** is the global network of networks — the roads. The **web** (websites you open in a browser) is just one kind of traffic that travels on it, alongside email, video calls, games and app data. The internet is the infrastructure; the web is one service riding on it."),
            .heading("Clients, servers and packets"),
            .paragraph("Most everyday networking follows a **client–server** pattern: your device (the client) asks for something, and another machine (the server) answers. You open a page, the web server sends it back. Crucially, the data doesn't cross as one big lump — it's chopped into small **packets** that travel independently and are reassembled at the other end. That packet idea is so central it gets its own lesson next."),
            .callout(.tip, "Two numbers describe almost any link: **bandwidth** (how much data fits through per second — your “100 Mbps”) and **latency** (how long one packet takes to arrive — the “ping” in a game). A fat pipe with high latency still feels slow; both matter."),
            .checkpoint(QuizQuestion(
                "Your home Wi-Fi with a laptop, phone and TV all connected is best described as a…",
                options: ["WAN", "LAN", "The internet", "An ISP"],
                correct: 1,
                why: "Devices in one location behind one router form a Local Area Network (LAN). A WAN spans distance, and the internet is a global collection of networks reached through your ISP."))
        ],
        quiz: [
            QuizQuestion(
                "What is the difference between the internet and the web?",
                options: [
                    "They are two words for the same thing",
                    "The internet is the global network infrastructure; the web is one service (websites) that runs on it",
                    "The web is faster than the internet",
                    "The internet is only for email"
                ],
                correct: 1,
                why: "The internet is the network of networks — the roads. The web is one kind of traffic on those roads, alongside email, streaming, games and more."),
            QuizQuestion(
                "In a client–server exchange, which device makes the request?",
                options: ["The server", "The client", "The ISP", "The router"],
                correct: 1,
                why: "The client (your device) asks; the server answers. When you open a page, your browser is the client and the web server responds."),
            QuizQuestion(
                "Why is data broken into packets instead of sent as one continuous stream?",
                options: [
                    "To make it bigger",
                    "So pieces can travel independently, take different routes and be reassembled — and a single lost piece can be resent",
                    "Because servers can't read large files",
                    "To encrypt it"
                ],
                correct: 1,
                why: "Packet switching lets small chunks travel independently and share links efficiently; only a lost packet needs resending, not the whole transfer.")
        ]
    )

    private static let packetsLayersLesson = Lesson(
        id: "net-packets-layers",
        title: "Packets & Layers",
        subtitle: "The big idea: data travels in small envelopes, wrapped layer by layer.",
        minutes: 11,
        difficulty: .foundational,
        blocks: [
            .heading("Why layers make networking sane"),
            .paragraph("Networking looks impossibly complicated until you see the trick: it's split into **layers**, each doing one job and trusting the layer beneath it. The app doesn't worry about cables; the cable doesn't worry about websites. The **OSI model** names seven layers; the practical **TCP/IP model** groups them into four. Either way, the point is the same — separate concerns so each problem is solved once."),
            .animation(.osiModel, caption: "Send a message down the stack and watch each layer add its own header, then peel them off in reverse on the far side."),
            .keyPoints([
                "Application — the actual content: a web page, email, message (HTTP, DNS).",
                "Transport — splits data into segments and tracks delivery (TCP, UDP, ports).",
                "Network — addresses and routes packets between networks (IP addresses).",
                "Link — moves frames across one physical hop (Ethernet, Wi-Fi, MAC addresses).",
                "Each layer talks only to the same layer on the other machine — and to its neighbours below and above."
            ]),
            .definition(term: "Encapsulation", meaning: "As data heads down the stack, each layer wraps it in its own header (an envelope with addressing for that layer). Your message becomes a transport segment, inside a network packet, inside a link-layer frame. The receiver unwraps them in reverse — decapsulation."),
            .heading("What's actually inside a packet"),
            .paragraph("A packet on the wire is a stack of nested envelopes. The outer **frame** carries hardware (MAC) addresses for the next hop. Inside it, the **IP packet** carries the source and destination IP addresses for the whole journey. Inside that, the **transport segment** carries port numbers and delivery info. And at the very centre sits your real data — maybe a web request. Network tools like Wireshark let you open every envelope and read it."),
            .animation(.packetTravel, caption: "Peel a real packet apart, header by header — Ethernet, then IP, then TCP, then the payload."),
            .callout(.tip, "A clean mental model: the **IP address** is like the full street address on a parcel — it stays the same all the way to the destination. The **MAC address** is like the instruction “hand it to the next courier” — it changes at every hop. You'll see exactly why in the routing module."),
            .callout(.info, "Anything sent without encryption travels as readable text inside that payload. That's fine on a trusted link, but it's the entire reason HTTPS, Wi-Fi encryption and VPNs exist — topics later in this track."),
            .checkpoint(QuizQuestion(
                "As a message travels down the sending device's stack, what does each layer do to it?",
                options: [
                    "Encrypts it",
                    "Adds its own header, wrapping the data from the layer above (encapsulation)",
                    "Deletes part of it to save space",
                    "Converts it to a different language"
                ],
                correct: 1,
                why: "Each layer encapsulates: it adds its own header around the data handed down from above. The receiver strips those headers off in reverse order."))
        ],
        quiz: [
            QuizQuestion(
                "What is the main benefit of splitting networking into layers?",
                options: [
                    "It makes networks faster",
                    "Each layer solves one problem independently, so changes at one layer don't break the others",
                    "It encrypts the data",
                    "It removes the need for addresses"
                ],
                correct: 1,
                why: "Layering separates concerns — the app doesn't care about cables and the cable doesn't care about apps — so each layer can evolve independently."),
            QuizQuestion(
                "Which layer is responsible for IP addresses and routing packets between networks?",
                options: ["Application", "Transport", "Network", "Link"],
                correct: 2,
                why: "The Network layer handles logical IP addressing and routing between networks. The Link layer handles one physical hop; Transport handles ports and delivery."),
            QuizQuestion(
                "In the parcel analogy, which address stays the same the whole journey?",
                options: ["The MAC address", "The IP address", "Both change every hop", "Neither changes"],
                correct: 1,
                why: "The destination IP is the final street address and stays fixed end to end. The MAC address is the next-hop courier instruction and is rewritten at each hop.")
        ]
    )

    // MARK: N2 — Addresses & names

    private static let addressing = Module(
        id: "net-addressing",
        title: "Addresses & Names",
        summary: "How every device is found — IP and MAC addresses, how subnets carve a network up, and how friendly names become addresses through DNS.",
        systemImage: "number",
        lessons: [ipMacLesson, subnettingLesson, dnsLesson]
    )

    private static let ipMacLesson = Lesson(
        id: "net-ip-mac",
        title: "IP & MAC Addresses",
        subtitle: "The two addresses every device carries — one logical, one physical.",
        minutes: 10,
        difficulty: .foundational,
        blocks: [
            .heading("Two addresses, two jobs"),
            .paragraph("Every networked device carries **two** addresses, and beginners constantly confuse them. The **MAC address** is the permanent hardware ID of the network card, set at the factory. The **IP address** is a logical address assigned by the network you join — and it changes as you move from home Wi-Fi to the café to the office. MAC says *which card*; IP says *where on the network*."),
            .animation(.ipAddressing, caption: "An IPv4 address broken into its four octets and 32 bits — then the hardware MAC that never changes."),
            .heading("Reading an IPv4 address"),
            .paragraph("An **IPv4** address is 32 bits, written as four **octets** (0–255) separated by dots, like `192.168.1.42`. Each octet is just a byte. That gives about 4.3 billion addresses — which the world ran out of, so we also now have **IPv6**, a vastly larger 128-bit space written in hex groups like `2001:db8::7334`."),
            .keyPoints([
                "IPv4 — 32 bits, four dotted octets (192.168.1.42). ~4.3 billion addresses.",
                "IPv6 — 128 bits, eight hex groups (2001:db8::1). Effectively unlimited.",
                "MAC — 48-bit hardware address (a4:83:e7:2b:14:9f), unique per network card.",
                "Public IP — reachable across the internet; you usually have one, shared by your whole home.",
                "Private IP — only valid inside a local network; 192.168.x.x, 10.x.x.x, 172.16–31.x.x."
            ]),
            .definition(term: "Private address ranges", meaning: "Three IPv4 blocks are reserved for private use and are never routed on the public internet: 10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16. Every home and office reuses them internally — which is why you and your neighbour can both be 192.168.1.10 with no conflict. NAT (a later lesson) bridges them to the public internet."),
            .terminal(prompt: "kali@lab",
                      command: "ip addr show eth0",
                      output: """
2: eth0: <BROADCAST,MULTICAST,UP> mtu 1500
    link/ether a4:83:e7:2b:14:9f      <-- MAC (hardware, fixed)
    inet 192.168.1.42/24              <-- IPv4 (assigned by this network)
"""),
            .callout(.tip, "On Windows the equivalent command is `ipconfig /all`; on macOS/Linux try `ip addr` or `ifconfig`. Spotting your own IP, gateway and MAC is step one of understanding any network you're on."),
            .checkpoint(QuizQuestion(
                "You take your laptop from home to a café. Which address changes?",
                options: [
                    "The MAC address",
                    "The IP address",
                    "Both change",
                    "Neither changes"
                ],
                correct: 1,
                why: "The MAC is burned into the network card and stays put. The IP is handed out by whichever network you join, so it changes from home to café to office."))
        ],
        quiz: [
            QuizQuestion(
                "How many bits is an IPv4 address?",
                options: ["8", "32", "48", "128"],
                correct: 1,
                why: "IPv4 is 32 bits — four 8-bit octets. 48 bits is a MAC address; 128 bits is IPv6."),
            QuizQuestion(
                "Which of these is a private IP address?",
                options: ["8.8.8.8", "192.168.1.10", "93.184.216.34", "203.0.113.5"],
                correct: 1,
                why: "192.168.x.x is one of the reserved private ranges, valid only inside a local network. The others are public, internet-routable addresses."),
            QuizQuestion(
                "What is a MAC address used for?",
                options: [
                    "Routing packets across the internet",
                    "Identifying a specific network card for delivery on the local link",
                    "Encrypting traffic",
                    "Naming a website"
                ],
                correct: 1,
                why: "The MAC is a hardware address used to deliver frames to the right card on the local network segment. Internet-wide routing uses IP addresses.")
        ]
    )

    private static let subnettingLesson = Lesson(
        id: "net-subnetting",
        title: "Subnets, Masks & CIDR",
        subtitle: "How one address is split into a network part and a host part.",
        minutes: 11,
        difficulty: .intermediate,
        blocks: [
            .heading("Every IP has two halves"),
            .paragraph("An IP address secretly contains two pieces of information: which **network** you're on, and which **host** (device) you are within it. The **subnet mask** is what draws the line between them. Bits on the network side are shared by everyone in your subnet; bits on the host side are unique to each device. Get this one idea and subnetting stops being scary."),
            .animation(.subnetMask, caption: "Watch the mask slide along the 32 bits, splitting network from host — and the count of usable hosts change with it."),
            .heading("CIDR: the /24 shorthand"),
            .paragraph("Writing masks as `255.255.255.0` is clumsy, so we use **CIDR** notation: a slash and the number of network bits. `192.168.1.42/24` means the first 24 bits are the network (`192.168.1`) and the last 8 are the host (`.42`). A `/24` leaves 8 host bits = 256 addresses, minus 2 reserved (network + broadcast) = **254 usable** hosts."),
            .keyPoints([
                "Subnet mask — marks which bits are network (1s) and which are host (0s).",
                "CIDR /n — shorthand for n network bits; /24 = 255.255.255.0.",
                "Usable hosts = 2^(host bits) − 2 (one address is the network, one the broadcast).",
                "Smaller subnet (e.g. /26) = more networks, fewer hosts each; bigger (/16) = the reverse.",
                "The default gateway is just one host in your subnet — the router's address."
            ]),
            .definition(term: "Network & broadcast addresses", meaning: "In every IPv4 subnet, the first address (all host bits 0) names the network itself and the last (all host bits 1) is the broadcast address that reaches every host at once. Neither can be assigned to a device, which is why you subtract 2 from the total."),
            .terminal(prompt: "kali@lab",
                      command: "ipcalc 192.168.1.42/24",
                      output: """
Address:   192.168.1.42
Netmask:   255.255.255.0 = 24
Network:   192.168.1.0/24
Broadcast: 192.168.1.255
HostMin:   192.168.1.1     HostMax: 192.168.1.254   (254 hosts)
"""),
            .callout(.tip, "Quick check for “are these two IPs on the same network?”: apply the mask to both and compare. 192.168.1.42/24 and 192.168.1.200/24 share `192.168.1` → same subnet, they talk directly. 192.168.2.5/24 is different → it must go via the gateway."),
            .checkpoint(QuizQuestion(
                "How many usable host addresses are in a /24 network?",
                options: ["256", "254", "128", "24"],
                correct: 1,
                why: "A /24 has 8 host bits = 256 total addresses, minus the network and broadcast addresses = 254 usable for devices."))
        ],
        quiz: [
            QuizQuestion(
                "What does the subnet mask determine?",
                options: [
                    "The speed of the network",
                    "Which bits of an IP are the network part and which are the host part",
                    "The MAC address",
                    "The DNS server"
                ],
                correct: 1,
                why: "The mask draws the boundary between network bits (shared by the subnet) and host bits (unique per device)."),
            QuizQuestion(
                "In CIDR, what does the /26 in 10.0.0.0/26 mean?",
                options: [
                    "26 usable hosts",
                    "The first 26 bits are the network portion",
                    "26 networks",
                    "A speed of 26 Mbps"
                ],
                correct: 1,
                why: "The number after the slash is how many leading bits are the network portion. /26 leaves 6 host bits = 62 usable hosts."),
            QuizQuestion(
                "Two hosts are 192.168.1.5/24 and 192.168.2.5/24. Can they talk directly without a router?",
                options: [
                    "Yes, the IPs are almost identical",
                    "No — applying the /24 mask gives different networks (192.168.1 vs 192.168.2), so traffic must go via the gateway",
                    "Yes, because they share the same host number",
                    "Only if they have the same MAC"
                ],
                correct: 1,
                why: "With a /24 mask the third octet is part of the network. 192.168.1 ≠ 192.168.2, so they're on different subnets and must route through the gateway.")
        ]
    )

    private static let dnsLesson = Lesson(
        id: "net-dns",
        title: "DNS — The Internet's Phonebook",
        subtitle: "How a name like shop.com becomes an IP address you can actually reach.",
        minutes: 10,
        difficulty: .foundational,
        blocks: [
            .heading("Names for humans, numbers for machines"),
            .paragraph("You type `shop.com`; your computer needs `93.184.216.34`. **DNS** (the Domain Name System) is the global directory that translates names into IP addresses. It's one of the most important systems on the internet, and almost every connection you make starts with a silent DNS lookup you never see."),
            .animation(.dnsResolution, caption: "A resolver walks the DNS hierarchy — root, then the .com server, then the domain's own server — and caches the answer."),
            .heading("How a lookup works"),
            .paragraph("DNS is a hierarchy, resolved top-down. Your **resolver** (run by your ISP, or a public one like `8.8.8.8`) asks a **root** server, which points to the **TLD** server for `.com`, which points to the **authoritative** server that actually knows `shop.com`'s address. The resolver then **caches** the answer for a while (its TTL) so the next lookup is instant. It feels like one step; it's really a short relay."),
            .keyPoints([
                "Resolver — the server that does the legwork of looking up a name for you.",
                "Root → TLD (.com) → Authoritative — the three tiers of the hierarchy.",
                "Record types — A (IPv4), AAAA (IPv6), MX (mail), CNAME (alias), TXT (text/verification).",
                "TTL — how long an answer may be cached before it must be looked up again.",
                "Public resolvers — 8.8.8.8 (Google), 1.1.1.1 (Cloudflare) are common alternatives to your ISP's."
            ]),
            .terminal(prompt: "kali@lab",
                      command: "dig +short shop.com A",
                      output: """
93.184.216.34
# the A record — the IPv4 address the name resolves to
"""),
            .definition(term: "A record vs CNAME", meaning: "An **A record** maps a name straight to an IPv4 address (AAAA does the same for IPv6). A **CNAME** maps a name to *another name* — an alias — so `www.shop.com` can point at `shop.com` and inherit its address. Follow CNAMEs and you eventually land on an A record."),
            .callout(.tip, "When a website “isn't loading” but the server is fine, DNS is a prime suspect. Testing with `dig`, `nslookup`, or trying a different resolver (1.1.1.1) quickly tells you whether the name is resolving at all."),
            .checkpoint(QuizQuestion(
                "What does a DNS resolver return when you look up a domain name?",
                options: [
                    "The website's HTML",
                    "The IP address the name maps to",
                    "The MAC address of the server",
                    "An encryption key"
                ],
                correct: 1,
                why: "DNS translates a human-friendly name into the IP address your computer needs to actually open a connection. Fetching the page itself comes afterward."))
        ],
        quiz: [
            QuizQuestion(
                "Put the DNS hierarchy in the order a resolver queries it:",
                options: [
                    "Authoritative → TLD → Root",
                    "Root → TLD (.com) → Authoritative",
                    "TLD → Root → Authoritative",
                    "Resolver → MAC → IP"
                ],
                correct: 1,
                why: "A recursive resolver starts at the root, is referred to the TLD server for the domain's suffix, then to the authoritative server that holds the actual record."),
            QuizQuestion(
                "Why does DNS use caching with a TTL?",
                options: [
                    "To encrypt the lookup",
                    "So repeated lookups are answered instantly instead of walking the whole hierarchy every time",
                    "To hide the IP address",
                    "Because names change every second"
                ],
                correct: 1,
                why: "Caching answers for their TTL avoids re-querying the hierarchy for every connection, making the web dramatically faster and lighter on DNS servers."),
            QuizQuestion(
                "Which DNS record type maps a name to an IPv4 address?",
                options: ["MX", "CNAME", "A", "TXT"],
                correct: 2,
                why: "An A record holds an IPv4 address. AAAA is IPv6, MX is mail servers, CNAME is an alias to another name, and TXT holds arbitrary text.")
        ]
    )

    // MARK: N3 — Moving data across networks

    private static let routing = Module(
        id: "net-routing",
        title: "Moving Data Across Networks",
        summary: "How a packet actually finds its way — switches, routers and gateways, hop-by-hop routing, NAT, and how devices get their addresses automatically.",
        systemImage: "arrow.triangle.branch",
        lessons: [switchRouterLesson, routingLesson, natLesson, dhcpLesson, vlanLesson]
    )

    private static let switchRouterLesson = Lesson(
        id: "net-switch-router",
        title: "Switches, Routers & the Default Gateway",
        subtitle: "The two boxes that move your data — and the rule that decides which one to use.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("Switch vs router — one letter, very different jobs"),
            .paragraph("A **switch** connects devices *within* one local network and forwards frames by MAC address — it's the box your home devices hang off (often built into your router). A **router** connects *different* networks together and forwards packets by IP address. Switch = inside the building; router = doorway to other buildings."),
            .animation(.defaultGateway, caption: "A packet to a neighbour stays on the switch; a packet to the internet is handed to the default gateway — the router."),
            .heading("The default gateway"),
            .paragraph("So how does your device decide whether to use the switch or the router? It applies the **subnet mask** from the last module. If the destination is in your subnet, it delivers directly over the local switch. If it's anywhere else, it sends the packet to the **default gateway** — your router's IP — and trusts the router to forward it onward. The gateway is your network's exit door."),
            .keyPoints([
                "Switch — forwards by MAC address within one LAN (Layer 2).",
                "Router — forwards by IP address between networks (Layer 3).",
                "Default gateway — the router IP a device sends all off-subnet traffic to.",
                "Same subnet → deliver directly via the switch; different subnet → send to the gateway.",
                "Your gateway is usually the first usable address, like 192.168.1.1."
            ]),
            .definition(term: "ARP (Address Resolution Protocol)", meaning: "To actually deliver a frame on the local network, a device needs the destination's MAC, not just its IP. ARP is the “who has 192.168.1.1? tell me your MAC” broadcast that fills in that gap. It's how IP addresses get matched to hardware addresses on a LAN."),
            .terminal(prompt: "kali@lab",
                      command: "ip route | grep default",
                      output: """
default via 192.168.1.1 dev eth0
# everything not on my subnet goes to 192.168.1.1 — the gateway
"""),
            .callout(.tip, "“I can reach other devices in my house but not the internet” almost always means the local switch is fine but the **gateway/router** path is broken. “I can't even reach my own printer” points lower down — the switch or cabling."),
            .checkpoint(QuizQuestion(
                "Your device wants to send a packet to an IP outside its own subnet. Where does it send it?",
                options: [
                    "Directly to the destination over the switch",
                    "To the default gateway (the router)",
                    "To the DNS server",
                    "It broadcasts it to everyone"
                ],
                correct: 1,
                why: "Off-subnet traffic goes to the default gateway, which routes it toward the destination. Only same-subnet traffic is delivered directly via the switch."))
        ],
        quiz: [
            QuizQuestion(
                "What does a switch use to forward frames within a local network?",
                options: ["IP addresses", "MAC addresses", "Domain names", "Port numbers"],
                correct: 1,
                why: "A switch operates at Layer 2 and forwards by MAC address. Routers operate at Layer 3 and forward by IP between networks."),
            QuizQuestion(
                "What is the default gateway?",
                options: [
                    "The DNS server",
                    "The router address a device sends all off-subnet traffic to",
                    "The fastest device on the network",
                    "The broadcast address"
                ],
                correct: 1,
                why: "The default gateway is your network's exit — the router IP that handles any traffic destined outside your local subnet."),
            QuizQuestion(
                "What problem does ARP solve?",
                options: [
                    "Translating a domain name to an IP",
                    "Finding the MAC address that goes with a known IP on the local network",
                    "Assigning IP addresses automatically",
                    "Encrypting frames"
                ],
                correct: 1,
                why: "ARP maps a known IP to its hardware MAC address so a frame can actually be delivered on the local link. DNS handles names; DHCP assigns addresses.")
        ]
    )

    private static let routingLesson = Lesson(
        id: "net-routing-traceroute",
        title: "Routing & Traceroute",
        subtitle: "How a packet hops across the world, one router at a time.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("No router knows the whole way"),
            .paragraph("A packet bound for the other side of the planet isn't handed a complete map. Each **router** knows only one thing: the best *next hop* toward a destination. The packet bounces router to router, each making a local decision from its **routing table**, until it arrives. It's a relay of independent handoffs, not a pre-planned route."),
            .animation(.routingHops, caption: "A packet hops from router to router, its TTL ticking down with each hop — exactly what traceroute prints."),
            .heading("TTL and how traceroute sees the path"),
            .paragraph("Every packet carries a **TTL** (Time To Live) counter that each router decreases by one. If it ever hits zero, the packet is dropped and the router sends back an error — a safety valve against packets looping forever. **Traceroute** cleverly abuses this: it sends packets with TTL 1, then 2, then 3… so each dies one hop further along, and every router reveals itself in turn. That's how you get a numbered list of the hops to a destination."),
            .keyPoints([
                "Routing table — each router's list of “to reach network X, send to next-hop Y”.",
                "Next hop — routers only decide the immediate next step, not the full path.",
                "TTL — a hop counter that prevents infinite loops; decremented by every router.",
                "Traceroute — increments TTL to map each hop along the way.",
                "Different packets in the same connection can even take different routes."
            ]),
            .terminal(prompt: "kali@lab",
                      command: "traceroute shop.com",
                      output: """
1  192.168.1.1     1 ms      <-- your gateway
2  10.20.0.1       8 ms      <-- your ISP
3  72.14.5.9      14 ms
4  93.184.216.34  21 ms      <-- destination reached
"""),
            .definition(term: "Hop", meaning: "One step from one router to the next. The number of hops between you and a destination is roughly how many independent networks your traffic crosses. Each hop adds a little latency, which is why far-away servers feel slower."),
            .callout(.tip, "Traceroute is a frontline troubleshooting tool: if the hops climb normally then suddenly stop or time out, the break is at (or just past) the last router that answered. It turns “the internet is down” into “it breaks at hop 4.”"),
            .checkpoint(QuizQuestion(
                "What does each router do to a packet's TTL value?",
                options: [
                    "Doubles it",
                    "Decreases it by one; if it reaches zero the packet is dropped",
                    "Resets it to 64",
                    "Leaves it unchanged"
                ],
                correct: 1,
                why: "Each router decrements the TTL by one. Hitting zero drops the packet and triggers an error reply — the behaviour traceroute exploits to map the path."))
        ],
        quiz: [
            QuizQuestion(
                "How much of the route does an individual router along the path know?",
                options: [
                    "The entire end-to-end path",
                    "Only the best next hop toward the destination",
                    "Nothing — it forwards randomly",
                    "Just the source address"
                ],
                correct: 1,
                why: "Routing is hop-by-hop. Each router consults its table and forwards to the next hop; no single router holds the full path."),
            QuizQuestion(
                "How does traceroute discover each hop?",
                options: [
                    "It asks DNS for the route",
                    "It sends packets with increasing TTL values so each expires one hop further and that router replies",
                    "It reads the routing tables remotely",
                    "It pings the destination repeatedly"
                ],
                correct: 1,
                why: "By starting at TTL 1 and increasing it, each packet dies one hop later, and the expiring router identifies itself — building the hop list."),
            QuizQuestion(
                "Why does a server geographically far away often feel slower?",
                options: [
                    "Its IP address is larger",
                    "More hops and distance add latency to every packet",
                    "DNS is slower for far names",
                    "It uses UDP"
                ],
                correct: 1,
                why: "More hops and longer physical distance increase round-trip latency. Bandwidth may be fine, but each packet simply takes longer to arrive.")
        ]
    )

    private static let natLesson = Lesson(
        id: "net-nat",
        title: "NAT — Sharing One Public IP",
        subtitle: "How a whole house full of devices gets online through a single address.",
        minutes: 9,
        difficulty: .intermediate,
        blocks: [
            .heading("The address shortage, solved"),
            .paragraph("There aren't enough IPv4 addresses for every device on earth, yet your home might have a dozen online at once. The fix is **NAT** (Network Address Translation). Your devices use private addresses internally; your router owns one public address; and it **rewrites** the address (and port) on every outgoing packet so replies find their way back to the right device. One public IP, many private devices."),
            .animation(.natTranslation, caption: "A private device's address and port are rewritten to the router's public address on the way out, and restored on the way back."),
            .heading("How the router keeps everyone straight"),
            .paragraph("When `192.168.1.10` opens a connection, the router records a mapping and stamps the packet with its **public** IP and a unique port. The server only ever sees the public address. When the reply comes back to that port, the router looks up its **translation table** and forwards it to the right private device. Multiplexing many internal conversations onto one public address by port is technically called PAT, but everyone just says NAT."),
            .keyPoints([
                "Private devices → one shared public IP, managed by the router.",
                "The router rewrites source IP+port outbound and reverses it inbound.",
                "A translation table tracks which private device owns each connection.",
                "NAT incidentally hides internal devices — they aren't directly reachable from outside.",
                "Port forwarding is how you deliberately poke a hole inward (e.g. to host a game server)."
            ]),
            .definition(term: "Port forwarding", meaning: "Because NAT blocks unsolicited inbound connections, a device inside can't normally be reached from the internet. Port forwarding is a manual router rule — “send anything arriving on public port 25565 to 192.168.1.10” — that opens a specific path inward, commonly used to self-host a server."),
            .callout(.warning, "NAT is a side-effect privacy/safety benefit, not a real firewall. It hides internal devices but doesn't inspect or filter malicious traffic on connections you *do* open. You still need an actual firewall — a later lesson."),
            .checkpoint(QuizQuestion(
                "With NAT, what does an external web server see as the source of your traffic?",
                options: [
                    "Your device's private IP (192.168.1.10)",
                    "Your router's single public IP",
                    "Your MAC address",
                    "Your DNS server"
                ],
                correct: 1,
                why: "NAT rewrites the source to the router's public IP, so the server only ever sees that one address — never your internal private IP."))
        ],
        quiz: [
            QuizQuestion(
                "What core problem does NAT solve?",
                options: [
                    "Slow DNS lookups",
                    "Letting many devices share a single public IPv4 address",
                    "Encrypting traffic",
                    "Finding MAC addresses"
                ],
                correct: 1,
                why: "NAT lets a whole private network share one scarce public IPv4 address by translating addresses and ports at the router."),
            QuizQuestion(
                "How does the router know which private device a returning packet belongs to?",
                options: [
                    "It guesses",
                    "It consults its translation table mapping public ports back to private device+port",
                    "By the MAC address in the packet",
                    "It broadcasts to all devices"
                ],
                correct: 1,
                why: "The router keeps a translation table. Each outbound connection gets a unique public port, so replies to that port map cleanly back to the right private device."),
            QuizQuestion(
                "Why might you set up port forwarding?",
                options: [
                    "To speed up your Wi-Fi",
                    "To allow an inbound connection from the internet to reach a specific internal device",
                    "To change your DNS server",
                    "To assign IP addresses"
                ],
                correct: 1,
                why: "NAT blocks unsolicited inbound connections; port forwarding deliberately opens a path to one internal device, e.g. to host a game or web server.")
        ]
    )

    private static let dhcpLesson = Lesson(
        id: "net-dhcp",
        title: "DHCP — Getting an Address Automatically",
        subtitle: "Why you never have to type in an IP address to join Wi-Fi.",
        minutes: 8,
        difficulty: .foundational,
        blocks: [
            .heading("Who hands out the addresses?"),
            .paragraph("When you join a network, your device just *works* — it gets an IP, a gateway and DNS servers without you typing anything. That magic is **DHCP** (Dynamic Host Configuration Protocol). A DHCP server (usually built into your router) leases out addresses from a pool and hands new devices everything they need to start talking."),
            .animation(.dhcpLease, caption: "The four-step DORA exchange — Discover, Offer, Request, Acknowledge — that leases a new device its address."),
            .heading("DORA: four messages to get online"),
            .paragraph("The handshake has four steps, remembered as **DORA**. The new device **Discovers** by broadcasting “is there a DHCP server?”. The server **Offers** an available address. The device formally **Requests** that offer. The server **Acknowledges**, and the lease is set — bundled with the gateway, subnet mask and DNS servers. It's a short, reliable negotiation that happens in a blink every time you connect."),
            .keyPoints([
                "Discover — new device broadcasts looking for a DHCP server.",
                "Offer — server proposes an available IP from its pool.",
                "Request — device accepts that specific offer.",
                "Acknowledge — server confirms; the lease (with gateway + DNS) is active.",
                "Lease — the address is borrowed for a time, then renewed or returned to the pool."
            ]),
            .definition(term: "Static vs dynamic IP", meaning: "DHCP gives a **dynamic** address that can change over time. Servers, printers and other always-on devices often get a **static** address instead — either configured by hand or pinned in the router (a DHCP reservation) — so their address never moves and other devices can rely on it."),
            .callout(.tip, "If a device shows an address starting with `169.254.x.x`, it never heard back from a DHCP server and self-assigned a link-local address. That's a classic “DHCP isn't working” fingerprint — check the router or the cable."),
            .checkpoint(QuizQuestion(
                "What does a device get from DHCP besides an IP address?",
                options: [
                    "Only the IP address",
                    "The default gateway and DNS servers too",
                    "A MAC address",
                    "A public domain name"
                ],
                correct: 1,
                why: "A DHCP lease bundles the essentials: the IP, subnet mask, default gateway, and DNS servers — everything the device needs to actually use the network."))
        ],
        quiz: [
            QuizQuestion(
                "What do the four steps of DHCP (DORA) stand for?",
                options: [
                    "Detect, Open, Route, Accept",
                    "Discover, Offer, Request, Acknowledge",
                    "Deliver, Order, Resolve, Answer",
                    "Discover, Open, Reply, Allocate"
                ],
                correct: 1,
                why: "DORA = Discover, Offer, Request, Acknowledge — the four-message exchange that leases a device its address and settings."),
            QuizQuestion(
                "A device shows an IP of 169.254.10.5. What most likely happened?",
                options: [
                    "It got a normal lease",
                    "It couldn't reach a DHCP server and self-assigned a link-local address",
                    "It was assigned a public IP",
                    "Its MAC address changed"
                ],
                correct: 1,
                why: "169.254.x.x is APIPA / link-local — a self-assigned address used when no DHCP server responds. It signals a DHCP or connectivity failure."),
            QuizQuestion(
                "Why might a printer be given a static IP instead of a DHCP-assigned one?",
                options: [
                    "Static IPs are faster",
                    "So its address never changes and other devices can reliably find it",
                    "Printers can't use DHCP",
                    "To hide it from the network"
                ],
                correct: 1,
                why: "A fixed address means dependents (computers, print servers) always know where to reach it, unlike a dynamic lease that could change.")
        ]
    )

    // MARK: N4 — Protocols you use daily

    private static let protocols = Module(
        id: "net-protocols",
        title: "Protocols You Use Daily",
        summary: "The transport choices and application protocols behind every app — TCP vs UDP, ports, and the handful of protocols that carry the web, mail and remote access.",
        systemImage: "rectangle.connected.to.line.below",
        lessons: [tcpUdpLesson, appProtocolsLesson]
    )

    private static let tcpUdpLesson = Lesson(
        id: "net-tcp-udp",
        title: "TCP vs UDP",
        subtitle: "Reliable and ordered, or fast and lightweight — two ways to send data.",
        minutes: 9,
        difficulty: .intermediate,
        blocks: [
            .heading("Two transports, two trade-offs"),
            .paragraph("At the transport layer you get a choice. **TCP** is the careful courier: it sets up a connection, numbers every segment, waits for acknowledgements, retransmits anything lost and delivers in order. **UDP** is the postcard: it just fires packets off with no setup, no acknowledgements and no reordering. TCP trades speed for reliability; UDP trades reliability for speed."),
            .animation(.tcpVsUdp, caption: "TCP acknowledges and reorders every segment; UDP fires packets off and never looks back — a lost one is simply gone."),
            .heading("When each one wins"),
            .paragraph("Use **TCP** when every byte must arrive correctly and in order: web pages, file downloads, email. Use **UDP** when speed matters more than perfection and a lost packet is better skipped than re-sent late: live video, voice calls, online games, and DNS lookups. A stutter in a call is fine; a frozen download is not."),
            .keyPoints([
                "TCP — connection-oriented, reliable, ordered, with acknowledgements and retransmission.",
                "UDP — connectionless, best-effort, no ordering or retransmission, very low overhead.",
                "TCP starts with the 3-way handshake (SYN, SYN-ACK, ACK); UDP just sends.",
                "TCP: web, file transfer, email. UDP: video/voice, gaming, DNS.",
                "Both use port numbers to identify the right service on a host."
            ]),
            .definition(term: "Port", meaning: "A 16-bit number (0–65535) that identifies a specific service on a device, so one IP can run many at once. The IP gets you to the machine; the port gets you to the right program — web on 80/443, SSH on 22. Ports belong to the transport layer, shared by both TCP and UDP."),
            .callout(.tip, "A real-time video call dropping a frame and carrying on is UDP doing its job. If it used TCP, the call would freeze every time it stopped to re-request a lost packet — by the time it arrived, the moment would be gone."),
            .checkpoint(QuizQuestion(
                "A live voice call drops a tiny bit of audio but keeps going smoothly. Which transport protocol is it most likely using?",
                options: ["TCP", "UDP", "DNS", "ARP"],
                correct: 1,
                why: "Real-time audio favours UDP: it's better to skip a lost packet and stay live than to freeze the call waiting for a retransmission, which TCP would do."))
        ],
        quiz: [
            QuizQuestion(
                "Which protocol guarantees that data arrives complete and in order?",
                options: ["UDP", "TCP", "Both equally", "Neither"],
                correct: 1,
                why: "TCP numbers segments, acknowledges them and retransmits losses, delivering an ordered, complete stream. UDP makes no such guarantees."),
            QuizQuestion(
                "Why is UDP preferred for online gaming and live video?",
                options: [
                    "It encrypts the data",
                    "Its low overhead and no-retransmission behaviour keep latency low; a stale packet isn't worth resending",
                    "It guarantees delivery",
                    "It uses domain names instead of IPs"
                ],
                correct: 1,
                why: "For real-time data, speed beats perfection. UDP skips setup and retransmission, so a lost packet is simply dropped rather than delaying everything."),
            QuizQuestion(
                "What is the role of a port number?",
                options: [
                    "To identify the device on the internet",
                    "To identify which service/program on a host the traffic is for",
                    "To encrypt the connection",
                    "To set the packet's TTL"
                ],
                correct: 1,
                why: "The IP address locates the machine; the port number selects which service on it (web, SSH, mail) the traffic should reach.")
        ]
    )

    private static let appProtocolsLesson = Lesson(
        id: "net-app-protocols",
        title: "The Protocols Behind the Apps",
        subtitle: "HTTP, HTTPS, email and remote access — and the ports they ride on.",
        minutes: 10,
        difficulty: .foundational,
        blocks: [
            .heading("Every app speaks a protocol"),
            .paragraph("When you open a website, send an email or remote into a server, your app is speaking a specific **application protocol** over TCP or UDP. Learning the common ones — and the well-known **ports** they use — is like learning the main roads of a city. You'll recognise instantly what a connection is for just from its port number."),
            .animation(.httpRequest, caption: "A browser sends an HTTP request, the server replies and sets a cookie, and the browser proves its identity on the next request."),
            .heading("HTTP and the lock icon"),
            .paragraph("The web runs on **HTTP**: your browser sends a request (a method, a path, headers) and the server returns a response (a status code, headers, content). On its own, HTTP is plain text — anyone in the middle can read it. **HTTPS** is the same protocol wrapped in **TLS** encryption, which is what the padlock in your address bar means: the conversation is private and the server's identity is verified."),
            .keyPoints([
                "HTTP (80) / HTTPS (443) — the web; HTTPS adds TLS encryption.",
                "DNS (53) — name-to-IP lookups (mostly UDP).",
                "SSH (22) — secure encrypted remote shell and file transfer.",
                "SMTP (25) sends mail; IMAP (143) / POP3 (110) retrieve it.",
                "FTP (21) and Telnet (23) are legacy and unencrypted — avoid them; use SFTP/SSH instead."
            ]),
            .terminal(prompt: "kali@lab",
                      command: "curl -I https://shop.com",
                      output: """
HTTP/2 200
server: nginx
content-type: text/html; charset=UTF-8
strict-transport-security: max-age=31536000
"""),
            .definition(term: "Well-known ports", meaning: "Ports 0–1023 are reserved for standard services so clients know where to connect without being told: 80 for HTTP, 443 for HTTPS, 22 for SSH, 53 for DNS. Memorising a handful makes reading network traffic and firewall rules far faster."),
            .callout(.warning, "Plain HTTP, FTP and Telnet send everything — including passwords — as readable text. On any network you don't fully trust, that's an open door. Their encrypted replacements (HTTPS, SFTP, SSH) exist for exactly this reason."),
            .checkpoint(QuizQuestion(
                "What does the padlock / HTTPS in your browser actually provide?",
                options: [
                    "A faster connection",
                    "TLS encryption of the traffic plus verification of the server's identity",
                    "A guarantee the site is trustworthy and honest",
                    "A different IP address"
                ],
                correct: 1,
                why: "HTTPS is HTTP over TLS: it encrypts the connection and verifies the server's certificate. It secures the channel — it does not vouch that the site's owner is honest."))
        ],
        quiz: [
            QuizQuestion(
                "Which port does HTTPS use by default?",
                options: ["80", "22", "443", "53"],
                correct: 2,
                why: "HTTPS defaults to TCP 443. Port 80 is plain HTTP, 22 is SSH, and 53 is DNS."),
            QuizQuestion(
                "What is the main difference between HTTP and HTTPS?",
                options: [
                    "HTTPS is a completely different protocol",
                    "HTTPS is HTTP wrapped in TLS encryption, protecting and authenticating the connection",
                    "HTTP is newer",
                    "HTTPS doesn't use ports"
                ],
                correct: 1,
                why: "HTTPS is the same HTTP, carried inside a TLS-encrypted, authenticated channel — which is what the browser padlock represents."),
            QuizQuestion(
                "Why should you avoid Telnet and plain FTP on an untrusted network?",
                options: [
                    "They are too slow",
                    "They transmit data and credentials in plaintext, so anyone in the middle can read them",
                    "They only work on Windows",
                    "They use too many ports"
                ],
                correct: 1,
                why: "Telnet and FTP have no encryption — credentials cross the wire as readable text. SSH and SFTP replaced them precisely to fix that.")
        ]
    )

    // MARK: N5 — Wireless & network security

    private static let wireless = Module(
        id: "net-wireless",
        title: "Wireless & Network Security",
        summary: "How Wi-Fi actually connects you, and the everyday controls — firewalls and VPNs — that keep a network safe.",
        systemImage: "wifi",
        lessons: [wifiLesson, firewallVpnLesson]
    )

    private static let wifiLesson = Lesson(
        id: "net-wifi",
        title: "Wi-Fi & Wireless Networks",
        subtitle: "What really happens between “select network” and “connected”.",
        minutes: 9,
        difficulty: .foundational,
        blocks: [
            .heading("Networking over the air"),
            .paragraph("**Wi-Fi** is just networking where the link is radio instead of a cable. An **access point** (AP) broadcasts a network name — the **SSID** — and devices within range associate with it. Everything you've learned still applies: once connected, your device gets an IP via DHCP, uses a gateway, and sends the very same packets. Only the first hop changed from copper to radio."),
            .animation(.wifiConnect, caption: "Scan for the SSID, authenticate with the WPA2 passphrase, associate — and the phone is on the network."),
            .heading("Joining a network, step by step"),
            .paragraph("Connecting is a short sequence: your device **scans** the airwaves and lists nearby SSIDs; you pick one and **authenticate** (typically with a WPA2/WPA3 passphrase); the device **associates** with the AP; and finally DHCP leases it an address. Wireless also juggles **channels** and **bands** (2.4 GHz reaches further; 5/6 GHz is faster but shorter-range) to reduce interference between nearby networks."),
            .keyPoints([
                "SSID — the network's broadcast name you pick from the list.",
                "Access Point (AP) — the radio that bridges wireless devices onto the wired network.",
                "WPA2 / WPA3 — the encryption securing the air link; WPA3 is the modern standard.",
                "Bands — 2.4 GHz (longer range, slower, more crowded) vs 5/6 GHz (faster, shorter).",
                "After associating, it's normal networking: DHCP, gateway, DNS, packets."
            ]),
            .definition(term: "WPA2 vs open Wi-Fi", meaning: "A WPA2/WPA3 network encrypts the radio link with the passphrase, so others nearby can't simply read your wireless traffic. **Open** Wi-Fi (no password) leaves that air link unencrypted — anyone in range can capture unsecured traffic, which is why a VPN matters on public hotspots."),
            .callout(.warning, "“Free Wi-Fi” with no password means the wireless link is unencrypted. Stick to HTTPS sites and use a VPN on open networks — the next lesson covers exactly why."),
            .checkpoint(QuizQuestion(
                "After your phone associates with a Wi-Fi access point, how does it get its IP address?",
                options: [
                    "The SSID contains it",
                    "From DHCP, just like a wired device",
                    "From the MAC address",
                    "It picks one at random permanently"
                ],
                correct: 1,
                why: "Once associated, Wi-Fi is ordinary networking: the device requests an address via DHCP and receives its IP, gateway and DNS, exactly as a wired device would."))
        ],
        quiz: [
            QuizQuestion(
                "What is an SSID?",
                options: [
                    "The Wi-Fi password",
                    "The broadcast name of a wireless network",
                    "The router's IP address",
                    "A type of encryption"
                ],
                correct: 1,
                why: "The SSID is the network's name that the access point advertises and you select from the list. The passphrase and encryption (WPA2/3) are separate."),
            QuizQuestion(
                "Compared with 2.4 GHz, the 5 GHz band generally offers…",
                options: [
                    "Longer range but slower speeds",
                    "Faster speeds but shorter range",
                    "Both longer range and faster speeds",
                    "No difference at all"
                ],
                correct: 1,
                why: "Higher-frequency 5/6 GHz carries more data (faster) but penetrates walls less and reaches shorter distances than 2.4 GHz."),
            QuizQuestion(
                "Why is open (passwordless) Wi-Fi riskier than a WPA2 network?",
                options: [
                    "It's slower",
                    "The wireless link is unencrypted, so nearby devices can capture unsecured traffic",
                    "It can't reach the internet",
                    "It uses a different IP scheme"
                ],
                correct: 1,
                why: "Without WPA2/WPA3 the air link isn't encrypted, so anyone in radio range can sniff traffic that isn't otherwise protected (e.g. by HTTPS or a VPN).")
        ]
    )

    private static let firewallVpnLesson = Lesson(
        id: "net-firewall-vpn",
        title: "Firewalls & VPNs",
        subtitle: "The two everyday tools that filter what comes in and protect what goes out.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("A firewall decides what's allowed"),
            .paragraph("A **firewall** is a gatekeeper for network traffic. It checks each packet against a **ruleset** and either permits or drops it — typically by source/destination IP and port. The guiding principle is **default-deny**: block everything, then allow only what's genuinely needed. That one habit shrinks the attack surface dramatically."),
            .animation(.firewallFilter, caption: "Packets are matched against the ruleset — allowed ports pass through, everything else is dropped at the wall."),
            .keyPoints([
                "Firewall — filters traffic against rules, allowing or blocking by IP and port.",
                "Default-deny — start by blocking all, then explicitly allow only what's needed.",
                "Inbound rules guard what can reach you; outbound rules limit what can leave.",
                "Stateful firewalls track connections, so replies to traffic you started are allowed back automatically.",
                "Firewalls run on your router, your OS, and in the cloud — often all three."
            ]),
            .heading("A VPN protects traffic in transit"),
            .paragraph("Where a firewall filters, a **VPN** (Virtual Private Network) protects. It builds an **encrypted tunnel** from your device to a VPN server, so everyone between you and that server — the café Wi-Fi, the ISP — sees only scrambled ciphertext, not your actual traffic. It also makes your traffic appear to come from the VPN server's location. On untrusted networks, that tunnel is your privacy."),
            .animation(.vpnTunnel, caption: "Inside the encrypted tunnel your data is unreadable — a snooper on the public network sees only ciphertext."),
            .definition(term: "VPN tunnel", meaning: "An encrypted channel that wraps your traffic between your device and a VPN server. It provides confidentiality (eavesdroppers can't read it) and a degree of privacy (your real IP is hidden behind the server's). It does not make you anonymous, and the VPN provider itself can see your traffic."),
            .callout(.tip, "Firewall and VPN solve different problems and are used together: the firewall controls *which* connections are allowed; the VPN protects the *contents* of the ones you make over a hostile network. Neither replaces the other."),
            .callout(.danger, "A VPN encrypts the link to the VPN server — not your whole identity. The provider can see your traffic, and HTTPS is still what protects you the rest of the way to a website. Choose a VPN you'd actually trust with that visibility."),
            .checkpoint(QuizQuestion(
                "You're on open café Wi-Fi and connect to a VPN. What can the café network operator now see?",
                options: [
                    "All your traffic in plaintext",
                    "Only encrypted tunnel traffic to the VPN server — not its contents",
                    "Your passwords",
                    "Nothing at all, including that you're online"
                ],
                correct: 1,
                why: "The VPN tunnel encrypts your traffic to the VPN server, so the local network sees only ciphertext going to the server — not the sites you visit or their contents."))
        ],
        quiz: [
            QuizQuestion(
                "What is the safest default policy for a firewall?",
                options: [
                    "Allow everything, then block known-bad traffic",
                    "Default-deny: block everything, then allow only what's explicitly needed",
                    "Allow all outbound, block all inbound permanently",
                    "Turn the firewall off for speed"
                ],
                correct: 1,
                why: "Default-deny minimises the attack surface: nothing is permitted unless there's an explicit rule for it, so forgotten services aren't left exposed."),
            QuizQuestion(
                "What does a VPN primarily provide?",
                options: [
                    "Faster internet",
                    "An encrypted tunnel that hides your traffic from the network between you and the VPN server",
                    "A new MAC address",
                    "Complete anonymity online"
                ],
                correct: 1,
                why: "A VPN encrypts traffic between your device and its server, shielding it from local eavesdroppers and masking your IP. It is not full anonymity — the provider still sees your traffic."),
            QuizQuestion(
                "How do firewalls and VPNs relate?",
                options: [
                    "They are the same tool",
                    "A firewall filters which connections are allowed; a VPN protects the contents of connections you make — they complement each other",
                    "A VPN replaces the need for a firewall",
                    "A firewall encrypts traffic and a VPN filters it"
                ],
                correct: 1,
                why: "They address different problems: filtering (firewall) vs confidentiality in transit (VPN). Strong setups use both together.")
        ]
    )

    // MARK: N6 — The modern internet

    private static let modern = Module(
        id: "net-modern",
        title: "The Modern Internet",
        summary: "How today's internet scales: the move to IPv6 for endless addresses, and the load balancers, CDNs and anycast that keep huge sites fast and online.",
        systemImage: "globe.americas.fill",
        lessons: [ipv6Lesson, cdnLesson, quicLesson]
    )

    private static let ipv6Lesson = Lesson(
        id: "net-ipv6",
        title: "IPv6 & the Address Crunch",
        subtitle: "Why we ran out of IPv4 — and how a 128-bit address makes NAT a thing of the past.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("The internet ran out of numbers"),
            .paragraph("IPv4 has 32 bits of address space — about 4.3 billion addresses. That sounded limitless in the 1980s and is laughably small today, with phones, laptops, servers and a fridge per household. The world officially exhausted the free IPv4 pool, and NAT (one public IP shared by a whole network) was the duct-tape fix. **IPv6** is the real solution: a **128-bit** address, which is roughly 3.4 × 10³⁸ addresses — enough to give every grain of sand its own."),
            .animation(.ipv6Address, caption: "A 128-bit address splits into a 48-bit routing prefix (your ISP), a 16-bit subnet id (yours), and a 64-bit interface id (the host) — often auto-built from the MAC via SLAAC."),
            .heading("Reading an IPv6 address"),
            .paragraph("An IPv6 address is eight groups of four hex digits, separated by colons: `2001:0db8:85a3:1f00:0000:8a2e:0370:7334`. To keep it readable there are two shortcuts — and you'll see both constantly."),
            .keyPoints([
                "Drop leading zeros in each group: 0db8 → db8, 0000 → 0.",
                "Collapse one run of all-zero groups with :: (used once per address): 2001:db8::1.",
                "The first 64 bits are typically the network (prefix + subnet); the last 64 identify the interface.",
                "Loopback is ::1 (the IPv6 'localhost'); a link-local address starts fe80:: and works only on the local link.",
                "/64 is the standard subnet size — every LAN gets a full 64 bits of host space."
            ]),
            .definition(term: "SLAAC", meaning: "Stateless Address Autoconfiguration — a host hears a Router Advertisement announcing the /64 prefix, then builds its own address by appending an interface id (from its MAC via EUI-64, or a randomized 'privacy' value). No DHCP server required, though DHCPv6 still exists for managed networks."),
            .terminal(prompt: "kali@lab",
                      command: "ip -6 addr show dev eth0 | grep inet6",
                      output: """
inet6 2001:db8:85a3:1f00:8a2e:370:7334/64 scope global dynamic
inet6 fe80::a00:27ff:fe94:1234/64 scope link
"""),
            .heading("What changes for security"),
            .paragraph("IPv6 isn't just 'more addresses' — it shifts the threat model. Because every device can have a globally routable address, the NAT that accidentally hid your devices is gone, so a host firewall matters more, not less. And huge /64 subnets make old-style ping-sweep scanning impractical — but attackers pivot to enumerating DNS, multicast and neighbor caches instead."),
            .callout(.warning, "Dual-stack hosts run IPv4 and IPv6 at once. A firewall rule set lovingly tuned for IPv4 that forgets IPv6 leaves a wide-open parallel path — a classic real-world gap. Always test both stacks."),
            .callout(.tip, "Link-local fe80:: addresses and IPv6 Router Advertisements enable LAN attacks too (rogue RA, SLAAC spoofing) — the IPv6 cousins of DHCP/ARP spoofing. RA Guard on switches is the mitigation."),
            .checkpoint(QuizQuestion(
                "Why does the move to IPv6 make a host-based firewall more important than it was behind IPv4 NAT?",
                options: [
                    "IPv6 has no encryption",
                    "Every device can have a globally routable address, so it's no longer accidentally hidden behind NAT",
                    "IPv6 disables all firewalls",
                    "IPv6 addresses are easier to guess"
                ],
                correct: 1,
                why: "NAT incidentally shielded internal hosts because they had no public address. With IPv6 every device can be directly addressable, so explicit firewalling — not NAT side-effects — is what controls inbound access."))
        ],
        quiz: [
            QuizQuestion(
                "How many bits is an IPv6 address?",
                options: ["32", "64", "128", "256"],
                correct: 2,
                why: "IPv6 uses 128-bit addresses (versus IPv4's 32), which is why it has enough space to abandon NAT entirely."),
            QuizQuestion(
                "What does `::` mean in an IPv6 address?",
                options: [
                    "The end of the address",
                    "A single collapsed run of one or more all-zero 16-bit groups",
                    "A separator between IPv4 and IPv6",
                    "The subnet mask"
                ],
                correct: 1,
                why: "`::` is shorthand for one contiguous run of zero groups, and may appear only once per address so it's unambiguous. 2001:db8::1 expands the omitted groups back to zeros."),
            QuizQuestion(
                "What does SLAAC let a host do?",
                options: [
                    "Encrypt its traffic automatically",
                    "Configure its own IPv6 address from a router-advertised prefix, without a DHCP server",
                    "Translate IPv6 to IPv4",
                    "Pick a faster route"
                ],
                correct: 1,
                why: "Stateless Address Autoconfiguration lets a host build its address from the advertised /64 prefix plus an interface id — no stateful DHCP server needed (though DHCPv6 remains an option).")
        ]
    )

    private static let cdnLesson = Lesson(
        id: "net-cdn",
        title: "Load Balancers, CDNs & Anycast",
        subtitle: "How one website serves millions at once — and stays up when a server dies.",
        minutes: 11,
        difficulty: .intermediate,
        blocks: [
            .heading("One name, many servers"),
            .paragraph("A busy site can't run on a single machine — it would melt, and one crash would take everything down. Instead, many identical servers sit behind a **load balancer**: a single front door that spreads incoming requests across the pool. To the user it's one address; behind it, the work is shared and any one server can fail without anyone noticing."),
            .animation(.loadBalancer, caption: "Each request is handed to the next healthy backend; the node failing its health check is skipped automatically — the foundation of both scale and uptime."),
            .keyPoints([
                "Load balancing algorithms — round-robin (take turns), least-connections (send to the idlest), or hash-based (sticky per client).",
                "Health checks — the balancer probes each backend and stops routing to one that stops responding.",
                "Horizontal scaling — handle more load by adding more servers to the pool, not by buying one bigger machine.",
                "High availability — because the pool has redundancy, a single server (or whole datacentre) can fail with no outage.",
                "L4 vs L7 — a layer-4 balancer routes by IP/port; a layer-7 one understands HTTP and can route by URL, host or cookie."
            ]),
            .definition(term: "CDN", meaning: "Content Delivery Network — a global mesh of edge servers that cache a site's static content (images, scripts, video) close to users. A visitor in Tokyo is served from a nearby edge instead of an origin server an ocean away, cutting latency dramatically and absorbing traffic spikes and DDoS floods."),
            .heading("Anycast: the same IP in many places"),
            .paragraph("How does a CDN send you to the *nearest* edge automatically? **Anycast.** The same IP address is announced from datacentres all over the world, and internet routing (BGP) naturally delivers your packets to the closest one. One address, dozens of physical locations — it's how DNS roots, big CDNs and DDoS scrubbing centres all work."),
            .terminal(prompt: "kali@lab",
                      command: "curl -sI https://cdn.shop.lab/logo.png | grep -iE 'cf-(cache|ray)|x-cache|server'",
                      output: """
server: cloudflare
cf-cache-status: HIT
cf-ray: 8a1f3c2d4e5f-NRT
"""),
            .callout(.tip, "`cf-cache-status: HIT` means the edge served a cached copy without bothering the origin; `NRT` in the ray id is the Tokyo (Narita) datacentre — anycast routed this request to the nearest edge. Reading these headers tells you a site's architecture for free."),
            .callout(.info, "This is why a CDN is a front-line DDoS defence: a globally distributed anycast network has far more capacity than any single origin, so a flood is spread across the whole mesh and absorbed at the edges instead of crushing one server."),
            .callout(.warning, "A CDN can also hide the origin's real IP. Attackers hunt for it via old DNS records, SSL-certificate scans or misconfigured subdomains — and if they find it, they can bypass the CDN's protection entirely. Lock origin firewalls to only accept traffic from the CDN."),
            .checkpoint(QuizQuestion(
                "A load balancer's health check finds one backend has stopped responding. What happens to user requests?",
                options: [
                    "All requests fail until an admin intervenes",
                    "The balancer stops routing to the dead node and keeps serving from the healthy ones",
                    "Every request is sent to the dead node anyway",
                    "The website's IP address changes"
                ],
                correct: 1,
                why: "Health checks let the balancer route around failure automatically — it simply removes the unhealthy node from rotation, so users keep getting served by the rest of the pool with no outage."))
        ],
        quiz: [
            QuizQuestion(
                "What problem does a load balancer primarily solve?",
                options: [
                    "Encrypting traffic",
                    "Spreading requests across many servers for scale and resilience behind one address",
                    "Assigning IP addresses",
                    "Blocking ports"
                ],
                correct: 1,
                why: "A load balancer presents one front door and distributes requests across a pool, enabling horizontal scaling and high availability — no single server is a bottleneck or a single point of failure."),
            QuizQuestion(
                "How does anycast send a user to the nearest CDN edge?",
                options: [
                    "The user manually picks a city",
                    "The same IP is announced from many locations, and internet routing delivers packets to the closest one",
                    "The CDN emails the user a new address",
                    "It uses the user's MAC address"
                ],
                correct: 1,
                why: "Anycast advertises one IP from many datacentres; BGP routing naturally chooses the topologically nearest, so the same address resolves to whichever edge is closest to each user."),
            QuizQuestion(
                "Why is a large CDN an effective defence against DDoS?",
                options: [
                    "It hides the website from search engines",
                    "Its distributed anycast capacity absorbs and spreads a flood across many edges instead of one origin",
                    "It blocks all traffic from other countries",
                    "It encrypts the attack traffic"
                ],
                correct: 1,
                why: "A globally distributed network has vastly more aggregate bandwidth than any single origin, so attack traffic is spread across the mesh and filtered at the edges rather than overwhelming one server.")
        ]
    )

    private static let quicLesson = Lesson(
        id: "net-quic",
        title: "QUIC & HTTP/3",
        subtitle: "Why the modern web ditched TCP for a faster, connection-migrating protocol over UDP.",
        minutes: 9,
        difficulty: .advanced,
        blocks: [
            .heading("The cost of the old stack"),
            .paragraph("For decades the web ran on **TCP**, with **TLS** layered on top for encryption. It works, but it's slow to start: TCP needs a round trip to connect, then TLS needs another to secure it, before a single byte of your page is sent. And TCP has a nasty quirk — **head-of-line blocking** — where one lost packet stalls *everything* behind it, even unrelated requests."),
            .animation(.quicHandshake, caption: "TCP+TLS spends two round trips before any data; QUIC folds transport and crypto into one handshake over UDP — zero round trips when resuming."),
            .heading("What QUIC changes"),
            .paragraph("**QUIC** is a new transport built on UDP that powers **HTTP/3**. It rolls TCP's reliability and TLS 1.3's encryption into one protocol, so a connection is both established and encrypted in a single round trip — and instantly on a repeat visit. Crucially, encryption is mandatory: there's no unencrypted QUIC."),
            .keyPoints([
                "1-RTT setup (0-RTT on resume) — transport + crypto handshake combined.",
                "No head-of-line blocking — independent streams, so one lost packet only stalls its own stream.",
                "Connection migration — a connection id (not the IP/port) names the session, so it survives switching Wi-Fi → cellular.",
                "Always encrypted — TLS 1.3 is built in; even the transport headers are largely protected.",
                "Runs in user space over UDP — so it can evolve without waiting for operating-system TCP changes."
            ]),
            .definition(term: "Connection migration", meaning: "Because a QUIC connection is identified by a connection ID rather than the source IP and port, it keeps working when your address changes — walking out of Wi-Fi range onto cellular doesn't drop the download. TCP, tied to the 4-tuple, can't do this."),
            .callout(.info, "QUIC is already huge: most traffic to Google, YouTube, Meta and Cloudflare-fronted sites uses HTTP/3. If you see lots of UDP/443 in a capture, that's QUIC — not a misconfiguration."),
            .callout(.warning, "For defenders, QUIC complicates monitoring: it's UDP/443, fully encrypted including most metadata, so old TCP-oriented inspection misses it. Some networks block UDP/443 to force a fallback to inspectable HTTP/2 — a real trade-off between performance and visibility."),
            .checkpoint(QuizQuestion(
                "Why can a QUIC connection survive moving from Wi-Fi to cellular while a TCP one drops?",
                options: [
                    "QUIC reconnects faster",
                    "QUIC identifies the connection by a connection id, not the IP/port, so a changed address doesn't break it",
                    "Cellular is faster",
                    "TCP also survives it"
                ],
                correct: 1,
                why: "TCP is bound to the source IP+port 4-tuple, so an address change kills the connection. QUIC's connection id lets the session continue seamlessly across network changes — connection migration."))
        ],
        quiz: [
            QuizQuestion(
                "What transport does QUIC (HTTP/3) run on?",
                options: ["TCP", "UDP", "ICMP", "A new IP protocol"],
                correct: 1,
                why: "QUIC is built on UDP, implementing its own reliability, ordering and (mandatory TLS 1.3) encryption in user space — sidestepping TCP's limitations."),
            QuizQuestion(
                "What problem does QUIC's independent-streams design solve?",
                options: [
                    "Weak encryption",
                    "Head-of-line blocking — one lost packet no longer stalls all the other requests",
                    "DNS resolution",
                    "IP exhaustion"
                ],
                correct: 1,
                why: "In TCP a single lost segment blocks everything behind it. QUIC's separate streams mean a loss only delays its own stream, so other requests keep flowing."),
            QuizQuestion(
                "Why does QUIC complicate network monitoring?",
                options: [
                    "It uses plaintext",
                    "It's UDP/443 and fully encrypted including most metadata, so TCP-oriented inspection misses it",
                    "It only runs on servers",
                    "It disables logging"
                ],
                correct: 1,
                why: "QUIC encrypts not just the payload but much of the transport metadata, and rides UDP/443, so traditional TCP-based inspection tooling has little to see — a visibility challenge for defenders.")
        ]
    )

    // MARK: N7 — Internet infrastructure

    private static let infra = Module(
        id: "net-infra",
        title: "Internet Infrastructure",
        summary: "The plumbing that ties the whole internet together: BGP, the routing protocol that decides global paths, and the SMTP/MX/IMAP chain that actually delivers your email.",
        systemImage: "point.3.connected.trianglepath.dotted",
        lessons: [bgpLesson, emailLesson]
    )

    private static let bgpLesson = Lesson(
        id: "net-bgp",
        title: "BGP & How the Internet Routes",
        subtitle: "The protocol that glues 70,000 networks into one internet — and how it goes wrong.",
        minutes: 11,
        difficulty: .advanced,
        blocks: [
            .heading("The internet is a network of networks"),
            .paragraph("The 'inter' in internet is literal: it's tens of thousands of independent networks — **Autonomous Systems** (AS) — that agree to carry each other's traffic. Each AS (an ISP, a cloud, a big company) has a number, like AS15169 for Google. The protocol they use to tell each other 'I can reach these addresses, send that traffic to me' is **BGP**, the Border Gateway Protocol — the routing glue of the entire internet."),
            .animation(.bgpRouting, caption: "Each AS announces the prefixes it can reach; BGP propagates those routes and every router picks the best, usually shortest, AS-path to the destination."),
            .heading("How a route is chosen"),
            .paragraph("BGP doesn't optimise for speed — it optimises for **policy and path length**. An AS hears multiple ways to reach a destination prefix and picks one based on rules (preferring shorter AS-paths, cheaper peering, configured preferences). Those choices, multiplied across every network, are how a packet finds its way across the planet."),
            .keyPoints([
                "Prefix — a block of addresses announced together, e.g. 203.0.113.0/24.",
                "AS-path — the list of Autonomous Systems a route passes through; shorter usually wins.",
                "Peering vs transit — networks peer (swap traffic free) or buy transit (pay to reach the rest of the internet).",
                "BGP is built on trust — historically an AS could announce almost any prefix and neighbours would believe it.",
                "RPKI — modern cryptographic route origin validation that checks an AS is actually authorised to announce a prefix."
            ]),
            .definition(term: "BGP hijacking", meaning: "When an AS announces a prefix it doesn't own — by accident or malice — and other networks believe it, traffic for those addresses is rerouted to the attacker. It has been used to intercept traffic and steal cryptocurrency. RPKI route validation is the primary defence."),
            .terminal(prompt: "kali@lab",
                      command: "whois -h whois.radb.net ' -i origin AS15169' | grep route | head -3",
                      output: """
route:      8.8.8.0/24
route:      8.34.208.0/20
route:      23.236.48.0/20
"""),
            .callout(.danger, "Because classic BGP trusts announcements, a single fat-fingered or malicious route can black-hole or intercept a chunk of the internet. The 2008 'Pakistan vs YouTube' incident and several crypto-theft hijacks are textbook cases. This is why RPKI adoption matters."),
            .callout(.tip, "BGP also underpins anycast (one prefix announced from many sites) and DDoS scrubbing (announcing a victim's prefix to pull attack traffic into a cleaning centre). The same global routing you're learning powers both the attack and the defence."),
            .checkpoint(QuizQuestion(
                "What is an Autonomous System (AS) in BGP?",
                options: [
                    "A single router",
                    "An independently-administered network (ISP, cloud, enterprise) that announces its routes to others",
                    "A type of firewall",
                    "A DNS server"
                ],
                correct: 1,
                why: "An AS is a network under one administrative authority with its own AS number. BGP runs between ASes, exchanging reachability so the global internet's paths can be built."))
        ],
        quiz: [
            QuizQuestion(
                "What does BGP primarily exchange between Autonomous Systems?",
                options: [
                    "Encryption keys",
                    "Reachability — which IP prefixes each AS can deliver, and via what path",
                    "DNS records",
                    "User passwords"
                ],
                correct: 1,
                why: "BGP advertises routes: which prefixes an AS can reach and the AS-path to them, letting every network compute how to forward traffic across the internet."),
            QuizQuestion(
                "What is BGP hijacking?",
                options: [
                    "Cracking a router password",
                    "An AS announcing a prefix it doesn't own, so traffic is misrouted to it",
                    "Flooding a link with packets",
                    "Spoofing a MAC address"
                ],
                correct: 1,
                why: "If an AS announces someone else's prefix and neighbours accept it, traffic for those addresses flows to the wrong network — enabling interception or outages. RPKI helps validate legitimate origins."),
            QuizQuestion(
                "Why is BGP historically vulnerable?",
                options: [
                    "It's encrypted too strongly",
                    "It was built on trust — networks largely believed each other's announcements without validation",
                    "It runs over UDP",
                    "It has no addresses"
                ],
                correct: 1,
                why: "Classic BGP has no built-in authentication of route ownership, so a false announcement is accepted by default. RPKI adds cryptographic origin validation to close that gap.")
        ]
    )

    private static let emailLesson = Lesson(
        id: "net-email",
        title: "How Email Travels",
        subtitle: "The SMTP / MX / IMAP chain behind every message — and why spoofing is so easy.",
        minutes: 10,
        difficulty: .intermediate,
        blocks: [
            .heading("Several protocols in a trench coat"),
            .paragraph("Sending an email feels instant, but behind it is a relay of distinct protocols. Your client **submits** the message with SMTP, your provider looks up the recipient's mail server via a DNS **MX record**, **SMTP** carries it there, and finally the recipient's client pulls it down with **IMAP** (or the older POP). Understanding this chain explains both how mail works and why phishing is so effective."),
            .animation(.emailFlow, caption: "Submit by SMTP, find the destination server by MX lookup, deliver by SMTP, then read with IMAP/POP — four protocols, one message."),
            .keyPoints([
                "SMTP (port 25/465/587) — the protocol that transfers mail between servers and accepts your submission.",
                "MX record — a DNS entry naming which server receives mail for a domain (mail.bob.com handles bob.com).",
                "IMAP (993) / POP (995) — how your client retrieves and syncs mail from your server.",
                "MTA / MUA — Mail Transfer Agent (the servers) vs Mail User Agent (your app).",
                "The envelope vs the headers — the SMTP envelope routes the mail; the visible From: header is separate and easily faked."
            ]),
            .definition(term: "Why spoofing is easy", meaning: "SMTP was designed in a trusting era and never authenticated the sender. The From: header you see is just text the sender writes — there's nothing in core SMTP stopping anyone claiming to be your bank. That gap is exactly why SPF, DKIM and DMARC were bolted on later."),
            .terminal(prompt: "kali@lab",
                      command: "dig +short MX bob.com",
                      output: """
10 mail.bob.com.
20 backup-mx.bob.com.
"""),
            .callout(.danger, "Because the visible From: is unauthenticated by default, email spoofing underpins most phishing. The fix isn't in SMTP itself but in the layered checks — SPF (authorised sending IPs), DKIM (a cryptographic signature) and DMARC (alignment + policy) — covered in the Blue Team track."),
            .callout(.tip, "Reading email headers (Received: lines, Authentication-Results:) traces the actual path a message took and whether SPF/DKIM/DMARC passed — a core skill for both phishing triage and incident response."),
            .checkpoint(QuizQuestion(
                "What does a domain's DNS MX record tell a sending mail server?",
                options: [
                    "The recipient's password",
                    "Which mail server should receive email for that domain",
                    "The fastest route to the domain",
                    "Whether the domain uses encryption"
                ],
                correct: 1,
                why: "The MX (Mail eXchange) record names the host that accepts mail for a domain, so a sender knows where to deliver. Multiple MX records with priorities provide fallback."))
        ],
        quiz: [
            QuizQuestion(
                "Which protocol transfers mail between mail servers?",
                options: ["IMAP", "SMTP", "HTTP", "POP"],
                correct: 1,
                why: "SMTP (Simple Mail Transfer Protocol) both accepts your submission and carries mail server-to-server. IMAP and POP are for retrieving mail to your client."),
            QuizQuestion(
                "Why is basic email sender spoofing so easy?",
                options: [
                    "Mail is never encrypted",
                    "Core SMTP doesn't authenticate the From: header — it's just text the sender supplies",
                    "DNS is broken",
                    "IMAP allows it"
                ],
                correct: 1,
                why: "SMTP was designed without sender authentication, so the visible From: can be set to anything. SPF, DKIM and DMARC were added later specifically to combat this."),
            QuizQuestion(
                "What does a mail client use IMAP for?",
                options: [
                    "Sending mail to other servers",
                    "Retrieving and syncing your mail from your mail server",
                    "Looking up MX records",
                    "Encrypting the connection"
                ],
                correct: 1,
                why: "IMAP retrieves messages and keeps them synced across devices (POP typically downloads and removes them). Sending/transfer is SMTP's job.")
        ]
    )

    // MARK: N8 — Web & real-time

    private static let webtech = Module(
        id: "net-webtech",
        title: "Web & Real-Time",
        summary: "The middle boxes and channels that shape modern web traffic: forward and reverse proxies, and the WebSockets that power live, two-way apps.",
        systemImage: "arrow.left.arrow.right.circle.fill",
        lessons: [proxiesLesson, webSocketsLesson]
    )

    private static let proxiesLesson = Lesson(
        id: "net-proxies",
        title: "Proxies & Reverse Proxies",
        subtitle: "The middle-men of the web — one hides the clients, the other fronts the servers.",
        minutes: 9,
        difficulty: .intermediate,
        blocks: [
            .heading("A proxy is a middle-man for requests"),
            .paragraph("A **proxy** is a server that makes requests on someone else's behalf. The crucial distinction is *whose* behalf — and that splits proxies into two opposite roles that confuse people endlessly. A **forward proxy** sits in front of the **clients**; a **reverse proxy** sits in front of the **servers**. Same machine in the middle, opposite direction of who it represents."),
            .animation(.proxyFlow, caption: "Forward proxy: clients → proxy → internet (fronts the clients). Reverse proxy: internet → proxy → backend pool (fronts the servers)."),
            .heading("Forward proxy — fronting the clients"),
            .paragraph("A forward proxy is what a company puts between its employees and the internet. Outbound requests go through it, so it can **filter** (block categories), **log** (who went where), **cache**, and **anonymise** (the destination sees the proxy's IP, not the user's). A VPN is a close cousin of this idea."),
            .heading("Reverse proxy — fronting the servers"),
            .paragraph("A reverse proxy is what sits in front of a website. Clients on the internet hit it, and it forwards to one of many **backend servers**. It's where you do **TLS termination**, **caching**, **load balancing** and **WAF** filtering — and it hides the backend topology entirely. Nginx, HAProxy, Envoy and every CDN are reverse proxies."),
            .keyPoints([
                "Forward proxy — represents the client; used for egress filtering, logging, caching, anonymity.",
                "Reverse proxy — represents the server; used for TLS termination, caching, load balancing, WAF.",
                "Both terminate the connection and open a new one — so they see (and can inspect) the traffic.",
                "TLS termination at the reverse proxy means it decrypts, inspects, then re-encrypts to the backend.",
                "An API gateway is a specialised reverse proxy adding auth, rate-limiting and routing per API."
            ]),
            .terminal(prompt: "kali@lab",
                      command: "curl -sI https://shop.lab | grep -iE 'server|via|x-cache'",
                      output: """
server: nginx
via: 1.1 varnish (Varnish/7.0)
x-cache: HIT
"""),
            .callout(.tip, "Recognising a reverse proxy from response headers (Server: nginx, Via:, X-Cache:) tells you the request isn't hitting the app directly — useful for both architecture mapping and understanding why an attack behaves oddly (the proxy may normalise or cache it)."),
            .callout(.warning, "Proxies see your traffic. A forward proxy (or a TLS-terminating reverse proxy) decrypts and can log everything — which is exactly how request smuggling and cache-poisoning attacks exploit disagreements between the proxy and the backend about a request's meaning."),
            .checkpoint(QuizQuestion(
                "What is the key difference between a forward proxy and a reverse proxy?",
                options: [
                    "Forward proxies are faster",
                    "A forward proxy fronts the clients (egress); a reverse proxy fronts the servers (ingress)",
                    "Reverse proxies don't use TLS",
                    "They are the same thing"
                ],
                correct: 1,
                why: "It's about whose behalf the proxy acts: a forward proxy represents outbound clients, a reverse proxy represents the servers it protects and load-balances. Same middle position, opposite role."))
        ],
        quiz: [
            QuizQuestion(
                "What is a reverse proxy commonly used for?",
                options: [
                    "Blocking employees from websites",
                    "TLS termination, caching, load balancing and hiding the backend servers",
                    "Assigning IP addresses",
                    "Resolving DNS"
                ],
                correct: 1,
                why: "A reverse proxy fronts servers — terminating TLS, caching responses, distributing load across a backend pool, and concealing the internal topology. Nginx, HAProxy and CDNs do this."),
            QuizQuestion(
                "An employer routes all staff web traffic through a server that filters and logs it. What is that?",
                options: ["A reverse proxy", "A forward proxy", "A DNS server", "A load balancer"],
                correct: 1,
                why: "Fronting the clients for egress filtering, logging and caching is the forward-proxy role — it represents the users making outbound requests."),
            QuizQuestion(
                "Why can a TLS-terminating reverse proxy inspect HTTPS traffic?",
                options: [
                    "It cracks the encryption",
                    "It terminates the TLS connection, so it decrypts, inspects, then re-encrypts to the backend",
                    "HTTPS isn't encrypted",
                    "It reads the browser's memory"
                ],
                correct: 1,
                why: "Because the client's TLS session ends at the proxy, the proxy holds the keys and sees plaintext before forwarding (often re-encrypted) to the backend — enabling caching, WAF inspection and routing.")
        ]
    )

    private static let webSocketsLesson = Lesson(
        id: "net-websockets",
        title: "WebSockets & Real-Time Web",
        subtitle: "How the web escaped request/response to power live chat, dashboards and games.",
        minutes: 9,
        difficulty: .advanced,
        blocks: [
            .heading("Breaking out of request/response"),
            .paragraph("Classic HTTP is strictly **request/response**: the client asks, the server answers, the connection is done. That's terrible for anything live — chat, trading dashboards, multiplayer games — where the *server* needs to push updates the moment they happen. The old workaround was 'polling' (asking again and again), which is wasteful and laggy. **WebSockets** fixed it properly."),
            .animation(.webSocketUpgrade, caption: "An ordinary HTTP request carries an Upgrade header; after a 101 Switching Protocols, the same TCP connection becomes a persistent, bidirectional channel."),
            .heading("The upgrade handshake"),
            .paragraph("A WebSocket starts life as a normal HTTP GET with an `Upgrade: websocket` header. If the server agrees, it replies **101 Switching Protocols**, and from that point the same TCP connection is no longer HTTP — it's a full-duplex WebSocket where either side can send 'frames' at any time, with almost no per-message overhead."),
            .keyPoints([
                "ws:// and wss:// — the WebSocket schemes (wss is WebSocket over TLS, the secure form).",
                "Starts as HTTP — so it works through the same ports (80/443) and most firewalls.",
                "Full-duplex — server and client both push anytime; no polling, low latency.",
                "Persistent — one long-lived connection instead of a request per update.",
                "Used by — chat, live dashboards, collaborative editing, multiplayer games, trading."
            ]),
            .terminal(prompt: "browser",
                      command: "GET /chat HTTP/1.1  ·  Upgrade: websocket  ·  Connection: Upgrade",
                      output: """
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
← connection is now a two-way WebSocket
"""),
            .definition(term: "Cross-Site WebSocket Hijacking (CSWSH)", meaning: "Because the WebSocket handshake is an HTTP request, it rides the user's cookies — and crucially, it is NOT protected by the Same-Origin Policy the way fetch() is. If a server authenticates the socket by cookie alone, a malicious page can open a socket as the victim. The fix is validating the Origin header and using anti-CSRF tokens on the handshake."),
            .callout(.warning, "WebSockets need their own security thinking. The Same-Origin Policy and CORS don't constrain them the way they do normal requests, so servers must explicitly check the Origin header on the handshake — or risk CSWSH, the WebSocket cousin of CSRF."),
            .callout(.tip, "For defenders and testers: a tool like Burp can intercept and replay individual WebSocket frames, so the live channel is just as testable as HTTP — look for missing Origin checks and trust placed in client-sent frames."),
            .checkpoint(QuizQuestion(
                "How does a WebSocket connection begin?",
                options: [
                    "As a UDP packet",
                    "As an HTTP request with an Upgrade header, answered by 101 Switching Protocols",
                    "As a DNS lookup",
                    "As a TLS handshake only"
                ],
                correct: 1,
                why: "WebSockets bootstrap over HTTP: the client sends GET with Upgrade: websocket, and a 101 response switches the same connection to the bidirectional WebSocket protocol."))
        ],
        quiz: [
            QuizQuestion(
                "What problem do WebSockets solve that plain HTTP can't?",
                options: [
                    "Encryption",
                    "Letting the server push data to the client anytime over a persistent two-way connection",
                    "Resolving domain names",
                    "Compressing images"
                ],
                correct: 1,
                why: "HTTP is request/response, so the server can't initiate. WebSockets keep a persistent full-duplex channel open, letting the server push updates instantly — ideal for chat, dashboards and games."),
            QuizQuestion(
                "What does a 101 Switching Protocols response indicate in the WebSocket handshake?",
                options: [
                    "An error occurred",
                    "The server agreed to upgrade the connection from HTTP to WebSocket",
                    "The page moved",
                    "Authentication failed"
                ],
                correct: 1,
                why: "101 confirms the protocol switch: from that point the connection is a WebSocket, not HTTP, and both sides can exchange frames freely."),
            QuizQuestion(
                "Why is Cross-Site WebSocket Hijacking possible?",
                options: [
                    "WebSockets have no encryption",
                    "The handshake carries cookies but isn't constrained by the Same-Origin Policy, so a server trusting cookies alone can be opened cross-site",
                    "WebSockets use UDP",
                    "Browsers don't support them"
                ],
                correct: 1,
                why: "The handshake is a cookie-bearing HTTP request not protected like fetch() is. If the server authenticates by cookie without checking Origin, a malicious page can open an authenticated socket — so validate Origin and use handshake tokens.")
        ]
    )

    private static let vlanLesson = Lesson(
        id: "net-vlans",
        title: "VLANs & Segmentation",
        subtitle: "How one physical switch becomes many separate networks — and why that's a security win.",
        minutes: 9,
        difficulty: .intermediate,
        blocks: [
            .heading("One switch, many networks"),
            .paragraph("By default, every device plugged into a switch shares one **broadcast domain** — they can all talk to each other. A **VLAN** (Virtual LAN) carves that single switch into several logical networks that behave as if physically separate. Finance, guest Wi-Fi and servers can share the same hardware yet be unable to reach one another."),
            .animation(.vlanTagging, caption: "As a frame enters, the switch tags it with its VLAN id (802.1Q) and only forwards it to ports in the same VLAN — VLAN 10 can't reach VLAN 20."),
            .heading("How it works"),
            .paragraph("Each switch port is assigned to a VLAN. When a frame needs to travel between switches, the switch adds an **802.1Q tag** — a small VLAN id stamped into the frame — so the next switch knows which VLAN it belongs to. The link that carries multiple tagged VLANs between switches is a **trunk**."),
            .keyPoints([
                "Broadcast domain — the set of devices that receive each other's broadcasts; a VLAN is its own domain.",
                "802.1Q tag — the 12-bit VLAN id added to a frame so switches keep traffic separated (4094 usable VLANs).",
                "Access port — belongs to one VLAN, connects an end device. Trunk port — carries many tagged VLANs between switches.",
                "Inter-VLAN routing — to move traffic between VLANs you must go through a router/L3 switch, where firewall rules can apply.",
                "Security value — segmentation limits lateral movement: a compromised guest device can't reach the server VLAN."
            ]),
            .definition(term: "Segmentation", meaning: "Dividing a network into zones so that compromise of one doesn't grant access to all. VLANs are the classic switch-level tool for it; microsegmentation (a Zero Trust idea) pushes the same principle down to individual workloads. Either way, the goal is to shrink an attacker's blast radius."),
            .callout(.tip, "Segmentation is one of the highest-value defensive controls: it directly blunts the lateral movement that turns one foothold into a domain takeover. A flat network is an attacker's dream — everything is one hop away."),
            .callout(.danger, "VLANs are an isolation convenience, not a hard security boundary. VLAN hopping (double-tagging, or abusing dynamic trunking) can defeat weak configs — so disable auto-trunking, pick an unused native VLAN, and don't rely on VLANs alone for high-stakes isolation."),
            .checkpoint(QuizQuestion(
                "Two devices are on the same switch but in different VLANs. Can they communicate directly?",
                options: [
                    "Yes, always — they share a switch",
                    "No — VLANs are separate broadcast domains; traffic between them must be routed (and can be filtered)",
                    "Only if they have the same IP",
                    "Only over Wi-Fi"
                ],
                correct: 1,
                why: "Different VLANs are isolated broadcast domains even on one switch. Reaching from one to the other requires a router or L3 switch, which is exactly where access controls can be enforced."))
        ],
        quiz: [
            QuizQuestion(
                "What does a VLAN let you do?",
                options: [
                    "Speed up a single connection",
                    "Split one physical switch into multiple isolated logical networks",
                    "Encrypt all traffic",
                    "Assign public IP addresses"
                ],
                correct: 1,
                why: "A VLAN logically partitions a switch into separate broadcast domains, so different groups share hardware without sharing a network — the basis of segmentation."),
            QuizQuestion(
                "What is the purpose of an 802.1Q tag?",
                options: [
                    "To encrypt the frame",
                    "To stamp a frame with its VLAN id so switches keep VLAN traffic separated across trunks",
                    "To compress the frame",
                    "To assign an IP address"
                ],
                correct: 1,
                why: "The 802.1Q tag carries the VLAN id within the frame, letting switches forward it only within its VLAN — essential on trunk links that carry several VLANs."),
            QuizQuestion(
                "Why is network segmentation a strong security control?",
                options: [
                    "It makes the network faster",
                    "It limits lateral movement — a compromised device can't freely reach other zones",
                    "It encrypts passwords",
                    "It removes the need for firewalls"
                ],
                correct: 1,
                why: "By isolating zones, segmentation shrinks an attacker's blast radius: a foothold in one segment can't pivot across the whole network, directly hampering lateral movement.")
        ]
    )
}
