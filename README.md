# SMS Gateway Console App (Take-Home Assignment)

A secure, multi-tenant SMS administration console built in Flutter. This application is designed to be highly responsive, accessible, and resilient.

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (3.22.x or later recommended)
* Android SDK / Xcode (for running on emulators or physical devices)

### Setup & Installation
1. Clone or navigate to the repository directory.
2. Fetch package dependencies:
   ```bash
   flutter pub get
   ```
3. Run the automated test suite to verify implementation:
   ```bash
   flutter test
   ```

### Running the Application
Launch the application on your connected simulator or web browser:
```bash
flutter run
```

---

## 🛠 Project Structure & Architecture

To keep the codebase clean, readable, and easy to explain, the project has been simplified down to **exactly 7 source files**:

### Configuration & Core Services
1. **[app_config.dart](file:///Users/faisalkabir/StudioProjects/Others/Studio%20Butterfly%20Assignment/lib/core/app_config.dart)**: Houses compile-time environment variables (`API_BASE_URL`, `API_KEY`, `TENANT_ID`) and defaults.
2. **[app_theme.dart](file:///Users/faisalkabir/StudioProjects/Others/Studio%20Butterfly%20Assignment/lib/core/app_theme.dart)**: Declares Material 3 Light/Dark color themes, responsive spacing, and standard text styles.
3. **[api_client.dart](file:///Users/faisalkabir/StudioProjects/Others/Studio%20Butterfly%20Assignment/lib/core/api_client.dart)**: Centralizes network connectivity checks, automatic header injection (`X-Tenant-Id`, `Authorization`), logging (`ApiLogInterceptor`), and single-flight `401` JWT Token Refresh retries directly inside the request loop.

### SMS Gateway Feature
4. **[sms_models.dart](file:///Users/faisalkabir/StudioProjects/Others/Studio%20Butterfly%20Assignment/lib/features/sms/sms_models.dart)**: Holds `SmsMessage`, `CostBreakdown`, and `CostBreakdownRow` data models, alongside the exact decimal arithmetic custom `Money` class.
5. **[sms_repository.dart](file:///Users/faisalkabir/StudioProjects/Others/Studio%20Butterfly%20Assignment/lib/features/sms/sms_repository.dart)**: Coordinates data operations, tenant ID caching, and implements the **offline-first local database fallback** to run locally on devices without backend connectivity.
6. **[sms_bloc.dart](file:///Users/faisalkabir/StudioProjects/Others/Studio%20Butterfly%20Assignment/lib/features/sms/sms_bloc.dart)**: Enforces Uni-directional Data Flow using the BLoC pattern (events, states, and the logic class `SmsConsoleBloc`).
7. **[sms_console_page.dart](file:///Users/faisalkabir/StudioProjects/Others/Studio%20Butterfly%20Assignment/lib/features/sms/sms_console_page.dart)**: Aggregates the root view controller and its visual sub-components (`SmsSendForm`, `CostBreakdownCard`, `SmsHistoryList`) into a single adaptive design layout.

---

## 🛡 Prevention of the 10 Code Review Findings

The implementation resolves the 10 code review findings as follows:

* **F1: Hardcoded sensitive credentials**: Extracted to secure compile-time environment parameters inside `AppConfig`.
* **F2: Floating-point math for money**: Solved by implementing exact integer micro-units arithmetic in `Money`.
* **F3: Type cast crashes on JSON data**: Safeguarded by parsing decimal strings to scaled integers inside data model maps.
* **F4: Missing tenant isolation header**: Automatic inject of `X-Tenant-Id` header on all request actions.
* **F5: Unmasked raw phone numbers**: Removed raw logs and added phone masking logic.
* **F6: Infinite spinner on connection errors**: Bounded loading state lifecycle and error catches to immediately show snackbars.
* **F7: Layout regression**: Guarded by a Golden Test suite testing Light and Dark themes.
* **F8: Cross-tenant state leakage**: Switching tenants flushes the BLoC state completely before triggering a reload.
* **F9 & F10: Money parsing / costing inconsistencies**: Handled by type-safe integer scaling logic inside the custom `Money` class.

---

## 🧪 Verification Plan

### Automated Test Coverage
* **Unit Tests**: Asserts correct arithmetic in `Money` and correct parsing of message JSON payloads.
* **Widget/Integration Tests**: Validates SMS submission success, snackbar visual cues, validation failures, and tenant selection.
* **Golden Tests**: Asserts responsive design fidelity across both Light & Dark themes.

Run tests:
```bash
flutter test
```
