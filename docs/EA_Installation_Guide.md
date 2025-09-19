# 🚀 EA INSTALLATION & SETUP GUIDE - Schritt für Schritt

## 📁 **BENÖTIGTE DATEIEN**

### **NUR EINE DATEI ERFORDERLICH:**
✅ **`Complete_Signal_EA_v92_Universal.mq5`** - Das ist alles!

**KEINE weiteren Dateien nötig:**
- ❌ Keine .mqh Include-Dateien
- ❌ Keine DLL-Dateien  
- ❌ Keine zusätzlichen Libraries
- ❌ Keine Konfigurationsdateien

**Die Universal Asset Classification v9.2 ist bereits vollständig in die .mq5 Datei integriert!**

---

## 🔧 **SCHRITT-FÜR-SCHRITT INSTALLATION**

### **SCHRITT 1: EA-Datei herunterladen**

**Option A: Direkt von GitHub**
```
https://raw.githubusercontent.com/stelona/signal-ea-v90/main/src/main/Complete_Signal_EA_v92_Universal.mq5
```
- Rechtsklick → "Speichern unter..."
- Speichern als: `Complete_Signal_EA_v92_Universal.mq5`

**Option B: Aus der Anhang-Datei**
- Die Datei ist bereits in der vorherigen Nachricht angehängt
- Einfach herunterladen und speichern

### **SCHRITT 2: EA in MetaTrader 5 installieren**

1. **MetaTrader 5 öffnen**
2. **MetaEditor öffnen:**
   - Drücken Sie `F4` ODER
   - Menü: `Tools → MetaQuotes Language Editor`
3. **EA-Datei öffnen:**
   - `File → Open` → Wählen Sie die heruntergeladene .mq5 Datei
4. **EA kompilieren:**
   - Drücken Sie `F7` ODER
   - Klicken Sie auf den "Compile" Button
   - **Erwartung:** "0 errors, 0 warnings" - Kompilierung erfolgreich

### **SCHRITT 3: WebRequest aktivieren (KRITISCH!)**

**OHNE DIESEN SCHRITT FUNKTIONIERT DER EA NICHT!**

1. **MetaTrader 5 Optionen öffnen:**
   - `Tools → Options`
2. **Expert Advisors Tab wählen**
3. **WebRequest aktivieren:**
   - ✅ Häkchen bei "Allow WebRequest for listed URL"
   - **URL hinzufügen:** `https://n8n.stelona.com`
   - Klicken Sie "Add URL"
4. **Weitere Einstellungen:**
   - ✅ "Allow automated trading"
   - ✅ "Allow DLL imports" (falls verfügbar)

### **SCHRITT 4: EA auf Chart anwenden**

1. **Chart öffnen:**
   - Beliebiges Symbol (z.B. EURUSD)
   - Beliebiger Timeframe (z.B. M5)
2. **EA anwenden:**
   - Navigator → Expert Advisors → `Complete_Signal_EA_v92_Universal`
   - Drag & Drop auf den Chart
3. **EA-Parameter konfigurieren:**
   ```
   === API CONFIGURATION ===
   signal_api_url = "https://n8n.stelona.com/webhook/get-signal2"
   position_api_url = "https://n8n.stelona.com/webhook/check-status"
   delivery_api_url = "https://n8n.stelona.com/webhook/signal-delivery"
   login_api_url = "https://n8n.stelona.com/webhook/login-status"
   
   === TRADING SETTINGS ===
   risk_percent = 5.0  ← ULTRA-SICHER (Max 5%)
   magic_number = 12345
   enable_break_even = true
   
   === DEBUG & TESTING ===
   debug_mode = true  ← AKTIVIEREN für detaillierte Logs
   verbose_signal_check = false
   enable_manual_test = false
   ```
4. **"OK" klicken**

---

## ✅ **ERFOLGS-VALIDIERUNG**

### **Erwartete Log-Meldungen nach Start:**
```
[⚡] ════════════════════════════════════════════
[⚡] 🌍 Signal EA v9.2-UNIVERSAL - Initialisierung
[⚡] 🎯 UNIVERSAL ASSET CLASSIFICATION AKTIV
[⚡] 🛡️ ULTRA-SICHERE RISIKO-KONTROLLE AKTIV
[⚡] ════════════════════════════════════════════
[⚡] Account ID: 12345678
[⚡] Balance: 5000.00 EUR
[SUCCESS] ✅ Broker-Suffix gefunden: '.ecn'
[⚡] ✅ EA v9.2-UNIVERSAL erfolgreich initialisiert
[⚡] 🌍 UNIVERSAL ASSET CLASSIFICATION: 16 Asset-Typen unterstützt
[⚡] 🛡️ ULTRA-SICHERE LOTSIZE-BERECHNUNG: Niemals mehr als 5% Risiko
[⚡] ════════════════════════════════════════════
```

### **Wenn Sie diese Meldungen sehen → EA läuft korrekt! ✅**

---

## 🚨 **HÄUFIGE PROBLEME & LÖSUNGEN**

### **Problem 1: "URL not allowed" Fehler**
```
[ERROR] Fehler 4060: URL nicht in der Liste der erlaubten URLs
```
**Lösung:**
- WebRequest-Einstellungen prüfen (Schritt 3)
- URL korrekt hinzugefügt: `https://n8n.stelona.com`

### **Problem 2: EA kompiliert nicht**
```
Compilation errors found
```
**Lösung:**
- Stellen Sie sicher, dass Sie die komplette .mq5 Datei haben
- Keine Zeichen beim Copy/Paste verloren gegangen
- MetaTrader 5 Build 3815+ verwenden

### **Problem 3: Keine Signale empfangen**
```
[VERBOSE] Keine Antwort von Signal API
```
**Lösung:**
- Das ist NORMAL wenn keine Signale vorhanden sind
- API-URLs in den Parametern prüfen
- Account-ID wird automatisch übertragen

### **Problem 4: EA startet nicht**
```
Expert Advisor stopped
```
**Lösung:**
- "Allow automated trading" aktivieren
- Chart-Symbol muss handelbar sein
- Markt muss geöffnet sein (für Tests)

---

## 🎯 **PARAMETER-EMPFEHLUNGEN**

### **Für Produktiv-Einsatz:**
```
risk_percent = 5.0          ← ULTRA-SICHER
debug_mode = false          ← Weniger Logs
verbose_signal_check = false
enable_manual_test = false
```

### **Für Testing/Debug:**
```
risk_percent = 1.0          ← EXTRA-SICHER beim Testen
debug_mode = true           ← Detaillierte Logs
verbose_signal_check = true ← Alle API-Calls sehen
enable_manual_test = false  ← Nur bei Bedarf
```

---

## 🌐 **DOWNLOAD-LINKS**

### **Hauptdatei:**
```
https://raw.githubusercontent.com/stelona/signal-ea-v90/main/src/main/Complete_Signal_EA_v92_Universal.mq5
```

### **GitHub Repository (alle Versionen):**
```
https://github.com/stelona/signal-ea-v90
```

### **Dokumentation:**
```
https://github.com/stelona/signal-ea-v90/tree/main/docs
```

---

## 🏆 **ZUSAMMENFASSUNG**

**Sie brauchen nur:**
1. ✅ **Eine .mq5 Datei** herunterladen
2. ✅ **In MetaEditor kompilieren** (F7)
3. ✅ **WebRequest aktivieren** für n8n.stelona.com
4. ✅ **Auf Chart anwenden** mit korrekten API-URLs

**Das war's! Der EA ist sofort einsatzbereit und löst alle Ihre Asset-Typ und Lotsize-Probleme automatisch.**

**Bei Problemen:** Prüfen Sie die Logs im "Experts" Tab - der EA gibt detaillierte Fehlermeldungen aus!
