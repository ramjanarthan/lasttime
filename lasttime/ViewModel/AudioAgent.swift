//
//  AudioAgent.swift
//  lasttime
//
//  Created by Ram Janarthan on 13/3/26.
//

import Foundation
import Speech
import AVFoundation

@MainActor
@Observable
class AudioAgent {
    private(set) var state = AudioAgentState.idle
    private let audioManager = AudioManager()
    private let transcriptionManager = TranscriptionManager()
    
    private func requestPermission() async -> Bool {
        let micPermission = await audioManager.requestMicPermission()
        let speechPermission = await transcriptionManager.requestSpeechPermission()
        return micPermission && speechPermission
    }

    func startListening() async {
        guard await requestPermission() else {
            state = .error("Permission denied")
            return
        }
        
        do {
            try audioManager.setUpAudioSession()
            
            try await transcriptionManager.startTranscription { [weak self] text, isFinal in
                Task { @MainActor in
                    guard let self else { return }
                    
                }
            }
            
            try audioManager.startAudioStream { [weak self] buffer in
                try? self?.transcriptionManager.processAudioBuffer(buffer)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func stopListening() async {
        audioManager.stopAudioStream()
        await transcriptionManager.stopTranscription()
    }
}
