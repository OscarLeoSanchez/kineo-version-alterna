import 'package:flutter/material.dart';
import 'package:kineo_coach/core/theme/app_colors.dart';

/// A banner widget for displaying API / network errors.
///
/// Use [isCompact] for an inline variant suitable inside cards.
/// Provide [onRetry] to show a "Reintentar" button.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.isCompact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return isCompact ? _CompactBanner(message: message, onRetry: onRetry) : _FullBanner(message: message, onRetry: onRetry);
  }
}

class _FullBanner extends StatelessWidget {
  const _FullBanner({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorPale),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorDark, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.errorDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorDark,
                backgroundColor: AppColors.errorPale,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactBanner extends StatelessWidget {
  const _CompactBanner({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorPale),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorDark, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.errorDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  color: AppColors.errorDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
