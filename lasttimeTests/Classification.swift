//
//  Classification.swift
//  lasttimeTests
//
//  Created by Ram Janarthan on 13/4/26.
//

import Testing
@testable import lasttime

struct Classification {
    struct DataEntry {
        let text: String
        let inputType: UserQueryClassification
    }
        
    let dataset = [
        DataEntry(text: "When did I last eat a burger?", inputType: .query("When did I last eat a burger")),
        DataEntry(text: "Where did I go yesterday?", inputType: .invalid),
        DataEntry(text: "Whats the capital of England", inputType: .invalid),
        DataEntry(text: "When did I leave work yesterday?", inputType: .query("When did I leave work yesterday")),
        DataEntry(text: "Who is the president?", inputType: .invalid),
        DataEntry(text: "I am hunry and want to eat", inputType: .invalid),
        DataEntry(text: "Why do I go to work?", inputType: .invalid),
        DataEntry(text: "Note that I brushed my teeth today", inputType: .memory("I brushed my teeth")),
        DataEntry(text: "Remember that I ate fruits this afternoon", inputType: .memory("I ate fruits this afternoon"))

    ]
    
    @Test func classification() async throws {
        var results: [Bool] = []
        
        for entry in dataset {
            let manager = GenerationManager()
            let classification = await manager.classifiyInput(for: entry.text)
            
            let isCorrect = entry.inputType.isComparable(to: classification)
            print("Expected: \(entry.inputType), Got: \(classification) - ", isCorrect ? "✅" : "❌")
            results.append(isCorrect)
        }
        
        let numberCorrect = results.filter(\.self).count
        let total = results.count
        
        print("Results of evaluation: \(numberCorrect)/\(total)")
    }

}
