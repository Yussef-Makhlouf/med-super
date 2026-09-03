import 'failure.dart';

/// Bespoke sealed Result — repository/use-case contracts return this,
/// never throw across the domain boundary.
sealed class Result<T> {
  const Result._();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Ok() => null,
        Err(:final failure) => failure,
      };

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final failure) => err(failure),
      };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok(:final value) => Result.ok(transform(value)),
        Err(:final failure) => Result.err(failure),
      };

  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
        Ok(:final value) => transform(value),
        Err(:final failure) => Result.err(failure),
      };
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value) : super._();
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure) : super._();
}
