import 'dart:io';

import 'package:elephant_collar/ui/home/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final fcmToken = await messaging.getToken();
  print("fcmToken: $fcmToken");
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await _requestPermissions(flutterLocalNotificationsPlugin);
  if (Platform.isAndroid) {
    _createNotificationChannel(flutterLocalNotificationsPlugin);
  }
  FirebaseMessaging.onMessage.listen(
    (event) async {
      await _firebaseMessagingForegroundHandler(
          flutterLocalNotificationsPlugin, event);
    },
  );
  FirebaseMessaging.onBackgroundMessage(
    (message) async {
      await _firebaseMessagingBackgroundHandler(
          flutterLocalNotificationsPlugin, message);
    },
  );
  runApp(
      MyApp(flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin));
}

Future<void> _requestPermissions(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  if (Platform.isIOS || Platform.isMacOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  } else if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }
}

Future<void> _createNotificationChannel(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  const channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> _firebaseMessagingForegroundHandler(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    RemoteMessage message) async {
  print("Foreground Message");
  print("Message data: ${message.data}");
  await _showNotification(flutterLocalNotificationsPlugin, message);
}

Future<void> _firebaseMessagingBackgroundHandler(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    RemoteMessage message) async {
  print("Background Message");
  print("Message data: ${message.data}");
  await _showNotification(flutterLocalNotificationsPlugin, message);
}

Future<void> _showNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    RemoteMessage message) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
          'high_importance_channel', 'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
  final android = message.notification?.android;
  NotificationDetails notificationDetails = NotificationDetails(
      android: android != null ? androidNotificationDetails : null);
  await flutterLocalNotificationsPlugin.show(0, message.data["title"] ?? "",
      message.data["body"] ?? "", notificationDetails);
}

Future<void> _showNotificationIOS(
    BuildContext context,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    int id,
    String? title,
    String? body,
    String? payload) async {
  // NotificationDetails notificationDetails =
  //     const NotificationDetails(iOS: DarwinNotificationDetails());
  // await flutterLocalNotificationsPlugin.show(
  //     id, title ?? "", body, notificationDetails);
  showDialog(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: Text(title ?? ''),
      content: Text(body ?? ''),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('OK'),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        )
      ],
    ),
  );
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const MyApp({required this.flutterLocalNotificationsPlugin, super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) {
        _showNotificationIOS(
            context, flutterLocalNotificationsPlugin, id, title, body, payload);
      },
    );
    flutterLocalNotificationsPlugin.initialize(InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin));
    return MaterialApp(
      title: 'Collar Alert',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
