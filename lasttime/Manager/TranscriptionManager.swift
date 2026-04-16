//
//  TranscriptionManager.swift
//  lasttime
//
//  Created by Ram Janarthan on 12/3/26.
//

import Foundation
import Speech
import Accelerate

class TranscriptionManager {
    enum TranscriptionError: Error {
        case transcriptionCreationError
        case processingError
    }
    
    enum TranscriptionUpdate {
        case filtered
        case transcribed(result: String, isFinished: Bool)
    }
    
    private var analyzerInputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var transcriptionOutputBuidler: AsyncStream<TranscriptionUpdate>.Continuation?
    
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var analyzerFormat: AVAudioFormat?
    private let filter = AudioFilter()
    private var converter = BufferConverter()

    private var recogniserTask: Task<(), Error>?
    private var audioProcessingTask: Task<(), Error>?
    private var analyzerTask: Task<(), Error>?
    
    private var isSetup: Bool = false
    private(set) var isTranscribing: Bool = false
    
    func requestSpeechPermission() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            return SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        return status == .authorized
    }
    
    func checkIfDeviceSupported() async -> Bool {
        return SpeechTranscriber.isAvailable
    }
    
    func setup() async throws {
        guard !isSetup else {
            return
        }
        
        
        transcriber = SpeechTranscriber(
            locale: Locale.current,
            preset: .progressiveTranscription
        )

        guard let transcriber else {
            throw TranscriptionError.transcriptionCreationError
        }
        
        analyzer = SpeechAnalyzer(modules: [transcriber])
        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        try await analyzer?.prepareToAnalyze(in: analyzerFormat)
        
        guard analyzerFormat != nil else {
            throw TranscriptionError.processingError
        }
        
        isSetup = true
    }
    
    func startTranscription(audioBufferStream: AsyncStream<AVAudioPCMBuffer>) async throws -> AsyncStream<TranscriptionUpdate>  {
        guard let transcriber else {
            throw TranscriptionError.transcriptionCreationError
        }
        
        isTranscribing = true
        
        let (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
        self.analyzerInputBuilder = inputBuilder
        
        let (transcriptionUpdateSequence, transcriptionOutputBuilder) = AsyncStream<TranscriptionUpdate>.makeStream()
        self.transcriptionOutputBuidler = transcriptionOutputBuilder
        
        recogniserTask = Task {
            for try await result in transcriber.results {
                let text = String(result.text.characters)
                transcriptionOutputBuidler?.yield(.transcribed(result: text, isFinished: result.isFinal))
            }
        }
        
        audioProcessingTask = Task {
            for await buffer in audioBufferStream {
                try processAudioBuffer(buffer)
            }
        }
        
        analyzerTask = Task {
            try await analyzer?.start(inputSequence: inputSequence)
        }
        
        print("Starting transcription")
        return transcriptionUpdateSequence
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) throws {
        guard let transcriptionOutputBuidler, let analyzerInputBuilder, let analyzerFormat else {
            throw TranscriptionError.processingError
        }
        
        guard let buffer = filter.filter(buffer) else {
            transcriptionOutputBuidler.yield(.filtered)
            return
        }
       
        let converted = try converter.convertBuffer(buffer, to: analyzerFormat)
        analyzerInputBuilder.yield(AnalyzerInput(buffer: converted))
    }
    
    func stopTranscription() async {
        analyzerInputBuilder?.finish()
        transcriptionOutputBuidler?.finish()

        recogniserTask?.cancel()
        audioProcessingTask?.cancel()
        analyzerTask?.cancel()

        recogniserTask = nil
        audioProcessingTask = nil
        analyzerTask = nil

        analyzerInputBuilder = nil
        transcriptionOutputBuidler = nil
        analyzerFormat = nil
        analyzer = nil
        transcriber = nil
        converter = BufferConverter()
        isSetup = false
        isTranscribing = false
    }
}
