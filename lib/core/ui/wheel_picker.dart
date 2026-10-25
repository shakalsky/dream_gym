import 'dart:async';

import 'package:flutter/services.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// One spinning column of a [WheelPicker].
class WheelColumn {
  const WheelColumn({
    required this.itemCount,
    required this.initialIndex,
    required this.labelOf,
    required this.onChanged,
    this.width = 88,
    this.alignment = Alignment.center,
  });

  final int itemCount;
  final int initialIndex;
  final String Function(int index) labelOf;
  final ValueChanged<int> onChanged;
  final double width;

  /// Where labels sit inside the column: two columns that read as one number
  /// ('62' '.5') align toward each other.
  final Alignment alignment;
}

/// A scroll-wheel number picker in the app's own style.
///
/// The selected row sits in an accent-tinted band and is drawn in the accent
/// color; the rows around it shrink and fade out toward the edges. Each step
/// gives a haptic tick, and tapping a row scrolls to it.
class WheelPicker extends StatelessWidget {
  const WheelPicker({
    required this.columns,
    this.suffix,
    this.height = 220,
    super.key,
  });

  static const itemExtent = 48.0;

  final List<WheelColumn> columns;

  /// A unit shown to the right of the columns, inside the band.
  final String? suffix;

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final suffix = this.suffix;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: itemExtent,
            decoration: BoxDecoration(
              color: colors.primary100,
              borderRadius: BorderRadius.circular(AppSizes.mediumButtonRadius),
              border: Border.all(color: colors.primary200),
            ),
          ),
          // Rows fade into the sheet at the top and bottom edges.
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x00000000),
                Color(0xFF000000),
                Color(0xFF000000),
                Color(0x00000000),
              ],
              stops: [0, 0.3, 0.7, 1],
            ).createShader(bounds),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final column in columns)
                  SizedBox(
                    width: column.width,
                    child: _WheelColumnView(column: column),
                  ),
              ],
            ),
          ),
          if (suffix != null)
            Positioned(
              right: AppSizes.padding20,
              child: IgnorePointer(
                child: Text(
                  suffix,
                  style: context.appFonts.bodyLarge?.copyWith(
                    color: colors.primary500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WheelColumnView extends StatefulWidget {
  const _WheelColumnView({required this.column});

  final WheelColumn column;

  @override
  State<_WheelColumnView> createState() => _WheelColumnViewState();
}

class _WheelColumnViewState extends State<_WheelColumnView> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.column.initialIndex);
  late int _selected = widget.column.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelected(int index) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _selected = index);
    widget.column.onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final column = widget.column;
    final base = context.appFonts.headlineSmall ?? const TextStyle();

    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: WheelPicker.itemExtent,
      physics: const FixedExtentScrollPhysics(),
      // Flatter than a full drum: a gentle curve, no magnifier.
      diameterRatio: 2.4,
      perspective: 0.002,
      squeeze: 1.05,
      onSelectedItemChanged: _onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: column.itemCount,
        builder: (context, index) {
          final isSelected = index == _selected;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(
              _controller.animateToItem(
                index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
            ),
            child: Align(
              alignment: column.alignment,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: base.copyWith(
                  fontSize: isSelected ? 26 : 22,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.primary500 : colors.gray500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                // Shrinks a label too long for its column instead of
                // clipping it.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(column.labelOf(index)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Opens [picker] in a bottom sheet under [title], with a Done button.
///
/// The picker reports every step as it happens, so there is nothing to
/// confirm: Done, a tap outside and a swipe down all simply close it.
Future<void> showWheelPickerSheet(
  BuildContext context, {
  required String title,
  required WheelPicker picker,
}) {
  return showModalBottomSheet<void>(
    context: context,
    // Sized to its content: the default cap of half the screen clips the
    // wheel on small phones.
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.appThemeColors.backgroundWhite,
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.defaultPadding,
          0,
          AppSizes.defaultPadding,
          AppSizes.defaultPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: context.appFonts.titleMedium?.copyWith(
                color: context.appThemeColors.gray1000,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSizes.padding12.verticalSpace,
            picker,
            AppSizes.padding20.verticalSpace,
            SizedBox(
              width: double.infinity,
              child: AppPrimaryButton(
                text: 'Done',
                buttonSize: PrimaryButtonSize.big,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
