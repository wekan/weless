@echo off
:menu
cls
echo 1) Install dependencies
echo 2) Build (client + PHP server)
echo 3) Exit
echo 4) Build HTML5 client only
echo 5) Build PHP backend only
echo 6) Build JS/serverless backend only
echo 7) Run locally: HTML5 client + PHP backend   (http://127.0.0.1:8080)
echo 8) Run locally: HTML5 client + JS backend     (http://127.0.0.1:8080)
set /p choice=Choose an option:

if "%choice%"=="1" goto install_dependencies
if "%choice%"=="2" goto build_project
if "%choice%"=="3" exit
if "%choice%"=="4" goto build_client
if "%choice%"=="5" goto build_php
if "%choice%"=="6" goto build_js
if "%choice%"=="7" goto run_php
if "%choice%"=="8" goto run_js

echo Invalid option. Please choose a valid option.
pause
goto menu

:install_dependencies
echo Installing dependencies...
choco install nodejs haxe lxi -y

echo Restoring pinned Haxe libraries (HaxeUI + tink stack) for Haxe 5...
npx lix download

pause
goto menu

:build_project
echo Building project (client + PHP server)...
npx haxe build.hxml
pause
goto menu

:build_client
echo Building HTML5 client only...
npx haxe build.client.hxml
pause
goto menu

:build_php
echo Building PHP backend only...
npx haxe build.server.php.hxml
pause
goto menu

:build_js
echo Building JS/serverless backend only...
npx haxe build.server.js.hxml
pause
goto menu

:run_php
echo Building client + PHP backend...
call npx haxe build.client.hxml || goto menu
call npx haxe build.server.php.hxml || goto menu
echo Serving on http://127.0.0.1:8080  (Ctrl+C to stop)
php -S 127.0.0.1:8080 tools/dev-router-php.php
goto menu

:run_js
echo Building client + JS dev server...
if not exist deploy\local mkdir deploy\local
call npx haxe build.client.hxml || goto menu
call npx haxe build.devserver.node.hxml || goto menu
echo Serving on http://127.0.0.1:8080  (Ctrl+C to stop)
set PORT=8080
set WWW_DIR=deploy/www/html5
node deploy/local/devserver.js
goto menu
