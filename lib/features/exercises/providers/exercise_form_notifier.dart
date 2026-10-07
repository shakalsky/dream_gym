import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/exercises/domain/exercise.dart';
import 'package:dream_gym/features/exercises/domain/photo_selection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

part 'exercise_form_state.dart';

/// Keyed by the exercise being edited, or null while adding one. Disposed with
/// the form, so the next one opens fresh.
final NotifierProviderFamily<
  ExerciseFormNotifier,
  ExerciseFormState,
  Exercise?
>
exerciseFormProvider = NotifierProvider.autoDispose.family(
  ExerciseFormNotifier.new,
);

/// Drives the add/edit exercise form.
///
/// The one rule worth knowing: a picked photo is not copied into the store
/// until [save] runs. Abandoning the form therefore leaves nothing behind, and
/// the old photo is only deleted once the new row is safely written.
class ExerciseFormNotifier extends Notifier<ExerciseFormState> {
  ExerciseFormNotifier(this._exercise);

  final Exercise? _exercise;
  late ExerciseRepository _exercises;
  late PhotoStore _photos;

  /// The photo the exercise had when the form opened — what has to be cleaned
  /// up if the reader replaces or removes it.
  String? get _storedPhotoFileName => _exercise?.photoFileName;

  @override
  ExerciseFormState build() {
    _exercises = ref.watch(exerciseRepositoryProvider);
    _photos = ref.watch(photoStoreProvider);

    final exercise = _exercise;
    final photoFileName = exercise?.photoFileName;

    return ExerciseFormState(
      exerciseId: exercise?.id,
      name: exercise?.name ?? '',
      photo: photoFileName == null
          ? const NoPhoto()
          : StoredPhoto(photoFileName),
    );
  }

  void nameChanged(String value) {
    state = state.copyWith(name: value, status: ExerciseFormStatus.editing);
  }

  /// Asks for a photo. Backing out of the picker leaves the form as it was.
  Future<void> pickPhoto(PhotoSource source) async {
    try {
      final path = await _photos.pick(source);
      if (!ref.mounted || path == null) return;

      state = state.copyWith(
        photo: PickedPhoto(path),
        status: ExerciseFormStatus.editing,
      );
    } on Exception catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ExerciseFormStatus.failure,
        error: 'Could not open ${source.label.toLowerCase()}: $error',
      );
    }
  }

  void removePhoto() {
    state = state.copyWith(
      photo: const NoPhoto(),
      status: ExerciseFormStatus.editing,
    );
  }

  /// Writes the exercise, then tidies up the photo it replaced.
  Future<void> save() async {
    // Taken once, up front: the writes below carry on even if the form is
    // closed mid-save, and a disposed notifier has no state left to read.
    final form = state;
    if (!form.canSave) return;

    state = form.copyWith(status: ExerciseFormStatus.saving);

    try {
      // Copied first: if this fails, no row claims a photo that is not there.
      final picked = form.photo;
      final storedFileName = picked is PickedPhoto
          ? await _photos.store(picked.path)
          : null;

      final exerciseId = form.exerciseId;
      if (exerciseId == null) {
        await _exercises.create(
          name: form.name,
          photoFileName: storedFileName,
        );
      } else {
        await _exercises.update(
          exerciseId,
          name: form.name,
          photoFileName: switch (form.photo) {
            PickedPhoto() => Value(storedFileName),
            NoPhoto() => const Value(null),
            // Untouched — left absent so the column is not rewritten.
            StoredPhoto() => const Value.absent(),
          },
        );
      }

      final replaced = _storedPhotoFileName;
      if (replaced != null && form.photo is! StoredPhoto) {
        await _photos.delete(replaced);
      }

      if (!ref.mounted) return;
      state = state.copyWith(status: ExerciseFormStatus.saved);
    } on Exception catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ExerciseFormStatus.failure,
        error: 'Could not save the exercise: $error',
      );
    }
  }
}
