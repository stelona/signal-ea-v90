# 🚀 Pre-Flight Workflow - Symbol Detection für SaaS Platform

## 🎯 Konzept

**Problem:** Broker-Suffixe sind erst NACH dem Login bekannt. Template muss aber VOR dem Customer-MT5-Start erstellt werden.

**Lösung:** **Pre-Flight Check** - Temporärer MT5-Start zur Symbol-Erkennung

---

## 📋 Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  1. CUSTOMER INPUT (Web Interface)                          │
│     → Login, Password, Broker                               │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  2. BACKEND: Erstellt login.ini                             │
│     [login.ini]                                             │
│     login=12345678                                          │
│     password=SecretPass                                     │
│     broker=IC Markets                                       │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  3. PRE-FLIGHT CHECK (mt5_preflight_check.py)               │
│     ✓ Temp-MT5 starten                                      │
│     ✓ Login mit credentials                                 │
│     ✓ Symbol-Liste auslesen via API                         │
│     ✓ Suffixe erkennen (BTCUSD.raw, ETHUSD.raw, etc.)      │
│     ✓ servers.dat zu S3 hochladen                          │
│     ✓ Suffix-Daten an Webhook senden                       │
│     ✓ MT5 beenden                                          │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  4. WEBHOOK EMPFÄNGT                                        │
│     {                                                        │
│       "crypto": {                                           │
│         "BTCUSD": {                                         │
│           "full_symbol": "BTCUSD.raw",                     │
│           "suffix": ".raw"                                  │
│         }                                                   │
│       },                                                    │
│       "broker_info": {                                      │
│         "server": "ICMarkets-Live10"                       │
│       },                                                    │
│       "servers_dat_s3": {                                  │
│         "bucket": "my-mt5-configs",                        │
│         "key": "customer-123/servers.dat"                  │
│       }                                                     │
│     }                                                       │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  5. IHR BACKEND                                             │
│     ✓ Erstellt Chart-Template mit korrektem Suffix          │
│     ✓ Template: BTCUSD.raw + signal.ex5                    │
│     ✓ Startet Customer-MT5 Container                        │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  6. CUSTOMER-MT5 LÄUFT                                      │
│     ✓ Lädt Template                                         │
│     ✓ signal.ex5 auf BTCUSD.raw H1                         │
│     ✓ Trading aktiv                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 Implementierung

### Schritt 1: Installation

```bash
# Python Dependencies
pip install -r requirements.txt

# Minimal (nur MT5 API):
pip install MetaTrader5

# Mit S3 und Webhook:
pip install MetaTrader5 boto3 requests
```

### Schritt 2: Pre-Flight Script ausführen

```bash
python3 mt5_preflight_check.py \
    --config /path/to/login.ini \
    --webhook-url https://api.ihredomain.com/mt5/symbols \
    --s3-bucket my-mt5-configs \
    --s3-prefix customer-123/ \
    --s3-region eu-central-1 \
    --output-json /tmp/symbols.json
```

**Parameter:**

| Parameter | Beschreibung | Required |
|-----------|-------------|----------|
| `--config` | Pfad zur login.ini | ✅ |
| `--webhook-url` | Webhook für Symbol-Daten | Optional |
| `--s3-bucket` | S3 Bucket für servers.dat | Optional |
| `--s3-prefix` | S3 Key Prefix (z.B. customer-123/) | Optional |
| `--s3-region` | AWS Region | Optional (default: eu-central-1) |
| `--output-json` | Lokales JSON Output | Optional |
| `--server` | Manueller Server-Name | Optional |

### Schritt 3: Webhook Payload verarbeiten

**Webhook erhält:**

```json
{
  "crypto": {
    "BTCUSD": {
      "base_symbol": "BTCUSD",
      "full_symbol": "BTCUSD.raw",
      "suffix": ".raw",
      "description": "Bitcoin vs US Dollar",
      "path": "Crypto"
    },
    "ETHUSD": {
      "base_symbol": "ETHUSD",
      "full_symbol": "ETHUSD.raw",
      "suffix": ".raw",
      "description": "Ethereum vs US Dollar",
      "path": "Crypto"
    }
  },
  "forex": {
    "EURUSD": {
      "base_symbol": "EURUSD",
      "full_symbol": "EURUSD",
      "suffix": "",
      "description": "Euro vs US Dollar",
      "path": "Forex"
    }
  },
  "indices": {
    "US30": {
      "base_symbol": "US30",
      "full_symbol": "US30",
      "suffix": "",
      "description": "US Wall Street 30",
      "path": "Indices"
    }
  },
  "broker_info": {
    "server": "ICMarkets-Live10",
    "company": "IC Markets",
    "currency": "USD"
  },
  "servers_dat_s3": {
    "bucket": "my-mt5-configs",
    "key": "customer-123/servers.dat",
    "region": "eu-central-1",
    "uploaded": true
  },
  "timestamp": "2024-01-15T10:30:45.123456"
}
```

### Schritt 4: Template erstellen (Ihr Backend)

**Python Beispiel:**

```python
import json

# Webhook Payload empfangen
data = request.get_json()

# Suffix extrahieren
btc_symbol = data['crypto']['BTCUSD']['full_symbol']  # "BTCUSD.raw"
eth_symbol = data['crypto']['ETHUSD']['full_symbol']  # "ETHUSD.raw"

# Template erstellen
template = f"""<chart>
symbol={btc_symbol}
period=60
<expert>
name=signal.ex5
path=Experts\\signal.ex5
expertmode=1
</expert>
</chart>
"""

# Template speichern
with open(f'/opt/mt5/customer-{customer_id}/AutoStart.tpl', 'w') as f:
    f.write(template)

# Customer-MT5 starten
start_customer_mt5(customer_id)
```

**Node.js Beispiel:**

```javascript
// Webhook Handler
app.post('/mt5/symbols', async (req, res) => {
  const data = req.body;

  // Suffix extrahieren
  const btcSymbol = data.crypto.BTCUSD.full_symbol;  // "BTCUSD.raw"

  // Template erstellen
  const template = `<chart>
symbol=${btcSymbol}
period=60
<expert>
name=signal.ex5
path=Experts\\signal.ex5
expertmode=1
</expert>
</chart>`;

  // Template speichern
  await fs.writeFile(
    `/opt/mt5/customer-${customerId}/AutoStart.tpl`,
    template
  );

  // Customer-MT5 starten
  await startCustomerMT5(customerId);

  res.json({ status: 'ok' });
});
```

### Schritt 5: servers.dat von S3 abrufen (später)

**Für späteren Login auf anderen Servern:**

```python
import boto3

s3 = boto3.client('s3')

# servers.dat herunterladen
s3.download_file(
    'my-mt5-configs',
    'customer-123/servers.dat',
    '/tmp/servers.dat'
)

# In MT5 Terminal kopieren
import shutil
shutil.copy(
    '/tmp/servers.dat',
    '~/.wine/drive_c/.../Terminal/<hash>/config/servers.dat'
)
```

---

## 🐳 Docker Integration

### docker-compose.yml

```yaml
version: '3.8'

services:
  mt5-preflight:
    image: your-mt5-image:latest
    container_name: mt5-preflight-${CUSTOMER_ID}
    environment:
      - DISPLAY=:99
      - CUSTOMER_ID=${CUSTOMER_ID}
      - WEBHOOK_URL=${WEBHOOK_URL}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    volumes:
      - ./login.ini:/opt/mt5/login.ini:ro
      - ./mt5_preflight_check.py:/opt/mt5/preflight.py:ro
    command: >
      bash -c "
        Xvfb :99 &
        wine terminal64.exe &
        sleep 10
        python3 /opt/mt5/preflight.py
          --config /opt/mt5/login.ini
          --webhook-url ${WEBHOOK_URL}
          --s3-bucket ${S3_BUCKET}
          --s3-prefix customer-${CUSTOMER_ID}/
      "
    restart: "no"  # Run once
```

### Startup Script

```bash
#!/bin/bash
# preflight.sh

set -e

CUSTOMER_ID=$1
LOGIN=$2
PASSWORD=$3
BROKER=$4

# 1. Erstelle login.ini
cat > /tmp/login-${CUSTOMER_ID}.ini <<EOF
login=${LOGIN}
password=${PASSWORD}
broker=${BROKER}
EOF

# 2. Start Pre-Flight Container
docker-compose run --rm \
  -e CUSTOMER_ID=${CUSTOMER_ID} \
  -e WEBHOOK_URL=https://api.example.com/mt5/symbols \
  -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
  -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
  -v /tmp/login-${CUSTOMER_ID}.ini:/opt/mt5/login.ini:ro \
  mt5-preflight

# 3. Warte auf Webhook (in Ihrem Backend)
echo "✓ Pre-Flight abgeschlossen - Webhook sollte Suffixe erhalten haben"

# 4. Ihr Backend startet jetzt Customer-MT5 mit korrektem Template
```

---

## 📊 Beispiel-Output

### Console Output:

```
═══════════════════════════════════════════════════════════
  MT5 Pre-Flight Check v1.0 - Stelona
═══════════════════════════════════════════════════════════

═══════════════════════════════════════════════════════════
  MT5 Initialisierung
═══════════════════════════════════════════════════════════
✓ MT5 initialisiert
  Version: 5382
  Path: /root/.wine/drive_c/Program Files/MetaTrader 5

═══════════════════════════════════════════════════════════
  MT5 Login
═══════════════════════════════════════════════════════════
  Account: 12345678
  Server:  ICMarkets-Live10
✓ Login erfolgreich!
  Server:  ICMarkets-Live10
  Balance: 10000.00 USD
  Hebel:   1:500

═══════════════════════════════════════════════════════════
  Symbol-Erkennung
═══════════════════════════════════════════════════════════
  Scanne Crypto-Symbole...
✓ BTCUSD → BTCUSD.raw
✓ ETHUSD → ETHUSD.raw
✓ XRPUSD → XRPUSD.raw
✓ LTCUSD → LTCUSD.raw

  Scanne Forex-Symbole...
✓ EURUSD → EURUSD
✓ GBPUSD → GBPUSD
✓ USDJPY → USDJPY

  Scanne Indizes...
✓ US30 → US30
✓ US100 → US100
✓ US500 → US500

═══════════════════════════════════════════════════════════
  Suche servers.dat
═══════════════════════════════════════════════════════════
  MT5 Data Path: /root/.wine/drive_c/users/root/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075
✓ Gefunden: .../Terminal/.../config/servers.dat

═══════════════════════════════════════════════════════════
  S3 Upload
═══════════════════════════════════════════════════════════
  Datei:   .../config/servers.dat
  Bucket:  my-mt5-configs
  Key:     customer-123/servers.dat
  Region:  eu-central-1
✓ S3 Upload erfolgreich!

═══════════════════════════════════════════════════════════
  Webhook Notification
═══════════════════════════════════════════════════════════
  URL: https://api.example.com/mt5/symbols
  Payload: 1245 bytes
✓ Webhook erfolgreich! Status: 200

✓ MT5 beendet

═══════════════════════════════════════════════════════════
  ✓ PRE-FLIGHT CHECK ABGESCHLOSSEN
═══════════════════════════════════════════════════════════
  Crypto-Symbole:  5/5
  Forex-Symbole:   7/5
  Indizes:         5/5
  servers.dat S3:  ✓
  Webhook:         ✓
═══════════════════════════════════════════════════════════

✓ Ihr System kann jetzt Customer-MT5 mit korrektem Template starten!
```

---

## 🔍 Troubleshooting

### Problem: boto3 oder requests nicht installiert

**Symptom:**
```
⚠ WARNING: boto3 not installed - S3 upload disabled
```

**Lösung:**
```bash
pip install boto3 requests
```

### Problem: AWS Credentials nicht gefunden

**Symptom:**
```
✗ ERROR: AWS Credentials nicht gefunden!
```

**Lösung:**

```bash
# Option 1: Environment Variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# Option 2: AWS CLI Config
aws configure

# Option 3: IAM Role (EC2/ECS)
# Automatisch wenn auf AWS ausgeführt
```

### Problem: Webhook Timeout

**Symptom:**
```
✗ ERROR: Webhook Timeout nach 10s
```

**Lösung:**

```bash
# Timeout erhöhen
python3 mt5_preflight_check.py \
    --webhook-timeout 30
```

### Problem: servers.dat nicht gefunden

**Symptom:**
```
✗ ERROR: servers.dat nicht gefunden!
```

**Lösung:**

servers.dat wird erst NACH dem ersten Login erstellt. Führen Sie Pre-Flight Check NACH erfolgreichem Login aus.

```bash
# Manuell prüfen
find ~/.wine -name "servers.dat"

# Sollte finden:
# ~/.wine/drive_c/users/<user>/AppData/Roaming/MetaQuotes/Terminal/<hash>/config/servers.dat
```

---

## 🎯 Vorteile

| Vorteil | Beschreibung |
|---------|-------------|
| **✅ Suffix vor Template-Erstellung bekannt** | Template kann mit korrektem Symbol erstellt werden |
| **✅ servers.dat in S3** | Für späteren Login auf anderen Servern |
| **✅ Webhook Integration** | Einfache Integration in Ihr Backend |
| **✅ JSON Output** | Lokales Backup der Symbol-Daten |
| **✅ Broker-neutral** | Funktioniert mit allen Brokern |
| **✅ Fehlerbehandlung** | Graceful degradation (boto3/requests optional) |

---

## 📝 Zusammenfassung

### Workflow:

```
1. Customer gibt Zugangsdaten ein
   ↓
2. Backend erstellt login.ini
   ↓
3. Pre-Flight Check:
   - Login
   - Symbol-Liste auslesen
   - Suffixe erkennen
   - servers.dat → S3
   - Suffixe → Webhook
   ↓
4. Ihr Backend:
   - Empfängt Webhook
   - Erstellt Template mit korrektem Suffix
   - Startet Customer-MT5
   ↓
5. ✅ EA läuft auf korrektem Symbol
```

### Files:

- **`mt5_preflight_check.py`** - Pre-Flight Script
- **`requirements.txt`** - Python Dependencies
- **`PREFLIGHT_WORKFLOW.md`** - Diese Doku

### Integration:

**Minimal (nur MT5 API):**
```bash
pip install MetaTrader5
python3 mt5_preflight_check.py --config login.ini --output-json symbols.json
```

**Mit S3 + Webhook:**
```bash
pip install -r requirements.txt
python3 mt5_preflight_check.py \
    --config login.ini \
    --webhook-url https://api.example.com/mt5/symbols \
    --s3-bucket my-configs \
    --s3-prefix customer-123/
```

---

**© 2024 Stelona. All rights reserved.**
