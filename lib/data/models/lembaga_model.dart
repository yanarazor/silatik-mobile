class LembagaModel {
  final String nama;
  final String nib;
  final String badanHukum;
  final String alamat;
  final String provinsi;
  final String kota;
  final String kodePos;
  final String telepon;
  final String email;
  final String website;

  const LembagaModel({
    required this.nama,
    required this.nib,
    required this.badanHukum,
    required this.alamat,
    required this.provinsi,
    required this.kota,
    required this.kodePos,
    required this.telepon,
    required this.email,
    this.website = '',
  });

  factory LembagaModel.fromJson(Map<String, dynamic> json) => LembagaModel(
        nama: json['nama'] ?? '',
        nib: json['nib'] ?? '',
        badanHukum: json['badan_hukum'] ?? '',
        alamat: json['alamat'] ?? '',
        provinsi: json['provinsi'] ?? '',
        kota: json['kota'] ?? '',
        kodePos: json['kode_pos'] ?? '',
        telepon: json['telepon'] ?? '',
        email: json['email'] ?? '',
        website: json['website'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'nib': nib,
        'badan_hukum': badanHukum,
        'alamat': alamat,
        'provinsi': provinsi,
        'kota': kota,
        'kode_pos': kodePos,
        'telepon': telepon,
        'email': email,
        'website': website,
      };
}
