# 🐧 MT5 SaaS Automation - Linux/Wine Edition

**Vollautomatisches MT5 Auto-Login System für Linux - ZERO manuelle Interaktion!**

Perfekt für SaaS-Plattformen, die MT5-Instanzen vermieten.

---

## 🚀 Quick Start

### Option 1: Direkte Installation (Systemd)

```bash
# 1. Dependencies installieren
sudo apt-get update
sudo apt-get install wine wine64 xvfb jq -y

# 2. Alle Scripts ausführbar machen
chmod +x *.sh

# 3. Kunden-Config erstellen
./mt5_wine_config.sh create \
  --account 12345678 \
  --password "KundenPasswort" \
  --server "ICMarkets-Demo"

# 4. Als systemd Service installieren
sudo ./install_systemd_service.sh /opt/mt5/config.json

# Fertig! MT5 startet automatisch bei System-Boot
```

### Option 2: Docker Container

```bash
# 1. Docker Image bauen
docker build -t mt5-saas:latest .

# 2. Container starten (mit ENV-Variablen)
docker run -d \
  --name mt5-customer1 \
  -e ACCOUNT=12345678 \
  -e PASSWORD="KundenPasswort" \
  -e SERVER="ICMarkets-Demo" \
  --restart unless-stopped \
  mt5-saas:latest

# 3. Logs prüfen
docker logs -f mt5-customer1

# 4. Status prüfen
docker ps
```

### Option 3: Docker Compose (Multi-Tenant)

```bash
# 1. docker-compose.yml bearbeiten (Credentials anpassen)
nano docker-compose.yml

# 2. Alle Container starten
docker-compose up -d

# 3. Status prüfen
docker-compose ps

# 4. Logs einzelner Kunde
docker-compose logs -f customer1
```

---

## 📁 Dateien

| Datei | Beschreibung |
|-------|--------------|
| **mt5_autostart.sh** | Hauptscript - Startet MT5 in Wine |
| **install_systemd_service.sh** | Installiert als systemd Service |
| **mt5_wine_config.sh** | Config-Manager - erstellt JSON aus Kunden-Eingaben |
| **Dockerfile** | Docker-Image für Container-Setup |
| **docker-compose.yml** | Multi-Tenant Container-Orchestrierung |

---

## 🎯 Workflow für SaaS-Plattform

### 1. Kunde gibt Zugangsdaten ein (Web-Interface)

```javascript
// Beispiel: Web-Formular
{
  account: 12345678,
  password: "KundenPasswort",
  server: "ICMarkets-Demo"
}
```

### 2. System erstellt Config-Datei

```bash
# Automatisch via API/Script
./mt5_wine_config.sh create \
  --account $CUSTOMER_ACCOUNT \
  --password "$CUSTOMER_PASSWORD" \
  --server "$CUSTOMER_SERVER" \
  --customer-id "$CUSTOMER_ID"

# Erstellt: /opt/mt5/${CUSTOMER_ID}_config.json
```

### 3. MT5 startet automatisch

```bash
# Option A: Systemd Service
sudo ./install_systemd_service.sh \
  /opt/mt5/${CUSTOMER_ID}_config.json \
  mt5-${CUSTOMER_ID}

# Option B: Docker Container
docker run -d \
  --name mt5-${CUSTOMER_ID} \
  -v /opt/mt5/${CUSTOMER_ID}_config.json:/opt/mt5/config.json:ro \
  --restart unless-stopped \
  mt5-saas:latest
```

### 4. Kunde nutzt MT5 - ZERO Klicks erforderlich!

MT5 läuft automatisch mit den Zugangsdaten des Kunden. Kunde muss nichts installieren oder konfigurieren.

---

## 🛠️ Verwendung

### Config erstellen

```bash
# Interaktiv
./mt5_wine_config.sh create \
  --account 12345678 \
  --password "MyPassword" \
  --server "ICMarkets-Demo"

# Mit Kunden-ID (Multi-Tenant)
./mt5_wine_config.sh create \
  --account 11111111 \
  --password "Pass1" \
  --server "XM-Demo" \
  --customer-id customer1

# Output-Datei angeben
./mt5_wine_config.sh create \
  --account 12345678 \
  --password "Pass" \
  --server "Server" \
  --output /custom/path/config.json
```

### MT5 manuell starten (Test)

```bash
# Einmalig (ohne Monitoring)
HEADLESS=false ./mt5_autostart.sh /opt/mt5/config.json

# Mit Monitoring (automatischer Neustart)
./mt5_autostart.sh /opt/mt5/config.json
```

### Systemd Service verwalten

```bash
# Status prüfen
sudo systemctl status mt5-autostart

# Logs anzeigen
sudo journalctl -u mt5-autostart -f

# Service stoppen
sudo systemctl stop mt5-autostart

# Service starten
sudo systemctl start mt5-autostart

# Service neuladen
sudo systemctl restart mt5-autostart

# Auto-Start deaktivieren
sudo systemctl disable mt5-autostart
```

### Docker verwalten

```bash
# Container Status
docker ps

# Logs
docker logs -f mt5-customer1

# In Container einsteigen
docker exec -it mt5-customer1 /bin/bash

# Container stoppen
docker stop mt5-customer1

# Container starten
docker start mt5-customer1

# Container entfernen
docker rm -f mt5-customer1
```

---

## 🏢 Multi-Tenant Setup

### Systemd (mehrere Services)

```bash
# Struktur:
/opt/mt5/
  ├── customer1/
  │   └── config.json
  ├── customer2/
  │   └── config.json
  └── customer3/
      └── config.json

# Service für jeden Kunden
for customer in customer1 customer2 customer3; do
  sudo ./install_systemd_service.sh \
    /opt/mt5/$customer/config.json \
    mt5-$customer \
    mt5user
done

# Status aller Services
systemctl status 'mt5-*'
```

### Docker Compose

```bash
# docker-compose.yml bearbeiten
nano docker-compose.yml

# Alle Container starten
docker-compose up -d

# Nur bestimmte Kunden
docker-compose up -d customer1 customer3

# Skalieren (z.B. 5x customer1)
docker-compose up -d --scale customer1=5
```

---

## 📊 Monitoring

### Prozess prüfen

```bash
# MT5-Prozesse anzeigen
ps aux | grep terminal64.exe

# Mit pgrep
pgrep -fa terminal64.exe

# Ressourcen-Verbrauch
top -p $(pgrep -f terminal64.exe)
```

### Logs

```bash
# Systemd Service Logs
sudo journalctl -u mt5-autostart -f

# Script Logs
tail -f /var/log/mt5/mt5_autostart.log

# Docker Logs
docker logs -f mt5-customer1
```

### Health-Check Script

```bash
#!/bin/bash
# health_check.sh

if pgrep -f "terminal64.exe" > /dev/null; then
    echo "✓ MT5 läuft"
    exit 0
else
    echo "✗ MT5 läuft NICHT!"
    exit 1
fi
```

---

## 🐛 Troubleshooting

### MT5 startet nicht

```bash
# 1. Wine testen
wine --version
winecfg  # Öffnet Wine Config

# 2. MT5-Installation prüfen
ls -la ~/.wine/drive_c/Program*Files*/MetaTrader*

# 3. Xvfb prüfen
pgrep Xvfb
echo $DISPLAY

# 4. Manuell starten (Debug)
WINEDEBUG=+all wine ~/.wine/drive_c/Program\ Files/MetaTrader\ 5/terminal64.exe
```

### Config-Probleme

```bash
# Config validieren
jq . /opt/mt5/config.json

# Config-Info anzeigen
./mt5_wine_config.sh info

# Setup testen
./mt5_wine_config.sh test
```

### Docker-Probleme

```bash
# Container Logs
docker logs mt5-customer1

# In Container einsteigen
docker exec -it mt5-customer1 /bin/bash

# Prozesse im Container
docker exec mt5-customer1 ps aux

# Neu bauen (ohne Cache)
docker build --no-cache -t mt5-saas:latest .
```

---

## 🔧 Installation & Setup

### System-Requirements

- **OS:** Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **RAM:** Min. 1GB pro MT5-Instanz (empfohlen: 2GB)
- **CPU:** 1 Core pro Instanz (empfohlen: 2 Cores)
- **Disk:** 2GB pro Instanz

### Dependencies installieren

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
  wine \
  wine64 \
  xvfb \
  jq \
  wget \
  curl

# Fedora/CentOS
sudo dnf install -y \
  wine \
  xorg-x11-server-Xvfb \
  jq \
  wget \
  curl

# Docker (optional)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

### MT5 installieren

```bash
# Automatisch via Script
./mt5_wine_config.sh install-mt5

# Oder manuell
wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
wine mt5setup.exe /auto
```

### Xvfb als Service

```bash
# Automatisch via install_systemd_service.sh
# Oder manuell:

sudo tee /etc/systemd/system/xvfb.service <<EOF
[Unit]
Description=X Virtual Frame Buffer
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/Xvfb :99 -screen 0 1024x768x24

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now xvfb
```

---

## 🔐 Sicherheit

### File-Berechtigungen

```bash
# Config-Dateien nur für Owner lesbar
chmod 600 /opt/mt5/config.json
chown mt5user:mt5user /opt/mt5/config.json
```

### Firewall

```bash
# Nur ausgehende Verbindungen zu Broker-Servern
sudo ufw allow out to any port 443
sudo ufw allow out to any port 80

# Alle eingehenden Verbindungen blockieren
sudo ufw default deny incoming
sudo ufw enable
```

### Docker Security

```bash
# Als non-root user ausführen (bereits im Dockerfile)
# Ressourcen-Limits setzen
docker run -d \
  --memory="2g" \
  --cpus="1.0" \
  --read-only \
  --tmpfs /tmp \
  mt5-saas:latest
```

---

## 📚 Weitere Dokumentation

Siehe Haupt-Dokumentation:
- [SAAS_DEPLOYMENT_GUIDE.md](../../../docs/SAAS_DEPLOYMENT_GUIDE.md) - Windows-Version
- [Linux Deployment Guide](../../../docs/LINUX_SAAS_DEPLOYMENT_GUIDE.md) - Vollständige Linux-Anleitung

---

## 💡 Tipps

### Performance-Optimierung

```bash
# Wine mit optimierten Settings
export WINEDLLOVERRIDES="mscoree,mshtml="  # Deaktiviere .NET
export WINEDEBUG=-all  # Kein Debug-Output
```

### Automatisches Cleanup

```bash
# Alte Logs automatisch löschen (Cron)
0 0 * * * find /var/log/mt5 -type f -mtime +7 -delete
```

### Backup-Strategie

```bash
# Config-Backup
cp /opt/mt5/config.json /opt/mt5/backups/config_$(date +%Y%m%d).json

# Wine-Prefix Backup
tar czf wine_backup_$(date +%Y%m%d).tar.gz ~/.wine
```

---

## 📞 Support

- **GitHub Issues:** [https://github.com/stelona/signal-ea-v90/issues](https://github.com/stelona/signal-ea-v90/issues)
- **Email:** [support@stelona.com](mailto:support@stelona.com)
- **Docs:** [docs/LINUX_SAAS_DEPLOYMENT_GUIDE.md](../../../docs/LINUX_SAAS_DEPLOYMENT_GUIDE.md)

---

**© 2024 Stelona. All rights reserved.**
