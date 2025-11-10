@echo off
title Device Status Checker
color 0E

:check
cls
echo ============================================
echo    Flutter Device Status Checker
echo ============================================
echo.
echo Checking connected devices...
echo.
echo ============================================
echo    CONNECTED DEVICES
echo ============================================
flutter devices
echo.
echo ============================================
echo    AVAILABLE EMULATORS
echo ============================================
flutter emulators
echo.
echo ============================================
echo    RUNNING PROCESSES
echo ============================================
echo.
echo Flutter processes:
tasklist | findstr "flutter.exe" 2>nul
if errorlevel 1 (
    echo   No Flutter processes running
) else (
    echo   Flutter is running!
)
echo.
echo Emulator processes:
tasklist | findstr "qemu-system" 2>nul
if errorlevel 1 (
    echo   No emulator processes running
) else (
    echo   Emulator is running!
)
echo.
echo ============================================
echo    PORT USAGE
echo ============================================
echo.
echo Port 8080 usage:
netstat -ano | findstr ":8080" 2>nul
if errorlevel 1 (
    echo   Port 8080 is FREE ✅
) else (
    echo   Port 8080 is IN USE ⚠️
)
echo.
echo ============================================
echo.
echo Options:
echo [1] Refresh Status
echo [2] Kill All Flutter Processes
echo [3] Kill Emulator
echo [4] Kill Port 8080 Process
echo [5] Exit
echo.
set /p choice="Choose option (1-5): "

if "%choice%"=="1" goto check
if "%choice%"=="2" goto kill_flutter
if "%choice%"=="3" goto kill_emulator
if "%choice%"=="4" goto kill_port
if "%choice%"=="5" goto end
goto check

:kill_flutter
echo.
echo Killing Flutter processes...
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM dart.exe 2>nul
echo Done!
timeout /t 2
goto check

:kill_emulator
echo.
echo Killing emulator...
taskkill /F /IM qemu-system-x86_64.exe 2>nul
taskkill /F /IM adb.exe 2>nul
echo Done!
timeout /t 2
goto check

:kill_port
echo.
echo Finding process on port 8080...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8080"') do (
    echo Killing PID: %%a
    taskkill /F /PID %%a 2>nul
)
echo Done!
timeout /t 2
goto check

:end
exit
