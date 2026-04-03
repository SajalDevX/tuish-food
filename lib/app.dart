import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

class TuishFoodApp extends ConsumerStatefulWidget {
  const TuishFoodApp({super.key});

  @override
  ConsumerState<TuishFoodApp> createState() => _TuishFoodAppState();
}

class _TuishFoodAppState extends ConsumerState<TuishFoodApp> {
  StreamSubscription<String>? _notificationRouteSub;
  StreamSubscription<RemoteMessage>? _messageOpenSub;

  @override
  void initState() {
    super.initState();
    _setupNotificationRouting();
  }

  void _setupNotificationRouting() {
    final notificationService = NotificationService();

    // Handle taps on local notifications (foreground)
    _notificationRouteSub =
        notificationService.onNotificationRoute.listen(_navigateToRoute);

    // Handle taps on FCM notifications that open the app from background
    _messageOpenSub =
        notificationService.onMessageOpenedApp.listen((message) {
      final route = message.data['route'] as String?;
      if (route != null && route.isNotEmpty) {
        _navigateToRoute(route);
      }
    });

    // Handle the initial message that launched the app from terminated state
    notificationService.getInitialMessage().then((message) {
      if (message != null) {
        final route = message.data['route'] as String?;
        if (route != null && route.isNotEmpty) {
          // Delay slightly so the router is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            _navigateToRoute(route);
          });
        }
      }
    });
  }

  void _navigateToRoute(String route) {
    final router = ref.read(routerProvider);
    router.go(route);
  }

  @override
  void dispose() {
    _notificationRouteSub?.cancel();
    _messageOpenSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
