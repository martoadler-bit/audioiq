import Foundation

@MainActor
final class CompressionExerciseViewModel: ObservableObject {
    @Published var round: CompressionRound
    @Published var selected: CompressionAmount?
    @Published var isRevealed = false
    @Published var score = 0
    @Published var attempts = 0

    let engine: ProcessingAudioEngine
    private static var difficulty: CompressionDifficulty {
        switch AppSettings.shared.difficulty {
        case .beginner: return .easy
        case .intermediate: return .medium
        case .advanced: return .hard
        }
    }
    private let generator = CompressionExerciseGenerator()

    init(engine: ProcessingAudioEngine) {
        self.engine = engine
        self.round = generator.makeRound(difficulty: Self.difficulty)
        engine.resetAllProcessing()
        engine.loadRandomRealLoop()
    }

    func playReference() {
        engine.setCompression(threshold: 0, headroom: 0, masterGain: 0, enabled: false)
        engine.isPlaying ? engine.stop() : engine.playLooping()
    }

    func playProcessed() {
        engine.setCompression(
            threshold: round.target.threshold,
            headroom: round.target.headroom,
            masterGain: round.target.masterGain,
            enabled: true
        )
        engine.playLooping()
    }

    func select(_ amount: CompressionAmount) {
        guard !isRevealed else { return }
        selected = amount
        isRevealed = true
        attempts += 1
        let correct = amount == round.target
        if correct { score += 1 }
        ProgressTracker.shared.record(module: "Compression", correct: correct)
    }

    func next() {
        engine.stop()
        engine.loadRandomRealLoop()
        round = generator.makeRound(difficulty: Self.difficulty)
        selected = nil
        isRevealed = false
    }

}
