import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hamrochat/models/call_history_model.dart';
import 'package:hamrochat/services/webrtc_service.dart';
import 'package:hamrochat/providers/providers.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Missed'),
            Tab(text: 'Outgoing'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearHistoryDialog();
                  break;
                case 'stats':
                  _showCallStatistics();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stats',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Call Statistics'),
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear_all, color: Colors.red),
                  title: Text('Clear History',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search call history...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCallHistoryList(CallHistoryFilter.all),
                _buildCallHistoryList(CallHistoryFilter.missed),
                _buildCallHistoryList(CallHistoryFilter.outgoing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistoryList(CallHistoryFilter filter) {
    return Consumer(
      builder: (context, ref, child) {
        final currentUserAsync = ref.watch(currentUserProvider);

        return currentUserAsync.when(
          data: (currentUser) {
            if (currentUser == null) {
              return const Center(
                child: Text('Please log in to view call history'),
              );
            }

            return ref.watch(callHistoryProvider(currentUser.uid)).when(
                  data: (callHistory) {
                    final filteredCalls = _filterCalls(callHistory, filter);
                    final searchedCalls =
                        _searchCalls(filteredCalls, _searchQuery);

                    if (searchedCalls.isEmpty) {
                      return _buildEmptyState(filter);
                    }

                    return ListView.builder(
                      itemCount: searchedCalls.length,
                      itemBuilder: (context, index) {
                        final call = searchedCalls[index];
                        return _buildCallHistoryItem(call, currentUser.uid);
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
                          'Error loading call history',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref
                              .invalidate(callHistoryProvider(currentUser.uid)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => const Center(
            child: Text('Error loading user data'),
          ),
        );
      },
    );
  }

  Widget _buildCallHistoryItem(CallHistoryModel call, String currentUserId) {
    final isIncoming = call.isIncoming;
    final otherUserName = isIncoming ? call.callerName : call.receiverName;
    final otherUserPhotoURL =
        isIncoming ? call.callerPhotoURL : call.receiverPhotoURL;

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: otherUserPhotoURL != null
            ? CachedNetworkImageProvider(otherUserPhotoURL)
            : null,
        child: otherUserPhotoURL == null
            ? const Icon(Icons.person, size: 28)
            : null,
      ),
      title: Text(
        otherUserName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeago.format(call.startTime),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          if (call.duration != null)
            Text(
              _formatDuration(call.duration!),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                call.callType == CallType.video ? Icons.videocam : Icons.call,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                call.callStatus.icon,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            call.callStatus.displayName,
            style: TextStyle(
              color: _getStatusColor(call.callStatus),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      onTap: () => _showCallDetails(call),
      onLongPress: () => _showCallOptions(call),
    );
  }

  Widget _buildEmptyState(CallHistoryFilter filter) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case CallHistoryFilter.all:
        title = 'No call history';
        subtitle = 'Your call history will appear here';
        icon = Icons.call;
        break;
      case CallHistoryFilter.missed:
        title = 'No missed calls';
        subtitle = 'You haven\'t missed any calls';
        icon = Icons.call_missed;
        break;
      case CallHistoryFilter.outgoing:
        title = 'No outgoing calls';
        subtitle = 'Your outgoing calls will appear here';
        icon = Icons.call_made;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  List<CallHistoryModel> _filterCalls(
      List<CallHistoryModel> calls, CallHistoryFilter filter) {
    switch (filter) {
      case CallHistoryFilter.all:
        return calls;
      case CallHistoryFilter.missed:
        return calls
            .where((call) => call.callStatus == CallStatus.missed)
            .toList();
      case CallHistoryFilter.outgoing:
        return calls.where((call) => !call.isIncoming).toList();
    }
  }

  List<CallHistoryModel> _searchCalls(
      List<CallHistoryModel> calls, String query) {
    if (query.isEmpty) return calls;

    return calls.where((call) {
      final otherName = call.isIncoming ? call.callerName : call.receiverName;
      return otherName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Color _getStatusColor(CallStatus status) {
    switch (status) {
      case CallStatus.answered:
        return Colors.green;
      case CallStatus.missed:
        return Colors.red;
      case CallStatus.rejected:
        return Colors.orange;
      case CallStatus.failed:
        return Colors.red;
      case CallStatus.ongoing:
        return Colors.blue;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Call History'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter name to search...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCallDetails(CallHistoryModel call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Call ID: ${call.callId}'),
            const SizedBox(height: 8),
            Text(
                'Type: ${call.callType == CallType.video ? 'Video' : 'Audio'}'),
            const SizedBox(height: 8),
            Text('Status: ${call.callStatus.displayName}'),
            const SizedBox(height: 8),
            Text('Started: ${timeago.format(call.startTime)}'),
            if (call.endTime != null) ...[
              const SizedBox(height: 8),
              Text('Ended: ${timeago.format(call.endTime!)}'),
            ],
            if (call.duration != null) ...[
              const SizedBox(height: 8),
              Text('Duration: ${_formatDuration(call.duration!)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCallOptions(CallHistoryModel call) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Call Details'),
              onTap: () {
                Navigator.pop(context);
                _showCallDetails(call);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteCallDialog(call);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCallDialog(CallHistoryModel call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Call'),
        content: const Text(
            'Are you sure you want to delete this call from history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final callHistoryRepository =
                    ref.read(callHistoryRepositoryProvider);
                await callHistoryRepository.deleteCallHistory(call.callId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Call deleted from history')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting call: $e'),
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

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Call History'),
        content: const Text(
            'Are you sure you want to clear all call history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final currentUser = ref.read(currentUserProvider).value;
                if (currentUser != null) {
                  final callHistoryRepository =
                      ref.read(callHistoryRepositoryProvider);
                  await callHistoryRepository.clearCallHistory(currentUser.uid);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Call history cleared')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing history: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showCallStatistics() {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<Map<String, int>>(
        future: _getCallStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load statistics: ${snapshot.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          final stats = snapshot.data ?? {};

          return AlertDialog(
            title: const Text('Call Statistics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatItem('Total Calls', stats['total'] ?? 0),
                _buildStatItem('Answered', stats['answered'] ?? 0),
                _buildStatItem('Missed', stats['missed'] ?? 0),
                _buildStatItem('Rejected', stats['rejected'] ?? 0),
                _buildStatItem('Failed', stats['failed'] ?? 0),
                const Divider(),
                _buildStatItem('Audio Calls', stats['audio'] ?? 0),
                _buildStatItem('Video Calls', stats['video'] ?? 0),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getCallStatistics() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) throw Exception('User not logged in');

    final callHistoryRepository = ref.read(callHistoryRepositoryProvider);
    return await callHistoryRepository.getCallStatistics(currentUser.uid);
  }
}

enum CallHistoryFilter {
  all,
  missed,
  outgoing,
}
