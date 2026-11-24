/// App-wide configuration.
///
/// Set the API URL at build/run time without editing code:
///   flutter run --dart-define=API_BASE_URL=https://vpl.yourdomain.com/api
///
/// Defaults:
///  * Android emulator → http://10.0.2.2:8000/api  (your PC's localhost)
///  * Real phone on same Wi-Fi → use your PC's LAN IP, e.g. http://192.168.1.20:8000/api
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const String appName = 'VPL Player';
  static const Duration requestTimeout = Duration(seconds: 30);
}
