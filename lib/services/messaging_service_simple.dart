import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../backend_url.dart';
import '../models.dart';

class MessagingService {
  static String get baseUrl => ApiUrls.messagingService;

  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();
  final Map<String, List<Message>> _conversationCache = {};

  String? _currentUserId;
  String? _authToken;
  Timer? _pollingTimer;
  bool _hasConnectionIssue = false;

  // Streams for UI to listen to
  Stream<Message> get messageStream => _messageController.stream;
  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;

  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  /// Initialize the messaging service with user credentials
  Future<void> initialize(String userId, String authToken) async {
    _currentUserId = userId;
    _authToken = authToken;
    _connectionStatusController.add('Connected');

    // Start polling for new messages (fallback when SignalR is not available)
    _startPolling();

    if (kDebugMode) {
      debugPrint('✅ Messaging service initialized');
    }
  }

  /// Start polling for new messages
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // This will be used to check for new messages when SignalR is not working
      // For now, we'll rely on manual refresh
    });
  }

  /// Send a message via REST API
  Future<bool> sendMessage(String receiverId, String content,
      {MessageType type = MessageType.text}) async {
    if (_currentUserId == null || _authToken == null) {
      if (kDebugMode) {
        debugPrint('❌ Cannot send message: Not authenticated');
      }
      return false;
    }

    try {
      // Optimistically add message to cache
      final tempMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId!,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        type: type,
      );

      final conversationId = _getConversationId(_currentUserId!, receiverId);
      _conversationCache[conversationId] ??= [];
      _conversationCache[conversationId]!.add(tempMessage);

      // Notify UI immediately
      _messageController.add(tempMessage);

      // Send via REST API
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'receiverId': receiverId,
          'content': content,
          'type': type.index,
        }),
      );

      if (response.statusCode == 200) {
        final messageData = json.decode(response.body);
        final confirmedMessage = Message.fromJson(messageData);

        // Update cache with confirmed message
        final index = _conversationCache[conversationId]!.indexWhere((m) =>
            m.content == tempMessage.content &&
            m.senderId == tempMessage.senderId);

        if (index != -1) {
          _conversationCache[conversationId]![index] = confirmedMessage;
        }

        if (kDebugMode) {
          debugPrint('📤 Message sent successfully: $content');
        }

        return true;
      } else {
        // Remove optimistic message on failure
        _conversationCache[conversationId]?.remove(tempMessage);

        if (kDebugMode) {
          debugPrint('❌ Failed to send message: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send message: $e');
      }
      return false;
    }
  }

  /// Get conversation history
  Future<List<Message>> getConversation(String otherUserId,
      {int page = 1, int pageSize = 50}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/messages/conversation/$otherUserId?page=$page&pageSize=$pageSize'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = json.decode(response.body);
        final messages =
            messagesJson.map((json) => Message.fromJson(json)).toList();

        // Cache the messages
        final conversationId = _getConversationId(_currentUserId!, otherUserId);
        _conversationCache[conversationId] = messages.reversed.toList();

        return messages;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to load conversation: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading conversation: $e');
      }
      return [];
    }
  }

  /// Get all conversations
  Future<List<ConversationSummary>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/conversations'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> conversationsJson = json.decode(response.body);
        _hasConnectionIssue = false;
        return conversationsJson
            .map((json) => ConversationSummary.fromJson(json))
            .toList();
      } else {
        if (!_hasConnectionIssue && kDebugMode) {
          debugPrint('❌ Failed to load conversations: ${response.statusCode}');
        }
        _hasConnectionIssue = true;
        return [];
      }
    } catch (e) {
      if (!_hasConnectionIssue && kDebugMode) {
        debugPrint('❌ Error loading conversations: $e');
      }
      _hasConnectionIssue = true;
      return [];
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/messages/$messageId/read'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );
      _hasConnectionIssue = false;

      // Update local cache
      for (final conversation in _conversationCache.values) {
        final messageIndex = conversation.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          final message = conversation[messageIndex];
          conversation[messageIndex] = message.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          break;
        }
      }
    } catch (e) {
      if (!_hasConnectionIssue && kDebugMode) {
        debugPrint('❌ Error marking message as read: $e');
      }
      _hasConnectionIssue = true;
    }
  }

  /// Refresh conversation to get new messages
  Future<void> refreshConversation(String otherUserId) async {
    final messages = await getConversation(otherUserId);

    // Check for new messages and notify UI
    final conversationId = _getConversationId(_currentUserId!, otherUserId);
    final cachedMessages = _conversationCache[conversationId] ?? [];

    for (final message in messages) {
      final existsInCache = cachedMessages.any((m) => m.id == message.id);
      if (!existsInCache && message.senderId != _currentUserId) {
        _messageController.add(message);
      }
    }
  }

  /// Get cached messages for a conversation
  List<Message> getCachedMessages(String otherUserId) {
    final conversationId = _getConversationId(_currentUserId!, otherUserId);
    return _conversationCache[conversationId] ?? [];
  }

  /// Generate conversation ID
  String _getConversationId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}';
  }

  /// Dispose resources
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.close();
    _connectionStatusController.close();
  }
}

/// Conversation summary model
class ConversationSummary {
  final String conversationId;
  final Message lastMessage;
  final int unreadCount;
  final String otherUserId;

  ConversationSummary({
    required this.conversationId,
    required this.lastMessage,
    required this.unreadCount,
    required this.otherUserId,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        conversationId: json['conversationId'] ?? '',
        lastMessage: Message.fromJson(json['lastMessage'] ?? {}),
        unreadCount: json['unreadCount'] ?? 0,
        otherUserId: json['otherUserId'] ?? '',
      );
}
