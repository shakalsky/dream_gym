import 'package:bloc/bloc.dart';
import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/exercises/domain/exercise.dart';
import 'package:dream_gym/features/exercises/domain/photo_selection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:equatable/equatable.dart';

part 'exercise_form_state.dart';

/// Drives the add/edit exercise form.
///
/// The one rule worth knowing: a picked photo is not copied into the store
/// until [save] runs. Abandoning the form therefore leaves nothing behind, and
/// the old photo is only deleted once the new row is safely written.
class ExerciseFormCubit extends Cubit<ExerciseFormState> {
  ExerciseFormCubit({
    required ExerciseRepository exercises,
    required PhotoStore photos,
    Exercise? exercise,
  }) : _exercises = exercises,
       _photos = photos,
       _storedPhotoFileName = exercise?.photoFileName,
       super(
         ExerciseFormState(
           exerciseId: exercise?.id,
           name: exercise?.name ?? '',
           photo: exercise?.photoFileName == null
               ? const NoPhoto()
               : StoredPhoto(exercise!.photoFileName!),
         ),
       );

  final ExerciseRepository _exercises;
  final PhotoStore _photos;

  /// The photo the exercise had when the form opened — what has to be cleaned
  /// up if the reader replaces or removes it.
  final String? _storedPhotoFileName;

  void nameChanged(String value) {
    emit(state.copyWith(name: value, status: ExerciseFormStatus.editing));
  }

  /// Asks for a photo. Backing out of the picker leaves the form as it was.
  Future<void> pickPhoto(PhotoSource source) async {
    try {
      final path = await _photos.pick(source);
      if (isClosed || path == null) return;

      emit(
        state.copyWith(
          photo: PickedPhoto(path),
          status: ExerciseFormStatus.editing,
        ),
      );
    } on Exception catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ExerciseFormStatus.failure,
          error: 'Could not open ${source.label.toLowerCase()}: $error',
        ),
      );
    }
  }

  void removePhoto() {
    emit(
      state.copyWith(
        photo: const NoPhoto(),
        status: ExerciseFormStatus.editing,
      ),
    );
  }

  /// Writes the exercise, then tidies up the photo it replaced.
  Future<void> save() async {
    if (!state.canSave) return;

    emit(state.copyWith(status: ExerciseFormStatus.saving));

    try {
      // Copied first: if this fails, no row claims a photo that is not there.
      final picked = state.photo;
      final storedFileName = picked is PickedPhoto
          ? await _photos.store(picked.path)
          : null;

      final exerciseId = state.exerciseId;
      if (exerciseId == null) {
        await _exercises.create(
          name: state.name,
          photoFileName: storedFileName,
        );
      } else {
        await _exercises.update(
          exerciseId,
          name: state.name,
          photoFileName: switch (state.photo) {
            PickedPhoto() => Value(storedFileName),
            NoPhoto() => const Value(null),
            // Untouched — left absent so the column is not rewritten.
            StoredPhoto() => const Value.absent(),
          },
        );
      }

      final replaced = _storedPhotoFileName;
      if (replaced != null && state.photo is! StoredPhoto) {
        await _photos.delete(replaced);
      }

      if (isClosed) return;
      emit(state.copyWith(status: ExerciseFormStatus.saved));
    } on Exception catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ExerciseFormStatus.failure,
          error: 'Could not save the exercise: $error',
        ),
      );
    }
  }
}
