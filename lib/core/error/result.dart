// typedef Result<T> = Either<Failure, T> (or a bespoke sealed Result<T>).
// Repository/use case contracts return this — never throw across the
// domain boundary.
