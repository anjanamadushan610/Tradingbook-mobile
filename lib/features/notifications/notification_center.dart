import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/notification.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationCenterState {
  const NotificationCenterState({this.unread = 0, this.latest});

  final int unread;

  /// The most recent pushed notification (drives the in-app banner).
  final AppNotification? latest;
}

/// Live unread badge + incoming notifications over the NotificationDO
/// WebSocket. Reconnects with exponential backoff and jitter (the API
/// contract asks for it to avoid thundering-herd reconnects), pauses in the
/// background, and falls back to polling the unread count if the socket
/// can't be held open.
class NotificationCenter extends Cubit<NotificationCenterState>
    with WidgetsBindingObserver {
  NotificationCenter(this._repo, this._tokens)
      : super(const NotificationCenterState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final NotificationRepository _repo;
  final TokenStorage _tokens;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  int _attempt = 0;
  bool _active = false;
  final _random = Random();

  /// Stream of freshly pushed notifications for list screens to prepend.
  final _incoming = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get incoming => _incoming.stream;

  Future<void> start() async {
    _active = true;
    await refreshUnread();
    _connect();
    _pollTimer ??= Timer.periodic(const Duration(minutes: 2), (_) => refreshUnread());
  }

  Future<void> stop() async {
    _active = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _disconnect();
    emit(const NotificationCenterState());
  }

  Future<void> refreshUnread() async {
    try {
      final count = await _repo.unreadCount();
      if (!isClosed) emit(NotificationCenterState(unread: count, latest: state.latest));
    } catch (_) {}
  }

  void markedRead(int count) {
    emit(NotificationCenterState(
      unread: max(0, state.unread - count),
      latest: state.latest,
    ));
  }

  void allRead() => emit(NotificationCenterState(unread: 0, latest: state.latest));

  Future<void> _connect() async {
    if (!_active || _channel != null) return;
    final token = (await _tokens.read())?.accessToken;
    if (token == null) return;
    try {
      final uri = Uri.parse(
        '${AppConfig.wsBaseUrl}/api/notifications/ws?token=${Uri.encodeQueryComponent(token)}',
      );
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready;
      _attempt = 0;
      _sub = channel.stream.listen(
        _onMessage,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      switch (msg['type']) {
        case 'unread_count':
          emit(NotificationCenterState(
            unread: (msg['count'] as num?)?.toInt() ?? state.unread,
            latest: state.latest,
          ));
        case 'notification':
          final n = AppNotification.fromJson(msg['notification'] as Map<String, dynamic>);
          _incoming.add(n);
          emit(NotificationCenterState(unread: state.unread + 1, latest: n));
      }
    } catch (_) {}
  }

  void _scheduleReconnect() {
    _disconnect();
    if (!_active) return;
    // The access token in the URL expires after 15 minutes; a close is often
    // just that. Any API call refreshes it, so poke one before reconnecting.
    refreshUnread();
    final base = min(60, pow(2, _attempt).toInt());
    final delay = Duration(milliseconds: (base * 1000 * (0.5 + _random.nextDouble())).round());
    _attempt = min(_attempt + 1, 6);
    _reconnectTimer = Timer(delay, _connect);
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    if (state == AppLifecycleState.resumed) {
      _attempt = 0;
      refreshUnread();
      _connect();
    } else if (state == AppLifecycleState.paused) {
      _disconnect();
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnect();
    _pollTimer?.cancel();
    _incoming.close();
    return super.close();
  }
}
