import SwiftUI
import AVFoundation

struct DistortionLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    private enum Character: String, CaseIterable, Identifiable {
        case mild = "Mild", gritty = "Gritty", extreme = "Extreme"
        var id: String { rawValue }

        var preset: AVAudioUnitDistortionPreset {
            switch self {
            case .mild: return .multiDistortedFunk
            case .gritty: return .drumsBitBrush
            case .extreme: return .multiEverythingIsBroken
            }
        }

        /// Purely visual — approximates how aggressive each character reads on the waveform.
        var visualDriveRange: ClosedRange<Float> {
            switch self {
            case .mild: return 1...5
            case .gritty: return 4...12
            case .extreme: return 10...24
            }
        }
    }

    @State private var character: Character = .mild
    @State private var mix: Double = 0

    private var visualDrive: Float {
        let range = character.visualDriveRange
        return range.lowerBound + (range.upperBound - range.lowerBound) * Float(mix / 100)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Distortion adds harmonics by clipping the waveform. Mix controls how much of that clipped signal blends with the clean original — push it up to hear the character take over.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                LabPlayButton(engine: engine)

                LiveDistortionVisualizerView(drive: visualDrive)

                Picker("Character", selection: $character) {
                    ForEach(Character.allCases) { c in
                        Text(c.rawValue).tag(c)
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
        .navigationTitle("Distortion Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
            apply()
        }
        .onDisappear { engine.stop() }
        .onChange(of: character) { _, _ in apply() }
        .onChange(of: mix) { _, _ in apply() }
    }

    private func apply() {
        engine.setLiveDistortion(preset: character.preset, wetDryMix: Float(mix), enabled: true)
    }
}
