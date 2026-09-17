import 'dart:convert';

import 'package:flutter/material.dart';

/// Resolves an avatar URL into the right [ImageProvider].
///
/// Mock avatar uploads store the actually-picked photo as a base64
/// `data:` URI (no real backend/storage to host the file), so this must
/// render via [MemoryImage] instead of [NetworkImage] — otherwise the
/// uploaded photo would never actually show, only a generic placeholder.
ImageProvider resolveAvatarImage(String url) {
  if (url.startsWith('data:')) {
    final commaIndex = url.indexOf(',');
    final base64Data = commaIndex == -1 ? '' : url.substring(commaIndex + 1);
    return MemoryImage(base64Decode(base64Data));
  }
  return NetworkImage(url);
}

/// A circular avatar that crops a real photo top-aligned instead of
/// center-cropped. `CircleAvatar.backgroundImage` alone always centers the
/// crop — for a typical portrait photo (face in the upper half), that cuts
/// the head off and keeps more of the body/shoulders, which is the bug this
/// widget fixes everywhere an avatar is shown (headers, profile screens).
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.radius,
    required this.backgroundColor,
    this.imageUrl,
    this.placeholderIcon = Icons.person,
    this.placeholderIconColor,
  });

  final double radius;
  final Color backgroundColor;
  final String? imageUrl;
  final IconData placeholderIcon;
  final Color? placeholderIconColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        color: backgroundColor,
        alignment: Alignment.center,
        child: url == null
            ? Icon(
                placeholderIcon,
                size: radius,
                color: placeholderIconColor,
              )
            : Image(
                image: resolveAvatarImage(url),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
      ),
    );
  }
}

/// First letter of the first two words in [name] (e.g. "محمود طه" -> "مط",
/// "Amr Adel" -> "AA"), for an initials-fallback avatar. Uppercased for
/// Latin names; Arabic has no case, so `toUpperCase()` is a no-op there.
/// Falls back to "?" for an empty/blank name rather than an empty avatar.
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.characters.first.toUpperCase();
  return (words.first.characters.first + words[1].characters.first).toUpperCase();
}

/// A deterministic background color for an initials avatar, picked from
/// [name] so the same doctor always gets the same color across the app
/// (search results, profile, headers) instead of a random one per render.
Color _initialsColorOf(String name) {
  const palette = [
    Color(0xFF2563EB), // blue
    Color(0xFF0D9488), // teal
    Color(0xFF7C3AED), // violet
    Color(0xFFDB2777), // pink
    Color(0xFFD97706), // amber
    Color(0xFF059669), // emerald
    Color(0xFFDC2626), // red
    Color(0xFF4F46E5), // indigo
  ];
  final index = name.trim().isEmpty ? 0 : name.trim().codeUnits.reduce((a, b) => a + b) % palette.length;
  return palette[index];
}

/// A doctor avatar with a real-photo/initials fallback: shows the doctor's
/// photo (top-aligned crop) if one exists, otherwise a colored circle with
/// their initials — never the generic person icon, since a name is always
/// available for a doctor card. `borderRadius` picks the shape: `null`
/// (default) renders a circle, any other value a rounded square/rect (for
/// card-style avatars like search results).
class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({
    super.key,
    required this.name,
    required this.size,
    this.photoUrl,
    this.borderRadius,
  });

  final String name;
  final double size;
  final String? photoUrl;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    final color = _initialsColorOf(name);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: url == null ? color.withValues(alpha: 0.12) : null,
        alignment: Alignment.center,
        child: url != null
            ? Image(
                image: resolveAvatarImage(url),
                width: size,
                height: size,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              )
            : Text(
                initialsOf(name),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.36,
                ),
              ),
      ),
    );
  }
}
