@echo off
echo ========================================
echo Dewbye 앱 빌드 및 배포 스크립트
echo ========================================
echo.

echo [1/5] Flutter 패키지 설치 중...
call flutter pub get
if %errorlevel% neq 0 (
    echo Flutter 패키지 설치 실패!
    pause
    exit /b 1
)
echo.

echo [2/5] 앱 아이콘 생성 중...
call flutter pub run flutter_launcher_icons
if %errorlevel% neq 0 (
    echo 앱 아이콘 생성 실패! 계속 진행합니다...
)
echo.

echo [3/5] Flutter 코드 정리 중...
call flutter clean
call flutter pub get
echo.

echo [4/5] APK 빌드 중 (Release 모드)...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo APK 빌드 실패!
    pause
    exit /b 1
)
echo.

echo [5/5] 연결된 Android 기기에 설치 중...
call flutter install
if %errorlevel% neq 0 (
    echo 설치 실패! Android 기기가 연결되어 있는지 확인하세요.
    echo USB 디버깅이 활성화되어 있는지 확인하세요.
    pause
    exit /b 1
)
echo.

echo ========================================
echo 빌드 및 배포 완료!
echo APK 파일 위치: build\app\outputs\flutter-apk\app-release.apk
echo ========================================
pause


