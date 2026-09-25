import 'package:flutter/material.dart';

/// Bottom action bar with the "Edit Profil Lembaga" button.
class EditFooter extends StatelessWidget {
  const EditFooter({super.key, required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4ECF7))),
        boxShadow: [
          BoxShadow(
            color: Color(0x140C2D5C),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: const Text('Edit Profil Lembaga'),
          ),
        ),
      ),
    );
  }
}