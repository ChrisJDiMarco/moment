# Moment

Moment is a native SwiftUI iPhone app for one everyday job: turning a messy daily situation into the smallest useful next move.

## Research basis

- Everyday AI is moving toward ambient, task-specific help, but trust depends on making the model's assumptions visible.
- Recent AI product coverage keeps pointing at the same failure mode: broad assistants add surface area, while useful everyday AI reduces cognitive overload around one concrete job.
- Household generative AI research suggests the practical value is reducing effort around productive non-market tasks, not replacing all planning.
- Human-AI studies warn that people often overestimate AI speedups, so Moment focuses on lowering mental load and preserving agency instead of promising automation.
- Cognitive-friction research points to a better pattern: the assistant should show signals, confidence, and what it parked.

## Product choice

The app avoids a generic chatbot. It is a single-purpose “life triage instrument”:

1. Paste or type a messy situation.
2. Pick a pace: Now, Today, or This Week.
3. Moment detects signals such as time pressure, people, errands, decisions, and low bandwidth.
4. It recommends one move, explains why that move won, offers small follow-ups, gives ready-to-send words, and parks the rest.

The current prototype is local and key-free. Its planner is deterministic and transparent, which keeps the simulator build reliable while leaving a clean path to swap in Apple's on-device Foundation Models framework later for richer natural-language planning.

## Design direction

Moment should feel like a pocket triage instrument, not a todo app. The interface uses one strong primary recommendation, visible signal chips, friction/fit meters, and a deliberate "parked" section so the user can trust what the app ignored.

Sources checked during concept selection:

- TechRadar, June 24, 2026: wearable/everyday AI succeeds when it reduces cognitive overload around a specific issue.
- TechRadar, January 2026: AI is becoming ambient inside everyday tasks, but trust and agency remain the product risk.
- Tom's Guide, January 2026: everyday AI is already most useful when it quietly improves search, writing, photos, health, and navigation instead of demanding a new workflow.
- Apple developer direction: iOS 26-era Foundation Models make private on-device AI plausible for this pattern, but this prototype avoids requiring beta-only APIs.

## Build

```sh
xcodebuild -project projects/Moment/Moment.xcodeproj -scheme Moment -destination 'generic/platform=iOS Simulator' build
```
