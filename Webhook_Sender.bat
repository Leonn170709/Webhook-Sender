@echo off
setlocal EnableDelayedExpansion
title Webhook Sender

REM ================= COLORS =================
for /f %%A in ('echo prompt $E^| cmd') do set "ESC=%%A"

set CYAN=%ESC%[36m
set GREEN=%ESC%[32m
set YELLOW=%ESC%[33m
set RED=%ESC%[31m
set RESET=%ESC%[0m

REM ================= STATE =================
set sent=0
set failed=0
set infinite=false
set last_error=None

cls
echo %CYAN%
echo  __        __   _     _                 _
echo  \ \      / /__| |__ | |__   ___   ___ | | _____ _ __
echo   \ \ /\ / / _ \ '_ \| '_ \ / _ \ / _ \| |/ / __| '_ \
echo    \ V  V /  __/ |_) | | | | (_) | (_) |   <\__ \ |_) |
echo     \_/\_/ \___|_.__/|_| |_|\___/ \___/|_|\_\___/ .__/
echo                                                 |_|
echo %RESET%
echo %YELLOW%Welcome to Webhook Sender 🚀%RESET%
echo.

REM ================= WEBHOOKS =================
set /p multi=Use multiple webhooks? (y/n): 
set webhooks=

if /i "%multi%"=="y" (
    echo Enter webhooks (type DONE to finish):
    :addhook
    set /p wh=Webhook: 
    if /i "%wh%"=="DONE" goto hooksdone
    set webhooks=%webhooks% "%wh%"
    goto addhook
) else (
    set /p wh=Webhook: 
    set webhooks="%wh%"
)

:hooksdone

REM ================= MESSAGE =================
set /p message=Message: 

REM ================= COUNT =================
set /p count=How many times to send? (0 = infinite): 
if "%count%"=="0" set infinite=true

REM ================= DELAY =================
echo.
echo Choose delay:
echo  1) 0.4 seconds (best for Discord)
echo  2) 1 second
echo  3) 2 seconds
echo  4) Custom

set /p delaychoice=Select [1-4]: 

if "%delaychoice%"=="1" set delay=0.4
if "%delaychoice%"=="2" set delay=1
if "%delaychoice%"=="3" set delay=2
if "%delaychoice%"=="4" set /p delay=Enter delay in seconds: 
if not defined delay set delay=0.4

echo.
echo %GREEN%Starting...%RESET%
timeout /t 1 >nul

REM ================= MAIN LOOP =================
:loop
set /a sent+=1
set last_error=None
set had_error=false

for %%W in (%webhooks%) do (
    powershell -Command ^
      "try { ^
        $r = Invoke-RestMethod -Uri %%W -Method Post -ContentType 'application/json' -Body '{\"content\":\"%message%\"}'; ^
        exit 0 ^
      } catch { ^
        Write-Output $_.Exception.Message; ^
        exit 1 ^
      }" > error.tmp 2>&1

    if errorlevel 1 (
        set /a failed+=1
        set had_error=true

