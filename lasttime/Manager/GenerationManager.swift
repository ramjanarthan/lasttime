//
//  GenerationManager.swift
//  lasttime
//
//  Created by Ram Janarthan on 15/3/26.
//

import Foundation
import FoundationModels

class GenerationManager {
    private let memoryManager = MemoryManager()
    
    func getModelAvailability() -> SystemLanguageModel.Availability {
        return SystemLanguageModel.default.availability
    }
    
    private func classifyAsMemory(_ input: String) async throws -> MemoryToRememberClassification {
        let session = LanguageModelSession(model: .default, instructions: GenerationManager.memoryClassificationInstruction)
        let response = try await session.respond(to: input, generating: MemoryToRememberClassification.self)
        return response.content
    }
    
    private func classifyAsQuery(_ input: String) async throws -> WhenQuestionClassification {
        let session = LanguageModelSession(model: .default, instructions: GenerationManager.whenQuestionClassificationInstruction)
        let response = try await session.respond(to: input, generating: WhenQuestionClassification.self)
        return response.content
    }
    
    func classifiyInput(for input: String) async -> UserQueryClassification {
        do {
            let memoryClassification = try await classifyAsMemory(input)
            let whenQuestionClassification = try await classifyAsQuery(input)
            
            if memoryClassification.shouldRemember, whenQuestionClassification.isWhenQuestion {
                return .invalid
            } else if memoryClassification.shouldRemember {
                return .memory(memoryClassification.memory)
            } else if whenQuestionClassification.isWhenQuestion {
                return .query(whenQuestionClassification.question)
            } else {
                return .invalid
            } 
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
                
                let session = LanguageModelSession(model: .default)
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
    static let whenQuestionClassificationInstruction: String = """
    Classify this sentence as a when question or not
    """
    
    static let memoryClassificationInstruction: String = """
        Classify this sentence as a valid personal memory or not
    """
    
}

// GENERABLES
@Generable(description: "Classification of user input as a memory, a personal query, or invalid")
enum UserQueryClassification {
    case memory(String)
    case query(String)
    case invalid
    
    func isComparable(to other: UserQueryClassification) -> Bool {
        switch (self, other) {
        case (.memory(let _), .memory(let _)):
            return true
        case (.query, .query):
            return true
        case (.invalid, .invalid):
            return true
        default:
            return false
        }
    }
}

@Generable(description: "Classification as a 'when' question or not")
struct WhenQuestionClassification {
    
//    @Guide(description: "Boolean for whether the question is a 'when' question")
    let isWhenQuestion: Bool
    
//    @Guide(description: "Question itself, or empty string")
    let question: String
}

@Generable(description: "Classification as a personal memory to remember")
struct MemoryToRememberClassification {
    
//    @Guide(description: "Boolean for whether the memory is to be remembered")
    let shouldRemember: Bool
    
//    @Guide(description: "Memory itself, or empty string")
    let memory: String
}

// TOOL
