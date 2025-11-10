@echo off
title Flutter 3 Devices Launcher
color 0A
cls
echo ============================================
echo    Flutter 3-Device Launcher
echo ============================================
echo.
echo This will launch apps on:
echo [1] Physical Phone: SM A137F
echo [2] Android Emulator: Pixel 7a
echo [3] Web Browser: Chrome (port 8080)
echo.
echo ============================================
echo.
echo STEP 1: Starting Emulator (if not running)
echo ============================================
echo.

REM Check if emulator is already running
adb devices | findstr "emulator" >nul
if %errorlevel% equ 0 (
    echo Emulator is already running! ✓
) else (
    echo Starting emulator... Please wait 30 seconds.
    start /MIN "" flutter emulators --launch Pixel_7a
    echo Waiting for emulator to boot...
    timeout /t 30 /nobreak >nul
)

echo.
echo ============================================
echo STEP 2: Launching Apps on All Devices
echo ============================================
echo.

echo [1/3] Launching on Physical Phone...
start "Phone - SM A137F" cmd /k "title Phone-SM13 && cd /d C:\Users\B-Smart\AndroidStudioProjects\real && flutter run -d RF8TB02VZVH"
timeout /t 3 /nobreak >nul

echo [2/3] Launching on Emulator...
start "Emulator - Pixel 7a" cmd /k "title Emulator && cd /d C:\Users\B-Smart\AndroidStudioProjects\real && flutter run -d emulator-5554"
timeout /t 3 /nobreak >nul

echo [3/3] Launching on Web Browser...
start "Web - Chrome" cmd /k "title Web-Chrome && cd /d C:\Users\B-Smart\AndroidStudioProjects\real && flutter run -d chrome --web-port 8080"

echo.
echo ============================================
echo    ALL APPS LAUNCHING! ✓
echo ============================================
echo.
echo Three terminal windows will open:
echo - Phone-SM13 (Physical phone app)
echo - Emulator (Emulator app)
echo - Web-Chrome (Browser app on port 8080)
echo.
echo Wait 1-2 minutes for all apps to fully load.
echo.
echo To stop: Close each terminal window
echo Or press 'q' in each terminal
echo.
echo ============================================
pause
