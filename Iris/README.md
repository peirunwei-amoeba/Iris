# Iris - AI Chatbot App

A clean, modern chatbot application built with SwiftUI, Swift Data, and Foundation Models (Apple's on-device LLM).

## Architecture

### Models (Swift Data)
- **Conversation.swift**: Represents a chat conversation with title, timestamps, and messages
- **Message.swift**: Individual messages with role (user/assistant), content, and timestamp

### Services
- **ChatService.swift**: Manages interactions with Foundation Models
  - Checks model availability
  - Sends messages to the LLM
  - Supports streaming responses for better UX

### Views
- **ContentView.swift**: Main entry point, shows ConversationListView
- **ConversationListView.swift**: Displays all conversations in a list
  - Create new conversations
  - Delete existing conversations
  - Navigate to chat view
- **ChatView.swift**: The main chat interface
  - Send messages
  - Stream AI responses
  - Scroll to latest messages
  - Handle errors gracefully
- **MessageBubbleView.swift**: Displays individual message bubbles

## Features

✅ **Persistent Storage**: All conversations and messages are saved using Swift Data
✅ **Streaming Responses**: Real-time AI responses with streaming support
✅ **Clean Architecture**: Separation of concerns with Models, Views, and Services
✅ **No Sign-In**: Works completely offline with on-device AI
✅ **Error Handling**: Graceful handling of model availability issues
✅ **Modern SwiftUI**: Uses latest Swift 6 and SwiftUI patterns

## Requirements

- iOS 18.2+ (for Foundation Models)
- Device with Apple Intelligence support
- Apple Intelligence enabled in Settings

## Usage

1. Launch the app
2. Tap "+" to create a new conversation
3. Type your message and tap the send button
4. Watch as the AI streams its response in real-time
5. Continue the conversation or create new ones

## Model Availability

The app checks for Foundation Models availability and shows appropriate messages:
- Device not eligible for Apple Intelligence
- Apple Intelligence not enabled
- Model not ready (downloading)
- Model available ✓

## Code Structure

```
Iris/
├── Models/
│   ├── Conversation.swift
│   └── Message.swift
├── Services/
│   └── ChatService.swift
├── Views/
│   ├── ConversationListView.swift
│   └── ChatView.swift
├── ContentView.swift
└── IrisApp.swift
```

## Technical Highlights

- **Swift Data relationships**: Conversations have cascade delete rules for messages
- **Async/await**: Modern Swift concurrency throughout
- **Observable patterns**: ChatService uses @MainActor and @Published
- **Environment values**: ChatService injected via environment
- **Type-safe queries**: Swift Data @Query with sorting
- **Streaming UI**: Updates UI as AI generates responses

## Future Enhancements

- [ ] Conversation search
- [ ] Export conversations
- [ ] Custom AI instructions per conversation
- [ ] Message editing/regeneration
- [ ] System prompt customization
- [ ] Token usage tracking
- [ ] Message attachments
