import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/auditor_model.dart';
import '../../providers/auditor_provider.dart';
import '../registration/steps/step4_auditor.dart';
import 'auditor_detail_screen.dart';

class AuditorListScreen extends ConsumerWidget {
  const AuditorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditorsAsync = ref.watch(auditorListProvider);
    final auditors = auditorsAsync.valueOrNull;
    final displayAuditors =
        auditors == null || auditors.isEmpty ? _previewAuditors : auditors;

    return Stack(
      children: [
        const _BlueHeaderBand(height: 150),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kelola Auditor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${displayAuditors.length} auditor terdaftar',
                          style: const TextStyle(
                            color: Color(0xDDEAF2FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => showAuditorSheet(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari auditor...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE4ECF7)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...displayAuditors.map(
                (auditor) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AuditorTile(
                    auditor: auditor,
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AuditorDetailScreen(auditor: auditor),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlueHeaderBand extends StatelessWidget {
  const _BlueHeaderBand({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height + MediaQuery.paddingOf(context).top,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0057B8), Color(0xFF003D7A)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
    );
  }
}

class _AuditorTile extends StatelessWidget {
  const _AuditorTile({required this.auditor, required this.onTap});

  final AuditorModel auditor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = auditor.nama
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4ECF7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B2D5C).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary,
              child: Text(
                initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auditor.nama,
                    style: const TextStyle(
                      color: Color(0xFF1C2638),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIK: ****${auditor.nik.length >= 4 ? auditor.nik.substring(auditor.nik.length - 4) : auditor.nik}',
                    style: const TextStyle(
                      color: Color(0xFF5B6880),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: auditor.kompetensi
                        .take(2)
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFA7B0C3)),
          ],
        ),
      ),
    );
  }
}

final _previewAuditors = [
  AuditorModel(
    id: 'preview-1',
    nama: 'Budi Santoso',
    email: 'budi@example.com',
    nik: '3201010101013456',
    tempatLahir: 'Jakarta',
    tanggalLahir: DateTime(1990, 1, 1),
    alamat: '-',
    provinsi: 'DKI Jakarta',
    kabupaten: 'Jakarta Selatan',
    kodePos: '12345',
    agama: 'Islam',
    phone: '081234567890',
    keterangan: '-',
    fotoUrl: '',
    nomorSertifikasi: 'AUD-001',
    lembagaPenerbit: 'BRIN',
    tanggalTerbit: DateTime(2024, 1, 12),
    tanggalBerakhir: DateTime(2027, 1, 12),
    kompetensi: const ['Audit Aplikasi', 'Infrastruktur'],
    certificates: const [],
    statusLabel: 'Auditor TIK Tetap',
    activeLabel: 'Aktif',
    verificationLabel: 'Belum Verifikasi',
    strTanggalAkhir: null,
    filePath: '',
    fileName: '',
    fileSize: 0,
    ktpFileUrl: '',
    sertifikatKompetensiUrl: '',
    portofolioUrl: '',
    praktikAuditUrl: '',
    asosiasiProfesiUrl: '',
    pernyataanIntegritasUrl: '',
    suratPermohonanUrl: '',
    pengangkatanUrl: '',
  ),
  AuditorModel(
    id: 'preview-2',
    nama: 'Rina Wulandari',
    email: 'rina@example.com',
    nik: '3201010101011090',
    tempatLahir: 'Bandung',
    tanggalLahir: DateTime(1992, 2, 2),
    alamat: '-',
    provinsi: 'Jawa Barat',
    kabupaten: 'Bandung',
    kodePos: '40111',
    agama: 'Islam',
    phone: '081234567891',
    keterangan: '-',
    fotoUrl: '',
    nomorSertifikasi: 'AUD-002',
    lembagaPenerbit: 'BRIN',
    tanggalTerbit: DateTime(2024, 2, 14),
    tanggalBerakhir: DateTime(2027, 2, 14),
    kompetensi: const ['Infrastruktur'],
    certificates: const [],
    statusLabel: 'Auditor TIK Tetap',
    activeLabel: 'Aktif',
    verificationLabel: 'Belum Verifikasi',
    strTanggalAkhir: null,
    filePath: '',
    fileName: '',
    fileSize: 0,
    ktpFileUrl: '',
    sertifikatKompetensiUrl: '',
    portofolioUrl: '',
    praktikAuditUrl: '',
    asosiasiProfesiUrl: '',
    pernyataanIntegritasUrl: '',
    suratPermohonanUrl: '',
    pengangkatanUrl: '',
  ),
  AuditorModel(
    id: 'preview-3',
    nama: 'Agus Pratama',
    email: 'agus@example.com',
    nik: '3201010101012222',
    tempatLahir: 'Surabaya',
    tanggalLahir: DateTime(1991, 3, 3),
    alamat: '-',
    provinsi: 'Jawa Timur',
    kabupaten: 'Surabaya',
    kodePos: '60200',
    agama: 'Islam',
    phone: '081234567892',
    keterangan: '-',
    fotoUrl: '',
    nomorSertifikasi: 'AUD-003',
    lembagaPenerbit: 'BRIN',
    tanggalTerbit: DateTime(2024, 3, 3),
    tanggalBerakhir: DateTime(2025, 3, 3),
    kompetensi: const ['Organisasi'],
    certificates: const [],
    statusLabel: 'Auditor TIK Tetap',
    activeLabel: 'Tidak Aktif',
    verificationLabel: 'Belum Verifikasi',
    strTanggalAkhir: null,
    filePath: '',
    fileName: '',
    fileSize: 0,
    ktpFileUrl: '',
    sertifikatKompetensiUrl: '',
    portofolioUrl: '',
    praktikAuditUrl: '',
    asosiasiProfesiUrl: '',
    pernyataanIntegritasUrl: '',
    suratPermohonanUrl: '',
    pengangkatanUrl: '',
  ),
];
