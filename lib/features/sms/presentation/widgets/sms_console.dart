import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/sms_console_bloc.dart';
import '../bloc/sms_console_event.dart';
import '../bloc/sms_console_state.dart';
import 'cost_breakdown_card.dart';
import 'sms_history_list.dart';
import 'sms_send_form.dart';

class SmsConsolePage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const SmsConsolePage({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<SmsConsolePage> createState() => _SmsConsolePageState();
}

class _SmsConsolePageState extends State<SmsConsolePage> {
  late final SmsConsoleBloc _bloc;

  // Tenant choices for the dropdown
  final List<Map<String, String>> _tenants = [
    {
      'id': '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f',
      'name': 'Acme Corp (Tenant A)',
    },
    {
      'id': '8e2b1c3d-5f4a-7b8c-9d0e-1f2a3b4c5d6e',
      'name': 'Stark Labs (Tenant B)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _bloc = getIt<SmsConsoleBloc>()..add(const FetchDashboard());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<SmsConsoleBloc, SmsConsoleState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.successMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _bloc.add(const ClearSuccess());
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.error!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () => _bloc.add(const ClearError()),
                ),
              ),
            );
            _bloc.add(const ClearError());
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'SMS Gateway Console',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              // Tenant Selector Dropdown
              BlocBuilder<SmsConsoleBloc, SmsConsoleState>(
                builder: (context, state) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    height: 38,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.tenantId,
                        dropdownColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        items: _tenants.map((t) {
                          return DropdownMenuItem<String>(
                            value: t['id'],
                            child: Text(t['name']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _bloc.add(ChangeTenant(val));
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.s),
              // Theme Toggle
              if (widget.onToggleTheme != null)
                IconButton(
                  onPressed: widget.onToggleTheme,
                  icon: Icon(
                    widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                  tooltip: 'Toggle Light/Dark Theme',
                ),
              const SizedBox(width: AppSpacing.s),
            ],
          ),
          body: BlocBuilder<SmsConsoleBloc, SmsConsoleState>(
            builder: (context, state) {
              if (state.status == SmsConsoleStatus.loading &&
                  state.costBreakdown == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == SmsConsoleStatus.error &&
                  state.costBreakdown == null) {
                return _buildErrorView(
                  context,
                  state.error ?? 'Unknown loading error',
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Breakpoint: 768px for desktop layout
                  if (constraints.maxWidth > 768) {
                    return _buildDesktopLayout(context, state);
                  } else {
                    return _buildMobileLayout(context, state);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String errorText) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.m),
            Text('Dashboard Failed to Load', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s),
            Text(
              errorText,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.l),
            ElevatedButton.icon(
              onPressed: () => _bloc.add(const FetchDashboard()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Loading'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, AppSpacing.buttonHeight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, SmsConsoleState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Send Form Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: SmsSendForm(
                isSending: state.isSending,
                onSend: (to, body) {
                  _bloc.add(SendSms(to: to, body: body));
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          // Cost Breakdown Card
          CostBreakdownCard(
            costBreakdown: state.costBreakdown,
            isLoading: state.status == SmsConsoleStatus.loading,
          ),
          const SizedBox(height: AppSpacing.m),
          // Messages Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'Message History Feed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          // Messages List inside bounded height container on mobile scroll
          SizedBox(
            height: 400,
            child: SmsHistoryList(
              messages: state.messages,
              isLoading: state.status == SmsConsoleStatus.loading,
              hasMore: state.nextCursor != null,
              onLoadMore: () => _bloc.add(const LoadMoreMessages()),
              onRefresh: () => _bloc.add(const FetchDashboard()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, SmsConsoleState state) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Send form + Cost details (fixed width sidebar)
          SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: SmsSendForm(
                        isSending: state.isSending,
                        onSend: (to, body) {
                          _bloc.add(SendSms(to: to, body: body));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  CostBreakdownCard(
                    costBreakdown: state.costBreakdown,
                    isLoading: state.status == SmsConsoleStatus.loading,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.l),
          // Right Column: Paged messages history
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xs,
                    bottom: AppSpacing.s,
                  ),
                  child: Text(
                    'SMS Message History Feed',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                ),
                Expanded(
                  child: SmsHistoryList(
                    messages: state.messages,
                    isLoading: state.status == SmsConsoleStatus.loading,
                    hasMore: state.nextCursor != null,
                    onLoadMore: () => _bloc.add(const LoadMoreMessages()),
                    onRefresh: () => _bloc.add(const FetchDashboard()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
