import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hamrochat/providers/providers.dart';
import 'package:hamrochat/models/chat_model.dart';
import 'package:hamrochat/models/user_model.dart';
import 'package:hamrochat/screens/chat/chat_room_screen.dart';
import 'package:hamrochat/screens/chat/new_chat_screen.dart';
import 'package:hamrochat/screens/chat/profile_screen.dart';
import 'package:hamrochat/screens/call/call_history_screen.dart';
import 'package:hamrochat/widgets/ongoing_call_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize search animation
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    ));

    // Refresh chat list when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(userChatsProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchAnimationController.dispose();
    _searchController.dispose();
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
      appBar: _isSearching
          ? null
          : AppBar(
              title: const Text('Chats'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
              ],
            ),
      drawer: _isSearching ? null : _buildDrawer(context, ref),
      body: Column(
        children: [
          // Ongoing call indicator
          const OngoingCallIndicator(),

          // Animated search bar
          AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              return _isSearching
                  ? Container(
                      height: 56.0 + (_searchAnimation.value * 56.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: _stopSearch,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(
                                      color: Color.fromARGB(255, 32, 29, 29)),
                                  decoration: const InputDecoration(
                                    hintText: '  Search users...',
                                    hintStyle: TextStyle(
                                        color: Color.fromARGB(179, 23, 23, 23)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.white),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),

          // Content based on search state
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : userChatsAsync.when(
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
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(userChatsProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
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
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: chat.chatImage != null
            ? CachedNetworkImageProvider(chat.chatImage!)
            : null,
        child: chat.chatImage == null
            ? Icon(
                chat.type == ChatType.group ? Icons.group : Icons.person,
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
              return ref.watch(unreadCountProvider(chat.chatId)).when(
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

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header with user info
          Consumer(
            builder: (context, ref, child) {
              return ref.watch(currentUserProvider).when(
                    data: (currentUser) {
                      return UserAccountsDrawerHeader(
                        accountName: Text(
                          currentUser?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        accountEmail: Text(
                          currentUser?.email ?? 'user@example.com',
                          style: const TextStyle(fontSize: 14),
                        ),
                        currentAccountPicture: CircleAvatar(
                          backgroundImage: currentUser?.photoURL != null
                              ? CachedNetworkImageProvider(
                                  currentUser!.photoURL!)
                              : null,
                          child: currentUser?.photoURL == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      );
                    },
                    loading: () => UserAccountsDrawerHeader(
                      accountName: const Text('Loading...'),
                      accountEmail: const Text('Please wait...'),
                      currentAccountPicture: const CircleAvatar(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    error: (_, __) => UserAccountsDrawerHeader(
                      accountName: const Text('Error'),
                      accountEmail: const Text('Failed to load user data'),
                      currentAccountPicture: const CircleAvatar(
                        child: Icon(Icons.error, color: Colors.white),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  );
            },
          ),

          // Drawer menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: const Text(
                    'Profile',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: const Text(
                    'Settings',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.call, color: Colors.blue),
                  title: const Text(
                    'Call History',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CallHistoryScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help, color: Colors.green),
                  title: const Text(
                    'Help & Support',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Help & Support coming soon!')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context, ref);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    _searchAnimationController.forward();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchAnimationController.reverse();
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Search for users',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Type a name or email to find users',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        return ref.watch(searchedUsersProvider(_searchQuery)).when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserTile(context, ref, user);
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
                      'Error searching users',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(searchedUsersProvider(_searchQuery)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
      },
    );
  }

  Widget _buildUserTile(BuildContext context, WidgetRef ref, UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: user.photoURL != null
            ? CachedNetworkImageProvider(user.photoURL!)
            : null,
        child:
            user.photoURL == null ? const Icon(Icons.person, size: 28) : null,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        user.email,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: user.isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.blue),
            onPressed: () => _startChatWithUser(context, ref, user),
          ),
        ],
      ),
      onTap: () => _startChatWithUser(context, ref, user),
    );
  }

  void _startChatWithUser(
      BuildContext context, WidgetRef ref, UserModel user) async {
    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      final chat = await chatRepository.createOrGetOneOnOneChat(user.uid, user);

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(chat: chat),
          ),
        );
        _stopSearch();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
