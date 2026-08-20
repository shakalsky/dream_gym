import 'dart:io';

import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/features/exercises/cubit/exercise_form_cubit.dart';
import 'package:dream_gym/features/exercises/domain/exercise.dart';
import 'package:dream_gym/features/exercises/domain/photo_selection.dart';
import 'package:dream_gym/features/exercises/widgets/exercise_photo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// Adds a new exercise, or edits one that exists.
class ExerciseFormPage extends StatelessWidget {
  const ExerciseFormPage({this.exercise, super.key});

  /// [exercise] null means 'add', otherwise the form opens on that exercise.
  static Route<void> route({Exercise? exercise}) => MaterialPageRoute(
    builder: (context) => ExerciseFormPage(exercise: exercise),
  );

  final Exercise? exercise;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExerciseFormCubit(
        exercises: context.read(),
        photos: context.read(),
        exercise: exercise,
      ),
      child: const ExerciseFormView(),
    );
  }
}

@visibleForTesting
class ExerciseFormView extends StatefulWidget {
  const ExerciseFormView({super.key});

  @override
  State<ExerciseFormView> createState() => _ExerciseFormViewState();
}

class _ExerciseFormViewState extends State<ExerciseFormView> {
  late final TextEditingController _name = TextEditingController(
    text: context.read<ExerciseFormCubit>().state.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = context.read<ExerciseFormCubit>().state.isEditing;

    return BlocListener<ExerciseFormCubit, ExerciseFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ExerciseFormStatus.saved) {
          Navigator.of(context).pop();
        } else if (state.status == ExerciseFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'Something went wrong')),
          );
        }
      },
      child: Scaffold(
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
                    const _PhotoField(),
                    AppSizes.padding24.verticalSpace,
                    _NameField(controller: _name),
                  ],
                ),
              ),
              const _SaveButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  /// Owned by the form's state, so the field keeps its text and cursor across
  /// the rebuilds every keystroke causes.
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExerciseFormCubit>().state;

    return AppInput.gray(
      controller: controller,
      label: 'Name',
      isImportant: true,
      placeholder: 'Bench press',
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      enabled: !state.isSaving,
      onChanged: context.read<ExerciseFormCubit>().nameChanged,
      onFieldSubmitted: (_) => context.read<ExerciseFormCubit>().save(),
    );
  }
}

/// The photo, and the only way to change it.
class _PhotoField extends StatelessWidget {
  const _PhotoField();

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final state = context.watch<ExerciseFormCubit>().state;
    final hasPhoto = state.photo is! NoPhoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _choose(context, hasPhoto: hasPhoto),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: switch (state.photo) {
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
                onPressed: () => _choose(context, hasPhoto: hasPhoto),
              ),
              AppLiteButton.small(
                text: 'Remove',
                onPressed: context.read<ExerciseFormCubit>().removePhoto,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _choose(BuildContext context, {required bool hasPhoto}) async {
    final cubit = context.read<ExerciseFormCubit>();
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

    if (source != null) await cubit.pickPhoto(source);
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExerciseFormCubit>().state;

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
          onPressed: state.canSave
              ? context.read<ExerciseFormCubit>().save
              : null,
        ),
      ),
    );
  }
}
