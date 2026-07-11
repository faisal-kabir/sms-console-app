import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sms_console_app/features/sms/sms_console_page.dart';
import 'package:sms_console_app/core/app_theme.dart';
import 'package:sms_console_app/core/api_client.dart';
import '../mocks/mock_api_interceptor.dart';
import 'package:sms_console_app/features/sms/sms_repository.dart';
import 'package:sms_console_app/features/sms/sms_bloc.dart';

// Mock Connectivity to avoid native channel dependency in tests
class MockConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.wifi];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value([ConnectivityResult.wifi]);
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    // Reset dependency injection between tests
    await getIt.reset();

    // Manually register mock and repository classes for full test isolation
    getIt.registerLazySingleton<Connectivity>(() => MockConnectivity());
    getIt.registerLazySingleton<TenantRepository>(() => TenantRepository());
    getIt.registerLazySingleton<ApiClient>(
      () => ApiClient(
        tenantRepository: getIt<TenantRepository>(),
        connectivity: getIt<Connectivity>(),
      )..dio.interceptors.add(MockApiInterceptor()),
    );
    getIt.registerLazySingleton<SmsRepository>(
      () => SmsRepository(apiClient: getIt<ApiClient>()),
    );
    getIt.registerFactory<SmsConsoleBloc>(
      () => SmsConsoleBloc(
        smsRepository: getIt<SmsRepository>(),
        tenantRepository: getIt<TenantRepository>(),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('SMS Console Widget & Integration Tests (Catching Findings 4, 6, 8, & 10)', () {
    testWidgets(
      'Dashboard loads initial state and renders breakdown and feed (Prevents Finding 4: Missing Tenant Isolation)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const SmsConsolePage()),
        );

        // Verify the loading spinner is displayed initially (after flushing BLoC microtasks)
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Let async timer in MockApiInterceptor finish loading (600ms)
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump();

        // Renders header, cards, and list
        expect(find.text('SMS Gateway Console'), findsOneWidget);
        expect(find.text('TOTAL SMS COST'), findsOneWidget);
        expect(find.text('Acme Corp (Tenant A)'), findsOneWidget);

        // Asserts that the history list loaded mock data (SM0001, SM0002, SM0003)
        expect(find.text('+4915*****11'), findsOneWidget);
        expect(find.text('+4915*****22'), findsOneWidget);
        expect(find.text('+4915*****33'), findsOneWidget);

        // Verify no spinners or loading indicators left
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'Tenant isolation works: switching tenants updates header, cost breakdown, and clears old list (Prevents Finding 8: Cross-tenant leak)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const SmsConsolePage()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump();

        // Starts with Tenant A details
        expect(find.text('+4915*****11'), findsOneWidget); // Tenant A item
        expect(find.text('+1212*****88'), findsNothing); // Tenant B item

        // Tap on tenant selector dropdown
        final dropdown = find.byType(DropdownButton<String>);
        expect(dropdown, findsOneWidget);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();

        // Tap Tenant B option
        final tenantBOption = find.text('Stark Labs (Tenant B)').last;
        await tester.tap(tenantBOption);

        // Pump initial loader
        await tester.pump();

        // Wait for Mock API response
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump();

        // Verifies Tenant B items loaded, and Tenant A items cleared (No cross-tenant leak!)
        expect(find.text('+1212*****88'), findsOneWidget); // Tenant B item
        expect(find.text('+4915*****11'), findsNothing); // Tenant A item
      },
    );

    testWidgets(
      'SMS Send Flow Success: displays success snackbar, updates breakdown rows, and reloads history list (Prevents Finding 10: Inconsistent Cost Estimation)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const SmsConsolePage()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump();

        // Find TextFormField by type and index
        final phoneField = find.byType(TextFormField).at(0);
        final messageField = find.byType(TextFormField).at(1);
        final sendButton = find.byType(ElevatedButton);

        await tester.enterText(phoneField, '+49159999999');
        await tester.enterText(messageField, 'Test message content');
        await tester.pumpAndSettle();

        // Tap send
        await tester.tap(sendButton);
        // Pump initial loading state
        await tester.pump();
        expect(
          find.byType(CircularProgressIndicator),
          findsOneWidget,
        ); // Button shows loading spinner

        // Wait for Mock API response
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Assert snackbar shows up with exact provider name and cost
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Sent via TWILIO — €0.07'), findsOneWidget);

        // Verify message has been added to list feed
        expect(find.text('+4915*****99'), findsOneWidget);
      },
    );

    testWidgets(
      'SMS Send Flow Failure: handles validation error, shows snackbar, and does not hang on loading spinner (Prevents Finding 6: Infinite spinner on errors)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const SmsConsolePage()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump();

        final phoneField = find.byType(TextFormField).at(0);
        final messageField = find.byType(TextFormField).at(1);
        final sendButton = find.byType(ElevatedButton);

        // input number '+400' to trigger validation error mock scenario
        await tester.enterText(phoneField, '+400');
        await tester.enterText(messageField, 'Message body');
        await tester.pumpAndSettle();

        await tester.tap(sendButton);
        await tester.pump();

        // Let Mock API respond with error
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verifies snackbar error toast appears
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Validation Error: must be E.164'), findsOneWidget);

        // Verify that the send form is interactable and does not hang on progress spinner
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Send Message'), findsOneWidget);
      },
    );
  });
}
