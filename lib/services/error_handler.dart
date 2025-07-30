import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ErrorType {
  network,
  api,
  offline,
  authentication,
  storage,
  parsing,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? details;
  final dynamic originalError;

  const AppError({
    required this.type,
    required this.message,
    this.details,
    this.originalError,
  });

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, details: $details)';
  }
}

class ErrorHandler {
  static Future<bool> isOnline() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  static AppError handleError(dynamic error) {
    if (error is AppError) {
      return error;
    }

    String message = 'An unexpected error occurred';
    ErrorType type = ErrorType.unknown;

    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      type = ErrorType.network;
      message =
          'Network connection failed. Please check your internet connection.';
    } else if (error.toString().contains('FormatException') ||
        error.toString().contains('JSON')) {
      type = ErrorType.parsing;
      message = 'Failed to process server response. Please try again.';
    } else if (error.toString().contains('401') ||
        error.toString().contains('403')) {
      type = ErrorType.authentication;
      message = 'Authentication failed. Please sign in again.';
    } else if (error.toString().contains('404')) {
      type = ErrorType.api;
      message = 'Service temporarily unavailable. Please try again later.';
    } else if (error.toString().contains('500') ||
        error.toString().contains('502') ||
        error.toString().contains('503')) {
      type = ErrorType.api;
      message = 'Server error. Please try again in a few moments.';
    }

    return AppError(type: type, message: message, originalError: error);
  }

  static String getErrorMessage(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        return 'Check your internet connection and try again.';
      case ErrorType.offline:
        return 'You\'re offline. Some features may not be available.';
      case ErrorType.api:
        return 'Service temporarily unavailable. Please try again later.';
      case ErrorType.authentication:
        return 'Please sign in again to continue.';
      case ErrorType.storage:
        return 'Failed to save data locally.';
      case ErrorType.parsing:
        return 'Failed to process response. Please try again.';
      default:
        return error.message;
    }
  }

  static AppError createOfflineError() {
    return const AppError(
      type: ErrorType.offline,
      message: 'No internet connection available',
    );
  }
}
