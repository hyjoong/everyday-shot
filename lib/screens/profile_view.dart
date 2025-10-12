import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/features/auth/providers/auth_provider.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';
import 'package:everyday_shot/widgets/cached_photo_image.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  void _showSettingsBottomSheet(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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

            // 설정 옵션들
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
              title: const Text(
                '설정',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              onTap: () {
                Navigator.pop(context);
                // TODO: 설정 페이지 구현
              },
            ),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                '로그아웃',
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context, authProvider);
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
    return Consumer2<AuthProvider, PhotoProvider>(
      builder: (context, authProvider, photoProvider, _) {
        final user = authProvider.user;
        final photos = photoProvider.photos;

        return CustomScrollView(
          slivers: [
            // 프로필 헤더
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    // 프로필 이미지
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 이메일
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 이름 (있는 경우만)
                    if (user?.displayName != null && user!.displayName!.isNotEmpty)
                      Text(
                        user.displayName!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 통계
                    _buildStatItem('사진', photos.length),
                  ],
                ),
              ),
            ),

            // 갤러리 그리드
            if (photoProvider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (photos.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    '아직 사진이 없습니다',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(2),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final photo = photos[index];
                      return CachedPhotoImage(
                        imagePath: photo.imagePath,
                        fit: BoxFit.cover,
                      );
                    },
                    childCount: photos.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  static Future<void> _handleLogout(BuildContext context, AuthProvider authProvider) async {
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
            child: const Text('취소'),
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
  }
}
