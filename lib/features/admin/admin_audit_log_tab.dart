import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/audit_log_entry.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/formatters.dart';

// Audit log tab — lists admin actions in reverse chronological order.
class AdminAuditLogTab extends ConsumerWidget {
  const AdminAuditLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final logAsync = ref.watch(auditLogProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(auditLogProvider),
      child: logAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _EmptyState(
          colors: colors,
          textTheme: theme.textTheme,
          message: 'Could not load audit log.',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: _EmptyState(
                      colors: colors,
                      textTheme: theme.textTheme,
                      message: 'Admin actions will appear here.',
                    ),
                  ),
                );
              },
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audit log',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'History of admin actions across users and projects',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _LogEntryCard(
                      entry: entry,
                      colors: colors,
                      theme: theme,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  const _LogEntryCard({
    required this.entry,
    required this.colors,
    required this.theme,
  });

  final AuditLogEntry entry;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconForTarget(entry.targetType),
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formatAuditTimestamp(entry.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${entry.adminName} ${entry.action} ${entry.targetType} "${entry.targetName}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
            if (entry.reason != null && entry.reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Reason: ${entry.reason}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForTarget(String targetType) {
    switch (targetType) {
      case 'project':
        return Icons.folder_outlined;
      case 'user':
        return Icons.person_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.colors,
    required this.textTheme,
    required this.message,
  });

  final ColorScheme colors;
  final TextTheme textTheme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No audit log entries',
            style: textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
