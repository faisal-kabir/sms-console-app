# ADR 0001: State Management, Dependency Injection, and Decimal Arithmetic

## Status
Approved

## Context
The SMS Console application requires a robust state management system to handle asynchronous flows (loading, sending, errors, multi-tenant state switching) while maintaining high testability. Additionally, the backend returns decimal numbers for cost rates and costs as strings (e.g., `'0.0750'`, `'0.2250'`). Representing these costs as floating-point `double` types introduces binary floating-point rounding errors (e.g., `0.1 + 0.2 != 0.3`), which is unacceptable for billing and financial auditing.

Furthermore, we need a clean, decoupling mechanism for dependency injection to mock network clients and repositories during unit and integration tests.

## Decision
We decided to adopt:
1. **BLoC (Business Logic Component)** for state management.
2. **GetIt** for Service Location / Dependency Injection.
3. A **Custom `Money` Class** using integer micro-units (`1 unit = 0.0001 EUR/USD`) for exact decimal arithmetic instead of `double` or importing heavy external packages.

---

## State Management: BLoC vs. Alternatives

### Riverpod / Provider
* **Riverpod** is a highly capable state management framework, but introducing it would require adding new dependencies not standard to the project root and rewriting test patterns.
* **Provider** with `ChangeNotifier` is lightweight but can result in mutable state leakage if not structured carefully.

### Chosen: BLoC (Business Logic Component)
* **Rationale**: BLoC enforces a strict unidirectional data flow and clean separation of concerns. The UI fires events (e.g., `FetchDashboard`, `SendSms`, `SwitchTenant`) and BLoC emits immutable states (`SmsConsoleState`).
* **Consequences**: Makes the application highly predictable. We can test 100% of business logic by writing standard Dart unit tests on the BLoC without inflating widget bindings.

---

## Service Location: GetIt vs. Manual Injection

### Manual Constructor Injection
* **Rejected**: Passing repositories and clients through multiple layout layers (prop-drilling) creates messy widget constructors and complicates stateful page instantiation.

### Chosen: GetIt
* **Rationale**: Registered as a central service locator, initialized once on startup in `lib/di/injection.dart`.
* **Consequences**: Enables clean, lazy-loaded singletons. In tests, we can call `getIt.reset()` and register mock instances of `Connectivity`, `ApiClient`, and `SmsRepository` to isolate widget tests from real HTTP activity.

---

## Decimal Arithmetic: Custom `Money` vs. Alternatives

### Floating Point `double`
* **Rejected**: `double` has precision limitations. For instance, `0.0750 * 3` in double results in `0.22500000000000003`, leading to inconsistent cost estimations and accounting discrepancies.

### Heavy External `decimal` or `money2` Packages
* **Rejected**: To maintain a lean dependency tree and ensure total compliance with take-home constraints, introducing heavy packages for a single dashboard representation is over-engineering.

### Chosen: Custom `Money` Class (Micro-units representation)
* **Rationale**: The `Money` class represents currency amounts internally as a 64-bit integer of micro-units (`10,000 micro-units = 1.0000 main unit`). This completely eliminates rounding errors.
* **Consequences**:
  * **Addition, multiplication, and formatting** are 100% precise.
  * Extensible and keeps the runtime memory footprint exceptionally low.
  * Easily parsed from backend strings and formatted to the standard localized forms.
