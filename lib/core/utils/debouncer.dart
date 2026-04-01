import 'dart:async';

import 'package:flutter/foundation.dart';

/// A simple debouncer for rate-limiting user-triggered actions such as
/// search-as-you-type.
///
/// ```dart
/// final _debouncer = Debouncer(milliseconds: 500);
///
/// void onSearchChanged(String query) {
///   _debouncer.run(() => _performSearch(query));
/// }
///
/// @override
/// void dispose() {
///   _debouncer.dispose();
///   super.dispose();
/// }
/// ```
class Debouncer {
  Debouncer({this.milliseconds = 500});

  /// The debounce window in milliseconds.
  final int milliseconds;

  Timer? _timer;

  /// Schedules [action] to run after the debounce window.
  ///
  /// If [run] is called again before the window elapses, the previous
  /// pending call is cancelled and a new window begins.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Returns `true` when a debounced action is pending.
  bool get isActive => _timer?.isActive ?? false;

  /// Cancels any pending action and releases the timer.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
