//
//  AudioAgentState.swift
//  lasttime
//
//  Created by Ram Janarthan on 13/3/26.
//

import Foundation

enum AudioAgentState: Equatable {
    case error(String)
    case idle
    case transcribing
//    case processing
//    case responding
}

enum AudioAgentEvent: Equatable {
    case onError(String)
    case onAppear
    case onDisappear
    case transcribing
    case onFinishedTranscribing
//    case onFinishedProcessing
}
