import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/error/failure.dart';
import 'error_banner.dart';
import 'empty_state.dart';

/// Renders an [AsyncValue<T>] with appropriate UI per state/failure type.
/// Never shows a generic error toast — maps Failure variants to distinct UX.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.onRetry,
    this.loadingWidget,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () =>
          loadingWidget ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(context, error),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    if (error is! Failure) {
      return ErrorBanner(message: error.toString(), onRetry: onRetry);
    }

    return switch (error) {
      NetworkFailure() => ErrorBanner(
        message: 'No internet connection. Check your network and try again.',
        onRetry: onRetry,
      ),
      ServerFailure(:final message) => ErrorBanner(
        message: message ?? 'Something went wrong. Please try again.',
        onRetry: onRetry,
      ),
      AuthFailure() => const EmptyState(
        title: 'Session expired',
        subtitle: 'Please sign in again.',
        icon: Icons.lock_outline,
      ),
      ValidationFailure(:final fieldErrors) => ErrorBanner(
        message: fieldErrors.values.first,
      ),
      ConflictFailure(:final reason) => _ConflictDialog(reason: reason),
      CacheFailure() => ErrorBanner(
        message: 'Could not load cached data.',
        onRetry: onRetry,
      ),
      UnknownFailure() => ErrorBanner(
        message: 'An unexpected error occurred.',
        onRetry: onRetry,
      ),
    };
  }
}

class _ConflictDialog extends StatelessWidget {
  const _ConflictDialog({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_outlined, size: 40),
              const SizedBox(height: 12),
              Text(
                reason,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
