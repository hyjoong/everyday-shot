import 'package:flutter/material.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/screens/calendar_view.dart';
import 'package:everyday_shot/screens/feed_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('매일한컷'),
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: '캘린더'),
              Tab(text: '피드'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CalendarView(),
            FeedView(),
          ],
        ),
      ),
    );
  }
}
