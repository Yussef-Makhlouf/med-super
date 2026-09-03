import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/app/router/app_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/app_theme.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/domain/entities/otp_request_result.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

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
        final key = failureMessage(result.failure);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(key.tr())));
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
            backgroundColor: const Color(0xFFF3F6FB),
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
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: const _LoginHeroIllustration(),
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
                                            color: const Color(0xFFD8DEE8),
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
                                                      color: const Color(
                                                        0xFF1A2B4A,
                                                      ),
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'auth.welcome_intro_subtitle'.tr(),
                                                textAlign: TextAlign.center,
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      color: const Color(
                                                        0xFF8A94A6,
                                                      ),
                                                    ),
                                              ),
                                              const SizedBox(height: 22),
                                              _RoleToggle(
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
                                                      color: const Color(
                                                        0xFF1A2B4A,
                                                      ),
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              _PhoneField(
                                                controller: _phoneController,
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
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
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
                                                              Icons.arrow_back,
                                                              size: 20,
                                                            ),
                                                          ],
                                                        ),
                                                ),
                                              ),
                                              if (kDebugMode) ...[
                                                const SizedBox(height: 12),
                                                Text(
                                                  'auth.mock_otp_hint'.tr(),
                                                  textAlign: TextAlign.center,
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFF8A94A6,
                                                        ),
                                                      ),
                                                ),
                                              ],
                                              const SizedBox(height: 24),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    child: Divider(),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    child: Text(
                                                      'common.or'.tr(),
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color: const Color(
                                                              0xFF8A94A6,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  const Expanded(
                                                    child: Divider(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              Center(
                                                child: Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: brandBlue
                                                          .withValues(
                                                            alpha: 0.45,
                                                          ),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: IconButton(
                                                    onPressed: () {
                                                      // Biometric wired in a later sprint.
                                                    },
                                                    icon: const Icon(
                                                      Icons.fingerprint,
                                                      color: brandBlue,
                                                      size: 28,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'auth.have_account_prompt'
                                                        .tr(),
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                          color: const Color(
                                                            0xFF8A94A6,
                                                          ),
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

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleChip(
              label: 'auth.role_doctor'.tr(),
              selected: value == UserRole.doctor,
              onTap: () => onChanged(UserRole.doctor),
            ),
          ),
          Expanded(
            child: _RoleChip(
              label: 'auth.role_patient'.tr(),
              selected: value == UserRole.patient,
              onTap: () => onChanged(UserRole.patient),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? brandBlue : const Color(0xFF8A94A6),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        final digits = controller.text.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) return 'auth.phone_required'.tr();
        if (!isValidEgyptPhone(digits)) return 'auth.phone_invalid'.tr();
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: field.hasError
                      ? Theme.of(context).colorScheme.error
                      : const Color(0xFFD8DEE8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.start,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      onChanged: field.didChange,
                      decoration: InputDecoration(
                        hintText: 'auth.phone_hint'.tr(),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFD8DEE8),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'auth.country_code'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2B4A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('🇪🇬', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LoginHeroIllustration extends StatelessWidget {
  const _LoginHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 28,
            left: 36,
            child: _blob(36, brandBlue.withValues(alpha: 0.25)),
          ),
          Positioned(
            top: 48,
            right: 40,
            child: _blob(22, brandBlue.withValues(alpha: 0.35)),
          ),
          Positioned(
            bottom: 56,
            left: 48,
            child: _blob(18, brandBlue.withValues(alpha: 0.2)),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: brandBlue,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: brandBlue.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 64,
            ),
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
