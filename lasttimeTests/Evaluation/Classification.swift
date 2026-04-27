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
        let kind: UserIntent
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
                DataEntry(text: "When did I last eat a burger?", kind: .recallFact, canonical: "When did I last eat a burger?"),
                DataEntry(text: "Where did I go yesterday?", kind: .recallFact, canonical: "Where did I go yesterday"),
                DataEntry(text: "Whats the capital of England", kind: .unsupported, canonical: nil),
                DataEntry(text: "When did I leave work yesterday?", kind: .recallFact, canonical: "When did I leave work yesterday"),
                DataEntry(text: "Who is the president?", kind: .unsupported, canonical: nil),
                DataEntry(text: "I am hunry and want to eat", kind: .unsupported, canonical: nil),
                DataEntry(text: "Why do I go to work?", kind: .unsupported, canonical: nil),
                DataEntry(text: "Note that I brushed my teeth today", kind: .storeFact, canonical: "I brushed my teeth"),
                DataEntry(text: "Remember that I ate fruits this afternoon", kind: .storeFact, canonical: "I ate fruits this afternoon")
            ]
        }
    }

    @Test func classification() async throws {
        var results: [Bool] = []
        let memoryManager = MemoryManager()
        let generationManager = GenerationManager(memoryManager: memoryManager)
        
        for entry in dataset {
            let response = await generationManager.classifiyInput(for: entry.text)
            let isCorrect = entry.kind == response.intent
            print("Expected: \(entry.kind), Got: \(response.intent) - ", isCorrect ? "✅" : "❌")
            print("Input: \(entry.text) --- Conciseform : \(response.conciseForm) --- reasoning: \(response.reason)")
            results.append(isCorrect)
        }
        
        let numberCorrect = results.filter(\.self).count
        let total = results.count
        
        print("Results of evaluation: \(numberCorrect)/\(total)")
    }
}

class TestClass { }

