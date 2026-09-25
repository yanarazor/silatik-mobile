import 'package:flutter/material.dart';

/// Spinner placeholder used while a dropdown's options are loading.
class DropdownLoading extends StatelessWidget {
  const DropdownLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
}

/// Tappable dropdown placeholder shown when loading options failed.
class DropdownError extends StatelessWidget {
  const DropdownError({super.key, required this.hint, required this.onRetry});

  final String hint;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onRetry,
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: hint,
            errorText: 'Tap untuk coba lagi',
            prefixIcon: const Icon(Icons.error_outline),
          ),
          child: const SizedBox(height: 20),
        ),
      );
}