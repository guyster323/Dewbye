@echo off
echo ========================================
echo Dewbye - GitHub Pages 배포용 빌드
echo ========================================
echo.

echo [1/4] Flutter 패키지 설치 중...
call flutter pub get
if %errorlevel% neq 0 (
    echo Flutter 패키지 설치 실패!
    pause
    exit /b 1
)
echo.

echo [2/4] Web 지원 활성화...
flutter config --enable-web
echo.

echo [3/4] GitHub Pages용 Web 빌드 중...
echo (--base-href=/Dewbye/ 옵션으로 빌드)
flutter build web --release --base-href=/Dewbye/
if %errorlevel% neq 0 (
    echo Web 빌드 실패!
    pause
    exit /b 1
)
echo.

echo [4/4] docs 폴더로 복사 중...
if exist "..\docs" rmdir /s /q "..\docs"
mkdir "..\docs"
xcopy "build\web\*" "..\docs\" /E /Y
echo.

echo ========================================
echo 빌드 완료!
echo.
echo 빌드 파일 위치: build\web\
echo 배포 파일 위치: ..\docs\
echo.
echo 다음 단계:
echo 1. Git에서 docs 폴더를 커밋하세요
echo 2. GitHub 저장소 설정에서 Pages 소스를 
echo    main 브랜치의 /docs 폴더로 설정하세요
echo ========================================
pause

