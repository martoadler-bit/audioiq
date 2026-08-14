import SwiftUI

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Every loop in Audio IQ is a real recording, not a synthesized tone. Most are public domain or CC0. The \(Credits.attributionRequired.count) below are CC BY / CC BY-SA, which require crediting the original author.")
                    .font(.subheadline)
                    .foregroundStyle(DS.subtext)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(Credits.attributionRequired) { credit in
                        creditRow(credit)
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Credits")
    }

    private func creditRow(_ credit: Credit) -> some View {
        Link(destination: URL(string: credit.sourceURL) ?? URL(string: "https://commons.wikimedia.org")!) {
            VStack(alignment: .leading, spacing: 4) {
                Text(credit.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(DS.text)
                    .multilineTextAlignment(.leading)
                if !credit.artist.isEmpty {
                    Text(credit.artist)
                        .font(.caption)
                        .foregroundStyle(DS.subtext)
                }
                HStack {
                    Text(credit.license)
                        .font(.caption2.bold())
                        .foregroundStyle(DS.accent)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(DS.subtext)
                }
            }
            .padding()
            .background(DS.card, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
