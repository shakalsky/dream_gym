import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:dream_gym/features/training/providers/log_training_notifier.dart';
import 'package:flutter/services.dart';
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

  late final TextEditingController _weight = TextEditingController(
    text: ref.read(_form).weightText,
  );

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

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
          _WeightField(form: _form, controller: _weight),
          AppSizes.padding24.verticalSpace,
          _SaveButton(form: _form),
        ],
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
              onPressed: sets > 1
                  ? () => notifier.setsChanged(sets - 1)
                  : null,
            ),
            SizedBox(
              width: 72,
              child: Center(
                child: Text(
                  '$sets',
                  style: context.appFonts.headlineSmall,
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

class _WeightField extends ConsumerWidget {
  const _WeightField({required this.form, required this.controller});

  final _FormProvider form;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(form.notifier);
    final isSaving = ref.watch(form.select((state) => state.isSaving));

    return AppInput.gray(
      controller: controller,
      label: 'Weight per set',
      isImportant: true,
      placeholder: '60',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        // Digits and one separator, either kind — a gym floor is no place to
        // discover that your keyboard's comma is not accepted.
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      textInputAction: TextInputAction.done,
      enabled: !isSaving,
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: AppSizes.padding12),
        child: Center(
          child: Text(
            'kg',
            style: context.appFonts.bodyMedium?.copyWith(
              color: context.appThemeColors.gray500,
            ),
          ),
        ),
      ),
      onChanged: notifier.weightChanged,
      onFieldSubmitted: (_) => notifier.save(),
    );
  }
}

class _SaveButton extends ConsumerWidget {
  const _SaveButton({required this.form});

  final _FormProvider form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(form);
    final weightKg = state.weightKg;

    return SizedBox(
      width: double.infinity,
      child: AppPrimaryButton(
        text: weightKg == null
            ? 'Save'
            : 'Save ${formatSetsByWeight(state.sets, weightKg)}',
        buttonSize: PrimaryButtonSize.big,
        isLoading: state.isSaving,
        onPressed: state.canSave ? ref.read(form.notifier).save : null,
      ),
    );
  }
}
