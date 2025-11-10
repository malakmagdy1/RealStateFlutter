@echo off
title Run Flutter - Manual Control
color 0B

:menu
cls
echo ============================================
echo    Flutter Multi-Device Launcher
echo ============================================
echo.
echo Choose an option:
echo.
echo [1] Launch Emulator ONLY (Pixel 7a)
echo [2] Run on Physical Phone (SM13 - RF8TB02VZVH)
echo [3] Run on Emulator (after it's booted)
echo [4] Run on Web (Chrome Port 8080)
echo [5] Run on ALL 3 DEVICES (Auto)
echo [6] Show Connected Devices
echo [7] Exit
echo.
echo ============================================
set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto launch_emulator
if "%choice%"=="2" goto run_phone
if "%choice%"=="3" goto run_emulator
if "%choice%"=="4" goto run_web
if "%choice%"=="5" goto run_all
if "%choice%"=="6" goto show_devices
if "%choice%"=="7" goto end
goto menu

:launch_emulator
echo.
echo Starting Pixel 7a Emulator...
start "Android Emulator" cmd /c "flutter emulators --launch Pixel_7a"
echo.
echo Emulator is starting...
echo Wait 20-30 seconds for it to fully boot, then choose option 3.
echo.
pause
goto menu

:run_phone
echo.
echo Starting Flutter on Physical Phone (SM13)...
start "Flutter - Physical Phone" cmd /k "flutter run -d RF8TB02VZVH"
echo.
echo App launching on your phone...
pause
goto menu

:run_emulator
echo.
echo Starting Flutter on Emulator...
echo Make sure emulator is fully booted!
timeout /t 3
start "Flutter - Emulator" cmd /k "flutter run -d emulator-5554"
echo.
echo App launching on emulator...
pause
goto menu

:run_web
echo.
echo Starting Flutter Web on Port 8080...
start "Flutter - Web" cmd /k "flutter run -d chrome --web-port 8080"
echo.
echo Web app launching at http://localhost:8080
pause
goto menu

:run_all
echo.
echo ============================================
echo    Launching ALL 3 DEVICES
echo ============================================
echo.
echo [1/4] Starting Emulator...
start "Android Emulator" cmd /c "flutter emulators --launch Pixel_7a"
echo Waiting 20 seconds for emulator to boot...
timeout /t 20 /nobreak
echo.
echo [2/4] Starting Physical Phone App...
start "Flutter - Physical Phone" cmd /k "flutter run -d RF8TB02VZVH"
timeout /t 3
echo.
echo [3/4] Starting Emulator App...
start "Flutter - Emulator" cmd /k "flutter run -d emulator-5554"
timeout /t 3
echo.
echo [4/4] Starting Web App...
start "Flutter - Web" cmd /k "flutter run -d chrome --web-port 8080"
echo.
echo ============================================
echo All devices launching!
echo Check: Phone, Emulator window, and Chrome
echo ============================================
pause
goto menu

:show_devices
echo.
echo ============================================
echo    Connected Devices
echo ============================================
flutter devices
echo.
echo ============================================
echo    Available Emulators
echo ============================================
flutter emulators
echo.
pause
goto menu

:end
echo.
echo Exiting...
exit
