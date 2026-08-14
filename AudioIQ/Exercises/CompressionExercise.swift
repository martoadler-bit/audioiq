import Foundation

/// Named compression amounts, each a (threshold, headroom, makeup gain) preset for
/// Apple's AUDynamicsProcessor. Headroom drives the effective ratio: lower headroom = harder knee.
enum CompressionAmount: String, CaseIterable, Identifiable {
    case subtle = "Subtle"
    case moderate = "Moderate"
    case heavy = "Heavy"
    case extreme = "Extreme"

    var id: String { rawValue }

    var threshold: Float {
        switch self {
        case .subtle: return -12
        case .moderate: return -20
        case .heavy: return -28
        case .extreme: return -36
        }
    }

    var headroom: Float {
        switch self {
        case .subtle: return 10
        case .moderate: return 6
        case .heavy: return 3
        case .extreme: return 1
        }
    }

    var masterGain: Float {
        switch self {
        case .subtle: return 2
        case .moderate: return 5
        case .heavy: return 8
        case .extreme: return 11
        }
    }
}

enum CompressionDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    /// Which amounts are in play — easy contrasts extremes, hard makes neighbors that are
    /// closer to each other and thus harder to tell apart.
    var pool: [CompressionAmount] {
        switch self {
        case .easy: return [.subtle, .extreme]
        case .medium: return [.subtle, .moderate, .heavy, .extreme]
        case .hard: return [.moderate, .heavy]
        }
    }
}

struct CompressionRound {
    let target: CompressionAmount
    let choices: [CompressionAmount]
    let correctIndex: Int
}

final class CompressionExerciseGenerator {
    func makeRound(difficulty: CompressionDifficulty) -> CompressionRound {
        let pool = difficulty.pool
        let target = pool.randomElement()!
        var choices = pool
        choices.shuffle()
        let correctIndex = choices.firstIndex(of: target)!
        return CompressionRound(target: target, choices: choices, correctIndex: correctIndex)
    }
}
