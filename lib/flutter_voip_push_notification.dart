import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Message handler for incoming notification
///
/// [isLocal] is true if this is a notification from a message scheduled locally
/// or false if its a remote voip push notification
/// [message] contains the notification payload see link below for how to parse this data
/// https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html#//apple_ref/doc/uid/TP40008194-CH10-SW1
typedef FutureOr<dynamic> MessageHandler(
    bool isLocal, Map<String, dynamic> notification);

class NotificationSettings {
  const NotificationSettings({
    this.sound = true,
    this.alert = true,
    this.badge = true,
  });

  NotificationSettings._fromMap(Map<String, bool> settings)
      : sound = settings['sound'] ?? false,
        alert = settings['alert'] ?? false,
        badge = settings['badge'] ?? false;

  final bool sound;
  final bool alert;
  final bool badge;

  @visibleForTesting
  Map<String, dynamic> toMap() {
    return <String, bool>{'sound': sound, 'alert': alert, 'badge': badge};
  }

  @override
  String toString() => 'PushNotificationSettings ${toMap()}';
}

class LocalNotification {
  const LocalNotification({
    required this.alertBody,
    this.alertAction = 'view',
    this.soundName,
    this.category,
    this.userInfo,
  });

  /// The message displayed in the notification alert.
  final String alertBody;

  /// The [action] displayed beneath an actionable notification. Defaults to "view";
  final String alertAction;

  /// The sound played when the notification is fired (optional).
  final String? soundName;

  /// The category of this notification, required for actionable notifications (optional).
  final String? category;

  /// An optional object containing additional notification data.
  final Map<String, dynamic>? userInfo;

  @visibleForTesting
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'alertBody': alertBody,
      'alertAction': alertAction,
      'soundName': soundName,
      'category': category,
      'userInfo': userInfo
    };
  }

  @override
  String toString() => 'LocalNotification ${toMap()}';
}

class FlutterVoipPushNotification {
  factory FlutterVoipPushNotification() => _instance;

  @visibleForTesting
  FlutterVoipPushNotification.private(MethodChannel channel)
      : _channel = channel;

  static final FlutterVoipPushNotification _instance =
      FlutterVoipPushNotification.private(
          const MethodChannel('com.peerwaya/flutter_voip_push_notification'));

  final MethodChannel _channel;
  late String _token;
  late MessageHandler _onMessage;
  late MessageHandler _onResume;
  late void Function(String message)? _debug;

  final StreamController<String> _tokenStreamController =
      StreamController<String>.broadcast();

  /// Fires when a new device token is generated.
  Stream<String> get onTokenRefresh {
    return _tokenStreamController.stream;
  }

  /// Sets up [MessageHandler] for incoming messages.
  void configure({
    required MessageHandler onMessage,
    required MessageHandler onResume,
    void Function(String message)? debug,
  }) {
    _onMessage = onMessage;
    _onResume = onResume;
    _debug = debug;
    _channel.setMethodCallHandler(_handleMethod);
    //_channel.invokeMethod<void>('configure');
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    final Map map = call.arguments.cast<String, dynamic>();
    _debug?.call('_handleMethod: ${call.method}');
    switch (call.method) {
      case "onToken":
        _token = map["deviceToken"];
        _tokenStreamController.add(_token);
        return null;
      case "onMessage":
        return _onMessage(
            map["local"], map["notification"].cast<String, dynamic>());
      case "onResume":
        return _onResume(
            map["local"], map["notification"].cast<String, dynamic>());
      default:
        throw UnsupportedError("Unrecognized JSON message");
    }
  }

  /// Returns the locally cached push token
  Future<String?> getToken() async {
    return await _channel.invokeMethod<String>('getToken');
  }

  /// Prompts the user for notification permissions the first time
  /// it is called.
  Future<void> requestNotificationPermissions(
      [NotificationSettings iosSettings = const NotificationSettings()]) async {
    _channel.invokeMethod<void>(
        'requestNotificationPermissions', iosSettings.toMap());
  }

  /// Schedules the local [notification] for immediate presentation.
  Future<void> presentLocalNotification(LocalNotification notification) async {
    await _channel.invokeMethod<void>(
        'presentLocalNotification', notification.toMap());
  }
}
