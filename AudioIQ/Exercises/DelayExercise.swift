import Foundation

enum DelayAmount: String, CaseIterable, Identifiable {
    case short = "Short"
    case medium = "Medium"
    case long = "Long"
    case extreme = "Extreme"

    var id: String { rawValue }

    var time: TimeInterval {
        switch self {
        case .short: return 0.08
        case .medium: return 0.22
        case .long: return 0.45
        case .extreme: return 0.85
        }
    }

    var feedback: Float {
        switch self {
        case .short: return 15
        case .medium: return 25
        case .long: return 35
        case .extreme: return 45
        }
    }

    var wetDryMix: Float { 35 }
}

enum DelayDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    var pool: [DelayAmount] {
        switch self {
        case .easy: return [.short, .extreme]
        case .medium: return [.short, .medium, .long, .extreme]
        case .hard: return [.medium, .long]
        }
    }
}

struct DelayRound {
    let target: DelayAmount
    let choices: [DelayAmount]
    let correctIndex: Int
}

final class DelayExerciseGenerator {
    func makeRound(difficulty: DelayDifficulty) -> DelayRound {
        let pool = difficulty.pool
        let target = pool.randomElement()!
        var choices = pool
        choices.shuffle()
        let correctIndex = choices.firstIndex(of: target)!
        return DelayRound(target: target, choices: choices, correctIndex: correctIndex)
    }
}
