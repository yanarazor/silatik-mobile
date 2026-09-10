import '../../core/utils/api_response_utils.dart';

class DokumenModel {
  final int id;
  final String ref;
  final String judul;
  final String? linkEksternal;
  final String? urlFilename;
  final String? filename;

  const DokumenModel({
    required this.id,
    required this.ref,
    required this.judul,
    this.linkEksternal,
    this.urlFilename,
    this.filename,
  });

  factory DokumenModel.fromJson(Map<String, dynamic> json) {
    final linkExt = (json['link_eksternal'] ?? '').toString();
    final urlFile = (json['url_filename'] ?? '').toString();
    final fileName = (json['filename'] ?? '').toString();

    return DokumenModel(
      id: parseInt(json['id']) ?? 0,
      ref: (json['ref'] ?? '').toString(),
      judul: (json['judul'] ?? json['nama'] ?? json['title'] ?? '').toString(),
      linkEksternal: linkExt.isNotEmpty ? linkExt : null,
      urlFilename: urlFile.isNotEmpty ? urlFile : null,
      filename: fileName.isNotEmpty ? fileName : null,
    );
  }

  bool get isPdf => urlFilename?.toLowerCase().endsWith('.pdf') == true;

  String? get openUrl => urlFilename ?? linkEksternal;
}
