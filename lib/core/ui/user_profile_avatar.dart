import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    super.key,
    this.imageUrl,
    this.imageProvider,
    this.displayName,
    this.radius = 20,
    this.backgroundColor,
    this.fontSize,
  });

  final String? imageUrl;
  final ImageProvider? imageProvider;
  final String? displayName;
  final double radius;
  final Color? backgroundColor;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final image =
        imageProvider ??
        (imageUrl != null && imageUrl!.parseUrl() != null
            ? CachedNetworkImageProvider(imageUrl!)
            : null);

    final bgColor = backgroundColor ?? context.colorScheme.onSurface;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colorScheme.outline,
          width: UiConstants.borderWidth,
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: image,
        child: image == null ? _buildFallbackContent(context, bgColor) : null,
      ),
    );
  }

  Widget _buildFallbackContent(BuildContext context, Color bgColor) {
    final name = displayName;

    if (name == null || name.isEmpty) {
      return Icon(
        Symbols.person,
        size: radius * 1.2,
        color: context.colorScheme.onInverseSurface.withAlpha(50),
      );
    }

    return Text(
      name.toInitials().toUpperCase(),
      style: context.primaryTextTheme.titleMedium?.copyWith(
        fontSize: fontSize ?? (radius * 0.8),
        color: context.colorScheme.onInverseSurface,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

extension on String {
  Uri? parseUrl() {
    return Uri.tryParse(this);
  }

  String toInitials() {
    if (isEmpty) return '';
    final parts = trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first;
    return '${parts.first.characters.first}${parts.last.characters.first}';
  }
}
