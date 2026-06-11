import SwiftUI

// MARK: - Difficulty

/// How demanding a lesson is, mirroring the way professional tracks (e.g. OSCP)
/// ramp from fundamentals to expert exploitation.
enum Difficulty: Int, CaseIterable, Comparable, Codable {
    case foundational, intermediate, advanced, expert

    var label: String {
        switch self {
        case .foundational: return "Foundational"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        case .expert:       return "Expert"
        }
    }

    /// Number of filled pips shown in the UI (out of 4).
    var pips: Int { rawValue + 1 }

    var tint: Color {
        switch self {
        case .foundational: return Theme.teal
        case .intermediate: return Theme.amber
        case .advanced:     return Theme.red
        case .expert:       return Theme.magenta
        }
    }

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { lhs.rawValue < rhs.rawValue }
}

// MARK: - Callouts

/// Inline highlighted boxes inside a lesson — the way courseware flags
/// "remember this", a gotcha, a tip, or a real-world danger.
enum CalloutKind: String {
    case info, tip, warning, danger, lab

    var systemImage: String {
        switch self {
        case .info:    return "info.circle.fill"
        case .tip:     return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger:  return "flame.fill"
        case .lab:     return "flask.fill"
        }
    }

    var tint: Color {
        switch self {
        case .info:    return Theme.blue
        case .tip:     return Theme.teal
        case .warning: return Theme.amber
        case .danger:  return Theme.red
        case .lab:     return Theme.violet
        }
    }

    var title: String {
        switch self {
        case .info:    return "Concept"
        case .tip:     return "Pro tip"
        case .warning: return "Watch out"
        case .danger:  return "Real-world risk"
        case .lab:     return "Hands-on lab"
        }
    }
}

// MARK: - Animations

/// Every custom animated explainer the iOS app can render. A lesson references
/// one of these by case; `AnimationRegistry` maps it to the actual SwiftUI view.
/// Keeping it an enum (in shared code) means content authors pick an animation
/// without importing any UIKit/iOS-only code.
enum AnimationID: String, CaseIterable, Codable {
    // Networking & fundamentals
    case osiModel
    case tcpHandshake
    case packetTravel
    case symmetricEncryption
    case publicKeyExchange
    case hashing
    case httpRequest
    case adForest

    // Red team
    case cyberKillChain
    case portScan
    case phishingFlow
    case sqlInjection
    case xssReflected
    case accessControl
    case fileInclusion
    case templateInjection
    case csrf
    case jwtAttack
    case sourceReview
    case clientSide
    case privilegeEscalation
    case passwordCracking
    case kerberoasting
    case dcsync
    case attackPath
    case delegation
    case forestTrust
    case lateralMovement
    case tunneling
    case amsiBypass
    case processInjection
    case applockerBypass
    case wifiHandshake
    case arpPoisoning
    case bufferOverflow
    case ropChain
    case sehOverflow
    case formatString
    case heapExploit
    case c2Beacon

    // Blue team
    case defenseInDepth
    case siemPipeline
    case incidentResponse
    case mitreAttack
    case threatHunting
    case adTiering

    /// Short human label used in the lesson UI chrome.
    var label: String {
        switch self {
        case .osiModel:            return "The OSI Model"
        case .tcpHandshake:        return "TCP 3-Way Handshake"
        case .packetTravel:        return "Anatomy of a Packet"
        case .symmetricEncryption: return "Symmetric Encryption"
        case .publicKeyExchange:   return "Public-Key Exchange"
        case .hashing:             return "Hashing"
        case .httpRequest:         return "An HTTP Request"
        case .adForest:            return "Active Directory Forest"
        case .cyberKillChain:      return "The Cyber Kill Chain"
        case .portScan:            return "Port Scanning"
        case .phishingFlow:        return "Phishing → Initial Access"
        case .sqlInjection:        return "SQL Injection"
        case .xssReflected:        return "Cross-Site Scripting"
        case .accessControl:       return "Broken Access Control (IDOR)"
        case .fileInclusion:       return "Path Traversal & File Inclusion"
        case .templateInjection:   return "Server-Side Template Injection"
        case .csrf:                return "Cross-Site Request Forgery"
        case .jwtAttack:           return "JWT Token Attacks"
        case .sourceReview:        return "Source-to-Sink (White-Box)"
        case .clientSide:          return "Client-Side Attack"
        case .privilegeEscalation: return "Privilege Escalation"
        case .passwordCracking:    return "Offline Password Cracking"
        case .kerberoasting:       return "Kerberoasting"
        case .dcsync:              return "DCSync → Golden Ticket"
        case .attackPath:          return "Attack Path (BloodHound)"
        case .delegation:          return "Kerberos Delegation Abuse"
        case .forestTrust:         return "Forest Trust Abuse"
        case .lateralMovement:     return "Lateral Movement"
        case .tunneling:           return "Tunneling & Pivoting"
        case .amsiBypass:          return "AMSI Bypass"
        case .processInjection:    return "Process Injection"
        case .applockerBypass:     return "AppLocker Bypass"
        case .wifiHandshake:       return "WPA2 Handshake Capture"
        case .arpPoisoning:        return "ARP Poisoning (MITM)"
        case .bufferOverflow:      return "Stack Buffer Overflow"
        case .ropChain:            return "Return-Oriented Programming"
        case .sehOverflow:         return "SEH Overflow"
        case .formatString:        return "Format String Exploit"
        case .heapExploit:         return "Heap Exploitation"
        case .c2Beacon:            return "Command & Control Beacon"
        case .defenseInDepth:      return "Defense in Depth"
        case .siemPipeline:        return "SIEM Detection Pipeline"
        case .incidentResponse:    return "Incident Response Lifecycle"
        case .mitreAttack:         return "MITRE ATT&CK"
        case .threatHunting:       return "Threat Hunting Loop"
        case .adTiering:           return "Tiered AD Administration"
        }
    }
}

// MARK: - Lesson content blocks

/// A lesson is an ordered list of blocks. The lesson player walks the list and
/// renders each one, so authoring a lesson is just describing it as data.
enum LessonBlock {
    case heading(String)
    case paragraph(String)
    case keyPoints([String])
    case callout(CalloutKind, String)
    case definition(term: String, meaning: String)
    case terminal(prompt: String, command: String, output: String)
    case code(language: String, String)
    case animation(AnimationID, caption: String)
    case checkpoint(QuizQuestion)
}

// MARK: - Quiz

struct QuizQuestion: Identifiable {
    let id: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String

    init(id: String = UUID().uuidString,
         _ prompt: String,
         options: [String],
         correct correctIndex: Int,
         why explanation: String) {
        self.id = id
        self.prompt = prompt
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
    }
}

// MARK: - Lesson / Module / Track

struct Lesson: Identifiable {
    let id: String            // stable slug, e.g. "red-recon-osint" — drives progress
    let title: String
    let subtitle: String
    let minutes: Int
    let difficulty: Difficulty
    let blocks: [LessonBlock]
    let quiz: [QuizQuestion]

    /// The animations referenced anywhere in this lesson (for the lesson header chips).
    var animations: [AnimationID] {
        blocks.compactMap { if case let .animation(id, _) = $0 { return id } else { return nil } }
    }
}

struct Module: Identifiable {
    let id: String
    let title: String
    let summary: String
    let systemImage: String
    let lessons: [Lesson]

    var totalMinutes: Int { lessons.reduce(0) { $0 + $1.minutes } }
}

extension Lesson {
    /// The module this lesson belongs to (for "up next" context labels).
    var parentModule: Module? {
        Curriculum.allModules.first { $0.lessons.contains { $0.id == id } }
    }
}

enum TrackKind: String {
    case fundamentals, redTeam, blueTeam

    var title: String {
        switch self {
        case .fundamentals: return "Fundamentals"
        case .redTeam:      return "Red Team"
        case .blueTeam:     return "Blue Team"
        }
    }

    var accent: Color {
        switch self {
        case .fundamentals: return Theme.teal
        case .redTeam:      return Theme.red
        case .blueTeam:     return Theme.blue
        }
    }

    var glyph: String {
        switch self {
        case .fundamentals: return "function"
        case .redTeam:      return "flame.fill"
        case .blueTeam:     return "shield.lefthalf.filled"
        }
    }
}

struct Track: Identifiable {
    let id: String
    let kind: TrackKind
    let title: String
    let tagline: String
    let modules: [Module]

    var accent: Color { kind.accent }
    var lessons: [Lesson] { modules.flatMap(\.lessons) }
    var totalMinutes: Int { modules.reduce(0) { $0 + $1.totalMinutes } }
}

// MARK: - Curriculum root

/// The whole course. Built in code from the `*Content` files so it ships with
/// the binary, works fully offline, and is trivial to extend — add a `Lesson`
/// to a `Module` and it appears everywhere (dashboard, progress, search).
enum Curriculum {
    static let tracks: [Track] = [
        FundamentalsContent.track,
        RedTeamContent.track,
        BlueTeamContent.track
    ]

    static var allLessons: [Lesson] { tracks.flatMap(\.lessons) }
    static var allModules: [Module] { tracks.flatMap(\.modules) }
    static var lessonCount: Int { allLessons.count }

    static func track(for kind: TrackKind) -> Track {
        tracks.first { $0.kind == kind }!
    }

    static func lesson(id: String) -> Lesson? {
        allLessons.first { $0.id == id }
    }

    /// The track a given lesson belongs to — used to colour lesson chrome.
    static func track(forLesson lessonID: String) -> Track? {
        tracks.first { $0.lessons.contains { $0.id == lessonID } }
    }

    /// The next lesson in curriculum order (track → module → lesson). Powers the
    /// "Up next" hand-off at the end of a lesson so a learner can keep going on a
    /// phone without backing out to the track list.
    static func lessonAfter(id lessonID: String) -> Lesson? {
        let all = allLessons
        guard let idx = all.firstIndex(where: { $0.id == lessonID }), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }
}
