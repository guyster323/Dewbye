@echo off
echo ========================================
echo Dewbye Web Platform - Build and Run
echo ========================================
echo.

echo [1/3] Checking Flutter Web support...
flutter config --enable-web
echo.

echo [2/3] Building for Web (Release)...
flutter build web --release
if %errorlevel% neq 0 (
    echo Web build failed!
    pause
    exit /b 1
)
echo.

echo [3/3] Starting local server...
echo.
echo Web app is running at: http://localhost:8000
echo Press Ctrl+C to stop the server
echo.
cd build\web
python -m http.server 8000

pause


