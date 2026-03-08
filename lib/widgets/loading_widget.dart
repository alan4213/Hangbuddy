import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  
  const LoadingWidget({
    super.key,
    this.message,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 2,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double fontSize;
  
  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? AppTheme.primaryColor.withOpacity(0.8),
            backgroundColor?.withOpacity(0.6) ?? AppTheme.primaryColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? AppTheme.primaryColor).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}