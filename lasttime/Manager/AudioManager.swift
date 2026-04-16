//
//  SpeechManager.swift
//  lasttime
//
//  Created by Ram Janarthan on 11/3/26.
//

import Foundation
import AVFoundation

class AudioManager {
    let audioEngine = AVAudioEngine()
    
    let audioBufferStream: AsyncStream<AVAudioPCMBuffer>
    private let audioBufferStreamBuilder: AsyncStream<AVAudioPCMBuffer>.Continuation
    
    init() {
        (audioBufferStream, audioBufferStreamBuilder) = AsyncStream<AVAudioPCMBuffer>.makeStream()
    }
    
    private var audioTapInstalled = false
    var isAudioStreamRunning: Bool { audioTapInstalled }

    func requestMicPermission() async -> Bool {
        return await AVAudioApplication.requestRecordPermission()
    }
    
    func setupAudioStream() {
        guard !audioTapInstalled else { return }
        
        audioEngine.inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: audioEngine.inputNode.outputFormat(forBus: 0)
        ) { [weak self] buffer, _ in
            self?.audioBufferStreamBuilder.yield(buffer)
        }
        
        audioEngine.prepare()
        audioTapInstalled = true
    }
    
    
    func startAudioStream() throws {
        try audioEngine.start()
        print("Starting audio stream")
    }
    
    func pauseAudioStream() {
        audioEngine.pause()
    }
    
    func stopAudioStream() {
        guard audioTapInstalled else { return }
        print("Stopping audio stream")
        
        self.audioBufferStreamBuilder.finish()
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioTapInstalled = false
    }
}
