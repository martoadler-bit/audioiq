import SwiftUI

struct DelayLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    @State private var time: Double = 0.25
    @State private var feedback: Double = 25
    @State private var mix: Double = 30

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Delay repeats the signal after a set time. Feedback controls how many repeats you hear — low values give a single slapback, high values trail off for seconds.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                LabPlayButton(engine: engine)

                DelayVisualizerView(time: time, feedback: Float(feedback), label: "Live")

                labSlider(title: "Time", value: String(format: "%.0f ms", time * 1000)) {
                    Slider(value: $time, in: 0.03...0.9)
                }

                labSlider(title: "Feedback", value: String(format: "%.0f%%", feedback)) {
                    Slider(value: $feedback, in: 0...70)
                }

                labSlider(title: "Mix", value: String(format: "%.0f%%", mix)) {
                    Slider(value: $mix, in: 0...100)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Delay Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
            apply()
        }
        .onDisappear { engine.stop() }
        .onChange(of: time) { _, _ in apply() }
        .onChange(of: feedback) { _, _ in apply() }
        .onChange(of: mix) { _, _ in apply() }
    }

    private func apply() {
        engine.setDelay(time: time, feedback: Float(feedback), wetDryMix: Float(mix), enabled: true)
    }
}
