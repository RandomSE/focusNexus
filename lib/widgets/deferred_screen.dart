import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/providers/deferred_load_params.dart';
import 'package:focusNexus/providers/deferred_load_provider.dart';

/// Runs [load] via [deferredScreenLoadProvider] and shows [loading] until ready.
class DeferredScreen<T> extends ConsumerStatefulWidget {
  const DeferredScreen({
    super.key,
    required this.loadToken,
    required this.load,
    required this.loading,
    required this.builder,
    this.errorBuilder,
    this.minLoadingMs = 0,
  });

  /// Stable id for the async family (include generation when reload is needed).
  final String loadToken;
  final Future<T> Function() load;
  final Widget Function(BuildContext context) loading;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final int minLoadingMs;

  @override
  ConsumerState<DeferredScreen<T>> createState() => _DeferredScreenState<T>();
}

class _DeferredScreenState<T> extends ConsumerState<DeferredScreen<T>> {
  late DeferredLoadParams _params;
  Widget? _stableLoading;

  @override
  void initState() {
    super.initState();
    _params = _buildParams();
  }

  @override
  void didUpdateWidget(covariant DeferredScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadToken != widget.loadToken ||
        oldWidget.minLoadingMs != widget.minLoadingMs) {
      _params = _buildParams();
      _stableLoading = null;
    }
  }

  DeferredLoadParams _buildParams() {
    return DeferredLoadParams(
      token: widget.loadToken,
      minLoadingMs: widget.minLoadingMs,
      loader: () async => await widget.load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(deferredScreenLoadProvider(_params));

    return async.when(
      loading: () {
        _stableLoading ??= widget.loading(context);
        return _stableLoading!;
      },
      error: (error, _) {
        _stableLoading = null;
        return widget.errorBuilder?.call(context, error) ??
            Center(child: Text('$error'));
      },
      data: (data) {
        _stableLoading = null;
        return widget.builder(context, data as T);
      },
    );
  }
}
