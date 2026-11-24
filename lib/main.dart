import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'state/session.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(
    ChangeNotifierProvider(
      create: (_) => Session()..bootstrap(),
      child: const VplApp(),
    ),
  );
}

/// Used to clear pushed screens when the user logs in / out (incl. token expiry).
final navigatorKey = GlobalKey<NavigatorState>();

class VplApp extends StatelessWidget {
  const VplApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      navigatorKey: navigatorKey,
      home: const _Root(),
    );
  }
}

/// Switches between splash, login and home based on auth state.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  AuthStatus? _last;

  @override
  Widget build(BuildContext context) {
    final status = context.select<Session, AuthStatus>((s) => s.status);
    if (_last != null && _last != status) {
      // auth state changed → drop any screens pushed on top (signup, payment …)
      WidgetsBinding.instance.addPostFrameCallback((_) => navigatorKey.currentState?.popUntil((r) => r.isFirst));
    }
    _last = status;
    switch (status) {
      case AuthStatus.unknown:
        return const _Splash();
      case AuthStatus.loggedOut:
        return const LoginScreen();
      case AuthStatus.loggedIn:
        return const HomeScreen();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.pitchDeep,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 34, backgroundColor: AppColors.ball, child: Icon(Icons.sports_cricket, color: Colors.white, size: 34)),
          SizedBox(height: 18),
          CircularProgressIndicator(color: AppColors.gold),
        ]),
      ),
    );
  }
}
