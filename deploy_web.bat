@echo off
echo ====================================
echo Building Flutter Web App
echo ====================================
call flutter build web --release

echo.
echo ====================================
echo Creating Archive
echo ====================================
cd build\web
tar -czf web_build.tar.gz *
cd ..\..

echo.
echo ====================================
echo Uploading to Server
echo ====================================
scp -o StrictHostKeyChecking=no build\web\web_build.tar.gz root@31.97.46.103:/tmp/

echo.
echo ====================================
echo Deploying on Server
echo ====================================
ssh -o StrictHostKeyChecking=no root@31.97.46.103 "cd /var/www/aqar.bdcbiz.com && rm -rf * && tar -xzf /tmp/web_build.tar.gz && cp firebase-messaging-sw.js /var/www/realestate/public/ && rm /tmp/web_build.tar.gz && nginx -t && systemctl reload nginx"

echo.
echo ====================================
echo Deployment Complete!
echo ====================================
echo Service worker deployed to: https://aqar.bdcbiz.com/firebase-messaging-sw.js
echo.

pause
