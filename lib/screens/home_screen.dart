import 'package:flutter/material.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/screens/calendar_view.dart';
import 'package:everyday_shot/screens/feed_view.dart';
import 'package:everyday_shot/screens/gallery_view.dart';
import 'package:everyday_shot/screens/add_photo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _selectedDate;

  /// 캘린더에서 날짜 선택 시 호출
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
              Tab(text: '갤러리'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CalendarView(onDateSelected: _onDateSelected),
            const FeedView(),
            const GalleryView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPhotoScreen(
                  initialDate: _selectedDate ?? DateTime.now(),
                ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
