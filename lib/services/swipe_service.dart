import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'api_service.dart';
import '../backend_url.dart';

/// Enhanced swipe service with retry logic and idempotency support
class SwipeService {
  static const _uuid = Uuid();
  static const _maxRetries = 3;
  static const _baseDelayMs = 200;

  /// Record a swipe with automatic retry and idempotency
  /// 
  /// Parameters:
  /// - [targetUserId]: User being swiped on
  /// - [isLike]: true for like, false for pass
  /// - [idempotencyKey]: Optional client-provided key; auto-generated if null
  /// 
  /// Returns SwipeResponse or null on failure after all retries
  static Future<Map<String, dynamic>?> swipe({
    required String targetUserId,
    required bool isLike,
    String? idempotencyKey,
  }) async {
    // Generate idempotency key if not provided
    final key = idempotencyKey ?? _uuid.v4();

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final token = await AppState().getOrRefreshAuthToken();
        if (token == null) {
          debugPrint('Swipe aborted: no access token');
          return null;
        }

        final uri = Uri.parse('${ApiUrls.gateway}/api/swipes');
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'targetUserId': targetUserId,
            'direction': isLike ? 'like' : 'pass',
            'idempotencyKey': key, // Include idempotency key in request
          }),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Swipe request timed out'),
        );

        if (response.statusCode == 200) {
          debugPrint('Swipe succeeded (attempt ${attempt + 1})');
          return json.decode(response.body) as Map<String, dynamic>;
        }

        // 4xx errors shouldn't be retried (except 429 rate limit)
        if (response.statusCode >= 400 && response.statusCode < 500) {
          if (response.statusCode == 429) {
            debugPrint('Rate limited, will retry (attempt ${attempt + 1})');
          } else {
            debugPrint('Swipe failed with ${response.statusCode}: ${response.body}');
            return null; // Don't retry client errors
          }
        }

        // 5xx errors should be retried
        if (response.statusCode >= 500) {
          debugPrint('Server error ${response.statusCode}, will retry (attempt ${attempt + 1})');
        }

        // Exponential backoff before retry
        if (attempt < _maxRetries - 1) {
          final delayMs = _baseDelayMs * pow(2, attempt).toInt();
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      } on TimeoutException catch (e) {
        debugPrint('Swipe timeout (attempt ${attempt + 1}): $e');
        if (attempt < _maxRetries - 1) {
          final delayMs = _baseDelayMs * pow(2, attempt).toInt();
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      } catch (e, stack) {
        debugPrint('Swipe error (attempt ${attempt + 1}): $e');
        debugPrint('$stack');
        
        // For network errors, retry
        if (attempt < _maxRetries - 1) {
          final delayMs = _baseDelayMs * pow(2, attempt).toInt();
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
    }

    debugPrint('Swipe failed after $_maxRetries attempts');
    return null;
  }

  /// Batch swipe multiple profiles with idempotency
  /// 
  /// Each swipe in the batch gets its own UUID for retry safety.
  static Future<Map<String, dynamic>?> batchSwipe({
    required List<Map<String, dynamic>> swipes,
  }) async {
    try {
      final token = await AppState().getOrRefreshAuthToken();
      if (token == null) {
        debugPrint('Batch swipe aborted: no access token');
        return null;
      }

      final uri = Uri.parse('${ApiUrls.gateway}/api/swipes/batch');
      
      // Add idempotency keys to each swipe if not present
      final swipesWithKeys = swipes.map((s) {
        return {
          ...s,
          'idempotencyKey': s['idempotencyKey'] ?? _uuid.v4(),
        };
      }).toList();

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'swipes': swipesWithKeys,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      debugPrint('Batch swipe failed (${response.statusCode}): ${response.body}');
      return null;
    } catch (e, stack) {
      debugPrint('Batch swipe error: $e');
      debugPrint('$stack');
      return null;
    }
  }
}

/// Timeout exception for network operations
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
