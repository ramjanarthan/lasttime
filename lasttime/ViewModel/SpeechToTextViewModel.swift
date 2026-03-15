//
//  SpeechToTextViewModel.swift
//  lasttime
//
//  Created by Ram Janarthan on 11/3/26.
//

import Foundation
import Speech
import AVFoundation

@MainActor
@Observable
class SpeechToTextViewModel {
    
    private(set) var isRecording = false
    private var lastInteractionContent: (any InteractionContentModel)?
    private var _interactionContent: [any InteractionContentModel] = []

    var interactionContent: [any InteractionContentModel] {
        if let lastInteractionContent = lastInteractionContent {
            return _interactionContent + [lastInteractionContent]
        }
        return _interactionContent
    }
    
    private(set) var errorMessage: String?

    private let audioManager = AudioManager()
    private let transcriptionManager = TranscriptionManager()
    
    private func requestPermission() async -> Bool {
        let micPermission = await audioManager.requestMicPermission()
        let speechPermission = await transcriptionManager.requestSpeechPermission()
        return micPermission && speechPermission
    }
    
    func toggleRecording() {
        if isRecording {
            Task { await stopRecording() }
        } else {
            Task { await startRecording() }
        }
    }
    
    func startRecording() async {
        guard await requestPermission() else {
            errorMessage = "Permission denied"
            return
        }
        
        do {
            try audioManager.setUpAudioSession()
            
            let userContent = TranscriptionModel(id: UUID())
            lastInteractionContent = userContent
            
            try await transcriptionManager.startTranscription { [weak self] text, isFinal in
                Task { @MainActor in
                    guard let self else { return }
                    
                    self.lastInteractionContent?.updateContent(with: text, isFinal: isFinal)
                }
            }
            
            try audioManager.startAudioStream { [weak self] buffer in
                try? self?.transcriptionManager.processAudioBuffer(buffer)
            }
            
            isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopRecording() async {
        audioManager.stopAudioStream()
        await transcriptionManager.stopTranscription()
        isRecording = false
        
        if let content = lastInteractionContent {
            _interactionContent.append(content)
            self.lastInteractionContent = nil
        }
    }
}
