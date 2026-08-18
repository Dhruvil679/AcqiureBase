import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/audit_log_entry.dart';
import '../../core/models/project_model.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';

// Admin overview tab — platform stats with `fl_chart` visualizations for users,
// projects, categories, and statuses, plus recent audit activity.
class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  static const int _chartDays = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final usersAsync = ref.watch(allUsersProvider);
    final projectsAsync = ref.watch(projectsByStatusProvider('all'));
    final auditAsync = ref.watch(auditLogProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load users',
        message: '$error',
      ),
      data: (users) => projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load projects',
          message: '$error',
        ),
        data: (projects) {
          final totalUsers = users.length;
          final totalProjects = projects.length;
          final pending = projects.where((p) => p.status == 'pending').length;
          final approved = projects.where((p) => p.status == 'approved').length;
          final rejected = projects.where((p) => p.status == 'rejected').length;
          final featured = projects.where((p) => p.status == 'approved' && p.isFeatured).length;
          final suspended = users.where((u) => u.isSuspended).length;
          final newUsersThisWeek = users.where((u) => _isWithinDays(u.createdAt, 7)).length;
          final newProjectsThisWeek = projects.where((p) => _isWithinDays(p.createdAt, 7)).length;
          final categoryCounts = _countByCategory(projects);
          final statusCounts = _countByStatus(projects);
          final recentActivity = auditAsync.valueOrNull?.take(10).toList() ?? [];

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Overview of platform activity',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isWide ? 1.45 : 1.3,
                      children: [
                        _MetricCard(label: 'Total Users', value: '$totalUsers'),
                        _MetricCard(label: 'Total Projects', value: '$totalProjects'),
                        _MetricCard(label: 'Pending', value: '$pending'),
                        _MetricCard(label: 'Approved', value: '$approved'),
                        _MetricCard(label: 'Rejected', value: '$rejected'),
                        _MetricCard(label: 'Featured', value: '$featured'),
                        _MetricCard(label: 'Suspended', value: '$suspended'),
                        _MetricCard(label: 'New Users (7d)', value: '$newUsersThisWeek'),
                        _MetricCard(label: 'New Projects (7d)', value: '$newProjectsThisWeek'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _LineChartCard(
                              title: 'New users (last 30 days)',
                              data: _dailyCounts(users.map((u) => u.createdAt).whereType<DateTime>().toList()),
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _LineChartCard(
                              title: 'New project submissions (last 30 days)',
                              data: _dailyCounts(projects.map((p) => p.createdAt).whereType<DateTime>().toList()),
                              color: colors.tertiary,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _LineChartCard(
                            title: 'New users (last 30 days)',
                            data: _dailyCounts(users.map((u) => u.createdAt).whereType<DateTime>().toList()),
                            color: colors.primary,
                          ),
                          const SizedBox(height: 16),
                          _LineChartCard(
                            title: 'New project submissions (last 30 days)',
                            data: _dailyCounts(projects.map((p) => p.createdAt).whereType<DateTime>().toList()),
                            color: colors.tertiary,
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PieChartCard(
                              title: 'Projects by category',
                              data: categoryCounts,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PieChartCard(
                              title: 'Projects by status',
                              data: statusCounts,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PieChartCard(
                            title: 'Projects by category',
                            data: categoryCounts,
                          ),
                          const SizedBox(height: 16),
                          _PieChartCard(
                            title: 'Projects by status',
                            data: statusCounts,
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),
                    Text(
                      'Recent activity',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RecentActivityList(entries: recentActivity, colors: colors, theme: theme),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isWithinDays(DateTime? date, int days) {
    if (date == null) return false;
    return date.isAfter(DateTime.now().subtract(Duration(days: days)));
  }

  Map<ProjectCategory, int> _countByCategory(List<ProjectModel> projects) {
    final counts = <ProjectCategory, int>{};
    for (final category in ProjectCategory.values) {
      counts[category] = 0;
    }
    for (final project in projects) {
      counts[project.category] = (counts[project.category] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _countByStatus(List<ProjectModel> projects) {
    final counts = <String, int>{'pending': 0, 'approved': 0, 'rejected': 0};
    for (final project in projects) {
      counts[project.status] = (counts[project.status] ?? 0) + 1;
    }
    return counts;
  }

  List<int> _dailyCounts(List<DateTime> dates) {
    final now = DateTime.now();
    final counts = List<int>.filled(_chartDays, 0);
    for (var i = 0; i < _chartDays; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: _chartDays - 1 - i));
      counts[i] = dates.where((d) {
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).length;
    }
    return counts;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  const _LineChartCard({
    required this.title,
    required this.data,
    required this.color,
  });

  final String title;
  final List<int> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final maxY = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    final topY = maxY < 1 ? 1.0 : (maxY * 1.2).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: data.every((v) => v == 0)
                  ? Center(
                      child: Text(
                        'No data for this period',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: topY > 0 ? topY / 4 : 1,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: colors.outlineVariant,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: topY > 0 ? topY / 4 : 1,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: (data.length / 5).ceilToDouble().clamp(1, double.infinity),
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                                final day = DateTime.now().subtract(
                                  Duration(days: data.length - 1 - index),
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${day.month}/${day.day}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (data.length - 1).toDouble(),
                        minY: 0,
                        maxY: topY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              data.length,
                              (i) => FlSpot(i.toDouble(), data[i].toDouble()),
                            ),
                            color: color,
                            barWidth: 3,
                            isCurved: true,
                            preventCurveOverShooting: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: color.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => colors.inverseSurface,
                            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                              final day = DateTime.now().subtract(
                                Duration(days: data.length - 1 - spot.x.toInt()),
                              );
                              return LineTooltipItem(
                                '${data[spot.x.toInt()]} on ${day.month}/${day.day}',
                                TextStyle(color: colors.onInverseSurface, fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  const _PieChartCard({required this.title, required this.data});

  final String title;
  final Map<dynamic, int> data;

  List<Color> _palette(ColorScheme colors) => [
    colors.primary,
    colors.secondary,
    colors.tertiary,
    colors.error,
    colors.primaryContainer,
    colors.secondaryContainer,
    colors.tertiaryContainer,
    colors.outlineVariant,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = _palette(colors);
    final entries = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: total == 0
                  ? Center(
                      child: Text(
                        'No data available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: entries.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final percent = total == 0 ? 0.0 : item.value / total;
                                return PieChartSectionData(
                                  color: palette[index % palette.length],
                                  value: item.value.toDouble(),
                                  title: '${(percent * 100).toStringAsFixed(0)}%',
                                  radius: 60,
                                  titleStyle: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.surface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: entries.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final label = item.key is ProjectCategory
                                ? (item.key as ProjectCategory).label
                                : item.key.toString();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: palette[index % palette.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$label (${item.value})',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({
    required this.entries,
    required this.colors,
    required this.theme,
  });

  final List<AuditLogEntry> entries;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.history_outlined,
        title: 'No activity yet',
        message: 'Admin actions will show up here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: entries.map((entry) {
        final reason = entry.reason;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatAuditTimestamp(entry.timestamp)} — ${entry.adminName} ${entry.action} ${entry.targetType} "${entry.targetName}"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: $reason',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
