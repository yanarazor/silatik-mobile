class NotifikasiModel {
  final String id;
  final String judul;
  final String isi;
  final String kategori;
  final DateTime waktu;
  final bool isRead;
  final String? actionUrl;

  const NotifikasiModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.waktu,
    this.isRead = false,
    this.actionUrl,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'];
    final data =
        payload is Map<String, dynamic> ? payload : const <String, dynamic>{};
    final rawTime = json['waktu'] ??
        json['created_at'] ??
        json['updated_at'] ??
        json['tanggal'] ??
        json['date'];
    return NotifikasiModel(
      id: (json['ref'] ?? json['id'] ?? '').toString(),
      judul: (json['judul'] ??
              json['title'] ??
              json['subject'] ??
              data['title'] ??
              data['judul'] ??
              'Notifikasi')
          .toString(),
      isi: (json['isi'] ??
              json['body'] ??
              json['message'] ??
              json['description'] ??
              data['message'] ??
              data['body'] ??
              data['isi'] ??
              data['description'] ??
              '')
          .toString(),
      kategori: (json['kategori'] ??
              json['type'] ??
              json['category'] ??
              data['kategori'] ??
              data['type'] ??
              'Info')
          .toString(),
      waktu: rawTime != null
          ? DateTime.tryParse(rawTime.toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] == true ||
          json['read_at'] != null ||
          json['status_baca'] == 1,
      actionUrl:
          (data['action'] ?? data['action_url'] ?? data['url'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'judul': judul,
        'isi': isi,
        'kategori': kategori,
        'waktu': waktu.toIso8601String(),
        'is_read': isRead,
        'action_url': actionUrl,
      };
}
