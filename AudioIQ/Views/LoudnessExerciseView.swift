import SwiftUI

struct LoudnessExerciseView: View {
    @StateObject private var vm: LoudnessExerciseViewModel

    init(engine: ProcessingAudioEngine) {
        _vm = StateObject(wrappedValue: LoudnessExerciseViewModel(engine: engine))
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            Text("How many dB louder or quieter is the processed version?")
                .font(.title3.bold())
                .foregroundStyle(DS.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                playButton(title: "Original", systemImage: "waveform", action: vm.playReference)
                playButton(title: "Processed", systemImage: "speaker.wave.3", action: vm.playProcessed)
            }

            VStack(spacing: 12) {
                ForEach(vm.round.choices) { choice in
                    choiceButton(choice)
                }
            }

            if vm.isRevealed {
                LoudnessVisualizerView(deltaDB: vm.round.targetDelta)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .id(vm.round.targetDelta)

                Button("Next") { vm.next() }
                    .buttonStyle(.borderedProminent)
                    .tint(moduleColor)
                    .bouncy()
            }

            Spacer()
        }
        .padding()
        .appBackground()
        .onDisappear { vm.engine.stop() }
    }

    private var moduleColor: Color { DS.moduleColor("Loudness") }

    private var header: some View {
        HStack {
            Text(AppSettings.shared.difficulty.rawValue)
                .font(.subheadline.bold())
                .foregroundStyle(moduleColor)
            Spacer()
            Text("\(vm.score)/\(vm.attempts)")
                .foregroundStyle(DS.subtext)
        }
    }

    private func playButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage).font(.title2)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(DS.text)
        }
        .bouncy()
    }

    private func choiceButton(_ choice: LoudnessChoice) -> some View {
        let isCorrect = choice.deltaDB == vm.round.targetDelta
        let isSelected = choice == vm.selected

        var background: Color = DS.card
        if vm.isRevealed {
            if isCorrect { background = DS.correct.opacity(0.3) }
            else if isSelected { background = DS.wrong.opacity(0.3) }
        }

        return Button {
            vm.select(choice)
        } label: {
            HStack {
                Text(choice.label)
                    .font(.headline)
                Spacer()
                if vm.isRevealed && isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(DS.correct)
                } else if vm.isRevealed && isSelected {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(DS.wrong)
                }
            }
            .padding()
            .background(background, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(DS.text)
            .overlay(alignment: .trailing) {
                if vm.isRevealed && isCorrect {
                    CelebrationBurst(color: DS.correct).padding(.trailing, 24)
                }
            }
        }
        .disabled(vm.isRevealed)
        .bouncy()
    }
}
