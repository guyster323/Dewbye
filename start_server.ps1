# Dewbye Web App - PowerShell Local Server
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Dewbye Web App - Local Server" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting local web server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "After server starts, open your browser and go to:" -ForegroundColor Green
Write-Host "  http://localhost:8000" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Try to start Python HTTP server
try {
    python -m http.server 8000
} catch {
    Write-Host "Python is not installed." -ForegroundColor Red
    Write-Host "Please install Python from: https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: You can use any web server to serve this folder." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
}

