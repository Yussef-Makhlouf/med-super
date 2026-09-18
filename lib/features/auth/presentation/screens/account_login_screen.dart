import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_theme.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/auth_hero_illustration.dart';
import 'package:med_super/core/widgets/auth_phone_field.dart';
import 'package:med_super/core/widgets/auth_role_toggle.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/auth/presentation/widgets/auth_secondary_entry_cards.dart';
import 'package:solar_icons/solar_icons.dart';

/// Phone + password login screen for users who already finished signup.
class AccountLoginScreen extends ConsumerStatefulWidget {
  const AccountLoginScreen({
    this.successMessageKey,
    this.isProviderLogin = false,
    this.loginHandler,
    super.key,
  });

  /// Reuses the password-login form on the provider-only route while keeping
  /// the patient route free from a role selector.
  const AccountLoginScreen.provider({super.key})
    : successMessageKey = null,
      isProviderLogin = true,
      loginHandler = null;

  /// Translation key for a one-shot success message shown on arrival, e.g.
  /// after a completed password reset (which does not auto-login).
  final String? successMessageKey;

  /// Whether this route is the provider entry point (Doctor / Clinic staff).
  final bool isProviderLogin;

  /// A narrow test seam for checking the selected role without duplicating the
  /// production auth flow. Normal app use always calls [SessionController].
  final AccountLoginHandler? loginHandler;

  @override
  ConsumerState<AccountLoginScreen> createState() => _AccountLoginScreenState();
}

typedef AccountLoginHandler =
    Future<Result<Session>> Function({
      required String phone,
      required String password,
      required UserRole role,
    });

class _AccountLoginScreenState extends ConsumerState<AccountLoginScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late UserRole _role;
  bool _submitting = false;
  bool _obscurePassword = true;

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
    final target = (_extentController.value - velocityBias) > 0.5 ? 1.0 : 0.0;
    _animateExtentTo(target);
  }

  @override
  void initState() {
    super.initState();
    _role = widget.isProviderLogin ? UserRole.doctor : UserRole.patient;
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
      final key = widget.successMessageKey;
      if (key != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(key.tr())));
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _sheetController.dispose();
    _extentController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_submitting) return;

    final phone = normalizeEgyptPhone(_phoneController.text);
    setState(() => _submitting = true);
    try {
      final handler = widget.loginHandler;
      final result = handler != null
          ? await handler(
              phone: phone,
              password: _passwordController.text,
              role: _role,
            )
          : await ref
                .read(sessionControllerProvider.notifier)
                .loginWithPassword(
                  phone: phone,
                  password: _passwordController.text,
                  role: _role,
                );

      if (!mounted) return;

      if (result is Ok<Session>) {
        context.go('/');
      } else if (result is Err<Session>) {
        final message = authFailureMessage(result.failure);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _returnToPatientLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/account-login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force light theme — matches the send-OTP screen even when app is dark.
    // splashFactory override avoids Material 3's default InkSparkle, whose
    // fragment shader throws on backends (and the software renderer used
    // under `flutter test`) that don't support its runtime stage data.
    return Theme(
      data: AppTheme.light().copyWith(splashFactory: InkRipple.splashFactory),
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
                      if (widget.isProviderLogin)
                        PositionedDirectional(
                          top: 0,
                          start: 0,
                          child: IconButton(
                            onPressed: _returnToPatientLogin,
                            color: AppPalette.ink,
                            icon: const BackButtonIcon(),
                          ),
                        ),
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
                                icon: SolarIconsBold.lockKeyhole,
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _extentController,
                        builder: (context, child) {
                          final fraction =
                              _collapsedFraction +
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
                                                (widget.isProviderLogin
                                                        ? 'auth.provider_login_title'
                                                        : 'auth.login_password_title')
                                                    .tr(),
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
                                                (widget.isProviderLogin
                                                        ? 'auth.provider_login_subtitle'
                                                        : 'auth.login_password_subtitle')
                                                    .tr(),
                                                textAlign: TextAlign.center,
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppPalette.inkMuted,
                                                    ),
                                              ),
                                              const SizedBox(height: 22),
                                              if (widget.isProviderLogin) ...[
                                                AuthRoleToggle<UserRole>(
                                                  entries: [
                                                    (
                                                      'auth.role_doctor'.tr(),
                                                      UserRole.doctor,
                                                    ),
                                                    (
                                                      'auth.role_clinic_staff'
                                                          .tr(),
                                                      UserRole.clinicStaff,
                                                    ),
                                                  ],
                                                  value: _role,
                                                  onChanged: (role) => setState(
                                                    () => _role = role,
                                                  ),
                                                ),
                                                const SizedBox(height: 22),
                                              ],
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
                                                textInputAction:
                                                    TextInputAction.next,
                                                validator: (_) {
                                                  final raw =
                                                      _phoneController.text;
                                                  if (raw.trim().isEmpty) {
                                                    return 'auth.phone_required'
                                                        .tr();
                                                  }
                                                  if (!isValidEgyptPhone(raw)) {
                                                    return 'auth.phone_invalid'
                                                        .tr();
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 18),
                                              Text(
                                                'auth.password_label'.tr(),
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppPalette.ink,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
                                                textInputAction:
                                                    TextInputAction.done,
                                                onFieldSubmitted: (_) =>
                                                    _onLogin(),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'auth.password_required'
                                                        .tr();
                                                  }
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                  hintText: 'auth.password_hint'
                                                      .tr(),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppRadii.md,
                                                        ),
                                                    borderSide:
                                                        const BorderSide(
                                                          color:
                                                              AppPalette.border,
                                                        ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              AppRadii.md,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: AppPalette
                                                                  .border,
                                                            ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              AppRadii.md,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: brandBlue,
                                                            ),
                                                      ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 14,
                                                      ),
                                                  suffixIcon: IconButton(
                                                    onPressed: () => setState(
                                                      () => _obscurePassword =
                                                          !_obscurePassword,
                                                    ),
                                                    icon: Icon(
                                                      _obscurePassword
                                                          ? SolarIconsOutline
                                                                .eye
                                                          : SolarIconsOutline
                                                                .eyeClosed,
                                                      color:
                                                          AppPalette.inkMuted,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: () => context.push(
                                                    '/forgot-password',
                                                  ),
                                                  child: Text(
                                                    'auth.forgot_password_link_cta'
                                                        .tr(),
                                                    style: const TextStyle(
                                                      color: brandBlue,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                height: 56,
                                                child: ElevatedButton(
                                                  onPressed: _submitting
                                                      ? null
                                                      : _onLogin,
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
                                                  child: _submitting
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
                                                      : Text(
                                                          'auth.login_password_cta'
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
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              if (widget.isProviderLogin)
                                                PatientEntryCard(
                                                  onTap: _returnToPatientLogin,
                                                )
                                              else ...[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'auth.no_account_prompt'
                                                          .tr(),
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: AppPalette
                                                                .inkMuted,
                                                          ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          context.go('/login'),
                                                      child: Text(
                                                        'auth.signup_cta'.tr(),
                                                        style: const TextStyle(
                                                          color: brandBlue,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                ProviderEntryCard(
                                                  onTap: () => context.push(
                                                    '/provider-login',
                                                  ),
                                                ),
                                              ],
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
