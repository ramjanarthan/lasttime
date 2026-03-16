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
    private(set) var state: AudioAgentState = .idle
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
    private let generationManager = GenerationManager()
    
    private func requestPermission() async -> Bool {
        let micPermission = await audioManager.requestMicPermission()
        let speechPermission = await transcriptionManager.requestSpeechPermission()
        return micPermission && speechPermission
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

                    self.lastInteractionContent?.updateContent(with: text, isFinal: isFinal)
                }
            }
            
            try audioManager.startAudioStream { [weak self] buffer in
                if let filtered = try? self?.transcriptionManager.filter(buffer) {
                    if self?.state == .idle {
                        self?.state = .listening
                    }
                    
                    guard self?.state == .listening else {
                        return
                    }
                    
                    if self?.lastInteractionContent == nil {
                        let userContent = TranscriptionModel(id: UUID(), isFinal: false)
                        self?.lastInteractionContent = userContent
                    }
                    
                    try? self?.transcriptionManager.processAudioBuffer(filtered)
                } else {
                    if self?.state == .listening {
                        self?.state = .idle
                    }
                    
                    guard self?.state == .idle else {
                        return
                    }
                    
                    if let content = self?.lastInteractionContent, content.isFinal {
                        Task {
                            if let model = content as? TranscriptionModel {
                                do  {
                                    try await self?.generateResponse(for: model)
                                } catch {
                                    print("Error: ", error.localizedDescription)
                                }
                            }
                        }
                        
                        self?._interactionContent.append(content)
                        self?.lastInteractionContent = nil
                    }
                }
            }
            
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopRecording() async {
        audioManager.stopAudioStream()
        await transcriptionManager.stopTranscription()
        
        if let content = lastInteractionContent, content.isFinal {
            _interactionContent.append(content)
            self.lastInteractionContent = nil
        }
    }
    
    private func generateResponse(for interactionContent: TranscriptionModel) async throws {
        state = .processing
        
        let response = try await generationManager.generateOutput(for: interactionContent.displayContent)
        
        var content = GenerationModel(id: UUID(), isFinal: true)
        content.updateContent(with: response, isFinal: true)
        _interactionContent.append(content)
        
        state = .idle
    }
}
