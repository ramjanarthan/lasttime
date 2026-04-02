//
//  SpeechToTextViewModel.swift
//  lasttime
//
//  Created by Ram Janarthan on 11/3/26.
//

import Foundation
import Speech
import AVFoundation

extension AudioAgentInteractionView {

    @MainActor
    @Observable
    class ViewModel {
        private(set) var state: AudioAgentState = .idle {
            didSet {
                handleStateChange(oldValue: oldValue, newValue: state)
            }
        }

        private var lastInteractionContent: (any InteractionContentModel)?
        private var _interactionContent: [any InteractionContentModel] = []
        
        var interactionContent: [any InteractionContentModel] {
            if let lastInteractionContent = lastInteractionContent {
                return _interactionContent + [lastInteractionContent]
            }
            return _interactionContent
        }
        
        private let audioManager = AudioManager()
        private let transcriptionManager = TranscriptionManager()
//        private let generationManager = GenerationManager()
        
        private var transcriptionObservationTask: Task<(), Error>?
        
        init() {
            do {
                try audioManager.setUpAudioSession()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
        
        private func requestPermission() async -> Bool {
            let micPermission = await audioManager.requestMicPermission()
            let speechPermission = await transcriptionManager.requestSpeechPermission()
            return micPermission && speechPermission
        }
        
        private func handleStateChange(oldValue: AudioAgentState, newValue: AudioAgentState) {
//            switch (oldValue, newValue) {
//            case (.idle, .transcribing):
//                break
//            case (.transcribing, .processing):
//                break
//            case (.processing, .idle):
//                break
//            default:
//                fatalError("Error in the setup")
//            }
        }
        
        func handleEvent(_ event: AudioAgentEvent) async {
            print("Handle event ---- ", event)
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
                if let lastInteractionContent {
                    self._interactionContent.append(lastInteractionContent)
                    self.lastInteractionContent = nil
                }
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
                            //                            self.state = .idle
                            break
                        case .transcribed(let result, let isFinished):
                            if self.lastInteractionContent == nil {
                                self.lastInteractionContent = TranscriptionModel(id: UUID(), isFinal: false)
                            }
                            
                            self.lastInteractionContent?.updateContent(with: result, isFinal: isFinished)
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
            
            if let content = lastInteractionContent, content.isFinal {
                _interactionContent.append(content)
                self.lastInteractionContent = nil
            }
        }
        
        private func generateResponse(for interactionContent: TranscriptionModel) async throws {
//            state = .processing
//            
//            let response = try await generationManager.generateOutput(for: interactionContent.displayContent)
//            
//            var content = GenerationModel(id: UUID(), isFinal: true)
//            content.updateContent(with: response, isFinal: true)
//            _interactionContent.append(content)
//            
//            state = .idle
        }
    }
}
