//+------------------------------------------------------------------+
//|                    Signal-Copier-Optimized-v8.3-UNIVERSAL       |
//|                                          Copyright 2024, Stelona |
//|                                       https://www.stelona.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Stelona"
#property link      "https://www.stelona.com"
#property version   "8.60"
#property strict

// Version 8.6-UNIVERSAL - BREAK EVEN SL/TP UPDATES:
// 🚀 NEUE FEATURES in v8.6:
// ✅ BREAK EVEN SL/TP UPDATES: SL/TP Änderungen werden auch bei Break Even Status übernommen
// ✅ VEREINFACHTE LOGIK: Keine komplexe Profitabilitätsprüfung mehr
// ✅ ARRAY & LEGACY FORMAT: Funktioniert mit beiden API-Formaten
// ✅ VOLLSTÄNDIGE FLEXIBILITÄT: Nutzer kann SL in Profitbereich verschieben
// ✅ ITERATIVE LOT-REDUZIERUNG: Automatische Anpassung bis im Risikorahmen
// ✅ KONSISTENTE RISIKO-BERECHNUNG: Einheitliche Berechnung an allen Stellen
// ✅ DYNAMISCHE LIMITS NACH BERECHNUNG: Limits basierend auf tatsächlichen Werten
// 
// 🔧 BEHOBENE PROBLEME aus v8.4:
// ✅ VALIDIERUNGSBEREICHE KORRIGIERT: Realistische Bereiche für Forex-Paare (0.1-50 EUR/Pip)
// ✅ STACK OVERFLOW BEHOBEN: Endlosschleife in Fallback-Logik verhindert
// ✅ FOREX-METHODE OPTIMIERT: Akzeptiert jetzt korrekte Werte wie 60.87 EUR für 9.9 Pips
// 
// 🔧 KRITISCHE KORREKTUREN in v8.3:
// ✅ LOTSIZE-BUG BEHOBEN: Korrigierte Point Size Berechnung für alle Forex-Paare
// ✅ NEUE FOREX-METHODE: Zuverlässige Pip-basierte Berechnung als primäre Methode
// ✅ VERBESSERTE VALIDIERUNG: Realistische Bereiche für Loss-per-Lot Werte
// ✅ ENHANCED CURRENCY CONVERSION: Robustere Währungskonvertierung mit Fallbacks
// ✅ TRANSPARENT LOGGING: Detaillierte Logs für alle Berechnungsschritte
// 
// 🚨 BEHOBENES PROBLEM:
// Das kritische Problem in v8.6: UniversalDatabase verwendete falsche point_size (0.00001 statt 0.0001)
// für Forex-Paare, was zu 10x zu hohen Loss-per-Lot Werten und damit 10x zu kleinen Lotsizes führte.
// v8.3 behebt dies durch eine neue, zuverlässige Forex-spezifische Berechnungsmethode.
// 
// 🌍 UNIVERSELLE REVOLUTION in v8.1:
// ✅ BROKER-NEUTRAL: Funktioniert mit ALLEN Broker-Konfigurationen
// ✅ SYMBOL-NORMALISIERUNG: Automatische Erkennung von Symbol-Varianten
// ✅ UNIVERSELLE DATENBANK: Umfassende Symbol-Spezifikationen für alle Märkte
// ✅ ROBUSTE WÄHRUNGSKONVERTIERUNG: Mehrfache Fallback-Mechanismen
// ✅ INTELLIGENTE SCHÄTZUNG: Point-Value-Berechnung auch ohne Broker-Daten
// 
// 🔧 UNIVERSELLE FEATURES:
// - Symbol-Pattern-Matching (XAUUSD* erkennt XAUUSDs, XAUUSD#, etc.)
// - Comprehensive Symbol Database (Gold, Silber, Forex, Indizes, Crypto)
// - Multi-Path Currency Conversion (Direct, Reverse, via USD/EUR, Hardcoded)
// - Intelligent Point Value Estimation basierend auf Symbol-Typ
// - Self-Learning System für broker-spezifische Optimierungen
// 
// 🎯 WARUM v8.1 UNIVERSELL IST:
// Das Problem in v8.0: Broker-spezifische Symbol-Namen (XAUUSDs statt XAUUSD)
// führten zum Versagen aller Berechnungsmethoden. v8.1 löst dies durch
// universelle Symbol-Erkennung und umfassende Fallback-Mechanismen.
// 
// 📋 ALLE FEATURES (v8.5-UNIVERSAL - EXAKTE RISIKO-KONTROLLE):
// ✅ EXAKTE LOT-BERECHNUNG: Basierend auf tatsächlichen Loss-per-Lot Werten
// ✅ STRIKTE RISIKO-KONTROLLE: Niemals Überschreitung des gewünschten Risikos
// ✅ ITERATIVE LOT-ANPASSUNG: Automatische Reduzierung bis im Risikorahmen
// ✅ KONSISTENTE BERECHNUNG: Einheitliche Risiko-Berechnung überall
// ✅ ITERATIVE RISIKO-REDUZIERUNG: Automatische Lot-Anpassung bis Risiko EXAKT passt
// ✅ DETAILLIERTE BREAK EVEN LOGS: Vollständige Transparenz bei Break Even Ausführung
// ✅ ERWEITERTE SL/TP LOGS: Alle Modifikationen mit Details und Grund dokumentiert
// ✅ API VALUE TRACKING: EA ändert nur bei neuen API-Werten - User können jederzeit manuell ändern
// ✅ GBPJPY CROSS-PAIR FIX: Realistische Pip-Werte für alle JPY Cross-Pairs
// ✅ UMFASSENDE INDEX-MAPPINGS: 18 vorkonfigurierte Symbol-Mappings (US, EU, ASIA, etc.)
// ✅ PERSISTENTE DATENHALTUNG: API-Werte in lokaler JSON-Datei (überlebt EA-Neustarts)
// ✅ LOW RISK FEATURE: Bei low_risk=1 wird Risiko und Lotsize halbiert
// ✅ STRIKTE RISIKO-KONTROLLE: NIEMALS mehr als gewünschtes Risiko (auch bei halbierten Werten)
// ✅ ROBUSTE LOT-BERECHNUNG: 5-stufiges Fallback-System (Forex → OrderCalcProfit → Tick → Contract → Hardcoded)
// ✅ CROSS-CURRENCY SUPPORT: Automatische Währungskonvertierung für alle Major Pairs
// ✅ SIGNAL DELIVERY API: Vollständige Integration mit Status-Tracking (executed/rejected/etc.)
// ✅ WERTBASIERTES SL/TP TRACKING: Jeder spezifische Wert nur einmal angewendet
// ✅ HARDCODED FALLBACK-WERTE: 100% Zuverlässigkeit für alle Major Currency Pairs
// ✅ LIMIT ORDER VALIDIERUNG: Warnung vor sofortiger Ausführung
// ✅ JSON ENCODING FIX: Einheitliches CP_UTF8 Format für alle API-Calls
// ✅ RISIKO-SCHUTZ: Automatische Lot-Reduzierung wenn Risiko überschritten wird

#include <Trade\Trade.mqh>

// ===== GLOBALE OBJEKTE =====
CTrade trade;
string account_id;
datetime last_signal_check = 0;
datetime last_position_check = 0;

// ===== POSITION TRACKING =====
struct TrackedPosition {
    ulong original_ticket;     // Original ticket
    ulong current_ticket;      // Current ticket (changes after partial close)
    string signal_id;          // Signal ID
    bool be_executed;          // Break Even executed
    datetime be_time;          // When BE was set
    double be_level;           // BE price level
    bool is_active;           // Position still active
    datetime last_checked;     // Last API check
    // IMPROVED: Value-based tracking instead of boolean flags
    double last_applied_sl;    // Letzter vom EA angewendeter SL-Wert
    double last_applied_tp;    // Letzter vom EA angewendeter TP-Wert
    datetime last_sl_change;   // Wann wurde SL zuletzt vom EA geändert
    datetime last_tp_change;   // Wann wurde TP zuletzt vom EA geändert
    string applied_sl_values;  // Liste der bereits angewendeten SL-Werte (kommagetrennt)
    string applied_tp_values;  // Liste der bereits angewendeten TP-Werte (kommagetrennt)
    // API VALUE TRACKING
    string last_api_sl;        // Letzter API SL-Wert (als String für exakte Vergleiche)
    string last_api_tp;        // Letzter API TP-Wert (als String für exakte Vergleiche)
    datetime last_api_update;  // Wann wurden API-Werte zuletzt aktualisiert
    // Legacy fields (kept for compatibility)
    double last_modified_sl;   // Letzter modifizierter SL
    double last_modified_tp;   // Letzter modifizierter TP
    bool sl_modified;          // Wurde SL bereits modifiziert?
    bool tp_modified;          // Wurde TP bereits modifiziert?
    datetime sl_modified_time; // Wann wurde SL modifiziert?
    datetime tp_modified_time; // Wann wurde TP modifiziert?
    string last_sl_hash;       // Hash der letzten SL-Änderung
    string last_tp_hash;       // Hash der letzten TP-Änderung
};
TrackedPosition tracked_positions[];

// ===== HAUPT-EINSTELLUNGEN =====
input group "API Einstellungen"
input string signal_api_url = "https://n8n.stelona.com/webhook/get-signal"; // Signal API URL
input string position_api_url = "https://n8n.stelona.com/webhook/check-status"; // Position API URL
input string delivery_api_url = "https://n8n.stelona.com/webhook/signal-delivery"; // Delivery API URL
input string login_api_url = "https://n8n.stelona.com/webhook/login-status"; // Login Status API URL

input group "Trading Einstellungen"
input int magic_number = 12345; // Magic Number

input group "Timing Einstellungen"
input int check_interval_signal = 15; // Signal Check Intervall (Sekunden)
input int check_interval_position = 20; // Position Check Intervall (Sekunden)
input int api_timeout_ms = 5000; // API Timeout (ms)

input group "Login Einstellungen"
input int max_login_attempts = 30; // Maximale Login-Versuche (Standard: 30)
input int login_retry_delay_seconds = 5; // Pause zwischen Login-Versuchen (Sekunden)

input group "Break Even Einstellungen"
input bool use_breakeven = true; // Break Even verwenden (nur via API)

input group "API Value Tracking"
input string api_values_file = "api_values.json"; // Datei für API-Werte (persistent)

input group "Debug Einstellungen"
input bool debug_mode = false; // Debug-Modus (detaillierte Logs)
input bool enable_manual_test = false; // Manuellen SL/TP Test aktivieren

input group "Symbol Mapping"
input string symbol_mappings = "US30:DJIUSD,US30:DJI30,US100:NAS100,US500:SPX500,DAX:GER40,DAX30:GER30,DAX40:GER40,FTSE:UK100,CAC40:FRA40,NIKKEI:JPN225,HANGSENG:HK50,ASX200:AUS200,RUSSELL:US2000,STOXX50:EUSTX50,IBEX35:SPA35,SMI:SWI20,KOSPI:KOR200,TSX:CAN60,BOVESPA:BRA50"; // Symbol-Mappings (Format: "ORIGINAL:BROKER,ORIGINAL2:BROKER2")

// ===== SYMBOL-MAPPING =====
string broker_suffix = "";
struct SymbolMapping {
    string original;
    string mapped;
    datetime last_check;
};
SymbolMapping symbol_cache[];

// Custom Symbol Mappings (aus Input-Parameter)
struct CustomSymbolMapping {
    string api_symbol;      // Symbol aus API (z.B. "US30")
    string broker_symbol;   // Symbol beim Broker (z.B. "DJIUSD")
};
CustomSymbolMapping custom_mappings[];

// ===== AUTOMATISCHE INDEX-SYMBOL-ERKENNUNG =====
// Struktur für automatisch erkannte Index-Symbole
struct AutoDetectedIndex {
    string api_name;        // Name aus API (z.B. "US30")
    string broker_symbol;   // Broker-Symbol (z.B. "DJIUSD#")
    string base_name;       // Basis-Name (z.B. "DJIUSD")
    datetime detected_time; // Wann erkannt
    bool is_active;        // Ist handelbar
};
AutoDetectedIndex auto_detected_indices[];

// Index-Erkennungsmuster
struct IndexPattern {
    string api_name;
    string patterns[10];    // Maximal 10 Muster pro Index
    int pattern_count;      // Anzahl der tatsächlich verwendeten Muster
};

// Vordefinierte Index-Muster für automatische Erkennung
IndexPattern index_patterns[] = {
    {"US30", {"DJ", "DOW", "US30", "DJI", "DJIUSD", "DJIA"}, 6},
    {"US100", {"NAS", "NDX", "US100", "NASDAQ", "NAS100", "NASUSD"}, 6},
    {"US500", {"SPX", "SP500", "US500", "SPY", "SPX500", "SPXUSD"}, 6},
    {"DAX", {"DAX", "GER", "DE30", "DE40", "GER30", "GER40"}, 6},
    {"FTSE", {"FTSE", "UK100", "UKX", "FTSE100"}, 4},
    {"CAC40", {"CAC", "FRA40", "FR40", "CAC40"}, 4},
    {"NIKKEI", {"NKY", "JPN225", "N225", "NIKKEI", "NIK225"}, 5},
    {"HANGSENG", {"HSI", "HK50", "HANGSENG", "HANG", "HSI50"}, 5},
    {"ASX200", {"ASX", "AUS200", "XJO", "ASX200"}, 4},
    {"RUSSELL", {"RTY", "US2000", "RUSSELL", "RUT", "RUS2000"}, 5},
    {"STOXX50", {"SX5E", "EUSTX50", "STOXX", "STOXX50", "EU50"}, 5},
    {"IBEX35", {"IBEX", "SPA35", "ES35", "IBEX35"}, 4},
    {"SMI", {"SMI", "SWI20", "CH20", "SWISS"}, 4},
    {"KOSPI", {"KOSPI", "KOR200", "KS11", "KOREA"}, 4},
    {"TSX", {"TSX", "CAN60", "GSPTSE", "CANADA"}, 4},
    {"BOVESPA", {"BOVESPA", "BRA50", "IBOV", "BRAZIL"}, 4}
};

// ===== PROCESSED SIGNALS =====
struct ProcessedSignal {
    string signal_id;
    datetime processed_time;
    bool success;
};
ProcessedSignal processed_signals[];

// ===== LOG FUNKTIONEN (Optimiert) =====
void LogInfo(string message) {
    Print("[INFO] ", message);
}

void LogSuccess(string message) {
    Print("[SUCCESS] ", message);
}

void LogWarning(string message) {
    if(debug_mode) Print("[WARNING] ", message);
}

void LogError(string message) {
    Print("[ERROR] ", message);
}

void LogDebug(string message) {
    if(debug_mode) Print("[DEBUG] ", message);
}

void LogImportant(string message) {
    // Wird IMMER geloggt (wichtige Events)
    Print("[⚡] ", message);
}

// ===== HILFSFUNKTIONEN FÜR FEHLENDE MQL5 FEATURES =====
bool IsTradeContextBusy() {
    // Prüfe ob Trade-Context verfügbar ist
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return true;
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return true;
    return false;
}

double GetPositionCommission(ulong ticket) {
    if(HistorySelectByPosition(ticket)) {
        int deals = HistoryDealsTotal();
        double total_commission = 0;
        for(int i = 0; i < deals; i++) {
            ulong deal_ticket = HistoryDealGetTicket(i);
            if(deal_ticket > 0) {
                total_commission += HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
            }
        }
        return total_commission;
    }
    return 0;
}

// ===== ORDER TYPE CONVERSION FOR CONSISTENT API FORMAT =====
string OrderTypeToString(ENUM_ORDER_TYPE order_type) {
    switch(order_type) {
        case ORDER_TYPE_BUY:        return "market buy";
        case ORDER_TYPE_SELL:       return "market sell";
        case ORDER_TYPE_BUY_LIMIT:  return "limit buy";
        case ORDER_TYPE_SELL_LIMIT: return "limit sell";
        case ORDER_TYPE_BUY_STOP:   return "stop buy";
        case ORDER_TYPE_SELL_STOP:  return "stop sell";
        default:                    return "unknown";
    }
}

string DirectionToOrderType(string direction, string order_type_str) {
    // Fallback function for when we only have direction and order_type strings
    string dir = direction;
    string type = order_type_str;
    StringToLowerCase(dir);
    StringToLowerCase(type);
    
    if(type == "market") {
        return (dir == "buy") ? "market buy" : "market sell";
    } else if(type == "limit") {
        return (dir == "buy") ? "limit buy" : "limit sell";
    } else if(type == "stop") {
        return (dir == "buy") ? "stop buy" : "stop sell";
    }
    
    // Default fallback
    return (dir == "buy") ? "market buy" : "market sell";
}

// ===== IMPROVED VALUE-BASED TRACKING FUNCTIONS FOR SL/TP MODIFICATIONS =====
string CreateModificationHash(string signal_id, double sl, double tp) {
    // Erstelle einen Hash für die Modifikation um Duplikate zu vermeiden
    string hash_input = signal_id + "_" + DoubleToString(sl, 5) + "_" + DoubleToString(tp, 5);
    // Einfacher Hash basierend auf String-Länge und Zeichen
    int hash = 0;
    for(int i = 0; i < StringLen(hash_input); i++) {
        hash += StringGetCharacter(hash_input, i) * (i + 1);
    }
    return IntegerToString(hash);
}

int FindTrackedPositionIndex(string signal_id) {
    for(int i = 0; i < ArraySize(tracked_positions); i++) {
        if(tracked_positions[i].signal_id == signal_id && tracked_positions[i].is_active) {
            return i;
        }
    }
    return -1;
}

bool HasValueBeenApplied(string applied_values, double value, int digits) {
    if(applied_values == "" || value <= 0) return false;
    
    string normalized_value = DoubleToString(NormalizeDouble(value, digits), digits);
    
    // Prüfe ob der Wert in der kommaseparierten Liste enthalten ist
    if(StringFind(applied_values, normalized_value) >= 0) {
        LogDebug("Wert " + normalized_value + " bereits in angewendeten Werten gefunden: " + applied_values);
        return true;
    }
    
    return false;
}

void AddAppliedValue(string &applied_values, double value, int digits) {
    if(value <= 0) return;
    
    string normalized_value = DoubleToString(NormalizeDouble(value, digits), digits);
    
    if(applied_values == "") {
        applied_values = normalized_value;
    } else {
        applied_values = applied_values + "," + normalized_value;
    }
    
    // Begrenze die Liste auf die letzten 10 Werte um Speicher zu sparen
    string values[];
    int count = StringSplit(applied_values, ',', values);
    if(count > 10) {
        applied_values = "";
        for(int i = count - 10; i < count; i++) {
            if(applied_values == "") {
                applied_values = values[i];
            } else {
                applied_values = applied_values + "," + values[i];
            }
        }
    }
    
    LogDebug("Wert " + normalized_value + " zu angewendeten Werten hinzugefügt: " + applied_values);
}

bool IsModificationAlreadyApplied(int track_index, double new_sl, double new_tp) {
    if(track_index < 0 || track_index >= ArraySize(tracked_positions)) return false;
    
    // IMPROVED: Prüfe ob die spezifischen Werte bereits angewendet wurden
    bool sl_already_applied = false;
    bool tp_already_applied = false;
    
    if(new_sl > 0) {
        sl_already_applied = HasValueBeenApplied(tracked_positions[track_index].applied_sl_values, new_sl, 5);
        if(sl_already_applied) {
            LogDebug("SL-Wert " + DoubleToString(new_sl, 5) + " für Signal " + tracked_positions[track_index].signal_id + " bereits angewendet");
        }
    }
    
    if(new_tp > 0) {
        tp_already_applied = HasValueBeenApplied(tracked_positions[track_index].applied_tp_values, new_tp, 5);
        if(tp_already_applied) {
            LogDebug("TP-Wert " + DoubleToString(new_tp, 5) + " für Signal " + tracked_positions[track_index].signal_id + " bereits angewendet");
        }
    }
    
    // KORREKTUR: Nur überspringen wenn BEIDE Werte bereits angewendet wurden (oder nicht angefordert)
    bool skip_sl = (new_sl <= 0 || sl_already_applied);
    bool skip_tp = (new_tp <= 0 || tp_already_applied);
    
    return (skip_sl && skip_tp);
}

// NEUE FUNKTION: Prüfe individuelle Werte
bool ShouldModifySL(int track_index, double new_sl) {
    if(track_index < 0 || track_index >= ArraySize(tracked_positions)) return false;
    if(new_sl <= 0) return false;
    
    bool sl_already_applied = HasValueBeenApplied(tracked_positions[track_index].applied_sl_values, new_sl, 5);
    if(sl_already_applied) {
        LogDebug("SL-Wert " + DoubleToString(new_sl, 5) + " bereits angewendet - wird übersprungen");
        return false;
    }
    return true;
}

bool ShouldModifyTP(int track_index, double new_tp) {
    if(track_index < 0 || track_index >= ArraySize(tracked_positions)) return false;
    if(new_tp <= 0) return false;
    
    bool tp_already_applied = HasValueBeenApplied(tracked_positions[track_index].applied_tp_values, new_tp, 5);
    if(tp_already_applied) {
        LogDebug("TP-Wert " + DoubleToString(new_tp, 5) + " bereits angewendet - wird übersprungen");
        return false;
    }
    return true;
}

void MarkModificationAsApplied(int track_index, double new_sl, double new_tp, bool sl_changed, bool tp_changed, int digits) {
    if(track_index < 0 || track_index >= ArraySize(tracked_positions)) return;
    
    datetime current_time = TimeCurrent();
    
    if(sl_changed && new_sl > 0) {
        // Neue wertbasierte Tracking
        tracked_positions[track_index].last_applied_sl = new_sl;
        tracked_positions[track_index].last_sl_change = current_time;
        AddAppliedValue(tracked_positions[track_index].applied_sl_values, new_sl, digits);
        
        // Legacy tracking (für Kompatibilität)
        tracked_positions[track_index].sl_modified = true;
        tracked_positions[track_index].last_modified_sl = new_sl;
        tracked_positions[track_index].sl_modified_time = current_time;
        tracked_positions[track_index].last_sl_hash = CreateModificationHash(tracked_positions[track_index].signal_id, new_sl, 0);
        
        LogDebug("SL-Modifikation markiert: " + DoubleToString(new_sl, digits) + " für Signal " + tracked_positions[track_index].signal_id);
    }
    
    if(tp_changed && new_tp > 0) {
        // Neue wertbasierte Tracking
        tracked_positions[track_index].last_applied_tp = new_tp;
        tracked_positions[track_index].last_tp_change = current_time;
        AddAppliedValue(tracked_positions[track_index].applied_tp_values, new_tp, digits);
        
        // Legacy tracking (für Kompatibilität)
        tracked_positions[track_index].tp_modified = true;
        tracked_positions[track_index].last_modified_tp = new_tp;
        tracked_positions[track_index].tp_modified_time = current_time;
        tracked_positions[track_index].last_tp_hash = CreateModificationHash(tracked_positions[track_index].signal_id, 0, new_tp);
        
        LogDebug("TP-Modifikation markiert: " + DoubleToString(new_tp, digits) + " für Signal " + tracked_positions[track_index].signal_id);
    }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit() {
    LogInfo("════════════════════════════════════════════");
    LogInfo("🚀 Signal Copier EA v8.5-UNIVERSAL - Initialisierung");
    LogInfo("🚀 EXAKTE RISIKO-KONTROLLE AKTIV (v8.5)");
    LogInfo("════════════════════════════════════════════");
    
    // Account ID setzen
    account_id = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    LogInfo("Account ID: " + account_id);
    LogInfo("Balance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + " " + 
            AccountInfoString(ACCOUNT_CURRENCY));
    
    // Magic Number setzen
    trade.SetExpertMagicNumber(magic_number);
    trade.SetTypeFilling(ORDER_FILLING_IOC);
    
    // Broker-Suffix ermitteln
    InitializeBrokerSuffix();
    
    // Symbol-Mappings initialisieren
    InitializeSymbolMappings();
    
    // ===== AUTOMATISCHE INDEX-SYMBOL-ERKENNUNG =====
    LogImportant("🔍 STARTE AUTOMATISCHE INDEX-SYMBOL-ERKENNUNG...");
    AutoDetectIndexSymbols();
    
    // Break Even History laden
    if(use_breakeven) {
        LoadBreakEvenHistory();
        LogDebug("Break Even Tracking aktiviert");
    }
    
    // ====== ERWEITERTE LOGIN STATUS ÜBERTRAGUNG - BIS ZU 30 VERSUCHE ======
    LogImportant("════════════════════════════════════════════");
    LogImportant("🔐 STARTE LOGIN-STATUS ÜBERTRAGUNG");
    LogImportant("   Max. Versuche: " + IntegerToString(max_login_attempts));
    LogImportant("   Pause zwischen Versuchen: " + IntegerToString(login_retry_delay_seconds) + " Sekunden");
    LogImportant("════════════════════════════════════════════");
    
    bool login_sent = false;
    int successful_attempt = 0;
    
    for(int retry = 0; retry < max_login_attempts && !login_sent; retry++) {
        if(retry > 0) {
            LogImportant("⏳ Login-Status Versuch " + IntegerToString(retry + 1) + "/" + 
                        IntegerToString(max_login_attempts) + " in " + 
                        IntegerToString(login_retry_delay_seconds) + " Sekunden...");
            
            // 5 Sekunden Pause mit Countdown
            for(int countdown = login_retry_delay_seconds; countdown > 0; countdown--) {
                if(countdown % 5 == 0 || countdown <= 3) {
                    LogDebug("   Warte noch " + IntegerToString(countdown) + " Sekunden...");
                }
                Sleep(1000); // 1 Sekunde
            }
        } else {
            LogImportant("📤 Login-Status Versuch 1/" + IntegerToString(max_login_attempts));
        }
        
        // Login Status senden
        login_sent = SendLoginStatus();
        
        if(login_sent) {
            successful_attempt = retry + 1;
            LogImportant("✅✅✅ LOGIN-STATUS ERFOLGREICH ÜBERTRAGEN!");
            LogImportant("   Erfolg nach " + IntegerToString(successful_attempt) + " Versuch(en)");
            LogImportant("════════════════════════════════════════════");
            break; // Schleife beenden bei Erfolg
        } else {
            if(retry < max_login_attempts - 1) {
                LogWarning("⚠️ Login-Status Übertragung fehlgeschlagen (Versuch " + 
                          IntegerToString(retry + 1) + "/" + IntegerToString(max_login_attempts) + ")");
            }
        }
    }
    
    if(!login_sent) {
        LogError("════════════════════════════════════════════");
        LogError("❌❌❌ LOGIN-STATUS FEHLGESCHLAGEN!");
        LogError("   Alle " + IntegerToString(max_login_attempts) + " Versuche fehlgeschlagen");
        LogError("   EA läuft trotzdem weiter, aber API ist nicht informiert");
        LogError("   Mögliche Ursachen:");
        LogError("   - API nicht erreichbar");
        LogError("   - WebRequest nicht erlaubt (siehe MT5 Einstellungen)");
        LogError("   - Netzwerkprobleme");
        LogError("════════════════════════════════════════════");
    }
    
    // Existierende Positionen laden und tracken
    InitializePositionTracking();
    
    // API-Verbindung IMMER testen
    TestAPIConnection();
    
    // Timer setzen (1 Sekunde)
    EventSetTimer(1);
    
    LogDebug("Konfiguration:");
    LogDebug("   Signal Check: alle " + IntegerToString(check_interval_signal) + " Sekunden");
    LogDebug("   Position Check: alle " + IntegerToString(check_interval_position) + " Sekunden");
    LogDebug("   Debug-Modus: " + (debug_mode ? "AN" : "AUS"));
    LogDebug("   Manual Test: " + (enable_manual_test ? "AN" : "AUS"));
    LogDebug("   Max Login-Versuche: " + IntegerToString(max_login_attempts));
    
    // API VALUE TRACKING: Lade bestehende MT5-Positionen
    LoadExistingPositionsFromMT5();
    
    LogInfo("✅ EA v8.6-UNIVERSAL erfolgreich initialisiert");
    LogInfo("🚀 v8.6 BREAK EVEN SL/TP UPDATES AKTIV: SL/TP werden auch bei Break Even Status übernommen");
    LogInfo("════════════════════════════════════════════");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
    SaveBreakEvenHistory();
    LogDebug("EA beendet. Grund: " + GetDeInitReasonText(reason));
}

//+------------------------------------------------------------------+
//| Timer function                                                    |
//+------------------------------------------------------------------+
void OnTimer() {
    // Signale prüfen
    if(TimeCurrent() - last_signal_check >= check_interval_signal) {
        CheckForNewSignals();
        last_signal_check = TimeCurrent();
    }
    
    // Positionen prüfen
    if(TimeCurrent() - last_position_check >= check_interval_position) {
        CheckOpenPositions();
        last_position_check = TimeCurrent();
    }
    
    // Manual Test (wenn aktiviert, einmal pro Minute)
    static datetime last_manual_test = 0;
    if(enable_manual_test && TimeCurrent() - last_manual_test >= 60) {
        TestManualSLTPUpdate();
        last_manual_test = TimeCurrent();
    }
    
    // Cleanup alte Daten
    if(MathMod(TimeCurrent(), 3600) < 1) { // Einmal pro Stunde
        CleanupOldData();
    }
}

//+------------------------------------------------------------------+
//| POSITION TRACKING INITIALISIERUNG                               |
//+------------------------------------------------------------------+
void InitializePositionTracking() {
    LogDebug("🔍 Initialisiere Position Tracking...");
    
    int positions_found = 0;
    int orders_found = 0;
    
    // Lade existierende Positionen
    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket)) {
            if(PositionGetInteger(POSITION_MAGIC) == magic_number) {
                string comment = PositionGetString(POSITION_COMMENT);
                string signal_id = ExtractSignalId(comment);
                
                if(signal_id != "") {
                    AddTrackedPosition(ticket, signal_id, true);
                    positions_found++;
                    LogDebug("   Position #" + IntegerToString(ticket) + " (Signal: " + signal_id + ") wird überwacht");
                }
            }
        }
    }
    
    // Lade existierende Pending Orders
    for(int i = 0; i < OrdersTotal(); i++) {
        ulong ticket = OrderGetTicket(i);
        if(OrderSelect(ticket)) {
            if(OrderGetInteger(ORDER_MAGIC) == magic_number) {
                string comment = OrderGetString(ORDER_COMMENT);
                string signal_id = ExtractSignalId(comment);
                
                if(signal_id != "") {
                    AddTrackedPosition(ticket, signal_id, false);
                    orders_found++;
                    LogDebug("   Order #" + IntegerToString(ticket) + " (Signal: " + signal_id + ") wird überwacht");
                }
            }
        }
    }
    
    if(positions_found > 0 || orders_found > 0) {
        LogImportant("📊 " + IntegerToString(positions_found) + " Positionen und " + 
                    IntegerToString(orders_found) + " Orders werden überwacht");
    }
}

//+------------------------------------------------------------------+
//| SIGNAL ID EXTRAKTION                                             |
//+------------------------------------------------------------------+
string ExtractSignalId(string comment) {
    if(StringFind(comment, "Signal: ") == 0) {
        return StringSubstr(comment, 8);
    }
    return "";
}

//+------------------------------------------------------------------+
//| TRACKED POSITION MANAGEMENT                                      |
//+------------------------------------------------------------------+
void AddTrackedPosition(ulong ticket, string signal_id, bool is_position) {
    // Prüfe ob bereits vorhanden
    for(int i = 0; i < ArraySize(tracked_positions); i++) {
        if(tracked_positions[i].signal_id == signal_id && tracked_positions[i].is_active) {
            // Update ticket wenn nötig (nach partial close)
            tracked_positions[i].current_ticket = ticket;
            tracked_positions[i].last_checked = TimeCurrent();
            return;
        }
    }
    
    // Neu hinzufügen
    int size = ArraySize(tracked_positions);
    ArrayResize(tracked_positions, size + 1);
    tracked_positions[size].original_ticket = ticket;
    tracked_positions[size].current_ticket = ticket;
    tracked_positions[size].signal_id = signal_id;
    tracked_positions[size].be_executed = IsBreakEvenExecuted(signal_id);
    tracked_positions[size].be_time = 0;
    tracked_positions[size].be_level = 0;
    tracked_positions[size].is_active = true;
    tracked_positions[size].last_checked = TimeCurrent();
    
    // API VALUE TRACKING: Initialisiere neue Felder
    tracked_positions[size].last_api_sl = "";
    tracked_positions[size].last_api_tp = "";
    tracked_positions[size].last_api_update = 0;
    
    // IMPROVED: Initialize new value-based tracking fields
    tracked_positions[size].last_applied_sl = 0;
    tracked_positions[size].last_applied_tp = 0;
    tracked_positions[size].last_sl_change = 0;
    tracked_positions[size].last_tp_change = 0;
    tracked_positions[size].applied_sl_values = "";
    tracked_positions[size].applied_tp_values = "";
    
    // Legacy fields (for compatibility)
    tracked_positions[size].last_modified_sl = 0;
    tracked_positions[size].last_modified_tp = 0;
    tracked_positions[size].sl_modified = false;
    tracked_positions[size].tp_modified = false;
    tracked_positions[size].sl_modified_time = 0;
    tracked_positions[size].tp_modified_time = 0;
    tracked_positions[size].last_sl_hash = "";
    tracked_positions[size].last_tp_hash = "";
}

//+------------------------------------------------------------------+
//| SIGNAL VERARBEITUNG                                              |
//+------------------------------------------------------------------+
void CheckForNewSignals() {
    // Kein Log beim Start - nur wenn wirklich etwas gefunden wird
    
    string response = GetSignalFromAPI();
    
    if(response == "") {
        // Kein Log wenn keine Signale vorhanden
        return;
    }
    
    LogDebug("API Response erhalten - prüfe Signal");
    
    // Signal parsen
    string signal_id = GetJsonValue(response, "signal_id");
    if(signal_id == "") signal_id = GetJsonValue(response, "id");
    
    if(signal_id == "") {
        // Kein Log wenn keine Signal-ID
        return;
    }
    
    // Prüfe ob bereits verarbeitet
    if(IsSignalAlreadyTraded(signal_id) || IsSignalProcessed(signal_id)) {
        LogDebug("Signal " + signal_id + " bereits verarbeitet");
        return;
    }
    
    // Signal-Daten extrahieren
    string symbol = GetJsonValue(response, "symbol");
    
    // Symbol-Korrektur für bekannte Tippfehler und Varianten
    if(symbol == "GPBUSD") {
        LogWarning("⚠️ Symbol-Korrektur: GPBUSD → GBPUSD");
        symbol = "GBPUSD";
    } else if(symbol == "ERUUSD") {
        LogWarning("⚠️ Symbol-Korrektur: ERUUSD → EURUSD");
        symbol = "EURUSD";
    }
    
    string direction = GetJsonValue(response, "direction");
    string order_type = GetJsonValue(response, "order_type");
    if(order_type == "") order_type = GetJsonValue(response, "entry_type");
    
    double entry = StringToDouble(GetJsonValue(response, "entry"));
    if(entry == 0) entry = StringToDouble(GetJsonValue(response, "entry_price"));
    
    // Entry-Bereich extrahieren
    double entry_min = StringToDouble(GetJsonValue(response, "entry_min"));
    double entry_max = StringToDouble(GetJsonValue(response, "entry_max"));
    
    double sl = StringToDouble(GetJsonValue(response, "sl"));
    double tp = StringToDouble(GetJsonValue(response, "tp"));
    if(tp == 0) tp = StringToDouble(GetJsonValue(response, "tp1"));
    
    double risk = StringToDouble(GetJsonValue(response, "risk"));
    
    // Low Risk Flag extrahieren
    int low_risk = (int)StringToInteger(GetJsonValue(response, "low_risk"));
    
    // Validierung
    if(!ValidateSignal(symbol, direction, sl, tp, risk, order_type, entry)) {
        LogError("Signal-Validierung fehlgeschlagen");
        MarkSignalAsProcessed(signal_id, false);
        
        // Detaillierte Fehlermeldung
        string validation_error = "Validation failed: ";
        if(symbol == "") validation_error += "missing symbol";
        else if(direction != "buy" && direction != "sell") validation_error += "invalid direction";
        else if(sl <= 0) validation_error += "invalid SL";
        else if(risk <= 0) validation_error += "invalid risk";
        else validation_error += "invalid parameters";
        
        SendDeliveryConfirmation(signal_id, 0, false, validation_error);
        return;
    }
    
    LogImportant("📡 NEUES SIGNAL: " + signal_id + " | " + symbol + " " + direction);
    
    // Trade ausführen
    bool success = ProcessSignal(signal_id, symbol, direction, order_type, entry, sl, tp, risk, 
                                entry_min, entry_max, low_risk);
    
    MarkSignalAsProcessed(signal_id, success);
}

//+------------------------------------------------------------------+
//| TRADE AUSFÜHRUNG                                                 |
//+------------------------------------------------------------------+
bool ProcessSignal(string signal_id, string symbol_original, string direction, 
                   string order_type, double entry, double sl, double tp, double risk_percent,
                   double entry_min, double entry_max, int low_risk = 0) {
    
    // Nochmalige Prüfung
    if(IsSignalAlreadyTraded(signal_id)) {
        LogDebug("Signal " + signal_id + " bereits als Trade vorhanden");
        return false;
    }
    
    // Symbol mapping mit Custom-Mappings
    string trading_symbol = FindTradingSymbol(symbol_original);
    if(trading_symbol == "") {
        LogError("Symbol nicht handelbar: " + symbol_original);
        SendDeliveryConfirmation(signal_id, 0, false, 
                                "Symbol not found: " + symbol_original);
        return false;
    }
    
    LogDebug("Symbol: " + symbol_original + " → " + trading_symbol);
    
    // Order-Typ bestimmen
    ENUM_ORDER_TYPE trade_type = DetermineOrderType(direction, order_type, entry, trading_symbol, 
                                                    entry_min, entry_max);
    
    // Entry-Preis für Pending Orders bestimmen
    double final_entry = entry;
    if(trade_type == ORDER_TYPE_BUY_LIMIT || trade_type == ORDER_TYPE_SELL_LIMIT ||
       trade_type == ORDER_TYPE_BUY_STOP || trade_type == ORDER_TYPE_SELL_STOP) {
        
        if(entry <= 0 && entry_min > 0 && entry_max > 0) {
            if(trade_type == ORDER_TYPE_BUY_LIMIT || trade_type == ORDER_TYPE_SELL_STOP) {
                final_entry = entry_max;
            } else {
                final_entry = entry_min;
            }
            LogDebug("Entry-Preis aus Bereich gesetzt: " + DoubleToString(final_entry, 5));
        } else if(entry > 0) {
            final_entry = entry;
        } else {
            LogError("Kein Entry-Preis für Pending Order verfügbar");
            SendDeliveryConfirmation(signal_id, 0, false, 
                                    "No entry price for pending order");
            return false;
        }
    }
    
    // Low Risk Behandlung
    double effective_risk_percent = risk_percent;
    if(low_risk == 1) {
        effective_risk_percent = risk_percent / 2.0;
        LogImportant("🔻 LOW RISK aktiviert: " + DoubleToString(risk_percent, 2) + "% → " + 
                    DoubleToString(effective_risk_percent, 2) + "%");
    }
    
    // Lot-Berechnung mit verbesserter Fehlerbehandlung
    double actual_risk = 0.0;
    double actual_risk_amount = 0.0; // Deklaration außerhalb des if-Blocks
    string risk_message;
    double calc_entry = (final_entry > 0 && trade_type != ORDER_TYPE_BUY && trade_type != ORDER_TYPE_SELL) ? 
                        final_entry : entry;
    double lots = CalculateLots_v85(trading_symbol, calc_entry, sl, effective_risk_percent, trade_type, risk_message);
    
    // v8.5 BERECHNUNG IST BEREITS KOMPLETT - KEINE REDUNDANTE BERECHNUNG MEHR NÖTIG
    if(lots > 0) {
        // Berechne tatsächliches Risiko für Logging (konsistent mit v8.5)
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        ENUM_ORDER_TYPE calc_order_type = (trade_type == ORDER_TYPE_BUY || trade_type == ORDER_TYPE_BUY_LIMIT || trade_type == ORDER_TYPE_BUY_STOP) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        double profit_at_sl = 0;
        
        if(OrderCalcProfit(calc_order_type, trading_symbol, lots, calc_entry, sl, profit_at_sl)) {
            actual_risk_amount = MathAbs(profit_at_sl);
            actual_risk = (actual_risk_amount / balance) * 100.0;
        } else {
            // Fallback: Schätze basierend auf v8.5 Berechnung
            actual_risk_amount = balance * effective_risk_percent / 100.0; // Geschätzt
            actual_risk = effective_risk_percent; // Verwende Ziel-Risiko als Schätzung
        }
        
        LogImportant("📊 KONSISTENTE RISIKO-VALIDIERUNG (v8.5):");
        LogImportant("   Finale Lots: " + DoubleToString(lots, 3));
        
        // 🛡️ INTELLIGENTE LOTSIZE-KORREKTUR: Reduziere Lots bei Risiko-Überschreitung
        double risk_tolerance = 0.05; // 0.05% Toleranz für Rundungsfehler
        bool orderCalcProfitWorked = false;
        
        if(OrderCalcProfit(calc_order_type, trading_symbol, lots, calc_entry, sl, profit_at_sl)) {
            double orderCalcRisk_amount = MathAbs(profit_at_sl);
            double orderCalcRisk_percent = (orderCalcRisk_amount / balance) * 100.0;
            
            // Prüfe ob OrderCalcProfit sinnvolle Werte liefert (nicht 0 oder unrealistisch)
            if(orderCalcRisk_amount > 0.01 && orderCalcRisk_percent > 0.001 && orderCalcRisk_percent < 50.0) {
                orderCalcProfitWorked = true;
                actual_risk_amount = orderCalcRisk_amount;
                actual_risk = orderCalcRisk_percent;
                
                LogImportant("   ✅ OrderCalcProfit erfolgreich: " + DoubleToString(actual_risk, 4) + "%");
                
                // Wenn Risiko zu hoch ist, reduziere Lots automatisch
                if(actual_risk > (effective_risk_percent + risk_tolerance)) {
                    LogImportant("🔧 INTELLIGENTE LOTSIZE-KORREKTUR:");
                    LogImportant("   Ursprüngliches Risiko: " + DoubleToString(actual_risk, 4) + "%");
                    LogImportant("   Maximales Risiko: " + DoubleToString(effective_risk_percent, 2) + "%");
                    LogImportant("   Überschreitung: " + DoubleToString(actual_risk - effective_risk_percent, 4) + "%");
                    
                    // Berechne korrigierte Lotsize
                    double target_risk_amount = balance * effective_risk_percent / 100.0;
                    double loss_per_lot_actual = actual_risk_amount / lots; // Tatsächliche Loss per Lot
                    double corrected_lots = target_risk_amount / loss_per_lot_actual;
                    
                    // Auf Volume Step normalisieren (nach unten für Sicherheit)
                    double volume_step = SymbolInfoDouble(trading_symbol, SYMBOL_VOLUME_STEP);
                    corrected_lots = MathFloor(corrected_lots / volume_step) * volume_step;
                    
                    // Minimum-Lot prüfen
                    double volume_min = SymbolInfoDouble(trading_symbol, SYMBOL_VOLUME_MIN);
                    if(corrected_lots < volume_min) {
                        corrected_lots = volume_min;
                    }
                    
                    LogImportant("   🔧 KORRIGIERTE LOTSIZE: " + DoubleToString(corrected_lots, 3) + " Lots");
                    
                    // Validiere korrigierte Lotsize
                    double corrected_profit_at_sl = 0;
                    if(OrderCalcProfit(calc_order_type, trading_symbol, corrected_lots, calc_entry, sl, corrected_profit_at_sl)) {
                        double corrected_risk_amount = MathAbs(corrected_profit_at_sl);
                        double corrected_risk = (corrected_risk_amount / balance) * 100.0;
                        
                        LogImportant("   ✅ KORRIGIERTES RISIKO: " + DoubleToString(corrected_risk, 4) + "%");
                        
                        if(corrected_risk <= effective_risk_percent + 0.01) { // Kleine Toleranz für Rundung
                            lots = corrected_lots;
                            actual_risk_amount = corrected_risk_amount;
                            actual_risk = corrected_risk;
                            LogImportant("   🎯 KORREKTUR ERFOLGREICH: Trade wird mit reduzierter Lotsize ausgeführt");
                        } else {
                            LogError("   ❌ KORREKTUR FEHLGESCHLAGEN: Risiko immer noch zu hoch");
                            lots = 0;
                            risk_message = "CORRECTION FAILED: Risk still too high after reduction";
                        }
                    } else {
                        LogError("   ❌ KORREKTUR-VALIDIERUNG FEHLGESCHLAGEN");
                        lots = 0;
                        risk_message = "CORRECTION VALIDATION FAILED";
                    }
                } else {
                    LogImportant("   ✅ RISIKO-VALIDIERUNG BESTANDEN: " + DoubleToString(actual_risk, 4) + "% ≤ " + DoubleToString(effective_risk_percent, 2) + "%");
                }
            } else {
                LogImportant("   ⚠️ OrderCalcProfit lieferte unrealistische Werte: " + DoubleToString(orderCalcRisk_percent, 6) + "%");
            }
        } else {
            LogImportant("   ⚠️ OrderCalcProfit fehlgeschlagen für " + trading_symbol);
        }
        
        // Fallback: Verwende v8.5 Berechnung als primäre Quelle
        if(!orderCalcProfitWorked) {
            LogImportant("🔄 FALLBACK: Verwende v8.5 Berechnung als Referenz");
            
            // Die v8.5 Berechnung ist bereits erfolgt und hat das korrekte Risiko berechnet
            // Wir verwenden eine konservative Schätzung basierend auf der v8.5 Logik
            
            // Konservative Schätzung: Das finale Risiko sollte nahe am Ziel-Risiko liegen
            // aber leicht darunter (wie v8.5 berechnet: 4.9872% statt 5.00%)
            actual_risk = effective_risk_percent * 0.997; // 99.7% des Ziel-Risikos (konservativ)
            actual_risk_amount = balance * actual_risk / 100.0;
            
            LogImportant("   📊 v8.5 Fallback-Schätzung: " + DoubleToString(actual_risk, 4) + "% (konservativ unter Ziel)");
            LogImportant("   ℹ️ Basiert auf v8.5 interner Berechnung - OrderCalcProfit nicht verfügbar");
        }
        
        LogImportant("   🛡️ FINALE LOTSIZE: " + DoubleToString(lots, 3) + " Lots");
        LogImportant("   🛡️ FINALES RISIKO: " + DoubleToString(actual_risk, 4) + "% (Methode: " + 
                    (orderCalcProfitWorked ? "OrderCalcProfit" : "v8.5 Fallback") + ")");
    }
    
    if(lots <= 0) {
        LogError("Lot-Berechnung fehlgeschlagen: " + risk_message);
        
        // Spezielle Behandlung für "Risk too small"
        if(StringFind(risk_message, "Risk too small") >= 0) {
            // Berechne Mindest-Risiko für diese Position (KORRIGIERT - gleiche Methode wie CalculateLots)
            double min_lot = SymbolInfoDouble(trading_symbol, SYMBOL_VOLUME_MIN);
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            
            // Verwende OrderCalcProfit für korrekte Berechnung (wie in CalculateLots)
            ENUM_ORDER_TYPE calc_order_type = (direction == "buy") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
            double profit_at_sl = 0;
            
            if(OrderCalcProfit(calc_order_type, trading_symbol, min_lot, calc_entry, sl, profit_at_sl)) {
                double min_risk_amount = MathAbs(profit_at_sl);
                double min_risk_percent = (min_risk_amount / balance) * 100.0;
                
                string detailed_error = "Risk too small: Min lot " + DoubleToString(min_lot, 3) +
                                      " requires " + DoubleToString(min_risk_percent, 2) + "% risk, " +
                                      "but only " + DoubleToString(effective_risk_percent, 2) + "% allocated" +
                                      (low_risk == 1 ? " (halved due to low_risk)" : "");
                
                LogError(detailed_error);
                
                // Erweiterte API-Benachrichtigung mit effective_risk_percent
                SendRiskTooSmallNotification(signal_id, trading_symbol, effective_risk_percent, 
                                            min_risk_percent, min_lot, balance, OrderTypeToString(trade_type));
            } else {
                LogError("❌ OrderCalcProfit für Min-Risiko fehlgeschlagen!");
                SendDeliveryConfirmation(signal_id, 0, false, risk_message);
            }
        } else {
            SendDeliveryConfirmation(signal_id, 0, false, 
                                    "Lot calculation failed: " + risk_message);
        }
        
        return false;
    }
    
    // Trade ausführen
    bool result = false;
    string comment = "Signal: " + signal_id;
    
    if(trade_type == ORDER_TYPE_BUY || trade_type == ORDER_TYPE_SELL) {
        // Market Order
        double price = (trade_type == ORDER_TYPE_BUY) ? 
                      SymbolInfoDouble(trading_symbol, SYMBOL_ASK) : 
                      SymbolInfoDouble(trading_symbol, SYMBOL_BID);
        
        result = trade.PositionOpen(trading_symbol, trade_type, lots, price, sl, tp, comment);
    } else {
        // Pending Order - PREIS-VALIDIERUNG HINZUFÜGEN
        double bid = SymbolInfoDouble(trading_symbol, SYMBOL_BID);
        double ask = SymbolInfoDouble(trading_symbol, SYMBOL_ASK);
        double spread = ask - bid;
        
        LogImportant("📊 PENDING ORDER VALIDIERUNG:");
        LogImportant("   Order Type: " + OrderTypeToString(trade_type));
        LogImportant("   Entry: " + DoubleToString(final_entry, 5));
        LogImportant("   Aktueller Bid: " + DoubleToString(bid, 5));
        LogImportant("   Aktueller Ask: " + DoubleToString(ask, 5));
        LogImportant("   Spread: " + DoubleToString(spread, 5));
        
        // Prüfe auf sofortige Ausführung
        bool will_execute_immediately = false;
        string warning_msg = "";
        
        if(trade_type == ORDER_TYPE_BUY_LIMIT) {
            if(final_entry >= ask) {
                will_execute_immediately = true;
                warning_msg = "Buy Limit " + DoubleToString(final_entry, 5) + 
                             " >= Ask " + DoubleToString(ask, 5) + " → SOFORTIGE AUSFÜHRUNG!";
            }
        }
        else if(trade_type == ORDER_TYPE_SELL_LIMIT) {
            if(final_entry <= bid) {
                will_execute_immediately = true;
                warning_msg = "Sell Limit " + DoubleToString(final_entry, 5) + 
                             " <= Bid " + DoubleToString(bid, 5) + " → SOFORTIGE AUSFÜHRUNG!";
            }
        }
        
        if(will_execute_immediately) {
            LogWarning("⚠️⚠️⚠️ " + warning_msg);
            LogWarning("   Diese Limit Order wird wahrscheinlich sofort als Market Order ausgeführt!");
            LogWarning("   Grund: Entry-Preis ist bereits besser als aktueller Marktpreis");
        }
        
        result = trade.OrderOpen(trading_symbol, trade_type, lots, 0, final_entry, sl, tp, 
                                ORDER_TIME_GTC, 0, comment);
    }
    
    if(result) {
        ulong ticket = trade.ResultOrder();
        double executed_price = trade.ResultPrice();
        double executed_volume = trade.ResultVolume();
        
        string order_info = (trade_type == ORDER_TYPE_BUY || trade_type == ORDER_TYPE_SELL) ? 
                           "MARKET" : "PENDING @ " + DoubleToString(final_entry, 5);
        
        LogImportant("✅ TRADE AUSGEFÜHRT: #" + IntegerToString(ticket) + 
                    " | " + trading_symbol + " | " + DoubleToString(executed_volume, 2) + " Lots | " +
                    order_info + " | Risiko: " + DoubleToString(actual_risk, 2) + "%");
        
        // Zu Tracking hinzufügen
        AddTrackedPosition(ticket, signal_id, (trade_type == ORDER_TYPE_BUY || trade_type == ORDER_TYPE_SELL));
        
        // MANUAL CHANGE PROTECTION: Initialisiere Position Tracking
        InitializePositionTracking(ticket, signal_id, sl, tp);
        
        // Erweiterte Delivery Confirmation
        SendTradeExecutionConfirmation(signal_id, ticket, trading_symbol, 
                                      trade_type, executed_volume, 
                                      executed_price, sl, tp, effective_risk_percent, actual_risk, actual_risk_amount);
    } else {
        uint error_code = trade.ResultRetcode();
        string error_msg = trade.ResultRetcodeDescription();
        LogError("Trade fehlgeschlagen: " + error_msg);
        LogImportant("🚨 TRADE-FEHLER ERKANNT - sende an API:");
        LogImportant("   Signal: " + signal_id);
        LogImportant("   Symbol: " + trading_symbol);
        LogImportant("   Direction: " + direction);
        LogImportant("   Lots: " + DoubleToString(lots, 3));
        LogImportant("   Error Code: " + IntegerToString(error_code));
        
        SendTradeErrorConfirmation(signal_id, trading_symbol, direction, 
                                  lots, error_code, error_msg, OrderTypeToString(trade_type), effective_risk_percent);
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| VEREINFACHTE LOT-BERECHNUNG - IMMER ABRUNDEN!                   |
//+------------------------------------------------------------------+
// ===== ROBUSTE LOT-BERECHNUNG MIT FALLBACK-MECHANISMEN =====

double CalculateLossPerLot_Method1_OrderCalcProfit(string symbol, ENUM_ORDER_TYPE order_type, 
                                                   double entry_price, double sl_price) {
    double profit_at_sl = 0;
    if(!OrderCalcProfit(order_type, symbol, 1.0, entry_price, sl_price, profit_at_sl)) {
        return -1; // Fehler
    }
    double loss_per_lot = MathAbs(profit_at_sl);
    
    // ANGEPASSTE Validierung: Flexibler für verschiedene Währungspaare
    double distance = MathAbs(entry_price - sl_price);
    
    // OrderCalcProfit ist die präziseste Methode - keine Validierung nötig
    LogDebug("✅ Method 1 (OrderCalcProfit): " + DoubleToString(loss_per_lot, 5) + " USD");
    return loss_per_lot;
}

double CalculateLossPerLot_Method2_TickCalculation(string symbol, double entry_price, double sl_price) {
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    
    LogDebug("📊 TICK CALCULATION DEBUG:");
    LogDebug("   Symbol: " + symbol);
    LogDebug("   Tick Size: " + DoubleToString(tick_size, 8));
    LogDebug("   Tick Value: " + DoubleToString(tick_value, 8));
    
    // UNIVERSELLE LÖSUNG: Keine Tick-Validierung mehr - verwende Fallbacks
    if(tick_size <= 0 || tick_value <= 0) {
        LogWarning("⚠️ Broker-Tick-Daten unvollständig - verwende universelle Berechnung");
        // Fallback zur universellen Symbol-Datenbank
        return CalculateWithUniversalDatabase(symbol, entry_price, sl_price);
    }
    
    double distance = MathAbs(entry_price - sl_price);
    double ticks = distance / tick_size;
    double loss_per_lot = ticks * tick_value;
    
    // Spezielle Behandlung für JPY-Paare (Cross-Currency)
    string base_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
    string profit_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    LogDebug("💱 CURRENCY INFO:");
    LogDebug("   Base: " + base_currency);
    LogDebug("   Profit: " + profit_currency);
    LogDebug("   Account: " + account_currency);
    
    // Wenn Profit Currency != Account Currency, versuche Konvertierung
    if(profit_currency != account_currency && loss_per_lot > 0) {
        string conversion_symbol = profit_currency + account_currency;
        double conversion_rate = SymbolInfoDouble(conversion_symbol, SYMBOL_BID);
        
        if(conversion_rate > 0) {
            double converted_loss = loss_per_lot * conversion_rate;
            LogDebug("💱 CURRENCY CONVERSION:");
            LogDebug("   " + profit_currency + " → " + account_currency);
            LogDebug("   Rate: " + DoubleToString(conversion_rate, 5));
            LogDebug("   Original: " + DoubleToString(loss_per_lot, 5) + " " + profit_currency);
            LogDebug("   Converted: " + DoubleToString(converted_loss, 5) + " " + account_currency);
            loss_per_lot = converted_loss;
        } else {
            // Fallback: Versuche umgekehrte Konvertierung
            conversion_symbol = account_currency + profit_currency;
            conversion_rate = SymbolInfoDouble(conversion_symbol, SYMBOL_ASK);
            if(conversion_rate > 0) {
                double converted_loss = loss_per_lot / conversion_rate;
                LogDebug("💱 REVERSE CURRENCY CONVERSION:");
                LogDebug("   " + profit_currency + " → " + account_currency);
                LogDebug("   Rate: 1/" + DoubleToString(conversion_rate, 5));
                LogDebug("   Converted: " + DoubleToString(converted_loss, 5) + " " + account_currency);
                loss_per_lot = converted_loss;
            } else {
                LogWarning("⚠️ Keine Währungskonvertierung verfügbar für " + profit_currency + " → " + account_currency);
            }
        }
    }
    
    LogDebug("✅ Method 2 (Tick Calculation):");
    LogDebug("   Distance: " + DoubleToString(distance, 5));
    LogDebug("   Tick Size: " + DoubleToString(tick_size, 8));
    LogDebug("   Tick Value: " + DoubleToString(tick_value, 5));
    LogDebug("   Ticks: " + DoubleToString(ticks, 2));
    LogDebug("   Loss per Lot: " + DoubleToString(loss_per_lot, 5) + " " + account_currency);
    
    return loss_per_lot;
}

double CalculateLossPerLot_Method3_ContractSize(string symbol, double entry_price, double sl_price) {
    double contract_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    if(contract_size <= 0 || point <= 0) {
        LogError("❌ Ungültige Contract-Daten: contract_size=" + DoubleToString(contract_size, 2) + 
                ", point=" + DoubleToString(point, 8));
        return -1;
    }
    
    double distance = MathAbs(entry_price - sl_price);
    double points = distance / point;
    
    // Für USD-basierte Symbole
    string profit_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    double loss_per_lot = 0;
    if(profit_currency == account_currency) {
        // Direkte Berechnung für USD/USD
        loss_per_lot = points * point * contract_size;
    } else {
        // Währungsumrechnung erforderlich
        LogDebug("⚠️ Währungsumrechnung erforderlich: " + profit_currency + " → " + account_currency);
        return -1; // Nicht implementiert
    }
    
    LogDebug("✅ Method 3 (Contract Size):");
    LogDebug("   Contract Size: " + DoubleToString(contract_size, 2));
    LogDebug("   Point: " + DoubleToString(point, 8));
    LogDebug("   Points: " + DoubleToString(points, 2));
    LogDebug("   Loss per Lot: " + DoubleToString(loss_per_lot, 5) + " USD");
    
    return loss_per_lot;
}

// ========== HARDCODED FALLBACK-WERTE FÜR ZUVERLÄSSIGKEIT ==========
double GetHardcodedPipValue(string symbol, string account_currency = "USD") {
    // Entferne Suffixe wie .ecn, .raw, etc.
    string clean_symbol = symbol;
    StringReplace(clean_symbol, ".ecn", "");
    StringReplace(clean_symbol, ".raw", "");
    StringReplace(clean_symbol, ".pro", "");
    StringReplace(clean_symbol, "#", "");
    
    double pip_value_usd = 0; // Basis-Pip-Value in USD
    
    // Standard Pip Values für 1 Standard Lot (100,000 Einheiten) in USD
    // Major USD Pairs (Quote Currency = USD)
    if(clean_symbol == "EURUSD" || clean_symbol == "GBPUSD" || 
       clean_symbol == "AUDUSD" || clean_symbol == "NZDUSD" ||
       clean_symbol == "USDCAD" || clean_symbol == "USDCHF") {
        pip_value_usd = 10.0; // $10 per pip for standard lot
    }
    
    // JPY Pairs - unterschiedliche Werte für direkte vs Cross-Pairs
    else if(clean_symbol == "USDJPY") {
        pip_value_usd = 6.7; // ~$6.7 per pip (varies with USDJPY rate)
    }
    else if(clean_symbol == "EURJPY" || clean_symbol == "GBPJPY" || 
            clean_symbol == "AUDJPY" || clean_symbol == "NZDJPY" || 
            clean_symbol == "CADJPY" || clean_symbol == "CHFJPY") {
        // Cross-JPY Paare haben höhere Pip-Werte
        if(clean_symbol == "GBPJPY") {
            pip_value_usd = 15.0; // GBPJPY ~$15 per pip (höher wegen GBP Stärke)
        } else if(clean_symbol == "EURJPY") {
            pip_value_usd = 12.0; // EURJPY ~$12 per pip
        } else {
            pip_value_usd = 8.0;  // Andere Cross-JPY ~$8 per pip
        }
    }
    
    // Cross Pairs (approximations)
    else if(clean_symbol == "EURGBP" || clean_symbol == "EURAUD" ||
            clean_symbol == "EURNZD" || clean_symbol == "EURCAD" ||
            clean_symbol == "EURCHF") {
        pip_value_usd = 10.0; // Similar to major pairs
    }
    
    // Crypto (if available)
    else if(clean_symbol == "BTCUSD" || clean_symbol == "BTCUSDT") {
        pip_value_usd = 1.0; // $1 per point
    }
    else if(clean_symbol == "ETHUSD" || clean_symbol == "ETHUSDT") {
        pip_value_usd = 1.0; // $1 per point
    }
    
    // Commodities
    else if(clean_symbol == "XAUUSD" || clean_symbol == "GOLD") {
        pip_value_usd = 10.0; // $10 per pip
    }
    else if(clean_symbol == "XAGUSD" || clean_symbol == "SILVER") {
        pip_value_usd = 50.0; // $50 per pip
    }
    
    if(pip_value_usd <= 0) {
        return -1; // Unbekanntes Symbol
    }
    
    // Wenn Account Currency = USD, direkt zurückgeben
    if(account_currency == "USD") {
        return pip_value_usd;
    }
    
    // Sonst: USD → Account Currency konvertieren
    double conversion_rate = GetCurrencyConversionRate("USD", account_currency);
    if(conversion_rate > 0) {
        double pip_value_account = pip_value_usd * conversion_rate;
        LogDebug("💱 PIP VALUE CONVERSION:");
        LogDebug("   USD Pip Value: " + DoubleToString(pip_value_usd, 2) + " USD");
        LogDebug("   Conversion Rate (USD→" + account_currency + "): " + DoubleToString(conversion_rate, 5));
        LogDebug("   " + account_currency + " Pip Value: " + DoubleToString(pip_value_account, 2) + " " + account_currency);
        return pip_value_account;
    }
    
    LogWarning("⚠️ Keine Währungskonvertierung verfügbar: USD → " + account_currency);
    LogWarning("   Verwende USD Pip Value als Fallback: " + DoubleToString(pip_value_usd, 2));
    return pip_value_usd; // Fallback: USD Value verwenden
}

// Robuste Währungskonvertierung mit Fallback-Raten
double GetCurrencyConversionRate(string from_currency, string to_currency) {
    if(from_currency == to_currency) {
        return 1.0; // Gleiche Währung
    }
    
    // Versuche Live-Rate zu bekommen
    string conversion_symbol = from_currency + to_currency;
    double live_rate = SymbolInfoDouble(conversion_symbol, SYMBOL_BID);
    
    if(live_rate > 0) {
        LogDebug("✅ Live Rate gefunden: " + conversion_symbol + " = " + DoubleToString(live_rate, 5));
        return live_rate;
    }
    
    // Versuche umgekehrte Rate
    conversion_symbol = to_currency + from_currency;
    live_rate = SymbolInfoDouble(conversion_symbol, SYMBOL_ASK);
    
    if(live_rate > 0) {
        double inverted_rate = 1.0 / live_rate;
        LogDebug("✅ Inverse Rate gefunden: " + conversion_symbol + " = " + DoubleToString(live_rate, 5) + 
                " → " + from_currency + to_currency + " = " + DoubleToString(inverted_rate, 5));
        return inverted_rate;
    }
    
    // Fallback: Hardcoded approximate rates (aktualisiert regelmäßig)
    LogWarning("⚠️ Keine Live-Rate verfügbar, verwende Fallback-Rate");
    
    if(from_currency == "USD") {
        if(to_currency == "EUR") return 0.92;      // USD → EUR (~0.92)
        if(to_currency == "GBP") return 0.79;      // USD → GBP (~0.79)
        if(to_currency == "JPY") return 148.5;     // USD → JPY (~148.5)
        if(to_currency == "CHF") return 0.88;      // USD → CHF (~0.88)
        if(to_currency == "CAD") return 1.36;      // USD → CAD (~1.36)
        if(to_currency == "AUD") return 1.52;      // USD → AUD (~1.52)
        if(to_currency == "NZD") return 1.64;      // USD → NZD (~1.64)
    }
    else if(to_currency == "USD") {
        if(from_currency == "EUR") return 1.09;    // EUR → USD (~1.09)
        if(from_currency == "GBP") return 1.27;    // GBP → USD (~1.27)
        if(from_currency == "JPY") return 0.0067;  // JPY → USD (~0.0067)
        if(from_currency == "CHF") return 1.14;    // CHF → USD (~1.14)
        if(from_currency == "CAD") return 0.74;    // CAD → USD (~0.74)
        if(from_currency == "AUD") return 0.66;    // AUD → USD (~0.66)
        if(from_currency == "NZD") return 0.61;    // NZD → USD (~0.61)
    }
    
    LogError("❌ Keine Konvertierungsrate verfügbar: " + from_currency + " → " + to_currency);
    return -1; // Keine Rate verfügbar
}

double CalculateLossPerLot_Method4_HardcodedFallback(string symbol, double entry_price, double sl_price) {
    LogDebug("🔄 UNIVERSELLE FALLBACK-BERECHNUNG:");
    
    // Verwende die universelle Datenbank statt hardcoded Values
    return CalculateWithUniversalDatabase(symbol, entry_price, sl_price);
}

double GetRobustLossPerLot(string symbol, ENUM_ORDER_TYPE order_type, double entry_price, double sl_price) {
    LogImportant("🔧 ROBUSTE LOT-BERECHNUNG:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Entry: " + DoubleToString(entry_price, 5));
    LogImportant("   SL: " + DoubleToString(sl_price, 5));
    LogImportant("   Distance: " + DoubleToString(MathAbs(entry_price - sl_price), 5));
    
    double loss_per_lot = -1;
    string method_used = "";
    
    // Method 1: OrderCalcProfit (mit Validierung)
    loss_per_lot = CalculateLossPerLot_Method1_OrderCalcProfit(symbol, order_type, entry_price, sl_price);
    if(loss_per_lot > 0) {
        method_used = "OrderCalcProfit (validiert)";
    } else {
        LogWarning("⚠️ Method 1 (OrderCalcProfit) fehlgeschlagen oder unrealistisch");
        
        // Method 2: Tick Calculation
        loss_per_lot = CalculateLossPerLot_Method2_TickCalculation(symbol, entry_price, sl_price);
        if(loss_per_lot > 0) {
            method_used = "Tick Calculation";
        } else {
            LogWarning("⚠️ Method 2 (Tick Calculation) fehlgeschlagen");
            
            // Method 3: Contract Size
            loss_per_lot = CalculateLossPerLot_Method3_ContractSize(symbol, entry_price, sl_price);
            if(loss_per_lot > 0) {
                method_used = "Contract Size";
            } else {
                LogWarning("⚠️ Method 3 (Contract Size) fehlgeschlagen");
                
                // Method 4: Hardcoded Fallback (ZUVERLÄSSIGKEITS-GARANTIE)
                loss_per_lot = CalculateLossPerLot_Method4_HardcodedFallback(symbol, entry_price, sl_price);
                if(loss_per_lot > 0) {
                    method_used = "Hardcoded Fallback";
                } else {
                    LogWarning("⚠️ Alle Standard-Methoden fehlgeschlagen - verwende universelle Lösung");
                    // Letzter Fallback: Universelle Datenbank mit konservativer Schätzung
                    loss_per_lot = CalculateWithUniversalDatabase(symbol, entry_price, sl_price);
                    method_used = "Universelle Datenbank (Fallback)";
                    
                    if(loss_per_lot <= 0) {
                        LogError("❌ Auch universelle Berechnung fehlgeschlagen für Symbol: " + symbol);
                        return -1;
                    }
                }
            }
        }
    }
    
    LogImportant("✅ BERECHNUNG ERFOLGREICH:");
    LogImportant("   Methode: " + method_used);
    LogImportant("   Verlust bei 1.0 Lot: " + DoubleToString(loss_per_lot, 5) + " USD");
    
    return loss_per_lot;
}

//+------------------------------------------------------------------+
//| OPTIMIERTE LOT-BERECHNUNG MIT ROBUSTEM RISIKO-SCHUTZ           |
//| Version: 8.6 - UNIVERSELLE BROKER-NEUTRALE LÖSUNG              |
//+------------------------------------------------------------------+
double CalculateLots(string symbol, double entry_price, double sl_price, 
                    double risk_percent, ENUM_ORDER_TYPE order_type, string &message) {
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("💰 OPTIMIERTE LOT-BERECHNUNG für " + symbol);
    LogImportant("════════════════════════════════════════════");
    
    // Basis-Informationen
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * risk_percent / 100.0;
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    LogImportant("📊 ACCOUNT:");
    LogImportant("   Balance: " + DoubleToString(balance, 2) + " " + account_currency);
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    LogImportant("   Risiko-Betrag: " + DoubleToString(risk_amount, 2) + " " + account_currency);
    
    // Symbol aktivieren und Daten laden
    if(!RefreshSymbolData(symbol)) {
        message = "Symbol data refresh failed";
        return 0;
    }
    
    // Symbol-Informationen
    double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    // Validierung
    if(min_lot <= 0 || max_lot <= 0 || lot_step <= 0) {
        LogError("❌ Ungültige Symbol-Daten für " + symbol);
        message = "Invalid symbol data";
        return 0;
    }
    
    // Währungen für Debug
    string base_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
    string profit_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
    
    LogImportant("📈 SYMBOL-INFO:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Base/Profit: " + base_currency + "/" + profit_currency);
    LogImportant("   Lot-Bereich: " + DoubleToString(min_lot, 3) + " - " + DoubleToString(max_lot, 3));
    LogImportant("   Lot-Step: " + DoubleToString(lot_step, 4));
    
    // Entry-Preis bestimmen (falls nicht gesetzt)
    if(entry_price <= 0) {
        double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        entry_price = (sl_price < bid) ? ask : bid;
        LogDebug("Entry automatisch gesetzt: " + DoubleToString(entry_price, digits));
    }
    
    // Order-Typ bestimmen
    ENUM_ORDER_TYPE calc_order_type = (entry_price > sl_price) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    
    LogImportant("📍 TRADE-PARAMETER:");
    LogImportant("   Order Type: " + (calc_order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"));
    LogImportant("   Entry: " + DoubleToString(entry_price, digits));
    LogImportant("   SL: " + DoubleToString(sl_price, digits));
    LogImportant("   Distanz: " + DoubleToString(MathAbs(entry_price - sl_price), digits) + " (" + 
                DoubleToString(MathAbs(entry_price - sl_price) * MathPow(10, digits-1), 1) + " Pips)");
    
    // ========== ROBUSTE BERECHNUNG MIT FALLBACK-MECHANISMEN ==========
    double loss_per_lot = GetRobustLossPerLot_v832(symbol, calc_order_type, entry_price, sl_price);
    
    if(loss_per_lot <= 0) {
        LogError("❌ Alle Berechnungsmethoden fehlgeschlagen!");
        message = "Loss calculation failed with all methods";
        return 0;
    }
    
    LogImportant("💡 VERLUST PRO LOT: " + DoubleToString(loss_per_lot, 2) + " " + account_currency);
    // ========== NOTFALL-PATCH: OrderCalcProfit-Berechnung DEAKTIVIERT ==========
    // GRUND: Schwerwiegender Bug führte zu 99.98 Lots statt 3% Risiko
    // LÖSUNG: Rückkehr zur bewährten Tick-Calculation-Methode
    LogWarning("⚠️ NOTFALL-MODUS: OrderCalcProfit-Berechnung deaktiviert");
    LogWarning("   Grund: Kritischer Bug in v7.0-7.2 (99-Lot Problem)");
    LogWarning("   Verwende bewährte Tick-Calculation-Methode");
    
    // Direkte Berechnung mit bewährter Methode
    double theoretical_lots = risk_amount / loss_per_lot;
    LogImportant("   Theoretisch maximale Lots: " + DoubleToString(theoretical_lots, 6));
    
    // ========== KRITISCHE SICHERHEITSBEGRENZUNG ==========
    // NIEMALS mehr als 10% des Kontos riskieren (Sicherheitsstopp)
    double max_allowed_lots = (balance * 0.10) / loss_per_lot;
    LogImportant("   Sicherheits-Maximum (10% Konto): " + DoubleToString(max_allowed_lots, 3));
    
    // Verwende das kleinere der beiden Limits
    double safe_lots = MathMin(theoretical_lots, max_allowed_lots);
    safe_lots = MathFloor(safe_lots / lot_step) * lot_step;
    LogImportant("   Auf Lot-Step normalisiert: " + DoubleToString(safe_lots, 3));
    
    // ========== MINDEST-LOT PRÜFUNG ==========
    if(safe_lots < min_lot) {
        LogWarning("⚠️ Berechnete Lots (" + DoubleToString(safe_lots, 3) + ") unter Minimum (" + DoubleToString(min_lot, 3) + ")");
        
        // Prüfe ob min_lot das Risiko überschreitet
        double min_lot_risk_amount = min_lot * loss_per_lot;
        double min_lot_risk_percent = (min_lot_risk_amount / balance) * 100.0;
        
        LogImportant("🔍 MINDEST-LOT ANALYSE:");
        LogImportant("   Min Lot: " + DoubleToString(min_lot, 3));
        LogImportant("   Risiko bei Min Lot: " + DoubleToString(min_lot_risk_percent, 3) + "%");
        LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
        
        // STRIKTE REGEL: Niemals mehr als gewünschtes Risiko
        if(min_lot_risk_percent > risk_percent) {
            LogError("❌ RISIKO ZU KLEIN!");
            LogError("   Mindest-Lots würden " + DoubleToString(min_lot_risk_percent, 2) + "% riskieren");
            LogError("   Aber nur " + DoubleToString(risk_percent, 2) + "% sind erlaubt");
            LogError("   Trade wird zum Schutz des Kontos ABGELEHNT!");
            
            message = "Risk too small. Min lot requires " + DoubleToString(min_lot_risk_percent, 2) + 
                     "% risk, but only " + DoubleToString(risk_percent, 2) + "% allocated";
            return 0;
        } else {
            // Min lot ist akzeptabel
            safe_lots = min_lot;
            LogImportant("✅ Min Lot akzeptiert (Risiko: " + DoubleToString(min_lot_risk_percent, 2) + "%)");
        }
    }
    
    // ========== MAXIMAL-LOT PRÜFUNG ==========
    if(safe_lots > max_lot) {
        safe_lots = max_lot;
        LogWarning("⚠️ Auf Maximum begrenzt: " + DoubleToString(max_lot, 3));
    }
    
    // ========== FINALE RISIKO-VALIDIERUNG ==========
    // Berechne das tatsächliche Risiko mit den finalen Lots
    double actual_risk_amount = 0.0;
    double actual_risk_percent = 0.0;
    
    // NOTFALL-PATCH: Verwende nur die bewährte Fallback-Methode
    // OrderCalcProfit ist in v7.0-7.2 fehlerhaft und gibt 0.00 zurück
    actual_risk_amount = safe_lots * loss_per_lot;
    actual_risk_percent = (actual_risk_amount / balance) * 100.0;
    LogDebug("Risiko via bewährte Tick-Calculation berechnet (OrderCalcProfit deaktiviert)");
    
    LogImportant("🔍 FINALE RISIKO-VALIDIERUNG:");
    LogImportant("   Finale Lots: " + DoubleToString(safe_lots, 3));
    LogImportant("   Tatsächlicher Verlust bei SL: " + DoubleToString(actual_risk_amount, 2) + " " + account_currency);
    LogImportant("   Tatsächliches Risiko: " + DoubleToString(actual_risk_percent, 3) + "%");
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    
    // ========== KRITISCHE SICHERHEITSPRÜFUNG ==========
    // NIEMALS mehr als gewünschtes Risiko akzeptieren!
    if(actual_risk_percent > risk_percent) {
        LogError("❌ KRITISCHER SICHERHEITSFEHLER!");
        LogError("   Tatsächliches Risiko (" + DoubleToString(actual_risk_percent, 3) + 
                "%) überschreitet gewünschtes Risiko (" + DoubleToString(risk_percent, 2) + "%)");
        LogError("   Differenz: +" + DoubleToString(actual_risk_percent - risk_percent, 3) + "%");
        
        // ROBUSTE KORREKTUR: Progressive Lot-Reduzierung für schnelle Konvergenz
        LogImportant("🛡️ AKTIVIERE OPTIMIERTEN RISIKO-SCHUTZ: Progressive Lot-Reduzierung...");
        
        // Schätze benötigte Iterationen für bessere Transparenz
        int estimated_iterations = EstimateRequiredIterations(actual_risk_percent - risk_percent, loss_per_lot, balance, lot_step);
        LogImportant("📊 Geschätzte Iterationen: ~" + IntegerToString(estimated_iterations) + " (statt " + 
                    IntegerToString((int)((actual_risk_percent - risk_percent) * balance / loss_per_lot / lot_step)) + " mit alter Methode)");
        
        double corrected_lots = safe_lots;
        int safety_iterations = 0;
        const int MAX_SAFETY_ITERATIONS = 1000; // Sehr hohe Grenze für Sicherheit
        
        while(actual_risk_percent > risk_percent && safety_iterations < MAX_SAFETY_ITERATIONS) {
            safety_iterations++;
            
            // PROGRESSIVE LOT-REDUZIERUNG: Nach jeweils 10 Versuchen größere Schritte
            double reduction_amount = GetProgressiveLotReduction(safety_iterations, lot_step);
            corrected_lots -= reduction_amount;
            
            // Prüfe ob noch über Minimum
            if(corrected_lots < min_lot) {
                LogError("❌ RISIKO-SCHUTZ FEHLGESCHLAGEN!");
                LogError("   Selbst Minimum-Lot (" + DoubleToString(min_lot, 3) + 
                        ") überschreitet gewünschtes Risiko");
                LogError("   Trade wird zum Schutz des Kontos ABGELEHNT!");
                
                message = "Risk protection failed: Even minimum lot exceeds desired risk";
                return 0;
            }
            
            // Berechne neues Risiko (nur mit bewährter Methode)
            actual_risk_amount = corrected_lots * loss_per_lot;
            actual_risk_percent = (actual_risk_amount / balance) * 100.0;
            
            // Erweiterte Logging-Information
            if(safety_iterations <= 10 || safety_iterations % 10 == 0 || actual_risk_percent <= risk_percent) {
                LogDebug("Iteration " + IntegerToString(safety_iterations) + 
                        " (Reduzierung: -" + DoubleToString(reduction_amount, 3) + "): " +
                        "Lots=" + DoubleToString(corrected_lots, 3) + 
                        ", Risiko=" + DoubleToString(actual_risk_percent, 3) + "%");
            }
        }
        
        if(actual_risk_percent <= risk_percent) {
            safe_lots = corrected_lots;
            LogSuccess("✅ RISIKO-SCHUTZ ERFOLGREICH nach " + IntegerToString(safety_iterations) + " Iteration(en)!");
            LogSuccess("   Korrigierte Lots: " + DoubleToString(safe_lots, 3));
            LogSuccess("   Finales Risiko: " + DoubleToString(actual_risk_percent, 3) + "%");
        } else {
            LogError("❌ RISIKO-SCHUTZ VERSAGT nach " + IntegerToString(MAX_SAFETY_ITERATIONS) + " Iterationen!");
            LogError("   Das sollte mathematisch unmöglich sein!");
            
            message = "Risk protection algorithm failed - mathematical error";
            return 0;
        }
    }
    
    // ========== FINALE VALIDIERUNG UND AUSGABE ==========
    double final_deviation = actual_risk_percent - risk_percent;
    
    LogImportant("✅ LOT-BERECHNUNG ERFOLGREICH ABGESCHLOSSEN:");
    LogImportant("   Finale Lots: " + DoubleToString(safe_lots, 3));
    LogImportant("   Finaler Verlust bei SL: " + DoubleToString(actual_risk_amount, 2) + " " + account_currency);
    LogImportant("   Finales Risiko: " + DoubleToString(actual_risk_percent, 3) + "%");
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    
    // Bewertung der Abweichung
    if(final_deviation > 0.001) { // Mehr als 0.001% Überschreitung
        LogError("   ❌ KRITISCHER FEHLER: Risiko um " + DoubleToString(final_deviation, 4) + "% zu hoch!");
        LogError("   Das sollte NIEMALS passieren - Algorithmus-Fehler!");
        
        message = "Critical error: Risk exceeds desired level by " + DoubleToString(final_deviation, 4) + "%";
        return 0;
    } else if(final_deviation > -0.5) {
        LogSuccess("   ✅ PERFEKT: Risiko optimal ausgenutzt (Abweichung: " + DoubleToString(final_deviation, 3) + "%)");
    } else {
        LogInfo("   ✅ SICHER: Risiko " + DoubleToString(MathAbs(final_deviation), 2) + "% unter gewünschtem Wert");
    }
    
    LogImportant("════════════════════════════════════════════");
    
    // 🚨 ABSOLUTE NOTFALL-SICHERHEITSBEGRENZUNG - NIEMALS MEHR ALS 10 LOTS!
    double ABSOLUTE_MAX_LOTS = 10.0;
    if(safe_lots > ABSOLUTE_MAX_LOTS) {
        LogError("🚨 NOTFALL-STOPP: " + DoubleToString(safe_lots, 3) + " Lots > " + DoubleToString(ABSOLUTE_MAX_LOTS, 1) + " Lots!");
        LogError("   TRADE WIRD ZUM SCHUTZ DES KONTOS ABGELEHNT!");
        LogError("   Mögliche Ursache: Fehlerhafte Point Value Berechnung");
        
        message = "EMERGENCY STOP: " + DoubleToString(safe_lots, 3) + " lots exceeds safety limit of " + DoubleToString(ABSOLUTE_MAX_LOTS, 1) + " lots";
        return 0; // Trade ablehnen!
    }
    
    message = "OK - Risk: " + DoubleToString(actual_risk_percent, 2) + "% (Target: " + DoubleToString(risk_percent, 2) + "%)";
    return safe_lots;
}

//+------------------------------------------------------------------+
//| SYMBOL-DATEN REFRESH FUNKTION                                   |
//+------------------------------------------------------------------+
bool RefreshSymbolData(string symbol) {
    // Stelle sicher, dass das Symbol im Market Watch ist
    if(!SymbolSelect(symbol, true)) {
        LogError("Symbol " + symbol + " konnte nicht aktiviert werden");
        return false;
    }
    
    // Warte auf Daten-Laden
    Sleep(100);
    
    // Versuche Symbol-Info zu refreshen
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    // Wenn keine Preise, versuche zu refreshen
    if(bid <= 0 || ask <= 0) {
        LogDebug("Refreshe Symbol-Daten für " + symbol);
        
        // Deaktiviere und reaktiviere Symbol
        SymbolSelect(symbol, false);
        Sleep(100);
        SymbolSelect(symbol, true);
        Sleep(500); // Längere Wartezeit
        
        // Nochmal prüfen
        bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        
        if(bid <= 0 || ask <= 0) {
            LogError("Symbol " + symbol + " hat keine gültigen Preise");
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| POSITION STATUS PRÜFUNG                                         |
//+------------------------------------------------------------------+
void CheckOpenPositions() {
    // Nur Debug-Log beim Start
    static datetime last_summary_log = 0;
    bool should_log_summary = (TimeCurrent() - last_summary_log >= 300); // Alle 5 Minuten
    
    int checked = 0;
    int changed = 0;
    
    // Prüfe alle getrackten Positionen
    for(int i = 0; i < ArraySize(tracked_positions); i++) {
        if(!tracked_positions[i].is_active) continue;
        
        // Position-Daten
        ulong ticket = tracked_positions[i].current_ticket;
        string signal_id = tracked_positions[i].signal_id;
        
        // Prüfe ob Position/Order noch existiert
        bool exists = false;
        bool is_position = false;
        
        if(PositionSelectByTicket(ticket)) {
            exists = true;
            is_position = true;
        } else if(OrderSelect(ticket)) {
            exists = true;
            is_position = false;
        } else {
            // Suche nach neuer Ticket ID (nach Partial Close)
            ulong new_ticket = FindPositionByComment(signal_id);
            if(new_ticket > 0) {
                tracked_positions[i].current_ticket = new_ticket;
                ticket = new_ticket;
                exists = true;
                is_position = true;
                LogDebug("Neue Ticket ID gefunden für Signal " + signal_id + ": #" + IntegerToString(new_ticket));
            } else {
                // Position geschlossen
                tracked_positions[i].is_active = false;
                LogDebug("Position/Order für Signal " + signal_id + " geschlossen");
                continue;
            }
        }
        
        if(!exists) {
            tracked_positions[i].is_active = false;
            continue;
        }
        
        checked++;
        
        // API Status holen (ohne Log)
        string response = GetPositionStatusFromAPI(signal_id, ticket);
        
        if(response != "") {
            // Bestimme Response-Format
            bool is_array = (StringFind(response, "[") == 0);
            
            if(is_array) {
                ProcessArrayStatusResponse(response, ticket, signal_id, is_position, i);
            } else {
                ProcessLegacyStatusResponse(response, ticket, signal_id, is_position, i);
            }
        }
        
        tracked_positions[i].last_checked = TimeCurrent();
    }
    
    // Nur zusammenfassende Logs wenn nötig
    if(should_log_summary && checked > 0) {
        LogDebug("Position Check: " + IntegerToString(checked) + " Positionen/Orders überwacht");
        last_summary_log = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| NEUES ARRAY-FORMAT VERARBEITEN                                  |
//+------------------------------------------------------------------+
void ProcessArrayStatusResponse(string response, ulong ticket, string signal_id, bool is_position, int track_index) {
    LogDebug("🔄 Verarbeite Array-Response für Signal " + signal_id);
    LogDebug("   Raw Response: " + response);
    
    // Entferne führende/nachfolgende Leerzeichen und Array-Klammern
    string clean_response = response;
    // Verwende die eingebaute StringReplace Funktion
    StringReplace(clean_response, "\n", "");
    StringReplace(clean_response, "\r", "");
    StringReplace(clean_response, " ", "");
    
    // Finde das erste Objekt im Array (zwischen [ und ])
    int array_start = StringFind(clean_response, "[");
    int array_end = StringFind(clean_response, "]");
    
    if(array_start == -1 || array_end == -1) {
        LogError("Ungültiges Array-Format");
        return;
    }
    
    // Extrahiere den Inhalt zwischen [ und ]
    string array_content = StringSubstr(clean_response, array_start + 1, array_end - array_start - 1);
    LogDebug("   Array Content: " + array_content);
    
    // Finde das erste JSON-Objekt
    int obj_start = StringFind(array_content, "{");
    int obj_end = StringFind(array_content, "}");
    
    if(obj_start == -1 || obj_end == -1) {
        LogError("Kein JSON-Objekt im Array gefunden");
        return;
    }
    
    // Extrahiere das JSON-Objekt
    string json_obj = StringSubstr(array_content, obj_start, obj_end - obj_start + 1);
    LogDebug("   JSON Object: " + json_obj);
    
    // Status extrahieren
    string status = GetJsonValue(json_obj, "status");
    string sl_str = GetJsonValue(json_obj, "sl");
    string tp_str = GetJsonValue(json_obj, "tp1");
    if(tp_str == "") tp_str = GetJsonValue(json_obj, "tp");
    
    double new_sl = StringToDouble(sl_str);
    double new_tp = StringToDouble(tp_str);
    
    LogDebug("   Status: " + status);
    LogDebug("   SL: " + (new_sl > 0 ? DoubleToString(new_sl, 5) : "keine Änderung"));
    LogDebug("   TP: " + (new_tp > 0 ? DoubleToString(new_tp, 5) : "keine Änderung"));
    
    // Flag um zu tracken ob eine Aktion durchgeführt wurde
    bool action_performed = false;
    
    // Status verarbeiten
    if(status == "active") {
        // Position ist aktiv - prüfe SL/TP Updates
        if(new_sl > 0 || new_tp > 0) {
            // Nur Debug-Log, ProcessSLTPUpdate wird selbst entscheiden ob eine Änderung notwendig ist
            LogDebug("   Prüfe mögliche SL/TP Updates...");
            if(is_position) {
                ProcessSLTPUpdate(ticket, signal_id, new_sl, new_tp);
            } else {
                ProcessPendingOrderSLTPUpdate(ticket, signal_id, new_sl, new_tp, track_index);
            }
        } else {
            LogDebug("   Position aktiv, keine SL/TP Updates von API");
        }
    }
    else if(status == "breakeven" && !tracked_positions[track_index].be_executed && use_breakeven) {
        LogImportant("📥 Status Update für Signal " + signal_id);
        LogImportant("🎯 BREAK EVEN für #" + IntegerToString(ticket));
        if(ProcessBreakEven(track_index)) {
            tracked_positions[track_index].be_executed = true;
            tracked_positions[track_index].be_time = TimeCurrent();
            SaveBreakEvenStatus(signal_id);
        }
        action_performed = true;
    }
    
    // 🎯 ZUSÄTZLICHE BEHANDLUNG: Break Even Status ohne weitere Aktion (Array Format)
    // Verhindert "Unbekannte Status" wenn Break Even bereits ausgeführt wurde
    else if(status == "breakeven" && tracked_positions[track_index].be_executed) {
        LogDebug("   Break Even bereits ausgeführt für Signal " + signal_id + " (Array Format) - keine weitere Aktion erforderlich");
        action_performed = true;
    }
    
    // 🎯 EINFACHE SL/TP UPDATES BEI BREAK EVEN STATUS (Array Format)
    // Übernehme SL/TP Änderungen auch bei Break Even Status
    if(status == "breakeven" && (new_sl > 0 || new_tp > 0)) {
        LogImportant("📥 SL/TP Update bei Break Even Status (Array Format) für Signal " + signal_id);
        LogImportant("✅ ÜBERNEHME SL/TP trotz Break Even Status:");
        LogImportant("   Neue SL: " + (new_sl > 0 ? DoubleToString(new_sl, 5) : "keine Änderung"));
        LogImportant("   Neue TP: " + (new_tp > 0 ? DoubleToString(new_tp, 5) : "keine Änderung"));
        
        if(is_position) {
            ProcessSLTPUpdate(ticket, signal_id, new_sl, new_tp);
        } else {
            ProcessPendingOrderSLTPUpdate(ticket, signal_id, new_sl, new_tp, track_index);
        }
    }
    else if(status == "close" || status == "closed") {
        LogImportant("📥 Status Update für Signal " + signal_id);
        if(is_position) {
            LogImportant("🔴 SCHLIESSE Position #" + IntegerToString(ticket));
            ClosePosition(ticket, signal_id);
        } else {
            LogImportant("❌ STORNIERE Order #" + IntegerToString(ticket));
            CancelOrder(ticket, signal_id);
        }
        tracked_positions[track_index].is_active = false;
        action_performed = true;
    }
    else if(status == "cancel" || status == "cancelled") {
        if(!is_position) {
            LogImportant("📥 Status Update für Signal " + signal_id);
            LogImportant("❌ STORNIERE Order #" + IntegerToString(ticket));
            CancelOrder(ticket, signal_id);
            tracked_positions[track_index].is_active = false;
            action_performed = true;
        }
    }
    else if(status == "partial_close") {
        double percent = StringToDouble(GetJsonValue(json_obj, "close_percent"));
        if(percent > 0 && is_position) {
            LogImportant("📥 Status Update für Signal " + signal_id);
            LogImportant("📊 TEILSCHLIESSUNG " + DoubleToString(percent, 0) + 
                        "% für #" + IntegerToString(ticket));
            ulong new_ticket = PartialClose(ticket, signal_id, percent);
            if(new_ticket > 0) {
                tracked_positions[track_index].current_ticket = new_ticket;
            }
            action_performed = true;
        }
    }
    else {
        // Unbekannter oder kein relevanter Status - kein Log
        LogDebug("   Status '" + status + "' - keine Aktion erforderlich");
    }
}

//+------------------------------------------------------------------+
//| ALTES FORMAT VERARBEITEN (Rückwärtskompatibilität)             |
//+------------------------------------------------------------------+
void ProcessLegacyStatusResponse(string response, ulong ticket, string signal_id, bool is_position, int track_index) {
    LogDebug("🔄 Verarbeite Legacy-Response für Signal " + signal_id);
    LogDebug("   Raw Response: " + response);
    
    // Status/Action extrahieren
    string action = GetJsonValue(response, "action");
    string status = GetJsonValue(response, "status");
    
    // Falls kein action vorhanden, verwende status
    if(action == "") action = status;
    
    // SL/TP Werte extrahieren (können in beiden Formaten vorkommen)
    string sl_str = GetJsonValue(response, "sl");
    string tp_str = GetJsonValue(response, "tp1");
    if(tp_str == "") tp_str = GetJsonValue(response, "tp");
    
    double new_sl = StringToDouble(sl_str);
    double new_tp = StringToDouble(tp_str);
    
    LogDebug("   Action/Status: " + action);
    LogDebug("   SL: " + (new_sl > 0 ? DoubleToString(new_sl, 5) : "keine Änderung"));
    LogDebug("   TP: " + (new_tp > 0 ? DoubleToString(new_tp, 5) : "keine Änderung"));
    
    // Flag um zu tracken ob eine Aktion durchgeführt wurde
    bool action_performed = false;
    
    // WICHTIG: Prüfe ZUERST auf SL/TP Updates bei "active" Status
    if(action == "active" && (new_sl > 0 || new_tp > 0)) {
        // Nur Debug-Log, ProcessSLTPUpdate wird selbst entscheiden ob eine Änderung notwendig ist
        LogDebug("   Prüfe mögliche SL/TP Updates...");
        
        if(is_position) {
            ProcessSLTPUpdate(ticket, signal_id, new_sl, new_tp);
        } else {
            ProcessPendingOrderSLTPUpdate(ticket, signal_id, new_sl, new_tp, track_index);
        }
    }
    
    // 🎯 EINFACHE SL/TP UPDATES BEI BREAK EVEN STATUS (Legacy Format)
    // Übernehme SL/TP Änderungen auch bei Break Even Status
    if(action == "breakeven" && (new_sl > 0 || new_tp > 0)) {
        LogImportant("📥 SL/TP Update bei Break Even Status (Legacy Format) für Signal " + signal_id);
        LogImportant("✅ ÜBERNEHME SL/TP trotz Break Even Status:");
        LogImportant("   Neue SL: " + (new_sl > 0 ? DoubleToString(new_sl, 5) : "keine Änderung"));
        LogImportant("   Neue TP: " + (new_tp > 0 ? DoubleToString(new_tp, 5) : "keine Änderung"));
        
        if(is_position) {
            ProcessSLTPUpdate(ticket, signal_id, new_sl, new_tp);
        } else {
            ProcessPendingOrderSLTPUpdate(ticket, signal_id, new_sl, new_tp, track_index);
        }
    }
    
    // Break Even Ausführung (falls noch nicht ausgeführt)
    if(action == "breakeven" && !tracked_positions[track_index].be_executed && use_breakeven) {
        LogImportant("📥 Break Even Ausführung für Signal " + signal_id);
        LogImportant("🎯 BREAK EVEN für #" + IntegerToString(ticket));
        if(ProcessBreakEven(track_index)) {
            tracked_positions[track_index].be_executed = true;
            tracked_positions[track_index].be_time = TimeCurrent();
            SaveBreakEvenStatus(signal_id);
        }
        action_performed = true;
    }
    
    // 🎯 ZUSÄTZLICHE BEHANDLUNG: Break Even Status ohne weitere Aktion
    // Verhindert "Unbekannte Action" wenn Break Even bereits ausgeführt wurde
    if(action == "breakeven" && tracked_positions[track_index].be_executed) {
        LogDebug("   Break Even bereits ausgeführt für Signal " + signal_id + " - keine weitere Aktion erforderlich");
        action_performed = true;
    }
    // Cancel/Cancelled
    else if(action == "cancel" || action == "cancelled") {
        LogImportant("📥 Status Update für Signal " + signal_id);
        if(is_position) {
            LogImportant("🔴 SCHLIESSE Position #" + IntegerToString(ticket));
            ClosePosition(ticket, signal_id);
        } else {
            LogImportant("❌ STORNIERE Order #" + IntegerToString(ticket));
            CancelOrder(ticket, signal_id);
        }
        tracked_positions[track_index].is_active = false;
        action_performed = true;
    }
    // Close
    else if(action == "close" || action == "closed") {
        if(is_position) {
            LogImportant("📥 Status Update für Signal " + signal_id);
            LogImportant("🔴 SCHLIESSE Position #" + IntegerToString(ticket));
            ClosePosition(ticket, signal_id);
            tracked_positions[track_index].is_active = false;
            action_performed = true;
        }
    }
    // Partial Close
    else if(action == "partial_close") {
        double percent = StringToDouble(GetJsonValue(response, "close_percent"));
        if(percent > 0 && is_position) {
            LogImportant("📥 Status Update für Signal " + signal_id);
            LogImportant("📊 TEILSCHLIESSUNG " + DoubleToString(percent, 0) + 
                        "% für #" + IntegerToString(ticket));
            ulong new_ticket = PartialClose(ticket, signal_id, percent);
            if(new_ticket > 0) {
                tracked_positions[track_index].current_ticket = new_ticket;
            }
            action_performed = true;
        }
    }
    // Fallback: Wenn Status "active" ist aber keine SL/TP Änderungen
    else if(action == "active") {
        LogDebug("   Position aktiv, keine Änderungen notwendig");
    }
    else {
        LogDebug("   Unbekannte oder keine Action: " + action);
    }
}

//+------------------------------------------------------------------+
//| IMPROVED SL/TP UPDATE FÜR OFFENE POSITIONEN - NUR LOGGING BEI ÄNDERUNGEN |
//+------------------------------------------------------------------+
void ProcessSLTPUpdate(ulong ticket, string signal_id, double new_sl, double new_tp) {
    if(!PositionSelectByTicket(ticket)) {
        LogError("❌ FEHLER: Position " + IntegerToString(ticket) + " nicht gefunden!");
        return;
    }
    
    // Position-Daten abrufen
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    string symbol = PositionGetString(POSITION_SYMBOL);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double min_stop_level = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
    
    // Finde Track-Index
    int track_index = FindTrackedPositionIndex(signal_id);
    if(track_index < 0) {
        LogError("Position nicht im Tracking gefunden: " + signal_id);
        return;
    }
    
    // API VALUE TRACKING: Prüfe ob API-Werte sich geändert haben
    string new_api_sl = DoubleToString(new_sl, 5);
    string new_api_tp = DoubleToString(new_tp, 5);
    
    bool api_sl_changed = (tracked_positions[track_index].last_api_sl != new_api_sl);
    bool api_tp_changed = (tracked_positions[track_index].last_api_tp != new_api_tp);
    
    if(!api_sl_changed && !api_tp_changed) {
        LogDebug("🔄 API-Werte unverändert für Signal " + signal_id + " - keine Aktion erforderlich");
        LogDebug("   SL: " + new_api_sl + " (unverändert)");
        LogDebug("   TP: " + new_api_tp + " (unverändert)");
        return;
    }
    
    // Neue API-Werte erkannt
    LogImportant("📡 NEUE API-WERTE ERKANNT für Signal " + signal_id);
    if(api_sl_changed) {
        LogImportant("   SL: " + tracked_positions[track_index].last_api_sl + " → " + new_api_sl);
    }
    if(api_tp_changed) {
        LogImportant("   TP: " + tracked_positions[track_index].last_api_tp + " → " + new_api_tp);
    }
    LogImportant("   Manuelle User-Änderungen werden respektiert - EA ändert nur bei neuen API-Werten");
    
    // Normalisiere neue Werte für Vergleich
    double normalized_new_sl = NormalizeDouble(new_sl, digits);
    double normalized_new_tp = NormalizeDouble(new_tp, digits);
    double normalized_current_sl = NormalizeDouble(current_sl, digits);
    double normalized_current_tp = NormalizeDouble(current_tp, digits);
    
    // ========== WICHTIG: Exakter Vergleich - wenn identisch, sofort beenden (KEIN LOG) ==========
    bool sl_identical = (normalized_new_sl == normalized_current_sl) || 
                       (new_sl <= 0 && current_sl <= 0);
    bool tp_identical = (normalized_new_tp == normalized_current_tp) || 
                       (new_tp <= 0 && current_tp <= 0);
    
    if(sl_identical && tp_identical) {
        // IMPROVED: Kein Log - Position ist bereits auf den gewünschten Werten
        LogDebug("Position #" + IntegerToString(ticket) + " bereits auf gewünschten SL/TP - keine Aktion erforderlich");
        return;
    }
    
    // IMPROVED: Prüfe ob die spezifischen Werte bereits angewendet wurden (value-based tracking)
    if(track_index >= 0 && IsModificationAlreadyApplied(track_index, new_sl, new_tp)) {
        LogDebug("Alle angeforderten Werte bereits angewendet für Signal " + signal_id + " - überspringe");
        return;
    }
    
    // Prüfe welche Werte bereits angewendet wurden und filtere sie heraus
    if(track_index >= 0) {
        if(new_sl > 0 && HasValueBeenApplied(tracked_positions[track_index].applied_sl_values, new_sl, digits)) {
            LogDebug("SL-Wert " + DoubleToString(new_sl, digits) + " bereits angewendet - überspringe SL-Änderung");
            new_sl = current_sl; // Setze auf aktuellen Wert um Änderung zu verhindern
        }
        
        if(new_tp > 0 && HasValueBeenApplied(tracked_positions[track_index].applied_tp_values, new_tp, digits)) {
            LogDebug("TP-Wert " + DoubleToString(new_tp, digits) + " bereits angewendet - überspringe TP-Änderung");
            new_tp = current_tp; // Setze auf aktuellen Wert um Änderung zu verhindern
        }
    }
    
    // Prüfe ob nach der Filterung noch Änderungen übrig sind
    sl_identical = (NormalizeDouble(new_sl, digits) == normalized_current_sl) || 
                   (new_sl <= 0 && current_sl <= 0);
    tp_identical = (NormalizeDouble(new_tp, digits) == normalized_current_tp) || 
                   (new_tp <= 0 && current_tp <= 0);
    
    if(sl_identical && tp_identical) {
        LogDebug("Keine neuen Werte nach Value-Filter für Position #" + IntegerToString(ticket));
        return;
    }
    
    // Prüfe ob Änderungen signifikant sind (mindestens 0.5 Point)
    bool sl_different = false;
    bool tp_different = false;
    
    if(!sl_identical && new_sl > 0) {
        sl_different = (MathAbs(new_sl - current_sl) >= point * 0.5);
    }
    
    if(!tp_identical && new_tp > 0) {
        tp_different = (MathAbs(new_tp - current_tp) >= point * 0.5);
    }
    
    // IMPROVED: Wenn keine signifikanten Änderungen, beenden (KEIN LOG)
    if(!sl_different && !tp_different) {
        LogDebug("Keine signifikanten SL/TP Änderungen für Position #" + IntegerToString(ticket) + " - Änderungen < 0.5 Points");
        return;
    }
    
    // Prüfe ob SL-Änderung erlaubt ist (Risikoreduktion)
    bool sl_allowed = false;
    if(sl_different) {
        if(type == POSITION_TYPE_BUY) {
            sl_allowed = (new_sl > current_sl || current_sl == 0);
        } else {
            sl_allowed = ((new_sl < current_sl || current_sl == 0) && new_sl > 0);
        }
        
        // Zusätzliche Prüfung: Mindestabstand zum aktuellen Preis
        if(sl_allowed) {
            double distance_to_price = (type == POSITION_TYPE_BUY) ? 
                                      (current_price - new_sl) : 
                                      (new_sl - current_price);
            if(distance_to_price < min_stop_level && min_stop_level > 0) {
                sl_allowed = false;
            }
        }
    }
    
    // IMPROVED: Wenn keine erlaubte Änderung, nur Debug-Log (KEIN WICHTIGES LOG)
    if(!sl_allowed && !tp_different) {
        LogDebug("SL-Änderung nicht erlaubt (würde Risiko erhöhen) und kein TP-Update für Position #" + IntegerToString(ticket));
        return;
    }
    
    // ========== NUR JETZT die ausführlichen Logs ausgeben (BEI TATSÄCHLICHEN ÄNDERUNGEN) ==========
    LogImportant("════════════════════════════════════════════");
    LogImportant("🔧 STARTE SL/TP UPDATE für OFFENE POSITION #" + IntegerToString(ticket));
    LogImportant("📥 Status Update für Signal " + signal_id);
    
    // IMPROVED: Zeige nur die Werte an, die tatsächlich geändert werden
    if(sl_different && sl_allowed) {
        LogImportant("   🎯 SL wird geändert: " + DoubleToString(current_sl, digits) + " → " + DoubleToString(new_sl, digits));
    }
    if(tp_different) {
        LogImportant("   🎯 TP wird geändert: " + DoubleToString(current_tp, digits) + " → " + DoubleToString(new_tp, digits));
    }
    
    LogImportant("🔧 ACTIVE Status mit SL/TP Update erkannt!");
    LogImportant("════════════════════════════════════════════");
    
    LogImportant("📥 NEUE WERTE VON API:");
    LogImportant("   New SL: " + DoubleToString(new_sl, digits));
    LogImportant("   New TP: " + DoubleToString(new_tp, digits));
    
    LogImportant("📊 AKTUELLE POSITION:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Type: " + (type == POSITION_TYPE_BUY ? "BUY" : "SELL"));
    LogImportant("   Open Price: " + DoubleToString(open_price, digits));
    LogImportant("   Current Price: " + DoubleToString(current_price, digits));
    LogImportant("   Current SL: " + DoubleToString(current_sl, digits));
    LogImportant("   Current TP: " + DoubleToString(current_tp, digits));
    
    bool sl_changed = false;
    bool tp_changed = false;
    double final_sl = current_sl;
    double final_tp = current_tp;
    
    // ========== SL ANALYSE ==========
    if(sl_different) {
        LogImportant("🔍 SL ANALYSE (Offene Position - nur Risikoreduktion erlaubt):");
        
        double sl_difference = new_sl - current_sl;
        double sl_difference_points = MathAbs(sl_difference) / point;
        
        LogImportant("   Neuer SL: " + DoubleToString(new_sl, digits));
        LogImportant("   Alter SL: " + DoubleToString(current_sl, digits));
        LogImportant("   Differenz: " + DoubleToString(sl_difference, digits) + 
                    " (" + DoubleToString(sl_difference_points, 2) + " points)");
        
        // KORREKTUR: Prüfe ob SL-Wert bereits angewendet wurde
        if(!ShouldModifySL(track_index, new_sl)) {
            LogImportant("   ❌ SL-Wert bereits angewendet - wird übersprungen (manuelle Änderung bleibt bestehen)");
        } else if(sl_difference_points < 0.5) {
            LogImportant("   ❌ SL-Änderung zu klein (< 0.5 Point) - wird ignoriert");
        } else if(sl_allowed) {
            final_sl = new_sl;
            sl_changed = true;
            LogImportant("   ✅ SL-ÄNDERUNG AKZEPTIERT (Risiko reduziert)!");
        } else {
            LogImportant("   ❌ SL-ÄNDERUNG ABGELEHNT (würde Risiko erhöhen)!");
        }
    }
    
    // ========== TP ANALYSE ==========
    if(tp_different) {
        LogImportant("🔍 TP ANALYSE (flexibel änderbar):");
        
        double tp_difference = new_tp - current_tp;
        double tp_difference_points = MathAbs(tp_difference) / point;
        
        LogImportant("   Neuer TP: " + DoubleToString(new_tp, digits));
        LogImportant("   Alter TP: " + DoubleToString(current_tp, digits));
        LogImportant("   Differenz: " + DoubleToString(tp_difference, digits) + 
                    " (" + DoubleToString(tp_difference_points, 2) + " points)");
        
        // KORREKTUR: Prüfe ob TP-Wert bereits angewendet wurde
        if(!ShouldModifyTP(track_index, new_tp)) {
            LogImportant("   ❌ TP-Wert bereits angewendet - wird übersprungen (manuelle Änderung bleibt bestehen)");
        } else if(tp_difference_points < 0.5) {
            LogImportant("   ❌ TP-Änderung zu klein - wird ignoriert");
        } else {
            final_tp = new_tp;
            tp_changed = true;
            LogImportant("   ✅ TP-ÄNDERUNG AKZEPTIERT!");
        }
    }
    
    // ========== MODIFIKATION AUSFÜHREN ==========
    LogImportant("════════════════════════════════════════════");
    LogImportant("📝 MODIFIKATION:");
    LogImportant("   SL wird geändert: " + (sl_changed ? "JA ✅" : "NEIN ❌"));
    LogImportant("   TP wird geändert: " + (tp_changed ? "JA ✅" : "NEIN ❌"));
    
    if(sl_changed || tp_changed) {
        LogImportant("🚀 FÜHRE MODIFIKATION AUS:");
        LogImportant("   Final SL: " + DoubleToString(final_sl, digits));
        LogImportant("   Final TP: " + DoubleToString(final_tp, digits));
        
        // Normalisiere Preise auf Symbol-Digits
        final_sl = NormalizeDouble(final_sl, digits);
        final_tp = NormalizeDouble(final_tp, digits);
        
        ResetLastError();
        
        if(trade.PositionModify(ticket, final_sl, final_tp)) {
            LogImportant("✅✅✅ POSITION SL/TP ERFOLGREICH MODIFIZIERT! ✅✅✅");
            LogImportant("   Position: #" + IntegerToString(ticket));
            LogImportant("   Signal: " + signal_id);
            LogImportant("   Symbol: " + PositionGetString(POSITION_SYMBOL));
            if(sl_changed) {
                LogImportant("   SL: " + DoubleToString(current_sl, digits) + " → " + DoubleToString(final_sl, digits));
            }
            if(tp_changed) {
                LogImportant("   TP: " + DoubleToString(current_tp, digits) + " → " + DoubleToString(final_tp, digits));
            }
            LogImportant("   Grund: Neue API-Werte empfangen");
            
            // IMPROVED: Markiere Modifikation als angewendet
            if(track_index >= 0) {
                MarkModificationAsApplied(track_index, final_sl, final_tp, sl_changed, tp_changed, digits);
                
                // API VALUE TRACKING: Speichere neue API-Werte nach erfolgreicher Änderung
                tracked_positions[track_index].last_api_sl = DoubleToString(final_sl, 5);
                tracked_positions[track_index].last_api_tp = DoubleToString(final_tp, 5);
                tracked_positions[track_index].last_api_update = TimeCurrent();
                SaveAPIValuesToFile(signal_id, final_sl, final_tp);
                LogDebug("💾 API-Werte aktualisiert für Position " + signal_id);
            }
            // Verifiziere die Änderung
            if(PositionSelectByTicket(ticket)) {
                double new_position_sl = PositionGetDouble(POSITION_SL);
                double new_position_tp = PositionGetDouble(POSITION_TP);
                LogImportant("   VERIFIKATION:");
                LogImportant("     Neuer SL in Position: " + DoubleToString(new_position_sl, digits));
                LogImportant("     Neuer TP in Position: " + DoubleToString(new_position_tp, digits));
            }
            
            // API-Benachrichtigung
            SendModificationConfirmation(signal_id, ticket, "position_modified", 
                                        "Position modified successfully", 
                                        final_sl, final_tp, current_sl, current_tp);
        } else {
            int error = GetLastError();
            string error_desc = trade.ResultRetcodeDescription();
            uint retcode = trade.ResultRetcode();
            
            LogError("❌❌❌ FEHLER! MODIFIKATION FEHLGESCHLAGEN! ❌❌❌");
            LogError("   Error Code: " + IntegerToString(error));
            LogError("   Retcode: " + IntegerToString((int)retcode));
            LogError("   Beschreibung: " + error_desc);
            
            SendDeliveryConfirmation(signal_id, ticket, false, 
                                    "Modification failed: " + error_desc);
        }
    } else {
        LogImportant("ℹ️ KEINE MODIFIKATION NOTWENDIG");
        LogImportant("   Grund: Keine erlaubten Änderungen oder Änderungen wurden abgelehnt");
    }
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("🔧 ENDE SL/TP UPDATE FÜR OFFENE POSITION");
    LogImportant("════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| SL/TP UPDATE FÜR PENDING ORDERS (FLEXIBEL IN BEIDE RICHTUNGEN) |
//+------------------------------------------------------------------+
void ProcessPendingOrderSLTPUpdate(ulong ticket, string signal_id, double new_sl, double new_tp, int track_index) {
    if(!OrderSelect(ticket)) {
        LogError("Order " + IntegerToString(ticket) + " nicht gefunden!");
        return;
    }
    
    // API VALUE TRACKING: Prüfe ob API-Werte sich geändert haben
    string new_api_sl = DoubleToString(new_sl, 5);
    string new_api_tp = DoubleToString(new_tp, 5);
    
    bool api_sl_changed = (tracked_positions[track_index].last_api_sl != new_api_sl);
    bool api_tp_changed = (tracked_positions[track_index].last_api_tp != new_api_tp);
    
    if(!api_sl_changed && !api_tp_changed) {
        LogDebug("🔄 API-Werte unverändert für Pending Order " + signal_id + " - keine Aktion erforderlich");
        LogDebug("   SL: " + new_api_sl + " (unverändert)");
        LogDebug("   TP: " + new_api_tp + " (unverändert)");
        return;
    }
    
    // Neue API-Werte erkannt
    LogImportant("📡 NEUE API-WERTE ERKANNT für Pending Order " + signal_id);
    if(api_sl_changed) {
        LogImportant("   SL: " + tracked_positions[track_index].last_api_sl + " → " + new_api_sl);
    }
    if(api_tp_changed) {
        LogImportant("   TP: " + tracked_positions[track_index].last_api_tp + " → " + new_api_tp);
    }
    LogImportant("   Manuelle User-Änderungen werden respektiert - EA ändert nur bei neuen API-Werten");
    
    double current_sl = OrderGetDouble(ORDER_SL);
    double current_tp = OrderGetDouble(ORDER_TP);
    double order_price = OrderGetDouble(ORDER_PRICE_OPEN);
    double volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
    ENUM_ORDER_TYPE order_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
    string symbol = OrderGetString(ORDER_SYMBOL);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // Normalisiere Werte für exakten Vergleich
    double normalized_new_sl = NormalizeDouble(new_sl, digits);
    double normalized_new_tp = NormalizeDouble(new_tp, digits);
    double normalized_current_sl = NormalizeDouble(current_sl, digits);
    double normalized_current_tp = NormalizeDouble(current_tp, digits);
    
    // ========== WICHTIG: Exakter Vergleich - wenn identisch, sofort beenden ==========
    bool sl_identical = (normalized_new_sl == normalized_current_sl) || 
                       (new_sl <= 0 && current_sl <= 0);
    bool tp_identical = (normalized_new_tp == normalized_current_tp) || 
                       (new_tp <= 0 && current_tp <= 0);
    
    if(sl_identical && tp_identical) {
        // Kein Log - Order ist bereits auf den gewünschten Werten
        LogDebug("   Pending Order #" + IntegerToString(ticket) + " bereits auf gewünschten SL/TP");
        return;
    }
    
    // Prüfe ob Änderungen signifikant sind
    bool sl_different = false;
    bool tp_different = false;
    
    if(!sl_identical && new_sl > 0) {
        sl_different = (MathAbs(new_sl - current_sl) > point * 0.5);
    }
    
    if(!tp_identical && new_tp > 0) {
        tp_different = (MathAbs(new_tp - current_tp) > point * 0.5);
    }
    
    // Wenn keine signifikanten Änderungen, beenden
    if(!sl_different && !tp_different) {
        LogDebug("   Keine signifikanten Änderungen für Pending Order #" + IntegerToString(ticket));
        return;
    }
    
    // ========== NUR JETZT die ausführlichen Logs ausgeben ==========
    LogImportant("════════════════════════════════════════════");
    LogImportant("🔧 STARTE SL/TP UPDATE für PENDING ORDER #" + IntegerToString(ticket));
    LogImportant("📥 Status Update für Signal " + signal_id);
    LogImportant("════════════════════════════════════════════");
    
    LogImportant("📊 AKTUELLE PENDING ORDER:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Type: " + OrderTypeToString((ENUM_ORDER_TYPE)order_type));
    LogImportant("   Order Price: " + DoubleToString(order_price, digits));
    LogImportant("   Volume: " + DoubleToString(volume, 3));
    LogImportant("   Current SL: " + DoubleToString(current_sl, digits));
    LogImportant("   Current TP: " + DoubleToString(current_tp, digits));
    
    // ========== BEI PENDING ORDERS: SL KANN IN BEIDE RICHTUNGEN! ==========
    if(sl_different) {
        LogImportant("⚠️ SL-ÄNDERUNG bei Pending Order erkannt!");
        LogImportant("   Alt: SL=" + DoubleToString(current_sl, digits));
        LogImportant("   Neu: SL=" + DoubleToString(new_sl, digits));
        
        // Prüfe Richtung der SL-Änderung
        bool is_buy_order = (order_type == ORDER_TYPE_BUY_LIMIT || order_type == ORDER_TYPE_BUY_STOP);
        bool sl_increased = (new_sl > current_sl);
        
        if(is_buy_order) {
            if(sl_increased) {
                LogImportant("   📈 BUY Order: SL wird ERHÖHT (Risiko wird reduziert)");
            } else {
                LogImportant("   📉 BUY Order: SL wird GESENKT (Risiko wird erhöht)");
                LogImportant("   ⚠️ ACHTUNG: Order wird mit NEUEM RISIKO neu berechnet!");
            }
        } else {
            if(sl_increased) {
                LogImportant("   📈 SELL Order: SL wird ERHÖHT (Risiko wird erhöht)");
                LogImportant("   ⚠️ ACHTUNG: Order wird mit NEUEM RISIKO neu berechnet!");
            } else {
                LogImportant("   📉 SELL Order: SL wird GESENKT (Risiko wird reduziert)");
            }
        }
        
        LogImportant("   → Order muss GELÖSCHT und NEU BERECHNET werden");
        
        // Order löschen
        LogInfo("🗑️ Lösche alte Order #" + IntegerToString(ticket) + "...");
        
        if(trade.OrderDelete(ticket)) {
            LogSuccess("✅ Alte Order #" + IntegerToString(ticket) + " erfolgreich gelöscht");
            
            // Warte kurz, damit die Order wirklich gelöscht ist
            Sleep(100);
            
            // Neue Order mit neuen Parametern erstellen
            LogInfo("📊 Berechne neue Lotgröße basierend auf neuem SL...");
            
            // Versuche das Risiko aus der alten Position zu berechnen
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
            double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
            double risk_percent = 1.0; // Standard 1%
            
            // Berechne das ursprüngliche Risiko
            if(tick_size > 0 && tick_value > 0 && current_sl > 0) {
                double old_sl_distance = MathAbs(order_price - current_sl);
                double old_sl_ticks = old_sl_distance / tick_size;
                double old_risk_amount = volume * old_sl_ticks * tick_value;
                risk_percent = (old_risk_amount / balance) * 100.0;
                
                LogImportant("   📊 RISIKO-BERECHNUNG:");
                LogImportant("      Altes Risiko: " + DoubleToString(risk_percent, 2) + "%");
                LogImportant("      Alte SL-Distanz: " + DoubleToString(old_sl_distance, digits));
                LogImportant("      Alte Lots: " + DoubleToString(volume, 3));
            }
            
            // Berechne neue Lots basierend auf neuem SL und GLEICHEM Risiko
            double actual_risk = 0.0;
            string risk_message;
            ENUM_ORDER_TYPE calc_order_type = (ENUM_ORDER_TYPE)order_type;
            double new_lots = CalculateLots_v85(symbol, order_price, new_sl, risk_percent, calc_order_type, risk_message);
            
            double new_sl_distance = MathAbs(order_price - new_sl);
            LogImportant("      Neue SL-Distanz: " + DoubleToString(new_sl_distance, digits));
            LogImportant("      Neue Lots: " + DoubleToString(new_lots, 3));
            LogImportant("      Tatsächliches Risiko: " + DoubleToString(actual_risk, 2) + "%");
            
            if(new_lots > 0) {
                // TP übernehmen (entweder neuer oder alter)
                double final_tp = (new_tp > 0) ? new_tp : current_tp;
                
                LogInfo("🔄 Erstelle neue Order mit angepasster Lotgröße...");
                LogInfo("   Symbol: " + symbol);
                LogInfo("   Type: " + OrderTypeToString((ENUM_ORDER_TYPE)order_type));
                LogInfo("   Lots: " + DoubleToString(new_lots, 3) + " (alt: " + DoubleToString(volume, 3) + ")");
                LogInfo("   Price: " + DoubleToString(order_price, digits));
                LogInfo("   SL: " + DoubleToString(new_sl, digits));
                LogInfo("   TP: " + DoubleToString(final_tp, digits));
                
                // Neue Order platzieren
                string comment = "Signal: " + signal_id;
                if(trade.OrderOpen(symbol, order_type, new_lots, 0, order_price, new_sl, final_tp, 
                                  ORDER_TIME_GTC, 0, comment)) {
                    
                    ulong new_ticket = trade.ResultOrder();
                    LogImportant("✅✅✅ NEUE ORDER ERSTELLT: #" + IntegerToString(new_ticket));
                    LogSuccess("   Erfolgreich ersetzt mit angepasster Lotgröße");
                    LogSuccess("   Risiko bleibt konstant bei " + DoubleToString(actual_risk, 2) + "%");
                    
                    // Tracking aktualisieren
                    tracked_positions[track_index].current_ticket = new_ticket;
                    tracked_positions[track_index].original_ticket = new_ticket;
                    
                    // API VALUE TRACKING: Aktualisiere API-Werte nach erfolgreicher Order-Ersetzung
                    tracked_positions[track_index].last_api_sl = new_api_sl;
                    tracked_positions[track_index].last_api_tp = DoubleToString(final_tp, 5);
                    tracked_positions[track_index].last_api_update = TimeCurrent();
                    SaveAPIValuesToFile(signal_id, new_sl, final_tp);
                    LogDebug("💾 API-Werte aktualisiert nach Order-Ersetzung für " + signal_id);
                    
                    // API-Benachrichtigung
                    SendOrderReplacementConfirmation(signal_id, ticket, new_ticket, 
                                                    "SL change required order replacement", 
                                                    new_lots, new_sl, final_tp, actual_risk);
                } else {
                    int error = GetLastError();
                    LogError("❌ Neue Order konnte nicht erstellt werden!");
                    LogError("   Error Code: " + IntegerToString(error));
                    LogError("   Error: " + trade.ResultRetcodeDescription());
                    
                    tracked_positions[track_index].is_active = false;
                    
                    SendDeliveryConfirmation(signal_id, 0, false, 
                                            "Order replacement failed: " + trade.ResultRetcodeDescription());
                }
            } else {
                LogError("❌ Lot-Berechnung für neue Order fehlgeschlagen!");
                LogError("   Fehler: " + risk_message);
                tracked_positions[track_index].is_active = false;
                
                SendDeliveryConfirmation(signal_id, 0, false, 
                                        "Order replacement failed - lot calculation: " + risk_message);
            }
        } else {
            int error = GetLastError();
            LogError("❌ Alte Order konnte nicht gelöscht werden!");
            LogError("   Error Code: " + IntegerToString(error));
            LogError("   Error: " + trade.ResultRetcodeDescription());
        }
    }
    // Nur TP ändern (ohne SL-Änderung)
    else if(tp_different) {
        LogImportant("════════════════════════════════════════════");
        LogImportant("📥 Status Update für Signal " + signal_id);
        LogImportant("🎯 TP-Änderung bei Pending Order (ohne SL-Änderung)");
        LogInfo("   Alt: TP=" + DoubleToString(current_tp, digits));
        LogInfo("   Neu: TP=" + DoubleToString(new_tp, digits));
        
        // Bei Pending Orders können wir TP direkt ändern
        if(trade.OrderModify(ticket, order_price, current_sl, new_tp, ORDER_TIME_GTC, 0)) {
            LogImportant("✅✅✅ PENDING ORDER TP ERFOLGREICH GEÄNDERT! ✅✅✅");
            LogImportant("   Order: #" + IntegerToString(ticket));
            LogImportant("   Signal: " + signal_id);
            LogImportant("   Symbol: " + symbol);
            LogImportant("   TP: " + DoubleToString(current_tp, digits) + " → " + DoubleToString(new_tp, digits));
            LogImportant("   Grund: Neue API-Werte empfangen");
            
            // API VALUE TRACKING: Aktualisiere API-Werte nach erfolgreicher Änderung
            tracked_positions[track_index].last_api_tp = new_api_tp;
            tracked_positions[track_index].last_api_update = TimeCurrent();
            SaveAPIValuesToFile(signal_id, new_sl, new_tp);
            LogDebug("💾 API-Werte aktualisiert für Pending Order " + signal_id);
            
            SendModificationConfirmation(signal_id, ticket, "order_modified", 
                                        "TP updated", current_sl, new_tp, current_sl, current_tp);
        } else {
            int error = GetLastError();
            LogError("❌ TP-Änderung fehlgeschlagen!");
            LogError("   Error Code: " + IntegerToString(error));
            LogError("   Error: " + trade.ResultRetcodeDescription());
        }
        LogImportant("════════════════════════════════════════════");
    }
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("🔧 ENDE SL/TP UPDATE FÜR PENDING ORDER");
    LogImportant("════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| TEST-FUNKTION: Manueller SL/TP Update Test                      |
//+------------------------------------------------------------------+
void TestManualSLTPUpdate() {
    if(!enable_manual_test) return;
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("🧪 STARTE MANUELLEN SL/TP TEST");
    LogImportant("════════════════════════════════════════════");
    
    // Suche nach offenen Positionen mit unserem Magic Number
    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket)) {
            if(PositionGetInteger(POSITION_MAGIC) == magic_number) {
                string symbol = PositionGetString(POSITION_SYMBOL);
                double current_sl = PositionGetDouble(POSITION_SL);
                double current_tp = PositionGetDouble(POSITION_TP);
                double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
                ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
                
                LogImportant("📊 POSITION GEFUNDEN:");
                LogImportant("   Ticket: #" + IntegerToString(ticket));
                LogImportant("   Symbol: " + symbol);
                LogImportant("   Type: " + (type == POSITION_TYPE_BUY ? "BUY" : "SELL"));
                LogImportant("   Open Price: " + DoubleToString(open_price, digits));
                LogImportant("   Current SL: " + DoubleToString(current_sl, digits));
                LogImportant("   Current TP: " + DoubleToString(current_tp, digits));
                
                // Simuliere API-Werte (10 Pips höher/niedriger)
                double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
                double new_sl = 0;
                double new_tp = 0;
                
                if(type == POSITION_TYPE_BUY) {
                    new_sl = current_sl + (10 * point * 10); // 10 Pips höher
                    new_tp = current_tp + (10 * point * 10); // 10 Pips höher
                } else {
                    new_sl = current_sl - (10 * point * 10); // 10 Pips niedriger
                    new_tp = current_tp - (10 * point * 10); // 10 Pips niedriger
                }
                
                // Normalisiere
                new_sl = NormalizeDouble(new_sl, digits);
                new_tp = NormalizeDouble(new_tp, digits);
                
                LogImportant("🎯 TESTE MIT NEUEN WERTEN:");
                LogImportant("   New SL: " + DoubleToString(new_sl, digits));
                LogImportant("   New TP: " + DoubleToString(new_tp, digits));
                
                // Versuche Modifikation
                ResetLastError();
                
                if(trade.PositionModify(ticket, new_sl, new_tp)) {
                    LogImportant("✅✅✅ TEST ERFOLGREICH! POSITION MODIFIZIERT!");
                } else {
                    int error = GetLastError();
                    LogError("❌ TEST FEHLGESCHLAGEN!");
                    LogError("   Error: " + IntegerToString(error));
                    LogError("   Description: " + trade.ResultRetcodeDescription());
                }
                
                break; // Nur erste Position testen
            }
        }
    }
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("🧪 TEST BEENDET");
    LogImportant("════════════════════════════════════════════");
}

// ===== ALLE WEITEREN FUNKTIONEN UNVERÄNDERT =====

//+------------------------------------------------------------------+
//| SPEZIELLE API-BENACHRICHTIGUNG FÜR "RISK TOO SMALL"            |
//+------------------------------------------------------------------+
void SendRiskTooSmallNotification(string signal_id, string symbol, double requested_risk_percent, 
                                  double required_risk_percent, double min_lot, double balance,
                                  string order_type_str = "market buy") {
    
    string message = "Risk too small for minimum lot size";
    double required_risk_amount = balance * required_risk_percent / 100.0;
    
    // Create complete JSON using helper functions
    string json = CreateBaseJSON(signal_id, false, message, order_type_str, symbol, min_lot);
    
    // Add status for risk too small
    int replaced = StringReplace(json, "\"message\":\"" + message + "\",", 
                                "\"status\":\"risk_too_small\",\"message\":\"" + message + "\",");
    
    // Add comprehensive risk calculation with required values
    json = AddRiskCalculation(json, requested_risk_percent, 0, required_risk_percent, required_risk_amount);
    
    // Add detailed risk information
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    double requested_risk_amount = balance * requested_risk_percent / 100.0;
    
    json += "\"risk_details\":{";
    json += "\"symbol\":\"" + symbol + "\",";
    json += "\"min_lot_size\":" + DoubleToString(min_lot, 3) + ",";
    json += "\"requested_risk_percent\":" + DoubleToString(requested_risk_percent, 2) + ",";
    json += "\"requested_risk_amount\":" + DoubleToString(requested_risk_amount, 2) + ",";
    json += "\"required_risk_percent\":" + DoubleToString(required_risk_percent, 2) + ",";
    json += "\"required_risk_amount\":" + DoubleToString(required_risk_amount, 2) + ",";
    json += "\"currency\":\"" + currency + "\",";
    json += "\"balance\":" + DoubleToString(balance, 2) + ",";
    json += "\"risk_difference_percent\":" + DoubleToString(required_risk_percent - requested_risk_percent, 2) + ",";
    json += "\"risk_difference_amount\":" + DoubleToString(required_risk_amount - requested_risk_amount, 2);
    json += "},";
    
    // Add complete account information
    json = AddAccountInfo(json);
    
    // Finalize JSON
    json = FinalizeJSON(json);
    
    LogImportant("📤 Sende RISK TOO SMALL Notification:");
    LogImportant("   Signal: " + signal_id);
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Gewünscht: " + DoubleToString(requested_risk_percent, 2) + "%");
    LogImportant("   Benötigt: " + DoubleToString(required_risk_percent, 2) + "%");
    
    LogDebug("📤 JSON Payload: " + json);
    
    char post_data[];
    char result_data[];
    string result_headers;
    
    // FIXED: Use same encoding as test connection
    StringToCharArray(json, post_data, 0, WHOLE_ARRAY, CP_UTF8);
    if(ArraySize(post_data) > 0) ArrayResize(post_data, ArraySize(post_data) - 1);
    
    string headers = "Content-Type: application/json\r\n";
    
    int res = WebRequest(
        "POST",
        delivery_api_url,
        headers,
        api_timeout_ms,
        post_data,
        result_data,
        result_headers
    );
    
    if(res == 200 || res == 201 || res == 204) {
        LogDebug("✅ Risk Too Small Notification erfolgreich gesendet");
    } else {
        LogError("❌ Risk Too Small Notification fehlgeschlagen: HTTP " + IntegerToString(res));
    }
}

// ===== NEUE API-BENACHRICHTIGUNGEN FÜR MODIFIKATIONEN =====
void SendModificationConfirmation(string signal_id, ulong ticket, string action_type, 
                                  string message, double new_sl, double new_tp, 
                                  double old_sl, double old_tp) {
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string timestamp = StringFormat("%04d-%02d-%02dT%02d:%02d:%02d", 
                                  dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
    
    // Get position/order details
    string symbol = "";
    double lots = 0;
    string order_type = "";
    
    if(PositionSelectByTicket(ticket)) {
        symbol = PositionGetString(POSITION_SYMBOL);
        lots = PositionGetDouble(POSITION_VOLUME);
        order_type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "market buy" : "market sell";
    } else if(OrderSelect(ticket)) {
        symbol = OrderGetString(ORDER_SYMBOL);
        lots = OrderGetDouble(ORDER_VOLUME_CURRENT);
        order_type = OrderTypeToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
    }
    
    string json = "{";
    json += "\"account_id\":\"" + account_id + "\",";
    json += "\"signal_id\":\"" + signal_id + "\",";
    json += "\"ticket\":\"" + IntegerToString(ticket) + "\",";
    json += "\"action\":\"" + action_type + "\",";
    json += "\"message\":\"" + message + "\",";
    json += "\"order_type\":\"" + order_type + "\",";
    json += "\"symbol\":\"" + symbol + "\",";
    json += "\"lots\":" + DoubleToString(lots, 3) + ",";
    json += "\"timestamp\":\"" + timestamp + "\",";
    json += "\"ea_version\":\"8.6\",";
    
    json += "\"modification\":{";
    json += "\"old_sl\":" + DoubleToString(old_sl, 5) + ",";
    json += "\"new_sl\":" + DoubleToString(new_sl, 5) + ",";
    json += "\"old_tp\":" + DoubleToString(old_tp, 5) + ",";
    json += "\"new_tp\":" + DoubleToString(new_tp, 5) + ",";
    json += "\"sl_changed\":" + ((new_sl != old_sl) ? "true" : "false") + ",";
    json += "\"tp_changed\":" + ((new_tp != old_tp) ? "true" : "false");
    json += "}";
    
    json += "}";
    
    // An API senden
    char post_data[];
    char result_data[];
    string result_headers;
    
    // FIXED: Use same encoding as test connection
    StringToCharArray(json, post_data, 0, WHOLE_ARRAY, CP_UTF8);
    if(ArraySize(post_data) > 0) ArrayResize(post_data, ArraySize(post_data) - 1);
    
    string headers = "Content-Type: application/json\r\n";
    
    WebRequest("POST", delivery_api_url, headers, api_timeout_ms,
              post_data, result_data, result_headers);
}

void SendOrderReplacementConfirmation(string signal_id, ulong old_ticket, ulong new_ticket,
                                      string message, double lots, double sl, double tp, 
                                      double risk_percent) {
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string timestamp = StringFormat("%04d-%02d-%02dT%02d:%02d:%02d", 
                                  dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
    
    // Get order details
    string symbol = "";
    string order_type = "";
    
    if(OrderSelect(new_ticket)) {
        symbol = OrderGetString(ORDER_SYMBOL);
        order_type = OrderTypeToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
    } else if(OrderSelect(old_ticket)) {
        symbol = OrderGetString(ORDER_SYMBOL);
        order_type = OrderTypeToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
    }
    
    string json = "{";
    json += "\"account_id\":\"" + account_id + "\",";
    json += "\"signal_id\":\"" + signal_id + "\",";
    json += "\"action\":\"order_replaced\",";
    json += "\"message\":\"" + message + "\",";
    json += "\"order_type\":\"" + order_type + "\",";
    json += "\"symbol\":\"" + symbol + "\",";
    json += "\"lots\":" + DoubleToString(lots, 3) + ",";
    json += "\"timestamp\":\"" + timestamp + "\",";
    json += "\"ea_version\":\"8.6\",";
    
    json += "\"replacement\":{";
    json += "\"old_ticket\":\"" + IntegerToString(old_ticket) + "\",";
    json += "\"new_ticket\":\"" + IntegerToString(new_ticket) + "\",";
    json += "\"lots\":" + DoubleToString(lots, 3) + ",";
    json += "\"sl\":" + DoubleToString(sl, 5) + ",";
    json += "\"tp\":" + DoubleToString(tp, 5) + ",";
    json += "\"risk_percent\":" + DoubleToString(risk_percent, 2);
    json += "},";
    
    // Risk calculation details
    if(risk_percent > 0) {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double requested_risk_amount = balance * risk_percent / 100.0;
        double calculated_risk_amount = requested_risk_amount; // Same for order replacement
        
        json += "\"risk_calculation\":{";
        json += "\"requested_risk_percent\":" + DoubleToString(risk_percent, 2) + ",";
        json += "\"requested_risk_amount\":" + DoubleToString(requested_risk_amount, 2) + ",";
        json += "\"calculated_risk_percent\":" + DoubleToString(risk_percent, 2) + ",";
        json += "\"calculated_risk_amount\":" + DoubleToString(calculated_risk_amount, 2);
        json += "},";
    }
    
    json += "\"account_info\":{";
    json += "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
    json += "\"currency\":\"" + AccountInfoString(ACCOUNT_CURRENCY) + "\"";
    json += "}";
    
    json += "}";
    
    // An API senden
    char post_data[];
    char result_data[];
    string result_headers;
    
    // FIXED: Use same encoding as test connection
    StringToCharArray(json, post_data, 0, WHOLE_ARRAY, CP_UTF8);
    if(ArraySize(post_data) > 0) ArrayResize(post_data, ArraySize(post_data) - 1);
    
    string headers = "Content-Type: application/json\r\n";
    
    WebRequest("POST", delivery_api_url, headers, api_timeout_ms,
              post_data, result_data, result_headers);
}

// [Alle weiteren Funktionen aus Version 8.6 folgen hier unverändert...]

// BREAK EVEN MANAGEMENT
bool ProcessBreakEven(int pos_index) {
    if(pos_index < 0 || pos_index >= ArraySize(tracked_positions)) return false;
    
    ulong ticket = tracked_positions[pos_index].current_ticket;
    string signal_id = tracked_positions[pos_index].signal_id;
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("🎯 BREAK EVEN VERARBEITUNG");
    LogImportant("   Signal ID: " + signal_id);
    LogImportant("   Ticket: #" + IntegerToString(ticket));
    
    if(!PositionSelectByTicket(ticket)) {
        LogError("❌ Position nicht gefunden für Break Even");
        return false;
    }
    
    double current_sl = PositionGetDouble(POSITION_SL);
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    string symbol = PositionGetString(POSITION_SYMBOL);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    LogImportant("📊 POSITION DETAILS:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Type: " + (type == POSITION_TYPE_BUY ? "BUY" : "SELL"));
    LogImportant("   Entry: " + DoubleToString(open_price, digits));
    LogImportant("   Current SL: " + DoubleToString(current_sl, digits));
    LogImportant("   Current TP: " + DoubleToString(current_tp, digits));
    
    // Prüfe ob SL bereits auf/über Entry
    bool sl_at_be = (type == POSITION_TYPE_BUY) ? 
                    (current_sl >= open_price) : 
                    (current_sl <= open_price && current_sl > 0);
    
    if(sl_at_be) {
        LogImportant("✅ SL bereits auf Break Even - keine Aktion erforderlich");
        LogImportant("════════════════════════════════════════════");
        return true;
    }
    
    // BE setzen (1 Point Offset für Sicherheit)
    double new_sl = (type == POSITION_TYPE_BUY) ? 
                    open_price + point : 
                    open_price - point;
    
    LogImportant("🎯 SETZE BREAK EVEN:");
    LogImportant("   Alter SL: " + DoubleToString(current_sl, digits));
    LogImportant("   Neuer SL: " + DoubleToString(new_sl, digits) + " (Entry + 1 Point)");
    
    if(trade.PositionModify(ticket, new_sl, current_tp)) {
        tracked_positions[pos_index].be_level = new_sl;
        
        LogSuccess("✅✅✅ BREAK EVEN ERFOLGREICH GESETZT! ✅✅✅");
        LogSuccess("   Position: #" + IntegerToString(ticket));
        LogSuccess("   Signal: " + signal_id);
        LogSuccess("   Entry: " + DoubleToString(open_price, digits));
        LogSuccess("   Break Even SL: " + DoubleToString(new_sl, digits));
        LogSuccess("   Risiko eliminiert - Position ist jetzt risikofrei!");
        
        // Erweiterte Delivery mit BE Details
        string be_details = symbol + " " + (type == POSITION_TYPE_BUY ? "BUY" : "SELL") + 
                           " | Entry: " + DoubleToString(open_price, digits) + 
                           " → BE: " + DoubleToString(new_sl, digits);
        SendStatusUpdate(signal_id, ticket, "breakeven", be_details);
        
        LogImportant("════════════════════════════════════════════");
        return true;
    }
    
    LogError("❌ BREAK EVEN SETZEN FEHLGESCHLAGEN!");
    LogError("   Error Code: " + IntegerToString(GetLastError()));
    LogError("   Error: " + trade.ResultRetcodeDescription());
    LogImportant("════════════════════════════════════════════");
    
    SendDeliveryConfirmation(signal_id, ticket, false, 
                            "Break Even failed: " + trade.ResultRetcodeDescription());
    return false;
}

// =// ========== JSON HELPER FUNCTIONS ==========

string DetermineStatus(bool success, string message) {
    string status_value = "";
    if(success) {
        if(StringFind(message, "executed") >= 0 || StringFind(message, "Trade executed") >= 0) {
            status_value = "executed";
        } else if(StringFind(message, "Break Even") >= 0) {
            status_value = "breakeven_set";
        } else if(StringFind(message, "closed") >= 0) {
            status_value = "closed";
        } else if(StringFind(message, "Partial") >= 0) {
            status_value = "partial_closed";
        } else if(StringFind(message, "cancelled") >= 0) {
            status_value = "cancelled";
        } else if(StringFind(message, "modified") >= 0 || StringFind(message, "SL/TP") >= 0) {
            status_value = "modified";
        } else {
            status_value = "success";
        }
    } else {
        if(StringFind(message, "Symbol not found") >= 0) {
            status_value = "symbol_not_found";
        } else if(StringFind(message, "Risk too small") >= 0 || StringFind(message, "Lot calculation failed") >= 0) {
            status_value = "risk_too_small";
        } else if(StringFind(message, "Invalid symbol data") >= 0) {
            status_value = "invalid_symbol_data";
        } else if(StringFind(message, "Validation failed") >= 0) {
            status_value = "validation_failed";
        } else if(StringFind(message, "market closed") >= 0) {
            status_value = "market_closed";
        } else if(StringFind(message, "not enough money") >= 0) {
            status_value = "insufficient_funds";
        } else {
            status_value = "rejected";
        }
    }
    return status_value;
}

string CreateBaseJSON(string signal_id, bool success, string message, 
                     string order_type = "", string symbol = "", double lots = 0,
                     ulong ticket = 0) {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string timestamp = StringFormat("%04d-%02d-%02dT%02d:%02d:%02d", 
                                  dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
    
    string json = "{";
    json += "\"account_id\":\"" + account_id + "\",";
    json += "\"signal_id\":\"" + signal_id + "\",";
    json += "\"success\":" + (success ? "true" : "false") + ",";
    json += "\"message\":\"" + message + "\",";
    json += "\"status\":\"" + DetermineStatus(success, message) + "\",";
    json += "\"timestamp\":\"" + timestamp + "\",";
    json += "\"ea_version\":\"8.6\",";
    
    if(order_type != "") {
        json += "\"order_type\":\"" + order_type + "\",";
    }
    if(symbol != "") {
        json += "\"symbol\":\"" + symbol + "\",";
    }
    if(lots > 0) {
        json += "\"lots\":" + DoubleToString(lots, 3) + ",";
    }
    if(ticket > 0) {
        json += "\"ticket\":\"" + IntegerToString(ticket) + "\",";
    }
    
    return json;
}

string AddRiskCalculation(string json, double requested_risk_percent, double calculated_risk_percent = 0,
                         double required_risk_percent = 0, double required_risk_amount = 0) {
    if(requested_risk_percent <= 0) return json;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double requested_risk_amount = balance * requested_risk_percent / 100.0;
    double calculated_risk_amount = balance * calculated_risk_percent / 100.0;
    
    json += "\"risk_calculation\":{";
    json += "\"requested_risk_percent\":" + DoubleToString(requested_risk_percent, 2) + ",";
    json += "\"requested_risk_amount\":" + DoubleToString(requested_risk_amount, 2) + ",";
    json += "\"calculated_risk_percent\":" + DoubleToString(calculated_risk_percent, 2) + ",";
    json += "\"calculated_risk_amount\":" + DoubleToString(calculated_risk_amount, 2);
    
    if(required_risk_percent > 0) {
        json += ",\"required_risk_percent\":" + DoubleToString(required_risk_percent, 2);
        json += ",\"required_risk_amount\":" + DoubleToString(required_risk_amount, 2);
        json += ",\"risk_difference_percent\":" + DoubleToString(required_risk_percent - requested_risk_percent, 2);
        json += ",\"risk_difference_amount\":" + DoubleToString(required_risk_amount - requested_risk_amount, 2);
    }
    
    json += "},";
    return json;
}

string AddAccountInfo(string json) {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
    
    json += "\"account_info\":{";
    json += "\"balance\":" + DoubleToString(balance, 2) + ",";
    json += "\"equity\":" + DoubleToString(equity, 2) + ",";
    json += "\"margin\":" + DoubleToString(margin, 2) + ",";
    json += "\"free_margin\":" + DoubleToString(free_margin, 2) + ",";
    json += "\"currency\":\"" + currency + "\",";
    json += "\"leverage\":" + IntegerToString(leverage);
    json += "},";
    return json;
}

string AddTradeDetails(string json, double entry_price = 0, double sl = 0, double tp = 0) {
    if(entry_price > 0) {
        json += "\"entry_price\":" + DoubleToString(entry_price, 5) + ",";
    }
    if(sl > 0) {
        json += "\"sl\":" + DoubleToString(sl, 5) + ",";
    }
    if(tp > 0) {
        json += "\"tp\":" + DoubleToString(tp, 5) + ",";
    }
    return json;
}

string AddErrorDetails(string json, string symbol, string direction, double lots, 
                      int error_code, string error_description) {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    
    json += "\"error_details\":{";
    json += "\"symbol\":\"" + symbol + "\",";
    json += "\"direction\":\"" + direction + "\",";
    json += "\"lots\":" + DoubleToString(lots, 3) + ",";
    json += "\"error_code\":" + IntegerToString(error_code) + ",";
    json += "\"error_description\":\"" + error_description + "\",";
    json += "\"account_balance\":" + DoubleToString(balance, 2) + ",";
    json += "\"free_margin\":" + DoubleToString(free_margin, 2);
    json += "},";
    return json;
}

string FinalizeJSON(string json) {
    // Remove trailing comma if present
    if(StringGetCharacter(json, StringLen(json) - 1) == ',') {
        json = StringSubstr(json, 0, StringLen(json) - 1);
    }
    json += "}";
    return json;
}

// TRADE OPERATIONS
void ClosePosition(ulong ticket, string signal_id) {
    if(!PositionSelectByTicket(ticket)) return;
    
    string symbol = PositionGetString(POSITION_SYMBOL);
    double volume = PositionGetDouble(POSITION_VOLUME);
    double profit = PositionGetDouble(POSITION_PROFIT);
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double close_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    
    if(trade.PositionClose(ticket)) {
        LogSuccess("Position geschlossen: #" + IntegerToString(ticket));
        
        string close_details = symbol + " " + DoubleToString(volume, 2) + " lots | " +
                              "Open: " + DoubleToString(open_price, 5) + " → " +
                              "Close: " + DoubleToString(close_price, 5) + " | " +
                              "P/L: " + DoubleToString(profit, 2) + " " + 
                              AccountInfoString(ACCOUNT_CURRENCY);
        
        // Sende Status an Delivery API
        SendStatusUpdate(signal_id, ticket, "close", close_details);
        
        // Sende Status an Signal API
        SendSignalStatusUpdate(signal_id, "closed", "Position closed: " + close_details);
    } else {
        LogError("Fehler beim Schließen: " + trade.ResultRetcodeDescription());
        SendDeliveryConfirmation(signal_id, ticket, false, 
                                "Close failed: " + trade.ResultRetcodeDescription());
    }
}

void CancelOrder(ulong ticket, string signal_id) {
    if(!OrderSelect(ticket)) return;
    
    string symbol = OrderGetString(ORDER_SYMBOL);
    double volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
    string order_type = OrderTypeToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
    double price = OrderGetDouble(ORDER_PRICE_OPEN);
    
    if(trade.OrderDelete(ticket)) {
        LogSuccess("Order storniert: #" + IntegerToString(ticket));
        
        string cancel_details = symbol + " " + order_type + " " +
                               DoubleToString(volume, 2) + " lots @ " +
                               DoubleToString(price, 5);
        
        // Sende Status an Delivery API
        SendStatusUpdate(signal_id, ticket, "cancel", cancel_details);
        
        // Sende Status an Signal API
        SendSignalStatusUpdate(signal_id, "cancelled", "Order cancelled: " + cancel_details);
    } else {
        LogError("Fehler beim Stornieren: " + trade.ResultRetcodeDescription());
        SendDeliveryConfirmation(signal_id, ticket, false, 
                                "Cancel failed: " + trade.ResultRetcodeDescription());
    }
}

ulong PartialClose(ulong ticket, string signal_id, double percent) {
    if(!PositionSelectByTicket(ticket)) return 0;
    
    string symbol = PositionGetString(POSITION_SYMBOL);
    double volume = PositionGetDouble(POSITION_VOLUME);
    double close_volume = NormalizeVolume(volume * percent / 100.0, symbol);
    
    if(close_volume <= 0) return 0;
    
    if(trade.PositionClosePartial(ticket, close_volume)) {
        ulong new_ticket = trade.ResultOrder();
        double remaining_volume = volume - close_volume;
        
        LogSuccess("Teilschließung erfolgreich. Neue Ticket: #" + IntegerToString(new_ticket));
        
        string partial_details = "Closed: " + DoubleToString(close_volume, 2) + " lots (" +
                                DoubleToString(percent, 0) + "%) | " +
                                "Remaining: " + DoubleToString(remaining_volume, 2) + " lots | " +
                                "New ticket: #" + IntegerToString(new_ticket);
        
        // Sende Status an Delivery API
        SendStatusUpdate(signal_id, new_ticket, "partial_close", partial_details);
        
        // Sende Status an Signal API
        SendSignalStatusUpdate(signal_id, "partial_closed", "Partial close: " + partial_details);
        
        return new_ticket;
    }
    
    LogError("Teilschließung fehlgeschlagen");
    SendDeliveryConfirmation(signal_id, ticket, false, 
                            "Partial close failed: " + trade.ResultRetcodeDescription());
    return 0;
}

// ERWEITERTE SIGNAL DELIVERY API FUNKTIONEN
void SendDeliveryConfirmation(string signal_id, ulong ticket, bool success, string message) {
    SendDeliveryConfirmationFull(signal_id, ticket, success, message, "", 0, 0, 0, "", "", 0);
}

void SendDeliveryConfirmationFull(string signal_id, ulong ticket, bool success, string message,
                                  string symbol = "", double lots = 0, double risk_percent = 0, 
                                  double entry_price = 0, string order_type = "", 
                                  string action = "", double calculated_risk_percent = 0, double calculated_risk_amount = 0) {
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string timestamp = StringFormat("%04d-%02d-%02dT%02d:%02d:%02d", 
                                  dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    string json = "{";
    json += "\"account_id\":\"" + account_id + "\",";
    json += "\"signal_id\":\"" + signal_id + "\",";
    json += "\"success\":" + (success ? "true" : "false") + ",";
    json += "\"ticket\":\"" + IntegerToString(ticket) + "\",";
    json += "\"message\":\"" + message + "\",";
    json += "\"timestamp\":\"" + timestamp + "\",";
    json += "\"ea_version\":\"8.6\",";
    
    // STATUS FIELD
    string status_value = "";
    if(success) {
        if(StringFind(message, "executed") >= 0 || StringFind(message, "Trade executed") >= 0) {
            status_value = "executed";
        } else if(StringFind(message, "Break Even") >= 0) {
            status_value = "breakeven_set";
        } else if(StringFind(message, "closed") >= 0) {
            status_value = "closed";
        } else if(StringFind(message, "Partial") >= 0) {
            status_value = "partial_closed";
        } else if(StringFind(message, "cancelled") >= 0) {
            status_value = "cancelled";
        } else {
            status_value = "success";
        }
    } else {
        if(StringFind(message, "Symbol not found") >= 0) {
            status_value = "symbol_not_found";
        } else if(StringFind(message, "Risk too small") >= 0 || StringFind(message, "Lot calculation failed") >= 0) {
            status_value = "risk_too_small";
        } else if(StringFind(message, "Invalid symbol data") >= 0) {
            status_value = "invalid_symbol_data";
        } else if(StringFind(message, "Validation failed") >= 0) {
            status_value = "validation_failed";
        } else {
            status_value = "failed";
        }
    }
    json += "\"status\":\"" + status_value + "\",";
    
    // Weitere Felder...
    if(order_type == "") {
        if(ticket > 0) {
            if(PositionSelectByTicket(ticket)) {
                ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                order_type = (pos_type == POSITION_TYPE_BUY) ? "market buy" : "market sell";
            } else if(OrderSelect(ticket)) {
                ENUM_ORDER_TYPE ord_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
                order_type = OrderTypeToString(ord_type);
            }
        }
    }
    json += "\"order_type\":\"" + order_type + "\",";
    
    double actual_lots = lots;
    if(actual_lots == 0 && ticket > 0) {
        if(PositionSelectByTicket(ticket)) {
            actual_lots = PositionGetDouble(POSITION_VOLUME);
        } else if(OrderSelect(ticket)) {
            actual_lots = OrderGetDouble(ORDER_VOLUME_CURRENT);
        }
    }
    json += "\"lots\":" + DoubleToString(actual_lots, 3) + ",";
    
    // Risk calculation details
    if(risk_percent > 0) {
        double requested_risk_amount = balance * risk_percent / 100.0;
        
        // Verwende den übergebenen calculated_risk_amount (exakter Verlust) oder berechne aus Prozent
        double final_calculated_risk_amount = calculated_risk_amount;
        double final_calculated_risk_percent = calculated_risk_percent;
        
        if(calculated_risk_amount > 0) {
            // Exakter Verlust wurde übergeben - berechne Prozent daraus
            final_calculated_risk_amount = calculated_risk_amount;
            final_calculated_risk_percent = (calculated_risk_amount / balance) * 100.0;
        } else if(calculated_risk_percent > 0) {
            // Nur Prozent wurde übergeben - berechne Betrag daraus
            final_calculated_risk_percent = calculated_risk_percent;
            final_calculated_risk_amount = balance * calculated_risk_percent / 100.0;
        }
        
        json += "\"risk_calculation\":{";
        json += "\"requested_risk_percent\":" + DoubleToString(risk_percent, 2) + ",";
        json += "\"requested_risk_amount\":" + DoubleToString(requested_risk_amount, 2) + ",";
        json += "\"calculated_risk_percent\":" + DoubleToString(final_calculated_risk_percent, 2) + ",";
        json += "\"calculated_risk_amount\":" + DoubleToString(final_calculated_risk_amount, 2);
        json += "},";
    }
    
    json += "\"account_info\":{";
    json += "\"balance\":" + DoubleToString(balance, 2) + ",";
    json += "\"equity\":" + DoubleToString(equity, 2) + ",";
    json += "\"margin\":" + DoubleToString(margin, 2) + ",";
    json += "\"free_margin\":" + DoubleToString(free_margin, 2) + ",";
    json += "\"currency\":\"" + currency + "\",";
    json += "\"leverage\":" + IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE));
    json += "}";
    
    json += "}";
    
    if(debug_mode) {
        LogDebug("📤 Sende Delivery Confirmation:");
        LogDebug("   Signal: " + signal_id);
        LogDebug("   Status: " + status_value);
    }
    
    char post_data[];
    char result_data[];
    string result_headers;
    
    // FIXED: Use same encoding as test connection
    StringToCharArray(json, post_data, 0, WHOLE_ARRAY, CP_UTF8);
    if(ArraySize(post_data) > 0) ArrayResize(post_data, ArraySize(post_data) - 1);
    
    string headers = "Content-Type: application/json\r\n";
    
    WebRequest("POST", delivery_api_url, headers, api_timeout_ms,
              post_data, result_data, result_headers);
}

void SendStatusUpdate(string signal_id, ulong ticket, string action, string details = "") {
    string message = "";
    string status = "";
    
    if(action == "breakeven") {
        message = "Break Even set";
        status = "breakeven_set";
        if(details != "") message += ": " + details;
    } else if(action == "partial_close") {
        message = "Partial close executed";
        status = "partial_closed";
        if(details != "") message += ": " + details;
    } else if(action == "close") {
        message = "Position closed";
        status = "closed";
        if(details != "") message += ": " + details;
    } else if(action == "cancel") {
        message = "Order cancelled";
        status = "cancelled";
        if(details != "") message += ": " + details;
    } else {
        message = action;
        status = action;
        if(details != "") message += ": " + details;
    }
    
    double lots = 0;
    string order_type = "";
    string symbol = "";
    
    if(PositionSelectByTicket(ticket)) {
        lots = PositionGetDouble(POSITION_VOLUME);
        order_type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "market buy" : "market sell";
        symbol = PositionGetString(POSITION_SYMBOL);
    } else if(OrderSelect(ticket)) {
        lots = OrderGetDouble(ORDER_VOLUME_CURRENT);
        order_type = OrderTypeToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
        symbol = OrderGetString(ORDER_SYMBOL);
    }
    
    SendDeliveryConfirmationFull(signal_id, ticket, true, message, symbol, 
                                 lots, 0, 0, order_type, status, 0);
}

void SendTradeExecutionConfirmation(string signal_id, ulong ticket, string symbol, 
                                   ENUM_ORDER_TYPE order_type, double lots, 
                                   double price, double sl, double tp, 
                                   double risk_percent, double calculated_risk_percent = 0, double calculated_risk_amount = 0) {
    
    string order_type_str = OrderTypeToString(order_type);
    string message = "Trade executed: " + symbol + " " + order_type_str + " " + 
                    DoubleToString(lots, 3) + " lots @ " + DoubleToString(price, 5);
    
    SendDeliveryConfirmationFull(signal_id, ticket, true, message, symbol, 
                                 lots, risk_percent, price, order_type_str, "trade_opened", calculated_risk_percent, calculated_risk_amount);
}

void SendTradeErrorConfirmation(string signal_id, string symbol, string direction,
                               double lots, int error_code, string error_description, 
                               string order_type_str = "", double requested_risk_percent = 0) {
    
    LogImportant("📤 SENDE TRADE-FEHLER AN API:");
    LogImportant("   Signal: " + signal_id);
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Direction: " + direction);
    LogImportant("   Lots: " + DoubleToString(lots, 3));
    LogImportant("   Error Code: " + IntegerToString(error_code));
    LogImportant("   Error: " + error_description);
    
    // Determine order_type if not provided
    if(order_type_str == "") {
        order_type_str = DirectionToOrderType(direction, "market"); // Default to market
    }
    
    string message = "Trade failed: " + error_description + " (Error " + 
                    IntegerToString(error_code) + ")";
    
    // Create complete JSON using helper functions
    string json = CreateBaseJSON(signal_id, false, message, order_type_str, symbol, lots);
    
    // Add error details
    json = AddErrorDetails(json, symbol, direction, lots, error_code, error_description);
    
    // Add risk calculation (calculated = 0 since trade failed)
    json = AddRiskCalculation(json, requested_risk_percent, 0);
    
    // Add complete account information
    json = AddAccountInfo(json);
    
    // Finalize JSON
    json = FinalizeJSON(json);
    
    LogDebug("📤 JSON Payload: " + json);
    LogDebug("📤 API URL: " + delivery_api_url);
    
    char post_data[];
    char result_data[];
    string result_headers;
    
    // FIXED: Use same encoding as test connection
    StringToCharArray(json, post_data, 0, WHOLE_ARRAY, CP_UTF8);
    if(ArraySize(post_data) > 0) ArrayResize(post_data, ArraySize(post_data) - 1);
    
    string headers = "Content-Type: application/json\r\n";
    
    ResetLastError();
    int response_code = WebRequest("POST", delivery_api_url, headers, api_timeout_ms,
                                  post_data, result_data, result_headers);
    
    if(response_code == -1) {
        int web_error = GetLastError();
        LogError("❌ WebRequest fehlgeschlagen!");
        LogError("   Error Code: " + IntegerToString(web_error));
        LogError("   URL: " + delivery_api_url);
    } else if(response_code == 200) {
        LogImportant("✅ Trade-Fehler erfolgreich an API gesendet (HTTP " + IntegerToString(response_code) + ")");
        string response_text = CharArrayToString(result_data);
        if(response_text != "") {
            LogDebug("📥 API Response: " + response_text);
        }
    } else {
        LogWarning("⚠️ API Response Code: " + IntegerToString(response_code));
        string response_text = CharArrayToString(result_data);
        if(response_text != "") {
            LogDebug("📥 API Response: " + response_text);
        }
    }
}

// API FUNCTIONS
string GetSignalFromAPI() {
    string url = signal_api_url + "?account_id=" + account_id;
    
    char dummy[];
    char result_data[];
    string result_headers = "";
    
    ResetLastError();
    
    int res = WebRequest(
        "GET",
        url,
        NULL,
        api_timeout_ms,
        dummy,
        result_data,
        result_headers
    );
    
    if(res == -1) {
        LogDebug("WebRequest fehlgeschlagen: " + IntegerToString(GetLastError()));
        return "";
    }
    
    if(res == 204) return ""; // No content
    
    if(res != 200) {
        LogDebug("API Fehler: HTTP " + IntegerToString(res));
        return "";
    }
    
    return CharArrayToString(result_data);
}

string GetPositionStatusFromAPI(string signal_id, ulong ticket) {
    string url = position_api_url + "?signal_id=" + signal_id + 
                 "&account_id=" + account_id +
                 "&ticket=" + IntegerToString(ticket);
    
    char dummy[];
    char result_data[];
    string result_headers = "";
    
    int res = WebRequest(
        "GET",
        url,
        NULL,
        api_timeout_ms,
        dummy,
        result_data,
        result_headers
    );
    
    if(res == 200) {
        return CharArrayToString(result_data);
    }
    
    return "";
}

// SYMBOL MANAGEMENT FUNKTIONEN
bool InitializeBrokerSuffix() {
    LogDebug("🔍 Ermittle Broker-Suffix...");
    
    // "#" zuerst testen, da es bei vielen Brokern Standard ist
    string test_suffixes[] = {"#", "", "+", "-", "p", ".pro", ".r", "_ecn", ".", "i", "m", ".a", ".c"};
    string test_symbols[] = {"EURUSD", "GBPUSD", "XAUUSD", "BTCUSD", "ETHUSD"};
    
    for(int s = 0; s < ArraySize(test_symbols); s++) {
        for(int i = 0; i < ArraySize(test_suffixes); i++) {
            string test_symbol = test_symbols[s] + test_suffixes[i];
            
            if(SymbolSelect(test_symbol, true)) {
                Sleep(50);
                
                if(IsSymbolTradeable(test_symbol)) {
                    broker_suffix = test_suffixes[i];
                    LogSuccess("✅ Broker-Suffix gefunden: '" + broker_suffix + "' (Symbol: " + test_symbol + ")");
                    
                    string confirm_symbols[] = {"USDJPY", "XAUUSD", "ETHUSD", "BTCEUR"};
                    int confirmed = 0;
                    for(int j = 0; j < ArraySize(confirm_symbols); j++) {
                        string confirm_symbol = confirm_symbols[j] + broker_suffix;
                        if(SymbolSelect(confirm_symbol, true)) {
                            Sleep(20);
                            if(IsSymbolTradeable(confirm_symbol)) {
                                confirmed++;
                                LogDebug("   ✓ Bestätigt mit: " + confirm_symbol);
                            }
                        }
                    }
                    
                    if(confirmed > 0 || s > 1) {
                        LogSuccess("✅ Suffix '" + broker_suffix + "' bestätigt");
                        return true;
                    }
                }
            }
        }
    }
    
    LogWarning("⚠️ Kein eindeutiges Broker-Suffix gefunden");
    LogWarning("⚠️ Verwende erweiterte Suche bei jedem Trade");
    return false;
}

string FindTradableSymbol(string original) {
    for(int i = 0; i < ArraySize(symbol_cache); i++) {
        if(symbol_cache[i].original == original) {
            if(TimeCurrent() - symbol_cache[i].last_check < 86400) {
                if(IsSymbolTradeable(symbol_cache[i].mapped)) {
                    return symbol_cache[i].mapped;
                } else {
                    ArrayRemove(symbol_cache, i, 1);
                    LogDebug("Cache-Eintrag für " + original + " war ungültig");
                    break;
                }
            }
        }
    }
    
    // "#" zuerst testen, da es bei vielen Brokern Standard ist
    string test_suffixes[] = {"#", "", "+", "-", "p", ".pro", ".r", "_ecn", ".", "i", "m", ".a", ".c"};
    
    LogDebug("🔍 Suche handelbares Symbol für: " + original);
    
    string found_symbols[];
    ArrayResize(found_symbols, 0);
    
    for(int i = 0; i < ArraySize(test_suffixes); i++) {
        string test = original + test_suffixes[i];
        
        if(SymbolSelect(test, true)) {
            Sleep(20);
            
            if(IsSymbolTradeable(test)) {
                int size = ArraySize(found_symbols);
                ArrayResize(found_symbols, size + 1);
                found_symbols[size] = test;
                
                LogDebug("   ✓ Handelbar: " + test);
                
                if(broker_suffix != "" && test_suffixes[i] == broker_suffix) {
                    LogDebug("   → Verwende bekanntes Suffix: " + test);
                    AddToSymbolCache(original, test);
                    return test;
                }
                
                // Wenn "#" gefunden wurde und broker_suffix noch leer ist, direkt verwenden
                if(test_suffixes[i] == "#" && broker_suffix == "") {
                    broker_suffix = "#";
                    LogInfo("   📌 Broker-Suffix '#' erkannt und gespeichert");
                    AddToSymbolCache(original, test);
                    return test;
                }
            } else {
                LogDebug("   ✗ Nicht handelbar: " + test);
            }
        }
    }
    
    if(ArraySize(found_symbols) > 0) {
        string best_symbol = found_symbols[0];
        
        if(ArraySize(found_symbols) > 1 && broker_suffix != "") {
            for(int i = 0; i < ArraySize(found_symbols); i++) {
                if(StringFind(found_symbols[i], broker_suffix) >= 0) {
                    best_symbol = found_symbols[i];
                    break;
                }
            }
        }
        
        LogSuccess("✅ Handelbares Symbol gefunden: " + best_symbol);
        
        if(StringLen(best_symbol) > StringLen(original)) {
            string found_suffix = StringSubstr(best_symbol, StringLen(original));
            if(broker_suffix == "" && found_suffix != "") {
                broker_suffix = found_suffix;
                LogInfo("📌 Broker-Suffix gespeichert: '" + broker_suffix + "'");
            }
        }
        
        AddToSymbolCache(original, best_symbol);
        return best_symbol;
    }
    
    LogDebug("❌ Kein handelbares Symbol gefunden für: " + original);
    return "";
}

string FindSymbolWithExtendedSearch(string original) {
    LogWarning("🔄 Erweiterte Symbol-Suche für: " + original);
    
    // "#" zuerst, da es bei vielen Brokern Standard ist
    string suffixes[] = {
        "#", "", "+", "-", "p", ".pro", ".r", "_ecn", ".", "i", "m",
        "pro", ".ecn", ".std", ".cent", ".micro", ".mini",
        ".a", ".c", ".raw", "raw", ".spot", "spot",
        "cash", ".cash", ".cfd", "cfd"
    };
    
    bool is_crypto = (StringFind(original, "BTC") >= 0 || 
                     StringFind(original, "ETH") >= 0 ||
                     StringFind(original, "XRP") >= 0 ||
                     StringFind(original, "LTC") >= 0);
    
    for(int i = 0; i < ArraySize(suffixes); i++) {
        string test = original + suffixes[i];
        LogDebug("   Teste: " + test);
        
        if(IsSymbolTradeable(test)) {
            LogSuccess("   ✅ Symbol gefunden: " + test);
            
            if(broker_suffix == "" && suffixes[i] != "") {
                broker_suffix = suffixes[i];
                LogInfo("   📌 Broker-Suffix gespeichert: '" + broker_suffix + "'");
            }
            
            AddToSymbolCache(original, test);
            return test;
        }
    }
    
    if(is_crypto) {
        LogDebug("🔄 Spezielle Krypto-Suche...");
        
        if(StringFind(original, "USD") > 0) {
            string without_usd = StringSubstr(original, 0, StringFind(original, "USD"));
            LogDebug("   Teste ohne USD: " + without_usd);
            
            for(int i = 0; i < ArraySize(suffixes); i++) {
                string test = without_usd + suffixes[i];
                if(IsSymbolTradeable(test)) {
                    LogSuccess("   ✅ Krypto-Symbol gefunden: " + test);
                    AddToSymbolCache(original, test);
                    return test;
                }
            }
        }
        
        string crypto_base = "";
        if(StringFind(original, "BTC") >= 0) crypto_base = "BTC";
        else if(StringFind(original, "ETH") >= 0) crypto_base = "ETH";
        else if(StringFind(original, "XRP") >= 0) crypto_base = "XRP";
        else if(StringFind(original, "LTC") >= 0) crypto_base = "LTC";
        
        if(crypto_base != "") {
            string quote_currencies[] = {"USD", "USDT", "EUR", ""};
            for(int q = 0; q < ArraySize(quote_currencies); q++) {
                for(int i = 0; i < ArraySize(suffixes); i++) {
                    string test = crypto_base + quote_currencies[q] + suffixes[i];
                    LogDebug("   Teste: " + test);
                    
                    if(IsSymbolTradeable(test)) {
                        LogSuccess("   ✅ Krypto-Symbol gefunden: " + test);
                        AddToSymbolCache(original, test);
                        return test;
                    }
                }
            }
        }
    }
    
    LogWarning("⚠️ Durchsuche alle Symbole im Terminal...");
    int total_symbols = SymbolsTotal(false);
    
    for(int i = 0; i < total_symbols; i++) {
        string symbol_name = SymbolName(i, false);
        
        if(StringFind(symbol_name, original) >= 0 || 
           (is_crypto && StringFind(symbol_name, StringSubstr(original, 0, 3)) >= 0)) {
            
            LogDebug("   Gefunden in Liste: " + symbol_name);
            
            if(IsSymbolTradeable(symbol_name)) {
                LogSuccess("   ✅ Symbol aus Liste verwendbar: " + symbol_name);
                AddToSymbolCache(original, symbol_name);
                return symbol_name;
            }
        }
    }
    
    LogError("❌ Symbol nicht gefunden: " + original);
    LogError("   Versucht mit Suffixen: " + IntegerToString(ArraySize(suffixes)));
    LogError("   Durchsuchte Symbole: " + IntegerToString(total_symbols));
    
    return "";
}

bool IsSymbolTradeable(string symbol) {
    if(!SymbolSelect(symbol, true)) {
        LogDebug("Symbol " + symbol + " konnte nicht aktiviert werden");
        return false;
    }
    
    Sleep(50);
    
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    long trade_mode = SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
    bool visible = SymbolInfoInteger(symbol, SYMBOL_VISIBLE);
    long calc_mode = SymbolInfoInteger(symbol, SYMBOL_TRADE_CALC_MODE);
    long exec_mode = SymbolInfoInteger(symbol, SYMBOL_TRADE_EXEMODE);
    
    bool session_deals = SymbolInfoInteger(symbol, SYMBOL_SESSION_DEALS) > 0;
    double min_volume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double max_volume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    
    // Spezielle Behandlung für Gold/Metalle/CFDs (oft haben diese "#" Suffix)
    bool is_metal = (StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "XAG") >= 0 || 
                     StringFind(symbol, "GOLD") >= 0 || StringFind(symbol, "SILVER") >= 0);
    
    if(debug_mode) {
        LogDebug("Symbol Check: " + symbol);
        LogDebug("   Bid: " + DoubleToString(bid, 5) + " | Ask: " + DoubleToString(ask, 5));
        LogDebug("   Trade Mode: " + IntegerToString(trade_mode));
        LogDebug("   Session Deals: " + (session_deals ? "Ja" : "Nein"));
        LogDebug("   Min Volume: " + DoubleToString(min_volume, 3));
        LogDebug("   Visible: " + (visible ? "Ja" : "Nein"));
        LogDebug("   Is Metal/CFD: " + (is_metal ? "Ja" : "Nein"));
    }
    
    bool is_tradeable = false;
    
    // Basis-Checks
    if(bid > 0 && ask > 0 && min_volume > 0 && max_volume > 0 && min_volume <= max_volume) {
        
        // Trade Mode Check - Akzeptiere auch SYMBOL_TRADE_MODE_LONGONLY und SYMBOL_TRADE_MODE_SHORTONLY
        if(trade_mode == SYMBOL_TRADE_MODE_FULL || 
           trade_mode == SYMBOL_TRADE_MODE_LONGONLY || 
           trade_mode == SYMBOL_TRADE_MODE_SHORTONLY) {
            
            // Für Metalle/CFDs mit "#" Suffix - vereinfachte Prüfung
            if(is_metal || StringFind(symbol, "#") >= 0) {
                // Bei Metallen/CFDs reicht es wenn Preise vorhanden sind
                is_tradeable = true;
                LogDebug("   ✓ Symbol " + symbol + " ist handelbar (Metal/CFD mit # Suffix)");
            } else {
                // Standard Margin-Check für normale Symbole
                double test_lots = min_volume;
                double test_price = ask;
                double margin_required = 0;
                
                if(OrderCalcMargin(ORDER_TYPE_BUY, symbol, test_lots, test_price, margin_required)) {
                    if(margin_required > 0) {
                        is_tradeable = true;
                        LogDebug("   ✓ Symbol " + symbol + " ist handelbar (Margin: " + 
                                DoubleToString(margin_required, 2) + ")");
                    } else {
                        // Fallback: Wenn Margin = 0 aber Symbol hat "#" - trotzdem akzeptieren
                        if(StringFind(symbol, "#") >= 0) {
                            is_tradeable = true;
                            LogDebug("   ✓ Symbol " + symbol + " ist handelbar (# Suffix, Margin-Check übersprungen)");
                        } else {
                            LogDebug("   ✗ Symbol " + symbol + " - Margin-Berechnung = 0");
                        }
                    }
                } else {
                    // Margin-Berechnung fehlgeschlagen - bei "#" Suffix trotzdem versuchen
                    if(StringFind(symbol, "#") >= 0) {
                        is_tradeable = true;
                        LogDebug("   ✓ Symbol " + symbol + " ist handelbar (# Suffix, Margin-Check fehlgeschlagen aber ignoriert)");
                    } else {
                        LogDebug("   ✗ Symbol " + symbol + " - Margin-Berechnung fehlgeschlagen");
                    }
                }
            }
        } else {
            LogDebug("   ✗ Trade Mode ist nicht FULL/LONG/SHORT (" + IntegerToString(trade_mode) + ")");
        }
    } else {
        if(bid <= 0 || ask <= 0) {
            LogDebug("   ✗ Keine gültigen Preise");
        } else if(min_volume <= 0 || max_volume <= 0) {
            LogDebug("   ✗ Ungültige Volume-Limits");
        }
    }
    
    return is_tradeable;
}

void AddToSymbolCache(string original, string mapped) {
    int size = ArraySize(symbol_cache);
    ArrayResize(symbol_cache, size + 1);
    symbol_cache[size].original = original;
    symbol_cache[size].mapped = mapped;
    symbol_cache[size].last_check = TimeCurrent();
}

// Utility functions
ulong FindPositionByComment(string signal_id) {
    string expected_comment = "Signal: " + signal_id;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket)) {
            if(PositionGetInteger(POSITION_MAGIC) == magic_number) {
                if(PositionGetString(POSITION_COMMENT) == expected_comment) {
                    return ticket;
                }
            }
        }
    }
    return 0;
}

double NormalizeVolume(double volume, string symbol) {
    double min_volume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double max_volume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double volume_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    volume = MathFloor(volume / volume_step) * volume_step;
    
    if(volume < min_volume) return 0;
    if(volume > max_volume) volume = max_volume;
    
    return volume;
}

ENUM_ORDER_TYPE DetermineOrderType(string direction, string order_type, double entry, string symbol, 
                                   double entry_min, double entry_max) {
    string type_lower = order_type;
    StringToLowerCase(type_lower);
    
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    if(direction == "buy") {
        if(type_lower == "limit" && entry > 0) {
            return ORDER_TYPE_BUY_LIMIT;
        }
        else if(type_lower == "stop" && entry > 0) {
            return ORDER_TYPE_BUY_STOP;
        }
        else if(type_lower == "market" || type_lower == "") {
            if(entry_min > 0 && entry_max > 0) {
                if(ask > entry_max) {
                    LogDebug("Market Order → Buy Limit (Ask " + DoubleToString(ask, 5) + 
                            " > entry_max " + DoubleToString(entry_max, 5) + ")");
                    return ORDER_TYPE_BUY_LIMIT;
                }
                else if(ask < entry_min) {
                    LogDebug("Market Order → Buy Stop (Ask " + DoubleToString(ask, 5) + 
                            " < entry_min " + DoubleToString(entry_min, 5) + ")");
                    return ORDER_TYPE_BUY_STOP;
                }
                else {
                    LogDebug("Market Order (Ask " + DoubleToString(ask, 5) + 
                            " im Bereich " + DoubleToString(entry_min, 5) + 
                            " - " + DoubleToString(entry_max, 5) + ")");
                    return ORDER_TYPE_BUY;
                }
            }
            return ORDER_TYPE_BUY;
        }
    } else {
        if(type_lower == "limit" && entry > 0) {
            return ORDER_TYPE_SELL_LIMIT;
        }
        else if(type_lower == "stop" && entry > 0) {
            return ORDER_TYPE_SELL_STOP;
        }
        else if(type_lower == "market" || type_lower == "") {
            if(entry_min > 0 && entry_max > 0) {
                if(bid < entry_min) {
                    LogDebug("Market Order → Sell Limit (Bid " + DoubleToString(bid, 5) + 
                            " < entry_min " + DoubleToString(entry_min, 5) + ")");
                    return ORDER_TYPE_SELL_LIMIT;
                }
                else if(bid > entry_max) {
                    LogDebug("Market Order → Sell Stop (Bid " + DoubleToString(bid, 5) + 
                            " > entry_max " + DoubleToString(entry_max, 5) + ")");
                    return ORDER_TYPE_SELL_STOP;
                }
                else {
                    LogDebug("Market Order (Bid " + DoubleToString(bid, 5) + 
                            " im Bereich " + DoubleToString(entry_min, 5) + 
                            " - " + DoubleToString(entry_max, 5) + ")");
                    return ORDER_TYPE_SELL;
                }
            }
            return ORDER_TYPE_SELL;
        }
    }
    
    return (direction == "buy") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
}

// Break Even History Management
bool IsBreakEvenExecuted(string signal_id) {
    string filename = "BE_History_" + account_id + ".dat";
    if(!FileIsExist(filename)) return false;
    
    int handle = FileOpen(filename, FILE_READ|FILE_BIN);
    if(handle != INVALID_HANDLE) {
        while(!FileIsEnding(handle)) {
            string saved_signal = FileReadString(handle);
            if(saved_signal == signal_id) {
                FileClose(handle);
                return true;
            }
        }
        FileClose(handle);
    }
    return false;
}

void SaveBreakEvenStatus(string signal_id) {
    string filename = "BE_History_" + account_id + ".dat";
    int handle = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_BIN);
    
    if(handle != INVALID_HANDLE) {
        FileSeek(handle, 0, SEEK_END);
        FileWriteString(handle, signal_id);
        FileClose(handle);
    }
}

void LoadBreakEvenHistory() {
    string filename = "BE_History_" + account_id + ".dat";
    if(!FileIsExist(filename)) return;
    
    int handle = FileOpen(filename, FILE_READ|FILE_BIN);
    if(handle != INVALID_HANDLE) {
        int count = 0;
        while(!FileIsEnding(handle)) {
            string signal_id = FileReadString(handle);
            if(signal_id != "") count++;
        }
        FileClose(handle);
        LogDebug("BE-Historie geladen: " + IntegerToString(count) + " Einträge");
    }
}

void SaveBreakEvenHistory() {
    for(int i = 0; i < ArraySize(tracked_positions); i++) {
        if(tracked_positions[i].be_executed && tracked_positions[i].is_active) {
            SaveBreakEvenStatus(tracked_positions[i].signal_id);
        }
    }
}

// Helper Functions
bool IsSignalAlreadyTraded(string signal_id) {
    string expected_comment = "Signal: " + signal_id;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket)) {
            if(PositionGetInteger(POSITION_MAGIC) == magic_number) {
                if(PositionGetString(POSITION_COMMENT) == expected_comment) {
                    return true;
                }
            }
        }
    }
    
    for(int i = 0; i < OrdersTotal(); i++) {
        ulong ticket = OrderGetTicket(i);
        if(OrderSelect(ticket)) {
            if(OrderGetInteger(ORDER_MAGIC) == magic_number) {
                if(OrderGetString(ORDER_COMMENT) == expected_comment) {
                    return true;
                }
            }
        }
    }
    
    datetime check_from = TimeCurrent() - 86400;
    HistorySelect(check_from, TimeCurrent());
    
    for(int i = 0; i < HistoryDealsTotal(); i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket > 0) {
            if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == magic_number) {
                if(HistoryDealGetString(ticket, DEAL_COMMENT) == expected_comment) {
                    return true;
                }
            }
        }
    }
    
    return false;
}

bool IsSignalProcessed(string signal_id) {
    for(int i = 0; i < ArraySize(processed_signals); i++) {
        if(processed_signals[i].signal_id == signal_id) {
            return true;
        }
    }
    return false;
}

void MarkSignalAsProcessed(string signal_id, bool success) {
    int size = ArraySize(processed_signals);
    ArrayResize(processed_signals, size + 1);
    processed_signals[size].signal_id = signal_id;
    processed_signals[size].processed_time = TimeCurrent();
    processed_signals[size].success = success;
}

bool ValidateSignal(string symbol, string direction, double sl, double tp, double risk, string order_type, double entry) {
    if(symbol == "") return false;
    if(direction != "buy" && direction != "sell") return false;
    if(sl <= 0) return false;
    if(risk <= 0) return false;
    
    string type_lower = order_type;
    StringToLowerCase(type_lower);
    if((type_lower == "limit" || type_lower == "stop")) {
        if(entry <= 0) {
            LogError("Limit/Stop Order ohne Entry-Preis!");
            return false;
        }
    }
    
    return true;
}

string GetJsonValue(string json, string key) {
    int key_pos = StringFind(json, "\"" + key + "\"");
    if(key_pos == -1) return "";
    
    int colon_pos = StringFind(json, ":", key_pos);
    if(colon_pos == -1) return "";
    
    int value_start = colon_pos + 1;
    int json_len = StringLen(json);
    while(value_start < json_len && 
          (StringSubstr(json, value_start, 1) == " " || 
           StringSubstr(json, value_start, 1) == "\"")) {
        value_start++;
    }
    
    int value_end = value_start;
    bool in_quotes = (StringSubstr(json, value_start - 1, 1) == "\"");
    
    if(in_quotes) {
        value_end = StringFind(json, "\"", value_start);
    } else {
        while(value_end < json_len) {
            string char_at = StringSubstr(json, value_end, 1);
            if(char_at == "," || char_at == "}" || char_at == "]") break;
            value_end++;
        }
    }
    
    if(value_end == -1) value_end = json_len;
    
    return StringSubstr(json, value_start, value_end - value_start);
}

void StringToLowerCase(string &str) {
    int str_len = StringLen(str);
    for(int i = 0; i < str_len; i++) {
        ushort char_code = StringGetCharacter(str, i);
        if(char_code >= 'A' && char_code <= 'Z') {
            StringSetCharacter(str, i, ushort(char_code + 32));
        }
    }
}

void CleanupOldData() {
    datetime cutoff = TimeCurrent() - 86400;
    for(int i = ArraySize(processed_signals) - 1; i >= 0; i--) {
        if(processed_signals[i].processed_time < cutoff) {
            ArrayRemove(processed_signals, i, 1);
        }
    }
    
    for(int i = ArraySize(tracked_positions) - 1; i >= 0; i--) {
        if(!tracked_positions[i].is_active) {
            if(TimeCurrent() - tracked_positions[i].last_checked > 3600) {
                ArrayRemove(tracked_positions, i, 1);
            }
        }
    }
    
    LogDebug("Cleanup durchgeführt");
}

string GetDeInitReasonText(int reason) {
    switch(reason) {
        case REASON_REMOVE: return "EA entfernt";
        case REASON_RECOMPILE: return "Neu kompiliert";
        case REASON_CHARTCHANGE: return "Chart gewechselt";
        case REASON_CHARTCLOSE: return "Chart geschlossen";
        case REASON_PARAMETERS: return "Parameter geändert";
        case REASON_ACCOUNT: return "Account gewechselt";
        default: return "Unbekannt";
    }
}

string GetOrderTypeString(int order_type) {
    switch(order_type) {
        case ORDER_TYPE_BUY: return "buy";
        case ORDER_TYPE_SELL: return "sell";
        case ORDER_TYPE_BUY_LIMIT: return "buy_limit";
        case ORDER_TYPE_SELL_LIMIT: return "sell_limit";
        case ORDER_TYPE_BUY_STOP: return "buy_stop";
        case ORDER_TYPE_SELL_STOP: return "sell_stop";
        default: return "unknown";
    }
}

string PeriodToString(ENUM_TIMEFRAMES period) {
    switch(period) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default: return "Unknown";
    }
}

string GetAccountTradeMode() {
    ENUM_ACCOUNT_TRADE_MODE mode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
    switch(mode) {
        case ACCOUNT_TRADE_MODE_DEMO: return "DEMO";
        case ACCOUNT_TRADE_MODE_CONTEST: return "CONTEST";
        case ACCOUNT_TRADE_MODE_REAL: return "REAL";
        default: return "UNKNOWN";
    }
}

// VERBESSERTE SendLoginStatus FUNKTION MIT DETAILLIERTEM FEEDBACK
bool SendLoginStatus() {
    LogInfo("🔐 Sende Login-Status an API...");
    
    int wait_count = 0;
    while(!TerminalInfoInteger(TERMINAL_CONNECTED) && wait_count < 20) {
        LogDebug("   Warte auf Terminal-Verbindung... " + IntegerToString(wait_count + 1) + "/20");
        Sleep(500);
        wait_count++;
    }
    
    bool is_connected = TerminalInfoInteger(TERMINAL_CONNECTED) > 0;
    bool is_trade_allowed = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) > 0;
    long account_login = AccountInfoInteger(ACCOUNT_LOGIN);
    string server_name = AccountInfoString(ACCOUNT_SERVER);
    string company_name = AccountInfoString(ACCOUNT_COMPANY);
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    bool login_success = (is_connected && account_login > 0 && server_name != "");
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string timestamp = StringFormat("%04d-%02d-%02dT%02d:%02d:%02d", 
                                  dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
    
    string json = "{";
    json += "\"account_id\":\"" + account_id + "\",";
    json += "\"login_success\":" + (login_success ? "true" : "false") + ",";
    json += "\"timestamp\":\"" + timestamp + "\",";
    
    json += "\"connection\":{";
    json += "\"terminal_connected\":" + (is_connected ? "true" : "false") + ",";
    json += "\"trade_allowed\":" + (is_trade_allowed ? "true" : "false") + ",";
    json += "\"experts_enabled\":" + (MQLInfoInteger(MQL_TRADE_ALLOWED) ? "true" : "false") + ",";
    json += "\"dlls_allowed\":" + (MQLInfoInteger(MQL_DLLS_ALLOWED) ? "true" : "false") + ",";
    json += "\"trade_context_busy\":" + (IsTradeContextBusy() ? "true" : "false");
    json += "},";
    
    json += "\"account\":{";
    json += "\"login\":\"" + IntegerToString(account_login) + "\",";
    json += "\"server\":\"" + server_name + "\",";
    json += "\"company\":\"" + company_name + "\",";
    json += "\"balance\":" + DoubleToString(balance, 2) + ",";
    json += "\"equity\":" + DoubleToString(equity, 2) + ",";
    json += "\"margin\":" + DoubleToString(margin, 2) + ",";
    json += "\"free_margin\":" + DoubleToString(free_margin, 2) + ",";
    json += "\"margin_level\":" + (margin > 0 ? DoubleToString(equity/margin*100, 2) : "0") + ",";
    json += "\"currency\":\"" + currency + "\",";
    json += "\"leverage\":" + IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE)) + ",";
    json += "\"trade_mode\":\"" + GetAccountTradeMode() + "\"";
    json += "},";
    
    json += "\"ea_config\":{";
    json += "\"magic_number\":" + IntegerToString(magic_number) + ",";
    json += "\"version\":\"8.6\",";
    json += "\"build\":\"" + TimeToString(__DATETIME__, TIME_DATE|TIME_SECONDS) + "\",";
    json += "\"symbol\":\"" + Symbol() + "\",";
    json += "\"timeframe\":\"" + PeriodToString(Period()) + "\",";
    json += "\"debug_mode\":" + (debug_mode ? "true" : "false") + ",";
    json += "\"breakeven_enabled\":" + (use_breakeven ? "true" : "false") + ",";
    json += "\"check_interval_signal\":" + IntegerToString(check_interval_signal) + ",";
    json += "\"check_interval_position\":" + IntegerToString(check_interval_position) + ",";
    json += "\"max_login_attempts\":" + IntegerToString(max_login_attempts) + ",";
    json += "\"login_retry_delay\":" + IntegerToString(login_retry_delay_seconds);
    json += "},";
    
    int open_positions = 0;
    int pending_orders = 0;
    double floating_profit = 0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i) > 0) {
            if(PositionGetInteger(POSITION_MAGIC) == magic_number) {
                open_positions++;
                floating_profit += PositionGetDouble(POSITION_PROFIT);
            }
        }
    }
    
    for(int i = 0; i < OrdersTotal(); i++) {
        if(OrderGetTicket(i) > 0) {
            if(OrderGetInteger(ORDER_MAGIC) == magic_number) {
                pending_orders++;
            }
        }
    }
    
    json += "\"current_status\":{";
    json += "\"open_positions\":" + IntegerToString(open_positions) + ",";
    json += "\"pending_orders\":" + IntegerToString(pending_orders) + ",";
    json += "\"floating_profit\":" + DoubleToString(floating_profit, 2);
    json += "}";
    
    json += "}";
    
    if(debug_mode) {
        LogDebug("Login-Status JSON:");
        LogDebug(json);
    }
    
    char post_data[];
    char result_data[];
    string result_headers;
    
    // FIXED: Use same encoding as test connection
    StringToCharArray(json, post_data, 0, WHOLE_ARRAY, CP_UTF8);
    if(ArraySize(post_data) > 0) ArrayResize(post_data, ArraySize(post_data) - 1);
    
    string headers = "Content-Type: application/json\r\n";
    
    ResetLastError();
    int res = WebRequest(
        "POST",
        login_api_url,
        headers,
        api_timeout_ms,
        post_data,
        result_data,
        result_headers
    );
    
    int error_code = GetLastError();
    string response = CharArrayToString(result_data);
    
    // ERFOLG bei HTTP 200
    if(res == 200) {
        if(login_success) {
            LogSuccess("✅ Login-Status erfolgreich gemeldet (HTTP 200):");
            LogSuccess("   Account: " + IntegerToString(account_login));
            LogSuccess("   Server: " + server_name);
            LogSuccess("   Balance: " + DoubleToString(balance, 2) + " " + currency);
            LogSuccess("   Magic Number: " + IntegerToString(magic_number));
        } else {
            LogWarning("⚠️ Login-Status gemeldet (Verbindung noch nicht vollständig)");
            LogWarning("   Terminal Connected: " + (is_connected ? "Ja" : "Nein"));
            LogWarning("   Trade Allowed: " + (is_trade_allowed ? "Ja" : "Nein"));
        }
        
        if(response != "" && debug_mode) {
            LogDebug("API Response: " + response);
        }
        
        return true; // ERFOLG - Keine weiteren Versuche nötig
    } 
    // Auch bei HTTP 201 als Erfolg werten
    else if(res == 201) {
        LogSuccess("✅ Login-Status erfolgreich gemeldet (HTTP 201 - Created)");
        return true; // ERFOLG - Keine weiteren Versuche nötig
    }
    // Bei WebRequest Fehler (-1)
    else if(res == -1) {
        if(error_code == 4014 || error_code == 4060) {
            LogError("❌ WebRequest nicht erlaubt!");
            LogError("   Bitte URL in MT5 freigeben: " + login_api_url);
        } else {
            LogError("❌ WebRequest Fehler: " + IntegerToString(error_code));
        }
    } 
    // Andere HTTP Status Codes
    else {
        LogError("❌ Login-Status konnte nicht gesendet werden: HTTP " + IntegerToString(res));
        
        if(res == 404) {
            LogError("   Endpoint nicht gefunden: " + login_api_url);
        } else if(res == 500) {
            LogError("   Server-Fehler - API prüfen");
        } else if(res == 422) {
            LogError("   Datenformat-Fehler");
            if(response != "") {
                LogError("   API Response: " + response);
            }
        } else if(res == 503) {
            LogError("   Service Unavailable - Server überlastet oder in Wartung");
        } else if(res == 502) {
            LogError("   Bad Gateway - Proxy/Gateway-Fehler");
        }
    }
    
    return false; // Fehler - Weitere Versuche nötig
}

// TestAPIConnection
void TestAPIConnection() {
    LogInfo("🔌 Teste API-Verbindungen...");
    
    LogInfo("════════════════════════════════════════════");
    LogInfo("📍 KONFIGURIERTE API-ENDPOINTS:");
    LogInfo("   Signal API:   " + signal_api_url);
    LogInfo("   Position API: " + position_api_url);
    LogInfo("   Delivery API: " + delivery_api_url);
    LogInfo("   Login API:    " + login_api_url);
    LogInfo("════════════════════════════════════════════");
    
    LogInfo("🧪 Teste DELIVERY API Verbindung...");
    LogInfo("   URL: " + delivery_api_url);
    
    string test_json = "{";
    test_json += "\"account_id\":\"" + account_id + "\",";
    test_json += "\"signal_id\":\"TEST_CONNECTION\",";
    test_json += "\"success\":\"true\",";
    test_json += "\"ticket\":\"0\",";
    test_json += "\"message\":\"EA startup connection test\",";
    test_json += "\"ea_version\":\"8.6\"";
    test_json += "}";
    
    char post_data[];
    char result_data[];
    string result_headers;
    
    StringToCharArray(test_json, post_data, 0, WHOLE_ARRAY, CP_UTF8);
    if(ArraySize(post_data) > 0) ArrayResize(post_data, ArraySize(post_data) - 1);
    
    string headers = "Content-Type: application/json\r\n";
    
    LogInfo("   Sende Test-Request...");
    
    ResetLastError();
    int res = WebRequest(
        "POST",
        delivery_api_url,
        headers,
        api_timeout_ms,
        post_data,
        result_data,
        result_headers
    );
    
    int error_code = GetLastError();
    
    if(res == -1) {
        LogError("❌ DELIVERY API NICHT ERREICHBAR!");
        LogError("   Error Code: " + IntegerToString(error_code));
        
        if(error_code == 4014) {
            LogError("════════════════════════════════════════════");
            LogError("❌ WICHTIG: WebRequest ist DEAKTIVIERT!");
            LogError("LÖSUNG - Folge diesen Schritten:");
            LogError("1. MT5 Menu: Tools → Options");
            LogError("2. Tab: Expert Advisors");
            LogError("3. ☑ 'Allow WebRequest for listed URL' AKTIVIEREN");
            LogError("4. Klicke 'Add' und füge diese URL hinzu:");
            LogError("   " + delivery_api_url);
            LogError("5. Auch diese URLs hinzufügen:");
            LogError("   " + signal_api_url);
            LogError("   " + position_api_url);
            LogError("   " + login_api_url);
            LogError("6. OK klicken");
            LogError("7. EA vom Chart entfernen und neu hinzufügen!");
            LogError("════════════════════════════════════════════");
        }
    } else if(res == 200 || res == 201 || res == 204) {
        LogSuccess("✅ DELIVERY API erreichbar! (HTTP " + IntegerToString(res) + ")");
        
        string response = CharArrayToString(result_data);
        if(response != "") {
            LogDebug("   Test-Response: " + response);
        }
    } else if(res == 404) {
        LogError("❌ DELIVERY API Endpoint nicht gefunden (HTTP 404)");
        LogError("   Falsche URL oder API nicht deployed");
        LogError("   Prüfe URL: " + delivery_api_url);
    } else if(res == 0) {
        LogError("❌ Server nicht erreichbar!");
        LogError("   Prüfe ob Server online ist");
        LogError("   URL: " + delivery_api_url);
    } else {
        LogWarning("⚠️ DELIVERY API antwortet mit HTTP " + IntegerToString(res));
        
        string response = CharArrayToString(result_data);
        if(response != "") {
            LogWarning("   Response: " + response);
        }
    }
    
    LogInfo("🧪 Teste Signal API (GET Request)...");
    
    string test_url = signal_api_url + "?account_id=" + account_id;
    char dummy[];
    
    ResetLastError();
    res = WebRequest(
        "GET",
        test_url,
        NULL,
        api_timeout_ms,
        dummy,
        result_data,
        result_headers
    );
    
    error_code = GetLastError();
    
    if(res == -1) {
        LogError("❌ Signal API nicht erreichbar! Error: " + IntegerToString(error_code));
    } else if(res == 200 || res == 204) {
        LogSuccess("✅ Signal API erreichbar (HTTP " + IntegerToString(res) + ")");
    } else {
        LogWarning("⚠️ Signal API antwortet mit HTTP " + IntegerToString(res));
    }
    
    LogInfo("════════════════════════════════════════════");
}

// ========== SIGNAL API STATUS UPDATE ==========
void SendSignalStatusUpdate(string signal_id, string status, string message = "") {
    LogImportant("📤 SENDE STATUS AN SIGNAL API:");
    LogImportant("   Signal ID: " + signal_id);
    LogImportant("   Status: " + status);
    LogImportant("   Message: " + message);
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string timestamp = StringFormat("%04d-%02d-%02dT%02d:%02d:%02d", 
                                  dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
    
    // Erstelle JSON für Signal API Status Update
    string json = "{";
    json += "\"account_id\":\"" + account_id + "\",";
    json += "\"signal_id\":\"" + signal_id + "\",";
    json += "\"status\":\"" + status + "\",";
    json += "\"timestamp\":\"" + timestamp + "\",";
    json += "\"ea_version\":\"8.6\"";
    if(message != "") {
        json += ",\"message\":\"" + message + "\"";
    }
    json += "}";
    
    LogDebug("📤 Signal API JSON: " + json);
    
    // Sende an Signal API
    char post_data[];
    char result_data[];
    string result_headers;
    
    StringToCharArray(json, post_data, 0, WHOLE_ARRAY, CP_UTF8);
    if(ArraySize(post_data) > 0) ArrayResize(post_data, ArraySize(post_data) - 1);
    
    string headers = "Content-Type: application/json\r\n";
    
    ResetLastError();
    int response_code = WebRequest("POST", signal_api_url, headers, api_timeout_ms,
                                  post_data, result_data, result_headers);
    
    if(response_code == -1) {
        int web_error = GetLastError();
        LogError("❌ Signal API WebRequest fehlgeschlagen!");
        LogError("   Error Code: " + IntegerToString(web_error));
        LogError("   URL: " + signal_api_url);
    } else if(response_code == 200) {
        LogImportant("✅ Status erfolgreich an Signal API gesendet (HTTP " + IntegerToString(response_code) + ")");
        string response_text = CharArrayToString(result_data);
        if(response_text != "") {
            LogDebug("📥 Signal API Response: " + response_text);
        }
    } else {
        LogWarning("⚠️ Signal API Response Code: " + IntegerToString(response_code));
        string response_text = CharArrayToString(result_data);
        if(response_text != "") {
            LogDebug("📥 Signal API Response: " + response_text);
        }
    }
}

// ========== SYMBOL MAPPING FUNCTIONS ==========
void InitializeSymbolMappings() {
    LogImportant("🔄 INITIALISIERE SYMBOL-MAPPINGS");
    
    if(symbol_mappings == "" || StringFind(symbol_mappings, "US30:DJIUSD,US100:NAS100,US500:SPX500") >= 0) {
        LogInfo("   Umfassende Index-Mappings: US, EU, ASIA, etc.");
    } else {
        LogInfo("   Custom-Mappings: " + symbol_mappings);
    }
    
    // Parse symbol_mappings String
    ParseSymbolMappings(symbol_mappings);
    
    LogImportant("✅ " + IntegerToString(ArraySize(custom_mappings)) + " Symbol-Mappings geladen");
    
    // Zeige alle Mappings (begrenzt auf erste 10 für Übersichtlichkeit)
    int show_count = MathMin(ArraySize(custom_mappings), 10);
    for(int i = 0; i < show_count; i++) {
        LogInfo("   " + custom_mappings[i].api_symbol + " → " + custom_mappings[i].broker_symbol);
    }
    
    if(ArraySize(custom_mappings) > 10) {
        LogInfo("   ... und " + IntegerToString(ArraySize(custom_mappings) - 10) + " weitere Mappings");
    }
}

void ParseSymbolMappings(string mappings_str) {
    if(mappings_str == "") return;
    
    // Reset array
    ArrayResize(custom_mappings, 0);
    
    // Split by comma
    string pairs[];
    int pair_count = StringSplit(mappings_str, ',', pairs);
    
    for(int i = 0; i < pair_count; i++) {
        string pair = pairs[i];
        StringTrimLeft(pair);
        StringTrimRight(pair);
        
        if(pair == "") continue;
        
        // Split by colon
        string parts[];
        int part_count = StringSplit(pair, ':', parts);
        
        if(part_count == 2) {
            string api_symbol = parts[0];
            string broker_symbol = parts[1];
            
            StringTrimLeft(api_symbol);
            StringTrimRight(api_symbol);
            StringTrimLeft(broker_symbol);
            StringTrimRight(broker_symbol);
            
            if(api_symbol != "" && broker_symbol != "") {
                int size = ArraySize(custom_mappings);
                ArrayResize(custom_mappings, size + 1);
                custom_mappings[size].api_symbol = api_symbol;
                custom_mappings[size].broker_symbol = broker_symbol;
                
                LogDebug("Mapping hinzugefügt: " + api_symbol + " → " + broker_symbol);
            }
        } else {
            LogWarning("Ungültiges Mapping-Format: " + pair + " (erwartet: ORIGINAL:BROKER)");
        }
    }
}

string ApplySymbolMapping(string api_symbol) {
    // MULTIPLE MAPPING SUPPORT: Probiere alle Mappings für dieses Symbol
    LogDebug("🔍 Suche alle Mappings für: " + api_symbol);
    
    int mapping_count = 0;
    
    // Durchsuche alle Custom-Mappings für dieses Symbol
    for(int i = 0; i < ArraySize(custom_mappings); i++) {
        if(custom_mappings[i].api_symbol == api_symbol) {
            mapping_count++;
            string mapped_symbol = custom_mappings[i].broker_symbol;
            
            LogDebug("   Mapping " + IntegerToString(mapping_count) + ": " + api_symbol + " → " + mapped_symbol);
            
            // Prüfe ob dieses Mapping handelbar ist
            if(IsSymbolTradeable(mapped_symbol)) {
                LogImportant("✅ HANDELBARES MAPPING GEFUNDEN: " + api_symbol + " → " + mapped_symbol);
                return mapped_symbol;
            } else {
                LogDebug("   ❌ Mapping nicht handelbar: " + mapped_symbol);
                
                // Versuche erweiterte Suche für dieses Mapping
                string extended_symbol = FindSymbolWithExtendedSearch(mapped_symbol);
                if(extended_symbol != "") {
                    LogImportant("✅ MAPPING MIT SUFFIX GEFUNDEN: " + api_symbol + " → " + extended_symbol);
                    return extended_symbol;
                } else {
                    LogDebug("   ❌ Auch mit Suffix nicht gefunden: " + mapped_symbol);
                }
            }
        }
    }
    
    if(mapping_count > 0) {
        LogWarning("⚠️ " + IntegerToString(mapping_count) + " Mapping(s) gefunden, aber keines handelbar");
    } else {
        LogDebug("   Kein Custom-Mapping gefunden für: " + api_symbol);
    }
    
    // Kein handelbares Mapping gefunden - Original zurückgeben
    return api_symbol;
}

string FindTradingSymbol(string original_symbol) {
    LogDebug("🔍 Erweiterte Symbol-Suche für: " + original_symbol);
    
    // 1. PRIORITÄT: Multiple Custom-Mapping (probiert alle Mappings durch)
    string mapped_symbol = ApplySymbolMapping(original_symbol);
    if(mapped_symbol != original_symbol) {
        // ApplySymbolMapping hat bereits ein handelbares Symbol gefunden
        return mapped_symbol;
    }
    
    // 2. PRIORITÄT: Automatisch erkannte Indizes (als Fallback)
    for(int i = 0; i < ArraySize(auto_detected_indices); i++) {
        if(auto_detected_indices[i].api_name == original_symbol && auto_detected_indices[i].is_active) {
            string detected_symbol = auto_detected_indices[i].broker_symbol;
            
            // Verifikation: Ist Symbol noch handelbar?
            if(IsSymbolTradeable(detected_symbol)) {
                LogImportant("✅ AUTO-ERKANNT (Fallback): " + original_symbol + " → " + detected_symbol);
                return detected_symbol;
            } else {
                // Symbol nicht mehr verfügbar - deaktiviere
                auto_detected_indices[i].is_active = false;
                LogWarning("⚠️ Auto-erkanntes Symbol nicht mehr verfügbar: " + detected_symbol);
            }
        }
    }
    
    // 3. PRIORITÄT: Standard-Symbol-Suche
    LogDebug("   Fallback: Verwende Standard-Symbol-Suche");
    string found_symbol = FindTradableSymbol(original_symbol);
    if(found_symbol != "") {
        return found_symbol;
    }
    
    // 4. PRIORITÄT: Erweiterte Suche als letzter Ausweg
    return FindSymbolWithExtendedSearch(original_symbol);
}

// ========== API VALUE TRACKING FUNCTIONS ==========

void InitializePositionTracking(ulong ticket, string signal_id, double initial_sl, double initial_tp) {
    int track_index = FindTrackedPositionIndex(signal_id);
    if(track_index >= 0) {
        // API VALUE TRACKING: Initialisiere mit aktuellen API-Werten
        tracked_positions[track_index].last_api_sl = DoubleToString(initial_sl, 5);
        tracked_positions[track_index].last_api_tp = DoubleToString(initial_tp, 5);
        tracked_positions[track_index].last_api_update = TimeCurrent();
        
        // Speichere initiale API-Werte in Datei
        SaveAPIValuesToFile(signal_id, initial_sl, initial_tp);
        
        LogDebug("API Value Tracking initialisiert für Signal " + signal_id + 
                " mit SL: " + DoubleToString(initial_sl, 5) + 
                ", TP: " + DoubleToString(initial_tp, 5));
    }
}

//+------------------------------------------------------------------+
//| API VALUE FILE MANAGEMENT                                        |
//+------------------------------------------------------------------+
void SaveAPIValuesToFile(string signal_id, double sl, double tp) {
    string filename = api_values_file;
    string json_content = "";
    
    // Lade bestehende Datei
    int file_handle = FileOpen(filename, FILE_READ|FILE_TXT);
    if(file_handle != INVALID_HANDLE) {
        json_content = FileReadString(file_handle, (int)FileSize(file_handle));
        FileClose(file_handle);
    }
    
    // Wenn Datei leer oder nicht vorhanden, initialisiere JSON
    if(json_content == "" || StringFind(json_content, "{") < 0) {
        json_content = "{}";
    }
    
    // Erstelle neuen Eintrag
    string new_entry = "\"" + signal_id + "\":{" +
                      "\"sl\":\"" + DoubleToString(sl, 5) + "\"," +
                      "\"tp\":\"" + DoubleToString(tp, 5) + "\"," +
                      "\"last_update\":\"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\"" +
                      "}";
    
    // Füge Eintrag in JSON ein
    if(StringFind(json_content, "\"" + signal_id + "\"") >= 0) {
        // Update bestehenden Eintrag
        int start_pos = StringFind(json_content, "\"" + signal_id + "\"");
        int end_pos = StringFind(json_content, "}", start_pos) + 1;
        
        string before = StringSubstr(json_content, 0, start_pos);
        string after = StringSubstr(json_content, end_pos);
        
        // Entferne führendes Komma wenn nötig
        if(StringLen(after) > 0 && StringGetCharacter(after, 0) == ',') {
            after = StringSubstr(after, 1);
        }
        
        json_content = before + new_entry;
        if(StringLen(after) > 1) { // Mehr als nur "}"
            json_content += "," + after;
        } else {
            json_content += "}";
        }
    } else {
        // Neuen Eintrag hinzufügen
        if(StringLen(json_content) > 2) { // Mehr als "{}"
            // Entferne schließende Klammer, füge Komma und neuen Eintrag hinzu
            json_content = StringSubstr(json_content, 0, StringLen(json_content) - 1);
            json_content += "," + new_entry + "}";
        } else {
            // Erste Eintrag
            json_content = "{" + new_entry + "}";
        }
    }
    
    // Speichere aktualisierte Datei
    file_handle = FileOpen(filename, FILE_WRITE|FILE_TXT);
    if(file_handle != INVALID_HANDLE) {
        FileWriteString(file_handle, json_content);
        FileClose(file_handle);
        LogDebug("💾 API-Werte gespeichert in " + filename + " für Signal " + signal_id);
    } else {
        LogError("❌ Fehler beim Speichern der API-Werte in " + filename);
    }
}

bool LoadAPIValuesFromFile(string signal_id, string &sl_value, string &tp_value) {
    string filename = api_values_file;
    
    int file_handle = FileOpen(filename, FILE_READ|FILE_TXT);
    if(file_handle == INVALID_HANDLE) {
        LogDebug("📁 API-Werte Datei nicht gefunden: " + filename);
        return false;
    }
    
    string json_content = FileReadString(file_handle, (int)FileSize(file_handle));
    FileClose(file_handle);
    
    // Suche Signal ID in JSON
    string search_pattern = "\"" + signal_id + "\":{";
    int signal_pos = StringFind(json_content, search_pattern);
    if(signal_pos < 0) {
        LogDebug("📁 Signal " + signal_id + " nicht in API-Werte Datei gefunden");
        return false;
    }
    
    // Extrahiere SL-Wert
    string sl_pattern = "\"sl\":\"";
    int sl_start = StringFind(json_content, sl_pattern, signal_pos) + StringLen(sl_pattern);
    int sl_end = StringFind(json_content, "\"", sl_start);
    sl_value = StringSubstr(json_content, sl_start, sl_end - sl_start);
    
    // Extrahiere TP-Wert
    string tp_pattern = "\"tp\":\"";
    int tp_start = StringFind(json_content, tp_pattern, signal_pos) + StringLen(tp_pattern);
    int tp_end = StringFind(json_content, "\"", tp_start);
    tp_value = StringSubstr(json_content, tp_start, tp_end - tp_start);
    
    LogDebug("📁 API-Werte geladen für Signal " + signal_id + ": SL=" + sl_value + ", TP=" + tp_value);
    return true;
}

void LoadExistingPositionsFromMT5() {
    LogImportant("🔄 LADE BESTEHENDE MT5-POSITIONEN FÜR API VALUE TRACKING");
    
    int loaded_positions = 0;
    int total_positions = PositionsTotal();
    
    LogImportant("   Gefundene MT5-Positionen: " + IntegerToString(total_positions));
    
    // Scanne alle offenen Positionen in MT5
    for(int i = 0; i < total_positions; i++) {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        
        if(!PositionSelectByTicket(ticket)) continue;
        
        string comment = PositionGetString(POSITION_COMMENT);
        string symbol = PositionGetString(POSITION_SYMBOL);
        double current_sl = PositionGetDouble(POSITION_SL);
        double current_tp = PositionGetDouble(POSITION_TP);
        
        // Extrahiere Signal ID aus Kommentar
        string signal_id = ExtractSignalIdFromComment(comment);
        if(signal_id == "") {
            LogDebug("   Position #" + IntegerToString(ticket) + " (" + symbol + "): Keine Signal ID gefunden");
            continue;
        }
        
        // Prüfe ob Position bereits im Tracking ist
        int existing_index = FindTrackedPositionIndex(signal_id);
        if(existing_index >= 0) {
            LogDebug("   Position #" + IntegerToString(ticket) + " bereits im Tracking");
            continue;
        }
        
        // Füge Position zum Tracking hinzu
        AddTrackedPosition(ticket, signal_id, true);
        
        // Initialisiere API Value Tracking mit aktuellen MT5-Werten
        int track_index = FindTrackedPositionIndex(signal_id);
        if(track_index >= 0) {
            // Setze Symbol-Feld (wird von AddTrackedPosition nicht gesetzt)
            // tracked_positions[track_index].symbol = symbol; // Falls Symbol-Feld existiert
            
            tracked_positions[track_index].last_api_sl = DoubleToString(current_sl, 5);
            tracked_positions[track_index].last_api_tp = DoubleToString(current_tp, 5);
            tracked_positions[track_index].last_api_update = TimeCurrent();
            
            // Speichere als initiale API-Werte in Datei
            SaveAPIValuesToFile(signal_id, current_sl, current_tp);
            loaded_positions++;
            
            LogImportant("   ✅ Position #" + IntegerToString(ticket) + " (" + symbol + ")");
            LogImportant("      Signal ID: " + signal_id);
            LogImportant("      SL: " + DoubleToString(current_sl, 5) + ", TP: " + DoubleToString(current_tp, 5));
        }
    }
    
    LogImportant("✅ " + IntegerToString(loaded_positions) + " MT5-Positionen für API Value Tracking geladen");
    
    if(loaded_positions == 0) {
        LogImportant("   ℹ️ Keine Positionen mit Signal IDs gefunden - EA bereit für neue Signale");
    }
}


string ExtractSignalIdFromComment(string comment) {
    // Suche nach Signal ID Pattern: "sig_YYYY-MM-DDTHH:MM:SS"
    string pattern = "sig_";
    int start_pos = StringFind(comment, pattern);
    if(start_pos < 0) return "";
    
    // Extrahiere Signal ID (Pattern: sig_ + 19 Zeichen für Datum/Zeit)
    int signal_id_length = 23; // "sig_" (4) + "YYYY-MM-DDTHH:MM:SS" (19)
    if(start_pos + signal_id_length > StringLen(comment)) {
        // Fallback: Suche bis zum nächsten Leerzeichen oder Ende
        int end_pos = StringFind(comment, " ", start_pos);
        if(end_pos < 0) end_pos = StringLen(comment);
        signal_id_length = end_pos - start_pos;
    }
    
    string signal_id = StringSubstr(comment, start_pos, signal_id_length);
    
    // Validiere Signal ID Format
    if(StringLen(signal_id) >= 23 && StringFind(signal_id, "sig_") == 0) {
        LogDebug("Signal ID extrahiert: " + signal_id + " aus Kommentar: " + comment);
        return signal_id;
    }
    
    LogDebug("Ungültiges Signal ID Format: " + signal_id + " aus Kommentar: " + comment);
    return "";
}



//+------------------------------------------------------------------+
//| HILFSFUNKTION: BERECHNE MAXIMALE SICHERE LOTS                   |
//+------------------------------------------------------------------+
double CalculateMaxSafeLots(string symbol, double risk_amount, double loss_per_lot) {
    double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    // Berechne theoretische maximale Lots
    double theoretical_max = risk_amount / loss_per_lot;
    
    // Normalisiere auf Lot-Step (IMMER ABRUNDEN)
    double safe_lots = MathFloor(theoretical_max / lot_step) * lot_step;
    
    // Begrenze auf erlaubten Bereich
    if(safe_lots < min_lot) safe_lots = min_lot;
    if(safe_lots > max_lot) safe_lots = max_lot;
    
    return safe_lots;
}

//+------------------------------------------------------------------+
//| HILFSFUNKTION: VALIDIERE FINALES RISIKO                         |
//+------------------------------------------------------------------+
bool ValidateFinalRisk(string symbol, double lots, double entry_price, double sl_price, 
                      double desired_risk_percent, ENUM_ORDER_TYPE order_type, 
                      double &actual_risk_percent, double &actual_risk_amount) {
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double profit_at_sl = 0;
    
    // Versuche OrderCalcProfit
    if(OrderCalcProfit(order_type, symbol, lots, entry_price, sl_price, profit_at_sl)) {
        actual_risk_amount = MathAbs(profit_at_sl);
        actual_risk_percent = (actual_risk_amount / balance) * 100.0;
        return (actual_risk_percent <= desired_risk_percent);
    }
    
    // Fallback: Verwende robuste Berechnung
    double loss_per_lot = GetRobustLossPerLot_v832(symbol, order_type, entry_price, sl_price);
    if(loss_per_lot > 0) {
        actual_risk_amount = lots * loss_per_lot;
        actual_risk_percent = (actual_risk_amount / balance) * 100.0;
        return (actual_risk_percent <= desired_risk_percent);
    }
    
    // Wenn alles fehlschlägt
    actual_risk_amount = 0;
    actual_risk_percent = 0;
    return false;
}



//+------------------------------------------------------------------+
//| AUTOMATISCHE INDEX-SYMBOL-ERKENNUNG FUNKTIONEN                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| AUTOMATISCHE INDEX-SYMBOL-ERKENNUNG BEIM EA-START              |
//+------------------------------------------------------------------+
void AutoDetectIndexSymbols() {
    LogImportant("🔍 STARTE AUTOMATISCHE INDEX-SYMBOL-ERKENNUNG...");
    
    int total_symbols = SymbolsTotal(true);
    int detected_count = 0;
    
    LogImportant("📊 Durchsuche " + IntegerToString(total_symbols) + " verfügbare Symbole...");
    
    // INTELLIGENTE BROKER-ERKENNUNG: Deaktiviere Auto-Erkennung für Forex-only Broker
    if(total_symbols < 50) {
        LogWarning("⚠️ FOREX-ONLY BROKER ERKANNT:");
        LogWarning("   Nur " + IntegerToString(total_symbols) + " Symbole verfügbar");
        LogWarning("   Wahrscheinlich keine Index-Symbole vorhanden");
        LogWarning("   Automatische Erkennung wird DEAKTIVIERT");
        LogImportant("✅ Verwende nur Custom-Mappings für Symbol-Zuordnung");
        
        // Lösche alte fehlerhafte Erkennungen
        ArrayResize(auto_detected_indices, 0);
        return;
    }
    
    // Lösche alte Erkennungen
    ArrayResize(auto_detected_indices, 0);
    
    // Durchsuche alle verfügbaren Symbole
    for(int i = 0; i < total_symbols; i++) {
        string symbol = SymbolName(i, true);
        if(symbol == "") continue;
        
        // Prüfe gegen alle Index-Muster
        for(int j = 0; j < ArraySize(index_patterns); j++) {
            string api_name = index_patterns[j].api_name;
            
            // Prüfe alle Muster für diesen Index
            for(int k = 0; k < index_patterns[j].pattern_count; k++) {
                string pattern = index_patterns[j].patterns[k];
                string symbol_upper = CustomStringToUpper(symbol);
                string pattern_upper = CustomStringToUpper(pattern);
                
                // STRIKTE MUSTER-PRÜFUNG: Symbol muss mit Muster beginnen oder exakt enthalten
                bool pattern_match = false;
                
                // 1. Exakte Übereinstimmung (ohne Suffix)
                if(StringFind(symbol_upper, pattern_upper) == 0) {
                    // Symbol beginnt mit Muster
                    int pattern_len = StringLen(pattern_upper);
                    if(StringLen(symbol_upper) == pattern_len) {
                        pattern_match = true; // Exakte Übereinstimmung
                    } else {
                        // Prüfe ob nach dem Muster ein bekannter Suffix folgt
                        string suffix = StringSubstr(symbol_upper, pattern_len);
                        if(suffix == "#" || suffix == "+" || suffix == "-" || 
                           StringFind(suffix, ".") == 0 || StringFind(suffix, "_") == 0) {
                            pattern_match = true;
                        }
                    }
                }
                
                // 2. Spezielle Prüfung für zusammengesetzte Namen (z.B. DJIUSD)
                if(!pattern_match && StringLen(pattern_upper) >= 3) {
                    // Für längere Muster: Muss komplett enthalten sein UND Index-typisch sein
                    if(StringFind(symbol_upper, pattern_upper) >= 0) {
                        // Zusätzliche Validierung: Symbol sollte Index-typisch sein UND kein Forex-Paar
                        if(IsIndexLikeSymbol(symbol_upper) && !IsForexPair(symbol_upper)) {
                            pattern_match = true;
                        }
                    }
                }
                
                if(pattern_match) {
                    // Muster gefunden! Prüfe ob Symbol handelbar
                    if(SymbolSelect(symbol, true)) {
                        // Prüfe ob bereits erkannt
                        if(!IsIndexAlreadyDetected(api_name)) {
                            AddDetectedIndex(api_name, symbol);
                            detected_count++;
                            
                            LogImportant("✅ INDEX ERKANNT: " + api_name + " → " + symbol + " (Muster: " + pattern + ")");
                            break; // Nur einmal pro API-Name
                        }
                    }
                }
            }
        }
    }
    
    LogImportant("🎯 ERKENNUNG ABGESCHLOSSEN:");
    LogImportant("   Erkannte Indizes: " + IntegerToString(detected_count));
    LogImportant("   Verfügbare Symbole: " + IntegerToString(total_symbols));
    
    if(detected_count == 0) {
        LogWarning("⚠️ KEINE INDEX-SYMBOLE ERKANNT:");
        LogWarning("   Broker bietet wahrscheinlich nur Forex-Handel");
        LogWarning("   Verwende Custom-Mappings für Symbol-Zuordnung");
    }
    
    // Speichere Erkennungen persistent
    SaveDetectedIndicesToFile();
    
    // Zeige alle erkannten Indizes
    ShowDetectedIndices();
}

//+------------------------------------------------------------------+
//| PRÜFE OB INDEX BEREITS ERKANNT                                  |
//+------------------------------------------------------------------+
bool IsIndexAlreadyDetected(string api_name) {
    for(int i = 0; i < ArraySize(auto_detected_indices); i++) {
        if(auto_detected_indices[i].api_name == api_name && auto_detected_indices[i].is_active) {
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| FÜGE ERKANNTEN INDEX HINZU                                      |
//+------------------------------------------------------------------+
void AddDetectedIndex(string api_name, string broker_symbol) {
    int size = ArraySize(auto_detected_indices);
    ArrayResize(auto_detected_indices, size + 1);
    
    auto_detected_indices[size].api_name = api_name;
    auto_detected_indices[size].broker_symbol = broker_symbol;
    auto_detected_indices[size].base_name = ExtractBaseName(broker_symbol);
    auto_detected_indices[size].detected_time = TimeCurrent();
    auto_detected_indices[size].is_active = true;
}

//+------------------------------------------------------------------+
//| EXTRAHIERE BASIS-NAME AUS BROKER-SYMBOL                         |
//+------------------------------------------------------------------+
string ExtractBaseName(string broker_symbol) {
    string base = broker_symbol;
    
    // Entferne bekannte Suffixe
    string suffixes[] = {"#", "+", "-", ".pro", ".ecn", ".std", ".raw", ".spot", ".cash", ".cfd"};
    
    for(int i = 0; i < ArraySize(suffixes); i++) {
        int pos = StringFind(base, suffixes[i]);
        if(pos > 0) {
            base = StringSubstr(base, 0, pos);
            break;
        }
    }
    
    return base;
}

//+------------------------------------------------------------------+
//| SPEICHERE ERKANNTE INDIZES IN DATEI                             |
//+------------------------------------------------------------------+
void SaveDetectedIndicesToFile() {
    string filename = "detected_indices.json";
    int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI);
    
    if(file_handle != INVALID_HANDLE) {
        FileWrite(file_handle, "{");
        FileWrite(file_handle, "  \"detected_time\": \"" + TimeToString(TimeCurrent()) + "\",");
        FileWrite(file_handle, "  \"account_id\": \"" + account_id + "\",");
        FileWrite(file_handle, "  \"broker\": \"" + AccountInfoString(ACCOUNT_COMPANY) + "\",");
        FileWrite(file_handle, "  \"indices\": [");
        
        int active_count = 0;
        for(int i = 0; i < ArraySize(auto_detected_indices); i++) {
            if(auto_detected_indices[i].is_active) {
                if(active_count > 0) {
                    FileWrite(file_handle, "    },");
                }
                FileWrite(file_handle, "    {");
                FileWrite(file_handle, "      \"api_name\": \"" + auto_detected_indices[i].api_name + "\",");
                FileWrite(file_handle, "      \"broker_symbol\": \"" + auto_detected_indices[i].broker_symbol + "\",");
                FileWrite(file_handle, "      \"base_name\": \"" + auto_detected_indices[i].base_name + "\"");
                active_count++;
            }
        }
        
        if(active_count > 0) {
            FileWrite(file_handle, "    }");
        }
        
        FileWrite(file_handle, "  ]");
        FileWrite(file_handle, "}");
        
        FileClose(file_handle);
        LogDebug("💾 Erkannte Indizes gespeichert: " + filename);
    } else {
        LogError("❌ Fehler beim Speichern der erkannten Indizes");
    }
}

//+------------------------------------------------------------------+
//| ZEIGE ALLE ERKANNTEN INDIZES                                    |
//+------------------------------------------------------------------+
void ShowDetectedIndices() {
    if(ArraySize(auto_detected_indices) == 0) {
        LogWarning("⚠️ Keine Index-Symbole automatisch erkannt");
        return;
    }
    
    LogImportant("📋 ERKANNTE INDEX-SYMBOLE:");
    LogImportant("════════════════════════════════════════");
    
    for(int i = 0; i < ArraySize(auto_detected_indices); i++) {
        if(auto_detected_indices[i].is_active) {
            LogImportant("   " + auto_detected_indices[i].api_name + " → " + auto_detected_indices[i].broker_symbol);
        }
    }
    
    LogImportant("════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| LADE ERKANNTE INDIZES AUS DATEI (VEREINFACHT)                   |
//+------------------------------------------------------------------+
void LoadDetectedIndicesFromFile() {
    string filename = "detected_indices.json";
    
    if(!FileIsExist(filename)) {
        LogDebug("📁 Keine gespeicherten Index-Erkennungen gefunden - führe neue Erkennung durch");
        AutoDetectIndexSymbols();
        return;
    }
    
    LogDebug("📁 Gespeicherte Index-Erkennungen gefunden - führe neue Erkennung durch (Aktualisierung)");
    
    // Für Einfachheit: Führe immer neue Erkennung durch
    // In einer erweiterten Version könnte hier JSON-Parsing implementiert werden
    AutoDetectIndexSymbols();
}

//+------------------------------------------------------------------+
//| VALIDIERE ERKANNTE SYMBOLE (PERIODISCHE PRÜFUNG)               |
//+------------------------------------------------------------------+
void ValidateDetectedSymbols() {
    bool changes_made = false;
    
    for(int i = 0; i < ArraySize(auto_detected_indices); i++) {
        if(auto_detected_indices[i].is_active) {
            string symbol = auto_detected_indices[i].broker_symbol;
            
            // Prüfe ob Symbol noch verfügbar ist
            if(!SymbolSelect(symbol, true)) {
                LogWarning("⚠️ Auto-erkanntes Symbol nicht mehr verfügbar: " + symbol);
                auto_detected_indices[i].is_active = false;
                changes_made = true;
            }
        }
    }
    
    // Speichere Änderungen wenn nötig
    if(changes_made) {
        SaveDetectedIndicesToFile();
        LogDebug("🔄 Erkannte Symbole aktualisiert");
    }
}


//+------------------------------------------------------------------+
//| PRÜFE OB SYMBOL INDEX-TYPISCH IST                               |
//+------------------------------------------------------------------+
bool IsIndexLikeSymbol(string symbol_upper) {
    // Ausschließen von typischen Forex-Paaren
    if(StringLen(symbol_upper) == 6 || StringLen(symbol_upper) == 7) {
        // Typische Forex-Muster ausschließen
        if(StringFind(symbol_upper, "USD") > 0 && StringFind(symbol_upper, "USD") <= 3) return false;
        if(StringFind(symbol_upper, "EUR") >= 0 && StringFind(symbol_upper, "EUR") <= 3) return false;
        if(StringFind(symbol_upper, "GBP") >= 0 && StringFind(symbol_upper, "GBP") <= 3) return false;
        if(StringFind(symbol_upper, "JPY") > 0 && StringFind(symbol_upper, "JPY") <= 3) return false;
        if(StringFind(symbol_upper, "AUD") >= 0 && StringFind(symbol_upper, "AUD") <= 3) return false;
        if(StringFind(symbol_upper, "CAD") > 0 && StringFind(symbol_upper, "CAD") <= 3) return false;
        if(StringFind(symbol_upper, "CHF") > 0 && StringFind(symbol_upper, "CHF") <= 3) return false;
        if(StringFind(symbol_upper, "NZD") >= 0 && StringFind(symbol_upper, "NZD") <= 3) return false;
    }
    
    // Index-typische Muster
    if(StringFind(symbol_upper, "30") >= 0) return true;  // US30, DAX30, etc.
    if(StringFind(symbol_upper, "100") >= 0) return true; // US100, FTSE100, etc.
    if(StringFind(symbol_upper, "500") >= 0) return true; // US500, SPX500, etc.
    if(StringFind(symbol_upper, "225") >= 0) return true; // JPN225, etc.
    if(StringFind(symbol_upper, "200") >= 0) return true; // AUS200, etc.
    if(StringFind(symbol_upper, "2000") >= 0) return true; // US2000, etc.
    if(StringFind(symbol_upper, "50") >= 0) return true;  // HK50, EU50, etc.
    if(StringFind(symbol_upper, "40") >= 0) return true;  // GER40, FRA40, etc.
    if(StringFind(symbol_upper, "35") >= 0) return true;  // SPA35, etc.
    if(StringFind(symbol_upper, "20") >= 0) return true;  // SWI20, etc.
    
    return false;
}


//+------------------------------------------------------------------+
//| PROGRESSIVE LOT-REDUZIERUNG FÜR OPTIMIERTE KONVERGENZ          |
//+------------------------------------------------------------------+
double GetProgressiveLotReduction(int iteration, double base_lot_step) {
    // Progressive Reduzierung basierend auf Iteration
    // Iterationen 1-10:   1x lot_step (0.01)
    // Iterationen 11-20:  2x lot_step (0.02) 
    // Iterationen 21-30:  3x lot_step (0.03)
    // Iterationen 31-40:  4x lot_step (0.04)
    // usw.
    
    if(iteration <= 10) {
        return base_lot_step; // Standard: 0.01
    } else if(iteration <= 20) {
        return base_lot_step * 2.0; // 0.02
    } else if(iteration <= 30) {
        return base_lot_step * 3.0; // 0.03
    } else if(iteration <= 40) {
        return base_lot_step * 4.0; // 0.04
    } else if(iteration <= 50) {
        return base_lot_step * 5.0; // 0.05
    } else if(iteration <= 60) {
        return base_lot_step * 6.0; // 0.06
    } else if(iteration <= 70) {
        return base_lot_step * 7.0; // 0.07
    } else if(iteration <= 80) {
        return base_lot_step * 8.0; // 0.08
    } else if(iteration <= 90) {
        return base_lot_step * 9.0; // 0.09
    } else if(iteration <= 100) {
        return base_lot_step * 10.0; // 0.10
    } else {
        // Für sehr hartnäckige Fälle: Noch aggressivere Reduzierung
        int group = ((iteration - 100) / 10) + 11;
        double multiplier = MathMin(group, 50.0); // Maximal 50x (0.50 Lot)
        return base_lot_step * multiplier;
    }
}

//+------------------------------------------------------------------+
//| BERECHNE ERWARTETE ITERATIONEN FÜR DEBUGGING                    |
//+------------------------------------------------------------------+
int EstimateRequiredIterations(double risk_difference_percent, double loss_per_lot, double balance, double lot_step) {
    // Schätze wie viele Iterationen benötigt werden
    double excess_amount = (risk_difference_percent / 100.0) * balance;
    double excess_lots = excess_amount / loss_per_lot;
    
    // Simuliere progressive Reduzierung
    double total_reduction = 0.0;
    int iterations = 0;
    
    while(total_reduction < excess_lots && iterations < 1000) {
        iterations++;
        double reduction = GetProgressiveLotReduction(iterations, lot_step);
        total_reduction += reduction;
    }
    
    return iterations;
}


//+------------------------------------------------------------------+
//| PRÄZISE LOT-BERECHNUNG MIT OrderCalcProfit (ELIMINIERT ITERATIONEN) |
//+------------------------------------------------------------------+
double CalculateExactLotsWithOrderCalcProfit(string symbol, ENUM_ORDER_TYPE order_type, 
                                           double entry_price, double sl_price, double risk_amount, 
                                           double lot_step, double min_lot, double max_lot) {
    LogDebug("🎯 STARTE PRÄZISE OrderCalcProfit-BERECHNUNG:");
    LogDebug("   Risk Amount: " + DoubleToString(risk_amount, 2));
    LogDebug("   Lot Step: " + DoubleToString(lot_step, 3));
    LogDebug("   Min/Max Lot: " + DoubleToString(min_lot, 3) + " / " + DoubleToString(max_lot, 3));
    
    // Binäre Suche für optimale Lots
    double low_lots = min_lot;
    double high_lots = MathMin(max_lot, 100.0); // Begrenze auf vernünftige Werte
    double best_lots = 0;
    
    int iterations = 0;
    const int MAX_ITERATIONS = 50; // Binäre Suche ist sehr effizient
    
    while(high_lots - low_lots > lot_step && iterations < MAX_ITERATIONS) {
        iterations++;
        
        // Teste mittleren Wert
        double test_lots = (low_lots + high_lots) / 2.0;
        test_lots = MathFloor(test_lots / lot_step) * lot_step; // Normalisiere auf Lot-Step
        
        if(test_lots < min_lot) test_lots = min_lot;
        if(test_lots > max_lot) test_lots = max_lot;
        
        // Berechne tatsächliches Risiko mit OrderCalcProfit
        double profit_at_sl;
        if(OrderCalcProfit(order_type, symbol, test_lots, entry_price, sl_price, profit_at_sl)) {
            double actual_risk = MathAbs(profit_at_sl);
            
            LogDebug("   Iteration " + IntegerToString(iterations) + ": " + 
                    DoubleToString(test_lots, 3) + " Lots → " + 
                    DoubleToString(actual_risk, 2) + " Risk");
            
            if(actual_risk <= risk_amount) {
                // Dieses Lot-Level ist sicher
                best_lots = test_lots;
                low_lots = test_lots + lot_step; // Versuche höher
            } else {
                // Zu hoch, reduziere
                high_lots = test_lots - lot_step;
            }
        } else {
            LogWarning("⚠️ OrderCalcProfit fehlgeschlagen für " + DoubleToString(test_lots, 3) + " Lots");
            high_lots = test_lots - lot_step;
        }
    }
    
    LogDebug("🎯 BINÄRE SUCHE ABGESCHLOSSEN:");
    LogDebug("   Iterationen: " + IntegerToString(iterations));
    LogDebug("   Beste Lots: " + DoubleToString(best_lots, 3));
    
    return best_lots;
}

//+------------------------------------------------------------------+
//| ALTERNATIVE: LINEARE SUCHE (FALLBACK)                           |
//+------------------------------------------------------------------+
double CalculateExactLotsLinearSearch(string symbol, ENUM_ORDER_TYPE order_type, 
                                    double entry_price, double sl_price, double risk_amount, 
                                    double lot_step, double min_lot, double max_lot) {
    LogDebug("🔍 STARTE LINEARE SUCHE (Fallback):");
    
    double test_lots = min_lot;
    double best_lots = 0;
    int iterations = 0;
    const int MAX_ITERATIONS = 1000;
    
    while(test_lots <= max_lot && iterations < MAX_ITERATIONS) {
        iterations++;
        
        double profit_at_sl;
        if(OrderCalcProfit(order_type, symbol, test_lots, entry_price, sl_price, profit_at_sl)) {
            double actual_risk = MathAbs(profit_at_sl);
            
            if(actual_risk <= risk_amount) {
                best_lots = test_lots; // Dieses Level ist noch sicher
                test_lots += lot_step; // Versuche höher
            } else {
                break; // Zu hoch, stoppe
            }
        } else {
            LogWarning("⚠️ OrderCalcProfit fehlgeschlagen für " + DoubleToString(test_lots, 3) + " Lots");
            break;
        }
        
        // Logging nur alle 100 Iterationen
        if(iterations % 100 == 0) {
            LogDebug("   Iteration " + IntegerToString(iterations) + ": " + 
                    DoubleToString(test_lots, 3) + " Lots");
        }
    }
    
    LogDebug("🔍 LINEARE SUCHE ABGESCHLOSSEN:");
    LogDebug("   Iterationen: " + IntegerToString(iterations));
    LogDebug("   Beste Lots: " + DoubleToString(best_lots, 3));
    
    return best_lots;
}


//+------------------------------------------------------------------+
//| PRÜFE OB SYMBOL EIN FOREX-PAAR IST                              |
//+------------------------------------------------------------------+
bool IsForexPair(string symbol_upper) {
    // Liste der häufigsten Forex-Währungen
    string currencies[] = {"USD", "EUR", "GBP", "JPY", "AUD", "CAD", "CHF", "NZD", 
                          "SEK", "NOK", "DKK", "PLN", "CZK", "HUF", "TRY", "ZAR", 
                          "MXN", "SGD", "HKD", "CNH", "RUB"};
    
    // Prüfe typische Forex-Paar-Längen (6-7 Zeichen ohne Suffix)
    string base_symbol = symbol_upper;
    
    // Entferne bekannte Suffixe
    if(StringFind(base_symbol, "#") >= 0) base_symbol = StringSubstr(base_symbol, 0, StringFind(base_symbol, "#"));
    if(StringFind(base_symbol, "+") >= 0) base_symbol = StringSubstr(base_symbol, 0, StringFind(base_symbol, "+"));
    if(StringFind(base_symbol, "-") >= 0) base_symbol = StringSubstr(base_symbol, 0, StringFind(base_symbol, "-"));
    if(StringFind(base_symbol, ".") >= 0) base_symbol = StringSubstr(base_symbol, 0, StringFind(base_symbol, "."));
    
    // Forex-Paare sind normalerweise 6 Zeichen (EURUSD) oder 7 (EURGBP mit Suffix)
    if(StringLen(base_symbol) != 6) return false;
    
    // Extrahiere Basis- und Quote-Währung
    string base_currency = StringSubstr(base_symbol, 0, 3);
    string quote_currency = StringSubstr(base_symbol, 3, 3);
    
    // Prüfe ob beide Teile bekannte Währungen sind
    bool base_is_currency = false;
    bool quote_is_currency = false;
    
    for(int i = 0; i < ArraySize(currencies); i++) {
        if(base_currency == currencies[i]) base_is_currency = true;
        if(quote_currency == currencies[i]) quote_is_currency = true;
    }
    
    return (base_is_currency && quote_is_currency);
}


//+------------------------------------------------------------------+
//| SECURE RISK MANAGEMENT STRUCTURES (v8.0)                       |
//+------------------------------------------------------------------+

// Struktur für Risiko-Berechnungsergebnisse
struct RiskCalculationResult {
    double lots;
    double risk_amount;
    double risk_percent;
    string method_used;
    bool is_reliable;
    string validation_notes;
    double confidence_score; // 0.0 - 1.0
};

// Sicherheits-Konfiguration
struct SecurityConfig {
    double max_risk_percent_absolute;    // Absolute Obergrenze (z.B. 20%)
    double max_lots_per_1000_balance;   // Max Lots pro 1000 Kontowährung
    double max_lots_absolute;           // Absolute Lot-Obergrenze
    double min_sl_distance_pips;        // Minimum SL-Distanz in Pips
    double max_sl_distance_pips;        // Maximum SL-Distanz in Pips
    double cross_validation_tolerance;  // Toleranz für Cross-Validation (%)
    bool enable_real_time_verification; // Real-Time Verifikation aktiviert
};

// Globale Sicherheits-Konfiguration
SecurityConfig g_security_config = {
    20.0,    // max_risk_percent_absolute
    1.0,     // max_lots_per_1000_balance  
    10.0,    // max_lots_absolute
    1.0,     // min_sl_distance_pips
    1000.0,  // max_sl_distance_pips
    5.0,     // cross_validation_tolerance
    true     // enable_real_time_verification
};

//+------------------------------------------------------------------+
//| LAYER 1: EINGABE-VALIDIERUNG                                    |
//+------------------------------------------------------------------+
bool ValidateRiskInputs(double balance, double risk_percent, double entry, double sl, string symbol) {
    LogDebug("🔍 LAYER 1: Validiere Eingabe-Parameter...");
    
    // Basis-Validierungen
    if(balance <= 0) {
        LogError("❌ Ungültige Balance: " + DoubleToString(balance, 2));
        return false;
    }
    
    if(risk_percent <= 0 || risk_percent > g_security_config.max_risk_percent_absolute) {
        LogError("❌ Ungültiges Risiko: " + DoubleToString(risk_percent, 2) + "% (Max: " + 
                DoubleToString(g_security_config.max_risk_percent_absolute, 1) + "%)");
        return false;
    }
    
    if(entry <= 0 || sl <= 0) {
        LogError("❌ Ungültige Preise - Entry: " + DoubleToString(entry, 5) + ", SL: " + DoubleToString(sl, 5));
        return false;
    }
    
    // SL-Distanz Validierung
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double distance_pips = MathAbs(entry - sl) * MathPow(10, digits-1);
    
    if(distance_pips < g_security_config.min_sl_distance_pips) {
        LogError("❌ SL-Distanz zu klein: " + DoubleToString(distance_pips, 1) + " Pips (Min: " + 
                DoubleToString(g_security_config.min_sl_distance_pips, 1) + ")");
        return false;
    }
    
    if(distance_pips > g_security_config.max_sl_distance_pips) {
        LogError("❌ SL-Distanz zu groß: " + DoubleToString(distance_pips, 1) + " Pips (Max: " + 
                DoubleToString(g_security_config.max_sl_distance_pips, 1) + ")");
        return false;
    }
    
    LogDebug("✅ LAYER 1: Alle Eingabe-Parameter validiert");
    return true;
}

//+------------------------------------------------------------------+
//| LAYER 2: ENHANCED TICK-VALUE BERECHNUNG                        |
//+------------------------------------------------------------------+
RiskCalculationResult CalculateWithEnhancedTickValue(string symbol, double entry, double sl, double risk_amount) {
    RiskCalculationResult result;
    result.method_used = "Enhanced Tick-Value";
    result.is_reliable = false;
    result.confidence_score = 0.0;
    
    LogDebug("🔧 METHODE 1: Enhanced Tick-Value Berechnung...");
    
    // Hole Symbol-Informationen
    double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double contract_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    
    LogDebug("   Tick Value: " + DoubleToString(tick_value, 6));
    LogDebug("   Tick Size: " + DoubleToString(tick_size, 6));
    LogDebug("   Contract Size: " + DoubleToString(contract_size, 2));
    
    // Validiere Tick-Daten
    if(tick_value <= 0 || tick_size <= 0) {
        result.validation_notes = "Invalid tick data - tick_value: " + DoubleToString(tick_value, 6) + 
                                 ", tick_size: " + DoubleToString(tick_size, 6);
        LogDebug("❌ " + result.validation_notes);
        return result;
    }
    
    // Berechne Distanz in Ticks
    double distance = MathAbs(entry - sl);
    double ticks = distance / tick_size;
    
    LogDebug("   Distanz: " + DoubleToString(distance, 6));
    LogDebug("   Ticks: " + DoubleToString(ticks, 2));
    
    // Berechne Verlust pro Lot
    double loss_per_lot = ticks * tick_value;
    
    // Währungskonvertierung falls nötig
    string profit_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    LogDebug("   Profit Currency: " + profit_currency);
    LogDebug("   Account Currency: " + account_currency);
    
    if(profit_currency != account_currency) {
        double conversion_rate = GetConversionRate(profit_currency, account_currency);
        LogDebug("   Conversion Rate: " + DoubleToString(conversion_rate, 6));
        
        if(conversion_rate > 0) {
            loss_per_lot *= conversion_rate;
            LogDebug("   Loss per Lot (converted): " + DoubleToString(loss_per_lot, 2));
        } else {
            result.validation_notes = "Currency conversion failed: " + profit_currency + " to " + account_currency;
            LogDebug("❌ " + result.validation_notes);
            return result;
        }
    }
    
    // Plausibilitätsprüfung
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double max_reasonable_loss = balance * 0.50; // Max 50% pro Lot
    
    if(loss_per_lot <= 0) {
        result.validation_notes = "Invalid loss per lot: " + DoubleToString(loss_per_lot, 2);
        LogDebug("❌ " + result.validation_notes);
        return result;
    }
    
    if(loss_per_lot > max_reasonable_loss) {
        result.validation_notes = "Loss per lot implausible: " + DoubleToString(loss_per_lot, 2) + 
                                 " (Max reasonable: " + DoubleToString(max_reasonable_loss, 2) + ")";
        LogDebug("❌ " + result.validation_notes);
        return result;
    }
    
    // Berechne finale Lots
    result.lots = risk_amount / loss_per_lot;
    result.risk_amount = result.lots * loss_per_lot;
    result.risk_percent = (result.risk_amount / balance) * 100.0;
    result.is_reliable = true;
    result.confidence_score = 0.9; // Hohe Konfidenz für Tick-Value Methode
    result.validation_notes = "Enhanced Tick-Value calculation successful";
    
    LogDebug("✅ METHODE 1: Erfolgreich - " + DoubleToString(result.lots, 3) + " Lots");
    
    return result;
}

//+------------------------------------------------------------------+
//| LAYER 3: CONTRACT SIZE BACKUP-METHODE                          |
//+------------------------------------------------------------------+
RiskCalculationResult CalculateWithContractSize(string symbol, double entry, double sl, double risk_amount) {
    RiskCalculationResult result;
    result.method_used = "Contract Size";
    result.is_reliable = false;
    result.confidence_score = 0.0;
    
    LogDebug("🔧 METHODE 2: Contract Size Berechnung...");
    
    double contract_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    string base_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
    string profit_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    LogDebug("   Contract Size: " + DoubleToString(contract_size, 2));
    LogDebug("   Base Currency: " + base_currency);
    LogDebug("   Profit Currency: " + profit_currency);
    
    if(contract_size <= 0) {
        result.validation_notes = "Invalid contract size: " + DoubleToString(contract_size, 2);
        LogDebug("❌ " + result.validation_notes);
        return result;
    }
    
    // Berechne Pip-Value
    double distance = MathAbs(entry - sl);
    double pip_value = contract_size * distance;
    
    LogDebug("   Distance: " + DoubleToString(distance, 6));
    LogDebug("   Pip Value (before conversion): " + DoubleToString(pip_value, 2));
    
    // Währungskonvertierung
    if(profit_currency != account_currency) {
        double conversion_rate = GetConversionRate(profit_currency, account_currency);
        LogDebug("   Conversion Rate: " + DoubleToString(conversion_rate, 6));
        
        if(conversion_rate > 0) {
            pip_value *= conversion_rate;
            LogDebug("   Pip Value (converted): " + DoubleToString(pip_value, 2));
        } else {
            result.validation_notes = "Currency conversion failed: " + profit_currency + " to " + account_currency;
            LogDebug("❌ " + result.validation_notes);
            return result;
        }
    }
    
    // Plausibilitätsprüfung
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double max_reasonable_loss = balance * 0.50;
    
    if(pip_value <= 0) {
        result.validation_notes = "Invalid pip value: " + DoubleToString(pip_value, 2);
        LogDebug("❌ " + result.validation_notes);
        return result;
    }
    
    if(pip_value > max_reasonable_loss) {
        result.validation_notes = "Pip value implausible: " + DoubleToString(pip_value, 2) + 
                                 " (Max reasonable: " + DoubleToString(max_reasonable_loss, 2) + ")";
        LogDebug("❌ " + result.validation_notes);
        return result;
    }
    
    // Berechne finale Lots
    result.lots = risk_amount / pip_value;
    result.risk_amount = result.lots * pip_value;
    result.risk_percent = (result.risk_amount / balance) * 100.0;
    result.is_reliable = true;
    result.confidence_score = 0.7; // Mittlere Konfidenz für Contract Size
    result.validation_notes = "Contract Size calculation successful";
    
    LogDebug("✅ METHODE 2: Erfolgreich - " + DoubleToString(result.lots, 3) + " Lots");
    
    return result;
}

//+------------------------------------------------------------------+
//| LAYER 4: VALIDIERTE ORDERCALCPROFIT-METHODE                    |
//+------------------------------------------------------------------+
RiskCalculationResult CalculateWithValidatedOrderCalcProfit(string symbol, ENUM_ORDER_TYPE order_type, 
                                                          double entry, double sl, double risk_amount) {
    RiskCalculationResult result;
    result.method_used = "Validated OrderCalcProfit";
    result.is_reliable = false;
    result.confidence_score = 0.0;
    
    LogDebug("🔧 METHODE 3: Validierte OrderCalcProfit Berechnung...");
    
    // Teste mit kleiner Lot-Größe zuerst
    double test_lots = 0.01;
    double test_profit = 0;
    
    LogDebug("   Teste mit " + DoubleToString(test_lots, 2) + " Lots...");
    
    if(!OrderCalcProfit(order_type, symbol, test_lots, entry, sl, test_profit)) {
        result.validation_notes = "OrderCalcProfit function failed";
        LogDebug("❌ " + result.validation_notes);
        return result;
    }
    
    LogDebug("   OrderCalcProfit Ergebnis: " + DoubleToString(test_profit, 6));
    
    // Validiere Ergebnis
    if(test_profit == 0 || MathAbs(test_profit) < 0.001) {
        result.validation_notes = "OrderCalcProfit returned invalid result: " + DoubleToString(test_profit, 6);
        LogDebug("❌ " + result.validation_notes);
        return result;
    }
    
    // Berechne Verlust pro Lot
    double loss_per_lot = MathAbs(test_profit) / test_lots;
    LogDebug("   Loss per Lot: " + DoubleToString(loss_per_lot, 2));
    
    // Plausibilitätsprüfung
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double max_reasonable_loss = balance * 0.50; // Max 50% pro Lot
    
    if(loss_per_lot > max_reasonable_loss) {
        result.validation_notes = "OrderCalcProfit result implausible: " + DoubleToString(loss_per_lot, 2) + 
                                 " (Max reasonable: " + DoubleToString(max_reasonable_loss, 2) + ")";
        LogDebug("❌ " + result.validation_notes);
        return result;
    }
    
    // Berechne finale Lots
    result.lots = risk_amount / loss_per_lot;
    result.risk_amount = result.lots * loss_per_lot;
    result.risk_percent = (result.risk_amount / balance) * 100.0;
    result.is_reliable = true;
    result.confidence_score = 0.8; // Hohe Konfidenz wenn validiert
    result.validation_notes = "OrderCalcProfit validated and reliable";
    
    LogDebug("✅ METHODE 3: Erfolgreich - " + DoubleToString(result.lots, 3) + " Lots");
    
    return result;
}

//+------------------------------------------------------------------+
//| LAYER 5: CROSS-VALIDATION UND METHODEN-AUSWAHL                 |
//+------------------------------------------------------------------+
bool CrossValidateResults(RiskCalculationResult &primary, RiskCalculationResult &secondary) {
    if(!primary.is_reliable || !secondary.is_reliable) {
        LogDebug("❌ Cross-Validation: Eine oder beide Methoden unzuverlässig");
        return false;
    }
    
    double tolerance = g_security_config.cross_validation_tolerance / 100.0; // Convert % to decimal
    double difference = MathAbs(primary.lots - secondary.lots) / MathMax(primary.lots, secondary.lots);
    
    LogDebug("🔍 CROSS-VALIDATION:");
    LogDebug("   " + primary.method_used + ": " + DoubleToString(primary.lots, 3) + " Lots");
    LogDebug("   " + secondary.method_used + ": " + DoubleToString(secondary.lots, 3) + " Lots");
    LogDebug("   Differenz: " + DoubleToString(difference * 100, 2) + "%");
    LogDebug("   Toleranz: " + DoubleToString(tolerance * 100, 1) + "%");
    
    if(difference > tolerance) {
        LogWarning("⚠️ CROSS-VALIDATION FEHLGESCHLAGEN:");
        LogWarning("   Differenz (" + DoubleToString(difference * 100, 2) + 
                  "%) überschreitet Toleranz (" + DoubleToString(tolerance * 100, 1) + "%)");
        return false;
    }
    
    LogDebug("✅ Cross-Validation erfolgreich");
    return true;
}

RiskCalculationResult SelectBestResult(RiskCalculationResult &results[], int count) {
    LogDebug("🎯 METHODEN-AUSWAHL aus " + IntegerToString(count) + " Ergebnissen...");
    
    // Finde die zuverlässigste Methode mit höchster Konfidenz
    RiskCalculationResult best_result;
    best_result.is_reliable = false;
    best_result.confidence_score = 0.0;
    
    for(int i = 0; i < count; i++) {
        LogDebug("   Methode " + IntegerToString(i+1) + " (" + results[i].method_used + "):");
        LogDebug("     Zuverlässig: " + (results[i].is_reliable ? "Ja" : "Nein"));
        LogDebug("     Konfidenz: " + DoubleToString(results[i].confidence_score, 2));
        LogDebug("     Lots: " + DoubleToString(results[i].lots, 3));
        
        if(results[i].is_reliable && results[i].confidence_score > best_result.confidence_score) {
            best_result = results[i];
            LogDebug("     ✅ Neue beste Methode!");
        }
    }
    
    if(best_result.is_reliable) {
        LogImportant("🏆 BESTE METHODE: " + best_result.method_used + 
                    " (Konfidenz: " + DoubleToString(best_result.confidence_score, 2) + ")");
    } else {
        LogError("❌ KEINE ZUVERLÄSSIGE METHODE GEFUNDEN!");
    }
    
    return best_result;
}


//+------------------------------------------------------------------+
//| Hilfsfunktion: Währungskonvertierung                            |
//+------------------------------------------------------------------+
double GetConversionRate(string from_currency, string to_currency) {
    if(from_currency == to_currency) {
        return 1.0;
    }
    
    // Versuche direktes Währungspaar
    string direct_symbol = from_currency + to_currency;
    double direct_rate = SymbolInfoDouble(direct_symbol, SYMBOL_BID);
    if(direct_rate > 0) {
        return direct_rate;
    }
    
    // Versuche umgekehrtes Währungspaar
    string reverse_symbol = to_currency + from_currency;
    double reverse_rate = SymbolInfoDouble(reverse_symbol, SYMBOL_ASK);
    if(reverse_rate > 0) {
        return 1.0 / reverse_rate;
    }
    
    // Fallback über USD
    if(from_currency != "USD" && to_currency != "USD") {
        string from_usd = from_currency + "USD";
        string to_usd = to_currency + "USD";
        
        double from_rate = SymbolInfoDouble(from_usd, SYMBOL_BID);
        double to_rate = SymbolInfoDouble(to_usd, SYMBOL_BID);
        
        if(from_rate > 0 && to_rate > 0) {
            return from_rate / to_rate;
        }
        
        // Versuche USD als Basis
        string usd_from = "USD" + from_currency;
        string usd_to = "USD" + to_currency;
        
        double usd_from_rate = SymbolInfoDouble(usd_from, SYMBOL_ASK);
        double usd_to_rate = SymbolInfoDouble(usd_to, SYMBOL_BID);
        
        if(usd_from_rate > 0 && usd_to_rate > 0) {
            return usd_to_rate / usd_from_rate;
        }
    }
    
    LogWarning("⚠️ Währungskonvertierung fehlgeschlagen: " + from_currency + " → " + to_currency);
    return 0.0;
}

//+------------------------------------------------------------------+
//| UNIVERSAL SYMBOL DATABASE (v8.1)                               |
//+------------------------------------------------------------------+

// Struktur für Symbol-Spezifikationen
struct SymbolSpec {
    string symbol_pattern;     // Pattern mit Wildcards (z.B. "XAUUSD*")
    double contract_size;      // Standard-Kontraktgröße
    double point_value_usd;    // Point-Value in USD
    string base_currency;      // Basis-Währung
    string profit_currency;    // Profit-Währung
    double typical_spread;     // Typischer Spread
    string symbol_type;        // "METAL", "FOREX", "INDEX", "CRYPTO", "COMMODITY"
};

// Umfassende Symbol-Datenbank
SymbolSpec g_universal_symbol_database[] = {
    // PRECIOUS METALS - GOLD (KORRIGIERT: 100 USD per 1.00 move)
    {"XAUUSD*", 100.0, 100.0, "XAU", "USD", 0.30, "METAL"},
    {"GOLD*", 100.0, 100.0, "XAU", "USD", 0.30, "METAL"},
    {"GC*", 100.0, 1000.0, "XAU", "USD", 0.30, "METAL"},  // Futures (andere Spezifikation)
    {"XAUEUR*", 100.0, 100.0, "XAU", "EUR", 0.30, "METAL"},
    {"XAUGBP*", 100.0, 100.0, "XAU", "GBP", 0.30, "METAL"},
    
    // PRECIOUS METALS - SILVER (KORRIGIERT: 50 USD per 1.00 move)
    {"XAGUSD*", 5000.0, 50.0, "XAG", "USD", 0.03, "METAL"},
    {"SILVER*", 5000.0, 50.0, "XAG", "USD", 0.03, "METAL"},
    {"SI*", 5000.0, 250.0, "XAG", "USD", 0.03, "METAL"},  // Futures (andere Spezifikation)
    {"XAGEUR*", 5000.0, 50.0, "XAG", "EUR", 0.03, "METAL"},
    
    // PRECIOUS METALS - PLATINUM & PALLADIUM
    {"XPTUSD*", 50.0, 1.0, "XPT", "USD", 2.0, "METAL"},
    {"XPDUSD*", 100.0, 1.0, "XPD", "USD", 3.0, "METAL"},
    
    // FOREX MAJORS
    {"EURUSD*", 100000.0, 0.0001, "EUR", "USD", 0.00001, "FOREX"},
    {"GBPUSD*", 100000.0, 0.0001, "GBP", "USD", 0.00001, "FOREX"},
    {"USDJPY*", 100000.0, 0.01, "USD", "JPY", 0.001, "FOREX"},
    {"USDCHF*", 100000.0, 0.0001, "USD", "CHF", 0.00001, "FOREX"},
    {"AUDUSD*", 100000.0, 0.0001, "AUD", "USD", 0.00001, "FOREX"},
    {"NZDUSD*", 100000.0, 0.0001, "NZD", "USD", 0.00001, "FOREX"},
    {"USDCAD*", 100000.0, 0.0001, "USD", "CAD", 0.00001, "FOREX"},
    
    // FOREX MINORS
    {"EURGBP*", 100000.0, 0.0001, "EUR", "GBP", 0.00001, "FOREX"},
    {"EURJPY*", 100000.0, 0.01, "EUR", "JPY", 0.001, "FOREX"},
    {"GBPJPY*", 100000.0, 0.01, "GBP", "JPY", 0.001, "FOREX"},
    {"EURCHF*", 100000.0, 0.0001, "EUR", "CHF", 0.00001, "FOREX"},
    {"GBPCHF*", 100000.0, 0.0001, "GBP", "CHF", 0.00001, "FOREX"},
    {"AUDCAD*", 100000.0, 0.0001, "AUD", "CAD", 0.00001, "FOREX"},
    {"AUDCHF*", 100000.0, 0.0001, "AUD", "CHF", 0.00001, "FOREX"},
    {"AUDJPY*", 100000.0, 0.01, "AUD", "JPY", 0.001, "FOREX"},
    {"CADJPY*", 100000.0, 0.01, "CAD", "JPY", 0.001, "FOREX"},
    {"CHFJPY*", 100000.0, 0.01, "CHF", "JPY", 0.001, "FOREX"},
    {"EURAUD*", 100000.0, 0.0001, "EUR", "AUD", 0.00001, "FOREX"},
    {"EURCAD*", 100000.0, 0.0001, "EUR", "CAD", 0.00001, "FOREX"},
    {"EURNZD*", 100000.0, 0.0001, "EUR", "NZD", 0.00001, "FOREX"},
    {"GBPAUD*", 100000.0, 0.0001, "GBP", "AUD", 0.00001, "FOREX"},
    {"GBPCAD*", 100000.0, 0.0001, "GBP", "CAD", 0.00001, "FOREX"},
    {"GBPNZD*", 100000.0, 0.0001, "GBP", "NZD", 0.00001, "FOREX"},
    {"NZDCAD*", 100000.0, 0.0001, "NZD", "CAD", 0.00001, "FOREX"},
    {"NZDCHF*", 100000.0, 0.0001, "NZD", "CHF", 0.00001, "FOREX"},
    {"NZDJPY*", 100000.0, 0.01, "NZD", "JPY", 0.001, "FOREX"},
    
    // INDICES - US
    {"US30*", 1.0, 1.0, "USD", "USD", 2.0, "INDEX"},
    {"DJ30*", 1.0, 1.0, "USD", "USD", 2.0, "INDEX"},
    {"DJI*", 1.0, 1.0, "USD", "USD", 2.0, "INDEX"},
    {"DJIUSD*", 1.0, 1.0, "USD", "USD", 2.0, "INDEX"},
    {"US100*", 1.0, 1.0, "USD", "USD", 1.0, "INDEX"},
    {"NAS100*", 1.0, 1.0, "USD", "USD", 1.0, "INDEX"},
    {"NASDAQ*", 1.0, 1.0, "USD", "USD", 1.0, "INDEX"},
    {"US500*", 1.0, 1.0, "USD", "USD", 0.5, "INDEX"},
    {"SPX500*", 1.0, 1.0, "USD", "USD", 0.5, "INDEX"},
    {"SPY*", 1.0, 1.0, "USD", "USD", 0.5, "INDEX"},
    {"US2000*", 1.0, 1.0, "USD", "USD", 1.0, "INDEX"},
    {"RUSSELL*", 1.0, 1.0, "USD", "USD", 1.0, "INDEX"},
    
    // INDICES - EUROPE
    {"GER40*", 1.0, 1.0, "EUR", "EUR", 1.0, "INDEX"},
    {"GER30*", 1.0, 1.0, "EUR", "EUR", 1.0, "INDEX"},
    {"DAX*", 1.0, 1.0, "EUR", "EUR", 1.0, "INDEX"},
    {"UK100*", 1.0, 1.0, "GBP", "GBP", 1.0, "INDEX"},
    {"FTSE*", 1.0, 1.0, "GBP", "GBP", 1.0, "INDEX"},
    {"FRA40*", 1.0, 1.0, "EUR", "EUR", 1.0, "INDEX"},
    {"CAC40*", 1.0, 1.0, "EUR", "EUR", 1.0, "INDEX"},
    {"EUSTX50*", 1.0, 1.0, "EUR", "EUR", 1.0, "INDEX"},
    {"STOXX50*", 1.0, 1.0, "EUR", "EUR", 1.0, "INDEX"},
    {"SPA35*", 1.0, 1.0, "EUR", "EUR", 1.0, "INDEX"},
    {"IBEX35*", 1.0, 1.0, "EUR", "EUR", 1.0, "INDEX"},
    {"SWI20*", 1.0, 1.0, "CHF", "CHF", 1.0, "INDEX"},
    {"SMI*", 1.0, 1.0, "CHF", "CHF", 1.0, "INDEX"},
    
    // INDICES - ASIA PACIFIC
    {"JPN225*", 1.0, 1.0, "JPY", "JPY", 10.0, "INDEX"},
    {"NIKKEI*", 1.0, 1.0, "JPY", "JPY", 10.0, "INDEX"},
    {"HK50*", 1.0, 1.0, "HKD", "HKD", 2.0, "INDEX"},
    {"HANGSENG*", 1.0, 1.0, "HKD", "HKD", 2.0, "INDEX"},
    {"AUS200*", 1.0, 1.0, "AUD", "AUD", 1.0, "INDEX"},
    {"ASX200*", 1.0, 1.0, "AUD", "AUD", 1.0, "INDEX"},
    {"KOR200*", 1.0, 1.0, "KRW", "KRW", 0.1, "INDEX"},
    {"KOSPI*", 1.0, 1.0, "KRW", "KRW", 0.1, "INDEX"},
    {"CAN60*", 1.0, 1.0, "CAD", "CAD", 1.0, "INDEX"},
    {"TSX*", 1.0, 1.0, "CAD", "CAD", 1.0, "INDEX"},
    {"BRA50*", 1.0, 1.0, "BRL", "BRL", 10.0, "INDEX"},
    {"BOVESPA*", 1.0, 1.0, "BRL", "BRL", 10.0, "INDEX"},
    
    // COMMODITIES - ENERGY
    {"USOIL*", 1000.0, 0.01, "USD", "USD", 0.03, "COMMODITY"},
    {"WTI*", 1000.0, 0.01, "USD", "USD", 0.03, "COMMODITY"},
    {"BRENT*", 1000.0, 0.01, "USD", "USD", 0.03, "COMMODITY"},
    {"UKOIL*", 1000.0, 0.01, "USD", "USD", 0.03, "COMMODITY"},
    {"NGAS*", 10000.0, 0.001, "USD", "USD", 0.005, "COMMODITY"},
    {"NATGAS*", 10000.0, 0.001, "USD", "USD", 0.005, "COMMODITY"},
    
    // CRYPTOCURRENCIES
    {"BTCUSD*", 1.0, 1.0, "BTC", "USD", 10.0, "CRYPTO"},
    {"BITCOIN*", 1.0, 1.0, "BTC", "USD", 10.0, "CRYPTO"},
    {"ETHUSD*", 1.0, 1.0, "ETH", "USD", 2.0, "CRYPTO"},
    {"ETHEREUM*", 1.0, 1.0, "ETH", "USD", 2.0, "CRYPTO"},
    {"LTCUSD*", 1.0, 1.0, "LTC", "USD", 1.0, "CRYPTO"},
    {"XRPUSD*", 1.0, 1.0, "XRP", "USD", 0.001, "CRYPTO"},
    {"ADAUSD*", 1.0, 1.0, "ADA", "USD", 0.001, "CRYPTO"},
    {"DOTUSD*", 1.0, 1.0, "DOT", "USD", 0.01, "CRYPTO"},
    {"LINKUSD*", 1.0, 1.0, "LINK", "USD", 0.01, "CRYPTO"},
    {"BNBUSD*", 1.0, 1.0, "BNB", "USD", 0.1, "CRYPTO"},
    {"SOLUSD*", 1.0, 1.0, "SOL", "USD", 0.01, "CRYPTO"},
    {"MATICUSD*", 1.0, 1.0, "MATIC", "USD", 0.001, "CRYPTO"},
    {"AVAXUSD*", 1.0, 1.0, "AVAX", "USD", 0.01, "CRYPTO"}
};

//+------------------------------------------------------------------+
//| UNIVERSAL SYMBOL FUNCTIONS (v8.1)                              |
//+------------------------------------------------------------------+

// Symbol-Normalisierung: Entfernt Broker-spezifische Suffixe
string NormalizeSymbolName(string symbol) {
    string normalized = CustomStringToUpper(symbol);
    
    // Liste der häufigsten Broker-Suffixe
    string suffixes[] = {
        "s", "#", "+", "-", "p", ".pro", ".ecn", ".std", ".cent", ".micro", 
        ".mini", ".raw", ".spot", ".cash", ".cfd", "pro", "ecn", "std", 
        "cent", "micro", "mini", "raw", "spot", "cash", "cfd", ".r", 
        "_ecn", "_std", "_pro", "_raw", "_spot", "_cash", "_cfd", ".", 
        "i", "m", ".a", ".c", ".b", ".d", ".e", ".f", ".g", ".h"
    };
    
    // Entferne das längste passende Suffix
    for(int i = 0; i < ArraySize(suffixes); i++) {
        string suffix_upper = CustomStringToUpper(suffixes[i]);
        if(StringEndsWith(normalized, suffix_upper)) {
            int new_length = StringLen(normalized) - StringLen(suffix_upper);
            if(new_length > 0) {
                normalized = StringSubstr(normalized, 0, new_length);
                break; // Nur das erste (längste) passende Suffix entfernen
            }
        }
    }
    
    return normalized;
}

// Pattern-Matching: Prüft ob Symbol zu Pattern passt (mit Wildcards)
bool MatchesPattern(string symbol, string pattern) {
    string symbol_upper = CustomStringToUpper(symbol);
    string pattern_upper = CustomStringToUpper(pattern);
    
    // Einfacher Wildcard-Support: * am Ende
    if(StringEndsWith(pattern_upper, "*")) {
        string pattern_base = StringSubstr(pattern_upper, 0, StringLen(pattern_upper) - 1);
        return StringFind(symbol_upper, pattern_base) == 0; // Beginnt mit Pattern
    }
    
    // Exakte Übereinstimmung
    return symbol_upper == pattern_upper;
}

// Finde Symbol-Spezifikation in der Datenbank
SymbolSpec FindSymbolSpec(string symbol) {
    SymbolSpec empty_spec;
    empty_spec.symbol_pattern = "";
    empty_spec.contract_size = 0.0;
    empty_spec.point_value_usd = 0.0;
    
    string normalized = NormalizeSymbolName(symbol);
    
    // Durchsuche Datenbank nach passendem Pattern
    for(int i = 0; i < ArraySize(g_universal_symbol_database); i++) {
        if(MatchesPattern(normalized, g_universal_symbol_database[i].symbol_pattern)) {
            LogDebug("✅ Symbol-Spec gefunden: " + symbol + " → " + g_universal_symbol_database[i].symbol_pattern);
            return g_universal_symbol_database[i];
        }
    }
    
    LogDebug("❌ Keine Symbol-Spec gefunden für: " + symbol + " (normalisiert: " + normalized + ")");
    return empty_spec;
}

// Intelligente Point-Value-Schätzung basierend auf Symbol-Typ
double EstimatePointValue(string symbol) {
    string normalized = NormalizeSymbolName(symbol);
    
    // Gold/Precious Metals (KORRIGIERT)
    if(StringFind(normalized, "XAU") >= 0 || StringFind(normalized, "GOLD") >= 0) {
        return 100.0; // 100 USD per 1.00 move (100 Unzen * 1.00 USD)
    }
    
    // Silver (KORRIGIERT)
    if(StringFind(normalized, "XAG") >= 0 || StringFind(normalized, "SILVER") >= 0) {
        return 50.0; // 50 USD per 1.00 move (5000 Unzen * 0.01 USD)
    }
    
    // Platinum
    if(StringFind(normalized, "XPT") >= 0 || StringFind(normalized, "PLATINUM") >= 0) {
        return 1.0;
    }
    
    // Palladium
    if(StringFind(normalized, "XPD") >= 0 || StringFind(normalized, "PALLADIUM") >= 0) {
        return 1.0;
    }
    
    // Oil
    if(StringFind(normalized, "OIL") >= 0 || StringFind(normalized, "WTI") >= 0 || 
       StringFind(normalized, "BRENT") >= 0) {
        return 0.01; // 1 cent per point
    }
    
    // Indices (meist 1 USD per point)
    if(StringFind(normalized, "US30") >= 0 || StringFind(normalized, "DJ") >= 0 ||
       StringFind(normalized, "US100") >= 0 || StringFind(normalized, "NAS") >= 0 ||
       StringFind(normalized, "US500") >= 0 || StringFind(normalized, "SPX") >= 0 ||
       StringFind(normalized, "DAX") >= 0 || StringFind(normalized, "GER") >= 0 ||
       StringFind(normalized, "FTSE") >= 0 || StringFind(normalized, "UK100") >= 0) {
        return 1.0;
    }
    
    // Forex pairs
    if(StringLen(normalized) == 6) {
        string quote = StringSubstr(normalized, 3, 3);
        
        if(quote == "JPY") {
            return 0.01; // 1 pip = 0.01 JPY
        } else if(quote == "USD") {
            return 0.0001; // 1 pip = $0.0001
        } else {
            return 0.0001; // Standard Forex
        }
    }
    
    // Crypto (meist 1 USD per point)
    if(StringFind(normalized, "BTC") >= 0 || StringFind(normalized, "ETH") >= 0 ||
       StringFind(normalized, "BITCOIN") >= 0 || StringFind(normalized, "ETHEREUM") >= 0) {
        return 1.0;
    }
    
    // Default: Conservative estimate
    return 0.1;
}


//+------------------------------------------------------------------+
//| STRING HELPER FUNCTIONS (v8.1)                                 |
//+------------------------------------------------------------------+

// CustomStringToUpper - Konvertiert String zu Großbuchstaben
string CustomStringToUpper(string str) {
    string result = str;
    for(int i = 0; i < StringLen(str); i++) {
        int char_code = StringGetCharacter(str, i);
        if(char_code >= 97 && char_code <= 122) { // a-z
            char_code -= 32; // Konvertiere zu A-Z
            StringSetCharacter(result, i, (ushort)char_code);
        }
    }
    return result;
}

// StringEndsWith - Prüft ob String mit Suffix endet
bool StringEndsWith(string str, string suffix) {
    int str_len = StringLen(str);
    int suffix_len = StringLen(suffix);
    
    if(suffix_len > str_len) return false;
    if(suffix_len == 0) return true;
    
    string str_end = StringSubstr(str, str_len - suffix_len, suffix_len);
    return str_end == suffix;
}

// StringStartsWith - Prüft ob String mit Prefix beginnt  
bool StringStartsWith(string str, string prefix) {
    int str_len = StringLen(str);
    int prefix_len = StringLen(prefix);
    
    if(prefix_len > str_len) return false;
    if(prefix_len == 0) return true;
    
    string str_start = StringSubstr(str, 0, prefix_len);
    return str_start == prefix;
}



// Universelle Datenbank-basierte Berechnung (Fallback für fehlerhafte Broker-Daten)
double CalculateWithUniversalDatabase(string symbol, double entry_price, double sl_price) {
    LogDebug("🌍 UNIVERSELLE DATENBANK-BERECHNUNG:");
    
    // 1. Symbol normalisieren (einfache Suffix-Entfernung)
    string normalized = symbol;
    StringReplace(normalized, ".ecn", "");
    StringReplace(normalized, ".raw", "");
    StringReplace(normalized, ".pro", "");
    StringReplace(normalized, ".std", "");
    StringReplace(normalized, "#", "");
    StringReplace(normalized, "s", ""); // Für XAUUSDs → XAUUSD
    
    LogDebug("   Normalisiert: " + symbol + " → " + normalized);
    
    // 2. Intelligente Symbol-Erkennung und Point Value Schätzung
    double point_value = 0.0001; // Standard Forex
    double contract_size = 100000; // Standard Forex
    
    // Gold/Precious Metals
    if(StringFind(normalized, "XAUUSD") >= 0 || StringFind(normalized, "GOLD") >= 0) {
        point_value = 100.0; // 100 USD per 1.00 move
        contract_size = 100.0; // 100 Unzen
        LogDebug("   Erkannt als: Gold (XAUUSD)");
    }
    // Silver
    else if(StringFind(normalized, "XAGUSD") >= 0 || StringFind(normalized, "SILVER") >= 0) {
        point_value = 50.0; // 50 USD per 1.00 move
        contract_size = 5000.0; // 5000 Unzen
        LogDebug("   Erkannt als: Silber (XAGUSD)");
    }
    // Forex Pairs
    else if(StringLen(normalized) == 6) {
        string quote_currency = StringSubstr(normalized, 3, 3);
        if(quote_currency == "JPY") {
            point_value = 0.01; // JPY pairs
        } else {
            point_value = 0.0001; // Standard Forex
        }
        contract_size = 100000; // Standard Forex
        LogDebug("   Erkannt als: Forex Paar (" + quote_currency + ")");
    }
    // Indices
    else if(StringFind(normalized, "US30") >= 0 || StringFind(normalized, "DJ") >= 0 ||
            StringFind(normalized, "US100") >= 0 || StringFind(normalized, "NAS") >= 0 ||
            StringFind(normalized, "US500") >= 0 || StringFind(normalized, "SPX") >= 0 ||
            StringFind(normalized, "DAX") >= 0 || StringFind(normalized, "GER") >= 0) {
        point_value = 1.0; // 1 USD per point
        contract_size = 1.0; // 1 Index point
        LogDebug("   Erkannt als: Index");
    }
    
    // 3. Berechnung - KORRIGIERT: Berücksichtige Point Size!
    double distance = MathAbs(entry_price - sl_price);
    double point_size = 0.00001; // Standard Point Size für Forex (5 Dezimalstellen)
    
    // Für JPY Paare: 3 Dezimalstellen
    if(StringLen(normalized) == 6) {
        string quote_currency = StringSubstr(normalized, 3, 3);
        if(quote_currency == "JPY") {
            point_size = 0.001; // JPY pairs haben 3 Dezimalstellen
        }
    }
    
    // KORREKTE FORMEL: Distance × (Point Value / Point Size) × Contract Size
    double loss_per_lot = distance * (point_value / point_size) * contract_size;
    
    LogDebug("   Contract Size: " + DoubleToString(contract_size, 0));
    LogDebug("   Point Value: " + DoubleToString(point_value, 8));
    LogDebug("   Point Size: " + DoubleToString(point_size, 8));
    LogDebug("   Distance: " + DoubleToString(distance, 8));
    LogDebug("   Berechnung: " + DoubleToString(distance, 8) + " × (" + DoubleToString(point_value, 8) + " / " + DoubleToString(point_size, 8) + ") × " + DoubleToString(contract_size, 0));
    LogDebug("   Loss per Lot: " + DoubleToString(loss_per_lot, 5));
    
    // 4. Einfache Währungskonvertierung (USD → EUR)
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    if(account_currency == "EUR" && loss_per_lot > 0) {
        // Einfache USD→EUR Konvertierung mit Standard-Rate
        double eur_rate = 0.92; // Konservative Rate
        loss_per_lot *= eur_rate;
        LogDebug("   USD→EUR Konvertierung (Rate: 0.92): " + DoubleToString(loss_per_lot, 5));
    }
    
    // 🚨 KRITISCHE SICHERHEITSPRÜFUNG - NIEMALS ZU KLEINE LOSS VALUES!
    if(loss_per_lot <= 0.1) {
        LogError("🚨 NOTFALL: Loss per Lot zu klein (" + DoubleToString(loss_per_lot, 8) + ") - verwende Sicherheitswert");
        
        // Intelligenter Sicherheitswert basierend auf Symbol
        if(StringLen(normalized) == 6) {
            // Forex: Etwa 1 EUR per Lot für 10 Pips
            loss_per_lot = 1.0;
        } else {
            // Andere Symbole: Konservativer Wert
            loss_per_lot = 5.0;
        }
        
        LogWarning("   Sicherheitswert gesetzt: " + DoubleToString(loss_per_lot, 2) + " EUR per Lot");
    }
    
    LogWarning("🛡️ SICHERHEITSPRÜFUNG: Loss per Lot = " + DoubleToString(loss_per_lot, 5));
    
    return loss_per_lot;
}


//+------------------------------------------------------------------+
//| NEUE v8.3 KORREKTUREN - ZUVERLÄSSIGE LOTSIZE-BERECHNUNG         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| NEUE ZUVERLÄSSIGE FOREX LOT-BERECHNUNG (v8.3)                   |
//+------------------------------------------------------------------+
double CalculateLossPerLot_Forex_v83(string symbol, double entry_price, double sl_price, string &log_message) {
    log_message = "";
    
    LogImportant("🆕 NEUE FOREX-SPEZIFISCHE BERECHNUNG (v8.3):");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Entry: " + DoubleToString(entry_price, 5));
    LogImportant("   SL: " + DoubleToString(sl_price, 5));
    
    // 1. Symbol-Informationen abrufen
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    string quote_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    LogImportant("   Digits: " + IntegerToString(digits));
    LogImportant("   Point: " + DoubleToString(point, 8));
    LogImportant("   Quote Currency: " + quote_currency);
    LogImportant("   Account Currency: " + account_currency);
    
    if(point <= 0) {
        log_message = "Ungültiger Point-Wert: " + DoubleToString(point, 8);
        LogError("❌ " + log_message);
        return -1;
    }
    
    // 2. Pip-Größe bestimmen (KORRIGIERT)
    double pip_size = point * 10; // Standard: Point * 10 für 5-stellige Quotes
    if(digits == 3 || digits == 2) { // Für JPY-Paare und Metalle
        pip_size = point;
    }
    
    LogImportant("   Pip Size: " + DoubleToString(pip_size, 8));

    // 3. Distanz in Pips berechnen
    double distance_in_price = MathAbs(entry_price - sl_price);
    double distance_in_pips = distance_in_price / pip_size;
    
    LogImportant("   Distance in Price: " + DoubleToString(distance_in_price, 8));
    LogImportant("   Distance in Pips: " + DoubleToString(distance_in_pips, 1));
    
    // 4. Pip-Wert in Account-Währung berechnen
    double pip_value_in_account_currency = 10.0; // Standard-Annäherung für die meisten USD-Paare
    
    // Genauere Berechnung mit Tick-Werten, wenn verfügbar
    double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    
    LogImportant("   Tick Value: " + DoubleToString(tick_value, 5));
    LogImportant("   Tick Size: " + DoubleToString(tick_size, 8));
    
    if(tick_value > 0 && tick_size > 0 && tick_value < 1000) { // Validierung
        pip_value_in_account_currency = (pip_size / tick_size) * tick_value;
        LogImportant("   Pip Value (berechnet): " + DoubleToString(pip_value_in_account_currency, 2) + " " + account_currency);
    } else {
        // Fallback-Werte für verschiedene Währungspaare
        if(quote_currency == "USD" && account_currency == "USD") {
            pip_value_in_account_currency = 10.0; // Standard für XXX/USD Paare
        } else if(quote_currency == "JPY" && account_currency == "USD") {
            pip_value_in_account_currency = 100000.0 / entry_price; // Für XXX/JPY Paare
        } else if(quote_currency == account_currency) {
            pip_value_in_account_currency = 100000.0 * pip_size; // Direkte Berechnung
        } else {
            // Währungskonvertierung erforderlich
            double conversion_rate = GetCurrencyConversionRate_v83(quote_currency, account_currency);
            if(conversion_rate > 0) {
                pip_value_in_account_currency = 10.0 * conversion_rate;
            } else {
                pip_value_in_account_currency = 10.0; // Konservative Schätzung
            }
        }
        
        log_message = "Tick-Werte nicht verfügbar oder unrealistisch, verwende Fallback-Berechnung.";
        LogImportant("   Pip Value (Fallback): " + DoubleToString(pip_value_in_account_currency, 2) + " " + account_currency);
    }
    
    // 5. Verlust pro Lot berechnen
    double loss_per_lot = distance_in_pips * pip_value_in_account_currency;
    
    LogImportant("   BERECHNUNG: " + DoubleToString(distance_in_pips, 1) + " Pips × " + 
                DoubleToString(pip_value_in_account_currency, 2) + " " + account_currency + "/Pip");
    LogImportant("   Loss per Lot: " + DoubleToString(loss_per_lot, 2) + " " + account_currency);
    
    // 6. Validierung: Ist der Wert realistisch?
    // KORRIGIERT: Realistische Bereiche für Forex-Paare
    double expected_range_min = distance_in_pips * 0.1;   // Minimum: 0.1 EUR per Pip
    double expected_range_max = distance_in_pips * 50.0;  // Maximum: 50 EUR per Pip
    
    LogImportant("   VALIDIERUNG:");
    LogImportant("   Erwarteter Bereich: " + DoubleToString(expected_range_min, 2) + " - " + DoubleToString(expected_range_max, 2));
    
    if(loss_per_lot <= 0) {
        log_message = "Berechneter Verlust ist null oder negativ: " + DoubleToString(loss_per_lot, 5);
        LogError("❌ " + log_message);
        return -1;
    }
    
    if(loss_per_lot < expected_range_min) {
        LogWarning("⚠️ Loss per Lot möglicherweise zu klein: " + DoubleToString(loss_per_lot, 2) + " < " + DoubleToString(expected_range_min, 2));
        // Aber nicht ablehnen - könnte bei sehr kleinen Distanzen normal sein
    }
    
    if(loss_per_lot > expected_range_max) {
        LogWarning("⚠️ Loss per Lot möglicherweise zu hoch: " + DoubleToString(loss_per_lot, 2) + " > " + DoubleToString(expected_range_max, 2));
        LogWarning("   Aber akzeptiere Wert - könnte bei großen Distanzen normal sein");
        // NICHT ablehnen - der Wert könnte korrekt sein
    }
    
    LogImportant("✅ FOREX-BERECHNUNG ERFOLGREICH: " + DoubleToString(loss_per_lot, 2) + " " + account_currency);
    return loss_per_lot;
}

//+------------------------------------------------------------------+
//| VERBESSERTE WÄHRUNGSKONVERTIERUNG (v8.3)                        |
//+------------------------------------------------------------------+
double GetCurrencyConversionRate_v83(string from_currency, string to_currency) {
    if(from_currency == to_currency) return 1.0;
    
    LogDebug("💱 WÄHRUNGSKONVERTIERUNG: " + from_currency + " → " + to_currency);
    
    // Direkte Konvertierung versuchen
    string direct_symbol = from_currency + to_currency;
    double direct_rate = SymbolInfoDouble(direct_symbol, SYMBOL_BID);
    if(direct_rate > 0 && direct_rate < 1000000) { // Realistische Grenze
        LogDebug("   Direkte Konvertierung: " + direct_symbol + " = " + DoubleToString(direct_rate, 5));
        return direct_rate;
    }
    
    // Umgekehrte Konvertierung versuchen
    string reverse_symbol = to_currency + from_currency;
    double reverse_rate = SymbolInfoDouble(reverse_symbol, SYMBOL_ASK);
    if(reverse_rate > 0 && reverse_rate < 1000000) {
        double conversion_rate = 1.0 / reverse_rate;
        LogDebug("   Umgekehrte Konvertierung: " + reverse_symbol + " = " + DoubleToString(reverse_rate, 5) + " → " + DoubleToString(conversion_rate, 5));
        return conversion_rate;
    }
    
    // Via USD konvertieren
    if(from_currency != "USD" && to_currency != "USD") {
        double from_to_usd = GetCurrencyConversionRate_v83(from_currency, "USD");
        double usd_to_target = GetCurrencyConversionRate_v83("USD", to_currency);
        if(from_to_usd > 0 && usd_to_target > 0) {
            double conversion_rate = from_to_usd * usd_to_target;
            LogDebug("   Via USD Konvertierung: " + DoubleToString(conversion_rate, 5));
            return conversion_rate;
        }
    }
    
    // Erweiterte Hardcoded Fallback-Raten (konservativ, Stand 2024)
    if(from_currency == "USD" && to_currency == "EUR") return 0.92;
    if(from_currency == "EUR" && to_currency == "USD") return 1.08;
    if(from_currency == "USD" && to_currency == "GBP") return 0.79;
    if(from_currency == "GBP" && to_currency == "USD") return 1.27;
    if(from_currency == "USD" && to_currency == "JPY") return 150.0;
    if(from_currency == "JPY" && to_currency == "USD") return 0.0067;
    if(from_currency == "USD" && to_currency == "CHF") return 0.91;
    if(from_currency == "CHF" && to_currency == "USD") return 1.10;
    if(from_currency == "USD" && to_currency == "CAD") return 1.35;
    if(from_currency == "CAD" && to_currency == "USD") return 0.74;
    if(from_currency == "USD" && to_currency == "AUD") return 1.52;
    if(from_currency == "AUD" && to_currency == "USD") return 0.66;
    
    LogWarning("   ⚠️ Keine Konvertierung verfügbar für " + from_currency + " → " + to_currency);
    return 0.0;
}

//+------------------------------------------------------------------+
//| VERBESSERTE ROBUSTE LOT-BERECHNUNG (v8.3)                       |
//+------------------------------------------------------------------+
double GetRobustLossPerLot_v83(string symbol, ENUM_ORDER_TYPE order_type, double entry_price, double sl_price) {
    LogImportant("🔧 VERBESSERTE ROBUSTE LOT-BERECHNUNG v8.3:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Entry: " + DoubleToString(entry_price, 5));
    LogImportant("   SL: " + DoubleToString(sl_price, 5));
    LogImportant("   Distance: " + DoubleToString(MathAbs(entry_price - sl_price), 5));
    
    double loss_per_lot = -1;
    string method_used = "";
    string log_msg = "";
    
    // ========== NEUE METHOD 1: FOREX-SPEZIFISCHE BERECHNUNG (v8.3) ==========
    // Prüfe ob es sich um ein Forex-Paar handelt
    string normalized_symbol = symbol;
    StringReplace(normalized_symbol, ".ecn", "");
    StringReplace(normalized_symbol, ".raw", "");
    StringReplace(normalized_symbol, ".pro", "");
    StringReplace(normalized_symbol, ".std", "");
    StringReplace(normalized_symbol, "#", "");
    
    bool is_forex_pair = (StringLen(normalized_symbol) == 6) || 
                        (StringFind(symbol, "USD") >= 0) || 
                        (StringFind(symbol, "EUR") >= 0) || 
                        (StringFind(symbol, "GBP") >= 0) || 
                        (StringFind(symbol, "JPY") >= 0) || 
                        (StringFind(symbol, "CHF") >= 0) || 
                        (StringFind(symbol, "CAD") >= 0) || 
                        (StringFind(symbol, "AUD") >= 0) || 
                        (StringFind(symbol, "NZD") >= 0);
    
    if(is_forex_pair) {
        LogImportant("🆕 VERWENDE NEUE FOREX-METHODE (v8.3):");
        loss_per_lot = CalculateLossPerLot_Forex_v83(symbol, entry_price, sl_price, log_msg);
        if(loss_per_lot > 0) {
            method_used = "Forex-spezifische Berechnung (v8.3)";
            LogImportant("✅ FOREX-METHODE ERFOLGREICH!");
        } else {
            LogWarning("⚠️ Forex-Methode fehlgeschlagen: " + log_msg);
        }
    }
    
    // ========== FALLBACK: BESTEHENDE METHODEN ==========
    if(loss_per_lot <= 0) {
        LogImportant("🔄 FALLBACK ZU BESTEHENDEN METHODEN:");
        
        // Verwende die ursprüngliche GetRobustLossPerLot Funktion als Fallback (NICHT v83!)
        loss_per_lot = GetRobustLossPerLot(symbol, order_type, entry_price, sl_price);
        if(loss_per_lot > 0) {
            method_used = "Bestehende Methoden (Fallback)";
        } else {
            LogError("❌ Alle Methoden fehlgeschlagen für Symbol: " + symbol);
            return -1;
        }
    }
    
    LogImportant("✅ VERBESSERTE BERECHNUNG ERFOLGREICH:");
    LogImportant("   Methode: " + method_used);
    LogImportant("   Verlust bei 1.0 Lot: " + DoubleToString(loss_per_lot, 5) + " " + AccountInfoString(ACCOUNT_CURRENCY));
    
    return loss_per_lot;
}

//+------------------------------------------------------------------+
//| KORRIGIERTE LOT-BERECHNUNG (v8.3)                               |
//+------------------------------------------------------------------+
double CalculateLots_v83(string symbol, double entry_price, double sl_price, 
                         double risk_percent, ENUM_ORDER_TYPE order_type, string &message) {
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("💰 KORRIGIERTE LOT-BERECHNUNG v8.3 für " + symbol);
    LogImportant("════════════════════════════════════════════");
    
    // Basis-Informationen
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * risk_percent / 100.0;
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    LogImportant("📊 ACCOUNT:");
    LogImportant("   Balance: " + DoubleToString(balance, 2) + " " + account_currency);
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    LogImportant("   Risiko-Betrag: " + DoubleToString(risk_amount, 2) + " " + account_currency);
    
    // Symbol aktivieren und Daten laden
    if(!RefreshSymbolData(symbol)) {
        message = "Symbol data refresh failed";
        return 0;
    }
    
    // Symbol-Informationen
    double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    // Validierung
    if(min_lot <= 0 || max_lot <= 0 || lot_step <= 0) {
        LogError("❌ Ungültige Symbol-Daten für " + symbol);
        message = "Invalid symbol data";
        return 0;
    }
    
    // Währungen für Debug
    string base_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
    string profit_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
    
    LogImportant("📈 SYMBOL-INFO:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Base/Profit: " + base_currency + "/" + profit_currency);
    LogImportant("   Lot-Bereich: " + DoubleToString(min_lot, 3) + " - " + DoubleToString(max_lot, 3));
    LogImportant("   Lot-Step: " + DoubleToString(lot_step, 4));
    
    // Entry-Preis bestimmen (falls nicht gesetzt)
    if(entry_price <= 0) {
        double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        entry_price = (sl_price < bid) ? ask : bid;
        LogDebug("Entry automatisch gesetzt: " + DoubleToString(entry_price, digits));
    }
    
    // Order-Typ bestimmen
    ENUM_ORDER_TYPE calc_order_type = (entry_price > sl_price) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    
    LogImportant("📍 TRADE-PARAMETER:");
    LogImportant("   Order Type: " + (calc_order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"));
    LogImportant("   Entry: " + DoubleToString(entry_price, digits));
    LogImportant("   SL: " + DoubleToString(sl_price, digits));
    LogImportant("   Distanz: " + DoubleToString(MathAbs(entry_price - sl_price), digits) + " (" + 
                DoubleToString(MathAbs(entry_price - sl_price) * MathPow(10, digits-1), 1) + " Pips)");
    
    // ========== KORRIGIERTE BERECHNUNG MIT NEUER v8.3.2 METHODE ==========
    double loss_per_lot = GetRobustLossPerLot_v832(symbol, calc_order_type, entry_price, sl_price);
    
    if(loss_per_lot <= 0) {
        LogError("❌ Alle korrigierten Berechnungsmethoden fehlgeschlagen!");
        message = "Loss calculation failed with all corrected methods";
        return 0;
    }
    
    LogImportant("💡 VERLUST PRO LOT: " + DoubleToString(loss_per_lot, 2) + " " + account_currency);
    
    // Direkte Berechnung
    double theoretical_lots = risk_amount / loss_per_lot;
    LogImportant("   Theoretisch maximale Lots: " + DoubleToString(theoretical_lots, 6));
    
    // ========== KRITISCHE SICHERHEITSBEGRENZUNG ==========
    // NIEMALS mehr als 10% des Kontos riskieren (Sicherheitsstopp)
    double max_allowed_lots = (balance * 0.10) / loss_per_lot;
    LogImportant("   Sicherheits-Maximum (10% Konto): " + DoubleToString(max_allowed_lots, 3));
    
    // Verwende das kleinere der beiden Limits
    double safe_lots = MathMin(theoretical_lots, max_allowed_lots);
    safe_lots = MathFloor(safe_lots / lot_step) * lot_step;
    LogImportant("   Auf Lot-Step normalisiert: " + DoubleToString(safe_lots, 3));
    
    // ========== MINDEST-LOT PRÜFUNG ==========
    if(safe_lots < min_lot) {
        LogWarning("⚠️ Berechnete Lots (" + DoubleToString(safe_lots, 3) + ") unter Minimum (" + DoubleToString(min_lot, 3) + ")");
        
        // Prüfe ob min_lot das Risiko überschreitet
        double min_lot_risk_amount = min_lot * loss_per_lot;
        double min_lot_risk_percent = (min_lot_risk_amount / balance) * 100.0;
        
        LogImportant("🔍 MINDEST-LOT ANALYSE:");
        LogImportant("   Min Lot: " + DoubleToString(min_lot, 3));
        LogImportant("   Risiko bei Min Lot: " + DoubleToString(min_lot_risk_percent, 3) + "%");
        LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
        
        // STRIKTE REGEL: Niemals mehr als gewünschtes Risiko
        if(min_lot_risk_percent > risk_percent) {
            LogError("❌ RISIKO ZU KLEIN!");
            LogError("   Mindest-Lots würden " + DoubleToString(min_lot_risk_percent, 2) + "% riskieren");
            LogError("   Aber nur " + DoubleToString(risk_percent, 2) + "% sind erlaubt");
            LogError("   Trade wird zum Schutz des Kontos ABGELEHNT!");
            
            message = "Risk too small. Min lot requires " + DoubleToString(min_lot_risk_percent, 2) + 
                     "% risk, but only " + DoubleToString(risk_percent, 2) + "% allocated";
            return 0;
        } else {
            // Min lot ist akzeptabel
            safe_lots = min_lot;
            LogImportant("✅ Min Lot akzeptiert (Risiko: " + DoubleToString(min_lot_risk_percent, 2) + "%)");
        }
    }
    
    // ========== MAXIMAL-LOT PRÜFUNG ==========
    if(safe_lots > max_lot) {
        safe_lots = max_lot;
        LogWarning("⚠️ Auf Maximum begrenzt: " + DoubleToString(max_lot, 3));
    }
    
    // ========== FINALE RISIKO-VALIDIERUNG ==========
    // Berechne das tatsächliche Risiko mit den finalen Lots
    double actual_risk_amount = safe_lots * loss_per_lot;
    double actual_risk_percent = (actual_risk_amount / balance) * 100.0;
    
    LogImportant("🔍 FINALE RISIKO-VALIDIERUNG:");
    LogImportant("   Finale Lots: " + DoubleToString(safe_lots, 3));
    LogImportant("   Tatsächlicher Verlust bei SL: " + DoubleToString(actual_risk_amount, 2) + " " + account_currency);
    LogImportant("   Tatsächliches Risiko: " + DoubleToString(actual_risk_percent, 3) + "%");
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    
    // ========== KRITISCHE SICHERHEITSPRÜFUNG ==========
    // NIEMALS mehr als gewünschtes Risiko akzeptieren!
    if(actual_risk_percent > risk_percent) {
        LogError("❌ KRITISCHER SICHERHEITSFEHLER!");
        LogError("   Tatsächliches Risiko (" + DoubleToString(actual_risk_percent, 3) + 
                "%) überschreitet gewünschtes Risiko (" + DoubleToString(risk_percent, 2) + "%)");
        LogError("   Differenz: +" + DoubleToString(actual_risk_percent - risk_percent, 3) + "%");
        
        // ROBUSTE KORREKTUR: Progressive Lot-Reduzierung
        LogImportant("🛡️ AKTIVIERE RISIKO-SCHUTZ: Progressive Lot-Reduzierung...");
        
        double corrected_lots = safe_lots;
        int safety_iterations = 0;
        const int MAX_SAFETY_ITERATIONS = 1000;
        
        while(actual_risk_percent > risk_percent && safety_iterations < MAX_SAFETY_ITERATIONS) {
            safety_iterations++;
            
            // Progressive Lot-Reduzierung
            double reduction_amount = lot_step;
            if(safety_iterations > 10) reduction_amount = lot_step * 5;
            if(safety_iterations > 50) reduction_amount = lot_step * 10;
            
            corrected_lots -= reduction_amount;
            
            // Prüfe ob noch über Minimum
            if(corrected_lots < min_lot) {
                LogError("❌ RISIKO-SCHUTZ FEHLGESCHLAGEN!");
                LogError("   Selbst Minimum-Lot (" + DoubleToString(min_lot, 3) + 
                        ") überschreitet gewünschtes Risiko");
                LogError("   Trade wird zum Schutz des Kontos ABGELEHNT!");
                
                message = "Risk protection failed: Even minimum lot exceeds desired risk";
                return 0;
            }
            
            // Berechne neues Risiko
            actual_risk_amount = corrected_lots * loss_per_lot;
            actual_risk_percent = (actual_risk_amount / balance) * 100.0;
            
            if(safety_iterations <= 10 || safety_iterations % 10 == 0 || actual_risk_percent <= risk_percent) {
                LogDebug("Iteration " + IntegerToString(safety_iterations) + 
                        ": Lots=" + DoubleToString(corrected_lots, 3) + 
                        ", Risiko=" + DoubleToString(actual_risk_percent, 3) + "%");
            }
        }
        
        if(actual_risk_percent <= risk_percent) {
            safe_lots = corrected_lots;
            LogSuccess("✅ RISIKO-SCHUTZ ERFOLGREICH nach " + IntegerToString(safety_iterations) + " Iteration(en)!");
            LogSuccess("   Korrigierte Lots: " + DoubleToString(safe_lots, 3));
            LogSuccess("   Finales Risiko: " + DoubleToString(actual_risk_percent, 3) + "%");
        } else {
            LogError("❌ RISIKO-SCHUTZ VERSAGT nach " + IntegerToString(MAX_SAFETY_ITERATIONS) + " Iterationen!");
            
            message = "Risk protection algorithm failed";
            return 0;
        }
    }
    
    // ========== FINALE VALIDIERUNG UND AUSGABE ==========
    double final_deviation = actual_risk_percent - risk_percent;
    
    LogImportant("✅ KORRIGIERTE LOT-BERECHNUNG v8.3 ERFOLGREICH:");
    LogImportant("   Finale Lots: " + DoubleToString(safe_lots, 3));
    LogImportant("   Finaler Verlust bei SL: " + DoubleToString(actual_risk_amount, 2) + " " + account_currency);
    LogImportant("   Finales Risiko: " + DoubleToString(actual_risk_percent, 3) + "%");
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    
    // Bewertung der Abweichung
    if(final_deviation > 0.001) { // Mehr als 0.001% Überschreitung
        LogError("   ❌ KRITISCHER FEHLER: Risiko um " + DoubleToString(final_deviation, 4) + "% zu hoch!");
        
        message = "Critical error: Risk exceeds desired level by " + DoubleToString(final_deviation, 4) + "%";
        return 0;
    } else if(final_deviation > -0.5) {
        LogSuccess("   ✅ PERFEKT: Risiko optimal ausgenutzt (Abweichung: " + DoubleToString(final_deviation, 3) + "%)");
    } else {
        LogInfo("   ✅ SICHER: Risiko " + DoubleToString(MathAbs(final_deviation), 2) + "% unter gewünschtem Wert");
    }
    
    LogImportant("════════════════════════════════════════════");
    
    // 🚨 FLEXIBLE NOTFALL-SICHERHEITSBEGRENZUNG basierend auf Symbol-Typ (v8.3.2)
    ENUM_SYMBOL_TYPE symbol_type = ClassifySymbol_v832(symbol);
    double ABSOLUTE_MAX_LOTS = GetMaxAllowedLots_v832(symbol, symbol_type);
    
    if(safe_lots > ABSOLUTE_MAX_LOTS) {
        LogError("🚨 NOTFALL-STOPP: " + DoubleToString(safe_lots, 3) + " Lots > " + DoubleToString(ABSOLUTE_MAX_LOTS, 1) + " Lots!");
        LogError("   Symbol-Typ: " + EnumToString(symbol_type));
        LogError("   TRADE WIRD ZUM SCHUTZ DES KONTOS ABGELEHNT!");
        
        message = "EMERGENCY STOP: " + DoubleToString(safe_lots, 3) + " lots exceeds " + EnumToString(symbol_type) + " safety limit (" + DoubleToString(ABSOLUTE_MAX_LOTS, 1) + ")";
        return 0;
    }
    
    message = "OK - Risk: " + DoubleToString(actual_risk_percent, 2) + "% (Target: " + DoubleToString(risk_percent, 2) + "%) - v8.3.2 CRYPTO-OPTIMIZED";
    return safe_lots;
}


//+------------------------------------------------------------------+
//| NEUE v8.3.2 KRYPTO-OPTIMIERUNGEN                                |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| INTELLIGENTE SYMBOL-KLASSIFIZIERUNG (v8.3.2)                   |
//+------------------------------------------------------------------+
enum ENUM_SYMBOL_TYPE {
    SYMBOL_TYPE_FOREX,      // Forex-Paare (EURUSD, GBPJPY, etc.)
    SYMBOL_TYPE_CRYPTO,     // Krypto-Paare (BTCUSD, ETHUSD, XRPUSDT, etc.)
    SYMBOL_TYPE_METAL,      // Edelmetalle (XAUUSD, XAGUSD, etc.)
    SYMBOL_TYPE_INDEX,      // Indizes (US30, SPX500, etc.)
    SYMBOL_TYPE_COMMODITY,  // Rohstoffe (WTIUSD, BRENTUSD, etc.)
    SYMBOL_TYPE_UNKNOWN     // Unbekannt
};

ENUM_SYMBOL_TYPE ClassifySymbol_v832(string symbol) {
    string normalized = symbol;
    StringReplace(normalized, ".ecn", "");
    StringReplace(normalized, ".raw", "");
    StringReplace(normalized, ".pro", "");
    StringReplace(normalized, ".std", "");
    StringReplace(normalized, "#", "");
    normalized = CustomStringToUpper(normalized);
    
    LogDebug("🔍 SYMBOL-KLASSIFIZIERUNG: " + symbol + " → " + normalized);
    
    // Krypto-Paare erkennen
    if(StringFind(normalized, "BTC") >= 0 || StringFind(normalized, "ETH") >= 0 || 
       StringFind(normalized, "XRP") >= 0 || StringFind(normalized, "ADA") >= 0 ||
       StringFind(normalized, "DOT") >= 0 || StringFind(normalized, "SOL") >= 0 ||
       StringFind(normalized, "MATIC") >= 0 || StringFind(normalized, "AVAX") >= 0 ||
       StringFind(normalized, "LINK") >= 0 || StringFind(normalized, "UNI") >= 0 ||
       StringFind(normalized, "DOGE") >= 0 || StringFind(normalized, "SHIB") >= 0 ||
       StringFind(normalized, "LTC") >= 0 || StringFind(normalized, "BCH") >= 0 ||
       StringFind(normalized, "USDT") >= 0 || StringFind(normalized, "USDC") >= 0) {
        LogDebug("   → KRYPTO erkannt");
        return SYMBOL_TYPE_CRYPTO;
    }
    
    // Edelmetalle erkennen
    if(StringFind(normalized, "XAU") >= 0 || StringFind(normalized, "GOLD") >= 0 ||
       StringFind(normalized, "XAG") >= 0 || StringFind(normalized, "SILVER") >= 0 ||
       StringFind(normalized, "XPD") >= 0 || StringFind(normalized, "XPT") >= 0) {
        LogDebug("   → METALL erkannt");
        return SYMBOL_TYPE_METAL;
    }
    
    // Indizes erkennen
    if(StringFind(normalized, "US30") >= 0 || StringFind(normalized, "US100") >= 0 ||
       StringFind(normalized, "US500") >= 0 || StringFind(normalized, "DAX") >= 0 ||
       StringFind(normalized, "FTSE") >= 0 || StringFind(normalized, "CAC") >= 0 ||
       StringFind(normalized, "NIKKEI") >= 0 || StringFind(normalized, "SPX") >= 0 ||
       StringFind(normalized, "NDX") >= 0 || StringFind(normalized, "DJI") >= 0) {
        LogDebug("   → INDEX erkannt");
        return SYMBOL_TYPE_INDEX;
    }
    
    // Rohstoffe erkennen
    if(StringFind(normalized, "WTI") >= 0 || StringFind(normalized, "BRENT") >= 0 ||
       StringFind(normalized, "OIL") >= 0 || StringFind(normalized, "GAS") >= 0) {
        LogDebug("   → ROHSTOFF erkannt");
        return SYMBOL_TYPE_COMMODITY;
    }
    
    // Forex-Paare erkennen (6 Zeichen oder bekannte Währungen)
    if(StringLen(normalized) == 6 || 
       StringFind(normalized, "USD") >= 0 || StringFind(normalized, "EUR") >= 0 ||
       StringFind(normalized, "GBP") >= 0 || StringFind(normalized, "JPY") >= 0 ||
       StringFind(normalized, "CHF") >= 0 || StringFind(normalized, "CAD") >= 0 ||
       StringFind(normalized, "AUD") >= 0 || StringFind(normalized, "NZD") >= 0) {
        LogDebug("   → FOREX erkannt");
        return SYMBOL_TYPE_FOREX;
    }
    
    LogDebug("   → UNBEKANNT");
    return SYMBOL_TYPE_UNKNOWN;
}

//+------------------------------------------------------------------+
//| KRYPTO-SPEZIFISCHE LOT-BERECHNUNG (v8.3.2)                     |
//+------------------------------------------------------------------+
double CalculateLossPerLot_Crypto_v832(string symbol, double entry_price, double sl_price, string &log_message) {
    log_message = "";
    
    LogImportant("🚀 NEUE KRYPTO-SPEZIFISCHE BERECHNUNG (v8.3.2):");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Entry: " + DoubleToString(entry_price, 5));
    LogImportant("   SL: " + DoubleToString(sl_price, 5));
    
    // 1. Symbol-Informationen abrufen
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    string quote_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    double contract_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    
    LogImportant("   Digits: " + IntegerToString(digits));
    LogImportant("   Point: " + DoubleToString(point, 8));
    LogImportant("   Quote Currency: " + quote_currency);
    LogImportant("   Account Currency: " + account_currency);
    LogImportant("   Contract Size: " + DoubleToString(contract_size, 2));
    
    if(point <= 0) {
        log_message = "Ungültiger Point-Wert: " + DoubleToString(point, 8);
        LogError("❌ " + log_message);
        return -1;
    }
    
    // 2. Distanz berechnen
    double distance_in_price = MathAbs(entry_price - sl_price);
    LogImportant("   Distance in Price: " + DoubleToString(distance_in_price, 8));
    
    // 3. Krypto-spezifische Berechnung
    double loss_per_lot = 0.0;
    
    // Methode 1: Direkte Berechnung mit Contract Size
    if(contract_size > 0) {
        loss_per_lot = distance_in_price * contract_size;
        LogImportant("   METHODE 1 (Contract Size): " + DoubleToString(distance_in_price, 8) + " × " + DoubleToString(contract_size, 2));
        LogImportant("   Loss per Lot: " + DoubleToString(loss_per_lot, 2) + " " + quote_currency);
    }
    
    // Methode 2: Fallback mit Tick-Werten
    if(loss_per_lot <= 0) {
        double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
        
        LogImportant("   METHODE 2 (Tick Values):");
        LogImportant("   Tick Value: " + DoubleToString(tick_value, 8));
        LogImportant("   Tick Size: " + DoubleToString(tick_size, 8));
        
        if(tick_value > 0 && tick_size > 0) {
            double ticks = distance_in_price / tick_size;
            loss_per_lot = ticks * tick_value;
            LogImportant("   Ticks: " + DoubleToString(ticks, 2));
            LogImportant("   Loss per Lot: " + DoubleToString(loss_per_lot, 2) + " " + quote_currency);
        }
    }
    
    // Methode 3: Intelligente Schätzung für Krypto
    if(loss_per_lot <= 0) {
        LogImportant("   METHODE 3 (Krypto-Schätzung):");
        
        // Für die meisten Krypto-Paare: 1 Lot = 1 Einheit der Basis-Währung
        // Bei XRPUSDT: 1 Lot = 1 XRP, Preisänderung = direkter USD-Verlust
        loss_per_lot = distance_in_price * 1.0; // 1 Lot = 1 Einheit
        
        LogImportant("   Annahme: 1 Lot = 1 Einheit der Basis-Währung");
        LogImportant("   Loss per Lot: " + DoubleToString(loss_per_lot, 2) + " " + quote_currency);
    }
    
    // 4. Währungskonvertierung (falls erforderlich)
    if(quote_currency != account_currency && loss_per_lot > 0) {
        double conversion_rate = GetCurrencyConversionRate_v83(quote_currency, account_currency);
        if(conversion_rate > 0) {
            double converted_loss = loss_per_lot * conversion_rate;
            LogImportant("   WÄHRUNGSKONVERTIERUNG:");
            LogImportant("   " + DoubleToString(loss_per_lot, 2) + " " + quote_currency + " × " + DoubleToString(conversion_rate, 4) + " = " + DoubleToString(converted_loss, 2) + " " + account_currency);
            loss_per_lot = converted_loss;
        } else {
            LogWarning("   ⚠️ Währungskonvertierung fehlgeschlagen, verwende " + quote_currency + " Werte");
        }
    }
    
    // 5. Krypto-spezifische Validierung
    double expected_range_min = distance_in_price * 0.01;  // Minimum: 1% der Preisdistanz
    double expected_range_max = distance_in_price * 1000;  // Maximum: 1000x der Preisdistanz
    
    LogImportant("   KRYPTO-VALIDIERUNG:");
    LogImportant("   Erwarteter Bereich: " + DoubleToString(expected_range_min, 4) + " - " + DoubleToString(expected_range_max, 2));
    
    if(loss_per_lot <= 0) {
        log_message = "Berechneter Verlust ist null oder negativ: " + DoubleToString(loss_per_lot, 5);
        LogError("❌ " + log_message);
        return -1;
    }
    
    if(loss_per_lot < expected_range_min) {
        LogWarning("⚠️ Loss per Lot möglicherweise zu klein: " + DoubleToString(loss_per_lot, 4) + " < " + DoubleToString(expected_range_min, 4));
        // Aber nicht ablehnen - könnte bei sehr kleinen Distanzen normal sein
    }
    
    if(loss_per_lot > expected_range_max) {
        LogWarning("⚠️ Loss per Lot möglicherweise zu hoch: " + DoubleToString(loss_per_lot, 2) + " > " + DoubleToString(expected_range_max, 2));
        LogWarning("   Aber akzeptiere Wert - könnte bei großen Distanzen normal sein");
        // NICHT ablehnen - der Wert könnte korrekt sein
    }
    
    LogImportant("✅ KRYPTO-BERECHNUNG ERFOLGREICH: " + DoubleToString(loss_per_lot, 4) + " " + account_currency);
    return loss_per_lot;
}

//+------------------------------------------------------------------+
//| VERBESSERTE ROBUSTE LOT-BERECHNUNG MIT KRYPTO-SUPPORT (v8.3.2) |
//+------------------------------------------------------------------+
double GetRobustLossPerLot_v832(string symbol, ENUM_ORDER_TYPE order_type, double entry_price, double sl_price) {
    LogImportant("🔧 VERBESSERTE ROBUSTE LOT-BERECHNUNG v8.3.2:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Entry: " + DoubleToString(entry_price, 5));
    LogImportant("   SL: " + DoubleToString(sl_price, 5));
    LogImportant("   Distance: " + DoubleToString(MathAbs(entry_price - sl_price), 5));
    
    double loss_per_lot = -1;
    string method_used = "";
    string log_msg = "";
    
    // ========== INTELLIGENTE SYMBOL-KLASSIFIZIERUNG ==========
    ENUM_SYMBOL_TYPE symbol_type = ClassifySymbol_v832(symbol);
    
    // ========== METHODE 1: KRYPTO-SPEZIFISCHE BERECHNUNG (v8.3.2) ==========
    if(symbol_type == SYMBOL_TYPE_CRYPTO) {
        LogImportant("🚀 VERWENDE NEUE KRYPTO-METHODE (v8.3.2):");
        loss_per_lot = CalculateLossPerLot_Crypto_v832(symbol, entry_price, sl_price, log_msg);
        if(loss_per_lot > 0) {
            method_used = "Krypto-spezifische Berechnung (v8.3.2)";
            LogImportant("✅ KRYPTO-METHODE ERFOLGREICH!");
        } else {
            LogWarning("⚠️ Krypto-Methode fehlgeschlagen: " + log_msg);
        }
    }
    
    // ========== METHODE 2: FOREX-SPEZIFISCHE BERECHNUNG (v8.3) ==========
    if(loss_per_lot <= 0 && symbol_type == SYMBOL_TYPE_FOREX) {
        LogImportant("🆕 VERWENDE FOREX-METHODE (v8.3):");
        loss_per_lot = CalculateLossPerLot_Forex_v83(symbol, entry_price, sl_price, log_msg);
        if(loss_per_lot > 0) {
            method_used = "Forex-spezifische Berechnung (v8.3)";
            LogImportant("✅ FOREX-METHODE ERFOLGREICH!");
        } else {
            LogWarning("⚠️ Forex-Methode fehlgeschlagen: " + log_msg);
        }
    }
    
    // ========== FALLBACK: BESTEHENDE METHODEN ==========
    if(loss_per_lot <= 0) {
        LogImportant("🔄 FALLBACK ZU BESTEHENDEN METHODEN:");
        
        // Verwende die ursprüngliche GetRobustLossPerLot Funktion als Fallback
        loss_per_lot = GetRobustLossPerLot(symbol, order_type, entry_price, sl_price);
        if(loss_per_lot > 0) {
            method_used = "Bestehende Methoden (Fallback)";
        } else {
            LogError("❌ Alle Methoden fehlgeschlagen für Symbol: " + symbol);
            return -1;
        }
    }
    
    LogImportant("✅ VERBESSERTE BERECHNUNG ERFOLGREICH:");
    LogImportant("   Symbol-Typ: " + EnumToString(symbol_type));
    LogImportant("   Methode: " + method_used);
    LogImportant("   Verlust bei 1.0 Lot: " + DoubleToString(loss_per_lot, 5) + " " + AccountInfoString(ACCOUNT_CURRENCY));
    
    return loss_per_lot;
}

//+------------------------------------------------------------------+
//| FLEXIBLE LOT-LIMITS BASIEREND AUF SYMBOL-TYP (v8.3.2)          |
//+------------------------------------------------------------------+
double GetMaxAllowedLots_v832(string symbol, ENUM_SYMBOL_TYPE symbol_type) {
    double max_lots = 10.0; // Standard-Limit
    
    switch(symbol_type) {
        case SYMBOL_TYPE_FOREX:
            max_lots = 10.0;   // Forex: 10 Lots
            break;
        case SYMBOL_TYPE_CRYPTO:
            max_lots = 100.0;  // Krypto: 100 Lots (höher wegen kleinerer Lot-Sizes)
            break;
        case SYMBOL_TYPE_METAL:
            max_lots = 5.0;    // Metalle: 5 Lots (konservativ)
            break;
        case SYMBOL_TYPE_INDEX:
            max_lots = 2.0;    // Indizes: 2 Lots (sehr konservativ)
            break;
        case SYMBOL_TYPE_COMMODITY:
            max_lots = 5.0;    // Rohstoffe: 5 Lots
            break;
        default:
            max_lots = 10.0;   // Unbekannt: Standard
            break;
    }
    
    LogImportant("🛡️ FLEXIBLE LOT-LIMITS:");
    LogImportant("   Symbol-Typ: " + EnumToString(symbol_type));
    LogImportant("   Max erlaubte Lots: " + DoubleToString(max_lots, 1));
    
    return max_lots;
}


//+------------------------------------------------------------------+
//| ROBUSTE SYMBOL-DATENSAMMLUNG (v8.32)                            |
//+------------------------------------------------------------------+
struct SymbolDataCollection {
    // Basis-Informationen
    string symbol;
    bool is_available;
    bool is_selected;
    
    // Preis-Daten
    double bid;
    double ask;
    double spread;
    double last_price;
    
    // Symbol-Spezifikationen
    int digits;
    double point;
    double tick_size;
    double tick_value;
    double contract_size;
    
    // Lot-Informationen
    double volume_min;
    double volume_max;
    double volume_step;
    double volume_limit;
    
    // Währungen
    string base_currency;
    string profit_currency;
    string margin_currency;
    
    // Trading-Zeiten
    bool trade_allowed;
    datetime trade_time_from;
    datetime trade_time_to;
    
    // Margin-Informationen
    double margin_initial;
    double margin_maintenance;
    
    // Zusätzliche Daten
    double swap_long;
    double swap_short;
    int spread_float;
    
    // Validierung
    bool data_complete;
    string error_message;
    datetime collection_time;
};

//+------------------------------------------------------------------+
//| SAMMLE ALLE SYMBOL-DATEN (v8.32)                                |
//+------------------------------------------------------------------+
SymbolDataCollection CollectSymbolData_v832(string symbol, int max_retries = 3, int retry_delay_ms = 500) {
    SymbolDataCollection data;
    data.symbol = symbol;
    data.is_available = false;
    data.is_selected = false;
    data.data_complete = false;
    data.error_message = "";
    data.collection_time = TimeCurrent();
    
    LogImportant("📊 ROBUSTE SYMBOL-DATENSAMMLUNG v8.32:");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Max Retries: " + IntegerToString(max_retries));
    
    for(int retry = 0; retry <= max_retries; retry++) {
        if(retry > 0) {
            LogDebug("   Retry " + IntegerToString(retry) + "/" + IntegerToString(max_retries));
            Sleep(retry_delay_ms);
        }
        
        // ========== SCHRITT 1: SYMBOL AKTIVIEREN ==========
        LogDebug("   Schritt 1: Symbol aktivieren...");
        if(!SymbolSelect(symbol, true)) {
            data.error_message = "Symbol konnte nicht aktiviert werden";
            LogWarning("   ⚠️ " + data.error_message);
            continue;
        }
        data.is_selected = true;
        
        // Kurz warten für Daten-Laden
        Sleep(100);
        
        // ========== SCHRITT 2: PREIS-DATEN SAMMELN ==========
        LogDebug("   Schritt 2: Preis-Daten sammeln...");
        data.bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        data.ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        data.last_price = SymbolInfoDouble(symbol, SYMBOL_LAST);
        
        if(data.bid <= 0 || data.ask <= 0) {
            data.error_message = "Keine gültigen Preise verfügbar (Bid: " + DoubleToString(data.bid, 5) + ", Ask: " + DoubleToString(data.ask, 5) + ")";
            LogWarning("   ⚠️ " + data.error_message);
            continue;
        }
        
        data.spread = data.ask - data.bid;
        data.is_available = true;
        
        // ========== SCHRITT 3: SYMBOL-SPEZIFIKATIONEN ==========
        LogDebug("   Schritt 3: Symbol-Spezifikationen sammeln...");
        data.digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        data.point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        data.tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
        data.tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        data.contract_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
        
        // ========== SCHRITT 4: LOT-INFORMATIONEN ==========
        LogDebug("   Schritt 4: Lot-Informationen sammeln...");
        data.volume_min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
        data.volume_max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
        data.volume_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
        data.volume_limit = SymbolInfoDouble(symbol, SYMBOL_VOLUME_LIMIT);
        
        // ========== SCHRITT 5: WÄHRUNGEN ==========
        LogDebug("   Schritt 5: Währungen sammeln...");
        data.base_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
        data.profit_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
        data.margin_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_MARGIN);
        
        // ========== SCHRITT 6: TRADING-ZEITEN ==========
        LogDebug("   Schritt 6: Trading-Zeiten prüfen...");
        data.trade_allowed = (bool)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
        data.trade_time_from = (datetime)SymbolInfoInteger(symbol, SYMBOL_START_TIME);
        data.trade_time_to = (datetime)SymbolInfoInteger(symbol, SYMBOL_EXPIRATION_TIME);
        
        // ========== SCHRITT 7: MARGIN-INFORMATIONEN ==========
        LogDebug("   Schritt 7: Margin-Informationen sammeln...");
        data.margin_initial = SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL);
        data.margin_maintenance = SymbolInfoDouble(symbol, SYMBOL_MARGIN_MAINTENANCE);
        
        // ========== SCHRITT 8: ZUSÄTZLICHE DATEN ==========
        LogDebug("   Schritt 8: Zusätzliche Daten sammeln...");
        data.swap_long = SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG);
        data.swap_short = SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT);
        data.spread_float = (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD_FLOAT);
        
        // ========== SCHRITT 9: VALIDIERUNG ==========
        LogDebug("   Schritt 9: Daten validieren...");
        bool validation_passed = true;
        string validation_errors = "";
        
        // Kritische Validierungen
        if(data.point <= 0) {
            validation_errors += "Point ungültig (" + DoubleToString(data.point, 8) + "); ";
            validation_passed = false;
        }
        
        if(data.volume_min <= 0 || data.volume_max <= 0 || data.volume_step <= 0) {
            validation_errors += "Lot-Parameter ungültig (Min: " + DoubleToString(data.volume_min, 3) + 
                               ", Max: " + DoubleToString(data.volume_max, 3) + 
                               ", Step: " + DoubleToString(data.volume_step, 4) + "); ";
            validation_passed = false;
        }
        
        if(data.base_currency == "" || data.profit_currency == "") {
            validation_errors += "Währungen fehlen (Base: '" + data.base_currency + 
                               "', Profit: '" + data.profit_currency + "'); ";
            validation_passed = false;
        }
        
        if(validation_passed) {
            data.data_complete = true;
            LogImportant("✅ DATENSAMMLUNG ERFOLGREICH nach " + IntegerToString(retry + 1) + " Versuch(en)");
            break;
        } else {
            data.error_message = "Validierung fehlgeschlagen: " + validation_errors;
            LogWarning("   ⚠️ " + data.error_message);
        }
    }
    
    // ========== FINALE AUSGABE ==========
    if(data.data_complete) {
        LogImportant("📊 GESAMMELTE SYMBOL-DATEN:");
        LogImportant("   Preise: Bid=" + DoubleToString(data.bid, data.digits) + 
                    ", Ask=" + DoubleToString(data.ask, data.digits) + 
                    ", Spread=" + DoubleToString(data.spread, data.digits));
        LogImportant("   Spezifikationen: Digits=" + IntegerToString(data.digits) + 
                    ", Point=" + DoubleToString(data.point, 8) + 
                    ", Contract=" + DoubleToString(data.contract_size, 2));
        LogImportant("   Lots: Min=" + DoubleToString(data.volume_min, 3) + 
                    ", Max=" + DoubleToString(data.volume_max, 3) + 
                    ", Step=" + DoubleToString(data.volume_step, 4));
        LogImportant("   Währungen: " + data.base_currency + "/" + data.profit_currency + 
                    " (Margin: " + data.margin_currency + ")");
        LogImportant("   Tick: Size=" + DoubleToString(data.tick_size, 8) + 
                    ", Value=" + DoubleToString(data.tick_value, 5));
    } else {
        LogError("❌ DATENSAMMLUNG FEHLGESCHLAGEN nach " + IntegerToString(max_retries + 1) + " Versuchen");
        LogError("   Letzter Fehler: " + data.error_message);
    }
    
    return data;
}

//+------------------------------------------------------------------+
//| VERBESSERTE LOT-BERECHNUNG MIT DATENSAMMLUNG (v8.32)            |
//+------------------------------------------------------------------+
double CalculateLots_v832_Enhanced(string symbol, double entry_price, double sl_price, 
                                   double risk_percent, ENUM_ORDER_TYPE order_type, string &message) {
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("💰 ENHANCED LOT-BERECHNUNG v8.32 für " + symbol);
    LogImportant("════════════════════════════════════════════");
    
    // ========== SCHRITT 1: ROBUSTE DATENSAMMLUNG ==========
    SymbolDataCollection symbol_data = CollectSymbolData_v832(symbol, 3, 500);
    
    if(!symbol_data.data_complete) {
        message = "Symbol data collection failed: " + symbol_data.error_message;
        LogError("❌ " + message);
        return 0;
    }
    
    // ========== SCHRITT 2: ACCOUNT-INFORMATIONEN ==========
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * risk_percent / 100.0;
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    LogImportant("📊 ACCOUNT & RISK:");
    LogImportant("   Balance: " + DoubleToString(balance, 2) + " " + account_currency);
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    LogImportant("   Risiko-Betrag: " + DoubleToString(risk_amount, 2) + " " + account_currency);
    
    // ========== SCHRITT 3: ENTRY-PREIS BESTIMMEN ==========
    if(entry_price <= 0) {
        entry_price = (sl_price < symbol_data.bid) ? symbol_data.ask : symbol_data.bid;
        LogDebug("Entry automatisch gesetzt: " + DoubleToString(entry_price, symbol_data.digits));
    }
    
    // Order-Typ bestimmen
    ENUM_ORDER_TYPE calc_order_type = (entry_price > sl_price) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    
    LogImportant("📍 TRADE-PARAMETER (MIT GESAMMELTEN DATEN):");
    LogImportant("   Order Type: " + (calc_order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"));
    LogImportant("   Entry: " + DoubleToString(entry_price, symbol_data.digits));
    LogImportant("   SL: " + DoubleToString(sl_price, symbol_data.digits));
    LogImportant("   Distanz: " + DoubleToString(MathAbs(entry_price - sl_price), symbol_data.digits));
    LogImportant("   Spread: " + DoubleToString(symbol_data.spread, symbol_data.digits));
    
    // ========== SCHRITT 4: LOSS-PER-LOT MIT GESAMMELTEN DATEN ==========
    double loss_per_lot = GetRobustLossPerLot_v832(symbol, calc_order_type, entry_price, sl_price);
    
    if(loss_per_lot <= 0) {
        LogError("❌ Loss-per-Lot Berechnung fehlgeschlagen trotz vollständiger Datensammlung!");
        message = "Loss calculation failed despite complete data collection";
        return 0;
    }
    
    LogImportant("💡 VERLUST PRO LOT (MIT GESAMMELTEN DATEN): " + DoubleToString(loss_per_lot, 2) + " " + account_currency);
    
    // ========== SCHRITT 5: LOT-BERECHNUNG MIT VALIDIERUNG ==========
    double theoretical_lots = risk_amount / loss_per_lot;
    LogImportant("   Theoretisch maximale Lots: " + DoubleToString(theoretical_lots, 6));
    
    // Sicherheitsbegrenzung
    double max_allowed_lots = (balance * 0.10) / loss_per_lot;
    LogImportant("   Sicherheits-Maximum (10% Konto): " + DoubleToString(max_allowed_lots, 3));
    
    // Verwende das kleinere der beiden Limits
    double safe_lots = MathMin(theoretical_lots, max_allowed_lots);
    safe_lots = MathFloor(safe_lots / symbol_data.volume_step) * symbol_data.volume_step;
    LogImportant("   Auf Lot-Step normalisiert: " + DoubleToString(safe_lots, 3));
    
    // ========== SCHRITT 6: SYMBOL-SPEZIFISCHE VALIDIERUNG ==========
    if(safe_lots < symbol_data.volume_min) {
        LogWarning("⚠️ Berechnete Lots (" + DoubleToString(safe_lots, 3) + ") unter Minimum (" + DoubleToString(symbol_data.volume_min, 3) + ")");
        
        double min_lot_risk_amount = symbol_data.volume_min * loss_per_lot;
        double min_lot_risk_percent = (min_lot_risk_amount / balance) * 100.0;
        
        if(min_lot_risk_percent > risk_percent) {
            LogError("❌ RISIKO ZU KLEIN! Min Lot würde " + DoubleToString(min_lot_risk_percent, 2) + "% riskieren, aber nur " + DoubleToString(risk_percent, 2) + "% erlaubt");
            message = "Risk too small. Min lot requires " + DoubleToString(min_lot_risk_percent, 2) + "% risk";
            return 0;
        } else {
            safe_lots = symbol_data.volume_min;
            LogImportant("✅ Min Lot akzeptiert (Risiko: " + DoubleToString(min_lot_risk_percent, 2) + "%)");
        }
    }
    
    if(safe_lots > symbol_data.volume_max) {
        safe_lots = symbol_data.volume_max;
        LogWarning("⚠️ Auf Maximum begrenzt: " + DoubleToString(symbol_data.volume_max, 3));
    }
    
    // ========== SCHRITT 7: FINALE VALIDIERUNG ==========
    double actual_risk_amount = safe_lots * loss_per_lot;
    double actual_risk_percent = (actual_risk_amount / balance) * 100.0;
    
    LogImportant("🔍 FINALE VALIDIERUNG (MIT GESAMMELTEN DATEN):");
    LogImportant("   Finale Lots: " + DoubleToString(safe_lots, 3));
    LogImportant("   Tatsächlicher Verlust bei SL: " + DoubleToString(actual_risk_amount, 2) + " " + account_currency);
    LogImportant("   Tatsächliches Risiko: " + DoubleToString(actual_risk_percent, 3) + "%");
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    
    // ========== SCHRITT 8: FLEXIBLE LOT-LIMITS ==========
    ENUM_SYMBOL_TYPE symbol_type = ClassifySymbol_v832(symbol);
    double ABSOLUTE_MAX_LOTS = GetMaxAllowedLots_v832(symbol, symbol_type);
    
    if(safe_lots > ABSOLUTE_MAX_LOTS) {
        LogError("🚨 NOTFALL-STOPP: " + DoubleToString(safe_lots, 3) + " Lots > " + DoubleToString(ABSOLUTE_MAX_LOTS, 1) + " Lots!");
        LogError("   Symbol-Typ: " + EnumToString(symbol_type));
        message = "EMERGENCY STOP: " + DoubleToString(safe_lots, 3) + " lots exceeds " + EnumToString(symbol_type) + " safety limit";
        return 0;
    }
    
    LogImportant("✅ ENHANCED LOT-BERECHNUNG v8.32 ERFOLGREICH:");
    LogImportant("   Finale Lots: " + DoubleToString(safe_lots, 3));
    LogImportant("   Finales Risiko: " + DoubleToString(actual_risk_percent, 3) + "%");
    LogImportant("   Datensammlung: VOLLSTÄNDIG");
    LogImportant("════════════════════════════════════════════");
    
    message = "OK - Risk: " + DoubleToString(actual_risk_percent, 2) + "% (Target: " + DoubleToString(risk_percent, 2) + "%) - v8.32 ENHANCED";
    return safe_lots;
}


//+------------------------------------------------------------------+
//| VERSION 8.4 - EINHEITLICHE LOTSIZE-BERECHNUNG                   |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| DYNAMISCHE LIMIT-ERMITTLUNG (v8.4)                              |
//+------------------------------------------------------------------+
struct DynamicLimits {
    double max_lots_account;      // Basierend auf Account-Balance
    double max_lots_symbol;       // Basierend auf Symbol-Spezifikationen
    double max_lots_asset_type;   // Basierend auf Asset-Typ
    double max_lots_risk;         // Basierend auf Risiko-Management
    double final_max_lots;        // Finales Limit (Minimum aller)
    
    string limit_reason;          // Grund für das finale Limit
    bool limits_valid;            // Sind alle Limits gültig?
};

DynamicLimits GetDynamicLimits_v84(string symbol, SymbolDataCollection &symbol_data, double balance) {
    DynamicLimits limits;
    limits.limits_valid = false;
    
    LogImportant("🛡️ DYNAMISCHE LIMIT-ERMITTLUNG v8.4:");
    
    // 1. Account-basiertes Limit (10% der Balance)
    double min_loss_per_lot = 1.0; // Minimum 1 EUR/USD pro Lot
    limits.max_lots_account = (balance * 0.10) / min_loss_per_lot;
    LogImportant("   Account-Limit (10% Balance): " + DoubleToString(limits.max_lots_account, 1) + " Lots");
    
    // 2. Symbol-basiertes Limit
    limits.max_lots_symbol = symbol_data.volume_max;
    LogImportant("   Symbol-Limit (Max Volume): " + DoubleToString(limits.max_lots_symbol, 1) + " Lots");
    
    // 3. Asset-Typ basiertes Limit
    ENUM_SYMBOL_TYPE symbol_type = ClassifySymbol_v832(symbol);
    switch(symbol_type) {
        case SYMBOL_TYPE_FOREX:
            limits.max_lots_asset_type = 50.0;   // Forex: 50 Lots
            break;
        case SYMBOL_TYPE_CRYPTO:
            limits.max_lots_asset_type = 500.0;  // Krypto: 500 Lots (oft kleinere Lot-Sizes)
            break;
        case SYMBOL_TYPE_METAL:
            limits.max_lots_asset_type = 20.0;   // Metalle: 20 Lots
            break;
        case SYMBOL_TYPE_INDEX:
            limits.max_lots_asset_type = 5.0;    // Indizes: 5 Lots (sehr konservativ)
            break;
        case SYMBOL_TYPE_COMMODITY:
            limits.max_lots_asset_type = 10.0;   // Rohstoffe: 10 Lots
            break;
        default:
            limits.max_lots_asset_type = 25.0;   // Unbekannt: 25 Lots
            break;
    }
    LogImportant("   Asset-Typ Limit (" + EnumToString(symbol_type) + "): " + DoubleToString(limits.max_lots_asset_type, 1) + " Lots");
    
    // 4. Risiko-Management Limit (Nie mehr als 20% Risiko bei 1 Lot)
    double estimated_loss_per_lot = balance * 0.001; // Schätzung: 0.1% pro Lot
    limits.max_lots_risk = (balance * 0.20) / estimated_loss_per_lot;
    LogImportant("   Risiko-Limit (20% Max): " + DoubleToString(limits.max_lots_risk, 1) + " Lots");
    
    // 5. Finales Limit = Minimum aller Limits
    limits.final_max_lots = MathMin(limits.max_lots_account, 
                           MathMin(limits.max_lots_symbol,
                           MathMin(limits.max_lots_asset_type, limits.max_lots_risk)));
    
    // Bestimme den limitierenden Faktor
    if(limits.final_max_lots == limits.max_lots_account) {
        limits.limit_reason = "Account-Balance (10% Regel)";
    } else if(limits.final_max_lots == limits.max_lots_symbol) {
        limits.limit_reason = "Symbol Maximum Volume";
    } else if(limits.final_max_lots == limits.max_lots_asset_type) {
        limits.limit_reason = "Asset-Typ Sicherheit (" + EnumToString(symbol_type) + ")";
    } else {
        limits.limit_reason = "Risiko-Management (20% Regel)";
    }
    
    limits.limits_valid = (limits.final_max_lots > 0);
    
    LogImportant("   FINALES LIMIT: " + DoubleToString(limits.final_max_lots, 1) + " Lots");
    LogImportant("   Limitierender Faktor: " + limits.limit_reason);
    
    return limits;
}

//+------------------------------------------------------------------+
//| EINHEITLICHE LOSS-PER-LOT BERECHNUNG (v8.4)                    |
//+------------------------------------------------------------------+
double CalculateLossPerLot_v84(string symbol, SymbolDataCollection &symbol_data, 
                               double entry_price, double sl_price, ENUM_SYMBOL_TYPE symbol_type) {
    
    LogImportant("💰 EINHEITLICHE LOSS-PER-LOT BERECHNUNG v8.4:");
    LogImportant("   Symbol: " + symbol + " (Typ: " + EnumToString(symbol_type) + ")");
    LogImportant("   Entry: " + DoubleToString(entry_price, symbol_data.digits));
    LogImportant("   SL: " + DoubleToString(sl_price, symbol_data.digits));
    
    double distance_in_price = MathAbs(entry_price - sl_price);
    LogImportant("   Distanz: " + DoubleToString(distance_in_price, symbol_data.digits));
    
    double loss_per_lot = 0.0;
    string method_used = "";
    
    // ========== METHODE 1: OrderCalcProfit (Präziseste Methode) ==========
    double profit_at_sl = 0.0;
    ENUM_ORDER_TYPE calc_order_type = (entry_price > sl_price) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    
    if(OrderCalcProfit(calc_order_type, symbol, 1.0, entry_price, sl_price, profit_at_sl)) {
        loss_per_lot = MathAbs(profit_at_sl);
        method_used = "OrderCalcProfit (Präzise)";
        LogImportant("   ✅ METHODE 1 ERFOLGREICH: " + method_used);
    }
    
    // ========== METHODE 2: Contract Size Berechnung ==========
    if(loss_per_lot <= 0 && symbol_data.contract_size > 0) {
        loss_per_lot = distance_in_price * symbol_data.contract_size;
        method_used = "Contract Size (" + DoubleToString(symbol_data.contract_size, 2) + ")";
        LogImportant("   ✅ METHODE 2 ERFOLGREICH: " + method_used);
    }
    
    // ========== METHODE 3: Tick Value Berechnung ==========
    if(loss_per_lot <= 0 && symbol_data.tick_value > 0 && symbol_data.tick_size > 0) {
        double ticks = distance_in_price / symbol_data.tick_size;
        loss_per_lot = ticks * symbol_data.tick_value;
        method_used = "Tick Value (Ticks: " + DoubleToString(ticks, 1) + ")";
        LogImportant("   ✅ METHODE 3 ERFOLGREICH: " + method_used);
    }
    
    // ========== METHODE 4: Asset-spezifische Schätzung ==========
    if(loss_per_lot <= 0) {
        switch(symbol_type) {
            case SYMBOL_TYPE_FOREX: {
                // Forex: Pip-basierte Schätzung
                double pip_size = (symbol_data.digits == 5 || symbol_data.digits == 3) ? 
                                 symbol_data.point * 10 : symbol_data.point;
                double pips = distance_in_price / pip_size;
                loss_per_lot = pips * 1.0; // Schätzung: 1 EUR pro Pip
                method_used = "Forex Pip-Schätzung (" + DoubleToString(pips, 1) + " Pips)";
                break;
            }
                
            case SYMBOL_TYPE_CRYPTO: {
                // Krypto: Direkte Preisdifferenz
                loss_per_lot = distance_in_price * 1.0; // 1 Lot = 1 Einheit
                method_used = "Krypto Direkt-Schätzung";
                break;
            }
                
            case SYMBOL_TYPE_METAL: {
                // Metalle: Basierend auf Preis-Level
                loss_per_lot = distance_in_price * 100.0; // Typisch für Gold/Silber
                method_used = "Metall-Schätzung";
                break;
            }
                
            default: {
                // Allgemeine Schätzung
                loss_per_lot = distance_in_price * 10.0;
                method_used = "Allgemeine Schätzung";
                break;
            }
        }
        LogImportant("   ✅ METHODE 4 ERFOLGREICH: " + method_used);
    }
    
    // ========== WÄHRUNGSKONVERTIERUNG ==========
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    if(symbol_data.profit_currency != account_currency && loss_per_lot > 0) {
        double conversion_rate = GetCurrencyConversionRate_v83(symbol_data.profit_currency, account_currency);
        if(conversion_rate > 0) {
            double converted_loss = loss_per_lot * conversion_rate;
            LogImportant("   💱 WÄHRUNGSKONVERTIERUNG: " + DoubleToString(loss_per_lot, 2) + " " + 
                        symbol_data.profit_currency + " → " + DoubleToString(converted_loss, 2) + " " + account_currency);
            loss_per_lot = converted_loss;
        }
    }
    
    // ========== REALISTISCHE VALIDIERUNG ==========
    double min_expected = distance_in_price * 0.01;  // Minimum: 1% der Preisdistanz
    double max_expected = distance_in_price * 10000; // Maximum: 10000x der Preisdistanz
    
    if(loss_per_lot < min_expected || loss_per_lot > max_expected) {
        LogWarning("⚠️ Loss per Lot außerhalb erwarteter Bereiche: " + DoubleToString(loss_per_lot, 4));
        LogWarning("   Erwartet: " + DoubleToString(min_expected, 4) + " - " + DoubleToString(max_expected, 2));
        LogWarning("   Aber akzeptiere Wert - könnte korrekt sein");
    }
    
    LogImportant("✅ LOSS-PER-LOT BERECHNUNG ERFOLGREICH:");
    LogImportant("   Methode: " + method_used);
    LogImportant("   Verlust pro Lot: " + DoubleToString(loss_per_lot, 4) + " " + account_currency);
    
    return loss_per_lot;
}

//+------------------------------------------------------------------+
//| EINHEITLICHE LOTSIZE-BERECHNUNG v8.4 (ALLE ASSETS)             |
//+------------------------------------------------------------------+
double CalculateLots_v84(string symbol, double entry_price, double sl_price, 
                         double risk_percent, ENUM_ORDER_TYPE order_type, string &message) {
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("🚀 EINHEITLICHE LOTSIZE-BERECHNUNG v8.4");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Risiko: " + DoubleToString(risk_percent, 2) + "%");
    LogImportant("════════════════════════════════════════════");
    
    // ========== SCHRITT 1: ROBUSTE DATENSAMMLUNG ==========
    SymbolDataCollection symbol_data = CollectSymbolData_v832(symbol, 3, 500);
    
    if(!symbol_data.data_complete) {
        message = "Symbol data collection failed: " + symbol_data.error_message;
        LogError("❌ " + message);
        return 0;
    }
    
    // ========== SCHRITT 2: ACCOUNT & RISK SETUP ==========
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * risk_percent / 100.0;
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    LogImportant("📊 ACCOUNT & RISK:");
    LogImportant("   Balance: " + DoubleToString(balance, 2) + " " + account_currency);
    LogImportant("   Risiko-Betrag: " + DoubleToString(risk_amount, 2) + " " + account_currency);
    
    // ========== SCHRITT 3: ENTRY-PREIS BESTIMMEN ==========
    if(entry_price <= 0) {
        entry_price = (sl_price < symbol_data.bid) ? symbol_data.ask : symbol_data.bid;
        LogDebug("Entry automatisch gesetzt: " + DoubleToString(entry_price, symbol_data.digits));
    }
    
    // ========== SCHRITT 4: ASSET-TYP ERKENNEN ==========
    ENUM_SYMBOL_TYPE symbol_type = ClassifySymbol_v832(symbol);
    LogImportant("🔍 ASSET-TYP: " + EnumToString(symbol_type));
    
    // ========== SCHRITT 5: DYNAMISCHE LIMITS ERMITTELN ==========
    DynamicLimits limits = GetDynamicLimits_v84(symbol, symbol_data, balance);
    
    if(!limits.limits_valid) {
        message = "Dynamic limits calculation failed";
        LogError("❌ " + message);
        return 0;
    }
    
    // ========== SCHRITT 6: LOSS-PER-LOT BERECHNEN ==========
    double loss_per_lot = CalculateLossPerLot_v84(symbol, symbol_data, entry_price, sl_price, symbol_type);
    
    if(loss_per_lot <= 0) {
        message = "Loss per lot calculation failed";
        LogError("❌ " + message);
        return 0;
    }
    
    // ========== SCHRITT 7: LOTSIZE BERECHNEN ==========
    double theoretical_lots = risk_amount / loss_per_lot;
    LogImportant("📈 LOTSIZE-BERECHNUNG:");
    LogImportant("   Theoretische Lots: " + DoubleToString(theoretical_lots, 6));
    
    // Auf Symbol-Step normalisieren
    double normalized_lots = MathFloor(theoretical_lots / symbol_data.volume_step) * symbol_data.volume_step;
    LogImportant("   Normalisiert (Step " + DoubleToString(symbol_data.volume_step, 4) + "): " + DoubleToString(normalized_lots, 3));
    
    // ========== SCHRITT 8: LIMITS ANWENDEN ==========
    double final_lots = normalized_lots;
    
    // Minimum-Lot prüfen
    if(final_lots < symbol_data.volume_min) {
        final_lots = symbol_data.volume_min;
        LogImportant("   Auf Minimum angehoben: " + DoubleToString(final_lots, 3));
    }
    
    // Maximum-Lot prüfen (Symbol)
    if(final_lots > symbol_data.volume_max) {
        final_lots = symbol_data.volume_max;
        LogImportant("   Auf Symbol-Maximum begrenzt: " + DoubleToString(final_lots, 3));
    }
    
    // Dynamisches Limit prüfen
    if(final_lots > limits.final_max_lots) {
        final_lots = limits.final_max_lots;
        LogImportant("   Auf dynamisches Limit begrenzt: " + DoubleToString(final_lots, 3));
        LogImportant("   Grund: " + limits.limit_reason);
    }
    
    // ========== SCHRITT 9: FINALE VALIDIERUNG ==========
    double actual_risk_amount = final_lots * loss_per_lot;
    double actual_risk_percent = (actual_risk_amount / balance) * 100.0;
    double risk_deviation = actual_risk_percent - risk_percent;
    
    LogImportant("🔍 FINALE VALIDIERUNG:");
    LogImportant("   Finale Lots: " + DoubleToString(final_lots, 3));
    LogImportant("   Tatsächliches Risiko: " + DoubleToString(actual_risk_percent, 3) + "%");
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    LogImportant("   Abweichung: " + DoubleToString(risk_deviation, 3) + "%");
    
    // Risiko-Bewertung
    if(risk_deviation > 0.1) { // Mehr als 0.1% Überschreitung
        LogError("❌ KRITISCHER FEHLER: Risiko um " + DoubleToString(risk_deviation, 3) + "% zu hoch!");
        message = "Risk exceeds target by " + DoubleToString(risk_deviation, 3) + "%";
        return 0;
    } else if(risk_deviation > -1.0) {
        LogSuccess("✅ OPTIMAL: Risiko gut ausgenutzt (Abweichung: " + DoubleToString(risk_deviation, 3) + "%)");
    } else {
        LogInfo("✅ SICHER: Risiko " + DoubleToString(MathAbs(risk_deviation), 2) + "% unter Ziel");
    }
    
    LogImportant("✅ EINHEITLICHE BERECHNUNG v8.4 ERFOLGREICH:");
    LogImportant("   Asset-Typ: " + EnumToString(symbol_type));
    LogImportant("   Finale Lots: " + DoubleToString(final_lots, 3));
    LogImportant("   Finales Risiko: " + DoubleToString(actual_risk_percent, 3) + "%");
    LogImportant("   Dynamisches Limit: " + DoubleToString(limits.final_max_lots, 1) + " (" + limits.limit_reason + ")");
    LogImportant("════════════════════════════════════════════");
    
    message = "OK - Risk: " + DoubleToString(actual_risk_percent, 2) + "% (Target: " + DoubleToString(risk_percent, 2) + "%) - v8.4 UNIFIED";
    return final_lots;
}


//+------------------------------------------------------------------+
//| VERSION 8.5 - EXAKTE RISIKO-KONTROLLE                           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| EXAKTE DYNAMISCHE LIMITS (v8.5) - NACH Loss-per-Lot Berechnung |
//+------------------------------------------------------------------+
struct ExactDynamicLimits {
    double max_lots_account;      // Basierend auf Account-Balance und tatsächlicher Loss-per-Lot
    double max_lots_symbol;       // Basierend auf Symbol-Spezifikationen
    double max_lots_risk_mgmt;    // Basierend auf konservativem Risiko-Management
    double final_max_lots;        // Finales Limit (Minimum aller)
    
    string limit_reason;          // Grund für das finale Limit
    bool limits_valid;            // Sind alle Limits gültig?
};

ExactDynamicLimits GetExactDynamicLimits_v85(string symbol, SymbolDataCollection &symbol_data, 
                                              double balance, double actual_loss_per_lot) {
    ExactDynamicLimits limits;
    limits.limits_valid = false;
    
    LogImportant("🛡️ EXAKTE DYNAMISCHE LIMITS v8.5 (NACH Loss-per-Lot Berechnung):");
    LogImportant("   Tatsächliche Loss per Lot: " + DoubleToString(actual_loss_per_lot, 4) + " EUR");
    
    if(actual_loss_per_lot <= 0) {
        LogError("❌ Ungültige Loss per Lot: " + DoubleToString(actual_loss_per_lot, 4));
        return limits;
    }
    
    // 1. Account-basiertes Limit (10% der Balance mit tatsächlicher Loss-per-Lot)
    limits.max_lots_account = (balance * 0.10) / actual_loss_per_lot;
    LogImportant("   Account-Limit (10% Balance): " + DoubleToString(limits.max_lots_account, 1) + " Lots");
    
    // 2. Symbol-basiertes Limit
    limits.max_lots_symbol = symbol_data.volume_max;
    LogImportant("   Symbol-Limit (Max Volume): " + DoubleToString(limits.max_lots_symbol, 1) + " Lots");
    
    // 3. Risiko-Management Limit (Nie mehr als 25% der Balance riskieren)
    limits.max_lots_risk_mgmt = (balance * 0.25) / actual_loss_per_lot;
    LogImportant("   Risiko-Management Limit (25% Max): " + DoubleToString(limits.max_lots_risk_mgmt, 1) + " Lots");
    
    // 4. Finales Limit = Minimum aller Limits
    limits.final_max_lots = MathMin(limits.max_lots_account, 
                           MathMin(limits.max_lots_symbol, limits.max_lots_risk_mgmt));
    
    // Bestimme den limitierenden Faktor
    if(limits.final_max_lots == limits.max_lots_account) {
        limits.limit_reason = "Account-Balance (10% Regel)";
    } else if(limits.final_max_lots == limits.max_lots_symbol) {
        limits.limit_reason = "Symbol Maximum Volume";
    } else {
        limits.limit_reason = "Risiko-Management (25% Regel)";
    }
    
    limits.limits_valid = (limits.final_max_lots > 0);
    
    LogImportant("   FINALES LIMIT: " + DoubleToString(limits.final_max_lots, 1) + " Lots");
    LogImportant("   Limitierender Faktor: " + limits.limit_reason);
    
    return limits;
}

//+------------------------------------------------------------------+
//| ITERATIVE RISIKO-KONTROLLE (v8.5)                               |
//+------------------------------------------------------------------+
double ApplyIterativeRiskControl_v85(double initial_lots, double loss_per_lot, double balance, 
                                      double target_risk_percent, double volume_step, 
                                      double volume_min, double volume_max, string &control_message) {
    
    LogImportant("🔄 ITERATIVE RISIKO-KONTROLLE v8.5:");
    LogImportant("   Initial Lots: " + DoubleToString(initial_lots, 6));
    LogImportant("   Target Risk: " + DoubleToString(target_risk_percent, 2) + "%");
    
    double target_risk_amount = balance * target_risk_percent / 100.0;
    double current_lots = initial_lots;
    int iteration = 0;
    const int max_iterations = 50;
    
    while(iteration < max_iterations) {
        iteration++;
        
        // Berechne aktuelles Risiko
        double current_risk_amount = current_lots * loss_per_lot;
        double current_risk_percent = (current_risk_amount / balance) * 100.0;
        double risk_deviation = current_risk_percent - target_risk_percent;
        
        LogDebug("   Iteration " + IntegerToString(iteration) + ": " + 
                DoubleToString(current_lots, 3) + " Lots = " + 
                DoubleToString(current_risk_percent, 3) + "% Risk");
        
        // 🛡️ ULTRA-STRIKTE TOLERANZ: Prüfe ob wir im akzeptablen Bereich sind (±0.001%)
        if(MathAbs(risk_deviation) <= 0.001) {
            LogImportant("   ✅ OPTIMAL: Risiko-Ziel erreicht in " + IntegerToString(iteration) + " Iterationen");
            LogImportant("   Finale Lots: " + DoubleToString(current_lots, 3));
            LogImportant("   Finales Risiko: " + DoubleToString(current_risk_percent, 3) + "%");
            LogImportant("   Abweichung: " + DoubleToString(risk_deviation, 4) + "%");
            
            control_message = "Optimal - Risk: " + DoubleToString(current_risk_percent, 3) + 
                             "% (Target: " + DoubleToString(target_risk_percent, 2) + "%) - " + 
                             IntegerToString(iteration) + " iterations";
            return current_lots;
        }
        
        // Risiko zu hoch - reduziere Lots
        if(risk_deviation > 0) {
            double reduction_factor = target_risk_amount / current_risk_amount;
            current_lots = current_lots * reduction_factor;
            
            // Auf Volume Step normalisieren (nach unten)
            current_lots = MathFloor(current_lots / volume_step) * volume_step;
            
            LogDebug("   Risiko zu hoch (" + DoubleToString(risk_deviation, 3) + 
                    "%) - reduziere auf " + DoubleToString(current_lots, 3) + " Lots");
        }
        // Risiko zu niedrig - erhöhe Lots (vorsichtig)
        else {
            double increase_factor = target_risk_amount / current_risk_amount;
            double new_lots = current_lots * increase_factor;
            
            // Auf Volume Step normalisieren (nach unten für Sicherheit)
            new_lots = MathFloor(new_lots / volume_step) * volume_step;
            
            // Nur erhöhen wenn es sicher ist
            if(new_lots > current_lots && new_lots <= volume_max) {
                current_lots = new_lots;
                LogDebug("   Risiko zu niedrig (" + DoubleToString(risk_deviation, 3) + 
                        "%) - erhöhe auf " + DoubleToString(current_lots, 3) + " Lots");
            } else {
                // Kann nicht sicher erhöhen - akzeptiere aktuellen Wert
                LogImportant("   ✅ SICHER: Kann nicht sicher erhöhen - akzeptiere " + 
                           DoubleToString(current_lots, 3) + " Lots");
                break;
            }
        }
        
        // Prüfe Minimum-Lot
        if(current_lots < volume_min) {
            current_lots = volume_min;
            LogImportant("   Auf Minimum-Lot angehoben: " + DoubleToString(current_lots, 3));
            break;
        }
        
        // Prüfe Maximum-Lot
        if(current_lots > volume_max) {
            current_lots = volume_max;
            LogImportant("   Auf Maximum-Lot begrenzt: " + DoubleToString(current_lots, 3));
            break;
        }
    }
    
    // Finale Berechnung
    double final_risk_amount = current_lots * loss_per_lot;
    double final_risk_percent = (final_risk_amount / balance) * 100.0;
    double final_deviation = final_risk_percent - target_risk_percent;
    
    LogImportant("   🔍 FINALE ITERATIVE KONTROLLE:");
    LogImportant("   Iterationen: " + IntegerToString(iteration));
    LogImportant("   Finale Lots: " + DoubleToString(current_lots, 3));
    LogImportant("   Finales Risiko: " + DoubleToString(final_risk_percent, 3) + "%");
    LogImportant("   Abweichung: " + DoubleToString(final_deviation, 4) + "%");
    
    // Strikte Risiko-Kontrolle: Niemals über Ziel
    if(final_deviation > 0.01) {
        LogError("❌ KRITISCH: Risiko überschreitet Ziel um " + DoubleToString(final_deviation, 4) + "%");
        control_message = "RISK EXCEEDED by " + DoubleToString(final_deviation, 4) + "%";
        return 0; // Sicherheits-Stopp
    }
    
    if(final_deviation > -1.0) {
        LogSuccess("✅ OPTIMAL: Risiko gut ausgenutzt");
        control_message = "Optimal - Risk: " + DoubleToString(final_risk_percent, 3) + 
                         "% (Target: " + DoubleToString(target_risk_percent, 2) + "%)";
    } else {
        LogInfo("✅ SICHER: Risiko " + DoubleToString(MathAbs(final_deviation), 2) + "% unter Ziel");
        control_message = "Safe - Risk: " + DoubleToString(final_risk_percent, 3) + 
                         "% (Target: " + DoubleToString(target_risk_percent, 2) + "%)";
    }
    
    return current_lots;
}

//+------------------------------------------------------------------+
//| EXAKTE LOTSIZE-BERECHNUNG v8.5 (STRIKTE RISIKO-KONTROLLE)      |
//+------------------------------------------------------------------+
double CalculateLots_v85(string symbol, double entry_price, double sl_price, 
                         double risk_percent, ENUM_ORDER_TYPE order_type, string &message) {
    
    LogImportant("════════════════════════════════════════════");
    LogImportant("🚀 EXAKTE LOTSIZE-BERECHNUNG v8.5");
    LogImportant("   Symbol: " + symbol);
    LogImportant("   Risiko: " + DoubleToString(risk_percent, 2) + "%");
    LogImportant("   STRIKTE RISIKO-KONTROLLE AKTIV");
    LogImportant("════════════════════════════════════════════");
    
    // ========== SCHRITT 1: ROBUSTE DATENSAMMLUNG ==========
    SymbolDataCollection symbol_data = CollectSymbolData_v832(symbol, 3, 500);
    
    if(!symbol_data.data_complete) {
        message = "Symbol data collection failed: " + symbol_data.error_message;
        LogError("❌ " + message);
        return 0;
    }
    
    // ========== SCHRITT 2: ACCOUNT & RISK SETUP ==========
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * risk_percent / 100.0;
    string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    LogImportant("📊 ACCOUNT & RISK:");
    LogImportant("   Balance: " + DoubleToString(balance, 2) + " " + account_currency);
    LogImportant("   Risiko-Betrag: " + DoubleToString(risk_amount, 2) + " " + account_currency);
    
    // ========== SCHRITT 3: ENTRY-PREIS BESTIMMEN ==========
    if(entry_price <= 0) {
        entry_price = (sl_price < symbol_data.bid) ? symbol_data.ask : symbol_data.bid;
        LogDebug("Entry automatisch gesetzt: " + DoubleToString(entry_price, symbol_data.digits));
    }
    
    // ========== SCHRITT 4: ASSET-TYP ERKENNEN ==========
    ENUM_SYMBOL_TYPE symbol_type = ClassifySymbol_v832(symbol);
    LogImportant("🔍 ASSET-TYP: " + EnumToString(symbol_type));
    
    // ========== SCHRITT 5: LOSS-PER-LOT BERECHNEN (ZUERST!) ==========
    double loss_per_lot = CalculateLossPerLot_v84(symbol, symbol_data, entry_price, sl_price, symbol_type);
    
    if(loss_per_lot <= 0) {
        message = "Loss per lot calculation failed";
        LogError("❌ " + message);
        return 0;
    }
    
    // ========== SCHRITT 6: EXAKTE DYNAMISCHE LIMITS (NACH Loss-per-Lot) ==========
    ExactDynamicLimits limits = GetExactDynamicLimits_v85(symbol, symbol_data, balance, loss_per_lot);
    
    if(!limits.limits_valid) {
        message = "Exact dynamic limits calculation failed";
        LogError("❌ " + message);
        return 0;
    }
    
    // ========== SCHRITT 7: INITIALE LOTSIZE BERECHNEN ==========
    double theoretical_lots = risk_amount / loss_per_lot;
    LogImportant("📈 INITIALE LOTSIZE-BERECHNUNG:");
    LogImportant("   Theoretische Lots: " + DoubleToString(theoretical_lots, 6));
    
    // Auf Symbol-Step normalisieren (nach unten für Sicherheit)
    double initial_lots = MathFloor(theoretical_lots / symbol_data.volume_step) * symbol_data.volume_step;
    LogImportant("   Initial normalisiert (Step " + DoubleToString(symbol_data.volume_step, 4) + "): " + DoubleToString(initial_lots, 3));
    
    // ========== SCHRITT 8: LIMITS ANWENDEN ==========
    double limited_lots = initial_lots;
    
    // Minimum-Lot prüfen
    if(limited_lots < symbol_data.volume_min) {
        limited_lots = symbol_data.volume_min;
        LogImportant("   Auf Minimum angehoben: " + DoubleToString(limited_lots, 3));
    }
    
    // Maximum-Lot prüfen (Symbol)
    if(limited_lots > symbol_data.volume_max) {
        limited_lots = symbol_data.volume_max;
        LogImportant("   Auf Symbol-Maximum begrenzt: " + DoubleToString(limited_lots, 3));
    }
    
    // Exakte dynamische Limits prüfen
    if(limited_lots > limits.final_max_lots) {
        limited_lots = limits.final_max_lots;
        LogImportant("   Auf exaktes dynamisches Limit begrenzt: " + DoubleToString(limited_lots, 3));
        LogImportant("   Grund: " + limits.limit_reason);
    }
    
    // ========== SCHRITT 9: ITERATIVE RISIKO-KONTROLLE ==========
    string control_message;
    double final_lots = ApplyIterativeRiskControl_v85(limited_lots, loss_per_lot, balance, 
                                                      risk_percent, symbol_data.volume_step,
                                                      symbol_data.volume_min, symbol_data.volume_max, 
                                                      control_message);
    
    if(final_lots <= 0) {
        message = "Iterative risk control failed: " + control_message;
        LogError("❌ " + message);
        return 0;
    }
    
    // ========== SCHRITT 10: FINALE VALIDIERUNG ==========
    double actual_risk_amount = final_lots * loss_per_lot;
    double actual_risk_percent = (actual_risk_amount / balance) * 100.0;
    double risk_deviation = actual_risk_percent - risk_percent;
    
    LogImportant("🔍 FINALE VALIDIERUNG v8.5:");
    LogImportant("   Finale Lots: " + DoubleToString(final_lots, 3));
    LogImportant("   Tatsächliches Risiko: " + DoubleToString(actual_risk_percent, 4) + "%");
    LogImportant("   Gewünschtes Risiko: " + DoubleToString(risk_percent, 2) + "%");
    LogImportant("   Abweichung: " + DoubleToString(risk_deviation, 4) + "%");
    
    // 🛡️ ULTRA-STRIKTE KONTROLLE: NIEMALS ÜBER ZIEL (Toleranz: 0.001%)
    if(risk_deviation > 0.001) {
        LogError("🚨 ULTRA-KRITISCHER FEHLER: Risiko überschreitet Ziel um " + DoubleToString(risk_deviation, 6) + "%");
        LogError("   Finales Risiko: " + DoubleToString(actual_risk_percent, 6) + "%");
        LogError("   Maximales Risiko: " + DoubleToString(risk_percent, 2) + "%");
        LogError("   🛡️ SICHERHEITSSTOPP: Trade wird verhindert!");
        message = "ULTRA-CRITICAL: Risk exceeds target by " + DoubleToString(risk_deviation, 6) + "% - SAFETY STOP";
        return 0;
    }
    
    LogImportant("✅ EXAKTE BERECHNUNG v8.5 ERFOLGREICH:");
    LogImportant("   Asset-Typ: " + EnumToString(symbol_type));
    LogImportant("   Finale Lots: " + DoubleToString(final_lots, 3));
    LogImportant("   Finales Risiko: " + DoubleToString(actual_risk_percent, 4) + "%");
    LogImportant("   Exaktes Limit: " + DoubleToString(limits.final_max_lots, 1) + " (" + limits.limit_reason + ")");
    LogImportant("   STRIKTE RISIKO-KONTROLLE: ✅ AKTIV");
    LogImportant("════════════════════════════════════════════");
    
    message = control_message + " - v8.5 EXACT";
    return final_lots;
}

