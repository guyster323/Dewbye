# Dewbye Web Platform

## 🌐 브랜치 전략

### Master Branch (master)
- **용도:** Android/iOS 모바일 앱 개발
- **빌드:** APK/IPA
- **배포:** Google Play Store / Apple App Store

### Web Platform Branch (web-platform)
- **용도:** 웹 애플리케이션 개발
- **빌드:** HTML/JS/CSS
- **배포:** 웹 서버 (Firebase Hosting, Netlify, GitHub Pages 등)

---

## 🚀 Web 플랫폼 특징

### 장점
1. ✅ **빌드 불필요** - 코드 수정 후 즉시 확인 가능
2. ✅ **브라우저에서 직접 실행** - 별도 기기 불필요
3. ✅ **빠른 개발 사이클** - Hot Reload 지원
4. ✅ **크로스 플랫폼** - 모든 OS에서 접근 가능
5. ✅ **쉬운 공유** - URL만으로 배포/테스트 가능
6. ✅ **네트워크 문제 없음** - 로컬 서버에서 개발

### Web 전용 기능
- 반응형 디자인 (데스크톱/태블릿/모바일)
- URL 라우팅
- SEO 최적화
- PWA (Progressive Web App) 지원

---

## 💻 개발 환경 설정

### 1. Flutter Web 활성화
```powershell
flutter config --enable-web
```

### 2. Web 디바이스 확인
```powershell
flutter devices
```

출력 예시:
```
Chrome (web) • chrome • web-javascript • Google Chrome
Edge (web)   • edge   • web-javascript • Microsoft Edge
```

### 3. Web에서 실행
```powershell
cd D:\LGES_Backup\AI_Driven\Dewbye\Dewbye\dewbye
flutter run -d chrome
```

또는 Edge:
```powershell
flutter run -d edge
```

---

## 🛠️ Web 빌드

### Development Build (디버그)
```powershell
flutter build web
```

### Production Build (최적화)
```powershell
flutter build web --release
```

**빌드 결과:**
```
dewbye/build/web/
├── index.html
├── main.dart.js
├── flutter.js
├── assets/
└── icons/
```

---

## 🌍 로컬 서버 실행

### Python 사용
```powershell
cd dewbye/build/web
python -m http.server 8000
```

브라우저에서: `http://localhost:8000`

### VS Code Live Server
1. VS Code에서 `dewbye/build/web/index.html` 열기
2. 오른쪽 클릭 → "Open with Live Server"

---

## 📱 Web vs App 차이점

### Web에서 제한되는 기능
1. **비디오 배경** - 성능 고려하여 정적 이미지로 대체 가능
2. **위치 권한** - 브라우저 API 사용 (다른 방식)
3. **저장소 권한** - Web Storage/IndexedDB 사용
4. **파일 다운로드** - `<a>` 태그 또는 Blob API 사용

### Web에서 자동 처리
- **권한 관리** - 브라우저가 자동 처리
- **업데이트** - 새로고침만으로 자동 업데이트
- **설치 불필요** - 즉시 사용 가능

---

## 🔄 Web 최적화

### 1. 비디오 배경 처리

**Option A: 정적 이미지로 대체**
```dart
// Web에서는 비디오 대신 이미지 사용
if (kIsWeb) {
  // 이미지 배경
  Image.asset('assets/images/intro_bg.png')
} else {
  // 비디오 배경
  VideoPlayer(_videoController!)
}
```

**Option B: 조건부 로딩**
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (!kIsWeb) {
  // 모바일에서만 비디오 초기화
  _initializeVideo();
}
```

### 2. 권한 처리

**Web용 위치 권한:**
```dart
import 'package:geolocator/geolocator.dart';

if (kIsWeb) {
  // Web Geolocation API 사용
  LocationPermission permission = await Geolocator.requestPermission();
}
```

### 3. 성능 최적화

**Web 특화 설정:**
```dart
// pubspec.yaml에서 Web 전용 설정
flutter:
  web:
    bootstrapWorker: true
    
    # WASM 지원 (향후)
    wasm:
      auto-detect: true
```

---

## 📋 Web 개발 체크리스트

### 초기 설정
- [ ] Flutter Web 활성화
- [ ] Chrome/Edge에서 실행 테스트
- [ ] Hot Reload 작동 확인

### 기능 조정
- [ ] 비디오 배경 → 이미지 또는 조건부 처리
- [ ] 권한 요청 → Web API로 변경
- [ ] 파일 저장 → Blob/다운로드 API 사용
- [ ] 반응형 레이아웃 확인

### 빌드 & 배포
- [ ] Production 빌드 테스트
- [ ] 각 브라우저에서 테스트 (Chrome, Edge, Firefox, Safari)
- [ ] 모바일 브라우저에서 테스트
- [ ] 배포 플랫폼 선택 및 배포

---

## 🎯 개발 워크플로우

### 1. Web 브랜치에서 개발
```powershell
git checkout web-platform
flutter run -d chrome
# 코드 수정 및 테스트
```

### 2. 변경사항 커밋
```powershell
git add .
git commit -m "feat: Add web-specific feature"
git push origin web-platform
```

### 3. Master로 병합 (선택적)
```powershell
git checkout master
git merge web-platform
# 충돌 해결 후
git push origin master
```

---

## 🌐 배포 옵션

### Option 1: Firebase Hosting (권장)
```powershell
# Firebase CLI 설치
npm install -g firebase-tools

# 로그인
firebase login

# 초기화
firebase init hosting

# 배포
firebase deploy
```

### Option 2: GitHub Pages
```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages
on:
  push:
    branches: [ web-platform ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dewbye/build/web
```

### Option 3: Netlify
1. Netlify에 로그인
2. "New site from Git" 클릭
3. GitHub 저장소 연결
4. Build command: `cd dewbye && flutter build web --release`
5. Publish directory: `dewbye/build/web`

---

## 🔍 디버깅

### Chrome DevTools 사용
```powershell
flutter run -d chrome --web-renderer html
```

**또는**

```powershell
flutter run -d chrome --web-renderer canvaskit
```

### 브라우저 콘솔
- F12 → Console 탭
- Flutter 앱의 모든 `print()` 및 `debugPrint()` 출력 확인

---

## 📚 참고 자료

- [Flutter Web 공식 문서](https://flutter.dev/web)
- [Flutter Web 렌더링](https://docs.flutter.dev/platform-integration/web/renderers)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
- [PWA 설정](https://docs.flutter.dev/platform-integration/web/building)

---

## 🆚 브랜치 전환

### Master (모바일) → Web
```powershell
git checkout web-platform
```

### Web → Master (모바일)
```powershell
git checkout master
```

### 현재 브랜치 확인
```powershell
git branch
```

---

**현재 브랜치:** `web-platform`  
**생성일:** 2025-12-02  
**상태:** 초기 설정 완료


