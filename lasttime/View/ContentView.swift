//
//  ContentView.swift
//  lasttime
//
//  Created by Ram Janarthan on 9/3/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = SpeechToTextViewModel()
    
    var body: some View {
        VStack {
            Circle()
                .fill(viewModel.isRecording ? Color.red : Color.gray)
                .frame(width: 30, height: 100)
            
            
            Button(viewModel.isRecording ? "Stop" : "Record", systemImage: "mic") {
                withAnimation {
                    viewModel.toggleRecording()
                }
            }
            
            if viewModel.interactionContent.isEmpty {
                Text("Tap the mic to start recording..")
                    .font(.body)
                    .padding()
            }
          
            InteractionView(viewModel: viewModel)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
