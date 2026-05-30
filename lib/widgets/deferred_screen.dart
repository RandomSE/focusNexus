import 'package:flutter/material.dart';

/// Runs [load] on the first [build] (not in [State.initState]) and shows
/// [loading] until the future completes.
class DeferredScreen<T> extends StatefulWidget {
  const DeferredScreen({
    super.key,
    required this.load,
    required this.loading,
    required this.builder,
    this.errorBuilder,
    this.minLoadingMs = 0,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context) loading;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final int minLoadingMs;

  @override
  State<DeferredScreen<T>> createState() => _DeferredScreenState<T>();
}

class _DeferredScreenState<T> extends State<DeferredScreen<T>> {
  Future<T>? _future;
  Widget? _stableLoading;

  @override
  Widget build(BuildContext context) {
    _future ??= () async {
      final startedAt = DateTime.now();
      final data = await widget.load();
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      final remainingMs = widget.minLoadingMs - elapsedMs;
      if (remainingMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: remainingMs));
      }
      return data;
    }();
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _stableLoading = null;
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              Center(child: Text('${snapshot.error}'));
        }
        if (snapshot.connectionState != ConnectionState.done) {
          _stableLoading ??= widget.loading(context);
          return _stableLoading!;
        }
        _stableLoading = null;
        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}
