import '../../core/utils/api_response_utils.dart';

class SliderItem {
  final int id;
  final String alt;
  final String desc;
  final String src;
  final String srcUrl;
  final bool isAktif;

  const SliderItem({
    required this.id,
    this.alt = '',
    this.desc = '',
    this.src = '',
    this.srcUrl = '',
    this.isAktif = false,
  });

  factory SliderItem.fromJson(Map<String, dynamic> json) => SliderItem(
        id: parseInt(json['id']) ?? 0,
        alt: pickString(json, const ['alt'], fallback: '')!,
        desc: pickString(json, const ['desc'], fallback: '')!,
        src: pickString(json, const ['src'], fallback: '')!,
        srcUrl: pickString(json, const ['src_url'], fallback: '')!,
        isAktif: (parseInt(json['is_aktif']) ?? 0) == 1,
      );
}
