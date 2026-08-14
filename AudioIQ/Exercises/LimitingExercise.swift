import Foundation

/// Same underlying AUDynamicsProcessor as the Compression module, but pushed toward a much
/// harder knee (near-zero headroom) — the audible difference between gentle compression and
/// a brickwall limiter is how suddenly loud peaks get caught, not how much overall gain changes.
enum LimitAmount: String, CaseIterable, Identifiable {
    case gentle = "Gentle"
    case moderate = "Moderate"
    case brickwall = "Brickwall"
    case extreme = "Extreme"

    var id: String { rawValue }

    var threshold: Float {
        switch self {
        case .gentle: return -6
        case .moderate: return -10
        case .brickwall: return -16
        case .extreme: return -24
        }
    }

    var headroom: Float {
        switch self {
        case .gentle: return 6
        case .moderate: return 2.5
        case .brickwall: return 0.5
        case .extreme: return 0.1
        }
    }

    var masterGain: Float {
        switch self {
        case .gentle: return 2
        case .moderate: return 5
        case .brickwall: return 9
        case .extreme: return 14
        }
    }
}

enum LimitDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    var pool: [LimitAmount] {
        switch self {
        case .easy: return [.gentle, .extreme]
        case .medium: return [.gentle, .moderate, .brickwall, .extreme]
        case .hard: return [.moderate, .brickwall]
        }
    }
}

struct LimitRound {
    let target: LimitAmount
    let choices: [LimitAmount]
    let correctIndex: Int
}

final class LimitingExerciseGenerator {
    func makeRound(difficulty: LimitDifficulty) -> LimitRound {
        let pool = difficulty.pool
        let target = pool.randomElement()!
        var choices = pool
        choices.shuffle()
        let correctIndex = choices.firstIndex(of: target)!
        return LimitRound(target: target, choices: choices, correctIndex: correctIndex)
    }
}
