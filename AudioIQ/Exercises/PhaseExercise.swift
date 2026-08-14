import Foundation

enum PhaseType: String, CaseIterable, Identifiable {
    case normal = "Unchanged"
    case mono = "Mono"
    case wide = "Wide"
    case outOfPhase = "Out of Phase"

    var id: String { rawValue }
}

enum PhaseDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    var pool: [PhaseType] {
        switch self {
        case .easy: return [.normal, .mono, .outOfPhase]
        case .medium: return [.normal, .mono, .wide, .outOfPhase]
        case .hard: return [.normal, .wide]
        }
    }
}

struct PhaseRound {
    let target: PhaseType
    let choices: [PhaseType]
    let correctIndex: Int
}

final class PhaseExerciseGenerator {
    func makeRound(difficulty: PhaseDifficulty) -> PhaseRound {
        let pool = difficulty.pool
        let target = pool.randomElement()!
        var choices = pool
        choices.shuffle()
        let correctIndex = choices.firstIndex(of: target)!
        return PhaseRound(target: target, choices: choices, correctIndex: correctIndex)
    }
}
