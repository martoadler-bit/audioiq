import SwiftUI

struct LimitingLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    @State private var amountT: Double = 1
    private static let steps = LimitAmount.allCases

    private var nearestAmount: LimitAmount {
        Self.steps[Int(amountT.rounded().clamped(to: 0...3))]
    }

    private var threshold: Float { interpolate(\.threshold) }
    private var headroom: Float { interpolate(\.headroom) }
    private var masterGain: Float { interpolate(\.masterGain) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("A limiter is a compressor with an almost-vertical ratio: it lets everything through until a ceiling, then refuses to let anything past it. Push toward Extreme and listen for the peaks getting caught, not the whole mix getting quieter.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                LabPlayButton(engine: engine)

                LimitVisualizerView(amount: nearestAmount)
                    .id(nearestAmount)

                labSlider(title: "Ceiling", value: nearestAmount.rawValue) {
                    Slider(value: $amountT, in: 0...3, step: 0.01)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Limiting Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
            apply()
        }
        .onDisappear { engine.stop() }
        .onChange(of: amountT) { _, _ in apply() }
    }

    private func interpolate(_ keyPath: KeyPath<LimitAmount, Float>) -> Float {
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
