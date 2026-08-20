import 'dart:async';

/// Emits whenever either source emits, combining the two latest values.
///
/// The exercises and the training entries live in separate tables and arrive
/// as separate drift streams, but every screen wants them together. Written
/// here instead of adding rxdart for one operator.
///
/// Nothing is emitted until both sources have produced a value; after that,
/// every event from either side produces one. Errors and completion are
/// forwarded — the combined stream closes once both sources have.
Stream<R> combineLatest2<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A first, B second) combine,
) {
  late StreamController<R> controller;
  StreamSubscription<A>? firstSubscription;
  StreamSubscription<B>? secondSubscription;

  A? latestFirst;
  B? latestSecond;
  var hasFirst = false;
  var hasSecond = false;
  var closedCount = 0;

  void emit() {
    if (!hasFirst || !hasSecond) return;
    controller.add(combine(latestFirst as A, latestSecond as B));
  }

  void onSourceDone() {
    closedCount++;
    if (closedCount == 2) unawaited(controller.close());
  }

  controller = StreamController<R>(
    onListen: () {
      firstSubscription = first.listen(
        (value) {
          latestFirst = value;
          hasFirst = true;
          emit();
        },
        onError: controller.addError,
        onDone: onSourceDone,
      );
      secondSubscription = second.listen(
        (value) {
          latestSecond = value;
          hasSecond = true;
          emit();
        },
        onError: controller.addError,
        onDone: onSourceDone,
      );
    },
    onPause: () {
      firstSubscription?.pause();
      secondSubscription?.pause();
    },
    onResume: () {
      firstSubscription?.resume();
      secondSubscription?.resume();
    },
    onCancel: () async {
      await firstSubscription?.cancel();
      await secondSubscription?.cancel();
    },
  );

  return controller.stream;
}
