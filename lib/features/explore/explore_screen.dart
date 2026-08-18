import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/project_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../projects/add_edit_project_screen.dart';
import '../projects/project_detail_screen.dart';
import '../projects/widgets/project_card.dart';
import '../../core/widgets/empty_state.dart';

// Main explore feed with search, category filters, featured carousel, and
// paginated project list.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ProjectCategory? _selectedCategory;

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

  void _onSearchChanged() {
    setState(() {});
  }

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
      _showError('Could not load projects: $e');
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
      _showError('Could not load more projects: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<_ExplorePageResult> _fetchPage({DocumentSnapshot? startAfter}) async {
    final repository = ref.read(projectRepositoryProvider);
    const limit = 20;

    if (_selectedCategory != null) {
      final result = await repository.fetchProjectsByCategory(
        _selectedCategory!,
        startAfter: startAfter,
        limit: limit,
      );
      return _ExplorePageResult(
        items: result.items,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
      );
    }

    final result = await repository.fetchApprovedProjects(
      startAfter: startAfter,
      limit: limit,
    );
    return _ExplorePageResult(
      items: result.items,
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
    );
  }

  void _selectCategory(ProjectCategory? category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });
    _loadInitial();
  }

  void _openProject(ProjectModel project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: project.projectId),
      ),
    );
  }

  Future<void> _toggleSave(ProjectModel project) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    await ref.read(savedProjectRepositoryProvider).toggleSave(
          uid,
          project.projectId,
        );

    if (!mounted) return;
    final savedIdsAsync = ref.read(savedProjectIdsProvider);
    final isSaved = savedIdsAsync.valueOrNull?.contains(project.projectId) ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved ? 'Saved "${project.name}"' : 'Removed "${project.name}"'),
      ),
    );
  }

  List<ProjectModel> _applySearch(List<ProjectModel> projects) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return projects;
    return projects.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.tagline.toLowerCase().contains(query);
    }).toList();
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

    final featuredAsync = ref.watch(featuredProjectsProvider);
    final savedIdsAsync = ref.watch(savedProjectIdsProvider);

    final displayedProjects = _applySearch(_projects);
    final featured = featuredAsync.valueOrNull ?? [];
    final savedIds = savedIdsAsync.valueOrNull ?? {};

    final showFeatured = featured.isNotEmpty &&
        _searchController.text.isEmpty &&
        _selectedCategory == null;

    return Scaffold(
      backgroundColor: colors.surface,
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
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CategoryFilter(
                selected: _selectedCategory,
                onSelected: _selectCategory,
                colorScheme: colors,
                textTheme: theme.textTheme,
              ),
            ),
            if (showFeatured)
              SliverToBoxAdapter(
                child: _FeaturedCarousel(
                  projects: featured.take(10).toList(),
                  savedIds: savedIds,
                  onTap: _openProject,
                  onSave: _toggleSave,
                  colorScheme: colors,
                  textTheme: theme.textTheme,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Discover',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (displayedProjects.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'No projects found',
                  message: _searchController.text.isNotEmpty
                      ? 'Try a different search term.'
                      : 'Check back later for new listings.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == displayedProjects.length) {
                        return _isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }

                      final project = displayedProjects[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProjectCard(
                          project: project,
                          onTap: () => _openProject(project),
                          isSaved: savedIds.contains(project.projectId),
                          onSave: (_) => _toggleSave(project),
                        ),
                      );
                    },
                    childCount: displayedProjects.length + 1,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _ExplorePageResult {
  const _ExplorePageResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });

  final List<ProjectModel> items;
  final dynamic lastDocument;
  final bool hasMore;
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.selected,
    required this.onSelected,
    required this.colorScheme,
    required this.textTheme,
  });

  final ProjectCategory? selected;
  final ValueChanged<ProjectCategory?> onSelected;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final categories = [null, ...ProjectCategory.values];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selected == category;
          final label = category == null ? 'All' : category.label;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            selectedColor: colorScheme.secondaryContainer,
            labelStyle: textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({
    required this.projects,
    required this.savedIds,
    required this.onTap,
    required this.onSave,
    required this.colorScheme,
    required this.textTheme,
  });

  final List<ProjectModel> projects;
  final Set<String> savedIds;
  final ValueChanged<ProjectModel> onTap;
  final ValueChanged<ProjectModel> onSave;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Featured',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final project = projects[index];
              return SizedBox(
                width: 280,
                child: ProjectCard(
                  project: project,
                  onTap: () => onTap(project),
                  isSaved: savedIds.contains(project.projectId),
                  onSave: (_) => onSave(project),
                  isFeatured: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
