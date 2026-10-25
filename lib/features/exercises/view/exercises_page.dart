import 'package:dream_gym/core/ui/empty_state.dart';
import 'package:dream_gym/core/ui/kettlebell_border.dart';
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

    // The app bar lives in the home shell. The empty state brings its own
    // add button, so the floating one waits until there is a list to sit on.
    final showFab = state.status != ExercisesStatus.loading && !state.isEmpty;

    return Scaffold(
      body: _body(context, state),
      floatingActionButton: showFab ? const _AddExerciseButton() : null,
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
          onPressed: () => addExercise(context),
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
        // Room under the last tile so the floating button never covers it.
        96,
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

  /// Opens the form for a new exercise.
  static Future<void> addExercise(BuildContext context) =>
      Navigator.of(context).push<void>(ExerciseFormPage.route());
}

class _AddExerciseButton extends StatelessWidget {
  const _AddExerciseButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;

    const size = Size(50, 50 * KettlebellBorder.aspectRatio);
    final foreground = Theme.of(context).colorScheme.onPrimary;

    // Shaped like a kettlebell, with the "+" on its body. The ripple and the
    // shadow follow the outline too.
    return SizedBox.fromSize(
      size: size,
      child: FloatingActionButton(
        tooltip: 'Add exercise',
        shape: const KettlebellBorder(),
        backgroundColor: colors.primary500,
        foregroundColor: foreground,
        elevation: 2,
        onPressed: () => ExercisesPage.addExercise(context),
        child: CustomPaint(
          size: size,
          painter: _PlusPainter(color: foreground),
        ),
      ),
    );
  }
}

/// A chunky, round-ended "+" on the kettlebell's body. Drawn rather than
/// taken from the icon font, whose "+" is too thin to read at this size.
class _PlusPainter extends CustomPainter {
  const _PlusPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = KettlebellBorder.bodyCenter(Offset.zero & size);
    final thickness = size.width * 0.12;
    final reach = (size.width * 0.34 - thickness) / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawLine(
        center - Offset(reach, 0),
        center + Offset(reach, 0),
        paint,
      )
      ..drawLine(
        center - Offset(0, reach),
        center + Offset(0, reach),
        paint,
      );
  }

  @override
  bool shouldRepaint(_PlusPainter oldDelegate) => oldDelegate.color != color;
}
