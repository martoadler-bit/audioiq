import SwiftUI

/// Named ProgressView2 to avoid clashing with SwiftUI's own ProgressView.
struct ProgressView2: View {
    @ObservedObject private var tracker = ProgressTracker.shared

    private let modules: [(key: String, title: String, icon: String)] = [
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

    private var overall: ProgressTracker.ModuleStats {
        tracker.aggregateStats(for: modules.map(\.key))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard

                VStack(spacing: 12) {
                    ForEach(modules, id: \.key) { module in
                        moduleRow(module)
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Progress")
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            statBlock(value: "\(tracker.dailyStreak)", label: tracker.dailyStreak == 1 ? "day streak" : "day streak", icon: "flame.fill")
            Divider().background(DS.subtext.opacity(0.3))
            statBlock(value: "\(overall.accuracyPercent)%", label: "accuracy", icon: "target")
            Divider().background(DS.subtext.opacity(0.3))
            statBlock(value: "\(overall.totalAttempts)", label: "rounds", icon: "number")
        }
        .padding(.vertical, 20)
        .background(DS.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statBlock(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(DS.accent)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(DS.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(DS.subtext)
        }
        .frame(maxWidth: .infinity)
    }

    private func moduleRow(_ module: (key: String, title: String, icon: String)) -> some View {
        let stats = tracker.statsFor(module.key)
        return HStack(spacing: 14) {
            Image(systemName: module.icon)
                .font(.title3)
                .foregroundStyle(DS.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(module.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(DS.text)
                    Spacer()
                    if stats.totalAttempts > 0 {
                        Text("\(stats.accuracyPercent)%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(DS.subtext)
                    } else {
                        Text("Not started")
                            .font(.caption)
                            .foregroundStyle(DS.subtext.opacity(0.6))
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DS.subtext.opacity(0.15))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DS.accent)
                            .frame(width: geo.size.width * CGFloat(stats.accuracy))
                    }
                }
                .frame(height: 6)

                if stats.bestStreak > 1 {
                    Text("Best streak: \(stats.bestStreak)")
                        .font(.caption2)
                        .foregroundStyle(DS.subtext)
                }
            }
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
    }
}
