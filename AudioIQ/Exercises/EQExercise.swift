import Foundation

struct EQChoice: Identifiable, Equatable {
    let id = UUID()
    let frequency: Float

    var label: String {
        frequency >= 1000 ? "\(String(format: "%.1f", frequency / 1000))kHz" : "\(Int(frequency))Hz"
    }
}

struct EQRound {
    let targetFrequency: Float
    let gain: Float
    let choices: [EQChoice]
    let correctIndex: Int
}

enum EQDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    var gainRange: ClosedRange<Float> {
        switch self {
        case .easy: return 9...12
        case .medium: return 5...8
        case .hard: return 2...4
        }
    }

    /// Standard octave-ish band centers used across ear-training tools like this one.
    var bandPool: [Float] {
        switch self {
        case .easy: return [100, 250, 630, 1600, 4000, 10000]
        case .medium: return [80, 160, 320, 630, 1250, 2500, 5000, 10000]
        case .hard: return [63, 100, 160, 250, 400, 630, 1000, 1600, 2500, 4000, 6300, 10000, 16000]
        }
    }
}

final class EQExerciseGenerator {
    func makeRound(difficulty: EQDifficulty, cutInsteadOfBoost: Bool = false) -> EQRound {
        let pool = difficulty.bandPool
        let targetIndex = Int.random(in: 0..<pool.count)
        let target = pool[targetIndex]

        var distractorIndices = Set<Int>()
        while distractorIndices.count < 3 {
            let idx = Int.random(in: 0..<pool.count)
            if idx != targetIndex { distractorIndices.insert(idx) }
        }

        var optionIndices = Array(distractorIndices) + [targetIndex]
        optionIndices.shuffle()
        let correctIndex = optionIndices.firstIndex(of: targetIndex)!
        let choices = optionIndices.map { EQChoice(frequency: pool[$0]) }

        let gainMagnitude = Float.random(in: difficulty.gainRange)
        let gain = cutInsteadOfBoost ? -gainMagnitude : gainMagnitude

        return EQRound(targetFrequency: target, gain: gain, choices: choices, correctIndex: correctIndex)
    }
}
