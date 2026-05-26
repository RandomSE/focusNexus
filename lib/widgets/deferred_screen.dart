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
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context) loading;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  State<DeferredScreen<T>> createState() => _DeferredScreenState<T>();
}

class _DeferredScreenState<T> extends State<DeferredScreen<T>> {
  Future<T>? _future;

  @override
  Widget build(BuildContext context) {
    _future ??= widget.load();
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              Center(child: Text('${snapshot.error}'));
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loading(context);
        }
        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}
