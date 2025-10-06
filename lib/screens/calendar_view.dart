import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';

class CalendarView extends StatefulWidget {
  final Function(DateTime)? onDateSelected;

  const CalendarView({super.key, this.onDateSelected});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// 특정 날짜에 사진이 있는지 확인
  List<dynamic> _getEventsForDay(DateTime day) {
    final photoProvider = context.read<PhotoProvider>();
    final photo = photoProvider.getPhotoByDate(day);
    return photo != null ? ['photo'] : [];
  }

  /// 커스텀 셀 빌더 (사진 썸네일 표시)
  Widget? _cellBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final photoProvider = context.read<PhotoProvider>();
    final photo = photoProvider.getPhotoByDate(day);

    if (photo == null) return null;

    final isToday = isSameDay(day, DateTime.now());
    final isSelected = isSameDay(day, _selectedDay);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: AppColors.accentLight, width: 2)
            : null,
      ),
      child: Stack(
        children: [
          // 사진 썸네일
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(photo.imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
          // 날짜 텍스트 (오버레이)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // 날짜 숫자
          Positioned(
            top: 2,
            right: 4,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // 선택 표시
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.accent,
                  width: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhotoProvider>(
      builder: (context, photoProvider, child) {
        return Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              locale: 'ko_KR',

              // 커스텀 셀 빌더 추가
              calendarBuilders: CalendarBuilders(
                defaultBuilder: _cellBuilder,
                selectedBuilder: _cellBuilder,
                todayBuilder: _cellBuilder,
                outsideBuilder: _cellBuilder,
              ),

              calendarStyle: CalendarStyle(
                outsideDaysVisible: true,
                cellMargin: EdgeInsets.zero,

                // 오늘 날짜
                todayDecoration: BoxDecoration(
                  color: AppColors.accentLight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.accentLight,
                  fontWeight: FontWeight.bold,
                ),

                // 선택된 날짜
                selectedDecoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),

                // 기본 날짜
                defaultTextStyle: const TextStyle(
                  color: AppColors.textPrimary,
                ),

                // 주말
                weekendTextStyle: const TextStyle(
                  color: AppColors.textSecondary,
                ),

                // 다른 달 날짜
                outsideTextStyle: const TextStyle(
                  color: AppColors.textTertiary,
                ),

                // 마커 숨김 (썸네일로 대체)
                markersMaxCount: 0,
              ),

          // 헤더 스타일
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: AppColors.textPrimary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: AppColors.textPrimary,
            ),
          ),

          // 요일 스타일
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            weekendStyle: TextStyle(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),

              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                // 상위 위젯에 선택된 날짜 전달
                widget.onDateSelected?.call(selectedDay);
              },

              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ],
        );
      },
    );
  }
}
