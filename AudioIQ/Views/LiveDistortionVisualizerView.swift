import SwiftUI

/// Continuous version of DistortionVisualizerView's waveform — driven directly by a live
/// "drive" slider instead of a fixed DistortionType, so it redraws smoothly as the user drags.
struct LiveDistortionVisualizerView: View {
    /// 1 = clean, higher = harder tanh saturation, matching the quiz's overdrive/fuzz math.
    let drive: Float

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            var path = Path()
            let steps = 160
            let norm = tanh(Double(drive))
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let x = t * 2
                let raw = sin(x * .pi * 2)
                let shaped = norm > 0.0001 ? tanh(raw * Double(drive)) / norm : raw
                let y = midY - CGFloat(shaped) * midY * 0.85
                let px = CGFloat(t) * size.width
                if i == 0 { path.move(to: CGPoint(x: px, y: y)) }
                else { path.addLine(to: CGPoint(x: px, y: y)) }
            }
            context.stroke(path, with: .color(DS.accent), lineWidth: 2)

            var zero = Path()
            zero.move(to: CGPoint(x: 0, y: midY))
            zero.addLine(to: CGPoint(x: size.width, y: midY))
            context.stroke(zero, with: .color(DS.subtext.opacity(0.25)), lineWidth: 1)
        }
        .frame(height: 110)
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
    }
}
