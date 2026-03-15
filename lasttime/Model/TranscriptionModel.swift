//
//  TranscriptionModel.swift
//  lasttime
//
//  Created by Ram Janarthan on 12/3/26.
//

import Foundation

struct TranscriptionModel: InteractionContentModel {
    let id: UUID
    let type = InteractionType.user
    var isFinal: Bool
    
    private var finalizedText: String = ""
    private var currentText: String = ""
    
    init(id: UUID, isFinal: Bool) {
        self.id = id
        self.isFinal = isFinal
    }
    
    mutating func updateContent(with text: String, isFinal: Bool) {
        if isFinal {
            self.finalizedText += text + " "
            self.currentText = ""
        } else {
            self.currentText = text
        }
        
        self.isFinal = isFinal
    }
    
    var displayContent: String {
        return finalizedText + currentText
    }
}
