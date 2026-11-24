import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/models.dart';
import '../services/player_api.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

/// Holds the logged-in player's session + latest dashboard data.
class Session extends ChangeNotifier {
  Session() {
    client.onUnauthorized = () {
      if (status == AuthStatus.loggedIn) _clearLocal();
    };
  }

  final ApiClient client = ApiClient();
  late final PlayerApi api = PlayerApi(client);
  final TokenStorage _storage = TokenStorage();

  AuthStatus status = AuthStatus.unknown;
  Dashboard? dashboard;
  String? loadError;

  Player? get player => dashboard?.player;
  Registration? get registration => dashboard?.registration;
  Tournament? get tournament => dashboard?.tournament;

  Future<void> bootstrap() async {
    final token = await _storage.read();
    if (token == null) {
      status = AuthStatus.loggedOut;
      notifyListeners();
      return;
    }
    client.token = token;
    try {
      dashboard = await api.me();
      status = AuthStatus.loggedIn;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _clearLocal(notify: false);
      } else {
        // offline: keep the token, show the error on home with retry
        status = AuthStatus.loggedIn;
        loadError = e.message;
      }
    }
    notifyListeners();
  }

  Future<void> login(String login, String password) async {
    final token = await api.login(login, password);
    await _startSession(token);
  }

  Future<void> register(Map<String, dynamic> data) async {
    final token = await api.register(data);
    await _startSession(token);
  }

  Future<void> _startSession(String token) async {
    client.token = token;
    await _storage.write(token);
    dashboard = await api.me();
    loadError = null;
    status = AuthStatus.loggedIn;
    notifyListeners();
  }

  /// Re-fetch GET /me (call after any change).
  Future<void> refresh() async {
    try {
      dashboard = await api.me();
      loadError = null;
    } on ApiException catch (e) {
      loadError = e.message;
      if (e.isUnauthorized) return;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      // ignore network errors on logout
    }
    await _clearLocal();
  }

  Future<void> _clearLocal({bool notify = true}) async {
    client.token = null;
    dashboard = null;
    status = AuthStatus.loggedOut;
    await _storage.clear();
    if (notify) notifyListeners();
  }
}
