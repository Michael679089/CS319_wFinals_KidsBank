import 'dart:async'; //Needed for StreamSubscription
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
  String? _lastNotifId;
  DateTime? _lastNotifTime;
  bool _isLoggingOut = false; 

  String get _lastNotifKey => 'last_notif_id_${widget.kidId}'; //Per kid
  String get _lastNotifTimeKey => 'last_notif_time_${widget.kidId}'; //Per kid

  @override
  void initState() {
    super.initState();
    _loadLastNotifData().then((_) => _listenToNotifications());
  }

  Future<void> _loadLastNotifData() async {
    final prefs = await SharedPreferences.getInstance();
    _lastNotifId = prefs.getString(_lastNotifKey);
    final ts = prefs.getString(_lastNotifTimeKey);
    if (ts != null) {
      _lastNotifTime = DateTime.tryParse(ts);
    }
  }

  Future<void> _saveLastNotifData(String notifId, DateTime? notifTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNotifKey, notifId);
    if (notifTime != null) {
      await prefs.setString(_lastNotifTimeKey, notifTime.toIso8601String());
    }
  }

  void _listenToNotifications() {
    _subscription = FirebaseFirestore.instance
        .collection('kids_notifications')
        .where('kid_id', isEqualTo: widget.kidId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || _isLoggingOut) return; 
      if (snapshot.docs.isEmpty) return;

      final latestDoc = snapshot.docs.first;
      final latestData = latestDoc.data();
      final latestTime = (latestData['timestamp'] as Timestamp?)?.toDate();

      if (latestDoc.id != _lastNotifId ||
          (latestTime != null && (_lastNotifTime == null || latestTime.isAfter(_lastNotifTime!)))) {
        _lastNotifId = latestDoc.id;
        _lastNotifTime = latestTime;
        _saveLastNotifData(_lastNotifId!, _lastNotifTime);
        _showPopup(latestData);
      }
    });
  }

  Future<void> _showPopup(Map<String, dynamic> notif) async {
  if (!mounted || _isLoggingOut) return;
  // Play sound
  final player = AudioPlayer();
  await player.play(AssetSource('sounds/ping.mp3'));

  // Choose popup color & display type
  String displayType;
  Color bgColor;
  switch (notif['type']) {
    case 'deposit':
      displayType = 'Deposit';
      bgColor = Colors.green;
      break;
    case 'withdraw':
    case 'withdrawal':
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

  // Show clickable popup
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
            "[$displayType] ${notif['notification_title'] ?? 'Notification'}",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            '${notif['notification_message'] ?? ''}'
            '${notif['amount'] != null ? ' - \$${notif['amount']}' : ''}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    ),
    background: bgColor,
    duration: const Duration(seconds: 3),
    slideDismissDirection: DismissDirection.up,
  );
}

  @override
  void dispose() {
     _isLoggingOut = true;
    _subscription?.cancel();
    OverlaySupportEntry.of(context)?.dismiss(); //Dismiss popup on logout/page change
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
