import 'dart:async';

import 'package:dream_gym/app/view/environment_page.dart';
import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/features/exercises/view/exercises_page.dart';
import 'package:dream_gym/features/settings/view/settings_page.dart';
import 'package:dream_gym/features/statistics/view/statistics_page.dart';
import 'package:flutter/services.dart';
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
    final colors = context.appThemeColors;
    final tabs = <_HomeTab>[
      const _HomeTab(
        label: 'Exercises',
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        page: ExercisesPage(),
      ),
      const _HomeTab(
        label: 'Progress',
        icon: Icons.insights_outlined,
        activeIcon: Icons.insights_rounded,
        page: StatisticsPage(),
      ),
      _HomeTab(
        label: 'Settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        page: SettingsPage(env: widget.env),
      ),
      // A development build keeps the environment readable on the device; a
      // release has no business showing it.
      //
      // The icon is a terminal rather than a cog: the cog belongs to
      // Settings, and two tabs sharing one icon is a bug report waiting to
      // happen.
      if (widget.env.flavor.isDevelopment)
        _HomeTab(
          label: 'Env',
          title: widget.env.appName,
          icon: Icons.terminal_outlined,
          activeIcon: Icons.terminal_rounded,
          page: EnvironmentPage(env: widget.env),
        ),
    ];
    final current = tabs[_index];

    return Scaffold(
      // One app bar for every tab: the pages supply only their body, so the
      // header cannot drift from tab to tab. It shares the page background,
      // so the screen reads as one flat surface down to the tab bar.
      appBar: AppBar(
        backgroundColor: colors.backgroundWhite,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          current.title ?? current.label,
          style: context.appFonts.titleLarge?.copyWith(
            color: colors.gray1000,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      // Each tab keeps its scroll position and its provider state while the
      // other is on screen — walking to Progress and back should not reload
      // the list.
      body: IndexedStack(
        index: _index,
        children: [for (final tab in tabs) tab.page],
      ),
      bottomNavigationBar: _BottomBar(
        tabs: tabs,
        index: _index,
        onSelected: (index) {
          if (index == _index) return;
          unawaited(HapticFeedback.selectionClick());
          setState(() => _index = index);
        },
      ),
    );
  }
}

class _HomeTab {
  const _HomeTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
    this.title,
  });

  final String label;

  /// Outlined, for when the tab is not selected.
  final IconData icon;

  /// Filled, for when it is.
  final IconData activeIcon;

  final Widget page;

  /// The app bar title; the tab's [label] when null.
  final String? title;
}

/// A flat, full-width bar with a hairline on top.
///
/// Built here rather than taken from Material: `NavigationBar` brings an
/// indicator pill and always-on labels, and this bar has neither.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.tabs,
    required this.index,
    required this.onSelected,
  });

  /// Tall enough for the icon, the label under it and some air.
  static const itemHeight = 60.0;

  final List<_HomeTab> tabs;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.backgroundWhite,
        border: Border(top: BorderSide(color: colors.gray100)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizes.padding8,
          AppSizes.padding8,
          AppSizes.padding8,
          AppSizes.padding8 + MediaQuery.paddingOf(context).bottom,
        ),
        // A fixed height: the selected tab grows a label and the old one loses
        // its own, and without this the bar would jump while they trade.
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
    );
  }
}

/// Icon only while idle; the selected tab fills its icon and shows its label.
class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 200);

  final _HomeTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final color = isSelected ? colors.primary500 : colors.gray500;

    // The label is hidden on idle tabs, so the semantics carry it instead.
    return Semantics(
      label: tab.label,
      selected: isSelected,
      button: true,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: _BottomBar.itemHeight,
          // The label's line is part of the fixed height, so a large system
          // text size is capped rather than allowed to overflow it.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: _duration,
                  child: Icon(
                    isSelected ? tab.activeIcon : tab.icon,
                    key: ValueKey(isSelected),
                    size: 26,
                    color: color,
                  ),
                ),
                AnimatedSize(
                  duration: _duration,
                  curve: Curves.easeOut,
                  child: isSelected
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.appFonts.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
