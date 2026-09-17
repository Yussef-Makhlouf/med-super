import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/repositories/provider_registration_repository.dart';
import 'package:med_super/features/provider_registration/domain/usecases/submit_registration_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ProviderRegistrationRepository {}

void main() {
  late _MockRepository repository;
  late SubmitRegistrationUseCase usecase;

  setUp(() {
    repository = _MockRepository();
    usecase = SubmitRegistrationUseCase(repository);
  });

  const draft = DoctorRegistrationDraft(fullName: 'Dr. X');

  test('delegates to repository.submit with the given draft', () async {
    when(
      () => repository.submit(draft),
    ).thenAnswer((_) async => const Result.ok(null));

    await usecase.call(draft);

    verify(() => repository.submit(draft)).called(1);
  });

  test('passes through an Ok result unchanged', () async {
    when(
      () => repository.submit(draft),
    ).thenAnswer((_) async => const Result.ok(null));

    final result = await usecase.call(draft);

    expect(result.isOk, isTrue);
  });

  test('passes through an Err result unchanged', () async {
    const failure = Failure.network();
    when(
      () => repository.submit(draft),
    ).thenAnswer((_) async => const Result.err(failure));

    final result = await usecase.call(draft);

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, failure);
  });

  test('does not call repository more than once per call()', () async {
    when(
      () => repository.submit(draft),
    ).thenAnswer((_) async => const Result.ok(null));

    await usecase.call(draft);

    // Mocktail requires the interaction to be `verify()`-ed before
    // `verifyNoMoreInteractions` will consider it accounted for.
    verify(() => repository.submit(draft)).called(1);
    verifyNoMoreInteractions(repository);
  });
}
