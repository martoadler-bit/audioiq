import SwiftUI

struct LoudnessLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    @State private var gainDB: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Our ears judge \"better\" largely by \"louder\" — even a couple dB can trick you into thinking a mix sounds improved. Ride the fader and notice how quickly perceived loudness shifts.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                LabPlayButton(engine: engine)

                LoudnessVisualizerView(deltaDB: Float(gainDB))

                labSlider(title: "Gain", value: String(format: "%+.1f dB", gainDB)) {
                    Slider(value: $gainDB, in: -20...20)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Loudness Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
            apply()
        }
        .onDisappear { engine.stop() }
        .onChange(of: gainDB) { _, _ in apply() }
    }

    private func apply() {
        engine.setLoudness(gainDB: Float(gainDB))
    }
}
