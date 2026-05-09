import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AppNotificationWrapper extends StatefulWidget {
  final Widget child;

  const AppNotificationWrapper({super.key, required this.child});

  @override
  State<AppNotificationWrapper> createState() => _AppNotificationWrapperState();
}

class _AppNotificationWrapperState extends State<AppNotificationWrapper> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  StreamSubscription<User?>? _authSubscription;
  final DateTime _startTime = DateTime.now();

  // Track unread counts to detect new messages
  final Map<String, int> _lastUnreadCounts = {};

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(_handleAuthChange);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _notificationSubscription?.cancel();
    _chatSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleAuthChange(User? user) {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _chatSubscription?.cancel();
    _chatSubscription = null;
    _lastUnreadCounts.clear();

    if (user != null) {
      // 1. Listen for general notifications (likes, views, matches)
      _notificationSubscription = FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .listen(_handleNotifications);

      // 2. Listen for new messages in chats
      _chatSubscription = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .snapshots()
          .listen((snapshot) => _handleChatChanges(snapshot, user.uid));
    }
  }

  void _handleNotifications(QuerySnapshot snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final data = change.doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        final type = data['type'] as String?;
        
        // Only play if it's a fresh notification (after app start)
        if (timestamp != null && timestamp.isAfter(_startTime)) {
          if (type == 'match') {
            _playSound('audios/match.mp3');
          } else {
            _playSound('audios/notification.mp3');
          }
        }
      }
    }
  }

  void _handleChatChanges(QuerySnapshot snapshot, String myUid) {
    for (var change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>;
      final chatId = change.doc.id;
      final unreadCount = (data['unreadCount'] as Map<String, dynamic>?) ?? {};
      final myUnread = (unreadCount[myUid] as num?)?.toInt() ?? 0;
      final lastSenderId = data['lastMessageSenderId'] as String?;
      final lastTime = (data['lastMessageTime'] as Timestamp?)?.toDate();

      // Only care about messages from OTHERS that arrived AFTER app start
      if (lastSenderId != null && 
          lastSenderId != myUid && 
          lastTime != null && 
          lastTime.isAfter(_startTime)) {
        
        final previousUnread = _lastUnreadCounts[chatId] ?? 0;
        
        // If unread count increased, play sound
        if (myUnread > previousUnread) {
          _playSound('audios/notification.mp3');
        }
      }
      
      // Update local tracking
      _lastUnreadCounts[chatId] = myUnread;
    }
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('AppNotificationWrapper: Error playing sound $assetPath — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
