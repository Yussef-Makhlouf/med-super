import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/color_schemes.dart';

/// One result/attachment file — a thumbnail that opens a full-screen
/// preview on tap, with its own download action. Deliberately doesn't try
/// to render a PDF in-app (no PDF viewer package in this project) — a PDF
/// shows an icon + label instead of an unusable thumbnail; download still
/// works identically for both.
class ResultFileThumbnail extends StatelessWidget {
  const ResultFileThumbnail({
    required this.fileUrl,
    required this.fileLabel,
    this.isCritical = false,
    super.key,
  });

  final String? fileUrl;
  final String fileLabel;
  final bool isCritical;

  bool get _isPdf => fileLabel.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    final url = fileUrl;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      onTap: url == null
          ? null
          : () => showDialog<void>(
              context: context,
              builder: (_) => _ResultFilePreviewDialog(
                fileUrl: url,
                fileLabel: fileLabel,
                isPdf: _isPdf,
              ),
            ),
      child: Container(
        width: 88,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.sm),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_isPdf || url == null)
                      Container(
                        color: AppColors.surfaceMuted,
                        child: Icon(
                          _isPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                          color: AppColors.mutedText2,
                        ),
                      )
                    else
                      Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: AppColors.surfaceMuted,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.mutedText2,
                              ),
                            ),
                      ),
                    if (isCritical)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                fileLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.ink900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultFilePreviewDialog extends StatefulWidget {
  const _ResultFilePreviewDialog({
    required this.fileUrl,
    required this.fileLabel,
    required this.isPdf,
  });

  final String fileUrl;
  final String fileLabel;
  final bool isPdf;

  @override
  State<_ResultFilePreviewDialog> createState() =>
      _ResultFilePreviewDialogState();
}

class _ResultFilePreviewDialogState extends State<_ResultFilePreviewDialog> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeName = widget.fileLabel.isNotEmpty
          ? widget.fileLabel
          : 'result-${DateTime.now().millisecondsSinceEpoch}';
      final savePath = '${dir.path}${Platform.pathSeparator}$safeName';
      await Dio().download(widget.fileUrl, savePath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'lab_booking.orders.result_download_success'.tr(
              args: [savePath],
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('lab_booking.orders.result_download_error'.tr()),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 420,
            child: widget.isPdf
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: Colors.white70,
                          size: 64,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.fileLabel,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                : InteractiveViewer(
                    child: Image.network(
                      widget.fileUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: FilledButton.icon(
                onPressed: _downloading ? null : _download,
                style: FilledButton.styleFrom(backgroundColor: brandBlue),
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_outlined, size: 18),
                label: Text('lab_booking.orders.download_cta'.tr()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
