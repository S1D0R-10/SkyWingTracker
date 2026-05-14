import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/flights/models/flight_session.dart';
import 'package:skywing_tracker/features/flights/providers/flight_provider.dart';

class FlightReturnRegistrationScreen extends ConsumerStatefulWidget {
  final String flightId;
  final String participantId;

  const FlightReturnRegistrationScreen({
    super.key,
    required this.flightId,
    required this.participantId,
  });

  @override
  ConsumerState<FlightReturnRegistrationScreen> createState() =>
      _FlightReturnRegistrationScreenState();
}

class _FlightReturnRegistrationScreenState
    extends ConsumerState<FlightReturnRegistrationScreen> {
  late DateTime _returnTime;
  final _notesController = TextEditingController();
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _returnTime = DateTime.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
  }

  Future<void> _saveReturn() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(flightRepositoryProvider);
      final participants = await repo.getParticipants(widget.flightId);
      final participant = participants.firstWhere(
        (p) => p.id == widget.participantId,
      );

      final updated = participant.copyWith(
        status: FlightStatus.returned,
        returnTime: _returnTime,
        conditionNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await repo.updateParticipant(updated);

      ref.invalidate(participantsProvider(widget.flightId));
      ref.invalidate(liveParticipantsProvider(widget.flightId));

      if (mounted) {
        context.go('/flights/${widget.flightId}/live');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editReturnTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _returnTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_returnTime),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _returnTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(participantsProvider(widget.flightId));

    return Scaffold(
      appBar: AppBar(title: const Text('Register Return')),
      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (participants) {
          final participant = participants
              .where((p) => p.id == widget.participantId)
              .firstOrNull;

          if (participant == null) {
            return const Center(child: Text('Participant not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pigeon info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flutter_dash,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participant.pigeonName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          participant.pigeonRingNumber,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Return time
              const Text(
                'Return Time',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _editReturnTime,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatDateTime(_returnTime),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Condition notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Condition Notes (optional)',
                  hintText: 'e.g. Good condition, slight fatigue',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Photo capture
              const Text(
                'Photo (optional)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _photoPath != null
                          ? AppColors.success
                          : AppColors.divider,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _photoPath != null
                      ? Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                _photoPath!,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              color: AppColors.textSecondary,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to capture photo',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _saving ? null : _saveReturn,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text('Save Return'),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
