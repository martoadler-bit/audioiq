import Foundation

@MainActor
final class ReverbExerciseViewModel: ObservableObject {
    @Published var round: ReverbRound
    @Published var selected: ReverbType?
    @Published var isRevealed = false
    @Published var score = 0
    @Published var attempts = 0

    let engine: ProcessingAudioEngine
    private static var difficulty: ReverbDifficulty {
        switch AppSettings.shared.difficulty {
        case .beginner: return .easy
        case .intermediate: return .medium
        case .advanced: return .hard
        }
    }
    private let generator = ReverbExerciseGenerator()

    init(engine: ProcessingAudioEngine) {
        self.engine = engine
        self.round = generator.makeRound(difficulty: Self.difficulty)
        engine.resetAllProcessing()
        engine.loadRandomRealLoop()
    }

    func playReference() {
        engine.setReverb(preset: .smallRoom, wetDryMix: 0, enabled: false)
        engine.isPlaying ? engine.stop() : engine.playLooping()
    }

    func playProcessed() {
        engine.setReverb(preset: round.target.preset, wetDryMix: round.target.wetDryMix, enabled: true)
        engine.playLooping()
    }

    func select(_ type: ReverbType) {
        guard !isRevealed else { return }
        selected = type
        isRevealed = true
        attempts += 1
        let correct = type == round.target
        if correct { score += 1 }
        ProgressTracker.shared.record(module: "Reverb", correct: correct)
    }

    func next() {
        engine.stop()
        engine.loadRandomRealLoop()
        round = generator.makeRound(difficulty: Self.difficulty)
        selected = nil
        isRevealed = false
    }

}
