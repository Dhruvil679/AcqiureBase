import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/home_shell.dart';
import '../../core/services/user_service.dart';
import 'login_screen.dart';

// Sign-up screen. Creates a Firebase Auth account and the matching Firestore
// user document.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

enum _UsernameAvailability { unknown, checking, available, taken, invalid }

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _customSkillController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Profession? _profession;
  final List<String> _selectedSkills = [];

  Timer? _usernameDebounceTimer;
  _UsernameAvailability _usernameAvailability = _UsernameAvailability.unknown;

  static const List<String> _starterSkills = [
    'Flutter',
    'React',
    'Python',
    'UI/UX Design',
    'Marketing',
    'Sales',
    'Product Management',
    'Data Science',
    'Writing',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    _usernameDebounceTimer?.cancel();
    final normalized = UserService.normalizeUsername(_usernameController.text);

    if (!UserService.isValidUsername(normalized)) {
      setState(() {
        _usernameAvailability = _UsernameAvailability.invalid;
      });
      return;
    }

    setState(() {
      _usernameAvailability = _UsernameAvailability.checking;
    });

    _usernameDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final userService = ref.read(userServiceProvider);
      final available = await userService.isUsernameAvailable(normalized);
      if (!mounted) return;
      setState(() {
        _usernameAvailability = available
            ? _UsernameAvailability.available
            : _UsernameAvailability.taken;
      });
    });
  }

  @override
  void dispose() {
    _usernameDebounceTimer?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      _showError('Please select at least one skill.');
      return;
    }
    if (_profession == null) {
      _showError('Please select your profession.');
      return;
    }

    final normalizedUsername =
        UserService.normalizeUsername(_usernameController.text);
    if (!UserService.isValidUsername(normalizedUsername)) {
      _showError('Please enter a valid username.');
      return;
    }
    if (_usernameAvailability == _UsernameAvailability.taken) {
      _showError('That username is already taken. Try another one.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final userService = ref.read(userServiceProvider);

      final credential = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;
      if (user == null) throw StateError('Account creation failed');

      await userService.createUserDocument(
        user: user,
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        skills: List.from(_selectedSkills),
        profession: _profession!,
      );

      await authService.sendEmailVerification();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome! Verify your email before publishing projects.'),
        ),
      );
    } on UsernameAlreadyTakenException catch (_) {
      if (!mounted) return;
      _showError('That username is already taken. Try another one.');
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(_friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  void _addCustomSkill() {
    final skill = _customSkillController.text.trim();
    if (skill.isEmpty) return;
    if (_selectedSkills.contains(skill)) {
      _customSkillController.clear();
      return;
    }
    setState(() {
      _selectedSkills.add(skill);
      _customSkillController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() => _selectedSkills.remove(skill));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  String _friendlyAuthError(Exception e) {
    final message = e.toString().toLowerCase();
    debugPrint('Registration error: $e');
    if (message.contains('email-already-in-use')) {
      return 'An account already exists for this email.';
    }
    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (message.contains('network-request-failed') || message.contains('unavailable')) {
      return 'Network error. Check your connection and try again.';
    }
    if (message.contains('permission-denied')) {
      return 'Registration was blocked by server rules. Please try again.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    // Show the raw error for unknown cases so we can diagnose quickly.
    final raw = e.toString();
    if (raw.length > 120) {
      return 'Error: ${raw.substring(0, 120)}...';
    }
    return 'Error: $raw';
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }
    final normalized = UserService.normalizeUsername(value);
    if (!UserService.isValidUsername(normalized)) {
      return '3–20 lowercase letters, numbers, or underscores';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create account',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join AcquireBase to discover and publish products.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(theme, colors, 'Account'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() =>
                                _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(theme, colors, 'About you'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.alternate_email),
                        suffixIcon: _buildUsernameSuffix(),
                        helperText: '3–20 lowercase letters, numbers, or underscores',
                      ),
                      validator: _validateUsername,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'First name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (value.length > 50) {
                                return 'Max 50 chars';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Surname',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (value.length > 50) {
                                return 'Max 50 chars';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your age';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 13 || age > 100) {
                          return 'Age must be between 13 and 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Current profession',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Profession>(
                      initialValue: _profession,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      hint: const Text('Select profession'),
                      items: Profession.values.map((profession) {
                        return DropdownMenuItem(
                          value: profession,
                          child: Text(profession.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _profession = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Skills',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SkillsSelector(
                      starterSkills: _starterSkills,
                      selectedSkills: _selectedSkills,
                      onToggle: _toggleSkill,
                      onRemove: _removeSkill,
                    ),
                    if (_selectedSkills.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Select at least one skill',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customSkillController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Add a custom skill',
                              prefixIcon: Icon(Icons.add_circle_outline),
                            ),
                            onFieldSubmitted: (_) => _addCustomSkill(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: _addCustomSkill,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('Sign Up'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text('Sign In'),
                        ),
                      ],
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

  Widget _buildSectionTitle(ThemeData theme, ColorScheme colors, String text) {
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget? _buildUsernameSuffix() {
    switch (_usernameAvailability) {
      case _UsernameAvailability.unknown:
      case _UsernameAvailability.invalid:
        return null;
      case _UsernameAvailability.checking:
        return const SizedBox(
          width: 20,
          height: 20,
          child: Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _UsernameAvailability.available:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case _UsernameAvailability.taken:
        return const Icon(Icons.cancel, color: Colors.red, size: 20);
    }
  }
}

class _SkillsSelector extends StatelessWidget {
  const _SkillsSelector({
    required this.starterSkills,
    required this.selectedSkills,
    required this.onToggle,
    required this.onRemove,
  });

  final List<String> starterSkills;
  final List<String> selectedSkills;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...starterSkills.map((skill) {
          final isSelected = selectedSkills.contains(skill);
          return FilterChip(
            label: Text(skill),
            selected: isSelected,
            onSelected: (_) => onToggle(skill),
            selectedColor: colors.secondaryContainer,
            checkmarkColor: colors.onSecondaryContainer,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? colors.onSecondaryContainer
                  : colors.onSurfaceVariant,
            ),
          );
        }),
        ...selectedSkills
            .where((skill) => !starterSkills.contains(skill))
            .map((skill) {
          return InputChip(
            label: Text(skill),
            onDeleted: () => onRemove(skill),
            deleteIconColor: colors.onSecondaryContainer,
            backgroundColor: colors.secondaryContainer,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSecondaryContainer,
            ),
          );
        }),
      ],
    );
  }
}
