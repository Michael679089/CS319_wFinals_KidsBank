import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KidsNotificationListener extends StatefulWidget {
  final String kidId;
  final String familyUserId;
  final Widget child;

  const KidsNotificationListener({
    super.key,
    required this.kidId,
    required this.familyUserId,
    required this.child,
  });

  @override
  State<KidsNotificationListener> createState() => _KidsNotificationListenerState();
}

class _KidsNotificationListenerState extends State<KidsNotificationListener> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final Set<String> _shownNotifIds = {}; // All shown IDs
  bool _isLoggingOut = false;

  String get _shownIdsKey => 'shown_notifs_${widget.kidId}';

  @override
  void initState() {
    super.initState();
    _loadShownNotifIds().then((_) => _listenToNotifications());
  }

  Future<void> _loadShownNotifIds() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_shownIdsKey) ?? [];
    _shownNotifIds.addAll(savedIds);
  }

  Future<void> _saveShownNotifIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_shownIdsKey, _shownNotifIds.toList());
  }

  void _listenToNotifications() {
    _subscription = FirebaseFirestore.instance
        .collection('kids_notifications')
        .where('kid_id', isEqualTo: widget.kidId)
        .where('type', whereIn: ['deposit', 'withdraw', 'reward', 'locked_reward'])
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || _isLoggingOut) return;

      for (var doc in snapshot.docs) {
        final docId = doc.id;
        if (_shownNotifIds.contains(docId)) {
          // 🔒 Already shown → skip
          continue;
        }

        final data = doc.data();
        _shownNotifIds.add(docId); // ✅ Mark as shown immediately
        _saveShownNotifIds();
        _showPopup(data);
      }
    });
  }

  Future<void> _showPopup(Map<String, dynamic> notif) async {
    if (!mounted || _isLoggingOut) return;

    final player = AudioPlayer();
    await player.play(AssetSource('sounds/ping.mp3'));

    final type = (notif['type'] ?? '').toString().toLowerCase();
    String displayType;
    Color bgColor;
    switch (type) {
      case 'deposit':
        displayType = 'Deposit';
        bgColor = Colors.green;
        break;
      case 'withdraw':
        displayType = 'Withdrawal';
        bgColor = Colors.redAccent;
        break;
      case 'reward':
        displayType = 'Reward';
        bgColor = Colors.blueAccent;
        break;
      case 'locked_reward':
        displayType = 'Chore';
        bgColor = Colors.purpleAccent;
        break;
      default:
        displayType = 'Notification';
        bgColor = Colors.orange;
    }

    showSimpleNotification(
      GestureDetector(
        onTap: () {
          if (!_isLoggingOut) {
            Navigator.pushNamed(
              context,
              '/kids-notifications-page',
              arguments: {
                "kid-id": widget.kidId,
                "family-user-id": widget.familyUserId,
              },
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == 'locked_reward'
                  ? '[Chore] Added New Chore'
                  : '[$displayType] ${notif['notification_title'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              type == 'locked_reward'
                  ? '${notif['notification_message'] ?? ''}'
                  : '${notif['notification_message'] ?? ''}'
                    '${notif['amount'] != null ? ' - \$${(notif['amount'] as num).toStringAsFixed(2)}' : ''}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      background: bgColor,
      duration: const Duration(seconds: 7),
      slideDismissDirection: DismissDirection.horizontal,
    );
  }

  @override
  void dispose() {
    _isLoggingOut = true;
    _subscription?.cancel();
    OverlaySupportEntry.of(context)?.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
