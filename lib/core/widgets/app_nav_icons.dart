import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// The single place every reading-direction-dependent control resolves its
/// arrow icon through.
///
/// Solar icons are plain glyphs — unlike Material's `Icons.arrow_back`, they
/// do **not** auto-mirror with `Directionality`. Screens that hardcoded
/// `SolarIconsOutline.arrowRight`/`arrowLeft` directly (e.g. the shared
/// `FlowHeader`) are only correct in the locale they were built/tested in;
/// the other locale gets a backwards arrow. Every back/dismiss/disclosure
/// control must go through here instead.
///
/// Not for calendar/date pagination (prev/next week, etc.) — that's a
/// temporal axis, not a reading-direction one, and stays fixed
/// left=previous/right=next regardless of locale by convention.
abstract final class AppNavIcons {
  static IconData back(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
          ? SolarIconsOutline.arrowRight
          : SolarIconsOutline.arrowLeft;

  static IconData forward(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
          ? SolarIconsOutline.arrowLeft
          : SolarIconsOutline.arrowRight;

  static IconData chevronBack(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
          ? SolarIconsOutline.altArrowRight
          : SolarIconsOutline.altArrowLeft;

  static IconData chevronForward(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
          ? SolarIconsOutline.altArrowLeft
          : SolarIconsOutline.altArrowRight;
}
