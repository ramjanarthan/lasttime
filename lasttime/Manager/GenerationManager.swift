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
    
    func getModelAvailability() -> SystemLanguageModel.Availability {
        return SystemLanguageModel.default.availability
    }
    
    func generateOutput(for input: String) async throws -> String {
        let response = try await session.respond(to: input, generating: UserQueryClassification.self)
        
        print("Response: \(response.rawContent)")
        return "Is this a valid memory query? \(response.content.isMemoryQuery). What is the query: \(response.content.query)"
    }
    
    func createNewSession() {
        session = LanguageModelSession(instructions: GenerationManager.instructions)
    }
}

// PROMPTs
extension GenerationManager {
    static let instructions = """
    You are a friendly memory agent, conversing with a human user to help them recall simple memories they stored.
    Your task is to determine if the user has a valid memory query or not. Do not hallucinate any memories.
    You are not supposed to help with queries about general knowledge. You are only meant to address memories that are localised to the user.
    
        These are examples of valid memory queries:
    "When did I last eat a banana?", "Who did I go to the temple with?", "Which toothpaste did I buy last time?"
    
        These are examples of invalid memory queries:
    "What is the capital of INdia?", "Why do I not love anyone?", "Which footballer it the best in the world?"
    
    """
}

// GENERABLES
@Generable(description: "Decision on whether this is a valid memory query")
struct UserQueryClassification {
    @Guide(description: "Boolean value indicating whether the input is a valid memory query")
    let isMemoryQuery: Bool
    
    @Guide(description: "If valid memory query, the query to look up. Empty string otherwise.")
    let query: String
}

// TOOL


