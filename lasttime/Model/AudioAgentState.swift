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
    case listening
    case processing
    case responding
}
