import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/sms_models.dart';

class SmsRepository {
  final ApiClient apiClient;

  SmsRepository({required this.apiClient});

  Future<CostBreakdown> getCostBreakdown() async {
    final response = await apiClient.request<Map<String, dynamic>>(
      '/api/v1/sms/cost/breakdown',
      options: ApiClientOptions.getOptions(),
    );

    if (response.data == null) {
      throw Exception('Empty cost breakdown response');
    }

    return CostBreakdown.fromJson(response.data!);
  }

  Future<PaginatedMessagesResponse> getMessages({
    String? cursor,
    int limit = 50,
  }) async {
    final response = await apiClient.request<Map<String, dynamic>>(
      '/api/v1/sms/messages',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': limit,
      },
      options: ApiClientOptions.getOptions(),
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
  }

  Future<SendSmsResponse> sendSms({
    required String to,
    required String body,
    String? referenceId,
  }) async {
    final response = await apiClient.request<Map<String, dynamic>>(
      '/api/v1/sms/send',
      data: {
        'to': to,
        'body': body,
        // ignore: use_null_aware_elements
        if (referenceId != null) 'referenceId': referenceId,
      },
      options: ApiClientOptions.postOptions(),
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
  }
}

// Helpers for options
class ApiClientOptions {
  static Options getOptions() => Options(method: 'GET');
  static Options postOptions() => Options(method: 'POST');
}

// Model wrapper for paginated messages response
class PaginatedMessagesResponse {
  final List<SmsMessage> items;
  final String? nextCursor;

  const PaginatedMessagesResponse({
    required this.items,
    required this.nextCursor,
  });
}

// Model wrapper for send SMS response
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
