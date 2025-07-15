import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Items here must match the order in the BottomNavigationBar
// and the order of the StatefulShellBranches in AppRouter.
enum _Tabs { home, stories, calendar, location, account }

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
  _Tabs activeTab = _Tabs.home;
  _Tabs? previousTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedBranchContainer(
        currentIndex: widget.navigationShell.currentIndex,
        previousIndex: previousTab != null
            ? _Tabs.values.indexOf(previousTab!)
            : null,
        children: widget.children,
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final height = context.screenHeight * 0.12;
    return Container(
      height: height > 100 ? 100 : height,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTabIcon(_Tabs.home, Icons.space_dashboard_rounded),
            _buildTabIcon(_Tabs.stories, Icons.calendar_view_day_rounded),
            _buildTabIcon(_Tabs.calendar, Icons.calendar_month_rounded),
            _buildTabIcon(_Tabs.location, Icons.location_on_rounded),
            _buildTabIcon(_Tabs.account, Icons.person_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildTabIcon(_Tabs tab, IconData icon) {
    final isActive = tab == activeTab;
    final color = isActive
        ? context.colorScheme.primary
        : context.colorScheme.onSecondary.withAlpha(120);
    return Expanded(
      child: Center(
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => _onTap(_Tabs.values.indexOf(tab)),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    final tab = _Tabs.values[index];
    if (tab == activeTab) return;
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
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  int? _animatingFromIndex;
  int? _animatingToIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: 200.milliseconds, vsync: this);
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart),
        );
  }

  @override
  void didUpdateWidget(_AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentIndex != widget.currentIndex) {
      _startAnimation(oldWidget.currentIndex, widget.currentIndex);
    }
  }

  void _startAnimation(int from, int to) {
    setState(() {
      _animatingFromIndex = from;
      _animatingToIndex = to;
    });

    final isForward = to > from;
    _slideAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: Offset(isForward ? -1.0 : 1.0, 0),
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart),
        );

    _controller.forward().then((_) {
      setState(() {
        _animatingFromIndex = null;
        _animatingToIndex = null;
      });
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stackChildren = <Widget>[];

    // Show the current tab (or animating target)
    final currentTabIndex = _animatingToIndex ?? widget.currentIndex;
    stackChildren.add(
      SlideTransition(
        position: _animatingToIndex != null
            ? Tween<Offset>(
                begin: Offset(
                  widget.currentIndex > (_animatingFromIndex ?? 0) ? 1.0 : -1.0,
                  0,
                ),
                end: Offset.zero,
              ).animate(_controller)
            : const AlwaysStoppedAnimation(Offset.zero),
        child: _branchNavigatorWrapper(
          currentTabIndex,
          widget.children[currentTabIndex],
        ),
      ),
    );

    // Show the previous tab during animation
    if (_animatingFromIndex != null) {
      stackChildren.insert(
        0, // Put behind the incoming tab
        SlideTransition(
          position: _slideAnimation,
          child: _branchNavigatorWrapper(
            _animatingFromIndex!,
            widget.children[_animatingFromIndex!],
          ),
        ),
      );
    }

    return Stack(children: stackChildren);
  }

  Widget _branchNavigatorWrapper(int index, Widget navigator) => IgnorePointer(
    ignoring: index != widget.currentIndex && _animatingToIndex != index,
    child: TickerMode(
      enabled: index == widget.currentIndex || _animatingToIndex == index,
      child: navigator,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
