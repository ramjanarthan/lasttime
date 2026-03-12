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
    
    private(set) var model = TranscriptionModel()
    private(set) var errorMessage: String?
    private let audioManager = AudioManager()
    private let transcriptionManager = TranscriptionManager()
    
    private func requestPermission() async -> Bool {
        let micPermission = await audioManager.requestMicPermission()
        let speechPermission = await transcriptionManager.requestSpeechPermission()
        return micPermission && speechPermission
    }
    
    func toggleRecording() {
        if model.isRecording {
            Task { await stopRecording() }
        } else {
            Task { await startRecording() }
        }
    }
    
    func clearTranscript() {
        model.finalizedText = ""
        model.currentText = ""
        errorMessage = nil
    }
    
    func startRecording() async {
        guard await requestPermission() else {
            errorMessage = "Permission denied"
            return
        }
        
        do {
            try audioManager.setUpAudioSession()
            
            try await transcriptionManager.startTranscription { [weak self] text, isFinal in
                Task { @MainActor in
                    guard let self else { return }
                    
                    if isFinal {
                        self.model.finalizedText += text + " "
                        self.model.currentText = ""
                    } else {
                        self.model.currentText = text
                    }
                }
            }
            
            try audioManager.startAudioStream { [weak self] buffer in
                try? self?.transcriptionManager.processAudioBuffer(buffer)
            }
            
            model.isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopRecording() async {
        audioManager.stopAudioStream()
        await transcriptionManager.stopTranscription()
        model.isRecording = false
    }
}
