import 'package:flutter/material.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/models/photo.dart';

/// 사진 삭제 확인 다이얼로그
class DeletePhotoDialog {
  static Future<bool> show(BuildContext context, Photo photo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          '사진 삭제',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '이 사진을 삭제하시겠습니까?\n삭제된 사진은 복구할 수 없습니다.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
