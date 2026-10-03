import Foundation

// MARK: - Lab registry

/// Every hands-on lab in the app, in one browsable place.
///
/// Labs come from two sources and the learner should not have to care which:
/// some are embedded in a lesson body (`LessonBlock.interactiveLab`) because the
/// technique is best drilled right where it is taught; the rest live in the
/// standalone lab library files and exist purely to be practised. `Labs.all`
/// unifies both so the Labs hub can list, filter and track them identically.
enum Labs {

    /// Labs that exist on their own, authored in the `Labs*.swift` library files.
    static var standalone: [InteractiveLab] {
        LabsFoundations.labs + LabsNetworking.labs + LabsRed.labs + LabsBlue.labs
    }

    /// Labs embedded inside lesson bodies, harvested so the hub lists them too.
    static var inLesson: [InteractiveLab] {
        Curriculum.allLessons.flatMap { lesson in
            lesson.blocks.compactMap { block -> InteractiveLab? in
                guard case .interactiveLab(let lab) = block else { return nil }
                return lab
            }
        }
    }

    /// All labs, ordered by track then difficulty then title — a stable, teachable ramp.
    static let all: [InteractiveLab] = {
        let order = Dictionary(uniqueKeysWithValues: TrackKind.allCases.enumerated().map { ($1, $0) })
        return (inLesson + standalone).sorted {
            let (a, b) = (order[$0.track] ?? 0, order[$1.track] ?? 0)
            if a != b { return a < b }
            if $0.difficulty != $1.difficulty { return $0.difficulty < $1.difficulty }
            return $0.title < $1.title
        }
    }()

    static func lab(id: String) -> InteractiveLab? { all.first { $0.id == id } }

    static func labs(for track: TrackKind) -> [InteractiveLab] { all.filter { $0.track == track } }

    static var count: Int { all.count }

    /// Total practice minutes on offer — shown on the hub header.
    static var totalMinutes: Int { all.reduce(0) { $0 + $1.minutes } }
}
