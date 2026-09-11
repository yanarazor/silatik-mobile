import '../../core/utils/api_response_utils.dart';

/// A single help-center FAQ entry. `fromJson` owns the title/body key
/// variants the backend may use.
class Faq {
  final String title;
  final String body;

  const Faq({this.title = '', this.body = ''});

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
        title: pickString(
            json, const ['title', 'judul', 'question', 'pertanyaan'],
            fallback: '')!,
        body: pickString(
            json, const ['body', 'isi', 'answer', 'jawaban', 'description'],
            fallback: '')!,
      );
}
