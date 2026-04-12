//
//  GenerationManager.swift
//  lasttime
//
//  Created by Ram Janarthan on 15/3/26.
//

import Foundation
import FoundationModels

class GenerationManager {
    private var session: LanguageModelSession
    
    init() {
        session = LanguageModelSession(instructions: GenerationManager.instructions)
    }
    
    func generateOutput(for input: String) async throws -> String {
        let response = try await session.respond(to: input)
        return response.content
    }
    
    func createNewSession() {
        session = LanguageModelSession(instructions: GenerationManager.instructions)
    }
}

// PROMPTs
extension GenerationManager {
    static let instructions = " You are a friendly agent, conversing with a human user and trying to be useful."
}
