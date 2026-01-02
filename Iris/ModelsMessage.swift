//
//  Message.swift
//  Iris
//
//  Created by Runwei Pei on 2/1/26.
//

import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case user
    case assistant
}

@Model
final class Message {
    var id: UUID
    var roleRawValue: String
    var content: String
    var timestamp: Date
    
    var conversation: Conversation?
    
    /// Computed property for role
    var role: MessageRole {
        get {
            MessageRole(rawValue: roleRawValue) ?? .user
        }
        set {
            roleRawValue = newValue.rawValue
        }
    }
    
    init(role: MessageRole, content: String, conversation: Conversation? = nil) {
        self.id = UUID()
        self.roleRawValue = role.rawValue
        self.content = content
        self.timestamp = Date()
        self.conversation = conversation
    }
}
