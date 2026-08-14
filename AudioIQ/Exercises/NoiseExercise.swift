import Foundation

enum NoiseType: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case hum = "Hum (60Hz)"
    case hiss = "Hiss"
    case clicks = "Clicks / Pops"

    var id: String { rawValue }
}

enum NoiseDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    var pool: [NoiseType] {
        switch self {
        case .easy: return [.clean, .hum, .clicks]
        case .medium: return [.clean, .hum, .hiss, .clicks]
        case .hard: return [.hum, .hiss]
        }
    }
}

struct NoiseRound {
    let target: NoiseType
    let choices: [NoiseType]
    let correctIndex: Int
}

final class NoiseExerciseGenerator {
    func makeRound(difficulty: NoiseDifficulty) -> NoiseRound {
        let pool = difficulty.pool
        let target = pool.randomElement()!
        var choices = pool
        choices.shuffle()
        let correctIndex = choices.firstIndex(of: target)!
        return NoiseRound(target: target, choices: choices, correctIndex: correctIndex)
    }
}
