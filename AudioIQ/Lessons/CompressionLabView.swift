import SwiftUI

struct CompressionLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    /// 0...3 continuous, interpolating between the named amounts so the knob feels smooth
    /// while still landing on the same threshold/headroom/gain values the quiz teaches.
    @State private var amountT: Double = 1

    private static let steps = CompressionAmount.allCases

    private var nearestAmount: CompressionAmount {
        Self.steps[Int(amountT.rounded().clamped(to: 0...3))]
    }

    private var threshold: Float { interpolate(\.threshold) }
    private var headroom: Float { interpolate(\.headroom) }
    private var masterGain: Float { interpolate(\.masterGain) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("A compressor turns down anything louder than the threshold. A lower threshold and harder ratio squash the signal more, flattening its dynamics.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                LabPlayButton(engine: engine)

                CompressionVisualizerView(amount: nearestAmount)
                    .id(nearestAmount)

                labSlider(title: "Amount", value: nearestAmount.rawValue) {
                    Slider(value: $amountT, in: 0...3, step: 0.01)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Compression Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
            apply()
        }
        .onDisappear { engine.stop() }
        .onChange(of: amountT) { _, _ in apply() }
    }

    private func interpolate(_ keyPath: KeyPath<CompressionAmount, Float>) -> Float {
        let lower = Self.steps[Int(amountT.rounded(.down)).clamped(to: 0...3)]
        let upper = Self.steps[Int(amountT.rounded(.up)).clamped(to: 0...3)]
        let frac = Float(amountT - amountT.rounded(.down))
        return lower[keyPath: keyPath] + (upper[keyPath: keyPath] - lower[keyPath: keyPath]) * frac
    }

    private func apply() {
        engine.setCompression(threshold: threshold, headroom: headroom, masterGain: masterGain, enabled: true)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
