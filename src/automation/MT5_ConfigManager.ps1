#Requires -Version 5.1
<#
.SYNOPSIS
    MT5 Konfigurations-Manager für automatisches Setup

.DESCRIPTION
    Verwaltet MT5-Konfigurationsdateien programmatisch.
    Perfekt für SaaS-Plattformen zur automatischen Account-Konfiguration.

.EXAMPLE
    .\MT5_ConfigManager.ps1 -Account 12345678 -Server "ICMarkets-Demo" -DataPath "C:\Users\..."

.NOTES
    Version: 1.0
    Author: Stelona
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [long]$Account,

    [Parameter(Mandatory=$false)]
    [string]$Server,

    [Parameter(Mandatory=$false)]
    [string]$DataPath,

    [Parameter(Mandatory=$false)]
    [string]$Action = "configure",

    [Parameter(Mandatory=$false)]
    [switch]$Backup
)

# ============================================
# FUNKTIONEN
# ============================================

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'ERROR' { 'Red' }
        'WARNING' { 'Yellow' }
        'SUCCESS' { 'Green' }
        default { 'White' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Find-MT5DataPath {
    Write-Log "Suche MT5 Datenordner..."

    $appDataPath = [Environment]::GetFolderPath('ApplicationData')
    $terminalBasePath = Join-Path $appDataPath "MetaQuotes\Terminal"

    if (-not (Test-Path $terminalBasePath)) {
        Write-Log "MetaQuotes Terminal Ordner nicht gefunden" -Level ERROR
        return $null
    }

    # Suche nach Terminal-Ordnern (mit Hash-Namen)
    $terminalFolders = Get-ChildItem -Path $terminalBasePath -Directory |
        Where-Object { $_.Name -match '^[A-F0-9]{32}$' }

    if ($terminalFolders.Count -eq 0) {
        Write-Log "Keine Terminal-Instanzen gefunden" -Level ERROR
        return $null
    }

    if ($terminalFolders.Count -eq 1) {
        $path = $terminalFolders[0].FullName
        Write-Log "MT5 Datenordner gefunden: $path" -Level SUCCESS
        return $path
    }

    # Mehrere gefunden - wähle neuesten
    $newest = $terminalFolders | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $path = $newest.FullName
    Write-Log "Mehrere Terminal-Instanzen gefunden - verwende neueste: $path" -Level WARNING
    return $path
}

function Backup-MT5Config {
    param([string]$DataPath)

    Write-Log "Erstelle Backup der MT5-Konfiguration..."

    $backupDir = Join-Path $DataPath "config_backups"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $backupDir "backup_$timestamp"
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

    # Backup wichtiger Dateien
    $filesToBackup = @(
        "terminal.ini",
        "origin.txt",
        "common.ini"
    )

    foreach ($file in $filesToBackup) {
        $sourcePath = Join-Path $DataPath $file
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $backupPath -Force
            Write-Log "  Gesichert: $file"
        }
    }

    Write-Log "Backup erstellt: $backupPath" -Level SUCCESS
    return $backupPath
}

function Read-IniFile {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @{}
    }

    $ini = @{}
    $section = ""

    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()

        # Überspringe Kommentare und leere Zeilen
        if ($line -eq "" -or $line.StartsWith(";") -or $line.StartsWith("#")) {
            return
        }

        # Section
        if ($line -match '^\[(.+)\]$') {
            $section = $matches[1]
            $ini[$section] = @{}
            return
        }

        # Key=Value
        if ($line -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()

            if ($section) {
                $ini[$section][$key] = $value
            }
        }
    }

    return $ini
}

function Write-IniFile {
    param(
        [hashtable]$IniData,
        [string]$Path
    )

    $content = @()

    foreach ($sectionName in $IniData.Keys | Sort-Object) {
        $content += "[$sectionName]"

        $section = $IniData[$sectionName]
        foreach ($key in $section.Keys | Sort-Object) {
            $value = $section[$key]
            $content += "$key=$value"
        }

        $content += ""  # Leerzeile nach Section
    }

    $content | Set-Content -Path $Path -Encoding UTF8
}

function Set-MT5AccountConfig {
    param(
        [string]$DataPath,
        [long]$Account,
        [string]$Server
    )

    Write-Log "Konfiguriere MT5 Account..."
    Write-Log "  Account: $Account"
    Write-Log "  Server:  $Server"

    $iniPath = Join-Path $DataPath "terminal.ini"

    # Lese bestehende INI
    $ini = Read-IniFile -Path $iniPath

    # Erstelle/Update Account-Sektion
    if (-not $ini.ContainsKey("Common")) {
        $ini["Common"] = @{}
    }

    $ini["Common"]["Login"] = $Account.ToString()
    $ini["Common"]["Server"] = $Server

    # Speichere INI
    Write-IniFile -IniData $ini -Path $iniPath

    Write-Log "Account-Konfiguration gespeichert" -Level SUCCESS

    # Erstelle origin.txt (Server-Info)
    $originPath = Join-Path $DataPath "origin.txt"
    $Server | Set-Content -Path $originPath -Encoding UTF8

    Write-Log "Server-Konfiguration gespeichert: origin.txt" -Level SUCCESS
}

function Get-MT5AccountInfo {
    param([string]$DataPath)

    Write-Log "Lese MT5 Account-Informationen..."

    $iniPath = Join-Path $DataPath "terminal.ini"

    if (-not (Test-Path $iniPath)) {
        Write-Log "terminal.ini nicht gefunden" -Level ERROR
        return $null
    }

    $ini = Read-IniFile -Path $iniPath

    $info = @{
        Account = $null
        Server = $null
        DataPath = $DataPath
    }

    if ($ini.ContainsKey("Common")) {
        $info.Account = $ini["Common"]["Login"]
        $info.Server = $ini["Common"]["Server"]
    }

    # Prüfe auch origin.txt
    $originPath = Join-Path $DataPath "origin.txt"
    if (Test-Path $originPath) {
        $originServer = Get-Content $originPath -Raw -ErrorAction SilentlyContinue
        if ($originServer) {
            $info.Server = $originServer.Trim()
        }
    }

    Write-Log "Account: $($info.Account)" -Level SUCCESS
    Write-Log "Server:  $($info.Server)" -Level SUCCESS

    return $info
}

function Initialize-MT5ForSaaS {
    param(
        [string]$DataPath,
        [long]$Account,
        [string]$Server,
        [string]$Password
    )

    Write-Log "═══════════════════════════════════════════════════════════" -Level INFO
    Write-Log "   MT5 SaaS Initialisierung" -Level INFO
    Write-Log "═══════════════════════════════════════════════════════════" -Level INFO

    # 1. Backup
    if ($Backup) {
        Backup-MT5Config -DataPath $DataPath
    }

    # 2. Account konfigurieren
    Set-MT5AccountConfig -DataPath $DataPath -Account $Account -Server $Server

    # 3. Erstelle Verzeichnisse
    $requiredDirs = @(
        "MQL5",
        "MQL5\Files",
        "MQL5\Scripts",
        "MQL5\Experts",
        "MQL5\Include",
        "Logs"
    )

    foreach ($dir in $requiredDirs) {
        $fullPath = Join-Path $DataPath $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Log "  Verzeichnis erstellt: $dir"
        }
    }

    # 4. Erstelle Config-Datei für Auto-Login
    $configData = @{
        account = $Account
        password = $Password
        server = $Server
        mt5_data_path = $DataPath
        configured_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    } | ConvertTo-Json -Depth 5

    $configPath = Join-Path $DataPath "MQL5\Files\mt5_auto_config.json"
    $configData | Set-Content -Path $configPath -Encoding UTF8

    Write-Log "Auto-Login Config erstellt: $configPath" -Level SUCCESS

    Write-Log "═══════════════════════════════════════════════════════════" -Level SUCCESS
    Write-Log "   MT5 erfolgreich für SaaS konfiguriert!" -Level SUCCESS
    Write-Log "═══════════════════════════════════════════════════════════" -Level SUCCESS
}

# ============================================
# HAUPTPROGRAMM
# ============================================

Write-Log "═══════════════════════════════════════════════════════════"
Write-Log "   MT5 Config Manager v1.0 - Stelona"
Write-Log "═══════════════════════════════════════════════════════════"
Write-Log ""

# Finde oder verwende DataPath
if (-not $DataPath) {
    $DataPath = Find-MT5DataPath
    if (-not $DataPath) {
        Write-Log "MT5 Datenordner konnte nicht gefunden werden" -Level ERROR
        Write-Log "Bitte geben Sie den Pfad manuell an: -DataPath 'C:\Users\...\Terminal\...'" -Level ERROR
        exit 1
    }
}

# Validiere DataPath
if (-not (Test-Path $DataPath)) {
    Write-Log "DataPath existiert nicht: $DataPath" -Level ERROR
    exit 1
}

Write-Log "Verwende MT5 Datenordner: $DataPath" -Level SUCCESS
Write-Log ""

# Führe Aktion aus
switch ($Action.ToLower()) {
    "configure" {
        if (-not $Account -or -not $Server) {
            Write-Log "Für 'configure' werden Account und Server benötigt" -Level ERROR
            Write-Log "Verwendung: -Account 12345678 -Server 'ICMarkets-Demo'" -Level ERROR
            exit 1
        }

        $password = Read-Host -Prompt "Passwort" -AsSecureString
        $passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        )

        Initialize-MT5ForSaaS -DataPath $DataPath -Account $Account -Server $Server -Password $passwordPlain
    }

    "info" {
        $info = Get-MT5AccountInfo -DataPath $DataPath
        if ($info) {
            Write-Log ""
            Write-Log "═══════════════════════════════════════════════════════════"
            Write-Log "   MT5 Account-Informationen"
            Write-Log "═══════════════════════════════════════════════════════════"
            Write-Log "Account:   $($info.Account)"
            Write-Log "Server:    $($info.Server)"
            Write-Log "Data Path: $($info.DataPath)"
            Write-Log "═══════════════════════════════════════════════════════════"
        }
    }

    "backup" {
        Backup-MT5Config -DataPath $DataPath
    }

    default {
        Write-Log "Unbekannte Aktion: $Action" -Level ERROR
        Write-Log "Verfügbare Aktionen: configure, info, backup" -Level ERROR
        exit 1
    }
}

Write-Log ""
Write-Log "Fertig!"
