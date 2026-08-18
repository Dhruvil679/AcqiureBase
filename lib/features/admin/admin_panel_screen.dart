import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/formatters.dart';
import '../../features/splash/splash_screen.dart';
import 'admin_audit_log_tab.dart';
import 'admin_moderation_tab.dart';
import 'admin_overview_tab.dart';
import 'admin_profile_screen.dart';
import 'admin_users_tab.dart';

// Admin shell — responsive navigation with a rail on desktop and a bottom bar
// on mobile, matching the admin-panel reference layout.
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.storefront_outlined),
      selectedIcon: Icon(Icons.storefront),
      label: Text('Listings'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outlined),
      selectedIcon: Icon(Icons.people),
      label: Text('Users'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: Text('Log'),
    ),
  ];

  static const _pages = [
    AdminOverviewTab(),
    AdminModerationTab(),
    AdminUsersTab(),
    AdminAuditLogTab(),
  ];

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  Widget get _trailing => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IconButton(
          tooltip: 'Log out',
          icon: const Icon(Icons.logout_outlined),
          onPressed: _logout,
        ),
      );

  List<Widget> get _appBarActions {
    final user = ref.watch(currentUserProfileProvider).valueOrNull;
    final photoUrl = user?.photoUrl;
    final initials = getInitials(user?.displayName ?? '');

    return [
      IconButton(
        tooltip: 'Search',
        icon: const Icon(Icons.search),
        onPressed: () {
          // Search is handled inside each tab; this keeps the reference top-bar
          // layout consistent.
        },
      ),
      IconButton(
        tooltip: 'Notifications',
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {
          // Notifications are handled from the user shell; visual cue only.
        },
      ),
      IconButton(
        tooltip: 'Settings',
        icon: const Icon(Icons.settings_outlined),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
          );
        },
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
            );
          },
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: photoUrl?.isNotEmpty == true
                ? CachedNetworkImageProvider(photoUrl!)
                : null,
            child: photoUrl?.isNotEmpty != true
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
        ),
      ),
      const SizedBox(width: 8),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        final body = IndexedStack(
          index: _selectedIndex,
          children: _pages,
        );

        if (isWide) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('AcquireBase'),
              actions: _appBarActions,
            ),
            body: Row(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/acquirebase.png',
                            height: 28,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.shopping_bag_outlined,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AcquireBase',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Admin Console',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: NavigationRail(
                        backgroundColor: colors.surfaceContainerHigh,
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) {
                          setState(() => _selectedIndex = index);
                        },
                        labelType: NavigationRailLabelType.all,
                        indicatorColor: colors.primary,
                        indicatorShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        selectedIconTheme: IconThemeData(color: colors.onPrimary),
                        unselectedIconTheme: IconThemeData(
                          color: colors.onSurfaceVariant,
                        ),
                        selectedLabelTextStyle: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        unselectedLabelTextStyle: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                        destinations: _destinations,
                        trailing: _trailing,
                      ),
                    ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colors.outlineVariant,
                ),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('AcquireBase'),
            actions: _appBarActions,
          ),
          body: body,
          bottomNavigationBar: NavigationBar(
            backgroundColor: colors.surfaceContainerHigh,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: _destinations
                .map(
                  (d) => NavigationDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: (d.label as Text).data!,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
