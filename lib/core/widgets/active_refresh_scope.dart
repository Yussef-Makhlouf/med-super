import 'dart:async';

import 'package:flutter/material.dart';

/// Runs a bounded refresh while its route/tab is visible and the app is active.
/// Refreshes immediately when the app returns to the foreground.
class ActiveRefreshScope extends StatefulWidget {
  const ActiveRefreshScope({
    required this.onRefresh,
    required this.child,
    this.enabled = true,
    this.interval = const Duration(seconds: 15),
    super.key,
  }) : assert(interval >= const Duration(seconds: 10)),
       assert(interval <= const Duration(minutes: 5));

  final Future<void> Function() onRefresh;
  final Widget child;
  final bool enabled;
  final Duration interval;

  @override
  State<ActiveRefreshScope> createState() => _ActiveRefreshScopeState();
}

class _ActiveRefreshScopeState extends State<ActiveRefreshScope>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _appResumed = true;
  bool _routeCurrent = true;
  bool _tickerEnabled = true;
  bool _refreshing = false;
  bool _explicitlyEnabled = true;

  bool get _isActive =>
      _explicitlyEnabled && _appResumed && _routeCurrent && _tickerEnabled;

  @override
  void initState() {
    super.initState();
    _appResumed = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _explicitlyEnabled = widget.enabled;
    WidgetsBinding.instance.addObserver(this);
    _syncTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    _tickerEnabled = TickerMode.of(context);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant ActiveRefreshScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _explicitlyEnabled = widget.enabled;
    if (oldWidget.interval != widget.interval) {
      _timer?.cancel();
      _timer = null;
    }
    _syncTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    _syncTimer();
    if (_isActive) unawaited(_refreshSafely());
  }

  void _syncTimer() {
    if (!_isActive) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(widget.interval, (_) {
      if (_isActive) unawaited(_refreshSafely());
    });
  }

  Future<void> _refreshSafely() async {
    if (_refreshing || !_isActive) return;
    _refreshing = true;
    try {
      await widget.onRefresh();
    } catch (_) {
      // The watched provider retains its error state and the screen's retry
      // affordance remains available; periodic sync should not throw globally.
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
