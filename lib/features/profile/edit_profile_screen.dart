import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/activity_log_entry.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repositories_provider.dart';
import '../../core/utils/formatters.dart';

// Edit profile screen. Only writes safe fields; Firestore rules block
// role/isSuspension changes.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _ageController;
  late final TextEditingController _skillsController;
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _twitterController;
  late final TextEditingController _linkedinController;
  late final TextEditingController _websiteController;

  bool _isLoading = false;
  String _avatarUrl = '';
  Profession _profession = Profession.other;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProfileProvider).valueOrNull ??
        const UserModel(uid: '');
    _firstNameController = TextEditingController(text: user.firstName);
    _lastNameController = TextEditingController(text: user.lastName);
    _ageController =
        TextEditingController(text: user.age != null ? '${user.age}' : '');
    _skillsController = TextEditingController(text: user.skills.join(', '));
    _nameController = TextEditingController(text: user.displayName);
    _bioController = TextEditingController(text: user.bio);
    _twitterController = TextEditingController(text: user.socialLinks.twitter);
    _linkedinController = TextEditingController(text: user.socialLinks.linkedin);
    _websiteController = TextEditingController(text: user.socialLinks.website);
    _avatarUrl = user.photoUrl;
    _profession = user.profession;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _skillsController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      _showError('You must be signed in to update your profile.');
      return;
    }

    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText);
    if (age == null || age < 13 || age > 100) {
      _showError('Please enter a valid age between 13 and 100.');
      return;
    }

    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(20)
        .toList();

    setState(() => _isLoading = true);

    try {
      await ref.read(userRepositoryProvider).updateProfile(
            uid: uid,
            displayName: _nameController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            age: age,
            profession: _profession,
            skills: skills,
            bio: _bioController.text.trim(),
            photoUrl: _avatarUrl,
            socialLinks: {
              'twitter': _twitterController.text.trim(),
              'linkedin': _linkedinController.text.trim(),
              'website': _websiteController.text.trim(),
            },
          );

      await ref.read(activityLogRepositoryProvider).log(
            uid: uid,
            action: ActivityAction.profileUpdated,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      _showError('Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isLoading = true);

    try {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) {
        _showError('You must be signed in to update your avatar.');
        return;
      }

      final url = await ref.read(storageServiceProvider).uploadAvatar(
            uid: uid,
            file: file,
          );

      if (!mounted) return;
      if (url == null) {
        _showError('Could not upload avatar. Check your Cloudinary preset and network.');
        return;
      }

      setState(() => _avatarUrl = url);
    } on Exception catch (e) {
      if (!mounted) return;
      _showError('Failed to upload avatar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: colors.primaryContainer,
                            backgroundImage: _avatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(_avatarUrl)
                                : null,
                            child: _avatarUrl.isEmpty
                                ? Text(
                                    getInitials(_nameController.text),
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: colors.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          Material(
                            shape: const CircleBorder(),
                            color: colors.primary,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _pickAvatar,
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
                    const SizedBox(height: 32),
                    Text(
                      'Personal info',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            maxLength: 50,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (value.length > 50) return 'Max 50 chars';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            maxLength: 50,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (value.length > 50) return 'Max 50 chars';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final n = int.tryParse(value?.trim() ?? '');
                              if (n == null || n < 13 || n > 100) {
                                return 'Age 13–100';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<Profession>(
                            value: _profession,
                            decoration: const InputDecoration(
                              labelText: 'Profession',
                              prefixIcon: Icon(Icons.work_outline),
                            ),
                            items: Profession.values.map((profession) {
                              return DropdownMenuItem(
                                value: profession,
                                child: Text(profession.label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _profession = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        labelText: 'Skills (comma separated)',
                        prefixIcon: Icon(Icons.lightbulb_outline),
                        helperText: 'e.g. Flutter, Firebase, UI Design',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Public info',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a display name';
                        }
                        if (value.length > 50) {
                          return 'Max 50 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        prefixIcon: Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      maxLength: 300,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Social links',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _twitterController,
                      decoration: const InputDecoration(
                        labelText: 'Twitter / X',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _linkedinController,
                      decoration: const InputDecoration(
                        labelText: 'LinkedIn',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        prefixIcon: Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
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
                          : const Text('Save profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
