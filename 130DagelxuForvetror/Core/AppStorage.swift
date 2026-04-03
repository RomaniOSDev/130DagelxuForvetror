import Combine
import Foundation

@MainActor
final class AcademyProgressStore: ObservableObject {
    private enum Keys {
        static let hasSeenOnboarding = "academy.hasSeenOnboarding"
        static let starsPrefix = "academy.stars."
        static let completedPrefix = "academy.completed."
        static let totalPlaySeconds = "academy.totalPlaySeconds"
        static let sessionsPlayed = "academy.sessionsPlayed"
        static let storedAchievementIds = "academy.unlockedAchievementIds"
    }

    private let defaults: UserDefaults

    @Published private(set) var hasSeenOnboarding: Bool
    @Published private(set) var totalPlaySeconds: TimeInterval
    @Published private(set) var sessionsPlayed: Int
    @Published private(set) var unlockedAchievementIds: Set<String>

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        hasSeenOnboarding = userDefaults.bool(forKey: Keys.hasSeenOnboarding)
        totalPlaySeconds = userDefaults.double(forKey: Keys.totalPlaySeconds)
        sessionsPlayed = userDefaults.integer(forKey: Keys.sessionsPlayed)
        if let stored = userDefaults.array(forKey: Keys.storedAchievementIds) as? [String] {
            unlockedAchievementIds = Set(stored)
        } else {
            unlockedAchievementIds = []
        }
        reconcileAchievementsFromProgress()
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
    }

    func stars(for address: LevelAddress) -> Int {
        let key = Keys.starsPrefix + Self.storageKey(for: address)
        return defaults.object(forKey: key) as? Int ?? 0
    }

    func isLevelUnlocked(_ address: LevelAddress) -> Bool {
        if address.levelIndex == 0 { return true }
        let previous = LevelAddress(
            activity: address.activity,
            difficulty: address.difficulty,
            levelIndex: address.levelIndex - 1
        )
        return defaults.bool(forKey: Keys.completedPrefix + Self.storageKey(for: previous))
    }

    func isLevelCompleted(_ address: LevelAddress) -> Bool {
        defaults.bool(forKey: Keys.completedPrefix + Self.storageKey(for: address))
    }

    func recordSession(_ summary: ActivitySessionSummary) {
        guard summary.passed else {
            addPlaytime(summary.durationSeconds)
            sessionsPlayed += 1
            defaults.set(sessionsPlayed, forKey: Keys.sessionsPlayed)
            objectWillChange.send()
            return
        }

        let keyBase = Self.storageKey(for: LevelAddress(
            activity: summary.activity,
            difficulty: summary.difficulty,
            levelIndex: summary.levelIndex
        ))

        let starKey = Keys.starsPrefix + keyBase
        let priorStars = defaults.object(forKey: starKey) as? Int ?? 0
        let merged = max(priorStars, summary.starsEarned)
        defaults.set(merged, forKey: starKey)
        defaults.set(true, forKey: Keys.completedPrefix + keyBase)

        addPlaytime(summary.durationSeconds)
        sessionsPlayed += 1
        defaults.set(sessionsPlayed, forKey: Keys.sessionsPlayed)

        reconcileAchievementsFromProgress()
        objectWillChange.send()
    }

    private func addPlaytime(_ seconds: TimeInterval) {
        totalPlaySeconds += max(0, seconds)
        defaults.set(totalPlaySeconds, forKey: Keys.totalPlaySeconds)
    }

    func totalStarsCount() -> Int {
        var sum = 0
        for activity in ActivityKind.allCases {
            for difficulty in DifficultyTier.allCases {
                for index in 0 ..< LevelAddress.levelsPerTrack {
                    sum += stars(for: LevelAddress(activity: activity, difficulty: difficulty, levelIndex: index))
                }
            }
        }
        return sum
    }

    func completedLevelsCount(activity: ActivityKind) -> Int {
        var count = 0
        for difficulty in DifficultyTier.allCases {
            for index in 0 ..< LevelAddress.levelsPerTrack {
                let address = LevelAddress(activity: activity, difficulty: difficulty, levelIndex: index)
                if isLevelCompleted(address) { count += 1 }
            }
        }
        return count
    }

    func evaluateNewAchievements() -> [String] {
        var newly: [String] = []
        for achievement in AchievementDef.allCases {
            let id = achievement.rawValue
            guard !unlockedAchievementIds.contains(id) else { continue }
            if meetsCriteria(for: achievement) {
                newly.append(id)
            }
        }
        return newly
    }

    private func meetsCriteria(for achievement: AchievementDef) -> Bool {
        switch achievement {
        case .firstSteps:
            return ActivityKind.allCases.contains { completedLevelsCount(activity: $0) > 0 }
        case .starCollector:
            return totalStarsCount() >= 12
        case .labAssistant:
            return completedLevelsCount(activity: .scienceLab) >= 5
        case .wordSmith:
            return completedLevelsCount(activity: .languageAdventure) >= 5
        case .perfectLesson:
            for activity in ActivityKind.allCases {
                for difficulty in DifficultyTier.allCases {
                    for index in 0 ..< LevelAddress.levelsPerTrack {
                        let address = LevelAddress(activity: activity, difficulty: difficulty, levelIndex: index)
                        if stars(for: address) >= 3 { return true }
                    }
                }
            }
            return false
        case .dedicatedStudent:
            return totalPlaySeconds >= 600
        case .tripleThreat:
            return ActivityKind.allCases.allSatisfy { kind in
                for difficulty in DifficultyTier.allCases {
                    for index in 0 ..< LevelAddress.levelsPerTrack {
                        let address = LevelAddress(activity: kind, difficulty: difficulty, levelIndex: index)
                        if stars(for: address) >= 1 { return true }
                    }
                }
                return false
            }
        }
    }

    private func reconcileAchievementsFromProgress() {
        let newIds = evaluateNewAchievements()
        guard !newIds.isEmpty else { return }
        unlockedAchievementIds.formUnion(newIds)
        defaults.set(Array(unlockedAchievementIds), forKey: Keys.storedAchievementIds)
    }

    func isAchievementUnlocked(_ achievement: AchievementDef) -> Bool {
        unlockedAchievementIds.contains(achievement.rawValue)
    }

    func resetAllProgress() {
        let dictionary = defaults.dictionaryRepresentation()
        for key in dictionary.keys where
            key.hasPrefix("academy.") {
            defaults.removeObject(forKey: key)
        }
        hasSeenOnboarding = false
        totalPlaySeconds = 0
        sessionsPlayed = 0
        unlockedAchievementIds = []
        defaults.set(false, forKey: Keys.hasSeenOnboarding)
        defaults.set(0, forKey: Keys.totalPlaySeconds)
        defaults.set(0, forKey: Keys.sessionsPlayed)
        defaults.removeObject(forKey: Keys.storedAchievementIds)

        NotificationCenter.default.post(name: ProgressNotifications.progressDidReset, object: nil)
        objectWillChange.send()
    }

    private static func storageKey(for address: LevelAddress) -> String {
        "\(address.activity.rawValue).\(address.difficulty.rawValue).\(address.levelIndex)"
    }

    func refreshFromDefaults() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalPlaySeconds = defaults.double(forKey: Keys.totalPlaySeconds)
        sessionsPlayed = defaults.integer(forKey: Keys.sessionsPlayed)
        if let stored = defaults.array(forKey: Keys.storedAchievementIds) as? [String] {
            unlockedAchievementIds = Set(stored)
        } else {
            unlockedAchievementIds = []
        }
        objectWillChange.send()
    }
}
