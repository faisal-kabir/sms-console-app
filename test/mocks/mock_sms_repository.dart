import 'package:dio/dio.dart';
import 'package:sms_console_app/core/api_client.dart';
import 'package:sms_console_app/features/sms/sms_models.dart';
import 'package:sms_console_app/features/sms/sms_repository.dart';

class MockSmsRepository extends SmsRepository {
  // In-memory database per tenant for test isolation
  final Map<String, List<SmsMessage>> _messagesDb = {
    '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f': [
      SmsMessage(
        messageId: 'SM0001',
        recipient: '+4915*****11',
        status: 'DELIVERED',
        segmentCount: 1,
        cost: Money.parse('0.0750'),
        sentAt: DateTime.parse('2026-07-10T10:14:22Z'),
      ),
      SmsMessage(
        messageId: 'SM0002',
        recipient: '+4915*****22',
        status: 'SENT',
        segmentCount: 2,
        cost: Money.parse('0.1500'),
        sentAt: DateTime.parse('2026-07-10T11:15:30Z'),
      ),
      SmsMessage(
        messageId: 'SM0003',
        recipient: '+4915*****33',
        status: 'ACCEPTED',
        segmentCount: 1,
        cost: Money.parse('0.0460'),
        sentAt: DateTime.parse('2026-07-10T12:16:45Z'),
      ),
    ],
    '8e2b1c3d-5f4a-7b8c-9d0e-1f2a3b4c5d6e': [
      SmsMessage(
        messageId: 'SM0004',
        recipient: '+1212*****88',
        status: 'DELIVERED',
        segmentCount: 3,
        cost: Money.parse('0.2250'),
        sentAt: DateTime.parse('2026-07-10T14:20:00Z'),
      ),
    ],
  };

  MockSmsRepository(ApiClient apiClient) : super(apiClient: apiClient);

  List<SmsMessage> _getMessagesForTenant() {
    final tenantId = apiClient.tenantRepository.tenantId;
    return _messagesDb.putIfAbsent(tenantId, () => []);
  }

  @override
  Future<CostBreakdown> getCostBreakdown() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final messages = _getMessagesForTenant();
    Money twilioCost = Money.zero();
    int twilioCount = 0;
    Money awsCost = Money.zero();
    int awsCount = 0;

    for (final msg in messages) {
      final isTwilio =
          msg.recipient.startsWith('+49') ||
          msg.recipient.startsWith('+401') ||
          msg.recipient.startsWith('+429');
      if (isTwilio) {
        twilioCost = twilioCost + msg.cost;
        twilioCount++;
      } else {
        awsCost = awsCost + msg.cost;
        awsCount++;
      }
    }

    return CostBreakdown(
      totalCost: twilioCost + awsCost,
      rows: [
        CostBreakdownRow(
          provider: 'TWILIO',
          totalCost: twilioCost,
          messageCount: twilioCount,
        ),
        CostBreakdownRow(
          provider: 'AWS_SNS',
          totalCost: awsCost,
          messageCount: awsCount,
        ),
      ],
    );
  }

  @override
  Future<PaginatedMessagesResponse> getMessages({
    String? cursor,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final messages = _getMessagesForTenant();
    return PaginatedMessagesResponse(items: messages, nextCursor: null);
  }

  @override
  Future<SendSmsResponse> sendSms({
    required String to,
    required String body,
    String? referenceId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (to == '+400') {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/sms/send'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/sms/send'),
          statusCode: 400,
          data: const {'message': 'must be E.164'},
        ),
      );
    }

    final provider = to.startsWith('+49') ? 'TWILIO' : 'AWS_SNS';
    final segmentCount = (body.length / 160).ceil();
    final rate = provider == 'TWILIO' ? 0.0750 : 0.0460;
    final costStr = (rate * segmentCount).toStringAsFixed(4);
    final costMoney = Money.parse(costStr);
    final messageId =
        'SM${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

    String masked = to;
    if (to.length > 7) {
      masked = '${to.substring(0, 5)}*****${to.substring(to.length - 2)}';
    }

    final newMsg = SmsMessage(
      messageId: messageId,
      recipient: masked,
      status: 'ACCEPTED',
      segmentCount: segmentCount,
      cost: costMoney,
      sentAt: DateTime.now().toUtc(),
    );

    _getMessagesForTenant().insert(0, newMsg);

    return SendSmsResponse(
      messageId: messageId,
      provider: provider,
      status: 'ACCEPTED',
      segmentCount: segmentCount,
      cost: costStr,
      currency: 'EUR',
    );
  }
}
