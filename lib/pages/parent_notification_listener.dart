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

class _ParentNotificationListenerState extends State<ParentNotificationListener> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<UnifiedNotification>>? _subscription;
  bool _isLoggingOut = false;

  /// Stores shown notification IDs so they don't repeat
  final Set<String> _shownNotifIds = {};
  String get _shownIdsKey => 'shown_notifs_${widget.familyId}';

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

  /// Combine chores + withdrawals stream
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
      for (var doc in kidsSnapshot.docs) doc.id: doc['first_name'] ?? 'Kid'
    };
    final kidAvatars = {
      for (var doc in kidsSnapshot.docs)
        doc.id: (doc['avatar_file_path'] as String?)?.isNotEmpty == true
            ? doc['avatar_file_path']
            : 'assets/avatar1.png'
    };

    // Chores stream (all completed chores for family kids)
    final choresStream = _firestore
        .collection('chores')
        .where('status', isEqualTo: 'completed')
        .where('kid_id', whereIn: kidIds)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final kidId = data['kid_id'];
              final timestamp = (data['completed_at'] as Timestamp?)?.toDate() ??
                  (data['created_at'] as Timestamp?)?.toDate() ??
                  DateTime.now();

              return UnifiedNotification(
                id: doc.id,
                kidId: kidId,
                kidName: kidNames[kidId] ?? 'Kid',
                avatar: kidAvatars[kidId] ?? 'assets/avatar1.png',
                type: 'chore_completed',
                title: 'Chore Completed',
                message: '${kidNames[kidId]} completed a chore!',
                choreTitle: data['chore_title']?.toString() ?? '',
                choreDesc: data['chore_description']?.toString() ?? '',
                createdAt: timestamp,
                status: data['status']?.toString() ?? '',
                chore: ChoreModel(
                  id: doc.id,
                  kid_id: kidId,
                  chore_title: data['chore_title']?.toString() ?? '',
                  chore_description: data['chore_description']?.toString() ?? '',
                  reward_money: (data['reward_money'] ?? 0).toDouble(),
                  status: data['status']?.toString() ?? '',
                  created_at: timestamp,
                ),
              );
            }).toList());

    // Withdrawal stream (all withdrawals for family kids)
    final withdrawalStream = _firestore
        .collection('kids_notifications')
        .where('type', isEqualTo: 'withdrawal')
        .where('kid_id', whereIn: kidIds)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final kidId = data['kid_id'];

              return UnifiedNotification(
                id: doc.id,
                kidId: kidId,
                kidName: kidNames[kidId] ?? 'Kid',
                avatar: kidAvatars[kidId] ?? 'assets/avatar1.png',
                type: 'withdrawal',
                title: data['notification_title']?.toString() ?? '',
                message: data['notification_message']?.toString() ?? '',
                amount: (data['amount'] ?? 0).toDouble(),
                createdAt: (data['timestamp'] as Timestamp).toDate(),
                status: data['status']?.toString() ?? '',
              );
            }).toList());

    // Merge streams
    yield* Rx.combineLatest2(choresStream, withdrawalStream, (c, w) {
      final all = [...c, ...w]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    });
  }

  void _listenToNotifications() {
    _subscription = getNotificationsStream().listen((notifications) {
      if (!mounted || _isLoggingOut) return;

      final newNotifs = notifications.where((n) => !_shownNotifIds.contains(n.id)).toList();

      for (final notif in newNotifs) {
        _shownNotifIds.add(notif.id);
        _saveShownNotifIds();
        _showPopup(notif);
      }
    });
  }

  Future<void> _showPopup(UnifiedNotification notif) async {
    if (!mounted || _isLoggingOut) return;

    final player = AudioPlayer();
    await player.play(AssetSource('sounds/ping.mp3'));

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

    String displayMessage;
    if (notif.type == 'chore_completed') {
      displayMessage = notif.choreTitle?.isNotEmpty == true
          ? "✅ ${notif.kidName} completed the chore: ${notif.choreTitle}"
          : "✅ ${notif.kidName} completed a chore!";
    } else if (notif.type == 'withdrawal') {
      displayMessage =
          "💸 ${notif.kidName} has withdrawn \$${notif.amount?.toStringAsFixed(2) ?? '0.00'}";
    } else {
      displayMessage = notif.message;
    }

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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(displayMessage, style: const TextStyle(color: Colors.white70)),
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
