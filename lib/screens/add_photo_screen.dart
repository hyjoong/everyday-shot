import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';
import 'package:everyday_shot/features/photo/services/image_service.dart';
import 'package:everyday_shot/models/photo.dart';

class AddPhotoScreen extends StatefulWidget {
  final DateTime initialDate;

  const AddPhotoScreen({super.key, required this.initialDate});

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  final ImageService _imageService = ImageService();
  final TextEditingController _memoController = TextEditingController();
  final Uuid _uuid = const Uuid();

  late DateTime _selectedDate;
  File? _selectedImage;
  bool _isSaving = false;
  List<AssetEntity> _todayPhotos = [];
  bool _loadingPhotos = false;
  bool _isSelectingPhoto = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _loadTodayPhotos();
  }

  /// 선택된 날짜의 갤러리 사진 로드
  Future<void> _loadTodayPhotos() async {
    setState(() {
      _loadingPhotos = true;
    });

    final photos = await _imageService.getPhotosForDate(_selectedDate);

    if (mounted) {
      setState(() {
        _todayPhotos = photos;
        _loadingPhotos = false;
      });
    }
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
      // 날짜가 변경되면 해당 날짜의 사진 목록 다시 로드
      await _loadTodayPhotos();
    }
  }

  /// 이미지 선택 (갤러리 or 카메라)
  Future<void> _pickImage(ImageSource source) async {
    // 로딩 시작
    setState(() {
      _isSelectingPhoto = true;
    });

    try {
      final String? imagePath = await _imageService.pickAndSaveImage(
        source: source,
      );

      if (imagePath != null && mounted) {
        final imageFile = File(imagePath);

        // EXIF에서 촬영 날짜 추출 시도
        final DateTime? exifDate =
            await _imageService.getImageDateTime(imageFile);

        setState(() {
          _selectedImage = imageFile;
          // EXIF 날짜가 있으면 자동 설정
          if (exifDate != null) {
            _selectedDate = exifDate;
          }
        });

        // EXIF 날짜를 찾았다면 사용자에게 알림
        if (exifDate != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '촬영 날짜로 자동 설정: ${exifDate.year}.${exifDate.month.toString().padLeft(2, '0')}.${exifDate.day.toString().padLeft(2, '0')}',
              ),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      // 로딩 종료
      if (mounted) {
        setState(() {
          _isSelectingPhoto = false;
        });
      }
    }
  }

  /// 이미지 선택 옵션 표시
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library,
                      color: AppColors.textPrimary),
                  title: const Text(
                    '갤러리에서 선택',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt,
                      color: AppColors.textPrimary),
                  title: const Text(
                    '카메라로 촬영',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 사진 저장
  Future<void> _savePhoto() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진을 선택해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final photo = Photo(
        id: _uuid.v4(),
        date: _selectedDate,
        imagePath: _selectedImage!.path,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await context.read<PhotoProvider>().addPhoto(photo);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진이 저장되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
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
        title: const Text('사진 추가'),
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
              onPressed: _savePhoto,
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
            // 사진 영역
            GestureDetector(
              onTap: _isSelectingPhoto ? null : _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width - 32, // 가로 꽉 차게
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // 선택된 이미지 또는 플레이스홀더
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _selectedImage != null
                          ? SizedBox.expand(
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 64,
                                    color: AppColors.textTertiary,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    '사진 선택',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    // 로딩 오버레이
                    if (_isSelectingPhoto)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                  strokeWidth: 4,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '사진 불러오는 중...',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 오늘 촬영한 사진 (상단 배치)
            if (_todayPhotos.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDate.month}월 ${_selectedDate.day}일 촬영한 사진',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_todayPhotos.length}장',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _todayPhotos.length,
                  itemBuilder: (context, index) {
                    final asset = _todayPhotos[index];
                    return GestureDetector(
                      onTap: _isSelectingPhoto
                          ? null
                          : () async {
                              // 로딩 시작
                              setState(() {
                                _isSelectingPhoto = true;
                              });

                              try {
                                // 사진 선택
                                final file = await asset.file;
                                if (file != null) {
                                  final savedPath =
                                      await _imageService.saveImage(file);
                                  final imageFile = File(savedPath);

                                  // EXIF 날짜 추출
                                  final exifDate = await _imageService
                                      .getImageDateTime(imageFile);

                                  if (mounted) {
                                    setState(() {
                                      _selectedImage = imageFile;
                                      if (exifDate != null) {
                                        _selectedDate = exifDate;
                                      }
                                    });

                                    if (exifDate != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '촬영 날짜로 자동 설정: ${exifDate.year}.${exifDate.month.toString().padLeft(2, '0')}.${exifDate.day.toString().padLeft(2, '0')}',
                                          ),
                                          backgroundColor: AppColors.accent,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                }
                              } finally {
                                // 로딩 종료
                                if (mounted) {
                                  setState(() {
                                    _isSelectingPhoto = false;
                                  });
                                }
                              }
                            },
                      child: Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List?>(
                            future: asset.thumbnailDataWithSize(
                              const ThumbnailSize.square(240),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.data != null) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(
                                color: AppColors.surfaceVariant,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColors.accent,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ] else if (_loadingPhotos) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

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
              '메모 (선택)',
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                hintText: '오늘의 한마디를 남겨보세요',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
