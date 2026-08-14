import Foundation

@MainActor
final class LoudnessExerciseViewModel: ObservableObject {
    @Published var round: LoudnessRound
    @Published var selected: LoudnessChoice?
    @Published var isRevealed = false
    @Published var score = 0
    @Published var attempts = 0

    let engine: ProcessingAudioEngine
    private static var difficulty: LoudnessDifficulty {
        switch AppSettings.shared.difficulty {
        case .beginner: return .easy
        case .intermediate: return .medium
        case .advanced: return .hard
        }
    }
    private let generator = LoudnessExerciseGenerator()

    init(engine: ProcessingAudioEngine) {
        self.engine = engine
        self.round = generator.makeRound(difficulty: Self.difficulty)
        engine.resetAllProcessing()
        engine.loadRandomRealLoop()
    }

    func playReference() {
        engine.setLoudness(gainDB: 0)
        engine.isPlaying ? engine.stop() : engine.playLooping()
    }

    func playProcessed() {
        engine.setLoudness(gainDB: round.targetDelta)
        engine.playLooping()
    }

    func select(_ choice: LoudnessChoice) {
        guard !isRevealed else { return }
        selected = choice
        isRevealed = true
        attempts += 1
        let correct = choice.deltaDB == round.targetDelta
        if correct { score += 1 }
        ProgressTracker.shared.record(module: "Loudness", correct: correct)
    }

    func next() {
        engine.stop()
        engine.setLoudness(gainDB: 0)
        engine.loadRandomRealLoop()
        round = generator.makeRound(difficulty: Self.difficulty)
        selected = nil
        isRevealed = false
    }

}
