import SwiftUI

struct ContentView: View {
    @State private var prompt = "I need to reply to my landlord, pick up the prescription before 6, figure out dinner, and I keep avoiding the insurance form because I am tired."
    @State private var pace: PaceMode = .now
    @State private var plan = MomentEngine().plan(
        from: "I need to reply to my landlord, pick up the prescription before 6, figure out dinner, and I keep avoiding the insurance form because I am tired.",
        pace: .now
    )
    @State private var completed: Set<UUID> = []

    private let engine = MomentEngine()

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    inputPanel
                    PlanHero(plan: plan, completed: completed.contains(plan.oneMove.id)) {
                        toggle(plan.oneMove.id)
                    }
                    CompassCard(plan: plan)
                    ReasonCard(plan: plan)
                    if !plan.nextMoves.isEmpty {
                        moveStack
                    }
                    scriptCard
                    parkingLot
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .tint(.teal)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Moment")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(Color.ink)
                Text("The smallest useful move from daily chaos.")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.mutedInk)
            }
            Spacer()
            Image(systemName: "wand.and.rays.inverse")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(Color.paper)
                .frame(width: 54, height: 54)
                .background(Circle().fill(Color.ink))
                .accessibilityHidden(true)
        }
    }

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Pace", selection: $pace) {
                ForEach(PaceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: pace) { _, newValue in
                analyze(pace: newValue)
            }

            TextEditor(text: $prompt)
                .font(.body)
                .foregroundStyle(Color.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 118)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.62)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ink.opacity(0.08)))
                .accessibilityLabel("Messy daily situation")

            Button {
                analyze(pace: pace)
            } label: {
                Label("Find the move", systemImage: "sparkle.magnifyingglass")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 8))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.panel))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ink.opacity(0.08)))
    }

    private var moveStack: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Then")
                .font(.title3.bold())
                .foregroundStyle(Color.ink)
            ForEach(plan.nextMoves) { move in
                MoveRow(move: move, isComplete: completed.contains(move.id)) {
                    toggle(move.id)
                }
            }
        }
    }

    private var scriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Ready words", systemImage: "quote.bubble.fill")
                .font(.headline)
                .foregroundStyle(Color.violet)
            Text(plan.script)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.72)))
    }

    private var parkingLot: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Parked on purpose", systemImage: "tray.full.fill")
                .font(.headline)
                .foregroundStyle(Color.gold)
            ForEach(plan.parkingLot, id: \.self) { item in
                Text(item)
                    .font(.subheadline)
                    .foregroundStyle(Color.mutedInk)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.panel))
    }

    private func analyze(pace: PaceMode) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            plan = engine.plan(from: prompt, pace: pace)
            completed = []
        }
    }

    private func toggle(_ id: UUID) {
        if completed.contains(id) {
            completed.remove(id)
        } else {
            completed.insert(id)
        }
    }
}

private struct PlanHero: View {
    let plan: MomentPlan
    let completed: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(plan.title)
                    .font(.title2.bold())
                    .foregroundStyle(Color.paper)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text("\(plan.oneMove.minutes)m")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.paper)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.16)))
            }

            HStack(alignment: .center, spacing: 14) {
                Button(action: onToggle) {
                    Image(systemName: completed ? "checkmark.circle.fill" : plan.oneMove.symbol)
                        .font(.system(size: 27, weight: .bold))
                        .frame(width: 58, height: 58)
                        .foregroundStyle(completed ? Color.mint : Color.paper)
                        .background(Circle().fill(Color.white.opacity(0.14)))
                }
                .accessibilityLabel(completed ? "Mark incomplete" : "Mark complete")

                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.oneMove.title)
                        .font(.title3.bold())
                        .foregroundStyle(Color.paper)
                    Text(plan.oneMove.detail)
                        .font(.subheadline)
                        .foregroundStyle(Color.paper.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            signalRail
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color.ink, Color.teal, Color.coral.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }

    private var signalRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(plan.detectedSignals, id: \.self) { signal in
                    Text(signal)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.paper)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.white.opacity(0.16)))
                }
            }
        }
    }
}

private struct ReasonCard: View {
    let plan: MomentPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Why this move", systemImage: "scope")
                .font(.headline)
                .foregroundStyle(Color.ink)
            Text(plan.reason)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.72)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ink.opacity(0.07)))
    }
}

private struct CompassCard: View {
    let plan: MomentPlan

    var body: some View {
        HStack(spacing: 12) {
            Meter(title: "Fit", value: plan.confidence, color: .teal)
            Meter(title: "Friction", value: plan.friction, color: .coral)
        }
    }
}

private struct Meter: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.mutedInk)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.ink)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ink.opacity(0.08))
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * value)
                }
            }
            .frame(height: 9)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.72)))
    }
}

private struct MoveRow: View {
    let move: MicroMove
    let isComplete: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : move.symbol)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(isComplete ? Color.mint : move.tint)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(move.tint.opacity(0.12)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(move.title)
                        .font(.headline)
                        .foregroundStyle(Color.ink)
                    Text(move.detail)
                        .font(.caption)
                        .foregroundStyle(Color.mutedInk)
                        .lineLimit(2)
                }
                Spacer()
                Text("\(move.minutes)m")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.mutedInk)
            }
            .padding(13)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.panel))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ink.opacity(0.07)))
        }
        .buttonStyle(.plain)
    }
}
