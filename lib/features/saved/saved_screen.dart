import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/project_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../projects/project_detail_screen.dart';
import '../projects/widgets/project_card.dart';

// Saved projects tab — swipe a card to remove it.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, ProjectModel project) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    await ref.read(savedProjectRepositoryProvider).removeSave(uid, project.projectId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed "${project.name}" from saved.')),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final savedAsync = ref.watch(savedProjectsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Saved'),
      ),
      body: SafeArea(
        child: savedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Could not load saved projects.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          data: (saved) => saved.isEmpty
              ? _EmptyState(theme: theme, colors: colors)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: saved.length,
                  itemBuilder: (context, index) {
                    final project = saved[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey(project.projectId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bookmark_remove_outlined,
                            color: colors.onErrorContainer,
                          ),
                        ),
                        onDismissed: (_) => _remove(context, ref, project),
                        child: ProjectCard(
                          project: project,
                          onTap: () => _openProject(context, project),
                          isSaved: true,
                          onSave: (_) => _remove(context, ref, project),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme, required this.colors});

  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 72,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing saved yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark on a project to save it for later.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
