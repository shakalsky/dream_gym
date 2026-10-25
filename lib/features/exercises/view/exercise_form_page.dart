import 'dart:io';

import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/features/exercises/domain/exercise.dart';
import 'package:dream_gym/features/exercises/domain/exercise_icon.dart';
import 'package:dream_gym/features/exercises/domain/photo_selection.dart';
import 'package:dream_gym/features/exercises/providers/exercise_form_notifier.dart';
import 'package:dream_gym/features/exercises/widgets/exercise_icon_data.dart';
import 'package:dream_gym/features/exercises/widgets/exercise_photo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// The provider of this one form, handed down to the fields that make it up.
typedef _FormProvider =
    NotifierProvider<ExerciseFormNotifier, ExerciseFormState>;

/// Adds a new exercise, or edits one that exists.
class ExerciseFormPage extends ConsumerStatefulWidget {
  const ExerciseFormPage({this.exercise, super.key});

  /// [exercise] null means 'add', otherwise the form opens on that exercise.
  static Route<void> route({Exercise? exercise}) => MaterialPageRoute(
    builder: (context) => ExerciseFormPage(exercise: exercise),
  );

  final Exercise? exercise;

  @override
  ConsumerState<ExerciseFormPage> createState() => _ExerciseFormPageState();
}

class _ExerciseFormPageState extends ConsumerState<ExerciseFormPage> {
  late final _FormProvider _form = exerciseFormProvider(widget.exercise);

  late final TextEditingController _name = TextEditingController(
    text: ref.read(_form).name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(_form, (previous, next) {
      if (previous?.status == next.status) return;

      if (next.status == ExerciseFormStatus.saved) {
        Navigator.of(context).pop();
      } else if (next.status == ExerciseFormStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error ?? 'Something went wrong')),
        );
      }
    });

    final isEditing = ref.read(_form).isEditing;

    return Scaffold(
      appBar: AppAppBar(
        title: isEditing ? 'Edit exercise' : 'New exercise',
        hasBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.defaultPadding),
                children: [
                  _PhotoField(form: _form),
                  AppSizes.padding24.verticalSpace,
                  _NameField(form: _form, controller: _name),
                  AppSizes.padding24.verticalSpace,
                  _IconField(form: _form),
                ],
              ),
            ),
            _SaveButton(form: _form),
          ],
        ),
      ),
    );
  }
}

class _NameField extends ConsumerWidget {
  const _NameField({required this.form, required this.controller});

  final _FormProvider form;

  /// Owned by the form's state, so the field keeps its text and cursor across
  /// the rebuilds every keystroke causes.
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(form.select((state) => state.isSaving));
    final notifier = ref.read(form.notifier);

    return AppInput.gray(
      controller: controller,
      label: 'Name',
      isImportant: true,
      placeholder: 'Bench press',
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      enabled: !isSaving,
      onChanged: notifier.nameChanged,
      onFieldSubmitted: (_) => notifier.save(),
    );
  }
}

/// A grid of every [ExerciseIcon], with the chosen one highlighted.
class _IconField extends ConsumerWidget {
  const _IconField({required this.form});

  final _FormProvider form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appThemeColors;
    final selected = ref.watch(form.select((state) => state.icon));
    final isSaving = ref.watch(form.select((state) => state.isSaving));
    final notifier = ref.read(form.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InputLabel(text: 'Icon'),
        Text(
          'Shown when the exercise has no photo',
          style: context.appFonts.bodySmall?.copyWith(color: colors.gray500),
        ),
        AppSizes.padding12.verticalSpace,
        Wrap(
          spacing: AppSizes.padding8,
          runSpacing: AppSizes.padding8,
          children: [
            for (final icon in ExerciseIcon.values)
              _IconOption(
                icon: icon,
                isSelected: icon == selected,
                onTap: isSaving ? null : () => notifier.iconChanged(icon),
              ),
          ],
        ),
      ],
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final ExerciseIcon icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final radius = BorderRadius.circular(AppSizes.mediumButtonRadius);

    return Semantics(
      button: true,
      selected: isSelected,
      label: icon.label,
      excludeSemantics: true,
      child: Material(
        color: isSelected ? colors.primary100 : colors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isSelected ? colors.primary500 : colors.gray100,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox.square(
            dimension: 52,
            child: Icon(
              icon.data,
              size: AppSizes.iconsSize28,
              color: isSelected ? colors.primary500 : colors.gray600,
            ),
          ),
        ),
      ),
    );
  }
}

/// The photo, and the only way to change it.
class _PhotoField extends ConsumerWidget {
  const _PhotoField({required this.form});

  final _FormProvider form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appThemeColors;
    final photo = ref.watch(form.select((state) => state.photo));
    final notifier = ref.read(form.notifier);
    final hasPhoto = photo is! NoPhoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _choose(context, notifier),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: switch (photo) {
              NoPhoto() => DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface1,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius16),
                  border: Border.all(color: colors.gray100),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: AppSizes.iconsSize28,
                        color: colors.gray400,
                      ),
                      AppSizes.padding8.verticalSpace,
                      Text(
                        'Add a photo',
                        style: context.appFonts.bodySmall?.copyWith(
                          color: colors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              StoredPhoto(:final fileName) => ExercisePhoto(
                photoFileName: fileName,
                width: double.infinity,
                height: 200,
                borderRadius: AppSizes.borderRadius16,
              ),
              PickedPhoto(:final path) => ExercisePhoto.file(
                File(path),
                width: double.infinity,
                height: 200,
                borderRadius: AppSizes.borderRadius16,
              ),
            },
          ),
        ),
        if (hasPhoto) ...[
          AppSizes.padding4.verticalSpace,
          Row(
            children: [
              AppLiteButton.small(
                text: 'Replace',
                onPressed: () => _choose(context, notifier),
              ),
              AppLiteButton.small(
                text: 'Remove',
                onPressed: notifier.removePhoto,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _choose(
    BuildContext context,
    ExerciseFormNotifier notifier,
  ) async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final source in PhotoSource.values)
              ListTile(
                leading: Icon(
                  source == PhotoSource.camera
                      ? Icons.photo_camera_outlined
                      : Icons.photo_library_outlined,
                  color: context.appThemeColors.gray800,
                ),
                title: Text(
                  source.label,
                  style: context.appFonts.bodyLarge,
                ),
                onTap: () => Navigator.of(context).pop(source),
              ),
            AppSizes.padding8.verticalSpace,
          ],
        ),
      ),
    );

    if (source != null) await notifier.pickPhoto(source);
  }
}

class _SaveButton extends ConsumerWidget {
  const _SaveButton({required this.form});

  final _FormProvider form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(form);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.defaultPadding,
        AppSizes.padding8,
        AppSizes.defaultPadding,
        AppSizes.defaultPadding,
      ),
      child: SizedBox(
        width: double.infinity,
        child: AppPrimaryButton(
          text: state.isEditing ? 'Save changes' : 'Add exercise',
          buttonSize: PrimaryButtonSize.big,
          isLoading: state.isSaving,
          onPressed: state.canSave ? ref.read(form.notifier).save : null,
        ),
      ),
    );
  }
}
