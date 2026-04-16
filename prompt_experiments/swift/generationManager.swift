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
        let session = LanguageModelSession(model: .default, instructions: Self.memorySessionInstructions)
        let prompt = Prompt {
            Self.memoryPrompt
            "------------"
            "\(input)."
        }
        let response = try await session.respond(to: prompt, generating: FactClassification.self)
        return response.content
    }
    
    private func classifyAsQuery(_ input: String) async throws -> QuestionClassification {
        let session = LanguageModelSession(model: .default, instructions: Self.querySessionInstructions)
        let prompt = Prompt {
            Self.queryPrompt
            "------------"
            "\(input)."
        }
        let response = try await session.respond(to: prompt, generating: QuestionClassification.self)
        
        let containsWhen = input.lowercased().contains("when")
        if containsWhen, response.content.isQuestion {
            return QuestionClassification(isQuestion: true, question: response.content.question)
        } else {
            return QuestionClassification(isQuestion: false, question: "")
        }
    }
    
    func classifiyInput(for input: String) async -> UserQueryClassification {
        do {
            let memoryClassification = try await classifyAsMemory(input)
            let whenQuestionClassification = try await classifyAsQuery(input)
            let memoryHeuristic = heuristicMemory(input)
            let questionHeuristic = heuristicQuery(input)
            
            if questionHeuristic.isQuestion {
                let questionText = whenQuestionClassification.question.isEmpty ? input.trimmingCharacters(in: .whitespacesAndNewlines) : whenQuestionClassification.question
                return .query(questionText)
            } else if memoryHeuristic.isFact {
                let factText = memoryClassification.fact.isEmpty ? input.trimmingCharacters(in: .whitespacesAndNewlines) : memoryClassification.fact
                return .memory(factText)
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

    private func heuristicMemory(_ input: String) -> FactClassification {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalizeInput(cleaned)
        let lower = normalized.lowercased()
        let words = normalizedWords(from: normalized)
        let memoryCues = [
            "remember",
            "note",
            "record",
            "keep in mind",
            "remind you",
            "just so you know",
            "put this in memory",
            "let me remind you",
        ]
        let containsCue = memoryCues.contains { lower.contains($0) }
        let timeTokens: Set<String> = [
            "yesterday", "today", "ago", "last", "monday", "tuesday", "wednesday", "thursday",
            "friday", "saturday", "sunday", "morning", "afternoon", "evening", "night", "tonight",
            "noon", "week", "month", "year", "earlier",
        ]
        let timePhrases = [
            "this morning",
            "this afternoon",
            "this evening",
            "last night",
            "earlier today",
            "earlier this week",
        ]
        let containsTime = !words.isDisjoint(with: timeTokens) || timePhrases.contains(where: lower.contains)
        let firstPerson = !words.isDisjoint(with: ["i", "my"])
        let isQuestion = cleaned.hasSuffix("?")
        let isFact = !isQuestion && (containsCue || (firstPerson && containsTime))
        return .init(isFact: isFact, fact: isFact ? cleaned : "")
    }

    private func heuristicQuery(_ input: String) -> QuestionClassification {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalizeInput(cleaned)
        let lower = normalized.lowercased()
        let words = normalizedWords(from: normalized)
        let containsWhen = words.contains("when")
        let isQuestion = cleaned.hasSuffix("?") || lower.hasPrefix("when")
        let pastMarkers: Set<String> = [
            "did", "last", "ago", "previous", "previously", "earlier", "yesterday", "was", "had", "before",
        ]
        let futureMarkers: Set<String> = [
            "will", "should", "plan", "plans", "next", "tomorrow", "later", "future", "planning", "going",
        ]
        let personal = !words.isDisjoint(with: ["i", "my"])
        let hasPast = !words.isDisjoint(with: pastMarkers)
        let hasFuture = !words.isDisjoint(with: futureMarkers) || lower.contains("plan to") || lower.contains("plan on")
        if containsWhen && personal && hasPast && !hasFuture && isQuestion {
            return .init(isQuestion: true, question: cleaned)
        }
        return .init(isQuestion: false, question: "")
    }

    private func normalizedWords(from input: String) -> Set<String> {
        let punctuation = CharacterSet(charactersIn: ".,?!'\"" )
        let tokens = input
            .split { $0.isWhitespace }
            .map { $0.trimmingCharacters(in: punctuation) }
            .map { $0.lowercased() }
            .filter { !$0.isEmpty }
        return Set(tokens)
    }

    private func normalizeInput(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "—", with: " ")
            .replacingOccurrences(of: "–", with: " ")
            .replacingOccurrences(of: "’", with: "'")
    }
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

@Generable(description: "Classification as a question or not")
struct QuestionClassification {
//    @Guide(description: "Boolean for whether the question is a 'when' question")
    let isQuestion: Bool
    
//    @Guide(description: "Question itself, or empty string")
    let question: String
}

@Generable(description: "Classification as a personal user fact or not")
struct FactClassification {
    
//    @Guide(description: "Boolean for whether the memory is to be remembered")
    let isFact: Bool
    
//    @Guide(description: "Memory itself, or empty string")
    let fact: String
}

// TOOL

extension GenerationManager {
    static let memoryPrompt: String = """
        Classify this sentence as a fact about the user. Return is_fact = true only when the sentence describes something the user actually did or experienced in the past and mentions timing language (e.g., "Remember that I ate lunch at noon.") or explicit memory cues. Return false for questions, general knowledge, future planning, or ongoing thoughts (e.g., "I am thinking about lunch.").
        """
    static let queryPrompt: String = """
        Classify this sentence as a personal question about when the user last did something. Return is_question = true only when the sentence addresses the user (I/my) and asks about a past event with timing language such as did, last, previously, earlier, yesterday, or ago. Return false for future planning/future tense (e.g., "When should I plan to refuel my car next month?") or general knowledge.
        """
    static let memorySessionInstructions: String = "You are a careful classifier that labels inputs as personal facts only when the sentence describes a specific thing the user did or experienced and includes past timing language or memory cues. Example: \"Remember that I ran a mile yesterday\" -> is_fact true; \"I am thinking about lunch\" -> is_fact false."
    static let querySessionInstructions: String = "You are a careful classifier that labels inputs as personal 'when' questions only when the user asks about when they last did something. Example: \"When did I last drink coffee?\" -> is_question true; \"When will we go on vacation?\" -> is_question false."
}
