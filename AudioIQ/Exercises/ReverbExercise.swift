import AVFoundation

enum ReverbType: String, CaseIterable, Identifiable {
    case dry = "Dry"
    case room = "Room"
    case hall = "Hall"
    case plate = "Plate"
    case cathedral = "Cathedral"

    var id: String { rawValue }

    var preset: AVAudioUnitReverbPreset {
        switch self {
        case .dry: return .smallRoom
        case .room: return .mediumRoom
        case .hall: return .largeHall
        case .plate: return .plate
        case .cathedral: return .cathedral
        }
    }

    var wetDryMix: Float {
        switch self {
        case .dry: return 0
        case .room: return 35
        case .hall: return 55
        case .plate: return 45
        case .cathedral: return 70
        }
    }
}

enum ReverbDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }

    var pool: [ReverbType] {
        switch self {
        case .easy: return [.dry, .cathedral, .room]
        case .medium: return [.dry, .room, .hall, .cathedral]
        case .hard: return [.room, .plate, .hall]
        }
    }
}

struct ReverbRound {
    let target: ReverbType
    let choices: [ReverbType]
    let correctIndex: Int
}

final class ReverbExerciseGenerator {
    func makeRound(difficulty: ReverbDifficulty) -> ReverbRound {
        let pool = difficulty.pool
        let target = pool.randomElement()!
        var choices = pool
        choices.shuffle()
        let correctIndex = choices.firstIndex(of: target)!
        return ReverbRound(target: target, choices: choices, correctIndex: correctIndex)
    }
}
