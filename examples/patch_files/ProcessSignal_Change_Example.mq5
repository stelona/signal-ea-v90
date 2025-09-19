//+------------------------------------------------------------------+
//| BEISPIEL: WIE SIE ProcessSignal() ÄNDERN MÜSSEN                 |
//+------------------------------------------------------------------+

// ⚠️ SUCHEN Sie in Ihrem ProcessSignal() nach einer ähnlichen Stelle wie unten
// und ersetzen Sie nur die Lotsize-Berechnung

bool ProcessSignal(string signal_json) {
    // ... (Ihr bestehender Code bleibt unverändert) ...
    
    // Symbol-Mapping (bleibt unverändert)
    string mapped_symbol = FindTradingSymbol(symbol);
    if(mapped_symbol == "") {
        LogError("Symbol nicht gefunden: " + symbol);
        return false;
    }
    
    // Order-Type bestimmen (bleibt unverändert)
    ENUM_ORDER_TYPE mt_order_type = ORDER_TYPE_BUY;
    if(direction == "sell") {
        mt_order_type = (order_type == "market") ? ORDER_TYPE_SELL : ORDER_TYPE_SELL_LIMIT;
    } else {
        mt_order_type = (order_type == "market") ? ORDER_TYPE_BUY : ORDER_TYPE_BUY_LIMIT;
    }
    
    // ========== HIER IST DIE ÄNDERUNG ==========
    
    // ❌ ALTE ZEILE (suchen Sie nach so etwas in Ihrem Code):
    // double lots = CalculateLots_v85(mapped_symbol, entry, sl, risk, mt_order_type, calc_message);
    // oder
    // double lots = CalculateLots(symbol, direction, entry, sl, risk, order_type);
    // oder
    // double lots = CalculateLots_v832_Enhanced(mapped_symbol, entry, sl, risk, mt_order_type, calc_message);
    
    // ✅ NEUE ZEILE (ersetzen Sie durch):
    string calc_message = "";
    double lots = CalculateLots_v90_Enhanced(mapped_symbol, entry, sl, risk, mt_order_type, calc_message);
    
    // ========== ENDE DER ÄNDERUNG ==========
    
    if(lots <= 0) {
        LogError("Lot-Berechnung fehlgeschlagen: " + calc_message);
        // ... (Rest bleibt unverändert) ...
        return false;
    }
    
    // Trade ausführen (bleibt unverändert)
    bool trade_success = false;
    ulong ticket = 0;
    
    // ... (Rest Ihres Codes bleibt unverändert) ...
    
    return trade_success;
}

//+------------------------------------------------------------------+
//| WEITERE MÖGLICHE STELLEN WO SIE ÄNDERN MÜSSEN                  |
//+------------------------------------------------------------------+

// Falls Sie auch in anderen Funktionen Lotsize-Berechnungen haben,
// ersetzen Sie diese ebenfalls:

// ❌ ALTE AUFRUFE:
// double lots = CalculateLots_v85(...);
// double lots = CalculateLots_v84(...);
// double lots = CalculateLots_v832_Enhanced(...);
// double lots = GetRobustLossPerLot_v832(...);

// ✅ NEUER AUFRUF:
// string calc_message = "";
// double lots = CalculateLots_v90_Enhanced(symbol, entry, sl, risk, order_type, calc_message);

//+------------------------------------------------------------------+
//| TIPPS ZUM FINDEN DER RICHTIGEN STELLE                           |
//+------------------------------------------------------------------+

// 1. Suchen Sie nach "CalculateLots" (Strg+F in MetaEditor)
// 2. Suchen Sie nach "lots =" 
// 3. Suchen Sie nach "ProcessSignal"
// 4. Die Lotsize-Berechnung ist meist in der Mitte von ProcessSignal()
// 5. Sie erkennen es an Parametern wie: symbol, entry, sl, risk

//+------------------------------------------------------------------+
//| VALIDIERUNG NACH DER ÄNDERUNG                                   |
//+------------------------------------------------------------------+

// Nach der Änderung sollten Sie diese Logs sehen:
// 🚀 OPTIMIERTE LOTSIZE-BERECHNUNG v9.0
// 🇯🇵 JPY-PAAR SPEZIALBEHANDLUNG AKTIV
// 🛡️ STRIKTE RISIKO-KONTROLLE AKTIV

// Wenn Sie diese Meldungen NICHT sehen, wurde die Funktion nicht aufgerufen
// → Prüfen Sie, ob Sie die richtige Stelle geändert haben
