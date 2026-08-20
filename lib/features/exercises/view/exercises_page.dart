import 'package:dream_gym/core/ui/empty_state.dart';
import 'package:dream_gym/core/ui/icon_action.dart';
import 'package:dream_gym/features/exercises/cubit/exercises_cubit.dart';
import 'package:dream_gym/features/exercises/view/exercise_form_page.dart';
import 'package:dream_gym/features/exercises/widgets/exercise_tile.dart';
import 'package:dream_gym/features/training/view/exercise_detail_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// The exercises the reader trains — the app's front door.
class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExercisesCubit(
        exercises: context.read(),
        training: context.read(),
      ),
      child: const ExercisesView(),
    );
  }
}

@visibleForTesting
class ExercisesView extends StatelessWidget {
  const ExercisesView({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: BlocConsumer<ExercisesCubit, ExercisesState>(
        listenWhen: (previous, current) => current.error != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
          context.read<ExercisesCubit>().errorShown();
        },
        builder: (context, state) {
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

          // Read once per build rather than per tile, so every row on screen
          // agrees about what day it is.
          final today = DateTime.now();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.defaultPadding,
              AppSizes.padding12,
              AppSizes.defaultPadding,
              AppSizes.padding32,
            ),
            itemCount: state.logs.length,
            separatorBuilder: (context, index) =>
                AppSizes.padding8.verticalSpace,
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
        },
      ),
    );
  }

  Future<void> _addExercise(BuildContext context) =>
      Navigator.of(context).push<void>(ExerciseFormPage.route());
}
