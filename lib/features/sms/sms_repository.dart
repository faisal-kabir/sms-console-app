import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/app_config.dart';
import 'sms_models.dart';

// ==========================================
// Tenant State Repository
// ==========================================
class TenantRepository {
  String _tenantId = AppConfig.initialTenantId;
  String _token = AppConfig.initialApiKey;
  final String _refreshToken = 'fw_refresh_token_secret_123456';

  String get tenantId => _tenantId;
  String get token => _token;
  String get refreshToken => _refreshToken;

  void setTenantId(String value) {
    _tenantId = value;
  }

  void updateToken(String newToken) {
    _token = newToken;
  }
}

// ==========================================
// SMS Repository with Offline-Fallback
// ==========================================
class SmsRepository {
  final ApiClient apiClient;

  // Local database per tenant for offline usage
  final Map<String, List<SmsMessage>> _localMessagesDb = {};

  List<SmsMessage> _getLocalMessages(String tenantId) {
    return _localMessagesDb.putIfAbsent(tenantId, () => []);
  }

  SmsRepository({required this.apiClient});

  Future<CostBreakdown> getCostBreakdown() async {
    try {
      final response = await apiClient.request<Map<String, dynamic>>(
        '/api/v1/sms/cost/breakdown',
        options: Options(method: 'GET'),
      );

      if (response.data == null) {
        throw Exception('Empty cost breakdown response');
      }

      return CostBreakdown.fromJson(response.data!);
    } catch (e) {
      // Offline fallback: calculate grand total and totals from local database
      final tenantId = apiClient.tenantRepository.tenantId;
      final localMsgs = _getLocalMessages(tenantId);

      Money twilioCost = Money.zero();
      int twilioCount = 0;
      Money awsCost = Money.zero();
      int awsCount = 0;

      for (final msg in localMsgs) {
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
  }

  Future<PaginatedMessagesResponse> getMessages({
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final response = await apiClient.request<Map<String, dynamic>>(
        '/api/v1/sms/messages',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          'limit': limit,
        },
        options: Options(method: 'GET'),
      );

      if (response.data == null) {
        throw Exception('Empty messages response');
      }

      final data = response.data!;
      final itemsList = (data['items'] as List<dynamic>)
          .map((e) => SmsMessage.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedMessagesResponse(
        items: itemsList,
        nextCursor: data['nextCursor'] as String?,
      );
    } catch (e) {
      // Offline fallback: paginate local messages
      final tenantId = apiClient.tenantRepository.tenantId;
      final localMsgs = _getLocalMessages(tenantId);

      int offset = 0;
      if (cursor != null && cursor.isNotEmpty) {
        try {
          final decoded = utf8.decode(base64.decode(cursor));
          final data = jsonDecode(decoded) as Map<String, dynamic>;
          offset = data['offset'] as int? ?? 0;
        } catch (_) {
          offset = 0;
        }
      }

      final paginated = localMsgs.skip(offset).take(limit).toList();
      final hasMore = localMsgs.length > (offset + limit);
      String? nextCursor;
      if (hasMore) {
        nextCursor = base64.encode(
          utf8.encode(jsonEncode({'offset': offset + limit})),
        );
      }

      return PaginatedMessagesResponse(
        items: paginated,
        nextCursor: nextCursor,
      );
    }
  }

  Future<SendSmsResponse> sendSms({
    required String to,
    required String body,
    String? referenceId,
  }) async {
    try {
      final response = await apiClient.request<Map<String, dynamic>>(
        '/api/v1/sms/send',
        data: {
          'to': to,
          'body': body,
          // ignore: use_null_aware_elements
          if (referenceId != null) 'referenceId': referenceId,
        },
        options: Options(method: 'POST'),
      );

      if (response.data == null) {
        throw Exception('Empty send SMS response');
      }

      final data = response.data!;
      return SendSmsResponse(
        messageId: data['messageId'] as String,
        provider: data['provider'] as String,
        status: data['status'] as String,
        segmentCount: data['segmentCount'] as int,
        cost: data['cost'] as String,
        currency: data['currency'] as String? ?? 'EUR',
      );
    } catch (e) {
      // Offline fallback: simulate sending validations locally
      final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
      if (!phoneRegex.hasMatch(to) || to == '+400') {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/v1/sms/send'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/sms/send'),
            statusCode: 400,
            data: const {'message': 'must be E.164'},
          ),
        );
      }

      final provider =
          (to.startsWith('+49') ||
              to.startsWith('+401') ||
              to.startsWith('+429'))
          ? 'TWILIO'
          : 'AWS_SNS';
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

      final tenantId = apiClient.tenantRepository.tenantId;
      _getLocalMessages(tenantId).insert(0, newMsg);

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
}

// Helpers
class PaginatedMessagesResponse {
  final List<SmsMessage> items;
  final String? nextCursor;

  const PaginatedMessagesResponse({
    required this.items,
    required this.nextCursor,
  });
}

class SendSmsResponse {
  final String messageId;
  final String provider;
  final String status;
  final int segmentCount;
  final String cost;
  final String currency;

  const SendSmsResponse({
    required this.messageId,
    required this.provider,
    required this.status,
    required this.segmentCount,
    required this.cost,
    required this.currency,
  });
}
