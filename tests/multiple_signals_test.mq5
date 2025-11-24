//+------------------------------------------------------------------+
//| Test Multiple Signals JSON Processing                           |
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//| Helper function to detect if JSON response is an array          |
//+------------------------------------------------------------------+
bool IsJSONArray(string json) {
    string trimmed = json;
    StringReplace(trimmed, " ", "");
    StringReplace(trimmed, "\t", "");
    StringReplace(trimmed, "\n", "");
    StringReplace(trimmed, "\r", "");
    return StringGetCharacter(trimmed, 0) == '[';
}

//+------------------------------------------------------------------+
//| Simple JSON string extraction                                   |
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

//+------------------------------------------------------------------+
//| Simple JSON double extraction                                   |
//+------------------------------------------------------------------+
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
//| Convert new signal format to old format for compatibility       |
//+------------------------------------------------------------------+
string ConvertSignalToOldFormat(string new_signal_json) {
    string signal_id = ExtractStringFromJSON(new_signal_json, "id");
    string symbol = ExtractStringFromJSON(new_signal_json, "symbol");
    string direction = ExtractStringFromJSON(new_signal_json, "direction");
    string entry_type = ExtractStringFromJSON(new_signal_json, "entry_type");
    double entry_price = ExtractDoubleFromJSON(new_signal_json, "entry_price");
    double sl = ExtractDoubleFromJSON(new_signal_json, "sl");
    double tp1 = ExtractDoubleFromJSON(new_signal_json, "tp1");
    double risk = ExtractDoubleFromJSON(new_signal_json, "risk");
    
    // Convert to old format JSON
    string old_format = "{";
    old_format += "\"signal_id\":\"" + signal_id + "\",";
    old_format += "\"symbol\":\"" + symbol + "\",";
    old_format += "\"direction\":\"" + direction + "\",";
    old_format += "\"order_type\":\"" + entry_type + "\",";
    old_format += "\"entry\":\"" + DoubleToString(entry_price, 5) + "\",";
    old_format += "\"sl\":\"" + DoubleToString(sl, 5) + "\",";
    old_format += "\"tp\":\"" + DoubleToString(tp1, 5) + "\",";
    old_format += "\"risk\":\"" + DoubleToString(risk, 2) + "\"";
    old_format += "}";
    
    return old_format;
}

//+------------------------------------------------------------------+
//| Test function to validate multiple signals processing            |
//+------------------------------------------------------------------+
void TestMultipleSignalsProcessing() {
    Print("=== TESTING MULTIPLE SIGNALS PROCESSING ===");
    
    // Test 1: JSON array detection
    string single_signal = "{\"signal_id\":\"test1\",\"symbol\":\"EURUSD\"}";
    string array_signals = "[{\"id\":\"test1\",\"symbol\":\"EURUSD\"},{\"id\":\"test2\",\"symbol\":\"GBPUSD\"}]";
    string array_with_spaces = " \n\t [\n {\"id\":\"test1\"} \n ] \t ";
    
    bool is_single = IsJSONArray(single_signal);
    bool is_array = IsJSONArray(array_signals);
    bool is_array_with_spaces = IsJSONArray(array_with_spaces);
    
    Print("Test 1 - JSON Array Detection:");
    Print("  Single signal detection: ", (is_single ? "FAILED (detected as array)" : "PASSED"));
    Print("  Array signals detection: ", (is_array ? "PASSED" : "FAILED (not detected as array)"));
    Print("  Array with spaces detection: ", (is_array_with_spaces ? "PASSED" : "FAILED (not detected as array)"));
    
    // Test 2: Signal format conversion
    string new_format_signal = "{\"id\":\"sig_2025-09-23T10:04:16\",\"symbol\":\"USDJPY\",\"direction\":\"sell\",\"entry_type\":\"limit\",\"entry_price\":\"148.25000\",\"sl\":\"148.40000\",\"tp1\":\"146.70000\",\"risk\":1}";
    string converted = ConvertSignalToOldFormat(new_format_signal);
    
    Print("Test 2 - Signal Conversion:");
    Print("  Input: ", new_format_signal);
    Print("  Output: ", converted);
    
    // Validate conversion
    string expected_signal_id = ExtractStringFromJSON(converted, "signal_id");
    string expected_symbol = ExtractStringFromJSON(converted, "symbol");
    string expected_direction = ExtractStringFromJSON(converted, "direction");
    double expected_entry = ExtractDoubleFromJSON(converted, "entry");
    
    bool conversion_ok = (expected_signal_id == "sig_2025-09-23T10:04:16" && 
                         expected_symbol == "USDJPY" && 
                         expected_direction == "sell" && 
                         expected_entry == 148.25000);
    
    Print("  Conversion validation: ", (conversion_ok ? "PASSED" : "FAILED"));
    
    // Test 3: Array parsing simulation
    string test_array = "[{\"total_signals\":2,\"id\":\"sig_2025-09-23T10:04:16\",\"symbol\":\"USDJPY\",\"direction\":\"sell\",\"entry_type\":\"limit\",\"entry_price\":\"148.25000\",\"sl\":\"148.40000\",\"tp1\":\"146.70000\",\"risk\":1},{\"total_signals\":2,\"id\":\"sig_2025-09-23T10:04:15\",\"symbol\":\"USDJPY\",\"direction\":\"sell\",\"entry_type\":\"limit\",\"entry_price\":\"148.21000\",\"sl\":\"148.40000\",\"tp1\":\"146.70000\",\"risk\":1}]";
    
    Print("Test 3 - Array Parsing:");
    Print("  Is array: ", (IsJSONArray(test_array) ? "PASSED" : "FAILED"));
    
    // Extract total signals
    double total_signals = ExtractDoubleFromJSON(test_array, "total_signals");
    Print("  Total signals detected: ", total_signals);
    
    Print("=== ALL TESTS COMPLETED ===");
}

//+------------------------------------------------------------------+
//| Script start function                                            |
//+------------------------------------------------------------------+
void OnStart() {
    TestMultipleSignalsProcessing();
}