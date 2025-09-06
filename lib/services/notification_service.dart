import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hamrochat/services/webrtc_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
  }

  // Create notification channels
  Future<void> _createNotificationChannels() async {
    // Call notification channel
    const callChannel = AndroidNotificationChannel(
      'call_channel',
      'Call Notifications',
      description: 'Notifications for incoming calls',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Message notification channel
    const messageChannel = AndroidNotificationChannel(
      'message_channel',
      'Message Notifications',
      description: 'Notifications for new messages',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(callChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messageChannel);
  }

  // Show incoming call notification
  Future<void> showIncomingCallNotification({
    required String callerName,
    required String callerId,
    required CallType callType,
    String? callerPhotoURL,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'call_channel',
      'Call Notifications',
      channelDescription: 'Notifications for incoming calls',
      importance: Importance.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      actions: [
        AndroidNotificationAction('answer', 'Answer'),
        AndroidNotificationAction('reject', 'Reject'),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'call_category',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      'incoming_call_$callerId'.hashCode,
      'Incoming ${callType == CallType.video ? 'Video' : 'Audio'} Call',
      'From $callerName',
      notificationDetails,
      payload: 'call_$callerId',
    );
  }

  // Show ongoing call notification
  Future<void> showOngoingCallNotification({
    required String otherUserName,
    required String otherUserId,
    required CallType callType,
    String? otherUserPhotoURL,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'call_channel',
      'Call Notifications',
      channelDescription: 'Notifications for ongoing calls',
      importance: Importance.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      actions: [
        AndroidNotificationAction('return_to_call', 'Return to Call'),
        AndroidNotificationAction('end_call', 'End Call'),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
      categoryIdentifier: 'ongoing_call_category',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      'ongoing_call_$otherUserId'.hashCode,
      'Ongoing ${callType == CallType.video ? 'Video' : 'Audio'} Call',
      'With $otherUserName',
      notificationDetails,
      payload: 'ongoing_call_$otherUserId',
    );
  }

  // Show missed call notification
  Future<void> showMissedCallNotification({
    required String callerName,
    required String callerId,
    required CallType callType,
    String? callerPhotoURL,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'call_channel',
      'Call Notifications',
      channelDescription: 'Notifications for incoming calls',
      importance: Importance.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      'missed_call_$callerId'.hashCode,
      'Missed ${callType == CallType.video ? 'Video' : 'Audio'} Call',
      'From $callerName',
      notificationDetails,
    );
  }

  // Show message notification
  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String chatId,
    String? senderPhotoURL,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'message_channel',
      'Message Notifications',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      'message_$chatId'.hashCode,
      senderName,
      message,
      notificationDetails,
      payload: 'message_$chatId',
    );
  }

  // Cancel call notification
  Future<void> cancelCallNotification(String callerId) async {
    await _localNotifications.cancel('incoming_call_$callerId'.hashCode);
  }

  // Cancel ongoing call notification
  Future<void> cancelOngoingCallNotification(String otherUserId) async {
    await _localNotifications.cancel('ongoing_call_$otherUserId'.hashCode);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      if (payload.startsWith('call_')) {
        final callerId = payload.substring(5);
        // Handle call notification tap
        _handleCallNotificationTap(callerId, response.actionId);
      } else if (payload.startsWith('message_')) {
        final chatId = payload.substring(8);
        // Handle message notification tap
        _handleMessageNotificationTap(chatId);
      }
    }
  }

  // Handle call notification tap
  void _handleCallNotificationTap(String callerId, String? actionId) {
    if (actionId == 'answer') {
      // Answer the call
      print('Answer call from $callerId');
    } else if (actionId == 'reject') {
      // Reject the call
      print('Reject call from $callerId');
    } else {
      // Open call screen
      print('Open call screen for $callerId');
    }
  }

  // Handle message notification tap
  void _handleMessageNotificationTap(String chatId) {
    // Navigate to chat screen
    print('Navigate to chat $chatId');
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // For iOS, permissions are requested during initialization
    return true;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }

    return true;
  }

  // Open notification settings
  Future<void> openNotificationSettings() async {
    // Note: This method may not be available in all versions
    // You might need to use a different approach or remove this method
    print('Opening notification settings...');
  }
}
