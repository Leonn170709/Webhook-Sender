@echo off
title Recon Sender
chcp 65001 >nul
color 0A

:: ASCII Banner
echo.
echo   __        __   _     _                 _
echo    \ \      / /__^| ^|__ ^| ^|__   ___   ___ ^| ^| _____ _ __   __ _ _ __ ___
echo     \ \ /\ / / _ \ '_ \^| '_ \ / _ \ / _ \^| ^|/ / __^| '_ \ / _` ^| '_ ` _ \
echo      \ V  V /  __/ ^|_) ^| ^| ^| ^| (_) ^| (_) ^|   <\__ \ ^|_) ^| (_^| ^| ^| ^| ^| ^| ^|
echo       \_/\_/ \___^|_.__/^|_^| ^|_^|\___/ \___/^|_^|\_\___/ .__/ \__,_^|_^| ^|_^| ^|_^|
echo                                                   ^|_^|
echo.
echo ================================================
echo            Welcome to Webhook Sender 🚀
echo ================================================
echo.

:: Ask for multiple webhooks
set "webhooks="
set /p multi="Do you want to enter multiple webhooks? (y/n): "

if /i "%multi%"=="y" (
    echo Enter your webhooks (one per line).
    echo Type DONE when finished:
    :gethooks
    set /p hook=Webhook:
    if /i "%hook%"=="done" goto afterhooks
    if "%hook%"=="" goto afterhooks
    set "webhooks=!webhooks! %hook%"
    goto gethooks
) else (
    set /p hook=Webhook:
    set "webhooks=%hook%"
)

:afterhooks
:: Ask for message
set /p message=Message:

:: Ask for how many times
set /p count=How often to send:

:: Ask for delay
set /p delay=Delay in seconds:

echo.
echo Starting to send messages...
timeout /t 1 >nul

:: Enable delayed expansion for loop vars
setlocal enabledelayedexpansion

for /l %%i in (1,1,%count%) do (
    cls
    echo --------------------------------------------------
    echo Sending message %%i of %count%
    echo --------------------------------------------------
    for %%w in (%webhooks%) do (
        curl -s -X POST -H "Content-Type: application/json" -d "{\"content\": \"%message%\"}" "%%w" >nul
    )
    echo [✓] Message sent!
    timeout /t %delay% >nul
)

echo.
echo All messages sent successfully! 🎉
pause
