import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:everyday_shot/firebase_options.dart';
import 'package:everyday_shot/constants/app_theme.dart';
import 'package:everyday_shot/screens/home_screen.dart';
import 'package:everyday_shot/features/photo/providers/photo_provider.dart';
import 'package:everyday_shot/features/auth/providers/auth_provider.dart';
import 'package:everyday_shot/features/auth/screens/login_screen.dart';
import 'package:everyday_shot/features/photo/services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: '.env');

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Kakao SDK 초기화 (hot reload 시 재초기화 방지)
  try {
    final kakaoAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
    if (kakaoAppKey.isNotEmpty) {
      KakaoSdk.init(nativeAppKey: kakaoAppKey);
    }
  } catch (e) {
    debugPrint('⚠️ Kakao SDK 초기화 실패 (이미 초기화됨): $e');
  }

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
        // 인증 상태 변경 시 클라우드 동기화
        if (authProvider.isAuthenticated && !_hasInitialized) {
          _hasInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final user = authProvider.user;
            if (user != null) {
              try {
                final firestoreService = FirestoreService();

                // 사용자 문서 생성 또는 업데이트
                await firestoreService.createOrUpdateUser(
                  userId: user.uid,
                  email: user.email ?? '',
                  displayName: user.displayName,
                );

                // 사진 동기화
                photoProvider.setUserId(user.uid);
                await photoProvider.syncWithCloud(user.uid);
              } catch (e) {
                // 동기화 실패 시 로컬 데이터로 계속 사용
                photoProvider.setUserId(user.uid);
              }
            }
          });
        } else if (!authProvider.isAuthenticated && _hasInitialized) {
          _hasInitialized = false;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            photoProvider.setUserId(null);
            // 로그아웃 시 로컬 DB 완전 삭제 (다른 계정 데이터가 섞이지 않도록)
            await photoProvider.clearLocalData();
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
