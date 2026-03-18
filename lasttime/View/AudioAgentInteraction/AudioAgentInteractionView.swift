//
//  AudioAgentInteractionView.swift
//  lasttime
//
//  Created by Ram Janarthan on 9/3/26.
//

import SwiftUI

struct AudioAgentInteractionView: View {
    @State private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            switch viewModel.state {
            case .error(let errorMessage):
                Text(errorMessage)
                    .foregroundColor(.red)
            case .idle:
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 30, height: 100)
            case .transcribing:
                Circle()
                    .fill(Color.green)
                    .frame(width: 30, height: 100)
            case .processing:
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 100)
            case .responding:
                Circle()
                    .fill(Color.pink)
                    .frame(width: 30, height: 100)
            }
            
            if viewModel.interactionContent.isEmpty {
                Text("Say something to get started..")
                    .font(.body)
                    .padding()
            }
          
            ChatView(viewModel: viewModel)
        }
        .padding()
        .onAppear {
            Task {
                await viewModel.startRecording()
            }
        }
        .onDisappear {
            Task {
                await viewModel.stopRecording()
            }
        }
    }
}

#Preview {
    AudioAgentInteractionView()
}
