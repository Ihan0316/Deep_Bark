# Deep_Bark

반려견의 사진을 분석하여 믹스인지 순종인지를 파악하고, 위치 기반으로 주변의 반려견과 소통할 수 있는 모바일 애플리케이션입니다.

## 개발 환경

- Flutter - 안드로이드, ios 앱 프론트
- Spring Boot - 백(서버)단 작업
- Python - 모델링 및 모델 서버

## 프로젝트 구조

### 1. Flutter 모바일 앱 (App_flutter)

- 위치 기반 서비스 (Google Maps)
- 카카오 로그인 연동
- 반려견 정보 공유
- 위키피디아 API 연동
- 이미지 업로드
- 다국어 지원 (한국어, 영어)

#### 주요 패키지

- `google_maps_flutter`: 지도 서비스
- `kakao_flutter_sdk`: 카카오 로그인
- `image_picker`: 이미지 선택 및 업로드
- `http`: API 통신
- `provider`: 상태 관리
- `shared_preferences`: 로컬 데이터 저장
- `webview_flutter`: 웹뷰 기능
- `geocoding`: 위치 정보 처리

### 2. Spring Boot 백엔드

- RESTful API 서버
- 사용자 인증 및 권한 관리
- 데이터베이스 연동
- 파일 업로드 처리

### 3. Python AI 모델 (Python/FlaskProject-Deep-Bark)

- EfficientNet B4 모델 사용
- Flask 기반 API 서버
- 이미지 처리 및 분석

## 주요 기능

1. 반려견 사진 분석

   - 믹스견/순종견 분류
   - 품종 예측
   - 분석 결과 제공

2. 위치 기반 서비스

   - 반려견 원산지 위치 표시

3. 반려견 정보

   - 위키피디아 API를 통한 품종 정보 제공
   - 사진 및 정보 호출

4. 사용자 관리
   - 소셜 (카카오, 구글) 로그인
   - 프로필 관리

## 기술 스택

- Frontend: Flutter
- Backend: Spring Boot
- AI: Python, TensorFlow, EfficientNet B4
- Database: Maria DB
- API: RESTful

## 설치 및 실행 방법

### Flutter 앱 실행

```bash
cd App_flutter
flutter pub get
flutter run
```

### Spring Boot 백엔드 실행

```bash
cd Java/deep_bark
./gradlew bootRun
```

## 기여 방법

1. 이 저장소를 fork합니다.
2. 새로운 feature 브랜치를 생성합니다 (`git checkout -b feature/amazing-feature`)
3. 변경사항을 commit합니다 (`git commit -m 'Add some amazing feature'`)
4. 브랜치에 push합니다 (`git push origin feature/amazing-feature`)
5. Pull Request를 생성합니다.

## 이슈 제보

버그 리포트나 기능 요청은 [이슈 트래커](https://github.com/Ihan0316/Deep_Bark/issues)를 통해 제보해주세요.

## 라이센스

이 프로젝트는 MIT 라이센스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
