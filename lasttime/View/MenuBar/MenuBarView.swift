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

    // Animation timer — drives continuous animations
    @State private var animationPhase: CGFloat = 0
    // Track previous state for transitions
    @State private var displayedState: AudioAgentState = .idle

    private let dotCount = 5
    private let dotSize: CGFloat = 6
    private let spacing: CGFloat = 10
    private let animationArea: CGFloat = 20 // vertical space for dot movement

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                let totalWidth = CGFloat(dotCount - 1) * spacing
                let startX = centerX - totalWidth / 2

                let date = timeline.date.timeIntervalSinceReferenceDate
                let phase = date.truncatingRemainder(dividingBy: 1000)

                for i in 0..<dotCount {
                    let t = CGFloat(i) / CGFloat(dotCount - 1)
                    let position = dotPosition(
                        index: i,
                        t: t,
                        startX: startX,
                        centerX: centerX,
                        centerY: centerY,
                        phase: phase
                    )

                    let dotRect = CGRect(
                        x: position.x - dotSize / 2,
                        y: position.y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    let color = dotColor(for: displayedState)
                    context.fill(
                        Circle().path(in: dotRect),
                        with: .color(color)
                    )
                }
            }
        }
        .frame(height: 40)
        .onChange(of: state) { _, newState in
            withAnimation(.easeInOut(duration: 0.4)) {
                displayedState = newState
            }
        }
        .onAppear {
            displayedState = state
        }
    }

    // MARK: - Dot Positioning per State

    private func dotPosition(
        index: Int,
        t: CGFloat, // normalised 0...1 across dots
        startX: CGFloat,
        centerX: CGFloat,
        centerY: CGFloat,
        phase: CGFloat
    ) -> CGPoint {
        let baseX = startX + CGFloat(index) * spacing

        switch displayedState {
        case .idle:
            return CGPoint(x: baseX, y: centerY)

        case .transcribing:
            // Waveform — each dot oscillates vertically with a phase offset
            let frequency: CGFloat = 3.0
            let wavePhase = phase * frequency + CGFloat(index) * .pi * 0.5
            let amplitude: CGFloat = animationArea * 0.4
            let yOffset = sin(wavePhase) * amplitude
            return CGPoint(x: baseX, y: centerY + yOffset)

        case .processing:
            // Circular spinner — dots orbit around the centre
            let angularSpeed: CGFloat = 2.0
            let baseAngle = phase * angularSpeed
            let angleForDot = baseAngle + (CGFloat(index) * (2 * .pi / CGFloat(dotCount)))
            let radius: CGFloat = 10
            let x = centerX + cos(angleForDot) * radius
            let y = centerY + sin(angleForDot) * radius
            return CGPoint(x: x, y: y)

        case .responding:
            // Checkmark — dots arranged as a ✓ shape
            let checkmarkPoints = checkmarkPositions(
                centerX: centerX,
                centerY: centerY
            )
            return checkmarkPoints[index]

        case .error:
            // Frown — bottom half of a circle (upside-down semicircle)
            let frownPoints = frownPositions(
                centerX: centerX,
                centerY: centerY
            )
            return frownPoints[index]
        }
    }

    // MARK: - Shape Helpers

    /// Returns 5 points arranged as a checkmark ✓
    private func checkmarkPositions(centerX: CGFloat, centerY: CGFloat) -> [CGPoint] {
        // Checkmark goes: top-left → dip down → rise to top-right
        let scale: CGFloat = 1.0
        // The tick: descend to a bottom point then ascend higher
        let points: [(CGFloat, CGFloat)] = [
            (-16, -2),   // start upper-left
            (-8, 2),    // descend slightly
            (-2, 8),    // bottom of checkmark
            (8, -4),    // ascend right
            (16, -10),  // top of checkmark right
        ]
        return points.map { dx, dy in
            CGPoint(x: centerX + dx * scale, y: centerY + dy * scale)
        }
    }

    /// Returns 5 points arranged as the bottom half of a frown ⌢
    private func frownPositions(centerX: CGFloat, centerY: CGFloat) -> [CGPoint] {
        // Upside-down semicircle (sad mouth) — arc opening downward
        let radius: CGFloat = 14
        let points: [CGFloat] = [0, 0.25, 0.5, 0.75, 1.0]
        return points.map { t in
            // Arc from π to 2π (bottom semicircle)
            let angle = .pi + t * .pi
            return CGPoint(
                x: centerX + cos(angle) * radius,
                y: centerY - 4 + sin(angle) * radius
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
}

// MARK: - Status Label

/// A small text label shown beneath the dots
private func statusLabel(for state: AudioAgentState) -> String {
    switch state {
    case .idle:
        return "Listening…"
    case .transcribing:
        return "Transcribing…"
    case .processing:
        return "Thinking…"
    case .responding:
        return "Done"
    case .error(let message):
        return message
    }
}

// MARK: - Main MenuBarView

struct MenuBarView: View {
    @State var viewModel = ViewModel()

    private let panelWidth: CGFloat = 280

    var body: some View {
        VStack(spacing: 0) {
            // ── Content Area ──
            VStack(spacing: 8) {
                // User input panel
                userInputPanel

                // Status indicator
                VStack(spacing: 2) {
                    StatusIndicatorView(state: viewModel.state)
                    Text(statusLabel(for: viewModel.state))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                // System response panel
                systemResponsePanel
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // ── Quit Row ──
            Button(action: {
                NSApp.terminate(nil)
            }) {
                Text("Quit LastTime")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.clear)
            .onHover { hovering in
                // The native menu item hover is handled by SwiftUI
            }
        }
        .frame(width: 300)
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
    }

    // MARK: - Subviews

    private var userInputPanel: some View {
        Text(viewModel.userInput?.displayContent ?? " ")
            .font(.system(.body, design: .rounded))
            .frame(width: panelWidth, alignment: .leading)
            .padding(10)
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
            .padding(10)
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

#Preview("Idle") {
    MenuBarView()
}
