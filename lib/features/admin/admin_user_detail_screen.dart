import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/activity_log_entry.dart';
import '../../core/models/project_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../projects/project_detail_screen.dart';
import '../projects/widgets/project_card.dart';

// Admin detail view for a single user. Shows every captured user detail,
// admin-only role/suspension state, audit history, and moderation actions.
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _isLoading = false;

  Future<void> _toggleSuspend(UserModel user) async {
    final activating = user.isSuspended;
    final confirmed = await showConfirmationDialog(
      context: context,
      title: activating ? 'Activate account?' : 'Suspend account?',
      content: activating
          ? '${user.displayName} will be able to sign in and use the app again.'
          : '${user.displayName} will be blocked from signing in until reactivated.',
      confirmText: activating ? 'Activate' : 'Suspend',
      isDestructive: !activating,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(adminFunctionsServiceProvider).setUserSuspension(
            uid: user.uid,
            isSuspended: !user.isSuspended,
          );
      await _logAction(
        user.isSuspended ? 'activated user' : 'suspended user',
        user,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isSuspended
                ? '${user.displayName} activated.'
                : '${user.displayName} suspended.',
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      _showError('Failed to update suspension: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _toggleRole(UserModel user) async {
    final newRole = user.role == 'admin' ? 'user' : 'admin';
    final confirmed = await showConfirmationDialog(
      context: context,
      title: newRole == 'admin' ? 'Promote to admin?' : 'Demote to user?',
      content: newRole == 'admin'
          ? '${user.displayName} will gain admin access to moderate content and manage users.'
          : '${user.displayName} will lose admin access and return to a regular user role.',
      confirmText: newRole == 'admin' ? 'Promote' : 'Demote',
      isDestructive: newRole != 'admin',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(adminFunctionsServiceProvider).setAdminClaim(
            uid: user.uid,
            role: newRole,
          );
      await _logAction(
        newRole == 'admin' ? 'promoted user to admin' : 'demoted user to user',
        user,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newRole == 'admin'
                ? '${user.displayName} promoted to admin.'
                : '${user.displayName} demoted to user.',
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      _showError('Failed to update role: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete user?',
      content:
          'This will permanently delete ${user.displayName}\'s account and all their data. This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(adminFunctionsServiceProvider).deleteUserAccount(
            uid: user.uid,
          );
      await _logAction('deleted user', user);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.displayName} deleted.')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      _showError('Failed to delete user: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logAction(String action, UserModel user) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    await ref.read(auditLogRepositoryProvider).log(
          adminUid: admin.uid,
          adminName: admin.displayName ?? admin.email ?? 'Admin',
          action: action,
          targetType: 'user',
          targetId: user.uid,
          targetName: user.displayName.isNotEmpty
              ? user.displayName
              : user.email.isNotEmpty
                  ? user.email
                  : 'Unknown',
        );
  }

  void _openProject(ProjectModel project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          projectId: project.projectId,
          adminView: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final userAsync = ref.watch(userByIdProvider(widget.userId));
    final projectsAsync = ref.watch(projectsByOwnerProvider(widget.userId));

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: _NotFound(colors: colors, textTheme: theme.textTheme),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: _NotFound(colors: colors, textTheme: theme.textTheme),
          );
        }

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            title: const Text('User details'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Avatar(photoUrl: user.photoUrl, name: user.displayName),
                    const SizedBox(height: 16),
                    Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : 'No name',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user.username.isNotEmpty)
                      Text(
                        '@${user.username}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text('Role: ${user.role}'),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text(user.isSuspended ? 'Suspended' : 'Active'),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text('Joined: ${formatDate(user.createdAt)}'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _InfoSection(user: user),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : () => _toggleSuspend(user),
                      icon: Icon(
                        user.isSuspended
                            ? Icons.check_circle_outline
                            : Icons.block_outlined,
                      ),
                      label: Text(
                        user.isSuspended ? 'Activate account' : 'Suspend account',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _isLoading ? null : () => _toggleRole(user),
                      icon: Icon(
                        user.role == 'admin'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                      ),
                      label: Text(
                        user.role == 'admin'
                            ? 'Demote to User'
                            : 'Promote to Admin',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _deleteUser(user),
                      icon: Icon(Icons.delete_outline, color: colors.error),
                      label: Text(
                        'Delete user',
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Admin actions on this user',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AdminAuditList(targetId: widget.userId),
                    const SizedBox(height: 32),
                    Text(
                      'Published projects',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    projectsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Could not load projects: $error'),
                        ),
                      ),
                      data: (projects) => _ProjectsList(
                        projects: projects,
                        onTap: _openProject,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Recent activity',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _UserActivityList(uid: widget.userId),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});

  final String photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 48,
      backgroundColor: colors.primaryContainer,
      backgroundImage: photoUrl.isNotEmpty
          ? CachedNetworkImageProvider(photoUrl)
          : null,
      child: photoUrl.isEmpty
          ? Text(
              getInitials(name),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            )
          : null,
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account details',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _InfoGrid(user: user),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 20, color: colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skills',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (user.skills.isEmpty)
                        Text('-', style: theme.textTheme.bodyMedium)
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.skills
                              .map(
                                (skill) => Chip(
                                  label: Text(skill),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.link, size: 20, color: colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Social links',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _SocialLinksRow(links: user.socialLinks),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'UID: ${user.uid}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = [
      _InfoItem(label: 'Username', value: user.username.isNotEmpty ? user.username : '-'),
      _InfoItem(label: 'Email', value: user.email),
      _InfoItem(
        label: 'Full name',
        value: '${user.firstName} ${user.lastName}'.trim().isNotEmpty
            ? '${user.firstName} ${user.lastName}'.trim()
            : '-',
      ),
      _InfoItem(label: 'Profession', value: user.profession.label),
      _InfoItem(label: 'Age', value: user.age?.toString() ?? '-'),
      _InfoItem(label: 'Profile views', value: '${user.profileViews}'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _SocialLinksRow extends StatelessWidget {
  const _SocialLinksRow({required this.links});

  final SocialLinks links;

  Future<void> _open(String rawUrl, String fallbackPrefix) async {
    var url = rawUrl.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) {
      url = '$fallbackPrefix$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final entries = [
      (
        label: 'Twitter',
        value: links.twitter,
        icon: Icons.alternate_email,
        prefix: 'https://twitter.com/',
      ),
      (
        label: 'LinkedIn',
        value: links.linkedin,
        icon: Icons.work_outline,
        prefix: 'https://linkedin.com/in/',
      ),
      (
        label: 'Website',
        value: links.website,
        icon: Icons.language,
        prefix: 'https://',
      ),
    ];

    final active = entries.where((e) => e.value.trim().isNotEmpty).toList();

    if (active.isEmpty) {
      return Text('-', style: theme.textTheme.bodyMedium);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: active.map((e) {
        return ActionChip(
          avatar: Icon(e.icon, size: 18),
          label: Text(e.label),
          onPressed: () => _open(e.value, e.prefix),
        );
      }).toList(),
    );
  }
}

class _ProjectsList extends StatelessWidget {
  const _ProjectsList({
    required this.projects,
    required this.onTap,
  });

  final List<ProjectModel> projects;
  final ValueChanged<ProjectModel> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No published projects.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: projects.map((project) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProjectCard(
            project: project,
            onTap: () => onTap(project),
          ),
        );
      }).toList(),
    );
  }
}

class _AdminAuditList extends ConsumerWidget {
  const _AdminAuditList({required this.targetId});

  final String targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final auditAsync = ref.watch(
      auditLogForTargetProvider((targetType: 'user', targetId: targetId)),
    );

    return auditAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load admin audit history.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No admin actions recorded.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return Column(
          children: entries.take(20).map((entry) {
            final reason = entry.reason;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined,
                            color: colors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${entry.adminName} ${entry.action}',
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
      },
    );
  }
}

class _UserActivityList extends ConsumerWidget {
  const _UserActivityList({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final activityAsync = ref.watch(userActivityProvider(uid));

    return activityAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load activity.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No recent activity.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return Column(
          children: entries.take(20).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(_iconForAction(entry.action), color: colors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _labelFor(entry),
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
          }).toList(),
        );
      },
    );
  }

  String _labelFor(ActivityLogEntry entry) {
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
            Icons.person_off_outlined,
            size: 64,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'User not found',
            style: textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This account may have been deleted.',
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
