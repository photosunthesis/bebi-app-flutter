import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

enum MainScaffoldTab {
  home,
  calendar,
  stories,
  cycles,
  location;

  IconData get iconData => switch (this) {
    MainScaffoldTab.home => Symbols.home,
    MainScaffoldTab.calendar => Symbols.calendar_month,
    MainScaffoldTab.stories => Symbols.calendar_view_day,
    MainScaffoldTab.cycles => Symbols.menstrual_health,
    MainScaffoldTab.location => Symbols.location_pin,
  };
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  MainScaffoldTab activeTab = MainScaffoldTab.home;
  MainScaffoldTab? previousTab;
  DateTime? _lastTapTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedBranchContainer(
        currentIndex: widget.navigationShell.currentIndex,
        previousIndex: previousTab != null
            ? MainScaffoldTab.values.indexOf(previousTab!)
            : null,
        children: widget.children,
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outline,
            width: UiConstants.borderWidth,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: kIsWebiOS && kIsPwa ? 12 : 0),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: MainScaffoldTab.values.map((tab) {
              final isActive = tab == activeTab;
              final color = isActive
                  ? context.colorScheme.primary
                  : context.colorScheme.secondary.withAlpha(120);

              return Padding(
                padding: const EdgeInsets.all(4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _onTap(MainScaffoldTab.values.indexOf(tab)),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        tab.iconData,
                        color: color,
                        size: 28,
                        fill: isActive ? 1 : 0,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < 120.milliseconds) {
      return; // Ignore taps within debounce window
    }

    _lastTapTime = now;

    final tab = MainScaffoldTab.values[index];

    if (tab == activeTab) return; // Ignore if the same tab is tapped

    setState(() {
      previousTab = activeTab;
      activeTab = tab;
    });

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _AnimatedBranchContainer extends StatefulWidget {
  const _AnimatedBranchContainer({
    required this.currentIndex,
    this.previousIndex,
    required this.children,
  });

  final int currentIndex;
  final int? previousIndex;
  final List<Widget> children;

  @override
  State<_AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<_AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _animatingFromIndex;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: 120.milliseconds,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isAnimating) {
      _startAnimation(oldWidget.currentIndex);
    }
  }

  void _startAnimation(int fromIndex) {
    setState(() {
      _animatingFromIndex = fromIndex;
      _isAnimating = true;
    });

    _animationController.forward().then((_) {
      setState(() {
        _animatingFromIndex = null;
        _isAnimating = false;
      });
      _animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        var shouldShow = index == widget.currentIndex;

        if (_isAnimating && index == _animatingFromIndex) {
          shouldShow = true; // Keep previous tab visible during animation
        }

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            if (!_isAnimating) {
              return _branchNavigatorWrapper(
                index,
                Visibility(
                  visible: shouldShow,
                  maintainState: true,
                  child: entry.value,
                ),
              );
            }

            final isForward = widget.currentIndex > (_animatingFromIndex ?? 0);

            Animation<double> fadeAnimation;
            Animation<Offset> slideAnimation;

            if (index == widget.currentIndex) {
              fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeIn,
                ),
              );
              slideAnimation =
                  Tween<Offset>(
                    begin: Offset(isForward ? 0.1 : -0.1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeIn,
                    ),
                  );
            } else if (index == _animatingFromIndex) {
              fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOut,
                ),
              );
              slideAnimation =
                  Tween<Offset>(
                    begin: Offset.zero,
                    end: Offset(isForward ? -0.1 : 0.1, 0),
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    ),
                  );
            } else {
              return const SizedBox.shrink();
            }

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: _branchNavigatorWrapper(index, entry.value),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _branchNavigatorWrapper(int index, Widget navigator) {
    // Only the current tab (or animating target) should be interactive
    final isInteractive =
        index == widget.currentIndex ||
        (_isAnimating && index == widget.currentIndex);

    return IgnorePointer(
      ignoring: !isInteractive,
      child: TickerMode(enabled: isInteractive, child: navigator),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
