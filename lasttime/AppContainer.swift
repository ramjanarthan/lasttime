//
//  AppContainer.swift
//  lasttime
//
//  Created by Ram Janarthan on 20/4/26.
//

import Foundation
import SwiftUI

class AppContainer: ObservableObject {
    let audioManager = AudioManager()
    let transcriptionManager = TranscriptionManager()
    let memoryManager = MemoryManager()
    let generationManager: GenerationManager
    
    init() {
        generationManager = GenerationManager(memoryManager: memoryManager)
    }
}
