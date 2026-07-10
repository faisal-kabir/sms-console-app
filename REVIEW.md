# Code Review of `starter/lib/sms_console.dart`

This document details findings from reviewing the starter codebase `sms_console.dart` against the `API-CONTRACT.md` specification.

---

### Finding 1: Hardcoded Sensitive API Credentials (Credential Leak)
* **Severity:** Critical (Real-Incident-Grade)
* **Impact:** The business loses credential secrecy. If compiled into the binary, the API key can be easily decompiled and extracted from the APK/IPA. Malicious actors can then send unauthorized messages using the business's billing account, causing massive financial loss and reputation damage.
* **Location:** Line 9:
  ```dart
  const String kApiKey = 'fw_live_8c21e0b47ad94f13ba77e0c9d51a3b62';
  ```
* **Mechanism:** The secret key is hardcoded directly as a compile-time string constant in the widget tree file.
* **Fix:** Move the API key to a secure build-time configuration (e.g., using `--dart-define-from-file` or environment variables) or fetch it dynamically and cache it in `flutter_secure_storage`. Do not commit keys to source control.

---

### Finding 2: Floating-Point Math for Currency Arithmetic (Precision Loss)
* **Severity:** Critical (Real-Incident-Grade)
* **Impact:** Accumulating rounding errors over thousands or millions of messages leads to direct billing discrepancies and audit failures. The invoice totals on the client will mismatch the server invoices.
* **Location:** Lines 13, 18-23, 53-56, 83-85:
  ```dart
  static double totalCost = 0.0;
  // ...
  total = total + (costRows[i]['totalCost'] as double);
  // ...
  final cost = rateFor(provider) * segments;
  ```
* **Mechanism:** The code uses `double` (IEEE 754 floating-point format) to store and calculate money. Floating-point cannot precisely represent certain decimals in binary (e.g., `0.0079 * 3` becomes `0.023700000000000002` instead of exactly `0.0237`). 
* **Fix:** Perform all currency calculations in minor/micro units using integers (e.g., scaling decimal amounts by `10000` to support up to 4 decimal places). Convert back to a display string only at the UI layer.

---

### Finding 3: Type Cast Crash on String from API Response
* **Severity:** Critical (Real-Incident-Grade)
* **Impact:** The application crashes immediately upon receiving responses from the monthly breakdown endpoint, rendering the screen completely blank or unresponsive to the user.
* **Location:** Line 55:
  ```dart
  total = total + (costRows[i]['totalCost'] as double);
  ```
* **Mechanism:** According to `API-CONTRACT.md`, the `totalCost` returned by the server is a decimal **string** (e.g. `"8.2500"`). The code tries to cast a Dart `String` to a `double` using the `as` operator, which throws a runtime `TypeError` (`_TypeError: type 'String' is not a subtype of type 'double'`).
* **Fix:** Parse the string to a scaled integer representation instead of casting it (e.g. `int.parse(costRows[i]['totalCost'].replaceAll('.', ''))` or `double.parse(...)`).

---

### Finding 4: Missing Required Tenant Isolation Header
* **Severity:** Critical (Real-Incident-Grade)
* **Impact:** All network requests fail with `403 Forbidden` in production, as the backend requires a tenant ID to scope data, making the app entirely broken for the user.
* **Location:** Lines 48, 74, 127:
  ```dart
  headers: {'Authorization': 'Bearer $kApiKey'}
  ```
* **Mechanism:** The server contract states that both `Authorization` and `X-Tenant-Id` headers are required on all requests, returning a `403` if `X-Tenant-Id` is missing or unauthorized. The starter code only sends `Authorization`.
* **Fix:** Centralize request configuration in an API client or interceptor that automatically attaches the active tenant ID header (`X-Tenant-Id`) to every outgoing request.

---

### Finding 5: Unmasked PII Logs (Data Leak)
* **Severity:** High (Real-Incident-Grade)
* **Impact:** The business suffers privacy compliance violations (e.g., GDPR, CCPA). Raw phone numbers and SMS content are leaked into system-wide logs, accessible to other apps or crash reporters.
* **Location:** Line 69:
  ```dart
  print('Sending SMS to $phone: $body');
  ```
* **Mechanism:** The code prints raw input phone numbers and message bodies directly to the console using `print()`, which writes to standard output in both debug and release builds.
* **Fix:** Remove the raw `print` statement, or mask the recipient phone number (e.g. `+4915*****78`) before logging, and use a secure logging library that disables debug logging in release builds.

---

### Finding 6: Infinite Loading Spinner on Network Failures
* **Severity:** High
* **Impact:** The app hangs on a spinner indefinitely if the user has a spotty connection or is offline. The user must force-kill the app to recover.
* **Location:** Lines 44-61, 63-96:
  ```dart
  setState(() => loading = true);
  final res = await http.get(...); // inside loadCosts()
  // ...
  setState(() => loading = false);
  ```
* **Mechanism:** The HTTP requests are executed without any `try-catch` blocks. If `http.get` throws a `SocketException` (offline) or `TimeoutException` (slow network), execution halts, the subsequent `setState(() => loading = false)` is never reached, and the loading spinner remains active forever.
* **Fix:** Wrap all asynchronous HTTP requests in `try-catch` blocks, manage connection timeouts, and make sure that `loading` is set to `false` in a `finally` block while notifying the user of the failure.

---

### Finding 7: Duplicated Network Requests and UI Re-renders via FutureBuilder
* **Severity:** High
* **Impact:** The app floods the server with duplicate API calls on every keystroke or screen repaint, degrading performance, raising cloud billing costs, and hitting rate limits quickly. If the request fails, it throws a null reference error on `snapshot.data!.body`.
* **Location:** Lines 124-147:
  ```dart
  FutureBuilder(
    future: http.get(Uri.parse('$kApiBase/api/v1/sms/cost/breakdown'), ...),
    builder: (context, snapshot) {
      // ...
      final rows = jsonDecode(snapshot.data!.body)['rows'] as List<dynamic>;
      // ...
    }
  )
  ```
* **Mechanism:** 
  1. Creating a `Future` directly in the `future:` parameter of `FutureBuilder` triggers the network call every time the widget rebuilds.
  2. If the request fails, `snapshot.data` is null, and accessing `snapshot.data!.body` throws a `NullThrownError`, resulting in a red screen of death in debug or an unhandled crash in release.
* **Fix:** Use a BLoC/Cubit to manage data fetching and lifecycle. Keep futures out of the `build` method. Handle `snapshot.hasError` or error states explicitly.

---

### Finding 8: Cross-Tenant State Leakage via Global AppState
* **Severity:** Medium
* **Impact:** Privacy violation between tenants. When switching tenants, data from the previous tenant is temporarily or permanently visible to the new tenant.
* **Location:** Lines 12-16:
  ```dart
  class AppState {
    static double totalCost = 0.0;
    static List<dynamic> history = [];
    static String? lastError;
  }
  ```
* **Mechanism:** State is saved in static variables of a global `AppState` class. These variables survive user logout or tenant switching.
* **Fix:** Use BLoC/Cubit scoped to the widget lifecycle. When a tenant is switched, dispose of the current BLoC instance and create a new one, cleanly resetting the state.

---

### Finding 9: Accessing Non-Existent Fields in Breakdown API
* **Severity:** Medium
* **Impact:** UI displays blank or "null" subtitles in the list, providing a poor user experience.
* **Location:** Line 140:
  ```dart
  subtitle: Text(rows[i]['recipient']),
  ```
* **Mechanism:** The code calls `rows[i]['recipient']` on rows loaded from `POST /api/v1/sms/cost/breakdown`. However, `API-CONTRACT.md` defines that the breakdown response rows only contain `provider`, `totalCost`, and `messageCount` fields. There is no `recipient` field in that endpoint.
* **Fix:** Populate history using the correct `GET /api/v1/sms/messages` endpoint (which returns `recipient`, `cost`, `status`, and `sentAt`), and keep the breakdown endpoint for displaying summary widgets.

---

### Finding 10: Inconsistent Local Cost Calculation & Hardcoded Segments
* **Severity:** Low
* **Impact:** Incorrect cost estimates shown to the user.
* **Location:** Lines 82-85:
  ```dart
  final segments = 1;
  final cost = rateFor(provider) * segments;
  AppState.totalCost = AppState.totalCost + cost;
  ```
* **Mechanism:** The send method assumes the segment count is always 1 and calculates costs locally using client-side hardcoded rates. An SMS can consist of multiple segments if it's long, and local rates can drift from backend config.
* **Fix:** Extract the actual `segmentCount` and `cost` directly from the backend response fields returned by the `POST /api/v1/sms/send` endpoint.
