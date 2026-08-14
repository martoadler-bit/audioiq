import SwiftUI

/// Shared play/stop button for the free-play labs — bigger and more playful than the quiz's
/// A/B buttons since here there's only one live signal, not a reference to compare against.
struct LabPlayButton: View {
    @ObservedObject var engine: ProcessingAudioEngine

    var body: some View {
        Button {
            engine.isPlaying ? engine.stop() : engine.playLooping()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                Text(engine.isPlaying ? "Playing" : "Play loop")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(engine.isPlaying ? DS.accent.opacity(0.25) : DS.accent, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(engine.isPlaying ? DS.accent : DS.background)
        }
        .animation(.easeOut(duration: 0.2), value: engine.isPlaying)
        .bouncy(0.97)
    }
}

/// A labeled slider row shared by all the labs: title on the left, live value on the right,
/// the control itself underneath.
@ViewBuilder
func labSlider<Content: View>(title: String, value: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(DS.text)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(DS.accent)
        }
        content()
            .tint(DS.accent)
    }
    .padding()
    .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
}
