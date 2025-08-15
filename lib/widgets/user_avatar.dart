import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserAvatar extends StatelessWidget {
  final String avatarAsset;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;

  const UserAvatar({
    super.key,
    required this.avatarAsset,
    this.size = 32.0,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? const Color(0xFF00BCD4),
                width: borderWidth ?? 2.0,
              )
            : null,
      ),
      child: ClipOval(
        child: SvgPicture.asset(
          avatarAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback si el avatar no existe
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF00BCD4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: size * 0.6,
              ),
            );
          },
        ),
      ),
    );
  }
}

