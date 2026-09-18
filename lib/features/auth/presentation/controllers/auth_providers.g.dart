// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRemoteDatasource)
final authRemoteDatasourceProvider = AuthRemoteDatasourceProvider._();

final class AuthRemoteDatasourceProvider
    extends
        $FunctionalProvider<
          AuthRemoteDatasource,
          AuthRemoteDatasource,
          AuthRemoteDatasource
        >
    with $Provider<AuthRemoteDatasource> {
  AuthRemoteDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRemoteDatasourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRemoteDatasourceHash();

  @$internal
  @override
  $ProviderElement<AuthRemoteDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthRemoteDatasource create(Ref ref) {
    return authRemoteDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRemoteDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRemoteDatasource>(value),
    );
  }
}

String _$authRemoteDatasourceHash() =>
    r'e80921f39c874ab92eaaf9d0cd60ba9b05766e88';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'a4da9445bcfc7de77e744cbba2be2a5901b2f35b';

@ProviderFor(requestOtpUseCase)
final requestOtpUseCaseProvider = RequestOtpUseCaseProvider._();

final class RequestOtpUseCaseProvider
    extends
        $FunctionalProvider<
          RequestOtpUseCase,
          RequestOtpUseCase,
          RequestOtpUseCase
        >
    with $Provider<RequestOtpUseCase> {
  RequestOtpUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestOtpUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestOtpUseCaseHash();

  @$internal
  @override
  $ProviderElement<RequestOtpUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RequestOtpUseCase create(Ref ref) {
    return requestOtpUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestOtpUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RequestOtpUseCase>(value),
    );
  }
}

String _$requestOtpUseCaseHash() => r'2968bbf3295859f372bfca1ae25dcd127ccd6ea6';

@ProviderFor(verifyOtpUseCase)
final verifyOtpUseCaseProvider = VerifyOtpUseCaseProvider._();

final class VerifyOtpUseCaseProvider
    extends
        $FunctionalProvider<
          VerifyOtpUseCase,
          VerifyOtpUseCase,
          VerifyOtpUseCase
        >
    with $Provider<VerifyOtpUseCase> {
  VerifyOtpUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifyOtpUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifyOtpUseCaseHash();

  @$internal
  @override
  $ProviderElement<VerifyOtpUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VerifyOtpUseCase create(Ref ref) {
    return verifyOtpUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerifyOtpUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerifyOtpUseCase>(value),
    );
  }
}

String _$verifyOtpUseCaseHash() => r'b12452af9519aceb5eb14a67ec29352415e7426a';

@ProviderFor(setPasswordUseCase)
final setPasswordUseCaseProvider = SetPasswordUseCaseProvider._();

final class SetPasswordUseCaseProvider
    extends
        $FunctionalProvider<
          SetPasswordUseCase,
          SetPasswordUseCase,
          SetPasswordUseCase
        >
    with $Provider<SetPasswordUseCase> {
  SetPasswordUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setPasswordUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setPasswordUseCaseHash();

  @$internal
  @override
  $ProviderElement<SetPasswordUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SetPasswordUseCase create(Ref ref) {
    return setPasswordUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetPasswordUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetPasswordUseCase>(value),
    );
  }
}

String _$setPasswordUseCaseHash() =>
    r'a7bf3ab7fc3ce9d7342f72c4c2b307816cb4f7a3';

@ProviderFor(loginWithPasswordUseCase)
final loginWithPasswordUseCaseProvider = LoginWithPasswordUseCaseProvider._();

final class LoginWithPasswordUseCaseProvider
    extends
        $FunctionalProvider<
          LoginWithPasswordUseCase,
          LoginWithPasswordUseCase,
          LoginWithPasswordUseCase
        >
    with $Provider<LoginWithPasswordUseCase> {
  LoginWithPasswordUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginWithPasswordUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginWithPasswordUseCaseHash();

  @$internal
  @override
  $ProviderElement<LoginWithPasswordUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LoginWithPasswordUseCase create(Ref ref) {
    return loginWithPasswordUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoginWithPasswordUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoginWithPasswordUseCase>(value),
    );
  }
}

String _$loginWithPasswordUseCaseHash() =>
    r'71a52713219ee63134c4c7fbef41fe4d94ded2de';

@ProviderFor(getCurrentUserUseCase)
final getCurrentUserUseCaseProvider = GetCurrentUserUseCaseProvider._();

final class GetCurrentUserUseCaseProvider
    extends
        $FunctionalProvider<
          GetCurrentUserUseCase,
          GetCurrentUserUseCase,
          GetCurrentUserUseCase
        >
    with $Provider<GetCurrentUserUseCase> {
  GetCurrentUserUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getCurrentUserUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getCurrentUserUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetCurrentUserUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetCurrentUserUseCase create(Ref ref) {
    return getCurrentUserUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetCurrentUserUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetCurrentUserUseCase>(value),
    );
  }
}

String _$getCurrentUserUseCaseHash() =>
    r'4c558036519273e5a4eae954197dcf61cff31679';

@ProviderFor(logoutUseCase)
final logoutUseCaseProvider = LogoutUseCaseProvider._();

final class LogoutUseCaseProvider
    extends $FunctionalProvider<LogoutUseCase, LogoutUseCase, LogoutUseCase>
    with $Provider<LogoutUseCase> {
  LogoutUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logoutUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logoutUseCaseHash();

  @$internal
  @override
  $ProviderElement<LogoutUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LogoutUseCase create(Ref ref) {
    return logoutUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogoutUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogoutUseCase>(value),
    );
  }
}

String _$logoutUseCaseHash() => r'c3c6c589cbff5a2f6618cc56b1f9faae632da27a';

@ProviderFor(switchContextUseCase)
final switchContextUseCaseProvider = SwitchContextUseCaseProvider._();

final class SwitchContextUseCaseProvider
    extends
        $FunctionalProvider<
          SwitchContextUseCase,
          SwitchContextUseCase,
          SwitchContextUseCase
        >
    with $Provider<SwitchContextUseCase> {
  SwitchContextUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'switchContextUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$switchContextUseCaseHash();

  @$internal
  @override
  $ProviderElement<SwitchContextUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SwitchContextUseCase create(Ref ref) {
    return switchContextUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SwitchContextUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SwitchContextUseCase>(value),
    );
  }
}

String _$switchContextUseCaseHash() =>
    r'599bef45a40069333f627db25865899bb1f44baa';
