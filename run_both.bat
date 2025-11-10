@echo off
echo Starting Flutter Web and Mobile...
echo.

REM Start web in background
echo [1/2] Starting Flutter Web on port 8080...
start "Flutter Web" cmd /k "flutter run -d chrome --web-port 8080"
timeout /t 5

REM Start mobile emulator
echo [2/2] Starting Flutter Mobile on Emulator...
start "Flutter Mobile" cmd /k "flutter run -d emulator-5554"

echo.
echo Both apps are starting...
echo - Web: http://localhost:8080
echo - Mobile: Check Android Emulator
echo.
echo Close the terminal windows to stop the apps.
pause
