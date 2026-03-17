import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';

class PhotoGridCard extends StatelessWidget {
  final String? photoUrl;
  final bool isMainPhoto;
  final bool isEditing;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isLoading;
  final Map<String, String>? imageHeaders;

  const PhotoGridCard({
    super.key,
    this.photoUrl,
    this.isMainPhoto = false,
    this.isEditing = false,
    this.onTap,
    this.onDelete,
    this.isLoading = false,
    this.imageHeaders,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null) {
      return _buildAddPhotoButton();
    } else {
      return _buildPhotoCard();
    }
  }

  Widget _buildAddPhotoButton() {
    debugPrint('➕ Rendering empty photo slot (loading: $isLoading)');
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              const SizedBox(height: 8),
              const Text(
                'Uploading...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              Icon(
                Icons.add_a_photo_outlined,
                size: 32,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                'Add Photo',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    debugPrint(
      '🖼️ PhotoGridCard rendering network image: $photoUrl '
      '(main: $isMainPhoto, editing: $isEditing)',
    );
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              headers: imageHeaders,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                debugPrint(
                  '⏳ Loading image $photoUrl '
                  '(${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? -1} bytes)...',
                );
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Failed to load image $photoUrl -> $error');
                return Container(
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Failed to load',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Main photo badge
        if (isMainPhoto)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Text(
                'MAIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

        // Delete button
        if (isEditing && onDelete != null)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red[500],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),

        // Tap handler for reordering (if editing)
        if (isEditing && photoUrl != null)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Container(),
              ),
            ),
          ),
      ],
    );
  }
}
