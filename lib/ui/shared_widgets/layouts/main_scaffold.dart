import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

// Items here must match the order in the BottomNavigationBar
// and the order of the StatefulShellBranches in AppRouter.
enum _Tabs { home, calendar, stories, location, account }

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
  DateTime? _lastTapTime;

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
    final height = context.screenHeight * 0.11;
    return Container(
      height: height > 110 ? 110 : height,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withAlpha(14),
            blurRadius: 8,
            offset: const Offset(0, -1.5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTabIcon(_Tabs.home, Symbols.home),
            _buildTabIcon(_Tabs.calendar, Symbols.calendar_month),
            _buildTabIcon(_Tabs.stories, Symbols.calendar_view_day),
            _buildTabIcon(_Tabs.location, Symbols.location_pin),
            _buildTabIcon(_Tabs.account, Symbols.account_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildTabIcon(_Tabs tab, IconData icon) {
    final isActive = tab == activeTab;
    final color = isActive
        ? context.colorScheme.primary
        : context.colorScheme.secondary.withAlpha(120);
    return Flexible(
      child: Center(
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => _onTap(_Tabs.values.indexOf(tab)),
            customBorder: const CircleBorder(),
            splashColor: context.colorScheme.primary.withAlpha(20),
            highlightColor: context.colorScheme.primary.withAlpha(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < 160.milliseconds) {
      return; // Ignore taps within debounce window
    }

    _lastTapTime = now;

    final tab = _Tabs.values[index];

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
      duration: 150.milliseconds,
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
        final child = entry.value;
        var shouldShow = index == widget.currentIndex;

        if (_isAnimating && index == _animatingFromIndex) {
          shouldShow = true; // Keep previous tab visible during animation
        }

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            // Calculate slide offset for animation inside AnimatedBuilder
            var slideOffset = Offset.zero;

            if (_isAnimating) {
              final isForward =
                  widget.currentIndex > (_animatingFromIndex ?? 0);
              final animationValue = Curves.easeInOutQuad.transform(
                _animationController.value,
              );

              if (index == _animatingFromIndex) {
                // Outgoing tab - slide out
                slideOffset = Offset(
                  (isForward ? -1.0 : 1.0) * animationValue,
                  0,
                );
              } else if (index == widget.currentIndex) {
                // Incoming tab - slide in
                slideOffset = Offset(
                  (isForward ? 1.0 : -1.0) * (1.0 - animationValue),
                  0,
                );
              }
            }

            return Transform.translate(
              offset: Offset(
                slideOffset.dx * context.screenWidth,
                slideOffset.dy * context.screenHeight,
              ),
              child: Visibility(
                visible: shouldShow,
                maintainState: true, // Keep widget state alive
                child: _branchNavigatorWrapper(index, child),
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
