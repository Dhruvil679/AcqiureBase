import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../projects/project_detail_screen.dart';
import '../projects/widgets/project_card.dart';

// Public profile view for any user. Increments profileViews once when someone
// other than the owner opens it.
class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  bool _viewed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeIncrementViews());
  }

  Future<void> _maybeIncrementViews() async {
    if (_viewed) return;
    final currentUid = ref.read(currentUserProvider)?.uid;
    if (currentUid == null || currentUid == widget.userId) return;

    _viewed = true;
    await ref.read(userRepositoryProvider).incrementProfileViews(widget.userId);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
        appBar: AppBar(title: const Text('Profile')),
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
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: _NotFound(colors: colors, textTheme: theme.textTheme),
          );
        }

        final projectCount = projectsAsync.valueOrNull?.length ?? 0;

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            title: Text(user.displayName.isNotEmpty ? user.displayName : 'Profile'),
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _Avatar(photoUrl: user.photoUrl, name: user.displayName),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName.isNotEmpty
                              ? user.displayName
                              : 'No name',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (user.username.isNotEmpty)
                          Text(
                            '@${user.username}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          user.email.isNotEmpty ? user.email : 'No email',
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
                            if (user.role == 'admin')
                              _Badge(
                                label: 'Admin',
                                backgroundColor: colors.tertiaryContainer,
                                foregroundColor: colors.onTertiaryContainer,
                              ),
                            if (user.isSuspended)
                              _Badge(
                                label: 'Suspended',
                                backgroundColor: colors.errorContainer,
                                foregroundColor: colors.onErrorContainer,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.bio.isNotEmpty ? user.bio : 'No bio yet.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _StatsRow(
                          publishedCount: projectCount,
                          profileViews: user.profileViews,
                          colors: colors,
                          textTheme: theme.textTheme,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: _ProfileDetailsCard(user: user),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Projects',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
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
                            message: '',
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
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
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
    final initials = getInitials(name);

    return CircleAvatar(
      radius: 48,
      backgroundColor: colors.primaryContainer,
      backgroundImage:
          photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
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
      labelStyle: TextStyle(
        color: foregroundColor,
        fontWeight: FontWeight.w600,
      ),
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
                Icon(Icons.lightbulb_outline,
                    size: 20, color: colors.onSurfaceVariant),
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
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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
