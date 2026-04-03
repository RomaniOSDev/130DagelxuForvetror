import Foundation

struct DifficultyRoute: Hashable {
    let activity: ActivityKind
    let tier: DifficultyTier
}

struct PlayDestination: Hashable {
    let address: LevelAddress
}

struct ResultPayload: Hashable {
    let summary: ActivitySessionSummary
    let address: LevelAddress
    let freshAchievements: [AchievementDef]
}
