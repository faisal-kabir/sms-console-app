import 'package:equatable/equatable.dart';

abstract class SmsConsoleEvent extends Equatable {
  const SmsConsoleEvent();

  @override
  List<Object?> get props => [];
}

class FetchDashboard extends SmsConsoleEvent {
  const FetchDashboard();
}

class ChangeTenant extends SmsConsoleEvent {
  final String newTenantId;

  const ChangeTenant(this.newTenantId);

  @override
  List<Object?> get props => [newTenantId];
}

class LoadMoreMessages extends SmsConsoleEvent {
  const LoadMoreMessages();
}

class SendSms extends SmsConsoleEvent {
  final String to;
  final String body;

  const SendSms({required this.to, required this.body});

  @override
  List<Object?> get props => [to, body];
}

class ClearError extends SmsConsoleEvent {
  const ClearError();
}

class ClearSuccess extends SmsConsoleEvent {
  const ClearSuccess();
}
