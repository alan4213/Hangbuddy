import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../theme/app_theme.dart';

class ErrorHandler {
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable') ||
           errorString.contains('failed host lookup') ||
           errorString.contains('no internet') ||
           error is FirebaseException && error.code == 'unavailable';
  }

  static String getErrorMessage(dynamic error) {
    if (isNetworkError(error)) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Access denied. Please check your permissions.';
        case 'not-found':
          return 'Requested data not found.';
        case 'already-exists':
          return 'This item already exists.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    
    // Check if it's a user-friendly exception message
    final errorMessage = error.toString();
    if (errorMessage.startsWith('Exception: ')) {
      final message = errorMessage.substring(11); // Remove 'Exception: ' prefix
      // Return the actual message if it looks user-friendly
      if (message.contains('already have an active hangout') ||
          message.contains('Please delete it first') ||
          message.contains('hangout') ||
          message.contains('location') ||
          message.contains('permission')) {
        return message;
      }
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  static void showErrorSnackBar(
    BuildContext context, 
    dynamic error, {
    VoidCallback? onRetry,
    String? retryLabel,
  }) {
    final message = getErrorMessage(error);
    final isNetwork = isNetworkError(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isNetwork ? Icons.wifi_off : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isNetwork ? Colors.orange : Colors.red,
        duration: Duration(seconds: onRetry != null ? 6 : 4),
        action: onRetry != null
            ? SnackBarAction(
                label: retryLabel ?? 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static Widget buildErrorWidget({
    required String message,
    VoidCallback? onRetry,
    String? retryLabel,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  retryLabel ?? 'Try Again',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}