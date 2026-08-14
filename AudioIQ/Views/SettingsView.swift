import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var tracker = ProgressTracker.shared

    @State private var showResetAllConfirm = false
    @State private var moduleToReset: (key: String, title: String)?

    private let modules: [(key: String, title: String)] = [
        ("EQ", "EQ"), ("Compression", "Compression"), ("Distortion", "Distortion"),
        ("Loudness", "Loudness"), ("Reverb", "Reverb"), ("Delay", "Delay"),
        ("Noise", "Noise & Artifacts"), ("Phase", "Phase & Mono"), ("Limiting", "Limiting"),
        ("Saturation", "Saturation"), ("Codec", "Codec Artifacts"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                section(title: "Difficulty", subtitle: "Applies to every quiz module — narrower frequency gaps, closer amounts, and harder-to-tell-apart choices as you go up.") {
                    Picker("Difficulty", selection: $settings.difficulty) {
                        ForEach(AppSettings.Difficulty.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                section(title: "Daily reminder", subtitle: "A nudge to keep your practice streak alive.") {
                    Toggle("Remind me daily", isOn: Binding(
                        get: { settings.dailyReminderEnabled },
                        set: { newValue in
                            if newValue { settings.enableReminder() } else { settings.dailyReminderEnabled = false }
                        }
                    ))
                    .tint(DS.accent)

                    if settings.dailyReminderEnabled {
                        DatePicker("Time", selection: $settings.reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                NavigationLink {
                    AboutView()
                } label: {
                    settingsRow(icon: "info.circle", title: "About")
                }
                .bouncy()

                NavigationLink {
                    CreditsView()
                } label: {
                    settingsRow(icon: "quote.opening", title: "Audio credits")
                }
                .bouncy()

                section(title: "Reset progress", subtitle: "Clear a single module or everything at once. This can't be undone.") {
                    VStack(spacing: 8) {
                        ForEach(modules, id: \.key) { module in
                            let stats = tracker.statsFor(module.key)
                            Button {
                                moduleToReset = module
                            } label: {
                                HStack {
                                    Text(module.title)
                                        .foregroundStyle(DS.text)
                                    Spacer()
                                    Text(stats.totalAttempts > 0 ? "\(stats.totalAttempts) rounds" : "Not started")
                                        .font(.caption)
                                        .foregroundStyle(DS.subtext)
                                    Image(systemName: "xmark.circle")
                                        .foregroundStyle(DS.wrong.opacity(stats.totalAttempts > 0 ? 1 : 0.3))
                                }
                                .padding(.vertical, 4)
                            }
                            .disabled(stats.totalAttempts == 0)
                            if module.key != modules.last?.key {
                                Divider().background(DS.subtext.opacity(0.2))
                            }
                        }
                    }
                }

                Button(role: .destructive) {
                    showResetAllConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset all progress")
                        Spacer()
                    }
                    .padding()
                    .background(DS.card, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(DS.wrong)
                }
                .bouncy()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Settings")
        .confirmationDialog("Reset all progress?", isPresented: $showResetAllConfirm, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive) {
                tracker.resetAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your streak and accuracy for every module. This can't be undone.")
        }
        .confirmationDialog(
            "Reset \(moduleToReset?.title ?? "")?",
            isPresented: Binding(get: { moduleToReset != nil }, set: { if !$0 { moduleToReset = nil } }),
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                if let key = moduleToReset?.key { tracker.resetModule(key) }
                moduleToReset = nil
            }
            Button("Cancel", role: .cancel) { moduleToReset = nil }
        }
    }

    private func section<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(DS.text)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(DS.subtext)
            content()
                .padding(.top, 4)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(DS.accent)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(DS.text)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(DS.subtext)
        }
        .padding()
        .background(DS.card, in: RoundedRectangle(cornerRadius: 16))
    }
}
