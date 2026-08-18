import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/formatters.dart';
import '../../features/splash/splash_screen.dart';

// Minimal admin profile page. Excludes excluded settings sections (pricing,
// language, notifications, two-factor auth, etc.) and just shows the current
// admin's account + sign-out.
class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin profile'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load profile.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not signed in',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _signOut(context, ref),
                    child: const Text('Return to login'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: colors.primaryContainer,
                  backgroundImage: user.photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(user.photoUrl)
                      : null,
                  child: user.photoUrl.isEmpty
                      ? Text(
                          getInitials(user.displayName),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName : 'Admin',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user.email.isNotEmpty ? user.email : '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  label: Text(user.role.toUpperCase()),
                  backgroundColor: colors.tertiaryContainer,
                  labelStyle: TextStyle(
                    color: colors.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _SectionTitle(theme: theme, colors: colors, title: 'Account'),
              Card(
                elevation: 0,
                color: colors.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.person_outline,
                      label: 'Username',
                      value: user.username.isNotEmpty ? user.username : '-',
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Profession',
                      value: user.profession.label,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Joined',
                      value: formatDate(user.createdAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _SectionTitle(theme: theme, colors: colors, title: 'Administration'),
              Card(
                elevation: 0,
                color: colors.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(Icons.logout, color: colors.error),
                  title: Text(
                    'Log out',
                    style: TextStyle(
                      color: colors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _signOut(context, ref),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await ref.read(authServiceProvider).signOut();
    unawaited(
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.theme,
    required this.colors,
    required this.title,
  });

  final ThemeData theme;
  final ColorScheme colors;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 16),
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
