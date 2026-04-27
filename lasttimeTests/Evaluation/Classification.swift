//
//  Classification.swift
//  lasttimeTests
//
//  Created by Ram Janarthan on 13/4/26.
//

import Testing
import Foundation
import FoundationModels
@testable import lasttime

struct Classification {
    
    
    struct DataEntry: Decodable {
        let text: String
        let kind: Kind
        let canonical: String?
    }
        
    let dataset: [DataEntry]
    
    init() {
        let bundle = Bundle(for: TestClass.self)
        guard let datasetPath = bundle.url(forResource: "dataset", withExtension: "json") else {
            fatalError("Could not find dataset.json")
        }
        
        do {
            let data = try Data(contentsOf: datasetPath)

            let decoder = JSONDecoder()
            dataset = try decoder.decode([DataEntry].self, from: data)
        } catch {
            print("❌❌ Error when setting up dataset, falling back to default -- \(String(describing: error))")
            dataset = [
                DataEntry(text: "When did I last eat a burger?", kind: .query, canonical: "When did I last eat a burger?")
//                DataEntry(text: "Where did I go yesterday?", kind: .invalid),
//                DataEntry(text: "Whats the capital of England", kind: .invalid),
//                DataEntry(text: "When did I leave work yesterday?", kind: .query("When did I leave work yesterday")),
//                DataEntry(text: "Who is the president?", kind: .invalid),
//                DataEntry(text: "I am hunry and want to eat", kind: .invalid),
//                DataEntry(text: "Why do I go to work?", kind: .invalid),
//                DataEntry(text: "Note that I brushed my teeth today", kind: .memory("I brushed my teeth")),
//                DataEntry(text: "Remember that I ate fruits this afternoon", kind: .memory("I ate fruits this afternoon"))
                
            ]
        }
    }
    
    @Test func classification() async throws {
        var results: [Bool] = []
        
        for entry in dataset {
            let memoryManager = MemoryManager()
            let manager = GenerationManager(memoryManager: memoryManager)
            let classification = await manager.classifiyInput(for: entry.text)
            
            let isCorrect = entry.kind.isComparable(to: classification.kind)
            print("Expected: \(entry.kind), Got: \(classification) - ", isCorrect ? "✅" : "❌")
            results.append(isCorrect)
        }
        
        let numberCorrect = results.filter(\.self).count
        let total = results.count
        
        print("Results of evaluation: \(numberCorrect)/\(total)")
    }

    @Test func newClassificationStyle() async throws {
        var results: [Bool] = []
        
        for entry in dataset {
            let session = LanguageModelSession(instructions: Instructions.intentClassification)
            let prompt = Prompt {
                Instructions.promptPrefix
                entry.text
            }
            let response = try! await session.respond(to: prompt, generating: UserIntentClassifiction.self)
            let isCorrect = switch (entry.kind, response.content.intent) {
            case (.memory, .storeFact), (.query, .recallFact), (.invalid, .unsupported):
                true
            default:
                false
            }
            print("Expected: \(entry.kind), Got: \(response.content.intent) - ", isCorrect ? "✅" : "❌")
            print("Input: \(entry.text) --- Command : \(response.content.relevant) --- reasoning: \(response.content.reason)")
            results.append(isCorrect)
        }
        
        let numberCorrect = results.filter(\.self).count
        let total = results.count
        
        print("Results of evaluation: \(numberCorrect)/\(total)")
    }
}

class TestClass { }



struct Instructions {
static let intentClassification = """
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

static let promptPrefix = """

    Here are examples of statements with intent to store a user fact:
    - Log that I went for a hike last Sunday morning
    - Remember that I ate a cream sandwich today
    - Can you remember that I finished the Swift draft yesterday evening?
    
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

    @Guide(description: "Relevant substring containing key information")
    let relevant: String

    @Guide(description: "Intent of user command")
    let intent: UserIntent
}

@Generable
enum UserIntent {
case storeFact
case recallFact
case unsupported
}

