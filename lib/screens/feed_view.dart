import 'package:flutter/material.dart';
import 'package:everyday_shot/constants/app_colors.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '피드 뷰',
        style: TextStyle(
          fontSize: 24,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
