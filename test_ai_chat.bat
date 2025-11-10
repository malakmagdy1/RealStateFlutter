@echo off
echo.
echo ============================================
echo AI CHAT DEBUG TEST
echo ============================================
echo.
echo 1. Make sure the app is running on your device
echo 2. Open AI Chat in the app
echo 3. Send a message like: "show me apartments"
echo 4. Press any key here to capture the logs...
echo.
pause

echo.
echo Capturing last 100 lines of logs...
echo.
flutter logs --device-id="SM A137F" > ai_chat_logs.txt 2>&1 &
timeout /t 10 >nul
taskkill /IM flutter.exe /F >nul 2>&1

echo.
echo Logs saved to: ai_chat_logs.txt
echo.
echo Searching for AI CHAT activity...
findstr /I "AI.CHAT SEARCH.*API ChatBloc" ai_chat_logs.txt
echo.
echo ============================================
echo Check ai_chat_logs.txt for full details
echo ============================================
pause
