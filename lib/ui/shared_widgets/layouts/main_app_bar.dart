import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

abstract class MainAppBar {
  // TODO Find better way to access themes instead of this :D
  static BuildContext get _context =>
      AppRouter.instance.routerDelegate.navigatorKey.currentState!.context;

  static AppBar build({
    Widget? leading,
    List<Widget> actions = const [],
    bool darkStatusBarIcons = true,
  }) {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: darkStatusBarIcons
            ? Brightness.dark
            : Brightness.light,
      ),
      leading:
          leading ??
          IconButton(
            icon: const Icon(Symbols.arrow_back),
            onPressed: _context.pop,
          ),
      actions: [
        ...actions,
        const SizedBox(width: UiConstants.padding),
      ],
      centerTitle: true,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: _context.colorScheme.onSecondary,
          height: UiConstants.borderWidth,
        ),
      ),
    );
  }
}
