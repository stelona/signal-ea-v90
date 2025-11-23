# 🤖 MT5 SaaS Automation

**Vollautomatisches MT5 Auto-Login System - KEINE manuelle Interaktion erforderlich!**

## ⚡ Quick Start (für SaaS-Plattformen)

### 1. Kopiere alle Files nach `C:\MT5\automation`

```powershell
# Erstelle Verzeichnis
New-Item -ItemType Directory -Path "C:\MT5\automation" -Force

# Kopiere Scripts
Copy-Item *.ps1 -Destination "C:\MT5\automation\"
```

### 2. Konfiguration erstellen

Kopiere `examples/mt5_saas_config.json` nach `C:\MT5\config.json` und passe an:

```json
{
  "account": 12345678,
  "password": "IhrPasswort",
  "server": "ICMarkets-Demo",
  "mt5_path": "C:\\Program Files\\MetaTrader 5\\terminal64.exe"
}
```

### 3. Test-Lauf

```powershell
cd C:\MT5\automation
.\MT5_AutoStart.ps1 -ConfigFile "C:\MT5\config.json" -NoMonitor
```

MT5 sollte jetzt **automatisch** mit Ihren Login-Daten starten!

### 4. Als Service installieren

```powershell
# PowerShell als Administrator
.\Install-MT5Service.ps1 -ConfigFile "C:\MT5\config.json"

# Wähle Option 1 (Windows Service) oder 2 (Task Scheduler)
```

**Fertig!** MT5 startet nun automatisch bei jedem System-Boot.

---

## 📁 Dateien

| Datei | Beschreibung |
|-------|--------------|
| **MT5_AutoStart.ps1** | Hauptscript - Startet MT5 automatisch |
| **Install-MT5Service.ps1** | Installiert als Windows Service |
| **MT5_ConfigManager.ps1** | Verwaltet MT5-Konfigurationen |

---

## 🚀 Verwendung

### Manueller Start (einmalig)

```powershell
.\MT5_AutoStart.ps1 -ConfigFile "C:\MT5\config.json" -NoMonitor
```

### Mit Prozess-Überwachung

```powershell
.\MT5_AutoStart.ps1 -ConfigFile "C:\MT5\config.json"
# Startet MT5 neu bei Absturz
```

### Service-Installation

```powershell
# Installieren
.\Install-MT5Service.ps1 -ConfigFile "C:\MT5\config.json"

# Status prüfen
sc query MT5AutoStart

# Service stoppen
sc stop MT5AutoStart

# Service starten
sc start MT5AutoStart
```

### Konfiguration verwalten

```powershell
# Account-Info anzeigen
.\MT5_ConfigManager.ps1 -Action info

# Neuen Account konfigurieren
.\MT5_ConfigManager.ps1 -Action configure -Account 12345678 -Server "ICMarkets-Demo"

# Backup erstellen
.\MT5_ConfigManager.ps1 -Action backup
```

---

## 🏢 Multi-Tenant Setup

Für SaaS-Plattformen mit mehreren Kunden:

```powershell
# Struktur:
C:\MT5\
  ├── customer1\
  │   ├── config.json
  │   └── MT5\
  ├── customer2\
  │   ├── config.json
  │   └── MT5\
  └── automation\

# Service für jeden Kunden
.\Install-MT5Service.ps1 `
    -ConfigFile "C:\MT5\customer1\config.json" `
    -ServiceName "MT5_Customer1"

.\Install-MT5Service.ps1 `
    -ConfigFile "C:\MT5\customer2\config.json" `
    -ServiceName "MT5_Customer2"
```

---

## 📊 Monitoring

### Logs prüfen

```powershell
# Letzte 50 Zeilen
Get-Content C:\MT5\logs\mt5_autostart.log -Tail 50

# Real-time
Get-Content C:\MT5\logs\mt5_autostart.log -Wait

# Fehler finden
Select-String -Path C:\MT5\logs\*.log -Pattern "ERROR"
```

### Health-Check

```powershell
# MT5-Prozess prüfen
Get-Process -Name terminal64

# Service-Status
Get-Service -Name MT5AutoStart
```

---

## 🛡️ Sicherheit

### Credentials verschlüsseln

```powershell
# Passwort verschlüsseln
$password = Read-Host "Passwort" -AsSecureString
$encrypted = $password | ConvertFrom-SecureString

# In Config speichern als 'encrypted_password'
```

### File-Berechtigungen setzen

```powershell
# Nur SYSTEM und Admins
icacls "C:\MT5\config.json" /inheritance:r
icacls "C:\MT5\config.json" /grant:r "SYSTEM:(F)"
icacls "C:\MT5\config.json" /grant:r "Administrators:(F)"
```

---

## 🆘 Troubleshooting

### MT5 startet nicht

```powershell
# 1. Logs prüfen
Get-Content C:\MT5\logs\mt5_autostart.log -Tail 100

# 2. MT5-Pfad validieren
Test-Path "C:\Program Files\MetaTrader 5\terminal64.exe"

# 3. Config validieren
Get-Content C:\MT5\config.json | ConvertFrom-Json
```

### Service läuft nicht

```powershell
# Service-Logs
Get-Content C:\MT5\logs\service_stdout.log
Get-Content C:\MT5\logs\service_stderr.log

# Event-Log
Get-EventLog -LogName Application -Source MT5AutoStart -Newest 20
```

---

## 📚 Vollständige Dokumentation

Siehe: **[SAAS_DEPLOYMENT_GUIDE.md](../../docs/SAAS_DEPLOYMENT_GUIDE.md)**

Dort finden Sie:
- Detaillierte Installation
- Multi-Tenant-Konfiguration
- API-Integration
- Sicherheits-Best-Practices
- Performance-Optimierung
- Production-Checkliste

---

## 📞 Support

- **Email:** [support@stelona.com](mailto:support@stelona.com)
- **GitHub:** [https://github.com/stelona/signal-ea-v90/issues](https://github.com/stelona/signal-ea-v90/issues)
- **Docs:** [SAAS_DEPLOYMENT_GUIDE.md](../../docs/SAAS_DEPLOYMENT_GUIDE.md)

---

**© 2024 Stelona. All rights reserved.**
