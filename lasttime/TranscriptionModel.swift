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
    var isRecording: Bool = false
    
    var displayText: String {
        return finalizedText + currentText
    }
}
