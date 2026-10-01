import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Shared loading, empty, and error placeholders for revision wizards.
class RevisiStateViews {
  const RevisiStateViews({
    required this.loadingText,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.errorTitle,
    required this.errorMessage,
    required this.onRetry,
    this.emptyButtonLabel,
  });

  final String loadingText;
  final String emptyTitle;
  final String emptyMessage;
  final String errorTitle;
  final String errorMessage;
  final VoidCallback onRetry;
  final String? emptyButtonLabel;

  Widget loading() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(loadingText),
          ],
        ),
      );

  Widget empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open_rounded,
                  size: 64, color: Color(0xFF94A3B8)),
              const SizedBox(height: 14),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              if (emptyButtonLabel != null && emptyButtonLabel!.isNotEmpty) ...[
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(emptyButtonLabel!),
                ),
              ],
            ],
          ),
        ),
      );

  Widget error() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.error),
              const SizedBox(height: 14),
              Text(
                errorTitle,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
}
