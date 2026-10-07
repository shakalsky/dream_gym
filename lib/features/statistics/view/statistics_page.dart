import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/core/ui/app_card.dart';
import 'package:dream_gym/core/ui/empty_state.dart';
import 'package:dream_gym/core/ui/stat_tile.dart';
import 'package:dream_gym/features/statistics/domain/training_summary.dart';
import 'package:dream_gym/features/statistics/providers/statistics_notifier.dart';
import 'package:dream_gym/features/statistics/widgets/progress_chart.dart';
import 'package:dream_gym/features/training/domain/exercise_log.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:dream_gym/features/training/view/exercise_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// Progress: this week at the top, then one exercise's history in detail.
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Progress', centerTitle: false),
      body: _body(state),
    );
  }

  Widget _body(StatisticsState state) {
    if (state.status == StatisticsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasData) {
      return EmptyState(
        icon: Icons.insights_outlined,
        title: 'Nothing to show yet',
        message: state.logs.isEmpty
            ? 'Add an exercise, then log a couple of sessions. Your '
                  'progress shows up here.'
            : 'Log a session against one of your exercises and its '
                  'progress shows up here.',
      );
    }

    final selected = state.selected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.defaultPadding,
        AppSizes.padding12,
        AppSizes.defaultPadding,
        AppSizes.padding32,
      ),
      children: [
        _WeekCard(summary: state.summary),
        AppSizes.padding24.verticalSpace,
        _ExercisePicker(
          logs: state.trained,
          selectedId: state.selectedExerciseId,
        ),
        if (selected != null) ...[
          AppSizes.defaultPadding.verticalSpace,
          _ProgressCard(log: selected, metric: state.metric),
          AppSizes.defaultPadding.verticalSpace,
          _Records(log: selected),
        ],
      ],
    );
  }
}

/// This week against last week.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.summary});

  final TrainingSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final change = summary.volumeChange;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: context.appFonts.titleMedium?.copyWith(
              color: colors.gray1000,
            ),
          ),
          AppSizes.defaultPadding.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StatTile(
                  value: '${summary.trainingDays}',
                  label: summary.trainingDays == 1
                      ? 'Day in the gym'
                      : 'Days in the gym',
                ),
              ),
              Expanded(
                child: StatTile(value: '${summary.sets}', label: 'Sets'),
              ),
              Expanded(
                child: StatTile(
                  value: formatWeight(summary.volumeKg),
                  label: 'Total lifted',
                  caption: change == null
                      ? null
                      : '${change >= 0 ? '+' : '−'}'
                            '${(change.abs() * 100).round()}% vs last week',
                  // Deliberately not red and green: less volume than last week
                  // is a deload as often as a failure, and the app is in no
                  // position to tell which.
                  captionColor: colors.gray500,
                ),
              ),
            ],
          ),
          if (summary.busiestExercise != null) ...[
            AppSizes.padding12.verticalSpace,
            Text(
              'Most sets: ${summary.busiestExercise}',
              style: context.appFonts.bodySmall?.copyWith(
                color: colors.gray500,
              ),
            ),
          ],
          if (!summary.hasTrained) ...[
            AppSizes.padding12.verticalSpace,
            Text(
              'No training logged this week yet.',
              style: context.appFonts.bodySmall?.copyWith(
                color: colors.gray500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Which exercise the chart is about.
class _ExercisePicker extends ConsumerWidget {
  const _ExercisePicker({required this.logs, required this.selectedId});

  final List<ExerciseLog> logs;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(statisticsProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: AppSizes.padding8,
        children: [
          for (final log in logs)
            AppChip(
              title: log.exercise.name,
              isSelected: log.exercise.id == selectedId,
              onPressed: () => notifier.exerciseSelected(log.exercise.id),
            ),
        ],
      ),
    );
  }
}

/// The chart, and the switch that decides what it plots.
class _ProgressCard extends ConsumerStatefulWidget {
  const _ProgressCard({required this.log, required this.metric});

  final ExerciseLog log;
  final ProgressMetric metric;

  @override
  ConsumerState<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends ConsumerState<_ProgressCard>
    with SingleTickerProviderStateMixin {
  late final TabController _metrics = TabController(
    length: ProgressMetric.values.length,
    initialIndex: ProgressMetric.values.indexOf(widget.metric),
    vsync: this,
  );

  @override
  void dispose() {
    _metrics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.log.exercise.name,
            style: context.appFonts.titleMedium?.copyWith(
              color: context.appThemeColors.gray1000,
            ),
          ),
          AppSizes.padding12.verticalSpace,
          AppSegmentBar.small(
            controller: _metrics,
            selectedIndex: ProgressMetric.values.indexOf(widget.metric),
            onSelect: (index) => ref
                .read(statisticsProvider.notifier)
                .metricSelected(ProgressMetric.values[index ?? 0]),
            tabs: [
              for (final metric in ProgressMetric.values) Tab(text: metric.label),
            ],
          ),
          AppSizes.defaultPadding.verticalSpace,
          ProgressChart(
            points: widget.log.progress.series(widget.metric),
            metric: widget.metric,
          ),
        ],
      ),
    );
  }
}

/// The exercise's records, and the way through to its full history.
class _Records extends StatelessWidget {
  const _Records({required this.log});

  final ExerciseLog log;

  @override
  Widget build(BuildContext context) {
    final progress = log.progress;
    final best = progress.personalBest;
    final today = DateTime.now();

    return AppCard(
      onTap: () => Navigator.of(
        context,
      ).push(ExerciseDetailPage.route(log.exercise.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StatTile(
                  value: best == null
                      ? '—'
                      : formatWeight(best.heaviestWeightKg),
                  label: 'Personal best',
                  caption: best == null
                      ? null
                      : formatDay(best.day, today: today),
                ),
              ),
              Expanded(
                child: StatTile(
                  value: '${progress.sessionCount}',
                  label: 'Sessions',
                  caption: '${progress.totalSets} sets',
                ),
              ),
              Expanded(
                child: StatTile(
                  value: formatWeight(progress.totalVolumeKg),
                  label: 'Lifted in total',
                ),
              ),
            ],
          ),
          AppSizes.padding12.verticalSpace,
          Row(
            children: [
              Text(
                'Open history',
                style: context.appFonts.labelMedium?.copyWith(
                  color: context.appThemeColors.primary500,
                ),
              ),
              AppSizes.padding4.horizontalSpace,
              Icon(
                Icons.chevron_right,
                size: AppSizes.iconsSize16,
                color: context.appThemeColors.primary500,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
