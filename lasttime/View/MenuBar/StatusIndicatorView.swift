//
//  StatusIndicatorView.swift
//  lasttime
//
//  Created by Ram Janarthan on 20/4/26.
//

import SwiftUI
import AppKit
import SwiftUI
import AppKit

struct StatusIndicatorView: View {
    let state: AudioAgentState

    @State private var targetState: AudioAgentState = .idle

    @State private var transitionStart: Date?
    @State private var transitionDuration: TimeInterval = 0.0

    @State private var frozenFromPositions: [CGPoint] = Array(repeating: .zero, count: 5)
    @State private var frozenFromColor: Color = .secondary
    @State private var lastSampleTime: Date = .now

    private let dotCount = 5
    private let dotSize: CGFloat = 4
    private let spacing: CGFloat = 8
    private let indicatorWidth: CGFloat = 64
    private let indicatorHeight: CGFloat = 40

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let now = timeline.date

            Canvas { context, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                let phase = CGFloat(now.timeIntervalSinceReferenceDate)
                let progress = transitionProgress(at: now)

                for i in 0..<dotCount {
                    let target = targetPosition(
                        for: targetState,
                        index: i,
                        centerX: centerX,
                        centerY: centerY,
                        phase: phase
                    )

                    let position = lerp(frozenFromPositions[i], target, progress)

                    let rect = CGRect(
                        x: position.x - dotSize / 2,
                        y: position.y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )

                    context.fill(
                        Circle().path(in: rect),
                        with: .color(interpolatedColor(progress: progress))
                    )
                }
            }
            .onAppear {
                initializeIfNeeded(at: now)
                lastSampleTime = now
            }
            .onChange(of: now) { _, newNow in
                lastSampleTime = newNow
            }
        }
        .frame(width: indicatorWidth, height: indicatorHeight)
        .onAppear {
            targetState = state
        }
        .onChange(of: state) { _, newState in
            guard newState != targetState else { return }

            // Capture the exact currently rendered geometry as the new transition's start.
            let now = Date()
            let size = CGSize(width: indicatorWidth, height: indicatorHeight)
            let centerX = size.width / 2
            let centerY = size.height / 2
            let phase = CGFloat(now.timeIntervalSinceReferenceDate)
            let currentProgress = transitionProgress(at: now)

            var currentPositions: [CGPoint] = []
            currentPositions.reserveCapacity(dotCount)

            for i in 0..<dotCount {
                let currentTarget = targetPosition(
                    for: targetState,
                    index: i,
                    centerX: centerX,
                    centerY: centerY,
                    phase: phase
                )
                let currentRendered = lerp(frozenFromPositions[i], currentTarget, currentProgress)
                currentPositions.append(currentRendered)
            }

            frozenFromPositions = currentPositions
            frozenFromColor = interpolatedColor(progress: currentProgress)

            targetState = newState
            transitionStart = now
            transitionDuration = duration(to: newState)
        }
    }

    // MARK: - Init

    private func initializeIfNeeded(at now: Date) {
        if frozenFromPositions.allSatisfy({ $0 == .zero }) {
            let centerX = indicatorWidth / 2
            let centerY = indicatorHeight / 2
            let phase = CGFloat(now.timeIntervalSinceReferenceDate)

            frozenFromPositions = (0..<dotCount).map { i in
                targetPosition(
                    for: state,
                    index: i,
                    centerX: centerX,
                    centerY: centerY,
                    phase: phase
                )
            }

            frozenFromColor = dotColor(for: state)
            targetState = state
            transitionStart = nil
            transitionDuration = 0
        }
    }

    // MARK: - Transition Progress

    private func transitionProgress(at now: Date) -> CGFloat {
        guard let transitionStart, transitionDuration > 0 else { return 1 }

        let elapsed = now.timeIntervalSince(transitionStart)
        if elapsed >= transitionDuration {
            return 1
        }

        let raw = CGFloat(elapsed / transitionDuration)
        return smoothstep(raw)
    }

    // MARK: - Target Motion Fields

    private func targetPosition(
        for state: AudioAgentState,
        index: Int,
        centerX: CGFloat,
        centerY: CGFloat,
        phase: CGFloat
    ) -> CGPoint {
        switch state {
        case .idle:
            return wavePosition(
                amplitude: 1.0,
                frequency: 6.4,
                drift: 0.2,
                index: index,
                centerX: centerX,
                centerY: centerY,
                phase: phase
            )

        case .transcribing:
            return wavePosition(
                amplitude: 4.0,
                frequency: 10.2,
                drift: 0.9,
                index: index,
                centerX: centerX,
                centerY: centerY,
                phase: phase
            )

        case .processing:
            return circlePosition(
                index: index,
                centerX: centerX,
                centerY: centerY,
                phase: phase,
                radius: 8,
                angularSpeed: 2.2
            )

        case .responding:
            return checkmarkPositions(centerX: centerX, centerY: centerY)[index]

        case .error:
            return frownPositions(centerX: centerX, centerY: centerY)[index]
        }
    }

    private func wavePosition(
        amplitude: CGFloat,
        frequency: CGFloat,
        drift: CGFloat,
        index: Int,
        centerX: CGFloat,
        centerY: CGFloat,
        phase: CGFloat
    ) -> CGPoint {
        let totalWidth = CGFloat(dotCount - 1) * spacing
        let startX = centerX - totalWidth / 2
        let baseX = startX + CGFloat(index) * spacing

        let wavePhase = phase * frequency + CGFloat(index) * .pi * 0.55
        let x = baseX + cos(wavePhase) * drift
        let y = centerY + sin(wavePhase) * amplitude

        return CGPoint(x: x, y: y)
    }

    private func circlePosition(
        index: Int,
        centerX: CGFloat,
        centerY: CGFloat,
        phase: CGFloat,
        radius: CGFloat,
        angularSpeed: CGFloat
    ) -> CGPoint {
        let angle = phase * angularSpeed + CGFloat(index) * (2 * .pi / CGFloat(dotCount))
        return CGPoint(
            x: centerX + cos(angle) * radius,
            y: centerY + sin(angle) * radius
        )
    }

    // MARK: - Shapes

    private func checkmarkPositions(centerX: CGFloat, centerY: CGFloat) -> [CGPoint] {
        let points: [(CGFloat, CGFloat)] = [
            (-13, -1),
            (-7, 5),
            (-1, 10),
            (8, 0),
            (15, -9),
        ]
        return points.map { dx, dy in
            CGPoint(x: centerX + dx, y: centerY + dy)
        }
    }

    private func frownPositions(centerX: CGFloat, centerY: CGFloat) -> [CGPoint] {
        let radius: CGFloat = 12
        let points: [CGFloat] = [0.0, 0.25, 0.5, 0.75, 1.0]
        return points.map { t in
            let angle = .pi + t * .pi
            return CGPoint(
                x: centerX + cos(angle) * radius,
                y: centerY - 3 + sin(angle) * radius
            )
        }
    }

    // MARK: - Color

    private func dotColor(for state: AudioAgentState) -> Color {
        switch state {
        case .idle:
            return .secondary
        case .transcribing:
            return .blue
        case .processing:
            return .orange
        case .responding:
            return .green
        case .error:
            return .red
        }
    }

    private func interpolatedColor(progress: CGFloat) -> Color {
        Color.mix(
            from: frozenFromColor,
            to: dotColor(for: targetState),
            progress: progress
        )
    }

    // MARK: - Timing

    private func duration(to state: AudioAgentState) -> TimeInterval {
        switch state {
        case .transcribing:
            return 0.55
        case .processing:
            return 0.9
        case .idle:
            return 0.9
        case .responding, .error:
            return 0.7
        }
    }

    // MARK: - Math

    private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(
            x: a.x + (b.x - a.x) * t,
            y: a.y + (b.y - a.y) * t
        )
    }

    private func smoothstep(_ t: CGFloat) -> CGFloat {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }
}

private extension Color {
    static func mix(from: Color, to: Color, progress: CGFloat) -> Color {
        let fromComponents = NSColor(from).usingColorSpace(.deviceRGB) ?? .systemGray
        let toComponents = NSColor(to).usingColorSpace(.deviceRGB) ?? .systemGray

        let p = min(max(progress, 0), 1)
        let r = fromComponents.redComponent + (toComponents.redComponent - fromComponents.redComponent) * p
        let g = fromComponents.greenComponent + (toComponents.greenComponent - fromComponents.greenComponent) * p
        let b = fromComponents.blueComponent + (toComponents.blueComponent - fromComponents.blueComponent) * p
        let a = fromComponents.alphaComponent + (toComponents.alphaComponent - fromComponents.alphaComponent) * p
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}
