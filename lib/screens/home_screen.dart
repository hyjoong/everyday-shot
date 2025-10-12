import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/screens/calendar_view.dart';
import 'package:everyday_shot/screens/feed_view.dart';
import 'package:everyday_shot/screens/profile_view.dart';
import 'package:everyday_shot/screens/add_photo_screen.dart';
import 'package:everyday_shot/features/auth/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // 탭 변경 시 AppBar 다시 빌드
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 캘린더에서 날짜 선택 시 호출
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  /// 설정 바텀시트 표시
  void _showSettingsBottomSheet(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들바
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 로그아웃
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                '로그아웃',
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary),
              onTap: () async {
                Navigator.pop(bottomSheetContext);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text(
                      '로그아웃',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    content: const Text(
                      '로그아웃하시겠습니까?',
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
                          '로그아웃',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await authProvider.signOut();
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매일한컷'),
        actions: [
          // 프로필 탭(index 2)일 때만 설정 아이콘 표시
          if (_tabController.index == 2)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: '설정',
              onPressed: () => _showSettingsBottomSheet(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '캘린더'),
            Tab(text: '피드'),
            Tab(text: '프로필'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CalendarView(onDateSelected: _onDateSelected),
          const FeedView(),
          const ProfileView(),
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
    );
  }
}
