//
//  InteractionContentModel.swift
//  lasttime
//
//  Created by Ram Janarthan on 15/3/26.
//

import Foundation

protocol InteractionContentModel: Hashable {
    var id: UUID { get }
    var type: InteractionType { get }
    
    var isFinal: Bool { get }
    var displayContent: String { get }
    
    mutating func updateContent(with text: String, isFinal: Bool)
}
