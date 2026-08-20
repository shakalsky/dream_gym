import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/home/view/home_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// The app shell.
///
/// Takes the environment and its repositories rather than reading or opening
/// them, so the widget tree stays testable: a test builds an [AppEnv] and a
/// pair of fakes and pumps this.
class App extends StatelessWidget {
  const App({
    required this.env,
    required this.exercises,
    required this.training,
    required this.photos,
    super.key,
  });

  final AppEnv env;
  final ExerciseRepository exercises;
  final TrainingRepository training;
  final PhotoStore photos;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: exercises),
        RepositoryProvider.value(value: training),
        RepositoryProvider.value(value: photos),
      ],
      child: MaterialApp(
        title: env.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        // A dev build in release mode has no checked-mode banner of its own, and
        // that is exactly the build most easily mistaken for production.
        builder: env.flavor.isDevelopment
            ? (context, child) => Banner(
                message: 'DEV',
                location: BannerLocation.topEnd,
                child: child ?? const SizedBox.shrink(),
              )
            : null,
        home: HomePage(env: env),
      ),
    );
  }
}
