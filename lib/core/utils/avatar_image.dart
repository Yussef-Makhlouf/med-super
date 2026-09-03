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
