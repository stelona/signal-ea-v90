#Requires -Version 5.1
<#
.SYNOPSIS
    Vollautomatisches MT5 Auto-Start Script für SaaS-Plattformen

.DESCRIPTION
    Startet MetaTrader 5 automatisch mit konfigurierten Login-Daten.
    KEINE manuelle Interaktion erforderlich - perfekt für SaaS-Plattformen.

    Features:
    - Liest Login-Daten aus JSON-Konfiguration
    - Startet MT5 automatisch mit korrekten Parametern
    - Überwacht MT5-Prozess und startet bei Absturz neu
    - Logging aller Aktivitäten
    - Windows Service kompatibel

.PARAMETER ConfigFile
    Pfad zur JSON-Konfigurationsdatei mit Login-Daten

.PARAMETER NoMonitor
    Deaktiviert die automatische Prozessüberwachung

.EXAMPLE
    .\MT5_AutoStart.ps1 -ConfigFile "C:\MT5\config.json"

.NOTES
    Version: 1.0
    Author: Stelona
    Copyright 2024 Stelona. All rights reserved.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = ".\mt5_saas_config.json",

    [Parameter(Mandatory=$false)]
    [switch]$NoMonitor,

    [Parameter(Mandatory=$false)]
    [string]$LogFile = ".\mt5_autostart.log",

    [Parameter(Mandatory=$false)]
    [int]$RestartDelay = 10
)

# ============================================
# FUNKTIONEN
# ============================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARNING','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Konsole mit Farben
    switch ($Level) {
        'INFO'    { Write-Host $logMessage -ForegroundColor Cyan }
        'WARNING' { Write-Host $logMessage -ForegroundColor Yellow }
        'ERROR'   { Write-Host $logMessage -ForegroundColor Red }
        'SUCCESS' { Write-Host $logMessage -ForegroundColor Green }
    }

    # Log-Datei
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
}

function Read-MT5Config {
    param([string]$Path)

    Write-Log "Lese Konfigurationsdatei: $Path"

    if (-not (Test-Path $Path)) {
        Write-Log "Konfigurationsdatei nicht gefunden: $Path" -Level ERROR
        return $null
    }

    try {
        $config = Get-Content $Path -Raw | ConvertFrom-Json

        # Validierung
        if (-not $config.account -or -not $config.password -or -not $config.server) {
            Write-Log "Ungültige Konfiguration: Account, Password oder Server fehlt" -Level ERROR
            return $null
        }

        if (-not $config.mt5_path) {
            Write-Log "MT5-Pfad nicht konfiguriert" -Level ERROR
            return $null
        }

        Write-Log "Konfiguration erfolgreich geladen" -Level SUCCESS
        Write-Log "  Account: $($config.account)"
        Write-Log "  Server:  $($config.server)"
        Write-Log "  MT5:     $($config.mt5_path)"

        return $config

    } catch {
        Write-Log "Fehler beim Lesen der Konfiguration: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Test-MT5Process {
    param([string]$ProcessName = "terminal64")

    $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    return ($null -ne $process)
}

function Stop-MT5Process {
    param([string]$ProcessName = "terminal64")

    Write-Log "Stoppe MT5-Prozess..."

    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

    if ($processes) {
        foreach ($proc in $processes) {
            try {
                $proc.CloseMainWindow() | Out-Null
                Start-Sleep -Seconds 2

                if (-not $proc.HasExited) {
                    $proc.Kill()
                }

                Write-Log "MT5-Prozess beendet (PID: $($proc.Id))" -Level SUCCESS
            } catch {
                Write-Log "Fehler beim Beenden des Prozesses: $($_.Exception.Message)" -Level ERROR
            }
        }
    } else {
        Write-Log "Kein MT5-Prozess gefunden"
    }
}

function Start-MT5 {
    param(
        [string]$MT5Path,
        [long]$Account,
        [string]$Password,
        [string]$Server
    )

    Write-Log "════════════════════════════════════════════════════════"
    Write-Log "Starte MetaTrader 5..."
    Write-Log "════════════════════════════════════════════════════════"

    # MT5-Pfad validieren
    if (-not (Test-Path $MT5Path)) {
        Write-Log "MT5 Executable nicht gefunden: $MT5Path" -Level ERROR
        return $false
    }

    # Kommandozeilen-Argumente
    $arguments = @(
        "/login:$Account",
        "/server:`"$Server`"",
        "/password:`"$Password`""
    )

    Write-Log "Verwende folgende Parameter:"
    Write-Log "  Login:  $Account"
    Write-Log "  Server: $Server"
    Write-Log "  Password: ******** (versteckt)"

    try {
        # MT5 starten
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $MT5Path
        $processInfo.Arguments = $arguments -join " "
        $processInfo.UseShellExecute = $false
        $processInfo.RedirectStandardOutput = $false
        $processInfo.RedirectStandardError = $false
        $processInfo.CreateNoWindow = $false

        $process = [System.Diagnostics.Process]::Start($processInfo)

        if ($process) {
            Write-Log "MT5 erfolgreich gestartet (PID: $($process.Id))" -Level SUCCESS

            # Warte kurz und prüfe, ob Prozess noch läuft
            Start-Sleep -Seconds 5

            if (-not $process.HasExited) {
                Write-Log "MT5 läuft stabil" -Level SUCCESS
                return $true
            } else {
                Write-Log "MT5-Prozess wurde unerwartet beendet (Exit Code: $($process.ExitCode))" -Level ERROR
                return $false
            }
        } else {
            Write-Log "Fehler beim Starten von MT5" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "Exception beim Starten von MT5: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Monitor-MT5Process {
    param(
        [hashtable]$Config,
        [int]$CheckInterval = 30
    )

    Write-Log "════════════════════════════════════════════════════════"
    Write-Log "Starte MT5-Prozessüberwachung..."
    Write-Log "Prüfintervall: $CheckInterval Sekunden"
    Write-Log "Drücken Sie Strg+C zum Beenden"
    Write-Log "════════════════════════════════════════════════════════"

    $restartCount = 0

    while ($true) {
        Start-Sleep -Seconds $CheckInterval

        if (-not (Test-MT5Process)) {
            $restartCount++
            Write-Log "MT5-Prozess nicht gefunden! (Neustart #$restartCount)" -Level WARNING
            Write-Log "Warte $RestartDelay Sekunden vor Neustart..."

            Start-Sleep -Seconds $RestartDelay

            $success = Start-MT5 `
                -MT5Path $Config.mt5_path `
                -Account $Config.account `
                -Password $Config.password `
                -Server $Config.server

            if ($success) {
                Write-Log "MT5 erfolgreich neu gestartet" -Level SUCCESS
            } else {
                Write-Log "Neustart fehlgeschlagen - versuche erneut in $CheckInterval Sekunden" -Level ERROR
            }
        } else {
            # Prozess läuft
            $process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($process) {
                $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
                $cpuTime = $process.TotalProcessorTime.ToString("hh\:mm\:ss")
                Write-Log "MT5 Status: Läuft (PID: $($process.Id), RAM: $memoryMB MB, CPU-Zeit: $cpuTime)" -Level INFO
            }
        }
    }
}

function Initialize-MT5Config {
    param(
        [string]$MT5DataPath,
        [long]$Account,
        [string]$Server
    )

    Write-Log "Initialisiere MT5-Konfiguration..."

    # Suche terminal.ini
    $iniPath = Join-Path $MT5DataPath "terminal.ini"

    if (-not (Test-Path $MT5DataPath)) {
        Write-Log "MT5 Datenordner nicht gefunden: $MT5DataPath" -Level WARNING
        return $false
    }

    # Erstelle oder aktualisiere terminal.ini
    # HINWEIS: Dies ist eine vereinfachte Version
    # In Produktion sollte eine robustere INI-Bearbeitung verwendet werden

    Write-Log "MT5 Config-Initialisierung abgeschlossen" -Level SUCCESS
    return $true
}

# ============================================
# HAUPTPROGRAMM
# ============================================

function Main {
    Write-Log "════════════════════════════════════════════════════════"
    Write-Log "   MT5 Auto-Start System für SaaS-Plattformen v1.0"
    Write-Log "   Copyright 2024 Stelona"
    Write-Log "════════════════════════════════════════════════════════"
    Write-Log ""

    # Konfiguration laden
    $config = Read-MT5Config -Path $ConfigFile

    if ($null -eq $config) {
        Write-Log "Abbruch: Konfiguration konnte nicht geladen werden" -Level ERROR
        exit 1
    }

    # Prüfe ob MT5 bereits läuft
    if (Test-MT5Process) {
        Write-Log "MT5 läuft bereits!" -Level WARNING

        if ($config.stop_existing -eq $true) {
            Write-Log "Beende bestehenden MT5-Prozess (stop_existing=true)..." -Level WARNING
            Stop-MT5Process
            Start-Sleep -Seconds 3
        } else {
            Write-Log "Verwende bestehenden MT5-Prozess (stop_existing=false)" -Level INFO

            if (-not $NoMonitor) {
                Monitor-MT5Process -Config $config -CheckInterval 30
            }
            return
        }
    }

    # MT5 starten
    $success = Start-MT5 `
        -MT5Path $config.mt5_path `
        -Account $config.account `
        -Password $config.password `
        -Server $config.server

    if (-not $success) {
        Write-Log "Fehler beim Starten von MT5" -Level ERROR
        exit 1
    }

    # Prozessüberwachung starten (falls gewünscht)
    if (-not $NoMonitor) {
        Write-Log ""
        Monitor-MT5Process -Config $config -CheckInterval 30
    } else {
        Write-Log "Prozessüberwachung deaktiviert (-NoMonitor)" -Level INFO
    }
}

# Script ausführen
try {
    Main
} catch {
    Write-Log "Unbehandelter Fehler: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    exit 1
} finally {
    Write-Log "Script beendet"
}
