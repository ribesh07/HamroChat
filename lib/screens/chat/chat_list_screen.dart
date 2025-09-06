import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hamrochat/providers/providers.dart';
import 'package:hamrochat/models/chat_model.dart';
import 'package:hamrochat/screens/chat/chat_room_screen.dart';
import 'package:hamrochat/screens/chat/new_chat_screen.dart';
import 'package:hamrochat/screens/chat/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh chat list when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(userChatsProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh chat list when app resumes
      ref.invalidate(userChatsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userChatsAsync = ref.watch(userChatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.search),
          //   onPressed: () {
          //     // Implement search functionality
          //     _showSearchDialog(context, ref);
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(userChatsProvider),
          ),
          PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                } else if (value == 'logout') {
                  _showLogoutDialog(context, ref);
                }
              },
              itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: const [
                          Icon(Icons.person,
                              size: 20, color: Colors.blueAccent),
                          SizedBox(width: 12),
                          Text(
                            'Profile',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: const [
                          Icon(Icons.logout, size: 20, color: Colors.redAccent),
                          SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ]),
        ],
      ),
      body: userChatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start a new conversation!',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatTile(context, ref, chat);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading chats',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              // Text(
              //   error.toString(),
              //   textAlign: TextAlign.center,
              //   style: TextStyle(color: Colors.grey[600]),
              // ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userChatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NewChatScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, WidgetRef ref, ChatModel chat) {
    return Consumer(
      builder: (context, ref, child) {
        return ref.watch(currentUserProvider).when(
              data: (currentUser) {
                String displayName = chat.chatName;

                // For one-on-one chats, show the other participant's name
                if (chat.type == ChatType.oneOnOne && currentUser != null) {
                  // We'll need to fetch the other user's name
                  // For now, we'll use the stored chat name
                  displayName = chat.chatName;
                }

                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: chat.chatImage != null
                        ? CachedNetworkImageProvider(chat.chatImage!)
                        : null,
                    child: chat.chatImage == null
                        ? Icon(
                            chat.type == ChatType.group
                                ? Icons.group
                                : Icons.person,
                            size: 28,
                          )
                        : null,
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: chat.lastMessage != null
                      ? Text(
                          chat.lastMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        )
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (chat.lastMessageTime != null)
                        Text(
                          timeago.format(chat.lastMessageTime!),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Unread message indicator
                      Consumer(
                        builder: (context, ref, child) {
                          return ref
                              .watch(unreadCountProvider(chat.chatId))
                              .when(
                                data: (count) {
                                  if (count > 0) {
                                    return Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      child: Text(
                                        count > 99 ? '99+' : count.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    // Navigate to chat room
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(chat: chat),
                      ),
                    );
                    // Refresh chat list when returning from chat room
                    ref.invalidate(userChatsProvider);
                  },
                  onLongPress: () {
                    _showChatOptions(context, ref, chat);
                  },
                );
              },
              loading: () => ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: chat.chatImage != null
                      ? CachedNetworkImageProvider(chat.chatImage!)
                      : null,
                  child: chat.chatImage == null
                      ? Icon(
                          chat.type == ChatType.group
                              ? Icons.group
                              : Icons.person,
                          size: 28,
                        )
                      : null,
                ),
                title: Text(
                  chat.chatName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('Loading...'),
              ),
              error: (_, __) => ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: chat.chatImage != null
                      ? CachedNetworkImageProvider(chat.chatImage!)
                      : null,
                  child: chat.chatImage == null
                      ? Icon(
                          chat.type == ChatType.group
                              ? Icons.group
                              : Icons.person,
                          size: 28,
                        )
                      : null,
                ),
                title: Text(
                  chat.chatName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('Error loading user data'),
              ),
            );
      },
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Users'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            scrollPhysics: BouncingScrollPhysics(),
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter name or email...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authMethods = ref.read(authMethodsProvider);
              await authMethods.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context, WidgetRef ref, ChatModel chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Chat Info'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to chat info screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Mute Chat'),
              onTap: () {
                Navigator.of(context).pop();
                // Implement mute functionality
              },
            ),
            if (chat.type == ChatType.oneOnOne)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Chat',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteChatDialog(context, ref, chat);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Leave Group',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showLeaveGroupDialog(context, ref, chat);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteChatDialog(
      BuildContext context, WidgetRef ref, ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final chatRepository = ref.read(chatRepositoryProvider);
                await chatRepository.deleteChat(chat.chatId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting chat: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog(
      BuildContext context, WidgetRef ref, ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final chatRepository = ref.read(chatRepositoryProvider);
                await chatRepository.deleteChat(chat.chatId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Left group')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error leaving group: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
