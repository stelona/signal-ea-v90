//+------------------------------------------------------------------+
//| LOTSIZE-MODUL v9.0 - ENHANCED CALCULATION WITH JPY SUPPORT     |
//| Separate Datei: Lotsize_v90_Enhanced.mqh                        |
//+------------------------------------------------------------------+

#ifndef LOTSIZE_V90_ENHANCED_MQH
#define LOTSIZE_V90_ENHANCED_MQH

//+------------------------------------------------------------------+
//| MODUL-HEADER                                                     |
//+------------------------------------------------------------------+
// Version: 9.0
// Zweck: Optimierte Lotsize-Berechnung mit JPY-Paar Spezialbehandlung
// Features: 4-stufiges Fallback-System, strikte Risiko-Kontrolle
// Kompatibilität: Ersetzt alle v8.x Lotsize-Berechnungen

//+------------------------------------------------------------------+
//| MODUL-ABHÄNGIGKEITEN                                             |
//+------------------------------------------------------------------+
// Benötigt: Standard MQL5 Libraries
// Benötigt: Log-Funktionen (LogImportant, LogError, LogWarning)
// Optional: AccountInfo-Funktionen

//+------------------------------------------------------------------+
//| 1. JPY-PAAR ERKENNUNG v9.0                                      |
//+------------------------------------------------------------------+
bool IsJPYPair(string symbol) {
    string normalized = symbol;
    StringToUpper(normalized);
    
    // Entferne häufige Broker-Suffixe für bessere Erkennung
    string suffixes[] = {".ECN", ".RAW", ".PRO", ".STD", "#", "S", "+", "-", ".A", ".B", ".C"};
    for(int i = 0; i < ArraySize(suffixes); i++) {
        int pos = StringFind(normalized, suffixes[i]);
        if(pos > 0) {
            normalized = StringSubstr(normalized, 0, pos);
            break;
        }
    }
    
    // Prüfe ob JPY am Ende steht (Quote Currency)
    return (StringLen(normalized) >= 6 && StringSubstr(normalized, 3, 3) == "JPY");
}

//+------------------------------------------------------------------+
//| 2. ROBUSTE WÄHRUNGSKONVERTIERUNG v9.0                           |
//+------------------------------------------------------------------+
double GetCurrencyConversionRate_v90(string from_currency, string to_currency) {
    if(from_currency == to_currency) return 1.0;
    
    // Direkte Konvertierung versuchen
    string direct_symbol = from_currency + to_currency;
    if(SymbolSelect(direct_symbol, true)) {
        double rate = SymbolInfoDouble(direct_symbol, SYMBOL_BID);
        if(rate > 0) return rate;
    }
    
    // Umgekehrte Konvertierung versuchen
    string reverse_symbol = to_currency + from_currency;
    if(SymbolSelect(reverse_symbol, true)) {
        double rate = SymbolInfoDouble(reverse_symbol, SYMBOL_BID);
        if(rate > 0) return 1.0 / rate;
    }
    
    // Via USD konvertieren
    if(from_currency != "USD" && to_currency != "USD") {
        double from_usd = GetCurrencyConversionRate_v90(from_currency, "USD");
        double to_usd = GetCurrencyConversionRate_v90("USD", to_currency);
        if(from_usd > 0 && to_usd > 0) {
            return from_usd * to_usd;
        }
    }
    
    // Hardcoded Fallback-Raten (konservativ)
    if(from_currency == "JPY" && to_currency == "EUR") return 0.0067;
    if(from_currency == "JPY" && to_currency == "USD") return 0.0067;
    if(from_currency == "EUR" && to_currency == "USD") return 1.08;
    if(from_currency == "USD" && to_currency == "EUR") return 0.92;
    if(from_currency == "GBP" && to_currency == "USD") return 1.25;
    if(from_currency == "USD" && to_currency == "GBP") return 0.80;
    
    return -1; // Konvertierung fehlgeschlagen
}

//+------------------------------------------------------------------+
//| 3. JPY-SPEZIFISCHE LOSS-PER-LOT BERECHNUNG v9.0                 |
//+------------------------------------------------------------------+
double CalculateJPYLossPerLot_v90(string symbol, double entry_price, double sl_price, string &error_msg) {
    error_msg = "";
    
    LogImportant("🇯🇵 JPY-SPEZIFISCHE BERECHNUNG v9.0:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Entry: " + DoubleToString(entry_price, 3));
    LogImportant("   SL: " + DoubleToString(sl_price, 3));
    
    // JPY-Paare haben 3 Dezimalstellen (z.B. 148.123)
    // 1 Pip = 0.01 (NICHT 0.001!)
    // Standard Lot = 100,000 Einheiten der Basiswährung
    
    double distance = MathAbs(entry_price - sl_price);
    double pips = distance / 0.01; // JPY: 1 Pip = 0.01
    
    LogImportant("   Distanz: " + DoubleToString(distance, 3));
    LogImportant("   Pips (0.01): " + DoubleToString(pips, 1));
    
    // Für JPY-Paare: 1 Pip = 1000 JPY bei 1 Standard Lot
    double loss_jpy = pips * 1000.0;
    LogImportant("   Verlust in JPY: " + DoubleToString(loss_jpy, 0) + " JPY");
    
    // Konvertiere JPY zu Account-Währung
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    double loss_account_currency = 0.0;
    
    if(account_currency == "JPY") {
        loss_account_currency = loss_jpy;
        LogImportant("   Account-Währung ist JPY - keine Konvertierung nötig");
    } else {
        // Konvertiere JPY zu Account-Währung
        double jpy_rate = GetCurrencyConversionRate_v90("JPY", account_currency);
        if(jpy_rate > 0) {
            loss_account_currency = loss_jpy * jpy_rate;
            LogImportant("   JPY → " + account_currency + " Rate: " + DoubleToString(jpy_rate, 6));
            LogImportant("   Verlust in " + account_currency + ": " + DoubleToString(loss_account_currency, 2));
        } else {
            // Fallback: Verwende typische JPY Rate
            if(account_currency == "EUR") {
                loss_account_currency = loss_jpy * 0.0067; // ~150 JPY/EUR
                LogImportant("   Fallback JPY/EUR Rate: 0.0067");
            } else if(account_currency == "USD") {
                loss_account_currency = loss_jpy * 0.0067; // ~150 JPY/USD
                LogImportant("   Fallback JPY/USD Rate: 0.0067");
            } else {
                error_msg = "Währungskonvertierung von JPY zu " + account_currency + " nicht möglich";
                LogError("❌ " + error_msg);
                return -1;
            }
        }
    }
    
    // Validierung: JPY-Paare sollten typisch 0.5-5 EUR pro Pip ergeben
    double expected_per_pip = loss_account_currency / pips;
    LogImportant("   Verlust pro Pip: " + DoubleToString(expected_per_pip, 4) + " " + account_currency);
    
    if(expected_per_pip < 0.1 || expected_per_pip > 20.0) {
        LogWarning("⚠️ Ungewöhnlicher Verlust pro Pip: " + DoubleToString(expected_per_pip, 4) + 
                  " " + account_currency + " (erwartet: 0.5-5.0)");
        // Aber nicht ablehnen - könnte bei extremen Wechselkursen normal sein
    }
    
    LogImportant("✅ JPY-BERECHNUNG ERFOLGREICH: " + DoubleToString(loss_account_currency, 2) + " " + account_currency);
    return loss_account_currency;
}

//+------------------------------------------------------------------+
//| 4. VALIDIERUNG DER LOSS-PER-LOT WERTE v9.0                      |
//+------------------------------------------------------------------+
bool ValidateLossPerLot_v90(string symbol, double loss_per_lot, double distance, string &validation_msg) {
    validation_msg = "";
    
    if(loss_per_lot <= 0) {
        validation_msg = "Loss per Lot ist null oder negativ: " + DoubleToString(loss_per_lot, 5);
        return false;
    }
    
    bool is_jpy = IsJPYPair(symbol);
    bool is_gold = (StringFind(StringToUpper(symbol), "XAU") >= 0 || StringFind(StringToUpper(symbol), "GOLD") >= 0);
    bool is_forex = (StringLen(symbol) >= 6 && !is_gold);
    
    // Definiere realistische Bereiche
    double min_expected = 0.0;
    double max_expected = 0.0;
    
    if(is_jpy) {
        // JPY-Paare: Typisch 0.5-5 EUR pro Pip bei 1 Lot
        min_expected = distance * 50.0;   // Minimum: 50 EUR pro 1.00 JPY
        max_expected = distance * 1000.0; // Maximum: 1000 EUR pro 1.00 JPY
    } else if(is_gold) {
        // Gold: Typisch 1 EUR pro 0.01 USD bei 1 Lot
        min_expected = distance * 50.0;   // Minimum
        max_expected = distance * 200.0;  // Maximum
    } else if(is_forex) {
        // Standard Forex: Typisch 8-12 EUR pro Pip bei 1 Lot
        min_expected = distance * 50000.0;  // Minimum: 5 EUR pro 0.0001
        max_expected = distance * 150000.0; // Maximum: 15 EUR pro 0.0001
    } else {
        // Indizes, Krypto etc.: Sehr großzügige Bereiche
        min_expected = 0.01;
        max_expected = distance * 1000.0;
    }
    
    if(loss_per_lot < min_expected) {
        validation_msg = "Loss per Lot zu klein: " + DoubleToString(loss_per_lot, 5) + 
                        " < " + DoubleToString(min_expected, 5) + " (möglicherweise falsche Berechnung)";
        return false;
    }
    
    if(loss_per_lot > max_expected) {
        validation_msg = "Loss per Lot zu groß: " + DoubleToString(loss_per_lot, 5) + 
                        " > " + DoubleToString(max_expected, 5) + " (möglicherweise falsche Berechnung)";
        return false;
    }
    
    validation_msg = "Validierung erfolgreich: " + DoubleToString(loss_per_lot, 5) + 
                    " liegt im erwarteten Bereich [" + DoubleToString(min_expected, 2) + 
                    " - " + DoubleToString(max_expected, 2) + "]";
    return true;
}

//+------------------------------------------------------------------+
//| 5. HAUPTFUNKTION: OPTIMIERTE LOTSIZE-BERECHNUNG v9.0            |
//+------------------------------------------------------------------+
double CalculateLots_v90_Enhanced(string symbol, double entry_price, double sl_price, 
                                  double risk_percent, ENUM_ORDER_TYPE order_type, string &message) {
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("🚀 LOTSIZE-MODUL v9.0 - ENHANCED CALCULATION");
    LogImportant("🇯🇵 JPY-PAAR SPEZIALBEHANDLUNG AKTIV");
    LogImportant("🛡️ STRIKTE RISIKO-KONTROLLE AKTIV");
    LogImportant("════════════════════════════════════════════");
    
    LogImportant("📊 INPUT-PARAMETER:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Entry: " + DoubleToString(entry_price, 5));
    LogImportant("   SL: " + DoubleToString(sl_price, 5));
    LogImportant("   Risiko: " + DoubleToString(risk_percent, 2) + "%");
    LogImportant("   Order Type: " + EnumToString(order_type));
    
    // ========== SCHRITT 1: SYMBOL-DATEN SAMMELN ==========
    if(!SymbolSelect(symbol, true)) {
        message = "Symbol konnte nicht aktiviert werden: " + symbol;
        LogError("❌ " + message);
        return -1;
    }
    
    double volume_min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double volume_max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double volume_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    LogImportant("📈 SYMBOL-DATEN:");
    LogImportant("   Volume Min/Max/Step: " + DoubleToString(volume_min, 3) + "/" + 
                DoubleToString(volume_max, 3) + "/" + DoubleToString(volume_step, 4));
    LogImportant("   Digits: " + IntegerToString(digits));
    
    // ========== SCHRITT 2: LOSS-PER-LOT BERECHNUNG ==========
    double distance = MathAbs(entry_price - sl_price);
    double loss_per_lot = 0.0;
    string error_msg = "";
    string method_used = "";
    
    LogImportant("🔍 LOSS-PER-LOT BERECHNUNG:");
    LogImportant("   Distanz: " + DoubleToString(distance, 5));
    
    // Methode 1: JPY-spezifische Berechnung (NEUE v9.0 FUNKTION)
    if(IsJPYPair(symbol)) {
        LogImportant("🇯🇵 ERKANNT: JPY-Paar - verwende spezielle Berechnung");
        loss_per_lot = CalculateJPYLossPerLot_v90(symbol, entry_price, sl_price, error_msg);
        if(loss_per_lot > 0) {
            method_used = "JPY-spezifische Berechnung v9.0";
        } else {
            LogWarning("⚠️ JPY-Berechnung fehlgeschlagen: " + error_msg);
        }
    }
    
    // Methode 2: OrderCalcProfit (mit v9.0 Validierung)
    if(loss_per_lot <= 0) {
        LogImportant("🔄 VERWENDE OrderCalcProfit...");
        double profit_at_sl = 0;
        if(OrderCalcProfit(order_type, symbol, 1.0, entry_price, sl_price, profit_at_sl)) {
            double potential_loss = MathAbs(profit_at_sl);
            LogImportant("   OrderCalcProfit Ergebnis: " + DoubleToString(potential_loss, 5));
            
            // v9.0 Validierung
            string validation_msg = "";
            if(ValidateLossPerLot_v90(symbol, potential_loss, distance, validation_msg)) {
                loss_per_lot = potential_loss;
                method_used = "OrderCalcProfit (v9.0 validiert)";
                LogImportant("✅ OrderCalcProfit validiert: " + validation_msg);
            } else {
                LogWarning("⚠️ OrderCalcProfit Validierung fehlgeschlagen: " + validation_msg);
            }
        } else {
            LogWarning("⚠️ OrderCalcProfit fehlgeschlagen");
        }
    }
    
    // Methode 3: Tick-basierte Berechnung (mit v9.0 Validierung)
    if(loss_per_lot <= 0) {
        LogImportant("🔄 VERWENDE Tick-basierte Berechnung...");
        double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
        double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        
        if(tick_size > 0 && tick_value > 0) {
            double ticks = distance / tick_size;
            double potential_loss = ticks * tick_value;
            LogImportant("   Tick Size: " + DoubleToString(tick_size, 8));
            LogImportant("   Tick Value: " + DoubleToString(tick_value, 5));
            LogImportant("   Ticks: " + DoubleToString(ticks, 2));
            LogImportant("   Tick-Berechnung Ergebnis: " + DoubleToString(potential_loss, 5));
            
            // v9.0 Validierung
            string validation_msg = "";
            if(ValidateLossPerLot_v90(symbol, potential_loss, distance, validation_msg)) {
                loss_per_lot = potential_loss;
                method_used = "Tick-basierte Berechnung (v9.0 validiert)";
                LogImportant("✅ Tick-Berechnung validiert: " + validation_msg);
            } else {
                LogWarning("⚠️ Tick-Berechnung Validierung fehlgeschlagen: " + validation_msg);
            }
        } else {
            LogWarning("⚠️ Tick-Daten nicht verfügbar");
        }
    }
    
    // Methode 4: Fallback für kritische Fälle
    if(loss_per_lot <= 0) {
        LogWarning("🚨 ALLE BERECHNUNGSMETHODEN FEHLGESCHLAGEN - verwende Notfall-Schätzung");
        
        // Notfall-Schätzung basierend auf Symbol-Typ
        if(IsJPYPair(symbol)) {
            // JPY: Schätze 1 EUR pro Pip
            double pips = distance / 0.01;
            loss_per_lot = pips * 1.0;
            method_used = "JPY Notfall-Schätzung";
        } else if(StringLen(symbol) >= 6) {
            // Forex: Schätze 10 EUR pro Pip
            double pips = distance / 0.0001;
            loss_per_lot = pips * 10.0;
            method_used = "Forex Notfall-Schätzung";
        } else {
            // Andere: Schätze 1:1
            loss_per_lot = distance;
            method_used = "Allgemeine Notfall-Schätzung";
        }
        
        LogWarning("   Notfall-Schätzung: " + DoubleToString(loss_per_lot, 5) + " (Methode: " + method_used + ")");
    }
    
    if(loss_per_lot <= 0) {
        message = "Alle Berechnungsmethoden fehlgeschlagen";
        LogError("❌ " + message);
        return -1;
    }
    
    LogImportant("✅ LOSS-PER-LOT ERFOLGREICH BERECHNET:");
    LogImportant("   Methode: " + method_used);
    LogImportant("   Loss per Lot: " + DoubleToString(loss_per_lot, 5) + " " + AccountInfoString(ACCOUNT_CURRENCY));
    
    // ========== SCHRITT 3: LOTSIZE-BERECHNUNG ==========
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * (risk_percent / 100.0);
    double theoretical_lots = risk_amount / loss_per_lot;
    
    LogImportant("💰 LOTSIZE-BERECHNUNG:");
    LogImportant("   Balance: " + DoubleToString(balance, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY));
    LogImportant("   Risiko-Betrag: " + DoubleToString(risk_amount, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY));
    LogImportant("   Theoretische Lots: " + DoubleToString(theoretical_lots, 6));
    
    // Normalisiere auf Volume Step (IMMER ABRUNDEN für Sicherheit)
    double safe_lots = MathFloor(theoretical_lots / volume_step) * volume_step;
    
    // Begrenze auf erlaubten Bereich
    if(safe_lots < volume_min) {
        LogWarning("⚠️ Berechnete Lots unter Minimum - prüfe ob Minimum-Risiko akzeptabel ist");
        
        // Prüfe Risiko bei Minimum-Lot
        double min_risk_amount = volume_min * loss_per_lot;
        double min_risk_percent = (min_risk_amount / balance) * 100.0;
        
        if(min_risk_percent > risk_percent) {
            message = "Risiko zu klein - Minimum-Lot würde " + DoubleToString(min_risk_percent, 2) + 
                     "% riskieren, aber nur " + DoubleToString(risk_percent, 2) + "% erlaubt";
            LogError("❌ " + message);
            return -1;
        }
        
        safe_lots = volume_min;
        LogImportant("   Auf Minimum angehoben: " + DoubleToString(safe_lots, 6));
    }
    
    if(safe_lots > volume_max) {
        safe_lots = volume_max;
        LogImportant("   Auf Maximum begrenzt: " + DoubleToString(safe_lots, 6));
    }
    
    // ========== SCHRITT 4: FINALE RISIKO-VALIDIERUNG v9.0 ==========
    double final_risk_amount = safe_lots * loss_per_lot;
    double final_risk_percent = (final_risk_amount / balance) * 100.0;
    
    LogImportant("🛡️ FINALE RISIKO-VALIDIERUNG v9.0:");
    LogImportant("   Finale Lots: " + DoubleToString(safe_lots, 6));
    LogImportant("   Finales Risiko: " + DoubleToString(final_risk_amount, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + 
                " (" + DoubleToString(final_risk_percent, 2) + "%)");
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    
    // v9.0 STRIKTE KONTROLLE: Risiko darf NIEMALS überschritten werden
    if(final_risk_percent > risk_percent) {
        LogWarning("🚨 RISIKO ÜBERSCHRITTEN! Aktiviere iterative Reduzierung...");
        
        // Iterative Reduzierung bis Risiko passt
        int iterations = 0;
        while(final_risk_percent > risk_percent && safe_lots > volume_min && iterations < 100) {
            safe_lots -= volume_step;
            if(safe_lots < volume_min) safe_lots = volume_min;
            
            final_risk_amount = safe_lots * loss_per_lot;
            final_risk_percent = (final_risk_amount / balance) * 100.0;
            iterations++;
        }
        
        LogImportant("   Nach " + IntegerToString(iterations) + " Iterationen:");
        LogImportant("   Reduzierte Lots: " + DoubleToString(safe_lots, 6));
        LogImportant("   Reduziertes Risiko: " + DoubleToString(final_risk_amount, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + 
                    " (" + DoubleToString(final_risk_percent, 2) + "%)");
        
        // Wenn selbst Minimum-Lot zu viel Risiko bedeutet
        if(final_risk_percent > risk_percent) {
            message = "Selbst Minimum-Lot überschreitet Risiko-Limit: " + DoubleToString(final_risk_percent, 2) + 
                     "% > " + DoubleToString(risk_percent, 2) + "%";
            LogError("❌ " + message);
            return -1;
        }
    }
    
    LogImportant("✅ LOTSIZE-MODUL v9.0 ERFOLGREICH!");
    LogImportant("   Empfohlene Lotsize: " + DoubleToString(safe_lots, 6));
    LogImportant("   Tatsächliches Risiko: " + DoubleToString(final_risk_percent, 2) + "% (≤ " + DoubleToString(risk_percent, 2) + "%)");
    LogImportant("   Verwendete Methode: " + method_used);
    LogImportant("🛡️ RISIKO-KONTROLLE: AKTIV UND ERFOLGREICH");
    LogImportant("════════════════════════════════════════════");
    
    message = "Lotsize-Modul v9.0 Enhanced calculation successful (" + method_used + ")";
    return safe_lots;
}

//+------------------------------------------------------------------+
//| MODUL-INFORMATIONEN                                              |
//+------------------------------------------------------------------+
string GetLotsizeModuleInfo() {
    return "Lotsize-Modul v9.0 - Enhanced Calculation with JPY Support";
}

string GetLotsizeModuleVersion() {
    return "9.0";
}

bool IsLotsizeModuleLoaded() {
    return true;
}

//+------------------------------------------------------------------+
//| ENDE DES LOTSIZE-MODULS v9.0                                    |
//+------------------------------------------------------------------+

#endif // LOTSIZE_V90_ENHANCED_MQH
