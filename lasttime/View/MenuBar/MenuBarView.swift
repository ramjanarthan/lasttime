//
//  MenuBarView.swift
//  lasttime
//
//  Created by Ram Janarthan on 14/4/26.
//

import SwiftUI

struct MenuBarView: View {
    private let panelWidth: CGFloat = 240
    
    @StateObject private var viewModel: ViewModel

    init(container: AppContainer) {
        _viewModel = StateObject(
            wrappedValue: ViewModel(
                audioManager: container.audioManager,
                transcriptionManager: container.transcriptionManager,
                memoryManager: container.memoryManager,
                generationManager: container.generationManager
            )
        )
    }

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

            MenuItemRow(title: "Quit LastTime", shortcut: "⌘Q") {
                Task {
                    await viewModel.handleEvent(.onQuit)
                    await MainActor.run {
                        NSApp.terminate(nil)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
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
    }

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
        Text(viewModel.systemResponse?.displayContent ?? "")
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
