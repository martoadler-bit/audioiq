import Foundation

enum CodecType: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case high = "High Bitrate"
    case medium = "Medium Bitrate"
    case low = "Low Bitrate"

    var id: String { rawValue }

    /// One-pole lowpass coefficient — lower alpha means a darker, more muffled cutoff.
    var cutoffAlpha: Float {
        switch self {
        case .clean: return 1.01
        case .high: return 0.55
        case .medium: return 0.3
        case .low: return 0.14
        }
    }

    var quantLevels: Float {
        switch self {
        case .clean: return 0
        case .high: return 200
        case .medium: return 60
        case .low: return 22
        }
    }

    var noiseAmount: Float {
        switch self {
        case .clean: return 0
        case .high: return 0.004
        case .medium: return 0.012
        case .low: return 0.025
        }
    }
}

enum CodecDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    var pool: [CodecType] {
        switch self {
        case .easy: return [.clean, .low]
        case .medium: return [.clean, .high, .medium, .low]
        case .hard: return [.high, .medium]
        }
    }
}

struct CodecRound {
    let target: CodecType
    let choices: [CodecType]
    let correctIndex: Int
}

final class CodecExerciseGenerator {
    func makeRound(difficulty: CodecDifficulty) -> CodecRound {
        let pool = difficulty.pool
        let target = pool.randomElement()!
        var choices = pool
        choices.shuffle()
        let correctIndex = choices.firstIndex(of: target)!
        return CodecRound(target: target, choices: choices, correctIndex: correctIndex)
    }
}
