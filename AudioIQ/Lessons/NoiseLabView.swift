import SwiftUI

struct NoiseLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    @State private var type: NoiseType = .hum

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Every recording chain can pick up unwanted artifacts: ground-loop hum, self-noise hiss, or clicks from a bad connection. Learning to spot them by ear is half of troubleshooting.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    engine.isPlaying ? engine.stop() : engine.playNoisy(type)
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

                NoiseVisualizerView(type: type)
                    .id(type)

                Picker("Artifact", selection: $type) {
                    ForEach(NoiseType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Noise Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
        }
        .onDisappear { engine.stop() }
        .onChange(of: type) { _, _ in if engine.isPlaying { engine.playNoisy(type) } }
    }
}
