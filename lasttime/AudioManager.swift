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
    var audioTapInstalled = false
    
    func setUpAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    func requestMicPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission() { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func startAudioStream(onBuffer: @escaping (AVAudioPCMBuffer) -> Void) throws {
        guard !audioTapInstalled else { return }
        
        audioEngine.inputNode.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: audioEngine.inputNode.outputFormat(forBus: 0)
        ) { buffer, _ in
                onBuffer(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        audioTapInstalled = true
    }
    
    func stopAudioStream() {
        guard audioTapInstalled else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioTapInstalled = false
    }
}
