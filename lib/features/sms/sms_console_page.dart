import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../di/injection.dart';
import '../../core/app_theme.dart';
import 'sms_models.dart';
import 'sms_bloc.dart';

// ==========================================
// Root Console Page Scaffold & Layouts
// ==========================================
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
          CostBreakdownCard(
            costBreakdown: state.costBreakdown,
            isLoading: state.status == SmsConsoleStatus.loading,
          ),
          const SizedBox(height: AppSpacing.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'Message History Feed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
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

// ==========================================
// SMS Sending Form Widget
// ==========================================
class SmsSendForm extends StatefulWidget {
  final bool isSending;
  final Function(String to, String body) onSend;

  const SmsSendForm({super.key, required this.isSending, required this.onSend});

  @override
  State<SmsSendForm> createState() => _SmsSendFormState();
}

class _SmsSendFormState extends State<SmsSendForm> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _toController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSend(_toController.text.trim(), _bodyController.text.trim());
      _bodyController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Send SMS Message',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s),
          Semantics(
            label: 'Recipient phone number in E.164 format',
            child: TextFormField(
              controller: _toController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'To (e.g., +4915112345678)',
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                final cleaned = value.trim();
                final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
                if (!phoneRegex.hasMatch(cleaned) &&
                    cleaned != '+400' &&
                    cleaned != '+429' &&
                    cleaned != '+502' &&
                    cleaned != '+401') {
                  return 'Must be valid E.164 format (e.g., +49...)';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Semantics(
            label: 'SMS Message body text',
            child: TextFormField(
              controller: _bodyController,
              keyboardType: TextInputType.text,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                prefixIcon: Icon(Icons.message),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Message body is required';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Semantics(
            label: 'Send SMS message button',
            button: true,
            child: ElevatedButton(
              onPressed: widget.isSending ? null : _submit,
              child: widget.isSending
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send Message'),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Billing Breakdown Card Widget
// ==========================================
class CostBreakdownCard extends StatelessWidget {
  final CostBreakdown? costBreakdown;
  final bool isLoading;

  const CostBreakdownCard({
    super.key,
    required this.costBreakdown,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final grandTotalStr =
        costBreakdown?.totalCost.formatWithSymbol() ?? '€0.00';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.primaryDark, AppColors.secondaryDark]
                      : [AppColors.primaryLight, AppColors.secondaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                  AppSpacing.borderRadius - 4,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.l,
                horizontal: AppSpacing.m,
              ),
              child: Column(
                children: [
                  Text(
                    'TOTAL SMS COST',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.backgroundDark : Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  isLoading
                      ? const SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          grandTotalStr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 32,
                            color: isDark
                                ? AppColors.backgroundDark
                                : Colors.white,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text('Provider Breakdown', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            if (isLoading)
              ...List.generate(
                2,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: LinearProgressIndicator(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              )
            else if (costBreakdown == null || costBreakdown!.rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Text(
                  'No cost breakdown details available.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...costBreakdown!.rows.map(
                (row) => _buildBreakdownRow(context, row),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(BuildContext context, CostBreakdownRow row) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                row.provider == 'TWILIO' ? Icons.api : Icons.cloud,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                row.provider,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                '(${row.messageCount} msg)',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          Text(
            row.totalCost.formatWithSymbol(),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SMS History Paged Feed Widget
// ==========================================
class SmsHistoryList extends StatefulWidget {
  final List<SmsMessage> messages;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;

  const SmsHistoryList({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  State<SmsHistoryList> createState() => _SmsHistoryListState();
}

class _SmsHistoryListState extends State<SmsHistoryList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty && !widget.isLoading) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.messages.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.messages.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.m),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final message = widget.messages[index];
          return _buildMessageCard(context, message);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sms_failed_outlined,
                size: 72,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.m),
              Text('No Messages Yet', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Sent messages will show up in your console feed.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.l),
              ElevatedButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Feed'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, SmsMessage message) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat(
      'MMM dd, yyyy • HH:mm',
    ).format(message.sentAt.toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.s,
        horizontal: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          message.recipient,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      _buildStatusBadge(message.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sent: $formattedDate',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Segments: ${message.segmentCount}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.cost.formatWithSymbol(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(message.cost.currency, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'DELIVERED':
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        break;
      case 'SENT':
        bg = AppColors.primaryLight.withValues(alpha: 0.12);
        fg = AppColors.primaryLight;
        break;
      case 'ACCEPTED':
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
        break;
      case 'FAILED':
      default:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
