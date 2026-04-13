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
        session = LanguageModelSession(instructions: GenerationManager.classificationInstructions)
        session.prewarm()
    }
    
    func getModelAvailability() -> SystemLanguageModel.Availability {
        return SystemLanguageModel.default.availability
    }
    
    func classifiyInput(for input: String) async -> UserQueryClassification {
        do {
            let response = try await session.respond(to: input, generating: UserQueryClassification.self)
            return response.content
        } catch {
            return .invalid
        }
    }
    
    func generateOutput(for input: String) async throws -> String {
        let response = await classifiyInput(for: input)
        
        print("Response: \(response)")
        
        switch response {
        case .memory(let memory):
            return "I'm saving this as a memory -- \(memory)"
        case .query(let query):
            let valid_memories = memoryManager.getRelevantMemories(for: query)
            if let memory = valid_memories.first {
                print("The relevant memory is: \(memory)")
                
                let prompt = Prompt {
                    "Your task is to generate a response to the question: \(query). The relevant memory is: \(memory)"
                }
                
                let response = try await session.respond(to: prompt)
                return response.content
            } else {
                return "I couldn't find a relevant memory for that question."
            }
        case .invalid:
            return "This isn't a valid input type for me"
        }
    }
}

// PROMPTs
extension GenerationManager {
    static let classificationInstructions: String = """
    Decide if this is valid personal question about the user.  
    """
}

// GENERABLES
@Generable(description: "Classification of user input as a memory, a personal query, or anything else")
enum UserQueryClassification: Equatable {
    case memory(String)
    case query(String)
    case invalid
}

// TOOL


