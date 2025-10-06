import 'package:flutter/material.dart';
import 'package:everyday_shot/constants/app_colors.dart';

class GalleryView extends StatelessWidget {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: Icon(
              Icons.image,
              size: 32,
              color: AppColors.textTertiary,
            ),
          ),
        );
      },
    );
  }
}
