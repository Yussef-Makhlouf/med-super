import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_icons/solar_icons.dart';

/// Full-screen, edge-to-edge viewer for one or more network images.
///
/// Each image is fitted with `BoxFit.contain` against the *actual* viewport
/// (so a tall portrait prescription photo and a wide landscape one both fill
/// as much of the screen as they can without cropping), supports pinch and
/// double-tap zoom, horizontal swipe between images, and swipe-down to
/// dismiss while not zoomed in.
///
/// Open via [ImageGalleryViewer.open]; pass the same [heroTagFor] on the
/// thumbnails to get the shared-element transition.
class ImageGalleryViewer extends StatefulWidget {
  const ImageGalleryViewer({
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagFor,
    super.key,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final Object Function(int index)? heroTagFor;

  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    Object Function(int index)? heroTagFor,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => ImageGalleryViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          heroTagFor: heroTagFor,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late final PageController _pageController;
  late int _index;
  bool _zoomed = false;
  bool _chromeVisible = true;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset.abs() > 120 || velocity.abs() > 900) {
      _close();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.imageUrls.length;
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Background fades out as the image is dragged away, so the dismiss
    // gesture reads as "putting the photo back" rather than a glitch.
    final dragProgress = (_dragOffset.abs() / (screenHeight * 0.4)).clamp(
      0.0,
      1.0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 1 - dragProgress * 0.8),
        body: Stack(
          children: [
            GestureDetector(
              onTap: () => setState(() => _chromeVisible = !_chromeVisible),
              onVerticalDragUpdate: _zoomed ? null : _onVerticalDragUpdate,
              onVerticalDragEnd: _zoomed ? null : _onVerticalDragEnd,
              child: AnimatedContainer(
                duration: _dragOffset == 0
                    ? const Duration(milliseconds: 180)
                    : Duration.zero,
                transform: Matrix4.translationValues(0, _dragOffset, 0),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: count,
                  physics: _zoomed
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() {
                    _index = i;
                    _zoomed = false;
                  }),
                  itemBuilder: (context, i) => _ZoomableImage(
                    url: widget.imageUrls[i],
                    heroTag: widget.heroTagFor?.call(i),
                    onZoomChanged: (zoomed) {
                      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                    },
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _chromeVisible && _dragOffset == 0 ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: _TopBar(index: _index, count: count, onClose: _close),
              ),
            ),
            if (count > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _chromeVisible && _dragOffset == 0 ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < count; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _index ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.index,
    required this.count,
    required this.onClose,
  });

  final int index;
  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
          child: Row(
            children: [
              IconButton(
                onPressed: onClose,
                tooltip: 'common.image_viewer.close'.tr(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                ),
                icon: const Icon(
                  SolarIconsOutline.closeCircle,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (count > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    // Digits stay LTR even in Arabic so "2 / 3" never
                    // renders mirrored as "3 / 2".
                    '${index + 1} / $count',
                    textDirection: ui.TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({
    required this.url,
    required this.onZoomChanged,
    this.heroTag,
  });

  final String url;
  final Object? heroTag;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with SingleTickerProviderStateMixin {
  static const _doubleTapScale = 2.5;

  final _controller = TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          if (_animation != null) _controller.value = _animation!.value;
        });
    _controller.addListener(_reportZoom);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_reportZoom)
      ..dispose();
    _animController.dispose();
    super.dispose();
  }

  void _reportZoom() {
    widget.onZoomChanged(_controller.value.getMaxScaleOnAxis() > 1.01);
  }

  void _animateTo(Matrix4 target) {
    _animation = Matrix4Tween(begin: _controller.value, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0);
  }

  void _onDoubleTap() {
    if (_controller.value.getMaxScaleOnAxis() > 1.01) {
      _animateTo(Matrix4.identity());
      return;
    }
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    // Zoom toward the tapped point, so a patient double-tapping a drug name
    // lands on that line instead of the image center.
    final target = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (_doubleTapScale - 1),
        -position.dy * (_doubleTapScale - 1),
        0,
        1,
      )
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
    _animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      widget.url,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        return Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
              value: total == null
                  ? null
                  : progress.cumulativeBytesLoaded / total,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              SolarIconsOutline.galleryRemove,
              color: Colors.white70,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              'common.image_viewer.load_error'.tr(),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
    if (widget.heroTag != null) {
      image = Hero(tag: widget.heroTag!, child: image);
    }

    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 5,
        child: SizedBox.expand(child: image),
      ),
    );
  }
}
