@echo off
title Run Flutter on 3 Devices
color 0A
echo ============================================
echo    Running Flutter on 3 Devices
echo ============================================
echo.
echo Devices:
echo [1] Physical Phone: SM A137F (RF8TB02VZVH)
echo [2] Emulator: Pixel 7a
echo [3] Web Browser: Chrome (Port 8080)
echo.
echo ============================================
echo.

REM Step 1: Launch emulator in background
echo [Step 1/4] Starting Android Emulator (Pixel 7a)...
start "Android Emulator" cmd /c "flutter emulators --launch Pixel_7a"
echo - Emulator starting in background...
echo - Waiting 15 seconds for emulator to boot...
timeout /t 15 /nobreak >nul
echo.

REM Step 2: Start Flutter on Physical Phone
echo [Step 2/4] Starting Flutter on Physical Phone (SM13)...
start "Flutter - Physical Phone" cmd /k "flutter run -d RF8TB02VZVH"
echo - Physical phone app starting...
timeout /t 3 /nobreak >nul
echo.

REM Step 3: Start Flutter on Emulator
echo [Step 3/4] Starting Flutter on Emulator (Pixel 7a)...
echo - Waiting 10 more seconds for emulator to be fully ready...
timeout /t 10 /nobreak >nul
start "Flutter - Emulator" cmd /k "flutter run -d emulator-5554"
echo - Emulator app starting...
timeout /t 3 /nobreak >nul
echo.

REM Step 4: Start Flutter on Web
echo [Step 4/4] Starting Flutter Web (Port 8080)...
start "Flutter - Web" cmd /k "flutter run -d chrome --web-port 8080"
echo - Web app starting...
echo.

echo ============================================
echo    All 3 Apps Are Starting!
echo ============================================
echo.
echo - Physical Phone: SM A137F (Check your phone)
echo - Emulator: Pixel 7a (Check Android Emulator window)
echo - Web: http://localhost:8080 (Chrome will open)
echo.
echo Three terminal windows will open:
echo 1. Flutter - Physical Phone
echo 2. Flutter - Emulator
echo 3. Flutter - Web
echo.
echo To stop apps: Close each terminal window
echo Or press Ctrl+C in each terminal
echo.
echo ============================================
pause
