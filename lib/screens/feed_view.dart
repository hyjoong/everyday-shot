import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사진 영역
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(photo.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 날짜
                  Text(
                    DateFormat('yyyy.MM.dd').format(photo.date),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (photo.memo != null && photo.memo!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    // 메모
                    Text(
                      photo.memo!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
