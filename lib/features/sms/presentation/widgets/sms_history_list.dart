import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/sms_models.dart';

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
            // Details Left Side
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
            // Cost details right side
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
