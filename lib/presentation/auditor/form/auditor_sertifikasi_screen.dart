import 'package:flutter/material.dart';

import 'auditor_sertifikasi_body.dart';

Future<void> openAuditorSertifikasi(BuildContext context,
    {required String ref}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(builder: (_) => AuditorSertifikasiScreen(auditorRef: ref)),
  );
}

class AuditorSertifikasiScreen extends StatelessWidget {
  const AuditorSertifikasiScreen({super.key, required this.auditorRef});

  final String auditorRef;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      appBar: AppBar(
        title: const Text(
          'Sertifikasi Teknis',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: AuditorSertifikasiBody(
          formKey: auditorRef,
          showHeader: false,
        ),
      ),
    );
  }
}
