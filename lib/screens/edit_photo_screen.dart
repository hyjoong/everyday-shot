import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';
import 'package:everyday_shot/models/photo.dart';
import 'package:everyday_shot/widgets/cached_photo_image.dart';

class EditPhotoScreen extends StatefulWidget {
  final Photo photo;

  const EditPhotoScreen({super.key, required this.photo});

  @override
  State<EditPhotoScreen> createState() => _EditPhotoScreenState();
}

class _EditPhotoScreenState extends State<EditPhotoScreen> {
  late TextEditingController _memoController;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.photo.memo ?? '');
    _selectedDate = widget.photo.date;
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  /// 날짜 선택
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// 변경사항 저장
  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedPhoto = Photo(
        id: widget.photo.id,
        date: _selectedDate,
        imagePath: widget.photo.imagePath,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        createdAt: widget.photo.createdAt,
        updatedAt: DateTime.now(),
      );

      await context.read<PhotoProvider>().updatePhoto(updatedPhoto);

      if (mounted) {
        Navigator.pop(context, true); // true를 반환하여 수정되었음을 알림
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진이 수정되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 수정'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                '저장',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진 미리보기
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedPhotoImage(
                  imagePath: widget.photo.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 날짜 선택
            const Text(
              '날짜',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 메모 입력
            const Text(
              '메모',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                hintText: '오늘의 한마디를 남겨보세요',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                ),
                counterStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
