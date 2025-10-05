import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:everyday_shot/constants/app_colors.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 더미 마커 데이터
  final Map<DateTime, List<dynamic>> _events = {
    DateTime(2025, 3, 15): ['photo'],
    DateTime(2025, 3, 18): ['photo'],
    DateTime(2025, 3, 20): ['photo'],
  };

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
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
  }
}
