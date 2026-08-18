import 'package:flutter/material.dart';

import '../../../core/models/project_model.dart';
import '../../../core/widgets/app_network_image.dart';

// Project card reused across Explore, Saved, and Profile lists.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.isSaved,
    this.onSave,
    this.isFeatured = false,
  });

  final ProjectModel project;
  final VoidCallback onTap;
  final bool? isSaved;
  final ValueChanged<bool>? onSave;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: project.logoUrl.isNotEmpty
                    ? AppNetworkImage(
                        url: project.logoUrl,
                        borderRadius: BorderRadius.circular(12),
                        errorWidget: Icon(
                          Icons.folder_outlined,
                          color: colors.onPrimaryContainer,
                        ),
                      )
                    : Icon(
                        Icons.folder_outlined,
                        color: colors.onPrimaryContainer,
                      ),
              ),
              const SizedBox(width: 16),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Chip(
                            label: Text(project.category.label),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark_outline,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${project.saveCount}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            if (onSave != null && isSaved != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  isSaved! ? Icons.bookmark : Icons.bookmark_outline,
                                  color: isSaved! ? colors.primary : colors.onSurfaceVariant,
                                ),
                                tooltip: isSaved! ? 'Remove from saved' : 'Save',
                                onPressed: () => onSave!(!isSaved!),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
