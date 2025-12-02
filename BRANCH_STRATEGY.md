# Dewbye 프로젝트 브랜치 전략

## 🌳 브랜치 구조

```
Dewbye Repository
├── master (주 브랜치) - 모바일 앱 (Android/iOS)
└── web-platform (부 브랜치) - 웹 애플리케이션
```

---

## 📱 Master Branch

**용도:** Android 및 iOS 모바일 앱 개발

### 특징
- 비디오 배경 (Intro.mp4)
- 네이티브 권한 관리 (permission_handler)
- APK/IPA 빌드
- Google Play Store / Apple App Store 배포

### 개발 방법
```powershell
# Master 브랜치로 전환
git checkout master

# 모바일 앱 실행 (Android)
flutter run -d R3CW80CCH6V

# APK 빌드
flutter build apk --release
```

### 빌드 요구사항
- Android Studio 또는 Xcode
- Android SDK / iOS SDK
- 물리적 기기 또는 에뮬레이터
- 외부 네트워크 (Gradle 다운로드)

---

## 🌐 Web-Platform Branch

**용도:** 브라우저 기반 웹 애플리케이션

### 특징
- 그라데이션 배경 (비디오 대신)
- 브라우저 API 권한 관리
- HTML/JS/CSS 빌드
- 웹 서버 배포 (Firebase, Netlify, GitHub Pages)

### 개발 방법
```powershell
# Web 브랜치로 전환
git checkout web-platform

# 웹 앱 실행 (Chrome)
flutter run -d chrome

# 또는 개발 모드 스크립트
cd dewbye
.\web_dev_run.bat
```

### 빌드 방법
```powershell
# Production 빌드
flutter build web --release

# 로컬 서버 실행
cd dewbye
.\web_build_and_run.bat
```

### 빌드 요구사항
- 웹 브라우저 (Chrome, Edge, Firefox, Safari)
- 네트워크 제한 없음
- 즉시 테스트 가능

---

## 🔄 브랜치 전환

### Master → Web
```powershell
git checkout web-platform
```

### Web → Master
```powershell
git checkout master
```

### 현재 브랜치 확인
```powershell
git branch
# * (현재 브랜치에 * 표시)
```

---

## 📊 플랫폼 비교

| 항목 | Master (모바일) | Web-Platform (웹) |
|------|----------------|------------------|
| **배경** | 비디오 (Intro.mp4) | 그라데이션 |
| **권한** | 네이티브 API | 브라우저 API |
| **빌드** | APK/IPA | HTML/JS/CSS |
| **배포** | 앱 스토어 | 웹 서버 |
| **테스트** | 기기 필요 | 브라우저만 |
| **개발 속도** | 중간 | 빠름 ⭐ |
| **네트워크** | Gradle 필요 | 제한 없음 |
| **직접 수정** | 재빌드 필요 | 즉시 확인 ⭐ |

---

## 💡 개발 시나리오

### 시나리오 1: 빠른 UI 테스트
```powershell
# Web 브랜치 사용 (빠름!)
git checkout web-platform
flutter run -d chrome
# Hot Reload로 즉시 확인
```

### 시나리오 2: 모바일 기능 테스트
```powershell
# Master 브랜치 사용
git checkout master
flutter run -d R3CW80CCH6V
```

### 시나리오 3: 네트워크 문제 시
```powershell
# Web 브랜치 사용 (네트워크 제한 없음)
git checkout web-platform
flutter run -d chrome
```

---

## 🔀 변경사항 동기화

### Web의 변경사항을 Master로 가져오기
```powershell
# Master 브랜치로 전환
git checkout master

# Web 브랜치의 특정 파일 병합
git checkout web-platform -- dewbye/lib/screens/home_screen.dart

# 또는 전체 병합 (주의: 플랫폼 특화 코드 제외)
git merge web-platform
```

### Master의 변경사항을 Web으로 가져오기
```powershell
# Web 브랜치로 전환
git checkout web-platform

# Master 브랜치의 변경사항 병합
git merge master
```

---

## 🎯 권장 워크플로우

### 1단계: Web에서 빠른 프로토타이핑
```powershell
git checkout web-platform
# UI/UX 개발 및 테스트
flutter run -d chrome
```

### 2단계: Master에 반영
```powershell
git checkout master
# Web에서 완성된 기능을 Master로 이식
# 플랫폼 특화 코드 추가 (비디오, 권한 등)
```

### 3단계: 양쪽 브랜치 Push
```powershell
# Master 푸시
git checkout master
git push origin master

# Web 푸시
git checkout web-platform
git push origin web-platform
```

---

## 📝 주의사항

### 플랫폼 특화 코드

**Master (모바일) 전용:**
- `VideoPlayerController`
- `permission_handler` 패키지
- 네이티브 권한 요청
- 파일 시스템 접근

**Web-Platform (웹) 전용:**
- `kIsWeb` 조건부 처리
- 브라우저 Geolocation API
- Web Storage
- Canvas/HTML 렌더링

### 병합 시 주의
```dart
// 플랫폼 체크 코드는 자동 병합 가능
if (kIsWeb) {
  // Web 전용 코드
} else {
  // Mobile 전용 코드
}
```

---

## 🚀 배포 전략

### Master Branch (모바일)
1. 외부 네트워크에서 빌드
2. APK 생성
3. Google Play Console 업로드
4. 앱 스토어 심사

### Web-Platform Branch (웹)
1. Production 빌드
2. Firebase Hosting / Netlify 배포
3. 즉시 접근 가능
4. 심사 불필요

---

## 📚 참고 문서

**Master Branch:**
- `dewbye/빌드_가이드.md`
- `dewbye/외부네트워크_빌드명령.txt`
- `dewbye/ANDROID_STUDIO_빌드_가이드.md`

**Web-Platform Branch:**
- `dewbye/WEB_PLATFORM_README.md`
- `dewbye/web_dev_run.bat`
- `dewbye/web_build_and_run.bat`

---

## 🎉 브랜치 전략의 장점

### ✅ 유연한 개발
- 상황에 맞는 플랫폼 선택
- 네트워크 제약 우회
- 빠른 프로토타이핑

### ✅ 코드 재사용
- 대부분의 코드 공유
- 플랫폼별 최적화
- 유지보수 효율

### ✅ 독립적인 배포
- 모바일/웹 개별 배포
- 각 플랫폼 최적화
- 사용자 선택권

---

**현재 활성 브랜치:**
- ✅ master (모바일)
- ✅ web-platform (웹)

**마지막 업데이트:** 2025-12-02

