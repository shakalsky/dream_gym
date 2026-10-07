import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/core/ui/app_card.dart';
import 'package:dream_gym/core/ui/stat_tile.dart';
import 'package:dream_gym/features/exercises/domain/exercise.dart';
import 'package:dream_gym/features/exercises/view/exercise_form_page.dart';
import 'package:dream_gym/features/exercises/widgets/exercise_photo.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:dream_gym/features/training/providers/exercise_detail_notifier.dart';
import 'package:dream_gym/features/training/view/log_training_sheet.dart';
import 'package:dream_gym/features/training/widgets/session_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// One exercise: what it looks like, how it has gone, and the button that adds
/// today's result.
class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({required this.exerciseId, super.key});

  static Route<void> route(String exerciseId) => MaterialPageRoute(
    builder: (context) => ExerciseDetailPage(exerciseId: exerciseId),
  );

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = exerciseDetailProvider(exerciseId);

    ref.listen(detail, (previous, next) {
      // Deleted — here, or from another screen while this one was open.
      if (next.status == ExerciseDetailStatus.gone) {
        Navigator.of(context).pop();
        return;
      }

      final error = next.error;
      if (error == null) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      ref.read(detail.notifier).errorShown();
    });

    final state = ref.watch(detail);
    final notifier = ref.read(detail.notifier);
    final exercise = state.exercise;

    if (exercise == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final progress = state.progress;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppAppBar(
        title: exercise.name,
        hasBackButton: true,
        action: _Menu(exercise: exercise),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.defaultPadding,
                  AppSizes.padding8,
                  AppSizes.defaultPadding,
                  AppSizes.padding24,
                ),
                children: [
                  if (exercise.photoFileName != null) ...[
                    ExercisePhoto(
                      photoFileName: exercise.photoFileName,
                      width: double.infinity,
                      height: 180,
                      borderRadius: AppSizes.borderRadius16,
                    ),
                    AppSizes.defaultPadding.verticalSpace,
                  ],
                  _Summary(progress: progress, today: today),
                  AppSizes.padding24.verticalSpace,
                  Text(
                    'History',
                    style: context.appFonts.titleMedium,
                  ),
                  AppSizes.padding12.verticalSpace,
                  if (progress.isEmpty)
                    _NoHistory()
                  else
                    // Newest first: the last training is the one being
                    // compared against.
                    for (final session in progress.sessions.reversed) ...[
                      SessionCard(
                        session: session,
                        today: today,
                        isPersonalBest: session == progress.personalBest,
                        onDeleteEntry: (id) => _confirmDeleteEntry(
                          context,
                          notifier,
                          entryId: id,
                        ),
                      ),
                      AppSizes.padding8.verticalSpace,
                    ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.defaultPadding,
                AppSizes.padding8,
                AppSizes.defaultPadding,
                AppSizes.defaultPadding,
              ),
              child: SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  text: 'Add result',
                  buttonSize: PrimaryButtonSize.big,
                  onPressed: () => LogTrainingSheet.show(
                    context,
                    exerciseId: exercise.id,
                    exerciseName: exercise.name,
                    lastSession: progress.latest,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteEntry(
    BuildContext context,
    ExerciseDetailNotifier notifier, {
    required String entryId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this result?'),
        content: const Text(
          'It will be removed from your history and your statistics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await notifier.deleteEntry(entryId);
  }
}

/// The numbers the reader is actually chasing.
class _Summary extends StatelessWidget {
  const _Summary({required this.progress, required this.today});

  final ExerciseProgress progress;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final best = progress.personalBest;
    final gain = progress.weightGainKg;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StatTile(
              value: best == null ? '—' : formatWeight(best.heaviestWeightKg),
              label: 'Personal best',
              caption: best == null
                  ? null
                  : formatDay(best.day, today: today),
            ),
          ),
          Expanded(
            child: StatTile(
              value: '${progress.sessionCount}',
              label: progress.sessionCount == 1 ? 'Session' : 'Sessions',
              caption: progress.isEmpty
                  ? null
                  : '${progress.totalSets} sets in total',
            ),
          ),
          Expanded(
            child: StatTile(
              value: gain == null
                  ? '—'
                  : '${gain >= 0 ? '+' : '−'}${formatWeight(gain.abs())}',
              label: 'Since the start',
              caption: gain == null ? 'Needs two sessions' : null,
              captionColor: context.appThemeColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Text(
        'Nothing logged yet. After your next set, tap “Add result” and put in '
        'the sets and the weight.',
        style: context.appFonts.bodyMedium?.copyWith(
          color: context.appThemeColors.gray500,
        ),
      ),
    );
  }
}

class _Menu extends ConsumerWidget {
  const _Menu({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(exerciseDetailProvider(exercise.id).notifier);

    return PopupMenuButton<_MenuAction>(
      tooltip: 'More',
      icon: Icon(Icons.more_vert, color: context.appThemeColors.gray900),
      iconSize: AppSizes.iconsSize,
      onSelected: (action) => switch (action) {
        _MenuAction.edit => Navigator.of(
          context,
        ).push<void>(ExerciseFormPage.route(exercise: exercise)),
        _MenuAction.delete => _confirmDelete(context, notifier),
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _MenuAction.edit, child: Text('Edit exercise')),
        PopupMenuItem(
          value: _MenuAction.delete,
          child: Text('Delete exercise'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ExerciseDetailNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${exercise.name}?'),
        content: const Text(
          'Its photo and everything you logged for it are deleted too. This '
          'cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await notifier.deleteExercise();
  }
}

enum _MenuAction { edit, delete }
