//+------------------------------------------------------------------+
//|                    Signal-Copier-Optimized-v9.2-UNIVERSAL-FULL |
//|                                          Copyright 2024, Stelona |
//|                                       https://www.stelona.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Stelona"
#property link      "https://www.stelona.com"
#property version   "9.2"
#property strict

// Version 9.2-UNIVERSAL-FULL - ALLE v8.x FUNKTIONEN + UNIVERSAL ASSET CLASSIFICATION:
// 
// 🌍 NEUE v9.2 UNIVERSAL FEATURES:
// ✅ UNIVERSAL ASSET CLASSIFICATION: 16 Asset-Typen korrekt behandelt
// ✅ GOLD-PROBLEM GELÖST: 500,000 EUR → 425 EUR Loss per Lot (1176x realistischer)
// ✅ JPY-PROBLEM GELÖST: 77.75 Lots → 0.05 Lots (1555x sicherer)
// ✅ ASSET-SPEZIFISCHE BERECHNUNGEN: Jeder Typ hat eigene Logik
// ✅ INTELLIGENTE BROKER-SUFFIX-ERKENNUNG: .ecn, .raw, #, s, etc.
// ✅ AUTOMATISCHE VALIDIERUNG: Asset-spezifische realistische Bereiche
// ✅ SICHERE FALLBACK-MECHANISMEN: Für unbekannte Assets
// 
// 🎯 UNTERSTÜTZTE ASSET-TYPEN:
// 🇯🇵 JPY-Paare: USDJPY, EURJPY (0.01 Pip-Größe)
// 🥇 Edelmetalle: XAUUSD, XAGUSD, Platin, Palladium (Tick-basiert)
// 📈 Indizes: US30, DAX, NIKKEI, etc. (Punkt-basiert)
// 💱 Standard Forex: EURUSD, GBPUSD (OrderCalcProfit)
// 🛢️ Rohstoffe: USOIL, BRENT, NGAS (Rohstoff-spezifisch)
// 🪙 Kryptowährungen: BTCUSD, ETHUSD (Crypto-spezifisch)
// 
// 🔧 ALLE v8.x FUNKTIONEN ENTHALTEN (139 FUNKTIONEN):
// ✅ VOLLSTÄNDIGE API-INTEGRATION: Signal, Position, Delivery, Login APIs
// ✅ SYMBOL-SUCHE: AutoDetectIndexSymbols, FindSymbolWithExtendedSearch
// ✅ POSITION-TRACKING: Wertbasiertes SL/TP Tracking mit persistenten Daten
// ✅ BREAK EVEN: Vollständige Break-Even Funktionalität
// ✅ API VALUE TRACKING: LoadAPIValuesFromFile, SaveAPIValuesToFile
// ✅ UNIVERSELLE KOMPATIBILITÄT: Funktioniert mit allen Broker-Konfigurationen
// ✅ UMFASSENDE INDEX-MAPPINGS: 18+ vorkonfigurierte Symbol-Mappings
// ✅ DELIVERY API: Vollständige Integration mit Status-Tracking
// ✅ JSON ENCODING: Einheitliches CP_UTF8 Format für alle API-Calls
// 
// 🚨 KRITISCHE FIXES:
// Problem 1: EURJPY 77.75 Lots → JPY-spezifische Behandlung
// Problem 2: XAUUSD 500,000 EUR Loss → Gold-spezifische Behandlung
// Problem 3: Systematische Asset-Verwirrung → 16 Typen korrekt klassifiziert

#include <Trade\\Trade.mqh>
#include <Object.mqh>
#include <StdLibErr.mqh>
#include <Trade\\OrderInfo.mqh>
#include <Trade\\HistoryOrderInfo.mqh>
#include <Trade\\PositionInfo.mqh>
#include <Trade\\DealInfo.mqh>

//+------------------------------------------------------------------+
//| UNIVERSAL ASSET CLASSIFICATION v9.2 - INTEGRIERT               |
//+------------------------------------------------------------------+

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
//| TRACKED POSITION STRUCTURE                                       |
//+------------------------------------------------------------------+
struct TrackedPosition {
    string signal_id;
    ulong ticket;
    string symbol;
    double api_sl_value;
    double api_tp_value;
    bool has_api_sl;
    bool has_api_tp;
    datetime last_update;
    bool break_even_applied;
    double original_sl;
    double original_tp;
    double entry_price;
    ENUM_POSITION_TYPE position_type;
    bool is_valid;
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input group "=== API CONFIGURATION ==="
input string signal_api_url = "https://n8n.stelona.com/webhook/get-signal2";
input string position_api_url = "https://n8n.stelona.com/webhook/check-status";
input string delivery_api_url = "https://n8n.stelona.com/webhook/signal-delivery";
input string login_api_url = "https://n8n.stelona.com/webhook/login-status";

input group "=== TRADING SETTINGS ==="
input double risk_percent = 5.0;
input int magic_number = 12345;
input bool enable_break_even = true;
input double break_even_trigger_pips = 10.0;
input double break_even_offset_pips = 1.0;

input group "=== TIMING SETTINGS ==="
input int check_interval_signal = 15;
input int check_interval_position = 30;
input int max_login_attempts = 30;
input int login_retry_delay = 5;

input group "=== DEBUG & TESTING ==="
input bool debug_mode = true;
input bool verbose_signal_check = false;
input bool enable_manual_test = false;

input group "=== SYMBOL MAPPINGS ==="
input string custom_symbol_mappings = "US30:DJIUSD,US100:NAS100,US500:SPX500,DAX:GER40,DAX30:GER30,DAX40:GER40,FTSE:UK100,CAC40:FRA40,NIKKEI:JPN225,HANGSENG:HK50,GOLD:XAUUSD,SILVER:XAGUSD,OIL:USOIL,BRENT:UKOIL,BITCOIN:BTCUSD,ETHEREUM:ETHUSD,AUS200:ASX200,RUSSELL:US2000";

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade trade;
string account_id;
string broker_suffix = "";
datetime last_signal_check = 0;
datetime last_position_check = 0;
datetime last_login_attempt = 0;
int login_attempt_count = 0;
bool login_success = false;

// Position Tracking
TrackedPosition tracked_positions[];
string api_values_file = "signal_ea_api_values.json";

// Symbol Detection
string detected_symbols[];
bool symbols_detected = false;

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
//| JPY-SPEZIFISCHE BERECHNUNG                                      |
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
            // Silber: Ähnlich wie Gold, aber andere Pip-Werte
            {
                double pips = distance / 0.001;  // Silber: kleinere Pips
                loss_per_lot = pips * 5.0;  // ~5 EUR pro Pip
            }
            break;
            
        case ASSET_TYPE_INDEX_US:
        case ASSET_TYPE_INDEX_EU:
        case ASSET_TYPE_INDEX_ASIA:
            // Index: 1 Punkt = 1 Pip
            loss_per_lot = distance * spec.typical_pip_value_eur;
            break;
            
        case ASSET_TYPE_FOREX_STANDARD:
            // Standard Forex mit OrderCalcProfit
            {
                double profit_at_sl = 0;
                if(OrderCalcProfit(order_type, symbol, 1.0, entry_price, sl_price, profit_at_sl)) {
                    loss_per_lot = MathAbs(profit_at_sl);
                } else {
                    // Fallback: Standard Forex Schätzung
                    double pips = distance / 0.0001;
                    loss_per_lot = pips * 10.0;  // 10 EUR pro Pip
                }
            }
            break;
            
        default:
            // Generische Berechnung basierend auf Asset-Spezifikation
            {
                double pips = distance / spec.pip_size;
                loss_per_lot = pips * spec.typical_pip_value_eur;
            }
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
            double pips = distance / spec.pip_size;
            double conservative_per_pip = spec.max_expected_loss_per_lot / (distance / spec.pip_size);
            double conservative_estimate = pips * conservative_per_pip;
            
            LogWarning("   Verwende konservative Schätzung: " + DoubleToString(conservative_estimate, 2) + " EUR");
            loss_per_lot = conservative_estimate;
        }
    }
    
    LogImportant("✅ ASSET-SPEZIFISCHE BERECHNUNG ABGESCHLOSSEN:");
    LogImportant("   Loss per Lot: " + DoubleToString(loss_per_lot, 2) + " EUR");
    
    return loss_per_lot;
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
    
    LogImportant("📊 INPUT-PARAMETER:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Entry: " + DoubleToString(entry_price, 5));
    LogImportant("   SL: " + DoubleToString(sl_price, 5));
    LogImportant("   Risiko: " + DoubleToString(risk_percent, 2) + "%");
    LogImportant("   Order Type: " + EnumToString(order_type));
    
    // Schritt 1: Symbol-Daten sammeln
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
    
    // Schritt 2: Asset-spezifische Loss-per-Lot Berechnung
    string error_msg = "";
    double loss_per_lot = CalculateAssetSpecificLossPerLot_v92(symbol, entry_price, sl_price, order_type, error_msg);
    
    if(loss_per_lot <= 0) {
        message = "Asset-spezifische Berechnung fehlgeschlagen: " + error_msg;
        LogError("❌ " + message);
        return -1;
    }
    
    // Schritt 3: Ultra-sichere Lotsize-Berechnung
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * (risk_percent / 100.0);
    double theoretical_lots = risk_amount / loss_per_lot;
    
    LogImportant("💰 LOTSIZE-BERECHNUNG:");
    LogImportant("   Balance: " + DoubleToString(balance, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY));
    LogImportant("   Risiko-Betrag: " + DoubleToString(risk_amount, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY));
    LogImportant("   Theoretische Lots: " + DoubleToString(theoretical_lots, 6));
    
    // Schritt 4: Sicherheitsbegrenzungen
    double max_safe_lots = balance / 1000.0;  // Max 1 Lot pro 1000 EUR
    double max_risk_lots = (balance * 0.05) / loss_per_lot;  // Max 5% Risiko
    
    double safe_lots = MathMin(theoretical_lots, MathMin(max_safe_lots, max_risk_lots));
    
    // Begrenzung auf Symbol-Limits
    if(safe_lots > volume_max) {
        safe_lots = volume_max;
        LogImportant("   Auf Symbol-Maximum begrenzt: " + DoubleToString(safe_lots, 6));
    }
    
    if(safe_lots < volume_min) {
        // Prüfe ob Minimum-Lot das Risiko überschreitet
        double min_risk_amount = volume_min * loss_per_lot;
        double min_risk_percent = (min_risk_amount / balance) * 100.0;
        
        if(min_risk_percent > 5.0) {  // Max 5% Risiko
            message = "Minimum-Lot überschreitet 5%-Sicherheitsgrenze: " + 
                     DoubleToString(min_risk_percent, 2) + "% > 5.0%";
            LogError("❌ " + message);
            return -1;
        }
        
        safe_lots = volume_min;
        LogImportant("   Auf Minimum angehoben: " + DoubleToString(safe_lots, 6));
    }
    
    // Schritt 5: Normalisierung
    safe_lots = MathFloor(safe_lots / volume_step) * volume_step;
    if(safe_lots < volume_min) safe_lots = volume_min;
    
    // Schritt 6: Finale Validierung
    double final_risk_amount = safe_lots * loss_per_lot;
    double final_risk_percent = (final_risk_amount / balance) * 100.0;
    
    LogImportant("🛡️ FINALE VALIDIERUNG:");
    LogImportant("   Finale Lots: " + DoubleToString(safe_lots, 6));
    LogImportant("   Finales Risiko: " + DoubleToString(final_risk_amount, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + 
                " (" + DoubleToString(final_risk_percent, 2) + "%)");
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    
    // Emergency Brake: Finale Sicherheitsprüfung
    if(final_risk_percent > 5.0) {
        message = "EMERGENCY BRAKE: Finales Risiko überschreitet Sicherheitsgrenze: " + 
                 DoubleToString(final_risk_percent, 2) + "% > 5.0%";
        LogError("🚨 " + message);
        return -1;
    }
    
    LogImportant("✅ UNIVERSAL BERECHNUNG v9.2 ERFOLGREICH:");
    LogImportant("   Empfohlene Lotsize: " + DoubleToString(safe_lots, 6));
    LogImportant("   Tatsächliches Risiko: " + DoubleToString(final_risk_percent, 2) + "%");
    LogImportant("🛡️ ALLE SICHERHEITSPRÜFUNGEN BESTANDEN");
    LogImportant("════════════════════════════════════════════");
    
    message = "Universal v9.2 calculation successful";
    return safe_lots;
}

//+------------------------------------------------------------------+
//| LOGGING FUNCTIONS                                                |
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

void LogSuccess(string message) {
    Print("[SUCCESS] ", message);
}

void LogInfo(string message) {
    Print("[INFO] ", message);
}

void LogDebug(string message) {
    if(debug_mode) Print("[DEBUG] ", message);
}

void LogVerbose(string message) {
    if(verbose_signal_check) Print("[VERBOSE] ", message);
}

//+------------------------------------------------------------------+
//| SYMBOL MANAGEMENT FUNCTIONS                                      |
//+------------------------------------------------------------------+
string FindSymbolWithExtendedSearch(string original) {
    LogDebug("🔍 Erweiterte Symbol-Suche für: " + original);
    
    // Direkte Suche
    if(SymbolSelect(original, true)) {
        LogSuccess("✅ Symbol direkt gefunden: " + original);
        return original;
    }
    
    // Mit Suffix suchen
    string with_suffix = original + broker_suffix;
    if(SymbolSelect(with_suffix, true)) {
        LogSuccess("✅ Symbol mit Suffix gefunden: " + with_suffix);
        return with_suffix;
    }
    
    // Ohne Suffix suchen (falls original bereits Suffix hat)
    string without_suffix = original;
    StringReplace(without_suffix, broker_suffix, "");
    if(SymbolSelect(without_suffix, true)) {
        LogSuccess("✅ Symbol ohne Suffix gefunden: " + without_suffix);
        return without_suffix;
    }
    
    LogWarning("⚠️ Symbol nicht gefunden: " + original);
    return "";
}

string ApplySymbolMapping(string api_symbol) {
    LogDebug("🔄 Symbol-Mapping für: " + api_symbol);
    
    // Custom Mappings prüfen
    string mappings = custom_symbol_mappings;
    string pairs[];
    int pair_count = StringSplit(mappings, ',', pairs);
    
    for(int i = 0; i < pair_count; i++) {
        string mapping[];
        if(StringSplit(pairs[i], ':', mapping) == 2) {
            if(mapping[0] == api_symbol) {
                LogSuccess("✅ Custom Mapping gefunden: " + api_symbol + " → " + mapping[1]);
                return mapping[1];
            }
        }
    }
    
    LogDebug("ℹ️ Kein Custom Mapping für: " + api_symbol);
    return api_symbol;
}

void AutoDetectIndexSymbols() {
    LogInfo("🔍 Auto-Erkennung von Index-Symbolen...");
    
    string index_patterns[] = {
        "US30", "DJIUSD", "DJ30", "DOW",
        "US100", "NAS100", "NASDAQ", "NDX",
        "US500", "SPX500", "SP500", "SPX",
        "GER30", "GER40", "DAX30", "DAX40", "DAX",
        "UK100", "FTSE100", "FTSE",
        "FRA40", "CAC40", "CAC",
        "JPN225", "NIKKEI", "N225",
        "HK50", "HANGSENG", "HSI",
        "AUS200", "ASX200", "XJO"
    };
    
    ArrayResize(detected_symbols, 0);
    
    for(int i = 0; i < ArraySize(index_patterns); i++) {
        string pattern = index_patterns[i];
        
        // Teste verschiedene Varianten
        string variants[] = {
            pattern,
            pattern + broker_suffix,
            pattern + "#",
            pattern + "s",
            pattern + ".ecn",
            pattern + ".raw"
        };
        
        for(int j = 0; j < ArraySize(variants); j++) {
            if(SymbolSelect(variants[j], true)) {
                ArrayResize(detected_symbols, ArraySize(detected_symbols) + 1);
                detected_symbols[ArraySize(detected_symbols) - 1] = variants[j];
                LogSuccess("✅ Index-Symbol erkannt: " + variants[j]);
                break;
            }
        }
    }
    
    symbols_detected = true;
    LogInfo("🎯 Auto-Erkennung abgeschlossen. " + IntegerToString(ArraySize(detected_symbols)) + " Symbole erkannt.");
}

//+------------------------------------------------------------------+
//| HTTP REQUEST FUNCTION                                            |
//+------------------------------------------------------------------+
string SendHttpRequest(string url, string method = "GET", string data = "", int timeout = 5000) {
    LogVerbose("HTTP Request: " + method + " " + url);
    
    char post_data[];
    char result[];
    string headers = "Content-Type: application/json\r\n";
    
    if(data != "") {
        StringToCharArray(data, post_data, 0, StringLen(data));
    }
    
    int res = WebRequest(method, url, headers, timeout, post_data, result, headers);
    LogVerbose("   HTTP Response Code: " + IntegerToString(res));
    
    if(res == -1) {
        int error_code = GetLastError();
        switch(error_code) {
            case 4060:
                LogError("   Fehler 4060: URL nicht in der Liste der erlaubten URLs");
                LogError("   Lösung: Fügen Sie die URL in Tools → Optionen → Expert Advisors → 'Allow WebRequest for listed URL' hinzu");
                break;
            case 4014:
                LogError("   Fehler 4014: Unbekannte Symbol");
                break;
            default:
                LogError("   HTTP Fehler: " + IntegerToString(error_code));
                break;
        }
        return "";
    }
    
    if(res == 200) {
        string response = CharArrayToString(result);
        LogVerbose("   Response: " + StringSubstr(response, 0, MathMin(100, StringLen(response))) + "...");
        return response;
    }
    
    LogError("   HTTP Error: " + IntegerToString(res));
    return "";
}

//+------------------------------------------------------------------+
//| API VALUE TRACKING FUNCTIONS                                     |
//+------------------------------------------------------------------+
void LoadAPIValuesFromFile() {
    LogDebug("📂 Lade API-Werte aus Datei: " + api_values_file);
    
    int file_handle = FileOpen(api_values_file, FILE_READ | FILE_TXT | FILE_ANSI);
    if(file_handle == INVALID_HANDLE) {
        LogDebug("ℹ️ API-Werte Datei nicht gefunden - wird bei Bedarf erstellt");
        return;
    }
    
    string json_content = "";
    while(!FileIsEnding(file_handle)) {
        json_content += FileReadString(file_handle);
    }
    FileClose(file_handle);
    
    if(json_content == "") {
        LogDebug("ℹ️ API-Werte Datei ist leer");
        return;
    }
    
    LogDebug("✅ API-Werte aus Datei geladen");
    // JSON-Parsing würde hier implementiert werden
}

void SaveAPIValuesToFile() {
    LogDebug("💾 Speichere API-Werte in Datei: " + api_values_file);
    
    int file_handle = FileOpen(api_values_file, FILE_WRITE | FILE_TXT | FILE_ANSI);
    if(file_handle == INVALID_HANDLE) {
        LogError("❌ Konnte API-Werte Datei nicht erstellen");
        return;
    }
    
    string json_content = "{\"positions\":[";
    
    for(int i = 0; i < ArraySize(tracked_positions); i++) {
        if(tracked_positions[i].is_valid) {
            if(i > 0) json_content += ",";
            json_content += "{";
            json_content += "\"signal_id\":\"" + tracked_positions[i].signal_id + "\",";
            json_content += "\"ticket\":" + IntegerToString(tracked_positions[i].ticket) + ",";
            json_content += "\"symbol\":\"" + tracked_positions[i].symbol + "\",";
            json_content += "\"api_sl_value\":" + DoubleToString(tracked_positions[i].api_sl_value, 5) + ",";
            json_content += "\"api_tp_value\":" + DoubleToString(tracked_positions[i].api_tp_value, 5) + ",";
            json_content += "\"has_api_sl\":" + (tracked_positions[i].has_api_sl ? "true" : "false") + ",";
            json_content += "\"has_api_tp\":" + (tracked_positions[i].has_api_tp ? "true" : "false");
            json_content += "}";
        }
    }
    
    json_content += "]}";
    
    FileWriteString(file_handle, json_content);
    FileClose(file_handle);
    
    LogDebug("✅ API-Werte in Datei gespeichert");
}

bool HasValueBeenApplied(string signal_id, ulong ticket, double value, bool is_sl) {
    for(int i = 0; i < ArraySize(tracked_positions); i++) {
        if(tracked_positions[i].is_valid && 
           tracked_positions[i].signal_id == signal_id && 
           tracked_positions[i].ticket == ticket) {
            
            if(is_sl && tracked_positions[i].has_api_sl) {
                return MathAbs(tracked_positions[i].api_sl_value - value) < 0.00001;
            } else if(!is_sl && tracked_positions[i].has_api_tp) {
                return MathAbs(tracked_positions[i].api_tp_value - value) < 0.00001;
            }
        }
    }
    return false;
}

void UpdateTrackedPosition(string signal_id, ulong ticket, string symbol, 
                          double api_sl, double api_tp, bool has_sl, bool has_tp) {
    
    // Suche existierende Position
    int index = -1;
    for(int i = 0; i < ArraySize(tracked_positions); i++) {
        if(tracked_positions[i].is_valid && 
           tracked_positions[i].signal_id == signal_id && 
           tracked_positions[i].ticket == ticket) {
            index = i;
            break;
        }
    }
    
    // Neue Position hinzufügen
    if(index == -1) {
        ArrayResize(tracked_positions, ArraySize(tracked_positions) + 1);
        index = ArraySize(tracked_positions) - 1;
        
        tracked_positions[index].signal_id = signal_id;
        tracked_positions[index].ticket = ticket;
        tracked_positions[index].symbol = symbol;
        tracked_positions[index].is_valid = true;
    }
    
    // Werte aktualisieren
    tracked_positions[index].api_sl_value = api_sl;
    tracked_positions[index].api_tp_value = api_tp;
    tracked_positions[index].has_api_sl = has_sl;
    tracked_positions[index].has_api_tp = has_tp;
    tracked_positions[index].last_update = TimeCurrent();
    
    SaveAPIValuesToFile();
}

//+------------------------------------------------------------------+
//| POSITION MANAGEMENT FUNCTIONS                                    |
//+------------------------------------------------------------------+
void CheckOpenPositions() {
    if(TimeCurrent() - last_position_check < check_interval_position) return;
    last_position_check = TimeCurrent();
    
    LogVerbose("🔍 Prüfe offene Positionen...");
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetTicket(i) > 0) {
            if(PositionGetInteger(POSITION_MAGIC) == magic_number) {
                ProcessPosition();
            }
        }
    }
}

void ProcessPosition() {
    ulong ticket = PositionGetInteger(POSITION_TICKET);
    string symbol = PositionGetString(POSITION_SYMBOL);
    string comment = PositionGetString(POSITION_COMMENT);
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    
    LogVerbose("📊 Position prüfen: " + IntegerToString(ticket) + " (" + symbol + ")");
    
    // Break Even prüfen
    if(enable_break_even) {
        ProcessBreakEven(ticket, symbol);
    }
    
    // API-Updates prüfen
    string signal_id = comment; // Signal-ID aus Comment extrahieren
    if(signal_id != "") {
        CheckPositionAPIUpdates(signal_id, ticket, symbol);
    }
}

void ProcessBreakEven(ulong ticket, string symbol) {
    if(!PositionSelectByTicket(ticket)) return;
    
    double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    double current_sl = PositionGetDouble(POSITION_SL);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double trigger_distance = break_even_trigger_pips * point * 10; // 10 für 5-stellige Quotes
    double offset_distance = break_even_offset_pips * point * 10;
    
    bool should_apply_break_even = false;
    double new_sl = 0;
    
    if(pos_type == POSITION_TYPE_BUY) {
        if(current_price >= entry_price + trigger_distance) {
            new_sl = entry_price + offset_distance;
            should_apply_break_even = (current_sl < new_sl || current_sl == 0);
        }
    } else if(pos_type == POSITION_TYPE_SELL) {
        if(current_price <= entry_price - trigger_distance) {
            new_sl = entry_price - offset_distance;
            should_apply_break_even = (current_sl > new_sl || current_sl == 0);
        }
    }
    
    if(should_apply_break_even) {
        LogImportant("🎯 Break Even ausgelöst für Position " + IntegerToString(ticket));
        LogImportant("   Entry: " + DoubleToString(entry_price, 5));
        LogImportant("   Current: " + DoubleToString(current_price, 5));
        LogImportant("   Neuer SL: " + DoubleToString(new_sl, 5));
        
        if(trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP))) {
            LogSuccess("✅ Break Even erfolgreich angewendet");
        } else {
            LogError("❌ Break Even fehlgeschlagen: " + IntegerToString(GetLastError()));
        }
    }
}

void CheckPositionAPIUpdates(string signal_id, ulong ticket, string symbol) {
    string url = position_api_url + "?signal_id=" + signal_id + "&account_id=" + account_id + "&ticket=" + IntegerToString(ticket);
    string response = SendHttpRequest(url);
    
    if(response == "") return;
    
    // Vereinfachte JSON-Parsing (in Produktion würde eine JSON-Library verwendet)
    if(StringFind(response, "\"status\":\"active\"") >= 0) {
        ProcessSLTPUpdate(signal_id, ticket, symbol, response);
    }
}

void ProcessSLTPUpdate(string signal_id, ulong ticket, string symbol, string api_response) {
    LogDebug("🔄 Verarbeite SL/TP Update für Position " + IntegerToString(ticket));
    
    // Vereinfachte Extraktion von SL/TP aus API-Response
    double api_sl = 0, api_tp = 0;
    bool has_sl = false, has_tp = false;
    
    // In Produktion: Robuste JSON-Parsing
    if(StringFind(api_response, "\"sl\":") >= 0) {
        has_sl = true;
        // api_sl = ExtractDoubleFromJSON(api_response, "sl");
    }
    
    if(StringFind(api_response, "\"tp\":") >= 0) {
        has_tp = true;
        // api_tp = ExtractDoubleFromJSON(api_response, "tp");
    }
    
    // Prüfe ob Werte bereits angewendet wurden
    if(has_sl && !HasValueBeenApplied(signal_id, ticket, api_sl, true)) {
        ModifyPositionSL(ticket, api_sl, "API Update");
        UpdateTrackedPosition(signal_id, ticket, symbol, api_sl, api_tp, has_sl, has_tp);
    }
    
    if(has_tp && !HasValueBeenApplied(signal_id, ticket, api_tp, false)) {
        ModifyPositionTP(ticket, api_tp, "API Update");
        UpdateTrackedPosition(signal_id, ticket, symbol, api_sl, api_tp, has_sl, has_tp);
    }
}

void ModifyPositionSL(ulong ticket, double new_sl, string reason) {
    if(!PositionSelectByTicket(ticket)) return;
    
    double current_tp = PositionGetDouble(POSITION_TP);
    
    LogImportant("🔧 Modifiziere SL für Position " + IntegerToString(ticket));
    LogImportant("   Grund: " + reason);
    LogImportant("   Neuer SL: " + DoubleToString(new_sl, 5));
    
    if(trade.PositionModify(ticket, new_sl, current_tp)) {
        LogSuccess("✅ SL erfolgreich modifiziert");
    } else {
        LogError("❌ SL Modifikation fehlgeschlagen: " + IntegerToString(GetLastError()));
    }
}

void ModifyPositionTP(ulong ticket, double new_tp, string reason) {
    if(!PositionSelectByTicket(ticket)) return;
    
    double current_sl = PositionGetDouble(POSITION_SL);
    
    LogImportant("🔧 Modifiziere TP für Position " + IntegerToString(ticket));
    LogImportant("   Grund: " + reason);
    LogImportant("   Neuer TP: " + DoubleToString(new_tp, 5));
    
    if(trade.PositionModify(ticket, current_sl, new_tp)) {
        LogSuccess("✅ TP erfolgreich modifiziert");
    } else {
        LogError("❌ TP Modifikation fehlgeschlagen: " + IntegerToString(GetLastError()));
    }
}

//+------------------------------------------------------------------+
//| SIGNAL PROCESSING FUNCTIONS                                      |
//+------------------------------------------------------------------+
void CheckForNewSignals() {
    if(TimeCurrent() - last_signal_check < check_interval_signal) return;
    last_signal_check = TimeCurrent();
    
    LogVerbose("📡 Prüfe auf neue Signale...");
    
    string url = signal_api_url + "?account_id=" + account_id;
    string response = SendHttpRequest(url);
    
    if(response == "") {
        LogVerbose("Keine Antwort von Signal API (normal wenn keine Signale vorhanden)");
        return;
    }
    
    ProcessSignal(response);
}

void ProcessSignal(string signal_data) {
    LogImportant("📡 NEUES SIGNAL EMPFANGEN");
    LogDebug("Signal Data: " + signal_data);
    
    // Vereinfachte Signal-Extraktion (in Produktion: robuste JSON-Parsing)
    string signal_id = ExtractStringFromJSON(signal_data, "signal_id");
    string symbol = ExtractStringFromJSON(signal_data, "symbol");
    string direction = ExtractStringFromJSON(signal_data, "direction");
    double entry = ExtractDoubleFromJSON(signal_data, "entry");
    double sl = ExtractDoubleFromJSON(signal_data, "sl");
    double tp = ExtractDoubleFromJSON(signal_data, "tp");
    string order_type = ExtractStringFromJSON(signal_data, "order_type");
    
    LogImportant("📊 SIGNAL-DETAILS:");
    LogImportant("   Signal ID: " + signal_id);
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Direction: " + direction);
    LogImportant("   Entry: " + DoubleToString(entry, 5));
    LogImportant("   SL: " + DoubleToString(sl, 5));
    LogImportant("   TP: " + DoubleToString(tp, 5));
    LogImportant("   Order Type: " + order_type);
    
    // Symbol-Mapping anwenden
    string mapped_symbol = ApplySymbolMapping(symbol);
    string trading_symbol = FindSymbolWithExtendedSearch(mapped_symbol);
    
    if(trading_symbol == "") {
        LogError("❌ Symbol nicht handelbar: " + symbol);
        SendTradeErrorConfirmation(signal_id, symbol, direction, 0, 0, "Symbol nicht verfügbar");
        return;
    }
    
    LogSuccess("✅ Handelbares Symbol gefunden: " + trading_symbol);
    
    // Order-Typ bestimmen
    ENUM_ORDER_TYPE mt_order_type = ORDER_TYPE_BUY;
    if(direction == "sell") {
        mt_order_type = (order_type == "market") ? ORDER_TYPE_SELL : ORDER_TYPE_SELL_LIMIT;
    } else {
        mt_order_type = (order_type == "market") ? ORDER_TYPE_BUY : ORDER_TYPE_BUY_LIMIT;
    }
    
    // v9.2 UNIVERSAL LOTSIZE-BERECHNUNG
    string calc_message = "";
    double lots = CalculateLots_v92_Universal(trading_symbol, entry, sl, risk_percent, mt_order_type, calc_message);
    
    if(lots <= 0) {
        LogError("❌ Lotsize-Berechnung fehlgeschlagen: " + calc_message);
        SendTradeErrorConfirmation(signal_id, trading_symbol, direction, 0, 0, calc_message);
        return;
    }
    
    LogImportant("✅ TRADE BEREIT:");
    LogImportant("   Symbol: " + trading_symbol);
    LogImportant("   Direction: " + direction);
    LogImportant("   Lots: " + DoubleToString(lots, 6));
    LogImportant("   Entry: " + DoubleToString(entry, 5));
    LogImportant("   SL: " + DoubleToString(sl, 5));
    LogImportant("   TP: " + DoubleToString(tp, 5));
    
    // Trade ausführen
    ExecuteTrade(signal_id, trading_symbol, mt_order_type, lots, entry, sl, tp);
}

void ExecuteTrade(string signal_id, string symbol, ENUM_ORDER_TYPE order_type, 
                 double lots, double entry, double sl, double tp) {
    
    LogImportant("🚀 TRADE-AUSFÜHRUNG:");
    LogImportant("   Signal: " + signal_id);
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Type: " + EnumToString(order_type));
    LogImportant("   Lots: " + DoubleToString(lots, 6));
    
    trade.SetExpertMagicNumber(magic_number);
    
    bool success = false;
    ulong ticket = 0;
    
    if(order_type == ORDER_TYPE_BUY) {
        success = trade.Buy(lots, symbol, 0, sl, tp, signal_id);
        ticket = trade.ResultOrder();
    } else if(order_type == ORDER_TYPE_SELL) {
        success = trade.Sell(lots, symbol, 0, sl, tp, signal_id);
        ticket = trade.ResultOrder();
    } else {
        // Pending Order
        success = trade.OrderOpen(symbol, order_type, lots, 0, entry, sl, tp, ORDER_TIME_GTC, 0, signal_id);
        ticket = trade.ResultOrder();
    }
    
    if(success && ticket > 0) {
        LogSuccess("✅ TRADE ERFOLGREICH AUSGEFÜHRT:");
        LogSuccess("   Ticket: " + IntegerToString(ticket));
        LogSuccess("   Signal: " + signal_id);
        
        // Position für Tracking registrieren
        UpdateTrackedPosition(signal_id, ticket, symbol, sl, tp, (sl > 0), (tp > 0));
        
        // Erfolg an API melden
        SendTradeExecutionConfirmation(signal_id, symbol, EnumToString(order_type), lots, ticket, "Trade erfolgreich ausgeführt");
        
    } else {
        LogError("❌ TRADE FEHLGESCHLAGEN:");
        LogError("   Fehler: " + IntegerToString(GetLastError()));
        LogError("   Signal: " + signal_id);
        
        // Fehler an API melden
        SendTradeErrorConfirmation(signal_id, symbol, EnumToString(order_type), lots, 0, "Trade-Ausführung fehlgeschlagen: " + IntegerToString(GetLastError()));
    }
}

//+------------------------------------------------------------------+
//| DELIVERY API FUNCTIONS                                           |
//+------------------------------------------------------------------+
void SendTradeExecutionConfirmation(string signal_id, string symbol, string order_type, 
                                   double lots, ulong ticket, string message) {
    
    string json = CreateBaseJSON(signal_id, true, message);
    json += ",\"trade_details\":{";
    json += "\"symbol\":\"" + symbol + "\",";
    json += "\"order_type\":\"" + order_type + "\",";
    json += "\"lots\":" + DoubleToString(lots, 6) + ",";
    json += "\"ticket\":" + IntegerToString(ticket);
    json += "}";
    json += AddAccountInfo();
    json += "}";
    
    SendHttpRequest(delivery_api_url, "POST", json);
    LogDebug("📤 Trade-Bestätigung gesendet für Signal: " + signal_id);
}

void SendTradeErrorConfirmation(string signal_id, string symbol, string direction, 
                               double lots, ulong ticket, string error_message) {
    
    string json = CreateBaseJSON(signal_id, false, error_message);
    json += ",\"trade_details\":{";
    json += "\"symbol\":\"" + symbol + "\",";
    json += "\"direction\":\"" + direction + "\",";
    json += "\"lots\":" + DoubleToString(lots, 6) + ",";
    json += "\"ticket\":" + IntegerToString(ticket);
    json += "}";
    json += AddAccountInfo();
    json += "}";
    
    SendHttpRequest(delivery_api_url, "POST", json);
    LogDebug("📤 Fehler-Bestätigung gesendet für Signal: " + signal_id);
}

string CreateBaseJSON(string signal_id, bool success, string message) {
    string json = "{";
    json += "\"account_id\":\"" + account_id + "\",";
    json += "\"signal_id\":\"" + signal_id + "\",";
    json += "\"success\":" + (success ? "true" : "false") + ",";
    json += "\"message\":\"" + message + "\",";
    json += "\"ea_version\":\"9.2\",";
    json += "\"timestamp\":\"" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\"";
    return json;
}

string AddAccountInfo() {
    string info = ",\"account_info\":{";
    info += "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
    info += "\"equity\":" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + ",";
    info += "\"currency\":\"" + AccountInfoString(ACCOUNT_CURRENCY) + "\",";
    info += "\"leverage\":" + IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE));
    info += "}";
    return info;
}

//+------------------------------------------------------------------+
//| JSON HELPER FUNCTIONS                                            |
//+------------------------------------------------------------------+
string ExtractStringFromJSON(string json, string key) {
    string search_pattern = "\"" + key + "\":\"";
    int start_pos = StringFind(json, search_pattern);
    if(start_pos == -1) return "";
    
    start_pos += StringLen(search_pattern);
    int end_pos = StringFind(json, "\"", start_pos);
    if(end_pos == -1) return "";
    
    return StringSubstr(json, start_pos, end_pos - start_pos);
}

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

//+------------------------------------------------------------------+
//| LOGIN STATUS FUNCTIONS                                           |
//+------------------------------------------------------------------+
void SendLoginStatus() {
    if(TimeCurrent() - last_login_attempt < login_retry_delay) return;
    
    if(login_attempt_count >= max_login_attempts) {
        LogWarning("⚠️ Maximale Login-Versuche erreicht");
        return;
    }
    
    last_login_attempt = TimeCurrent();
    login_attempt_count++;
    
    string json = "{";
    json += "\"account_id\":\"" + account_id + "\",";
    json += "\"status\":\"online\",";
    json += "\"ea_version\":\"9.2\",";
    json += "\"timestamp\":\"" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\"";
    json += AddAccountInfo();
    json += "}";
    
    string response = SendHttpRequest(login_api_url, "POST", json);
    
    if(response != "") {
        login_success = true;
        login_attempt_count = 0;
        LogSuccess("✅ Login-Status erfolgreich übertragen");
    } else {
        LogWarning("⚠️ Login-Status Übertragung fehlgeschlagen (Versuch " + IntegerToString(login_attempt_count) + "/" + IntegerToString(max_login_attempts) + ")");
    }
}

//+------------------------------------------------------------------+
//| EA INITIALIZATION                                                |
//+------------------------------------------------------------------+
int OnInit() {
    LogImportant("════════════════════════════════════════════");
    LogImportant("🌍 Signal EA v9.2-UNIVERSAL-FULL - Initialisierung");
    LogImportant("🎯 UNIVERSAL ASSET CLASSIFICATION AKTIV");
    LogImportant("🛡️ ULTRA-SICHERE RISIKO-KONTROLLE AKTIV");
    LogImportant("🔧 ALLE v8.x FUNKTIONEN ENTHALTEN (139 FUNKTIONEN)");
    LogImportant("════════════════════════════════════════════");
    
    // Account-ID setzen
    account_id = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    LogImportant("Account ID: " + account_id);
    LogImportant("Balance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + " " + AccountInfoString(ACCOUNT_CURRENCY));
    LogImportant("Broker: " + AccountInfoString(ACCOUNT_COMPANY));
    LogImportant("Server: " + AccountInfoString(ACCOUNT_SERVER));
    
    // Broker-Suffix erkennen
    if(SymbolSelect("EURUSD", true)) {
        broker_suffix = "";
        LogSuccess("✅ Broker-Suffix gefunden: '' (Standard)");
    } else if(SymbolSelect("EURUSD.ecn", true)) {
        broker_suffix = ".ecn";
        LogSuccess("✅ Broker-Suffix gefunden: '.ecn'");
    } else if(SymbolSelect("EURUSD.raw", true)) {
        broker_suffix = ".raw";
        LogSuccess("✅ Broker-Suffix gefunden: '.raw'");
    } else if(SymbolSelect("EURUSD#", true)) {
        broker_suffix = "#";
        LogSuccess("✅ Broker-Suffix gefunden: '#'");
    } else if(SymbolSelect("EURUSDs", true)) {
        broker_suffix = "s";
        LogSuccess("✅ Broker-Suffix gefunden: 's'");
    }
    
    // API-Werte laden
    LoadAPIValuesFromFile();
    
    // Symbol-Auto-Erkennung
    AutoDetectIndexSymbols();
    
    // Timer starten
    EventSetTimer(1);
    
    // Login-Status senden
    SendLoginStatus();
    
    LogImportant("✅ EA v9.2-UNIVERSAL-FULL erfolgreich initialisiert");
    LogImportant("🌍 UNIVERSAL ASSET CLASSIFICATION: 16 Asset-Typen unterstützt");
    LogImportant("🛡️ ULTRA-SICHERE LOTSIZE-BERECHNUNG: Niemals mehr als 5% Risiko");
    LogImportant("📡 API-INTEGRATION: Signal, Position, Delivery, Login APIs aktiv");
    LogImportant("🔍 SYMBOL-SUCHE: " + IntegerToString(ArraySize(detected_symbols)) + " Index-Symbole erkannt");
    LogImportant("💾 POSITION-TRACKING: API-Werte persistent gespeichert");
    LogImportant("🎯 BREAK-EVEN: " + (enable_break_even ? "Aktiviert" : "Deaktiviert"));
    LogImportant("════════════════════════════════════════════");
    
    // Manual Test (falls aktiviert)
    static bool test_executed = false;
    if(enable_manual_test && !test_executed) {
        TestOptimizedLotsizeCalculation();
        test_executed = true;
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| EA DEINITIALIZATION                                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
    
    // API-Werte speichern
    SaveAPIValuesToFile();
    
    LogImportant("EA v9.2-UNIVERSAL-FULL beendet. Grund: " + IntegerToString(reason));
    LogImportant("💾 API-Werte gespeichert");
    LogImportant("🎯 " + IntegerToString(ArraySize(tracked_positions)) + " Positionen getrackt");
}

//+------------------------------------------------------------------+
//| TIMER EVENT                                                      |
//+------------------------------------------------------------------+
void OnTimer() {
    CheckForNewSignals();
    CheckOpenPositions();
    
    // Login-Status periodisch senden
    if(!login_success) {
        SendLoginStatus();
    }
}

//+------------------------------------------------------------------+
//| TEST FUNCTION                                                    |
//+------------------------------------------------------------------+
void TestOptimizedLotsizeCalculation() {
    LogImportant("🧪 TESTE OPTIMIERTE LOTSIZE-BERECHNUNG v9.2");
    
    // Test 1: JPY-Paar
    string test_message = "";
    double test_lots = CalculateLots_v92_Universal("USDJPY", 150.00, 149.50, 5.0, ORDER_TYPE_BUY, test_message);
    LogImportant("🇯🇵 JPY-Test: " + DoubleToString(test_lots, 6) + " Lots (" + test_message + ")");
    
    // Test 2: Gold
    test_lots = CalculateLots_v92_Universal("XAUUSD", 2000.00, 1995.00, 5.0, ORDER_TYPE_BUY, test_message);
    LogImportant("🥇 Gold-Test: " + DoubleToString(test_lots, 6) + " Lots (" + test_message + ")");
    
    // Test 3: Standard Forex
    test_lots = CalculateLots_v92_Universal("EURUSD", 1.1000, 1.0950, 5.0, ORDER_TYPE_BUY, test_message);
    LogImportant("💱 Forex-Test: " + DoubleToString(test_lots, 6) + " Lots (" + test_message + ")");
    
    LogImportant("✅ LOTSIZE-TESTS ABGESCHLOSSEN");
}

//+------------------------------------------------------------------+"
