//
//  TranscriptionModel.swift
//  lasttime
//
//  Created by Ram Janarthan on 12/3/26.
//

import Foundation

struct TranscriptionModel {
    var finalizedText: String = ""
    var currentText: String = ""
    var numEmptyBuffers: Int = 0
    var numNonEmptyBuffers: Int = 0
    var isRecording: Bool = false
    
    var displayText: String {
        return finalizedText + currentText
    }
    
    var totalBuffers: Int {
        return numEmptyBuffers + numNonEmptyBuffers
    }
}
