# 변경사항 요약

## 날짜: 2025-12-02

## 추가된 파일

### 화면 (Screens)
- `lib/screens/intro_screen.dart` - 새로운 인트로 화면

### 모델 (Models)
- `lib/models/user_settings.dart` - 사용자 설정 데이터 모델

### 에셋 (Assets)
- `assets/Intro.mp4` - 인트로 배경 비디오
- `assets/images/Dewbye_App_Icon2.png` - 앱 아이콘

### 문서 및 스크립트
- `build_and_deploy.bat` - 자동 빌드 및 배포 스크립트
- `README_BUILD.md` - 상세 빌드 가이드
- `빌드_가이드.md` - 한글 빌드 가이드
- `QUICK_START.txt` - 빠른 시작 가이드
- `CHANGES.md` - 이 파일

## 수정된 파일

### pubspec.yaml
- 추가된 패키지:
  - `permission_handler: ^11.3.0` - 권한 관리
  - `video_player: ^2.8.2` - 비디오 재생
  - `flutter_launcher_icons: ^0.13.1` (dev) - 앱 아이콘 생성
- 추가된 에셋:
  - `assets/Intro.mp4`
- 앱 아이콘 설정 추가

### lib/app.dart
- `IntroScreen` import 추가
- 초기 라우트를 `/intro`로 변경
- `/intro` 라우트 추가

### android/app/src/main/AndroidManifest.xml
- 위치 권한 추가:
  - `ACCESS_FINE_LOCATION`
  - `ACCESS_COARSE_LOCATION`
- 저장소 권한 추가 (Android 12 이하):
  - `WRITE_EXTERNAL_STORAGE`
  - `READ_EXTERNAL_STORAGE`
- Android 13+ 미디어 권한:
  - `READ_MEDIA_IMAGES`
  - `READ_MEDIA_VIDEO`
- 인터넷 권한:
  - `INTERNET`

## 새로운 기능

### Intro Screen
1. **비디오 배경**
   - Intro.mp4를 60% 투명도로 반복 재생
   - 그라데이션 오버레이로 가독성 향상

2. **권한 상태 표시**
   - 위치 권한 상태 표시
   - 저장소 권한 상태 표시
   - 자동 권한 요청
   - 권한이 없으면 탭하여 재요청

3. **사용자 설정 입력**
   - **위치 선택**:
     - 기본값: 현재 위치 자동 감지
     - GPS를 사용하여 자동으로 위치 파악
     - 수동 선택 가능 (터치 시 위치 검색 화면)
   
   - **건물 타입**:
     - 주거용
     - 상업용
     - 산업용
     - 창고
     - 사무실
   
   - **실내 온도 설정**:
     - 범위: 10°C ~ 30°C
     - 슬라이더로 0.5°C 단위 조절
     - 기본값: 22°C
   
   - **실내 습도 설정**:
     - 범위: 20% ~ 80%
     - 슬라이더로 1% 단위 조절
     - 기본값: 50%

4. **사용자 경험**
   - 유리 형태(Glassmorphism) 디자인
   - 실시간 위치 로딩 인디케이터
   - 권한 상태에 따른 시각적 피드백
   - 모든 조건이 충족되면 "분석 시작" 버튼 활성화

### 앱 아이콘
- Dewbye_App_Icon2.png로 변경
- 모든 Android 해상도에 대응
- Adaptive icon 지원

## 데이터 흐름

```
IntroScreen
  ↓
사용자 입력 수집
  - 위치 (GPS 또는 수동)
  - 건물 타입
  - 실내 온도
  - 실내 습도
  ↓
HomeScreen으로 전달
  - arguments로 UserSettings 전달
  ↓
분석 시작
```

## 권한 요청 흐름

```
앱 시작
  ↓
IntroScreen 표시
  ↓
자동으로 권한 확인
  ↓
권한이 없으면 자동 요청
  ↓
사용자 승인/거부
  ↓
권한 상태 표시 업데이트
  ↓
위치 권한 있으면 현재 위치 자동 가져오기
```

## 빌드 방법

### 빠른 시작
```bash
cd dewbye
.\build_and_deploy.bat
```

### 수동 빌드
```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter build apk --release
flutter install
```

## 주의사항

1. **Flutter 경로**: Flutter가 PATH에 등록되어 있어야 합니다.
2. **Android 기기**: USB 디버깅이 활성화되어 있어야 합니다.
3. **새 터미널**: PowerShell을 새로 열어서 실행하세요.
4. **권한**: 관리자 권한으로 실행하는 것을 권장합니다.

## 다음 단계

빌드 후 테스트 시나리오:
1. 앱 시작 시 Intro 화면이 표시되는지 확인
2. 비디오가 반복 재생되는지 확인
3. 권한 요청 다이얼로그가 표시되는지 확인
4. 현재 위치가 자동으로 감지되는지 확인
5. 건물 타입, 온도, 습도 설정이 작동하는지 확인
6. "분석 시작" 버튼을 눌러 HomeScreen으로 이동하는지 확인

## 파일 구조

```
dewbye/
├── lib/
│   ├── models/
│   │   └── user_settings.dart (새로 생성)
│   ├── screens/
│   │   └── intro_screen.dart (새로 생성)
│   └── app.dart (수정됨)
├── assets/
│   ├── Intro.mp4 (새로 추가)
│   └── images/
│       └── Dewbye_App_Icon2.png (새로 추가)
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml (수정됨)
├── pubspec.yaml (수정됨)
├── build_and_deploy.bat (새로 생성)
├── README_BUILD.md (새로 생성)
├── 빌드_가이드.md (새로 생성)
├── QUICK_START.txt (새로 생성)
└── CHANGES.md (새로 생성)
```



