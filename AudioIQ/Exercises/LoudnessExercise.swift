import Foundation

struct LoudnessChoice: Identifiable, Equatable {
    let id = UUID()
    let deltaDB: Float

    var label: String {
        deltaDB >= 0 ? "+\(String(format: "%.1f", deltaDB)) dB" : "\(String(format: "%.1f", deltaDB)) dB"
    }
}

struct LoudnessRound {
    let targetDelta: Float
    let choices: [LoudnessChoice]
    let correctIndex: Int
}

enum LoudnessDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    var deltaPool: [Float] {
        switch self {
        case .easy: return [-10, -6, 6, 10]
        case .medium: return [-6, -3, 3, 6]
        case .hard: return [-3, -1.5, 1.5, 3]
        }
    }
}

final class LoudnessExerciseGenerator {
    func makeRound(difficulty: LoudnessDifficulty) -> LoudnessRound {
        let pool = difficulty.deltaPool
        let targetIndex = Int.random(in: 0..<pool.count)
        let target = pool[targetIndex]

        var choices = pool.map { LoudnessChoice(deltaDB: $0) }
        choices.shuffle()
        let correctIndex = choices.firstIndex { $0.deltaDB == target }!

        return LoudnessRound(targetDelta: target, choices: choices, correctIndex: correctIndex)
    }
}
