import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/activity_log_entry.dart';
import '../../core/models/project_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../projects/add_edit_project_screen.dart';
import '../projects/project_detail_screen.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _deleteProject(BuildContext context, WidgetRef ref, ProjectModel project) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete project?',
      content: 'This will permanently remove "${project.name}". This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) return;

    await ref.read(projectRepositoryProvider).deleteProject(project.projectId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${project.name}" deleted.')),
      );
    }
  }

  void _openProject(BuildContext context, ProjectModel project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: project.projectId),
      ),
    );
  }

  void _editProject(BuildContext context, ProjectModel project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditProjectScreen(projectId: project.projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final projectsAsync = ref.watch(currentUserProjectsProvider);

    return projectsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text(
            'Could not load dashboard.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      data: (projects) {
        final totalViews = projects.fold(0, (sum, p) => sum + p.viewCount);
        final totalSaves = projects.fold(0, (sum, p) => sum + p.saveCount);

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            title: const Text('Dashboard'),
            backgroundColor: colors.surface,
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditProjectScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add project'),
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overview',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Projects',
                                value: '${projects.length}',
                                icon: Icons.folder_outlined,
                                colors: colors,
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Views',
                                value: '$totalViews',
                                icon: Icons.visibility_outlined,
                                colors: colors,
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Saves',
                                value: '$totalSaves',
                                icon: Icons.bookmark_outline,
                                colors: colors,
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'My Projects',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (projects.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.folder_outlined,
                      title: 'No published projects yet',
                      message: 'Tap the button below to list your first project.',
                      action: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddEditProjectScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add project'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final project = projects[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DashboardProjectTile(
                              project: project,
                              onTap: () => _openProject(context, project),
                              onEdit: () => _editProject(context, project),
                              onDelete: () => _deleteProject(context, ref, project),
                            ),
                          );
                        },
                        childCount: projects.length,
                      ),
                    ),
                  ),
                if (projects.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 88),
                  ),
                _buildRecentActivity(context, ref),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return const SizedBox.shrink();

    final activityAsync = ref.watch(userActivityProvider(uid));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return activityAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        )),
      ),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (entries) {
        if (entries.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...entries.take(10).map((entry) => _ActivityRow(entry: entry)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final ActivityLogEntry entry;

  String _actionLabel() {
    final projectName = entry.metadata['projectName'] as String?;
    final suffix = projectName != null ? ' "$projectName"' : '';
    switch (entry.action) {
      case ActivityAction.login:
        return 'Logged in';
      case ActivityAction.projectPublished:
        return 'Published project$suffix';
      case ActivityAction.projectEdited:
        return 'Edited project$suffix';
      case ActivityAction.projectSaved:
        return 'Saved project$suffix';
      case ActivityAction.projectUnsaved:
        return 'Removed project$suffix';
      case ActivityAction.profileUpdated:
        return 'Updated profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(_iconForAction(entry.action), color: colors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _actionLabel(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
            Text(
              formatAuditTimestamp(entry.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForAction(ActivityAction action) {
    switch (action) {
      case ActivityAction.login:
        return Icons.login_outlined;
      case ActivityAction.projectPublished:
      case ActivityAction.projectEdited:
        return Icons.folder_outlined;
      case ActivityAction.projectSaved:
        return Icons.bookmark_outlined;
      case ActivityAction.projectUnsaved:
        return Icons.bookmark_border_outlined;
      case ActivityAction.profileUpdated:
        return Icons.person_outlined;
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
    required this.theme,
  });

  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardProjectTile extends StatelessWidget {
  const _DashboardProjectTile({
    required this.project,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: project.logoUrl.isNotEmpty
                    ? AppNetworkImage(
                        url: project.logoUrl,
                        borderRadius: BorderRadius.circular(12),
                        errorWidget: Icon(
                          Icons.folder_outlined,
                          color: colors.onPrimaryContainer,
                        ),
                      )
                    : Icon(
                        Icons.folder_outlined,
                        color: colors.onPrimaryContainer,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.tagline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(project.category.label),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colors.error),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
