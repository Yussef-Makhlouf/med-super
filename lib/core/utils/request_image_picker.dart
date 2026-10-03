import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_icons/solar_icons.dart';

/// Presents the shared camera/gallery choice used by prescription and lab
/// request uploads. Images beyond [maxImages] are deliberately discarded
/// before their bytes are read, avoiding an unnecessary memory spike.
Future<List<({String path, Uint8List bytes})>?> pickRequestImages(
  BuildContext context, {
  required int maxImages,
}) async {
  if (maxImages <= 0) return const [];

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(SolarIconsOutline.camera),
            title: Text('common.image_source.camera'.tr()),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(SolarIconsOutline.gallery),
            title: Text('common.image_source.gallery'.tr()),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  try {
    final picker = ImagePicker();
    final files = source == ImageSource.camera
        ? await picker.pickImage(source: ImageSource.camera).then(
            (file) => file == null ? <XFile>[] : [file],
          )
        : await picker.pickMultiImage();
    return Future.wait(
      files.take(maxImages).map(
            (file) async => (path: file.path, bytes: await file.readAsBytes()),
          ),
    );
  } on PlatformException catch (error) {
    if (!context.mounted) return null;
    final denied = error.code.contains('camera') || error.code.contains('permission');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text((denied ? 'errors.camera_access_denied' : 'errors.image_picker_failed').tr())),
    );
    return null;
  } catch (_) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('errors.image_picker_failed'.tr())),
    );
    return null;
  }
}
