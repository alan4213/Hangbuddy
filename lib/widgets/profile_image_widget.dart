import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.size = 120,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 3,
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
                color: borderColor ?? AppTheme.primaryColor,
                width: borderWidth,
              )
            : null,
      ),
      child: CircleAvatar(
        radius: size / 2 - (showBorder ? borderWidth : 0),
        backgroundColor: Colors.grey[300],
        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
            ? NetworkImage(imageUrl!)
            : null,
        child: imageUrl == null || imageUrl!.isEmpty
            ? Icon(
                Icons.person,
                size: size * 0.5,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}