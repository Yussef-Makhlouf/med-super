import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/network/mock/mock_responses.dart';
import 'package:med_super/core/theme/app_theme.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

/// Phone + password login screen for users who already finished signup.
class AccountLoginScreen extends ConsumerStatefulWidget {
  const AccountLoginScreen({super.key});

  @override
  ConsumerState<AccountLoginScreen> createState() => _AccountLoginScreenState();
}

class _AccountLoginScreenState extends ConsumerState<AccountLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late UserRole _role;
  bool _submitting = false;
  bool _obscurePassword = true;

  late final AnimationController _sheetController;
  late final Animation<Offset> _sheetOffset;
  late final Animation<double> _sheetOpacity;

  // Sheet snaps between two fixed states rather than tracking the finger/
  // scroll 1:1 — collapsed matches the original layout (60% of the screen),
  // expanded rises to 92% (topper, but a sliver of the hero stays visible).
  static const _collapsedFraction = 0.6;
  static const _expandedFraction = 0.92;
  bool _expanded = false;

  bool _handleSheetScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      if (pixels > 8 && !_expanded) {
        setState(() => _expanded = true);
      } else if (pixels <= 0 && _expanded) {
        // Covers mouse-wheel/trackpad scrolling back to the top, which
        // never produces an OverscrollNotification the way a touch drag
        // past the boundary does.
        setState(() => _expanded = false);
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0 && _expanded) {
        setState(() => _expanded = false);
      }
    }
    return false;
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  double _handleDragAccum = 0;

  void _onHandleDragUpdate(DragUpdateDetails details) {
    _handleDragAccum += details.delta.dy;
  }

  void _onHandleDragEnd(DragEndDetails details) {
    // Handle drag always works, regardless of whether the form content
    // below has anything left to scroll — unlike the scroll-notification
    // path, which goes silent once the expanded sheet gives the form
    // enough room that it no longer overflows.
    if (_handleDragAccum < -12 && !_expanded) {
      setState(() => _expanded = true);
    } else if (_handleDragAccum > 12 && _expanded) {
      setState(() => _expanded = false);
    }
    _handleDragAccum = 0;
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
    // Small delay before starting so the screen isn't mid-flight before the
    // first frame even paints — makes the rise-up unmistakable on load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sheetController.forward();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_submitting) return;

    final phone = normalizeEgyptPhone(_phoneController.text);
    setState(() => _submitting = true);
    try {
      final result = await ref
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
        final key = failureMessage(result.failure);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(key.tr())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
            backgroundColor: const Color(0xFFF3F6FB),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sheetTop =
                      constraints.maxHeight *
                      (1 -
                          (_expanded ? _expandedFraction : _collapsedFraction));
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
                              child: const _AccountLoginHeroIllustration(),
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        top: sheetTop,
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
                                                'auth.login_password_title'
                                                    .tr(),
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
                                                'auth.login_password_subtitle'
                                                    .tr(),
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
                                              _AccountPhoneField(
                                                controller: _phoneController,
                                              ),
                                              const SizedBox(height: 18),
                                              Text(
                                                'auth.password_label'.tr(),
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
                                                          12,
                                                        ),
                                                    borderSide:
                                                        const BorderSide(
                                                          color: Color(
                                                            0xFFD8DEE8,
                                                          ),
                                                        ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFFD8DEE8,
                                                              ),
                                                            ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
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
                                                          ? Icons
                                                                .visibility_outlined
                                                          : Icons
                                                                .visibility_off_outlined,
                                                      color: const Color(
                                                        0xFF8A94A6,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
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
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
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
                                              if (kDebugMode) ...[
                                                const SizedBox(height: 12),
                                                Text(
                                                  'auth.mock_login_hint'.tr(
                                                    namedArgs: {
                                                      'phone': kMockDemoPhone,
                                                      'password':
                                                          kMockDemoPassword,
                                                    },
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFF8A94A6,
                                                        ),
                                                      ),
                                                ),
                                              ],
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'auth.no_account_prompt'
                                                        .tr(),
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                          color: const Color(
                                                            0xFF8A94A6,
                                                          ),
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

class _AccountPhoneField extends StatelessWidget {
  const _AccountPhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        final raw = controller.text;
        if (raw.trim().isEmpty) return 'auth.phone_required'.tr();
        if (!isValidEgyptPhone(raw)) return 'auth.phone_invalid'.tr();
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
                      textInputAction: TextInputAction.next,
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

class _AccountLoginHeroIllustration extends StatelessWidget {
  const _AccountLoginHeroIllustration();

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
              Icons.lock_person_rounded,
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
