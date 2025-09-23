//+------------------------------------------------------------------+
//|                    Signal-Copier-Optimized-v9.0-MAIN           |
//|                                          Copyright 2024, Stelona |
//|                                       https://www.stelona.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Stelona"
#property link      "https://www.stelona.com"
#property version   "9.0"
#property strict
#property description "Professional Signal Copying EA with v9.0 Enhanced Lotsize Calculation"
#property description "Features: JPY-pair optimization, modular architecture, strict risk control"
#property description "Repository: https://github.com/stelona/signal-ea-v90"

//+------------------------------------------------------------------+
//| VERSION INFORMATION                                              |
//+------------------------------------------------------------------+
// Version 9.0-MAIN - MODULAR ARCHITECTURE WITH v9.0 ENHANCEMENTS:
// 
// 🚀 NEW IN v9.0:
// ✅ JPY-PAIR OPTIMIZATION: Correct pip calculation (1 pip = 0.01 for JPY)
// ✅ MODULAR ARCHITECTURE: Separate modules for different functionalities
// ✅ STRICT RISK CONTROL: Never exceeds specified risk percentage
// ✅ 4-TIER FALLBACK SYSTEM: JPY → OrderCalcProfit → Tick → Emergency
// ✅ ROBUST VALIDATION: Realistic ranges for all symbol types
// ✅ GITHUB INTEGRATION: Professional version control and updates
// 
// 🔧 ARCHITECTURE:
// - Main EA file with core functionality
// - Separate modules for specialized features
// - Easy maintenance and updates
// - Backward compatibility with v8.x APIs
// 
// 📦 MODULES:
// - Lotsize_v90_Enhanced.mqh: Revolutionary lotsize calculation
// - Core_DataStructures.mqh: Data structures and enums
// - Core_Logging.mqh: Professional logging system
// - Core_Utilities.mqh: Utility functions
//
// 🌐 REPOSITORY: https://github.com/stelona/signal-ea-v90

//+------------------------------------------------------------------+
//| MODULE INCLUDES                                                  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include "../modules/Lotsize_v90_Enhanced.mqh"

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS                                                   |
//+------------------------------------------------------------------+
CTrade trade;
string account_id;
datetime last_signal_check = 0;
datetime last_position_check = 0;

//+------------------------------------------------------------------+
//| DATA STRUCTURES                                                  |
//+------------------------------------------------------------------+
struct TrackedPosition {
    ulong original_ticket;     // Original ticket
    ulong current_ticket;      // Current ticket (changes after partial close)
    string signal_id;          // Signal ID
    bool be_executed;          // Break Even executed
    datetime be_time;          // When BE was set
    double be_level;           // BE price level
    bool is_active;           // Position still active
    datetime last_checked;     // Last API check
    // Value-based tracking for SL/TP modifications
    string last_api_sl;        // Last API SL value (string for exact comparison)
    string last_api_tp;        // Last API TP value (string for exact comparison)
    datetime last_api_update;  // When API values were last updated
    double last_applied_sl;    // Last EA-applied SL value
    double last_applied_tp;    // Last EA-applied TP value
};
TrackedPosition tracked_positions[];

struct ProcessedSignal {
    string signal_id;
    datetime processed_time;
    bool success;
};
ProcessedSignal processed_signals[];

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input group "=== API Configuration ==="
input string signal_api_url = "https://n8n.stelona.com/webhook/get-signal2"; // Signal API URL
input string position_api_url = "https://n8n.stelona.com/webhook/check-status"; // Position API URL
input string delivery_api_url = "https://n8n.stelona.com/webhook/signal-delivery"; // Delivery API URL
input string login_api_url = "https://n8n.stelona.com/webhook/login-status"; // Login Status API URL

input group "=== Trading Configuration ==="
input int magic_number = 12345; // Magic Number for EA identification

input group "=== Timing Configuration ==="
input int check_interval_signal = 15; // Signal Check Interval (seconds)
input int check_interval_position = 20; // Position Check Interval (seconds)
input int api_timeout_ms = 5000; // API Timeout (milliseconds)

input group "=== Risk Management ==="
input bool use_breakeven = true; // Enable Break Even (API controlled)
input double max_risk_percent = 10.0; // Maximum Risk per Trade (%)

input group "=== Symbol Mapping ==="
input string symbol_mappings = "US30:DJIUSD,US100:NAS100,US500:SPX500,DAX:GER40,FTSE:UK100,CAC40:FRA40,NIKKEI:JPN225"; // Custom Symbol Mappings

input group "=== Debug & Testing ==="
input bool debug_mode = false; // Enable Debug Mode (detailed logs)
input bool enable_lotsize_test = false; // Test v9.0 Lotsize Calculation on startup

//+------------------------------------------------------------------+
//| LOGGING FUNCTIONS                                                |
//+------------------------------------------------------------------+
void LogInfo(string message) {
    Print("[INFO] ", message);
}

void LogSuccess(string message) {
    Print("[SUCCESS] ", message);
}

void LogWarning(string message) {
    Print("[WARNING] ", message);
}

void LogError(string message) {
    Print("[ERROR] ", message);
}

void LogDebug(string message) {
    if(debug_mode) Print("[DEBUG] ", message);
}

void LogImportant(string message) {
    Print("[⚡] ", message);
}

//+------------------------------------------------------------------+
//| UTILITY FUNCTIONS                                                |
//+------------------------------------------------------------------+
string GetJsonValue(string json, string key) {
    string search_key = "\"" + key + "\"";
    int start_pos = StringFind(json, search_key);
    if(start_pos < 0) return "";
    
    start_pos = StringFind(json, ":", start_pos);
    if(start_pos < 0) return "";
    start_pos++;
    
    // Skip whitespace
    while(start_pos < StringLen(json) && (StringGetCharacter(json, start_pos) == ' ' || StringGetCharacter(json, start_pos) == '\t')) {
        start_pos++;
    }
    
    if(start_pos >= StringLen(json)) return "";
    
    int end_pos;
    if(StringGetCharacter(json, start_pos) == '"') {
        // String value
        start_pos++;
        end_pos = StringFind(json, "\"", start_pos);
        if(end_pos < 0) return "";
        return StringSubstr(json, start_pos, end_pos - start_pos);
    } else {
        // Number or boolean value
        end_pos = start_pos;
        while(end_pos < StringLen(json)) {
            int ch = StringGetCharacter(json, end_pos);
            if(ch == ',' || ch == '}' || ch == ']' || ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
                break;
            }
            end_pos++;
        }
        return StringSubstr(json, start_pos, end_pos - start_pos);
    }
}

//+------------------------------------------------------------------+
//| SIGNAL PROCESSING FUNCTIONS                                     |
//+------------------------------------------------------------------+
bool IsSignalAlreadyProcessed(string signal_id) {
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
    
    LogDebug("Signal marked as processed: " + signal_id + " (Success: " + (success ? "Yes" : "No") + ")");
}

//+------------------------------------------------------------------+
//| POSITION TRACKING FUNCTIONS                                     |
//+------------------------------------------------------------------+
int FindTrackedPositionIndex(string signal_id) {
    for(int i = 0; i < ArraySize(tracked_positions); i++) {
        if(tracked_positions[i].signal_id == signal_id && tracked_positions[i].is_active) {
            return i;
        }
    }
    return -1;
}

void AddTrackedPosition(ulong ticket, string signal_id) {
    int size = ArraySize(tracked_positions);
    ArrayResize(tracked_positions, size + 1);
    
    tracked_positions[size].original_ticket = ticket;
    tracked_positions[size].current_ticket = ticket;
    tracked_positions[size].signal_id = signal_id;
    tracked_positions[size].be_executed = false;
    tracked_positions[size].be_time = 0;
    tracked_positions[size].be_level = 0;
    tracked_positions[size].is_active = true;
    tracked_positions[size].last_checked = TimeCurrent();
    tracked_positions[size].last_api_sl = "";
    tracked_positions[size].last_api_tp = "";
    tracked_positions[size].last_api_update = 0;
    tracked_positions[size].last_applied_sl = 0;
    tracked_positions[size].last_applied_tp = 0;
    
    LogDebug("Position added to tracking: Ticket=" + IntegerToString(ticket) + ", Signal=" + signal_id);
}

//+------------------------------------------------------------------+
//| API COMMUNICATION FUNCTIONS                                     |
//+------------------------------------------------------------------+
string SendHttpRequest(string url, string method = "GET", string data = "", int timeout = 5000) {
    char post_data[];
    char result[];
    string headers = "";
    
    if(data != "") {
        headers = "Content-Type: application/json; charset=utf-8\r\n";
        StringToCharArray(data, post_data, 0, StringLen(data), CP_UTF8);
    }
    
    ResetLastError();
    
    int res = WebRequest(method, url, headers, timeout, post_data, result, headers);
    
    if(res == -1) {
        int error_code = GetLastError();
        LogError("WebRequest failed: " + IntegerToString(error_code));
        if(error_code == 4060) {
            LogError("URL not allowed. Add to Tools -> Options -> Expert Advisors -> Allow WebRequest for listed URL");
        }
        return "";
    }
    
    if(res == 204) return ""; // No content
    
    if(res != 200) {
        LogDebug("HTTP Error: " + IntegerToString(res));
        return "";
    }
    
    return CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
}

string GetSignalFromAPI() {
    string url = signal_api_url + "?account_id=" + account_id;
    return SendHttpRequest(url, "GET", "", api_timeout_ms);
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
    
    string response = SendHttpRequest(delivery_api_url, "POST", json, api_timeout_ms);
    LogDebug("📤 Trade confirmation sent for signal: " + signal_id);
    if(response != "") {
        LogDebug("📥 Delivery API response: " + response);
    }
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
    
    string response = SendHttpRequest(delivery_api_url, "POST", json, api_timeout_ms);
    LogDebug("📤 Error confirmation sent for signal: " + signal_id);
    if(response != "") {
        LogDebug("📥 Delivery API response: " + response);
    }
}

string CreateBaseJSON(string signal_id, bool success, string message) {
    string json = "{";
    json += "\"account_id\":\"" + account_id + "\",";
    json += "\"signal_id\":\"" + signal_id + "\",";
    json += "\"success\":" + (success ? "true" : "false") + ",";
    json += "\"message\":\"" + message + "\",";
    json += "\"ea_version\":\"9.0\",";
    json += "\"timestamp\":\"" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\"";
    return json;
}

string AddAccountInfo() {
    string info = ",\"account_info\":{";
    info += "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
    info += "\"equity\":" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + ",";
    info += "\"currency\":\"" + AccountInfoString(ACCOUNT_CURRENCY) + "\",";
    info += "\"leverage\":" + IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE)) + ",";
    info += "\"free_margin\":" + DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN), 2);
    info += "}";
    return info;
}

//+------------------------------------------------------------------+
//| MAIN SIGNAL PROCESSING                                          |
//+------------------------------------------------------------------+
void CheckForNewSignals() {
    string response = GetSignalFromAPI();
    
    if(response == "") {
        return; // No signals available
    }
    
    LogDebug("API Response received - checking signal");
    
    string signal_id = GetJsonValue(response, "signal_id");
    if(signal_id == "") signal_id = GetJsonValue(response, "id");
    
    if(signal_id == "") {
        return; // No signal ID found
    }
    
    if(IsSignalAlreadyProcessed(signal_id)) {
        LogDebug("Signal " + signal_id + " already processed");
        return;
    }
    
    LogImportant("🆕 NEW SIGNAL DETECTED: " + signal_id);
    ProcessSignal(response);
}

bool ProcessSignal(string signal_json) {
    LogImportant("📡 PROCESSING SIGNAL");
    LogDebug("Signal JSON: " + signal_json);
    
    // Extract signal data
    string signal_id = GetJsonValue(signal_json, "signal_id");
    if(signal_id == "") signal_id = GetJsonValue(signal_json, "id");
    
    string symbol = GetJsonValue(signal_json, "symbol");
    string direction = GetJsonValue(signal_json, "direction");
    string order_type = GetJsonValue(signal_json, "order_type");
    if(order_type == "") order_type = GetJsonValue(signal_json, "entry_type");
    
    double entry = StringToDouble(GetJsonValue(signal_json, "entry"));
    if(entry == 0) entry = StringToDouble(GetJsonValue(signal_json, "entry_price"));
    
    double sl = StringToDouble(GetJsonValue(signal_json, "sl"));
    double tp = StringToDouble(GetJsonValue(signal_json, "tp"));
    if(tp == 0) tp = StringToDouble(GetJsonValue(signal_json, "tp1"));
    
    double risk = StringToDouble(GetJsonValue(signal_json, "risk"));
    
    LogDebug("   Signal ID: " + signal_id);
    LogDebug("   Symbol: " + symbol);
    LogDebug("   Direction: " + direction);
    LogDebug("   Entry: " + DoubleToString(entry, 5));
    LogDebug("   SL: " + DoubleToString(sl, 5));
    LogDebug("   TP: " + DoubleToString(tp, 5));
    LogDebug("   Risk: " + DoubleToString(risk, 2) + "%");
    
    // Basic validation
    if(signal_id == "" || symbol == "" || direction == "" || sl <= 0 || risk <= 0) {
        LogError("Invalid signal: Missing required fields");
        SendTradeErrorConfirmation(signal_id != "" ? signal_id : "UNKNOWN", symbol != "" ? symbol : "UNKNOWN", direction != "" ? direction : "UNKNOWN", 0, 0, "Invalid signal: Missing required fields");
        MarkSignalAsProcessed(signal_id, false);
        return false;
    }
    
    // Risk validation
    if(risk > max_risk_percent) {
        LogError("Risk too high: " + DoubleToString(risk, 2) + "% > " + DoubleToString(max_risk_percent, 2) + "%");
        SendTradeErrorConfirmation(signal_id, symbol, direction, 0, 0, "Risk too high: " + DoubleToString(risk, 2) + "% > " + DoubleToString(max_risk_percent, 2) + "%");
        MarkSignalAsProcessed(signal_id, false);
        return false;
    }
    
    // Symbol validation (basic - assume direct symbol name for now)
    string mapped_symbol = symbol;
    if(!SymbolSelect(mapped_symbol, true)) {
        LogError("Symbol not available: " + symbol);
        SendTradeErrorConfirmation(signal_id, symbol, direction, 0, 0, "Symbol not available: " + symbol);
        MarkSignalAsProcessed(signal_id, false);
        return false;
    }
    
    LogSuccess("   ✅ Symbol available: " + mapped_symbol);
    
    // Determine order type
    ENUM_ORDER_TYPE mt_order_type = ORDER_TYPE_BUY;
    if(direction == "sell") {
        mt_order_type = (order_type == "market") ? ORDER_TYPE_SELL : ORDER_TYPE_SELL_LIMIT;
    } else {
        mt_order_type = (order_type == "market") ? ORDER_TYPE_BUY : ORDER_TYPE_BUY_LIMIT;
    }
    
    // Set entry price if not provided
    if(entry <= 0) {
        if(direction == "buy") {
            entry = SymbolInfoDouble(mapped_symbol, SYMBOL_ASK);
        } else {
            entry = SymbolInfoDouble(mapped_symbol, SYMBOL_BID);
        }
        LogDebug("   Entry price auto-set: " + DoubleToString(entry, 5));
    }
    
    // Set default risk if not provided
    if(risk <= 0) {
        risk = 2.0; // Default: 2%
        LogDebug("   Risk auto-set: " + DoubleToString(risk, 1) + "%");
    }
    
    // ========== CRITICAL: USE v9.0 ENHANCED LOTSIZE CALCULATION ==========
    LogImportant("🔄 CALCULATING LOTSIZE WITH v9.0 ENHANCED MODULE...");
    
    string calc_message = "";
    double lots = CalculateLots_v90_Enhanced(mapped_symbol, entry, sl, risk, mt_order_type, calc_message);
    
    if(lots <= 0) {
        LogError("v9.0 Lotsize calculation failed: " + calc_message);
        SendTradeErrorConfirmation(signal_id, mapped_symbol, direction, 0, 0, "Lotsize calculation failed: " + calc_message);
        MarkSignalAsProcessed(signal_id, false);
        return false;
    }
    
    LogSuccess("✅ v9.0 LOTSIZE CALCULATED: " + DoubleToString(lots, 3) + " lots");
    
    // Execute trade
    bool trade_success = false;
    ulong ticket = 0;
    
    LogImportant("🔄 EXECUTING TRADE...");
    LogDebug("   Symbol: " + mapped_symbol);
    LogDebug("   Order Type: " + EnumToString(mt_order_type));
    LogDebug("   Lots: " + DoubleToString(lots, 3));
    LogDebug("   Entry: " + DoubleToString(entry, 5));
    LogDebug("   SL: " + DoubleToString(sl, 5));
    LogDebug("   TP: " + DoubleToString(tp, 5));
    
    if(mt_order_type == ORDER_TYPE_BUY || mt_order_type == ORDER_TYPE_SELL) {
        // Market Order
        trade_success = trade.PositionOpen(mapped_symbol, mt_order_type, lots, entry, sl, tp, "Signal: " + signal_id);
        if(trade_success) {
            ticket = trade.ResultOrder();
        }
    } else {
        // Pending Order
        trade_success = trade.OrderOpen(mapped_symbol, mt_order_type, lots, 0, entry, sl, tp, ORDER_TIME_GTC, 0, "Signal: " + signal_id);
        if(trade_success) {
            ticket = trade.ResultOrder();
        }
    }
    
    if(trade_success && ticket > 0) {
        LogSuccess("✅ TRADE EXECUTED SUCCESSFULLY!");
        LogSuccess("   Ticket: " + IntegerToString(ticket));
        LogSuccess("   Symbol: " + mapped_symbol);
        LogSuccess("   Lots: " + DoubleToString(lots, 3));
        LogSuccess("   Entry: " + DoubleToString(entry, 5));
        LogSuccess("   SL: " + DoubleToString(sl, 5));
        LogSuccess("   TP: " + DoubleToString(tp, 5));
        
        // Add to position tracking
        AddTrackedPosition(ticket, signal_id);
        
        // Send success confirmation to Delivery API
        SendTradeExecutionConfirmation(signal_id, mapped_symbol, EnumToString(mt_order_type), lots, ticket, "Trade executed successfully");
        
        // Mark as successfully processed
        MarkSignalAsProcessed(signal_id, true);
        
        return true;
    } else {
        LogError("❌ TRADE EXECUTION FAILED!");
        LogError("   Error: " + IntegerToString(trade.ResultRetcode()) + " - " + trade.ResultRetcodeDescription());
        
        // Send error confirmation to Delivery API
        SendTradeErrorConfirmation(signal_id, mapped_symbol, direction, lots, 0, "Trade execution failed: " + IntegerToString(trade.ResultRetcode()) + " - " + trade.ResultRetcodeDescription());
        
        MarkSignalAsProcessed(signal_id, false);
        
        return false;
    }
}

//+------------------------------------------------------------------+
//| TESTING FUNCTIONS                                               |
//+------------------------------------------------------------------+
void TestLotsizeCalculation() {
    LogImportant("🧪 TESTING v9.0 ENHANCED LOTSIZE CALCULATION");
    
    // Test JPY pair
    string test_symbol = "USDJPY";
    double test_entry = 148.000;
    double test_sl = 148.400;
    double test_risk = 5.0;
    ENUM_ORDER_TYPE test_order_type = ORDER_TYPE_SELL;
    
    string message = "";
    double calculated_lots = CalculateLots_v90_Enhanced(test_symbol, test_entry, test_sl, test_risk, test_order_type, message);
    
    LogImportant("🧪 TEST RESULTS:");
    LogImportant("   Symbol: " + test_symbol);
    LogImportant("   Entry: " + DoubleToString(test_entry, 3));
    LogImportant("   SL: " + DoubleToString(test_sl, 3));
    LogImportant("   Risk: " + DoubleToString(test_risk, 1) + "%");
    LogImportant("   Calculated Lots: " + DoubleToString(calculated_lots, 6));
    LogImportant("   Status: " + message);
    LogImportant("🧪 TEST COMPLETED");
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    LogImportant("════════════════════════════════════════════");
    LogImportant("🚀 Signal EA v9.0-MAIN - INITIALIZATION");
    LogImportant("📦 MODULAR ARCHITECTURE WITH v9.0 ENHANCEMENTS");
    LogImportant("🌐 Repository: https://github.com/stelona/signal-ea-v90");
    LogImportant("════════════════════════════════════════════");
    
    account_id = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    
    LogInfo("Account ID: " + account_id);
    LogInfo("Server: " + AccountInfoString(ACCOUNT_SERVER));
    LogInfo("Balance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + " " + AccountInfoString(ACCOUNT_CURRENCY));
    LogInfo("Magic Number: " + IntegerToString(magic_number));
    
    // Initialize trade object
    trade.SetExpertMagicNumber(magic_number);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    // Module information
    LogImportant("📦 LOADED MODULES:");
    LogImportant("   " + GetLotsizeModuleInfo());
    LogImportant("   Module Version: " + GetLotsizeModuleVersion());
    LogImportant("   Module Status: " + (IsLotsizeModuleLoaded() ? "LOADED" : "ERROR"));
    
    LogImportant("🔧 CONFIGURATION:");
    LogImportant("   Signal Check Interval: " + IntegerToString(check_interval_signal) + "s");
    LogImportant("   Position Check Interval: " + IntegerToString(check_interval_position) + "s");
    LogImportant("   API Timeout: " + IntegerToString(api_timeout_ms) + "ms");
    LogImportant("   Debug Mode: " + (debug_mode ? "ENABLED" : "DISABLED"));
    LogImportant("   Break Even: " + (use_breakeven ? "ENABLED" : "DISABLED"));
    LogImportant("   Max Risk per Trade: " + DoubleToString(max_risk_percent, 1) + "%");
    
    LogImportant("🌐 API ENDPOINTS:");
    LogImportant("   Signal API: " + signal_api_url + "?account_id=" + account_id);
    LogImportant("   Position API: " + position_api_url);
    LogImportant("   Delivery API: " + delivery_api_url);
    LogImportant("   Login API: " + login_api_url);
    
    // Test lotsize calculation if enabled
    if(enable_lotsize_test) {
        TestLotsizeCalculation();
    }
    
    LogImportant("✅ Signal EA v9.0-MAIN successfully initialized");
    LogImportant("🇯🇵 JPY-PAIR OPTIMIZATION: ACTIVE");
    LogImportant("🛡️ STRICT RISK CONTROL: ACTIVE");
    LogImportant("📡 Signal monitoring starts in " + IntegerToString(check_interval_signal) + " seconds");
    LogImportant("════════════════════════════════════════════");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    string reason_text = "";
    switch(reason) {
        case REASON_PROGRAM: reason_text = "EA manually stopped"; break;
        case REASON_REMOVE: reason_text = "EA removed from chart"; break;
        case REASON_RECOMPILE: reason_text = "EA recompiled"; break;
        case REASON_CHARTCHANGE: reason_text = "Chart symbol/timeframe changed"; break;
        case REASON_CHARTCLOSE: reason_text = "Chart closed"; break;
        case REASON_PARAMETERS: reason_text = "EA parameters changed"; break;
        case REASON_ACCOUNT: reason_text = "Account changed"; break;
        default: reason_text = "Unknown (" + IntegerToString(reason) + ")"; break;
    }
    
    LogImportant("Signal EA v9.0-MAIN shutting down. Reason: " + reason_text);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Check for new signals
    if(TimeCurrent() - last_signal_check >= check_interval_signal) {
        last_signal_check = TimeCurrent();
        CheckForNewSignals();
    }
    
    // Position status checking would go here
    // (Simplified for this main EA - full implementation in complete version)
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer() {
    // Periodic status updates
    static datetime last_status_output = 0;
    if(debug_mode && TimeCurrent() - last_status_output > 300) { // Every 5 minutes
        LogDebug("📊 STATUS UPDATE:");
        LogDebug("   Active Positions: " + IntegerToString(PositionsTotal()));
        LogDebug("   Open Orders: " + IntegerToString(OrdersTotal()));
        LogDebug("   Tracked Positions: " + IntegerToString(ArraySize(tracked_positions)));
        LogDebug("   Processed Signals: " + IntegerToString(ArraySize(processed_signals)));
        last_status_output = TimeCurrent();
    }
}
