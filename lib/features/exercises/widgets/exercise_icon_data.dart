import 'package:dream_gym/features/exercises/domain/exercise_icon.dart';
import 'package:flutter/material.dart';

/// The Material glyph for each [ExerciseIcon]. Kept out of the domain so it
/// stays free of Flutter.
extension ExerciseIconData on ExerciseIcon {
  IconData get data => switch (this) {
    ExerciseIcon.dumbbell => Icons.fitness_center,
    ExerciseIcon.gymnastics => Icons.sports_gymnastics,
    ExerciseIcon.running => Icons.directions_run,
    ExerciseIcon.walking => Icons.nordic_walking,
    ExerciseIcon.cycling => Icons.directions_bike,
    ExerciseIcon.swimming => Icons.pool,
    ExerciseIcon.rowing => Icons.rowing,
    ExerciseIcon.boxing => Icons.sports_mma,
    ExerciseIcon.martialArts => Icons.sports_martial_arts,
    ExerciseIcon.stretching => Icons.self_improvement,
    ExerciseIcon.mobility => Icons.accessibility_new,
    ExerciseIcon.cardio => Icons.monitor_heart_outlined,
  };
}
