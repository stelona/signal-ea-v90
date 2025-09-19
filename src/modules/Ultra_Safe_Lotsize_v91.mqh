//+------------------------------------------------------------------+
//|                    Ultra-Safe Lotsize Calculation v9.1          |
//|                                          Copyright 2024, Stelona |
//|                                       https://www.stelona.com    |
//+------------------------------------------------------------------+
// 
// 🚨 ULTRA-SICHERE LOTSIZE-BERECHNUNG v9.1
// 
// ENTWICKELT ALS ANTWORT AUF KRITISCHEN FALL:
// - EURJPY: 77.75 Lots bei 1054 EUR Balance (KATASTROPHAL!)
// - Loss per Lot: 1.36 EUR (10-20x zu klein)
// - Ursache: Fehlerhafte OrderCalcProfit + JPY-Konvertierung
// 
// 🛡️ NEUE SICHERHEITSEBENEN:
// 1. MULTIPLE VALIDIERUNG: 5 verschiedene Berechnungsmethoden
// 2. REALITÄTS-CHECK: Vergleich gegen bekannte Pip-Werte
// 3. MAXIMUM-LIMITS: Absolute Obergrenzen basierend auf Balance
// 4. PROGRESSIVE REDUZIERUNG: Schrittweise Verkleinerung bei Unsicherheit
// 5. EMERGENCY BRAKE: Sofortiger Stopp bei unrealistischen Werten
// 
// 🎯 ZIEL: NIEMALS MEHR ALS 5% BALANCE RISKIEREN, AUCH BEI FEHLERN

#property copyright "Copyright 2024, Stelona"
#property link      "https://www.stelona.com"
#property version   "9.1"

//+------------------------------------------------------------------+
//| ULTRA-SICHERE KONSTANTEN                                         |
//+------------------------------------------------------------------+
#define MAX_RISK_PERCENT_ABSOLUTE 5.0    // NIEMALS mehr als 5% Balance riskieren
#define MAX_LOTS_PER_1000_EUR 1.0        // NIEMALS mehr als 1 Lot pro 1000 EUR Balance
#define MIN_LOSS_PER_LOT_EUR 5.0         // Minimum Loss per Lot (unrealistisch wenn kleiner)
#define MAX_LOSS_PER_LOT_EUR 200.0       // Maximum Loss per Lot (unrealistisch wenn größer)
#define SAFETY_FACTOR 0.8                // Reduziere finale Lots um 20% für Sicherheit

//+------------------------------------------------------------------+
//| ERWEITERTE JPY-PAAR ERKENNUNG v9.1                              |
//+------------------------------------------------------------------+
bool IsJPYPair_v91(string symbol) {
    string normalized = symbol;
    StringToUpper(normalized);
    
    // Entferne ALLE möglichen Broker-Suffixe
    string suffixes[] = {".ECN", ".RAW", ".PRO", ".STD", ".MINI", ".MICRO", 
                        "#", "S", "+", "-", ".", "_", "M", "C", "E", "P",
                        ".A", ".B", ".C", ".D", ".1", ".2", ".3"};
    
    for(int i = 0; i < ArraySize(suffixes); i++) {
        int pos = StringFind(normalized, suffixes[i]);
        if(pos > 0) {
            normalized = StringSubstr(normalized, 0, pos);
            break;
        }
    }
    
    // Prüfe ob JPY am Ende steht (Quote Currency)
    bool is_jpy = (StringLen(normalized) >= 6 && StringSubstr(normalized, 3, 3) == "JPY");
    
    if(is_jpy) {
        LogImportant("🇯🇵 JPY-PAAR ERKANNT: " + symbol + " (normalisiert: " + normalized + ")");
    }
    
    return is_jpy;
}

//+------------------------------------------------------------------+
//| ULTRA-SICHERE JPY LOSS-PER-LOT BERECHNUNG v9.1                  |
//+------------------------------------------------------------------+
double CalculateJPYLossPerLot_v91(string symbol, double entry_price, double sl_price, string &error_msg) {
    error_msg = "";
    
    LogImportant("🇯🇵 ULTRA-SICHERE JPY-BERECHNUNG v9.1:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Entry: " + DoubleToString(entry_price, 3));
    LogImportant("   SL: " + DoubleToString(sl_price, 3));
    
    // JPY-Paare: 1 Pip = 0.01 (NICHT 0.001!)
    double distance = MathAbs(entry_price - sl_price);
    double pips = distance / 0.01;
    
    LogImportant("   Distanz: " + DoubleToString(distance, 3));
    LogImportant("   Pips (JPY): " + DoubleToString(pips, 1));
    
    // MEHRFACHE BERECHNUNG FÜR VALIDIERUNG
    double loss_methods[4];
    string method_names[4] = {"Standard", "Conservative", "Aggressive", "Fallback"};
    
    // Methode 1: Standard (1000 JPY pro Pip)
    loss_methods[0] = pips * 1000.0;
    
    // Methode 2: Konservativ (1200 JPY pro Pip)
    loss_methods[1] = pips * 1200.0;
    
    // Methode 3: Aggressiv (800 JPY pro Pip)
    loss_methods[2] = pips * 800.0;
    
    // Methode 4: Fallback (1100 JPY pro Pip)
    loss_methods[3] = pips * 1100.0;
    
    // Konvertiere alle zu Account-Währung
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    double loss_account[4];
    
    for(int i = 0; i < 4; i++) {
        if(account_currency == "JPY") {
            loss_account[i] = loss_methods[i];
        } else {
            // ULTRA-SICHERE JPY-KONVERTIERUNG
            double jpy_rate = GetUltraSafeJPYRate_v91(account_currency);
            loss_account[i] = loss_methods[i] * jpy_rate;
        }
        
        LogImportant("   Methode " + method_names[i] + ": " + 
                    DoubleToString(loss_methods[i], 0) + " JPY → " + 
                    DoubleToString(loss_account[i], 2) + " " + account_currency);
    }
    
    // Wähle KONSERVATIVSTE (höchste) Schätzung für Sicherheit
    double final_loss = loss_account[0];
    string chosen_method = method_names[0];
    
    for(int i = 1; i < 4; i++) {
        if(loss_account[i] > final_loss) {
            final_loss = loss_account[i];
            chosen_method = method_names[i];
        }
    }
    
    LogImportant("✅ GEWÄHLTE METHODE: " + chosen_method + " (konservativste)");
    LogImportant("✅ JPY LOSS PER LOT: " + DoubleToString(final_loss, 2) + " " + account_currency);
    
    // ULTRA-SICHERE VALIDIERUNG
    double per_pip = final_loss / pips;
    if(per_pip < 0.5 || per_pip > 10.0) {
        error_msg = "JPY Verlust pro Pip unrealistisch: " + DoubleToString(per_pip, 4) + 
                   " " + account_currency + " (erwartet: 0.5-10.0)";
        LogError("❌ " + error_msg);
        return -1;
    }
    
    return final_loss;
}

//+------------------------------------------------------------------+
//| ULTRA-SICHERE JPY-RATE KONVERTIERUNG                            |
//+------------------------------------------------------------------+
double GetUltraSafeJPYRate_v91(string to_currency) {
    LogImportant("💱 ULTRA-SICHERE JPY-KONVERTIERUNG:");
    
    // Versuche echte Rate zu holen
    double real_rate = -1;
    string jpy_symbol = "JPY" + to_currency;
    if(SymbolSelect(jpy_symbol, true)) {
        real_rate = SymbolInfoDouble(jpy_symbol, SYMBOL_BID);
        LogImportant("   Echte Rate " + jpy_symbol + ": " + DoubleToString(real_rate, 6));
    }
    
    // Versuche umgekehrte Rate
    if(real_rate <= 0) {
        string reverse_symbol = to_currency + "JPY";
        if(SymbolSelect(reverse_symbol, true)) {
            double reverse_rate = SymbolInfoDouble(reverse_symbol, SYMBOL_BID);
            if(reverse_rate > 0) {
                real_rate = 1.0 / reverse_rate;
                LogImportant("   Umgekehrte Rate " + reverse_symbol + ": " + DoubleToString(real_rate, 6));
            }
        }
    }
    
    // ULTRA-SICHERE FALLBACK-RATEN (KONSERVATIV)
    double safe_rates[3];
    string rate_names[3] = {"Conservative", "Standard", "Aggressive"};
    
    if(to_currency == "EUR") {
        safe_rates[0] = 0.0060;  // Konservativ (167 JPY/EUR)
        safe_rates[1] = 0.0067;  // Standard (150 JPY/EUR)
        safe_rates[2] = 0.0075;  // Aggressiv (133 JPY/EUR)
    } else if(to_currency == "USD") {
        safe_rates[0] = 0.0060;  // Konservativ (167 JPY/USD)
        safe_rates[1] = 0.0067;  // Standard (150 JPY/USD)
        safe_rates[2] = 0.0075;  // Aggressiv (133 JPY/USD)
    } else if(to_currency == "GBP") {
        safe_rates[0] = 0.0050;  // Konservativ (200 JPY/GBP)
        safe_rates[1] = 0.0055;  // Standard (182 JPY/GBP)
        safe_rates[2] = 0.0060;  // Aggressiv (167 JPY/GBP)
    } else {
        // Unbekannte Währung - sehr konservativ
        safe_rates[0] = 0.0050;
        safe_rates[1] = 0.0060;
        safe_rates[2] = 0.0070;
    }
    
    // Wenn echte Rate verfügbar, validiere gegen Fallback
    if(real_rate > 0) {
        bool rate_realistic = (real_rate >= safe_rates[0] * 0.5 && real_rate <= safe_rates[2] * 2.0);
        if(rate_realistic) {
            LogImportant("✅ Echte Rate validiert: " + DoubleToString(real_rate, 6));
            return real_rate;
        } else {
            LogWarning("⚠️ Echte Rate unrealistisch: " + DoubleToString(real_rate, 6) + 
                      " (erwartet: " + DoubleToString(safe_rates[0] * 0.5, 6) + 
                      " - " + DoubleToString(safe_rates[2] * 2.0, 6) + ")");
        }
    }
    
    // Verwende KONSERVATIVSTE Fallback-Rate
    double chosen_rate = safe_rates[0];  // Immer die konservativste
    LogImportant("🛡️ FALLBACK-RATE (konservativ): " + DoubleToString(chosen_rate, 6));
    
    return chosen_rate;
}

//+------------------------------------------------------------------+
//| ULTRA-SICHERE VALIDIERUNG v9.1                                  |
//+------------------------------------------------------------------+
bool ValidateLossPerLot_v91(string symbol, double loss_per_lot, double distance, string &validation_msg) {
    validation_msg = "";
    
    LogImportant("🛡️ ULTRA-SICHERE VALIDIERUNG v9.1:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Loss per Lot: " + DoubleToString(loss_per_lot, 5));
    LogImportant("   Distanz: " + DoubleToString(distance, 5));
    
    if(loss_per_lot <= 0) {
        validation_msg = "Loss per Lot ist null oder negativ";
        return false;
    }
    
    // ABSOLUTE MINIMUM/MAXIMUM GRENZEN
    if(loss_per_lot < MIN_LOSS_PER_LOT_EUR) {
        validation_msg = "Loss per Lot zu klein: " + DoubleToString(loss_per_lot, 5) + 
                        " < " + DoubleToString(MIN_LOSS_PER_LOT_EUR, 1) + " EUR (VERDÄCHTIG!)";
        return false;
    }
    
    if(loss_per_lot > MAX_LOSS_PER_LOT_EUR) {
        validation_msg = "Loss per Lot zu groß: " + DoubleToString(loss_per_lot, 5) + 
                        " > " + DoubleToString(MAX_LOSS_PER_LOT_EUR, 1) + " EUR (VERDÄCHTIG!)";
        return false;
    }
    
    // SYMBOL-SPEZIFISCHE VALIDIERUNG
    bool is_jpy = IsJPYPair_v91(symbol);
    bool is_gold = (StringFind(StringToUpper(symbol), "XAU") >= 0 || StringFind(StringToUpper(symbol), "GOLD") >= 0);
    
    double expected_min = 0.0;
    double expected_max = 0.0;
    
    if(is_jpy) {
        // JPY: Erwarte 10-50 EUR pro 1.00 JPY Distanz
        double jpy_distance = distance / 0.01;  // Pips in JPY
        expected_min = jpy_distance * 0.5;     // 0.5 EUR pro Pip minimum
        expected_max = jpy_distance * 5.0;     // 5.0 EUR pro Pip maximum
    } else if(is_gold) {
        // Gold: Erwarte 50-200 EUR pro 1.00 USD Distanz
        expected_min = distance * 50.0;
        expected_max = distance * 200.0;
    } else {
        // Standard Forex: Erwarte 5-15 EUR pro Pip
        double forex_pips = distance / 0.0001;
        expected_min = forex_pips * 5.0;
        expected_max = forex_pips * 15.0;
    }
    
    LogImportant("   Erwarteter Bereich: " + DoubleToString(expected_min, 2) + 
                " - " + DoubleToString(expected_max, 2) + " EUR");
    
    if(loss_per_lot < expected_min) {
        validation_msg = "Loss per Lot unter Erwartung: " + DoubleToString(loss_per_lot, 5) + 
                        " < " + DoubleToString(expected_min, 2) + " EUR";
        return false;
    }
    
    if(loss_per_lot > expected_max) {
        validation_msg = "Loss per Lot über Erwartung: " + DoubleToString(loss_per_lot, 5) + 
                        " > " + DoubleToString(expected_max, 2) + " EUR";
        return false;
    }
    
    validation_msg = "✅ Validierung erfolgreich: " + DoubleToString(loss_per_lot, 5) + 
                    " EUR liegt im erwarteten Bereich";
    LogImportant("✅ " + validation_msg);
    return true;
}

//+------------------------------------------------------------------+
//| ULTRA-SICHERE MAXIMUM-LOTS BERECHNUNG                           |
//+------------------------------------------------------------------+
double CalculateMaximumSafeLots_v91(double balance) {
    LogImportant("🛡️ MAXIMUM SAFE LOTS BERECHNUNG:");
    LogImportant("   Balance: " + DoubleToString(balance, 2) + " EUR");
    
    // REGEL 1: Niemals mehr als 1 Lot pro 1000 EUR Balance
    double max_by_balance = balance / 1000.0 * MAX_LOTS_PER_1000_EUR;
    
    // REGEL 2: Niemals mehr als 5% der Balance riskieren (bei 20 EUR Loss per Lot)
    double max_by_risk = (balance * MAX_RISK_PERCENT_ABSOLUTE / 100.0) / 20.0;
    
    // REGEL 3: Absolute Obergrenze basierend auf Balance
    double max_absolute = 0.0;
    if(balance < 500) {
        max_absolute = 0.01;      // Unter 500 EUR: Max 0.01 Lots
    } else if(balance < 1000) {
        max_absolute = 0.05;      // 500-1000 EUR: Max 0.05 Lots
    } else if(balance < 2000) {
        max_absolute = 0.10;      // 1000-2000 EUR: Max 0.10 Lots
    } else if(balance < 5000) {
        max_absolute = 0.50;      // 2000-5000 EUR: Max 0.50 Lots
    } else if(balance < 10000) {
        max_absolute = 1.00;      // 5000-10000 EUR: Max 1.00 Lots
    } else {
        max_absolute = balance / 10000.0;  // Über 10000 EUR: 1 Lot pro 10000 EUR
    }
    
    // Wähle das KLEINSTE (sicherste) Limit
    double final_max = MathMin(max_by_balance, MathMin(max_by_risk, max_absolute));
    
    LogImportant("   Max by Balance (1/1000): " + DoubleToString(max_by_balance, 3));
    LogImportant("   Max by Risk (5%/20EUR): " + DoubleToString(max_by_risk, 3));
    LogImportant("   Max Absolute: " + DoubleToString(max_absolute, 3));
    LogImportant("🛡️ FINALES MAXIMUM: " + DoubleToString(final_max, 3) + " Lots");
    
    return final_max;
}

//+------------------------------------------------------------------+
//| HAUPTFUNKTION: ULTRA-SICHERE LOTSIZE-BERECHNUNG v9.1            |
//+------------------------------------------------------------------+
double CalculateLots_v91_UltraSafe(string symbol, double entry_price, double sl_price, 
                                   double risk_percent, ENUM_ORDER_TYPE order_type, string &message) {
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("🛡️ ULTRA-SICHERE LOTSIZE-BERECHNUNG v9.1");
    LogImportant("🚨 ENTWICKELT NACH KRITISCHEM FALL: 77.75 LOTS!");
    LogImportant("🛡️ NIEMALS MEHR ALS 5% BALANCE RISKIEREN");
    LogImportant("════════════════════════════════════════════");
    
    LogImportant("📊 INPUT-PARAMETER:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Entry: " + DoubleToString(entry_price, 5));
    LogImportant("   SL: " + DoubleToString(sl_price, 5));
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    
    // SCHRITT 1: ABSOLUTE SICHERHEITSGRENZEN
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double max_safe_lots = CalculateMaximumSafeLots_v91(balance);
    
    LogImportant("🛡️ ABSOLUTE SICHERHEITSGRENZE: " + DoubleToString(max_safe_lots, 3) + " Lots");
    
    // SCHRITT 2: SYMBOL-DATEN SAMMELN
    if(!SymbolSelect(symbol, true)) {
        message = "Symbol konnte nicht aktiviert werden: " + symbol;
        LogError("❌ " + message);
        return -1;
    }
    
    double volume_min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double volume_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    // SCHRITT 3: LOSS-PER-LOT BERECHNUNG MIT MEHRFACHER VALIDIERUNG
    double distance = MathAbs(entry_price - sl_price);
    double loss_per_lot = 0.0;
    string error_msg = "";
    string method_used = "";
    
    LogImportant("🔍 LOSS-PER-LOT BERECHNUNG:");
    LogImportant("   Distanz: " + DoubleToString(distance, 5));
    
    // Methode 1: JPY-spezifische Berechnung (falls JPY-Paar)
    if(IsJPYPair_v91(symbol)) {
        LogImportant("🇯🇵 JPY-PAAR ERKANNT - verwende Ultra-Sichere JPY-Berechnung");
        loss_per_lot = CalculateJPYLossPerLot_v91(symbol, entry_price, sl_price, error_msg);
        if(loss_per_lot > 0) {
            method_used = "Ultra-Sichere JPY-Berechnung v9.1";
        } else {
            LogError("❌ JPY-Berechnung fehlgeschlagen: " + error_msg);
        }
    }
    
    // Methode 2: OrderCalcProfit (mit Ultra-Sicherer Validierung)
    if(loss_per_lot <= 0) {
        LogImportant("🔄 VERWENDE OrderCalcProfit mit Ultra-Sicherer Validierung...");
        double profit_at_sl = 0;
        if(OrderCalcProfit(order_type, symbol, 1.0, entry_price, sl_price, profit_at_sl)) {
            double potential_loss = MathAbs(profit_at_sl);
            LogImportant("   OrderCalcProfit Ergebnis: " + DoubleToString(potential_loss, 5));
            
            // Ultra-Sichere Validierung
            string validation_msg = "";
            if(ValidateLossPerLot_v91(symbol, potential_loss, distance, validation_msg)) {
                loss_per_lot = potential_loss;
                method_used = "OrderCalcProfit (Ultra-Sicher validiert)";
                LogImportant("✅ OrderCalcProfit validiert: " + validation_msg);
            } else {
                LogError("❌ OrderCalcProfit ABGELEHNT: " + validation_msg);
            }
        } else {
            LogWarning("⚠️ OrderCalcProfit fehlgeschlagen");
        }
    }
    
    // Methode 3: Konservative Schätzung basierend auf Symbol-Typ
    if(loss_per_lot <= 0) {
        LogWarning("🚨 ALLE PRÄZISEN METHODEN FEHLGESCHLAGEN - verwende KONSERVATIVE Schätzung");
        
        if(IsJPYPair_v91(symbol)) {
            // JPY: Sehr konservativ - 3 EUR pro Pip
            double pips = distance / 0.01;
            loss_per_lot = pips * 3.0;
            method_used = "JPY Konservative Schätzung (3 EUR/Pip)";
        } else if(StringLen(symbol) >= 6) {
            // Forex: Sehr konservativ - 15 EUR pro Pip
            double pips = distance / 0.0001;
            loss_per_lot = pips * 15.0;
            method_used = "Forex Konservative Schätzung (15 EUR/Pip)";
        } else {
            // Andere: Sehr konservativ - 2:1 Verhältnis
            loss_per_lot = distance * 2.0;
            method_used = "Allgemeine Konservative Schätzung (2:1)";
        }
        
        LogWarning("   Konservative Schätzung: " + DoubleToString(loss_per_lot, 5) + " EUR");
    }
    
    if(loss_per_lot <= 0) {
        message = "Alle Berechnungsmethoden fehlgeschlagen - TRADE ABGELEHNT";
        LogError("❌ " + message);
        return -1;
    }
    
    LogImportant("✅ LOSS-PER-LOT BESTIMMT:");
    LogImportant("   Methode: " + method_used);
    LogImportant("   Loss per Lot: " + DoubleToString(loss_per_lot, 5) + " EUR");
    
    // SCHRITT 4: ULTRA-SICHERE LOTSIZE-BERECHNUNG
    double risk_amount = balance * (risk_percent / 100.0);
    double theoretical_lots = risk_amount / loss_per_lot;
    
    LogImportant("💰 LOTSIZE-BERECHNUNG:");
    LogImportant("   Balance: " + DoubleToString(balance, 2) + " EUR");
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_amount, 2) + " EUR");
    LogImportant("   Theoretische Lots: " + DoubleToString(theoretical_lots, 6));
    
    // SCHRITT 5: MEHRFACHE SICHERHEITSBEGRENZUNGEN
    double safe_lots = theoretical_lots;
    
    // Begrenzung 1: Absolute Sicherheitsgrenze
    if(safe_lots > max_safe_lots) {
        LogWarning("🚨 SICHERHEITSGRENZE ÜBERSCHRITTEN!");
        LogWarning("   Berechnet: " + DoubleToString(safe_lots, 6));
        LogWarning("   Maximum: " + DoubleToString(max_safe_lots, 6));
        safe_lots = max_safe_lots;
    }
    
    // Begrenzung 2: Niemals mehr als 5% der Balance riskieren
    double max_risk_amount = balance * MAX_RISK_PERCENT_ABSOLUTE / 100.0;
    double max_lots_by_risk = max_risk_amount / loss_per_lot;
    if(safe_lots > max_lots_by_risk) {
        LogWarning("🚨 5%-RISIKO-GRENZE ÜBERSCHRITTEN!");
        LogWarning("   Berechnet: " + DoubleToString(safe_lots, 6));
        LogWarning("   5%-Maximum: " + DoubleToString(max_lots_by_risk, 6));
        safe_lots = max_lots_by_risk;
    }
    
    // Begrenzung 3: Symbol-Limits
    double volume_max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    if(safe_lots > volume_max) {
        safe_lots = volume_max;
        LogImportant("   Auf Symbol-Maximum begrenzt: " + DoubleToString(safe_lots, 6));
    }
    
    // Begrenzung 4: Minimum-Lot
    if(safe_lots < volume_min) {
        // Prüfe ob Minimum-Lot das Risiko überschreitet
        double min_risk_amount = volume_min * loss_per_lot;
        double min_risk_percent = (min_risk_amount / balance) * 100.0;
        
        if(min_risk_percent > MAX_RISK_PERCENT_ABSOLUTE) {
            message = "Minimum-Lot überschreitet 5%-Sicherheitsgrenze: " + 
                     DoubleToString(min_risk_percent, 2) + "% > " + 
                     DoubleToString(MAX_RISK_PERCENT_ABSOLUTE, 1) + "%";
            LogError("❌ " + message);
            return -1;
        }
        
        safe_lots = volume_min;
        LogImportant("   Auf Minimum angehoben: " + DoubleToString(safe_lots, 6));
    }
    
    // SCHRITT 6: SICHERHEITSFAKTOR ANWENDEN
    safe_lots = safe_lots * SAFETY_FACTOR;
    LogImportant("🛡️ SICHERHEITSFAKTOR (" + DoubleToString(SAFETY_FACTOR * 100, 0) + "%) angewendet: " + 
                DoubleToString(safe_lots, 6));
    
    // SCHRITT 7: NORMALISIERUNG
    safe_lots = MathFloor(safe_lots / volume_step) * volume_step;
    if(safe_lots < volume_min) safe_lots = volume_min;
    
    // SCHRITT 8: FINALE VALIDIERUNG
    double final_risk_amount = safe_lots * loss_per_lot;
    double final_risk_percent = (final_risk_amount / balance) * 100.0;
    
    LogImportant("🛡️ FINALE ULTRA-SICHERE VALIDIERUNG:");
    LogImportant("   Finale Lots: " + DoubleToString(safe_lots, 6));
    LogImportant("   Finales Risiko: " + DoubleToString(final_risk_amount, 2) + " EUR (" + 
                DoubleToString(final_risk_percent, 2) + "%)");
    LogImportant("   Sicherheitsgrenze: " + DoubleToString(MAX_RISK_PERCENT_ABSOLUTE, 1) + "%");
    
    // EMERGENCY BRAKE: Finale Sicherheitsprüfung
    if(final_risk_percent > MAX_RISK_PERCENT_ABSOLUTE) {
        message = "EMERGENCY BRAKE: Finales Risiko überschreitet Sicherheitsgrenze: " + 
                 DoubleToString(final_risk_percent, 2) + "% > " + 
                 DoubleToString(MAX_RISK_PERCENT_ABSOLUTE, 1) + "%";
        LogError("🚨 " + message);
        return -1;
    }
    
    // Zusätzliche Plausibilitätsprüfung
    if(safe_lots > balance / 100.0) {  // Niemals mehr als 1 Lot pro 100 EUR
        message = "EMERGENCY BRAKE: Lots zu hoch für Balance: " + 
                 DoubleToString(safe_lots, 6) + " Lots bei " + 
                 DoubleToString(balance, 2) + " EUR Balance";
        LogError("🚨 " + message);
        return -1;
    }
    
    LogImportant("✅ ULTRA-SICHERE BERECHNUNG v9.1 ERFOLGREICH!");
    LogImportant("   Empfohlene Lotsize: " + DoubleToString(safe_lots, 6));
    LogImportant("   Tatsächliches Risiko: " + DoubleToString(final_risk_percent, 2) + "%");
    LogImportant("   Verwendete Methode: " + method_used);
    LogImportant("🛡️ ALLE SICHERHEITSPRÜFUNGEN BESTANDEN");
    LogImportant("════════════════════════════════════════════");
    
    message = "Ultra-Safe v9.1 calculation successful (" + method_used + ")";
    return safe_lots;
}

//+------------------------------------------------------------------+
//| EMERGENCY BRAKE FUNKTION                                         |
//+------------------------------------------------------------------+
bool EmergencyBrakeCheck_v91(string symbol, double lots, double balance) {
    LogImportant("🚨 EMERGENCY BRAKE CHECK:");
    
    // Check 1: Lots vs Balance Ratio
    double lots_per_1000 = (lots * 1000.0) / balance;
    if(lots_per_1000 > MAX_LOTS_PER_1000_EUR) {
        LogError("🚨 EMERGENCY BRAKE: Zu viele Lots pro 1000 EUR: " + 
                DoubleToString(lots_per_1000, 3) + " > " + 
                DoubleToString(MAX_LOTS_PER_1000_EUR, 1));
        return false;
    }
    
    // Check 2: Absolute Lot Limit
    if(lots > 10.0) {  // Niemals mehr als 10 Lots, egal was
        LogError("🚨 EMERGENCY BRAKE: Absolute Lot-Grenze überschritten: " + 
                DoubleToString(lots, 3) + " > 10.0");
        return false;
    }
    
    // Check 3: Balance-basierte Limits
    if(balance < 1000 && lots > 0.1) {
        LogError("🚨 EMERGENCY BRAKE: Zu viele Lots für kleine Balance: " + 
                DoubleToString(lots, 3) + " Lots bei " + 
                DoubleToString(balance, 2) + " EUR");
        return false;
    }
    
    LogImportant("✅ EMERGENCY BRAKE: Alle Checks bestanden");
    return true;
}

//+------------------------------------------------------------------+
//| LOGGING FUNKTIONEN                                               |
//+------------------------------------------------------------------+
void LogImportant(string message) {
    Print("[⚡] ", message);
}

void LogError(string message) {
    Print("[ERROR] ", message);
}

void LogWarning(string message) {
    Print("[WARNING] ", message);
}
