import 'dart:convert';
import 'package:dio/dio.dart';

class MockApiInterceptor extends Interceptor {
  // Local in-memory DB per tenant for test isolation
  final Map<String, List<Map<String, dynamic>>> _messagesDb = {
    '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f': [
      {
        'messageId': 'SM0001',
        'recipient': '+4915*****11',
        'status': 'DELIVERED',
        'segmentCount': 1,
        'cost': '0.0750',
        'sentAt': '2026-07-10T10:14:22Z',
      },
      {
        'messageId': 'SM0002',
        'recipient': '+4915*****22',
        'status': 'SENT',
        'segmentCount': 2,
        'cost': '0.1500',
        'sentAt': '2026-07-10T11:15:30Z',
      },
      {
        'messageId': 'SM0003',
        'recipient': '+4915*****33',
        'status': 'ACCEPTED',
        'segmentCount': 1,
        'cost': '0.0460',
        'sentAt': '2026-07-10T12:16:45Z',
      },
    ],
    '8e2b1c3d-5f4a-7b8c-9d0e-1f2a3b4c5d6e': [
      {
        'messageId': 'SM0004',
        'recipient': '+1212*****88',
        'status': 'DELIVERED',
        'segmentCount': 3,
        'cost': '0.2250',
        'sentAt': '2026-07-10T14:20:00Z',
      },
    ],
  };

  bool _hasRefreshedToken = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    final tenantId = options.headers['X-Tenant-Id'] as String?;
    final authHeader = options.headers['Authorization'] as String?;

    // 1. Auth check
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 403,
            data: {'message': 'Missing authorization'},
          ),
        ),
      );
    }

    final token = authHeader.replaceFirst('Bearer ', '');

    // 2. Tenancy check
    if (tenantId == null || tenantId.isEmpty) {
      return handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 403,
            data: {'message': 'X-Tenant-Id header is required'},
          ),
        ),
      );
    }

    // --- Endpoint: POST /api/v1/auth/refresh ---
    if (path.endsWith('/api/v1/auth/refresh')) {
      _hasRefreshedToken = true;
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'accessToken': 'new_valid_token'},
        ),
      );
    }

    // 3. Simulated Token Expiration Check
    if (token == 'expired_token' && !_hasRefreshedToken) {
      return handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {
              'errorCode': 'TOKEN_EXPIRED',
              'message': 'Access token expired',
            },
          ),
        ),
      );
    }

    // --- Endpoint: POST /api/v1/sms/send ---
    if (path.endsWith('/api/v1/sms/send')) {
      final body = options.data as Map<String, dynamic>;
      final to = body['to'] as String;
      final msgBody = body['body'] as String;

      final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
      if (!phoneRegex.hasMatch(to) || to == '+400') {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {'message': 'must be E.164'},
            ),
          ),
        );
      }

      final provider = to.startsWith('+49') ? 'TWILIO' : 'AWS_SNS';
      final segmentCount = (msgBody.length / 160).ceil();
      final rate = provider == 'TWILIO' ? 0.0750 : 0.0460;
      final cost = (rate * segmentCount).toStringAsFixed(4);
      final messageId =
          'SM${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

      String masked = to;
      if (to.length > 7) {
        masked = '${to.substring(0, 5)}*****${to.substring(to.length - 2)}';
      }

      _messagesDb.putIfAbsent(tenantId, () => []);
      _messagesDb[tenantId]!.insert(0, {
        'messageId': messageId,
        'recipient': masked,
        'status': 'ACCEPTED',
        'segmentCount': segmentCount,
        'cost': cost,
        'sentAt': DateTime.now().toUtc().toIso8601String(),
      });

      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 202,
          data: {
            'messageId': messageId,
            'provider': provider,
            'status': 'ACCEPTED',
            'segmentCount': segmentCount,
            'cost': cost,
            'currency': 'EUR',
          },
        ),
      );
    }

    // --- Endpoint: GET /api/v1/sms/cost/breakdown ---
    if (path.endsWith('/api/v1/sms/cost/breakdown')) {
      final messages = _messagesDb[tenantId] ?? [];
      double twilioCost = 0.0;
      int twilioCount = 0;
      double awsCost = 0.0;
      int awsCount = 0;

      for (final msg in messages) {
        final costDouble = double.parse(msg['cost'] as String);
        final isTwilio = msg['recipient'].startsWith('+49') ||
            msg['recipient'].startsWith('+401') ||
            msg['recipient'].startsWith('+429');
        if (isTwilio) {
          twilioCost += costDouble;
          twilioCount++;
        } else {
          awsCost += costDouble;
          awsCount++;
        }
      }

      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'currency': 'EUR',
            'totalCost': (twilioCost + awsCost).toStringAsFixed(4),
            'rows': [
              {
                'provider': 'TWILIO',
                'totalCost': twilioCost.toStringAsFixed(4),
                'messageCount': twilioCount,
              },
              {
                'provider': 'AWS_SNS',
                'totalCost': awsCost.toStringAsFixed(4),
                'messageCount': awsCount,
              },
            ],
          },
        ),
      );
    }

    // --- Endpoint: GET /api/v1/sms/messages ---
    if (path.endsWith('/api/v1/sms/messages')) {
      final messages = _messagesDb[tenantId] ?? [];
      final queryParams = options.queryParameters;
      final cursor = queryParams['cursor'] as String?;
      final limit =
          int.tryParse(queryParams['limit']?.toString() ?? '50') ?? 50;

      int offset = 0;
      if (cursor != null && cursor.isNotEmpty) {
        try {
          final decoded = utf8.decode(base64.decode(cursor));
          final data = jsonDecode(decoded) as Map<String, dynamic>;
          offset = data['offset'] as int? ?? 0;
        } catch (_) {}
      }

      final paginated = messages.skip(offset).take(limit).toList();
      final hasMore = messages.length > (offset + limit);
      String? nextCursor;
      if (hasMore) {
        nextCursor = base64.encode(
          utf8.encode(jsonEncode({'offset': offset + limit})),
        );
      }

      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'items': paginated, 'nextCursor': nextCursor},
        ),
      );
    }

    return handler.next(options);
  }
}
