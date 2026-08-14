import Foundation
import Combine

@MainActor
final class EQExerciseViewModel: ObservableObject {
    @Published var round: EQRound
    @Published var selectedChoice: EQChoice?
    @Published var isRevealed = false
    @Published var score = 0
    @Published var attempts = 0

    let engine: ProcessingAudioEngine
    private static var difficulty: EQDifficulty {
        switch AppSettings.shared.difficulty {
        case .beginner: return .easy
        case .intermediate: return .medium
        case .advanced: return .hard
        }
    }
    private let generator = EQExerciseGenerator()

    init(engine: ProcessingAudioEngine) {
        self.engine = engine
        self.round = generator.makeRound(difficulty: Self.difficulty)
        engine.resetAllProcessing()
        engine.loadRandomRealLoop()
    }

    func toggleReference() {
        engine.setEQ(frequency: round.targetFrequency, gain: 0, enabled: false)
        engine.isPlaying ? engine.stop() : engine.playLooping()
    }

    func playProcessed() {
        engine.setEQ(frequency: round.targetFrequency, gain: round.gain, enabled: true)
        engine.playLooping()
    }

    func select(_ choice: EQChoice) {
        guard !isRevealed else { return }
        selectedChoice = choice
        isRevealed = true
        attempts += 1
        let correct = choice.frequency == round.targetFrequency
        if correct { score += 1 }
        ProgressTracker.shared.record(module: "EQ", correct: correct)
    }

    func next() {
        engine.stop()
        engine.loadRandomRealLoop()
        round = generator.makeRound(difficulty: Self.difficulty, cutInsteadOfBoost: Bool.random())
        selectedChoice = nil
        isRevealed = false
    }

}
