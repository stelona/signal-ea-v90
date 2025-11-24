#═══════════════════════════════════════════════════════════════════════════
# MT5 Pre-Flight Check - PowerShell Wrapper
# Windows 11 Version
#═══════════════════════════════════════════════════════════════════════════
#
# Funktionen:
# - Python Dependency Check
# - MT5 Installation Check
# - AWS Credentials Check
# - Pre-Flight Script Ausführung
# - Ergebnis-Anzeige
#
# Usage:
#   .\Run-PreflightCheck.ps1 -ConfigPath "C:\MT5\login.ini"
#
#   .\Run-PreflightCheck.ps1 `
#       -ConfigPath "C:\MT5\login.ini" `
#       -WebhookUrl "https://api.example.com/mt5/symbols" `
#       -S3Bucket "my-mt5-configs" `
#       -S3Prefix "customer-123/"
#
# Version: 1.0
# Author: Stelona
#═══════════════════════════════════════════════════════════════════════════

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath,

    [Parameter(Mandatory=$false)]
    [string]$WebhookUrl,

    [Parameter(Mandatory=$false)]
    [string]$S3Bucket,

    [Parameter(Mandatory=$false)]
    [string]$S3Prefix = "",

    [Parameter(Mandatory=$false)]
    [string]$S3Region = "eu-central-1",

    [Parameter(Mandatory=$false)]
    [string]$OutputJson,

    [Parameter(Mandatory=$false)]
    [switch]$SkipChecks
)

# ═══════════════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════════════

function Write-Header {
    param([string]$Text)
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ $Text" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "✗ ERROR: $Text" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Text)
    Write-Host "⚠ WARNING: $Text" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Text)
    Write-Host "  $Text" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════════════════
# System Checks
# ═══════════════════════════════════════════════════════════════════════════

function Test-PythonInstalled {
    Write-Header "Python Installation Check"

    try {
        $pythonVersion = & python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Python installiert: $pythonVersion"
            return $true
        }
    }
    catch {
        Write-Error-Custom "Python nicht gefunden!"
        Write-Info "Download: https://www.python.org/downloads/"
        Write-Info "Nach Installation: 'Add Python to PATH' aktivieren"
        return $false
    }

    return $false
}

function Test-PipPackages {
    Write-Header "Python Package Check"

    # Check MetaTrader5
    $mt5Installed = & python -c "import MetaTrader5" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "MetaTrader5 Python Paket installiert"
    } else {
        Write-Error-Custom "MetaTrader5 Paket fehlt!"
        Write-Info "Installation: pip install MetaTrader5"
        return $false
    }

    # Check boto3 (optional)
    $boto3Installed = & python -c "import boto3" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "boto3 installiert (S3 Upload verfügbar)"
    } else {
        Write-Warning-Custom "boto3 nicht installiert (S3 Upload deaktiviert)"
        Write-Info "Optional: pip install boto3"
    }

    # Check requests (optional)
    $requestsInstalled = & python -c "import requests" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "requests installiert (Webhook verfügbar)"
    } else {
        Write-Warning-Custom "requests nicht installiert (Webhook deaktiviert)"
        Write-Info "Optional: pip install requests"
    }

    Write-Host ""
    return $true
}

function Test-MT5Installed {
    Write-Header "MetaTrader 5 Installation Check"

    $mt5Paths = @(
        "C:\Program Files\MetaTrader 5\terminal64.exe",
        "C:\Program Files (x86)\MetaTrader 5\terminal64.exe",
        "$env:LOCALAPPDATA\Programs\MetaTrader 5\terminal64.exe"
    )

    foreach ($path in $mt5Paths) {
        if (Test-Path $path) {
            Write-Success "MT5 gefunden: $path"
            return $true
        }
    }

    Write-Warning-Custom "MT5 nicht an Standard-Pfaden gefunden"
    Write-Info "Pfade geprüft:"
    foreach ($path in $mt5Paths) {
        Write-Info "  - $path"
    }
    Write-Info ""
    Write-Info "MT5 könnte an anderem Ort installiert sein."
    Write-Info "Das Script wird trotzdem versuchen, MT5 zu initialisieren."
    Write-Host ""

    return $true
}

function Test-AWSCredentials {
    param([bool]$S3Required)

    if (-not $S3Required) {
        return $true
    }

    Write-Header "AWS Credentials Check"

    $hasAwsCreds = $false

    # Check environment variables
    if ($env:AWS_ACCESS_KEY_ID -and $env:AWS_SECRET_ACCESS_KEY) {
        Write-Success "AWS Credentials (Environment Variables) gefunden"
        $hasAwsCreds = $true
    }

    # Check AWS CLI config
    $awsConfigPath = "$env:USERPROFILE\.aws\credentials"
    if (Test-Path $awsConfigPath) {
        Write-Success "AWS Credentials (AWS CLI) gefunden"
        $hasAwsCreds = $true
    }

    if (-not $hasAwsCreds) {
        Write-Warning-Custom "Keine AWS Credentials gefunden!"
        Write-Info "Optionen:"
        Write-Info "  1. Environment Variables:"
        Write-Info "     `$env:AWS_ACCESS_KEY_ID='your-key'"
        Write-Info "     `$env:AWS_SECRET_ACCESS_KEY='your-secret'"
        Write-Info ""
        Write-Info "  2. AWS CLI:"
        Write-Info "     aws configure"
        Write-Host ""
    }

    return $hasAwsCreds
}

function Find-LoginIni {
    Write-Header "Suche login.ini"

    $searchPaths = @(
        "C:\MT5\login.ini",
        "C:\Program Files\MetaTrader 5\login.ini",
        "$env:USERPROFILE\Desktop\login.ini",
        ".\login.ini"
    )

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            Write-Success "Gefunden: $path"
            return $path
        }
    }

    Write-Error-Custom "login.ini nicht gefunden!"
    Write-Info "Durchsucht:"
    foreach ($path in $searchPaths) {
        Write-Info "  - $path"
    }
    Write-Host ""

    return $null
}

# ═══════════════════════════════════════════════════════════════════════════
# Main Script
# ═══════════════════════════════════════════════════════════════════════════

Write-Header "MT5 Pre-Flight Check - Windows 11"
Write-Info "Version: 1.0"
Write-Info "Platform: $([Environment]::OSVersion.VersionString)"
Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════
# System Checks
# ═══════════════════════════════════════════════════════════════════════════

if (-not $SkipChecks) {
    if (-not (Test-PythonInstalled)) {
        exit 1
    }

    if (-not (Test-PipPackages)) {
        exit 1
    }

    if (-not (Test-MT5Installed)) {
        # Warning only, continue
    }

    Test-AWSCredentials -S3Required ($S3Bucket -ne "")
}

# ═══════════════════════════════════════════════════════════════════════════
# Find Config
# ═══════════════════════════════════════════════════════════════════════════

if (-not $ConfigPath) {
    $ConfigPath = Find-LoginIni
    if (-not $ConfigPath) {
        Write-Error-Custom "Keine login.ini gefunden und --ConfigPath nicht angegeben!"
        exit 1
    }
}

if (-not (Test-Path $ConfigPath)) {
    Write-Error-Custom "Config-Datei nicht gefunden: $ConfigPath"
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════
# Build Arguments
# ═══════════════════════════════════════════════════════════════════════════

Write-Header "Pre-Flight Check wird ausgeführt"

$scriptPath = Join-Path $PSScriptRoot "mt5_preflight_check_windows.py"

if (-not (Test-Path $scriptPath)) {
    Write-Error-Custom "Python Script nicht gefunden: $scriptPath"
    exit 1
}

$arguments = @("--config", $ConfigPath)

if ($WebhookUrl) {
    $arguments += "--webhook-url", $WebhookUrl
    Write-Info "Webhook: $WebhookUrl"
}

if ($S3Bucket) {
    $arguments += "--s3-bucket", $S3Bucket
    if ($S3Prefix) {
        $arguments += "--s3-prefix", $S3Prefix
    }
    $arguments += "--s3-region", $S3Region
    Write-Info "S3 Bucket: $S3Bucket"
    Write-Info "S3 Prefix: $S3Prefix"
}

if ($OutputJson) {
    $arguments += "--output-json", $OutputJson
    Write-Info "JSON Output: $OutputJson"
}

Write-Host ""
Write-Info "Starte Pre-Flight Check..."
Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════
# Execute Python Script
# ═══════════════════════════════════════════════════════════════════════════

try {
    & python $scriptPath @arguments

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Header "✓ PRE-FLIGHT CHECK ERFOLGREICH"

        if ($OutputJson -and (Test-Path $OutputJson)) {
            Write-Host ""
            Write-Info "Ergebnis gespeichert in: $OutputJson"
            Write-Host ""

            # Show summary from JSON
            try {
                $result = Get-Content $OutputJson | ConvertFrom-Json

                Write-Info "Broker: $($result.broker_info.company) ($($result.broker_info.server))"
                Write-Info "Crypto: $($result.crypto.Count) Symbole"
                Write-Info "Forex: $($result.forex.Count) Symbole"
                Write-Info "Indizes: $($result.indices.Count) Symbole"

                if ($result.servers_dat_s3) {
                    Write-Info "servers.dat: s3://$($result.servers_dat_s3.bucket)/$($result.servers_dat_s3.key)"
                }
            }
            catch {
                Write-Warning-Custom "Konnte JSON nicht parsen: $_"
            }
        }

        Write-Host ""
        Write-Success "Pre-Flight Check abgeschlossen!"
    }
    else {
        Write-Host ""
        Write-Error-Custom "Pre-Flight Check fehlgeschlagen (Exit Code: $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
}
catch {
    Write-Error-Custom "Fehler beim Ausführen des Scripts: $_"
    exit 1
}
