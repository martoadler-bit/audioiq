import SwiftUI

struct LimitingExerciseView: View {
    @StateObject private var vm: LimitingExerciseViewModel

    init(engine: ProcessingAudioEngine) {
        _vm = StateObject(wrappedValue: LimitingExerciseViewModel(engine: engine))
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            Text("How hard is the limiter working?")
                .font(.title3.bold())
                .foregroundStyle(DS.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                playButton(title: "Original", systemImage: "waveform", action: vm.playReference)
                playButton(title: "Processed", systemImage: "water.waves", action: vm.playProcessed)
            }

            VStack(spacing: 12) {
                ForEach(vm.round.choices) { amount in
                    choiceButton(amount)
                }
            }

            if vm.isRevealed {
                LimitVisualizerView(amount: vm.round.target)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .id(vm.round.target)

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

    private var moduleColor: Color { DS.moduleColor("Limiting") }

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

    private func choiceButton(_ amount: LimitAmount) -> some View {
        let isCorrect = amount == vm.round.target
        let isSelected = amount == vm.selected

        var background: Color = DS.card
        if vm.isRevealed {
            if isCorrect { background = DS.correct.opacity(0.3) }
            else if isSelected { background = DS.wrong.opacity(0.3) }
        }

        return Button {
            vm.select(amount)
        } label: {
            HStack {
                Text(amount.rawValue)
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
