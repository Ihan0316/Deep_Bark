# Deep_Bark

**Deep_Bark**는 반려견의 사진을 AI로 분석하여 믹스견/순종견 여부와 품종을 예측하고, 위치 기반 서비스를 통해 반려견 관련 다양한 정보를 제공하는 모바일 애플리케이션입니다.

---

## 주요 특징

- **AI 기반 반려견 품종 분석**: 사진 한 장으로 믹스견/순종견 분류 및 품종 예측
- **위치 기반 서비스**: 지도에서 반려견 원산지 및 품종별 정보 탐색
- **반려견 정보 제공**: 위키피디아 API 연동으로 품종별 상세 정보 제공
- **소셜 로그인 및 사용자 관리**: 카카오, 구글 연동
- **다국어 지원**: 한국어, 영어

---

## 기술 스택

| 분야     | 기술/프레임워크                     |
| -------- | ----------------------------------- |
| Frontend | Flutter                             |
| Backend  | Spring Boot                         |
| AI       | Python, TensorFlow, EfficientNet B4 |
| Database | MariaDB                             |
| API      | RESTful                             |

---

## 프로젝트 구조

### 1. Flutter 모바일 앱 (`App_flutter`)

- 위치 기반 서비스 (Google Maps)
- 소셜 로그인 연동 (카카오, 구글)
- 반려견 정보 및 품종 정보 조회
- 이미지 업로드 및 분석 요청
- 다국어 지원 (한국어, 영어)

#### 주요 패키지

- `google_maps_flutter`: 지도 서비스
- `kakao_flutter_sdk`: 카카오 로그인
- `google_sign_in`: 구글 로그인
- `image_picker`: 이미지 선택 및 업로드
- `http`: API 통신
- `provider`: 상태 관리
- `shared_preferences`: 로컬 데이터 저장
- `webview_flutter`: 웹뷰 기능
- `geocoding`: 위치 정보 처리

### 2. Spring Boot 백엔드

- RESTful API 서버
- 사용자 인증 및 권한 관리
- MariaDB 연동
- 파일 업로드 처리

### 3. Python AI 모델 (`Python/FlaskProject-Deep-Bark`)

- EfficientNet B4 모델 기반 품종 예측
- Flask 기반 이미지 분석 API 서버

---

## 설치 및 실행 방법

### 1. Flutter 앱 실행

cd App_flutter
flutter pub get
flutter run
text

### 2. Spring Boot 백엔드 실행

cd Java/deep_bark
./gradlew bootRun
text

### 3. Python AI 모델 실행

cd Python/FlaskProject-Deep-Bark
pip install -r requirements.txt
python app.py
text

> **참고:**
>
> - 각 환경별 설정 파일(.env 등)과 API 키, DB 접속 정보 등은 별도 구성 필요
> - 자세한 환경 변수 설정은 각 디렉터리의 README 또는 예시 파일을 참고하세요.

---

## 기여 방법

1. 이 저장소를 fork합니다.
2. 새로운 feature 브랜치를 생성합니다 (`git checkout -b feature/amazing-feature`)
3. 변경사항을 commit합니다 (`git commit -m 'Add some amazing feature'`)
4. 브랜치에 push합니다 (`git push origin feature/amazing-feature`)
5. Pull Request를 생성합니다.

---

## 이슈 제보

버그 리포트나 기능 요청은 [이슈 트래커](https://github.com/Ihan0316/Deep_Bark/issues)를 통해 제보해주세요.

---

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.

---

> 더 궁금한 점이나 개선 의견이 있다면 언제든 이슈로 남겨주세요!
