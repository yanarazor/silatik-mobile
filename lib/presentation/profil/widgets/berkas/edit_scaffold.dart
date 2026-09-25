import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Scaffold shell shown while the document list loads / fails.
class EditScaffold extends StatelessWidget {
  const EditScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Edit Dokumen')),
        body: child,
      );
}