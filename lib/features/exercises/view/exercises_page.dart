import 'package:dream_gym/core/ui/empty_state.dart';
import 'package:dream_gym/core/ui/icon_action.dart';
import 'package:dream_gym/features/exercises/providers/exercises_notifier.dart';
import 'package:dream_gym/features/exercises/view/exercise_form_page.dart';
import 'package:dream_gym/features/exercises/widgets/exercise_tile.dart';
import 'package:dream_gym/features/training/view/exercise_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// The exercises the reader trains — the app's front door.
class ExercisesPage extends ConsumerWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(exercisesProvider, (previous, next) {
      final error = next.error;
      if (error == null) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      ref.read(exercisesProvider.notifier).errorShown();
    });

    final state = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Exercises',
        centerTitle: false,
        action: IconAction(
          icon: Icons.add,
          tooltip: 'Add exercise',
          onPressed: () => _addExercise(context),
        ),
      ),
      body: _body(context, state),
    );
  }

  Widget _body(BuildContext context, ExercisesState state) {
    if (state.status == ExercisesStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isEmpty) {
      return EmptyState(
        icon: Icons.fitness_center,
        title: 'No exercises yet',
        message:
            'Add the movements you train. Then write down your sets '
            'after each session and watch them add up.',
        action: AppPrimaryButton(
          text: 'Add exercise',
          buttonSize: PrimaryButtonSize.big,
          onPressed: () => _addExercise(context),
        ),
      );
    }

    // Read once per build rather than per tile, so every row on screen agrees
    // about what day it is.
    final today = DateTime.now();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.defaultPadding,
        AppSizes.padding12,
        AppSizes.defaultPadding,
        AppSizes.padding32,
      ),
      itemCount: state.logs.length,
      separatorBuilder: (context, index) => AppSizes.padding8.verticalSpace,
      itemBuilder: (context, index) {
        final log = state.logs[index];

        return ExerciseTile(
          log: log,
          today: today,
          onTap: () => Navigator.of(
            context,
          ).push(ExerciseDetailPage.route(log.exercise.id)),
        );
      },
    );
  }

  Future<void> _addExercise(BuildContext context) =>
      Navigator.of(context).push<void>(ExerciseFormPage.route());
}
