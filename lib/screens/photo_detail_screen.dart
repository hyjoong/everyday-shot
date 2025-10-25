import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';
import 'package:everyday_shot/models/photo.dart';
import 'package:everyday_shot/widgets/cached_photo_image.dart';
import 'package:everyday_shot/widgets/delete_photo_dialog.dart';
import 'package:everyday_shot/screens/edit_photo_screen.dart';

class PhotoDetailScreen extends StatefulWidget {
  final Photo initialPhoto;
  final List<Photo>? allPhotos; // 좌우 스와이프를 위한 전체 사진 목록

  const PhotoDetailScreen({
    super.key,
    required this.initialPhoto,
    this.allPhotos,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<Photo> _photos;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _photos = widget.allPhotos ?? [widget.initialPhoto];
    _currentIndex = _photos.indexWhere((p) => p.id == widget.initialPhoto.id);
    if (_currentIndex == -1) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
  }

  Future<void> _deleteCurrentPhoto() async {
    final photo = _photos[_currentIndex];
    final photoProvider = context.read<PhotoProvider>();
    final isLastPhoto = _photos.length == 1;

    final confirm = await DeletePhotoDialog.show(context, photo);
    if (!confirm) return;

    try {
      // 마지막 사진이면 화면을 먼저 닫음 (재빌드 에러 방지)
      if (isLastPhoto) {
        Navigator.pop(context);
        // 화면을 닫은 후 삭제
        await photoProvider.deletePhoto(photo.id);
        return;
      }

      // 여러 사진 중 하나를 삭제하는 경우
      // 먼저 로컬 상태 업데이트 (재빌드 에러 방지)
      setState(() {
        _photos.removeAt(_currentIndex);
        if (_currentIndex >= _photos.length) {
          _currentIndex = _photos.length - 1;
        }
      });

      // 그 다음 실제 삭제
      await photoProvider.deletePhoto(photo.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진이 삭제되었습니다'),
          backgroundColor: AppColors.accent,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // 에러 발생 시 로컬 상태 롤백 (여러 사진인 경우만)
      if (!isLastPhoto) {
        setState(() {
          // 전체 목록 다시 로드
          _photos = photoProvider.photos;
          _currentIndex = _photos.indexWhere((p) => p.id == photo.id);
          if (_currentIndex == -1) _currentIndex = 0;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 실패: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _editCurrentPhoto() async {
    final photo = _photos[_currentIndex];

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPhotoScreen(photo: photo),
      ),
    );

    // 수정되었으면 목록 새로고침
    if (result == true && mounted) {
      final photoProvider = context.read<PhotoProvider>();
      setState(() {
        // 업데이트된 사진 가져오기
        _photos = widget.allPhotos ?? photoProvider.photos;
        // 현재 인덱스 재조정
        _currentIndex = _photos.indexWhere((p) => p.id == photo.id);
        if (_currentIndex == -1) _currentIndex = 0;
      });
    }
  }

  void _showOptionsMenu() {
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
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
              title: const Text(
                '수정',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _editCurrentPhoto();
              },
            ),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                '삭제',
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _deleteCurrentPhoto();
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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showUI
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: _showOptionsMenu,
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // 이미지 뷰어 (PageView)
          PageView.builder(
            controller: _pageController,
            itemCount: _photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photo = _photos[index];
              return GestureDetector(
                onTap: _toggleUI,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: 'photo_${photo.id}',
                      child: CachedPhotoImage(
                        imagePath: photo.imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 하단 정보 (날짜, 메모)
          if (_showUI)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 날짜
                    Text(
                      DateFormat('yyyy년 MM월 dd일')
                          .format(_photos[_currentIndex].date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_photos[_currentIndex].memo != null &&
                        _photos[_currentIndex].memo!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      // 메모
                      Text(
                        _photos[_currentIndex].memo!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                    // 페이지 인디케이터 (사진이 여러 개일 때)
                    if (_photos.length > 1) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '${_currentIndex + 1} / ${_photos.length}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
