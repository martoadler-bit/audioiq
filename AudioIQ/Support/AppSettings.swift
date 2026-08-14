import Foundation
import UserNotifications

/// A single, app-wide difficulty setting shared by every quiz module — set once in Settings
/// instead of picked per exercise every time you open one.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    enum Difficulty: String, CaseIterable, Identifiable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"

        var id: String { rawValue }
    }

    @Published var difficulty: Difficulty {
        didSet { UserDefaults.standard.set(difficulty.rawValue, forKey: Self.difficultyKey) }
    }

    @Published var dailyReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyReminderEnabled, forKey: Self.reminderEnabledKey)
            dailyReminderEnabled ? scheduleReminder() : cancelReminder()
        }
    }

    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: Self.reminderTimeKey)
            if dailyReminderEnabled { scheduleReminder() }
        }
    }

    private static let difficultyKey = "AudioIQDifficulty"
    private static let reminderEnabledKey = "AudioIQDailyReminderEnabled"
    private static let reminderTimeKey = "AudioIQDailyReminderTime"
    private static let reminderIdentifier = "AudioIQDailyReminder"

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.difficultyKey)
        difficulty = stored.flatMap(Difficulty.init) ?? .beginner

        dailyReminderEnabled = UserDefaults.standard.bool(forKey: Self.reminderEnabledKey)
        reminderTime = UserDefaults.standard.object(forKey: Self.reminderTimeKey) as? Date
            ?? Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
    }

    func enableReminder() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted {
                    self.dailyReminderEnabled = true
                } else {
                    self.dailyReminderEnabled = false
                }
            }
        }
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Keep your streak going 🔥"
        content.body = "A couple rounds a day sharpens your ear fast — jump into Audio IQ."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.reminderIdentifier, content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
    }
}
