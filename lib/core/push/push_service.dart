import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/notification_repository.dart';

/// Push notifications via FCM, strictly optional.
///
/// Firebase needs `android/app/google-services.json` (and the iOS plist);
/// until those exist `Firebase.initializeApp` throws and this service simply
/// stays disabled — the app keeps its in-app, WebSocket-driven notifications.
class PushService {
  PushService(this._repo);

  final NotificationRepository _repo;

  bool _available = false;
  String? _registeredToken;
  StreamSubscription<String>? _refreshSub;

  /// Where a tapped notification should take the user (payload `data`).
  void Function(Map<String, dynamic> data)? onOpen;

  bool get isAvailable => _available;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      debugPrint('[push] disabled: $e');
      return;
    }
    FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen?.call(m.data));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Let the router settle before navigating from a cold start.
      Future.delayed(const Duration(milliseconds: 600), () => onOpen?.call(initial.data));
    }
  }

  /// After sign-in: ask permission (Android 13+ / iOS) and register the token.
  Future<void> registerForUser() async {
    if (!_available) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
      _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(_register);
    } catch (e) {
      debugPrint('[push] register failed: $e');
    }
  }

  Future<void> _register(String token) async {
    await _repo.registerPushToken(token, platform: Platform.isIOS ? 'ios' : 'android');
    _registeredToken = token;
  }

  /// Before sign-out, so the next user of this device doesn't get our pushes.
  Future<void> unregister() async {
    final token = _registeredToken;
    if (!_available || token == null) return;
    try {
      await _repo.unregisterPushToken(token);
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _registeredToken = null;
  }
}
