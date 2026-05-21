import 'auditor_model.dart';
import 'lembaga_model.dart';

class FileItem {
  final String path;
  final String name;
  final int size;

  const FileItem({required this.path, required this.name, required this.size});

  factory FileItem.fromJson(Map<String, dynamic> json) => FileItem(path: json['path'] ?? '', name: json['name'] ?? '', size: json['size'] ?? 0);
  Map<String, dynamic> toJson() => {'path': path, 'name': name, 'size': size};
}

class RegistrasiModel {
  final LembagaModel? lembaga;
  final String nomorKan;
  final DateTime? terbitKan;
  final DateTime? berakhirKan;
  final List<String> ruangLingkup;
  final FileItem? sertifikatKan;
  final Map<String, FileItem?> dokumen;
  final List<AuditorModel> auditors;
  final bool pernyataan;

  const RegistrasiModel({
    this.lembaga,
    this.nomorKan = '',
    this.terbitKan,
    this.berakhirKan,
    this.ruangLingkup = const [],
    this.sertifikatKan,
    this.dokumen = const {},
    this.auditors = const [],
    this.pernyataan = false,
  });

  RegistrasiModel copyWith({
    LembagaModel? lembaga,
    String? nomorKan,
    DateTime? terbitKan,
    DateTime? berakhirKan,
    List<String>? ruangLingkup,
    FileItem? sertifikatKan,
    Map<String, FileItem?>? dokumen,
    List<AuditorModel>? auditors,
    bool? pernyataan,
  }) {
    return RegistrasiModel(
      lembaga: lembaga ?? this.lembaga,
      nomorKan: nomorKan ?? this.nomorKan,
      terbitKan: terbitKan ?? this.terbitKan,
      berakhirKan: berakhirKan ?? this.berakhirKan,
      ruangLingkup: ruangLingkup ?? this.ruangLingkup,
      sertifikatKan: sertifikatKan ?? this.sertifikatKan,
      dokumen: dokumen ?? this.dokumen,
      auditors: auditors ?? this.auditors,
      pernyataan: pernyataan ?? this.pernyataan,
    );
  }
}
