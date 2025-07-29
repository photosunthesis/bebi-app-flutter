import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/cupertino.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.9,
      child: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: context.colorScheme.primary,
      ),
    );
  }
}
