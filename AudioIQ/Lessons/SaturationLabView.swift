import SwiftUI

struct SaturationLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    @State private var type: SaturationType = .warm

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("A little saturation rounds off transients and adds harmonics without sounding \"broken\" the way hard distortion does — it's the difference between tape warmth and a blown speaker.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    engine.isPlaying ? engine.stop() : engine.playSaturated(type)
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

                SaturationVisualizerView(type: type)
                    .id(type)

                Picker("Amount", selection: $type) {
                    ForEach(SaturationType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Saturation Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
        }
        .onDisappear { engine.stop() }
        .onChange(of: type) { _, _ in if engine.isPlaying { engine.playSaturated(type) } }
    }
}
