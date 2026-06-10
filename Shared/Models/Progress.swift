import Foundation
import Combine

// MARK: - Rank ladder

/// A playful but motivating progression, the way real programs hand out
/// certifications as you climb. Driven purely by earned XP.
struct Rank: Identifiable {
    let id: Int
    let title: String
    let xpRequired: Int
    let glyph: String

    static let ladder: [Rank] = [
        Rank(id: 0, title: "Initiate",        xpRequired: 0,    glyph: "circle.dashed"),
        Rank(id: 1, title: "Script Kiddie",   xpRequired: 300,  glyph: "terminal"),
        Rank(id: 2, title: "Apprentice",      xpRequired: 800,  glyph: "chevron.left.forwardslash.chevron.right"),
        Rank(id: 3, title: "Junior Pentester",xpRequired: 1600, glyph: "lock.open"),
        Rank(id: 4, title: "Operator",        xpRequired: 2800, glyph: "bolt.shield"),
        Rank(id: 5, title: "Team Lead",       xpRequired: 4400, glyph: "person.3.sequence.fill"),
        Rank(id: 6, title: "Elite Operator",  xpRequired: 6500, glyph: "crown.fill")
    ]

    static func current(for xp: Int) -> Rank {
        ladder.last { xp >= $0.xpRequired } ?? ladder[0]
    }

    static func next(after rank: Rank) -> Rank? {
        ladder.first { $0.xpRequired > rank.xpRequired }
    }
}

// MARK: - Progress store

/// Single source of truth for what the learner has done. Cross-platform:
/// persists a small JSON blob in `UserDefaults`, so it works identically on
/// iOS and watchOS with no extra frameworks.
///
/// (iPhone and Watch keep independent stores today; syncing them over
/// `WatchConnectivity` is a natural next step — see README.)
@MainActor
final class ProgressStore: ObservableObject {

    @Published private(set) var completedLessons: Set<String> = []
    @Published private(set) var bestQuizScore: [String: Int] = [:]   // lessonID → best %
    @Published private(set) var streak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published private(set) var lastActiveDay: Date?
    @Published var hasAcceptedEthics: Bool = false

    private let defaults: UserDefaults
    private let key = "cipher.progress.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
        refreshStreak()
        #if DEBUG
        if ProcessInfo.processInfo.environment["CIPHER_DEMO"] != nil { seedDemo() }
        #endif
    }

    #if DEBUG
    /// Populates believable progress for screenshots / previews. Compiled out of
    /// Release builds and only active when the CIPHER_DEMO env var is present.
    private func seedDemo() {
        hasAcceptedEthics = true
        let demo = ["fund-ethics", "fund-kill-chain", "fund-osi", "fund-tcp",
                    "fund-encryption", "red-osint", "red-scanning", "red-phishing", "blue-defense-in-depth"]
        completedLessons = Set(demo)
        for id in demo { bestQuizScore[id] = [80, 90, 100][id.count % 3] }
        streak = 6
        longestStreak = 9
        lastActiveDay = Calendar.current.startOfDay(for: Date())
    }
    #endif

    // MARK: Derived stats

    var xp: Int {
        let lessonXP = completedLessons.count * 100
        let quizXP = bestQuizScore.values.reduce(0) { $0 + Int(Double($1) * 0.5) }
        return lessonXP + quizXP
    }

    var rank: Rank { Rank.current(for: xp) }

    var xpIntoRank: Double {
        let cur = rank
        guard let nxt = Rank.next(after: cur) else { return 1 }
        let span = Double(nxt.xpRequired - cur.xpRequired)
        return span <= 0 ? 1 : Double(xp - cur.xpRequired) / span
    }

    var overallCompletion: Double {
        let total = Curriculum.lessonCount
        return total == 0 ? 0 : Double(completedLessons.count) / Double(total)
    }

    func completion(of track: Track) -> Double {
        let ids = track.lessons.map(\.id)
        guard !ids.isEmpty else { return 0 }
        let done = ids.filter(completedLessons.contains).count
        return Double(done) / Double(ids.count)
    }

    func completion(of module: Module) -> Double {
        let ids = module.lessons.map(\.id)
        guard !ids.isEmpty else { return 0 }
        let done = ids.filter(completedLessons.contains).count
        return Double(done) / Double(ids.count)
    }

    func isComplete(_ lessonID: String) -> Bool { completedLessons.contains(lessonID) }

    /// The next not-yet-completed lesson across the whole curriculum — powers
    /// the "Continue" button on the dashboard.
    var nextLesson: Lesson? {
        Curriculum.allLessons.first { !completedLessons.contains($0.id) }
    }

    // MARK: Mutations

    func markComplete(_ lessonID: String) {
        completedLessons.insert(lessonID)
        touchToday()
        save()
    }

    func recordQuiz(lessonID: String, scorePercent: Int) {
        let best = max(bestQuizScore[lessonID] ?? 0, scorePercent)
        bestQuizScore[lessonID] = best
        touchToday()
        save()
    }

    func acceptEthics() {
        hasAcceptedEthics = true
        touchToday()
        save()
    }

    /// Lightweight "I did something today" signal — used by the Apple Watch
    /// daily drill to keep the streak alive without completing a full lesson.
    func markDailyActivity() {
        touchToday()
        save()
    }

    func resetAll() {
        completedLessons = []
        bestQuizScore = [:]
        streak = 0
        longestStreak = 0
        lastActiveDay = nil
        save()
    }

    // MARK: Streak

    /// Call when the learner does anything meaningful today.
    private func touchToday() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if let last = lastActiveDay {
            let lastDay = cal.startOfDay(for: last)
            if cal.isDate(lastDay, inSameDayAs: today) {
                // already counted today
            } else if let yesterday = cal.date(byAdding: .day, value: 1, to: lastDay),
                      cal.isDate(yesterday, inSameDayAs: today) {
                streak += 1
            } else {
                streak = 1
            }
        } else {
            streak = 1
        }
        longestStreak = max(longestStreak, streak)
        lastActiveDay = today
    }

    /// On launch, expire a streak if the learner skipped a full day.
    private func refreshStreak() {
        guard let last = lastActiveDay else { return }
        let cal = Calendar.current
        let lastDay = cal.startOfDay(for: last)
        let today = cal.startOfDay(for: Date())
        if let gap = cal.dateComponents([.day], from: lastDay, to: today).day, gap > 1 {
            streak = 0
            save()
        }
    }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var completed: [String]
        var quiz: [String: Int]
        var streak: Int
        var longest: Int
        var lastActive: Date?
        var ethics: Bool
    }

    private func save() {
        let snap = Snapshot(completed: Array(completedLessons),
                            quiz: bestQuizScore,
                            streak: streak,
                            longest: longestStreak,
                            lastActive: lastActiveDay,
                            ethics: hasAcceptedEthics)
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        completedLessons = Set(snap.completed)
        bestQuizScore = snap.quiz
        streak = snap.streak
        longestStreak = snap.longest
        lastActiveDay = snap.lastActive
        hasAcceptedEthics = snap.ethics
    }
}
