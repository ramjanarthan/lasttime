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
        let prompt = build_prompt(prefix: GenerationManager.memoryClassificationPrompt, userInput: input)
        let response = try await session.respond(to: prompt, generating: Bool.self)
        return FactClassification(isFact: response.content, fact: input, confidence_score: 0)
    }
    
    private func classifyAsQuery(_ input: String) async throws -> QuestionClassification {
        let session = LanguageModelSession(model: .default)
        let prompt = build_prompt(prefix: GenerationManager.queryClassificationPrompt, userInput: input)
        let response = try await session.respond(to: prompt, generating: Bool.self)
        
        return QuestionClassification(isQuestion: response.content, question: input, confidence_score: 0)
        
//        let containsWhen = input.lowercased().contains("when")
//        if containsWhen, response.content.isQuestion {
//            return QuestionClassification(isQuestion: true, question: response.content.question, confidence_score: response.content.confidence_score)
//        } else {
//            return QuestionClassification(isQuestion: false, question: "", confidence_score: 0)
//        }
    }
    
    private func build_prompt(prefix: String, userInput: String) -> Prompt {
        return Prompt {
            prefix
            "Input: \"\(userInput)\""
            "Output:"
        }
    }
    
    func classifiyInput(for input: String) async -> UserQueryClassification {
        do {
            async let memoryClassification = classifyAsMemory(input)
            async let whenQuestionClassification = classifyAsQuery(input)
            
            let (memoryResult, queryResult) = try await (memoryClassification, whenQuestionClassification)
                    
            print("memory: \(memoryResult), when: \(queryResult)")
            
            if queryResult.isQuestion {
                return .query(queryResult.question)
            } else if memoryResult.isFact {
                return .memory(memoryResult.fact)
            } else {
                return .invalid
            }
        } catch {
            return .invalid
        }
    }
    
    func generateOutput(for input: String) async throws -> String {
        let response = await classifiyInput(for: input)
       
        LLogger.shared.debug("Classification: - \(response)")
        
        switch response {
        case .memory(let memory):
            memoryManager.saveMemory(memory)
            let session = LanguageModelSession(model: .default, instructions: GenerationManager.responseInstructions)
            let prompt = build_prompt(prefix: GenerationManager.memoryResponsePrompt, userInput: memory)
            let response = try await session.respond(to: prompt)
            return response.content
        case .query(let query):
            let valid_memories = memoryManager.getRelevantMemories(for: query)
            if let memory = valid_memories.first {
                print("The relevant memory is: \(memory)")
                
                let prompt = Prompt {
                    GenerationManager.queryResponsePrompt
                    "-----------"
                    "\(query)"
                    "-----------"
                    "\(memory)"
                }
                
                let session = LanguageModelSession(model: .default, instructions: GenerationManager.responseInstructions)
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
    static let whenQuestionClassificationInstruction: String = "You are a careful classifier that labels inputs as personal 'when' questions only when the sentence ends with a question mark, mentions the user, and is about when they last did something. Sentences that start with memory cues or lack a question mark must return is_question = false with a confidence_score below 60. If the checklist is satisfied, set is_question = true and give a confidence_score of 90 or higher (threshold is 60)."
    
    static let memoryClassificationInstruction: String = "You are a careful classifier that labels inputs as personal facts only when the sentence describes a discrete thing the user personally did or experienced in the past and has clear timing or memory cues. Explicit memory prompts (remember, note, record, keep in mind) should return is_fact = true even if they mention question words. Always supply a confidence_score between 0 and 100: yield 90+ whenever you are certain (the decision threshold is 60), and keep it below 60 when the evidence is missing or contradictory."
    
    static let responseInstructions: String = "You are a helpful app that lets users remember things about themselves. Generate text that is factual, respectful, and appropriate for a casual conversation in a curt, concise tone. Never make up any details, and never answer questions that aren't based on the user's past experiences."
    
    static let memoryClassificationPrompt = """
    Classify the sentence as a fact about the user.
    
    Input: "Can you note that I brushed my teeth at 12pm yesterday?"
    Ouput: True
    
    Input: "Remember that I replaced my laptop battery this afternoon."
    Output: True
    
    Input: "When did I last go to the gym?"
    Output: False
    
    Input: "I am thinking about lunch."
    Output: False
    """
    
    static let queryClassificationPrompt = """
    Classify this sentence as a personal question about when the user last did something.

    Input: "When did I last deep clean the bathroom?"
    Ouput: True
    
    Input: "When did I renew my passport?"
    Output: True
    
    Input: "Where did I leave the keys?"
    Output: False
    
    Input: "Tell me when to leave."
    Output: False
    
    Input: "When was the moon landing?"
    Output: False
    """
    
    static let memoryResponsePrompt = """
    The user has just provided a memory that was saved. Generate a simple response to acknowledge that this action has been carried out.    
    """
    
    static let queryResponsePrompt = """
    The user has just provided a question about a fact that they previously saved. Take a good look at the question the user asked, and the relevant memory retrieved from the store. Generate a simple response to the user to provide the answer to the question they are looking for. Do not answer in first person based on the memory, since it is from the perspective of the user. Here is the question that the user asked, followed by the memory that was retrieved:    
    """
}

// GENERABLES
@Generable(description: "Classification of user input as a memory, a personal 'when' question, or neither")
enum UserQueryClassification: CustomStringConvertible {
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
    
    var description: String {
        switch self {
        case .memory(let memory):
            return "Memory - {\(memory)}"
        case .query(let query):
            return "Query - {\(query)}"
        case .invalid:
            return "Invalid"
        }
    }
}

@Generable(description: "Classification result for whether an input is a personal question about the user")
struct QuestionClassification {
//    @Guide(description: "Boolean for whether the question is a 'when' question")
    let isQuestion: Bool
    
//    @Guide(description: "Question itself, or empty string")
    let question: String
    
    let confidence_score: Int
}

@Generable(description: "Classification result for whether an input is a fact to remember")
struct FactClassification {
    
//    @Guide(description: "Boolean for whether the memory is to be remembered")
    let isFact: Bool
    
//    @Guide(description: "Memory itself, or empty string")
    let fact: String
    
    let confidence_score: Int
}

// TOOL
