import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/core/ui/wheel_picker.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:dream_gym/features/training/providers/log_training_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// The provider of this one form, handed down to the fields that make it up.
typedef _FormProvider = NotifierProvider<LogTrainingNotifier, LogTrainingState>;

/// 'I just did four sets of sixty' — the form the reader uses most.
///
/// A sheet rather than a screen: it opens over the exercise, keeps its numbers
/// in sight, and closes back to it.
class LogTrainingSheet extends ConsumerStatefulWidget {
  const LogTrainingSheet({
    required this.exerciseId,
    required this.exerciseName,
    this.lastSession,
    super.key,
  });

  /// Opens the sheet. Completes when it closes.
  static Future<void> show(
    BuildContext context, {
    required String exerciseId,
    required String exerciseName,
    TrainingSession? lastSession,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // The weight field is the point of the sheet, and it needs room above the
      // keyboard.
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.appThemeColors.backgroundWhite,
      builder: (context) => LogTrainingSheet(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        lastSession: lastSession,
      ),
    );
  }

  final String exerciseId;
  final String exerciseName;

  /// What was logged last time, used to pre-fill the form.
  final TrainingSession? lastSession;

  @override
  ConsumerState<LogTrainingSheet> createState() => _LogTrainingSheetState();
}

class _LogTrainingSheetState extends ConsumerState<LogTrainingSheet> {
  late final _FormProvider _form = logTrainingProvider((
    exerciseId: widget.exerciseId,
    lastSession: widget.lastSession,
  ));

  @override
  Widget build(BuildContext context) {
    ref.listen(_form, (previous, next) {
      if (previous?.status == next.status) return;

      if (next.status == LogTrainingStatus.saved) {
        Navigator.of(context).pop();
      } else if (next.status == LogTrainingStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error ?? 'Something went wrong')),
        );
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.defaultPadding,
        right: AppSizes.defaultPadding,
        bottom:
            MediaQuery.viewInsetsOf(context).bottom + AppSizes.defaultPadding,
      ),
      // Scrolls once a row per set no longer fits above the keyboard.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextHeading.small(
              text: 'Add result',
              subtitle: widget.exerciseName,
            ),
            AppSizes.padding20.verticalSpace,
            _DayPicker(form: _form),
            AppSizes.padding20.verticalSpace,
            _SetsStepper(form: _form),
            AppSizes.padding20.verticalSpace,
            _SetDetails(form: _form),
            AppSizes.padding24.verticalSpace,
            _SaveButton(form: _form),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.appFonts.labelMedium?.copyWith(
        color: context.appThemeColors.gray600,
      ),
    );
  }
}

/// Today, yesterday, or a date from the picker.
///
/// Those two cover almost every entry — results get written down in the gym or
/// on the same evening — so they are one tap, and everything else is two.
class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.form});

  final _FormProvider form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(form.notifier);
    final selected = ref.watch(form.select((state) => state.day));
    // The notifier's clock, so 'Today' is selected when the form opens on it.
    final today = dayOf(ref.watch(clockProvider)());
    final yesterday = today.subtract(const Duration(days: 1));
    final isOther = selected != today && selected != yesterday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Day'),
        AppSizes.padding8.verticalSpace,
        Row(
          spacing: AppSizes.padding8,
          children: [
            AppChip(
              title: 'Today',
              isSelected: selected == today,
              onPressed: () => notifier.dayChanged(today),
            ),
            AppChip(
              title: 'Yesterday',
              isSelected: selected == yesterday,
              onPressed: () => notifier.dayChanged(yesterday),
            ),
            AppChip(
              title: isOther ? formatDate(selected) : 'Other',
              isSelected: isOther,
              onPressed: () => _pickDate(
                context,
                notifier,
                today: today,
                selected: selected,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    LogTrainingNotifier notifier, {
    required DateTime today,
    required DateTime selected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      // A training can be written up late, but not booked in advance.
      firstDate: DateTime(today.year - 5),
      lastDate: today,
    );

    if (picked != null) notifier.dayChanged(picked);
  }
}

class _SetsStepper extends ConsumerWidget {
  const _SetsStepper({required this.form});

  final _FormProvider form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(form.notifier);
    final sets = ref.watch(form.select((state) => state.sets));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Sets'),
        AppSizes.padding8.verticalSpace,
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              semanticLabel: 'One set fewer',
              onPressed: sets > 1 ? () => notifier.setsChanged(sets - 1) : null,
            ),
            // The buttons are for one more or one fewer; the count itself
            // opens the wheel, for jumping straight to it.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.padding8,
              ),
              child: Semantics(
                button: true,
                label: '$sets sets. Choose the number of sets',
                excludeSemantics: true,
                child: Material(
                  color: context.appThemeColors.surface1,
                  borderRadius: BorderRadius.circular(
                    AppSizes.mediumButtonRadius,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      AppSizes.mediumButtonRadius,
                    ),
                    onTap: () => _pickSets(context, notifier, sets),
                    child: SizedBox(
                      width: 72,
                      height: 48,
                      child: Center(
                        child: Text(
                          '$sets',
                          style: context.appFonts.headlineSmall?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              semanticLabel: 'One set more',
              onPressed: sets < LogTrainingNotifier.maxSets
                  ? () => notifier.setsChanged(sets + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> _pickSets(
    BuildContext context,
    LogTrainingNotifier notifier,
    int sets,
  ) {
    return showWheelPickerSheet(
      context,
      title: 'Sets',
      picker: WheelPicker(
        suffix: 'sets',
        columns: [
          WheelColumn(
            itemCount: LogTrainingNotifier.maxSets,
            initialIndex: sets - 1,
            labelOf: (index) => '${index + 1}',
            onChanged: (index) => notifier.setsChanged(index + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final isEnabled = onPressed != null;

    return Material(
      color: colors.surface2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: semanticLabel,
          child: SizedBox(
            // Comfortably tappable with a thumb, between sets, one-handed.
            width: 48,
            height: 48,
            child: Icon(
              icon,
              size: AppSizes.iconsSize,
              color: isEnabled ? colors.gray900 : colors.gray300,
            ),
          ),
        ),
      ),
    );
  }
}

/// One reps-and-weight for every set, or — with the switch off — one per set,
/// for pyramids, drop sets and the last set that came up short.
class _SetDetails extends ConsumerWidget {
  const _SetDetails({required this.form});

  final _FormProvider form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(form.notifier);
    final same = ref.watch(form.select((state) => state.sameForEverySet));
    final sets = ref.watch(form.select((state) => state.sets));
    final isSaving = ref.watch(form.select((state) => state.isSaving));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Same reps and weight for every set',
                  style: context.appFonts.bodyMedium?.copyWith(
                    color: context.appThemeColors.gray800,
                  ),
                ),
              ),
              AppToggle(
                value: same,
                onChanged: isSaving
                    ? null
                    : (value) => notifier.sameForEverySetChanged(same: value),
              ),
            ],
          ),
        ),
        AppSizes.padding12.verticalSpace,
        if (same) ...[
          _WheelField.reps(
            label: 'Reps per set',
            pickerTitle: 'Reps per set',
            text: ref.watch(form.select((state) => state.repsText)),
            enabled: !isSaving,
            onChanged: notifier.repsChanged,
          ),
          AppSizes.padding20.verticalSpace,
          _WheelField.weight(
            label: 'Weight per set',
            pickerTitle: 'Weight per set',
            text: ref.watch(form.select((state) => state.weightText)),
            enabled: !isSaving,
            onChanged: notifier.weightChanged,
          ),
        ] else
          for (var i = 0; i < sets; i++) ...[
            if (i > 0) AppSizes.padding12.verticalSpace,
            _FieldLabel('Set ${i + 1}'),
            AppSizes.padding8.verticalSpace,
            Row(
              spacing: AppSizes.padding12,
              children: [
                Expanded(
                  child: _WheelField.reps(
                    pickerTitle: 'Set ${i + 1} reps',
                    text: ref.watch(
                      form.select((state) => state.setRepsTexts[i]),
                    ),
                    enabled: !isSaving,
                    onChanged: (value) => notifier.setRepsChanged(i, value),
                  ),
                ),
                Expanded(
                  child: _WheelField.weight(
                    pickerTitle: 'Set ${i + 1} weight',
                    text: ref.watch(
                      form.select((state) => state.setWeightTexts[i]),
                    ),
                    enabled: !isSaving,
                    onChanged: (value) => notifier.setWeightChanged(i, value),
                  ),
                ),
              ],
            ),
          ],
      ],
    );
  }
}

/// The unit, shown at the trailing edge inside a field.
class _UnitSuffix extends StatelessWidget {
  const _UnitSuffix(this.unit);

  final String unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding12),
      child: Center(
        widthFactor: 1,
        child: Text(
          unit,
          style: context.appFonts.bodyMedium?.copyWith(
            color: context.appThemeColors.gray500,
          ),
        ),
      ),
    );
  }
}

/// The columns of a field's wheel, and the value they open on.
typedef _Wheel = ({String initial, List<WheelColumn> columns});

/// A number picked on a wheel rather than typed: reps or a weight.
///
/// Looks like any other input, but is read-only: a tap opens the wheel, which
/// writes every step straight to the form.
class _WheelField extends StatefulWidget {
  /// Whole reps, 1 to 100, on one wheel.
  const _WheelField.reps({
    required this.pickerTitle,
    required this.text,
    required this.enabled,
    required this.onChanged,
    this.label,
  }) : unit = 'reps',
       placeholder = '10',
       wheelFor = _repsWheel;

  /// Kilograms on two wheels: whole kilograms from 0 to 500 plus a few
  /// assistance settings below zero, and a half or not — the same precision
  /// the app shows weights in everywhere else.
  const _WheelField.weight({
    required this.pickerTitle,
    required this.text,
    required this.enabled,
    required this.onChanged,
    this.label,
  }) : unit = 'kg',
       placeholder = '60',
       wheelFor = _weightWheel;

  static const _maxReps = 100;
  static const _defaultReps = 10;
  static const _maxKg = 500;

  /// Below zero is assistance, as on an assisted pull-up machine. Any
  /// negative weight is valid, but the wheel offers only these for now.
  static const _assistKg = [-22, -16, -11, -7];
  static const _defaultKg = 60.0;

  /// Every whole kilogram the wheel offers, top to bottom.
  static final List<int> _wholeKg = [
    ..._assistKg,
    for (var kg = 0; kg <= _maxKg; kg++) kg,
  ];

  final String pickerTitle;

  /// The form's current text for this value.
  final String text;
  final String? label;
  final bool enabled;
  final ValueChanged<String> onChanged;

  final String unit;

  /// Shown while empty; also where the wheel starts.
  final String placeholder;

  /// Builds the wheel for the form's [text], reporting each step's new text.
  final _Wheel Function(String text, ValueChanged<String> onChanged) wheelFor;

  static _Wheel _repsWheel(String text, ValueChanged<String> onChanged) {
    final reps = (LogTrainingState.parseReps(text) ?? _defaultReps).clamp(
      1,
      _maxReps,
    );

    return (
      initial: '$reps',
      columns: [
        WheelColumn(
          itemCount: _maxReps,
          initialIndex: reps - 1,
          labelOf: (index) => '${index + 1}',
          onChanged: (index) => onChanged('${index + 1}'),
        ),
      ],
    );
  }

  static _Wheel _weightWheel(String text, ValueChanged<String> onChanged) {
    final kg = LogTrainingState.parseWeight(text) ?? _defaultKg;
    int whole;
    bool half;
    if (kg < 0) {
      // Snapped to the closest assistance setting the wheel offers.
      whole = _assistKg.reduce(
        (a, b) => (a - kg).abs() <= (b - kg).abs() ? a : b,
      );
      half = false;
    } else {
      // Snapped to the nearest half, which is what the decimal wheel offers.
      final halves = (kg * 2).round().clamp(0, _maxKg * 2);
      whole = halves ~/ 2;
      half = halves.isOdd;
    }

    // Assistance settings are whole kilograms, so the half only counts at
    // zero and above.
    String current() => formatKilograms(whole + (half && whole >= 0 ? .5 : 0));

    return (
      initial: current(),
      columns: [
        WheelColumn(
          itemCount: _wholeKg.length,
          initialIndex: _wholeKg.indexOf(whole),
          labelOf: (index) =>
              _wholeKg[index] == 0 ? 'body weight' : '${_wholeKg[index]}',
          // Wide enough for 'body weight'.
          width: 150,
          alignment: Alignment.centerRight,
          onChanged: (index) {
            whole = _wholeKg[index];
            onChanged(current());
          },
        ),
        WheelColumn(
          itemCount: 2,
          initialIndex: half ? 1 : 0,
          labelOf: (index) => index == 0 ? '.0' : '.5',
          width: 56,
          alignment: Alignment.centerLeft,
          onChanged: (index) {
            half = index == 1;
            onChanged(current());
          },
        ),
      ],
    );
  }

  @override
  State<_WheelField> createState() => _WheelFieldState();
}

class _WheelFieldState extends State<_WheelField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(_WheelField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The form is the source of truth; the field only mirrors it.
    if (widget.text != _controller.text) _controller.text = widget.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final field = widget;
    final wheel = field.wheelFor(field.text, field.onChanged);

    // Opening the wheel is choosing a value, so the one it opens on counts
    // even if it is never turned.
    field.onChanged(wheel.initial);

    await showWheelPickerSheet(
      context,
      title: field.pickerTitle,
      picker: WheelPicker(suffix: field.unit, columns: wheel.columns),
    );

    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;

    return AppInput.gray(
      controller: _controller,
      label: label,
      isImportant: label != null,
      placeholder: widget.placeholder,
      readOnly: true,
      enabled: widget.enabled,
      showClearButton: false,
      suffixIcon: _UnitSuffix(widget.unit),
      onTap: widget.enabled ? _pick : null,
    );
  }
}

class _SaveButton extends ConsumerWidget {
  const _SaveButton({required this.form});

  final _FormProvider form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(form);

    return SizedBox(
      width: double.infinity,
      child: AppPrimaryButton(
        text: _label(state),
        buttonSize: PrimaryButtonSize.big,
        isLoading: state.isSaving,
        onPressed: state.canSave ? ref.read(form.notifier).save : null,
      ),
    );
  }

  /// What is about to be saved: 'Save 3 × 10 @ 60 kg', or 'Save 3 sets' when
  /// the sets differ.
  static String _label(LogTrainingState state) {
    final sets = state.setResults;
    if (sets == null) return 'Save';

    final first = sets.first;
    return sets.every((set) => set == first)
        ? 'Save ${formatSetsByWeight(sets.length, first.weightKg, reps: first.reps)}'
        : 'Save ${formatSets(sets.length)}';
  }
}
