import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';
import 'package:everyday_shot/widgets/cached_photo_image.dart';

class GalleryView extends StatelessWidget {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PhotoProvider>(
      builder: (context, photoProvider, child) {
        final photos = photoProvider.photos;

        if (photoProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.accent,
            ),
          );
        }

        if (photos.isEmpty) {
          return const Center(
            child: Text(
              '아직 사진이 없습니다',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return CachedPhotoImage(
              imagePath: photo.imagePath,
              fit: BoxFit.cover,
            );
          },
        );
      },
    );
  }
}
