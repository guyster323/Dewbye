@echo off
echo ============================================
echo   Dewbye Web App - Local Server
echo ============================================
echo.
echo Starting local web server...
echo.
echo After server starts, open your browser and go to:
echo   http://localhost:8000
echo.
echo Press Ctrl+C to stop the server.
echo ============================================
echo.

REM Try Python 3 first
python -m http.server 8000 2>nul
if %ERRORLEVEL% neq 0 (
    REM Try Python 2
    python -m SimpleHTTPServer 8000 2>nul
    if %ERRORLEVEL% neq 0 (
        echo.
        echo Python is not installed. Please install Python from:
        echo   https://www.python.org/downloads/
        echo.
        echo Or use any other web server to serve this folder.
        pause
    )
)

