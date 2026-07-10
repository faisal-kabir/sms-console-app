import 'package:equatable/equatable.dart';

class Money extends Equatable {
  final int microAmount; // Scaled by 10,000 (e.g. 1500 micro-units = 0.1500)
  final String currency;

  const Money(this.microAmount, {this.currency = 'EUR'});

  factory Money.zero({String currency = 'EUR'}) => Money(0, currency: currency);

  factory Money.parse(String amountStr, {String currency = 'EUR'}) {
    // Matches decimal-string exactly, e.g. "0.1500" -> 1500, "12.4500" -> 124500
    // We avoid standard double multiplication which can lose precision.
    // Instead, we split by '.' and reconstruct the scaled integer value.
    final parts = amountStr.trim().split('.');
    if (parts.isEmpty) {
      throw FormatException('Invalid amount format: $amountStr');
    }

    int whole = int.parse(parts[0]);
    int fractional = 0;

    if (parts.length > 1) {
      String fracStr = parts[1];
      if (fracStr.length > 4) {
        fracStr = fracStr.substring(0, 4); // Limit to 4 decimal places
      } else {
        fracStr = fracStr.padRight(
          4,
          '0',
        ); // Pad with zeros to 4 decimal places
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

  @override
  String toString() {
    final doubleVal = toDouble();
    return doubleVal.toStringAsFixed(4);
  }

  // Visual string format (e.g. 2 decimal places)
  String format() {
    final doubleVal = toDouble();
    return doubleVal.toStringAsFixed(2);
  }

  String get currencySymbol {
    if (currency == 'EUR') return '€';
    if (currency == 'USD') return '\$';
    return currency;
  }

  String formatWithSymbol() {
    return '$currencySymbol${format()}';
  }

  @override
  List<Object?> get props => [microAmount, currency];
}
