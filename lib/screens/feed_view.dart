import 'package:flutter/material.dart';
import 'package:everyday_shot/constants/app_colors.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  // 더미 데이터
  static final List<Map<String, String>> _dummyData = [
    {'date': '2025.03.15', 'memo': '오늘 날씨 좋았다'},
    {'date': '2025.03.14', 'memo': '친구랑 카페'},
    {'date': '2025.03.12', 'memo': '주말 산책'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dummyData.length,
      itemBuilder: (context, index) {
        final item = _dummyData[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사진 영역
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 날짜
              Text(
                item['date']!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // 메모
              Text(
                item['memo']!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
