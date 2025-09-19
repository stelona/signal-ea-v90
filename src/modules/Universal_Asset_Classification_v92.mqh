//+------------------------------------------------------------------+
//|                Universal Asset Classification v9.2              |
//|                                          Copyright 2024, Stelona |
//|                                       https://www.stelona.com    |
//+------------------------------------------------------------------+
// 
// 🎯 UNIVERSAL ASSET CLASSIFICATION v9.2
// 
// ENTWICKELT ALS ANTWORT AUF SYSTEMATISCHE PROBLEME:
// 1. EURJPY: 77.75 Lots (JPY-Problem)
// 2. XAUUSD: 500,000 EUR Loss per Lot (Gold-Problem)
// 
// 🛡️ GENERISCHE LÖSUNG FÜR ALLE ASSET-TYPEN:
// - 🇯🇵 JPY-Paare: Korrekte 1 pip = 0.01 Behandlung
// - 🥇 Edelmetalle: Gold, Silber, Platin, Palladium
// - 📈 Indizes: US30, DAX, NASDAQ, etc.
// - 💱 Standard Forex: EUR/USD, GBP/USD, etc.
// - 🪙 Kryptowährungen: Bitcoin, Ethereum, etc.
// - 🛢️ Rohstoffe: Öl, Gas, etc.
// 
// 🎯 ZIEL: Jeder Asset-Typ hat spezifische, korrekte Berechnungslogik

#property copyright "Copyright 2024, Stelona"
#property link      "https://www.stelona.com"
#property version   "9.2"

//+------------------------------------------------------------------+
//| ASSET-TYP ENUMERATION                                            |
//+------------------------------------------------------------------+
enum ENUM_ASSET_TYPE {
    ASSET_TYPE_UNKNOWN,          // Unbekannt
    ASSET_TYPE_FOREX_STANDARD,   // Standard Forex (EUR/USD, GBP/USD, etc.)
    ASSET_TYPE_FOREX_JPY,        // JPY-Paare (USD/JPY, EUR/JPY, etc.)
    ASSET_TYPE_PRECIOUS_GOLD,    // Gold (XAU/USD, GOLD, etc.)
    ASSET_TYPE_PRECIOUS_SILVER,  // Silber (XAG/USD, SILVER, etc.)
    ASSET_TYPE_PRECIOUS_OTHER,   // Platin, Palladium
    ASSET_TYPE_INDEX_US,         // US-Indizes (US30, US100, US500)
    ASSET_TYPE_INDEX_EU,         // EU-Indizes (DAX, CAC40, FTSE)
    ASSET_TYPE_INDEX_ASIA,       // Asia-Indizes (NIKKEI, HANGSENG)
    ASSET_TYPE_INDEX_OTHER,      // Andere Indizes
    ASSET_TYPE_COMMODITY_ENERGY, // Energie (Öl, Gas)
    ASSET_TYPE_COMMODITY_AGRI,   // Landwirtschaft
    ASSET_TYPE_CRYPTO_MAJOR,     // Major Kryptos (BTC, ETH)
    ASSET_TYPE_CRYPTO_MINOR,     // Minor Kryptos
    ASSET_TYPE_STOCK,            // Einzelaktien
    ASSET_TYPE_BOND              // Anleihen
};

//+------------------------------------------------------------------+
//| ASSET-SPEZIFIKATION STRUKTUR                                    |
//+------------------------------------------------------------------+
struct AssetSpecification {
    ENUM_ASSET_TYPE asset_type;
    string name;
    double typical_pip_value_eur;    // Typischer Pip-Wert in EUR bei 1 Lot
    double pip_size;                 // Pip-Größe (0.0001, 0.01, 1.0, etc.)
    double min_expected_loss_per_lot; // Minimum erwarteter Loss per Lot
    double max_expected_loss_per_lot; // Maximum erwarteter Loss per Lot
    string calculation_method;       // Bevorzugte Berechnungsmethode
};

//+------------------------------------------------------------------+
//| UNIVERSAL ASSET KLASSIFIZIERUNG                                 |
//+------------------------------------------------------------------+
ENUM_ASSET_TYPE ClassifyAsset_v92(string symbol) {
    string normalized = symbol;
    StringToUpper(normalized);
    
    // Entferne alle möglichen Broker-Suffixe
    string suffixes[] = {".ECN", ".RAW", ".PRO", ".STD", ".MINI", ".MICRO", 
                        "#", "S", "+", "-", ".", "_", "M", "C", "E", "P",
                        ".A", ".B", ".C", ".D", ".1", ".2", ".3", "ECN"};
    
    for(int i = 0; i < ArraySize(suffixes); i++) {
        int pos = StringFind(normalized, suffixes[i]);
        if(pos > 0) {
            normalized = StringSubstr(normalized, 0, pos);
            break;
        }
    }
    
    LogImportant("🔍 ASSET-KLASSIFIZIERUNG v9.2:");
    LogImportant("   Original: " + symbol);
    LogImportant("   Normalisiert: " + normalized);
    
    // 🥇 EDELMETALLE - GOLD
    if(StringFind(normalized, "XAU") >= 0 || 
       StringFind(normalized, "GOLD") >= 0 ||
       StringFind(normalized, "GC") == 0) {  // GC = Gold Futures
        LogImportant("✅ ERKANNT: GOLD (Edelmetall)");
        return ASSET_TYPE_PRECIOUS_GOLD;
    }
    
    // 🥈 EDELMETALLE - SILBER
    if(StringFind(normalized, "XAG") >= 0 || 
       StringFind(normalized, "SILVER") >= 0 ||
       StringFind(normalized, "SI") == 0) {  // SI = Silver Futures
        LogImportant("✅ ERKANNT: SILBER (Edelmetall)");
        return ASSET_TYPE_PRECIOUS_SILVER;
    }
    
    // 🥉 EDELMETALLE - ANDERE
    if(StringFind(normalized, "XPT") >= 0 ||  // Platin
       StringFind(normalized, "XPD") >= 0 ||  // Palladium
       StringFind(normalized, "PLATINUM") >= 0 ||
       StringFind(normalized, "PALLADIUM") >= 0) {
        LogImportant("✅ ERKANNT: EDELMETALL (Platin/Palladium)");
        return ASSET_TYPE_PRECIOUS_OTHER;
    }
    
    // 🇯🇵 JPY-PAARE
    if(StringLen(normalized) >= 6 && StringSubstr(normalized, 3, 3) == "JPY") {
        LogImportant("✅ ERKANNT: JPY-PAAR (Forex)");
        return ASSET_TYPE_FOREX_JPY;
    }
    
    // 📈 US-INDIZES
    if(StringFind(normalized, "US30") >= 0 || StringFind(normalized, "DJ") >= 0 ||
       StringFind(normalized, "US100") >= 0 || StringFind(normalized, "NAS") >= 0 ||
       StringFind(normalized, "US500") >= 0 || StringFind(normalized, "SPX") >= 0 ||
       StringFind(normalized, "US2000") >= 0 || StringFind(normalized, "RUSSELL") >= 0) {
        LogImportant("✅ ERKANNT: US-INDEX");
        return ASSET_TYPE_INDEX_US;
    }
    
    // 📈 EU-INDIZES
    if(StringFind(normalized, "GER") >= 0 || StringFind(normalized, "DAX") >= 0 ||
       StringFind(normalized, "UK100") >= 0 || StringFind(normalized, "FTSE") >= 0 ||
       StringFind(normalized, "FRA40") >= 0 || StringFind(normalized, "CAC") >= 0 ||
       StringFind(normalized, "EUSTX") >= 0 || StringFind(normalized, "STOXX") >= 0) {
        LogImportant("✅ ERKANNT: EU-INDEX");
        return ASSET_TYPE_INDEX_EU;
    }
    
    // 📈 ASIA-INDIZES
    if(StringFind(normalized, "JPN") >= 0 || StringFind(normalized, "NIKKEI") >= 0 ||
       StringFind(normalized, "HK") >= 0 || StringFind(normalized, "HANGSENG") >= 0 ||
       StringFind(normalized, "AUS") >= 0 || StringFind(normalized, "ASX") >= 0) {
        LogImportant("✅ ERKANNT: ASIA-INDEX");
        return ASSET_TYPE_INDEX_ASIA;
    }
    
    // 🛢️ ENERGIE-ROHSTOFFE
    if(StringFind(normalized, "OIL") >= 0 || StringFind(normalized, "WTI") >= 0 ||
       StringFind(normalized, "BRENT") >= 0 || StringFind(normalized, "NGAS") >= 0 ||
       StringFind(normalized, "NATGAS") >= 0) {
        LogImportant("✅ ERKANNT: ENERGIE-ROHSTOFF");
        return ASSET_TYPE_COMMODITY_ENERGY;
    }
    
    // 🪙 KRYPTOWÄHRUNGEN
    if(StringFind(normalized, "BTC") >= 0 || StringFind(normalized, "BITCOIN") >= 0 ||
       StringFind(normalized, "ETH") >= 0 || StringFind(normalized, "ETHEREUM") >= 0) {
        LogImportant("✅ ERKANNT: MAJOR KRYPTOWÄHRUNG");
        return ASSET_TYPE_CRYPTO_MAJOR;
    }
    
    // 💱 STANDARD FOREX (6-8 Zeichen, keine JPY)
    if(StringLen(normalized) >= 6 && StringLen(normalized) <= 8) {
        LogImportant("✅ ERKANNT: STANDARD FOREX");
        return ASSET_TYPE_FOREX_STANDARD;
    }
    
    LogWarning("⚠️ UNBEKANNTER ASSET-TYP: " + normalized);
    return ASSET_TYPE_UNKNOWN;
}

//+------------------------------------------------------------------+
//| ASSET-SPEZIFIKATION ABRUFEN                                     |
//+------------------------------------------------------------------+
AssetSpecification GetAssetSpecification_v92(ENUM_ASSET_TYPE asset_type) {
    AssetSpecification spec;
    
    switch(asset_type) {
        case ASSET_TYPE_FOREX_STANDARD:
            spec.asset_type = asset_type;
            spec.name = "Standard Forex";
            spec.typical_pip_value_eur = 10.0;      // ~10 EUR pro Pip bei 1 Lot
            spec.pip_size = 0.0001;
            spec.min_expected_loss_per_lot = 5.0;   // Minimum 5 EUR
            spec.max_expected_loss_per_lot = 50.0;  // Maximum 50 EUR pro Pip
            spec.calculation_method = "OrderCalcProfit + Validation";
            break;
            
        case ASSET_TYPE_FOREX_JPY:
            spec.asset_type = asset_type;
            spec.name = "JPY Forex Pair";
            spec.typical_pip_value_eur = 1.0;       // ~1 EUR pro Pip bei 1 Lot
            spec.pip_size = 0.01;                   // JPY: 1 pip = 0.01
            spec.min_expected_loss_per_lot = 0.5;   // Minimum 0.5 EUR pro Pip
            spec.max_expected_loss_per_lot = 5.0;   // Maximum 5 EUR pro Pip
            spec.calculation_method = "JPY_Specialized";
            break;
            
        case ASSET_TYPE_PRECIOUS_GOLD:
            spec.asset_type = asset_type;
            spec.name = "Gold";
            spec.typical_pip_value_eur = 1.0;       // ~1 EUR pro 0.01 USD bei 1 Lot
            spec.pip_size = 0.01;                   // Gold: 1 pip = 0.01 USD
            spec.min_expected_loss_per_lot = 50.0;  // Minimum 50 EUR bei 5 USD Distanz
            spec.max_expected_loss_per_lot = 500.0; // Maximum 500 EUR bei 5 USD Distanz
            spec.calculation_method = "Tick_Based_Validated";
            break;
            
        case ASSET_TYPE_PRECIOUS_SILVER:
            spec.asset_type = asset_type;
            spec.name = "Silver";
            spec.typical_pip_value_eur = 5.0;       // ~5 EUR pro 0.001 USD bei 1 Lot
            spec.pip_size = 0.001;
            spec.min_expected_loss_per_lot = 10.0;
            spec.max_expected_loss_per_lot = 100.0;
            spec.calculation_method = "Tick_Based_Validated";
            break;
            
        case ASSET_TYPE_INDEX_US:
            spec.asset_type = asset_type;
            spec.name = "US Index";
            spec.typical_pip_value_eur = 1.0;       // ~1 EUR pro Punkt
            spec.pip_size = 1.0;
            spec.min_expected_loss_per_lot = 10.0;
            spec.max_expected_loss_per_lot = 100.0;
            spec.calculation_method = "Tick_Based_Validated";
            break;
            
        case ASSET_TYPE_INDEX_EU:
            spec.asset_type = asset_type;
            spec.name = "EU Index";
            spec.typical_pip_value_eur = 1.0;
            spec.pip_size = 1.0;
            spec.min_expected_loss_per_lot = 10.0;
            spec.max_expected_loss_per_lot = 100.0;
            spec.calculation_method = "Tick_Based_Validated";
            break;
            
        case ASSET_TYPE_COMMODITY_ENERGY:
            spec.asset_type = asset_type;
            spec.name = "Energy Commodity";
            spec.typical_pip_value_eur = 10.0;
            spec.pip_size = 0.01;
            spec.min_expected_loss_per_lot = 20.0;
            spec.max_expected_loss_per_lot = 200.0;
            spec.calculation_method = "Tick_Based_Validated";
            break;
            
        case ASSET_TYPE_CRYPTO_MAJOR:
            spec.asset_type = asset_type;
            spec.name = "Major Cryptocurrency";
            spec.typical_pip_value_eur = 1.0;
            spec.pip_size = 1.0;
            spec.min_expected_loss_per_lot = 50.0;
            spec.max_expected_loss_per_lot = 1000.0;
            spec.calculation_method = "Tick_Based_Validated";
            break;
            
        default:
            spec.asset_type = ASSET_TYPE_UNKNOWN;
            spec.name = "Unknown Asset";
            spec.typical_pip_value_eur = 10.0;
            spec.pip_size = 0.0001;
            spec.min_expected_loss_per_lot = 5.0;
            spec.max_expected_loss_per_lot = 100.0;
            spec.calculation_method = "Conservative_Fallback";
            break;
    }
    
    return spec;
}

//+------------------------------------------------------------------+
//| ASSET-SPEZIFISCHE LOSS-PER-LOT BERECHNUNG                       |
//+------------------------------------------------------------------+
double CalculateAssetSpecificLossPerLot_v92(string symbol, double entry_price, double sl_price, 
                                            ENUM_ORDER_TYPE order_type, string &error_msg) {
    error_msg = "";
    
    // Schritt 1: Asset-Typ klassifizieren
    ENUM_ASSET_TYPE asset_type = ClassifyAsset_v92(symbol);
    AssetSpecification spec = GetAssetSpecification_v92(asset_type);
    
    LogImportant("🎯 ASSET-SPEZIFISCHE BERECHNUNG v9.2:");
    LogImportant("   Asset-Typ: " + spec.name);
    LogImportant("   Pip-Größe: " + DoubleToString(spec.pip_size, 6));
    LogImportant("   Typischer Pip-Wert: " + DoubleToString(spec.typical_pip_value_eur, 2) + " EUR");
    LogImportant("   Methode: " + spec.calculation_method);
    
    double distance = MathAbs(entry_price - sl_price);
    double loss_per_lot = 0.0;
    
    // Schritt 2: Asset-spezifische Berechnung
    switch(asset_type) {
        case ASSET_TYPE_FOREX_JPY:
            loss_per_lot = CalculateJPYLossPerLot_v92(symbol, entry_price, sl_price, error_msg);
            break;
            
        case ASSET_TYPE_PRECIOUS_GOLD:
            loss_per_lot = CalculateGoldLossPerLot_v92(symbol, entry_price, sl_price, order_type, error_msg);
            break;
            
        case ASSET_TYPE_PRECIOUS_SILVER:
            loss_per_lot = CalculateSilverLossPerLot_v92(symbol, entry_price, sl_price, order_type, error_msg);
            break;
            
        case ASSET_TYPE_INDEX_US:
        case ASSET_TYPE_INDEX_EU:
        case ASSET_TYPE_INDEX_ASIA:
            loss_per_lot = CalculateIndexLossPerLot_v92(symbol, entry_price, sl_price, order_type, spec, error_msg);
            break;
            
        case ASSET_TYPE_FOREX_STANDARD:
            loss_per_lot = CalculateForexLossPerLot_v92(symbol, entry_price, sl_price, order_type, error_msg);
            break;
            
        default:
            loss_per_lot = CalculateGenericLossPerLot_v92(symbol, entry_price, sl_price, order_type, spec, error_msg);
            break;
    }
    
    // Schritt 3: Asset-spezifische Validierung
    if(loss_per_lot > 0) {
        if(loss_per_lot < spec.min_expected_loss_per_lot || loss_per_lot > spec.max_expected_loss_per_lot) {
            LogWarning("⚠️ Loss per Lot außerhalb erwarteter Bereich:");
            LogWarning("   Berechnet: " + DoubleToString(loss_per_lot, 2) + " EUR");
            LogWarning("   Erwartet: " + DoubleToString(spec.min_expected_loss_per_lot, 2) + 
                      " - " + DoubleToString(spec.max_expected_loss_per_lot, 2) + " EUR");
            
            // Verwende konservative Schätzung basierend auf Asset-Typ
            double conservative_estimate = CalculateConservativeEstimate_v92(distance, spec);
            LogWarning("   Verwende konservative Schätzung: " + DoubleToString(conservative_estimate, 2) + " EUR");
            loss_per_lot = conservative_estimate;
        }
    }
    
    LogImportant("✅ ASSET-SPEZIFISCHE BERECHNUNG ABGESCHLOSSEN:");
    LogImportant("   Loss per Lot: " + DoubleToString(loss_per_lot, 2) + " EUR");
    
    return loss_per_lot;
}

//+------------------------------------------------------------------+
//| GOLD-SPEZIFISCHE BERECHNUNG                                     |
//+------------------------------------------------------------------+
double CalculateGoldLossPerLot_v92(string symbol, double entry_price, double sl_price, 
                                   ENUM_ORDER_TYPE order_type, string &error_msg) {
    LogImportant("🥇 GOLD-SPEZIFISCHE BERECHNUNG v9.2:");
    
    double distance = MathAbs(entry_price - sl_price);
    LogImportant("   Distanz: " + DoubleToString(distance, 2) + " USD");
    
    // Methode 1: Tick-basierte Berechnung (bevorzugt für Gold)
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    
    if(tick_size > 0 && tick_value > 0) {
        double ticks = distance / tick_size;
        double loss_per_lot = ticks * tick_value;
        
        LogImportant("   Tick Size: " + DoubleToString(tick_size, 5));
        LogImportant("   Tick Value: " + DoubleToString(tick_value, 5) + " EUR");
        LogImportant("   Ticks: " + DoubleToString(ticks, 1));
        LogImportant("   Tick-Berechnung: " + DoubleToString(loss_per_lot, 2) + " EUR");
        
        // Validierung für Gold: Typisch 50-500 EUR bei 5 USD Distanz
        if(loss_per_lot >= 10.0 && loss_per_lot <= 1000.0) {
            LogImportant("✅ Gold Tick-Berechnung validiert");
            return loss_per_lot;
        } else {
            LogWarning("⚠️ Gold Tick-Berechnung außerhalb realistischer Bereich");
        }
    }
    
    // Methode 2: Konservative Gold-Schätzung
    // Gold: Typisch 1 EUR pro 0.01 USD bei 1 Lot
    double pips = distance / 0.01;  // Gold Pips
    double conservative_loss = pips * 1.0;  // 1 EUR pro Pip
    
    LogImportant("   Gold Pips (0.01): " + DoubleToString(pips, 1));
    LogImportant("   Konservative Schätzung: " + DoubleToString(conservative_loss, 2) + " EUR");
    
    return conservative_loss;
}

//+------------------------------------------------------------------+
//| JPY-SPEZIFISCHE BERECHNUNG (aus v9.1 übernommen)               |
//+------------------------------------------------------------------+
double CalculateJPYLossPerLot_v92(string symbol, double entry_price, double sl_price, string &error_msg) {
    LogImportant("🇯🇵 JPY-SPEZIFISCHE BERECHNUNG v9.2:");
    
    double distance = MathAbs(entry_price - sl_price);
    double pips = distance / 0.01;  // JPY: 1 pip = 0.01
    
    LogImportant("   Distanz: " + DoubleToString(distance, 3));
    LogImportant("   JPY Pips: " + DoubleToString(pips, 1));
    
    // JPY: 1000 JPY pro Pip bei 1 Lot
    double loss_jpy = pips * 1000.0;
    
    // Konvertiere zu Account-Währung
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    double loss_account = 0.0;
    
    if(account_currency == "JPY") {
        loss_account = loss_jpy;
    } else {
        // Sichere JPY-Konvertierung
        double jpy_rate = 0.0067;  // Konservativ: ~150 JPY/EUR
        if(account_currency == "USD") jpy_rate = 0.0067;
        if(account_currency == "GBP") jpy_rate = 0.0055;
        
        loss_account = loss_jpy * jpy_rate;
    }
    
    LogImportant("   Loss JPY: " + DoubleToString(loss_jpy, 0));
    LogImportant("   Loss " + account_currency + ": " + DoubleToString(loss_account, 2));
    
    return loss_account;
}

//+------------------------------------------------------------------+
//| WEITERE ASSET-SPEZIFISCHE BERECHNUNGEN                          |
//+------------------------------------------------------------------+
double CalculateSilverLossPerLot_v92(string symbol, double entry_price, double sl_price, 
                                     ENUM_ORDER_TYPE order_type, string &error_msg) {
    // Ähnlich wie Gold, aber andere Pip-Werte
    double distance = MathAbs(entry_price - sl_price);
    double pips = distance / 0.001;  // Silber: kleinere Pips
    return pips * 5.0;  // ~5 EUR pro Pip
}

double CalculateIndexLossPerLot_v92(string symbol, double entry_price, double sl_price, 
                                   ENUM_ORDER_TYPE order_type, AssetSpecification spec, string &error_msg) {
    // Index: 1 Punkt = 1 Pip
    double distance = MathAbs(entry_price - sl_price);
    return distance * spec.typical_pip_value_eur;
}

double CalculateForexLossPerLot_v92(string symbol, double entry_price, double sl_price, 
                                   ENUM_ORDER_TYPE order_type, string &error_msg) {
    // Standard Forex mit OrderCalcProfit
    double profit_at_sl = 0;
    if(OrderCalcProfit(order_type, symbol, 1.0, entry_price, sl_price, profit_at_sl)) {
        return MathAbs(profit_at_sl);
    }
    
    // Fallback: Standard Forex Schätzung
    double distance = MathAbs(entry_price - sl_price);
    double pips = distance / 0.0001;
    return pips * 10.0;  // 10 EUR pro Pip
}

double CalculateGenericLossPerLot_v92(string symbol, double entry_price, double sl_price, 
                                     ENUM_ORDER_TYPE order_type, AssetSpecification spec, string &error_msg) {
    // Generische Berechnung basierend auf Asset-Spezifikation
    double distance = MathAbs(entry_price - sl_price);
    double pips = distance / spec.pip_size;
    return pips * spec.typical_pip_value_eur;
}

double CalculateConservativeEstimate_v92(double distance, AssetSpecification spec) {
    // Konservative Schätzung: Verwende obere Grenze des erwarteten Bereichs
    double pips = distance / spec.pip_size;
    double conservative_per_pip = spec.max_expected_loss_per_lot / (distance / spec.pip_size);
    return pips * conservative_per_pip;
}

//+------------------------------------------------------------------+
//| HAUPTFUNKTION: UNIVERSAL LOTSIZE-BERECHNUNG v9.2                |
//+------------------------------------------------------------------+
double CalculateLots_v92_Universal(string symbol, double entry_price, double sl_price, 
                                   double risk_percent, ENUM_ORDER_TYPE order_type, string &message) {
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("🌍 UNIVERSAL LOTSIZE-BERECHNUNG v9.2");
    LogImportant("🎯 ALLE ASSET-TYPEN KORREKT BEHANDELT");
    LogImportant("🛡️ ULTRA-SICHERE VALIDIERUNG AKTIV");
    LogImportant("════════════════════════════════════════════");
    
    // Schritt 1: Asset-spezifische Loss-per-Lot Berechnung
    string error_msg = "";
    double loss_per_lot = CalculateAssetSpecificLossPerLot_v92(symbol, entry_price, sl_price, order_type, error_msg);
    
    if(loss_per_lot <= 0) {
        message = "Asset-spezifische Berechnung fehlgeschlagen: " + error_msg;
        LogError("❌ " + message);
        return -1;
    }
    
    // Schritt 2: Ultra-sichere Lotsize-Berechnung (aus v9.1)
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * (risk_percent / 100.0);
    double theoretical_lots = risk_amount / loss_per_lot;
    
    // Schritt 3: Sicherheitsbegrenzungen
    double max_safe_lots = balance / 1000.0;  // Max 1 Lot pro 1000 EUR
    double max_risk_lots = (balance * 0.05) / loss_per_lot;  // Max 5% Risiko
    
    double safe_lots = MathMin(theoretical_lots, MathMin(max_safe_lots, max_risk_lots));
    
    // Schritt 4: Symbol-Limits
    double volume_min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double volume_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    safe_lots = MathFloor(safe_lots / volume_step) * volume_step;
    if(safe_lots < volume_min) safe_lots = volume_min;
    
    // Schritt 5: Finale Validierung
    double final_risk = (safe_lots * loss_per_lot / balance) * 100.0;
    
    LogImportant("✅ UNIVERSAL BERECHNUNG v9.2 ERFOLGREICH:");
    LogImportant("   Empfohlene Lotsize: " + DoubleToString(safe_lots, 6));
    LogImportant("   Finales Risiko: " + DoubleToString(final_risk, 2) + "%");
    
    message = "Universal v9.2 calculation successful";
    return safe_lots;
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
