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
        DataEntry(text: "Hey can you tell me when I last ate a burger?", inputType: .query("When I last ate a burger")),
        DataEntry(text: "Where did I go yesterday?", inputType: .query("Where did I go yesterday?")),
        DataEntry(text: "Whats the capital of England", inputType: .invalid),
        DataEntry(text: "When do I go to work?", inputType: .query("When do I go to work")),
        DataEntry(text: "Who is the shitty president?", inputType: .invalid),
        DataEntry(text: "I am hunry and want to eat", inputType: .invalid),
        DataEntry(text: "Why do I go to work?", inputType: .invalid),
    ]
    
    @Test func classification() async throws {
        var results: [Bool] = []
        
        for entry in dataset {
            let manager = GenerationManager()
            let classification = await manager.classifiyInput(for: entry.text)
            results.append(classification == entry.inputType)
        }
        
        let numberCorrect = results.filter(\.self).count
        let total = results.count
        
        print("Results of evaluation: \(numberCorrect)/\(total)")
    }

}
