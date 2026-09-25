import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../data/models/master_data_model.dart';
import '../../../../providers/master_data_provider.dart';
import '../../../shared/dropdown_states.dart';
import '../../../shared/field_label.dart';

/// Dependent province / city fields for the institution form. Writes the
/// selected ids into [form] and resolves stored display names to ids once the
/// master lists load; unresolved names stay unselected so the user re-picks.
class WilayahFields extends ConsumerStatefulWidget {
  const WilayahFields({
    super.key,
    required this.form,
    required this.initialProvinsi,
    required this.initialKabupaten,
  });

  final FormGroup form;
  final String initialProvinsi;
  final String initialKabupaten;

  @override
  ConsumerState<WilayahFields> createState() => _WilayahFieldsState();
}

class _WilayahFieldsState extends ConsumerState<WilayahFields> {
  String? _lastProvinsi;
  String? _pendingKabupatenName;
  bool _provinsiResolved = false;

  @override
  void initState() {
    super.initState();
    _pendingKabupatenName =
        widget.initialKabupaten.isEmpty ? null : widget.initialKabupaten;

    // Reset kabupaten only when the user actually changes province (mirrors
    // the auditor step). Programmatic prefill syncs _lastProvinsi first.
    widget.form.control('provinsi').valueChanges.listen((value) {
      final next = value?.toString();
      if (next == _lastProvinsi) return;
      _lastProvinsi = next;
      _pendingKabupatenName = null;
      widget.form.control('kabupaten').reset();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FieldLabel('Provinsi'),
        _provinsiDropdown(),
        const FieldLabel('Kota/Kabupaten'),
        _kabupatenDropdown(),
      ],
    );
  }

  Widget _provinsiDropdown() {
    final async = ref.watch(provinsiListProvider);
    return async.when(
      loading: () => const DropdownLoading(),
      error: (_, __) => DropdownError(
        hint: 'Gagal memuat provinsi',
        onRetry: () => ref.invalidate(provinsiListProvider),
      ),
      data: (list) {
        _resolveProvinsiPrefill(list);
        return ReactiveDropdownField<String>(
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
        );
      },
    );
  }

  /// Match the stored province name to an id, once. Leaves it unselected when
  /// there's no confident match so the user re-picks rather than send a wrong
  /// id.
  void _resolveProvinsiPrefill(List<ProvinsiModel> list) {
    if (_provinsiResolved) return;
    _provinsiResolved = true;
    final name = widget.initialProvinsi.trim().toLowerCase();
    if (name.isEmpty) return;
    ProvinsiModel? match;
    for (final e in list) {
      if (e.nama.trim().toLowerCase() == name) {
        match = e;
        break;
      }
    }
    if (match == null) return;
    _lastProvinsi = match.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.form.control('provinsi').value = match!.id;
    });
  }

  Widget _kabupatenDropdown() {
    final provinsiId = widget.form.control('provinsi').value?.toString();
    if (provinsiId == null || provinsiId.isEmpty) {
      return ReactiveDropdownField<String>(
        formControlName: 'kabupaten',
        decoration: const InputDecoration(
          hintText: 'Pilih Provinsi dulu',
          prefixIcon: Icon(Icons.location_city_outlined),
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
        _resolveKabupatenPrefill(list);
        return ReactiveDropdownField<String>(
          formControlName: 'kabupaten',
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Pilih Kota/Kabupaten',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
          items: list
              .map((KabupatenModel e) =>
                  DropdownMenuItem(value: e.id, child: Text(e.nama)))
              .toList(),
        );
      },
    );
  }

  /// Match the stored kabupaten name to an id once its list is available.
  void _resolveKabupatenPrefill(List<KabupatenModel> list) {
    final pendingName = _pendingKabupatenName?.trim().toLowerCase();
    if (pendingName == null || pendingName.isEmpty) return;
    KabupatenModel? match;
    for (final e in list) {
      if (e.nama.trim().toLowerCase() == pendingName) {
        match = e;
        break;
      }
    }
    if (match == null) return;
    _pendingKabupatenName = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.form.control('kabupaten').value != match!.id) {
        widget.form.control('kabupaten').value = match.id;
        setState(() {});
      }
    });
  }
}