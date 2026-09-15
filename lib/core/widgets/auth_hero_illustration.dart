import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:solar_icons/solar_icons.dart';

/// Rounded blob-backdrop hero used by the send-OTP, phone+password login,
/// and forgot-password screens — same soft-tinted panel with three
/// decorative blobs behind a single glyph tile, differing only in the icon
/// and the tile/icon size.
class AuthBlobHeroIllustration extends StatelessWidget {
  const AuthBlobHeroIllustration({
    required this.icon,
    this.tileSize = 120,
    this.iconSize = 64,
    super.key,
  });

  final IconData icon;
  final double tileSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tileRadius = tileSize * (28 / 120);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.primarySoft,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 28,
            left: 36,
            child: _blob(36, AppPalette.primary.withValues(alpha: 0.25)),
          ),
          Positioned(
            top: 48,
            right: 40,
            child: _blob(22, AppPalette.primary.withValues(alpha: 0.35)),
          ),
          Positioned(
            bottom: 56,
            left: 48,
            child: _blob(18, AppPalette.primary.withValues(alpha: 0.2)),
          ),
          Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              color: AppPalette.primary,
              borderRadius: BorderRadius.circular(tileRadius),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ],
      ),
    );
  }

  static Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Shield backdrop with a small overlay glyph and four corner tag chips —
/// used by both OTP-style verification screens (login OTP and
/// password-reset code), which differ only in the overlay icon.
class AuthShieldHeroIllustration extends StatelessWidget {
  const AuthShieldHeroIllustration({
    required this.overlayIcon,
    required this.tags,
    super.key,
  });

  final IconData overlayIcon;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppPalette.primarySoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              SolarIconsOutline.shield,
              size: 120,
              color: AppPalette.primary.withValues(alpha: 0.85),
            ),
            Icon(
              overlayIcon,
              size: 36,
              color: AppPalette.primary.withValues(alpha: 0.95),
            ),
            if (tags.isNotEmpty) ...[
              Positioned(top: 28, left: 36, child: _tag(tags[0])),
              if (tags.length > 1)
                Positioned(top: 40, right: 28, child: _tag(tags[1])),
              if (tags.length > 2)
                Positioned(bottom: 36, left: 28, child: _tag(tags[2])),
              if (tags.length > 3)
                Positioned(bottom: 48, right: 40, child: _tag(tags[3])),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppPalette.primary.withValues(alpha: 0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: AppPalette.primary.withValues(alpha: 0.9),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),
  );
}
