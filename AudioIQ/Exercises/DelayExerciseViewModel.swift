import Foundation

@MainActor
final class DelayExerciseViewModel: ObservableObject {
    @Published var round: DelayRound
    @Published var selected: DelayAmount?
    @Published var isRevealed = false
    @Published var score = 0
    @Published var attempts = 0

    let engine: ProcessingAudioEngine
    private static var difficulty: DelayDifficulty {
        switch AppSettings.shared.difficulty {
        case .beginner: return .easy
        case .intermediate: return .medium
        case .advanced: return .hard
        }
    }
    private let generator = DelayExerciseGenerator()

    init(engine: ProcessingAudioEngine) {
        self.engine = engine
        self.round = generator.makeRound(difficulty: Self.difficulty)
        engine.resetAllProcessing()
        engine.loadRandomRealLoop()
    }

    func playReference() {
        engine.setDelay(time: 0, feedback: 0, wetDryMix: 0, enabled: false)
        engine.isPlaying ? engine.stop() : engine.playLooping()
    }

    func playProcessed() {
        engine.setDelay(time: round.target.time, feedback: round.target.feedback, wetDryMix: round.target.wetDryMix, enabled: true)
        engine.playLooping()
    }

    func select(_ amount: DelayAmount) {
        guard !isRevealed else { return }
        selected = amount
        isRevealed = true
        attempts += 1
        let correct = amount == round.target
        if correct { score += 1 }
        ProgressTracker.shared.record(module: "Delay", correct: correct)
    }

    func next() {
        engine.stop()
        engine.loadRandomRealLoop()
        round = generator.makeRound(difficulty: Self.difficulty)
        selected = nil
        isRevealed = false
    }

}
