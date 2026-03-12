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
                .fill(viewModel.model.isRecording ? Color.red : Color.gray)
                .frame(width: 30, height: 100)
            
            
            Button(viewModel.model.isRecording ? "Stop" : "Record", systemImage: "mic") {
                withAnimation {
                    viewModel.toggleRecording()
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !viewModel.model.displayText.isEmpty {
                        Text(viewModel.model.displayText)
                            .font(.body)
                            .padding()
                    } else {
                        Text("Tap the mic to start recording..")
                            .font(.body)
                            .padding()
                    }
                }
            }
            
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
