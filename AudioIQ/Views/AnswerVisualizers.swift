import SwiftUI

// MARK: - EQ: animated frequency-response curve with a bump/dip at the target band

struct EQVisualizerView: View {
    let frequency: Float
    let gain: Float

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(gain >= 0 ? "+\(String(format: "%.1f", gain)) dB at \(label)" : "\(String(format: "%.1f", gain)) dB at \(label)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let baselineY = size.height * 0.55
                var path = Path()
                let steps = 120
                for i in 0...steps {
                    let t = CGFloat(i) / CGFloat(steps)
                    let freq = logFrequency(at: t)
                    let y = baselineY - curveOffset(freq: freq)
                    let x = t * size.width
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }

                var fillPath = path
                fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
                fillPath.addLine(to: CGPoint(x: 0, y: size.height))
                fillPath.closeSubpath()
                context.fill(fillPath, with: .linearGradient(
                    Gradient(colors: [DS.accent.opacity(0.35), DS.accent.opacity(0.02)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

                context.stroke(path, with: .color(DS.accent), lineWidth: 2)

                var baseline = Path()
                baseline.move(to: CGPoint(x: 0, y: baselineY))
                baseline.addLine(to: CGPoint(x: size.width, y: baselineY))
                context.stroke(baseline, with: .color(DS.subtext.opacity(0.3)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                let markerT = logPosition(for: Double(frequency))
                let markerX = markerT * size.width
                let markerY = baselineY - curveOffset(freq: Double(frequency))
                context.fill(Path(ellipseIn: CGRect(x: markerX - 4, y: markerY - 4, width: 8, height: 8)), with: .color(DS.accent))
            }
            .frame(height: 110)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }

    private var label: String {
        frequency >= 1000 ? "\(String(format: "%.1f", frequency / 1000))kHz" : "\(Int(frequency))Hz"
    }

    private func logPosition(for freq: Double) -> CGFloat {
        let minF = log10(20.0), maxF = log10(20000.0)
        return CGFloat((log10(freq) - minF) / (maxF - minF))
    }

    private func logFrequency(at t: CGFloat) -> Double {
        let minF = log10(20.0), maxF = log10(20000.0)
        return pow(10, minF + Double(t) * (maxF - minF))
    }

    private func curveOffset(freq: Double) -> CGFloat {
        let sigma = 0.22
        let d = log10(freq) - log10(Double(frequency))
        let bump = exp(-(d * d) / (2 * sigma * sigma))
        return CGFloat(Double(gain) * bump) * 2.2
    }
}

// MARK: - Compression: input vs. compressed waveform against a threshold line

struct CompressionVisualizerView: View {
    let amount: CompressionAmount

    @State private var appeared = false
    private let bars: [CGFloat] = (0..<24).map { i in
        let t = Double(i) / 24
        return CGFloat(0.35 + 0.6 * abs(sin(t * .pi * 3.7)) )
    }

    private var thresholdLevel: CGFloat {
        switch amount {
        case .subtle: return 0.75
        case .moderate: return 0.55
        case .heavy: return 0.4
        case .extreme: return 0.25
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gain reduction: \(amount.rawValue.lowercased())")
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let thresholdY = size.height * (1 - thresholdLevel)
                var thresholdPath = Path()
                thresholdPath.move(to: CGPoint(x: 0, y: thresholdY))
                thresholdPath.addLine(to: CGPoint(x: size.width, y: thresholdY))
                context.stroke(thresholdPath, with: .color(DS.wrong.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                let barWidth = size.width / CGFloat(bars.count)
                for (i, level) in bars.enumerated() {
                    let compressedLevel = min(level, thresholdLevel + (level - thresholdLevel).clamped(to: 0...1) * 0.15)
                    let x = CGFloat(i) * barWidth + 2
                    let width = barWidth - 4

                    // Ghost outline at the original (uncompressed) height — the gap between
                    // this and the solid bar is what visually communicates the gain reduction,
                    // and it stays legible even when the compressed bars end up nearly flat.
                    if level > compressedLevel + 0.01 {
                        let originalHeight = level * size.height
                        let ghostRect = CGRect(x: x, y: size.height - originalHeight, width: width, height: originalHeight)
                        context.stroke(Path(roundedRect: ghostRect, cornerRadius: 2), with: .color(DS.subtext.opacity(0.5)), lineWidth: 1)
                    }

                    let barHeight = compressedLevel * size.height
                    let rect = CGRect(x: x, y: size.height - barHeight, width: width, height: barHeight)
                    let color = level > thresholdLevel ? DS.accent : DS.accent.opacity(0.5)
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
                }
            }
            .frame(height: 110)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Distortion: waveform shaped with the same math the audio engine applies

struct DistortionVisualizerView: View {
    let type: DistortionType

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type.rawValue)
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let midY = size.height / 2
                var path = Path()
                let steps = 160
                for i in 0...steps {
                    let t = Double(i) / Double(steps)
                    let x = t * 2
                    let raw = sin(x * .pi * 2)
                    let shaped = shape(raw)
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
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }

    private func shape(_ x: Double) -> Double {
        switch type {
        case .clean:
            return x
        case .overdrive:
            let drive = 4.0
            return tanh(x * drive) / tanh(drive) * 0.9
        case .fuzz:
            let drive = 18.0
            return tanh(x * drive) / tanh(drive)
        case .digitalClip:
            let gain = 6.0, threshold = 0.35
            let v = max(-threshold, min(threshold, x * gain))
            return v / threshold * 0.9
        case .bitcrush:
            let levels: Double = 16
            return (x * levels).rounded() / levels
        }
    }
}

// MARK: - Loudness: reference vs. processed level meters

struct LoudnessVisualizerView: View {
    let deltaDB: Float

    @State private var appeared = false

    /// Meters are relative to a nominal -18dBFS reference, clamped to a realistic meter range.
    private var referenceLevel: CGFloat { 0.55 }
    private var processedLevel: CGFloat {
        let scaled = 0.55 * pow(10, CGFloat(deltaDB) / 20)
        return min(max(scaled, 0.04), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(deltaDB >= 0 ? "+\(String(format: "%.1f", deltaDB)) dB" : "\(String(format: "%.1f", deltaDB)) dB")
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let meterWidth = (size.width - 24) / 2
                drawMeter(context: context, x: 0, width: meterWidth, size: size, level: referenceLevel, label: "Original")
                drawMeter(context: context, x: meterWidth + 24, width: meterWidth, size: size, level: processedLevel, label: "Processed")
            }
            .frame(height: 110)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }

    private func drawMeter(context: GraphicsContext, x: CGFloat, width: CGFloat, size: CGSize, level: CGFloat, label: String) {
        let barAreaHeight = size.height - 20
        let barHeight = level * barAreaHeight
        let track = CGRect(x: x, y: 0, width: width, height: barAreaHeight)
        context.fill(Path(roundedRect: track, cornerRadius: 6), with: .color(DS.subtext.opacity(0.12)))

        let bar = CGRect(x: x, y: barAreaHeight - barHeight, width: width, height: barHeight)
        context.fill(Path(roundedRect: bar, cornerRadius: 6), with: .linearGradient(
            Gradient(colors: [DS.accent, DS.accent.opacity(0.6)]),
            startPoint: CGPoint(x: 0, y: barAreaHeight - barHeight), endPoint: CGPoint(x: 0, y: barAreaHeight)))

        context.draw(Text(label).font(.caption2).foregroundStyle(DS.subtext),
                      at: CGPoint(x: x + width / 2, y: size.height - 8))
    }
}

// MARK: - Reverb: an impulse followed by a decaying tail of reflections

struct ReverbVisualizerView: View {
    let type: ReverbType

    @State private var appeared = false

    /// Roughly how long the tail reads visually and how dense the reflections are —
    /// not physically accurate, just legible: bigger space = longer, denser tail.
    private var tailLength: CGFloat {
        switch type {
        case .dry: return 0.04
        case .room: return 0.35
        case .plate: return 0.5
        case .hall: return 0.75
        case .cathedral: return 1.0
        }
    }

    private var reflectionCount: Int {
        switch type {
        case .dry: return 1
        case .room: return 10
        case .plate: return 14
        case .hall: return 20
        case .cathedral: return 28
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type.rawValue)
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let baseY = size.height * 0.85
                let impulseX: CGFloat = 6

                var direct = Path()
                direct.move(to: CGPoint(x: impulseX, y: baseY))
                direct.addLine(to: CGPoint(x: impulseX, y: 6))
                context.stroke(direct, with: .color(DS.accent), lineWidth: 3)

                let tailWidth = (size.width - impulseX) * tailLength
                guard reflectionCount > 1 else { return }
                for i in 1..<reflectionCount {
                    let t = CGFloat(i) / CGFloat(reflectionCount - 1)
                    let x = impulseX + t * tailWidth
                    let decay = exp(-Double(t) * 3.2)
                    let height = (baseY - 6) * CGFloat(decay)
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: baseY))
                    line.addLine(to: CGPoint(x: x, y: baseY - height))
                    context.stroke(line, with: .color(DS.accent.opacity(0.25 + 0.35 * decay)), lineWidth: 2)
                }

                var floor = Path()
                floor.move(to: CGPoint(x: 0, y: baseY))
                floor.addLine(to: CGPoint(x: size.width, y: baseY))
                context.stroke(floor, with: .color(DS.subtext.opacity(0.25)), lineWidth: 1)
            }
            .frame(height: 110)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }
}

// MARK: - Delay: distinct repeating echoes, spaced by the delay time and shrinking with feedback

struct DelayVisualizerView: View {
    let time: TimeInterval
    let feedback: Float
    let label: String

    init(amount: DelayAmount) {
        self.time = amount.time
        self.feedback = amount.feedback
        self.label = amount.rawValue
    }

    init(time: TimeInterval, feedback: Float, label: String) {
        self.time = time
        self.feedback = feedback
        self.label = label
    }

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(label) — \(String(format: "%.0f", time * 1000)) ms")
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let baseY = size.height * 0.85
                // Visualize a fixed one-second window regardless of the actual delay time,
                // so short delays show tight repeats and long ones show sparse, spread echoes.
                let windowSeconds: Double = 1.0
                var t = 0.0
                var amplitude: CGFloat = 1.0
                var isFirst = true
                while t < windowSeconds {
                    let x = CGFloat(t / windowSeconds) * size.width
                    let height = (baseY - 6) * amplitude
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: baseY))
                    line.addLine(to: CGPoint(x: x, y: baseY - height))
                    context.stroke(line, with: .color(isFirst ? DS.accent : DS.accent.opacity(Double(amplitude) * 0.8 + 0.1)), lineWidth: isFirst ? 3 : 2)
                    t += max(time, 0.02)
                    amplitude *= CGFloat(feedback / 100)
                    isFirst = false
                }

                var floor = Path()
                floor.move(to: CGPoint(x: 0, y: baseY))
                floor.addLine(to: CGPoint(x: size.width, y: baseY))
                context.stroke(floor, with: .color(DS.subtext.opacity(0.25)), lineWidth: 1)
            }
            .frame(height: 110)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }
}

// MARK: - Noise: a clean waveform with the artifact's visible signature overlaid

struct NoiseVisualizerView: View {
    let type: NoiseType

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type.rawValue)
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let midY = size.height / 2
                var path = Path()
                let steps = 200
                var rng = SeededGenerator(seed: 7)
                for i in 0...steps {
                    let t = Double(i) / Double(steps)
                    let base = sin(t * .pi * 2 * 3) * 0.55

                    var artifact = 0.0
                    switch type {
                    case .clean:
                        artifact = 0
                    case .hum:
                        artifact = sin(t * .pi * 2 * 9) * 0.18
                    case .hiss:
                        artifact = Double.random(in: -0.12...0.12, using: &rng)
                    case .clicks:
                        artifact = (i % 27 == 0) ? Double.random(in: -0.6...0.6, using: &rng) : 0
                    }

                    let y = midY - CGFloat(base + artifact) * midY * 0.9
                    let x = CGFloat(t) * size.width
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(path, with: .color(DS.accent), lineWidth: 1.6)

                var zero = Path()
                zero.move(to: CGPoint(x: 0, y: midY))
                zero.addLine(to: CGPoint(x: size.width, y: midY))
                context.stroke(zero, with: .color(DS.subtext.opacity(0.25)), lineWidth: 1)
            }
            .frame(height: 110)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }
}

// MARK: - Phase: separate L/R traces so mono collapse / phase inversion is visible directly

struct PhaseVisualizerView: View {
    let type: PhaseType

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type.rawValue)
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let steps = 140
                func trace(gain: Double, phaseFlip: Bool, yCenter: CGFloat, color: Color) {
                    var path = Path()
                    for i in 0...steps {
                        let t = Double(i) / Double(steps)
                        var v = sin(t * .pi * 2 * 3) * gain
                        if phaseFlip { v = -v }
                        let y = yCenter - CGFloat(v) * 24
                        let x = CGFloat(t) * size.width
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    context.stroke(path, with: .color(color), lineWidth: 1.8)
                }

                let topY = size.height * 0.3
                let bottomY = size.height * 0.75

                switch type {
                case .normal:
                    trace(gain: 0.55, phaseFlip: false, yCenter: topY, color: DS.accent)
                    trace(gain: 0.55, phaseFlip: false, yCenter: bottomY, color: DS.accent.opacity(0.6))
                case .mono:
                    trace(gain: 0.55, phaseFlip: false, yCenter: topY, color: DS.accent)
                    trace(gain: 0.55, phaseFlip: false, yCenter: bottomY, color: DS.accent)
                case .wide:
                    trace(gain: 0.75, phaseFlip: false, yCenter: topY, color: DS.accent)
                    trace(gain: 0.35, phaseFlip: false, yCenter: bottomY, color: DS.accent.opacity(0.6))
                case .outOfPhase:
                    trace(gain: 0.55, phaseFlip: false, yCenter: topY, color: DS.accent)
                    trace(gain: 0.55, phaseFlip: true, yCenter: bottomY, color: DS.wrong)
                }

                context.draw(Text("L").font(.caption2).foregroundStyle(DS.subtext), at: CGPoint(x: 10, y: topY - 22))
                context.draw(Text("R").font(.caption2).foregroundStyle(DS.subtext), at: CGPoint(x: 10, y: bottomY - 22))
            }
            .frame(height: 110)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }
}

// MARK: - Limiting: reuses the ghost/solid gain-reduction bars, just with a much lower ceiling

struct LimitVisualizerView: View {
    let amount: LimitAmount

    @State private var appeared = false
    private let bars: [CGFloat] = (0..<24).map { i in
        let t = Double(i) / 24
        return CGFloat(0.35 + 0.6 * abs(sin(t * .pi * 3.7)))
    }

    private var ceilingLevel: CGFloat {
        switch amount {
        case .gentle: return 0.85
        case .moderate: return 0.7
        case .brickwall: return 0.55
        case .extreme: return 0.4
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ceiling: \(amount.rawValue.lowercased())")
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let ceilingY = size.height * (1 - ceilingLevel)
                var ceilingPath = Path()
                ceilingPath.move(to: CGPoint(x: 0, y: ceilingY))
                ceilingPath.addLine(to: CGPoint(x: size.width, y: ceilingY))
                context.stroke(ceilingPath, with: .color(DS.wrong.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                let barWidth = size.width / CGFloat(bars.count)
                for (i, level) in bars.enumerated() {
                    let x = CGFloat(i) * barWidth + 2
                    let width = barWidth - 4
                    let limited = min(level, ceilingLevel)

                    if level > limited + 0.01 {
                        let originalHeight = level * size.height
                        let ghostRect = CGRect(x: x, y: size.height - originalHeight, width: width, height: originalHeight)
                        context.stroke(Path(roundedRect: ghostRect, cornerRadius: 2), with: .color(DS.subtext.opacity(0.5)), lineWidth: 1)
                    }

                    let barHeight = limited * size.height
                    let rect = CGRect(x: x, y: size.height - barHeight, width: width, height: barHeight)
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(DS.accent))
                }
            }
            .frame(height: 110)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }
}

// MARK: - Saturation: same waveform-shaping style as Distortion, but with gentle drive levels

struct SaturationVisualizerView: View {
    let type: SaturationType

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type.rawValue)
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let midY = size.height / 2
                var path = Path()
                let steps = 160
                let norm = tanh(Double(type.drive))
                for i in 0...steps {
                    let t = Double(i) / Double(steps)
                    let raw = sin(t * .pi * 2 * 2)
                    let shaped = tanh(raw * Double(type.drive)) / norm
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
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }
}

// MARK: - Codec: a spectrum bar chart where high-frequency bars shrink and dim with lower bitrate

struct CodecVisualizerView: View {
    let type: CodecType

    @State private var appeared = false
    private let bandCount = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type.rawValue)
                .font(.caption.monospacedDigit())
                .foregroundStyle(DS.subtext)

            Canvas { context, size in
                let barWidth = size.width / CGFloat(bandCount)
                for i in 0..<bandCount {
                    let t = Float(i) / Float(bandCount - 1)
                    let naturalHeight: Float = 0.9 - t * 0.5
                    let rolloff = min(1, type.cutoffAlpha * 2.2)
                    let attenuation = t > rolloff ? max(0.05, 1 - (t - rolloff) * 3) : 1
                    let height = CGFloat(naturalHeight * attenuation) * size.height
                    let x = CGFloat(i) * barWidth + 1
                    let rect = CGRect(x: x, y: size.height - height, width: barWidth - 2, height: height)
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(DS.accent.opacity(Double(attenuation) * 0.8 + 0.2)))
                }
            }
            .frame(height: 110)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
    }
}
