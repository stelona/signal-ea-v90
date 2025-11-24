# 🤖 MT5 Auto-Login + EA Auto-Load - Vollständige Anleitung

## 🎯 Was macht das Script?

Das erweiterte Script (`auto_login_with_ea.py`) führt **vollautomatisch** aus:

1. ✅ Login in MT5 (wie vorher)
2. ✅ **Broker-Suffixe automatisch erkennen** (z.B. `.raw`, `.m`, etc.)
3. ✅ **BTCUSD mit richtigem Suffix finden** (z.B. `BTCUSD.raw`)
4. ✅ **Chart-Template mit EA erstellen**
5. ✅ **Optional: MT5 neu starten** für automatisches EA-Laden

---

## 🚀 Quick Start (für Ihr Docker-Setup)

### **Schritt 1: Script in Container kopieren**

```bash
docker cp src/automation/linux/auto_login_with_ea.py IHR_CONTAINER:/opt/mt5/
chmod +x /opt/mt5/auto_login_with_ea.py
```

### **Schritt 2: In Ihrem Docker-Entrypoint**

```bash
#!/bin/bash
# docker-entrypoint.sh

# 1. MT5 starten (wie bisher)
wine terminal64.exe &

# 2. Warte bis MT5 bereit ist
sleep 10

# 3. NEUER SCHRITT: Auto-Login + EA-Setup
python3 /opt/mt5/auto_login_with_ea.py \
    --config /opt/mt5/login.ini \
    --ea signal.ex5 \
    --symbol BTCUSD \
    --restart

# Script wird MT5 neu starten und Template laden!
```

**Das war's!** ZERO manuelle Interaktion.

---

## 📋 Verwendung

### **Basis (mit MT5-Neustart)**

```bash
python3 auto_login_with_ea.py \
    --config /pfad/zu/login.ini \
    --ea signal.ex5 \
    --restart
```

### **Mit spezifischem Symbol**

```bash
python3 auto_login_with_ea.py \
    --config /pfad/zu/login.ini \
    --ea signal.ex5 \
    --symbol BTCUSD \
    --restart
```

### **Ohne Neustart (nur Template erstellen)**

```bash
python3 auto_login_with_ea.py \
    --config /pfad/zu/login.ini \
    --ea signal.ex5
```

---

## 🔍 Was passiert im Detail?

### **1. Broker-Suffix-Erkennung**

Das Script analysiert alle verfügbaren Symbole und erkennt automatisch, welches Suffix Ihr Broker verwendet:

```
Beispiel IC Markets Raw:
- Gefunden: BTCUSD.raw
- Suffix erkannt: .raw

Beispiel Pepperstone:
- Gefunden: BTCUSD
- Suffix erkannt: (kein Suffix)

Beispiel XM:
- Gefunden: BTCUSDm
- Suffix erkannt: m
```

**Output:**
```
═══════════════════════════════════════════════════════════
  Erkenne Broker-Suffix für Symbole
═══════════════════════════════════════════════════════════
Gefunden: 1234 Symbole
  Gefunden: BTCUSD.raw
✓ Suffix erkannt: '.raw' (vollständig: BTCUSD.raw)
```

### **2. Symbol-Validierung**

```
Suche Symbol: BTCUSD.raw
✓ Symbol gefunden und aktiv: BTCUSD.raw
  Beschreibung: Bitcoin vs US Dollar
  Spread:       50
```

### **3. Chart-Template-Erstellung**

Das Script erstellt ein MT5-Template mit folgender Konfiguration:
- **Symbol:** BTCUSD.raw (mit erkanntem Suffix)
- **Timeframe:** H1 (1 Stunde)
- **EA:** signal.ex5 (automatisch geladen)

**Template-Pfad:**
```
~/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Profiles/Templates/AutoStart.tpl
```

### **4. MT5-Neustart (optional)**

Wenn `--restart` angegeben:
1. Script erstellt Template
2. Script beendet MT5 (`mt5.shutdown()`)
3. Docker/systemd startet MT5 automatisch neu
4. MT5 lädt Template automatisch
5. EA ist auf dem Chart aktiv

---

## 🐳 Docker-Integration

### **Komplettes Beispiel für Ihr Setup**

```bash
#!/bin/bash
# docker-entrypoint.sh

set -e

echo "Starting MT5 SaaS Container..."

# Xvfb starten (haben Sie bereits)
Xvfb :99 -screen 0 1024x768x24 &
export DISPLAY=:99
sleep 2

# ════════════════════════════════════════════════════════
# MT5 MIT AUTO-LOGIN + EA-SETUP
# ════════════════════════════════════════════════════════

# Funktion für MT5-Start mit Auto-Login
start_mt5_with_ea() {
    echo "═══════════════════════════════════════════════════════════"
    echo "  Starting MT5 with Auto-Login + EA Setup"
    echo "═══════════════════════════════════════════════════════════"

    # 1. MT5 im Hintergrund starten
    wine "C:\Program Files\MetaTrader 5\terminal64.exe" &
    local mt5_pid=$!

    echo "MT5 started (PID: $mt5_pid)"
    echo "Waiting for MT5 to initialize..."
    sleep 10

    # 2. Auto-Login + EA-Setup
    echo "Running Auto-Login + EA Setup..."
    python3 /opt/mt5/auto_login_with_ea.py \
        --config /opt/mt5/login.ini \
        --ea signal.ex5 \
        --symbol BTCUSD \
        --restart

    # Script wird MT5 beenden und neu starten
    echo "Waiting for MT5 restart..."
    sleep 5

    # 3. MT5 erneut starten (mit Template)
    echo "Starting MT5 with EA Template..."
    wine "C:\Program Files\MetaTrader 5\terminal64.exe" &

    echo "✓ MT5 running with EA on BTCUSD H1"
}

# Starte MT5 mit Auto-Login + EA
start_mt5_with_ea

# Container am Leben halten
echo "Container ready - MT5 running with EA"
tail -f /var/log/mt5/mt5.log
```

---

## 🔧 Anpassungen

### **Anderes Symbol verwenden**

```bash
python3 auto_login_with_ea.py \
    --config /opt/mt5/login.ini \
    --ea signal.ex5 \
    --symbol EURUSD \
    --restart
```

### **Anderen EA verwenden**

```bash
python3 auto_login_with_ea.py \
    --config /opt/mt5/login.ini \
    --ea MyExpertAdvisor.ex5 \
    --restart
```

### **Mehrere Symbole/EAs (Multi-Chart)**

Rufen Sie das Script mehrfach auf (ohne `--restart`), dann einmal mit `--restart`:

```bash
# Chart 1: BTCUSD
python3 auto_login_with_ea.py --ea signal.ex5 --symbol BTCUSD

# Chart 2: ETHUSD
python3 auto_login_with_ea.py --ea signal.ex5 --symbol ETHUSD

# Chart 3: EURUSD (mit Neustart)
python3 auto_login_with_ea.py --ea signal.ex5 --symbol EURUSD --restart
```

---

## 📊 Output-Beispiel

```
═══════════════════════════════════════════════════════════
  MT5 Auto-Login + EA Setup v2.0 - Stelona
═══════════════════════════════════════════════════════════

Lese Konfigurationsdatei: /opt/mt5/login.ini
✓ Config geladen: Login=12345678, Broker=IC Markets

Initialisiere MT5-Verbindung...
✓ MT5 erfolgreich initialisiert
MT5 Version: 5.0.40 (Build 4300)

Suche Server für Broker: IC Markets
✓ Server gefunden (Live): ICMarketsSC-Live10

═══════════════════════════════════════════════════════════
  MT5 Login-Versuch
═══════════════════════════════════════════════════════════
Account: 12345678
Server:  ICMarketsSC-Live10

✓ Login erfolgreich!
Name:     John Doe
Balance:  10000.00 USD

═══════════════════════════════════════════════════════════
  EA Auto-Setup
═══════════════════════════════════════════════════════════

═══════════════════════════════════════════════════════════
  Erkenne Broker-Suffix für Symbole
═══════════════════════════════════════════════════════════
Gefunden: 1234 Symbole
  Gefunden: BTCUSD.raw
✓ Suffix erkannt: '.raw' (vollständig: BTCUSD.raw)

Suche Symbol: BTCUSD.raw
✓ Symbol gefunden und aktiv: BTCUSD.raw
  Beschreibung: Bitcoin vs US Dollar
  Spread:       50

═══════════════════════════════════════════════════════════
  Erstelle Chart-Template mit EA
═══════════════════════════════════════════════════════════
✓ Template erstellt: ~/.wine/.../Templates/AutoStart.tpl

═══════════════════════════════════════════════════════════
  ✓ SETUP ABGESCHLOSSEN!
═══════════════════════════════════════════════════════════

Symbol gefunden: BTCUSD.raw
EA:              signal.ex5
Template:        AutoStart.tpl

MT5-Neustart gewünscht...
✓ MT5 heruntergefahren - wird automatisch neu gestartet
```

---

## 🛡️ Wichtige Hinweise

### **MT5 Python API Limitation**

⚠️ Die MT5 Python API kann **KEINE EAs direkt auf Charts laden**!

**Workaround (das nutzt das Script):**
1. Erstellt ein Chart-Template (`.tpl` Datei)
2. Template enthält Symbol, Timeframe und EA-Konfiguration
3. MT5 neu starten → Template wird automatisch geladen
4. EA läuft auf dem Chart

### **Warum MT5-Neustart?**

Nach dem Erstellen des Templates muss MT5 neu gestartet werden, damit:
1. Das Template erkannt wird
2. Der EA automatisch auf den Chart geladen wird

**Das ist OK laut Ihrer Anforderung:** "Sollte ein Neustart nötig sein, ist das kein Problem"

### **Vollautomatisch im Docker**

In Docker ist der Neustart kein Problem:
```bash
# Script beendet MT5 mit mt5.shutdown()
# Docker-Restart-Policy startet MT5 automatisch neu
# Oder: Ihr Entrypoint-Script startet MT5 erneut
```

---

## 🔍 Troubleshooting

### **Problem: "Symbol nicht gefunden"**

**Lösung:** Prüfen Sie verfügbare Symbole:
```python
import MetaTrader5 as mt5
mt5.initialize()
mt5.login(...)
symbols = mt5.symbols_get()
for s in symbols:
    if 'BTC' in s.name:
        print(s.name)
```

### **Problem: "Template nicht geladen"**

**Ursache:** MT5 wurde nicht neu gestartet

**Lösung:** Verwenden Sie `--restart` Flag:
```bash
python3 auto_login_with_ea.py --config ... --restart
```

### **Problem: "EA nicht auf Chart"**

**Ursache:** Template-Pfad falsch oder EA nicht gefunden

**Lösung:** Prüfen Sie:
```bash
# 1. EA existiert?
ls ~/.wine/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Experts/signal.ex5

# 2. Template erstellt?
ls ~/.wine/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Profiles/Templates/AutoStart.tpl

# 3. Logs prüfen
tail -f /var/log/mt5/auto_login.log
```

---

## 📝 Zusammenfassung

| Schritt | Beschreibung | Automatisch? |
|---------|--------------|--------------|
| 1. MT5 Start | Wine startet MT5 | ✅ Ja |
| 2. Login | Script loggt ein | ✅ Ja |
| 3. Suffix-Erkennung | Findet `.raw`, `.m`, etc. | ✅ Ja |
| 4. Symbol-Suche | Findet BTCUSD.raw | ✅ Ja |
| 5. Template-Erstellung | Erstellt .tpl mit EA | ✅ Ja |
| 6. MT5-Neustart | Script beendet MT5 | ✅ Ja |
| 7. Template laden | MT5 lädt EA automatisch | ✅ Ja |

**Ergebnis:** EA läuft auf BTCUSD H1 - **ZERO manuelle Interaktion!** 🎯

---

## 📞 Support

Bei Fragen oder Problemen:
- **GitHub Issues:** https://github.com/stelona/signal-ea-v90/issues
- **Email:** support@stelona.com

---

**© 2024 Stelona. All rights reserved.**
