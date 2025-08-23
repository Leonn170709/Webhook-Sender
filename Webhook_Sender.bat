@echo off
:banner
cls
echo.
echo """""""""""""""""""""""""""""""""""""""""""""""
echo " __        __   _     _                 _    "
echo " \ \      / /__| |__ | |__   ___   ___ | | __"
echo "  \ \ /\ / / _ \ '_ \| '_ \ / _ \ / _ \| |/ /"
echo "   \ V  V /  __/ |_) | | | | (_) | (_) |   < "
echo "  __\_/\_/ \___|_.__/|_| |_|\___/ \___/|_|\_\"
echo " / ___|  ___ _ __   __| | ___ _ __           "
echo " \___ \ / _ \ '_ \ / _` |/ _ \ '__|          "
echo "  ___) |  __/ | | | (_| |  __/ |             "
echo " |____/ \___|_| |_|\__,_|\___|_|             "
echo """""""""""""""""""""""""""""""""""""""""""""""
echo.
echo  -----------------------------------------------------------------------------------------
echo                           Simple Webhook Sender
echo  -----------------------------------------------------------------------------------------
echo.


::  User Input

set /p webhook=Webhook URL : 
set /p message=Message     : 
set /p count=Repeat times  : 
set /p delay=Delay (sec)   : 

cls
echo.
echo  Sending "%message%" %count% times with %delay% seconds delay...
echo  -----------------------------------------------------------------------------------------
echo.

::  Sending Loop

for /l %%i in (1,1,%count%) do (
    echo  Sending message %%i of %count%...
    curl -s -X POST -H "Content-type: application/json" --data "{\"content\": \"%message%\"}" %webhook%
    if %%i lss %count% (
        timeout /t %delay% >nul
    )
)

echo.
echo  All %count% messages have been sent successfully.
echo.
pause
