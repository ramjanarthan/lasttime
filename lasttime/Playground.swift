//
//  Playground.swift
//  lasttime
//
//  Created by Ram Janarthan on 27/4/26.
//

import Playgrounds
import FoundationModels

#Playground {
    let session = LanguageModelSession(instructions: Instructions.intentClassification)
    let prompt = Prompt {
        Instructions.promptPrefix
        "Can you tell me the last time I replaced the smoke detector batteries?"
    }
    let response = try! await session.respond(to: prompt, generating: UserIntentClassifiction.self)
    print(response)
}

struct Instructions {
    static let intentClassification = """
        You are a very accurate intent classification system. Your task
        is to analyse a given input and classify its intent. The supported intent
        is "storeFact" and "recallFact". You are aiming to help the user remember important facts about themselves, and help them recall this at a later time. 
        """
    
    static let promptPrefix = """
        Here are examples of statements with intent to store a user fact:
        - Log that I went for a hike last Sunday morning
        - Remember that I ate a cream sandwich today
        
        
        Here are examples of statements with intent to recall a user fact:
        - When did I last eat a sandwich?
        - When did I last visit San Francisco?
        
        Here is the user input to classify:
        """
}

@Generable
struct UserIntentClassifiction {
    
    @Guide(description: "Reasoning for user intent classification")
    let reason: String
    
    @Guide(description: "Relevant substring for semantic retrieval")
    let command: String
    
    @Guide(description: "Intent of user command")
    let intent: UserIntent
}

@Generable
enum UserIntent {
    case storeFact
    case recallFact
    case unsupported
}
