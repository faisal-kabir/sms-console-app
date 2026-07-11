import 'package:equatable/equatable.dart';

// ==========================================
// Exact Decimal Currency Class (No floats)
// ==========================================
class Money extends Equatable {
  final int microAmount; // Scaled by 10,000 (e.g. 1500 micro-units = 0.1500)
  final String currency;

  const Money(this.microAmount, {this.currency = 'EUR'});

  factory Money.zero({String currency = 'EUR'}) => Money(0, currency: currency);

  factory Money.parse(String amountStr, {String currency = 'EUR'}) {
    final parts = amountStr.trim().split('.');
    if (parts.isEmpty) {
      throw FormatException('Invalid amount format: $amountStr');
    }

    int whole = int.parse(parts[0]);
    int fractional = 0;

    if (parts.length > 1) {
      String fracStr = parts[1];
      if (fracStr.length > 4) {
        fracStr = fracStr.substring(0, 4);
      } else {
        fracStr = fracStr.padRight(4, '0');
      }
      fractional = int.parse(fracStr);
    }

    final micro = (whole * 10000) + fractional;
    return Money(micro, currency: currency);
  }

  factory Money.fromMicro(int micro, {String currency = 'EUR'}) {
    return Money(micro, currency: currency);
  }

  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Cannot add different currencies: $currency and ${other.currency}',
      );
    }
    return Money(microAmount + other.microAmount, currency: currency);
  }

  Money operator *(int count) {
    return Money(microAmount * count, currency: currency);
  }

  double toDouble() => microAmount / 10000.0;

  String format() => toDouble().toStringAsFixed(2);

  String get currencySymbol {
    if (currency == 'EUR') return '€';
    if (currency == 'USD') return '\$';
    return currency;
  }

  String formatWithSymbol() => '$currencySymbol${format()}';

  @override
  String toString() => toDouble().toStringAsFixed(4);

  @override
  List<Object?> get props => [microAmount, currency];
}

// ==========================================
// SMS Message & History Feed Models
// ==========================================
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
  List<Object?> get props => [messageId];
}

// ==========================================
// Billing & Cost Breakdown Models
// ==========================================
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

  const CostBreakdown({required this.totalCost, required this.rows});

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
