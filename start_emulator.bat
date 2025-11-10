@echo off
title Starting Android Emulator
color 0A
echo ============================================
echo    Starting Android Emulator
echo ============================================
echo.
echo Launching Pixel 7a emulator...
echo This may take 30-60 seconds to fully boot.
echo.
echo DO NOT CLOSE THIS WINDOW!
echo.
flutter emulators --launch Pixel_7a
echo.
echo If emulator window appeared, wait for it to finish booting.
echo Then run: run_phone_emulator_web.bat
echo.
pause
