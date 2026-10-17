import Foundation

struct MomentEngine {
    func plan(from rawText: String, pace: PaceMode) -> MomentPlan {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()
        let sentences = splitSentences(text)
        let signals = detectSignals(in: lower, pace: pace)
        let moves = buildMoves(from: sentences, lower: lower, pace: pace)
        let sorted = moves.sorted { lhs, rhs in
            lhs.weight == rhs.weight ? lhs.minutes < rhs.minutes : lhs.weight > rhs.weight
        }
        let fallback = MicroMove(
            title: "Name the smallest visible finish line",
            detail: "Write the outcome in one sentence, then do the first two-minute setup step.",
            minutes: min(8, pace.minutes),
            kind: .decide,
            weight: 0.55
        )
        let oneMove = sorted.first ?? fallback
        let nextMoves = Array(sorted.dropFirst().prefix(3))
        let parked = parkingLot(from: sentences, excluding: oneMove.title)
        let confidence = min(0.94, 0.48 + Double(signals.count) * 0.07 + Double(sorted.count) * 0.05)
        let friction = min(0.95, 0.2 + urgencyScore(lower) + ambiguityScore(lower))

        return MomentPlan(
            title: title(for: lower, fallback: text),
            oneMove: oneMove,
            nextMoves: nextMoves,
            parkingLot: parked,
            detectedSignals: signals,
            reason: reason(for: oneMove, lower: lower, signalCount: signals.count),
            script: script(for: oneMove, lower: lower),
            confidence: confidence,
            friction: friction
        )
    }

    private func detectSignals(in text: String, pace: PaceMode) -> [String] {
        var signals = ["\(pace.rawValue) lens"]
        if containsAny(text, ["today", "tonight", "now", "asap", "urgent", "late"]) {
            signals.append("time pressure")
        }
        if text.range(of: #"\b(before|by|at)\s+\d{1,2}(:\d{2})?\b"#, options: .regularExpression) != nil {
            signals.append("deadline mentioned")
        }
        if containsAny(text, ["mom", "dad", "kid", "wife", "husband", "friend", "boss", "client", "doctor", "teacher"]) {
            signals.append("other people involved")
        }
        if containsAny(text, ["buy", "pickup", "pick up", "store", "pharmacy", "grocery", "return"]) {
            signals.append("physical errand")
        }
        if containsAny(text, ["email", "text", "call", "reply", "message", "send"]) {
            signals.append("communication task")
        }
        if containsAny(text, ["decide", "choose", "figure out", "not sure", "maybe", "or"]) {
            signals.append("decision fog")
        }
        if containsAny(text, ["tired", "overwhelmed", "stressed", "anxious", "busy", "too much"]) {
            signals.append("low bandwidth")
        }
        return signals
    }

    private func buildMoves(from sentences: [String], lower: String, pace: PaceMode) -> [MicroMove] {
        var moves: [MicroMove] = []
        if containsAny(lower, ["call", "phone"]) {
            moves.append(.init(title: "Make the shortest call", detail: "Open with the ask, confirm the next concrete step, then hang up.", minutes: min(10, pace.minutes), kind: .call, weight: 0.84 + urgencyScore(lower)))
        }
        if containsAny(lower, ["email", "text", "reply", "message", "send"]) {
            moves.append(.init(title: "Send the imperfect message", detail: "Use the script below. The win is getting the thread moving, not sounding brilliant.", minutes: min(7, pace.minutes), kind: .message, weight: 0.78 + urgencyScore(lower)))
        }
        if containsAny(lower, ["buy", "pickup", "pick up", "store", "pharmacy", "grocery", "return", "drop off"]) {
            moves.append(.init(title: "Batch the outside-world errand", detail: "Pair the stop with the next time you leave. Add only the location and close time.", minutes: min(18, pace.minutes), kind: .errand, weight: 0.75))
        }
        if containsAny(lower, ["appointment", "meeting", "calendar", "schedule", "book", "deadline"]) {
            moves.append(.init(title: "Put a time box on the calendar", detail: "Reserve the smallest real block before the day fills itself.", minutes: min(5, pace.minutes), kind: .schedule, weight: 0.81 + urgencyScore(lower)))
        }
        if containsAny(lower, ["decide", "choose", "figure out", "maybe", "option", "or"]) {
            moves.append(.init(title: "Make the reversible choice", detail: "Pick the option that keeps the most doors open for 24 hours.", minutes: min(12, pace.minutes), kind: .decide, weight: 0.72 + ambiguityScore(lower)))
        }
        if containsAny(lower, ["tired", "overwhelmed", "stressed", "anxious", "busy", "too much"]) {
            moves.append(.init(title: "Do a two-minute reset first", detail: "Clear the surface, drink water, and remove one avoidable input before acting.", minutes: 2, kind: .reset, weight: 0.7))
        }

        for sentence in sentences.prefix(4) where sentence.count > 18 {
            let cleaned = sentence.replacingOccurrences(of: "\n", with: " ")
            moves.append(.init(title: actionTitle(from: cleaned), detail: cleaned, minutes: estimatedMinutes(for: cleaned, pace: pace), kind: inferredKind(from: cleaned.lowercased()), weight: sentenceWeight(cleaned.lowercased())))
        }

        return moves
    }

    private func splitSentences(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func actionTitle(from sentence: String) -> String {
        let words = sentence.split(separator: " ").prefix(8).joined(separator: " ")
        return words.first.map { "Start: " + String($0).uppercased() + words.dropFirst() } ?? "Start the obvious next step"
    }

    private func reason(for move: MicroMove, lower: String, signalCount: Int) -> String {
        if move.kind == .reset {
            return "Bandwidth is the bottleneck, so the app lowers noise before asking for effort."
        }
        if containsAny(lower, ["today", "tonight", "now", "asap", "urgent", "late", "deadline"]) {
            return "A time-bound item beats vague planning. This move creates motion before the window closes."
        }
        if signalCount >= 4 {
            return "Several signals are competing. Moment chooses the move that unlocks the most follow-up choices."
        }
        return "This is the smallest visible action with a clean finish line."
    }

    private func inferredKind(from text: String) -> MoveKind {
        if containsAny(text, ["call", "phone"]) { return .call }
        if containsAny(text, ["email", "text", "reply", "message", "send"]) { return .message }
        if containsAny(text, ["buy", "pickup", "store", "pharmacy", "grocery", "return"]) { return .errand }
        if containsAny(text, ["calendar", "schedule", "book", "appointment"]) { return .schedule }
        if containsAny(text, ["decide", "choose", "maybe", "or"]) { return .decide }
        return .reset
    }

    private func estimatedMinutes(for text: String, pace: PaceMode) -> Int {
        let base = max(4, min(25, text.split(separator: " ").count / 2))
        return min(base, pace.minutes)
    }

    private func sentenceWeight(_ text: String) -> Double {
        0.45 + urgencyScore(text) + ambiguityScore(text) + (containsAny(text, ["need", "must", "should"]) ? 0.16 : 0)
    }

    private func urgencyScore(_ text: String) -> Double {
        containsAny(text, ["today", "tonight", "now", "asap", "urgent", "late", "deadline"]) ? 0.2 : 0
    }

    private func ambiguityScore(_ text: String) -> Double {
        containsAny(text, ["maybe", "not sure", "figure out", "overwhelmed", "too much", "or"]) ? 0.15 : 0
    }

    private func parkingLot(from sentences: [String], excluding title: String) -> [String] {
        let parked = sentences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !title.lowercased().contains($0.prefix(12).lowercased()) }
            .prefix(3)
        return parked.isEmpty ? ["Anything not needed for the first move waits here."] : Array(parked)
    }

    private func title(for lower: String, fallback: String) -> String {
        if containsAny(lower, ["morning", "today"]) { return "Today, without the pile-up" }
        if containsAny(lower, ["family", "kid", "mom", "dad"]) { return "Reduce the family logistics load" }
        if containsAny(lower, ["work", "client", "boss"]) { return "Unstick the work thread" }
        return fallback.isEmpty ? "Clear the next ten minutes" : "One useful move from the mess"
    }

    private func script(for move: MicroMove, lower: String) -> String {
        switch move.kind {
        case .call:
            return "Hi, quick check: I need to resolve this today. What is the next step, and who owns it?"
        case .message:
            return "Quick update: I am trying to close the loop on this. The next useful step I see is [one move]. Does that work?"
        case .errand:
            return "When I leave next, I only need: location, item, close time. Everything else can wait."
        case .decide:
            return lower.contains("or") ? "For the next 24 hours, I am choosing the option that is easiest to reverse." : "I am deciding the next test, not the final answer."
        case .schedule:
            return "Block the time first. Details can be cleaned up inside the block."
        case .reset:
            return "Before solving the whole thing, I am lowering the noise and making the first move visible."
        }
    }

    private func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }
}
