import SwiftUI

struct PhaseLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    @State private var type: PhaseType = .normal

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("What you hear on headphones can vanish on a mono speaker if the channels cancel. Try Out of Phase and imagine that being your kick drum live at a festival.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    engine.isPlaying ? engine.stop() : engine.playPhaseShifted(type)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                        Text(engine.isPlaying ? "Playing" : "Play loop")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(engine.isPlaying ? DS.accent.opacity(0.25) : DS.accent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(engine.isPlaying ? DS.accent : DS.background)
                }
                .animation(.easeOut(duration: 0.2), value: engine.isPlaying)
                .bouncy(0.97)

                PhaseVisualizerView(type: type)
                    .id(type)

                Picker("Image", selection: $type) {
                    ForEach(PhaseType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Phase Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
        }
        .onDisappear { engine.stop() }
        .onChange(of: type) { _, _ in if engine.isPlaying { engine.playPhaseShifted(type) } }
    }
}
