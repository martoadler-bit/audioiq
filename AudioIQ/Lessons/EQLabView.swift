import SwiftUI

struct EQLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    @State private var freqT: Double = 0.45
    @State private var gain: Double = 8

    private var frequency: Float { Float(20 * pow(1000, freqT)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("A parametric EQ boosts or cuts a narrow band around one frequency. Sweep it across the spectrum and listen for the band that makes the mix feel boxy, harsh, or boomy.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                LabPlayButton(engine: engine)

                EQVisualizerView(frequency: frequency, gain: Float(gain))

                labSlider(title: "Frequency", value: freqLabel) {
                    Slider(value: $freqT, in: 0...1)
                }

                labSlider(title: "Gain", value: String(format: "%+.1f dB", gain)) {
                    Slider(value: $gain, in: -15...15)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("EQ Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
            apply()
        }
        .onDisappear { engine.stop() }
        .onChange(of: freqT) { _, _ in apply() }
        .onChange(of: gain) { _, _ in apply() }
    }

    private var freqLabel: String {
        frequency >= 1000 ? String(format: "%.1f kHz", frequency / 1000) : String(format: "%.0f Hz", frequency)
    }

    private func apply() {
        engine.setEQ(frequency: frequency, gain: Float(gain), enabled: true)
    }
}
