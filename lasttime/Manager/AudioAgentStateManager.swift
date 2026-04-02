//
//  AudioAgentStateManager.swift
//  lasttime
//
//  Created by Ram Janarthan on 18/3/26.
//

import Foundation
import SwiftUI

protocol AudioAgentStateManager {
    var state: AudioAgentState { get }
    
    func updateState(_ newState: AudioAgentState)
}

@MainActor
@Observable
class AudioAgentStateManagerImp: @MainActor AudioAgentStateManager {
    private(set) var state: AudioAgentState = .idle
    
    let transcriptionManager: TranscriptionManager
    let generationManager: GenerationManager
    
    init (transcriptionManager: TranscriptionManager, generationManager: GenerationManager) {
        self.transcriptionManager = transcriptionManager
        self.generationManager = generationManager
    }

    func updateState(_ newState: AudioAgentState) {
        
    }
}
