import Foundation

@MainActor
final class SaturationExerciseViewModel: ObservableObject {
    @Published var round: SaturationRound
    @Published var selected: SaturationType?
    @Published var isRevealed = false
    @Published var score = 0
    @Published var attempts = 0

    let engine: ProcessingAudioEngine
    private static var difficulty: SaturationDifficulty {
        switch AppSettings.shared.difficulty {
        case .beginner: return .easy
        case .intermediate: return .medium
        case .advanced: return .hard
        }
    }
    private let generator = SaturationExerciseGenerator()

    init(engine: ProcessingAudioEngine) {
        self.engine = engine
        self.round = generator.makeRound(difficulty: Self.difficulty)
        engine.resetAllProcessing()
        engine.loadRandomRealLoop()
    }

    func playReference() {
        engine.isPlaying ? engine.stop() : engine.playLooping()
    }

    func playProcessed() {
        engine.playSaturated(round.target)
    }

    func select(_ type: SaturationType) {
        guard !isRevealed else { return }
        selected = type
        isRevealed = true
        attempts += 1
        let correct = type == round.target
        if correct { score += 1 }
        ProgressTracker.shared.record(module: "Saturation", correct: correct)
    }

    func next() {
        engine.stop()
        engine.loadRandomRealLoop()
        round = generator.makeRound(difficulty: Self.difficulty)
        selected = nil
        isRevealed = false
    }

}
