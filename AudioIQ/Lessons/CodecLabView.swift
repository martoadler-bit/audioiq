import SwiftUI

struct CodecLabView: View {
    @ObservedObject var engine: ProcessingAudioEngine

    @State private var type: CodecType = .medium

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Lossy codecs throw away detail to hit a target file size. At low bitrates the top end gets dull and a swirly noise creeps in around transients — the sound of a bad phone call, not a broken speaker.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    engine.isPlaying ? engine.stop() : engine.playCodecCrushed(type)
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

                CodecVisualizerView(type: type)
                    .id(type)

                Picker("Bitrate", selection: $type) {
                    ForEach(CodecType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Codec Lab")
        .onAppear {
            engine.resetAllProcessing()
            engine.loadRandomRealLoop()
        }
        .onDisappear { engine.stop() }
        .onChange(of: type) { _, _ in if engine.isPlaying { engine.playCodecCrushed(type) } }
    }
}
