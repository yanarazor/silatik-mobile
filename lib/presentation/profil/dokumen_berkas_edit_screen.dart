import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_response_utils.dart';
import '../../core/utils/url_opener.dart';
import '../../data/models/profil_dokumen.dart';
import '../../data/models/registrasi_model.dart';
import '../../data/services/latik_service.dart';
import '../../providers/profile_menu_provider.dart';
import '../../providers/latik_service_provider.dart';
import '../shared/dokumen_upload_card.dart';
import '../auditor/form/auditor_profil_step.dart' show kAuditorFileMaxBytes;
import 'widgets/berkas/doc_edit.dart';
import 'widgets/berkas/doc_extra_fields.dart';
import 'widgets/berkas/edit_scaffold.dart';
import 'widgets/berkas/item_divider.dart';

class DokumenBerkasEditScreen extends ConsumerStatefulWidget {
  const DokumenBerkasEditScreen({super.key});

  @override
  ConsumerState<DokumenBerkasEditScreen> createState() =>
      _DokumenBerkasEditScreenState();
}

class _DokumenBerkasEditScreenState
    extends ConsumerState<DokumenBerkasEditScreen> {
  final Map<int, DocEdit> _edits = {};
  List<ProfilDokumen> _docs = const [];
  bool _initialized = false;
  bool _submitting = false;

  void _initEdits(List<ProfilDokumen> docs) {
    _docs = docs;
    _edits.clear();
    for (final d in docs) {
      if (d.id == null) continue;
      _edits[d.id!] = DocEdit(
        file: d.url.trim().isEmpty
            ? null
            : FileItem(path: d.url, name: _fileNameFromUrl(d.url), size: 0),
        nomor: d.nomor,
        tanggal: parseFlexibleDate(d.tanggal),
      );
    }
    _initialized = true;
  }

  @override
  void dispose() {
    for (final e in _edits.values) {
      e.nomor.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(int id) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.size > kAuditorFileMaxBytes) {
      _snack('Ukuran file maksimal 10MB');
      return;
    }
    setState(() {
      _edits[id]
        ?..file = FileItem(path: file.path ?? '', name: file.name, size: file.size)
        ..newlyPicked = true;
    });
  }

  Future<void> _preview(FileItem doc) async {
    final path = doc.path.trim();
    if (path.toLowerCase().startsWith('http')) {
      await openFileUrl(context, path);
      return;
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && mounted) {
      _snack('Gagal membuka berkas: ${result.message}');
    }
  }

  Future<void> _pickDate(int id, DateTime? current) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
      initialDate: current ?? DateTime.now(),
    );
    if (date != null) setState(() => _edits[id]?.tanggal = date);
  }

  List<DokumenUpload>? _buildUploads() {
    final uploads = <DokumenUpload>[];
    for (final d in _docs) {
      final id = d.id;
      if (id == null) continue;
      final e = _edits[id]!;
      final hasFile = e.file != null;

      if (d.fileRequired && !hasFile) {
        _snack('Dokumen wajib belum lengkap: ${d.nama}');
        return null;
      }

      if (hasFile && d.nomorRequired && e.nomor.text.trim().isEmpty) {
        _snack('Nomor wajib diisi: ${d.nama}');
        return null;
      }
      if (hasFile && d.tanggalRequired && e.tanggal == null) {
        _snack('Tanggal wajib diisi: ${d.nama}');
        return null;
      }

      uploads.add(DokumenUpload(
        id: id,
        file: e.newlyPicked && e.file != null ? File(e.file!.path) : null,
        fileName: e.newlyPicked ? e.file?.name : null,
        nomor: e.nomor.text.trim(),
        tanggal: e.tanggal == null ? null : _formatDate(e.tanggal!),
      ));
    }
    return uploads;
  }

  bool _hasAnyChange() {
    for (final d in _docs) {
      final id = d.id;
      if (id == null) continue;
      final e = _edits[id]!;
      if (e.newlyPicked) return true;
      if (e.nomor.text.trim() != d.nomor.trim()) return true;
      if (_formatOrEmpty(e.tanggal) != _originalTanggal(d)) return true;
    }
    return false;
  }

  Future<void> _submit() async {
    if (!_hasAnyChange()) {
      _snack('Tidak ada perubahan untuk disimpan');
      return;
    }
    final uploads = _buildUploads();
    if (uploads == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(latikServiceProvider).saveDokumenBatch(uploads);
      ref.invalidate(dokumenBerkasProvider);
      if (mounted) {
        _snack('Dokumen tersimpan', error: false);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) _snack('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(dokumenBerkasProvider);
    return docsAsync.when(
      loading: () => const EditScaffold(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => EditScaffold(
        child: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(dokumenBerkasProvider),
            child: const Text('Coba Lagi'),
          ),
        ),
      ),
      data: (loaded) {
        if (!_initialized) _initEdits(loaded);
        return _buildForm(context);
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    final docs = _docs.where((d) => d.id != null).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Dokumen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (var i = 0; i < docs.length; i++) ...[
            if (i > 0) const ItemDivider(),
            _docGroup(docs[i]),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Simpan Perubahan'),
          ),
        ),
      ),
    );
  }

  Widget _docGroup(ProfilDokumen d) {
    final hasExtra = d.nomorRequired || d.tanggalRequired;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DokumenUploadCard(
          title: d.nama.isEmpty ? 'Dokumen' : d.nama,
          requiredDoc: d.fileRequired,
          file: _edits[d.id]!.file,
          onPick: () => _pick(d.id!),
          onPreview: () {
            final f = _edits[d.id]!.file;
            if (f != null) _preview(f);
          },
        ),
        if (hasExtra)
          DocExtraFields(
            doc: d,
            edit: _edits[d.id]!,
            onPickDate: _pickDate,
          ),
      ],
    );
  }

  void _snack(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }

  static String _formatOrEmpty(DateTime? d) => d == null ? '' : _formatDate(d);

  static String _originalTanggal(ProfilDokumen d) =>
      _formatOrEmpty(parseFlexibleDate(d.tanggal));

  static String _fileNameFromUrl(String url) {
    final clean = url.split('?').first;
    final seg = clean.split('/').where((s) => s.isNotEmpty).toList();
    return seg.isEmpty ? 'dokumen' : Uri.decodeComponent(seg.last);
  }
}
