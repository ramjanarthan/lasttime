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
    
    var audioTapInstalled = false
    
    func setUpAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    func requestMicPermission() async -> Bool {
        return await AVAudioApplication.requestRecordPermission()
    }
    
    func startAudioStream() throws {
        guard !audioTapInstalled else { return }
        
        audioEngine.inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: audioEngine.inputNode.outputFormat(forBus: 0)
        ) { [weak self] buffer, _ in
            self?.audioBufferStreamBuilder.yield(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        audioTapInstalled = true
    }
    
    func stopAudioStream() {
        guard audioTapInstalled else { return }
        
        self.audioBufferStreamBuilder.finish()
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioTapInstalled = false
    }
}
