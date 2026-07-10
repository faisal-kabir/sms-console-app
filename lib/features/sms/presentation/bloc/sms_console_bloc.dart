import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/money.dart';
import '../../data/repositories/sms_repository.dart';
import '../../data/repositories/tenant_repository.dart';
import 'sms_console_event.dart';
import 'sms_console_state.dart';

class SmsConsoleBloc extends Bloc<SmsConsoleEvent, SmsConsoleState> {
  final SmsRepository smsRepository;
  final TenantRepository tenantRepository;

  SmsConsoleBloc({required this.smsRepository, required this.tenantRepository})
    : super(SmsConsoleState.initial(tenantRepository.tenantId)) {
    on<FetchDashboard>(_onFetchDashboard);
    on<ChangeTenant>(_onChangeTenant);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendSms>(_onSendSms);
    on<ClearError>(_onClearError);
    on<ClearSuccess>(_onClearSuccess);
  }

  Future<void> _onFetchDashboard(
    FetchDashboard event,
    Emitter<SmsConsoleState> emit,
  ) async {
    emit(state.copyWith(status: SmsConsoleStatus.loading));
    try {
      final breakdown = await smsRepository.getCostBreakdown();
      final messagesRes = await smsRepository.getMessages(limit: 50);

      emit(
        state.copyWith(
          status: SmsConsoleStatus.success,
          costBreakdown: breakdown,
          messages: messagesRes.items,
          nextCursor: messagesRes.nextCursor,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SmsConsoleStatus.error, error: _parseError(e)),
      );
    }
  }

  Future<void> _onChangeTenant(
    ChangeTenant event,
    Emitter<SmsConsoleState> emit,
  ) async {
    tenantRepository.setTenantId(event.newTenantId);

    // Clear old state completely for tenant isolation
    emit(
      SmsConsoleState.initial(
        event.newTenantId,
      ).copyWith(status: SmsConsoleStatus.loading),
    );

    // Trigger fresh dashboard load
    add(const FetchDashboard());
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<SmsConsoleState> emit,
  ) async {
    if (state.nextCursor == null || state.status == SmsConsoleStatus.loading) {
      return;
    }

    try {
      final messagesRes = await smsRepository.getMessages(
        cursor: state.nextCursor,
        limit: 50,
      );

      emit(
        state.copyWith(
          messages: [...state.messages, ...messagesRes.items],
          nextCursor: messagesRes.nextCursor,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Failed to load more messages: ${_parseError(e)}',
        ),
      );
    }
  }

  Future<void> _onSendSms(SendSms event, Emitter<SmsConsoleState> emit) async {
    emit(state.copyWith(isSending: true));
    try {
      final sendRes = await smsRepository.sendSms(
        to: event.to,
        body: event.body,
      );

      // Refresh breakdown and message history
      final breakdown = await smsRepository.getCostBreakdown();
      final messagesRes = await smsRepository.getMessages(limit: 50);

      final costMoney = Money.parse(sendRes.cost, currency: sendRes.currency);

      emit(
        state.copyWith(
          isSending: false,
          costBreakdown: breakdown,
          messages: messagesRes.items,
          nextCursor: messagesRes.nextCursor,
          successMessage:
              'Sent via ${sendRes.provider} — €${costMoney.format()}',
        ),
      );
    } on DioException catch (e) {
      int retrySecs = 0;
      bool rateLimited = false;

      if (e.response?.statusCode == 429) {
        rateLimited = true;
        final retryHeader = e.response?.headers.value('Retry-After');
        retrySecs = int.tryParse(retryHeader ?? '') ?? 0;
      }

      emit(
        state.copyWith(
          isSending: false,
          error: _parseError(e),
          isRateLimited: rateLimited,
          retryAfterSeconds: retrySecs,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSending: false, error: e.toString()));
    }
  }

  void _onClearError(ClearError event, Emitter<SmsConsoleState> emit) {
    emit(
      state.copyWith(error: null, isRateLimited: false, retryAfterSeconds: 0),
    );
  }

  void _onClearSuccess(ClearSuccess event, Emitter<SmsConsoleState> emit) {
    emit(state.copyWith(successMessage: null));
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.error?.toString().contains('No internet') == true) {
        return 'No internet connection. Please verify your connection.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timeout. The server took too long to respond.';
      }
      if (e.response != null) {
        final code = e.response!.statusCode;
        final data = e.response!.data;

        if (code == 400 && data is Map) {
          final msg = data['message'] ?? 'Validation failed';
          return 'Validation Error: $msg';
        }
        if (code == 429) {
          final retry = e.response!.headers.value('Retry-After');
          return 'Rate limit exceeded. Please wait ${retry ?? "a few"} seconds before retrying.';
        }
        if (code == 502) {
          return 'Upstream provider failed. Please try again later.';
        }
        if (code == 403) {
          return 'Access Denied: Tenant not authorized.';
        }
      }
    }
    return e.toString();
  }
}
