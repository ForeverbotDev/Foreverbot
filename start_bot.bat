@echo off
setlocal enabledelayedexpansion
title Foreverbot - World of Warcraft: Forever Discord Assistant

:: 0. Check if accidentally launched via Wine / Proton on Linux
if defined WINEUSERNAME goto WINE_DETECTED
if defined WINEPREFIX goto WINE_DETECTED
ver | find /i "wine" >nul
if %ERRORLEVEL% EQU 0 goto WINE_DETECTED
goto WINDOWS_NATIVE

:WINE_DETECTED
echo ==========================================================
echo   🐧 Linux / Proton / Wine Environment Detected!
echo ==========================================================
echo You are running on Linux! You do NOT need Wine or Proton.
echo Foreverbot runs natively and much faster directly on Linux.
echo.
echo 👉 Please close this window and double-click: start_bot.sh
echo    (or open your terminal and run: ./start_bot.sh)
echo ==========================================================
pause
exit /b 0

:WINDOWS_NATIVE
echo ==========================================================
echo   ⚔️  Starting Foreverbot (WoW: Forever Companion)...
echo   🛑 Press Ctrl+C at any time to stop the bot.
echo ==========================================================

:: 1. Check Python installation
where py >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    set PY_CMD=py -3
) else (
    where python >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        set PY_CMD=python
    ) else (
        echo [ERROR] Python 3.10+ was not found on your Windows PC!
        echo Opening Python download page in your browser...
        start https://www.python.org/downloads/
        echo.
        echo ⚠️  IMPORTANT: During installation, CHECK the box:
        echo     [X] "Add Python to PATH" (at the bottom of the installer window)
        echo.
        echo Once installed, double-click start_bot.bat again!
        pause
        exit /b 1
    )
)

:: 2. Create virtual environment if missing
if not exist ".venv\Scripts\python.exe" (
    echo [INFO] Creating Python virtual environment (.venv)...
    %PY_CMD% -m venv .venv
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
    echo [INFO] Installing dependencies from requirements.txt...
    .venv\Scripts\python.exe -m pip install --upgrade pip -q
    .venv\Scripts\python.exe -m pip install -r requirements.txt
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to install requirements.
        pause
        exit /b 1
    )
)

:: 3. Check for .env file
if not exist ".env" (
    echo [INFO] Creating .env file from .env.example...
    copy .env.example .env >nul
    echo.
    echo ⚠️  Created .env! Opening in Notepad...
    echo 👉 Paste your DISCORD_BOT_TOKEN next to DISCORD_BOT_TOKEN=, save, and close Notepad.
    echo.
    notepad .env
    pause
)

:: Check if token is still placeholder
findstr /C:"YOUR_DISCORD_BOT_TOKEN_HERE" .env >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================================
    echo ⚠️  DISCORD_BOT_TOKEN is still not configured in .env!
    echo 👉 Opening .env in Notepad...
    echo 👉 Paste your bot token next to DISCORD_BOT_TOKEN= and save.
    echo ==========================================================
    notepad .env
    pause
    exit /b 1
)

:: 4. Launch Foreverbot
echo [INFO] Launching Foreverbot...
.venv\Scripts\python.exe bot.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Foreverbot stopped with an error code.
    pause
)
