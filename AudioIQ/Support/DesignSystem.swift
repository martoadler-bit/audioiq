import SwiftUI

enum DS {
    static let background = Color(red: 0.06, green: 0.07, blue: 0.09)
    static let card = Color(red: 0.12, green: 0.13, blue: 0.17)
    static let accent = Color(red: 0.35, green: 0.75, blue: 0.65)
    static let text = Color.white
    static let subtext = Color.white.opacity(0.6)
    static let correct = Color(red: 0.35, green: 0.85, blue: 0.45)
    static let wrong = Color(red: 0.95, green: 0.4, blue: 0.4)

    /// A distinct hue per module so the app reads as a set of playful "worlds" instead of one
    /// flat teal theme repeated seven times.
    static func moduleColor(_ key: String) -> Color {
        switch key {
        case "EQ": return Color(red: 0.35, green: 0.75, blue: 0.65)
        case "Compression": return Color(red: 0.45, green: 0.55, blue: 0.95)
        case "Distortion": return Color(red: 0.95, green: 0.45, blue: 0.35)
        case "Loudness": return Color(red: 0.95, green: 0.75, blue: 0.25)
        case "Reverb": return Color(red: 0.55, green: 0.45, blue: 0.95)
        case "Delay": return Color(red: 0.95, green: 0.45, blue: 0.7)
        case "Noise": return Color(red: 0.5, green: 0.85, blue: 0.55)
        case "Phase": return Color(red: 0.3, green: 0.85, blue: 0.85)
        case "Limiting": return Color(red: 0.85, green: 0.3, blue: 0.3)
        case "Saturation": return Color(red: 0.95, green: 0.55, blue: 0.15)
        case "Codec": return Color(red: 0.55, green: 0.65, blue: 0.7)
        case "Lessons": return Color(red: 0.95, green: 0.6, blue: 0.3)
        case "Progress": return Color(red: 1.0, green: 0.6, blue: 0.15)
        default: return accent
        }
    }
}

/// The shared gradient wallpaper behind every screen — a plain full-bleed gradient (no logo
/// or text baked in), so it can repeat across quiz, lab, and settings screens without looking
/// like a splash graphic escaped onto the wrong page.
struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            DS.background
            Image("AppBackground")
                .resizable()
                .scaledToFill()
        }
        .ignoresSafeArea()
    }
}

extension View {
    func appBackground() -> some View {
        background(AppBackgroundView())
    }
}

/// A snappy "press-down" feel on any button — the single change that does the most to make
/// the UI stop feeling like a form and start feeling like a game.
struct BouncyButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

extension View {
    func bouncy(_ scale: CGFloat = 0.95) -> some View {
        buttonStyle(BouncyButtonStyle(scale: scale))
    }
}

struct ModuleCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var accent: Color = DS.accent
    var disabled: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [accent, accent.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .opacity(disabled ? 0.4 : 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DS.text)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline.bold())
                .foregroundStyle(DS.subtext)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(DS.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(accent.opacity(disabled ? 0 : 0.25), lineWidth: 1.5)
                )
        )
        .shadow(color: accent.opacity(disabled ? 0 : 0.15), radius: 12, y: 6)
        .opacity(disabled ? 0.6 : 1)
    }
}

/// A big square tile for the Home grid — this, more than anything else, is what makes the
/// screen read as a game menu instead of a settings list.
struct GameTile: View {
    let title: String
    let systemImage: String
    let accent: Color
    var badge: String?

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.25), in: Capsule())
                }
            }

            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [accent, accent.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: accent.opacity(0.35), radius: 10, y: 6)
    }
}

struct ProgressSummaryCard: View {
    @ObservedObject var tracker: ProgressTracker

    private static let allModuleKeys = ["EQ", "Compression", "Distortion", "Loudness", "Reverb", "Delay", "Noise", "Phase", "Limiting", "Saturation", "Codec"]

    private var overall: ProgressTracker.ModuleStats {
        tracker.aggregateStats(for: Self.allModuleKeys)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.orange, .red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .scaleEffect(tracker.dailyStreak > 0 ? 1 : 0.85)
                    .opacity(tracker.dailyStreak > 0 ? 1 : 0.5)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tracker.dailyStreak > 0 ? "\(tracker.dailyStreak)-day streak 🔥" : "Your progress")
                    .font(.headline)
                    .foregroundStyle(DS.text)
                if overall.totalAttempts > 0 {
                    Text("\(overall.accuracyPercent)% accuracy across \(overall.totalAttempts) rounds")
                        .font(.subheadline)
                        .foregroundStyle(DS.subtext)
                } else {
                    Text("Play a round to start tracking")
                        .font(.subheadline)
                        .foregroundStyle(DS.subtext)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline.bold())
                .foregroundStyle(DS.subtext)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(DS.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1.5)
                )
        )
        .shadow(color: .orange.opacity(0.15), radius: 12, y: 6)
    }
}

/// A little burst of sparkles that pops out from the center of whatever it's attached to —
/// dropped on top of the correct answer when revealed.
struct CelebrationBurst: View {
    @State private var animate = false
    let color: Color

    private let symbols = ["star.fill", "sparkle", "star.fill", "sparkle", "star.fill", "sparkle"]

    var body: some View {
        ZStack {
            ForEach(0..<symbols.count, id: \.self) { i in
                Image(systemName: symbols[i])
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                    .offset(offset(for: i))
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 1.4 : 0.3)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { animate = true }
        }
    }

    private func offset(for index: Int) -> CGSize {
        let angle = Double(index) / Double(symbols.count) * 2 * .pi
        let radius: CGFloat = animate ? 46 : 0
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}
