import 'package:flutter_test/flutter_test.dart';
import 'package:vpl_player/core/api_exception.dart';
import 'package:vpl_player/models/models.dart';

void main() {
  test('ApiException exposes first field error', () {
    final e = ApiException('Invalid', statusCode: 422, errors: {'mobile': ['Bad mobile']});
    expect(e.fieldError('mobile'), 'Bad mobile');
    expect(e.fieldError('email'), isNull);
  });

  test('Registration parses API payload', () {
    final r = Registration.fromJson({
      'id': 1,
      'registration_no': 'VPL2-0001',
      'status': 'approved',
      'status_label': 'Approved',
      'payment_status': 'payment_approved',
      'payment_status_label': 'Payment Approved',
      'fee_amount': 500,
      'can_submit_payment': false,
      'is_completed': true,
      'latest_payment': null,
    });
    expect(r.isCompleted, isTrue);
    expect(r.feeAmount, 500.0);
    expect(r.registrationNo, 'VPL2-0001');
  });
}
