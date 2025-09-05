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

---

**Built with ❤️ using Flutter and Firebase**

*Ready to run and fully functional chat application with real-time messaging capabilities!*
