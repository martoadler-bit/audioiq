import AVFoundation

/// Loads a real-music loop and lets exercises apply live EQ / compression / distortion
/// on top of it, looping playback so the user can A/B compare freely.
final class ProcessingAudioEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    let eq = AVAudioUnitEQ(numberOfBands: 1)
    let distortion = AVAudioUnitDistortion()
    let reverb = AVAudioUnitReverb()
    let delay = AVAudioUnitDelay()
    private let dynamics = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect,
        componentSubType: kAudioUnitSubType_DynamicsProcessor,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0, componentFlagsMask: 0))

    @Published var isPlaying = false

    private var buffer: AVAudioPCMBuffer?

    /// Fetching this the first time can involve an XPC round-trip to the AU host and must
    /// never happen synchronously on the main thread (it can stall the UI for several seconds).
    /// We warm it up once in the background and only ever touch the cached tree afterwards.
    private var dynamicsParameterTree: AUParameterTree?

    init() {
        eq.bands[0].filterType = .parametric
        eq.bands[0].bypass = true

        distortion.loadFactoryPreset(.drumsBitBrush)
        distortion.wetDryMix = 0
        distortion.bypass = true

        dynamics.bypass = true

        reverb.loadFactoryPreset(.mediumRoom)
        reverb.wetDryMix = 0
        reverb.bypass = true

        delay.delayTime = 0.25
        delay.feedback = 25
        delay.wetDryMix = 0
        delay.bypass = true

        engine.attach(player)
        engine.attach(eq)
        engine.attach(distortion)
        engine.attach(dynamics)
        engine.attach(reverb)
        engine.attach(delay)

        // Fixed format matching our bundled audio assets (44.1kHz stereo), independent of
        // whatever sample rate the simulator/device hardware output happens to report.
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        engine.connect(player, to: eq, format: format)
        engine.connect(eq, to: distortion, format: format)
        engine.connect(distortion, to: dynamics, format: format)
        engine.connect(dynamics, to: reverb, format: format)
        engine.connect(reverb, to: delay, format: format)
        engine.connect(delay, to: engine.mainMixerNode, format: format)

        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let tree = self?.dynamics.auAudioUnit.parameterTree
            DispatchQueue.main.async {
                self?.dynamicsParameterTree = tree
            }
        }
    }

    static let realLoopResources: [String] = (1...265).map { String(format: "loop_%03d", $0) }

    func loadRandomRealLoop() {
        load(resource: Self.realLoopResources.randomElement()!)
    }

    func load(resource: String, ext: String = "wav") {
        let engineFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext),
              let file = try? AVAudioFile(forReading: url, commonFormat: engineFormat.commonFormat, interleaved: engineFormat.isInterleaved) else { return }
        buffer = AVAudioPCMBuffer(pcmFormat: engineFormat, frameCapacity: AVAudioFrameCount(file.length))
        guard let buffer else { return }
        try? file.read(into: buffer)
    }

    func playLooping() {
        guard let buffer else { return }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
        isPlaying = true
    }

    func stop() {
        player.stop()
        isPlaying = false
    }

    /// Resets every processing node to a clean pass-through. Exercises call this on entry
    /// since nodes are shared across screens and could be left engaged by a previous module.
    func resetAllProcessing() {
        eq.bands[0].bypass = true
        distortion.bypass = true
        dynamics.bypass = true
        reverb.bypass = true
        delay.bypass = true
        player.volume = 1
    }

    // MARK: Loudness controls

    func setLoudness(gainDB: Float) {
        player.volume = pow(10, gainDB / 20)
    }

    // MARK: EQ controls

    func setEQ(frequency: Float, gain: Float, bandwidth: Float = 1.0, enabled: Bool) {
        eq.bands[0].frequency = frequency
        eq.bands[0].gain = gain
        eq.bands[0].bandwidth = bandwidth
        eq.bands[0].bypass = !enabled
    }

    // MARK: Live distortion (for the free-play Lab — continuous, unlike the quiz's baked buffers)

    func setLiveDistortion(preset: AVAudioUnitDistortionPreset, wetDryMix: Float, enabled: Bool) {
        distortion.loadFactoryPreset(preset)
        distortion.wetDryMix = wetDryMix
        distortion.bypass = !enabled
    }

    // MARK: Distortion controls (baked into the buffer — AVAudioUnitDistortion can't do
    // bit-depth reduction / sample-and-hold aliasing, so all types go through the same path)

    func playDistorted(_ type: DistortionType) {
        guard let processed = distortedBuffer(type: type) else { return }
        player.stop()
        player.scheduleBuffer(processed, at: nil, options: .loops)
        player.play()
        isPlaying = true
    }

    private func distortedBuffer(type: DistortionType) -> AVAudioPCMBuffer? {
        guard let source = buffer, let srcData = source.floatChannelData else { return nil }
        let frameCount = Int(source.frameLength)
        let channels = Int(source.format.channelCount)
        guard let out = AVAudioPCMBuffer(pcmFormat: source.format, frameCapacity: source.frameLength),
              let outData = out.floatChannelData else { return nil }
        out.frameLength = source.frameLength

        for ch in 0..<channels {
            let inP = srcData[ch]
            let outP = outData[ch]
            switch type {
            case .clean:
                for i in 0..<frameCount { outP[i] = inP[i] }

            case .overdrive:
                let drive: Float = 4
                let norm = tanhf(drive)
                for i in 0..<frameCount { outP[i] = tanhf(inP[i] * drive) / norm * 0.9 }

            case .fuzz:
                let drive: Float = 18
                let norm = tanhf(drive)
                for i in 0..<frameCount { outP[i] = tanhf(inP[i] * drive) / norm }

            case .digitalClip:
                let gain: Float = 6
                let threshold: Float = 0.35
                for i in 0..<frameCount {
                    let v = max(-threshold, min(threshold, inP[i] * gain))
                    outP[i] = v / threshold * 0.9
                }

            case .bitcrush:
                let levels = powf(2, 4)
                let holdEvery = 10
                var held: Float = 0
                for i in 0..<frameCount {
                    if i % holdEvery == 0 {
                        held = roundf(inP[i] * levels) / levels
                    }
                    outP[i] = held
                }
            }
        }
        return out
    }

    // MARK: Dynamics (compression) controls

    /// Apple's AUDynamicsProcessor doesn't expose a direct "ratio" knob — it's driven by
    /// Threshold + HeadRoom (a lower headroom yields a harder knee, i.e. a higher effective
    /// ratio). masterGain compensates loudness so the audible difference is squashing, not volume.
    func setCompression(threshold: Float, headroom: Float, masterGain: Float, enabled: Bool) {
        if let tree = dynamicsParameterTree {
            for param in tree.allParameters {
                switch param.identifier {
                case "Threshold": param.value = threshold
                case "HeadRoom": param.value = headroom
                case "MasterGain": param.value = masterGain
                default: break
                }
            }
        }
        dynamics.bypass = !enabled
    }

    // MARK: Reverb controls

    func setReverb(preset: AVAudioUnitReverbPreset, wetDryMix: Float, enabled: Bool) {
        reverb.loadFactoryPreset(preset)
        reverb.wetDryMix = wetDryMix
        reverb.bypass = !enabled
    }

    // MARK: Delay controls

    func setDelay(time: TimeInterval, feedback: Float, wetDryMix: Float, enabled: Bool) {
        delay.delayTime = time
        delay.feedback = feedback
        delay.wetDryMix = wetDryMix
        delay.bypass = !enabled
    }

    // MARK: Noise/artifacts (baked into the buffer — these are additive artifacts, not
    // something a stock AudioUnit models)

    func playNoisy(_ type: NoiseType) {
        guard let processed = noisyBuffer(type: type) else { return }
        player.stop()
        player.scheduleBuffer(processed, at: nil, options: .loops)
        player.play()
        isPlaying = true
    }

    private func noisyBuffer(type: NoiseType) -> AVAudioPCMBuffer? {
        guard let source = buffer, let srcData = source.floatChannelData else { return nil }
        let frameCount = Int(source.frameLength)
        let channels = Int(source.format.channelCount)
        guard let out = AVAudioPCMBuffer(pcmFormat: source.format, frameCapacity: source.frameLength),
              let outData = out.floatChannelData else { return nil }
        out.frameLength = source.frameLength
        let sampleRate: Float = 44100

        for ch in 0..<channels {
            let inP = srcData[ch]
            let outP = outData[ch]
            switch type {
            case .clean:
                for i in 0..<frameCount { outP[i] = inP[i] }

            case .hum:
                // 60Hz mains hum plus its second harmonic, the classic ground-loop signature.
                for i in 0..<frameCount {
                    let t = Float(i) / sampleRate
                    let hum = 0.08 * sinf(2 * .pi * 60 * t) + 0.03 * sinf(2 * .pi * 120 * t)
                    outP[i] = max(-1, min(1, inP[i] + hum))
                }

            case .hiss:
                var rng = SeededGenerator(seed: UInt64(ch) + 1)
                for i in 0..<frameCount {
                    let noise = Float.random(in: -1...1, using: &rng) * 0.05
                    outP[i] = max(-1, min(1, inP[i] + noise))
                }

            case .clicks:
                var rng = SeededGenerator(seed: UInt64(ch) + 99)
                for i in 0..<frameCount { outP[i] = inP[i] }
                let clickCount = Int(Float(frameCount) / sampleRate * 4) // ~4 clicks/sec
                for _ in 0..<clickCount {
                    let center = Int.random(in: 0..<frameCount, using: &rng)
                    for offset in -8...8 {
                        let idx = center + offset
                        guard idx >= 0 && idx < frameCount else { continue }
                        let decay = 1 - Float(abs(offset)) / 8
                        outP[idx] = max(-1, min(1, outP[idx] + decay * Float.random(in: -1...1, using: &rng) * 0.8))
                    }
                }
            }
        }
        return out
    }

    // MARK: Phase / mono compatibility (baked — needs both channels at once, unlike the
    // per-channel-independent effects above)

    func playPhaseShifted(_ type: PhaseType) {
        guard let processed = phaseBuffer(type: type) else { return }
        player.stop()
        player.scheduleBuffer(processed, at: nil, options: .loops)
        player.play()
        isPlaying = true
    }

    private func phaseBuffer(type: PhaseType) -> AVAudioPCMBuffer? {
        guard let source = buffer, let srcData = source.floatChannelData, source.format.channelCount == 2 else { return nil }
        let frameCount = Int(source.frameLength)
        guard let out = AVAudioPCMBuffer(pcmFormat: source.format, frameCapacity: source.frameLength),
              let outData = out.floatChannelData else { return nil }
        out.frameLength = source.frameLength

        let left = srcData[0], right = srcData[1]
        let outLeft = outData[0], outRight = outData[1]

        for i in 0..<frameCount {
            let l = left[i], r = right[i]
            switch type {
            case .normal:
                outLeft[i] = l
                outRight[i] = r
            case .mono:
                let m = (l + r) / 2
                outLeft[i] = m
                outRight[i] = m
            case .wide:
                let mid = (l + r) / 2
                let side = (l - r) / 2 * 2.2
                outLeft[i] = max(-1, min(1, mid + side))
                outRight[i] = max(-1, min(1, mid - side))
            case .outOfPhase:
                outLeft[i] = l
                outRight[i] = -r
            }
        }
        return out
    }

    // MARK: Saturation / warmth (baked — gentler tanh than the Distortion module's overdrive/fuzz)

    func playSaturated(_ type: SaturationType) {
        guard let processed = saturatedBuffer(type: type) else { return }
        player.stop()
        player.scheduleBuffer(processed, at: nil, options: .loops)
        player.play()
        isPlaying = true
    }

    private func saturatedBuffer(type: SaturationType) -> AVAudioPCMBuffer? {
        guard let source = buffer, let srcData = source.floatChannelData else { return nil }
        let frameCount = Int(source.frameLength)
        let channels = Int(source.format.channelCount)
        guard let out = AVAudioPCMBuffer(pcmFormat: source.format, frameCapacity: source.frameLength),
              let outData = out.floatChannelData else { return nil }
        out.frameLength = source.frameLength

        let drive = type.drive
        let norm = tanhf(drive)
        for ch in 0..<channels {
            let inP = srcData[ch]
            let outP = outData[ch]
            for i in 0..<frameCount {
                outP[i] = tanhf(inP[i] * drive) / norm
            }
        }
        return out
    }

    // MARK: Codec / bitrate artifacts (baked — a one-pole lowpass to approximate the high-frequency
    // loss of a low-bitrate codec, plus light quantization noise for the characteristic "swirl")

    func playCodecCrushed(_ type: CodecType) {
        guard let processed = codecBuffer(type: type) else { return }
        player.stop()
        player.scheduleBuffer(processed, at: nil, options: .loops)
        player.play()
        isPlaying = true
    }

    private func codecBuffer(type: CodecType) -> AVAudioPCMBuffer? {
        guard let source = buffer, let srcData = source.floatChannelData else { return nil }
        let frameCount = Int(source.frameLength)
        let channels = Int(source.format.channelCount)
        guard let out = AVAudioPCMBuffer(pcmFormat: source.format, frameCapacity: source.frameLength),
              let outData = out.floatChannelData else { return nil }
        out.frameLength = source.frameLength

        guard type.cutoffAlpha < 1 else {
            // Clean: pass through untouched.
            for ch in 0..<channels {
                let inP = srcData[ch]
                let outP = outData[ch]
                for i in 0..<frameCount { outP[i] = inP[i] }
            }
            return out
        }

        for ch in 0..<channels {
            let inP = srcData[ch]
            let outP = outData[ch]
            var rng = SeededGenerator(seed: UInt64(ch) + 500)
            var state: Float = 0
            let alpha = type.cutoffAlpha
            let levels = type.quantLevels
            for i in 0..<frameCount {
                state += alpha * (inP[i] - state)
                let quantized = levels > 0 ? roundf(state * levels) / levels : state
                let noise = Float.random(in: -1...1, using: &rng) * type.noiseAmount
                outP[i] = max(-1, min(1, quantized + noise))
            }
        }
        return out
    }
}

/// Deterministic RNG so hiss/click placement is reproducible per channel instead of using
/// the system RNG (which would make left/right channels decorrelate in an unnatural way).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }
}
