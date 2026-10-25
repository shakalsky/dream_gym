/// The picture an exercise shows when it has no photo.
///
/// Stored by name, so reordering is safe. Renaming or removing a value is not:
/// rows that used it fall back to [dumbbell] when read.
enum ExerciseIcon {
  dumbbell('Weights'),
  gymnastics('Gymnastics'),
  running('Running'),
  walking('Walking'),
  cycling('Cycling'),
  swimming('Swimming'),
  rowing('Rowing'),
  boxing('Boxing'),
  martialArts('Martial arts'),
  stretching('Stretching'),
  mobility('Mobility'),
  cardio('Cardio')
  ;

  const ExerciseIcon(this.label);

  /// What the icon stands for, read out by screen readers.
  final String label;

  /// The icon an exercise gets until the reader picks another.
  static const ExerciseIcon fallback = ExerciseIcon.dumbbell;

  /// The icon stored under [name], or [fallback] for null or a name no
  /// longer in the enum.
  static ExerciseIcon fromName(String? name) =>
      ExerciseIcon.values.asNameMap()[name] ?? fallback;
}
