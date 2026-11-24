// Plain data models parsed from the Laravel API responses.

double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
List<String> _sl(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];

class Tournament {
  Tournament.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        name = j['name'] ?? '',
        season = j['season'] ?? '',
        title = j['title'] ?? '',
        startDate = _dt(j['registration_start_date']),
        endDate = _dt(j['registration_end_date']),
        isOpen = j['is_registration_open'] == true,
        closedReason = j['closed_reason'],
        description = j['description'],
        rules = j['rules'],
        instructions = j['instructions'],
        fee = _d(j['registration_fee']);

  final int id;
  final String name, season, title;
  final DateTime? startDate, endDate;
  final bool isOpen;
  final String? closedReason, description, rules, instructions;
  final double fee;
}

class PlayerDocument {
  PlayerDocument.fromJson(Map<String, dynamic> j)
      : type = j['type'],
        label = j['label'] ?? j['type'],
        status = j['status'] ?? 'pending',
        remarks = j['remarks'],
        url = j['url'];

  final String type, label, status, url;
  final String? remarks;
}

class Player {
  Player.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        firstName = j['first_name'] ?? '',
        surname = j['surname'] ?? '',
        fullName = j['full_name'] ?? '',
        age = j['age'] as int?,
        mobile = j['mobile'] ?? '',
        email = j['email'] ?? '',
        gender = j['gender'],
        village = j['village'],
        playingRole = j['playing_role'],
        battingStyle = j['batting_style'],
        bowlingStyle = j['bowling_style'],
        tshirtSize = j['tshirt_size'],
        missingProfileFields = _sl(j['missing_profile_fields']),
        missingDocuments = _sl(j['missing_documents']),
        documentStatus = j['document_status'] ?? 'incomplete',
        documents = (j['documents'] as List? ?? []).map((e) => PlayerDocument.fromJson(e)).toList();

  final int id;
  final String firstName, surname, fullName, mobile, email, documentStatus;
  final int? age;
  final String? gender, village, playingRole, battingStyle, bowlingStyle, tshirtSize;
  final List<String> missingProfileFields, missingDocuments;
  final List<PlayerDocument> documents;

  bool get profileComplete => missingProfileFields.isEmpty;
  bool get documentsComplete => missingDocuments.isEmpty;

  PlayerDocument? document(String type) {
    for (final d in documents) {
      if (d.type == type) return d;
    }
    return null;
  }
}

class Payment {
  Payment.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        method = j['method'] ?? 'upi',
        amount = _d(j['amount']),
        expectedAmount = _d(j['expected_amount']),
        transactionId = j['transaction_id'],
        paymentDate = _dt(j['payment_date']),
        status = j['status'] ?? '',
        statusLabel = j['status_label'] ?? '',
        adminRemarks = j['admin_remarks'],
        screenshotUrl = j['screenshot_url'],
        submittedAt = _dt(j['submitted_at']);

  final int id;
  final String method, status, statusLabel;
  final double amount, expectedAmount;
  final String? transactionId, adminRemarks, screenshotUrl;
  final DateTime? paymentDate, submittedAt;
}

class Registration {
  Registration.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        registrationNo = j['registration_no'],
        jerseyNumber = j['jersey_number'],
        jerseyName = j['jersey_name'],
        status = j['status'] ?? 'pending',
        statusLabel = j['status_label'] ?? '',
        rejectionRemarks = j['rejection_remarks'],
        paymentStatus = j['payment_status'] ?? 'payment_pending',
        paymentStatusLabel = j['payment_status_label'] ?? '',
        feeAmount = _d(j['fee_amount']),
        canSubmitPayment = j['can_submit_payment'] == true,
        isCompleted = j['is_completed'] == true,
        completedAt = _dt(j['completed_at']),
        latestPayment = j['latest_payment'] == null ? null : Payment.fromJson(j['latest_payment']);

  final int id;
  final String? registrationNo, jerseyNumber, jerseyName, rejectionRemarks;
  final String status, statusLabel, paymentStatus, paymentStatusLabel;
  final double feeAmount;
  final bool canSubmitPayment, isCompleted;
  final DateTime? completedAt;
  final Payment? latestPayment;

  bool get isRejected => status == 'rejected';
  bool get paymentInReview => paymentStatus == 'proof_submitted' || paymentStatus == 'under_verification';
}

/// Everything the home screen needs (GET /me).
class Dashboard {
  Dashboard.fromJson(Map<String, dynamic> j)
      : player = Player.fromJson(j['player']),
        tournament = j['tournament'] == null ? null : Tournament.fromJson(j['tournament']),
        registration = j['registration'] == null ? null : Registration.fromJson(j['registration']),
        unreadNotifications = (j['unread_notifications'] as int?) ?? 0;

  final Player player;
  final Tournament? tournament;
  final Registration? registration;
  final int unreadNotifications;
}

class PaymentPage {
  PaymentPage.fromJson(Map<String, dynamic> j)
      : tournamentName = j['payment']['tournament_name'] ?? '',
        playerName = j['payment']['player_name'] ?? '',
        fee = _d(j['payment']['registration_fee']),
        onlineEnabled = j['payment']['online_payment_enabled'] == true,
        qrCodeUrl = j['payment']['qr_code_url'],
        upiId = j['payment']['upi_id'],
        payeeName = j['payment']['payee_name'],
        instructions = j['payment']['instructions'],
        paymentStatus = j['payment']['payment_status'] ?? '',
        paymentStatusLabel = j['payment']['payment_status_label'] ?? '',
        canSubmit = j['payment']['can_submit_payment'] == true,
        history = (j['payments'] as List? ?? []).map((e) => Payment.fromJson(e)).toList();

  final String tournamentName, playerName, paymentStatus, paymentStatusLabel;
  final double fee;
  final bool onlineEnabled, canSubmit;
  final String? qrCodeUrl, upiId, payeeName, instructions;
  final List<Payment> history;
}

class Confirmation {
  Confirmation.fromJson(Map<String, dynamic> j)
      : registrationNo = j['registration_no'] ?? '',
        tournament = j['tournament'] ?? '',
        playerName = j['player_name'] ?? '',
        mobile = j['mobile'] ?? '',
        email = j['email'] ?? '',
        village = j['village'] ?? '',
        age = j['age'] as int?,
        gender = j['gender'],
        playingRole = j['playing_role'],
        battingStyle = j['batting_style'],
        bowlingStyle = j['bowling_style'],
        tshirtSize = j['tshirt_size'],
        jerseyNumber = j['jersey_number'],
        jerseyName = j['jersey_name'],
        feePaid = _d(j['fee_paid']),
        transactionId = j['transaction_id'],
        confirmedAt = _dt(j['confirmed_at']),
        photoUrl = j['photo_url'];

  final String registrationNo, tournament, playerName, mobile, email, village;
  final int? age;
  final String? gender, playingRole, battingStyle, bowlingStyle, tshirtSize, jerseyNumber, jerseyName, transactionId, photoUrl;
  final double feePaid;
  final DateTime? confirmedAt;
}

class AppNotification {
  AppNotification.fromJson(Map<String, dynamic> j)
      : id = j['id'].toString(),
        title = j['title'] ?? '',
        message = j['message'] ?? '',
        kind = j['kind'] ?? 'info',
        read = j['read'] == true,
        createdAt = _dt(j['created_at']);

  final String id, title, message, kind;
  final bool read;
  final DateTime? createdAt;
}

class StatusHistoryItem {
  StatusHistoryItem.fromJson(Map<String, dynamic> j)
      : type = j['type'] ?? '',
        from = j['from'],
        to = j['to'] ?? '',
        remarks = j['remarks'],
        at = _dt(j['at']);

  final String type, to;
  final String? from, remarks;
  final DateTime? at;
}
