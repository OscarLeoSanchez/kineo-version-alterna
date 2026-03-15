import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A subtle banner that slides in from the top when the device is offline.
/// Wrap it together with the main content in a [Column].
///
/// Example:
/// ```dart
/// Column(
///   children: [
///     OfflineBanner(isOffline: !_isOnline),
///     Expanded(child: mainContent),
///   ],
/// )
/// ```
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: isOffline ? 36 : 0,
      color: AppColors.divider,
      child: isOffline
          ? const _BannerContent()
          : const SizedBox.shrink(),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.wifi_off_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
        SizedBox(width: 6),
        Text(
          'Sin conexión — mostrando datos en caché',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
