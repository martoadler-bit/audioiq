import Foundation

enum SaturationType: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case subtle = "Subtle"
    case warm = "Warm"
    case hot = "Hot"

    var id: String { rawValue }

    var drive: Float {
        switch self {
        case .clean: return 1.001
        case .subtle: return 1.5
        case .warm: return 2.4
        case .hot: return 3.6
        }
    }
}

enum SaturationDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    var pool: [SaturationType] {
        switch self {
        case .easy: return [.clean, .hot]
        case .medium: return [.clean, .subtle, .warm, .hot]
        case .hard: return [.subtle, .warm]
        }
    }
}

struct SaturationRound {
    let target: SaturationType
    let choices: [SaturationType]
    let correctIndex: Int
}

final class SaturationExerciseGenerator {
    func makeRound(difficulty: SaturationDifficulty) -> SaturationRound {
        let pool = difficulty.pool
        let target = pool.randomElement()!
        var choices = pool
        choices.shuffle()
        let correctIndex = choices.firstIndex(of: target)!
        return SaturationRound(target: target, choices: choices, correctIndex: correctIndex)
    }
}
