import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/app/router/app_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_theme.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/auth_hero_illustration.dart';
import 'package:med_super/core/widgets/auth_phone_field.dart';
import 'package:med_super/core/widgets/auth_role_toggle.dart';
import 'package:med_super/features/auth/domain/entities/otp_request_result.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:solar_icons/solar_icons.dart';

/// Send-OTP / login screen — matches Figma (light, Arabic RTL).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin, RouteAware {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late UserRole _role;
  bool _sending = false;

  late final AnimationController _sheetController;
  late final Animation<Offset> _sheetOffset;
  late final Animation<double> _sheetOpacity;

  // Sheet extent as a live 0..1 fraction between _collapsedFraction (60%)
  // and _expandedFraction (92%) — driven directly by drag deltas (not just
  // snapped once on release) and read by an AnimatedBuilder scoped to only
  // the sheet's Positioned wrapper, so dragging tracks the finger in real
  // time and repaints just that subtree instead of the whole screen.
  late final AnimationController _extentController;
  static const _collapsedFraction = 0.6;
  static const _expandedFraction = 0.92;
  double _sheetHeight = 1;

  void _animateExtentTo(double target) {
    _extentController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  bool _handleSheetScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      if (pixels > 8 && _extentController.value < 1) {
        _animateExtentTo(1);
      } else if (pixels <= 0 && _extentController.value > 0) {
        // Covers mouse-wheel/trackpad scrolling back to the top, which
        // never produces an OverscrollNotification the way a touch drag
        // past the boundary does.
        _animateExtentTo(0);
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0 && _extentController.value > 0) {
        _animateExtentTo(0);
      }
    }
    return false;
  }

  void _toggleExpanded() =>
      _animateExtentTo(_extentController.value > 0.5 ? 0 : 1);

  void _onHandleDragUpdate(DragUpdateDetails details) {
    // Live 1:1 tracking: each dragged pixel maps directly to a fraction of
    // the sheet's travel range and is applied straight to the controller,
    // so the sheet visibly follows the finger during the drag itself
    // instead of only jumping once on release.
    final range = _sheetHeight * (_expandedFraction - _collapsedFraction);
    if (range <= 0) return;
    _extentController.value =
        (_extentController.value - details.delta.dy / range).clamp(0.0, 1.0);
  }

  void _onHandleDragEnd(DragEndDetails details) {
    // Snap to whichever side is closer, nudged by fling velocity so a
    // quick flick commits even from near the midpoint.
    final velocityBias = (details.primaryVelocity ?? 0) / 2000;
    final target =
        (_extentController.value - velocityBias) > 0.5 ? 1.0 : 0.0;
    _animateExtentTo(target);
  }

  @override
  void initState() {
    super.initState();
    _role = UserRole.patient;
    // Bottom sheet rises up from off-screen into place on first frame,
    // instead of appearing static — a more inviting entrance.
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _sheetOffset = Tween<Offset>(begin: const Offset(0, 1.4), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _sheetController, curve: Curves.easeOutBack),
        );
    _sheetOpacity = CurvedAnimation(
      parent: _sheetController,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    _extentController = AnimationController(vsync: this, value: 0);
    // Small delay before starting so the screen isn't mid-flight before the
    // first frame even paints — makes the rise-up unmistakable on load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sheetController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Coming back into view after popping a pushed screen (e.g. back from
    // '/account-login') — collapse back to the initial position instead of
    // staying in whatever state it was left in.
    if (_extentController.value > 0) _animateExtentTo(0);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _phoneController.dispose();
    _sheetController.dispose();
    _extentController.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_sending) return;

    final phone = normalizeEgyptPhone(_phoneController.text);
    setState(() => _sending = true);
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .requestOtp(phone: phone, role: _role);

      if (!mounted) return;

      if (result is Ok<OtpRequestResult>) {
        final value = result.value;
        context.push(
          '/verify-otp',
          extra: {
            'phone': phone,
            'role': _role.name,
            'requestId': value.requestId,
          },
        );
      } else if (result is Err<OtpRequestResult>) {
        final message = authFailureMessage(result.failure);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force light theme — Figma send-OTP is light even when app is dark.
    return Theme(
      data: AppTheme.light(),
      child: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          return Scaffold(
            backgroundColor: AppPalette.paper,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _sheetHeight = constraints.maxHeight;
                  return Stack(
                    children: [
                      // Pinned to the original top region (unchanged design)
                      // — the rising sheet simply covers it as it expands,
                      // instead of the hero being re-centered on the whole
                      // screen height.
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height:
                            constraints.maxHeight * (1 - _collapsedFraction),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: const AspectRatio(
                              aspectRatio: 1,
                              child: AuthBlobHeroIllustration(
                                icon: SolarIconsBold.health,
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _extentController,
                        builder: (context, child) {
                          final fraction = _collapsedFraction +
                              (_expandedFraction - _collapsedFraction) *
                                  _extentController.value;
                          return Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            top: constraints.maxHeight * (1 - fraction),
                            child: child!,
                          );
                        },
                        child: SlideTransition(
                          position: _sheetOffset,
                          child: FadeTransition(
                            opacity: _sheetOpacity,
                            child: Material(
                              color: Colors.white,
                              elevation: 8,
                              shadowColor: Colors.black26,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _toggleExpanded,
                                    onVerticalDragUpdate: _onHandleDragUpdate,
                                    onVerticalDragEnd: _onHandleDragEnd,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 10,
                                        bottom: 12,
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: AppPalette.border,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: NotificationListener<ScrollNotification>(
                                      onNotification: _handleSheetScroll,
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          24,
                                          28,
                                          24,
                                          24,
                                        ),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'auth.welcome_intro'.tr(),
                                                textAlign: TextAlign.center,
                                                style: textTheme.headlineSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppPalette.ink,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'auth.welcome_intro_subtitle'.tr(),
                                                textAlign: TextAlign.center,
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppPalette.inkMuted,
                                                    ),
                                              ),
                                              const SizedBox(height: 22),
                                              AuthRoleToggle<UserRole>(
                                                entries: [
                                                  (
                                                    'auth.role_doctor'.tr(),
                                                    UserRole.doctor,
                                                  ),
                                                  (
                                                    'auth.role_patient'.tr(),
                                                    UserRole.patient,
                                                  ),
                                                ],
                                                value: _role,
                                                onChanged: (role) => setState(
                                                  () => _role = role,
                                                ),
                                              ),
                                              const SizedBox(height: 22),
                                              Text(
                                                'auth.phone_label'.tr(),
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppPalette.ink,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              AuthPhoneField(
                                                controller: _phoneController,
                                                validator: (_) {
                                                  final digits =
                                                      _phoneController.text
                                                          .replaceAll(
                                                            RegExp(r'\D'),
                                                            '',
                                                          );
                                                  if (digits.isEmpty) {
                                                    return 'auth.phone_required'
                                                        .tr();
                                                  }
                                                  if (!isValidEgyptPhone(
                                                    digits,
                                                  )) {
                                                    return 'auth.phone_invalid'
                                                        .tr();
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 24),
                                              SizedBox(
                                                height: 56,
                                                child: ElevatedButton(
                                                  onPressed: _sending
                                                      ? null
                                                      : _onSendOtp,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: brandBlue,
                                                    foregroundColor:
                                                        Colors.white,
                                                    disabledBackgroundColor:
                                                        brandBlue.withValues(
                                                          alpha: 0.5,
                                                        ),
                                                    elevation: 0,
                                                    shape:
                                                        const StadiumBorder(),
                                                  ),
                                                  child: _sending
                                                      ? const SizedBox(
                                                          width: 22,
                                                          height: 22,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        )
                                                      : Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'auth.send_otp'
                                                                  .tr(),
                                                              style: textTheme
                                                                  .titleMedium
                                                                  ?.copyWith(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            const Icon(
                                                              SolarIconsOutline
                                                                  .arrowLeft,
                                                              size: 20,
                                                            ),
                                                          ],
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'auth.have_account_prompt'
                                                        .tr(),
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                          color: AppPalette
                                                              .inkMuted,
                                                        ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => context
                                                        .push('/account-login'),
                                                    child: Text(
                                                      'auth.login_link_cta'
                                                          .tr(),
                                                      style: const TextStyle(
                                                        color: brandBlue,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

