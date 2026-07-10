import 'package:equatable/equatable.dart';
import '../../../../core/domain/money.dart';

class SmsMessage extends Equatable {
  final String messageId;
  final String recipient;
  final String status; // ACCEPTED | SENT | DELIVERED | FAILED
  final int segmentCount;
  final Money cost;
  final DateTime sentAt;

  const SmsMessage({
    required this.messageId,
    required this.recipient,
    required this.status,
    required this.segmentCount,
    required this.cost,
    required this.sentAt,
  });

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      messageId: json['messageId'] as String,
      recipient: json['recipient'] as String,
      status: json['status'] as String,
      segmentCount: json['segmentCount'] as int,
      cost: Money.parse(json['cost'] as String),
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'recipient': recipient,
      'status': status,
      'segmentCount': segmentCount,
      'cost': cost.toString(),
      'sentAt': sentAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [messageId, recipient, status, segmentCount, cost, sentAt];
}

class CostBreakdownRow extends Equatable {
  final String provider;
  final Money totalCost;
  final int messageCount;

  const CostBreakdownRow({
    required this.provider,
    required this.totalCost,
    required this.messageCount,
  });

  factory CostBreakdownRow.fromJson(Map<String, dynamic> json) {
    return CostBreakdownRow(
      provider: json['provider'] as String,
      totalCost: Money.parse(json['totalCost'] as String),
      messageCount: json['messageCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'totalCost': totalCost.toString(),
      'messageCount': messageCount,
    };
  }

  @override
  List<Object?> get props => [provider, totalCost, messageCount];
}

class CostBreakdown extends Equatable {
  final Money totalCost;
  final List<CostBreakdownRow> rows;

  const CostBreakdown({
    required this.totalCost,
    required this.rows,
  });

  factory CostBreakdown.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as String? ?? 'EUR';
    final rowsList = (json['rows'] as List<dynamic>)
        .map((e) => CostBreakdownRow.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return CostBreakdown(
      totalCost: Money.parse(json['totalCost'] as String, currency: currency),
      rows: rowsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCost': totalCost.toString(),
      'currency': totalCost.currency,
      'rows': rows.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [totalCost, rows];
}
