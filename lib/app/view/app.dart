import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/features/settings/providers/settings_notifier.dart';
import 'package:dream_gym/home/view/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// The app shell.
///
/// Takes the environment but not its storage: that comes from the
/// `ProviderScope` above it, so the widget tree stays testable — a test builds
/// an [AppEnv], overrides the database and photo store with throwaway ones,
/// and pumps this.
class App extends ConsumerWidget {
  const App({required this.env, super.key});

  final AppEnv env;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched here, above `MaterialApp`, because `themeMode` is one of the
    // things the settings decide. Only the theme rebuilds the app.
    final themeMode = ref.watch(
      settingsProvider.select((state) => state.settings.theme.mode),
    );

    return MaterialApp(
      title: env.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
    );
  }
}
