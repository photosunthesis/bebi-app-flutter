import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.9,
      child: CupertinoSwitch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: activeColor ?? context.colorScheme.primary,
      ),
    );
  }
}
