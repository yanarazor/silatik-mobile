import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/auditor_model.dart';

class AuditorFormSheet extends StatefulWidget {
  final void Function(AuditorModel) onSave;
  const AuditorFormSheet({super.key, required this.onSave});

  @override
  State<AuditorFormSheet> createState() => _AuditorFormSheetState();
}

class _AuditorFormSheetState extends State<AuditorFormSheet> {
  final _form = FormGroup({
    'nama': FormControl<String>(validators: [Validators.required]),
    'nik': FormControl<String>(validators: [Validators.required]),
    'nomor': FormControl<String>(validators: [Validators.required]),
    'lembaga': FormControl<String>(validators: [Validators.required]),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ReactiveForm(
          formGroup: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Tambah Auditor',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            ReactiveTextField(
                formControlName: 'nama',
                decoration: const InputDecoration(labelText: 'Nama Lengkap*')),
            const SizedBox(height: 8),
            ReactiveTextField(
                formControlName: 'nik',
                decoration: const InputDecoration(labelText: 'NIK*')),
            const SizedBox(height: 8),
            ReactiveTextField(
                formControlName: 'nomor',
                decoration: const InputDecoration(
                    labelText: 'Nomor Sertifikasi Auditor*')),
            const SizedBox(height: 8),
            ReactiveTextField(
                formControlName: 'lembaga',
                decoration: const InputDecoration(
                    labelText: 'Lembaga Penerbit Sertifikasi*')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _form.markAllAsTouched();
                final nik = _form.control('nik').value?.toString();
                if (_form.invalid || AppValidators.nik(nik) != null) return;
                widget.onSave(AuditorModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nama: _form.control('nama').value,
                  email: '',
                  nik: nik!,
                  tempatLahir: '-',
                  tanggalLahir: null,
                  alamat: '-',
                  provinsi: '-',
                  kabupaten: '-',
                  kodePos: '-',
                  agama: '-',
                  phone: '-',
                  keterangan: '',
                  fotoUrl: '',
                  nomorSertifikasi: _form.control('nomor').value,
                  lembagaPenerbit: _form.control('lembaga').value,
                  tanggalTerbit: DateTime.now(),
                  tanggalBerakhir:
                      DateTime.now().add(const Duration(days: 365)),
                  kompetensi: const ['Audit Aplikasi'],
                  certificates: const [],
                  statusLabel: 'Auditor TIK Tetap',
                  activeLabel: 'Aktif',
                  verificationLabel: 'Belum Verifikasi',
                  strTanggalAkhir: null,
                  filePath: '',
                  fileName: 'sertifikat.pdf',
                  fileSize: 1024,
                  ktpFileUrl: '',
                  sertifikatKompetensiUrl: '',
                  portofolioUrl: '',
                  praktikAuditUrl: '',
                  asosiasiProfesiUrl: '',
                  pernyataanIntegritasUrl: '',
                  suratPermohonanUrl: '',
                  pengangkatanUrl: '',
                ));
                Navigator.pop(context);
              },
              child: const Text('Simpan Auditor'),
            )
          ]),
        ),
      ),
    );
  }
}
