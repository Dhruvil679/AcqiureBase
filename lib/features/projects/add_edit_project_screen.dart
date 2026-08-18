import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/activity_log_entry.dart';
import '../../core/models/project_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/widgets/app_network_image.dart';

// Screen for creating or editing a project. New submissions start as pending
// for moderation.
class AddEditProjectScreen extends ConsumerStatefulWidget {
  const AddEditProjectScreen({super.key, this.projectId});

  // null = create a new project; set = edit the existing one.
  final String? projectId;

  @override
  ConsumerState<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends ConsumerState<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _businessAgeController = TextEditingController();
  final _monthlyVisitorsController = TextEditingController();
  final _founderNameController = TextEditingController();
  final _founderBioController = TextEditingController();

  ProjectCategory _category = ProjectCategory.other;
  String _logoUrl = '';
  final List<String> _screenshotUrls = [];
  final List<String> _documentUrls = [];

  bool _isLoading = false;
  bool _isNew = true;
  ProjectModel? _existing;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _isNew = widget.projectId == null;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final repository = ref.read(projectRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).valueOrNull;

    if (!_isNew) {
      final project = await repository.getProjectById(widget.projectId!);
      if (project != null && mounted) {
        setState(() {
          _existing = project;
          _nameController.text = project.name;
          _taglineController.text = project.tagline;
          _descriptionController.text = project.description;
          _websiteController.text = project.websiteUrl;
          _businessAgeController.text = project.businessAge;
          _monthlyVisitorsController.text = project.monthlyVisitors;
          _founderNameController.text = project.founderName;
          _founderBioController.text = project.founderBio;
          _category = project.category;
          _logoUrl = project.logoUrl;
          _screenshotUrls.addAll(project.screenshotUrls);
          _documentUrls.addAll(project.documentUrls);
          _initialized = true;
        });
        return;
      }
    } else {
      _founderNameController.text = user?.displayName ?? '';
      _founderBioController.text = user?.bio ?? '';
    }

    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _businessAgeController.dispose();
    _monthlyVisitorsController.dispose();
    _founderNameController.dispose();
    _founderBioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    final uid = currentUser?.uid;
    if (uid == null) {
      _showError('You must be signed in to publish a project.');
      return;
    }

    // New submissions need a verified email. This stops spam accounts from
    // flooding the moderation queue.
    if (_isNew) {
      final verified = await _isEmailVerified();
      if (!verified) {
        if (mounted) await _showEmailVerificationDialog();
        return;
      }
    }

    setState(() => _isLoading = true);

    if (_isNew) {
      try {
        final rateStatus = await ref
            .read(projectFunctionsServiceProvider)
            .checkProjectSubmissionRate();
        if (!rateStatus.allowed) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showError(
            'Submission limit reached. You can submit ${rateStatus.remaining} more '
            'project(s) after ${rateStatus.resetAt ?? 'the cooldown period'}.',
          );
          return;
        }
      } on Exception catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError('Could not check submission rate: $e');
        return;
      }
    }

    final now = DateTime.now();
    final project = ProjectModel(
      projectId: _existing?.projectId ?? 'proj_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: uid,
      name: _nameController.text.trim(),
      logoUrl: _logoUrl,
      tagline: _taglineController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      websiteUrl: _websiteController.text.trim(),
      businessAge: _businessAgeController.text.trim(),
      monthlyVisitors: _monthlyVisitorsController.text.trim(),
      screenshotUrls: List.from(_screenshotUrls),
      documentUrls: List.from(_documentUrls),
      founderName: _founderNameController.text.trim(),
      founderBio: _founderBioController.text.trim(),
      status: _existing?.status ?? 'pending',
      isFeatured: _existing?.isFeatured ?? false,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
      saveCount: _existing?.saveCount ?? 0,
      viewCount: _existing?.viewCount ?? 0,
    );

    final repository = ref.read(projectRepositoryProvider);
    if (_isNew) {
      await repository.createProject(project);
      await ref.read(projectFunctionsServiceProvider).recordProjectSubmission();
      await _logActivity(
        ActivityAction.projectPublished,
        {'projectId': project.projectId, 'projectName': project.name},
      );
    } else {
      await repository.updateProject(
        project,
        editedBy: uid,
      );
      await _logActivity(
        ActivityAction.projectEdited,
        {'projectId': project.projectId, 'projectName': project.name},
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isNew
              ? 'Project submitted for review.'
              : 'Project updated successfully.',
        ),
      ),
    );
  }

  Future<bool> _isEmailVerified() async {
    final auth = ref.read(authServiceProvider);
    await auth.reloadCurrentUser();
    return auth.currentUser?.emailVerified ?? false;
  }

  Future<void> _showEmailVerificationDialog() async {
    final auth = ref.read(authServiceProvider);
    final colors = Theme.of(context).colorScheme;

    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify your email'),
        content: const Text(
          'You need to verify your email address before publishing a project. '
          'Tap resend to get a new verification link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resend email'),
          ),
        ],
      ),
    );

    if (sent == true) {
      try {
        await auth.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verification email sent.'),
              backgroundColor: colors.primary,
            ),
          );
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not send verification email: $e'),
              backgroundColor: colors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isLoading = true);

    try {
      final projectId = _existing?.projectId ??
          'proj_${DateTime.now().millisecondsSinceEpoch}';
      final url = await ref.read(storageServiceProvider).uploadProjectLogo(
            projectId: projectId,
            file: file,
          );

      if (!mounted) return;
      if (url == null) {
        _showError('Could not upload logo. Check your Cloudinary preset and network.');
        return;
      }
      setState(() => _logoUrl = url);
    } on Exception catch (e) {
      if (!mounted) return;
      _showError('Failed to upload logo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isLoading = true);

    try {
      final projectId = _existing?.projectId ??
          'proj_${DateTime.now().millisecondsSinceEpoch}';
      final url = await ref.read(storageServiceProvider).uploadProjectScreenshot(
            projectId: projectId,
            file: file,
          );

      if (!mounted) return;
      if (url == null) {
        _showError('Could not upload screenshot. Check your Cloudinary preset and network.');
        return;
      }
      setState(() => _screenshotUrls.add(url));
    } on Exception catch (e) {
      if (!mounted) return;
      _showError('Failed to upload screenshot: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() => _isLoading = true);

    try {
      final projectId = _existing?.projectId ??
          'proj_${DateTime.now().millisecondsSinceEpoch}';
      final url = await ref.read(storageServiceProvider).uploadProjectDocument(
            projectId: projectId,
            file: file,
          );

      if (!mounted) return;
      if (url == null) {
        _showError('Could not upload document. Check your Cloudinary preset and network.');
        return;
      }
      setState(() => _documentUrls.add(url));
    } on Exception catch (e) {
      if (!mounted) return;
      _showError('Failed to upload document: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removeScreenshot(String url) {
    setState(() => _screenshotUrls.remove(url));
  }

  void _removeDocument(String url) {
    setState(() => _documentUrls.remove(url));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _logActivity(ActivityAction action, Map<String, dynamic> metadata) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    await ref.read(activityLogRepositoryProvider).log(
          uid: uid,
          action: action,
          metadata: metadata,
        );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (!_initialized) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: Text(_isNew ? 'Add project' : 'Edit project'),
          backgroundColor: colors.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(_isNew ? 'Add project' : 'Edit project'),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(theme, colors, 'Project details'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Project name',
                      prefixIcon: Icon(Icons.folder_outlined),
                    ),
                    validator: (value) => _required(value, 'project name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taglineController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tagline',
                      prefixIcon: Icon(Icons.short_text),
                    ),
                    validator: (value) => _required(value, 'tagline'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    textInputAction: TextInputAction.next,
                    maxLines: 5,
                    minLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => _required(value, 'description'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ProjectCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: ProjectCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Website URL',
                      prefixIcon: Icon(Icons.language_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(theme, colors, 'Business'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _businessAgeController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Business age',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _monthlyVisitorsController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Monthly visitors',
                            prefixIcon: Icon(Icons.people_outline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(theme, colors, 'Founder'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _founderNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Founder name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => _required(value, 'founder name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _founderBioController,
                    textInputAction: TextInputAction.next,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Founder bio',
                      prefixIcon: Icon(Icons.info_outline),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(theme, colors, 'Media'),
                  const SizedBox(height: 16),
                  _LogoPicker(
                    url: _logoUrl,
                    onPick: _isLoading ? null : _pickLogo,
                    colors: colors,
                    theme: theme,
                  ),
                  const SizedBox(height: 24),
                  _MediaListEditor(
                    title: 'Screenshots',
                    urls: _screenshotUrls,
                    icon: Icons.image_outlined,
                    addLabel: 'Add screenshot',
                    onAdd: _isLoading ? null : _pickScreenshot,
                    onRemove: _removeScreenshot,
                  ),
                  const SizedBox(height: 24),
                  _MediaListEditor(
                    title: 'Documents',
                    urls: _documentUrls,
                    icon: Icons.description_outlined,
                    addLabel: 'Add document',
                    onAdd: _isLoading ? null : _pickDocument,
                    onRemove: _removeDocument,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(_isNew ? 'Submit project' : 'Save changes'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, ColorScheme colors, String text) {
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.url,
    required this.onPick,
    required this.colors,
    required this.theme,
  });

  final String url;
  final VoidCallback? onPick;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: url.isNotEmpty
                    ? AppNetworkImage(
                        url: url,
                        borderRadius: BorderRadius.circular(24),
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
              Material(
                shape: const CircleBorder(),
                color: colors.primary,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPick,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaListEditor extends StatelessWidget {
  const _MediaListEditor({
    required this.title,
    required this.urls,
    required this.icon,
    required this.addLabel,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final List<String> urls;
  final IconData icon;
  final String addLabel;
  final VoidCallback? onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: urls.map((url) {
            return InputChip(
              label: Text(
                _fileName(url),
                overflow: TextOverflow.ellipsis,
              ),
              avatar: Icon(icon, size: 18),
              onDeleted: () => onRemove(url),
              deleteIconColor: colors.onSecondaryContainer,
              backgroundColor: colors.secondaryContainer,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }

  String _fileName(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastSlash = path.lastIndexOf('/');
      if (lastSlash == -1) return url;
      final name = path.substring(lastSlash + 1);
      return name.isNotEmpty ? name : url;
    } catch (_) {
      return url;
    }
  }
}
