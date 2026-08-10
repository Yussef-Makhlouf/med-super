import 'package:responsive_framework/responsive_framework.dart';

/// responsive_framework breakpoints — MOBILE < 600, TABLET < 1024, DESKTOP ≥ 1024.
const appBreakpoints = [
  Breakpoint(start: 0, end: 599, name: MOBILE),
  Breakpoint(start: 600, end: 1023, name: TABLET),
  Breakpoint(start: 1024, end: double.infinity, name: DESKTOP),
];
