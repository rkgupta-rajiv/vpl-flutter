import '../core/api_client.dart';
import '../models/models.dart';

/// All player endpoints of the Laravel API in one place.
class PlayerApi {
  PlayerApi(this.client);

  final ApiClient client;

  // ---- public / auth ----
  Future<Tournament?> tournament() async {
    final r = await client.get('tournament');
    return r['tournament'] == null ? null : Tournament.fromJson(r['tournament']);
  }

  Future<String> register(Map<String, dynamic> data) async {
    final r = await client.post('auth/register', {...data, 'device_name': 'vpl-player-app'});
    return r['token'] as String;
  }

  Future<String> login(String login, String password) async {
    final r = await client.post('auth/login', {'login': login, 'password': password, 'device_name': 'vpl-player-app'});
    return r['token'] as String;
  }

  Future<String> forgotPassword(String email) async => (await client.post('auth/forgot-password', {'email': email}))['message'] ?? '';

  Future<String> resetPassword(String email, String otp, String password) async => (await client.post('auth/reset-password', {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': password,
      }))['message'] ??
      '';

  Future<void> logout() => client.post('auth/logout');

  Future<String> changePassword(String current, String password) async => (await client.post('auth/change-password', {
        'current_password': current,
        'password': password,
        'password_confirmation': password,
      }))['message'] ??
      '';

  // ---- player ----
  Future<Dashboard> me() async => Dashboard.fromJson(await client.get('me'));

  Future<Player> updateProfile(Map<String, dynamic> data) async => Player.fromJson((await client.put('profile', data))['player']);

  Future<Player> uploadDocument(String type, UploadFile file) async =>
      Player.fromJson((await client.multipart('documents/$type', files: {'file': file}))['player']);

  Future<Registration> joinTournament(String jerseyNumber, String jerseyName) async => Registration.fromJson(
      (await client.post('registration', {'jersey_number': jerseyNumber, 'jersey_name': jerseyName}))['registration']);

  Future<Registration> updateRegistration(String jerseyNumber, String jerseyName) async => Registration.fromJson(
      (await client.put('registration', {'jersey_number': jerseyNumber, 'jersey_name': jerseyName}))['registration']);

  Future<Registration> resubmit() async => Registration.fromJson((await client.post('registration/resubmit'))['registration']);

  Future<List<StatusHistoryItem>> history() async =>
      ((await client.get('registration/history'))['history'] as List).map((e) => StatusHistoryItem.fromJson(e)).toList();

  Future<PaymentPage> paymentPage() async => PaymentPage.fromJson(await client.get('payment'));

  Future<String> submitPayment({
    required double amount,
    required String transactionId,
    required DateTime paymentDate,
    required UploadFile screenshot,
  }) async {
    final d = paymentDate;
    final r = await client.multipart('payment', fields: {
      'amount': amount.toStringAsFixed(2),
      'transaction_id': transactionId.trim(),
      'payment_date': '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
    }, files: {
      'screenshot': screenshot
    });
    return r['message'] ?? 'Payment proof submitted.';
  }

  Future<Confirmation> confirmation() async => Confirmation.fromJson((await client.get('registration/confirmation'))['confirmation']);

  Future<List<AppNotification>> notifications() async =>
      ((await client.get('notifications'))['notifications'] as List).map((e) => AppNotification.fromJson(e)).toList();

  Future<void> markNotificationsRead() => client.post('notifications/read');
}
