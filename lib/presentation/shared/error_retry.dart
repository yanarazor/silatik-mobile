import 'package:flutter/material.dart';

/// Centered failure message with a "Muat Ulang" retry button.
///
/// Set [scrollable] when the widget is the direct child of a
/// [RefreshIndicator] so the pull-to-refresh gesture still has a scrollable
/// target.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.scrollable = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Muat Ulang'),
        ),
      ],
    );

    if (scrollable) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(child: content),
        ],
      );
    }
    return Center(child: content);
  }
}