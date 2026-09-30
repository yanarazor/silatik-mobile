import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../../../../data/models/latik_experience.dart';
import '../../../../data/models/latik_profile.dart';
import '../../../../providers/latik_service_provider.dart';
import '../../../../providers/profile_menu_provider.dart';
import '../../../shared/confirm_dialog.dart';
import '../../../shared/widgets/latik_info_parts.dart';
import 'experience_card.dart';
import 'experience_form_sheet.dart';

class ExperienceSection extends ConsumerStatefulWidget {
  const ExperienceSection({super.key, required this.profile});

  final LatikProfile profile;

  @override
  ConsumerState<ExperienceSection> createState() => _ExperienceSectionState();
}

class _ExperienceSectionState extends ConsumerState<ExperienceSection> {
  String? _deletingRef;

  Future<void> _openForm([LatikExperience? initial]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExperienceFormSheet(
        initial: initial,
        onSubmit: (experience) async {
          final service = ref.read(latikServiceProvider);
          if (initial == null) {
            await service.savePengalaman(experience.toPayload());
          } else {
            await service.updatePengalaman(
              experience.ref,
              experience.toPayload(),
            );
          }
        },
      ),
    );

    if (changed == true && mounted) {
      final refreshed = await _refreshProfile();
      if (!mounted) return;
      final action = initial == null ? 'ditambahkan' : 'diperbarui';
      _showMessage(
          refreshed
              ? 'Pengalaman LATIK $action'
              : 'Pengalaman LATIK $action, tetapi daftar gagal dimuat ulang',
          error: !refreshed);
    }
  }

  Future<void> _delete(LatikExperience experience) async {
    if (experience.ref.isEmpty || _deletingRef != null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus Pengalaman LATIK dengan ${experience.ippdPengguna} '
          'kegiatan ${experience.objectAudit}',
      message: 'Apakah Anda yakin ingin menghapus pengalaman LATIK ini?',
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingRef = experience.ref);
    try {
      await ref.read(latikServiceProvider).deletePengalaman(experience.ref);
      final refreshed = await _refreshProfile();
      if (mounted) {
        _showMessage(
          refreshed
              ? 'Pengalaman LATIK dihapus'
              : 'Pengalaman LATIK dihapus, tetapi daftar gagal dimuat ulang',
          error: !refreshed,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(ApiErrorHandler.messageFrom(error), error: true);
      }
    } finally {
      if (mounted) setState(() => _deletingRef = null);
    }
  }

  Future<bool> _refreshProfile() async {
    ref.invalidate(latikProfileProvider);
    try {
      await ref.read(latikProfileProvider.future);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.success,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final experiences = widget.profile.experiences;
    return LatikInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: LatikSectionTitle('Pengalaman LATIK')),
              if (experiences.isNotEmpty)
                ExperienceCountBadge(experiences.length),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          if (experiences.isEmpty)
            const EmptyExperience()
          else
            for (final experience in experiences)
              ExperienceCard(
                key: ValueKey(experience.ref),
                experience: experience,
                editable: widget.profile.editable,
                deleting: _deletingRef == experience.ref,
                actionsEnabled: _deletingRef == null,
                onEdit: () => _openForm(experience),
                onDelete: () => _delete(experience),
              ),
          if (widget.profile.editable) ...[
            const SizedBox(height: AppTheme.spacing8),
            OutlinedButton.icon(
              onPressed: _deletingRef == null ? _openForm : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Pengalaman LATIK'),
            ),
          ],
        ],
      ),
    );
  }
}
