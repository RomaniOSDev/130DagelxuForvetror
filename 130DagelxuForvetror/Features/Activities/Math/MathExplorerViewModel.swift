import Combine
import Foundation

@MainActor
final class MathExplorerViewModel: ObservableObject {
    struct Step: Identifiable, Equatable {
        let id = UUID()
        let prompt: String
        let correct: Int
        let choices: [Int]
        let timeLimit: TimeInterval?
    }

    @Published private(set) var steps: [Step] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var correctCount = 0
    @Published private(set) var mistakes = 0
    @Published private(set) var phase: Phase = .playing

    enum Phase: Equatable {
        case playing
        case finished(passed: Bool, summary: ActivitySessionSummary)
    }

    private let address: LevelAddress
    private let started = Date()

    init(address: LevelAddress) {
        self.address = address
        regenerateSteps()
    }

    var currentStep: Step? {
        guard currentIndex < steps.count else { return nil }
        return steps[currentIndex]
    }

    var livesRemaining: Int {
        let maxLives = maxLivesForDifficulty
        return max(0, maxLives - mistakes)
    }

    private var maxLivesForDifficulty: Int {
        switch address.difficulty {
        case .easy: return 4
        case .normal: return 3
        case .hard: return 2
        }
    }

    func registerAnswer(_ value: Int) {
        guard case .playing = phase, let step = currentStep else { return }
        Haptics.lightImpact()

        let ok = value == step.correct
        if ok {
            correctCount += 1
            Haptics.success()
        } else {
            mistakes += 1
            Haptics.warning()
        }

        let failedByLives = mistakes > maxLivesForDifficulty
        if failedByLives {
            finishSession(passed: false)
            return
        }

        if currentIndex + 1 >= steps.count {
            finishSession(passed: true)
        } else {
            currentIndex += 1
            stepDeadline = nil
        }
    }

    func tickTimer() {
        guard address.difficulty != .easy, case .playing = phase, let step = currentStep, let limit = step.timeLimit else { return }
        stepDeadline = stepDeadline ?? Date().addingTimeInterval(limit)
        if let deadline = stepDeadline, Date() > deadline {
            mistakes += 1
            stepDeadline = nil
            Haptics.warning()
            let failedByLives = mistakes > maxLivesForDifficulty
            if failedByLives {
                finishSession(passed: false)
                return
            }
            if currentIndex + 1 >= steps.count {
                finishSession(passed: true)
            } else {
                currentIndex += 1
                stepDeadline = nil
            }
        }
    }

    private var stepDeadline: Date?

    private func finishSession(passed: Bool) {
        stepDeadline = nil
        let total = steps.count
        let accuracy = total == 0 ? 0 : Double(correctCount) / Double(total)
        let accuracyPercent = Int(round(accuracy * 100))
        let duration = Date().timeIntervalSince(started)
        let stars = Self.stars(for: accuracy, passed: passed, difficulty: address.difficulty)
        let summary = ActivitySessionSummary(
            activity: .mathExplorer,
            difficulty: address.difficulty,
            levelIndex: address.levelIndex,
            starsEarned: stars,
            accuracyPercent: accuracyPercent,
            durationSeconds: duration,
            passed: passed
        )
        phase = .finished(passed: passed, summary: summary)
    }

    private static func stars(for accuracy: Double, passed: Bool, difficulty: DifficultyTier) -> Int {
        guard passed else { return 0 }
        var score = accuracy
        if difficulty == .normal { score -= 0.05 }
        if difficulty == .hard { score -= 0.08 }
        if score >= 0.92 { return 3 }
        if score >= 0.75 { return 2 }
        return 1
    }

    private func regenerateSteps() {
        steps = []
        currentIndex = 0
        correctCount = 0
        mistakes = 0
        phase = .playing
        stepDeadline = nil

        let count = baseRoundCount + min(address.levelIndex, 3)
        for index in 0 ..< count {
            steps.append(generateStep(roundIndex: index))
        }
    }

    private var baseRoundCount: Int {
        switch address.difficulty {
        case .easy: return 4
        case .normal: return 5
        case .hard: return 4
        }
    }

    private func generateStep(roundIndex: Int) -> Step {
        let levelBoost = address.levelIndex
        switch address.difficulty {
        case .easy:
            let a = Int.random(in: 2 ... 8 + levelBoost)
            let b = Int.random(in: 2 ... 8 + levelBoost)
            let isAdd = Bool.random()
            let prompt = isAdd ? "Combine \(a) and \(b)" : "Subtract smaller from \(max(a, b))"
            let correct = isAdd ? a + b : abs(a - b)
            return Step(
                prompt: prompt,
                correct: correct,
                choices: buildChoices(correct: correct, spread: 14),
                timeLimit: nil
            )
        case .normal:
            let a = Int.random(in: 4 ... 12 + levelBoost)
            let b = Int.random(in: 3 ... 10 + levelBoost)
            let modes = ["multiply", "divide", "add"]
            let mode = modes[roundIndex % modes.count]
            let prompt: String
            let correct: Int
            switch mode {
            case "multiply":
                prompt = "\(a) × \(b)"
                correct = a * b
            case "divide":
                let divisor = max(2, min(b, a))
                let quotient = max(2, a)
                let dividend = quotient * divisor
                prompt = "\(dividend) ÷ \(divisor)"
                correct = quotient
            default:
                prompt = "\(a) + \(b)"
                correct = a + b
            }
            return Step(
                prompt: prompt,
                correct: correct,
                choices: buildChoices(correct: correct, spread: 40),
                timeLimit: 12
            )
        case .hard:
            let x = Int.random(in: 2 ... 5 + levelBoost / 2)
            let y = Int.random(in: 2 ... 6 + levelBoost / 2)
            let z = Int.random(in: 2 ... 4)
            if roundIndex % 2 == 0 {
                let sum = x + y
                let prompt = "First \(x) + \(y), then multiply by \(z)"
                let correct = sum * z
                return Step(
                    prompt: prompt,
                    correct: correct,
                    choices: buildChoices(correct: correct, spread: max(18, correct / 2)),
                    timeLimit: 18
                )
            } else {
                let inner = x * y
                let correct = inner - z
                let prompt = "Take \(x) × \(y), then remove \(z)"
                return Step(
                    prompt: prompt,
                    correct: correct,
                    choices: buildChoices(correct: correct, spread: max(20, inner)),
                    timeLimit: 20
                )
            }
        }
    }

    private func buildChoices(correct: Int, spread: Int) -> [Int] {
        var set: Set<Int> = [correct]
        while set.count < 4 {
            let delta = Int.random(in: -spread ... spread)
            let candidate = correct + delta
            if candidate > 0 {
                set.insert(candidate)
            }
        }
        return set.shuffled()
    }
}
