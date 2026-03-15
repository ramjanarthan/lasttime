//
//  AudioFilter.swift
//  lasttime
//
//  Created by Ram Janarthan on 13/3/26.
//

import Foundation
import AVFoundation
import Accelerate

class AudioFilter {
    private var silenceCounter = 0
    private let silenceLimit = 15 // Number of quiet buffers to allow before stopping
    private let rmsThreshold: Float = 0.03

    func filter(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let floatData = buffer.floatChannelData else {
            return nil
        }

        let samples = UnsafeBufferPointer(start: floatData[0], count: Int(buffer.frameLength))
        let energy = vDSP.rootMeanSquare(samples)
        print("Energy ", energy)

        if energy > rmsThreshold {
            silenceCounter = silenceLimit
        } else {
            if silenceCounter > 0 {
                silenceCounter -= 1
            }
        }

        if silenceCounter <= 0 {
            return nil
        }
        
        return buffer
    }
}
