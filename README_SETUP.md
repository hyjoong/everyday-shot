# 환경 설정 가이드

## 1. Kakao SDK 설정

### `.env` 파일 생성
프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```
KAKAO_NATIVE_APP_KEY=your_kakao_native_app_key_here
```

### iOS Info.plist 설정
`ios/Runner/Info.plist` 파일에서 다음 부분을 수정하세요:

1. **CFBundleURLSchemes** (line 69):
   ```xml
   <string>kakao{YOUR_KAKAO_APP_KEY}</string>
   ```

2. **KAKAO_APP_KEY** (line 74):
   ```xml
   <key>KAKAO_APP_KEY</key>
   <string>{YOUR_KAKAO_APP_KEY}</string>
   ```

### Kakao 개발자 콘솔 설정

1. https://developers.kakao.com 접속
2. 내 애플리케이션 선택
3. **제품 설정 → 카카오 로그인 → Redirect URI**:
   - `kakao{YOUR_KAKAO_APP_KEY}://oauth` 추가

## 2. Firebase 설정

`.gitignore`에 이미 추가되어 있습니다:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Firebase 콘솔에서 다운로드한 설정 파일들을 해당 위치에 추가하세요.

## 3. 빌드 및 실행

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run
```
