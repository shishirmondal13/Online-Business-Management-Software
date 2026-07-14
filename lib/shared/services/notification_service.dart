import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/firestore_constants.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _salesSubscription;
  StreamSubscription? _productsSubscription;
  bool _isInitialized = false;
  Future<void>? _initFuture;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _initFuture ??= _doInitialize();
    await _initFuture;
  }

  Future<void> _doInitialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      ),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<void> startListening(String userId) async {
    await initialize();
    stopListening();

    final since = Timestamp.now();

    _salesSubscription = FirebaseFirestore.instance
        .collection(FirestoreConstants.sales)
        .where('createdAt', isGreaterThan: since)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() ?? {};
              _showNotification(
                title: 'New Sale!',
                body:
                    'Product sold for ${data[FirestoreConstants.totalAmount] ?? 0} BDT',
              );
            }
          }
        });

    _productsSubscription = FirebaseFirestore.instance
        .collection(FirestoreConstants.mobileStock)
        .where('createdAt', isGreaterThan: since)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() ?? {};
              _showNotification(
                title: 'New Mobile Added!',
                body:
                    '${data[FirestoreConstants.modelName] ?? 'Item'} added to stock.',
              );
            }
          }
        });
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'business_updates',
      'Business Updates',
      channelDescription: 'Notifications for sales and stock updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  void stopListening() {
    _salesSubscription?.cancel();
    _productsSubscription?.cancel();
    _salesSubscription = null;
    _productsSubscription = null;
  }
}
