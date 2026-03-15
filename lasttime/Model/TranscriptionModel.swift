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
    
    private var finalizedText: String = ""
    private var currentText: String = ""
    
    init(id: UUID) {
        self.id = id
    }
    
    mutating func updateContent(with text: String, isFinal: Bool) {
        if isFinal {
            self.finalizedText += text + " "
            self.currentText = ""
        } else {
            self.currentText = text
        }
    }
    
    var displayContent: String {
        return finalizedText + currentText
    }
}
