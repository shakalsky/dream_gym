import 'dart:math' as math;

import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// One exercise's progress over its sessions.
///
/// Deliberately one line and one colour: the three metrics have different units
/// and are switched between, never stacked on two y-axes. The number above the
/// plot is the headline — it follows the finger while scrubbing, so a point can
/// be read exactly without a floating tooltip to place.
class ProgressChart extends StatefulWidget {
  const ProgressChart({
    required this.points,
    required this.metric,
    this.plotHeight = 160,
    super.key,
  });

  /// Oldest first.
  final List<ProgressPoint> points;

  final ProgressMetric metric;
  final double plotHeight;

  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart> {
  /// Which point the reader is inspecting, or null for 'the latest one'.
  int? _selected;

  @override
  void didUpdateWidget(ProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A new exercise or metric means the old index means nothing.
    if (oldWidget.points != widget.points || oldWidget.metric != widget.metric) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final points = widget.points;

    if (points.isEmpty) return const SizedBox.shrink();

    final index = _selected ?? points.length - 1;
    final point = points[index];
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _selected == null
                  ? 'Latest · ${formatDay(point.day, today: today)}'
                  : formatDay(point.day, today: today),
              style: context.appFonts.labelMedium?.copyWith(
                color: colors.gray500,
              ),
            ),
            const Spacer(),
            Text(
              widget.metric.format(point.value),
              style: context.appFonts.titleLarge?.copyWith(
                color: colors.gray1000,
              ),
            ),
          ],
        ),
        AppSizes.padding12.verticalSpace,
        SizedBox(
          height: widget.plotHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final geometry = _ChartGeometry(
                size: Size(constraints.maxWidth, widget.plotHeight),
                points: points,
              );

              return GestureDetector(
                // Tap and drag both scrub: a finger on a 160px plot is not
                // precise, and letting it slide is how a reader finds the point
                // they meant.
                onTapDown: (details) =>
                    _scrub(geometry, details.localPosition.dx),
                onHorizontalDragStart: (details) =>
                    _scrub(geometry, details.localPosition.dx),
                onHorizontalDragUpdate: (details) =>
                    _scrub(geometry, details.localPosition.dx),
                child: Semantics(
                  label: _semanticsLabel(points, widget.metric),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, widget.plotHeight),
                    painter: _ProgressChartPainter(
                      geometry: geometry,
                      metric: widget.metric,
                      selectedIndex: _selected,
                      lineColor: colors.primary500,
                      // Under the line only — a fill this faint reads as
                      // volume, not as a second series.
                      fillColor: colors.primary500.withValues(alpha: 0.12),
                      gridColor: colors.gray100,
                      markerRingColor: colors.surface,
                      labelStyle:
                          context.appFonts.labelSmall?.copyWith(
                            color: colors.gray400,
                          ) ??
                          const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _scrub(_ChartGeometry geometry, double dx) {
    final index = geometry.indexAt(dx);
    if (index != _selected) setState(() => _selected = index);
  }

  static String _semanticsLabel(
    List<ProgressPoint> points,
    ProgressMetric metric,
  ) {
    final first = points.first;
    final last = points.last;

    return '${metric.label} over ${points.length} '
        '${points.length == 1 ? 'session' : 'sessions'}, from '
        '${metric.format(first.value)} on ${formatDate(first.day, withYear: true)} '
        'to ${metric.format(last.value)} on ${formatDate(last.day, withYear: true)}. '
        'The list of sessions below has every value.';
  }
}

/// Where everything goes. Kept apart from the painter so the gesture handler
/// can ask the same question the paint pass answers: which point is at this x?
class _ChartGeometry {
  _ChartGeometry({required this.size, required this.points});

  /// Room for the value labels on the left and the dates underneath.
  static const _leftGutter = 44.0;
  static const _bottomGutter = 20.0;
  static const _topPadding = 8.0;
  static const _rightPadding = 8.0;

  final Size size;
  final List<ProgressPoint> points;

  double get plotLeft => _leftGutter;

  double get plotRight => size.width - _rightPadding;

  double get plotTop => _topPadding;

  double get plotBottom => size.height - _bottomGutter;

  double get plotWidth => math.max(0, plotRight - plotLeft);

  double get plotHeight => math.max(0, plotBottom - plotTop);

  /// The lowest and highest values on the axis.
  ///
  /// Padded by a tenth so the line never runs along the top edge, and given a
  /// range of its own when every session was identical — a flat line through
  /// the middle is the honest picture of 'no change'.
  (double, double) get bounds {
    var lowest = points.first.value;
    var highest = points.first.value;

    for (final point in points) {
      lowest = math.min(lowest, point.value);
      highest = math.max(highest, point.value);
    }

    if (lowest == highest) {
      final padding = lowest.abs() < 1 ? 1.0 : lowest.abs() * 0.1;
      return (lowest - padding, highest + padding);
    }

    final padding = (highest - lowest) * 0.1;
    return (lowest - padding, highest + padding);
  }

  /// Sessions are spaced evenly rather than by date: this is a chart of one
  /// training after another, and the axis labels carry the dates.
  double xOf(int index) {
    if (points.length == 1) return plotLeft + plotWidth / 2;
    return plotLeft + plotWidth * index / (points.length - 1);
  }

  double yOf(double value) {
    final (lowest, highest) = bounds;
    final fraction = (value - lowest) / (highest - lowest);
    return plotBottom - plotHeight * fraction;
  }

  Offset offsetOf(int index) =>
      Offset(xOf(index), yOf(points[index].value));

  /// The point nearest to a horizontal position.
  int indexAt(double dx) {
    if (points.length == 1) return 0;

    final fraction = ((dx - plotLeft) / plotWidth).clamp(0.0, 1.0);
    return (fraction * (points.length - 1)).round();
  }
}

class _ProgressChartPainter extends CustomPainter {
  _ProgressChartPainter({
    required this.geometry,
    required this.metric,
    required this.selectedIndex,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.markerRingColor,
    required this.labelStyle,
  });

  /// Below this many sessions every point gets a marker; above it the line
  /// alone reads better than a row of touching dots.
  static const _maxMarkers = 14;

  final _ChartGeometry geometry;
  final ProgressMetric metric;
  final int? selectedIndex;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color markerRingColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final points = geometry.points;
    if (points.isEmpty || geometry.plotWidth <= 0) return;

    final (lowest, highest) = geometry.bounds;

    _paintGrid(canvas, lowest: lowest, highest: highest);
    _paintDates(canvas);

    final vertices = [
      for (var i = 0; i < points.length; i++) geometry.offsetOf(i),
    ];

    if (vertices.length > 1) {
      _paintFill(canvas, vertices);

      final line = Path()..moveTo(vertices.first.dx, vertices.first.dy);
      for (final vertex in vertices.skip(1)) {
        line.lineTo(vertex.dx, vertex.dy);
      }

      canvas.drawPath(
        line,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    _paintMarkers(canvas, vertices);
  }

  void _paintGrid(
    Canvas canvas, {
    required double lowest,
    required double highest,
  }) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Three lines: the two ends of the axis and its middle. Enough to read a
    // level off, few enough to stay behind the data.
    for (final fraction in const [0.0, 0.5, 1.0]) {
      final value = lowest + (highest - lowest) * fraction;
      final y = geometry.yOf(value);

      canvas.drawLine(
        Offset(geometry.plotLeft, y),
        Offset(geometry.plotRight, y),
        paint,
      );

      // Only the ends are labelled — a middle label is noise next to a value
      // that is already printed above the chart.
      if (fraction == 0.5) continue;

      _paintText(
        canvas,
        metric.format(value),
        alignRightAt: geometry.plotLeft - AppSizes.padding8,
        centerOnY: y,
      );
    }
  }

  void _paintDates(Canvas canvas) {
    final points = geometry.points;
    final y = geometry.plotBottom + AppSizes.padding4;

    _paintText(
      canvas,
      formatDate(points.first.day),
      leftAt: geometry.plotLeft,
      topAt: y,
    );

    if (points.length > 1) {
      _paintText(
        canvas,
        formatDate(points.last.day),
        alignRightAt: geometry.plotRight,
        topAt: y,
      );
    }
  }

  void _paintFill(Canvas canvas, List<Offset> vertices) {
    final path = Path()..moveTo(vertices.first.dx, geometry.plotBottom);
    for (final vertex in vertices) {
      path.lineTo(vertex.dx, vertex.dy);
    }
    path
      ..lineTo(vertices.last.dx, geometry.plotBottom)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor, fillColor.withValues(alpha: 0)],
        ).createShader(
          Rect.fromLTRB(
            geometry.plotLeft,
            geometry.plotTop,
            geometry.plotRight,
            geometry.plotBottom,
          ),
        ),
    );
  }

  void _paintMarkers(Canvas canvas, List<Offset> vertices) {
    final selected = selectedIndex;
    final showAll = vertices.length <= _maxMarkers;

    for (var i = 0; i < vertices.length; i++) {
      final isSelected = i == selected;
      final isEnd = i == vertices.length - 1;
      if (!showAll && !isSelected && !isEnd) continue;

      final radius = isSelected ? 6.0 : 4.0;

      canvas
        // A ring in the surface colour keeps touching markers legible.
        ..drawCircle(
          vertices[i],
          radius + 1,
          Paint()..color = markerRingColor,
        )
        ..drawCircle(vertices[i], radius, Paint()..color = lineColor);
    }

    if (selected != null) {
      canvas.drawLine(
        Offset(vertices[selected].dx, geometry.plotTop),
        Offset(vertices[selected].dx, geometry.plotBottom),
        Paint()
          ..color = lineColor.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text, {
    double? leftAt,
    double? alignRightAt,
    double? topAt,
    double? centerOnY,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = leftAt ?? (alignRightAt! - painter.width);
    final dy = topAt ?? (centerOnY! - painter.height / 2);

    painter
      ..paint(canvas, Offset(dx, dy))
      ..dispose();
  }

  @override
  bool shouldRepaint(_ProgressChartPainter oldDelegate) {
    return oldDelegate.geometry.points != geometry.points ||
        oldDelegate.geometry.size != geometry.size ||
        oldDelegate.metric != metric ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
