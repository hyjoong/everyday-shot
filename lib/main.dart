import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:everyday_shot/constants/app_theme.dart';
import 'package:everyday_shot/screens/home_screen.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PhotoProvider()..loadPhotos(),
      child: MaterialApp(
        title: '매일한컷',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
        ],
        home: const HomeScreen(),
      ),
    );
  }
}
