import 'dart:io';
import 'package:dio/dio.dart';

class NetErrors {
  static String describe(DioException e) {
    final inner = e.error;
    if (inner is FileSystemException) return storage(inner);
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The connection timed out. Check your network and try again.';
      case DioExceptionType.connectionError:
        return 'Network connection lost. Check your internet and try again.';
      case DioExceptionType.badCertificate:
        return 'The server certificate is not trusted.';
      case DioExceptionType.badResponse:
        final c = e.response?.statusCode;
        if (c == 401 || c == 403) {
          return "Access denied (HTTP $c). This file requires authorisation and can't be downloaded.";
        }
        if (c == 404) return 'File not found (HTTP 404).';
        return 'Server error (HTTP $c).';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String storage(FileSystemException e) => e.osError?.errorCode == 28
      ? 'Not enough storage space. Free up space and retry.'
      : 'Storage error: ${e.message}';
}
