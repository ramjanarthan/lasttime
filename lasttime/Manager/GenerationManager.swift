//
//  GenerationManager.swift
//  lasttime
//
//  Created by Ram Janarthan on 15/3/26.
//

import Foundation
import FoundationModels

class GenerationManager {
    private let memoryManager: MemoryManager
    
    init(memoryManager: MemoryManager) {
        self.memoryManager = memoryManager
    }
    
    func getModelAvailability() -> SystemLanguageModel.Availability {
        return SystemLanguageModel.default.availability
    }
    
    private func classifyAsMemory(_ input: String) async throws -> FactClassification {
        let session = LanguageModelSession(model: .default)
        let prompt = Prompt {
            "Classify this sentence as a fact about the user. Questions are not facts"
            "------------"
            "\(input)."
        }
        let response = try await session.respond(to: prompt, generating: FactClassification.self)
        return response.content
    }
    
    private func classifyAsQuery(_ input: String) async throws -> QuestionClassification {
        let session = LanguageModelSession(model: .default)
        let prompt = Prompt {
            "Classify this sentence as a personal question about the user. General knowledge questions are not valid"
            "------------"
            "\(input)."
        }
        let response = try await session.respond(to: prompt, generating: QuestionClassification.self)
        
        let containsWhen = input.lowercased().contains("when")
        if containsWhen, response.content.isQuestion {
            return QuestionClassification(isQuestion: true, question: response.content.question)
        } else {
            return QuestionClassification(isQuestion: false, question: "")
        }
    }
    
    func classifiyInput(for input: String) async -> UserQueryClassification {
        do {
            let memoryClassification = try await classifyAsMemory(input)
            let whenQuestionClassification = try await classifyAsQuery(input)
            
            print("memory: \(memoryClassification), when: \(whenQuestionClassification)")

            
            if whenQuestionClassification.isQuestion {
                return .query(whenQuestionClassification.question)
            } else if memoryClassification.isFact {
                return .memory(memoryClassification.fact)
            } else {
                return .invalid
            }
//            let session = LanguageModelSession(model: .default, instructions: GenerationManager.userQueryClassifcationInstructions)
//            let response = try await session.respond(to: input, generating: UserQueryClassification.self)
//            return response.content
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
        Classify the following sentence as a question or not
    """
    
    static let memoryClassificationInstruction: String = """
        Classify this sentence as a personal user fact or not
    """
    
    static let userQueryClassifcationInstructions: String = """
        Your task is to classify the user input is a question, a personal memory, or neither 
    """
}

// GENERABLES
@Generable(description: "Classification of user input as a memory, a personal 'when' question, or neither")
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

@Generable(description: "Classification as a question or not")
struct QuestionClassification {
//    @Guide(description: "Boolean for whether the question is a 'when' question")
    let isQuestion: Bool
    
//    @Guide(description: "Question itself, or empty string")
    let question: String
}

@Generable(description: "Classification as a personal user fact or not")
struct FactClassification {
    
//    @Guide(description: "Boolean for whether the memory is to be remembered")
    let isFact: Bool
    
//    @Guide(description: "Memory itself, or empty string")
    let fact: String
}

// TOOL
