import 'package:dream_gym/app/view/environment_page.dart';
import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/features/exercises/view/exercises_page.dart';
import 'package:dream_gym/features/settings/view/settings_page.dart';
import 'package:dream_gym/features/statistics/view/statistics_page.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// The app shell: the exercises you train, and how they are going.
class HomePage extends StatefulWidget {
  const HomePage({required this.env, super.key});

  final AppEnv env;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <_HomeTab>[
      const _HomeTab(
        label: 'Exercises',
        icon: Icons.fitness_center,
        page: ExercisesPage(),
      ),
      const _HomeTab(
        label: 'Progress',
        icon: Icons.insights_outlined,
        page: StatisticsPage(),
      ),
      _HomeTab(
        label: 'Settings',
        icon: Icons.settings_outlined,
        page: SettingsPage(env: widget.env),
      ),
      // A development build keeps the environment readable on the device; a
      // release has no business showing it.
      //
      // The icon is a terminal rather than a cog: `settings_outlined` now
      // belongs to Settings, and two tabs sharing one icon is a bug report
      // waiting to happen.
      if (widget.env.flavor.isDevelopment)
        _HomeTab(
          label: 'Env',
          icon: Icons.terminal_outlined,
          page: EnvironmentPage(env: widget.env),
        ),
    ];

    return Scaffold(
      // Each tab keeps its scroll position and its cubit while the other is on
      // screen — walking to Progress and back should not reload the list.
      body: IndexedStack(
        index: _index,
        children: [for (final tab in tabs) tab.page],
      ),
      bottomNavigationBar: _BottomBar(
        tabs: tabs,
        index: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }
}

class _HomeTab {
  const _HomeTab({
    required this.label,
    required this.icon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final Widget page;
}

/// Built here rather than taken from Material: the design system has its own
/// surfaces and greys, and `NavigationBar` would arrive with neither.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.tabs,
    required this.index,
    required this.onSelected,
  });

  final List<_HomeTab> tabs;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.gray100)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.padding4),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _BottomBarItem(
                    tab: tabs[i],
                    isSelected: i == index,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _HomeTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final color = isSelected ? colors.primary500 : colors.gray400;

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.padding8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: AppSizes.iconsSize, color: color),
              AppSizes.padding4.verticalSpace,
              Text(
                tab.label,
                style: context.appFonts.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
