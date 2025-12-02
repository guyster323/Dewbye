# Dewbye 앱 빌드 및 배포 가이드

## 업데이트 내역

### 새로 추가된 기능
1. **Intro Screen** - 앱 시작 시 표시되는 초기 화면
   - 배경: Intro.mp4 비디오 반복 재생 (투명도 60%)
   - 권한 상태 표시 및 자동 권한 요청
   - 사용자 설정 입력:
     - 위치 (현재 위치 자동 감지 또는 수동 선택)
     - 건물 타입 (주거용, 상업용, 산업용, 창고, 사무실)
     - 실내 온도 설정 (10°C ~ 30°C)
     - 실내 습도 설정 (20% ~ 80%)

2. **앱 아이콘 변경**
   - Dewbye_App_Icon2.png를 앱 아이콘으로 설정

3. **권한 관리**
   - 위치 권한 (ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION)
   - 저장소 권한 (Android 12 이하)
   - 인터넷 권한

## 빌드 방법

### 방법 1: 자동 빌드 스크립트 (권장)
```cmd
cd dewbye
build_and_deploy.bat
```

### 방법 2: 수동 빌드
```cmd
cd dewbye

# 1. 패키지 설치
flutter pub get

# 2. 앱 아이콘 생성
flutter pub run flutter_launcher_icons

# 3. APK 빌드
flutter build apk --release

# 4. 연결된 Android 기기에 설치
flutter install
```

### 방법 3: Android Studio에서 빌드
1. Android Studio에서 `dewbye` 폴더 열기
2. 상단 메뉴에서 `Build` > `Flutter` > `Build APK` 선택
3. 빌드 완료 후 `Run` > `Run 'main.dart'` 선택하여 연결된 기기에 설치

## 사전 요구사항

### Android 기기 설정
1. **개발자 옵션 활성화**
   - 설정 > 휴대전화 정보 > 빌드 번호를 7번 터치
   
2. **USB 디버깅 활성화**
   - 설정 > 개발자 옵션 > USB 디버깅 켜기
   
3. **USB로 컴퓨터에 연결**
   - USB 연결 시 "USB 디버깅 허용" 메시지에서 "허용" 선택

### 연결 확인
```cmd
# Android 기기가 연결되었는지 확인
flutter devices

# 또는
adb devices
```

## 빌드 결과물

빌드가 완료되면 다음 위치에 APK 파일이 생성됩니다:
```
dewbye/build/app/outputs/flutter-apk/app-release.apk
```

이 파일을 다른 Android 기기에 복사하여 설치할 수도 있습니다.

## 문제 해결

### Flutter가 인식되지 않는 경우
- Flutter SDK가 설치되어 있는지 확인
- 환경 변수 PATH에 Flutter SDK 경로가 추가되어 있는지 확인
- PowerShell을 관리자 권한으로 실행

### 기기가 인식되지 않는 경우
- USB 케이블이 데이터 전송을 지원하는지 확인
- USB 디버깅이 활성화되어 있는지 확인
- Google USB Driver (Windows) 또는 기기 제조사의 USB 드라이버 설치
- `adb devices` 명령으로 기기 확인

### 빌드 오류 발생 시
```cmd
# Flutter 클린 후 재빌드
flutter clean
flutter pub get
flutter build apk --release
```

### 권한 관련 오류
- AndroidManifest.xml에 필요한 권한이 모두 추가되어 있는지 확인
- 앱 설치 후 설정에서 수동으로 권한을 부여할 수도 있습니다

## 추가 정보

### 디버그 모드로 실행
개발 및 테스트를 위해 디버그 모드로 실행:
```cmd
flutter run
```

### 로그 확인
앱 실행 중 로그 확인:
```cmd
flutter logs
```

또는
```cmd
adb logcat | findstr flutter
```

## 지원

문제가 발생하면 다음을 확인하세요:
- Flutter 버전: `flutter --version`
- Android SDK 설치 여부
- Java JDK 설치 여부 (Android 빌드에 필요)


