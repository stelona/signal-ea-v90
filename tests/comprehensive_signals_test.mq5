//+------------------------------------------------------------------+
//| Comprehensive Multiple Signals Test                             |
//+------------------------------------------------------------------+
#property strict

// Sample test data that matches the problem statement format
string sample_multiple_signals = "[{\"total_signals\":2,\"id\":\"sig_2025-09-23T10:04:16\",\"symbol\":\"USDJPY\",\"direction\":\"sell\",\"entry_type\":\"limit\",\"entry_price\":\"148.25000\",\"entry_min\":null,\"entry_max\":null,\"sl\":\"148.40000\",\"tp1\":\"146.70000\",\"low_risk\":\"0\",\"risk\":1},{\"total_signals\":2,\"id\":\"sig_2025-09-23T10:04:15\",\"symbol\":\"USDJPY\",\"direction\":\"sell\",\"entry_type\":\"limit\",\"entry_price\":\"148.21000\",\"entry_min\":null,\"entry_max\":null,\"sl\":\"148.40000\",\"tp1\":\"146.70000\",\"low_risk\":\"0\",\"risk\":1}]";

string sample_single_signal = "{\"signal_id\":\"sig_legacy\",\"symbol\":\"EURUSD\",\"direction\":\"buy\",\"order_type\":\"market\",\"entry\":\"1.10000\",\"sl\":\"1.09500\",\"tp\":\"1.11000\"}";

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
//| Comprehensive Test of Multiple Signals Processing               |
//+------------------------------------------------------------------+
void TestComprehensiveMultipleSignals() {
    Print("=== COMPREHENSIVE MULTIPLE SIGNALS TEST ===");
    
    // Test 1: Array detection
    Print("\n--- Test 1: Array Detection ---");
    bool test1_pass = true;
    
    // Test various array formats
    string test_cases[] = {
        "[]",
        " [] ",
        "\n[\n]\t",
        "[{\"id\":\"test\"}]",
        sample_multiple_signals,
        sample_single_signal
    };
    bool expected_results[] = {true, true, true, true, true, false};
    
    for(int i = 0; i < 6; i++) {
        bool result = IsJSONArray(test_cases[i]);
        bool passed = (result == expected_results[i]);
        test1_pass = test1_pass && passed;
        Print("  Case ", i+1, ": ", (passed ? "PASSED" : "FAILED"), " (expected: ", expected_results[i], ", got: ", result, ")");
    }
    
    // Test 2: Signal extraction from new format
    Print("\n--- Test 2: Signal Field Extraction ---");
    bool test2_pass = true;
    
    string test_signal = "{\"total_signals\":2,\"id\":\"sig_2025-09-23T10:04:16\",\"symbol\":\"USDJPY\",\"direction\":\"sell\",\"entry_type\":\"limit\",\"entry_price\":\"148.25000\",\"sl\":\"148.40000\",\"tp1\":\"146.70000\",\"risk\":1}";
    
    string id = ExtractStringFromJSON(test_signal, "id");
    string symbol = ExtractStringFromJSON(test_signal, "symbol");
    string direction = ExtractStringFromJSON(test_signal, "direction");
    string entry_type = ExtractStringFromJSON(test_signal, "entry_type");
    double entry_price = ExtractDoubleFromJSON(test_signal, "entry_price");
    double sl = ExtractDoubleFromJSON(test_signal, "sl");
    double tp1 = ExtractDoubleFromJSON(test_signal, "tp1");
    double risk = ExtractDoubleFromJSON(test_signal, "risk");
    
    Print("  ID: ", id, " (expected: sig_2025-09-23T10:04:16)");
    Print("  Symbol: ", symbol, " (expected: USDJPY)");
    Print("  Direction: ", direction, " (expected: sell)");
    Print("  Entry Type: ", entry_type, " (expected: limit)");
    Print("  Entry Price: ", DoubleToString(entry_price, 5), " (expected: 148.25000)");
    Print("  SL: ", DoubleToString(sl, 5), " (expected: 148.40000)");
    Print("  TP1: ", DoubleToString(tp1, 5), " (expected: 146.70000)");
    Print("  Risk: ", DoubleToString(risk, 0), " (expected: 1)");
    
    bool extract_ok = (id == "sig_2025-09-23T10:04:16" && 
                      symbol == "USDJPY" && 
                      direction == "sell" && 
                      entry_type == "limit" &&
                      MathAbs(entry_price - 148.25000) < 0.00001 &&
                      MathAbs(sl - 148.40000) < 0.00001 &&
                      MathAbs(tp1 - 146.70000) < 0.00001 &&
                      MathAbs(risk - 1.0) < 0.00001);
    
    test2_pass = extract_ok;
    Print("  Extraction: ", (extract_ok ? "PASSED" : "FAILED"));
    
    // Test 3: Array parsing simulation
    Print("\n--- Test 3: Array Parsing Simulation ---");
    bool test3_pass = true;
    
    string array_content = sample_multiple_signals;
    
    // Find array boundaries
    int array_start = StringFind(array_content, "[");
    int array_end = StringFind(array_content, "]", array_start);
    
    if(array_start == -1 || array_end == -1) {
        Print("  ERROR: Could not find array boundaries");
        test3_pass = false;
    } else {
        Print("  Array boundaries found: start=", array_start, ", end=", array_end);
        
        // Extract array content
        string content = StringSubstr(array_content, array_start + 1, array_end - array_start - 1);
        Print("  Array content length: ", StringLen(content));
        
        // Count signals by counting opening braces
        int signal_count = 0;
        int brace_count = 0;
        bool in_string = false;
        
        for(int i = 0; i < StringLen(content); i++) {
            int ch = StringGetCharacter(content, i);
            
            if(ch == '"') {
                in_string = !in_string;
                continue;
            }
            
            if(!in_string) {
                if(ch == '{') {
                    if(brace_count == 0) {
                        signal_count++;
                    }
                    brace_count++;
                } else if(ch == '}') {
                    brace_count--;
                }
            }
        }
        
        Print("  Detected signals: ", signal_count, " (expected: 2)");
        test3_pass = (signal_count == 2);
    }
    
    // Test 4: Edge cases
    Print("\n--- Test 4: Edge Cases ---");
    bool test4_pass = true;
    
    // Empty array
    bool empty_array_result = IsJSONArray("[]");
    Print("  Empty array detection: ", (empty_array_result ? "PASSED" : "FAILED"));
    test4_pass = test4_pass && empty_array_result;
    
    // Malformed JSON
    bool malformed_result = IsJSONArray("{malformed");
    Print("  Malformed JSON rejection: ", (!malformed_result ? "PASSED" : "FAILED"));
    test4_pass = test4_pass && !malformed_result;
    
    // Array with extra whitespace
    bool whitespace_result = IsJSONArray("  \n\t  [  {\"test\":\"value\"}  ]  \t\n  ");
    Print("  Whitespace handling: ", (whitespace_result ? "PASSED" : "FAILED"));
    test4_pass = test4_pass && whitespace_result;
    
    // Final summary
    Print("\n=== TEST SUMMARY ===");
    Print("Test 1 (Array Detection): ", (test1_pass ? "PASSED" : "FAILED"));
    Print("Test 2 (Field Extraction): ", (test2_pass ? "PASSED" : "FAILED"));
    Print("Test 3 (Array Parsing): ", (test3_pass ? "PASSED" : "FAILED"));
    Print("Test 4 (Edge Cases): ", (test4_pass ? "PASSED" : "FAILED"));
    
    bool all_passed = test1_pass && test2_pass && test3_pass && test4_pass;
    Print("OVERALL RESULT: ", (all_passed ? "ALL TESTS PASSED ✅" : "SOME TESTS FAILED ❌"));
    
    if(all_passed) {
        Print("Implementation is ready for production use!");
    } else {
        Print("Review failed tests and fix implementation.");
    }
}

//+------------------------------------------------------------------+
//| Script start function                                            |
//+------------------------------------------------------------------+
void OnStart() {
    TestComprehensiveMultipleSignals();
}