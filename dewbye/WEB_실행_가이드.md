# Dewbye Web 앱 실행 가이드

## ✅ Web 앱 실행 성공!

**브랜치:** web-platform  
**실행 상태:** ✅ Chrome에서 정상 실행 중  
**포트:** http://localhost:51940 (자동 할당)

---

## 🎉 성공한 내용

### 1. Web 앱 실행
- ✅ Chrome 브라우저에서 정상 실행
- ✅ Intro Screen 표시
- ✅ 그라데이션 배경 (Web용)
- ✅ Hot Reload 지원

### 2. Web 권한 처리
- ✅ permission_handler 오류 해결
- ✅ Web에서는 자동 권한 승인
- ✅ 브라우저 Geolocation API 사용

### 3. Web 최적화
- ✅ `kIsWeb` 조건부 처리
- ✅ 비디오 → 그라데이션 배경
- ✅ Storage permission 우회
- ✅ Hive database 정상 작동

---

## 🚀 실행 방법

### 방법 1: 수동 실행 (권장)

```powershell
# Web 브랜치로 전환
git checkout web-platform

# Chrome에서 실행
cd dewbye
flutter run -d chrome
```

### 방법 2: 스크립트 사용

```powershell
cd dewbye
.\web_dev_run.bat
```

### 방법 3: Edge 사용

```powershell
flutter run -d edge
```

---

## 💻 실행 중 명령어

앱 실행 중 터미널에서 사용 가능한 명령:

| 키 | 기능 |
|----|------|
| `r` | **Hot Reload** - 코드 변경사항 즉시 반영 |
| `R` | **Hot Restart** - 앱 완전 재시작 |
| `h` | 도움말 - 모든 명령어 표시 |
| `d` | Detach - Flutter 종료, 앱은 계속 실행 |
| `c` | Clear - 화면 정리 |
| `q` | **Quit** - 앱 종료 |

---

## 🔧 개발 워크플로우

### 1. 코드 수정
- VS Code 또는 Cursor에서 코드 수정
- 파일 저장 (Ctrl + S)

### 2. 즉시 확인
- 터미널에서 `r` 입력 (Hot Reload)
- 또는 자동 Hot Reload 대기 (파일 저장 시)
- Chrome에서 즉시 변경사항 확인!

### 3. 디버깅
- Chrome에서 F12 → Console 탭
- Flutter DevTools 사용:
  ```
  http://127.0.0.1:51940/...=/devtools/
  ```

---

## 📊 Web vs Mobile 차이점

### Web 플랫폼 (web-platform 브랜치)

**배경:**
- ❌ 비디오 재생 안 함 (Intro.mp4 사용 안 함)
- ✅ 그라데이션 배경 (성능 최적화)

```dart
if (kIsWeb) {
  // 그라데이션 배경
  Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [...]),
    ),
  )
}
```

**권한:**
- ❌ permission_handler 사용 안 함
- ✅ 브라우저 자체 권한 사용
- ✅ Web Storage 자동 사용

**위치:**
- ✅ Geolocator 사용 (브라우저 API)
- ✅ 브라우저가 자동으로 권한 요청

---

## 🌐 Web 앱 접근

### 로컬 개발
```
http://localhost:51940 (포트는 자동 할당)
```

### DevTools
```
http://127.0.0.1:51940/_sriZsgqbgM=/devtools/
```

---

## ✨ Web 앱 특징

### 장점
1. **즉시 실행** - 빌드 불필요, 브라우저만 있으면 됨
2. **Hot Reload** - 코드 수정 즉시 반영
3. **디버깅 용이** - Chrome DevTools 사용
4. **네트워크 제한 없음** - Gradle 문제 없음
5. **크로스 플랫폼** - 모든 OS에서 접근 가능
6. **쉬운 공유** - URL만으로 공유

### 현재 실행 상태
```
✅ Chrome 브라우저에서 실행 중
✅ Hot Reload 준비 완료
✅ Hive database 정상 작동
✅ 위치 서비스 준비 완료
⚠️ 위치 가져오기 실패 (브라우저 권한 필요)
```

---

## 🔧 문제 해결

### 위치 가져오기 실패
**증상:** "Unexpected null value" 오류

**해결:**
1. Chrome에서 위치 권한 허용
   - 주소창 왼쪽 자물쇠 아이콘 클릭
   - "위치" → "허용"
2. 또는 Chrome 설정:
   - chrome://settings/content/location
   - localhost 허용

### 앱이 안 열림
1. Chrome이 자동으로 열렸는지 확인
2. 수동으로 열기:
   ```
   http://localhost:51940
   ```
3. 포트 번호는 터미널에서 확인

### Hot Reload 안 됨
- 터미널에 `r` 입력
- 또는 파일 저장 후 자동 Reload 대기

---

## 📝 개발 팁

### 반응형 디자인 테스트
Chrome DevTools에서:
1. F12 → Device Toolbar (Ctrl + Shift + M)
2. 다양한 화면 크기 테스트
   - 모바일 (375x667)
   - 태블릿 (768x1024)
   - 데스크톱 (1920x1080)

### 성능 프로파일링
1. Flutter DevTools 열기
2. Performance 탭
3. 프레임 렌더링 시간 확인

### 네트워크 모니터링
Chrome DevTools Network 탭:
- API 호출 확인
- 날씨 데이터 가져오기 확인
- 캐시 동작 확인

---

## 🎯 다음 단계

### 개발
1. Chrome에서 앱 확인
2. 필요한 기능 수정
3. Hot Reload로 즉시 테스트
4. 만족하면 커밋

### 배포
1. Production 빌드:
   ```powershell
   flutter build web --release
   ```

2. 결과물:
   ```
   dewbye/build/web/
   ```

3. 웹 서버에 업로드:
   - Firebase Hosting
   - Netlify
   - GitHub Pages
   - 회사 웹 서버

---

## 📌 현재 상태

**실행 중:** ✅ Chrome (포트: 51940)  
**Hot Reload:** ✅ 준비 완료  
**Debug Service:** ✅ 활성화  
**DevTools:** ✅ 사용 가능

**앱 URL:** http://localhost:51940 (Chrome 자동 열림)

---

**Chrome 브라우저에서 Dewbye 앱을 확인해보세요!** 🎊


