import Foundation

enum ActivityKind: String, CaseIterable, Codable, Hashable {
    case mathExplorer
    case scienceLab
    case languageAdventure

    var titleKey: String {
        switch self {
        case .mathExplorer: return "Math Explorer"
        case .scienceLab: return "Science Lab"
        case .languageAdventure: return "Language Adventure"
        }
    }
}

enum DifficultyTier: String, CaseIterable, Codable, Hashable {
    case easy
    case normal
    case hard

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

struct LevelAddress: Hashable, Codable {
    var activity: ActivityKind
    var difficulty: DifficultyTier
    var levelIndex: Int

    static let levelsPerTrack = 6
}

struct ActivitySessionSummary: Hashable {
    let activity: ActivityKind
    let difficulty: DifficultyTier
    let levelIndex: Int
    let starsEarned: Int
    let accuracyPercent: Int
    let durationSeconds: TimeInterval
    let passed: Bool
}

enum AchievementDef: String, CaseIterable, Identifiable {
    case firstSteps
    case starCollector
    case labAssistant
    case wordSmith
    case perfectLesson
    case dedicatedStudent
    case tripleThreat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstSteps: return "First Steps"
        case .starCollector: return "Star Collector"
        case .labAssistant: return "Lab Assistant"
        case .wordSmith: return "Word Smith"
        case .perfectLesson: return "Perfect Lesson"
        case .dedicatedStudent: return "Dedicated Student"
        case .tripleThreat: return "Triple Track"
        }
    }

    var detail: String {
        switch self {
        case .firstSteps: return "Finish any lesson."
        case .starCollector: return "Collect 12 total stars."
        case .labAssistant: return "Clear 5 Science Lab levels."
        case .wordSmith: return "Clear 5 Language Adventure levels."
        case .perfectLesson: return "Earn three stars on a single level."
        case .dedicatedStudent: return "Spend 10 minutes learning."
        case .tripleThreat: return "Earn at least one star in every activity."
        }
    }
}
