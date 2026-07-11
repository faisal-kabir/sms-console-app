import 'package:flutter_test/flutter_test.dart';
import 'package:sms_console_app/features/sms/sms_models.dart';

void main() {
  group(
    'Money Arithmetic Tests (Prevents REVIEW.md Finding 2: Floating-point precision loss)',
    () {
      test('Should parse decimal string and store micro-units exactly', () {
        final m1 = Money.parse('0.0079');
        expect(m1.microAmount, 79);
        expect(m1.toString(), '0.0079');
        expect(m1.format(), '0.01');
        expect(m1.formatWithSymbol(), '€0.01');
      });

      test(
        'Should multiply money exactly without binary floating-point drift',
        () {
          // Catching Finding 2: 0.0079 * 3 in double is 0.023700000000000002
          final m1 = Money.parse('0.0079');
          final result = m1 * 3;

          expect(result.microAmount, 237);
          expect(result.toString(), '0.0237');
        },
      );

      test('Should add money of same currency exactly', () {
        final m1 = Money.parse('1.2500');
        final m2 = Money.parse('4.2000');
        final sum = m1 + m2;

        expect(sum.microAmount, 54500);
        expect(sum.toString(), '5.4500');
        expect(sum.format(), '5.45');
        expect(sum.formatWithSymbol(), '€5.45');
      });

      test('Should throw ArgumentError when adding different currencies', () {
        final m1 = Money(100, currency: 'EUR');
        final m2 = Money(200, currency: 'USD');

        expect(() => m1 + m2, throwsArgumentError);
      });

      test('Should respect value and currency equality (Equatable)', () {
        final m1 = Money.parse('0.1500', currency: 'EUR');
        final m2 = Money.parse('0.1500', currency: 'EUR');
        final m3 = Money.parse('0.1500', currency: 'USD');
        final m4 = Money.parse('0.1600', currency: 'EUR');

        expect(m1, equals(m2));
        expect(m1, isNot(equals(m3)));
        expect(m1, isNot(equals(m4)));
      });
    },
  );
}
