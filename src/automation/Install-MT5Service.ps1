#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installiert MT5 Auto-Start als Windows Service

.DESCRIPTION
    Erstellt und konfiguriert einen Windows Service, der MT5 automatisch
    beim System-Start startet. Perfekt für SaaS-Plattformen ohne manuelle Interaktion.

.PARAMETER ServiceName
    Name des Windows Service (Standard: MT5AutoStart)

.PARAMETER ConfigFile
    Pfad zur JSON-Konfigurationsdatei

.PARAMETER StartupType
    Service Startup Type: Automatic, Manual, Disabled

.EXAMPLE
    .\Install-MT5Service.ps1 -ConfigFile "C:\MT5\config.json"

.NOTES
    Version: 1.0
    Author: Stelona
    Erfordert: Administrator-Rechte
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName = "MT5AutoStart",

    [Parameter(Mandatory=$true)]
    [string]$ConfigFile,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Automatic','Manual','Disabled')]
    [string]$StartupType = 'Automatic',

    [Parameter(Mandatory=$false)]
    [string]$DisplayName = "MetaTrader 5 Auto-Start Service",

    [Parameter(Mandatory=$false)]
    [string]$Description = "Startet und überwacht MetaTrader 5 automatisch für SaaS-Plattformen"
)

# ============================================
# FUNKTIONEN
# ============================================

function Write-ColorLog {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-NSSMWrapper {
    Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Cyan
    Write-ColorLog "   NSSM Installation (Non-Sucking Service Manager)" -Color Cyan
    Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Cyan

    # NSSM Download URL
    $nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
    $downloadPath = "$env:TEMP\nssm.zip"
    $extractPath = "$env:TEMP\nssm"
    $nssmExePath = "$extractPath\nssm-2.24\win64\nssm.exe"
    $installPath = "C:\Program Files\NSSM\nssm.exe"

    # Prüfe ob NSSM bereits installiert ist
    if (Test-Path $installPath) {
        Write-ColorLog "✓ NSSM ist bereits installiert: $installPath" -Color Green
        return $installPath
    }

    Write-ColorLog "NSSM wird heruntergeladen..." -Color Yellow

    try {
        # Download
        Invoke-WebRequest -Uri $nssmUrl -OutFile $downloadPath -UseBasicParsing
        Write-ColorLog "✓ Download abgeschlossen" -Color Green

        # Extract
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
        Write-ColorLog "✓ Archiv extrahiert" -Color Green

        # Install
        $nssmDir = "C:\Program Files\NSSM"
        if (-not (Test-Path $nssmDir)) {
            New-Item -ItemType Directory -Path $nssmDir -Force | Out-Null
        }

        Copy-Item -Path $nssmExePath -Destination $installPath -Force
        Write-ColorLog "✓ NSSM installiert nach: $installPath" -Color Green

        # Cleanup
        Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

        return $installPath

    } catch {
        Write-ColorLog "✗ Fehler bei NSSM-Installation: $($_.Exception.Message)" -Color Red
        Write-ColorLog "" -Color White
        Write-ColorLog "Alternative: Installieren Sie NSSM manuell von https://nssm.cc/" -Color Yellow
        return $null
    }
}

function Install-ServiceWithTaskScheduler {
    param(
        [string]$ScriptPath,
        [string]$ConfigPath,
        [string]$TaskName
    )

    Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Cyan
    Write-ColorLog "   Alternative Installation: Windows Task Scheduler" -Color Cyan
    Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Cyan

    # PowerShell Kommando
    $psCommand = "powershell.exe"
    $psArguments = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$ScriptPath`" -ConfigFile `"$ConfigPath`""

    # Task-Action
    $action = New-ScheduledTaskAction -Execute $psCommand -Argument $psArguments

    # Task-Trigger (Bei System-Start)
    $trigger = New-ScheduledTaskTrigger -AtStartup

    # Task-Settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Days 365)

    # Task-Principal (Als SYSTEM ausführen)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    try {
        # Entferne existierenden Task
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

        # Registriere neuen Task
        Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Description $Description | Out-Null

        Write-ColorLog "✓ Task Scheduler Job erstellt: $TaskName" -Color Green
        Write-ColorLog "" -Color White
        Write-ColorLog "Der Task startet MT5 automatisch bei jedem System-Boot" -Color Yellow
        Write-ColorLog "Verwaltung: taskschd.msc → Task Scheduler Library" -Color Yellow

        return $true

    } catch {
        Write-ColorLog "✗ Fehler beim Erstellen des Scheduled Task: $($_.Exception.Message)" -Color Red
        return $false
    }
}

function Install-ServiceWithNSSM {
    param(
        [string]$NSSMPath,
        [string]$ScriptPath,
        [string]$ConfigPath,
        [string]$ServiceName,
        [string]$DisplayName,
        [string]$Description
    )

    Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Cyan
    Write-ColorLog "   Service-Installation mit NSSM" -Color Cyan
    Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Cyan

    # PowerShell Command
    $psPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $psArguments = "-ExecutionPolicy Bypass -NoProfile -File `"$ScriptPath`" -ConfigFile `"$ConfigPath`""

    try {
        # Entferne existierenden Service
        $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($existingService) {
            Write-ColorLog "Entferne bestehenden Service..." -Color Yellow
            & $NSSMPath stop $ServiceName
            & $NSSMPath remove $ServiceName confirm
        }

        # Installiere Service
        Write-ColorLog "Installiere Service: $ServiceName" -Color Yellow

        & $NSSMPath install $ServiceName $psPath $psArguments

        # Konfiguriere Service
        & $NSSMPath set $ServiceName DisplayName $DisplayName
        & $NSSMPath set $ServiceName Description $Description
        & $NSSMPath set $ServiceName Start SERVICE_AUTO_START
        & $NSSMPath set $ServiceName AppStdout "C:\MT5\logs\service_stdout.log"
        & $NSSMPath set $ServiceName AppStderr "C:\MT5\logs\service_stderr.log"
        & $NSSMPath set $ServiceName AppRotateFiles 1
        & $NSSMPath set $ServiceName AppRotateBytes 1048576  # 1 MB

        Write-ColorLog "✓ Service erfolgreich installiert" -Color Green
        Write-ColorLog "" -Color White
        Write-ColorLog "Service-Name: $ServiceName" -Color Cyan
        Write-ColorLog "Display-Name: $DisplayName" -Color Cyan
        Write-ColorLog "Startup-Type: Automatic" -Color Cyan

        # Starte Service
        Write-ColorLog "" -Color White
        Write-ColorLog "Starte Service..." -Color Yellow
        & $NSSMPath start $ServiceName

        Start-Sleep -Seconds 3

        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            Write-ColorLog "✓ Service läuft!" -Color Green
            return $true
        } else {
            Write-ColorLog "⚠ Service wurde installiert, läuft aber nicht" -Color Yellow
            Write-ColorLog "Starten Sie den Service manuell: sc start $ServiceName" -Color Yellow
            return $true
        }

    } catch {
        Write-ColorLog "✗ Fehler bei Service-Installation: $($_.Exception.Message)" -Color Red
        return $false
    }
}

# ============================================
# HAUPTPROGRAMM
# ============================================

Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Cyan
Write-ColorLog "   MT5 Auto-Start Service Installer v1.0" -Color Cyan
Write-ColorLog "   Copyright 2024 Stelona" -Color Cyan
Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Cyan
Write-ColorLog "" -Color White

# Prüfe Admin-Rechte
if (-not (Test-AdminRights)) {
    Write-ColorLog "✗ FEHLER: Dieses Script erfordert Administrator-Rechte" -Color Red
    Write-ColorLog "" -Color White
    Write-ColorLog "Bitte führen Sie PowerShell als Administrator aus:" -Color Yellow
    Write-ColorLog "Rechtsklick auf PowerShell → Als Administrator ausführen" -Color Yellow
    exit 1
}

Write-ColorLog "✓ Administrator-Rechte bestätigt" -Color Green
Write-ColorLog "" -Color White

# Prüfe ob Konfigurationsdatei existiert
if (-not (Test-Path $ConfigFile)) {
    Write-ColorLog "✗ Konfigurationsdatei nicht gefunden: $ConfigFile" -Color Red
    exit 1
}

Write-ColorLog "✓ Konfigurationsdatei gefunden: $ConfigFile" -Color Green
Write-ColorLog "" -Color White

# Prüfe ob Auto-Start Script existiert
$scriptPath = Join-Path $PSScriptRoot "MT5_AutoStart.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-ColorLog "✗ MT5_AutoStart.ps1 nicht gefunden in: $PSScriptRoot" -Color Red
    exit 1
}

Write-ColorLog "✓ Auto-Start Script gefunden: $scriptPath" -Color Green
Write-ColorLog "" -Color White

# Erstelle Log-Verzeichnis
$logDir = "C:\MT5\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-ColorLog "✓ Log-Verzeichnis erstellt: $logDir" -Color Green
}

# Wähle Installationsmethode
Write-ColorLog "Wählen Sie die Installationsmethode:" -Color Cyan
Write-ColorLog "  [1] Windows Service (NSSM) - Empfohlen" -Color White
Write-ColorLog "  [2] Task Scheduler - Alternative" -Color White
Write-ColorLog "" -Color White

$choice = Read-Host "Ihre Wahl (1 oder 2)"

if ($choice -eq "1") {
    # NSSM Installation
    $nssmPath = Install-NSSMWrapper

    if ($nssmPath) {
        $success = Install-ServiceWithNSSM `
            -NSSMPath $nssmPath `
            -ScriptPath $scriptPath `
            -ConfigPath $ConfigFile `
            -ServiceName $ServiceName `
            -DisplayName $DisplayName `
            -Description $Description

        if ($success) {
            Write-ColorLog "" -Color White
            Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Green
            Write-ColorLog "   ✓ Installation erfolgreich abgeschlossen!" -Color Green
            Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Green
            Write-ColorLog "" -Color White
            Write-ColorLog "MT5 startet nun automatisch bei jedem System-Boot" -Color Yellow
            Write-ColorLog "" -Color White
            Write-ColorLog "Service-Verwaltung:" -Color Cyan
            Write-ColorLog "  Status prüfen:  sc query $ServiceName" -Color White
            Write-ColorLog "  Service stoppen: sc stop $ServiceName" -Color White
            Write-ColorLog "  Service starten: sc start $ServiceName" -Color White
            Write-ColorLog "  Service entfernen: $nssmPath remove $ServiceName confirm" -Color White
        }
    }

} elseif ($choice -eq "2") {
    # Task Scheduler Installation
    $success = Install-ServiceWithTaskScheduler `
        -ScriptPath $scriptPath `
        -ConfigPath $ConfigFile `
        -TaskName $ServiceName

    if ($success) {
        Write-ColorLog "" -Color White
        Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Green
        Write-ColorLog "   ✓ Installation erfolgreich abgeschlossen!" -Color Green
        Write-ColorLog "═══════════════════════════════════════════════════════════" -Color Green
        Write-ColorLog "" -Color White
        Write-ColorLog "MT5 startet nun automatisch bei jedem System-Boot" -Color Yellow
        Write-ColorLog "" -Color White
        Write-ColorLog "Task-Verwaltung:" -Color Cyan
        Write-ColorLog "  Status prüfen:  Get-ScheduledTask -TaskName $ServiceName" -Color White
        Write-ColorLog "  Task deaktivieren: Disable-ScheduledTask -TaskName $ServiceName" -Color White
        Write-ColorLog "  Task aktivieren: Enable-ScheduledTask -TaskName $ServiceName" -Color White
        Write-ColorLog "  Task entfernen: Unregister-ScheduledTask -TaskName $ServiceName" -Color White
    }

} else {
    Write-ColorLog "✗ Ungültige Auswahl" -Color Red
    exit 1
}

Write-ColorLog "" -Color White
Write-ColorLog "Drücken Sie eine beliebige Taste zum Beenden..." -Color Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
