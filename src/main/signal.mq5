//|                                    SignalReceiverEA_Enhanced.mq5 |
//|                                 API Signal Receiver Expert v10|
//|                                                                  |
//| ÄNDERUNGEN in v10 (DUAL TAKE-PROFIT SUPPORT):               |
//| - Unterstützung für zwei Take-Profit-Level (TP1 & TP2)         |
//| - Automatische Teil-Schließung bei TP1 (50% oder volle Position)|
//| - Intelligente Volumen-Berechnung mit minLot/step Validierung  |
//| - OnTick-basierte TP-Überwachung für präzises Triggering       |
//| - State-Management für TP1-Completion-Tracking                  |
//| - Volle Rückwärts-Kompatibilität (Single-TP weiterhin möglich) |
//| - Erweiterte Statistiken für TP1/TP2-Closes                    |
//|                                                                  |
//| ÄNDERUNGEN in v9 (DIREKTE KORREKTE BERECHNUNG):             |
//| - CalculateLotSize verwendet jetzt direkt OrderCalcProfit      |
//| - KEINE Nachkorrektur mehr nötig - erste Berechnung ist korrekt|
//| - Iterative Berechnung bis ECHTER Verlust = Target-Risiko      |
//| - Optimierungsfunktion nur noch für Feinabstimmung             |
//| - Maximale Präzision von Anfang an                             |
//| - Schnellere Ausführung durch weniger Iterationen              |
//|                                                                  |
//| OPTIMIERUNGEN in v11.1:                                         |
//| - Verbesserter JSON Parser (Enhanced String Parsing)           |
//| - HTTP Retry Logic mit exponentiellem Backoff (3x Versuche)    |
//| - Input Validation in OnInit() für robustere Konfiguration     |
#property copyright "Copyright 2025"
#property link      ""
#property version   "11.1"
#property strict

// Input parameters
input string   InpAPIBaseUrl = "https://n8n.stelona.com/webhook/get-signal";   // API Base URL für Signale
input string   InpAPIStatusUrl = "https://n8n.stelona.com/webhook/check-status"; // API URL für Status-Check
input string   InpAPILoginUrl = "https://n8n.stelona.com/webhook/login-status";  // API URL für Login-Status
input string   InpAPIDeliveryUrl = "https://n8n.stelona.com/webhook/signal-delivery"; // API URL für Signal Delivery
input int      InpCheckInterval = 12;                                          // Signal-Check Intervall (Sekunden)
input int      InpStatusInterval = 15;                                         // Status-Check Intervall (Sekunden)
input int      InpMagicNumber = 123456;                                        // Magic number
input bool     InpDebugMode = false;                                           // Debug mode (Standard: AUS)
input int      InpLoginRetryDelay = 2;                                         // Login Retry-Verzögerung (Sekunden)

// Risk Optimization Parameters (DIRECT v9)
input group "=== RISK OPTIMIZATION (v9 DIRECT - No Correction Needed) ==="
input bool     InpEnableRiskOptimization = true;                              // Risiko-Optimierung aktivieren
input int      InpMaxRiskIterations = 200;                                    // Max Iterationen für Risiko-Optimierung (erhöht für ultra-präzise Optimierung)
input double   InpRiskTolerance = 0.005;                                      // Risiko-Toleranz in % (0.5% Abweichung nach UNTEN OK, nach OBEN NIEMALS!)
input bool     InpAggressiveOptimization = true;                              // Aggressive Optimierung (nutzt Risiko maximal aus)
input bool     InpUseOrderCalcProfit = true;                                  // OrderCalcProfit für präzisere Berechnung verwenden

// Signal Delivery API Parameters
input bool     InpEnableDeliveryAPI = true;                                   // Signal Delivery API aktivieren
input bool     InpDeliveryDebugMode = false;                                  // Delivery API Debug Modus (Standard: AUS)
input int      InpDeliveryRetryAttempts = 3;                                  // Max Retry-Versuche für Delivery API
input int      InpDeliveryTimeout = 10000;                                    // Timeout für Delivery API (ms)
input bool     InpLogAllDeliveryRequests = false;                             // Alle Delivery Anfragen loggen (Standard: AUS)

// Symbol Mapping Parameters - ENHANCED v5.50: Symbol-Alias-Gruppen
input group "=== FOREX PAIRS ===" 
input string   InpMapping01 = "EURUSD";                                      // Mapping 1: EUR/USD
input string   InpMapping02 = "GBPUSD";                                      // Mapping 2: GBP/USD
input string   InpMapping03 = "USDJPY";                                      // Mapping 3: USD/JPY
input string   InpMapping04 = "AUDUSD";                                      // Mapping 4: AUD/USD
input string   InpMapping05 = "USDCHF";                                      // Mapping 5: USD/CHF

input group "=== GOLD & SILVER ===" 
input string   InpMapping06 = "XAUUSD";                             // Mapping 6: Gold
input string   InpMapping07 = "XAGUSD";                           // Mapping 7: Silver

input group "=== US INDICES ===" 
input string   InpMapping08 = "US30|DJ30|DJI30|DJIA|DJIUSD|DOWJONES";   // Mapping 8: Dow Jones
input string   InpMapping09 = "US100|NAS100|NASDAQ|NDX|NQ|USTEC";           // Mapping 9: Nasdaq
input string   InpMapping10 = "US500|SPX|SP500|SPX500|ES";                  // Mapping 10: S&P 500
input string   InpMapping11 = "US2000|RUSSELL|RUSSELL2000|RTY";             // Mapping 11: Russell 2000

input group "=== EUROPEAN INDICES ===" 
input string   InpMapping12 = "DAX|DAX30|DAX40|DE30|DE40|GER30|GER40";      // Mapping 12: DAX
input string   InpMapping13 = "FTSE|UK100|FTSE100|UKX";                     // Mapping 13: FTSE
input string   InpMapping14 = "CAC|CAC40|FRA40|FRANCE40";                   // Mapping 14: CAC 40
input string   InpMapping15 = "STOXX|STOXX50|EUSTX50|EURO50|EU50";         // Mapping 15: Euro Stoxx 50

input group "=== ASIAN INDICES ===" 
input string   InpMapping16 = "NIKKEI|JP225|JPN225|NI225";                  // Mapping 16: Nikkei
input string   InpMapping17 = "HANGSENG|HK50|HSI|HONGKONG50";               // Mapping 17: Hang Seng
input string   InpMapping18 = "CHINA50|CHN50|CN50";                         // Mapping 18: China 50
input string   InpMapping19 = "ASX|ASX200|AUS200|AU200";                    // Mapping 19: ASX 200

input group "=== COMMODITIES ===" 
input string   InpMapping20 = "OIL|USOIL|WTI|CRUDE|CL";                     // Mapping 20: US Oil
input string   InpMapping21 = "BRENT|UKOIL|BRENTOIL|BRN";                   // Mapping 21: Brent Oil
input string   InpMapping22 = "NATGAS|GAS|NG|NATURALGAS";                   // Mapping 22: Natural Gas
input string   InpMapping23 = "COPPER|HG";                                  // Mapping 23: Copper

input group "=== CRYPTOCURRENCIES ===" 
input string   InpMapping24 = "BITCOIN|BTCUSD|BTCUSDT";          // Mapping 24: Bitcoin
input string   InpMapping25 = "ETHEREUM|ETHUSD|ETHUSDT";                // Mapping 25: Ethereum
input string   InpMapping26 = "RIPPLE|XRPUSD|XRPUSDT";                  // Mapping 26: XRP
input string   InpMapping27 = "LITECOIN|LTCUSD|LTCUSDT";                // Mapping 27: Litecoin
input string   InpMapping28 = "DOGECOIN|DOGEUSD|DOGEUSDT";             // Mapping 28: Dogecoin
input string   InpMapping29 = "SOLANA|SOLUSD|SOLUSDT";                  // Mapping 29: Solana
input string   InpMapping30 = "CARDANO|ADAUSD|ADAUSDT";                 // Mapping 30: Cardano

// Fixed constants
const int MAX_LOGIN_ATTEMPTS = 1;  // Fixed max login attempts

// Global variables
datetime g_lastCheckTime = 0;
datetime g_lastStatusCheckTime = 0;
string g_executedSignals[];  // Array to store executed signal IDs
string g_symbolSuffix = "";  // Auto-detected suffix for symbols

// Track EA deletions (v5.49 - Fix für false positive ea_deleted)
ulong g_eaDeletedTickets[];  // Tickets die der EA gerade löscht
datetime g_lastEaDelete = 0;  // Zeitpunkt der letzten EA-Löschung

// Delivery API Statistics
struct DeliveryStats
{
    int totalRequests;
    int successfulRequests;
    int failedRequests;
    int retryAttempts;
    datetime lastRequest;
    string lastError;
    int pendingOrderNotifications;
    int marketOrderNotifications;
    int closeNotifications;
    int updateNotifications;
};

DeliveryStats g_deliveryStats;

// Multi-Signal Statistics
struct MultiSignalStats
{
    int totalSignalsReceived;
    int totalSignalsProcessed;
    int totalSignalsSkipped;
    int batchCount;
    datetime lastBatchTime;
    int newSignalsThisSession;
    int slTpUpdatesThisSession;
};

// Close Reason Statistics
struct CloseStats
{
    int slHit;
    int tpHit;
    int breakEvenHit;
    int manuallyClosed;
    int eaClosed;
    int marginCall;
    int pendingTriggered;
    int pendingManuallyDeleted;
    int pendingExpired;
    int marketClosed;
    int other;
    // v10: Dual TP statistics
    int tp1Hit;
    int tp2Hit;
    int tp1FullClose;
};

// Risk Optimization Statistics (OPTIMIZED v9)
struct RiskOptimizationStats
{
    int totalOptimizations;
    int lotsIncreased;
    int lotsDecreased;
    int lotsUnchanged;
    double totalRiskGained;
    double avgIterations;
    double maxDeviation;
    double avgDeviation;
};

MultiSignalStats g_multiSignalStats;
CloseStats g_closeStats;
RiskOptimizationStats g_riskOptStats;

// Structure for tracking positions
struct PositionData
{
    string signal_id;
    ulong ticket;
    double original_sl;
    double original_tp;
    double break_even_price;
    bool break_even_done;
    double last_api_sl;
    double last_api_tp;
    double original_risk;
    double last_blocked_sl;
    datetime last_update;
    bool is_pending;
    string symbol;
    double entry_price;
    double be_trigger_price;
    bool be_trigger_active;
    // v10: Dual TP support
    double tp1;
    double tp2;
    bool tp1_done;
    bool has_dual_tp;
    ENUM_ORDER_TYPE order_type;
};

PositionData g_trackedPositions[];

//| Register EA deletion of ticket (v5.49)                         |
void RegisterEADeletion(ulong ticket)
{
    int size = ArraySize(g_eaDeletedTickets);
    ArrayResize(g_eaDeletedTickets, size + 1);
    g_eaDeletedTickets[size] = ticket;
    g_lastEaDelete = TimeCurrent();
    
    if(InpDeliveryDebugMode)
        Print("DEBUG: EA-Deletion registered for ticket ", ticket);
}

//| Check if ticket was deleted by EA recently (v5.49)             |
bool WasDeletedByEA(ulong ticket)
{
    if(TimeCurrent() - g_lastEaDelete > 5)
    {
        ArrayResize(g_eaDeletedTickets, 0);
        return false;
    }
    
    for(int i = 0; i < ArraySize(g_eaDeletedTickets); i++)
    {
        if(g_eaDeletedTickets[i] == ticket)
        {
            if(InpDeliveryDebugMode)
                Print("DEBUG: Ticket ", ticket, " was deleted by EA (found in tracking list)");
            return true;
        }
    }
    
    return false;
}

//| Get correct filling mode for symbol                            |
ENUM_ORDER_TYPE_FILLING GetSymbolFillingMode(string symbol)
{
    int filling = (int)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
    
    if((filling & 1) == 1)
        return ORDER_FILLING_FOK;
    
    if((filling & 2) == 2)
        return ORDER_FILLING_IOC;
    
    return ORDER_FILLING_RETURN;
}

//| Convert order type to n8n format                               |
string ConvertOrderTypeToN8nFormat(string orderType)
{
    string type = orderType;
    StringReplace(type, "ORDER_TYPE_", "");
    type = ToLowerCase(type);
    
    if(StringFind(type, "buy_limit") >= 0)
        return "limit buy";
    else if(StringFind(type, "sell_limit") >= 0)
        return "limit sell";
    else if(StringFind(type, "buy_stop") >= 0)
        return "stop buy";
    else if(StringFind(type, "sell_stop") >= 0)
        return "stop sell";
    else if(type == "buy")
        return "buy";
    else if(type == "sell")
        return "sell";
    
    return type;
}

//| Custom lowercase conversion                                     |
string ToLowerCase(string text)
{
    string result = "";
    for(int i = 0; i < StringLen(text); i++)
    {
        ushort ch = StringGetCharacter(text, i);
        if(ch >= 'A' && ch <= 'Z')
            ch = ch + 32;
        result += ShortToString(ch);
    }
    return result;
}

//| JSON Escape Function                                           |
string EscapeJsonString(string text)
{
    string result = "";
    
    for(int i = 0; i < StringLen(text); i++)
    {
        ushort ch = StringGetCharacter(text, i);
        
        if(ch == '\\')
            result += "\\\\";
        else if(ch == '"')
            result += "\\\"";
        else if(ch == 10)
            result += "\\n";
        else if(ch == 13)
            result += "\\r";
        else if(ch == 9)
            result += "\\t";
        else if(ch == 8)
            result += "\\b";
        else if(ch == 12)
            result += "\\f";
        else if(ch < 32)
        {
            result += StringFormat("\\u%04x", ch);
        }
        else
        {
            result += ShortToString(ch);
        }
    }
    
    return result;
}

//| Format MySQL DATETIME Timestamp                                |
string GetMySQLTimestamp()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    return StringFormat("%04d-%02d-%02d %02d:%02d:%02d",
                       dt.year, dt.mon, dt.day,
                       dt.hour, dt.min, dt.sec);
}

//| Check if market is open for symbol                              |
bool IsMarketOpen(string symbol)
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE))
        return false;
    
    datetime from, to;
    if(!SymbolInfoSessionTrade(symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, 0, from, to))
        return false;
    
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    if(bid == 0 || ask == 0)
        return false;
    
    return true;
}

//| Send signal delivery status to n8n                             |
bool SendSignalDeliveryStatus(string signalId, string status, bool success, 
                             ulong ticket = 0, string message = "", 
                             string orderType = "", double lots = 0,
                             double requestedRiskPercent = 0, double requestedRiskAmount = 0,
                             double calculatedRiskPercent = 0, double calculatedRiskAmount = 0,
                             double profit = 0, string symbol = "")
{
    if(!InpEnableDeliveryAPI)
        return true;
    
    g_deliveryStats.totalRequests++;
    g_deliveryStats.lastRequest = TimeCurrent();
    
    if(status == "pending_created" || status == "pending_recreated")
        g_deliveryStats.pendingOrderNotifications++;
    else if(status == "executed")
        g_deliveryStats.marketOrderNotifications++;
    else if(StringFind(status, "close") >= 0 || StringFind(status, "_hit") >= 0 || 
            StringFind(status, "cancelled") >= 0 || StringFind(status, "deleted") >= 0 ||
            StringFind(status, "triggered") >= 0 || StringFind(status, "expired") >= 0 ||
            status == "position_closed")
        g_deliveryStats.closeNotifications++;
    else if(StringFind(status, "update") >= 0 || status == "breakeven_set")
        g_deliveryStats.updateNotifications++;
    
    if(InpLogAllDeliveryRequests || InpDeliveryDebugMode)
    {
        Print("========================================");
        Print("DELIVERY API REQUEST (v9)");
        Print("========================================");
        Print("  Signal ID: ", signalId);
        Print("  Status: ", status);
        Print("  Success: ", success);
        Print("  Ticket: ", ticket);
        Print("  Symbol: ", symbol);
        Print("  Order Type: ", orderType);
        Print("  Lots: ", DoubleToString(lots, 3));
        if(profit != 0)
            Print("  Profit: ", DoubleToString(profit, 2));
        Print("  Message: ", message);
        Print("========================================");
    }
    
    long accountId = AccountInfoInteger(ACCOUNT_LOGIN);
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
    
    string jsonBody = "{";
    
    jsonBody += "\"account_id\":\"" + IntegerToString(accountId) + "\",";
    jsonBody += "\"signal_id\":\"" + EscapeJsonString(signalId) + "\",";
    jsonBody += "\"success\":" + (success ? "true" : "false") + ",";
    jsonBody += "\"status\":\"" + EscapeJsonString(status) + "\",";
    jsonBody += "\"timestamp\":\"" + GetMySQLTimestamp() + "\",";
    jsonBody += "\"ea_version\":\"11\"";
    
    jsonBody += ",\"ticket\":\"" + (ticket > 0 ? IntegerToString(ticket) : "") + "\"";
    jsonBody += ",\"symbol\":\"" + EscapeJsonString(symbol) + "\"";
    jsonBody += ",\"message\":\"" + EscapeJsonString(message) + "\"";
    jsonBody += ",\"order_type\":\"" + EscapeJsonString(orderType) + "\"";
    jsonBody += ",\"volume\":" + DoubleToString(lots, 2);
    jsonBody += ",\"profit\":" + DoubleToString(profit, 2);
    
    jsonBody += ",\"risk\":{";
    jsonBody += "\"requested_percent\":" + DoubleToString(requestedRiskPercent, 2) + ",";
    jsonBody += "\"requested_amount\":" + DoubleToString(requestedRiskAmount, 2) + ",";
    jsonBody += "\"calculated_percent\":" + DoubleToString(calculatedRiskPercent, 2) + ",";
    jsonBody += "\"calculated_amount\":" + DoubleToString(calculatedRiskAmount, 2);
    jsonBody += "}";
    
    jsonBody += ",\"account\":{";
    jsonBody += "\"balance\":" + DoubleToString(balance, 2) + ",";
    jsonBody += "\"equity\":" + DoubleToString(equity, 2) + ",";
    jsonBody += "\"margin\":" + DoubleToString(margin, 2) + ",";
    jsonBody += "\"free_margin\":" + DoubleToString(freeMargin, 2) + ",";
    jsonBody += "\"currency\":\"" + EscapeJsonString(currency) + "\",";
    jsonBody += "\"leverage\":" + IntegerToString(leverage);
    jsonBody += "}";
    
    jsonBody += "}";
    
    bool requestSuccess = false;
    string lastError = "";
    
    for(int attempt = 1; attempt <= InpDeliveryRetryAttempts; attempt++)
    {
        string headers = "Content-Type: application/json\r\n";
        headers += "Accept: application/json\r\n";
        headers += "User-Agent: MetaTrader5/9 (SignalReceiver EA)\r\n";
        headers += "Content-Length: " + IntegerToString(StringLen(jsonBody)) + "\r\n";
        
        char post[];
        char result[];
        string resultHeaders;
        
        int jsonLen = StringLen(jsonBody);
        StringToCharArray(jsonBody, post, 0, jsonLen, CP_UTF8);
        
        int arraySize = ArraySize(post);
        if(arraySize > jsonLen && post[arraySize - 1] == 0)
        {
            ArrayResize(post, arraySize - 1);
        }
        
        if(InpDeliveryDebugMode)
        {
            Print("DEBUG - Sending JSON Body:");
            Print(jsonBody);
            Print("DEBUG - JSON String Length: ", jsonLen, " chars");
            Print("DEBUG - Array Size: ", ArraySize(post), " bytes");
        }
        
        ResetLastError();
        int res = WebRequest("POST", InpAPIDeliveryUrl, headers, InpDeliveryTimeout, post, result, resultHeaders);
        
        if(res == -1)
        {
            int error = GetLastError();
            lastError = "WebRequest failed: " + IntegerToString(error);
            
            Print("❌ DELIVERY API ERROR (Attempt ", attempt, "/", InpDeliveryRetryAttempts, "): ", lastError);
            
            if(error == 4014)
                Print("   → WebRequest nicht erlaubt - Aktiviere DLL-Imports in MT5!");
            else if(error == 5203)
                Print("   → URL nicht zugelassen - Füge 'https://n8n.stelona.com' zu MT5 Options hinzu!");
            
            g_deliveryStats.retryAttempts++;
            
            if(attempt < InpDeliveryRetryAttempts)
                Sleep(2000);
        }
        else
        {
            if(InpDeliveryDebugMode)
            {
                Print("DEBUG - Response Headers:");
                Print(resultHeaders);
                Print("DEBUG - Response Body:");
                string responseBody = CharArrayToString(result, 0, ArraySize(result), CP_UTF8);
                Print(responseBody);
            }
            
            if(StringFind(resultHeaders, "200") >= 0 || 
               StringFind(resultHeaders, "201") >= 0 || 
               StringFind(resultHeaders, "202") >= 0)
            {
                requestSuccess = true;
                g_deliveryStats.successfulRequests++;
                
                if(InpDeliveryDebugMode)
                    Print("✅ Delivery API SUCCESS");
                
                break;
            }
            else
            {
                string statusCode = "Unknown";
                int httpPos = StringFind(resultHeaders, "HTTP/");
                if(httpPos >= 0)
                {
                    int statusStart = httpPos + 9;
                    int statusEnd = StringFind(resultHeaders, " ", statusStart);
                    if(statusEnd > statusStart)
                        statusCode = StringSubstr(resultHeaders, statusStart, statusEnd - statusStart);
                }
                
                lastError = "HTTP " + statusCode;
                Print("⚠ DELIVERY API HTTP ERROR: ", lastError);
                Print("   Response Headers: ", resultHeaders);
                
                if(StringFind(statusCode, "4") == 0)
                    break;
                
                if(attempt < InpDeliveryRetryAttempts)
                {
                    g_deliveryStats.retryAttempts++;
                    Sleep(2000);
                }
            }
        }
    }
    
    if(!requestSuccess)
    {
        g_deliveryStats.failedRequests++;
        g_deliveryStats.lastError = lastError;
        
        if(InpDeliveryDebugMode)
            Print("❌ Delivery API FAILED: ", signalId, " | ", lastError);
        
        return false;
    }
    
    return true;
}

//| Send login status to n8n                                       |
bool SendLoginStatus()
{
    long accountLogin = AccountInfoInteger(ACCOUNT_LOGIN);
    string accountCompany = AccountInfoString(ACCOUNT_COMPANY);
    string accountServer = AccountInfoString(ACCOUNT_SERVER);
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
    
    string jsonBody = "{";
    jsonBody += "\"account_id\":\"" + IntegerToString(accountLogin) + "\",";
    jsonBody += "\"login_success\":true,";
    jsonBody += "\"timestamp\":\"" + GetMySQLTimestamp() + "\",";
    jsonBody += "\"ea_version\":\"11\",";
    jsonBody += "\"delivery_api_enabled\":" + (InpEnableDeliveryAPI ? "true" : "false") + ",";
    
    jsonBody += "\"account\":{";
    jsonBody += "\"company\":\"" + EscapeJsonString(accountCompany) + "\",";
    jsonBody += "\"server\":\"" + EscapeJsonString(accountServer) + "\",";
    jsonBody += "\"balance\":" + DoubleToString(balance, 2) + ",";
    jsonBody += "\"equity\":" + DoubleToString(equity, 2) + ",";
    jsonBody += "\"currency\":\"" + EscapeJsonString(currency) + "\",";
    jsonBody += "\"leverage\":" + IntegerToString(leverage);
    jsonBody += "}";
    
    jsonBody += "}";
    
    // Retry logic: Try up to 3 times
    int maxAttempts = 3;
    bool success = false;
    string lastError = "";
    
    for(int attempt = 1; attempt <= maxAttempts; attempt++)
    {
        string headers = "Content-Type: application/json\r\n";
        headers += "Accept: application/json\r\n";
        headers += "User-Agent: MetaTrader5/9 (SignalReceiver EA)\r\n";
        headers += "Content-Length: " + IntegerToString(StringLen(jsonBody)) + "\r\n";
        
        char post[];
        char result[];
        string resultHeaders;
        
        int jsonLen = StringLen(jsonBody);
        StringToCharArray(jsonBody, post, 0, jsonLen, CP_UTF8);
        
        int arraySize = ArraySize(post);
        if(arraySize > jsonLen && post[arraySize - 1] == 0)
        {
            ArrayResize(post, arraySize - 1);
        }
        
        if(InpDebugMode || attempt > 1)
        {
            Print("========================================");
            Print("LOGIN API REQUEST (Attempt ", attempt, "/", maxAttempts, ")");
            Print("========================================");
            Print("  Account ID: ", accountLogin);
            Print("  URL: ", InpAPILoginUrl);
            if(InpDebugMode)
            {
                Print("  JSON Body:");
                Print("  ", jsonBody);
            }
            Print("========================================");
        }
        
        ResetLastError();
        int res = WebRequest("POST", InpAPILoginUrl, headers, 10000, post, result, resultHeaders);
        
        if(res == -1)
        {
            int error = GetLastError();
            lastError = "WebRequest failed: " + IntegerToString(error);
            
            Print("❌ LOGIN API ERROR (Attempt ", attempt, "/", maxAttempts, "): ", lastError);
            
            if(error == 4014)
            {
                Print("   → WebRequest nicht erlaubt!");
                Print("   → Lösung: Tools → Options → Expert Advisors → 'Allow DLL imports' aktivieren");
            }
            else if(error == 5203)
            {
                Print("   → URL nicht zugelassen!");
                Print("   → Lösung: Tools → Options → Expert Advisors → 'Allow WebRequest for listed URL'");
                Print("   → URL hinzufügen: https://n8n.stelona.com");
            }
            else
            {
                Print("   → Netzwerk-Fehler oder Server nicht erreichbar");
            }
            
            if(attempt < maxAttempts)
            {
                Print("   → Retry in 2 Sekunden...");
                Sleep(2000);
            }
            continue;
        }
        
        if(InpDebugMode || attempt > 1)
        {
            Print("========================================");
            Print("LOGIN API RESPONSE:");
            Print("========================================");
            Print("  HTTP Code: ", res);
            Print("  Headers: ", resultHeaders);
            if(ArraySize(result) > 0)
            {
                string responseStr = CharArrayToString(result);
                Print("  Response: ", responseStr);
            }
            Print("========================================");
        }
        
        if(StringFind(resultHeaders, "200") >= 0 || StringFind(resultHeaders, "201") >= 0)
        {
            success = true;
            if(attempt > 1)
                Print("✅ Login-Status erfolgreich gesendet (nach ", attempt, " Versuchen)");
            break;
        }
        else
        {
            lastError = "HTTP Error: " + IntegerToString(res);
            Print("❌ LOGIN API HTTP ERROR (Attempt ", attempt, "/", maxAttempts, "): ", lastError);
            
            if(attempt < maxAttempts)
            {
                Print("   → Retry in 2 Sekunden...");
                Sleep(2000);
            }
        }
    }
    
    if(!success)
    {
        Print("========================================");
        Print("❌ LOGIN API FAILED AFTER ", maxAttempts, " ATTEMPTS");
        Print("========================================");
        Print("  Last Error: ", lastError);
        Print("  Account ID: ", accountLogin);
        Print("  URL: ", InpAPILoginUrl);
        Print("========================================");
        Print("TROUBLESHOOTING:");
        Print("  1. Prüfe MT5 Einstellungen:");
        Print("     Tools → Options → Expert Advisors");
        Print("     ✓ Allow DLL imports");
        Print("     ✓ Allow WebRequest for listed URL");
        Print("  2. Füge URL hinzu:");
        Print("     https://n8n.stelona.com");
        Print("  3. Prüfe Internetverbindung");
        Print("  4. Prüfe ob n8n Server erreichbar ist");
        Print("========================================");
    }
    
    return success;
}

//| Send logout status to n8n                                      |
void SendLogoutStatus(int deInitReason)
{
    string reasonStr = "UNKNOWN";
    switch(deInitReason)
    {
        case REASON_PROGRAM: reasonStr = "EA_STOPPED"; break;
        case REASON_REMOVE: reasonStr = "EA_REMOVED"; break;
        case REASON_RECOMPILE: reasonStr = "EA_RECOMPILED"; break;
        case REASON_CHARTCHANGE: reasonStr = "SYMBOL_CHANGED"; break;
        case REASON_CHARTCLOSE: reasonStr = "CHART_CLOSED"; break;
        case REASON_PARAMETERS: reasonStr = "PARAMETERS_CHANGED"; break;
        case REASON_ACCOUNT: reasonStr = "ACCOUNT_CHANGED"; break;
        case REASON_TEMPLATE: reasonStr = "TEMPLATE_APPLIED"; break;
        case REASON_INITFAILED: reasonStr = "INIT_FAILED"; break;
        case REASON_CLOSE: reasonStr = "TERMINAL_CLOSED"; break;
    }
    
    int openPositions = 0;
    int pendingOrders = 0;
    double floatingProfit = 0;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetTicket(i) > 0)
        {
            if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
            {
                openPositions++;
                floatingProfit += PositionGetDouble(POSITION_PROFIT);
            }
        }
    }
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderGetTicket(i) > 0)
        {
            if(OrderGetInteger(ORDER_MAGIC) == InpMagicNumber)
            {
                pendingOrders++;
            }
        }
    }
    
    string jsonBody = "{";
    jsonBody += "\"account_id\":\"" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "\",";
    jsonBody += "\"login_success\":false,";
    jsonBody += "\"timestamp\":\"" + GetMySQLTimestamp() + "\",";
    jsonBody += "\"logout_reason\":\"" + reasonStr + "\",";
    
    jsonBody += "\"final_state\":{";
    jsonBody += "\"open_positions\":" + IntegerToString(openPositions) + ",";
    jsonBody += "\"pending_orders\":" + IntegerToString(pendingOrders) + ",";
    jsonBody += "\"floating_profit\":" + DoubleToString(floatingProfit, 2) + ",";
    jsonBody += "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
    jsonBody += "\"equity\":" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2);
    jsonBody += "},";
    
    jsonBody += "\"session_stats\":{";
    jsonBody += "\"signals_processed\":" + IntegerToString(g_multiSignalStats.totalSignalsProcessed) + ",";
    jsonBody += "\"delivery_api_enabled\":" + (InpEnableDeliveryAPI ? "true" : "false") + ",";
    jsonBody += "\"total_requests\":" + IntegerToString(g_deliveryStats.totalRequests) + ",";
    jsonBody += "\"successful_requests\":" + IntegerToString(g_deliveryStats.successfulRequests) + ",";
    jsonBody += "\"failed_requests\":" + IntegerToString(g_deliveryStats.failedRequests) + ",";
    jsonBody += "\"retry_attempts\":" + IntegerToString(g_deliveryStats.retryAttempts);
    jsonBody += "}";
    
    jsonBody += "}";
    
    string headers = "Content-Type: application/json\r\n";
    headers += "Accept: application/json\r\n";
    headers += "User-Agent: MetaTrader5/9 (SignalReceiver EA)\r\n";
    headers += "Content-Length: " + IntegerToString(StringLen(jsonBody)) + "\r\n";
    
    char post[];
    char result[];
    string resultHeaders;
    
    int jsonLen = StringLen(jsonBody);
    StringToCharArray(jsonBody, post, 0, jsonLen, CP_UTF8);
    
    int arraySize = ArraySize(post);
    if(arraySize > jsonLen && post[arraySize - 1] == 0)
    {
        ArrayResize(post, arraySize - 1);
    }

    // v11.1: Use retry logic for robustness
    int res = WebRequestWithRetry("POST", InpAPILoginUrl, headers, 5000, post, result, resultHeaders, 3);

    if(res > 0)
    {
        SendSignalDeliveryStatus("ea_shutdown", "shutdown", true, 0,
                               StringFormat("EA shutdown: %s", reasonStr));
    }
}

//| Try to send login status                                       |
void TrySendLoginStatus()
{
    Print("========================================");
    Print("📡 Sende Login-Status an n8n...");
    Print("========================================");
    
    if(SendLoginStatus())
    {
        Print("✅ Login-Status erfolgreich an n8n gesendet!");
    }
    else
    {
        Print("⚠️ Login-Status konnte nicht gesendet werden");
        Print("   EA läuft trotzdem normal weiter");
        Print("   Login-Status wird beim nächsten Signal-Empfang erneut versucht");
    }
    
    Print("========================================");
}

//| Expert initialization function                                   |
int OnInit()
{
    // ═══════════════════════════════════════════════════════════════════
    // v11.1: INPUT VALIDATION
    // ═══════════════════════════════════════════════════════════════════

    // Validate API URLs
    if(InpAPIBaseUrl == "" || StringFind(InpAPIBaseUrl, "http") != 0)
    {
        Print("❌ FEHLER: InpAPIBaseUrl ist ungültig: ", InpAPIBaseUrl);
        Print("   Bitte gültige URL eingeben (muss mit http:// oder https:// beginnen)");
        return INIT_PARAMETERS_INCORRECT;
    }

    if(InpAPIStatusUrl == "" || StringFind(InpAPIStatusUrl, "http") != 0)
    {
        Print("❌ FEHLER: InpAPIStatusUrl ist ungültig: ", InpAPIStatusUrl);
        return INIT_PARAMETERS_INCORRECT;
    }

    if(InpAPILoginUrl == "" || StringFind(InpAPILoginUrl, "http") != 0)
    {
        Print("❌ FEHLER: InpAPILoginUrl ist ungültig: ", InpAPILoginUrl);
        return INIT_PARAMETERS_INCORRECT;
    }

    if(InpAPIDeliveryUrl == "" || StringFind(InpAPIDeliveryUrl, "http") != 0)
    {
        Print("❌ FEHLER: InpAPIDeliveryUrl ist ungültig: ", InpAPIDeliveryUrl);
        return INIT_PARAMETERS_INCORRECT;
    }

    // Validate intervals
    if(InpCheckInterval < 1 || InpCheckInterval > 3600)
    {
        Print("❌ FEHLER: InpCheckInterval muss zwischen 1 und 3600 Sekunden liegen: ", InpCheckInterval);
        return INIT_PARAMETERS_INCORRECT;
    }

    if(InpStatusInterval < 1 || InpStatusInterval > 3600)
    {
        Print("❌ FEHLER: InpStatusInterval muss zwischen 1 und 3600 Sekunden liegen: ", InpStatusInterval);
        return INIT_PARAMETERS_INCORRECT;
    }

    // Validate Magic Number
    if(InpMagicNumber <= 0)
    {
        Print("❌ FEHLER: InpMagicNumber muss größer als 0 sein: ", InpMagicNumber);
        return INIT_PARAMETERS_INCORRECT;
    }

    // Validate Risk Parameters
    if(InpEnableRiskOptimization)
    {
        if(InpMaxRiskIterations < 10 || InpMaxRiskIterations > 1000)
        {
            Print("❌ FEHLER: InpMaxRiskIterations muss zwischen 10 und 1000 liegen: ", InpMaxRiskIterations);
            return INIT_PARAMETERS_INCORRECT;
        }

        if(InpRiskTolerance < 0.001 || InpRiskTolerance > 10.0)
        {
            Print("❌ FEHLER: InpRiskTolerance muss zwischen 0.001 und 10.0 liegen: ", InpRiskTolerance);
            return INIT_PARAMETERS_INCORRECT;
        }
    }

    // Validate Delivery API Parameters
    if(InpEnableDeliveryAPI)
    {
        if(InpDeliveryRetryAttempts < 1 || InpDeliveryRetryAttempts > 10)
        {
            Print("❌ FEHLER: InpDeliveryRetryAttempts muss zwischen 1 und 10 liegen: ", InpDeliveryRetryAttempts);
            return INIT_PARAMETERS_INCORRECT;
        }

        if(InpDeliveryTimeout < 1000 || InpDeliveryTimeout > 60000)
        {
            Print("❌ FEHLER: InpDeliveryTimeout muss zwischen 1000 und 60000 ms liegen: ", InpDeliveryTimeout);
            return INIT_PARAMETERS_INCORRECT;
        }
    }

    // All validations passed
    if(InpDebugMode)
    {
        Print("✓ Alle Input-Parameter validiert");
    }

    // ═══════════════════════════════════════════════════════════════════
    // INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════

    ArrayResize(g_executedSignals, 0);
    ArrayResize(g_trackedPositions, 0);
    ArrayResize(g_eaDeletedTickets, 0);
    g_lastEaDelete = 0;
    
    g_deliveryStats.totalRequests = 0;
    g_deliveryStats.successfulRequests = 0;
    g_deliveryStats.failedRequests = 0;
    g_deliveryStats.retryAttempts = 0;
    g_deliveryStats.lastRequest = 0;
    g_deliveryStats.lastError = "";
    g_deliveryStats.pendingOrderNotifications = 0;
    g_deliveryStats.marketOrderNotifications = 0;
    g_deliveryStats.closeNotifications = 0;
    g_deliveryStats.updateNotifications = 0;
    
    g_multiSignalStats.totalSignalsReceived = 0;
    g_multiSignalStats.totalSignalsProcessed = 0;
    g_multiSignalStats.totalSignalsSkipped = 0;
    g_multiSignalStats.batchCount = 0;
    g_multiSignalStats.lastBatchTime = 0;
    g_multiSignalStats.newSignalsThisSession = 0;
    g_multiSignalStats.slTpUpdatesThisSession = 0;
    
    g_closeStats.slHit = 0;
    g_closeStats.tpHit = 0;
    g_closeStats.breakEvenHit = 0;
    g_closeStats.manuallyClosed = 0;
    g_closeStats.eaClosed = 0;
    g_closeStats.marginCall = 0;
    g_closeStats.pendingTriggered = 0;
    g_closeStats.pendingManuallyDeleted = 0;
    g_closeStats.pendingExpired = 0;
    g_closeStats.marketClosed = 0;
    g_closeStats.other = 0;
    // v10: Initialize dual TP statistics
    g_closeStats.tp1Hit = 0;
    g_closeStats.tp2Hit = 0;
    g_closeStats.tp1FullClose = 0;
    
    // OPTIMIZED v9: Initialize Risk Optimization Stats
    g_riskOptStats.totalOptimizations = 0;
    g_riskOptStats.lotsIncreased = 0;
    g_riskOptStats.lotsDecreased = 0;
    g_riskOptStats.lotsUnchanged = 0;
    g_riskOptStats.totalRiskGained = 0;
    g_riskOptStats.avgIterations = 0;
    g_riskOptStats.maxDeviation = 0;
    g_riskOptStats.avgDeviation = 0;
    
    LoadExecutedSignals();
    LoadTrackedPositions();
    DetectSymbolSuffix();
    TrySendLoginStatus();
    
    EventSetTimer(1);
    
    long accountNumber = AccountInfoInteger(ACCOUNT_LOGIN);
    string accountCompany = AccountInfoString(ACCOUNT_COMPANY);
    
    Print("====================================");
    Print("Signal Receiver EA v11.1 OPTIMIZED");
    Print("====================================");
    Print("Konto: ", accountNumber, " | ", accountCompany);
    Print("====================================");
    Print("API Endpoints:");
    Print("  Signals: ", InpAPIBaseUrl);
    Print("  Status: ", InpAPIStatusUrl);
    Print("  Login: ", InpAPILoginUrl);
    Print("  Delivery: ", InpAPIDeliveryUrl);
    Print("====================================");
    Print("Konfiguration:");
    Print("  Delivery API: ", (InpEnableDeliveryAPI ? "EIN" : "AUS"));
    Print("  Debug Mode: ", (InpDebugMode ? "EIN" : "AUS"));
    Print("  Delivery Debug: ", (InpDeliveryDebugMode ? "EIN" : "AUS"));
    Print("  Signal-Check: ", InpCheckInterval, "s");
    Print("  Status-Check: ", InpStatusInterval, "s");
    Print("  Symbol-Suffix: ", (g_symbolSuffix == "" ? "keins" : g_symbolSuffix));
    Print("====================================");
    Print("NEW in v9 OPTIMIZED:");
    Print("  🎯 PRÄZISE RISIKO-VALIDIERUNG");
    Print("  ✓ Post-Calculation Check aktiviert");
    Print("  ✓ Maximale Ausnutzung des Risikos");
    Print("  ✓ Strikte Obergrenze (nie überschreiten)");
    Print("  ✓ Risk Optimization: ", (InpEnableRiskOptimization ? "EIN" : "AUS"));
    Print("  ✓ Max Iterations: ", InpMaxRiskIterations);
    Print("  ✓ Risk Tolerance: ", DoubleToString(InpRiskTolerance, 2), "%");
    Print("  ✓ Aggressive Mode: ", (InpAggressiveOptimization ? "EIN" : "AUS"));
    Print("====================================");
    
    int activeMappings = CountActiveMappings();
    if(activeMappings > 0)
    {
        Print("Aktive Symbol-Mappings: ", activeMappings);
        if(InpDebugMode)
            PrintAllMappings();
    }
    Print("====================================");
    
    SynchronizeExistingPositions();
    
    Print("Teste Signal API...");
    string response = FetchSignalsFromAPI();
    if(response != "")
    {
        Print("✓ Signal API verbunden");
        
        if(StringGetCharacter(response, 0) == '[' || StringGetCharacter(response, 0) == '{')
        {
            if(response != "[]" && response != "{}")
            {
                Print("Verarbeite initiale Signale...");
                ParseAndExecuteSignals(response);
            }
        }
    }
    
    Print("====================================");
    Print("EA aktiv - überwacht Signale");
    Print("====================================");
    
    return(INIT_SUCCEEDED);
}

//| Count active mappings                                           |
int CountActiveMappings()
{
    int count = 0;
    string mappings[30];
    mappings[0] = InpMapping01; mappings[1] = InpMapping02; mappings[2] = InpMapping03;
    mappings[3] = InpMapping04; mappings[4] = InpMapping05; mappings[5] = InpMapping06;
    mappings[6] = InpMapping07; mappings[7] = InpMapping08; mappings[8] = InpMapping09;
    mappings[9] = InpMapping10; mappings[10] = InpMapping11; mappings[11] = InpMapping12;
    mappings[12] = InpMapping13; mappings[13] = InpMapping14; mappings[14] = InpMapping15;
    mappings[15] = InpMapping16; mappings[16] = InpMapping17; mappings[17] = InpMapping18;
    mappings[18] = InpMapping19; mappings[19] = InpMapping20; mappings[20] = InpMapping21;
    mappings[21] = InpMapping22; mappings[22] = InpMapping23; mappings[23] = InpMapping24;
    mappings[24] = InpMapping25; mappings[25] = InpMapping26; mappings[26] = InpMapping27;
    mappings[27] = InpMapping28; mappings[28] = InpMapping29; mappings[29] = InpMapping30;
    
    for(int i = 0; i < 30; i++)
    {
        if(mappings[i] != "" && StringLen(mappings[i]) > 0)
            count++;
    }
    
    return count;
}

//| Print all active mappings (Debug)                              |
void PrintAllMappings()
{
    string mappings[30];
    mappings[0] = InpMapping01; mappings[1] = InpMapping02; mappings[2] = InpMapping03;
    mappings[3] = InpMapping04; mappings[4] = InpMapping05; mappings[5] = InpMapping06;
    mappings[6] = InpMapping07; mappings[7] = InpMapping08; mappings[8] = InpMapping09;
    mappings[9] = InpMapping10; mappings[10] = InpMapping11; mappings[11] = InpMapping12;
    mappings[12] = InpMapping13; mappings[13] = InpMapping14; mappings[14] = InpMapping15;
    mappings[15] = InpMapping16; mappings[16] = InpMapping17; mappings[17] = InpMapping18;
    mappings[18] = InpMapping19; mappings[19] = InpMapping20; mappings[20] = InpMapping21;
    mappings[21] = InpMapping22; mappings[22] = InpMapping23; mappings[23] = InpMapping24;
    mappings[24] = InpMapping25; mappings[25] = InpMapping26; mappings[26] = InpMapping27;
    mappings[27] = InpMapping28; mappings[28] = InpMapping29; mappings[29] = InpMapping30;
    
    Print("Symbol Alias-Gruppen (aktiv):");
    for(int i = 0; i < 30; i++)
    {
        if(mappings[i] != "" && StringLen(mappings[i]) > 0)
        {
            Print("  Gruppe ", (i+1), ": ", mappings[i]);
        }
    }
}

//| Synchronize existing positions                                 |
void SynchronizeExistingPositions()
{
    int synced = 0;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 && PositionSelectByTicket(ticket))
        {
            string comment = PositionGetString(POSITION_COMMENT);
            string symbol = PositionGetString(POSITION_SYMBOL);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            
            if(StringFind(comment, "sig") >= 0)
            {
                string signalId = ExtractSignalId(comment);
                
                if(signalId != "" && !IsPositionTracked(ticket))
                {
                    double originalRisk = 1.0;
                    int riskPos = StringFind(comment, "R:");
                    if(riskPos >= 0)
                    {
                        string riskStr = StringSubstr(comment, riskPos + 2, 5);
                        double extractedRisk = StringToDouble(riskStr);
                        if(extractedRisk > 0 && extractedRisk <= 100)
                            originalRisk = extractedRisk;
                    }
                    
                    AddTrackedPosition(signalId, ticket, 
                                     PositionGetDouble(POSITION_SL),
                                     PositionGetDouble(POSITION_TP),
                                     0, false, originalRisk, symbol, entryPrice, 0, false);
                    synced++;
                }
            }
        }
    }
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        ulong orderTicket = OrderGetTicket(i);
        if(orderTicket > 0 && OrderSelect(orderTicket))
        {
            string comment = OrderGetString(ORDER_COMMENT);
            string symbol = OrderGetString(ORDER_SYMBOL);
            double entryPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            
            if(StringFind(comment, "sig") >= 0)
            {
                string signalId = ExtractSignalId(comment);
                
                if(signalId != "" && !IsPositionTracked(orderTicket))
                {
                    double originalRisk = 1.0;
                    int riskPos = StringFind(comment, "R:");
                    if(riskPos >= 0)
                    {
                        string riskStr = StringSubstr(comment, riskPos + 2, 5);
                        double extractedRisk = StringToDouble(riskStr);
                        if(extractedRisk > 0 && extractedRisk <= 100)
                            originalRisk = extractedRisk;
                    }
                    
                    AddTrackedPosition(signalId, orderTicket,
                                     OrderGetDouble(ORDER_SL),
                                     OrderGetDouble(ORDER_TP),
                                     0, true, originalRisk, symbol, entryPrice, 0, false);
                    synced++;
                }
            }
        }
    }
    
    if(synced > 0)
        Print("✓ ", synced, " Position(en)/Order(s) synchronisiert");
}

//| Extract signal ID from comment                                 |
string ExtractSignalId(string comment)
{
    StringTrimLeft(comment);
    StringTrimRight(comment);
    
    int riskPos = StringFind(comment, " R:");
    if(riskPos > 0)
    {
        comment = StringSubstr(comment, 0, riskPos);
        StringTrimRight(comment);
    }
    
    if(StringFind(comment, "sig_") == 0)
        return comment;
    
    if(StringFind(comment, "Signal:") == 0)
    {
        string signalId = StringSubstr(comment, 7);
        StringTrimLeft(signalId);
        StringTrimRight(signalId);
        return signalId;
    }
    
    int sigPos = StringFind(comment, "sig_");
    if(sigPos >= 0)
    {
        string signalId = StringSubstr(comment, sigPos);
        int spacePos = StringFind(signalId, " ");
        if(spacePos > 0)
            signalId = StringSubstr(signalId, 0, spacePos);
        return signalId;
    }
    
    return "";
}

//| Check if position is tracked                                   |
bool IsPositionTracked(ulong ticket)
{
    for(int i = 0; i < ArraySize(g_trackedPositions); i++)
    {
        if(g_trackedPositions[i].ticket == ticket)
            return true;
    }
    return false;
}

//| Add position to tracking                                       |
void AddTrackedPosition(string signalId, ulong ticket, double sl, double tp, 
                        double breakEvenPrice, bool isPending, double originalRisk, 
                        string symbol = "", double entryPrice = 0, 
                        double beTriggerPrice = 0, bool beTriggerActive = false,
                        double tp1 = 0, double tp2 = 0, ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY)
{
    int size = ArraySize(g_trackedPositions);
    ArrayResize(g_trackedPositions, size + 1);
    
    g_trackedPositions[size].signal_id = signalId;
    g_trackedPositions[size].ticket = ticket;
    g_trackedPositions[size].original_sl = sl;
    g_trackedPositions[size].original_tp = tp;
    g_trackedPositions[size].break_even_price = breakEvenPrice;
    g_trackedPositions[size].break_even_done = false;
    g_trackedPositions[size].last_api_sl = sl;
    g_trackedPositions[size].last_api_tp = tp;
    g_trackedPositions[size].original_risk = originalRisk;
    g_trackedPositions[size].last_blocked_sl = 0;
    g_trackedPositions[size].last_update = TimeCurrent();
    g_trackedPositions[size].is_pending = isPending;
    g_trackedPositions[size].symbol = symbol;
    g_trackedPositions[size].entry_price = entryPrice;
    g_trackedPositions[size].be_trigger_price = beTriggerPrice;
    g_trackedPositions[size].be_trigger_active = beTriggerActive;
    
    // v10: Initialize dual TP fields
    g_trackedPositions[size].tp1 = tp1;
    g_trackedPositions[size].tp2 = tp2;
    g_trackedPositions[size].tp1_done = false;
    g_trackedPositions[size].has_dual_tp = (tp1 > 0 && tp2 > 0 && MathAbs(tp1 - tp2) > 0.00001);
    g_trackedPositions[size].order_type = orderType;
    
    SaveTrackedPositions();
}

//| Check position status from API                                  |
void CheckPositionStatus(int posIndex)
{
    if(posIndex < 0 || posIndex >= ArraySize(g_trackedPositions))
        return;
    
    long accountNumber = AccountInfoInteger(ACCOUNT_LOGIN);
    
    string fullUrl = InpAPIStatusUrl + 
                    "?signal_id=" + g_trackedPositions[posIndex].signal_id +
                    "&account_id=" + IntegerToString(accountNumber) +
                    "&ticket=" + IntegerToString(g_trackedPositions[posIndex].ticket);
    
    string headers = "Content-Type: application/json\r\n";
    char post[];
    char result[];
    string resultHeaders;
    
    int timeout = 5000;
    ArrayResize(post, 0);

    // v11.1: Use retry logic for status checks
    int res = WebRequestWithRetry("GET", fullUrl, headers, timeout, post, result, resultHeaders, 3);

    if(res <= 0)
        return;

    string response = CharArrayToString(result, 0, ArraySize(result), CP_UTF8);

    ProcessStatusResponse(posIndex, response);
}

//| Process status response from API                               |
void ProcessStatusResponse(int posIndex, string json)
{
    if(posIndex < 0 || posIndex >= ArraySize(g_trackedPositions))
        return;
    
    if(json == "" || json == "[]" || json == "{}")
        return;
    
    StringReplace(json, "[", "");
    StringReplace(json, "]", "");
    
    string status = GetJsonValue(json, "status");
    string slStr = GetJsonValue(json, "sl");
    string tpStr = GetJsonValue(json, "tp1");
    if(tpStr == "") tpStr = GetJsonValue(json, "tp");
    
    string bePriceStr = GetJsonValue(json, "be_price");
    double beTriggerPrice = 0;
    bool beTriggerActive = false;
    
    if(bePriceStr != "" && bePriceStr != "null" && bePriceStr != "NULL")
    {
        beTriggerPrice = StringToDouble(bePriceStr);
        if(beTriggerPrice > 0)
        {
            beTriggerActive = true;
            
            if(MathAbs(beTriggerPrice - g_trackedPositions[posIndex].be_trigger_price) > 0.00001)
            {
                Print("🎯 BE-TRIGGER UPDATE: ", g_trackedPositions[posIndex].signal_id, 
                      " | Ticket ", g_trackedPositions[posIndex].ticket,
                      " | BE-Trigger: ", beTriggerPrice);
                
                g_trackedPositions[posIndex].be_trigger_price = beTriggerPrice;
                g_trackedPositions[posIndex].be_trigger_active = true;
                g_trackedPositions[posIndex].break_even_done = false;
                SaveTrackedPositions();
            }
        }
    }
    else
    {
        if(g_trackedPositions[posIndex].be_trigger_active)
        {
            Print("⚠ BE-TRIGGER DEAKTIVIERT: ", g_trackedPositions[posIndex].signal_id, 
                  " | Ticket ", g_trackedPositions[posIndex].ticket);
            
            g_trackedPositions[posIndex].be_trigger_price = 0;
            g_trackedPositions[posIndex].be_trigger_active = false;
            SaveTrackedPositions();
        }
    }
    
    double newSL = slStr != "" ? StringToDouble(slStr) : 0;
    double newTP = tpStr != "" ? StringToDouble(tpStr) : 0;
    
    if(status == "cancelled" || status == "canceled")
    {
        Print("⚠ CANCELLED: ", g_trackedPositions[posIndex].signal_id, " | Ticket ", g_trackedPositions[posIndex].ticket);
        CloseOrDeletePosition(posIndex);
        return;
    }
    
    if((status == "break_even" || status == "breakeven") && !g_trackedPositions[posIndex].break_even_done)
    {
        Print("🎯 BREAK-EVEN (MANUELL): ", g_trackedPositions[posIndex].signal_id, " | Ticket ", g_trackedPositions[posIndex].ticket);
        ExecuteBreakEven(posIndex, "manual");
        return;
    }
    
    bool slChanged = (newSL > 0 && MathAbs(newSL - g_trackedPositions[posIndex].last_api_sl) > 0.00001);
    bool tpChanged = (newTP > 0 && MathAbs(newTP - g_trackedPositions[posIndex].last_api_tp) > 0.00001);
    
    if(slChanged || tpChanged)
    {
        Print("🔄 UPDATE: ", g_trackedPositions[posIndex].signal_id, " | Ticket ", g_trackedPositions[posIndex].ticket);
        if(slChanged) Print("  SL: ", g_trackedPositions[posIndex].last_api_sl, " → ", newSL);
        if(tpChanged) Print("  TP: ", g_trackedPositions[posIndex].last_api_tp, " → ", newTP);
        
        g_multiSignalStats.slTpUpdatesThisSession++;
        
        UpdatePosition(posIndex, newSL, newTP, slChanged, tpChanged);
    }
}

//| Update position SL/TP                                          |
void UpdatePosition(int posIndex, double newSL, double newTP, bool updateSL, bool updateTP)
{
    if(posIndex < 0 || posIndex >= ArraySize(g_trackedPositions))
        return;
    
    if(g_trackedPositions[posIndex].is_pending)
    {
        if(OrderSelect(g_trackedPositions[posIndex].ticket))
        {
            string symbol = OrderGetString(ORDER_SYMBOL);
            ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            double entryPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            double currentSL = OrderGetDouble(ORDER_SL);
            double currentTP = OrderGetDouble(ORDER_TP);
            string comment = OrderGetString(ORDER_COMMENT);
            
            double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
            double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
            double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
            double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
            double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
            int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
            
            double slToUse = updateSL ? newSL : currentSL;
            double newSlDistance = MathAbs(entryPrice - slToUse) / point;
            
            double riskPercent = g_trackedPositions[posIndex].original_risk;
            
            double newLotSize = CalculateLotSize(symbol, riskPercent, newSlDistance, tickValue, tickSize, point, entryPrice, orderType);
            newLotSize = NormalizeLotSize(newLotSize, minLot, maxLot, lotStep);
            
            double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
            double actualLoss = CalculateActualLoss(symbol, newLotSize, newSlDistance, entryPrice, orderType);
            double actualRiskPercent = (actualLoss / accountBalance) * 100.0;
            
            if(actualRiskPercent > riskPercent * 1.05)
            {
                Print("❌ RISIKO zu hoch für Pending Order Update - wird NICHT ausgeführt");
                
                g_trackedPositions[posIndex].last_api_sl = newSL;
                if(updateTP) g_trackedPositions[posIndex].last_api_tp = newTP;
                SaveTrackedPositions();
                
                SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "risk_rejected", false,
                                       g_trackedPositions[posIndex].ticket,
                                       StringFormat("Risk too high: %.2f%% > %.2f%%", actualRiskPercent, riskPercent),
                                       "", 0, 0, 0, 0, 0, 0, symbol);
                return;
            }
            
            MqlTradeRequest deleteRequest = {};
            MqlTradeResult deleteResult = {};
            
            deleteRequest.action = TRADE_ACTION_REMOVE;
            deleteRequest.order = g_trackedPositions[posIndex].ticket;
            
            if(OrderSend(deleteRequest, deleteResult))
            {
                RegisterEADeletion(g_trackedPositions[posIndex].ticket);
                
                SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "order_deleted", true,
                                       g_trackedPositions[posIndex].ticket,
                                       "Old pending order deleted for modification",
                                       "", 0, 0, 0, 0, 0, 0, symbol);
                
                MqlTradeRequest newRequest = {};
                MqlTradeResult newResult = {};
                
                newRequest.action = TRADE_ACTION_PENDING;
                newRequest.symbol = symbol;
                newRequest.volume = newLotSize;
                newRequest.type = orderType;
                newRequest.price = NormalizeDouble(entryPrice, digits);
                newRequest.sl = updateSL ? NormalizeDouble(newSL, digits) : NormalizeDouble(currentSL, digits);
                newRequest.tp = updateTP ? NormalizeDouble(newTP, digits) : NormalizeDouble(currentTP, digits);
                newRequest.magic = InpMagicNumber;
                newRequest.comment = comment;
                newRequest.type_filling = GetSymbolFillingMode(symbol);
                
                if(OrderSend(newRequest, newResult))
                {
                    Print("✓ Pending Order neu platziert: ", newResult.order);
                    
                    g_trackedPositions[posIndex].ticket = newResult.order;
                    if(updateSL) g_trackedPositions[posIndex].original_sl = newSL;
                    if(updateTP) g_trackedPositions[posIndex].original_tp = newTP;
                    g_trackedPositions[posIndex].last_update = TimeCurrent();
                    
                    if(updateSL) g_trackedPositions[posIndex].last_api_sl = newSL;
                    if(updateTP) g_trackedPositions[posIndex].last_api_tp = newTP;
                    
                    SaveTrackedPositions();
                    
                    string orderTypeStr = ConvertOrderTypeToN8nFormat(EnumToString(orderType));
                    
                    SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "pending_recreated", true, newResult.order,
                                           StringFormat("Pending order recreated: %.3f lots", newLotSize),
                                           orderTypeStr, newLotSize, riskPercent, actualLoss,
                                           actualRiskPercent, actualLoss, 0, symbol);
                }
                else
                {
                    Print("❌ Fehler beim Platzieren der neuen Order: ", newResult.retcode);
                    
                    SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "new_order_failed", false,
                                           0, StringFormat("Failed to place new order: %d", newResult.retcode),
                                           "", 0, 0, 0, 0, 0, 0, symbol);
                    
                    CleanupTrackedPositions();
                }
            }
            else
            {
                Print("❌ Fehler beim Löschen der alten Order: ", deleteResult.retcode);
                
                SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "deletion_failed", false,
                                       g_trackedPositions[posIndex].ticket,
                                       StringFormat("Failed to delete old order: %d", deleteResult.retcode),
                                       "", 0, 0, 0, 0, 0, 0, symbol);
            }
        }
    }
    else
    {
        if(PositionSelectByTicket(g_trackedPositions[posIndex].ticket))
        {
            string symbol = PositionGetString(POSITION_SYMBOL);
            double currentSL = PositionGetDouble(POSITION_SL);
            double currentTP = PositionGetDouble(POSITION_TP);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            int posType = (int)PositionGetInteger(POSITION_TYPE);
            int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
            
            // CRITICAL FIX: Prevent SL widening (only allow SL tightening)
            // This protects against overwriting BE/Trailing SL after EA restart
            if(updateSL && currentSL > 0)
            {
                bool isBuy = (posType == POSITION_TYPE_BUY);
                double currentSlDistance = isBuy ? (entryPrice - currentSL) : (currentSL - entryPrice);
                double newSlDistance = isBuy ? (entryPrice - newSL) : (newSL - entryPrice);
                
                // Check if new SL is further from entry (= widening = bad!)
                if(newSlDistance > currentSlDistance)
                {
                    Print("⚠️ SL-VERGRÖSSERUNG BLOCKIERT: ", g_trackedPositions[posIndex].signal_id, 
                          " | Ticket ", g_trackedPositions[posIndex].ticket);
                    Print("   Aktueller SL: ", currentSL, " (Distance: ", DoubleToString(currentSlDistance, 1), " Points)");
                    Print("   Neuer SL: ", newSL, " (Distance: ", DoubleToString(newSlDistance, 1), " Points)");
                    Print("   → SL-Vergrößerung nicht erlaubt! (Schutz vor BE/Trailing-Überschreibung)");
                    
                    // Update tracking but DON'T send to broker
                    g_trackedPositions[posIndex].last_api_sl = newSL;
                    SaveTrackedPositions();
                    
                    SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "sl_widening_blocked", false,
                                           g_trackedPositions[posIndex].ticket,
                                           StringFormat("SL widening blocked: Current %.5f (%.1f pts) → New %.5f (%.1f pts)", 
                                                       currentSL, currentSlDistance, newSL, newSlDistance),
                                           "", 0, 0, 0, 0, 0, 0, symbol);
                    return;
                }
                
                // SL is tightening or same → OK
                if(newSlDistance < currentSlDistance)
                {
                    Print("✅ SL-VERKLEINERUNG: ", g_trackedPositions[posIndex].signal_id, 
                          " | Ticket ", g_trackedPositions[posIndex].ticket);
                    Print("   ", currentSL, " (", DoubleToString(currentSlDistance, 1), " pts) → ",
                          newSL, " (", DoubleToString(newSlDistance, 1), " pts)");
                }
            }
            
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_SLTP;
            request.position = g_trackedPositions[posIndex].ticket;
            
            request.sl = updateSL ? NormalizeDouble(newSL, digits) : NormalizeDouble(currentSL, digits);
            request.tp = updateTP ? NormalizeDouble(newTP, digits) : NormalizeDouble(currentTP, digits);
            
            if(OrderSend(request, result))
            {
                Print("✓ Position aktualisiert: Ticket ", g_trackedPositions[posIndex].ticket);
                
                if(updateSL) g_trackedPositions[posIndex].last_api_sl = newSL;
                if(updateTP) g_trackedPositions[posIndex].last_api_tp = newTP;
                
                SaveTrackedPositions();
                
                string statusMsg = "";
                string deliveryMsg = "";
                if(updateSL && updateTP)
                {
                    statusMsg = "sl_tp_updated";
                    deliveryMsg = StringFormat("Position SL/TP updated: SL %.5f, TP %.5f", request.sl, request.tp);
                }
                else if(updateSL)
                {
                    statusMsg = "sl_updated";
                    deliveryMsg = StringFormat("Position SL updated: %.5f", request.sl);
                }
                else if(updateTP)
                {
                    statusMsg = "tp_updated";
                    deliveryMsg = StringFormat("Position TP updated: %.5f", request.tp);
                }
                
                if(statusMsg != "")
                {
                    SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, statusMsg, true,
                                           g_trackedPositions[posIndex].ticket, deliveryMsg,
                                           "", 0, 0, 0, 0, 0, 0, symbol);
                }
            }
            else
            {
                Print("❌ Fehler beim Aktualisieren: ", result.retcode);
                
                SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "position_update_failed", false,
                                       g_trackedPositions[posIndex].ticket,
                                       StringFormat("Position update failed: %d", result.retcode),
                                       "", 0, 0, 0, 0, 0, 0, symbol);
            }
        }
    }
}

//| v9 DIRECT: Calculate lot size with REAL OrderCalcProfit      |
//| No correction needed - first calculation is accurate!           |
double CalculateLotSize(string symbol, double riskPercent, double slPoints, 
                       double tickValue, double tickSize, double point,
                       double entryPrice, ENUM_ORDER_TYPE orderType)
{
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = accountBalance * (riskPercent / 100.0);
    
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    
    // ===================================================================
    // v9 NEW: DIRECT calculation with OrderCalcProfit iteration
    // ===================================================================
    
    if(InpUseOrderCalcProfit && entryPrice > 0)
    {
        // Calculate SL price based on order type
        double slPrice = 0;
        ENUM_ORDER_TYPE calcType = orderType;
        
        if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
        {
            slPrice = entryPrice - (slPoints * point);
            calcType = ORDER_TYPE_BUY;
        }
        else  // SELL
        {
            slPrice = entryPrice + (slPoints * point);
            calcType = ORDER_TYPE_SELL;
        }
        
        // Start with theoretical calculation as initial guess
        double theoreticalLot = 0;
        if(tickSize != 0 && tickValue != 0)
        {
            double ticksInSL = slPoints * (point / tickSize);
            double lossPerLotTick = ticksInSL * tickValue;
            if(lossPerLotTick > 0)
                theoreticalLot = riskAmount / lossPerLotTick;
        }
        else
        {
            double lossPerLot = contractSize * slPoints * point;
            if(lossPerLot > 0)
                theoreticalLot = riskAmount / lossPerLot;
        }
        
        // Normalize initial guess
        theoreticalLot = MathRound(theoreticalLot / lotStep) * lotStep;
        if(theoreticalLot < minLot) theoreticalLot = minLot;
        if(theoreticalLot > maxLot) theoreticalLot = maxLot;
        
        // Iteratively find the correct lot size using OrderCalcProfit
        double currentLot = theoreticalLot;
        double bestLot = currentLot;
        double bestDeviation = 999999;
        int maxIterations = 50;  // Limit iterations for performance
        
        for(int i = 0; i < maxIterations; i++)
        {
            double profit = 0;
            if(OrderCalcProfit(calcType, symbol, currentLot, entryPrice, slPrice, profit))
            {
                double actualLoss = MathAbs(profit);
                
                // CRITICAL FIX: Validate OrderCalcProfit result
                // If actualLoss is 0.00, quotes are not available yet
                if(i == 0 && actualLoss < 0.01)
                {
                    Print("⚠️ OrderCalcProfit returned 0.00 - Quotes may not be available");
                    Print("   Symbol: ", symbol, " | Entry: ", entryPrice, " | SL: ", slPrice);
                    Print("   Retrying in 1 second...");
                    Sleep(1000);
                    
                    // Retry once
                    if(OrderCalcProfit(calcType, symbol, currentLot, entryPrice, slPrice, profit))
                    {
                        actualLoss = MathAbs(profit);
                        if(actualLoss < 0.01)
                        {
                            Print("❌ OrderCalcProfit still returns 0.00 - Cannot calculate risk");
                            Print("   Signal REJECTED for safety");
                            return 0.0;  // Abort - cannot calculate risk
                        }
                        Print("✅ OrderCalcProfit successful after retry: ", DoubleToString(actualLoss, 2), " USD");
                    }
                    else
                    {
                        Print("❌ OrderCalcProfit failed on retry - Signal REJECTED");
                        return 0.0;
                    }
                }
                
                double deviation = MathAbs(actualLoss - riskAmount);
                
                if(InpDebugMode)
                {
                    Print("  [", i+1, "] Lot=", DoubleToString(currentLot, 3), 
                          " Loss=", DoubleToString(actualLoss, 2),
                          " Target=", DoubleToString(riskAmount, 2),
                          " Dev=", DoubleToString(deviation, 2));
                }
                
                // Check if this is the best so far
                if(deviation < bestDeviation && actualLoss <= riskAmount * 1.005)  // Allow 0.5% tolerance
                {
                    bestDeviation = deviation;
                    bestLot = currentLot;
                }
                
                // If we're within tolerance, we're done
                if(deviation < riskAmount * 0.005)  // 0.5% tolerance
                {
                    if(InpDebugMode)
                        Print("  ✅ Found optimal lot size in ", i+1, " iterations");
                    return bestLot;
                }
                
                // Adjust lot size based on deviation
                if(actualLoss < riskAmount)
                {
                    // Loss is too small, increase lot size
                    double ratio = riskAmount / actualLoss;
                    currentLot = currentLot * ratio;
                }
                else
                {
                    // Loss is too large, decrease lot size
                    double ratio = riskAmount / actualLoss;
                    currentLot = currentLot * ratio;
                }
                
                // Normalize and clamp
                currentLot = MathRound(currentLot / lotStep) * lotStep;
                if(currentLot < minLot) currentLot = minLot;
                if(currentLot > maxLot) currentLot = maxLot;
                
                // If we're stuck at the same lot size, try small adjustments
                if(MathAbs(currentLot - bestLot) < lotStep * 0.1)
                {
                    if(actualLoss < riskAmount)
                        currentLot = bestLot + lotStep;
                    else
                        currentLot = bestLot - lotStep;
                    
                    if(currentLot < minLot || currentLot > maxLot)
                        break;  // Can't adjust further
                }
            }
            else
            {
                // OrderCalcProfit failed, use fallback
                if(InpDebugMode)
                    Print("  ⚠ OrderCalcProfit failed at iteration ", i+1);
                break;
            }
        }
        
        if(InpDebugMode)
            Print("  ℹ Using best lot from iterations: ", DoubleToString(bestLot, 3));
        
        return bestLot;
    }
    
    // ===================================================================
    // FALLBACK: Traditional calculation (if OrderCalcProfit not available)
    // ===================================================================
    
    bool isJPYPair = (StringFind(symbol, "JPY") >= 0);
    bool isCrypto = (StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "ETH") >= 0 || 
                     StringFind(symbol, "XRP") >= 0 || StringFind(symbol, "USDT") >= 0);
    bool isMetal = (StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0);
    bool isIndex = (StringFind(symbol, "US30") >= 0 || StringFind(symbol, "US100") >= 0 ||
                    StringFind(symbol, "US500") >= 0 || StringFind(symbol, "DE30") >= 0);
    bool isCommodity = (StringFind(symbol, "OIL") >= 0 || StringFind(symbol, "WTI") >= 0);
    
    double lotSize = 0;
    
    if(tickSize != 0 && tickValue != 0)
    {
        double ticksInSL = slPoints * (point / tickSize);
        double lossPerLotTick = ticksInSL * tickValue;
        if(lossPerLotTick > 0)
            lotSize = riskAmount / lossPerLotTick;
    }
    else if(isCrypto)
    {
        double lossPerLot = contractSize * slPoints * point;
        if(lossPerLot > 0)
            lotSize = riskAmount / lossPerLot;
    }
    else if(isJPYPair)
    {
        if(slPoints > 0 && tickValue > 0)
            lotSize = riskAmount / (slPoints * tickValue);
    }
    else
    {
        double valuePerPoint = contractSize * point;
        if(slPoints > 0 && valuePerPoint > 0)
            lotSize = riskAmount / (slPoints * valuePerPoint);
    }
    
    return lotSize;
}

//| Normalize lot size                                             |
double NormalizeLotSize(double lots, double minLot, double maxLot, double lotStep)
{
    lots = MathRound(lots / lotStep) * lotStep;
    
    if(lots < minLot)
        lots = minLot;
    if(lots > maxLot)
        lots = maxLot;
    
    int lotDigits = 0;
    double step = lotStep;
    int maxIterations = 10;  // Safety: max 10 iterations
    int iterations = 0;
    while(step < 1.0 && iterations < maxIterations)
    {
        step *= 10;
        lotDigits++;
        iterations++;
    }
    
    return NormalizeDouble(lots, lotDigits);
}

//| FIXED v9: Calculate REAL loss using OrderCalcProfit          |
//| Uses actual entry price and direction for accurate calculation  |
double CalculateActualLoss(string symbol, double lotSize, double slPoints, 
                          double entryPrice, ENUM_ORDER_TYPE orderType)
{
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
    
    double actualLoss = 0;
    bool useOrderCalcProfit = InpUseOrderCalcProfit;
    
    // ===================================================================
    // PRIMARY METHOD: Use OrderCalcProfit with REAL entry price (v9 FIXED!)
    // ===================================================================
    if(useOrderCalcProfit && entryPrice > 0)
    {
        // Calculate SL price based on order type
        double slPrice = 0;
        if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
        {
            // For BUY: SL is below entry
            slPrice = entryPrice - (slPoints * point);
        }
        else  // SELL
        {
            // For SELL: SL is above entry
            slPrice = entryPrice + (slPoints * point);
        }
        
        double profit = 0;
        
        // Calculate profit/loss using OrderCalcProfit with REAL prices
        ENUM_ORDER_TYPE calcType = orderType;
        if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
            calcType = ORDER_TYPE_BUY;
        else if(orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL_STOP)
            calcType = ORDER_TYPE_SELL;
        
        if(OrderCalcProfit(calcType, symbol, lotSize, entryPrice, slPrice, profit))
        {
            actualLoss = MathAbs(profit);
            
            // CRITICAL FIX: Validate OrderCalcProfit result for 0.00
            if(actualLoss < 0.01)
            {
                Print("⚠️ CalculateActualLoss: OrderCalcProfit returned 0.00");
                Print("   Symbol: ", symbol, " | Lot: ", DoubleToString(lotSize, 3));
                Print("   Entry: ", entryPrice, " | SL: ", slPrice);
                Print("   Retrying in 500ms...");
                Sleep(500);
                
                // Retry once
                if(OrderCalcProfit(calcType, symbol, lotSize, entryPrice, slPrice, profit))
                {
                    actualLoss = MathAbs(profit);
                    if(actualLoss < 0.01)
                    {
                        Print("❌ OrderCalcProfit still returns 0.00 - Using fallback calculation");
                        // Will fall through to fallback method
                    }
                    else
                    {
                        Print("✅ OrderCalcProfit successful after retry: ", DoubleToString(actualLoss, 2), " ", accountCurrency);
                    }
                }
            }
            
            if(InpDebugMode)
            {
                Print("DEBUG OrderCalcProfit (v9 FIXED):");
                Print("  Symbol: ", symbol, " | Lot: ", DoubleToString(lotSize, 3));
                Print("  Order Type: ", EnumToString(calcType));
                Print("  Entry Price: ", DoubleToString(entryPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
                Print("  SL Price: ", DoubleToString(slPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
                Print("  SL Points: ", DoubleToString(slPoints, 1));
                Print("  Calculated Loss: ", DoubleToString(actualLoss, 2), " ", accountCurrency);
            }
            
            // Validation: Check if result is reasonable (not zero and not absurdly high)
            if(actualLoss > 0.01 && actualLoss < 1000000)
            {
                if(InpDebugMode)
                    Print("  ✅ OrderCalcProfit result accepted");
                return actualLoss;  // Result is reasonable
            }
            else
            {
                if(InpDebugMode)
                    Print("  ⚠ OrderCalcProfit result seems unreasonable (", actualLoss, "), falling back");
            }
        }
        else
        {
            if(InpDebugMode)
                Print("  ⚠ OrderCalcProfit failed, using fallback calculation");
        }
    }
    
    // ===================================================================
    // FALLBACK METHOD: Manual calculation (only if OrderCalcProfit fails)
    // ===================================================================
    if(InpDebugMode)
        Print("DEBUG: Using fallback manual calculation");
    
    bool isCrypto = (StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "ETH") >= 0 || 
                     StringFind(symbol, "XRP") >= 0 || StringFind(symbol, "USDT") >= 0 ||
                     StringFind(symbol, "ADA") >= 0 || StringFind(symbol, "DOT") >= 0 ||
                     StringFind(symbol, "DOGE") >= 0 || StringFind(symbol, "LTC") >= 0 ||
                     StringFind(symbol, "SOL") >= 0 || StringFind(symbol, "AVAX") >= 0);
    
    bool isMetal = (StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0 ||
                    StringFind(symbol, "XAG") >= 0 || StringFind(symbol, "SILVER") >= 0);
    bool isIndex = (StringFind(symbol, "US30") >= 0 || StringFind(symbol, "US100") >= 0 ||
                    StringFind(symbol, "US500") >= 0 || StringFind(symbol, "DE30") >= 0 ||
                    StringFind(symbol, "DAX") >= 0 || StringFind(symbol, "NAS") >= 0);
    bool isCommodity = (StringFind(symbol, "OIL") >= 0 || StringFind(symbol, "WTI") >= 0 ||
                        StringFind(symbol, "BRENT") >= 0);
    
    if(isCrypto)
    {
        actualLoss = lotSize * contractSize * slPoints * point;
    }
    else if(isMetal || isIndex || isCommodity)
    {
        if(tickSize != 0 && tickValue != 0)
        {
            double ticks = slPoints * (point / tickSize);
            actualLoss = lotSize * ticks * tickValue;
        }
        else
        {
            actualLoss = lotSize * contractSize * slPoints * point;
        }
    }
    else  // Forex
    {
        if(tickSize != 0 && tickValue != 0)
        {
            double ticks = slPoints * (point / tickSize);
            actualLoss = lotSize * ticks * tickValue;
        }
        else
        {
            actualLoss = lotSize * slPoints * tickValue;
        }
    }
    
    if(InpDebugMode)
        Print("  Fallback Loss: ", DoubleToString(actualLoss, 2), " ", accountCurrency);
    
    return MathAbs(actualLoss);
}

//| FIXED v9: Optimize lot size with REAL loss calculation       |
//| Uses actual entry price and order type for accurate validation  |
double OptimizeLotSizeWithValidation(string symbol, double initialLotSize, double slPoints, 
                                     double targetRiskPercent, double &outActualRiskPercent,
                                     double &outActualLoss, int &outIterations,
                                     double entryPrice, ENUM_ORDER_TYPE orderType)
{
    if(!InpEnableRiskOptimization)
    {
        outIterations = 0;
        outActualLoss = CalculateActualLoss(symbol, initialLotSize, slPoints, entryPrice, orderType);
        outActualRiskPercent = (outActualLoss / AccountInfoDouble(ACCOUNT_BALANCE)) * 100.0;
        return initialLotSize;
    }
    
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    double targetRiskAmount = accountBalance * (targetRiskPercent / 100.0);
    double toleranceAmount = accountBalance * (InpRiskTolerance / 100.0);
    
    double currentLotSize = initialLotSize;
    double currentLoss = CalculateActualLoss(symbol, currentLotSize, slPoints, entryPrice, orderType);
    double currentRiskPercent = (currentLoss / accountBalance) * 100.0;
    
    int iterations = 0;
    bool optimized = false;
    double bestLotSize = currentLotSize;
    double bestLoss = currentLoss;
    double bestRiskPercent = currentRiskPercent;
    double bestDeviation = MathAbs(bestRiskPercent - targetRiskPercent);
    
    if(InpDebugMode)
    {
        Print("🎯 RISK OPTIMIZATION START (v9 FIXED - Real OrderCalcProfit):");
        Print("  Initial Lot: ", DoubleToString(currentLotSize, 3));
        Print("  Initial Risk: ", DoubleToString(currentRiskPercent, 2), "% (", DoubleToString(currentLoss, 2), " EUR)");
        Print("  Target Risk: ", DoubleToString(targetRiskPercent, 2), "% (", DoubleToString(targetRiskAmount, 2), " EUR)");
        Print("  Tolerance: ±", DoubleToString(InpRiskTolerance, 2), "% (", DoubleToString(toleranceAmount, 2), " EUR)");
        Print("  Initial Deviation: ", DoubleToString(bestDeviation, 2), "%");
    }
    
    // ===================================================================
    // PHASE 1: DECREASE if initial risk exceeds target (SAFETY FIRST!)
    // ===================================================================
    if(currentRiskPercent > targetRiskPercent)
    {
        if(InpDebugMode)
            Print("  ⚠ PHASE 1: INITIAL RISK TOO HIGH! Decreasing lots...");
        
        while(iterations < InpMaxRiskIterations && currentLotSize > minLot)
        {
            double testLotSize = currentLotSize - lotStep;
            
            if(testLotSize < minLot)
                testLotSize = minLot;
            
            testLotSize = NormalizeLotSize(testLotSize, minLot, maxLot, lotStep);
            
            // CRITICAL: Check if lot size didn't change BEFORE expensive calculation (prevents infinite loop!)
            if(testLotSize == currentLotSize)
            {
                Print("    ⚠ LOOP BREAK: Lot size cannot be reduced further (stuck at ", DoubleToString(currentLotSize, 3), ")");
                Print("    Current Risk: ", DoubleToString(currentRiskPercent, 2), "% vs Target: ", DoubleToString(targetRiskPercent, 2), "%");
                if(currentRiskPercent > targetRiskPercent)
                {
                    Print("    ⚠ WARNING: Account too small for this trade!");
                }
                bestLotSize = currentLotSize;
                bestLoss = currentLoss;
                bestRiskPercent = currentRiskPercent;
                bestDeviation = MathAbs(currentRiskPercent - targetRiskPercent);
                break;
            }
            
            double testLoss = CalculateActualLoss(symbol, testLotSize, slPoints, entryPrice, orderType);
            double testRiskPercent = (testLoss / accountBalance) * 100.0;
            double testDeviation = MathAbs(testRiskPercent - targetRiskPercent);
            
            iterations++;
            
            if(InpDebugMode)
                Print("    [", iterations, "] Lot=", DoubleToString(testLotSize, 3), 
                      " Risk=", DoubleToString(testRiskPercent, 2), "% (", DoubleToString(testLoss, 2), " EUR) Dev=", DoubleToString(testDeviation, 2), "%");
            
            // Update current values
            currentLotSize = testLotSize;
            currentLoss = testLoss;
            currentRiskPercent = testRiskPercent;
            
            // CRITICAL FIX v9: As soon as risk is below target, STOP and execute!
            // No tolerance check needed when decreasing - better to execute with lower risk than no trade!
            if(testRiskPercent <= targetRiskPercent)
            {
                bestLotSize = testLotSize;
                bestLoss = testLoss;
                bestRiskPercent = testRiskPercent;
                bestDeviation = testDeviation;
                optimized = true;
                
                if(InpDebugMode)
                    Print("    ✅ Risk now below target - STOP decreasing and execute!");
                break;
            }
            
            // Stop if we hit minLot
            if(testLotSize == minLot)
            {
                if(InpDebugMode)
                    Print("    → Reached minLot");
                
                // CRITICAL: If still exceeding target at minLot, we can't reduce further!
                if(testRiskPercent > targetRiskPercent)
                {
                    Print("    ⚠ WARNING: MinLot (", DoubleToString(minLot, 3), ") still exceeds target risk!");
                    Print("    MinLot Risk: ", DoubleToString(testRiskPercent, 2), "% > Target: ", DoubleToString(targetRiskPercent, 2), "%");
                    Print("    Account too small for this trade!");
                    bestLotSize = minLot;
                    bestLoss = testLoss;
                    bestRiskPercent = testRiskPercent;
                    bestDeviation = testDeviation;
                }
                break;
            }
        }
    }
    
    // ===================================================================
    // PHASE 2: INCREASE if under target (MAXIMIZE RISK UTILIZATION!)
    // ===================================================================
    else if(currentRiskPercent < targetRiskPercent && InpAggressiveOptimization)
    {
        if(InpDebugMode)
            Print("  → PHASE 2: Increasing lots (aggressive optimization)");
        
        // Step 2a: Coarse optimization with full lotStep
        while(iterations < InpMaxRiskIterations && currentLotSize < maxLot)
        {
            double testLotSize = currentLotSize + lotStep;
            testLotSize = NormalizeLotSize(testLotSize, minLot, maxLot, lotStep);
            
            if(testLotSize > maxLot)
                break;
            
            // CRITICAL: Check if lot size didn't change (prevents infinite loop!)
            if(testLotSize == currentLotSize)
            {
                if(InpDebugMode)
                    Print("    → LOOP BREAK: Lot size cannot be increased further (stuck at ", DoubleToString(currentLotSize, 3), ")");
                break;
            }
            
            double testLoss = CalculateActualLoss(symbol, testLotSize, slPoints, entryPrice, orderType);
            double testRiskPercent = (testLoss / accountBalance) * 100.0;
            double testDeviation = MathAbs(testRiskPercent - targetRiskPercent);
            
            iterations++;
            
            if(InpDebugMode)
                Print("    [", iterations, "] Lot=", DoubleToString(testLotSize, 3), 
                      " Risk=", DoubleToString(testRiskPercent, 2), "% (", DoubleToString(testLoss, 2), " EUR) Dev=", DoubleToString(testDeviation, 2), "%");
            
            // CRITICAL: Stop BEFORE exceeding target!
            if(testRiskPercent > targetRiskPercent)
            {
                if(InpDebugMode)
                    Print("    → Would exceed target risk (", DoubleToString(testRiskPercent, 2), "% > ", DoubleToString(targetRiskPercent, 2), "%), keeping previous lot");
                break;
            }
            
            // Update current values
            currentLotSize = testLotSize;
            currentLoss = testLoss;
            currentRiskPercent = testRiskPercent;
            
            // CRITICAL FIX v9: As soon as risk is below target, STOP and execute!
            // No tolerance check needed when decreasing - better to execute with lower risk than no trade!
            if(testRiskPercent <= targetRiskPercent)
            {
                bestLotSize = testLotSize;
                bestLoss = testLoss;
                bestRiskPercent = testRiskPercent;
                bestDeviation = testDeviation;
                optimized = true;
                
                if(InpDebugMode)
                    Print("    ✅ Risk now below target - STOP decreasing and execute!");
                break;
            }
            
            // Track best result
            if(testDeviation < bestDeviation)
            {
                bestLotSize = testLotSize;
                bestLoss = testLoss;
                bestRiskPercent = testRiskPercent;
                bestDeviation = testDeviation;
                optimized = true;
            }
            
            // Stop if we're within tolerance
            if(testDeviation <= InpRiskTolerance)
            {
                if(InpDebugMode)
                    Print("    → Reached optimal risk within tolerance");
                break;
            }
        }
        
        // Step 2b: Fine-tuning with half lotStep (NEW v9!)
        // Try to get even closer to target without exceeding
        if(bestRiskPercent < targetRiskPercent && bestDeviation > InpRiskTolerance)
        {
            if(InpDebugMode)
                Print("  → PHASE 2b: Fine-tuning with half lotStep...");
            
            double halfStep = lotStep / 2.0;
            double fineTestLot = bestLotSize;
            double previousFineLot = fineTestLot;
            
            while(iterations < InpMaxRiskIterations && fineTestLot < maxLot)
            {
                fineTestLot = fineTestLot + halfStep;
                
                // Normalize but allow half-steps
                if(fineTestLot > maxLot)
                    break;
                
                // CRITICAL: Check if lot size didn't change (prevents infinite loop!)
                if(fineTestLot == previousFineLot)
                {
                    if(InpDebugMode)
                        Print("    → LOOP BREAK: Fine lot cannot be increased further (stuck at ", DoubleToString(fineTestLot, 4), ")");
                    break;
                }
                previousFineLot = fineTestLot;
                
                double testLoss = CalculateActualLoss(symbol, fineTestLot, slPoints, entryPrice, orderType);
                double testRiskPercent = (testLoss / accountBalance) * 100.0;
                double testDeviation = MathAbs(testRiskPercent - targetRiskPercent);
                
                iterations++;
                
                if(InpDebugMode)
                    Print("    [", iterations, "] Fine Lot=", DoubleToString(fineTestLot, 4), 
                          " Risk=", DoubleToString(testRiskPercent, 2), "% (", DoubleToString(testLoss, 2), " EUR) Dev=", DoubleToString(testDeviation, 2), "%");
                
                // CRITICAL: Never exceed target!
                if(testRiskPercent > targetRiskPercent)
                {
                    if(InpDebugMode)
                        Print("    → Fine-tuning would exceed target, stopping");
                    break;
                }
                
                // Update best if better
                if(testDeviation < bestDeviation)
                {
                    bestLotSize = fineTestLot;
                    bestLoss = testLoss;
                    bestRiskPercent = testRiskPercent;
                    bestDeviation = testDeviation;
                    optimized = true;
                }
                
                // Stop if within tolerance
                if(testDeviation <= InpRiskTolerance)
                {
                    if(InpDebugMode)
                        Print("    → Fine-tuning reached optimal risk");
                    break;
                }
            }
            
            // Final normalization of fine-tuned lot
            bestLotSize = NormalizeLotSize(bestLotSize, minLot, maxLot, lotStep);
            
            // Re-calculate with normalized lot
            bestLoss = CalculateActualLoss(symbol, bestLotSize, slPoints, entryPrice, orderType);
            bestRiskPercent = (bestLoss / accountBalance) * 100.0;
            bestDeviation = MathAbs(bestRiskPercent - targetRiskPercent);
        }
    }
    else
    {
        if(InpDebugMode)
            Print("  → Initial lot size already optimal (within tolerance)");
        bestLotSize = currentLotSize;
        bestLoss = currentLoss;
        bestRiskPercent = currentRiskPercent;
    }
    
    // ===================================================================
    // FINAL SAFETY CHECK: Ensure we NEVER exceed target risk!
    // ===================================================================
    if(bestRiskPercent > targetRiskPercent)
    {
        if(InpDebugMode)
            Print("  ⚠⚠⚠ SAFETY CHECK: Best lot exceeds target! Rolling back...");
        
        // Roll back to a safe lot size
        double safeLotSize = bestLotSize;
        double previousSafeLot = safeLotSize + lotStep;  // Initialize to different value
        int safetyIterations = 0;
        int maxSafetyIterations = 100;
        
        while(safeLotSize >= minLot && safetyIterations < maxSafetyIterations)
        {
            // CRITICAL: Check if lot size didn't change (prevents infinite loop!)
            if(safeLotSize == previousSafeLot)
            {
                if(InpDebugMode)
                    Print("  → SAFETY LOOP BREAK: Cannot reduce further (stuck at ", DoubleToString(safeLotSize, 3), ")");
                break;
            }
            previousSafeLot = safeLotSize;
            safetyIterations++;
            
            double safeLoss = CalculateActualLoss(symbol, safeLotSize, slPoints, entryPrice, orderType);
            double safeRiskPercent = (safeLoss / accountBalance) * 100.0;
            
            if(safeRiskPercent <= targetRiskPercent)
            {
                bestLotSize = safeLotSize;
                bestLoss = safeLoss;
                bestRiskPercent = safeRiskPercent;
                bestDeviation = MathAbs(bestRiskPercent - targetRiskPercent);
                
                if(InpDebugMode)
                    Print("  → Rolled back to safe lot: ", DoubleToString(bestLotSize, 3), " (", DoubleToString(bestRiskPercent, 2), "%)");
                break;
            }
            
            safeLotSize -= lotStep;
            if(safeLotSize < minLot)
                safeLotSize = minLot;
        }
    }
    
    outActualLoss = bestLoss;
    outActualRiskPercent = bestRiskPercent;
    outIterations = iterations;
    
    // Update Statistics
    g_riskOptStats.totalOptimizations++;
    double deviation = bestRiskPercent - targetRiskPercent;
    
    if(optimized)
    {
        if(bestLotSize > initialLotSize)
        {
            g_riskOptStats.lotsIncreased++;
            double initialRisk = (CalculateActualLoss(symbol, initialLotSize, slPoints, entryPrice, orderType) / accountBalance) * 100.0;
            g_riskOptStats.totalRiskGained += (bestRiskPercent - initialRisk);
        }
        else if(bestLotSize < initialLotSize)
        {
            g_riskOptStats.lotsDecreased++;
        }
    }
    else
    {
        g_riskOptStats.lotsUnchanged++;
    }
    
    // Track max and average deviation
    if(MathAbs(deviation) > g_riskOptStats.maxDeviation)
        g_riskOptStats.maxDeviation = MathAbs(deviation);
    
    g_riskOptStats.avgIterations = (g_riskOptStats.avgIterations * (g_riskOptStats.totalOptimizations - 1) + iterations) / g_riskOptStats.totalOptimizations;
    g_riskOptStats.avgDeviation = (g_riskOptStats.avgDeviation * (g_riskOptStats.totalOptimizations - 1) + MathAbs(deviation)) / g_riskOptStats.totalOptimizations;
    
    if(InpDebugMode || optimized)
    {
        Print("====================================");
        Print("🎯 RISK OPTIMIZATION RESULT (v9 FIXED)");
        Print("====================================");
        Print("  Final Lot: ", DoubleToString(bestLotSize, 3), 
              (bestLotSize > initialLotSize ? " (INCREASED ✅)" : 
               bestLotSize < initialLotSize ? " (DECREASED ⚠)" : " (UNCHANGED ℹ)"));
        Print("  Final Risk: ", DoubleToString(bestRiskPercent, 2), "% (", DoubleToString(bestLoss, 2), " EUR)");
        Print("  Target Risk: ", DoubleToString(targetRiskPercent, 2), "% (", DoubleToString(targetRiskAmount, 2), " EUR)");
        Print("  Deviation: ", DoubleToString(deviation, 2), "% (", (deviation < 0 ? "UNDER ↓" : "OVER ↑"), ")");
        Print("  Iterations: ", iterations);
        Print("  Utilization: ", DoubleToString((bestRiskPercent / targetRiskPercent) * 100.0, 2), "%");
        
        if(bestLotSize > initialLotSize)
        {
            double initialRisk = (CalculateActualLoss(symbol, initialLotSize, slPoints, entryPrice, orderType) / accountBalance) * 100.0;
            double gainedRisk = bestRiskPercent - initialRisk;
            double gainedAmount = bestLoss - CalculateActualLoss(symbol, initialLotSize, slPoints, entryPrice, orderType);
            Print("  Risk Gained: +", DoubleToString(gainedRisk, 2), "% (+", DoubleToString(gainedAmount, 2), " EUR) 🎉");
        }
        
        // Safety check
        if(bestRiskPercent > targetRiskPercent)
        {
            Print("  ⚠⚠⚠ CRITICAL WARNING: Final risk exceeds target!");
            Print("  ⚠⚠⚠ This should NEVER happen - please report this bug!");
        }
        else
        {
            Print("  ✅ SAFETY CHECK PASSED: Risk within limits");
        }
        Print("====================================");
    }
    
    return bestLotSize;
}

//| Execute break even                                             |
void ExecuteBreakEven(int posIndex, string reason = "automatic")
{
    if(posIndex < 0 || posIndex >= ArraySize(g_trackedPositions))
        return;
    
    if(g_trackedPositions[posIndex].break_even_done)
        return;
    
    if(g_trackedPositions[posIndex].is_pending)
        return;
    
    if(PositionSelectByTicket(g_trackedPositions[posIndex].ticket))
    {
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        
        double breakEvenSL = openPrice;
        
        string symbol = PositionGetString(POSITION_SYMBOL);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        
        if(posType == POSITION_TYPE_BUY)
        {
            breakEvenSL = openPrice + 1 * point;
            
            if(breakEvenSL > currentSL)
            {
                MqlTradeRequest request = {};
                MqlTradeResult result = {};
                
                request.action = TRADE_ACTION_SLTP;
                request.position = g_trackedPositions[posIndex].ticket;
                request.sl = NormalizeDouble(breakEvenSL, digits);
                request.tp = currentTP;
                
                if(OrderSend(request, result))
                {
                    g_trackedPositions[posIndex].break_even_done = true;
                    SaveTrackedPositions();
                    Print("✓ BREAK-EVEN gesetzt (", reason, "): Ticket ", g_trackedPositions[posIndex].ticket);
                    
                    SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "breakeven_set", true,
                                           g_trackedPositions[posIndex].ticket,
                                           StringFormat("Break-even set for BUY (%s): %.5f", reason, request.sl),
                                           "", 0, 0, 0, 0, 0, 0, symbol);
                }
            }
            else
            {
                g_trackedPositions[posIndex].break_even_done = true;
                SaveTrackedPositions();
            }
        }
        else if(posType == POSITION_TYPE_SELL)
        {
            breakEvenSL = openPrice - 1 * point;
            
            if(breakEvenSL < currentSL || currentSL == 0)
            {
                MqlTradeRequest request = {};
                MqlTradeResult result = {};
                
                request.action = TRADE_ACTION_SLTP;
                request.position = g_trackedPositions[posIndex].ticket;
                request.sl = NormalizeDouble(breakEvenSL, digits);
                request.tp = currentTP;
                
                if(OrderSend(request, result))
                {
                    g_trackedPositions[posIndex].break_even_done = true;
                    SaveTrackedPositions();
                    Print("✓ BREAK-EVEN gesetzt (", reason, "): Ticket ", g_trackedPositions[posIndex].ticket);
                    
                    SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "breakeven_set", true,
                                           g_trackedPositions[posIndex].ticket,
                                           StringFormat("Break-even set for SELL (%s): %.5f", reason, request.sl),
                                           "", 0, 0, 0, 0, 0, 0, symbol);
                }
            }
            else
            {
                g_trackedPositions[posIndex].break_even_done = true;
                SaveTrackedPositions();
            }
        }
    }
}

//| Close or delete position                                       |
void CloseOrDeletePosition(int posIndex)
{
    if(posIndex < 0 || posIndex >= ArraySize(g_trackedPositions))
        return;
    
    string symbol = g_trackedPositions[posIndex].symbol;
    
    if(g_trackedPositions[posIndex].is_pending)
    {
        if(OrderSelect(g_trackedPositions[posIndex].ticket))
        {
            if(symbol == "") symbol = OrderGetString(ORDER_SYMBOL);
            ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            double volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
            
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_REMOVE;
            request.order = g_trackedPositions[posIndex].ticket;
            
            if(OrderSend(request, result))
            {
                Print("✓ Pending Order gelöscht (CANCELLED): Ticket ", g_trackedPositions[posIndex].ticket);
                
                string orderTypeStr = ConvertOrderTypeToN8nFormat(EnumToString(orderType));
                
                SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "cancelled", true,
                                       g_trackedPositions[posIndex].ticket,
                                       StringFormat("Pending order cancelled: %s %.3f lots", orderTypeStr, volume),
                                       orderTypeStr, volume, 0, 0, 0, 0, 0, symbol);
                
                for(int j = posIndex; j < ArraySize(g_trackedPositions) - 1; j++)
                {
                    g_trackedPositions[j] = g_trackedPositions[j + 1];
                }
                ArrayResize(g_trackedPositions, ArraySize(g_trackedPositions) - 1);
                SaveTrackedPositions();
            }
        }
        else
        {
            for(int j = posIndex; j < ArraySize(g_trackedPositions) - 1; j++)
            {
                g_trackedPositions[j] = g_trackedPositions[j + 1];
            }
            ArrayResize(g_trackedPositions, ArraySize(g_trackedPositions) - 1);
            SaveTrackedPositions();
        }
    }
    else
    {
        if(PositionSelectByTicket(g_trackedPositions[posIndex].ticket))
        {
            if(symbol == "") symbol = PositionGetString(POSITION_SYMBOL);
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double profit = PositionGetDouble(POSITION_PROFIT);
            
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_DEAL;
            request.position = g_trackedPositions[posIndex].ticket;
            request.symbol = symbol;
            request.volume = volume;
            request.deviation = 10;
            request.magic = InpMagicNumber;
            request.type_filling = GetSymbolFillingMode(symbol);
            
            if(posType == POSITION_TYPE_BUY)
            {
                request.type = ORDER_TYPE_SELL;
                request.price = SymbolInfoDouble(request.symbol, SYMBOL_BID);
            }
            else
            {
                request.type = ORDER_TYPE_BUY;
                request.price = SymbolInfoDouble(request.symbol, SYMBOL_ASK);
            }
            
            if(OrderSend(request, result))
            {
                Print("✓ Position geschlossen (CANCELLED): Ticket ", g_trackedPositions[posIndex].ticket);
                
                SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "position_closed", true,
                                       g_trackedPositions[posIndex].ticket,
                                       StringFormat("Position closed by API: %.3f lots @ %.5f", volume, request.price),
                                       "position_closed", volume, 0, 0, 0, 0, profit, symbol);
                
                for(int j = posIndex; j < ArraySize(g_trackedPositions) - 1; j++)
                {
                    g_trackedPositions[j] = g_trackedPositions[j + 1];
                }
                ArrayResize(g_trackedPositions, ArraySize(g_trackedPositions) - 1);
                SaveTrackedPositions();
            }
            else
            {
                request.deviation = 50;
                
                if(OrderSend(request, result))
                {
                    Print("✓ Position geschlossen (CANCELLED, Retry): Ticket ", g_trackedPositions[posIndex].ticket);
                    
                    SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "position_closed", true,
                                           g_trackedPositions[posIndex].ticket,
                                           StringFormat("Position closed by API (retry): %.3f lots @ %.5f", volume, request.price),
                                           "position_closed", volume, 0, 0, 0, 0, profit, symbol);
                    
                    for(int j = posIndex; j < ArraySize(g_trackedPositions) - 1; j++)
                    {
                        g_trackedPositions[j] = g_trackedPositions[j + 1];
                    }
                    ArrayResize(g_trackedPositions, ArraySize(g_trackedPositions) - 1);
                    SaveTrackedPositions();
                }
            }
        }
        else
        {
            for(int j = posIndex; j < ArraySize(g_trackedPositions) - 1; j++)
            {
                g_trackedPositions[j] = g_trackedPositions[j + 1];
            }
            ArrayResize(g_trackedPositions, ArraySize(g_trackedPositions) - 1);
            SaveTrackedPositions();
        }
    }
}

//| Check break even trigger                                       |
void CheckBreakEvenTrigger(int posIndex)
{
    if(posIndex < 0 || posIndex >= ArraySize(g_trackedPositions))
        return;
    
    if(g_trackedPositions[posIndex].break_even_done)
        return;
    
    if(g_trackedPositions[posIndex].is_pending)
        return;
    
    if(!g_trackedPositions[posIndex].be_trigger_active || g_trackedPositions[posIndex].be_trigger_price == 0)
        return;
    
    if(PositionSelectByTicket(g_trackedPositions[posIndex].ticket))
    {
        string symbol = PositionGetString(POSITION_SYMBOL);
        double currentBid = SymbolInfoDouble(symbol, SYMBOL_BID);
        double currentAsk = SymbolInfoDouble(symbol, SYMBOL_ASK);
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        
        double beTrigger = g_trackedPositions[posIndex].be_trigger_price;
        bool triggerBreakEven = false;
        
        if(posType == POSITION_TYPE_BUY)
        {
            if(currentBid >= beTrigger)
            {
                triggerBreakEven = true;
                Print("✅ BE-TRIGGER ERREICHT (BUY): ", g_trackedPositions[posIndex].signal_id,
                      " | Ticket ", g_trackedPositions[posIndex].ticket,
                      " | Bid: ", currentBid, " >= Trigger: ", beTrigger);
            }
        }
        else if(posType == POSITION_TYPE_SELL)
        {
            if(currentAsk <= beTrigger)
            {
                triggerBreakEven = true;
                Print("✅ BE-TRIGGER ERREICHT (SELL): ", g_trackedPositions[posIndex].signal_id,
                      " | Ticket ", g_trackedPositions[posIndex].ticket,
                      " | Ask: ", currentAsk, " <= Trigger: ", beTrigger);
            }
        }
        
        if(triggerBreakEven)
        {
            ExecuteBreakEven(posIndex, "automatic");
        }
    }
}

//| Analyze position close reason from history                     |
string AnalyzePositionCloseReason(ulong ticket, bool isPending, double entryPrice = 0)
{
    if(isPending)
    {
        if(HistoryOrderSelect(ticket))
        {
            int orderState = (int)HistoryOrderGetInteger(ticket, ORDER_STATE);
            int orderReason = (int)HistoryOrderGetInteger(ticket, ORDER_REASON);
            long orderMagic = HistoryOrderGetInteger(ticket, ORDER_MAGIC);
            
            if(InpDeliveryDebugMode)
            {
                Print("DEBUG Pending Order Analysis:");
                Print("  Ticket: ", ticket);
                Print("  State: ", orderState);
                Print("  Reason: ", orderReason);
                Print("  Magic: ", orderMagic);
            }
            
            if(orderState == ORDER_STATE_FILLED)
                return "triggered";
            
            if(orderState == ORDER_STATE_EXPIRED)
                return "expired";
            
            if(orderState == ORDER_STATE_CANCELED || orderState == ORDER_STATE_REJECTED)
            {
                if(orderReason == ORDER_REASON_EXPERT)
                {
                    if(WasDeletedByEA(ticket))
                    {
                        if(InpDeliveryDebugMode)
                            Print("DEBUG: Confirmed EA deletion");
                        return "ea_deleted";
                    }
                    else
                    {
                        if(InpDeliveryDebugMode)
                            Print("DEBUG: MT5 says EXPERT but EA didn't delete it → manually_deleted");
                        return "manually_deleted";
                    }
                }
                
                if(orderReason == ORDER_REASON_CLIENT || 
                   orderReason == ORDER_REASON_MOBILE || 
                   orderReason == ORDER_REASON_WEB)
                {
                    return "manually_deleted";
                }
                
                if(orderState == ORDER_STATE_CANCELED)
                {
                    return "manually_deleted";
                }
                
                return "deleted";
            }
        }
        
        return "disappeared";
    }
    else
    {
        HistorySelect(0, TimeCurrent());
        
        for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
        {
            ulong dealTicket = HistoryDealGetTicket(i);
            if(dealTicket > 0)
            {
                long dealPosition = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
                
                if(dealPosition == (long)ticket)
                {
                    int dealEntry = (int)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                    int dealReason = (int)HistoryDealGetInteger(dealTicket, DEAL_REASON);
                    double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                    string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
                    double closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                    
                    if(dealEntry == DEAL_ENTRY_OUT)
                    {
                        if(entryPrice > 0 && MathAbs(closePrice - entryPrice) < SymbolInfoDouble(HistoryDealGetString(dealTicket, DEAL_SYMBOL), SYMBOL_POINT) * 10)
                        {
                            if(dealReason == DEAL_REASON_SL)
                                return "breakeven_hit";
                        }
                        
                        if(StringFind(dealComment, "sl") >= 0 || StringFind(dealComment, "stop loss") >= 0)
                            return "sl_hit";
                        
                        if(StringFind(dealComment, "tp") >= 0 || StringFind(dealComment, "take profit") >= 0)
                            return "tp_hit";
                        
                        if(dealReason == DEAL_REASON_CLIENT)
                            return "manually_closed";
                        else if(dealReason == DEAL_REASON_EXPERT)
                            return "ea_closed";
                        else if(dealReason == DEAL_REASON_SL)
                            return "sl_hit";
                        else if(dealReason == DEAL_REASON_TP)
                            return "tp_hit";
                        else if(dealReason == DEAL_REASON_SO)
                            return "margin_call";
                        
                        if(dealProfit > 0)
                            return "closed_profit";
                        else if(dealProfit < 0)
                            return "closed_loss";
                        else
                            return "closed_breakeven";
                    }
                }
            }
        }
        
        return "disappeared";
    }
}

//| Get human-readable close reason message                        |
string GetCloseReasonMessage(string reason, bool isPending, double profit = 0)
{
    if(isPending)
    {
        if(reason == "triggered")
            return "Pending order was triggered and became a position";
        else if(reason == "manually_deleted")
            return "Pending order was manually deleted by trader";
        else if(reason == "ea_deleted")
            return "Pending order was deleted by EA";
        else if(reason == "expired")
            return "Pending order expired";
        else if(reason == "deleted")
            return "Pending order was deleted";
        else
            return "Pending order no longer exists";
    }
    else
    {
        if(reason == "sl_hit")
            return StringFormat("Position closed by Stop Loss (%.2f)", profit);
        else if(reason == "tp_hit")
            return StringFormat("Position closed by Take Profit (%.2f)", profit);
        else if(reason == "breakeven_hit")
            return StringFormat("Position closed at Break-Even (%.2f)", profit);
        else if(reason == "manually_closed")
            return StringFormat("Position manually closed by trader (%.2f)", profit);
        else if(reason == "ea_closed")
            return StringFormat("Position closed by EA (%.2f)", profit);
        else if(reason == "margin_call")
            return StringFormat("Position closed by margin call (%.2f)", profit);
        else if(reason == "closed_profit")
            return StringFormat("Position closed with profit (%.2f)", profit);
        else if(reason == "closed_loss")
            return StringFormat("Position closed with loss (%.2f)", profit);
        else if(reason == "closed_breakeven")
            return StringFormat("Position closed at breakeven (%.2f)", profit);
        else
            return StringFormat("Position closed (%.2f)", profit);
    }
}

//| Clean up closed positions with detailed tracking               |
void CleanupTrackedPositions()
{
    for(int i = ArraySize(g_trackedPositions) - 1; i >= 0; i--)
    {
        bool stillExists = false;
        
        if(g_trackedPositions[i].is_pending)
        {
            if(OrderSelect(g_trackedPositions[i].ticket))
                stillExists = true;
        }
        else
        {
            if(PositionSelectByTicket(g_trackedPositions[i].ticket))
                stillExists = true;
        }
        
        if(!stillExists)
        {
            if(InpDeliveryDebugMode)
                Print("DEBUG: Position/Order ", g_trackedPositions[i].ticket, " nicht mehr vorhanden - analysiere Grund...");
            
            string closeReason = AnalyzePositionCloseReason(g_trackedPositions[i].ticket, 
                                                            g_trackedPositions[i].is_pending,
                                                            g_trackedPositions[i].entry_price);
            
            if(InpDeliveryDebugMode)
                Print("DEBUG: Close Reason = ", closeReason);
            
            // CRITICAL FIX: If pending order was triggered, convert to position tracking
            if(closeReason == "triggered" && g_trackedPositions[i].is_pending)
            {
                // Check if position exists with same ticket
                if(PositionSelectByTicket(g_trackedPositions[i].ticket))
                {
                    Print("✅ PENDING ORDER TRIGGERED → POSITION: ", g_trackedPositions[i].signal_id, 
                          " | Ticket ", g_trackedPositions[i].ticket);
                    Print("   Converting to position tracking...");
                    
                    // Update tracking: pending → active position
                    g_trackedPositions[i].is_pending = false;
                    
                    // Update entry price to actual fill price
                    double actualEntry = PositionGetDouble(POSITION_PRICE_OPEN);
                    if(actualEntry > 0)
                        g_trackedPositions[i].entry_price = actualEntry;
                    
                    // Send API notification
                    string symbol = PositionGetString(POSITION_SYMBOL);
                    double lots = PositionGetDouble(POSITION_VOLUME);
                    int posType = (int)PositionGetInteger(POSITION_TYPE);
                    string orderTypeStr = (posType == POSITION_TYPE_BUY) ? "buy" : "sell";
                    
                    SendSignalDeliveryStatus(g_trackedPositions[i].signal_id, 
                                           "triggered",
                                           true,
                                           g_trackedPositions[i].ticket,
                                           "Pending order was triggered and became a position",
                                           orderTypeStr,
                                           lots,
                                           0, 0, 0, 0,
                                           0,
                                           symbol);
                    
                    SaveTrackedPositions();
                    
                    Print("✅ Position now tracked as active - BE commands will work!");
                    
                    // Continue tracking - DON'T remove!
                    continue;
                }
            }
            
            double profit = 0;
            string orderTypeStr = "";
            double lots = 0;
            string symbol = g_trackedPositions[i].symbol;
            
            if(!g_trackedPositions[i].is_pending)
            {
                HistorySelect(0, TimeCurrent());
                
                for(int j = HistoryDealsTotal() - 1; j >= 0; j--)
                {
                    ulong dealTicket = HistoryDealGetTicket(j);
                    if(dealTicket > 0)
                    {
                        long dealPosition = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
                        
                        if(dealPosition == (long)g_trackedPositions[i].ticket)
                        {
                            int dealEntry = (int)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                            
                            if(dealEntry == DEAL_ENTRY_OUT)
                            {
                                profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                                lots = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
                                if(symbol == "") symbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
                                
                                int dealType = (int)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
                                orderTypeStr = (dealType == DEAL_TYPE_BUY) ? "buy" : "sell";
                                break;
                            }
                        }
                    }
                }
            }
            else
            {
                HistorySelect(0, TimeCurrent());
                
                if(HistoryOrderSelect(g_trackedPositions[i].ticket))
                {
                    lots = HistoryOrderGetDouble(g_trackedPositions[i].ticket, ORDER_VOLUME_CURRENT);
                    if(symbol == "") symbol = HistoryOrderGetString(g_trackedPositions[i].ticket, ORDER_SYMBOL);
                    
                    int orderType = (int)HistoryOrderGetInteger(g_trackedPositions[i].ticket, ORDER_TYPE);
                    
                    switch(orderType)
                    {
                        case ORDER_TYPE_BUY_LIMIT: orderTypeStr = "limit buy"; break;
                        case ORDER_TYPE_SELL_LIMIT: orderTypeStr = "limit sell"; break;
                        case ORDER_TYPE_BUY_STOP: orderTypeStr = "stop buy"; break;
                        case ORDER_TYPE_SELL_STOP: orderTypeStr = "stop sell"; break;
                        default: orderTypeStr = "pending"; break;
                    }
                }
                else
                {
                    lots = 0.01;
                    orderTypeStr = "pending";
                }
            }
            
            string message = GetCloseReasonMessage(closeReason, g_trackedPositions[i].is_pending, profit);
            
            if(g_trackedPositions[i].is_pending)
            {
                Print("📭 PENDING ORDER ", closeReason == "manually_deleted" ? "MANUELL GELÖSCHT" : "ENTFERNT", ": ", 
                      g_trackedPositions[i].signal_id, " | Ticket ", g_trackedPositions[i].ticket);
            }
            else
            {
                string profitStr = (profit > 0) ? "+" + DoubleToString(profit, 2) : DoubleToString(profit, 2);
                Print("📊 POSITION GESCHLOSSEN (", closeReason, "): ", 
                      g_trackedPositions[i].signal_id, " | Ticket ", g_trackedPositions[i].ticket, 
                      " | P/L: ", profitStr);
            }
            
            if(closeReason == "sl_hit") g_closeStats.slHit++;
            else if(closeReason == "tp_hit") g_closeStats.tpHit++;
            else if(closeReason == "breakeven_hit") g_closeStats.breakEvenHit++;
            else if(closeReason == "manually_closed") g_closeStats.manuallyClosed++;
            else if(closeReason == "ea_closed") g_closeStats.eaClosed++;
            else if(closeReason == "margin_call") g_closeStats.marginCall++;
            else if(closeReason == "triggered") g_closeStats.pendingTriggered++;
            else if(closeReason == "manually_deleted") g_closeStats.pendingManuallyDeleted++;
            else if(closeReason == "expired") g_closeStats.pendingExpired++;
            else g_closeStats.other++;
            
            Print("📤 API NOTIFICATION: ", closeReason, " | Signal: ", g_trackedPositions[i].signal_id, 
                  " | Ticket: ", g_trackedPositions[i].ticket);
            
            bool apiSuccess = SendSignalDeliveryStatus(g_trackedPositions[i].signal_id, 
                                   closeReason,
                                   true,
                                   g_trackedPositions[i].ticket,
                                   message,
                                   orderTypeStr,
                                   lots,
                                   0, 0, 0, 0,
                                   profit,
                                   symbol);
            
            if(apiSuccess)
                Print("✅ API Notification gesendet");
            else
                Print("❌ API Notification FEHLGESCHLAGEN");
            
            for(int j = i; j < ArraySize(g_trackedPositions) - 1; j++)
            {
                g_trackedPositions[j] = g_trackedPositions[j + 1];
            }
            ArrayResize(g_trackedPositions, ArraySize(g_trackedPositions) - 1);
        }
    }
}

//| Save tracked positions                                         |
void SaveTrackedPositions()
{
    string filename = "SignalReceiverEA_positions.txt";
    int fileHandle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI);
    
    if(fileHandle != INVALID_HANDLE)
    {
        for(int i = 0; i < ArraySize(g_trackedPositions); i++)
        {
            string line = g_trackedPositions[i].signal_id + "|" +
                         IntegerToString(g_trackedPositions[i].ticket) + "|" +
                         DoubleToString(g_trackedPositions[i].original_sl) + "|" +
                         DoubleToString(g_trackedPositions[i].original_tp) + "|" +
                         DoubleToString(g_trackedPositions[i].break_even_price) + "|" +
                         (g_trackedPositions[i].break_even_done ? "1" : "0") + "|" +
                         DoubleToString(g_trackedPositions[i].last_api_sl) + "|" +
                         DoubleToString(g_trackedPositions[i].last_api_tp) + "|" +
                         (g_trackedPositions[i].is_pending ? "1" : "0") + "|" +
                         DoubleToString(g_trackedPositions[i].original_risk) + "|" +
                         DoubleToString(g_trackedPositions[i].last_blocked_sl) + "|" +
                         g_trackedPositions[i].symbol + "|" +
                         DoubleToString(g_trackedPositions[i].entry_price) + "|" +
                         DoubleToString(g_trackedPositions[i].be_trigger_price) + "|" +
                         (g_trackedPositions[i].be_trigger_active ? "1" : "0") + "|" +
                         DoubleToString(g_trackedPositions[i].tp1) + "|" +
                         DoubleToString(g_trackedPositions[i].tp2) + "|" +
                         (g_trackedPositions[i].tp1_done ? "1" : "0") + "|" +
                         (g_trackedPositions[i].has_dual_tp ? "1" : "0") + "|" +
                         IntegerToString(g_trackedPositions[i].order_type);
            
            FileWriteString(fileHandle, line + "\n");
        }
        FileClose(fileHandle);
    }
}

//| Load tracked positions                                         |
void LoadTrackedPositions()
{
    string filename = "SignalReceiverEA_positions.txt";
    
    if(!FileIsExist(filename))
        return;
    
    int fileHandle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_ANSI);
    
    if(fileHandle != INVALID_HANDLE)
    {
        ArrayResize(g_trackedPositions, 0);
        
        while(!FileIsEnding(fileHandle))
        {
            string line = FileReadString(fileHandle);
            StringTrimRight(line);
            StringTrimLeft(line);
            
            if(line != "")
            {
                string parts[];
                int count = StringSplit(line, '|', parts);
                
                if(count >= 6)
                {
                    int size = ArraySize(g_trackedPositions);
                    ArrayResize(g_trackedPositions, size + 1);
                    
                    g_trackedPositions[size].signal_id = parts[0];
                    g_trackedPositions[size].ticket = StringToInteger(parts[1]);
                    g_trackedPositions[size].original_sl = StringToDouble(parts[2]);
                    g_trackedPositions[size].original_tp = StringToDouble(parts[3]);
                    g_trackedPositions[size].break_even_price = StringToDouble(parts[4]);
                    g_trackedPositions[size].break_even_done = (parts[5] == "1");
                    
                    if(count > 6) g_trackedPositions[size].last_api_sl = StringToDouble(parts[6]);
                    else g_trackedPositions[size].last_api_sl = g_trackedPositions[size].original_sl;
                    
                    if(count > 7) g_trackedPositions[size].last_api_tp = StringToDouble(parts[7]);
                    else g_trackedPositions[size].last_api_tp = g_trackedPositions[size].original_tp;
                    
                    if(count > 8) g_trackedPositions[size].is_pending = (parts[8] == "1");
                    else g_trackedPositions[size].is_pending = false;
                    
                    if(count > 9) g_trackedPositions[size].original_risk = StringToDouble(parts[9]);
                    else g_trackedPositions[size].original_risk = 1.0;
                    
                    if(count > 10) g_trackedPositions[size].last_blocked_sl = StringToDouble(parts[10]);
                    else g_trackedPositions[size].last_blocked_sl = 0;
                    
                    if(count > 11) g_trackedPositions[size].symbol = parts[11];
                    else g_trackedPositions[size].symbol = "";
                    
                    if(count > 12) g_trackedPositions[size].entry_price = StringToDouble(parts[12]);
                    else g_trackedPositions[size].entry_price = 0;
                    
                    if(count > 13) g_trackedPositions[size].be_trigger_price = StringToDouble(parts[13]);
                    else g_trackedPositions[size].be_trigger_price = 0;
                    
                    if(count > 14) g_trackedPositions[size].be_trigger_active = (parts[14] == "1");
                    else g_trackedPositions[size].be_trigger_active = false;
                    
                    // v10: Load dual TP fields
                    if(count > 15) g_trackedPositions[size].tp1 = StringToDouble(parts[15]);
                    else g_trackedPositions[size].tp1 = g_trackedPositions[size].original_tp;
                    
                    if(count > 16) g_trackedPositions[size].tp2 = StringToDouble(parts[16]);
                    else g_trackedPositions[size].tp2 = g_trackedPositions[size].original_tp;
                    
                    if(count > 17) g_trackedPositions[size].tp1_done = (parts[17] == "1");
                    else g_trackedPositions[size].tp1_done = false;
                    
                    if(count > 18) g_trackedPositions[size].has_dual_tp = (parts[18] == "1");
                    else g_trackedPositions[size].has_dual_tp = false;
                    
                    if(count > 19) g_trackedPositions[size].order_type = (ENUM_ORDER_TYPE)StringToInteger(parts[19]);
                    else g_trackedPositions[size].order_type = ORDER_TYPE_BUY;
                    
                    g_trackedPositions[size].last_update = TimeCurrent();
                }
            }
        }
        
        FileClose(fileHandle);
        
        if(InpDebugMode && ArraySize(g_trackedPositions) > 0)
            Print("✓ ", ArraySize(g_trackedPositions), " Position(en) aus Datei geladen");
    }
}

// [REST OF THE CODE CONTINUES IN NEXT MESSAGE DUE TO LENGTH...]
//| Enhanced signal splitting                                      |
int SplitSignalsEnhanced(string json, string &signals[])
{
    int count = 0;
    int braceCount = 0;
    int startPos = 0;
    bool inString = false;
    bool escapeNext = false;
    
    ArrayResize(signals, 0);
    
    while(startPos < StringLen(json) && StringGetCharacter(json, startPos) != '{')
        startPos++;
    
    if(startPos >= StringLen(json))
        return 0;
    
    for(int i = startPos; i < StringLen(json); i++)
    {
        ushort charCode = StringGetCharacter(json, i);
        
        if(escapeNext)
        {
            escapeNext = false;
            continue;
        }
        
        if(charCode == '\\' && inString)
        {
            escapeNext = true;
            continue;
        }
        
        if(charCode == '"')
        {
            inString = !inString;
            continue;
        }
        
        if(!inString)
        {
            if(charCode == '{')
            {
                if(braceCount == 0)
                    startPos = i;
                braceCount++;
            }
            else if(charCode == '}')
            {
                braceCount--;
                if(braceCount == 0)
                {
                    count++;
                    ArrayResize(signals, count);
                    string signal = StringSubstr(json, startPos, i - startPos + 1);
                    signals[count - 1] = signal;
                    
                    startPos = i + 1;
                    while(startPos < StringLen(json) && StringGetCharacter(json, startPos) != '{')
                        startPos++;
                    
                    i = startPos - 1;
                }
            }
        }
    }
    
    return count;
}

//| Extract signals array from wrapper                            |
string ExtractSignalsArray(string wrapperJson)
{
    string searchPattern = "\"signals\":";
    int signalsPos = StringFind(wrapperJson, searchPattern);
    
    if(signalsPos == -1)
        return "";
    
    int arrayStart = signalsPos + StringLen(searchPattern);
    
    while(arrayStart < StringLen(wrapperJson) && 
          (StringGetCharacter(wrapperJson, arrayStart) == ' ' || 
           StringGetCharacter(wrapperJson, arrayStart) == '\t' ||
           StringGetCharacter(wrapperJson, arrayStart) == '\n'))
        arrayStart++;
    
    if(arrayStart >= StringLen(wrapperJson) || StringGetCharacter(wrapperJson, arrayStart) != '[')
        return "";
    
    int bracketCount = 0;
    int arrayEnd = arrayStart;
    bool inString = false;
    bool escapeNext = false;
    
    for(int i = arrayStart; i < StringLen(wrapperJson); i++)
    {
        ushort ch = StringGetCharacter(wrapperJson, i);
        
        if(escapeNext)
        {
            escapeNext = false;
            continue;
        }
        
        if(ch == '\\' && inString)
        {
            escapeNext = true;
            continue;
        }
        
        if(ch == '"')
        {
            inString = !inString;
            continue;
        }
        
        if(!inString)
        {
            if(ch == '[')
                bracketCount++;
            else if(ch == ']')
            {
                bracketCount--;
                if(bracketCount == 0)
                {
                    arrayEnd = i;
                    break;
                }
            }
        }
    }
    
    if(bracketCount != 0)
        return "";
    
    string signalsArray = StringSubstr(wrapperJson, arrayStart, arrayEnd - arrayStart + 1);
    return signalsArray;
}

//| Process signals array                                          |
void ProcessSignalsArray(string signalsArrayJson, int expectedCount)
{
    if(StringGetCharacter(signalsArrayJson, 0) == '[')
        signalsArrayJson = StringSubstr(signalsArrayJson, 1, StringLen(signalsArrayJson) - 2);
    
    if(StringLen(signalsArrayJson) == 0)
        return;
    
    string signals[];
    int signalCount = SplitSignalsEnhanced(signalsArrayJson, signals);
    
    g_multiSignalStats.totalSignalsReceived += signalCount;
    
    if(signalCount == 0)
        return;
    
    int processedCount = 0;
    int skippedCount = 0;
    
    for(int i = 0; i < signalCount; i++)
    {
        string signalId = GetJsonValue(signals[i], "id");
        
        if(signalId != "" && IsSignalExecuted(signalId))
        {
            skippedCount++;
            g_multiSignalStats.totalSignalsSkipped++;
            continue;
        }
        
        ProcessSingleSignal(signals[i]);
        processedCount++;
        g_multiSignalStats.totalSignalsProcessed++;
        
        if(i < signalCount - 1)
            Sleep(100);
    }
    
    if(processedCount > 0)
        Print("✓ ", processedCount, " neue Signal(e) verarbeitet", (skippedCount > 0 ? StringFormat(" (%d übersprungen)", skippedCount) : ""));
}

//| Process single signal                                          |
void ProcessSingleSignal(string signalJson)
{
    string id = GetJsonValue(signalJson, "id");
    
    if(id == "")
    {
        if(InpDebugMode)
            Print("❌ Signal ohne ID - überspringe");
        return;
    }
    
    if(IsSignalExecuted(id))
    {
        if(InpDebugMode)
            Print("⏭ Signal bereits verarbeitet: ", id);
        
        g_multiSignalStats.totalSignalsSkipped++;
        return;
    }
    
    Print("=====================================");
    Print("🆕 NEUES SIGNAL: ", id);
    Print("=====================================");
    
    g_multiSignalStats.newSignalsThisSession++;
    
    string rawSymbol = GetJsonValue(signalJson, "symbol");
    string symbol = MapSymbol(rawSymbol);
    
    string direction = GetJsonValue(signalJson, "direction");
    string entryType = GetJsonValue(signalJson, "entry_type");
    double entryPrice = StringToDouble(GetJsonValue(signalJson, "entry_price"));
    double sl = StringToDouble(GetJsonValue(signalJson, "sl"));
    
    // v10: Parse TP1 and TP2 with backward compatibility
    double tp1 = StringToDouble(GetJsonValue(signalJson, "tp1"));
    double tp2 = StringToDouble(GetJsonValue(signalJson, "tp2"));
    
    // Backward compatibility: if only "tp" exists, use it as tp1
    if(tp1 == 0)
    {
        string tpStr = GetJsonValue(signalJson, "tp");
        if(tpStr != "")
            tp1 = StringToDouble(tpStr);
    }
    
    // If tp2 is not provided, use tp1 (single TP mode)
    if(tp2 == 0 && tp1 > 0)
        tp2 = tp1;
    
    int lowRisk = (int)StringToInteger(GetJsonValue(signalJson, "low_risk"));
    string riskStr = GetJsonValue(signalJson, "risk");
    
    string bePriceStr = GetJsonValue(signalJson, "be_price");
    double beTriggerPrice = 0;
    bool beTriggerActive = false;
    
    if(bePriceStr != "" && bePriceStr != "null" && bePriceStr != "NULL" && bePriceStr != "0")
    {
        beTriggerPrice = StringToDouble(bePriceStr);
        if(beTriggerPrice > 0)
            beTriggerActive = true;
    }
    
    string breakEvenStr = GetJsonValue(signalJson, "break_even");
    double breakEvenPrice = 0;
    
    if(breakEvenStr != "" && breakEvenStr != "null" && breakEvenStr != "NULL" && breakEvenStr != "0")
    {
        breakEvenPrice = StringToDouble(breakEvenStr);
    }
    
    if(id == "" || symbol == "" || direction == "")
    {
        Print("❌ Pflichtfelder fehlen");
        SendSignalDeliveryStatus(id, "missing_fields", false, 0, "Required fields missing", "", 0, 0, 0, 0, 0, 0, symbol);
        return;
    }
    
    if(riskStr == "" || riskStr == "0")
    {
        Print("❌ Kein Risiko definiert");
        SendSignalDeliveryStatus(id, "missing_risk", false, 0, "No risk provided", "", 0, 0, 0, 0, 0, 0, symbol);
        return;
    }
    
    double risk = StringToDouble(riskStr);
    
    if(risk <= 0 || risk > 100)
    {
        Print("❌ Ungültiger Risiko-Wert: ", risk, "%");
        SendSignalDeliveryStatus(id, "invalid_risk", false, 0,
                               StringFormat("Invalid risk: %.2f%%", risk), "", 0, 0, 0, 0, 0, 0, symbol);
        return;
    }
    
    Print("  Raw Symbol: ", rawSymbol);
    Print("  Mapped Symbol: ", symbol);
    Print("  Richtung: ", direction);
    Print("  Entry: ", entryType, " @ ", entryPrice);
    Print("  API-Risiko: ", DoubleToString(risk, 2), "%");
    if(lowRisk == 1)
        Print("  Low-Risk Modus: AKTIV");
    // v10: Display TP1/TP2 info
    if(tp1 > 0 && tp2 > 0 && MathAbs(tp1 - tp2) > 0.00001)
    {
        Print("  TP1: ", tp1, " (Partial Close)");
        Print("  TP2: ", tp2, " (Full Close)");
    }
    else if(tp1 > 0)
    {
        Print("  TP: ", tp1, " (Single TP mode)");
    }
    if(breakEvenPrice > 0)
        Print("  Break-Even (legacy): ", breakEvenPrice);
    if(beTriggerActive)
        Print("  BE-Trigger (auto): ", beTriggerPrice);
    Print("=====================================");
    
    ExecuteSignalWithBreakEven(id, symbol, direction, entryType, entryPrice, sl, tp1, lowRisk, risk, breakEvenPrice, beTriggerPrice, beTriggerActive, tp2);
}

//| OPTIMIZED v10: Execute signal with dual TP support          |
bool ExecuteSignalWithBreakEven(string id, string symbol, string direction, string entryType, 
                                double entryPrice, double sl, double tp, int lowRisk, 
                                double riskPercent, double breakEvenPrice,
                                double beTriggerPrice = 0, bool beTriggerActive = false, double tp2 = 0)
{
    AddExecutedSignal(id);
    
    string actualSymbol = symbol;
    
    if(actualSymbol == "" || !SymbolSelect(actualSymbol, true))
    {
        Print("❌ Symbol nicht verfügbar beim Broker: ", symbol);
        SendSignalDeliveryStatus(id, "symbol_not_found", false, 0,
                               StringFormat("Symbol not available at broker: %s", symbol), "", 0, 0, 0, 0, 0, 0, symbol);
        return false;
    }
    
    symbol = actualSymbol;
    
    // CRITICAL FIX: Wait for quotes to load for new symbols
    // When a symbol is used for the first time, bid/ask might be 0
    // This causes false "market closed" errors
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    if(bid == 0 || ask == 0)
    {
        if(InpDebugMode)
            Print("⏳ Warte auf Quotes für neues Symbol: ", symbol);
        
        // Wait up to 5 seconds for quotes to load
        int maxWaitTime = 5000;  // 5 seconds
        int waitInterval = 100;  // 100ms
        int totalWaited = 0;
        
        while((bid == 0 || ask == 0) && totalWaited < maxWaitTime)
        {
            Sleep(waitInterval);
            totalWaited += waitInterval;
            
            bid = SymbolInfoDouble(symbol, SYMBOL_BID);
            ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
            
            if(InpDebugMode && totalWaited % 1000 == 0)
                Print("  → Warte auf Quotes... (", totalWaited/1000, "s)");
        }
        
        if(bid == 0 || ask == 0)
        {
            Print("❌ Keine Quotes für Symbol: ", symbol, " (nach ", totalWaited, "ms)");
            Print("   Bid: ", bid, " | Ask: ", ask);
            SendSignalDeliveryStatus(id, "market_closed", false, 0,
                                   StringFormat("No quotes available for symbol: %s", symbol), "", 0, 0, 0, 0, 0, 0, symbol);
            return false;
        }
        
        if(InpDebugMode)
            Print("✅ Quotes geladen nach ", totalWaited, "ms | Bid: ", bid, " | Ask: ", ask);
    }
    
    if(!IsMarketOpen(symbol))
    {
        Print("❌ Markt geschlossen für: ", symbol);
        g_closeStats.marketClosed++;
        SendSignalDeliveryStatus(id, "market_closed", false, 0,
                               StringFormat("Market closed for symbol: %s", symbol), "", 0, 0, 0, 0, 0, 0, symbol);
        return false;
    }
    
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    if(lowRisk == 1)
    {
        riskPercent = riskPercent / 2.0;
        Print("  → Low-Risk: Risiko halbiert auf ", riskPercent, "%");
    }
    
    ENUM_ORDER_TYPE orderType;
    if(direction == "buy")
    {
        if(entryType == "stop")
            orderType = ORDER_TYPE_BUY_STOP;
        else if(entryType == "limit")
            orderType = ORDER_TYPE_BUY_LIMIT;
        else
            orderType = ORDER_TYPE_BUY;
    }
    else if(direction == "sell")
    {
        if(entryType == "stop")
            orderType = ORDER_TYPE_SELL_STOP;
        else if(entryType == "limit")
            orderType = ORDER_TYPE_SELL_LIMIT;
        else
            orderType = ORDER_TYPE_SELL;
    }
    else
    {
        Print("❌ Ungültige Richtung: ", direction);
        SendSignalDeliveryStatus(id, "invalid_direction", false, 0,
                               StringFormat("Invalid direction: %s", direction), "", 0, 0, 0, 0, 0, 0, symbol);
        return false;
    }
    
    double currentBid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    if(entryType != "stop" && entryType != "limit")
    {
        if(direction == "buy")
            entryPrice = currentAsk;
        else
            entryPrice = currentBid;
    }
    
    double slDistance = MathAbs(entryPrice - sl) / point;
    
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
    double riskAmount = accountBalance * (riskPercent / 100.0);
    
    Print("========================================");
    Print("RISIKO-BERECHNUNG (v9 DIRECT - No Correction Needed)");
    Print("========================================");
    Print("  Symbol: ", symbol);
    Print("  Account Balance: ", DoubleToString(accountBalance, 2), " ", accountCurrency);
    Print("  Target Risk: ", DoubleToString(riskPercent, 2), "% (", DoubleToString(riskAmount, 2), " ", accountCurrency, ")");
    Print("  Entry Price: ", DoubleToString(entryPrice, digits));
    Print("  SL Price: ", DoubleToString(sl, digits));
    Print("  SL Distance: ", DoubleToString(slDistance, 1), " points");
    Print("========================================");
    Print("  STEP 1: DIRECT Calculation with OrderCalcProfit");
    
    // STEP 1: DIRECT lot calculation with OrderCalcProfit (v9 NEW!)
    double initialLotSize = CalculateLotSize(symbol, riskPercent, slDistance, tickValue, tickSize, point, entryPrice, orderType);
    initialLotSize = NormalizeLotSize(initialLotSize, minLot, maxLot, lotStep);
    
    Print("  Calculated Lot: ", DoubleToString(initialLotSize, 3));
    double initialLoss = CalculateActualLoss(symbol, initialLotSize, slDistance, entryPrice, orderType);
    double initialRisk = (initialLoss / accountBalance) * 100.0;
    Print("  Actual Risk: ", DoubleToString(initialRisk, 2), "% (", DoubleToString(initialLoss, 2), " ", accountCurrency, ")");
    Print("  Initial Deviation: ", DoubleToString(initialRisk - riskPercent, 2), "%");
    Print("  Initial Utilization: ", DoubleToString((initialRisk / riskPercent) * 100.0, 2), "%");
    Print("========================================");
    
    // STEP 2: Fine-tuning optimization (v9 - only if needed)
    double actualRiskPercent = initialRisk;
    double actualLoss = initialLoss;
    int iterations = 0;
    double optimizedLotSize = initialLotSize;
    
    // CRITICAL: If initial lot is already minLot AND risk is too high, skip optimization!
    if(initialLotSize <= minLot && initialLoss > riskAmount)
    {
        Print("  ⚠ SKIP OPTIMIZATION: Already at minLot (", DoubleToString(minLot, 3), ") and risk too high!");
        Print("  Initial Risk: ", DoubleToString(initialRisk, 2), "% > Target: ", DoubleToString(riskPercent, 2), "%");
        Print("  Account too small for this trade - cannot reduce further!");
        Print("========================================");
        
        // Skip optimization, go directly to CRITICAL CHECK which will abort
        actualRiskPercent = initialRisk;
        actualLoss = initialLoss;
        optimizedLotSize = initialLotSize;
    }
    // Only run optimization if initial calculation is not already optimal
    else if((initialLoss > riskAmount || MathAbs(initialLoss - riskAmount) > (accountBalance * InpRiskTolerance / 100.0)) && InpEnableRiskOptimization)
    {
        Print("  → Running fine-tuning optimization...");
        optimizedLotSize = OptimizeLotSizeWithValidation(symbol, initialLotSize, slDistance, 
                                                         riskPercent, actualRiskPercent, 
                                                         actualLoss, iterations,
                                                         entryPrice, orderType);
        
        Print("========================================");
        Print("  STEP 2: Fine-Tuning Result (v9)");
        Print("  Optimized Lot: ", DoubleToString(optimizedLotSize, 3));
        Print("  Final Risk: ", DoubleToString(actualRiskPercent, 2), "% (", DoubleToString(actualLoss, 2), " ", accountCurrency, ")");
        Print("  Target Risk: ", DoubleToString(riskPercent, 2), "% (", DoubleToString(riskAmount, 2), " ", accountCurrency, ")");
        Print("  Final Deviation: ", DoubleToString(actualRiskPercent - riskPercent, 2), "%");
        Print("  Final Utilization: ", DoubleToString((actualRiskPercent / riskPercent) * 100.0, 2), "%");
        Print("  Iterations: ", iterations);
        
        if(optimizedLotSize > initialLotSize)
        {
            double gainedRisk = actualRiskPercent - initialRisk;
            double gainedAmount = actualLoss - initialLoss;
            Print("  ✅ LOTS INCREASED! Risk Gained: +", DoubleToString(gainedRisk, 2), "% (+", DoubleToString(gainedAmount, 2), " ", accountCurrency, ") 🎉");
        }
        else if(optimizedLotSize < initialLotSize)
        {
            Print("  ⚠ LOTS DECREASED (safety correction)");
        }
        else
        {
            Print("  ℹ LOTS UNCHANGED (already optimal)");
        }
        Print("========================================");
    }
    else
    {
        Print("  ✅ STEP 1 calculation already optimal - no fine-tuning needed!");
        Print("  Deviation: ", DoubleToString(initialRisk - riskPercent, 2), "%");
        Print("  Utilization: ", DoubleToString((initialRisk / riskPercent) * 100.0, 2), "%");
        Print("========================================");
    }
    
    // ========================================
    // STEP 3: Apply Safety Margin (v10 FIX)
    // ========================================
    // Ensure actual risk NEVER exceeds target, accounting for:
    // - Wechselkurs-Schwankungen (especially JPY pairs)
    // - Swap-Gebühren (for pending orders)
    // - Spread-Änderungen
    // - Kommissionen
    
    Print("========================================");
    Print("  STEP 3: Safety Margin Validation");
    
    // Determine safety margin based on symbol type and order type
    double safetyMarginPercent = 0.5;  // Default: 0.5%
    
    if(StringFind(symbol, "JPY") >= 0)
        safetyMarginPercent = 1.0;  // JPY pairs: 1.0% (currency conversion risk)
    else if(StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0 || 
            StringFind(symbol, "XAG") >= 0 || StringFind(symbol, "SILVER") >= 0)
        safetyMarginPercent = 1.5;  // Metals: 1.5% (spread + volatility)
    else if(StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "ETH") >= 0 || 
            StringFind(symbol, "CRYPTO") >= 0 || StringFind(symbol, "XRP") >= 0 ||
            StringFind(symbol, "ADA") >= 0 || StringFind(symbol, "DOT") >= 0)
        safetyMarginPercent = 2.0;  // Crypto: 2.0% (high volatility)
    
    // Additional margin for pending orders (swap risk)
    if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_SELL_LIMIT ||
       orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_SELL_STOP)
        safetyMarginPercent += 0.5;
    
    // Calculate maximum allowed risk with safety margin
    double maxAllowedRisk = riskAmount * (1.0 - safetyMarginPercent / 100.0);
    
    Print("  Safety Margin: ", DoubleToString(safetyMarginPercent, 2), "%");
    Print("  Target Risk: ", DoubleToString(riskAmount, 2), " ", accountCurrency);
    Print("  Max Allowed: ", DoubleToString(maxAllowedRisk, 2), " ", accountCurrency);
    Print("  Calculated Risk: ", DoubleToString(actualLoss, 2), " ", accountCurrency);
    
    // Apply safety margin if needed
    if(actualLoss > maxAllowedRisk)
    {
        double originalLot = optimizedLotSize;
        double originalRisk = actualLoss;
        double originalRiskPercent = actualRiskPercent;
        
        double reductionFactor = maxAllowedRisk / actualLoss;
        optimizedLotSize = optimizedLotSize * reductionFactor;
        optimizedLotSize = NormalizeLotSize(optimizedLotSize, minLot, maxLot, lotStep);
        
        // Recalculate actual risk with reduced lot
        actualLoss = CalculateActualLoss(symbol, optimizedLotSize, slDistance, entryPrice, orderType);
        actualRiskPercent = (actualLoss / accountBalance) * 100.0;
        
        Print("  ⚠️ LOT SIZE REDUCED FOR SAFETY");
        Print("     Original Lot: ", DoubleToString(originalLot, 3));
        Print("     Reduced Lot: ", DoubleToString(optimizedLotSize, 3));
        Print("     Original Risk: ", DoubleToString(originalRiskPercent, 2), "% (", DoubleToString(originalRisk, 2), " ", accountCurrency, ")");
        Print("     New Risk: ", DoubleToString(actualRiskPercent, 2), "% (", DoubleToString(actualLoss, 2), " ", accountCurrency, ")");
        Print("     Safety Buffer: ", DoubleToString(riskAmount - actualLoss, 2), " ", accountCurrency);
    }
    else
    {
        Print("  ✅ Risk within safety margin");
        Print("     Safety Buffer: ", DoubleToString(maxAllowedRisk - actualLoss, 2), " ", accountCurrency);
    }
    Print("========================================");
    
    // CRITICAL CHECK: Never exceed target risk!
    if(actualLoss > riskAmount)
    {
        Print("❌ FATAL: Optimized lot still exceeds target risk!");
        Print("   Final Risk: ", DoubleToString(actualRiskPercent, 2), "% > Target: ", DoubleToString(riskPercent, 2), "%");
        Print("   Final Lot: ", DoubleToString(optimizedLotSize, 3));
        
        // Check if we're at minimum lot size
        if(optimizedLotSize <= minLot)
        {
            Print("   ⚠ Already at minimum lot size (", DoubleToString(minLot, 3), ") - cannot reduce further");
            Print("   Account too small for this trade!");
            
            SendSignalDeliveryStatus(id, "risk_too_small", false, 0,
                                   StringFormat("Account too small: Min lot %.3f would risk %.2f%% (target: %.2f%%)", 
                                               minLot, actualRiskPercent, riskPercent),
                                   "", optimizedLotSize, riskPercent, riskAmount,
                                   actualRiskPercent, actualLoss, 0, symbol);
        }
        else
        {
            Print("   This should never happen - aborting trade for safety");
            
            SendSignalDeliveryStatus(id, "risk_validation_failed", false, 0,
                                   StringFormat("Risk validation failed: %.2f%% > %.2f%%", actualRiskPercent, riskPercent),
                                   "", optimizedLotSize, riskPercent, riskAmount,
                                   actualRiskPercent, actualLoss, 0, symbol);
        }
        return false;
    }
    
    double lotSize = optimizedLotSize;
    
    if(lotSize == 0)
    {
        Print("❌ Losgröße konnte nicht berechnet werden");
        SendSignalDeliveryStatus(id, "lot_calculation_error", false, 0,
                               "Cannot calculate lot size", "", 0, riskPercent, riskAmount, 0, 0, 0, symbol);
        return false;
    }
    
    entryPrice = NormalizeDouble(entryPrice, digits);
    sl = NormalizeDouble(sl, digits);
    tp = NormalizeDouble(tp, digits);
    if(breakEvenPrice > 0)
        breakEvenPrice = NormalizeDouble(breakEvenPrice, digits);
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL)
    {
        request.action = TRADE_ACTION_DEAL;
    }
    else
    {
        request.action = TRADE_ACTION_PENDING;
    }
    
    request.symbol = symbol;
    request.volume = lotSize;
    request.type = orderType;
    request.price = entryPrice;
    request.sl = sl;
    request.tp = tp;
    request.magic = InpMagicNumber;
    request.comment = id + " R:" + DoubleToString(riskPercent, 2);
    request.type_filling = GetSymbolFillingMode(symbol);
    
    if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL)
        request.deviation = 10;
    
    if(!OrderSend(request, result))
    {
        Print("❌ OrderSend FEHLER: ", result.retcode, " - ", result.comment);
        
        SendSignalDeliveryStatus(id, "order_failed", false, 0,
                               StringFormat("OrderSend failed: %d - %s", result.retcode, result.comment),
                               "", 0, 0, 0, 0, 0, 0, symbol);
        return false;
    }
    
    Print("✅ SIGNAL AUSGEFÜHRT!");
    Print("  Ticket: ", result.order);
    Print("  Entry: ", entryPrice);
    Print("  SL: ", sl, " | TP: ", tp);
    Print("  Lots: ", DoubleToString(lotSize, 3));
    Print("  Risk: ", DoubleToString(actualRiskPercent, 2), "% (", DoubleToString(actualLoss, 2), " ", accountCurrency, ")");
    Print("  Filling Mode: ", EnumToString(request.type_filling));
    Print("=====================================");
    
    string orderTypeStr = ConvertOrderTypeToN8nFormat(EnumToString(orderType));
    
    string status = (orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL) ? "executed" : "pending_created";
    string message = (orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL) ? 
                     StringFormat("Trade executed: %s %s %.3f lots @ %.5f", symbol, orderTypeStr, lotSize, entryPrice) :
                     StringFormat("Pending order: %s %s %.3f lots @ %.5f", symbol, orderTypeStr, lotSize, entryPrice);
    
    SendSignalDeliveryStatus(id, status, true, result.order, message, orderTypeStr, lotSize,
                           riskPercent, riskAmount, actualRiskPercent, actualLoss, 0, symbol);
    
    bool isPending = (orderType != ORDER_TYPE_BUY && orderType != ORDER_TYPE_SELL);
    
    // v10: Pass TP1, TP2, and order type for dual TP support
    double finalTp1 = tp;
    double finalTp2 = (tp2 > 0) ? tp2 : tp;
    
    AddTrackedPosition(id, result.order, sl, tp, breakEvenPrice, isPending, riskPercent, symbol, entryPrice, beTriggerPrice, beTriggerActive, finalTp1, finalTp2, orderType);
    
    return true;
}

//| Parse and execute signals                                      |
void ParseAndExecuteSignals(string json)
{
    StringReplace(json, "\n", "");
    StringReplace(json, "\r", "");
    StringReplace(json, "\t", "");
    
    StringTrimLeft(json);
    StringTrimRight(json);
    
    bool isArray = (StringGetCharacter(json, 0) == '[');
    bool isObject = (StringGetCharacter(json, 0) == '{');
    
    if(!isArray && !isObject)
        return;
    
    if(isObject && !isArray)
    {
        if(StringFind(json, "\"signals\"") >= 0 && StringFind(json, "\"total_signals\"") >= 0)
        {
            string totalSignalsStr = GetJsonValue(json, "total_signals");
            int expectedSignals = (int)StringToInteger(totalSignalsStr);
            
            string signalsArrayJson = ExtractSignalsArray(json);
            if(signalsArrayJson != "")
            {
                ProcessSignalsArray(signalsArrayJson, expectedSignals);
            }
            return;
        }
        
        if(StringFind(json, "\"id\"") == -1 || 
           StringFind(json, "\"symbol\"") == -1 ||
           StringFind(json, "\"direction\"") == -1)
        {
            return;
        }
        
        g_multiSignalStats.totalSignalsReceived++;
        ProcessSingleSignal(json);
        return;
    }
    
    if(isArray)
    {
        g_multiSignalStats.batchCount++;
        g_multiSignalStats.lastBatchTime = TimeCurrent();
        
        json = StringSubstr(json, 1, StringLen(json) - 2);
        
        if(StringLen(json) == 0)
            return;
        
        string signals[];
        int signalCount = SplitSignalsEnhanced(json, signals);
        
        g_multiSignalStats.totalSignalsReceived += signalCount;
        
        if(signalCount == 0)
            return;
        
        int processedCount = 0;
        int skippedCount = 0;
        
        for(int i = 0; i < signalCount; i++)
        {
            string signalId = GetJsonValue(signals[i], "id");
            
            if(signalId != "" && IsSignalExecuted(signalId))
            {
                skippedCount++;
                g_multiSignalStats.totalSignalsSkipped++;
                continue;
            }
            
            ProcessSingleSignal(signals[i]);
            processedCount++;
            g_multiSignalStats.totalSignalsProcessed++;
            
            if(i < signalCount - 1)
                Sleep(100);
        }
        
        if(processedCount > 0)
            Print("✓ ", processedCount, " neue Signal(e) verarbeitet", (skippedCount > 0 ? StringFormat(" (%d übersprungen)", skippedCount) : ""));
    }
}

//| Map symbol name                                                |
string MapSymbol(string symbol)
{
    string upperSymbol = symbol;
    StringToUpper(upperSymbol);
    
    string mappings[30];
    mappings[0] = InpMapping01; mappings[1] = InpMapping02; mappings[2] = InpMapping03;
    mappings[3] = InpMapping04; mappings[4] = InpMapping05; mappings[5] = InpMapping06;
    mappings[6] = InpMapping07; mappings[7] = InpMapping08; mappings[8] = InpMapping09;
    mappings[9] = InpMapping10; mappings[10] = InpMapping11; mappings[11] = InpMapping12;
    mappings[12] = InpMapping13; mappings[13] = InpMapping14; mappings[14] = InpMapping15;
    mappings[15] = InpMapping16; mappings[16] = InpMapping17; mappings[17] = InpMapping18;
    mappings[18] = InpMapping19; mappings[19] = InpMapping20; mappings[20] = InpMapping21;
    mappings[21] = InpMapping22; mappings[22] = InpMapping23; mappings[23] = InpMapping24;
    mappings[24] = InpMapping25; mappings[25] = InpMapping26; mappings[26] = InpMapping27;
    mappings[27] = InpMapping28; mappings[28] = InpMapping29; mappings[29] = InpMapping30;
    
    for(int i = 0; i < 30; i++)
    {
        if(mappings[i] == "")
            continue;
        
        string aliasGroup = mappings[i];
        StringToUpper(aliasGroup);
        
        string aliases[];
        int aliasCount = StringSplit(aliasGroup, '|', aliases);
        
        bool foundInGroup = false;
        for(int j = 0; j < aliasCount; j++)
        {
            if(upperSymbol == aliases[j])
            {
                foundInGroup = true;
                break;
            }
        }
        
        if(foundInGroup)
        {
            if(InpDebugMode)
                Print("DEBUG: Symbol '", symbol, "' found in alias group: ", mappings[i]);
            
            for(int j = 0; j < aliasCount; j++)
            {
                string candidateSymbol = FindSymbolWithSuffix(aliases[j]);
                
                if(candidateSymbol != "")
                {
                    if(InpDebugMode)
                        Print("DEBUG: Found broker symbol: ", candidateSymbol, " (from alias: ", aliases[j], ")");
                    return candidateSymbol;
                }
            }
            
            if(InpDebugMode)
                Print("DEBUG: No broker symbol found for alias group: ", mappings[i]);
            return symbol;
        }
    }
    
    if(InpDebugMode)
        Print("DEBUG: Symbol '", symbol, "' not in any mapping group - searching directly");
    
    string directSymbol = FindSymbolWithSuffix(symbol);
    if(directSymbol != "")
        return directSymbol;
    
    return symbol;
}

//| Detect symbol suffix                                           |
void DetectSymbolSuffix()
{
    string currentSymbol = Symbol();
    
    string baseSymbols[] = {"EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCHF", "NZDUSD", "USDCAD", "XAUUSD"};
    
    for(int i = 0; i < ArraySize(baseSymbols); i++)
    {
        if(StringFind(currentSymbol, baseSymbols[i]) == 0)
        {
            g_symbolSuffix = StringSubstr(currentSymbol, StringLen(baseSymbols[i]));
            if(g_symbolSuffix != "")
            {
                return;
            }
        }
    }
    
    for(int i = 0; i < SymbolsTotal(false); i++)
    {
        string sym = SymbolName(i, false);
        if(StringFind(sym, "EURUSD") == 0 && StringLen(sym) > 6)
        {
            g_symbolSuffix = StringSubstr(sym, 6);
            return;
        }
    }
}

//| Find symbol with suffix                                         |
string FindSymbolWithSuffix(string baseSymbol)
{
    string symbolWithSuffix = baseSymbol + g_symbolSuffix;
    if(SymbolSelect(symbolWithSuffix, true))
        return symbolWithSuffix;
    
    if(SymbolSelect(baseSymbol, true))
        return baseSymbol;
    
    string possibleSuffixes[] = {"", ".ecn", ".pro", ".raw", ".a", ".m", ".s", "_ecn", "_raw", "_pro", "."};
    for(int i = 0; i < ArraySize(possibleSuffixes); i++)
    {
        symbolWithSuffix = baseSymbol + possibleSuffixes[i];
        if(SymbolSelect(symbolWithSuffix, true))
        {
            if(possibleSuffixes[i] != "" && g_symbolSuffix == "")
            {
                g_symbolSuffix = possibleSuffixes[i];
            }
            return symbolWithSuffix;
        }
    }
    
    if(StringFind(baseSymbol, "USD") > 0 && StringFind(baseSymbol, "USDT") == -1)
    {
        string cryptoSymbol = baseSymbol;
        StringReplace(cryptoSymbol, "USD", "USDT");
        
        symbolWithSuffix = cryptoSymbol + g_symbolSuffix;
        if(SymbolSelect(symbolWithSuffix, true))
        {
            return symbolWithSuffix;
        }
        
        if(SymbolSelect(cryptoSymbol, true))
        {
            return cryptoSymbol;
        }
        
        for(int i = 0; i < ArraySize(possibleSuffixes); i++)
        {
            symbolWithSuffix = cryptoSymbol + possibleSuffixes[i];
            if(SymbolSelect(symbolWithSuffix, true))
            {
                if(possibleSuffixes[i] != "" && g_symbolSuffix == "")
                {
                    g_symbolSuffix = possibleSuffixes[i];
                }
                return symbolWithSuffix;
            }
        }
    }
    
    for(int i = 0; i < SymbolsTotal(false); i++)
    {
        string sym = SymbolName(i, false);
        if(StringFind(sym, baseSymbol) == 0)
        {
            if(SymbolSelect(sym, true))
            {
                string newSuffix = StringSubstr(sym, StringLen(baseSymbol));
                if(newSuffix != "" && g_symbolSuffix == "")
                {
                    g_symbolSuffix = newSuffix;
                }
                return sym;
            }
        }
        
        if(StringFind(baseSymbol, "USD") > 0 && StringFind(baseSymbol, "USDT") == -1)
        {
            string cryptoBase = baseSymbol;
            StringReplace(cryptoBase, "USD", "USDT");
            if(StringFind(sym, cryptoBase) == 0)
            {
                if(SymbolSelect(sym, true))
                {
                    return sym;
                }
            }
        }
    }
    
    return "";
}

//| Timer function                                                  |
void OnTimer()
{
    static datetime lastSignalCheck = 0;
    static datetime lastStatusCheckTime = 0;
    
    datetime currentTime = TimeCurrent();
    
    if(currentTime - lastSignalCheck >= InpCheckInterval)
    {
        ProcessSignals();
        lastSignalCheck = currentTime;
    }
    
    if(currentTime - lastStatusCheckTime >= InpStatusInterval)
    {
        CleanupTrackedPositions();
        
        for(int i = ArraySize(g_trackedPositions) - 1; i >= 0; i--)
        {
            int currentSize = ArraySize(g_trackedPositions);
            CheckPositionStatus(i);
            
            if(ArraySize(g_trackedPositions) < currentSize)
                continue;
            
            CheckBreakEvenTrigger(i);
        }
        
        lastStatusCheckTime = currentTime;
    }
    
    for(int i = 0; i < ArraySize(g_trackedPositions); i++)
    {
        CheckBreakEvenTrigger(i);
    }
}

//| Deinitialization                                               |
void OnDeinit(const int reason)
{
    EventKillTimer();
    
    SendLogoutStatus(reason);
    
    SaveExecutedSignals();
    SaveTrackedPositions();
    
    Print("====================================");
    Print("EA v9 OPTIMIZED beendet");
    Print("  Neue Signale: ", g_multiSignalStats.newSignalsThisSession);
    Print("  SL/TP Updates: ", g_multiSignalStats.slTpUpdatesThisSession);
    Print("  Übersprungen: ", g_multiSignalStats.totalSignalsSkipped);
    Print("------------------------------------");
    Print("  Risk Optimization Stats:");
    Print("    Total Optimizations: ", g_riskOptStats.totalOptimizations);
    Print("    Lots Increased: ", g_riskOptStats.lotsIncreased);
    Print("    Lots Decreased: ", g_riskOptStats.lotsDecreased);
    Print("    Lots Unchanged: ", g_riskOptStats.lotsUnchanged);
    Print("    Total Risk Gained: ", DoubleToString(g_riskOptStats.totalRiskGained, 2), "%");
    Print("    Max Deviation: ", DoubleToString(g_riskOptStats.maxDeviation, 2), "%");
    Print("    Avg Deviation: ", DoubleToString(g_riskOptStats.avgDeviation, 2), "%");
    Print("    Avg Iterations: ", DoubleToString(g_riskOptStats.avgIterations, 1));
    Print("------------------------------------");
    Print("  Close Statistiken:");
    Print("    SL: ", g_closeStats.slHit, " | TP: ", g_closeStats.tpHit);
    Print("    TP1 Partial: ", g_closeStats.tp1Hit, " | TP1 Full: ", g_closeStats.tp1FullClose, " | TP2: ", g_closeStats.tp2Hit);
    Print("    Break-Even: ", g_closeStats.breakEvenHit);
    Print("    Manuell: ", g_closeStats.manuallyClosed, " | EA: ", g_closeStats.eaClosed);
    Print("    Market Closed: ", g_closeStats.marketClosed);
    Print("    Pending Manuell gelöscht: ", g_closeStats.pendingManuallyDeleted);
    Print("------------------------------------");
    Print("  Delivery API:");
    Print("    Total: ", g_deliveryStats.totalRequests);
    Print("    Erfolgreich: ", g_deliveryStats.successfulRequests);
    Print("    Fehlgeschlagen: ", g_deliveryStats.failedRequests);
    Print("    Pending: ", g_deliveryStats.pendingOrderNotifications);
    Print("    Market: ", g_deliveryStats.marketOrderNotifications);
    Print("    Closes: ", g_deliveryStats.closeNotifications);
    Print("    Updates: ", g_deliveryStats.updateNotifications);
    Print("====================================");
}
//+------------------------------------------------------------------+
//| v10: Check if TP1 is hit for a position                        |
//+------------------------------------------------------------------+
bool IsTp1Hit(int posIndex)
{
    if(posIndex < 0 || posIndex >= ArraySize(g_trackedPositions))
        return false;
    
    if(!g_trackedPositions[posIndex].has_dual_tp)
        return false;
    
    if(g_trackedPositions[posIndex].tp1_done)
        return false;
    
    if(g_trackedPositions[posIndex].is_pending)
        return false;
    
    double tp1 = g_trackedPositions[posIndex].tp1;
    if(tp1 <= 0)
        return false;
    
    string symbol = g_trackedPositions[posIndex].symbol;
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    ENUM_ORDER_TYPE orderType = g_trackedPositions[posIndex].order_type;
    
    // BUY: TP reached when Bid >= TP
    if(orderType == ORDER_TYPE_BUY)
    {
        return (bid >= tp1);
    }
    // SELL: TP reached when Ask <= TP
    else if(orderType == ORDER_TYPE_SELL)
    {
        return (ask <= tp1);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| v10: Check if TP2 is hit for a position                        |
//+------------------------------------------------------------------+
bool IsTp2Hit(int posIndex)
{
    if(posIndex < 0 || posIndex >= ArraySize(g_trackedPositions))
        return false;
    
    if(!g_trackedPositions[posIndex].has_dual_tp)
        return false;
    
    if(!g_trackedPositions[posIndex].tp1_done)
        return false;
    
    if(g_trackedPositions[posIndex].is_pending)
        return false;
    
    double tp2 = g_trackedPositions[posIndex].tp2;
    if(tp2 <= 0)
        return false;
    
    string symbol = g_trackedPositions[posIndex].symbol;
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    ENUM_ORDER_TYPE orderType = g_trackedPositions[posIndex].order_type;
    
    // BUY: TP reached when Bid >= TP
    if(orderType == ORDER_TYPE_BUY)
    {
        return (bid >= tp2);
    }
    // SELL: TP reached when Ask <= TP
    else if(orderType == ORDER_TYPE_SELL)
    {
        return (ask <= tp2);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| v10: Compute close volume for TP1 partial close                |
//+------------------------------------------------------------------+
double ComputeCloseVolumeForTp1(double vol, string symbol)
{
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    // Calculate volume digits from step (e.g., 0.01 = 2 digits, 0.1 = 1 digit)
    int digits_vol = 2;
    if(step >= 0.1) digits_vol = 1;
    else if(step >= 0.01) digits_vol = 2;
    else if(step >= 0.001) digits_vol = 3;
    else digits_vol = 4;
    
    // If volume is too small to split, close all
    if(vol < 2 * minLot)
    {
        Print("  ℹ Volume ", vol, " < 2*minLot (", 2*minLot, ") → Full close at TP1");
        return vol;
    }
    
    // Calculate half volume
    double half = vol / 2.0;
    
    // If half is less than minLot, close all
    if(half < minLot)
    {
        Print("  ℹ Half volume ", half, " < minLot (", minLot, ") → Full close at TP1");
        return vol;
    }
    
    // Normalize half down to step
    double half_down = MathFloor(half / step) * step;
    double half_up = vol - half_down;
    
    // Close the larger part, keep the smaller part
    double close_volume = (half_down >= half_up) ? half_down : half_up;
    double remain = vol - close_volume;
    
    // If remaining volume is less than minLot, close all instead
    if(remain < minLot)
    {
        Print("  ℹ Remaining volume ", remain, " < minLot (", minLot, ") → Full close at TP1");
        return vol;
    }
    
    // Normalize volumes
    close_volume = NormalizeDouble(close_volume, digits_vol);
    remain = NormalizeDouble(remain, digits_vol);
    
    Print("  ✓ Partial close: ", close_volume, " lots (", remain, " lots remain)");
    return close_volume;
}

//+------------------------------------------------------------------+
//| v10: Close partial position at TP1                             |
//+------------------------------------------------------------------+
bool ClosePartialAtTp1(int posIndex)
{
    if(posIndex < 0 || posIndex >= ArraySize(g_trackedPositions))
        return false;
    
    ulong ticket = g_trackedPositions[posIndex].ticket;
    string symbol = g_trackedPositions[posIndex].symbol;
    
    if(!PositionSelectByTicket(ticket))
    {
        Print("❌ Position not found: ", ticket);
        return false;
    }
    
    double currentVolume = PositionGetDouble(POSITION_VOLUME);
    double closeVolume = ComputeCloseVolumeForTp1(currentVolume, symbol);
    
    bool isFullClose = (MathAbs(closeVolume - currentVolume) < 0.00001);
    
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.position = ticket;
    request.symbol = symbol;
    request.volume = closeVolume;
    request.type_filling = GetSymbolFillingMode(symbol);
    request.magic = InpMagicNumber;
    
    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    request.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.price = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    if(!OrderSend(request, result))
    {
        int error = GetLastError();
        Print("❌ TP1 Close failed: ", error, " - ", result.comment);
        return false;
    }
    
    if(result.retcode != TRADE_RETCODE_DONE)
    {
        Print("❌ TP1 Close failed: ", result.retcode, " - ", result.comment);
        return false;
    }
    
    // Update statistics
    if(isFullClose)
    {
        g_closeStats.tp1FullClose++;
        Print("✅ TP1 REACHED - FULL CLOSE");
        Print("  Ticket: ", ticket);
        Print("  Volume: ", closeVolume, " lots (full position)");
        Print("  TP1: ", g_trackedPositions[posIndex].tp1);
        Print("  Reason: Volume not divisible");
    }
    else
    {
        g_closeStats.tp1Hit++;
        Print("✅ TP1 REACHED - PARTIAL CLOSE");
        Print("  Ticket: ", ticket);
        Print("  Closed: ", closeVolume, " lots");
        Print("  Remaining: ", NormalizeDouble(currentVolume - closeVolume, 2), " lots");
        Print("  TP1: ", g_trackedPositions[posIndex].tp1);
        Print("  Next Target: TP2 @ ", g_trackedPositions[posIndex].tp2);
    }
    
    // Mark TP1 as done
    g_trackedPositions[posIndex].tp1_done = true;
    SaveTrackedPositions();
    
    // Send delivery notification
    string deliveryMsg = isFullClose ? 
        StringFormat("TP1 reached - Full close: %.3f lots @ %.5f", closeVolume, g_trackedPositions[posIndex].tp1) :
        StringFormat("TP1 reached - Partial close: %.3f lots @ %.5f (%.3f lots remain for TP2)", 
                     closeVolume, g_trackedPositions[posIndex].tp1, currentVolume - closeVolume);
    
    SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "tp1_hit", true, ticket, 
                           deliveryMsg, "", closeVolume, 0, 0, 0, 0, 0, symbol);
    
    return true;
}

//+------------------------------------------------------------------+
//| v10: Close remaining position at TP2                           |
//+------------------------------------------------------------------+
bool CloseRemainingAtTp2(int posIndex)
{
    if(posIndex < 0 || posIndex >= ArraySize(g_trackedPositions))
        return false;
    
    ulong ticket = g_trackedPositions[posIndex].ticket;
    string symbol = g_trackedPositions[posIndex].symbol;
    
    if(!PositionSelectByTicket(ticket))
    {
        Print("❌ Position not found: ", ticket);
        return false;
    }
    
    double currentVolume = PositionGetDouble(POSITION_VOLUME);
    
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.position = ticket;
    request.symbol = symbol;
    request.volume = currentVolume;
    request.type_filling = GetSymbolFillingMode(symbol);
    request.magic = InpMagicNumber;
    
    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    request.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.price = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    if(!OrderSend(request, result))
    {
        int error = GetLastError();
        Print("❌ TP2 Close failed: ", error, " - ", result.comment);
        return false;
    }
    
    if(result.retcode != TRADE_RETCODE_DONE)
    {
        Print("❌ TP2 Close failed: ", result.retcode, " - ", result.comment);
        return false;
    }
    
    g_closeStats.tp2Hit++;
    Print("✅ TP2 REACHED - FULL CLOSE");
    Print("  Ticket: ", ticket);
    Print("  Volume: ", currentVolume, " lots");
    Print("  TP2: ", g_trackedPositions[posIndex].tp2);
    
    // Send delivery notification
    string deliveryMsg = StringFormat("TP2 reached - Final close: %.3f lots @ %.5f", 
                                     currentVolume, g_trackedPositions[posIndex].tp2);
    
    SendSignalDeliveryStatus(g_trackedPositions[posIndex].signal_id, "tp2_hit", true, ticket, 
                           deliveryMsg, "", currentVolume, 0, 0, 0, 0, 0, symbol);
    
    // Position will be removed by CheckClosedPositions()
    return true;
}

//+------------------------------------------------------------------+
//| v10: Monitor dual take profit levels                           |
//+------------------------------------------------------------------+
void MonitorDualTakeProfit()
{
    for(int i = ArraySize(g_trackedPositions) - 1; i >= 0; i--)
    {
        if(!g_trackedPositions[i].has_dual_tp)
            continue;
        
        if(g_trackedPositions[i].is_pending)
            continue;
        
        // Check if position still exists
        if(!PositionSelectByTicket(g_trackedPositions[i].ticket))
            continue;
        
        // Check TP1 first (if not done yet)
        if(!g_trackedPositions[i].tp1_done)
        {
            if(IsTp1Hit(i))
            {
                ClosePartialAtTp1(i);
            }
        }
        // Then check TP2 (only if TP1 is done)
        else
        {
            if(IsTp2Hit(i))
            {
                CloseRemainingAtTp2(i);
            }
        }
    }
}

//| Tick function                                                   |
void OnTick()
{
    // v10: Monitor TP1/TP2 for dual TP positions
    MonitorDualTakeProfit();
    
    // Timer handles checks
}

//| Fetch signals from API                                         |
string FetchSignalsFromAPI()
{
    long accountNumber = AccountInfoInteger(ACCOUNT_LOGIN);
    
    string fullUrl = InpAPIBaseUrl + "?account_id=" + IntegerToString(accountNumber);
    
    string headers = "Content-Type: application/json\r\n";
    char post[];
    char result[];
    string resultHeaders;
    
    int timeout = 5000;
    
    ArrayResize(post, 0);

    // v11.1: Use retry logic for signal fetching
    int res = WebRequestWithRetry("GET", fullUrl, headers, timeout, post, result, resultHeaders, 3);

    if(res <= 0)
        return "";

    string response = CharArrayToString(result, 0, ArraySize(result), CP_UTF8);

    return response;
}

//| Process signals                                                 |
void ProcessSignals()
{
    string jsonResponse = FetchSignalsFromAPI();
    
    if(jsonResponse == "")
        return;
    
    StringTrimLeft(jsonResponse);
    StringTrimRight(jsonResponse);
    
    if(jsonResponse == "[]" || jsonResponse == "{}")
        return;
    
    ParseAndExecuteSignals(jsonResponse);
}

//| Get JSON value (v11.1: Enhanced String Parsing)                 |
string GetJsonValue(string json, string key)
{
    // v11.1: Robust string-based JSON parsing (no external dependencies)
    string searchKey = "\"" + key + "\":";
    int keyPos = StringFind(json, searchKey);

    if(keyPos == -1)
    {
        searchKey = "\"" + key + "\" :";
        keyPos = StringFind(json, searchKey);

        if(keyPos == -1)
            return "";
    }

    int valueStart = keyPos + StringLen(searchKey);

    // Skip whitespace
    while(valueStart < StringLen(json) &&
          (StringGetCharacter(json, valueStart) == ' ' ||
           StringGetCharacter(json, valueStart) == '\t' ||
           StringGetCharacter(json, valueStart) == '\n' ||
           StringGetCharacter(json, valueStart) == '\r'))
        valueStart++;

    bool isString = (StringGetCharacter(json, valueStart) == '"');

    if(isString)
        valueStart++;

    int valueEnd = valueStart;
    while(valueEnd < StringLen(json))
    {
        ushort charCode = StringGetCharacter(json, valueEnd);

        if(isString && charCode == '"')
            break;
        else if(!isString && (charCode == ',' || charCode == '}' || charCode == ']'))
            break;

        valueEnd++;
    }

    string value = StringSubstr(json, valueStart, valueEnd - valueStart);

    // v11.1: Enhanced null and whitespace handling
    StringTrimLeft(value);
    StringTrimRight(value);

    if(value == "null" || value == "NULL")
        return "";

    return value;
}

//+------------------------------------------------------------------+
//| HTTP Request with Retry Logic (v11.1 Optimization)               |
//| Retries: 3x with exponential backoff (1s, 2s, 4s)                |
//+------------------------------------------------------------------+
int WebRequestWithRetry(
    string method,
    string url,
    string &headers,
    int timeout,
    const char &data[],
    char &result[],
    string &resultHeaders,
    int maxRetries = 3
)
{
    int attempt = 0;
    int delayMs = 1000;  // Start with 1 second
    int res = -1;

    while(attempt < maxRetries)
    {
        attempt++;

        // Make request
        res = WebRequest(method, url, headers, timeout, data, result, resultHeaders);

        // Success
        if(res > 0 && res < 600)
        {
            if(attempt > 1 && InpDebugMode)
            {
                Print("✓ HTTP Request successful on attempt ", attempt, "/", maxRetries);
            }
            return res;
        }

        // Failed - check if we should retry
        int error = GetLastError();

        if(InpDebugMode)
        {
            Print("⚠ HTTP Request failed (attempt ", attempt, "/", maxRetries, "): Error ", error);
        }

        // Don't retry on certain errors
        if(error == 4060)  // URL not allowed
        {
            if(InpDebugMode)
                Print("❌ URL not allowed in WebRequest - no retry");
            return res;
        }

        // Last attempt - don't sleep
        if(attempt >= maxRetries)
        {
            if(InpDebugMode)
                Print("❌ HTTP Request failed after ", maxRetries, " attempts");
            return res;
        }

        // Exponential backoff
        if(InpDebugMode)
            Print("⏳ Retrying in ", delayMs/1000, "s...");

        Sleep(delayMs);
        delayMs *= 2;  // Double delay for next attempt (exponential backoff)
    }

    return res;
}

//| Check if signal executed                                       |
bool IsSignalExecuted(string signalId)
{
    for(int i = 0; i < ArraySize(g_executedSignals); i++)
    {
        if(g_executedSignals[i] == signalId)
            return true;
    }
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            if(PositionSelectByTicket(ticket))
            {
                string comment = PositionGetString(POSITION_COMMENT);
                string extractedId = ExtractSignalId(comment);
                if(extractedId == signalId)
                {
                    AddExecutedSignal(signalId);
                    return true;
                }
            }
        }
    }
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        ulong orderTicket = OrderGetTicket(i);
        if(orderTicket > 0)
        {
            if(OrderSelect(orderTicket))
            {
                string comment = OrderGetString(ORDER_COMMENT);
                string extractedId = ExtractSignalId(comment);
                if(extractedId == signalId)
                {
                    AddExecutedSignal(signalId);
                    return true;
                }
            }
        }
    }
    
    return false;
}

//| Add executed signal                                            |
void AddExecutedSignal(string signalId)
{
    for(int i = 0; i < ArraySize(g_executedSignals); i++)
    {
        if(g_executedSignals[i] == signalId)
            return;
    }
    
    int size = ArraySize(g_executedSignals);
    ArrayResize(g_executedSignals, size + 1);
    g_executedSignals[size] = signalId;
    
    if(size % 10 == 0)
        SaveExecutedSignals();
}

//| Save executed signals                                          |
void SaveExecutedSignals()
{
    string filename = "SignalReceiverEA_executed.txt";
    int fileHandle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI);
    
    if(fileHandle != INVALID_HANDLE)
    {
        for(int i = 0; i < ArraySize(g_executedSignals); i++)
        {
            FileWriteString(fileHandle, g_executedSignals[i] + "\n");
        }
        FileClose(fileHandle);
    }
}

//| Load executed signals                                          |
void LoadExecutedSignals()
{
    string filename = "SignalReceiverEA_executed.txt";
    
    if(!FileIsExist(filename))
        return;
    
    int fileHandle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_ANSI);
    
    if(fileHandle != INVALID_HANDLE)
    {
        ArrayResize(g_executedSignals, 0);
        
        while(!FileIsEnding(fileHandle))
        {
            string signalId = FileReadString(fileHandle);
            StringTrimRight(signalId);
            StringTrimLeft(signalId);
            
            if(signalId != "")
            {
                int size = ArraySize(g_executedSignals);
                ArrayResize(g_executedSignals, size + 1);
                g_executedSignals[size] = signalId;
            }
        }
        
        FileClose(fileHandle);
        
        if(InpDebugMode && ArraySize(g_executedSignals) > 0)
            Print("✓ ", ArraySize(g_executedSignals), " ausgeführte Signal(e) geladen");
    }
}

//| Chart event handler                                            |
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if(id == CHARTEVENT_KEYDOWN)
    {
        if(lparam == 'S' || lparam == 's')
        {
            Print("====================================");
            Print("EA STATUS v9 OPTIMIZED");
            Print("====================================");
            Print("Konto: ", AccountInfoInteger(ACCOUNT_LOGIN));
            Print("Bilanz: ", AccountInfoDouble(ACCOUNT_BALANCE), " ", AccountInfoString(ACCOUNT_CURRENCY));
            Print("====================================");
            Print("SESSION STATISTIKEN:");
            Print("  Neue Signale: ", g_multiSignalStats.newSignalsThisSession);
            Print("  SL/TP Updates: ", g_multiSignalStats.slTpUpdatesThisSession);
            Print("  Übersprungen: ", g_multiSignalStats.totalSignalsSkipped);
            Print("====================================");
            Print("RISK OPTIMIZATION (v9 OPTIMIZED):");
            Print("  Total Optimizations: ", g_riskOptStats.totalOptimizations);
            Print("  Lots Increased: ", g_riskOptStats.lotsIncreased, " 🎉");
            Print("  Lots Decreased: ", g_riskOptStats.lotsDecreased);
            Print("  Lots Unchanged: ", g_riskOptStats.lotsUnchanged);
            Print("  Total Risk Gained: ", DoubleToString(g_riskOptStats.totalRiskGained, 2), "%");
            Print("  Max Deviation: ", DoubleToString(g_riskOptStats.maxDeviation, 2), "%");
            Print("  Avg Deviation: ", DoubleToString(g_riskOptStats.avgDeviation, 2), "%");
            Print("  Avg Iterations: ", DoubleToString(g_riskOptStats.avgIterations, 1));
            Print("====================================");
            Print("CLOSE STATISTIKEN:");
            Print("  SL getroffen: ", g_closeStats.slHit);
            Print("  TP getroffen: ", g_closeStats.tpHit);
            Print("  TP1 Partial Close: ", g_closeStats.tp1Hit);
            Print("  TP1 Full Close: ", g_closeStats.tp1FullClose);
            Print("  TP2 getroffen: ", g_closeStats.tp2Hit);
            Print("  Break-Even getroffen: ", g_closeStats.breakEvenHit);
            Print("  Manuell geschlossen: ", g_closeStats.manuallyClosed);
            Print("  EA geschlossen: ", g_closeStats.eaClosed);
            Print("  Margin Call: ", g_closeStats.marginCall);
            Print("  Market Closed: ", g_closeStats.marketClosed);
            Print("  Pending getriggert: ", g_closeStats.pendingTriggered);
            Print("  Pending manuell gelöscht: ", g_closeStats.pendingManuallyDeleted);
            Print("  Pending abgelaufen: ", g_closeStats.pendingExpired);
            if(g_closeStats.other > 0)
                Print("  Sonstige: ", g_closeStats.other);
            Print("====================================");
            Print("DELIVERY API STATISTIKEN:");
            Print("  Total Requests: ", g_deliveryStats.totalRequests);
            Print("  Erfolgreich: ", g_deliveryStats.successfulRequests);
            Print("  Fehlgeschlagen: ", g_deliveryStats.failedRequests);
            Print("  Retry Attempts: ", g_deliveryStats.retryAttempts);
            Print("------------------------------------");
            Print("  Nach Typ:");
            Print("    Pending Orders: ", g_deliveryStats.pendingOrderNotifications);
            Print("    Market Orders: ", g_deliveryStats.marketOrderNotifications);
            Print("    Close Events: ", g_deliveryStats.closeNotifications);
            Print("    Updates: ", g_deliveryStats.updateNotifications);
            if(g_deliveryStats.lastError != "")
                Print("  Letzter Fehler: ", g_deliveryStats.lastError);
            Print("====================================");
            Print("Überwachte Positionen: ", ArraySize(g_trackedPositions));
            Print("Ausgeführte Signale: ", ArraySize(g_executedSignals));
            Print("====================================");
            Print("AKTIVE MAPPINGS:");
            PrintAllMappings();
            Print("====================================");
        }
        
        if(lparam == 'R' || lparam == 'r')
        {
            Print("====================================");
            Print("RESET EXECUTED SIGNALS");
            Print("====================================");
            
            int oldCount = ArraySize(g_executedSignals);
            ArrayResize(g_executedSignals, 0);
            
            string filename = "SignalReceiverEA_executed.txt";
            if(FileIsExist(filename))
                FileDelete(filename);
            
            Print("✓ Reset abgeschlossen");
            Print("  Vorher: ", oldCount);
            Print("  Nachher: ", ArraySize(g_executedSignals));
            Print("====================================");
        }
    }
}
//+------------------------------------------------------------------+
