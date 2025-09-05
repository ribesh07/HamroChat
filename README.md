# HamroChat - Real-time Chat Application

A feature-rich chat application built with Flutter, Firebase, and Socket.IO for real-time messaging.

## 🚀 Features

### ✅ Completed Features

#### 🔐 Authentication
- **Email/Password Authentication** with Firebase Auth
- **User Registration** with validation
- **Password Reset** functionality
- **Auto-login** with persistent authentication state
- **Profile Management** with avatar upload

#### 💬 Real-time Messaging
- **Socket.IO Integration** using WebSocket URL: `wss://render.vsd.com`
- **Real-time message delivery** and updates
- **Message status indicators** (sent, delivered, read)
- **Typing indicators** when users are typing
- **Online/offline status** tracking

#### 🏠 Chat Management
- **One-on-one conversations**
- **Group chats** with multiple participants
- **Chat list** with last message preview
- **Unread message counts**
- **User search** to find and start new chats

#### 📱 Media Sharing
- **Image sharing** via camera or gallery
- **Firebase Storage integration** for file uploads
- **Image preview** in chat bubbles
- **Upload progress indicators**

#### 🎨 User Experience
- **Emoji picker** for expressing emotions
- **Message bubbles** with sender info (for groups)
- **Time stamps** with relative time display
- **Smooth navigation** between screens
- **Loading states** and error handling

#### ⚙️ Technical Features
- **Riverpod state management** for reactive UI
- **Firebase Firestore** for data persistence
- **Proper error handling** throughout the app
- **Null safety** compliant code
- **Clean architecture** with separated concerns

## 🏗️ Project Structure

```
lib/
├── models/              # Data models
│   ├── user_model.dart
│   ├── chat_model.dart
│   └── message_model.dart
├── repositories/        # Data access layer
│   ├── auth_repository.dart
│   └── chat_repository.dart
├── services/           # External services
│   └── socket_service.dart
├── providers/          # Riverpod providers
│   └── providers.dart
└── screens/           # UI screens
    ├── auth/          # Authentication screens
    └── chat/          # Chat-related screens
```

## 🔧 Setup Instructions

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Firebase Setup**
   - Your Firebase project is already configured
   - Authentication, Firestore, and Storage are ready

3. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Flow

1. **Authentication**: Users register or login with email/password
2. **Chat List**: View all conversations with unread counts
3. **New Chat**: Search for users to start conversations
4. **Messaging**: Send text messages, images, and emojis
5. **Groups**: Create and manage group chats
6. **Profile**: Update user information and avatar

## 🔮 Socket.IO Integration

The app connects to your WebSocket server at `wss://render.vsd.com` for:
- Real-time message delivery
- Typing indicators
- Online status updates
- Message status confirmations (delivered/read)

## 🎨 UI Highlights

- **Material Design** components
- **Intuitive navigation** with proper back handling
- **Responsive layouts** for different screen sizes
- **Smooth animations** and transitions
- **Proper loading states** for all async operations

## 🐛 Troubleshooting

### No Users Showing Up in Search?

1. **Make sure you have multiple accounts**: You need at least 2 user accounts to see others in search
2. **Use the Debug Tools**: Go to Profile → Debug Tools → "Add Test Users" to create sample users for testing
3. **Check the console**: Debug information is printed to help identify issues
4. **Leave search empty**: The search shows all available users when the search field is empty

### Testing the App

1. **Create multiple accounts** using different email addresses
2. **Or use Debug Tools** to add test users (alice@example.com, bob@example.com, charlie@example.com)
3. **Search functionality** works with both names and email addresses
4. **Case insensitive search** - try partial matches too

### Debug Console Output

Watch the debug console for helpful information like:
- `Search provider called with query: "..."`
- `Search query: "...", found X users`
- `Users found: X`

---

**Built with ❤️ using Flutter and Firebase**

*Ready to run and fully functional chat application with real-time messaging capabilities!*
