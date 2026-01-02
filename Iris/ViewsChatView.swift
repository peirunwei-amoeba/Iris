//
//  ChatView.swift
//  Iris
//
//  Created by Runwei Pei on 2/1/26.
//

import SwiftUI
import SwiftData
import FoundationModels

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ChatService.self) private var chatService
    @Bindable var conversation: Conversation
    
    @State private var messageText = ""
    @State private var isProcessing = false
    @State private var streamingContent = ""
    @State private var errorMessage: String?
    @Namespace private var glassNamespace
    
    var body: some View {
        ZStack {
          
            VStack(spacing: 0) {
                // Check model availability
                if chatService.modelAvailability != .available {
                    modelUnavailableView
                } else {
                    // Messages list
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(conversation.messages) { message in
                                    MessageBubbleView(message: message)
                                        .id(message.id)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                                
                                // Show streaming message
                                if isProcessing && !streamingContent.isEmpty {
                                    MessageBubbleView(
                                        role: .assistant,
                                        content: streamingContent,
                                        isStreaming: true
                                    )
                                    .id("streaming")
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 100)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: conversation.messages.count) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: streamingContent) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                    }
                    
                    // Input area with Liquid Glass
                    messageInputView
                }
            }
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") {
                errorMessage = nil
            }
        } message: { error in
            Text(error)
        }
    }
    
    private var modelUnavailableView: some View {
        VStack(spacing: 24) {
            GlassEffectContainer(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                        .glassEffect(.regular.tint(.orange), in: .circle)
                    
                    VStack(spacing: 8) {
                        Text("AI Model Unavailable")
                            .font(.title2.bold())
                        
                        Text(availabilityDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    
                    Button {
                        chatService.checkModelAvailability()
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.glass)
                }
                .padding(32)
                .glassEffect(.regular, in: .rect(cornerRadius: 24))
            }
        }
    }
    
    private var availabilityDescription: String {
        switch chatService.modelAvailability {
        case .available:
            return ""
        case .unavailable(.deviceNotEligible):
            return "This device doesn't support Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Please enable Apple Intelligence in Settings"
        case .unavailable(.modelNotReady):
            return "The AI model is downloading or not ready"
        case .unavailable(let other):
            return "Model unavailable: \(other)"
        }
    }
    
    private var messageInputView: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                // Text field with glass effect
                HStack {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .lineLimit(1...6)
                        .disabled(isProcessing)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .font(.body)
                }
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
                .glassEffectID("textfield", in: glassNamespace)
                
                // Send button with glass effect
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: isProcessing ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? Color.blue : Color.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .glassEffect(
                    canSend ? .regular.tint(.blue).interactive() : .regular,
                    in: .circle
                )
                .glassEffectID("sendbutton", in: glassNamespace)
                .disabled(!canSend && !isProcessing)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background {
            // Gentle gradient backdrop
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.03),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = conversation.messages.last {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else if isProcessing {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                proxy.scrollTo("streaming", anchor: .bottom)
            }
        }
    }
    
    private func sendMessage() {
        let userMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        // Clear input
        messageText = ""
        
        // Create user message
        let message = Message(role: .user, content: userMessage, conversation: conversation)
        modelContext.insert(message)
        conversation.messages.append(message)
        
        // Update conversation title if this is the first message
        if conversation.messages.count == 1 {
            conversation.updateTitle(from: userMessage)
        }
        
        try? modelContext.save()
        
        // Get AI response
        isProcessing = true
        streamingContent = ""
        
        Task { @MainActor in
            do {
                // Use streaming for better UX - updates in real-time
                for try await chunk in chatService.streamMessage(userMessage) {
                    streamingContent = chunk
                }
                
                // Create assistant message with final content
                let assistantMessage = Message(
                    role: .assistant,
                    content: streamingContent,
                    conversation: conversation
                )
                modelContext.insert(assistantMessage)
                conversation.messages.append(assistantMessage)
                conversation.updatedAt = Date()
                
                try? modelContext.save()
                
                // Clear streaming state
                streamingContent = ""
                isProcessing = false
                
            } catch {
                isProcessing = false
                streamingContent = ""
                errorMessage = "Failed to get response: \(error.localizedDescription)"
            }
        }
    }
}

struct MessageBubbleView: View {
    var role: MessageRole
    var content: String
    var isStreaming: Bool = false
    
    init(message: Message) {
        self.role = message.role
        self.content = message.content
        self.isStreaming = false
    }
    
    init(role: MessageRole, content: String, isStreaming: Bool = false) {
        self.role = role
        self.content = content
        self.isStreaming = isStreaming
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if role == .assistant {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: role == .assistant ? .trailing : .leading, spacing: 8) {
                // Message content with glass effect
                GlassEffectContainer(spacing: 10) {
                    Text(content)
                        .font(.body)
                        .foregroundStyle(role == .assistant ? Color.white : Color.primary)
                        .textSelection(.enabled)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .glassEffect(
                            role == .assistant 
                                ? .regular.tint(.blue).interactive()
                                : .regular.interactive(),
                            in: .rect(cornerRadius: 20)
                        )
                }
                
                // Streaming indicator
                if isStreaming {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Generating...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassEffect(.regular, in: .capsule)
                }
            }
            
            if role == .user {
                Spacer(minLength: 40)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(conversation: Conversation(title: "Preview Chat"))
    }
    .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
    .environment(ChatService())
}
