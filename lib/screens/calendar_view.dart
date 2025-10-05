import 'package:flutter/material.dart';
import 'package:everyday_shot/constants/app_colors.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '캘린더 뷰',
        style: TextStyle(
          fontSize: 24,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
