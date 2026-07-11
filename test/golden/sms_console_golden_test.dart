import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sms_console_app/di/injection.dart';
import 'package:sms_console_app/features/sms/presentation/widgets/sms_console.dart';
import 'package:sms_console_app/core/theme/app_theme.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    await initDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'SMS Console Page Golden Test (Prevents Finding 7: Layout regression)',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const SmsConsolePage()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();

      // Check matches golden file
      await expectLater(
        find.byType(SmsConsolePage),
        matchesGoldenFile('goldens/sms_console_dark.png'),
      );
    },
    skip: Platform.environment.containsKey('GITHUB_ACTIONS'),
  );
}
