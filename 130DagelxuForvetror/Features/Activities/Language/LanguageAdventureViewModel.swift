import Combine
import Foundation

@MainActor
final class LanguageAdventureViewModel: ObservableObject {
    struct Challenge: Identifiable {
        let id = UUID()
        let sentence: String
        let options: [String]
        let answer: String
        var scrambled: [String]?
    }

    enum Phase: Equatable {
        case playing
        case finished(ActivitySessionSummary)
    }

    @Published private(set) var phase: Phase = .playing
    @Published private(set) var current: Challenge
    @Published var selectedOption: String?
    @Published var orderedWords: [String]

    private let address: LevelAddress
    private let started = Date()
    private var roundIndex = 0
    private var correctAnswers = 0
    private let totalRounds: Int

    init(address: LevelAddress) {
        self.address = address
        self.totalRounds = 4 + min(address.levelIndex, 2)
        let first = Self.buildChallenge(difficulty: address.difficulty, level: address.levelIndex, index: 0)
        self.current = first
        self.orderedWords = first.scrambled ?? []
    }

    func submitEasyOrHardSelection() {
        guard let pick = selectedOption else {
            Haptics.warning()
            return
        }
        let ok = pick == current.answer
        advance(afterCorrect: ok)
    }

    func submitScrambled() {
        guard address.difficulty == .normal else { return }
        let joined = orderedWords.joined(separator: " ")
        let ok = joined == current.answer
        advance(afterCorrect: ok)
    }

    private func advance(afterCorrect ok: Bool) {
        Haptics.lightImpact()
        if ok {
            correctAnswers += 1
            Haptics.success()
        } else {
            Haptics.warning()
        }

        roundIndex += 1
        selectedOption = nil

        if roundIndex >= totalRounds {
            finalize()
            return
        }

        let next = Self.buildChallenge(difficulty: address.difficulty, level: address.levelIndex, index: roundIndex)
        current = next
        orderedWords = next.scrambled ?? []
    }

    private func finalize() {
        let accuracy = Double(correctAnswers) / Double(totalRounds)
        let passed = correctAnswers >= Int(ceil(Double(totalRounds) * 0.55))
        let summary = ActivitySessionSummary(
            activity: .languageAdventure,
            difficulty: address.difficulty,
            levelIndex: address.levelIndex,
            starsEarned: Self.stars(accuracy: accuracy, passed: passed, difficulty: address.difficulty),
            accuracyPercent: Int(round(accuracy * 100)),
            durationSeconds: Date().timeIntervalSince(started),
            passed: passed
        )
        phase = .finished(summary)
    }

    static func stars(accuracy: Double, passed: Bool, difficulty: DifficultyTier) -> Int {
        guard passed else { return 0 }
        var score = accuracy
        if difficulty == .normal { score -= 0.05 }
        if difficulty == .hard { score -= 0.08 }
        if score >= 0.92 { return 3 }
        if score >= 0.74 { return 2 }
        return 1
    }

    private static func buildChallenge(difficulty: DifficultyTier, level: Int, index: Int) -> Challenge {
        switch difficulty {
        case .easy:
            let bank = [
                ("The curious student reads a new book each week.", "curious"),
                ("Bright ideas spread quickly across the classroom.", "Bright"),
                ("Careful notes make difficult ideas feel simple.", "Careful"),
                ("Friendly questions help everyone learn together.", "Friendly"),
                ("Quiet focus turns small steps into big wins.", "Quiet")
            ]
            let pick = bank[(index + level) % bank.count]
            let options = ([pick.1, "sleepy", "noisy"]).shuffled()
            return Challenge(sentence: pick.0, options: options, answer: pick.1, scrambled: nil)
        case .normal:
            let fragments = [
                "Every",
                "experiment",
                "begins",
                "with",
                "a",
                "clear",
                "question"
]
            var words = fragments
            if index % 2 == 0 {
                words = ["Scientists", "observe", "patterns", "before", "they", "explain", "results"]
            }
            let joined = words.joined(separator: " ")
            return Challenge(sentence: joined, options: [], answer: joined, scrambled: words.shuffled())
        case .hard:
            let items = [
                ("Select the word that fits: The mixture became ___ after heating.", "thicker", ["thicker", "quieter", "smaller", "sleepier"]),
                ("Choose the precise verb: The team will ___ the results carefully.", "compare", ["compare", "ignore", "forget", "multiply"]),
                ("Pick the best fit: Honest feedback helps ideas grow ___. ", "stronger", ["stronger", "sideways", "backward", "silent"]),
                ("Context clue: The evidence was ___ so the class agreed quickly.", "clear", ["clear", "sticky", "purple", "imaginary"])
            ]
            let item = items[(index + level) % items.count]
            return Challenge(sentence: item.0, options: item.2.shuffled(), answer: item.1, scrambled: nil)
        }
    }

    func moveWordUp(at index: Int) {
        guard index > 0 else { return }
        orderedWords.swapAt(index, index - 1)
    }

    func moveWordDown(at index: Int) {
        guard index < orderedWords.count - 1 else { return }
        orderedWords.swapAt(index, index + 1)
    }

}
