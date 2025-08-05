import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wfinals_kidsbank/database/models/chores_model.dart';

class UnifiedNotification {
  final String id;
  final String kidId;
  final String kidName;
  final String avatar;
  final String type;
  final String title;
  final String message;
  final String? choreTitle;
  final String? choreDesc;
  final double? amount;
  final DateTime createdAt;
  final String status;
  final ChoreModel? chore;

  UnifiedNotification({
    required this.id,
    required this.kidId,
    required this.kidName,
    required this.avatar,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.status,
    this.choreTitle,
    this.choreDesc,
    this.amount,
    this.chore,
  });
}

class ParentNotificationListener extends StatefulWidget {
  final String familyId;
  final String parentId;
  final String userId;
  final Widget child;

  const ParentNotificationListener({
    super.key,
    required this.familyId,
    required this.parentId,
    required this.userId,
    required this.child,
  });

  @override
  State<ParentNotificationListener> createState() =>
      _ParentNotificationListenerState();
}

class _ParentNotificationListenerState
    extends State<ParentNotificationListener> {
  StreamSubscription<List<UnifiedNotification>>? _subscription;
  String? _lastNotifId;
  DateTime? _lastNotifTime;
  bool _isLoggingOut = false; 

  String get _lastNotifKey => 'last_parent_notif_${widget.familyId}';
  String get _lastNotifTimeKey =>
      'last_parent_notif_time_${widget.familyId}';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Unified stream with Chores + Withdrawals
  Stream<List<UnifiedNotification>> getNotificationsStream() async* {
    final kidsSnapshot = await _firestore
        .collection('kids')
        .where('family_id', isEqualTo: widget.familyId)
        .get();

    if (kidsSnapshot.docs.isEmpty) {
      yield [];
      return;
    }

    final kidIds = kidsSnapshot.docs.map((doc) => doc.id).toList();
    final kidNames = {
      for (var doc in kidsSnapshot.docs)
        doc.id: doc['first_name'] ?? 'Kid'
    };
    final kidAvatars = {
      for (var doc in kidsSnapshot.docs)
        doc.id: (doc['avatar_file_path'] as String?)?.isNotEmpty == true
            ? doc['avatar_file_path']
            : 'assets/avatar1.png'
    };

    final choresStream = _firestore
        .collection('chores')
        .where('status', whereIn: ['completed', 'rewarded'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => kidIds.contains(doc['kid_id']))
            .map((doc) {
              final data = doc.data();
              final kidId = data['kid_id'];
              return UnifiedNotification(
                id: doc.id,
                kidId: kidId,
                kidName: kidNames[kidId] ?? 'Kid',
                avatar: kidAvatars[kidId] ?? 'assets/avatar1.png',
                type: 'chore_completed',
                title: 'Chore Completed',
                message: '${kidNames[kidId]} completed a chore!',
                choreTitle: data['chore_title'],
                choreDesc: data['chore_description'],
                createdAt: (data['created_at'] as Timestamp).toDate(),
                status: data['status'],
                chore: ChoreModel(
                  id: doc.id,
                  kid_id: kidId,
                  chore_title: data['chore_title'],
                  chore_description: data['chore_description'],
                  reward_money: (data['reward_money'] ?? 0).toDouble(),
                  status: data['status'],
                  created_at: (data['created_at'] as Timestamp).toDate(),
                ),
              );
            })
            .toList());

    final withdrawalStream = _firestore
        .collection('kids_notifications')
        .where('type', isEqualTo: 'withdrawal')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => kidIds.contains(doc['kid_id']))
            .map((doc) {
              final data = doc.data();
              final kidId = data['kid_id'];
              return UnifiedNotification(
                id: doc.id,
                kidId: kidId,
                kidName: kidNames[kidId] ?? 'Kid',
                avatar: kidAvatars[kidId] ?? 'assets/avatar1.png',
                type: 'withdrawal',
                title: data['notification_title'],
                message: data['notification_message'],
                amount: (data['amount'] ?? 0).toDouble(),
                createdAt: (data['timestamp'] as Timestamp).toDate(),
                status: data['status'],
              );
            })
            .toList());

    yield* Rx.combineLatest2(
      choresStream,
      withdrawalStream,
      (List<UnifiedNotification> chores,
          List<UnifiedNotification> withdrawals) {
        final all = [...chores, ...withdrawals]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return all;
      },
    );
  }

  void _listenToNotifications() {
    _subscription = getNotificationsStream().listen((notifications) {
      if (!mounted || _isLoggingOut) return;
      if (notifications.isEmpty) return;
      final latest = notifications.first;

      if (latest.id != _lastNotifId ||
          (_lastNotifTime == null ||
              latest.createdAt.isAfter(_lastNotifTime!))) {
        _lastNotifId = latest.id;
        _lastNotifTime = latest.createdAt;
        _saveLastNotifData(_lastNotifId!, _lastNotifTime);
        _showPopup(latest);
      }
    });
  }

  Future<void> _showPopup(UnifiedNotification notif) async {
    if (!mounted || _isLoggingOut) return;
    // Play sound
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/ping.mp3'));

    // Choose popup color
    Color bgColor;
    switch (notif.type) {
      case 'withdrawal':
        bgColor = Colors.redAccent;
        break;
      case 'chore_completed':
        bgColor = Colors.greenAccent;
        break;
      default:
        bgColor = Colors.orange;
    }

    // Create proper display message
    String displayMessage;
    if (notif.type == 'chore_completed') {
      displayMessage = "${notif.kidName} has completed a chore!";
    } else if (notif.type == 'withdrawal') {
      displayMessage =
          "${notif.kidName} has withdrawn \$${notif.amount?.toStringAsFixed(2) ?? '0.00'}";
    } else {
      displayMessage = notif.message;
    }

    // Show popup
    showSimpleNotification(
      GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/parent-notifications-page',
            arguments: {
              "user-id": widget.userId,
              "parent-id": widget.parentId,
              "family_id": widget.familyId,
            },
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notif.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              displayMessage,
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
    OverlaySupportEntry.of(context)?.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
