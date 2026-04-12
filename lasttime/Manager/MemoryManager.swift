//
//  MemoryManager.swift
//  lasttime
//
//  Created by Ram Janarthan on 12/4/26.
//

import Foundation
import NaturalLanguage

class MemoryManager {
    let memories = [
        "I ate coffee at the Bakery on 20th street",
        "I brushed my teeth last Tuesday",
        "Rahul went to the gym on monday"
    ]
    
    func getRelevantMemories(for prompt: String) -> [String] {
        var relevantMemories: [String] = []
        
        let target_dictionary = Set(prompt.split(separator: " ").map({ x in
            x.lowercased()
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
}
