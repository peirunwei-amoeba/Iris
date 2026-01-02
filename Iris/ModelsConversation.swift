//
//  Conversation.swift
//  Iris
//
//  Created by Runwei Pei on 2/1/26.
//

import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message] = []
    
    init(title: String = "New Conversation") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Updates the conversation's title based on the first message
    func updateTitle(from firstMessage: String) {
        let truncated = String(firstMessage.prefix(50))
        self.title = truncated.count < firstMessage.count ? truncated + "..." : truncated
        self.updatedAt = Date()
    }
}
