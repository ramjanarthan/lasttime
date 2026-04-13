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
    private let memoryManager = MemoryManager()
    
    init() {
        session = LanguageModelSession(instructions: GenerationManager.instructions)
    }
    
    func getModelAvailability() -> SystemLanguageModel.Availability {
        return SystemLanguageModel.default.availability
    }
    
    func generateOutput(for input: String) async throws -> String {
        let response = try await session.respond(to: input, generating: UserQueryClassification.self)
        
        print("Response: \(response.rawContent)")
//        return "Is this a valid memory query? \(response.content.isMemoryQuery). What is the query: \(response.content.query)"
        
        let valid_memories = memoryManager.getRelevantMemories(for: response.content.query)
        if let memory = valid_memories.first {
            print("The relevant memory is: \(memory)")
            
            let prompt = Prompt {
                "Your task is to generate a response to the question: \(response.content.query). The relevant memory is: \(memory)"
            }
                
            let response = try await session.respond(to: prompt)
            return response.content
        } else {
            return "I couldn't find a relevant memory for that question."
        }
    }
    
    func createNewSession() {
        session = LanguageModelSession(instructions: GenerationManager.instructions)
    }
}

// PROMPTs
extension GenerationManager {
    static let instructions = """
    Decide if this is valid personal question about the user.  
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


