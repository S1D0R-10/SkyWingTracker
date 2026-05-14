import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/core/supabase_client.dart';
import 'package:skywing_tracker/features/pigeons/models/pigeon.dart';
import 'package:skywing_tracker/features/pigeons/providers/pigeon_provider.dart';

class CreateEditPigeonScreen extends ConsumerStatefulWidget {
  final String? pigeonId;

  const CreateEditPigeonScreen({super.key, this.pigeonId});

  @override
  ConsumerState<CreateEditPigeonScreen> createState() =>
      _CreateEditPigeonScreenState();
}

class _CreateEditPigeonScreenState
    extends ConsumerState<CreateEditPigeonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ringNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _healthNotesController = TextEditingController();

  String _selectedSex = 'male';
  DateTime? _hatchDate;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get _isEditing => widget.pigeonId != null;

  @override
  void dispose() {
    _ringNumberController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _healthNotesController.dispose();
    super.dispose();
  }

  void _populateFields(Pigeon pigeon) {
    if (_isInitialized) return;
    _ringNumberController.text = pigeon.ringNumber;
    _nameController.text = pigeon.name;
    _breedController.text = pigeon.breed;
    _colorController.text = pigeon.color ?? '';
    _healthNotesController.text = pigeon.healthNotes ?? '';
    _selectedSex = pigeon.sex;
    _hatchDate = pigeon.hatchDate;
    _imageUrl = pigeon.imageUrl;
    _isInitialized = true;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // In a real app, upload to Supabase Storage and get URL
      setState(() => _imageUrl = image.path);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hatchDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.card,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _hatchDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(pigeonRepositoryProvider);
      final now = DateTime.now();

      if (_isEditing) {
        final existing = await repository.getPigeonById(widget.pigeonId!);
        if (existing == null) throw Exception('Pigeon not found');

        final updated = existing.copyWith(
          ringNumber: _ringNumberController.text.trim(),
          name: _nameController.text.trim(),
          sex: _selectedSex,
          breed: _breedController.text.trim(),
          color: _colorController.text.trim().isEmpty
              ? null
              : _colorController.text.trim(),
          hatchDate: _hatchDate,
          healthNotes: _healthNotesController.text.trim().isEmpty
              ? null
              : _healthNotesController.text.trim(),
          imageUrl: _imageUrl,
          updatedAt: now,
        );
        await repository.updatePigeon(updated);
      } else {
        final currentUserId = supabase.auth.currentUser?.id ?? '';
        final pigeon = Pigeon(
          id: const Uuid().v4(),
          ownerId: currentUserId,
          ringNumber: _ringNumberController.text.trim(),
          name: _nameController.text.trim(),
          sex: _selectedSex,
          breed: _breedController.text.trim(),
          color: _colorController.text.trim().isEmpty
              ? null
              : _colorController.text.trim(),
          hatchDate: _hatchDate,
          healthNotes: _healthNotesController.text.trim().isEmpty
              ? null
              : _healthNotesController.text.trim(),
          imageUrl: _imageUrl,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await repository.createPigeon(pigeon);
      }

      ref.invalidate(pigeonsProvider);
      if (mounted) context.go('/pigeons');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      final pigeonAsync = ref.watch(pigeonByIdProvider(widget.pigeonId!));
      pigeonAsync.whenData((pigeon) {
        if (pigeon != null) _populateFields(pigeon);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Pigeon' : 'Add Pigeon')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: _imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _ImagePickerPlaceholder(),
                        ),
                      )
                    : const _ImagePickerPlaceholder(),
              ),
            ),
            const SizedBox(height: 24),

            // Ring Number
            TextFormField(
              controller: _ringNumberController,
              decoration: const InputDecoration(
                labelText: 'Ring Number *',
                prefixIcon: Icon(Icons.tag, color: AppColors.textSecondary),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Ring number is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(
                  Icons.flutter_dash,
                  color: AppColors.textSecondary,
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Sex dropdown
            DropdownButtonFormField<String>(
              value: _selectedSex,
              decoration: const InputDecoration(
                labelText: 'Sex *',
                prefixIcon: Icon(Icons.wc, color: AppColors.textSecondary),
              ),
              dropdownColor: AppColors.card,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _selectedSex = v!),
            ),
            const SizedBox(height: 16),

            // Breed
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(
                labelText: 'Breed *',
                prefixIcon: Icon(
                  Icons.category,
                  color: AppColors.textSecondary,
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Breed is required' : null,
            ),
            const SizedBox(height: 16),

            // Color
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color',
                prefixIcon: Icon(Icons.palette, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Hatch Date
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Hatch Date',
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      color: AppColors.textSecondary,
                    ),
                    hintText: _hatchDate != null
                        ? '${_hatchDate!.day}/${_hatchDate!.month}/${_hatchDate!.year}'
                        : 'Select date',
                  ),
                  controller: TextEditingController(
                    text: _hatchDate != null
                        ? '${_hatchDate!.day}/${_hatchDate!.month}/${_hatchDate!.year}'
                        : '',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Health Notes
            TextFormField(
              controller: _healthNotesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Health Notes',
                prefixIcon: Icon(
                  Icons.medical_services,
                  color: AppColors.textSecondary,
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Add Pigeon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerPlaceholder extends StatelessWidget {
  const _ImagePickerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 40, color: AppColors.textSecondary),
        SizedBox(height: 8),
        Text(
          'Tap to add photo',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
