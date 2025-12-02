# Android Studio로 빌드하기

## 현재 상황
- 모든 코드 작업 완료
- Flutter CLI 빌드 시 회사 네트워크 문제로 Gradle 플러그인 다운로드 실패
- Android Studio는 자체 Gradle 및 네트워크 설정을 사용하므로 성공률이 높음

## 빌드 방법

### 1단계: Android Studio 실행

### 2단계: 프로젝트 열기
1. **File** → **Open...**
2. 다음 경로 선택: `D:\LGES_Backup\AI_Driven\Dewbye\Dewbye\dewbye`
3. **OK** 클릭

### 3단계: Gradle Sync (자동)
- 프로젝트가 열리면 자동으로 Gradle 동기화 시작
- 하단 상태 표시줄에서 진행 상황 확인
- "Gradle sync finished" 메시지가 나타날 때까지 대기 (수 분 소요)

만약 Gradle sync가 시작되지 않으면:
- **File** → **Sync Project with Gradle Files** 클릭

### 4단계: 기기 선택
- 상단 툴바에서 기기 선택 드롭다운 클릭
- **SM F946N (R3CW80CCH6V)** 선택
- 기기가 보이지 않으면:
  1. USB 케이블 다시 연결
  2. 휴대폰에서 USB 디버깅 허용 확인
  3. **Tools** → **Device Manager** 확인

### 5단계: 실행
**방법 A - 직접 실행**:
- 상단의 초록색 재생 버튼 ▶️ 클릭
- 또는 **Shift + F10** 단축키

**방법 B - 디버그 실행**:
- 디버그 아이콘 🐛 클릭
- 또는 **Shift + F9** 단축키

### 6단계: 빌드 확인
- 하단 **Run** 탭에서 빌드 진행 상황 확인
- "Installing APK" 메시지 확인
- "Connecting to VM Service" 확인
- 휴대폰에서 앱이 자동으로 실행됨

## Release APK 생성 (선택사항)

Release 버전 APK 파일을 생성하려면:

1. **Build** → **Flutter** → **Build APK**
2. 빌드 완료 메시지 대기
3. "locate" 링크 클릭하여 APK 파일 위치 확인
4. APK 위치: `build\app\outputs\flutter-apk\app-release.apk`

## 문제 해결

### Gradle Sync 실패
1. **File** → **Invalidate Caches / Restart**
2. **Invalidate and Restart** 선택
3. Android Studio 재시작 후 자동으로 Gradle sync 재시도

### SDK 누락 오류
1. **Tools** → **SDK Manager**
2. **SDK Platforms** 탭:
   - Android 15 (API 35) 체크
3. **SDK Tools** 탭:
   - Android SDK Build-Tools 체크
   - Android SDK Platform-Tools 체크
   - Google Play services 체크
4. **Apply** 클릭하여 설치

### 플러그인 오류
1. **File** → **Settings** → **Plugins**
2. 다음 플러그인 설치 확인:
   - Flutter
   - Dart
3. 없으면 검색하여 설치 후 Android Studio 재시작

## 실행 확인

앱이 정상적으로 실행되면:
1. **Intro Screen**이 표시됨
2. 배경에 비디오가 재생됨
3. 권한 요청 다이얼로그 표시
4. 위치, 건물 타입, 온습도 설정 가능
5. "분석 시작" 버튼으로 메인 화면 이동

## 추가 정보

### Hot Reload
앱 실행 중 코드 수정 시:
- **Ctrl + \\** 또는 번개 아이콘 ⚡ 클릭
- 앱 재시작 없이 변경사항 반영

### 로그 확인
- **View** → **Tool Windows** → **Logcat**
- Flutter 앱의 모든 로그 확인 가능

### 디버깅
- 코드에 중단점 설정 (라인 번호 왼쪽 클릭)
- 디버그 모드로 실행
- 변수 값 확인, 단계별 실행 가능

---

**빌드 성공을 기원합니다! 🚀**




