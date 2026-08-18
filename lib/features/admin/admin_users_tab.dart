import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_model.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/csv_exporter.dart';
import '../../core/utils/formatters.dart';
import 'admin_user_detail_screen.dart';

// Admin users tab — search, filter, and manage user accounts.
// Desktop uses a data table; mobile uses the same cards as before.
class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _roleFilter = 'all';
  String _statusFilter = 'all';
  Profession? _professionFilter;

  List<UserModel> _users = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  void _onScroll() {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (max > 0 && current > max - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _users = [];
      _lastDoc = null;
      _hasMore = true;
    });

    try {
      final result = await _fetchPage();
      if (!mounted) return;
      setState(() {
        _users = result.items;
        _lastDoc = result.lastDocument as DocumentSnapshot?;
        _hasMore = result.hasMore;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      _showError('Could not load users: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _fetchPage(startAfter: _lastDoc);
      if (!mounted) return;
      setState(() {
        _users.addAll(result.items);
        _lastDoc = result.lastDocument as DocumentSnapshot?;
        _hasMore = result.hasMore;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      _showError('Could not load more users: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<_UsersPage> _fetchPage({DocumentSnapshot? startAfter}) async {
    final repository = ref.read(userRepositoryProvider);
    final result = await repository.fetchAllUsers(
      startAfter: startAfter,
      limit: 25,
    );
    return _UsersPage(
      items: result.items,
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
    );
  }

  void _setRoleFilter(String role) => setState(() => _roleFilter = role);

  void _setStatusFilter(String status) => setState(() => _statusFilter = status);

  void _setProfessionFilter(Profession? profession) =>
      setState(() => _professionFilter = profession);

  Future<void> _exportCsv() async {
    final users = _filteredUsers();
    if (users.isEmpty) {
      _showError('No users to export.');
      return;
    }
    final csv = CsvExporter.usersToCsv(users);
    await CsvExporter.shareCsv(
      filename: 'acquirebase_users_${DateTime.now().millisecondsSinceEpoch}.csv',
      csv: csv,
    );
  }

  List<UserModel> _filteredUsers() {
    var result = _users;

    if (_roleFilter != 'all') {
      result = result.where((u) => u.role == _roleFilter).toList();
    }

    if (_statusFilter != 'all') {
      final suspended = _statusFilter == 'suspended';
      result = result.where((u) => u.isSuspended == suspended).toList();
    }

    if (_professionFilter != null) {
      result = result.where((u) => u.profession == _professionFilter).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((u) {
        return u.displayName.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            u.username.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  void _openUser(UserModel user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminUserDetailScreen(userId: user.uid),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final filtered = _filteredUsers();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Users',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage accounts, roles, and suspension state',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or username...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9999),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9999),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9999),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      initialValue: _roleFilter,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All roles')),
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        if (value != null) _setRoleFilter(value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All statuses')),
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                      ],
                      onChanged: (value) {
                        if (value != null) _setStatusFilter(value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<Profession?>(
                      initialValue: _professionFilter,
                      decoration: const InputDecoration(labelText: 'Profession'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All professions'),
                        ),
                        ...Profession.values.map((profession) {
                          return DropdownMenuItem(
                            value: profession,
                            child: Text(profession.label),
                          );
                        }),
                      ],
                      onChanged: (value) => _setProfessionFilter(value),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              Expanded(
                child: _EmptyState(colors: colors, textTheme: theme.textTheme),
              )
            else
              Expanded(
                child: isWide
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth - 32,
                                ),
                                child: Card(
                                  elevation: 0,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: DataTable(
                                      headingRowColor: WidgetStatePropertyAll(
                                        colors.surfaceContainerHighest,
                                      ),
                                      dataRowMinHeight: 64,
                                      columns: const [
                                        DataColumn(label: Text('User')),
                                        DataColumn(label: Text('Email')),
                                        DataColumn(label: Text('Role')),
                                        DataColumn(label: Text('Status')),
                                        DataColumn(label: Text('Profession')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: filtered.map((user) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _UserAvatar(
                                                    photoUrl: user.photoUrl,
                                                    name: user.displayName,
                                                    radius: 16,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Flexible(
                                                    child: Text(
                                                      user.displayName.isNotEmpty
                                                          ? user.displayName
                                                          : 'No name',
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                user.email,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            DataCell(Text(user.role)),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: user.isSuspended
                                                      ? colors.error.withAlpha(30)
                                                      : Colors.green.withAlpha(30),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  user.isSuspended
                                                      ? 'Suspended'
                                                      : 'Active',
                                                  style: theme.textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: user.isSuspended
                                                        ? colors.error
                                                        : Colors.green,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(user.profession.label)),
                                            DataCell(
                                              FilledButton.tonal(
                                                onPressed: () => _openUser(user),
                                                child: const Text('Manage'),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == filtered.length) {
                            return _isLoadingMore
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : const SizedBox.shrink();
                          }

                          final user = filtered[index];
                          return _UserCard(
                            user: user,
                            colors: colors,
                            theme: theme,
                            onTap: () => _openUser(user),
                          );
                        },
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _UsersPage {
  const _UsersPage({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });

  final List<UserModel> items;
  final dynamic lastDocument;
  final bool hasMore;
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final UserModel user;
  final ColorScheme colors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _UserAvatar(
                photoUrl: user.photoUrl,
                name: user.displayName,
                radius: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : 'No name',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(user.role),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        if (user.isSuspended)
                          Chip(
                            label: const Text('Suspended'),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.photoUrl,
    required this.name,
    required this.radius,
  });

  final String photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      backgroundImage:
          photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
      child: photoUrl.isEmpty
          ? Text(
              getInitials(name),
              style: TextStyle(
                fontSize: radius * 0.7,
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors, required this.textTheme});

  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the filters or search query.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
