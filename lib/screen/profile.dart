import 'package:flutter/material.dart';
import '../model/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../widget/gradient_button.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile? initialUser;
  const ProfileScreen({super.key, this.initialUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _user;

  @override
  void initState() {
    super.initState();
    _user =
        widget.initialUser ??
        UserProfile(
          name: 'Brylle',
          email: 'brylle@example.com',
          contact: '0912 345 6789',
          address: 'Quezon City, Philippines',
          bloodType: 'O+',
        );
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _EditProfileForm(
        user: _user,
        onSave: (updatedUser) async {
          // Save to Laravel first.
          final savedUser = await ApiService.updateProfile(
            profile: updatedUser,
          );

          if (!mounted) return;

          // Update the screen only after Laravel confirms success.
          setState(() {
            _user = savedUser;
          });

          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(
            alpha: isDark ? 0.35 : 0.15,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.14),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Profile',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, _user),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: isDark ? 0.45 : 0.7,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Blood type ${_user.bloodType}',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _editProfile,
                    tooltip: 'Edit Profile',
                    icon: Icon(
                      Icons.edit_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ProfileItem(
              icon: Icons.email_outlined,
              label: 'Email Address',
              value: _user.email,
            ),
            const Divider(height: 24),
            _ProfileItem(
              icon: Icons.phone_outlined,
              label: 'Contact Number',
              value: _user.contact,
            ),
            const Divider(height: 24),
            _ProfileItem(
              icon: Icons.location_on_outlined,
              label: 'Home Address',
              value: _user.address,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'EDIT PROFILE',
                icon: Icons.edit_rounded,
                onTap: _editProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  final UserProfile user;
final Future<void> Function(UserProfile) onSave;

  const _EditProfileForm({required this.user, required this.onSave});

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late String _bloodType;

  

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _contactController = TextEditingController(text: widget.user.contact);
    _addressController = TextEditingController(text: widget.user.address);
    _bloodType = widget.user.bloodType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
TextFormField(
  initialValue: _bloodType,
  readOnly: true,
  decoration: const InputDecoration(
    labelText: 'Blood Type',
    prefixIcon: Icon(Icons.bloodtype_outlined),
    helperText: 'Contact an administrator to request a correction.',
  ),
),

              const SizedBox(height: 32),
           
SizedBox(
  width: double.infinity,
  child: GradientButton(
    label: _saving ? 'SAVING...' : 'SAVE CHANGES',
    onTap: () async {
      if (_saving || !_formKey.currentState!.validate()) {
        return;
      }

      setState(() => _saving = true);

      try {
        await widget.onSave(
          UserProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            contact: _contactController.text.trim(),
            address: _addressController.text.trim(),
            bloodType: _bloodType,
          ),
        );
          if (!mounted) return;

          Navigator.pop(this.context);
        } catch (e) {
          if (!mounted) return;

          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceFirst('Exception: ', ''),
              ),
              backgroundColor: Colors.red,
            ),
          );
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    },
  ),
),
  
            ],
          ),
        ),
      ),
    );
  }
}
