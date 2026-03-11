//
//  ContentView.swift
//  lasttime
//
//  Created by Ram Janarthan on 9/3/26.
//

import SwiftUI

struct ContentView: View {
    @State var isRecording = false
    @State var transcription = ""
  
    var body: some View {
        VStack {
            Circle()
                .fill(isRecording ? Color.red : Color.gray)
                .frame(width: 30, height: 100)
            
            
            Button(isRecording ? "Stop" : "Record", systemImage: "mic") {
                withAnimation {
                    isRecording.toggle()
                }
            }
            
            Text(transcription)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
