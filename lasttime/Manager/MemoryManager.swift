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
    private var memoryToVector: [String: [Double]] = [:]
    
    init() {
        self.memories = readFromFile() ?? [] // TODO: gracefully handle no memories read from file
        prepare()
    }
    
    private func prepare() {
        guard let embeddings = NLEmbedding.sentenceEmbedding(for: .english) else {
            return
        }
        
        for memory in memories {
            let vector = embeddings.vector(for: memory)
            memoryToVector[memory] = vector
        }
    }
    
    func getRelevantMemories(for prompt: String) -> [String] {
        guard let embeddings = NLEmbedding.sentenceEmbedding(for: .english) else {
            return []
        }
        
        // For each memory, calculate distance between memory and prompt, rank by lowest to highest and return top 5
        let relevantMemories = memories
            .map { (memory: $0, distance: embeddings.distance(between: $0, and: prompt)) }
            .sorted { $0.distance < $1.distance }
            .prefix(3)
            .map { $0.memory }
            
        return Array(relevantMemories)
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
