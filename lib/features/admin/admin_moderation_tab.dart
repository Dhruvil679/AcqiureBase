import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/project_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/csv_exporter.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../projects/project_detail_screen.dart';

// Admin moderation tab — review, approve, reject, feature, or remove projects.
// Desktop uses a data table; mobile uses the same cards as before.
class AdminModerationTab extends ConsumerStatefulWidget {
  const AdminModerationTab({super.key});

  @override
  ConsumerState<AdminModerationTab> createState() => _AdminModerationTabState();
}

class _AdminModerationTabState extends ConsumerState<AdminModerationTab> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _statusFilter = 'pending';
  ProjectCategory? _categoryFilter;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  static const List<String> _statusOptions = [
    'all',
    'pending',
    'approved',
    'rejected',
    'removed',
  ];

  List<ProjectModel> _projects = [];
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
      _projects = [];
      _lastDoc = null;
      _hasMore = true;
    });

    try {
      final result = await _fetchPage();
      if (!mounted) return;
      setState(() {
        _projects = result.items;
        _lastDoc = result.lastDocument as DocumentSnapshot?;
        _hasMore = result.hasMore;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      _showMessage('Could not load projects: $e');
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
        _projects.addAll(result.items);
        _lastDoc = result.lastDocument as DocumentSnapshot?;
        _hasMore = result.hasMore;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      _showMessage('Could not load more projects: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<_ProjectsPage> _fetchPage({DocumentSnapshot? startAfter}) async {
    final repository = ref.read(projectRepositoryProvider);
    final result = await repository.fetchProjectsByStatus(
      _statusFilter,
      startAfter: startAfter,
      limit: 25,
    );
    return _ProjectsPage(
      items: result.items,
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
    );
  }

  void _setStatusFilter(String status) {
    setState(() {
      _statusFilter = status;
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    _loadInitial();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(String projectId) {
    setState(() {
      if (_selectedIds.contains(projectId)) {
        _selectedIds.remove(projectId);
      } else {
        _selectedIds.add(projectId);
      }
    });
  }

  void _selectAll(List<ProjectModel> projects, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.addAll(projects.map((p) => p.projectId));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _setCategoryFilter(ProjectCategory? category) =>
      setState(() => _categoryFilter = category);

  List<ProjectModel> _filteredProjects() {
    var result = _projects;

    if (_categoryFilter != null) {
      result = result.where((p) => p.category == _categoryFilter).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.tagline.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  Future<void> _approve(ProjectModel project) async {
    await ref.read(projectRepositoryProvider).updateProjectStatus(
          projectId: project.projectId,
          status: 'approved',
        );
    await _logAction('approved project', project);
    await _notifyOwner(project, 'approved');
    _showMessage('"${project.name}" approved.');
  }

  Future<void> _reject(ProjectModel project) async {
    final reason = await _showReasonDialog('Reject "${project.name}"?');
    if (reason == null || !mounted) return;

    await ref.read(projectRepositoryProvider).updateProjectStatus(
          projectId: project.projectId,
          status: 'rejected',
        );
    await _logAction('rejected project', project, reason: reason);
    await _notifyOwner(project, 'rejected');
    _showMessage('"${project.name}" rejected.');
  }

  Future<void> _reapprove(ProjectModel project) async {
    await ref.read(projectRepositoryProvider).updateProjectStatus(
          projectId: project.projectId,
          status: 'approved',
        );
    await _logAction('re-approved project', project);
    await _notifyOwner(project, 'approved');
    _showMessage('"${project.name}" re-approved.');
  }

  Future<void> _feature(ProjectModel project) async {
    await ref.read(projectRepositoryProvider).setFeatured(
          projectId: project.projectId,
          isFeatured: true,
        );
    await _logAction('featured project', project);
    _showMessage('"${project.name}" featured.');
  }

  Future<void> _unfeature(ProjectModel project) async {
    await ref.read(projectRepositoryProvider).setFeatured(
          projectId: project.projectId,
          isFeatured: false,
        );
    await _logAction('unfeatured project', project);
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

    await ref.read(projectRepositoryProvider).updateProjectStatus(
          projectId: project.projectId,
          status: 'removed',
        );
    await _logAction('removed project', project, reason: reason);
    await _notifyOwner(project, 'removed');
    _showMessage('"${project.name}" removed.');
  }

  Future<void> _restore(ProjectModel project) async {
    await ref.read(projectRepositoryProvider).updateProjectStatus(
          projectId: project.projectId,
          status: 'approved',
        );
    await _logAction('restored project', project);
    await _notifyOwner(project, 'approved');
    _showMessage('"${project.name}" restored.');
  }

  Future<void> _bulkApprove() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Approve ${_selectedIds.length} project(s)?',
      content: 'The selected projects will be approved and become publicly visible.',
      confirmText: 'Approve',
    );
    if (!confirmed || !mounted) return;

    final selected = _filteredProjects()
        .where((p) => _selectedIds.contains(p.projectId))
        .toList();

    for (final project in selected) {
      try {
        await ref.read(projectRepositoryProvider).updateProjectStatus(
              projectId: project.projectId,
              status: 'approved',
            );
        await _logAction('approved project', project);
        await _notifyOwner(project, 'approved');
      } on Exception catch (e) {
        _showMessage('Failed to approve "${project.name}": $e');
      }
    }

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    _showMessage('${selected.length} project(s) approved.');
  }

  Future<void> _bulkReject() async {
    final reason = await _showReasonDialog(
      'Reject ${_selectedIds.length} project(s)?',
    );
    if (reason == null || !mounted) return;

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Reject ${_selectedIds.length} project(s)?',
      content: 'The selected projects will be rejected.',
      confirmText: 'Reject',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final selected = _filteredProjects()
        .where((p) => _selectedIds.contains(p.projectId))
        .toList();

    for (final project in selected) {
      try {
        await ref.read(projectRepositoryProvider).updateProjectStatus(
              projectId: project.projectId,
              status: 'rejected',
            );
        await _logAction('rejected project', project, reason: reason);
        await _notifyOwner(project, 'rejected');
      } on Exception catch (e) {
        _showMessage('Failed to reject "${project.name}": $e');
      }
    }

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    _showMessage('${selected.length} project(s) rejected.');
  }

  Future<void> _exportCsv() async {
    final projects = _filteredProjects();
    if (projects.isEmpty) {
      _showMessage('No projects to export.');
      return;
    }
    final csv = CsvExporter.projectsToCsv(projects);
    await CsvExporter.shareCsv(
      filename: 'acquirebase_projects_${DateTime.now().millisecondsSinceEpoch}.csv',
      csv: csv,
    );
  }

  Future<void> _notifyOwner(ProjectModel project, String status) async {
    await ref.read(notificationRepositoryProvider).notifyProjectStatus(
          userId: project.ownerId,
          projectId: project.projectId,
          projectName: project.name,
          status: status,
        );
  }

  Future<void> _logAction(String action, ProjectModel project, {String? reason}) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    await ref.read(auditLogRepositoryProvider).log(
          adminUid: admin.uid,
          adminName: admin.displayName ?? admin.email ?? 'Admin',
          action: action,
          targetType: 'project',
          targetId: project.projectId,
          targetName: project.name,
          reason: reason,
        );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    final filtered = _filteredProjects();

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
                    'Listings',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review and manage project submissions',
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
                  hintText: 'Search projects...',
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
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _statusOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final status = _statusOptions[index];
                  final selected = _statusFilter == status;
                  return ChoiceChip(
                    label: Text(status[0].toUpperCase() + status.substring(1)),
                    selected: selected,
                    onSelected: (_) => _setStatusFilter(status),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ProjectCategory?>(
                      initialValue: _categoryFilter,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All categories'),
                        ),
                        ...ProjectCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.label),
                          );
                        }),
                      ],
                      onChanged: (value) => _setCategoryFilter(value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _toggleSelectionMode,
                    icon: Icon(_isSelectionMode
                        ? Icons.cancel_outlined
                        : Icons.checklist_outlined),
                    label: Text(_isSelectionMode ? 'Done' : 'Select'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
            ),
            if (_isSelectionMode && _selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_selectedIds.length} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              Expanded(
                child: _EmptyState(
                  colors: colors,
                  textTheme: theme.textTheme,
                  statusFilter: _statusFilter,
                ),
              )
            else
              Expanded(
                child: isWide
                    ? _ModerationTable(
                        projects: filtered,
                        colors: colors,
                        theme: theme,
                        selectionMode: _isSelectionMode,
                        selectedIds: _selectedIds,
                        onToggleSelected: _toggleSelected,
                        onSelectAll: (selected) => _selectAll(filtered, selected),
                        onOpen: _openProject,
                        onApprove: _approve,
                        onReject: _reject,
                        onReapprove: _reapprove,
                        onFeature: _feature,
                        onUnfeature: _unfeature,
                        onRemove: _remove,
                        onRestore: _restore,
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

                          final project = filtered[index];
                          return _ModerationCard(
                            project: project,
                            colors: colors,
                            theme: theme,
                            isSelectionMode: _isSelectionMode,
                            isSelected: _selectedIds.contains(project.projectId),
                            onToggleSelected: () => _toggleSelected(project.projectId),
                            onTap: () => _openProject(project),
                            onApprove: () => _approve(project),
                            onReject: () => _reject(project),
                            onReapprove: () => _reapprove(project),
                            onFeature: () => _feature(project),
                            onUnfeature: () => _unfeature(project),
                            onRemove: () => _remove(project),
                            onRestore: () => _restore(project),
                          );
                        },
                      ),
              ),
            if (_isSelectionMode && _selectedIds.isNotEmpty)
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    border: Border(
                      top: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _bulkReject,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _bulkApprove,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProjectsPage {
  const _ProjectsPage({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });

  final List<ProjectModel> items;
  final dynamic lastDocument;
  final bool hasMore;
}

class _ModerationTable extends StatelessWidget {
  const _ModerationTable({
    required this.projects,
    required this.colors,
    required this.theme,
    required this.selectionMode,
    required this.selectedIds,
    required this.onToggleSelected,
    required this.onSelectAll,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
    required this.onReapprove,
    required this.onFeature,
    required this.onUnfeature,
    required this.onRemove,
    required this.onRestore,
  });

  final List<ProjectModel> projects;
  final ColorScheme colors;
  final ThemeData theme;
  final bool selectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelected;
  final ValueChanged<bool> onSelectAll;
  final ValueChanged<ProjectModel> onOpen;
  final ValueChanged<ProjectModel> onApprove;
  final ValueChanged<ProjectModel> onReject;
  final ValueChanged<ProjectModel> onReapprove;
  final ValueChanged<ProjectModel> onFeature;
  final ValueChanged<ProjectModel> onUnfeature;
  final ValueChanged<ProjectModel> onRemove;
  final ValueChanged<ProjectModel> onRestore;

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

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _rowActions(ProjectModel project) {
    switch (project.status) {
      case 'pending':
        return [
          TextButton(
            onPressed: () => onReject(project),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () => onApprove(project),
            child: const Text('Approve'),
          ),
        ];
      case 'approved':
        return [
          TextButton(
            onPressed: () => onRemove(project),
            child: const Text('Remove'),
          ),
          FilledButton.tonal(
            onPressed: project.isFeatured
                ? () => onUnfeature(project)
                : () => onFeature(project),
            child: Text(project.isFeatured ? 'Unfeature' : 'Feature'),
          ),
        ];
      case 'rejected':
        return [
          FilledButton(
            onPressed: () => onReapprove(project),
            child: const Text('Re-approve'),
          ),
        ];
      case 'removed':
        return [
          FilledButton(
            onPressed: () => onRestore(project),
            child: const Text('Restore'),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = projects.isNotEmpty &&
        projects.every((p) => selectedIds.contains(p.projectId));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth - 32),
            child: Card(
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(colors.surfaceContainerHighest),
                  dataRowMinHeight: 64,
                  columns: [
                    if (selectionMode)
                      DataColumn(
                        label: Checkbox(
                          value: allSelected,
                          onChanged: (value) => onSelectAll(value ?? false),
                        ),
                      ),
                    const DataColumn(label: Text('Project')),
                    const DataColumn(label: Text('Category')),
                    const DataColumn(label: Text('Founder')),
                    const DataColumn(label: Text('Status')),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: projects.map((project) {
                    return DataRow(
                      selected: selectionMode && selectedIds.contains(project.projectId),
                      onSelectChanged: selectionMode
                          ? (selected) => onToggleSelected(project.projectId)
                          : null,
                      cells: [
                        if (selectionMode)
                          DataCell(
                            Checkbox(
                              value: selectedIds.contains(project.projectId),
                              onChanged: (_) => onToggleSelected(project.projectId),
                            ),
                          ),
                        DataCell(
                          InkWell(
                            onTap: () => onOpen(project),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ProjectLogo(logoUrl: project.logoUrl),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        project.name,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        project.tagline,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(Text(project.category.label)),
                        DataCell(
                          Text(
                            project.founderName.isNotEmpty
                                ? project.founderName
                                : 'Anonymous',
                          ),
                        ),
                        DataCell(_statusBadge(project.status)),
                        DataCell(
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: _rowActions(project),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModerationCard extends StatelessWidget {
  const _ModerationCard({
    required this.project,
    required this.colors,
    required this.theme,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onReapprove,
    required this.onFeature,
    required this.onUnfeature,
    required this.onRemove,
    required this.onRestore,
  });

  final ProjectModel project;
  final ColorScheme colors;
  final ThemeData theme;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelected;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReapprove;
  final VoidCallback onFeature;
  final VoidCallback onUnfeature;
  final VoidCallback onRemove;
  final VoidCallback onRestore;

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

  List<Widget> _buildActions() {
    switch (project.status) {
      case 'pending':
        return [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Approve'),
            ),
          ),
        ];
      case 'approved':
        return [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: project.isFeatured ? onUnfeature : onFeature,
              icon: Icon(
                project.isFeatured ? Icons.star_outline : Icons.star,
              ),
              label: Text(project.isFeatured ? 'Unfeature' : 'Feature'),
            ),
          ),
        ];
      case 'rejected':
        return [
          Expanded(
            child: FilledButton.icon(
              onPressed: onReapprove,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Re-approve'),
            ),
          ),
        ];
      case 'removed':
        return [
          Expanded(
            child: FilledButton.icon(
              onPressed: onRestore,
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
    return Card(
      child: InkWell(
        onTap: isSelectionMode ? onToggleSelected : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelected(),
                    ),
                    const SizedBox(width: 12),
                  ],
                  _ProjectLogo(logoUrl: project.logoUrl),
                  const SizedBox(width: 12),
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(project.category.label),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(project.status).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          project.status.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _statusColor(project.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.founderName.isNotEmpty
                          ? project.founderName
                          : 'Anonymous',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isSelectionMode) ...[
                const SizedBox(height: 16),
                Row(
                  children: _buildActions(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectLogo extends StatelessWidget {
  const _ProjectLogo({required this.logoUrl});

  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        color: colors.surfaceContainerHighest,
        child: logoUrl.isNotEmpty
            ? Image(
                image: CachedNetworkImageProvider(logoUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.storefront_outlined,
                  color: colors.onSurfaceVariant,
                ),
              )
            : Icon(
                Icons.storefront_outlined,
                color: colors.onSurfaceVariant,
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.colors,
    required this.textTheme,
    required this.statusFilter,
  });

  final ColorScheme colors;
  final TextTheme textTheme;
  final String statusFilter;

  @override
  Widget build(BuildContext context) {
    final label = statusFilter == 'all'
        ? 'No projects found'
        : 'No ${statusFilter.toLowerCase()} projects';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            label,
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
