# ADR 0001: State Management Choice for SMS Gateway Console

## Status
Accepted

## Context
The SMS Gateway Console is a multi-tenant client interface requiring:
1. Complete tenant isolation (switching tenants must clear all loaded states immediately without leakage).
2. Proper lifecycle handling of network queries (avoiding duplicated requests on UI rebuilds).
3. Thorough error state mapping (e.g. mapping rate-limits, validation errors, timeouts, and token refresh).
4. Full mock testability for widget and unit tests.

BLoC (`flutter_bloc`) as its state management pattern, alongside dependency injection via `get_it`.

## Decision
We choose BLoC (`flutter_bloc`) to manage the state of the SMS Console page.

## Alternatives Considered

### 1. `setState` (Vanilla Flutter)
* **Why rejected**: Vanilla state management mixes business logic with presentation layout. It makes unit testing extremely difficult, lacks standard patterns for debouncing, event filtering, or cleanly resetting states, and is highly prone to lifecycle issues (like executing state changes on unmounted widgets).

### 2. Riverpod
* **Why rejected**: Riverpod is a powerful modern state management solution, Adding a new state management package would violate the primary constraint: "Follow the existing conventions of my project... state management, folder structure, lint rules, and theming approach."

### 3. Provider / ChangeNotifier
* **Why rejected**: While Provider is lightweight, `ChangeNotifier` does not enforce structured event-to-state streams. This makes tracing complex asynchronous transitions (such as: sending SMS -> showing loader -> refreshing breakdown -> updating history) less clean and less testable than BLoC's explicit event-driven architecture.

## Rationale
Using `flutter_bloc` provides the following benefits:
1. **Repository Alignment**: Directly aligns with the conventions.
2. **Strict Event-to-State Mapping**: Every action (e.g. sending SMS, switching tenant, paging) is an explicit event, resulting in a predictable state stream. This makes debugging simple and provides trace logs.
3. **Tenant Isolation**: When switching tenants, we dispatch a `ChangeTenant` event. The BLoC handler instantly emits `SmsConsoleState.initial(newTenantId)` with a loading state, ensuring that the visual list of the previous tenant is fully unmounted and garbage collected before the new tenant's data fetches.
4. **Testability**: We can easily test all BLoC logic by pumping events and asserting state emissions, decoupled from the widget tree.
