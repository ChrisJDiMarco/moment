import Foundation
import SwiftUI

enum PaceMode: String, CaseIterable, Identifiable {
    case now = "Now"
    case today = "Today"
    case week = "This Week"

    var id: String { rawValue }

    var minutes: Int {
        switch self {
        case .now: 12
        case .today: 35
        case .week: 90
        }
    }
}

enum MoveKind: String {
    case call = "Call"
    case message = "Message"
    case errand = "Errand"
    case decide = "Decide"
    case schedule = "Schedule"
    case reset = "Reset"
}

struct MicroMove: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let minutes: Int
    let kind: MoveKind
    let weight: Double

    var symbol: String {
        switch kind {
        case .call: "phone.fill"
        case .message: "message.fill"
        case .errand: "figure.walk"
        case .decide: "switch.2"
        case .schedule: "calendar.badge.clock"
        case .reset: "sparkles"
        }
    }

    var tint: Color {
        switch kind {
        case .call: .coral
        case .message: .violet
        case .errand: .teal
        case .decide: .ink
        case .schedule: .gold
        case .reset: .mint
        }
    }
}

struct MomentPlan {
    let title: String
    let oneMove: MicroMove
    let nextMoves: [MicroMove]
    let parkingLot: [String]
    let detectedSignals: [String]
    let reason: String
    let script: String
    let confidence: Double
    let friction: Double
}

extension Color {
    static let paper = Color(red: 0.965, green: 0.952, blue: 0.918)
    static let panel = Color(red: 0.996, green: 0.988, blue: 0.958)
    static let ink = Color(red: 0.105, green: 0.122, blue: 0.136)
    static let mutedInk = Color(red: 0.39, green: 0.40, blue: 0.39)
    static let teal = Color(red: 0.00, green: 0.47, blue: 0.48)
    static let coral = Color(red: 0.88, green: 0.29, blue: 0.23)
    static let violet = Color(red: 0.42, green: 0.30, blue: 0.78)
    static let gold = Color(red: 0.80, green: 0.54, blue: 0.15)
    static let mint = Color(red: 0.28, green: 0.62, blue: 0.44)
}
