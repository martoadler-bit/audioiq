import SwiftUI

struct ReverbLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    @State private var space: ReverbType = .room
    @State private var mix: Double = 40

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Reverb simulates a physical space by layering thousands of reflections after the direct sound. Bigger, harder rooms produce longer, denser tails.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                LabPlayButton(engine: engine)

                ReverbVisualizerView(type: space)
                    .id(space)

                Picker("Space", selection: $space) {
                    ForEach(ReverbType.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)

                labSlider(title: "Mix", value: String(format: "%.0f%%", mix)) {
                    Slider(value: $mix, in: 0...100)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Reverb Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
            apply()
        }
        .onDisappear { engine.stop() }
        .onChange(of: space) { _, _ in apply() }
        .onChange(of: mix) { _, _ in apply() }
    }

    private func apply() {
        engine.setReverb(preset: space.preset, wetDryMix: Float(mix), enabled: true)
    }
}
