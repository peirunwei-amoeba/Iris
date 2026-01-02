//
//  ContentView.swift
//  Iris
//
//  Created by Runwei Pei on 2/1/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ConversationListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}
