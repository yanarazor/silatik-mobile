class StrModel {
  final String nomor;
  final DateTime? tanggalTerbit;
  final DateTime? berlakuHingga;

  const StrModel({required this.nomor, this.tanggalTerbit, this.berlakuHingga});

  factory StrModel.fromJson(Map<String, dynamic> json) => StrModel(
        nomor: json['nomor'] ?? '',
        tanggalTerbit:
            json['tanggal_terbit'] != null ? DateTime.tryParse(json['tanggal_terbit']) : null,
        berlakuHingga:
            json['berlaku_hingga'] != null ? DateTime.tryParse(json['berlaku_hingga']) : null,
      );

  Map<String, dynamic> toJson() => {
        'nomor': nomor,
        'tanggal_terbit': tanggalTerbit?.toIso8601String(),
        'berlaku_hingga': berlakuHingga?.toIso8601String(),
      };
}
