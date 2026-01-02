//
//  ChatService.swift
//  Iris
//
//  Created by Runwei Pei on 2/1/26.
//

import Foundation
import FoundationModels
import Observation

/// Service responsible for handling LLM interactions
@MainActor
@Observable
final class ChatService {
    var modelAvailability: SystemLanguageModel.Availability = .unavailable(.modelNotReady)
    
    private let model = SystemLanguageModel.default
    private var currentSession: LanguageModelSession?
    
    init() {
        checkModelAvailability()
    }
    
    /// Checks if the Foundation Model is available
    func checkModelAvailability() {
        modelAvailability = model.availability
    }
    
    /// Sends a message and returns the response
    func sendMessage(_ prompt: String) async throws -> String {
        // Create a new session for this conversation
        // You can customize instructions here based on your app's needs
        let instructions = """
        You are a helpful and friendly AI assistant.
        Provide clear, concise, and accurate responses.
        Be conversational and engaging.
        """
        
        let session = LanguageModelSession(instructions: instructions)
        currentSession = session
        
        // Get response from the model
        let response = try await session.respond(to: prompt)
        
        return response.content
    }
    
    /// Streams a response with partial updates
    func streamMessage(_ prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let instructions = """
                    You are a helpful and friendly AI assistant.
                    Provide clear, concise, and accurate responses.
                    Be conversational and engaging.
                    """
                    
                    let session = LanguageModelSession(instructions: instructions)
                    self.currentSession = session
                    
                    let stream = session.streamResponse(to: prompt)
                    
                    for try await partial in stream {
                        continuation.yield(partial.content)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
