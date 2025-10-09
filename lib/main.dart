import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:everyday_shot/constants/app_theme.dart';
import 'package:everyday_shot/screens/home_screen.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';
import 'package:everyday_shot/features/auth/providers/auth_provider.dart';
import 'package:everyday_shot/features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initUser()),
        ChangeNotifierProvider(create: (_) => PhotoProvider()..loadPhotos()),
      ],
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
        home: const AuthWrapper(),
      ),
    );
  }
}

// 인증 상태에 따라 화면 라우팅
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PhotoProvider>(
      builder: (context, authProvider, photoProvider, _) {
        // 인증 상태 변경 시 PhotoProvider와 동기화
        if (authProvider.isAuthenticated && !_hasInitialized) {
          _hasInitialized = true;
          // 로그인 성공 시 동기화
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final userId = authProvider.user?.uid;
            if (userId != null) {
              photoProvider.setUserId(userId);
              photoProvider.syncWithCloud(userId).catchError((e) {
                // 동기화 실패 시 에러 처리 (선택사항)
                debugPrint('동기화 실패: $e');
              });
            }
          });
        } else if (!authProvider.isAuthenticated && _hasInitialized) {
          _hasInitialized = false;
          // 로그아웃 시 userId 초기화
          WidgetsBinding.instance.addPostFrameCallback((_) {
            photoProvider.setUserId(null);
          });
        }

        // 로그인 상태면 HomeScreen, 아니면 LoginScreen
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
