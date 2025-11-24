@echo off
REM ═══════════════════════════════════════════════════════════════════════════
REM MT5 Pre-Flight Check - Quick Test Script
REM Windows 11 Version
REM ═══════════════════════════════════════════════════════════════════════════
REM
REM Einfaches Batch-Script zum Testen des Pre-Flight Checks
REM
REM Usage:
REM   1. login.ini auf Desktop oder in C:\MT5\ ablegen
REM   2. Doppelklick auf test-preflight.bat
REM
REM Optionen (in diesem Script anpassen):
REM   - WEBHOOK_URL: Webhook für Suffix-Notification
REM   - S3_BUCKET: S3 Bucket für servers.dat Upload
REM   - OUTPUT_JSON: Lokaler Output-Pfad
REM
REM Version: 1.0
REM Author: Stelona
REM ═══════════════════════════════════════════════════════════════════════════

setlocal

REM ═══════════════════════════════════════════════════════════════════════════
REM KONFIGURATION (hier anpassen!)
REM ═══════════════════════════════════════════════════════════════════════════

REM Webhook URL (optional - leer lassen wenn nicht benötigt)
set WEBHOOK_URL=

REM S3 Bucket (optional - leer lassen wenn nicht benötigt)
set S3_BUCKET=
set S3_PREFIX=test/
set S3_REGION=eu-central-1

REM JSON Output (optional - leer lassen für keinen Output)
set OUTPUT_JSON=%USERPROFILE%\Desktop\mt5_symbols.json

REM Config-Datei (automatisch gesucht wenn leer)
set CONFIG_PATH=

REM ═══════════════════════════════════════════════════════════════════════════
REM Ab hier nichts mehr ändern!
REM ═══════════════════════════════════════════════════════════════════════════

echo ═══════════════════════════════════════════════════════════════════════════
echo   MT5 Pre-Flight Check - Quick Test
echo   Version: 1.0 - Windows 11
echo ═══════════════════════════════════════════════════════════════════════════
echo.

REM Check Python
echo Pruefe Python Installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo ✗ ERROR: Python nicht gefunden!
    echo.
    echo   Bitte installieren Sie Python von: https://www.python.org/downloads/
    echo   WICHTIG: 'Add Python to PATH' aktivieren!
    echo.
    pause
    exit /b 1
)
echo ✓ Python gefunden
echo.

REM Check MetaTrader5 Package
echo Pruefe MetaTrader5 Python Paket...
python -c "import MetaTrader5" >nul 2>&1
if errorlevel 1 (
    echo ✗ ERROR: MetaTrader5 Paket nicht installiert!
    echo.
    echo   Installation starten? (J/N)
    set /p INSTALL_MT5=
    if /i "%INSTALL_MT5%"=="J" (
        echo   Installiere MetaTrader5 Paket...
        pip install MetaTrader5
        if errorlevel 1 (
            echo ✗ Installation fehlgeschlagen!
            pause
            exit /b 1
        )
        echo ✓ Installation erfolgreich
    ) else (
        echo   Abgebrochen.
        pause
        exit /b 1
    )
)
echo ✓ MetaTrader5 Paket installiert
echo.

REM Check MT5 Installation
echo Pruefe MT5 Installation...
if exist "C:\Program Files\MetaTrader 5\terminal64.exe" (
    echo ✓ MT5 gefunden: C:\Program Files\MetaTrader 5\
) else if exist "C:\Program Files (x86)\MetaTrader 5\terminal64.exe" (
    echo ✓ MT5 gefunden: C:\Program Files (x86)\MetaTrader 5\
) else (
    echo ⚠ WARNING: MT5 nicht an Standard-Pfad gefunden
    echo   MT5 könnte an anderem Ort installiert sein.
)
echo.

REM Find Config
if "%CONFIG_PATH%"=="" (
    echo Suche login.ini...
    if exist "%USERPROFILE%\Desktop\login.ini" (
        set CONFIG_PATH=%USERPROFILE%\Desktop\login.ini
        echo ✓ Gefunden: %USERPROFILE%\Desktop\login.ini
    ) else if exist "C:\MT5\login.ini" (
        set CONFIG_PATH=C:\MT5\login.ini
        echo ✓ Gefunden: C:\MT5\login.ini
    ) else if exist ".\login.ini" (
        set CONFIG_PATH=.\login.ini
        echo ✓ Gefunden: .\login.ini
    ) else (
        echo ✗ ERROR: login.ini nicht gefunden!
        echo.
        echo   Bitte erstellen Sie eine login.ini Datei:
        echo   Ort: Desktop oder C:\MT5\login.ini
        echo.
        echo   Inhalt:
        echo   login=12345678
        echo   password=IhrPasswort
        echo   broker=IC Markets
        echo.
        pause
        exit /b 1
    )
) else (
    if not exist "%CONFIG_PATH%" (
        echo ✗ ERROR: Config-Datei nicht gefunden: %CONFIG_PATH%
        pause
        exit /b 1
    )
    echo ✓ Config: %CONFIG_PATH%
)
echo.

REM Build Arguments
set ARGS=--config "%CONFIG_PATH%"

if not "%WEBHOOK_URL%"=="" (
    set ARGS=%ARGS% --webhook-url "%WEBHOOK_URL%"
    echo Webhook: %WEBHOOK_URL%
)

if not "%S3_BUCKET%"=="" (
    set ARGS=%ARGS% --s3-bucket "%S3_BUCKET%" --s3-prefix "%S3_PREFIX%" --s3-region "%S3_REGION%"
    echo S3 Bucket: %S3_BUCKET%
)

if not "%OUTPUT_JSON%"=="" (
    set ARGS=%ARGS% --output-json "%OUTPUT_JSON%"
    echo JSON Output: %OUTPUT_JSON%
)

echo.
echo ═══════════════════════════════════════════════════════════════════════════
echo   Pre-Flight Check wird gestartet...
echo ═══════════════════════════════════════════════════════════════════════════
echo.

REM Run Python Script
python "%~dp0mt5_preflight_check_windows.py" %ARGS%

if errorlevel 1 (
    echo.
    echo ═══════════════════════════════════════════════════════════════════════════
    echo   ✗ PRE-FLIGHT CHECK FEHLGESCHLAGEN
    echo ═══════════════════════════════════════════════════════════════════════════
    echo.
    pause
    exit /b 1
)

echo.
echo ═══════════════════════════════════════════════════════════════════════════
echo   ✓ PRE-FLIGHT CHECK ERFOLGREICH!
echo ═══════════════════════════════════════════════════════════════════════════
echo.

if not "%OUTPUT_JSON%"=="" (
    if exist "%OUTPUT_JSON%" (
        echo Ergebnis gespeichert: %OUTPUT_JSON%
        echo.
        echo JSON-Datei oeffnen? (J/N)
        set /p OPEN_JSON=
        if /i "%OPEN_JSON%"=="J" (
            start notepad "%OUTPUT_JSON%"
        )
    )
)

echo.
pause
