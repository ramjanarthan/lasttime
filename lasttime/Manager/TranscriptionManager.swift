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
    
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var recogniserTask: Task<(), Error>?
    private var analyserFormat: AVAudioFormat?
    private let filter = AudioFilter()
    private var converter = BufferConverter()
    
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
    
    func startTranscription(onResult: @escaping (String, Bool) -> Void) async throws {
        transcriber = SpeechTranscriber(
            locale: Locale.current,
            preset: .progressiveTranscription
        )
        
        guard let transcriber else {
            throw TranscriptionError.transcriptionCreationError
        }
        
        analyzer = SpeechAnalyzer(modules: [transcriber])
        analyserFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        
        guard let analyserFormat else {
            throw TranscriptionError.processingError
        }
        
        try await analyzer?.prepareToAnalyze(in: analyserFormat)
        
        let (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
        self.inputBuilder = inputBuilder
        
        recogniserTask = Task {
            for try await result in transcriber.results {
                let text = String(result.text.characters)
                onResult(text, result.isFinal)
                print("\(Date.now) -- ", text, " -- " ,result.isFinal)
            }
        }
        
        try await analyzer?.start(inputSequence: inputSequence)
    }
    
    func filter(_ buffer: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer? {
        return filter.filter(buffer)
    }
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) throws {
        guard let inputBuilder, let analyserFormat else {
            throw TranscriptionError.processingError
        }
       
        let converted = try converter.convertBuffer(buffer, to: analyserFormat)
        inputBuilder.yield(AnalyzerInput(buffer: converted))
    }
    
    func stopTranscription() async {
        inputBuilder?.finish()
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()
        recogniserTask?.cancel()
        recogniserTask = nil
    }
}
