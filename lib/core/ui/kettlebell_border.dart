import 'package:flutter/widgets.dart';

/// A kettlebell outline: a round body with a handle on top, the handle's
/// opening cut through.
///
/// Laid out from the width: the body is a circle as wide as the box, sitting
/// on its bottom edge, so the box should be about [aspectRatio] times as
/// tall as it is wide.
class KettlebellBorder extends ShapeBorder {
  const KettlebellBorder();

  /// Height over width for the shape to fill its box.
  static const aspectRatio = 1.35;

  /// The middle of the round body — where a label belongs.
  static Offset bodyCenter(Rect rect) =>
      Offset(rect.center.dx, rect.bottom - rect.width / 2);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final w = rect.width;
    final center = bodyCenter(rect);
    final body = Path()
      ..addOval(Rect.fromCircle(center: center, radius: w / 2));

    // The handle runs from the top edge down into the body, which covers its
    // lower half.
    final handle = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            center.dx - w * 0.365,
            rect.top,
            center.dx + w * 0.365,
            center.dy,
          ),
          Radius.circular(w * 0.19),
        ),
      );

    // The opening reaches into the body too; adding the body back afterwards
    // gives the opening its curved floor.
    final opening = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(
            center.dx - w * 0.195,
            rect.top + w * 0.17,
            center.dx + w * 0.195,
            center.dy,
          ),
          topLeft: Radius.circular(w * 0.05),
          topRight: Radius.circular(w * 0.05),
        ),
      );

    return Path.combine(
      PathOperation.union,
      Path.combine(PathOperation.difference, handle, opening),
      body,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;

  @override
  bool operator ==(Object other) => other is KettlebellBorder;

  @override
  int get hashCode => (KettlebellBorder).hashCode;
}
