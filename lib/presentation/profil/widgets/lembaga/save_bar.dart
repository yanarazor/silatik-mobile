import 'package:flutter/material.dart';

/// Bottom save bar with a spinner while [saving].
class SaveBar extends StatelessWidget {
  const SaveBar({super.key, required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

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
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(saving ? 'Menyimpan...' : 'Simpan'),
          ),
        ),
      ),
    );
  }
}