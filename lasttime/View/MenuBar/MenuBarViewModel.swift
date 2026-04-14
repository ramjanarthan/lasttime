//
//  MenuBarViewModel.swift
//  lasttime
//
//  Created by Ram Janarthan on 14/4/26.
//

import Foundation
import Speech
import AVFoundation

extension MenuBarView {
    @MainActor
    @Observable
    class ViewModel {
        private(set) var state: AudioAgentState = .idle
        
        private var shouldWipeUserInput: Bool = true
        private(set) var userInput: TranscriptionModel?
        private(set) var systemResponse: GenerationModel?
        
        private let audioManager = AudioManager()
        private let transcriptionManager = TranscriptionManager()
        private let memoryManager = MemoryManager()
        private let generationManager: GenerationManager

        private var transcriptionObservationTask: Task<(), Error>?
        
        private func requestPermission() async -> Bool {
            let micPermission = await audioManager.requestMicPermission()
            let speechPermission = await transcriptionManager.requestSpeechPermission()
            return micPermission && speechPermission
        }
        
        init() {
            self.generationManager = GenerationManager(memoryManager: memoryManager)

            switch generationManager.getModelAvailability() {
            case .unavailable(let reason):
                switch reason {
                case .appleIntelligenceNotEnabled:
                    self.state = .error("Sorry, this device does not have apple intelligence enabled")
                case .deviceNotEligible:
                    self.state = .error("Sorry, this device is not eligible for apple intelligence")
                case .modelNotReady:
                    self.state = .error("Sorry, the model is not ready yet")
                default:
                    self.state = .idle
                }
            case .available:
                break
            }
        }
        
        func handleEvent(_ event: AudioAgentEvent) async {
            switch (state, event) {
            case (_, .onAppear):
                await startRecording()
                await startTranscribing()
            case (_, .onDisappear):
                await stopTranscribing()
                await stopRecording()
            case (_, .transcribing):
                self.state = .transcribing
            case (_, .onFinishedTranscribing):
                if let userInput {
                    self.state = .processing
                    await generateResponse(for: userInput)
                } else {
                    self.state = .idle
                }
            case (_, .onFinishedProcessing):
                self.state = .idle
            case (_, .onError(let errorMessage)):
                self.state = .error(errorMessage)
            }
            
        }

        func startRecording() async {
            guard await requestPermission() else {
                await self.handleEvent(.onError("Please grant mic and speech analysis access in settings"))
                return
            }
            
            guard !audioManager.isAudioStreamRunning else {
                return
            }
            
            do {
                try audioManager.startAudioStream()
            } catch {
                await handleEvent(.onError(error.localizedDescription))
            }
        }
        
        func startTranscribing() async {
            do {
                try await transcriptionManager.setup()
                let transcriptionUpdateStream = try await transcriptionManager.startTranscription(audioBufferStream: audioManager.audioBufferStream)
                transcriptionObservationTask = Task { @MainActor in
                    for try await event in transcriptionUpdateStream {
                        print("Event -- ", event)
                        switch event {
                        case .filtered:
                            // self.state = .idle
                            break
                        case .transcribed(let result, let isFinished):
                            if self.userInput == nil || self.shouldWipeUserInput {
                                self.userInput = TranscriptionModel(id: UUID(), isFinal: false)
                                self.shouldWipeUserInput = false
                            }
                            
                            self.userInput?.updateContent(with: result, isFinal: isFinished)
                            if isFinished {
                                await self.handleEvent(.onFinishedTranscribing)
                            } else {
                                await self.handleEvent(.transcribing)
                            }
                        }
                    }
                    
                }
            } catch {
                await handleEvent(.onError(error.localizedDescription))
            }
        }
        
        func stopTranscribing() async {
            if let task = transcriptionObservationTask {
                task.cancel()
                transcriptionObservationTask = nil
            }
        }
        
        func stopRecording() async {
            audioManager.stopAudioStream()
            await transcriptionManager.stopTranscription()
        }
        
        private func generateResponse(for interactionContent: TranscriptionModel) async {
            do {
                let response = try await generationManager.generateOutput(for: interactionContent.displayContent)
                
                await handleEvent(.onFinishedProcessing)
                
                var content = GenerationModel(id: UUID(), isFinal: true)
                content.updateContent(with: response, isFinal: true)
                systemResponse = content
                shouldWipeUserInput = true
            } catch {
                await handleEvent(.onError(error.localizedDescription))
            }
        }
    }
}
