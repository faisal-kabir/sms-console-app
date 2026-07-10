import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class MockApiInterceptor extends Interceptor {
  // Mock database of messages per tenant
  final Map<String, List<Map<String, dynamic>>> _messagesDb = {
    '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f': [
      // Tenant A
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
      // Tenant B
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

  // Track expired tokens for testing auth refresh flow
  bool _hasRefreshedToken = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final tenantId = options.headers['X-Tenant-Id'] as String?;
    final authHeader = options.headers['Authorization'] as String?;

    // Simulate Network Latency (short delay in tests to check spinners, normal delay in dev)
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    await Future.delayed(Duration(milliseconds: isTest ? 20 : 600));

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
    // If token is 'expired_token' and has not refreshed yet, trigger 401
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

      // Check for validation error (phone number must be E.164)
      final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
      if (!phoneRegex.hasMatch(to) || to == '+400') {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {
                'errorCode': 'INVALID_PHONE_NUMBER',
                'message': 'must be E.164',
              },
            ),
          ),
        );
      }

      // Check for Rate Limit 429
      if (to == '+429') {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 429,
              headers: Headers.fromMap({
                'Retry-After': ['5'],
              }),
              data: {
                'errorCode': 'RATE_LIMIT_EXCEEDED',
                'message': 'Too many requests',
              },
            ),
          ),
        );
      }

      // Check for Upstream Error 502
      if (to == '+502') {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 502,
              data: {
                'errorCode': 'UPSTREAM_PROVIDER_FAILED',
                'message': 'Upstream provider failed',
              },
            ),
          ),
        );
      }

      // Check for testing 401 Expired Token flow
      if (to == '+401' && token != 'new_valid_token') {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'errorCode': 'TOKEN_EXPIRED', 'message': 'Token expired'},
            ),
          ),
        );
      }

      // Successful Send
      final provider = to.startsWith('+49') ? 'TWILIO' : 'AWS_SNS';
      final segmentCount = (msgBody.length / 160).ceil();
      final rate = provider == 'TWILIO' ? 0.0750 : 0.0460;
      final cost = (rate * segmentCount).toStringAsFixed(4);

      final messageId =
          'SM${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
      final responseData = {
        'messageId': messageId,
        'provider': provider,
        'status': 'ACCEPTED',
        'segmentCount': segmentCount,
        'cost': cost,
        'currency': 'EUR',
      };

      // Mask recipient phone number (e.g. +4915112345678 -> +4915*****78)
      String masked = to;
      if (to.length > 7) {
        masked = to.substring(0, 5) + '*****' + to.substring(to.length - 2);
      }

      // Add to our mock db
      _messagesDb.putIfAbsent(tenantId, () => []);
      _messagesDb[tenantId]!.insert(0, {
        'messageId': messageId,
        'recipient': masked,
        'status': 'ACCEPTED',
        'segmentCount': segmentCount,
        'cost': cost,
        'sentAt': DateTime.now().toUtc().toIso8601String(),
      });

      // Asynchronously update status (only in non-test environments to avoid pending timers)
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        Future.delayed(const Duration(seconds: 3), () {
          if (_messagesDb[tenantId] != null &&
              _messagesDb[tenantId]!.isNotEmpty) {
            final idx = _messagesDb[tenantId]!.indexWhere(
              (m) => m['messageId'] == messageId,
            );
            if (idx != -1) {
              _messagesDb[tenantId]![idx]['status'] = 'SENT';
            }
          }
        });
        Future.delayed(const Duration(seconds: 6), () {
          if (_messagesDb[tenantId] != null &&
              _messagesDb[tenantId]!.isNotEmpty) {
            final idx = _messagesDb[tenantId]!.indexWhere(
              (m) => m['messageId'] == messageId,
            );
            if (idx != -1) {
              _messagesDb[tenantId]![idx]['status'] = 'DELIVERED';
            }
          }
        });
      }

      return handler.resolve(
        Response(requestOptions: options, statusCode: 202, data: responseData),
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
        if (msg['recipient'].startsWith('+49') ||
            (msg['recipient'].contains('*****') &&
                messages.indexOf(msg) % 2 == 0)) {
          twilioCost += costDouble;
          twilioCount++;
        } else {
          awsCost += costDouble;
          awsCount++;
        }
      }

      final totalCost = twilioCost + awsCost;

      final responseData = {
        'currency': 'EUR',
        'totalCost': totalCost.toStringAsFixed(4),
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
      };

      return handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: responseData),
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
        } catch (_) {
          offset = 0;
        }
      }

      final paginated = messages.skip(offset).take(limit).toList();
      final hasMore = messages.length > (offset + limit);
      String? nextCursor;
      if (hasMore) {
        nextCursor = base64.encode(
          utf8.encode(jsonEncode({'offset': offset + limit})),
        );
      }

      final responseData = {'items': paginated, 'nextCursor': nextCursor};

      return handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: responseData),
      );
    }

    return handler.next(options);
  }
}
