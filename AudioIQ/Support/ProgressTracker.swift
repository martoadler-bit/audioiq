import Foundation
import Combine

class ProgressTracker: ObservableObject {
    static let shared = ProgressTracker()

    @Published private(set) var stats: [String: ModuleStats] = [:]

    struct ModuleStats: Codable {
        var totalAttempts: Int = 0
        var totalCorrect: Int = 0
        var streak: Int = 0
        var bestStreak: Int = 0
        var lastPlayed: Date = .distantPast

        var accuracy: Double {
            guard totalAttempts > 0 else { return 0 }
            return Double(totalCorrect) / Double(totalAttempts)
        }

        var accuracyPercent: Int { Int(accuracy * 100) }
        var level: Int { min(5, totalAttempts / 20) }
    }

    private let key = "AudioIQProgress"
    private let dailyStreakKey = "AudioIQDailyStreak"
    private let lastPracticeDayKey = "AudioIQLastPracticeDay"

    @Published private(set) var dailyStreak: Int = 0

    private init() {
        load()
        loadDailyStreak()
    }

    func record(module: String, correct: Bool) {
        var s = stats[module] ?? ModuleStats()
        s.totalAttempts += 1
        s.lastPlayed = Date()
        if correct {
            s.totalCorrect += 1
            s.streak += 1
            s.bestStreak = max(s.bestStreak, s.streak)
        } else {
            s.streak = 0
        }
        stats[module] = s
        save()
        bumpDailyStreak()
    }

    func statsFor(_ module: String) -> ModuleStats {
        stats[module] ?? ModuleStats()
    }

    func aggregateStats(for keys: [String]) -> ModuleStats {
        var agg = ModuleStats()
        for key in keys {
            let s = stats[key] ?? ModuleStats()
            agg.totalAttempts += s.totalAttempts
            agg.totalCorrect += s.totalCorrect
            agg.streak = max(agg.streak, s.streak)
            agg.bestStreak = max(agg.bestStreak, s.bestStreak)
            if s.lastPlayed > agg.lastPlayed { agg.lastPlayed = s.lastPlayed }
        }
        return agg
    }

    private func save() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: ModuleStats].self, from: data) {
            stats = decoded
        }
    }

    /// A day-over-day practice streak (independent of per-answer accuracy) — the classic
    /// "come back tomorrow" habit hook, counted once per calendar day regardless of how
    /// many rounds you actually play.
    private func bumpDailyStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = UserDefaults.standard.object(forKey: lastPracticeDayKey) as? Date

        if let lastDay {
            let lastDayStart = calendar.startOfDay(for: lastDay)
            if lastDayStart == today {
                return // already counted today
            } else if let daysBetween = calendar.dateComponents([.day], from: lastDayStart, to: today).day, daysBetween == 1 {
                dailyStreak += 1
            } else {
                dailyStreak = 1
            }
        } else {
            dailyStreak = 1
        }

        UserDefaults.standard.set(today, forKey: lastPracticeDayKey)
        UserDefaults.standard.set(dailyStreak, forKey: dailyStreakKey)
    }

    private func loadDailyStreak() {
        let calendar = Calendar.current
        let stored = UserDefaults.standard.integer(forKey: dailyStreakKey)
        if let lastDay = UserDefaults.standard.object(forKey: lastPracticeDayKey) as? Date {
            let lastDayStart = calendar.startOfDay(for: lastDay)
            let today = calendar.startOfDay(for: Date())
            if let daysBetween = calendar.dateComponents([.day], from: lastDayStart, to: today).day, daysBetween > 1 {
                dailyStreak = 0 // streak broken since last session
                return
            }
        }
        dailyStreak = stored
    }

    func resetAll() {
        stats = [:]
        dailyStreak = 0
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: dailyStreakKey)
        UserDefaults.standard.removeObject(forKey: lastPracticeDayKey)
    }

    /// Clears a single module's stats, leaving the streak and every other module untouched.
    func resetModule(_ module: String) {
        stats[module] = nil
        save()
    }
}
