import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "waveform.badge.magnifyingglass")
                    .font(.system(size: 54))
                    .foregroundStyle(DS.accent)
                    .padding(.top, 12)

                VStack(spacing: 4) {
                    Text("Audio IQ")
                        .font(.title2.bold())
                        .foregroundStyle(DS.text)
                    Text("Version \(version) (\(build))")
                        .font(.caption)
                        .foregroundStyle(DS.subtext)
                }

                Text("Train your ears. Elevate your mix.\n\nAudio IQ is an ear-training app built for audio engineers, not musicians — practice recognizing EQ moves, compression, distortion, reverb, delay, phase issues, limiting, saturation, and codec artifacts on real recordings across dozens of genres.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    NavigationLink {
                        CreditsView()
                    } label: {
                        HStack {
                            Image(systemName: "quote.opening")
                            Text("Audio credits")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(DS.text)
                    }
                    .bouncy()
                }
                .padding(.top, 8)

                Spacer(minLength: 20)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("About")
    }
}
