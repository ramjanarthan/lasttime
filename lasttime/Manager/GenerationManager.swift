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
    
    func classifiyInput(for input: String) async -> UserIntentClassifiction {
        do {
            let session = LanguageModelSession(instructions: GenerationManager.intentClassificationInstructions)
            let prompt = Prompt {
                GenerationManager.intentClassificationPromptPrefix
                input
            }
            async let response = session.respond(to: prompt, generating: UserIntentClassifiction.self)
            return try await response.content
        } catch {
            return UserIntentClassifiction(reason: "", conciseForm: "", intent: .unsupported)
        }
    }
    
    func generateOutput(for input: String) async throws -> String {
        let response = await classifiyInput(for: input)
       
        LLogger.shared.debug("Classification: - \(response)")
        
        switch response.intent {
        case .storeFact:
            memoryManager.saveMemory(response.conciseForm)
            let session = LanguageModelSession(model: .default, instructions: GenerationManager.responseGenerationInstructions)
            let prompt = Prompt {
                GenerationManager.responseGenerationPromptPrefix
                response.intent
                "-----------"
                input
            }
            let response = try await session.respond(to: prompt)
            return response.content
        case .recallFact:
            let valid_memories = memoryManager.getRelevantMemories(for: response.conciseForm)
            if let memory = valid_memories.first {
                print("The relevant memory is: \(memory)")
                
                let prompt = Prompt {
                    GenerationManager.responseGenerationPromptPrefix
                    response.intent
                    "-----------"
                    response.conciseForm
                    "-----------"
                    memory
                }
                
                let session = LanguageModelSession(model: .default, instructions: GenerationManager.responseGenerationInstructions)
                let response = try await session.respond(to: prompt)
                return response.content
            } else {
                return "I couldn't find a relevant memory for that question."
            }
        case .unsupported:
            let session = LanguageModelSession(model: .default, instructions: GenerationManager.responseGenerationInstructions)
            let prompt = Prompt {
                GenerationManager.responseGenerationPromptPrefix
                response.intent
            }
            let response = try await session.respond(to: prompt)
            return response.content
        }
    }
}

// PROMPTs
extension GenerationManager {
    static let intentClassificationInstructions = """
        You are a very accurate intent classification system. Your task is to analyse a given input and classify its intent. The supported intent
        is "storeFact" and "recallFact". You are aiming to help the user remember important facts about themselves, and help them recall this at a later time. 
        
        The "storeFact" intent is for statements with clear intent to store information about the user. Statements usually fulfill these criteria:
            1. The sentence is first-person and describes something the user already did or experienced in the past.
            2. It contains explicit memory cues such as "remember", "record", "log" or "note", and may sometimes include polite prefixes like "please" and "can you"? 
            3. It is not a general knowledge statement.
        
        The "recallFact" intent is for statements with clear intent to recall information about the user. Statements usually fulfill these criteria:
            1. The sentence is clearly a question about something specific to the user that occured in the past
            2. It mentions the user (I/my/me) and asks with timing words such as when, last, previously, earlier, or ago.
            3. It is not about general knowledge
        """

    static let intentClassificationPromptPrefix = """
        Here are examples of statements with intent to store a user fact:
        - Log that I went for a hike last Sunday morning
        - Remember that I ate a cream sandwich today
        - Can you remember that I finished the Swift draft yesterday evening?
        
        Here are examples of statements with intent to recall a user fact:
        - When did I last eat a sandwich?
        - When did I last visit San Francisco?
        
        Here is the user input to classify:
        """
    
    static let responseGenerationInstructions = """
        You are a very helpful macOS application that helps users store and recall useful fact about themselves. Don't be too chatty, and maintain a friendly, concise tone in your response. Your task is to generate useful responses to the user, based on the action just carried out by the app. There are three types of actions that can be carried: "storeFact", "recallFact" and "unsupported". 
        
        The "storeFact" action means that the application just saved information from the user, and you should provide a message to acknowledge the same. Some examples include "Sure thing, I've noted that .." or "I've saved that .." followed by the information.
        
        The "recallFact" action means that the application just retrieved some information based on a user query. Based on the retrieved information and the user's query, provide a message that answers the user's query. For example, if the user asked "When did I last eat a fruit?" and the retrieved information is "Remember that I ate a banana on 27th April 2026", the response is "You last ate a banana on 27th April 2026". Always answer as though you are addressing the user directly.
        
        If the user action was "unsupported", provide a simple message to intimate that this was not supported. Some examples are "Sorry, I can't help with that" or "That is an unsupported input for me".
        """

    static let responseGenerationPromptPrefix = """
        Here is the action, and the relevant input:
        """
}

@Generable
struct UserIntentClassifiction: CustomStringConvertible {
    @Guide(description: "Reasoning for user intent classification")
    let reason: String

    @Guide(description: "Relevant substring containing key information")
    let conciseForm: String

    @Guide(description: "Intent of user command")
    let intent: UserIntent
    
    var description: String {
        return "Intent: \(intent), Reason: \(reason), conciseForm: \(conciseForm)"
    }
}

@Generable
enum UserIntent: Decodable, Equatable {
    case storeFact
    case recallFact
    case unsupported
}

