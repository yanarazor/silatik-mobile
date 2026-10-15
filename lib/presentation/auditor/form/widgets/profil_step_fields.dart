import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/url_opener.dart';
import '../../../../data/models/master_data_model.dart';
import '../../../../data/models/registrasi_model.dart';
import '../../../../providers/master_data_provider.dart';
import '../../../shared/dokumen_upload_card.dart';
import '../../../shared/dropdown_states.dart';
import '../../../shared/field_label.dart';

class AgamaDropdown extends ConsumerWidget {
  const AgamaDropdown({super.key, required this.form});

  final FormGroup form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agamaListProvider);
    return async.when(
      loading: () => const DropdownLoading(),
      error: (_, __) => ReactiveDropdownField<String>(
        formControlName: 'agama',
        decoration: const InputDecoration(
          hintText: 'Agama tidak tersedia',
          prefixIcon: Icon(Icons.self_improvement_outlined),
        ),
        items: const [],
      ),
      data: (list) => ReactiveDropdownField<String>(
        formControlName: 'agama',
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'Pilih Agama',
          prefixIcon: Icon(Icons.self_improvement_outlined),
        ),
        items: list
            .map((AgamaModel e) =>
                DropdownMenuItem(value: e.id, child: Text(e.nama)))
            .toList(),
      ),
    );
  }
}

class FotoField extends StatelessWidget {
  const FotoField({super.key, required this.foto, required this.onPick});

  final FileItem? foto;
  final Future<void> Function(ImagePickSource source) onPick;

  Future<void> _preview(BuildContext context) async {
    final path = foto?.path.trim() ?? '';
    if (path.isEmpty) return;
    if (path.toLowerCase().startsWith('http')) {
      await openFileUrl(context, path);
      return;
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka foto: ${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DokumenUploadCard(
      title: 'Foto Auditor',
      requiredDoc: true,
      file: foto,
      onPickImage: onPick,
      onPreview: () => _preview(context),
      leadingIcon: Icons.image_outlined,
      leadingColor: AppColors.primary,
      formatHint: 'Format JPG/PNG (maks. 10 MB)',
      imageThumbnail: true,
    );
  }
}

class ProfilWilayahFields extends ConsumerWidget {
  const ProfilWilayahFields({
    super.key,
    required this.form,
    required this.pendingKabupaten,
    required this.onKabupatenApplied,
  });

  final FormGroup form;
  final String? pendingKabupaten;
  final VoidCallback onKabupatenApplied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _provinsiDropdown(ref),
        const FieldLabel('Kota/Kabupaten', isRequired: false),
        _kabupatenDropdown(context, ref),
      ],
    );
  }

  Widget _provinsiDropdown(WidgetRef ref) {
    final async = ref.watch(provinsiListProvider);
    return async.when(
      loading: () => const DropdownLoading(),
      error: (_, __) => DropdownError(
        hint: 'Gagal memuat provinsi',
        onRetry: () => ref.invalidate(provinsiListProvider),
      ),
      data: (list) => ReactiveDropdownField<String>(
        formControlName: 'provinsi',
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'Pilih Provinsi',
          prefixIcon: Icon(Icons.map_outlined),
        ),
        items: list
            .map((ProvinsiModel e) =>
                DropdownMenuItem(value: e.id, child: Text(e.nama)))
            .toList(),
      ),
    );
  }

  Widget _kabupatenDropdown(BuildContext context, WidgetRef ref) {
    final provinsiId = form.control('provinsi').value?.toString();
    if (provinsiId == null || provinsiId.isEmpty) {
      return ReactiveDropdownField<String>(
        formControlName: 'kabupaten',
        decoration: const InputDecoration(
          hintText: 'Pilih Provinsi dulu',
          prefixIcon: Icon(Icons.location_on_outlined),
        ),
        items: const [],
      );
    }
    final async = ref.watch(kabupatenListProvider(provinsiId));
    return async.when(
      loading: () => const DropdownLoading(),
      error: (_, __) => DropdownError(
        hint: 'Gagal memuat kabupaten',
        onRetry: () => ref.invalidate(kabupatenListProvider(provinsiId)),
      ),
      data: (list) {
        final pending = pendingKabupaten;
        if (pending != null &&
            form.control('kabupaten').value != pending &&
            list.any((e) => e.id == pending)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            form.control('kabupaten').value = pending;
            onKabupatenApplied();
          });
        }
        return ReactiveDropdownField<String>(
          formControlName: 'kabupaten',
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Pilih Kota/Kabupaten',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          items: list
              .map((KabupatenModel e) =>
                  DropdownMenuItem(value: e.id, child: Text(e.nama)))
              .toList(),
        );
      },
    );
  }
}
