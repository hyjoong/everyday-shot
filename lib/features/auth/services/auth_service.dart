import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // iOS에서는 ClientID를 명시적으로 지정
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS
        ? '978762588523-uci72u5bncksdk73bqmrv7d4qak6vvop.apps.googleusercontent.com'
        : null,
  );

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 이메일/비밀번호 회원가입
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 이메일/비밀번호 로그인
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google 로그인 트리거
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // 사용자가 로그인 취소
        return null;
      }

      // Google 인증 정보 얻기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 로그인
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw '구글 로그인 실패: $e';
    }
  }

  // 카카오 로그인
  Future<UserCredential?> signInWithKakao() async {
    try {
      // 카카오톡 설치 여부 확인
      bool isTalkInstalled = await kakao.isKakaoTalkInstalled();

      kakao.OAuthToken token;
      if (isTalkInstalled) {
        // 카카오톡으로 로그인
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        // 카카오계정으로 로그인
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 카카오 사용자 정보 가져오기
      final kakaoUser = await kakao.UserApi.instance.me();
      final kakaoId = kakaoUser.id;

      if (kakaoId == null) {
        throw '카카오 사용자 ID를 가져올 수 없습니다';
      }

      // 카카오 ID를 기반으로 Firebase 이메일 계정 생성/로그인
      // 형식: kakao_{카카오ID}@everydayshot.app (가상 이메일)
      final email = 'kakao_$kakaoId@everydayshot.app';
      final password = 'kakao_${kakaoId}_everydayshot';

      UserCredential credential;
      try {
        // 기존 계정으로 로그인 시도
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          // 계정이 없으면 새로 생성
          credential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // 사용자 프로필 설정 (카카오 닉네임과 프로필 이미지)
          await credential.user?.updateDisplayName(
            kakaoUser.kakaoAccount?.profile?.nickname ?? '카카오 사용자',
          );
          await credential.user?.updatePhotoURL(
            kakaoUser.kakaoAccount?.profile?.profileImageUrl,
          );
        } else {
          throw e;
        }
      }

      return credential;
    } catch (e) {
      throw '카카오 로그인 실패: $e';
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    // 카카오 로그아웃
    try {
      await kakao.UserApi.instance.logout();
    } catch (_) {}

    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Firebase Auth 예외 처리
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일입니다.';
      case 'user-not-found':
        return '사용자를 찾을 수 없습니다.';
      case 'wrong-password':
        return '잘못된 비밀번호입니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '인증 오류: ${e.message}';
    }
  }
}
