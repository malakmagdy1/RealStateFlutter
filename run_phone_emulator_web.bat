@echo off
title Run Flutter on 3 Devices
color 0B
echo ============================================
echo    Starting Flutter on 3 Devices
echo ============================================
echo.
echo Make sure the emulator is fully booted before continuing!
echo Press Ctrl+C if emulator is not ready yet.
echo.
pause
echo.

echo [1/3] Starting Flutter on Physical Phone (SM13)...
start "Flutter Phone" cmd /k "cd /d C:\Users\B-Smart\AndroidStudioProjects\real && flutter run -d RF8TB02VZVH"
echo - Phone app starting...
timeout /t 5 /nobreak
echo.

echo [2/3] Starting Flutter on Emulator...
echo Checking for running emulator...
adb devices
echo.
echo Starting app on emulator...
start "Flutter Emulator" cmd /k "cd /d C:\Users\B-Smart\AndroidStudioProjects\real && flutter run -d emulator"
echo - Emulator app starting...
timeout /t 5 /nobreak
echo.

echo [3/3] Starting Flutter Web (Port 8080)...
start "Flutter Web" cmd /k "cd /d C:\Users\B-Smart\AndroidStudioProjects\real && flutter run -d chrome --web-port 8080"
echo - Web app starting...
echo.

echo ============================================
echo    All Apps Starting!
echo ============================================
echo.
echo Three terminal windows opened:
echo 1. Flutter Phone - Physical Phone (SM13)
echo 2. Flutter Emulator - Android Emulator
echo 3. Flutter Web - Chrome Browser
echo.
echo To stop: Close each terminal window
echo ============================================
echo.
pause
