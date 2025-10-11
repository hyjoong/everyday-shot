# Firebase Security Rules 설정

Firebase Console에서 다음 보안 규칙을 설정해야 합니다.

## Firestore Security Rules

Firebase Console > Firestore Database > 규칙 탭에서 다음 규칙을 설정하세요:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자 컬렉션 규칙
    match /users/{userId} {
      // 본인만 읽기/쓰기 가능
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // 사진 컬렉션 규칙
    match /photos/{photoId} {
      // 본인 사진만 읽기/쓰기 가능
      allow read, write: if request.auth != null &&
                            request.auth.uid == resource.data.userId;

      // 새 사진 생성 시 userId 검증
      allow create: if request.auth != null &&
                      request.auth.uid == request.resource.data.userId;
    }
  }
}
```

## Firebase Storage Rules

Firebase Console > Storage > 규칙 탭에서 다음 규칙을 설정하세요:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // 사용자별 사진 폴더 규칙
    match /users/{userId}/photos/{photoId} {
      // 본인 사진만 읽기/쓰기/삭제 가능
      allow read, write, delete: if request.auth != null &&
                                    request.auth.uid == userId;
    }
  }
}
```

## 설정 순서

1. **Firebase Console 접속**: https://console.firebase.google.com
2. **프로젝트 선택**: `everydaycut` 프로젝트
3. **Firestore Database 규칙 설정**:
   - 좌측 메뉴 > Firestore Database > 규칙 탭
   - 위의 Firestore Security Rules 복사/붙여넣기
   - "게시" 버튼 클릭
4. **Storage 규칙 설정**:
   - 좌측 메뉴 > Storage > 규칙 탭
   - 위의 Firebase Storage Rules 복사/붙여넣기
   - "게시" 버튼 클릭

## 보안 규칙 설명

### Firestore Rules
- 사용자는 본인의 프로필만 읽고 수정할 수 있습니다
- 사용자는 본인이 생성한 사진만 읽고 수정할 수 있습니다
- 새 사진 생성 시 userId가 현재 로그인한 사용자와 일치해야 합니다

### Storage Rules
- 사용자는 본인의 폴더(users/{userId})에만 접근할 수 있습니다
- 다른 사용자의 사진은 읽거나 수정할 수 없습니다
- 인증되지 않은 사용자는 아무 것도 접근할 수 없습니다

## 추가 참고사항

- 테스트 환경에서는 규칙을 일시적으로 완화할 수 있지만, 프로덕션에서는 반드시 위 규칙을 적용하세요
- 규칙 변경 후 약간의 지연(~1분)이 있을 수 있습니다
