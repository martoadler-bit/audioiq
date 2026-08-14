import Foundation

@MainActor
final class PhaseExerciseViewModel: ObservableObject {
    @Published var round: PhaseRound
    @Published var selected: PhaseType?
    @Published var isRevealed = false
    @Published var score = 0
    @Published var attempts = 0

    let engine: ProcessingAudioEngine
    private static var difficulty: PhaseDifficulty {
        switch AppSettings.shared.difficulty {
        case .beginner: return .easy
        case .intermediate: return .medium
        case .advanced: return .hard
        }
    }
    private let generator = PhaseExerciseGenerator()

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
        engine.playPhaseShifted(round.target)
    }

    func select(_ type: PhaseType) {
        guard !isRevealed else { return }
        selected = type
        isRevealed = true
        attempts += 1
        let correct = type == round.target
        if correct { score += 1 }
        ProgressTracker.shared.record(module: "Phase", correct: correct)
    }

    func next() {
        engine.stop()
        engine.loadRandomRealLoop()
        round = generator.makeRound(difficulty: Self.difficulty)
        selected = nil
        isRevealed = false
    }

}
