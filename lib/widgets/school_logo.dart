import 'package:flutter/material.dart';

class SchoolLogo extends StatelessWidget {
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;

  const SchoolLogo({
    super.key,
    this.size = 80.0,
    this.showBorder = true,
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
                width: borderWidth ?? 3.0,
              )
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/school_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si la imagen no existe
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 40,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

