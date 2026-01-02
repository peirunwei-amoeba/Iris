//
//  ConversationListView.swift
//  Iris
//
//  Created by Runwei Pei on 2/1/26.
//

import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]
    @State private var chatService = ChatService()
    
    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationList
                }
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createNewConversation()
                    } label: {
                        Label("New Conversation", systemImage: "plus")
                    }
                }
            }
        }
        .environment(chatService)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Conversations", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Start a new conversation to chat with the AI assistant")
        } actions: {
            Button("New Conversation") {
                createNewConversation()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var conversationList: some View {
        List {
            ForEach(conversations) { conversation in
                NavigationLink(value: conversation) {
                    ConversationRowView(conversation: conversation)
                }
            }
            .onDelete(perform: deleteConversations)
        }
        .navigationDestination(for: Conversation.self) { conversation in
            ChatView(conversation: conversation)
        }
    }
    
    private func createNewConversation() {
        let newConversation = Conversation()
        modelContext.insert(newConversation)
        try? modelContext.save()
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(conversations[index])
        }
        try? modelContext.save()
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
            
            HStack {
                Text(conversation.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if !conversation.messages.isEmpty {
                    Text("\(conversation.messages.count) messages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConversationListView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}
