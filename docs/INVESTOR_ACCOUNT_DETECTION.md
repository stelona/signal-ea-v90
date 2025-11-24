# 🔐 Investor-Account Detection

## 🎯 Was ist ein Investor-Account?

MetaTrader 5 bietet zwei Arten von Account-Zugängen:

### 1. **Trading Account (Full Access)**
- ✅ Vollzugriff auf Account
- ✅ Kann Orders platzieren
- ✅ Kann EAs ausführen
- ✅ Kann manuell traden
- **Verwendung:** Production Trading

### 2. **Investor Account (Read-Only)**
- ✅ Kann Account-Stand sehen
- ✅ Kann History sehen
- ✅ Kann Charts sehen
- ❌ **KANN NICHT handeln**
- ❌ **KANN KEINE EAs ausführen**
- **Verwendung:** Monitoring, Portfolio-Viewing, Performance-Tracking

---

## ⚠️ Warum ist das wichtig?

**Für Ihre SaaS-Plattform:**

Wenn ein Kunde versehentlich **Investor-Credentials** statt **Trading-Credentials** eingibt:

```
❌ Problem:
1. Login funktioniert ✓
2. Symbole werden erkannt ✓
3. Template wird erstellt ✓
4. EA wird geladen ✓
5. EA kann NICHT handeln ✗  ← KRITISCH!

→ Kunde beschwert sich: "EA funktioniert nicht!"
→ Support-Aufwand erhöht
→ Schlechte User-Experience
```

**Lösung:** Pre-Flight Check erkennt Investor-Accounts und **warnt SOFORT**.

---

## 🔍 Wie funktioniert die Erkennung?

### MT5 Python API Properties:

```python
account_info = mt5.account_info()

# Investor-Account Erkennung:
is_investor = not account_info.trade_allowed

# Zusätzliche Checks:
trade_allowed = account_info.trade_allowed    # False = Investor
trade_expert = account_info.trade_expert      # False = EAs nicht erlaubt
```

### Script Logic:

```python
def check_investor_mode() -> Dict:
    """Prüft ob Account im Investor-Modus ist"""
    account_info = mt5.account_info()

    is_investor = not account_info.trade_allowed

    return {
        'is_investor': is_investor,
        'trade_allowed': account_info.trade_allowed,
        'trade_expert': account_info.trade_expert,
        'trade_mode': 'INVESTOR (Read-Only)' if is_investor else 'TRADING (Full Access)'
    }
```

---

## 📊 Output Beispiele

### Trading Account (Normal):

```
═══════════════════════════════════════════════════════════
  MT5 Login
═══════════════════════════════════════════════════════════
  Account: 12345678
  Server:  ICMarkets-Live10
✓ Login erfolgreich!
  Server:  ICMarkets-Live10
  Balance: 10000.00 USD
  Hebel:   1:500
✓ Account-Typ: TRADING (Full Access)
  Expert Advisors erlaubt: True
```

### Investor Account (Read-Only):

```
═══════════════════════════════════════════════════════════
  MT5 Login
═══════════════════════════════════════════════════════════
  Account: 12345678
  Server:  ICMarkets-Live10
✓ Login erfolgreich!
  Server:  ICMarkets-Live10
  Balance: 10000.00 USD
  Hebel:   1:500

⚠ WARNING: INVESTOR-MODUS ERKANNT!
  Account-Typ: INVESTOR (Read-Only)
  Trading erlaubt: False
  Expert Advisors: False

✗ ERROR: Investor-Accounts können keine EAs ausführen!
  Verwenden Sie einen Trading-Account für EA-Betrieb.
  Oder: --allow-investor Flag zum Ignorieren
```

**Script bricht ab!** ❌

---

## 🚀 Verwendung

### Standard (Script bricht bei Investor ab):

```bash
# Linux
python3 mt5_preflight_check.py --config login.ini

# Windows
python mt5_preflight_check_windows.py --config login.ini
```

**Ergebnis bei Investor-Account:** ❌ Script stoppt mit Fehler

### Mit --allow-investor Flag (Warnung, aber kein Abbruch):

```bash
# Linux
python3 mt5_preflight_check.py \
    --config login.ini \
    --allow-investor

# Windows
python mt5_preflight_check_windows.py ^
    --config login.ini ^
    --allow-investor
```

**Ergebnis bei Investor-Account:** ⚠️ Warnung, aber Script läuft weiter

---

## 📄 JSON Output

### Mit Account-Type Information:

```json
{
  "crypto": { ... },
  "forex": { ... },
  "broker_info": {
    "server": "ICMarkets-Live10",
    "company": "IC Markets",
    "currency": "USD"
  },
  "account_type": {
    "is_investor": false,
    "trade_allowed": true,
    "trade_expert": true,
    "trade_mode": "TRADING (Full Access)"
  },
  "timestamp": "2024-01-15T10:30:45.123456"
}
```

### Investor Account:

```json
{
  "crypto": { ... },
  "forex": { ... },
  "broker_info": {
    "server": "ICMarkets-Live10",
    "company": "IC Markets",
    "currency": "USD"
  },
  "account_type": {
    "is_investor": true,
    "trade_allowed": false,
    "trade_expert": false,
    "trade_mode": "INVESTOR (Read-Only)"
  },
  "timestamp": "2024-01-15T10:30:45.123456"
}
```

---

## 🔧 Integration in Backend

### Webhook Handler Beispiel:

```python
# Webhook empfängt Daten
data = request.get_json()

# Prüfe Account-Typ
account_type = data.get('account_type', {})

if account_type.get('is_investor'):
    # INVESTOR-ACCOUNT ERKANNT!

    return {
        'status': 'error',
        'message': 'Investor-Account erkannt. Bitte verwenden Sie Trading-Credentials.',
        'details': {
            'trade_allowed': account_type['trade_allowed'],
            'trade_mode': account_type['trade_mode']
        }
    }, 400

# TRADING-ACCOUNT → OK
# Erstelle Template und starte Customer-MT5
...
```

### User-Friendly Error Message:

```
❌ Fehler: Investor-Zugang erkannt

Sie haben sich mit Investor-Credentials angemeldet.
Investor-Zugänge können keine Expert Advisors ausführen.

Bitte verwenden Sie Ihre Trading-Credentials:
- Öffnen Sie MT5
- Datei → Login
- Verwenden Sie Ihr Trading-Passwort (nicht Investor-Passwort)

Oder erstellen Sie neue Trading-Credentials bei Ihrem Broker.
```

---

## 🧪 Testing

### Wie erstellt man einen Investor-Account?

**In MetaTrader 5:**

1. Öffnen Sie MT5
2. Tools → Options → Server
3. Klick auf "Change" bei Ihrem Account
4. Tab "Investor"
5. Setzen Sie ein Investor-Passwort
6. Speichern

**Testen:**

```bash
# login.ini mit Investor-Credentials
login=12345678
password=InvestorPasswort
broker=IC Markets

# Script ausführen
python3 mt5_preflight_check.py --config login.ini

# Erwartetes Ergebnis:
# ⚠ WARNING: INVESTOR-MODUS ERKANNT!
# ✗ ERROR: Investor-Accounts können keine EAs ausführen!
# Exit Code: 1
```

---

## 📋 Use Cases

### Use Case 1: Customer Protection

**Szenario:** Kunde gibt versehentlich Investor-Passwort ein

**Ohne Detection:**
```
1. Login funktioniert ✓
2. EA wird geladen ✓
3. EA handelt nicht ✗
4. Kunde: "Ihr Service funktioniert nicht!" ✗
5. Support-Ticket ✗
```

**Mit Detection:**
```
1. Login funktioniert ✓
2. Investor-Account erkannt ⚠️
3. Klare Fehlermeldung ✓
4. Kunde korrigiert Passwort ✓
5. Kein Support-Ticket ✓
```

### Use Case 2: Portfolio Monitoring

**Szenario:** Interner Monitoring-Service (nicht für Trading)

```bash
# Mit --allow-investor Flag
python3 mt5_preflight_check.py \
    --config monitor.ini \
    --allow-investor \
    --output-json monitor-data.json

# Script läuft durch
# Daten werden gesammelt
# Kein Trading nötig
```

### Use Case 3: Backend Validation

**Szenario:** Validierung vor Container-Start

```python
# Pre-Flight Check
result = run_preflight_check(customer_id)

if result['account_type']['is_investor']:
    send_email_to_customer(
        subject="Trading-Credentials erforderlich",
        body="Bitte verwenden Sie Trading-Passwort..."
    )
    return False

# OK - starte Customer-MT5
start_customer_mt5(customer_id)
```

---

## 🎯 Best Practices

### Für SaaS-Plattform:

1. **Immer prüfen:** Investor-Accounts VOR Container-Start erkennen
2. **Clear Error Messages:** User-friendly Fehlermeldungen
3. **Documentation:** Erklären Sie Unterschied Trading vs. Investor
4. **Support:** FAQ-Eintrag für häufiges Problem

### Für User Interface:

```
┌─────────────────────────────────────────────┐
│  MT5 Zugangsdaten                           │
├─────────────────────────────────────────────┤
│  Account-Nummer: [12345678      ]           │
│  Passwort:       [**********    ]           │
│  Broker:         [IC Markets  ▼]            │
│                                              │
│  ⚠️ Wichtig: Verwenden Sie Ihr              │
│     TRADING-Passwort (nicht Investor)       │
│                                              │
│  [?] Was ist der Unterschied?               │
│                                              │
│  [ Zugangsdaten validieren ]                │
└─────────────────────────────────────────────┘
```

---

## 🔍 Troubleshooting

### Problem: "Script bricht bei meinem Account ab"

**Symptom:**
```
⚠ WARNING: INVESTOR-MODUS ERKANNT!
✗ ERROR: Investor-Accounts können keine EAs ausführen!
```

**Lösung:**

**Option 1: Trading-Passwort verwenden**
1. Loggen Sie sich in MT5 mit Trading-Passwort ein
2. Nicht mit Investor-Passwort!
3. Aktualisieren Sie login.ini

**Option 2: Flag verwenden (nur zu Test-Zwecken)**
```bash
python3 mt5_preflight_check.py --config login.ini --allow-investor
```

### Problem: "Ich weiß nicht welches Passwort ich habe"

**Test:**
1. Öffnen Sie MT5
2. Loggen Sie sich ein
3. Tools → Options → Trade → "Expert Advisors"
4. Ist "Allow automated trading" verfügbar?
   - ✅ JA → Trading-Account
   - ❌ NEIN (ausgegraut) → Investor-Account

### Problem: "Ich brauche ein neues Trading-Passwort"

**Bei Broker anfragen:**
1. Kontaktieren Sie Ihren Broker-Support
2. Fragen Sie nach: "Main Password" oder "Trading Password"
3. NICHT: "Investor Password"

---

## 📊 Zusammenfassung

| Feature | Trading Account | Investor Account |
|---------|----------------|------------------|
| **Login** | ✅ | ✅ |
| **Charts** | ✅ | ✅ |
| **History** | ✅ | ✅ |
| **Trading** | ✅ | ❌ |
| **EAs** | ✅ | ❌ |
| **Script Detection** | `is_investor: false` | `is_investor: true` |
| **Script Default** | ✅ Weiter | ❌ Abbruch |
| **Mit --allow-investor** | ✅ Weiter | ⚠️ Warnung + Weiter |

---

## ✅ Vorteile der Detection

1. **✅ Frühe Fehler-Erkennung:** Vor Container-Start
2. **✅ Bessere UX:** Klare Fehlermeldungen
3. **✅ Weniger Support:** Verhindert häufiges Problem
4. **✅ Customer Protection:** Kein "EA funktioniert nicht"-Frust
5. **✅ Backend Integration:** account_type in JSON/Webhook

---

**© 2024 Stelona. All rights reserved.**
