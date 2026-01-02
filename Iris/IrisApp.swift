//
//  IrisApp.swift
//  Iris
//
//  Created by Runwei Pei on 2/1/26.
//

import SwiftUI
import SwiftData

@main
struct IrisApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Conversation.self, Message.self])
    }
}
