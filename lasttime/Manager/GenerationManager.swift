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
        let prompt = build_prompt(prefix: GenerationManager.DEFAULT_MEMORY_PROMPT, userInput: input)
        let response = try await session.respond(to: prompt, generating: FactClassification.self)
        return response.content
    }
    
    private func classifyAsQuery(_ input: String) async throws -> QuestionClassification {
        let session = LanguageModelSession(model: .default)
        let prompt = build_prompt(prefix: GenerationManager.DEFAULT_QUERY_PROMPT, userInput: input)
        let response = try await session.respond(to: prompt, generating: QuestionClassification.self)
        
        let containsWhen = input.lowercased().contains("when")
        if containsWhen, response.content.isQuestion {
            return QuestionClassification(isQuestion: true, question: response.content.question, confidence_score: response.content.confidence_score)
        } else {
            return QuestionClassification(isQuestion: false, question: "", confidence_score: 0)
        }
    }
    
    private func build_prompt(prefix: String, userInput: String) -> Prompt {
        return Prompt {
            prefix
            "------------"
            userInput
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
        } catch {
            return .invalid
        }
    }
    
    func generateOutput(for input: String) async throws -> String {
        let response = await classifiyInput(for: input)
        
        print("Response: \(response)")
        
        switch response {
        case .memory(let memory):
            memoryManager.saveMemory(memory)
            let prompt = Prompt {
                "Generate a response to acknowledge the previous fact provided by the user: "
                "\(memory)"
            }
            
            let session = LanguageModelSession(model: .default)
            let response = try await session.respond(to: prompt)
            return response.content
        case .query(let query):
            let valid_memories = memoryManager.getRelevantMemories(for: query)
            if let memory = valid_memories.first {
                print("The relevant memory is: \(memory)")
                
                let prompt = Prompt {
                    "Your task is to generate a respond to the question: "
                    "\(query)."
                    "The relevant memory is:"
                    "\(memory)"
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
    static let whenQuestionClassificationInstruction: String = "You are a careful classifier that labels inputs as personal 'when' questions only when the sentence ends with a question mark, mentions the user, and is about when they last did something. Sentences that start with memory cues or lack a question mark must return is_question = false with a confidence_score below 60. If the checklist is satisfied, set is_question = true and give a confidence_score of 90 or higher (threshold is 60)."
    
    static let memoryClassificationInstruction: String = "You are a careful classifier that labels inputs as personal facts only when the sentence describes a discrete thing the user personally did or experienced in the past and has clear timing or memory cues. Explicit memory prompts (remember, note, record, keep in mind) should return is_fact = true even if they mention question words. Always supply a confidence_score between 0 and 100: yield 90+ whenever you are certain (the decision threshold is 60), and keep it below 60 when the evidence is missing or contradictory."
    
    static let userQueryClassifcationInstructions: String = """
        Your task is to classify the user input is a question, a personal memory, or neither 
    """
    
    static let DEFAULT_MEMORY_PROMPT = """
    Classify this sentence as a fact about the user.

    Return is_fact = true only when all of the following are satisfied:
    1. The sentence is first-person and describes something the user already did or experienced in the past.
    2. It contains explicit timing or memory cues such as yesterday, this morning, last night, remember, record, note, or keep in mind.
    3. It is not presented as a question, future plan, speculation, or general knowledge statement.
    4. Sentences that start with question words (when, where, how) but have no question mark should still be treated as memories when they clearly describe a past event.

    Examples:
    - "Remember that I replaced my laptop battery this afternoon." -> is_fact true
    - "When did I last go to the gym?" -> is_fact false

    Confidence: set confidence_score to a whole number between 0 and 100; use 90 or higher when you confidently meet all criteria because the decision threshold is 60, and use values around 40 when you are unsure or the signal is weak.

    When is_fact = true, set fact to the cleaned memory text and assign a confidence_score of 90+; when false, leave fact empty and keep confidence below 60.
    """
    
    static let DEFAULT_QUERY_PROMPT = """
    Classify this sentence as a personal question about when the user last did something.

    Return is_question = true only when all of the following are satisfied:
    1. The sentence is clearly a question and ends with a question mark (if there is no '?', return false regardless of other words).
    2. It mentions the user (I/my/me) and asks with timing words such as when, last, previously, earlier, or ago.
    3. It is not about future planning, general knowledge, or instructions to remember something (remember, note, record, keep in mind).

    Examples:
    - "When did I last eat a sandwich?" -> is_question true
    - "Note that I brushed my teeth at 12pm yesterday." -> is_question false

    Confidence: set confidence_score to a whole number between 0 and 100; use 90 or higher when you clearly satisfy the checklist, because the decision threshold is 60, and values near 40 when the input fails the guidelines.

    When is_question = true, set question to the canonical question text and return a confidence_score of 90+; otherwise return an empty string and confidence below 60.
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
