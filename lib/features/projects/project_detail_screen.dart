import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/activity_log_entry.dart';
import '../../core/models/project_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../profile/public_profile_screen.dart';
import 'add_edit_project_screen.dart';

// Project detail page. Shows different actions depending on whether you're the
// owner or an admin.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.adminView = false,
  });

  final String projectId;
  final bool adminView;

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectRepositoryProvider).incrementViewCount(widget.projectId);
    });
  }

  Future<void> _deleteProject(ProjectModel project) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete project?',
      content: 'This will permanently remove "${project.name}". This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    await ref.read(projectRepositoryProvider).deleteProject(project.projectId);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${project.name}" deleted.')),
    );
  }

  Future<String?> _showReasonDialog(String title) async {
    final controller = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'e.g. Violates guidelines',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }

  Future<void> _notifyOwner(ProjectModel project, String status) async {
    await ref.read(notificationRepositoryProvider).notifyProjectStatus(
          userId: project.ownerId,
          projectId: project.projectId,
          projectName: project.name,
          status: status,
        );
  }

  Future<void> _approve(ProjectModel project) async {
    await ref
        .read(projectRepositoryProvider)
        .updateProjectStatus(projectId: project.projectId, status: 'approved');
    await _notifyOwner(project, 'approved');
    _showMessage('"${project.name}" approved.');
  }

  Future<void> _reject(ProjectModel project) async {
    final reason = await _showReasonDialog('Reject "${project.name}"?');
    if (reason == null || !mounted) return;
    await ref
        .read(projectRepositoryProvider)
        .updateProjectStatus(projectId: project.projectId, status: 'rejected');
    await _notifyOwner(project, 'rejected');
    _showMessage('"${project.name}" rejected.');
  }

  Future<void> _reapprove(ProjectModel project) async {
    await ref
        .read(projectRepositoryProvider)
        .updateProjectStatus(projectId: project.projectId, status: 'approved');
    await _notifyOwner(project, 'approved');
    _showMessage('"${project.name}" re-approved.');
  }

  Future<void> _feature(ProjectModel project) async {
    await ref
        .read(projectRepositoryProvider)
        .setFeatured(projectId: project.projectId, isFeatured: true);
    _showMessage('"${project.name}" featured.');
  }

  Future<void> _unfeature(ProjectModel project) async {
    await ref
        .read(projectRepositoryProvider)
        .setFeatured(projectId: project.projectId, isFeatured: false);
    _showMessage('"${project.name}" unfeatured.');
  }

  Future<void> _remove(ProjectModel project) async {
    final reason = await _showReasonDialog('Remove "${project.name}"?');
    if (reason == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove project?'),
        content: Text('This will hide "${project.name}" from public view.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref
        .read(projectRepositoryProvider)
        .updateProjectStatus(projectId: project.projectId, status: 'removed');
    await _notifyOwner(project, 'removed');
    _showMessage('"${project.name}" removed.');
  }

  Future<void> _restore(ProjectModel project) async {
    await ref
        .read(projectRepositoryProvider)
        .updateProjectStatus(projectId: project.projectId, status: 'approved');
    await _notifyOwner(project, 'approved');
    _showMessage('"${project.name}" restored.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme.isEmpty) {
      _showMessage('Invalid link.');
      return;
    }
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showMessage('Could not open link.');
      }
    } catch (e) {
      _showMessage('Could not open link: $e');
    }
  }

  Future<void> _toggleSave(ProjectModel project) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    await ref
        .read(savedProjectRepositoryProvider)
        .toggleSave(uid, project.projectId);

    final isSaved = ref.read(savedProjectIdsProvider).valueOrNull?.
            contains(project.projectId) ??
        false;

    await ref.read(activityLogRepositoryProvider).log(
          uid: uid,
          action: isSaved ? ActivityAction.projectSaved : ActivityAction.projectUnsaved,
          metadata: {
            'projectId': project.projectId,
            'projectName': project.name,
          },
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved ? 'Saved "${project.name}"' : 'Removed "${project.name}"'),
      ),
    );
  }

  List<Widget> _buildAdminActions(ProjectModel project) {
    switch (project.status) {
      case 'pending':
        return [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _reject(project),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _approve(project),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Approve'),
            ),
          ),
        ];
      case 'approved':
        return [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _remove(project),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: project.isFeatured ? () => _unfeature(project) : () => _feature(project),
              icon: Icon(project.isFeatured ? Icons.star_outline : Icons.star),
              label: Text(project.isFeatured ? 'Unfeature' : 'Feature'),
            ),
          ),
        ];
      case 'rejected':
        return [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _reapprove(project),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Re-approve'),
            ),
          ),
        ];
      case 'removed':
        return [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _restore(project),
              icon: const Icon(Icons.restore_outlined),
              label: const Text('Restore'),
            ),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final projectAsync = ref.watch(projectByIdProvider(widget.projectId));
    final savedIdsAsync = ref.watch(savedProjectIdsProvider);

    final currentUid = ref.watch(currentUserProvider)?.uid ?? '';
    final savedIds = savedIdsAsync.valueOrNull ?? {};

    return projectAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text(
            'Could not load project.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project')),
            body: _NotFound(colors: colors, textTheme: theme.textTheme),
          );
        }

        final isOwner = project.ownerId == currentUid;
        final isSaved = savedIds.contains(project.projectId);

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              if (!widget.adminView) ...[
                if (isOwner) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEditProjectScreen(
                            projectId: project.projectId,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: () => _deleteProject(project),
                  ),
                ],
                IconButton(
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
                  tooltip: isSaved ? 'Unsave' : 'Save',
                  onPressed: () => _toggleSave(project),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(project: project, colors: colors, theme: theme),
                  if (widget.adminView) ...[
                    const SizedBox(height: 16),
                    _AdminStatusBanner(
                      project: project,
                      colors: colors,
                      theme: theme,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _InfoSection(project: project, theme: theme, colors: colors),
                  const SizedBox(height: 24),
                  _Description(project: project, theme: theme),
                  if (project.screenshotUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _Screenshots(
                      urls: project.screenshotUrls,
                      theme: theme,
                      colors: colors,
                    ),
                  ],
                  if (project.documentUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _Documents(
                      urls: project.documentUrls,
                      theme: theme,
                      colors: colors,
                      onOpenUrl: _openUrl,
                    ),
                  ],
                  if (isOwner || widget.adminView) ...[
                    const SizedBox(height: 24),
                    _EditHistory(projectId: project.projectId, theme: theme, colors: colors),
                  ],
                  const SizedBox(height: 24),
                  if (project.websiteUrl.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FilledButton.icon(
                        onPressed: () => _openUrl(project.websiteUrl),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Visit website'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: !widget.adminView
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      border: Border(
                        top: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: _buildAdminActions(project),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.project,
    required this.colors,
    required this.theme,
  });

  final ProjectModel project;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: project.logoUrl.isNotEmpty
                ? AppNetworkImage(
                    url: project.logoUrl,
                    borderRadius: BorderRadius.circular(24),
                    errorWidget: Icon(
                      Icons.folder_outlined,
                      size: 40,
                      color: colors.onPrimaryContainer,
                    ),
                  )
                : Icon(
                    Icons.folder_outlined,
                    size: 40,
                    color: colors.onPrimaryContainer,
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            project.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            project.tagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Chip(
            label: Text(project.category.label),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.project,
    required this.theme,
    required this.colors,
  });

  final ProjectModel project;
  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Founder',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(userId: project.ownerId),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      getInitials(
                        project.founderName.isNotEmpty
                            ? project.founderName
                            : 'Anonymous',
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.founderName.isNotEmpty
                              ? project.founderName
                              : 'Anonymous',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'View profile',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (project.founderBio.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.founderBio,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (project.businessAge.isNotEmpty)
                _InfoCard(
                  label: 'Business age',
                  value: project.businessAge,
                  colors: colors,
                  theme: theme,
                ),
              if (project.monthlyVisitors.isNotEmpty)
                _InfoCard(
                  label: 'Monthly visitors',
                  value: project.monthlyVisitors,
                  colors: colors,
                  theme: theme,
                ),
              _InfoCard(
                label: 'Saves',
                value: '${project.saveCount}',
                colors: colors,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.colors,
    required this.theme,
  });

  final String label;
  final String value;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.project, required this.theme});

  final ProjectModel project;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            project.description.isNotEmpty
                ? project.description
                : 'No description provided.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Screenshots extends StatelessWidget {
  const _Screenshots({
    required this.urls,
    required this.theme,
    required this.colors,
  });

  final List<String> urls;
  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Screenshots',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: urls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 280,
                  color: colors.surfaceContainerLow,
                  child: AppNetworkImage(
                    url: urls[index],
                    errorWidget: Icon(
                      Icons.image_not_supported_outlined,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Documents extends StatelessWidget {
  const _Documents({
    required this.urls,
    required this.theme,
    required this.colors,
    required this.onOpenUrl,
  });

  final List<String> urls;
  final ThemeData theme;
  final ColorScheme colors;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...urls.map((url) {
            return ListTile(
              leading: Icon(Icons.description_outlined, color: colors.primary),
              title: Text(
                'Document ${urls.indexOf(url) + 1}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface,
                ),
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => onOpenUrl(url),
            );
          }),
        ],
      ),
    );
  }
}

class _EditHistory extends ConsumerWidget {
  const _EditHistory({
    required this.projectId,
    required this.theme,
    required this.colors,
  });

  final String projectId;
  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(projectHistoryProvider(projectId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit history',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...entries.take(20).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatAuditTimestamp(entry.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Changed: ${entry.changedFields.join(', ')}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _AdminStatusBanner extends StatelessWidget {
  const _AdminStatusBanner({
    required this.project,
    required this.colors,
    required this.theme,
  });

  final ProjectModel project;
  final ColorScheme colors;
  final ThemeData theme;

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return colors.primary;
      case 'rejected':
        return colors.error;
      case 'removed':
        return colors.outline;
      default:
        return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(project.status);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings_outlined, color: colors.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin review',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Status: ${project.status.toUpperCase()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (project.status == 'approved' && project.isFeatured)
            Chip(
              label: const Text('Featured'),
              backgroundColor: statusColor.withAlpha(40),
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.colors, required this.textTheme});

  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Project not found',
            style: textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This project may have been removed or is still pending approval.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }
}
