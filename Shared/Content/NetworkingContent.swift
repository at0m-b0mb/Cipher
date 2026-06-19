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
        modules: [foundations, addressing, routing, protocols, wireless]
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
        lessons: [switchRouterLesson, routingLesson, natLesson, dhcpLesson]
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
}
