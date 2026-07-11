import 'package:flutter_test/flutter_test.dart';
import 'package:sms_console_app/features/sms/sms_models.dart';

void main() {
  group(
    'SMS Data Models JSON Parsing Tests (Prevents REVIEW.md Findings 3 & 9)',
    () {
      test(
        'Should parse CostBreakdown and decimal cost string without casting exceptions',
        () {
          // Prevents Finding 3: Server returns decimal strings for totalCost.
          // Trying to cast as double would crash.
          final mockJson = {
            'currency': 'EUR',
            'totalCost': '12.4500',
            'rows': [
              {
                'provider': 'TWILIO',
                'totalCost': '8.2500',
                'messageCount': 110,
              },
              {
                'provider': 'AWS_SNS',
                'totalCost': '4.2000',
                'messageCount': 91,
              },
            ],
          };

          final breakdown = CostBreakdown.fromJson(mockJson);

          expect(breakdown.totalCost, equals(Money.parse('12.4500')));
          expect(breakdown.rows.length, 2);
          expect(breakdown.rows[0].provider, 'TWILIO');
          expect(breakdown.rows[0].totalCost, equals(Money.parse('8.2500')));
          expect(breakdown.rows[0].messageCount, 110);
        },
      );

      test('Should parse SmsMessage with correct fields and types', () {
        // Confirms message parsing matches GET /api/v1/sms/messages shape.
        final mockMsgJson = {
          'messageId': 'SM3fa85f64',
          'recipient': '+4915*****78',
          'status': 'DELIVERED',
          'segmentCount': 2,
          'cost': '0.1500',
          'sentAt': '2026-07-09T08:14:22Z',
        };

        final message = SmsMessage.fromJson(mockMsgJson);

        expect(message.messageId, 'SM3fa85f64');
        expect(message.recipient, '+4915*****78');
        expect(message.status, 'DELIVERED');
        expect(message.segmentCount, 2);
        expect(message.cost, equals(Money.parse('0.1500')));
        expect(
          message.sentAt.toUtc(),
          DateTime.parse('2026-07-09T08:14:22Z').toUtc(),
        );
      });
    },
  );
}
