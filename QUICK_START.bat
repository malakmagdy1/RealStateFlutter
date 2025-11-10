@echo off
title Quick Start - 3 Devices
color 0E
cls
echo ========================================
echo   QUICK START - All 3 Devices
echo ========================================
echo.
echo Starting apps on all 3 devices NOW...
echo (Assumes emulator is already running)
echo.

cd /d C:\Users\B-Smart\AndroidStudioProjects\real

echo [1/3] Phone...
start "Phone" cmd /k "flutter run -d RF8TB02VZVH"

echo [2/3] Emulator...
start "Emulator" cmd /k "flutter run -d emulator-5554"

echo [3/3] Web...
start "Web" cmd /k "flutter run -d chrome --web-port 8080"

echo.
echo ========================================
echo Done! Check the 3 terminal windows.
echo ========================================
echo.
pause
