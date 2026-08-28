class ProvinsiModel {
  final String id;
  final String nama;

  ProvinsiModel({required this.id, required this.nama});

  factory ProvinsiModel.fromJson(Map<String, dynamic> json) {
    return ProvinsiModel(
      id: (json['id'] ?? json['kode'] ?? json['provinsi_id'] ?? '').toString(),
      nama: (json['nama'] ?? json['nama_provinsi'] ?? json['name'] ?? '').toString(),
    );
  }
}

class KabupatenModel {
  final String id;
  final String nama;
  final String provinsiId;

  KabupatenModel({
    required this.id,
    required this.nama,
    required this.provinsiId,
  });

  factory KabupatenModel.fromJson(Map<String, dynamic> json) {
    return KabupatenModel(
      id: (json['id'] ?? json['kode'] ?? json['kabupaten_id'] ?? '').toString(),
      nama: (json['nama'] ?? json['nama_kabupaten'] ?? json['name'] ?? '').toString(),
      provinsiId: (json['provinsi_id'] ?? json['id_provinsi'] ?? json['provinsi'] ?? '').toString(),
    );
  }
}
