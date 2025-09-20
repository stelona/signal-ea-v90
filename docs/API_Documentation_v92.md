# 📡 API DOCUMENTATION - Signal EA v9.2-COMPLETE-ALL

## 🎯 ÜBERSICHT ALLER API-ENDPUNKTE

Der Signal EA v9.2 kommuniziert mit **4 verschiedenen API-Endpunkten**:

1. **Signal API** - Empfängt neue Trading-Signale
2. **Position API** - Prüft Status und Updates bestehender Positionen
3. **Delivery API** - Sendet Trade-Bestätigungen und Status-Updates
4. **Login API** - Überträgt Login-Status und Account-Informationen

---

## 📡 1. SIGNAL API

### **Endpunkt:**
```
GET https://n8n.stelona.com/webhook/get-signal2?account_id={account_id}
```

### **EA Request:**
```http
GET /webhook/get-signal2?account_id=12345678 HTTP/1.1
Host: n8n.stelona.com
Content-Type: application/json; charset=utf-8
```

### **Erwartete API Response (Neues Signal):**
```json
{
  "signal_id": "SIG_2024_001",
  "symbol": "XAUUSD",
  "direction": "buy",
  "entry": 2000.50,
  "sl": 1995.00,
  "tp": 2010.00,
  "order_type": "market",
  "timestamp": "2024-01-15T14:30:00Z",
  "risk_percent": 5.0,
  "comment": "Gold breakout signal"
}
```

### **Erwartete API Response (Kein Signal):**
```json
{
  "status": "no_signals",
  "message": "No active signals for account",
  "timestamp": "2024-01-15T14:30:00Z"
}
```

### **EA Verarbeitung:**
```mql5
void ProcessSignal(string signal_data) {
    // Extrahiert Werte aus JSON:
    string signal_id = ExtractStringFromJSON(signal_data, "signal_id");
    string symbol = ExtractStringFromJSON(signal_data, "symbol");
    string direction = ExtractStringFromJSON(signal_data, "direction");
    double entry = ExtractDoubleFromJSON(signal_data, "entry");
    double sl = ExtractDoubleFromJSON(signal_data, "sl");
    double tp = ExtractDoubleFromJSON(signal_data, "tp");
    string order_type = ExtractStringFromJSON(signal_data, "order_type");
    
    // Symbol-Mapping anwenden
    string trading_symbol = FindSymbolWithExtendedSearch(symbol);
    
    // v9.2 Universal Lotsize-Berechnung
    string calc_message = "";
    double lots = CalculateLots_v92_Universal(trading_symbol, entry, sl, risk_percent, mt_order_type, calc_message);
    
    // Trade ausführen
    ExecuteTrade(signal_id, trading_symbol, mt_order_type, lots, entry, sl, tp);
}
```

---

## 📊 2. POSITION API

### **Endpunkt:**
```
GET https://n8n.stelona.com/webhook/check-status?signal_id={signal_id}&account_id={account_id}&ticket={ticket}
```

### **EA Request:**
```http
GET /webhook/check-status?signal_id=SIG_2024_001&account_id=12345678&ticket=987654321 HTTP/1.1
Host: n8n.stelona.com
Content-Type: application/json; charset=utf-8
```

### **Erwartete API Response (Position aktiv, keine Änderungen):**
```json
{
  "signal_id": "SIG_2024_001",
  "status": "active",
  "sl": 1995.00,
  "tp": 2010.00,
  "last_update": "2024-01-15T14:30:00Z",
  "message": "Position unchanged"
}
```

### **Erwartete API Response (SL/TP Update erforderlich):**
```json
{
  "signal_id": "SIG_2024_001",
  "status": "active",
  "sl": 1998.00,
  "tp": 2015.00,
  "last_update": "2024-01-15T14:35:00Z",
  "message": "SL/TP updated",
  "update_reason": "Market conditions changed"
}
```

### **Erwartete API Response (Position schließen):**
```json
{
  "signal_id": "SIG_2024_001",
  "status": "close",
  "close_reason": "Take profit reached",
  "last_update": "2024-01-15T14:40:00Z",
  "message": "Close position immediately"
}
```

### **Erwartete API Response (Break Even aktivieren):**
```json
{
  "signal_id": "SIG_2024_001",
  "status": "break_even",
  "break_even_level": 2000.50,
  "last_update": "2024-01-15T14:32:00Z",
  "message": "Activate break even"
}
```

### **EA Verarbeitung:**
```mql5
void ProcessSLTPUpdate(string signal_id, ulong ticket, string symbol, string api_response) {
    // Extrahiert neue Werte
    double api_sl = ExtractDoubleFromJSON(api_response, "sl");
    double api_tp = ExtractDoubleFromJSON(api_response, "tp");
    string status = ExtractStringFromJSON(api_response, "status");
    
    // Prüft ob bereits angewendet
    if(!IsModificationAlreadyApplied(signal_id, ticket, DoubleToString(api_sl, 5), true)) {
        ModifyPositionSL(ticket, api_sl, "API Update");
        UpdateAPIValueTracking(signal_id, ticket, DoubleToString(api_sl, 5), "");
    }
    
    if(!IsModificationAlreadyApplied(signal_id, ticket, DoubleToString(api_tp, 5), false)) {
        ModifyPositionTP(ticket, api_tp, "API Update");
        UpdateAPIValueTracking(signal_id, ticket, "", DoubleToString(api_tp, 5));
    }
}
```

---

## 📤 3. DELIVERY API

### **Endpunkt:**
```
POST https://n8n.stelona.com/webhook/signal-delivery
```

### **EA Request (Trade erfolgreich ausgeführt):**
```http
POST /webhook/signal-delivery HTTP/1.1
Host: n8n.stelona.com
Content-Type: application/json; charset=utf-8

{
  "account_id": "12345678",
  "signal_id": "SIG_2024_001",
  "success": true,
  "message": "Trade erfolgreich ausgeführt",
  "ea_version": "9.2",
  "timestamp": "2024-01-15T14:30:15Z",
  "trade_details": {
    "symbol": "XAUUSDs",
    "order_type": "ORDER_TYPE_BUY",
    "lots": 0.59,
    "ticket": 987654321,
    "entry_price": 2000.50,
    "sl": 1995.00,
    "tp": 2010.00,
    "execution_time": "2024-01-15T14:30:15Z"
  },
  "account_info": {
    "balance": 5000.00,
    "equity": 5125.50,
    "currency": "EUR",
    "leverage": 100,
    "free_margin": 4500.00
  },
  "calculation_details": {
    "asset_type": "PRECIOUS_GOLD",
    "risk_percent": 5.0,
    "risk_amount": 250.00,
    "loss_per_lot": 425.74,
    "calculation_method": "Universal_v92_Gold_Specific"
  }
}
```

### **EA Request (Trade fehlgeschlagen):**
```http
POST /webhook/signal-delivery HTTP/1.1
Host: n8n.stelona.com
Content-Type: application/json; charset=utf-8

{
  "account_id": "12345678",
  "signal_id": "SIG_2024_001",
  "success": false,
  "message": "Symbol nicht verfügbar",
  "ea_version": "9.2",
  "timestamp": "2024-01-15T14:30:15Z",
  "trade_details": {
    "symbol": "UNKNOWN_SYMBOL",
    "direction": "buy",
    "lots": 0.0,
    "ticket": 0,
    "error_code": 4106,
    "error_message": "Unknown symbol"
  },
  "account_info": {
    "balance": 5000.00,
    "equity": 5000.00,
    "currency": "EUR",
    "leverage": 100
  }
}
```

### **EA Request (Position Update/Modifikation):**
```http
POST /webhook/signal-delivery HTTP/1.1
Host: n8n.stelona.com
Content-Type: application/json; charset=utf-8

{
  "account_id": "12345678",
  "signal_id": "SIG_2024_001",
  "success": true,
  "message": "SL erfolgreich modifiziert",
  "ea_version": "9.2",
  "timestamp": "2024-01-15T14:35:20Z",
  "modification_details": {
    "ticket": 987654321,
    "modification_type": "SL_UPDATE",
    "old_sl": 1995.00,
    "new_sl": 1998.00,
    "reason": "API Update",
    "modification_time": "2024-01-15T14:35:20Z"
  },
  "position_status": {
    "current_price": 2005.25,
    "unrealized_pnl": 125.50,
    "pnl_percent": 2.51
  }
}
```

### **Erwartete API Response:**
```json
{
  "status": "received",
  "message": "Delivery confirmation processed",
  "timestamp": "2024-01-15T14:30:16Z"
}
```

### **EA Implementierung:**
```mql5
void SendTradeExecutionConfirmation(string signal_id, string symbol, string order_type, 
                                   double lots, ulong ticket, string message) {
    
    string json = CreateBaseJSON(signal_id, true, message);
    json += ",\"trade_details\":{";
    json += "\"symbol\":\"" + symbol + "\",";
    json += "\"order_type\":\"" + order_type + "\",";
    json += "\"lots\":" + DoubleToString(lots, 6) + ",";
    json += "\"ticket\":" + IntegerToString(ticket) + ",";
    json += "\"entry_price\":" + DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), 5) + ",";
    json += "\"sl\":" + DoubleToString(PositionGetDouble(POSITION_SL), 5) + ",";
    json += "\"tp\":" + DoubleToString(PositionGetDouble(POSITION_TP), 5) + ",";
    json += "\"execution_time\":\"" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\"";
    json += "}";
    json += AddAccountInfo();
    json += "}";
    
    SendHttpRequest(delivery_api_url, "POST", json);
}
```

---

## 🔐 4. LOGIN API

### **Endpunkt:**
```
POST https://n8n.stelona.com/webhook/login-status
```

### **EA Request (Login-Status):**
```http
POST /webhook/login-status HTTP/1.1
Host: n8n.stelona.com
Content-Type: application/json; charset=utf-8

{
  "account_id": "12345678",
  "status": "online",
  "ea_version": "9.2",
  "timestamp": "2024-01-15T14:30:00Z",
  "account_info": {
    "balance": 5000.00,
    "equity": 5125.50,
    "currency": "EUR",
    "leverage": 100,
    "free_margin": 4500.00,
    "margin_level": 1138.89,
    "company": "MetaQuotes Demo",
    "server": "MetaQuotes-Demo",
    "name": "Demo Account"
  },
  "ea_info": {
    "initialization_time": "2024-01-15T14:25:00Z",
    "broker_suffix": ".ecn",
    "detected_symbols": 145,
    "auto_detected_indices": 12,
    "custom_mappings": 19,
    "tracked_positions": 3,
    "universal_classification": "active",
    "debug_mode": true
  },
  "system_info": {
    "terminal_build": 3815,
    "terminal_company": "MetaQuotes Ltd.",
    "mql_build": 3815,
    "operating_system": "Windows 10"
  }
}
```

### **Erwartete API Response (Login erfolgreich):**
```json
{
  "status": "authenticated",
  "message": "Account successfully registered",
  "timestamp": "2024-01-15T14:30:01Z",
  "account_settings": {
    "max_risk_percent": 5.0,
    "enable_break_even": true,
    "signal_frequency": "high",
    "allowed_symbols": ["XAUUSD", "EURUSD", "USDJPY", "US30", "DAX"],
    "trading_hours": "24/7"
  }
}
```

### **Erwartete API Response (Login fehlgeschlagen):**
```json
{
  "status": "rejected",
  "message": "Account not authorized for trading signals",
  "timestamp": "2024-01-15T14:30:01Z",
  "error_code": "AUTH_FAILED",
  "retry_after": 300
}
```

### **EA Implementierung:**
```mql5
void SendLoginStatus() {
    string json = "{";
    json += "\"account_id\":\"" + account_id + "\",";
    json += "\"status\":\"online\",";
    json += "\"ea_version\":\"9.2\",";
    json += "\"timestamp\":\"" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\"";
    json += AddAccountInfo();
    json += ",\"ea_info\":{";
    json += "\"initialization_time\":\"" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\",";
    json += "\"broker_suffix\":\"" + broker_suffix + "\",";
    json += "\"detected_symbols\":" + IntegerToString(SymbolsTotal(true)) + ",";
    json += "\"auto_detected_indices\":" + IntegerToString(ArraySize(auto_detected_indices)) + ",";
    json += "\"custom_mappings\":" + IntegerToString(ArraySize(custom_mappings)) + ",";
    json += "\"tracked_positions\":" + IntegerToString(ArraySize(tracked_positions)) + ",";
    json += "\"universal_classification\":\"active\",";
    json += "\"debug_mode\":" + (debug_mode ? "true" : "false");
    json += "}";
    json += "}";
    
    string response = SendHttpRequest(login_api_url, "POST", json);
    
    if(response != "") {
        login_success = true;
        login_attempt_count = 0;
        LogSuccess("✅ Login-Status erfolgreich übertragen");
    }
}
```

---

## 🔧 HELPER FUNCTIONS FÜR JSON-VERARBEITUNG

### **String aus JSON extrahieren:**
```mql5
string ExtractStringFromJSON(string json, string key) {
    string search_pattern = "\"" + key + "\":\"";
    int start_pos = StringFind(json, search_pattern);
    if(start_pos == -1) return "";
    
    start_pos += StringLen(search_pattern);
    int end_pos = StringFind(json, "\"", start_pos);
    if(end_pos == -1) return "";
    
    return StringSubstr(json, start_pos, end_pos - start_pos);
}
```

### **Double aus JSON extrahieren:**
```mql5
double ExtractDoubleFromJSON(string json, string key) {
    string search_pattern = "\"" + key + "\":";
    int start_pos = StringFind(json, search_pattern);
    if(start_pos == -1) return 0;
    
    start_pos += StringLen(search_pattern);
    int end_pos = StringFind(json, ",", start_pos);
    if(end_pos == -1) end_pos = StringFind(json, "}", start_pos);
    if(end_pos == -1) return 0;
    
    string value_str = StringSubstr(json, start_pos, end_pos - start_pos);
    StringReplace(value_str, "\"", "");
    return StringToDouble(value_str);
}
```

---

## 🎯 TIMING UND FREQUENZ

### **Signal API:**
- **Frequenz:** Alle 15 Sekunden (konfigurierbar via `check_interval_signal`)
- **Timeout:** 5 Sekunden (konfigurierbar via `api_timeout_ms`)
- **Retry:** Automatisch beim nächsten Intervall

### **Position API:**
- **Frequenz:** Alle 30 Sekunden für jede getrackte Position (konfigurierbar via `check_interval_position`)
- **Timeout:** 5 Sekunden
- **Retry:** Automatisch beim nächsten Intervall

### **Delivery API:**
- **Frequenz:** Sofort nach Trade-Ereignissen (Ausführung, Modifikation, Fehler)
- **Timeout:** 5 Sekunden
- **Retry:** Keine automatische Wiederholung

### **Login API:**
- **Frequenz:** Bei EA-Start, dann alle 5 Sekunden bis erfolgreich (max. 30 Versuche)
- **Timeout:** 5 Sekunden
- **Retry:** Automatisch mit konfigurierbarer Verzögerung

---

## 🚨 FEHLERBEHANDLUNG

### **HTTP-Fehler-Codes:**
```mql5
if(res == -1) {
    int error_code = GetLastError();
    switch(error_code) {
        case 4060:
            LogError("URL nicht in der Liste der erlaubten URLs");
            LogError("Lösung: Tools → Optionen → Expert Advisors → 'Allow WebRequest for listed URL'");
            break;
        case 4014:
            LogError("Unbekannte Symbol");
            break;
        default:
            LogError("HTTP Fehler: " + IntegerToString(error_code));
            break;
    }
    return "";
}
```

### **API-Response Validierung:**
```mql5
// Prüfe ob Response gültig ist
if(response == "") {
    LogVerbose("Keine Antwort von API (normal wenn keine Daten vorhanden)");
    return;
}

// Prüfe auf Fehler-Response
if(StringFind(response, "\"status\":\"error\"") >= 0) {
    string error_message = ExtractStringFromJSON(response, "message");
    LogError("API Fehler: " + error_message);
    return;
}
```

---

## 🎯 ZUSAMMENFASSUNG

Der Signal EA v9.2 erwartet **strukturierte JSON-Responses** von allen API-Endpunkten:

1. **Signal API:** Liefert Trading-Signale mit allen erforderlichen Parametern
2. **Position API:** Liefert Status-Updates und SL/TP-Modifikationen für bestehende Positionen
3. **Delivery API:** Empfängt Bestätigungen über Trade-Ausführungen und Modifikationen
4. **Login API:** Authentifiziert den EA und übermittelt Account-Status

**Alle APIs verwenden UTF-8 JSON-Format** und erwarten **konsistente Datenstrukturen** für zuverlässige Kommunikation.
