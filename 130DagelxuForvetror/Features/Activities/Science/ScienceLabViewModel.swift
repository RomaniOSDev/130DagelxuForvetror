import Combine
import Foundation
import SwiftUI

@MainActor
final class ScienceLabViewModel: ObservableObject {
    enum Phase: Equatable {
        case playing
        case finished(ActivitySessionSummary)
    }

    @Published private(set) var phase: Phase = .playing
    @Published var beakerOffset: CGSize = .zero
    @Published var selectedHypothesisIndex: Int?
    @Published var variableSlider: Double = 0.5

    private let address: LevelAddress
    private let started = Date()
    private(set) var roundsCompleted = 0
    private var hardMistakes = 0

    private var roundsRequired: Int {
        switch address.difficulty {
        case .easy: return 3
        case .normal: return 4
        case .hard: return 3
        }
    }

    /// Rounds to finish (for UI labels).
    var goalRounds: Int { roundsRequired }

    private(set) var targetHypothesisOutcome: Double = 0.62
    private var normalMistakes = 0

    /// Whole-number hint shown on Hard mode (slider + hypothesis should combine near this).
    var targetMixPercent: Int {
        Int(round(targetHypothesisOutcome * 100))
    }

    init(address: LevelAddress) {
        self.address = address
        targetHypothesisOutcome = 0.42 + Double(address.levelIndex % 6) * 0.06
    }

    var snapTarget: CGPoint {
        CGPoint(x: 0, y: 40)
    }

    func dragEnded() {
        guard address.difficulty == .easy else { return }
        let target = snapTarget
        let current = CGPoint(x: beakerOffset.width, y: beakerOffset.height)
        let distance = hypot(current.x - target.x, current.y - target.y)
        if distance < 62 {
            Haptics.success()
            beakerOffset = CGSize(width: target.x, height: target.y)
            roundsCompleted += 1
            if roundsCompleted < roundsRequired {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    beakerOffset = .zero
                }
            }
            evaluateEasyProgress()
        } else {
            Haptics.warning()
        }
    }

    private func evaluateEasyProgress() {
        if roundsCompleted >= roundsRequired {
            finish(passed: true, accuracy: 0.95)
        }
    }

    func registerNormalHeatHit(isInWindow: Bool) {
        guard address.difficulty == .normal else { return }
        if isInWindow {
            roundsCompleted += 1
            normalMistakes = 0
            Haptics.success()
            if roundsCompleted >= roundsRequired {
                finish(passed: true, accuracy: 0.9)
            }
        } else {
            normalMistakes += 1
            Haptics.warning()
            if normalMistakes >= 6 {
                finish(passed: false, accuracy: 0.35)
            }
        }
    }

    func submitHardExperiment() {
        guard address.difficulty == .hard else { return }
        guard let index = selectedHypothesisIndex else {
            Haptics.warning()
            return
        }
        let hypothesisPart = Double(index) / 2.0 * 0.35
        let outcome = hypothesisPart + variableSlider * 0.65
        let delta = abs(outcome - targetHypothesisOutcome)
        let roundOk = delta < 0.16

        if roundOk {
            roundsCompleted += 1
            hardMistakes = 0
            Haptics.success()
            if roundsCompleted >= roundsRequired {
                let accuracy = max(0.55, 1 - delta * 2.2)
                finish(passed: true, accuracy: accuracy)
            } else {
                selectedHypothesisIndex = nil
                variableSlider = 0.5
                targetHypothesisOutcome = 0.38 + Double.random(in: 0 ... 0.42)
            }
        } else {
            hardMistakes += 1
            Haptics.warning()
            if hardMistakes >= 6 {
                finish(passed: false, accuracy: 0.4)
            }
        }
    }

    private func finish(passed: Bool, accuracy: Double) {
        let accuracyPercent = Int(round(min(1, max(0, accuracy)) * 100))
        let duration = Date().timeIntervalSince(started)
        let stars = Self.stars(accuracy: accuracy, passed: passed, difficulty: address.difficulty)
        let summary = ActivitySessionSummary(
            activity: .scienceLab,
            difficulty: address.difficulty,
            levelIndex: address.levelIndex,
            starsEarned: stars,
            accuracyPercent: accuracyPercent,
            durationSeconds: duration,
            passed: passed
        )
        phase = .finished(summary)
    }

    private static func stars(accuracy: Double, passed: Bool, difficulty: DifficultyTier) -> Int {
        guard passed else { return 0 }
        var score = accuracy
        if difficulty == .normal { score -= 0.05 }
        if difficulty == .hard { score -= 0.08 }
        if score >= 0.9 { return 3 }
        if score >= 0.72 { return 2 }
        return 1
    }
}
