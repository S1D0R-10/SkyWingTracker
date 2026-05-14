import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/core/supabase_client.dart';
import 'package:skywing_tracker/features/auth/models/user_profile.dart';
import 'package:skywing_tracker/features/auth/providers/auth_provider.dart';
import 'package:skywing_tracker/features/profile/models/user_settings.dart';
import 'package:skywing_tracker/features/profile/providers/profile_provider.dart';
import 'package:skywing_tracker/shared/widgets/app_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _clubNameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _useKilometers = true;
  bool _notifyFlightStart = true;
  bool _notifyOverdue = true;
  bool _notifyReturnReminder = true;
  bool _notifyInactive = false;
  bool _notifyDeclinePerformance = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _clubNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initFromProfile(UserProfile profile, UserSettings settings) {
    if (_initialized) return;
    _initialized = true;
    _displayNameController.text = profile.displayName;
    _clubNameController.text = profile.clubName ?? '';
    _locationController.text = profile.breederLocation ?? '';
    _useKilometers = settings.useKilometers;
    _notifyFlightStart = settings.notifyFlightStart;
    _notifyOverdue = settings.notifyOverdue;
    _notifyReturnReminder = settings.notifyReturnReminder;
    _notifyInactive = settings.notifyInactive;
    _notifyDeclinePerformance = settings.notifyDeclinePerformance;
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(userId, bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avatar updated')));
      if (url != null) ref.invalidate(userProfileProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
    }
  }

  Future<void> _save(UserProfile profile) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = profile.copyWith(
        displayName: _displayNameController.text.trim(),
        clubName: _clubNameController.text.trim().isEmpty
            ? null
            : _clubNameController.text.trim(),
        breederLocation: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        useKilometers: _useKilometers,
      );
      final settings = UserSettings(
        userId: profile.id,
        useKilometers: _useKilometers,
        notifyFlightStart: _notifyFlightStart,
        notifyOverdue: _notifyOverdue,
        notifyReturnReminder: _notifyReturnReminder,
        notifyInactive: _notifyInactive,
        notifyDeclinePerformance: _notifyDeclinePerformance,
      );
      await ref.read(profileRepositoryProvider).updateProfile(updated);
      await ref.read(profileRepositoryProvider).updateSettings(settings);
      ref.invalidate(userProfileProvider);
      ref.invalidate(userSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final settingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: _logout,
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }
          return settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (settings) {
              _initFromProfile(profile, settings);
              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadAvatar,
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: AppColors.card,
                              backgroundImage: profile.avatarUrl != null
                                  ? CachedNetworkImageProvider(
                                      profile.avatarUrl!,
                                    )
                                  : null,
                              child: profile.avatarUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 52,
                                      color: AppColors.textSecondary,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Fields
                    _buildSectionTitle('Personal Info'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clubNameController,
                      decoration: const InputDecoration(
                        labelText: 'Club Name',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Breeder Location',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Units'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _unitChip(
                            'km',
                            _useKilometers,
                            () => setState(() => _useKilometers = true),
                          ),
                          _unitChip(
                            'miles',
                            !_useKilometers,
                            () => setState(() => _useKilometers = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Notifications'),
                    const SizedBox(height: 8),
                    _notifTile(
                      'Flight started',
                      _notifyFlightStart,
                      (v) => setState(() => _notifyFlightStart = v),
                    ),
                    _notifTile(
                      'Pigeon overdue',
                      _notifyOverdue,
                      (v) => setState(() => _notifyOverdue = v),
                    ),
                    _notifTile(
                      'Return reminder',
                      _notifyReturnReminder,
                      (v) => setState(() => _notifyReturnReminder = v),
                    ),
                    _notifTile(
                      'Inactive 14+ days',
                      _notifyInactive,
                      (v) => setState(() => _notifyInactive = v),
                    ),
                    _notifTile(
                      'Declining performance',
                      _notifyDeclinePerformance,
                      (v) => setState(() => _notifyDeclinePerformance = v),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Save Profile',
                      isLoading: _isSaving,
                      onPressed: () => _save(profile),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Logout',
                      variant: AppButtonVariant.danger,
                      onPressed: _logout,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
        letterSpacing: 1,
      ),
    );
  }

  Widget _unitChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _notifTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        title: Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accent,
        dense: true,
      ),
    );
  }
}
