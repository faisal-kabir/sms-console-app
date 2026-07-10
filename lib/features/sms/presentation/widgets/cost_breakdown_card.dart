import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/sms_models.dart';

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
            // Header Total Section with Premium Gradient
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
          // Provider info
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
              const SizedBox(width: AppSpacing.xs),
              Text(
                '(${row.messageCount} msg)',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          // Cost details
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
