# app_flutter

## 로컬 시크릿 설정

이 앱은 Firebase 설정 파일과 Google Maps 키가 로컬에 있어야 정상 동작합니다. 실제 값은 Git에 커밋하지 않고 각 개발 환경에만 둡니다.

### Android

- `App_flutter/android/app/google-services.json.example`를 참고해 실제 Firebase 설정 파일을 `App_flutter/android/app/google-services.json` 경로에 둡니다.
- `App_flutter/android/local.properties`에 아래 값을 추가합니다.

```properties
googleMaps.apiKey=YOUR_ANDROID_GOOGLE_MAPS_API_KEY
```

### iOS

- `App_flutter/ios/Runner/GoogleService-Info.plist.example`를 참고해 실제 Firebase 설정 파일을 `App_flutter/ios/Runner/GoogleService-Info.plist` 경로에 둡니다.
- `App_flutter/ios/Flutter/Secrets.xcconfig.example`를 복사해 `App_flutter/ios/Flutter/Secrets.xcconfig`를 만든 뒤 값을 채웁니다.

```xcconfig
GOOGLE_MAPS_API_KEY=YOUR_IOS_GOOGLE_MAPS_API_KEY
```

`Secrets.xcconfig`, `google-services.json`, `GoogleService-Info.plist`는 모두 로컬 전용 파일이며 Git에서 추적하지 않습니다.
