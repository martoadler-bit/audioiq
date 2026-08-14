import SwiftUI

struct HomeView: View {
    @StateObject private var engine = ProcessingAudioEngine()
    @ObservedObject private var tracker = ProgressTracker.shared

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    private let quizModules: [(key: String, title: String, icon: String)] = [
        ("EQ", "EQ", "slider.horizontal.3"),
        ("Compression", "Compression", "waveform.path.ecg"),
        ("Distortion", "Distortion", "bolt.fill"),
        ("Loudness", "Loudness", "speaker.wave.3.fill"),
        ("Reverb", "Reverb", "building.columns"),
        ("Delay", "Delay", "arrow.triangle.2.circlepath"),
        ("Noise", "Noise & Artifacts", "waveform.path.badge.minus"),
        ("Phase", "Phase & Mono", "dot.radiowaves.left.and.right"),
        ("Limiting", "Limiting", "water.waves"),
        ("Saturation", "Saturation", "flame"),
        ("Codec", "Codec Artifacts", "antenna.radiowaves.left.and.right"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NavigationLink {
                        ProgressView2()
                    } label: {
                        ProgressSummaryCard(tracker: tracker)
                    }
                    .bouncy()

                    NavigationLink {
                        LessonsHomeView(engine: engine)
                    } label: {
                        ModuleCard(title: "Lessons", subtitle: "Interactive labs — play with every effect live", systemImage: "wand.and.stars", accent: DS.moduleColor("Lessons"))
                    }
                    .bouncy()

                    Text("Practice")
                        .font(.headline)
                        .foregroundStyle(DS.subtext)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(quizModules, id: \.key) { module in
                            NavigationLink {
                                destination(for: module.key)
                            } label: {
                                GameTile(title: module.title, systemImage: module.icon, accent: DS.moduleColor(module.key), badge: badge(for: module.key))
                            }
                            .bouncy()
                        }
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Audio IQ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(DS.subtext)
                    }
                }
            }
        }
    }

    private func badge(for key: String) -> String? {
        let stats = tracker.statsFor(key)
        guard stats.totalAttempts > 0 else { return nil }
        return "\(stats.accuracyPercent)%"
    }

    @ViewBuilder
    private func destination(for key: String) -> some View {
        switch key {
        case "EQ": EQExerciseView(engine: engine)
        case "Compression": CompressionExerciseView(engine: engine)
        case "Distortion": DistortionExerciseView(engine: engine)
        case "Loudness": LoudnessExerciseView(engine: engine)
        case "Reverb": ReverbExerciseView(engine: engine)
        case "Delay": DelayExerciseView(engine: engine)
        case "Noise": NoiseExerciseView(engine: engine)
        case "Phase": PhaseExerciseView(engine: engine)
        case "Limiting": LimitingExerciseView(engine: engine)
        case "Saturation": SaturationExerciseView(engine: engine)
        case "Codec": CodecExerciseView(engine: engine)
        default: EmptyView()
        }
    }
}
