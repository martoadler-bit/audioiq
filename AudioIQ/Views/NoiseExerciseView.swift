import SwiftUI

struct NoiseExerciseView: View {
    @StateObject private var vm: NoiseExerciseViewModel

    init(engine: ProcessingAudioEngine) {
        _vm = StateObject(wrappedValue: NoiseExerciseViewModel(engine: engine))
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            Text("What noise artifact is present?")
                .font(.title3.bold())
                .foregroundStyle(DS.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                playButton(title: "Original", systemImage: "waveform", action: vm.playReference)
                playButton(title: "Processed", systemImage: "waveform.badge.exclamationmark", action: vm.playProcessed)
            }

            VStack(spacing: 12) {
                ForEach(vm.round.choices) { type in
                    choiceButton(type)
                }
            }

            if vm.isRevealed {
                NoiseVisualizerView(type: vm.round.target)
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

    private var moduleColor: Color { DS.moduleColor("Noise") }

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

    private func choiceButton(_ type: NoiseType) -> some View {
        let isCorrect = type == vm.round.target
        let isSelected = type == vm.selected

        var background: Color = DS.card
        if vm.isRevealed {
            if isCorrect { background = DS.correct.opacity(0.3) }
            else if isSelected { background = DS.wrong.opacity(0.3) }
        }

        return Button {
            vm.select(type)
        } label: {
            HStack {
                Text(type.rawValue)
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
