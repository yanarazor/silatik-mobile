import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/latik_profile.dart';
import '../../location_picker_field.dart';
import '../../../shared/field_label.dart';
import 'profil_form_fields.dart';
import 'scope_tile.dart';
import 'wilayah_fields.dart';

/// Scrollable body of the institution edit form. Stateless: all editing state
/// lives in the parent screen and is written back through the callbacks.
class LembagaFormBody extends StatelessWidget {
  const LembagaFormBody({
    super.key,
    required this.form,
    required this.profile,
    required this.noPendaftaran,
    required this.position,
    required this.scopeAplikasi,
    required this.scopeInfrastruktur,
    required this.onScopeAplikasi,
    required this.onScopeInfrastruktur,
    required this.onPositionChanged,
  });

  final FormGroup form;
  final LatikProfile profile;
  final String noPendaftaran;
  final LatLng? position;
  final bool scopeAplikasi;
  final bool scopeInfrastruktur;
  final ValueChanged<bool> onScopeAplikasi;
  final ValueChanged<bool> onScopeInfrastruktur;
  final ValueChanged<LatLng?> onPositionChanged;

  @override
  Widget build(BuildContext context) {
    return ReactiveForm(
      formGroup: form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        children: [
          const FieldLabel('Nomor Registrasi', isRequired: false),
          ReadOnlyField(noPendaftaran, Icons.tag),
          const FieldLabel('Nama Lembaga'),
          ReactiveTextField(
            formControlName: 'nama_latik',
            validationMessages: requiredMsg('Nama lembaga'),
            decoration: const InputDecoration(
              hintText: 'Nama lembaga',
              prefixIcon: Icon(Icons.account_balance_outlined),
            ),
          ),
          const FieldLabel('Email', isRequired: false),
          ReadOnlyField(
            profile.email.isEmpty ? '-' : profile.email,
            Icons.email_outlined,
          ),
          const FieldLabel('NIB'),
          ReactiveTextField(
            formControlName: 'no_nib',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
            validationMessages: {
              ValidationMessage.required: (_) => 'NIB wajib diisi',
              ValidationMessage.pattern: (_) =>
                  'NIB harus tepat 13 digit angka',
            },
            decoration: const InputDecoration(
              hintText: '13 digit',
              prefixIcon: Icon(Icons.badge_outlined),
              counterText: '',
            ),
          ),
          const FieldLabel('NPWP'),
          ReactiveTextField(
            formControlName: 'no_npwp',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            validationMessages: {
              ValidationMessage.required: (_) => 'NPWP wajib diisi',
              ValidationMessage.pattern: (_) =>
                  'NPWP harus 15-16 digit angka',
            },
            decoration: const InputDecoration(
              hintText: '15-16 digit',
              prefixIcon: Icon(Icons.receipt_long_outlined),
              counterText: '',
            ),
          ),
          if (profile.noStr.isNotEmpty) ...[
            const FieldLabel('Nomor STR', isRequired: false),
            ReadOnlyField(profile.noStr, Icons.verified_outlined),
          ],
          const FieldLabel('Alamat'),
          ReactiveTextField(
            formControlName: 'address',
            maxLines: 2,
            validationMessages: requiredMsg('Alamat'),
            decoration: const InputDecoration(
              hintText: 'Alamat lengkap lembaga',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          WilayahFields(
            form: form,
            initialProvinsi: profile.provinsi,
            initialKabupaten: profile.kabupaten,
          ),
          const FieldLabel('Nomor Telepon'),
          ReactiveTextField(
            formControlName: 'phone',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validationMessages: requiredMsg('Nomor telepon'),
            decoration: const InputDecoration(
              hintText: '08xxxxxxxxxx',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const FieldLabel('Website'),
          ReactiveTextField(
            formControlName: 'website',
            keyboardType: TextInputType.url,
            validationMessages: requiredMsg('Website'),
            decoration: const InputDecoration(
              hintText: 'www.contoh.com',
              prefixIcon: Icon(Icons.language_outlined),
            ),
          ),
          const FieldLabel('Area Operasional', isRequired: false),
          ReactiveTextField(
            formControlName: 'area_operasional',
            decoration: const InputDecoration(
              hintText: 'Contoh: Thamrin',
              prefixIcon: Icon(Icons.map_outlined),
            ),
          ),
          const FieldLabel('Lingkup Pendaftaran'),
          ScopeTile(
            label: 'Aplikasi',
            value: scopeAplikasi,
            onChanged: onScopeAplikasi,
          ),
          ScopeTile(
            label: 'Infrastruktur',
            value: scopeInfrastruktur,
            onChanged: onScopeInfrastruktur,
          ),
          // TODO: Intentionally disabled per current fe
          const ScopeTile(
            label: 'Sekuriti (BSSN)',
            value: false,
            onChanged: null,
          ),
          const FieldLabel('Lokasi Lembaga'),
          LocationPickerField(
            initial: position,
            onChanged: onPositionChanged,
          ),
          const SizedBox(height: AppTheme.spacing24),
        ],
      ),
    );
  }
}