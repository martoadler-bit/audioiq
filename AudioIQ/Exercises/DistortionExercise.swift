import Foundation

enum DistortionType: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case overdrive = "Soft overdrive"
    case fuzz = "Hard fuzz"
    case digitalClip = "Digital clipping"
    case bitcrush = "Bitcrush / Aliasing"

    var id: String { rawValue }
}

enum DistortionDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    /// Easy contrasts wildly different characters; hard picks neighbors that share a
    /// similar harshness and are genuinely tricky to tell apart by ear.
    var pool: [DistortionType] {
        switch self {
        case .easy: return [.clean, .fuzz, .bitcrush]
        case .medium: return [.overdrive, .fuzz, .digitalClip, .bitcrush]
        case .hard: return [.overdrive, .digitalClip]
        }
    }
}

struct DistortionRound {
    let target: DistortionType
    let choices: [DistortionType]
    let correctIndex: Int
}

final class DistortionExerciseGenerator {
    func makeRound(difficulty: DistortionDifficulty) -> DistortionRound {
        let pool = difficulty.pool
        let target = pool.randomElement()!
        var choices = pool
        choices.shuffle()
        let correctIndex = choices.firstIndex(of: target)!
        return DistortionRound(target: target, choices: choices, correctIndex: correctIndex)
    }
}
