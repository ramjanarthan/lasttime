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
    final class ViewModel: ObservableObject {
        @Published private(set) var state: AudioAgentState = .idle

        private var shouldWipeUserInput: Bool = true
        private var audioPermissionGranted: Bool = false

        @Published private(set) var userInput: TranscriptionModel?
        @Published private(set) var systemResponse: GenerationModel?

        private let audioManager: AudioManager
        private let transcriptionManager: TranscriptionManager
        private let memoryManager: MemoryManager
        private let generationManager: GenerationManager

        private var transcriptionObservationTask: Task<(), Error>?

        private func requestPermission() async -> Bool {
            let micPermission = await audioManager.requestMicPermission()
            let speechPermission = await transcriptionManager.requestSpeechPermission()
            return micPermission && speechPermission
        }

        init(
            audioManager: AudioManager,
            transcriptionManager: TranscriptionManager,
            memoryManager: MemoryManager,
            generationManager: GenerationManager
        ) {
            self.audioManager = audioManager
            self.transcriptionManager = transcriptionManager
            self.memoryManager = memoryManager
            self.generationManager = generationManager

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
                if !audioManager.isAudioStreamRunning {
                    await setupAudioRecording()
                    await startRecording()
                    await setupTranscription()
                } else {
                    await startRecording()
                }

            case (_, .onDisappear):
                pauseRecording()
                memoryManager.writeToFile()

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
                LLogger.shared.error("\(errorMessage)")

            case (_, .onQuit):
                stopRecording()
                await stopTranscribing()
                self.state = .idle
            }
        }

        private func setupAudioRecording() async {
            if !audioPermissionGranted {
                guard await requestPermission() else {
                    await self.handleEvent(.onError("Please grant mic and speech analysis access in settings"))
                    return
                }
            }
            
            audioPermissionGranted = true
            guard !audioManager.isAudioStreamRunning else {
                return
            }
            
            audioManager.setupAudioStream()
        }
        
        func startRecording() async {
            do {
                try audioManager.startAudioStream()
            } catch {
                await handleEvent(.onError(error.localizedDescription))
            }
        }
        
        func setupTranscription() async {
            do {
                guard !transcriptionManager.isTranscribing else {
                    return
                }
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

        private func stopTranscribing() async {
            if let task = transcriptionObservationTask {
                task.cancel()
                transcriptionObservationTask = nil
            }
            await transcriptionManager.stopTranscription()
        }

        private func pauseRecording() {
            audioManager.pauseAudioStream()
        }

        private func stopRecording() {
            audioManager.stopAudioStream()
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
