import 'dart:math';

Map<String, dynamic> buildSaveProfilePayload({
  required String ref,
  required String noPendaftaran,
  required String namaLatik,
  required String email,
  required String address,
  required String phone,
  required String website,
  required String noNib,
  required String noNpwp,
  required String noStr,
  required String areaOperasional,
  required String provinsiId,
  required String kabupatenId,
  required bool scopeAplikasi,
  required bool scopeInfrastruktur,
  required String latitude,
  required String longitude,
}) {
  return <String, dynamic>{
    if (ref.isNotEmpty) 'ref': ref,
    'no_pendaftaran': noPendaftaran,
    'lingkup_pendaftaran': {
      'aplikasi': scopeAplikasi ? 1 : 0,
      'infrastruktur': scopeInfrastruktur ? 1 : 0,
    },
    'nama_latik': namaLatik,
    'email': email,
    'address': address,
    'phone': phone,
    'website': website,
    'no_npwp': noNpwp,
    'no_siup': '',
    'no_nib': noNib,
    'no_str': noStr,
    'jml_auditor': '',
    'position': {'lat': latitude, 'lng': longitude},
    'area_operasional': areaOperasional,
    'provinsi': int.tryParse(provinsiId) ?? provinsiId,
    'kabupaten': int.tryParse(kabupatenId) ?? kabupatenId,
    'latitude': latitude,
    'longitude': longitude,
  };
}

const _uidChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String generateNoPendaftaran([Random? random]) {
  final rng = random ?? Random();
  return String.fromCharCodes(
    List.generate(13, (_) => _uidChars.codeUnitAt(rng.nextInt(_uidChars.length))),
  );
}
