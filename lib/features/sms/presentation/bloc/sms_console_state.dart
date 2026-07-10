import 'package:equatable/equatable.dart';
import '../../data/models/sms_models.dart';

enum SmsConsoleStatus { initial, loading, success, error }

class SmsConsoleState extends Equatable {
  final SmsConsoleStatus status;
  final bool isSending;
  final String tenantId;
  final CostBreakdown? costBreakdown;
  final List<SmsMessage> messages;
  final String? nextCursor;
  final String? error;
  final String? successMessage;
  
  final bool isRateLimited;
  final int retryAfterSeconds;

  const SmsConsoleState({
    required this.status,
    required this.isSending,
    required this.tenantId,
    this.costBreakdown,
    required this.messages,
    this.nextCursor,
    this.error,
    this.successMessage,
    this.isRateLimited = false,
    this.retryAfterSeconds = 0,
  });

  factory SmsConsoleState.initial(String tenantId) {
    return SmsConsoleState(
      status: SmsConsoleStatus.initial,
      isSending: false,
      tenantId: tenantId,
      messages: const [],
    );
  }

  SmsConsoleState copyWith({
    SmsConsoleStatus? status,
    bool? isSending,
    String? tenantId,
    CostBreakdown? costBreakdown,
    List<SmsMessage>? messages,
    String? nextCursor,
    String? error,
    String? successMessage,
    bool? isRateLimited,
    int? retryAfterSeconds,
  }) {
    return SmsConsoleState(
      status: status ?? this.status,
      isSending: isSending ?? this.isSending,
      tenantId: tenantId ?? this.tenantId,
      costBreakdown: costBreakdown ?? this.costBreakdown,
      messages: messages ?? this.messages,
      nextCursor: nextCursor ?? this.nextCursor,
      error: error, // Clearable
      successMessage: successMessage, // Clearable
      isRateLimited: isRateLimited ?? this.isRateLimited,
      retryAfterSeconds: retryAfterSeconds ?? this.retryAfterSeconds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isSending,
        tenantId,
        costBreakdown,
        messages,
        nextCursor,
        error,
        successMessage,
        isRateLimited,
        retryAfterSeconds,
      ];
}
