import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InAppNotification {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String type = 'info',
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    print('=== InAppNotification.show called ===');
    print('Title: $title');
    print('Message: $message');
    print('Type: $type');
    
    // Try to find overlay in the widget tree
    OverlayState? overlay;
    
    // First try the provided context
    overlay = Overlay.maybeOf(context);
    
    // If not found, try the root navigator context
    if (overlay == null) {
      final navigatorContext = Navigator.maybeOf(context)?.context;
      if (navigatorContext != null) {
        overlay = Overlay.maybeOf(navigatorContext, rootOverlay: true);
      }
    }
    
    if (overlay == null) {
      print('No overlay found in any context - cannot show in-app notification');
      return;
    }
    
    print('Overlay found, creating notification');
    
    // Remove existing notification
    _currentOverlay?.remove();
    
    _currentOverlay = OverlayEntry(
      builder: (context) {
        print('Building notification overlay widget');
        return _NotificationWidget(
          title: title,
          message: message,
          type: type,
          onTap: onTap,
          onDismiss: () {
            print('Notification dismissed');
            _currentOverlay?.remove();
            _currentOverlay = null;
          },
        );
      },
    );

    print('Inserting overlay');
    overlay.insert(_currentOverlay!);
    print('Overlay inserted successfully');

    // Auto dismiss
    Future.delayed(duration, () {
      print('Auto-dismissing notification after ${duration.inSeconds}s');
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }

  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _NotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final String type;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.title,
    required this.message,
    required this.type,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onTap ?? _dismiss,
                  onPanUpdate: (details) {
                    if (details.delta.dy < -5) {
                      _dismiss();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getGradientColors(),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getIconColor().withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getIcon(),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.type) {
      case 'match':
        return Icons.favorite_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'interest':
        return Icons.people_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'error':
        return Icons.error_rounded;
      case 'warning':
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case 'match':
        return const Color(0xFFFF6B6B);
      case 'message':
        return const Color(0xFF4ECDC4);
      case 'interest':
        return AppTheme.primaryColor;
      case 'success':
        return const Color(0xFF4CAF50);
      case 'error':
        return const Color(0xFFF44336);
      case 'warning':
        return const Color(0xFFFF9800);
      default:
        return Colors.blue;
    }
  }

  List<Color> _getGradientColors() {
    final baseColor = _getIconColor();
    return [baseColor, baseColor.withOpacity(0.8)];
  }
}