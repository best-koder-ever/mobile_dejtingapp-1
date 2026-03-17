import 'package:dejtingapp/services/photo_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoUploadResult', () {
    test('fromJson parses successful upload', () {
      final json = {
        'success': true,
        'errorMessage': null,
        'warnings': <String>[],
        'photo': {
          'id': 42,
          'userId': 7,
          'originalFileName': 'selfie.jpg',
          'displayOrder': 0,
          'isPrimary': true,
          'createdAt': '2026-03-17T10:00:00Z',
          'width': 1920,
          'height': 1080,
          'fileSizeBytes': 245760,
          'moderationStatus': 'Approved',
          'qualityScore': 85,
          'urls': {
            'full': 'http://localhost:8085/api/photos/42/image',
            'medium': 'http://localhost:8085/api/photos/42/medium',
            'thumbnail': 'http://localhost:8085/api/photos/42/thumbnail',
          },
        },
        'processingInfo': {
          'wasResized': true,
          'originalWidth': 4000,
          'originalHeight': 3000,
          'finalWidth': 1920,
          'finalHeight': 1440,
          'formatConverted': false,
          'originalFormat': 'jpeg',
          'finalFormat': 'jpeg',
          'processingTimeMs': 120,
        },
      };

      final result = PhotoUploadResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.warnings, isEmpty);
      expect(result.photo, isNotNull);
      expect(result.photo!.id, 42);
      expect(result.photo!.userId, 7);
      expect(result.photo!.originalFileName, 'selfie.jpg');
      expect(result.photo!.isPrimary, isTrue);
      expect(result.photo!.width, 1920);
      expect(result.photo!.height, 1080);
      expect(result.photo!.fileSizeBytes, 245760);
      expect(result.photo!.moderationStatus, 'Approved');
      expect(result.photo!.qualityScore, 85);
      expect(result.photo!.urls.full, contains('/42/image'));
      expect(result.photo!.urls.medium, contains('/42/medium'));
      expect(result.photo!.urls.thumbnail, contains('/42/thumbnail'));
      expect(result.processingInfo, isNotNull);
      expect(result.processingInfo!.wasResized, isTrue);
      expect(result.processingInfo!.originalWidth, 4000);
      expect(result.processingInfo!.finalWidth, 1920);
      expect(result.processingInfo!.processingTimeMs, 120);
    });

    test('fromJson parses failed upload', () {
      final json = {
        'success': false,
        'errorMessage': 'File too large',
        'warnings': ['Consider compressing the image'],
      };

      final result = PhotoUploadResult.fromJson(json);

      expect(result.success, isFalse);
      expect(result.errorMessage, 'File too large');
      expect(result.warnings, hasLength(1));
      expect(result.photo, isNull);
      expect(result.processingInfo, isNull);
    });

    test('toJson round-trips correctly', () {
      final original = PhotoUploadResult(
        success: true,
        photo: PhotoResponse(
          id: 1,
          userId: 2,
          originalFileName: 'test.png',
          displayOrder: 0,
          isPrimary: true,
          createdAt: DateTime.utc(2026, 3, 17),
          width: 800,
          height: 600,
          fileSizeBytes: 50000,
          moderationStatus: 'Pending',
          qualityScore: 70,
          urls: PhotoUrls(
            full: 'http://localhost:8085/api/photos/1/image',
            medium: 'http://localhost:8085/api/photos/1/medium',
            thumbnail: 'http://localhost:8085/api/photos/1/thumbnail',
          ),
        ),
      );

      final json = original.toJson();
      final restored = PhotoUploadResult.fromJson(json);

      expect(restored.success, original.success);
      expect(restored.photo!.id, original.photo!.id);
      expect(restored.photo!.urls.full, original.photo!.urls.full);
    });
  });

  group('PhotoResponse', () {
    test('fileSizeFormatted shows human-readable sizes', () {
      expect(
        PhotoResponse(
          id: 1, userId: 1, originalFileName: 'a.jpg', displayOrder: 0,
          isPrimary: false, createdAt: DateTime.now(), width: 100, height: 100,
          fileSizeBytes: 512, moderationStatus: 'Approved', qualityScore: 80,
          urls: PhotoUrls(full: '', medium: '', thumbnail: ''),
        ).fileSizeFormatted,
        '512.0 B',
      );

      expect(
        PhotoResponse(
          id: 1, userId: 1, originalFileName: 'a.jpg', displayOrder: 0,
          isPrimary: false, createdAt: DateTime.now(), width: 100, height: 100,
          fileSizeBytes: 1048576, moderationStatus: 'Approved', qualityScore: 80,
          urls: PhotoUrls(full: '', medium: '', thumbnail: ''),
        ).fileSizeFormatted,
        '1.0 MB',
      );
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 5,
        'userId': 10,
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final photo = PhotoResponse.fromJson(json);
      expect(photo.id, 5);
      expect(photo.originalFileName, '');
      expect(photo.displayOrder, 0);
      expect(photo.isPrimary, false);
      expect(photo.width, 0);
      expect(photo.height, 0);
    });
  });

  group('UserPhotoSummary', () {
    test('fromJson parses complete summary', () {
      final json = {
        'userId': 7,
        'totalPhotos': 3,
        'hasPrimaryPhoto': true,
        'primaryPhoto': {
          'id': 42,
          'userId': 7,
          'originalFileName': 'primary.jpg',
          'displayOrder': 0,
          'isPrimary': true,
          'createdAt': '2026-03-17T10:00:00Z',
          'width': 800,
          'height': 600,
          'fileSizeBytes': 50000,
          'moderationStatus': 'Approved',
          'qualityScore': 90,
          'urls': {
            'full': 'http://localhost:8085/api/photos/42/image',
            'medium': 'http://localhost:8085/api/photos/42/medium',
            'thumbnail': 'http://localhost:8085/api/photos/42/thumbnail',
          },
        },
        'photos': [
          {
            'id': 42,
            'userId': 7,
            'originalFileName': 'primary.jpg',
            'displayOrder': 0,
            'isPrimary': true,
            'createdAt': '2026-03-17T10:00:00Z',
            'width': 800,
            'height': 600,
            'fileSizeBytes': 50000,
            'moderationStatus': 'Approved',
            'qualityScore': 90,
            'urls': {
              'full': 'http://localhost:8085/api/photos/42/image',
              'medium': 'http://localhost:8085/api/photos/42/medium',
              'thumbnail': 'http://localhost:8085/api/photos/42/thumbnail',
            },
          },
          {
            'id': 43,
            'userId': 7,
            'originalFileName': 'beach.jpg',
            'displayOrder': 1,
            'isPrimary': false,
            'createdAt': '2026-03-17T11:00:00Z',
            'width': 1920,
            'height': 1080,
            'fileSizeBytes': 245760,
            'moderationStatus': 'Approved',
            'qualityScore': 75,
            'urls': {
              'full': 'http://localhost:8085/api/photos/43/image',
              'medium': 'http://localhost:8085/api/photos/43/medium',
              'thumbnail': 'http://localhost:8085/api/photos/43/thumbnail',
            },
          },
        ],
        'totalStorageBytes': 295760,
        'remainingPhotoSlots': 4,
        'hasReachedPhotoLimit': false,
      };

      final summary = UserPhotoSummary.fromJson(json);

      expect(summary.userId, 7);
      expect(summary.totalPhotos, 3);
      expect(summary.hasPrimaryPhoto, isTrue);
      expect(summary.primaryPhoto, isNotNull);
      expect(summary.primaryPhoto!.id, 42);
      expect(summary.photos, hasLength(2));
      expect(summary.photos[0].isPrimary, isTrue);
      expect(summary.photos[1].originalFileName, 'beach.jpg');
      expect(summary.totalStorageBytes, 295760);
      expect(summary.remainingPhotoSlots, 4);
      expect(summary.hasReachedPhotoLimit, isFalse);
    });

    test('fromJson handles empty photo list', () {
      final json = {
        'userId': 1,
        'totalPhotos': 0,
        'hasPrimaryPhoto': false,
        'photos': [],
        'totalStorageBytes': 0,
        'remainingPhotoSlots': 6,
        'hasReachedPhotoLimit': false,
      };

      final summary = UserPhotoSummary.fromJson(json);
      expect(summary.totalPhotos, 0);
      expect(summary.hasPrimaryPhoto, isFalse);
      expect(summary.primaryPhoto, isNull);
      expect(summary.photos, isEmpty);
      expect(summary.remainingPhotoSlots, 6);
    });
  });

  group('PhotoOrderItem', () {
    test('toJson serializes correctly', () {
      final item = PhotoOrderItem(photoId: 42, displayOrder: 0);
      final json = item.toJson();
      expect(json['PhotoId'], 42);
      expect(json['DisplayOrder'], 0);
    });
  });

  group('PhotoProcessingInfo', () {
    test('round-trips through JSON', () {
      final original = PhotoProcessingInfo(
        wasResized: true,
        originalWidth: 4000,
        originalHeight: 3000,
        finalWidth: 1920,
        finalHeight: 1440,
        formatConverted: true,
        originalFormat: 'png',
        finalFormat: 'jpeg',
        processingTimeMs: 250,
      );

      final json = original.toJson();
      final restored = PhotoProcessingInfo.fromJson(json);

      expect(restored.wasResized, isTrue);
      expect(restored.originalWidth, 4000);
      expect(restored.finalWidth, 1920);
      expect(restored.formatConverted, isTrue);
      expect(restored.originalFormat, 'png');
      expect(restored.finalFormat, 'jpeg');
      expect(restored.processingTimeMs, 250);
    });
  });
}
