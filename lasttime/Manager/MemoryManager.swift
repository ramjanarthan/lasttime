//
//  MemoryManager.swift
//  lasttime
//
//  Created by Ram Janarthan on 12/4/26.
//

import Foundation
import NaturalLanguage

class MemoryManager {
    private var memories: [String] = []
    
    private let demoMemories: [String] = [
        "I ate coffee at the Bakery on 20th street",
        "I brushed my teeth last Tuesday",
        "I went to the gym on monday",
        "I walked the dog this afternoon",
        "I bought a new set of sheets on 28th May"
    ]
    
    init() {
        self.memories = readFromFile() ?? demoMemories
    }
    
    func getRelevantMemories(for prompt: String) -> [String] {
        var relevantMemories: [String] = []
        
        let target_dictionary = Set(prompt.split(separator: " ").map({ x in
            let filtered = x.filter({ !$0.isPunctuation })
            return filtered.lowercased()
        }))
        
        for memory in memories {
            let memory_dictionary = Set(memory.split(separator: " ").map({ x in
                x.lowercased()
            }))
            
            let intersection = memory_dictionary.intersection(target_dictionary)
            if intersection.count > 2 {
                relevantMemories.append(memory)
            }
        }
        
        return relevantMemories
    }
    
    func saveMemory(_ memory: String) {
        self.memories.append(memory)
    }
    
    private func readFromFile() -> [String]? {
        let results = UserDefaults.standard.value(forKey: "memories")
        if let results = results as? [String] {
            return results
        }
        return nil
    }
    
    func writeToFile() {
        UserDefaults.standard.set(self.memories, forKey: "memories")
    }
}
