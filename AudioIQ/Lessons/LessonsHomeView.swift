import SwiftUI

struct LessonsHomeView: View {
    let engine: ProcessingAudioEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Drag the controls and listen to what each one does to real music, in real time.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                NavigationLink {
                    EQLabView(engine: engine)
                } label: {
                    ModuleCard(title: "EQ Lab", subtitle: "Sweep frequency and gain on a live parametric band", systemImage: "slider.horizontal.3", accent: DS.moduleColor("EQ"))
                }
                .bouncy()

                NavigationLink {
                    CompressionLabView(engine: engine)
                } label: {
                    ModuleCard(title: "Compression Lab", subtitle: "Dial in threshold and ratio, watch the gain reduction", systemImage: "waveform.path.ecg", accent: DS.moduleColor("Compression"))
                }
                .bouncy()

                NavigationLink {
                    DistortionLabView(engine: engine)
                } label: {
                    ModuleCard(title: "Distortion Lab", subtitle: "Push the drive from clean to fuzz and watch it clip", systemImage: "bolt.fill", accent: DS.moduleColor("Distortion"))
                }
                .bouncy()

                NavigationLink {
                    LoudnessLabView(engine: engine)
                } label: {
                    ModuleCard(title: "Loudness Lab", subtitle: "Hear how a few dB changes perceived volume", systemImage: "speaker.wave.3.fill", accent: DS.moduleColor("Loudness"))
                }
                .bouncy()

                NavigationLink {
                    ReverbLabView(engine: engine)
                } label: {
                    ModuleCard(title: "Reverb Lab", subtitle: "Switch spaces and blend in the reflections live", systemImage: "building.columns", accent: DS.moduleColor("Reverb"))
                }
                .bouncy()

                NavigationLink {
                    DelayLabView(engine: engine)
                } label: {
                    ModuleCard(title: "Delay Lab", subtitle: "Dial in time and feedback for slapback to trails", systemImage: "arrow.triangle.2.circlepath", accent: DS.moduleColor("Delay"))
                }
                .bouncy()

                NavigationLink {
                    NoiseLabView(engine: engine)
                } label: {
                    ModuleCard(title: "Noise Lab", subtitle: "Compare hum, hiss and clicks side by side", systemImage: "waveform.path.badge.minus", accent: DS.moduleColor("Noise"))
                }
                .bouncy()

                NavigationLink {
                    PhaseLabView(engine: engine)
                } label: {
                    ModuleCard(title: "Phase Lab", subtitle: "Hear a mix collapse in mono or cancel out of phase", systemImage: "dot.radiowaves.left.and.right", accent: DS.moduleColor("Phase"))
                }
                .bouncy()

                NavigationLink {
                    LimitingLabView(engine: engine)
                } label: {
                    ModuleCard(title: "Limiting Lab", subtitle: "Push a ceiling down and feel peaks get caught", systemImage: "water.waves", accent: DS.moduleColor("Limiting"))
                }
                .bouncy()

                NavigationLink {
                    SaturationLabView(engine: engine)
                } label: {
                    ModuleCard(title: "Saturation Lab", subtitle: "Dial in warmth from clean to hot", systemImage: "flame", accent: DS.moduleColor("Saturation"))
                }
                .bouncy()

                NavigationLink {
                    CodecLabView(engine: engine)
                } label: {
                    ModuleCard(title: "Codec Lab", subtitle: "Hear a mix get crushed down to a low bitrate", systemImage: "antenna.radiowaves.left.and.right", accent: DS.moduleColor("Codec"))
                }
                .bouncy()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Lessons")
        .onDisappear { engine.stop() }
    }
}
