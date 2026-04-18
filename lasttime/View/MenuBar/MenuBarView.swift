//
//  MenuBarView.swift
//  lasttime
//
//  Created by Ram Janarthan on 14/4/26.
//

import SwiftUI

// MARK: - Status Indicator View

struct StatusIndicatorView: View {
    let state: AudioAgentState

    @State private var fromState: AudioAgentState = .idle
    @State private var toState: AudioAgentState = .idle
    @State private var transitionProgress: CGFloat = 1.0

    private let dotCount = 5
    private let dotSize: CGFloat = 4
    private let spacing: CGFloat = 8
    private let indicatorWidth: CGFloat = 64
    private let indicatorHeight: CGFloat = 40

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                let phase = CGFloat(timeline.date.timeIntervalSinceReferenceDate)

                for i in 0..<dotCount {
                    let fromPosition = dotPosition(
                        for: fromState,
                        index: i,
                        centerX: centerX,
                        centerY: centerY,
                        phase: phase
                    )
                    let toPosition = dotPosition(
                        for: toState,
                        index: i,
                        centerX: centerX,
                        centerY: centerY,
                        phase: phase
                    )
                    let position = CGPoint(
                        x: fromPosition.x + (toPosition.x - fromPosition.x) * transitionProgress,
                        y: fromPosition.y + (toPosition.y - fromPosition.y) * transitionProgress
                    )

                    let dotRect = CGRect(
                        x: position.x - dotSize / 2,
                        y: position.y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    let color = mixedColor(progress: transitionProgress)
                    context.fill(
                        Circle().path(in: dotRect),
                        with: .color(color)
                    )
                }
            }
        }
        .frame(width: indicatorWidth, height: indicatorHeight)
        .onChange(of: state) { _, newState in
            guard toState != newState else { return }
            fromState = toState
            toState = newState
            transitionProgress = 0
            withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
                transitionProgress = 1
            }
        }
        .onAppear {
            fromState = state
            toState = state
        }
    }

    // MARK: - Dot Positioning per State

    private func dotPosition(
        for state: AudioAgentState,
        index: Int,
        centerX: CGFloat,
        centerY: CGFloat,
        phase: CGFloat
    ) -> CGPoint {
        let totalWidth = CGFloat(dotCount - 1) * spacing
        let startX = centerX - totalWidth / 2
        let baseX = startX + CGFloat(index) * spacing

        switch state {
        case .idle:
            let frequency: CGFloat = 6.4
            let wavePhase = phase * frequency + CGFloat(index) * .pi * 0.55
            let amplitude: CGFloat = 1
            let yOffset = sin(wavePhase) * amplitude
            return CGPoint(x: baseX, y: centerY + yOffset)

        case .transcribing:
            let frequency: CGFloat = 6.4
            let wavePhase = phase * frequency + CGFloat(index) * .pi * 0.55
            let amplitude: CGFloat = 4
            let yOffset = sin(wavePhase) * amplitude
            return CGPoint(x: baseX, y: centerY + yOffset)

        case .processing:
            let angularSpeed: CGFloat = 2
            let baseAngle = phase * angularSpeed
            let angleForDot = baseAngle + (CGFloat(index) * (2 * .pi / CGFloat(dotCount)))
            let radius: CGFloat = 8
            let x = centerX + cos(angleForDot) * radius
            let y = centerY + sin(angleForDot) * radius
            return CGPoint(x: x, y: y)

        case .responding:
            return checkmarkPositions(centerX: centerX, centerY: centerY)[index]

        case .error:
            return frownPositions(centerX: centerX, centerY: centerY)[index]
        }
    }

    // MARK: - Shape Helpers

    /// Returns 5 points arranged as a checkmark ✓
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

    /// Returns 5 points arranged as the bottom half of a frown ⌢
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

    // MARK: - Dot Color

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

    private func mixedColor(progress: CGFloat) -> Color {
        Color.mix(
            from: dotColor(for: fromState),
            to: dotColor(for: toState),
            progress: progress
        )
    }
}

// MARK: - Main MenuBarView
struct MenuBarView: View {
    @State var viewModel = ViewModel()
    @Environment(\.scenePhase) private var scenePhase

    private let panelWidth: CGFloat = 240

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                userInputPanel

                StatusIndicatorView(state: viewModel.state)

                systemResponsePanel
            }
            .padding(.top, 8)
            .padding(.bottom, 8)

            Divider()

            // ── Quit Row ──
            Button(action: {
                Task {
                    await viewModel.handleEvent(.onQuit)
                    await MainActor.run {
                        NSApp.terminate(nil)
                    }
                }
            }) {
                Text("Quit LastTime")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
        .onAppear {
            Task {
                await viewModel.handleEvent(.onAppear)
            }
        }
        .onDisappear {
            Task {
                await viewModel.handleEvent(.onDisappear)
            }
        }
        .onChange(of: scenePhase, { oldValue, newValue in
            print("Old value: \(oldValue) & New value: \(newValue)")
        })
    }

    // MARK: - Subviews
    private var userInputPanel: some View {
        Text(viewModel.userInput?.displayContent ?? " ")
            .font(.system(.body, design: .rounded))
            .frame(width: panelWidth, alignment: .leading)
            .frame(minHeight: 64, alignment: .topLeading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private var systemResponsePanel: some View {
        Text(viewModel.systemResponse?.displayContent ?? " ")
            .font(.system(.body, design: .rounded))
            .frame(width: panelWidth, alignment: .leading)
            .frame(minHeight: 64, alignment: .topLeading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

// MARK: - Preview

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
