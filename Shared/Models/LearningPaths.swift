import SwiftUI

// MARK: - Learning paths
//
// A learning path is a curated, ordered route through lessons drawn from across
// the four tracks, aimed at a specific goal or role. Where the Curriculum is
// organised by *subject* (the reference), paths are organised by *destination*
// (the journey) — so an aspiring student always knows what to do next.

struct LearningPath: Identifiable {
    let id: String
    let title: String
    let goal: String          // one-line "who this is for / where it leads"
    let systemImage: String
    let accent: Color
    let level: String         // "Beginner" · "Intermediate" · "Advanced"
    let lessonIDs: [String]

    /// The resolved lessons, skipping any id that no longer exists. Progress and
    /// counts are computed from this, so a stale id can never break the maths.
    var lessons: [Lesson] { lessonIDs.compactMap { Curriculum.lesson(id: $0) } }
    var lessonCount: Int { lessons.count }
    var totalMinutes: Int { lessons.reduce(0) { $0 + $1.minutes } }
}

enum LearningPaths {

    static let all: [LearningPath] = [

        LearningPath(
            id: "path-beginner",
            title: "Absolute Beginner",
            goal: "Never touched security before? Start here — the mental model, the shell, networks and the web, from zero.",
            systemImage: "figure.walk",
            accent: Theme.teal,
            level: "Beginner",
            lessonIDs: [
                "fund-ethics", "fund-cia", "fund-threat-actors", "fund-linux",
                "net-what-is", "net-ip-mac", "net-dns", "fund-web-basics",
                "fund-encryption", "fund-auth", "fund-journey"
            ]),

        LearningPath(
            id: "path-networking",
            title: "Networking Essentials",
            goal: "Understand how computers actually talk — the foundation every other security skill stands on.",
            systemImage: "globe",
            accent: Theme.violet,
            level: "Beginner",
            lessonIDs: [
                "net-what-is", "net-packets-layers", "net-ip-mac", "net-subnetting",
                "net-dns", "net-switch-router", "net-routing-traceroute", "net-nat",
                "net-tcp-udp", "net-vlans", "net-firewall-vpn"
            ]),

        LearningPath(
            id: "path-crypto",
            title: "Cryptography Foundations",
            goal: "From bits and XOR to TLS — how data is protected, and how that protection is attacked.",
            systemImage: "lock.shield.fill",
            accent: Theme.teal,
            level: "Intermediate",
            lessonIDs: [
                "fund-bitwise", "fund-encryption", "fund-block-modes", "fund-hashing",
                "fund-entropy", "fund-pki", "fund-tls", "red-crypto-attacks"
            ]),

        LearningPath(
            id: "path-web",
            title: "Web Application Hacker",
            goal: "Hunt the internet's biggest attack surface — injection, access control, SSRF and modern API bugs.",
            systemImage: "ladybug.fill",
            accent: Theme.red,
            level: "Intermediate",
            lessonIDs: [
                "fund-web-basics", "fund-databases", "red-sqli", "red-xss",
                "red-access-control", "red-ssrf", "red-csrf", "red-file-upload",
                "red-jwt", "red-cors", "red-api", "red-bugbounty"
            ]),

        LearningPath(
            id: "path-pentester",
            title: "Aspiring Penetration Tester",
            goal: "The offensive workflow end to end: recon, exploit, escalate, pivot — then write it up.",
            systemImage: "target",
            accent: Theme.red,
            level: "Advanced",
            lessonIDs: [
                "fund-linux", "red-osint", "red-scanning", "red-exploitation",
                "red-metasploit", "red-sqli", "red-privesc", "red-linux-privesc",
                "red-windows-privesc", "red-tunneling", "red-lab", "red-report"
            ]),

        LearningPath(
            id: "path-ad",
            title: "Active Directory Attacker",
            goal: "Own the enterprise: Kerberos, BloodHound, delegation, trusts and the certificate-services path to Domain Admin.",
            systemImage: "person.2.badge.gearshape.fill",
            accent: Theme.red,
            level: "Advanced",
            lessonIDs: [
                "fund-ad-basics", "red-kerberoasting", "red-ad-attacks", "red-bloodhound",
                "red-lateral", "red-delegation", "red-trusts", "red-adcs"
            ]),

        LearningPath(
            id: "path-soc",
            title: "SOC Analyst / Blue Team",
            goal: "Defend and respond: build detections, hunt, run incidents and recover — the defender's daily craft.",
            systemImage: "shield.lefthalf.filled",
            accent: Theme.blue,
            level: "Intermediate",
            lessonIDs: [
                "fund-cia", "blue-defense-in-depth", "net-firewall-vpn", "blue-siem",
                "blue-mitre", "blue-detection-engineering", "blue-yara", "blue-threat-hunting",
                "blue-incident-response", "blue-forensics-essentials", "blue-soar", "blue-frameworks"
            ]),

        LearningPath(
            id: "path-cloud",
            title: "Cloud Security",
            goal: "Attack and defend the infrastructure most targets actually run on — IAM, storage, containers and posture.",
            systemImage: "cloud.fill",
            accent: Theme.blue,
            level: "Advanced",
            lessonIDs: [
                "fund-virtualization", "red-cloud-infra", "red-cloud-storage", "red-containers",
                "blue-cloud", "blue-zero-trust", "blue-secrets", "blue-frameworks"
            ])
    ]

    static func path(id: String) -> LearningPath? { all.first { $0.id == id } }
}
