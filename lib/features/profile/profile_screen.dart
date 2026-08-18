import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../features/admin/admin_panel_screen.dart';
import '../../features/auth/login_screen.dart';
import '../projects/add_edit_project_screen.dart';
import '../projects/project_detail_screen.dart';
import '../projects/widgets/project_card.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';

// Profile tab — shows the current user's full profile, stats, own projects,
// social links, and logout button.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final userAsync = ref.watch(currentUserProfileProvider);
    final projectsAsync = ref.watch(currentUserProjectsProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text(
            'Could not load profile.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      data: (user) {
        final profile = user ?? _fallbackUser();
        final projectCount = projectsAsync.valueOrNull?.length ?? 0;

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              _NotificationsIcon(),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit profile',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _Avatar(photoUrl: profile.photoUrl, name: profile.displayName),
                        const SizedBox(height: 16),
                        Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName
                              : 'No name',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (profile.username.isNotEmpty)
                          Text(
                            '@${profile.username}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email.isNotEmpty ? profile.email : 'No email',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (profile.role == 'admin')
                              _Badge(
                                label: 'Admin',
                                backgroundColor: colors.tertiaryContainer,
                                foregroundColor: colors.onTertiaryContainer,
                              ),
                            if (profile.isSuspended)
                              _Badge(
                                label: 'Suspended',
                                backgroundColor: colors.errorContainer,
                                foregroundColor: colors.onErrorContainer,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.bio.isNotEmpty ? profile.bio : 'No bio yet.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _StatsRow(
                          publishedCount: projectCount,
                          profileViews: profile.profileViews,
                          colors: colors,
                          textTheme: theme.textTheme,
                        ),
                        if (profile.role == 'admin') ...[
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AdminPanelScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.admin_panel_settings_outlined),
                            label: const Text('Admin Panel'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: _ProfileDetailsCard(user: profile),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Projects',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddEditProjectScreen(),
                              ),
                            );
                          },
                          child: const Text('Add project'),
                        ),
                      ],
                    ),
                  ),
                ),
                projectsAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Could not load projects.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  data: (projects) => projects.isEmpty
                      ? SliverToBoxAdapter(
                          child: EmptyState(
                            icon: Icons.folder_outlined,
                            title: 'No published projects yet',
                            message: 'Add your first project to see it here.',
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final project = projects[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ProjectCard(
                                    project: project,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ProjectDetailScreen(
                                            projectId: project.projectId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              childCount: projects.length,
                            ),
                          ),
                        ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: OutlinedButton.icon(
                      onPressed: () => _signOut(context, ref),
                      icon: const Icon(Icons.logout),
                      label: const Text('Log out'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  UserModel _fallbackUser() {
    return const UserModel(uid: '');
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Log out?',
      content: 'You will be signed out of AcquireBase.',
      confirmText: 'Log out',
    );
    if (!confirmed || !context.mounted) return;

    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
    final initials = getInitials(name);

    return CircleAvatar(
      radius: 48,
      backgroundColor: colors.primaryContainer,
      backgroundImage: photoUrl.isNotEmpty
          ? CachedNetworkImageProvider(photoUrl)
          : null,
      child: photoUrl.isEmpty
          ? Text(
              initials,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            )
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: foregroundColor, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.publishedCount,
    required this.profileViews,
    required this.colors,
    required this.textTheme,
  });

  final int publishedCount;
  final int profileViews;
  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(label: 'Projects', value: '$publishedCount'),
        Container(
          width: 1,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          color: colors.outlineVariant,
        ),
        _StatItem(label: 'Profile views', value: '$profileViews'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.badge_outlined,
              label: 'Full name',
              value: '${user.firstName} ${user.lastName}'.trim().isNotEmpty
                  ? '${user.firstName} ${user.lastName}'.trim()
                  : '-',
            ),
            _DetailRow(
              icon: Icons.cake_outlined,
              label: 'Age',
              value: user.age != null ? '${user.age}' : '-',
            ),
            _DetailRow(
              icon: Icons.work_outline,
              label: 'Profession',
              value: user.profession.label,
            ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Joined',
              value: formatDate(user.createdAt),
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
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
    final colors = theme.colorScheme;

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
          avatar: Icon(e.icon, size: 18, color: colors.primary),
          label: Text(e.label),
          onPressed: () => _open(e.value, e.prefix),
        );
      }).toList(),
    );
  }
}

class _NotificationsIcon extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final countAsync = ref.watch(unreadNotificationsCountProvider);
    final count = countAsync.valueOrNull ?? 0;

    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.notifications_outlined),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      },
    );
  }
}
