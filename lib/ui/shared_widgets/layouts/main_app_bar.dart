import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class MainAppBar {
  static AppBar build(
    BuildContext context, {
    Widget? leading,
    List<Widget> actions = const [],
    bool darkStatusBarIcons = true,
    bool autoImplementLeading = true,
    Widget? flexibleSpace,
    double? toolbarHeight,
  }) {
    return AppBar(
      automaticallyImplyLeading: autoImplementLeading,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: darkStatusBarIcons
            ? Brightness.dark
            : Brightness.light,
      ),
      leading: leading,
      actions: [...actions, const SizedBox(width: 8)],
      centerTitle: true,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: context.colorScheme.outline,
          height: UiConstants.borderWidth,
        ),
      ),
      flexibleSpace: flexibleSpace,
      toolbarHeight: toolbarHeight,
    );
  }
}
