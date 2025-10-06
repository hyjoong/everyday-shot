import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:everyday_shot/constants/app_colors.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

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

          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,

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

            // 마커
            markerDecoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            markerSize: 6,
            markersMaxCount: 1,
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
