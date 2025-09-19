//+------------------------------------------------------------------+
//|                                           Lotsize Tests v9.0    |
//|                                          Copyright 2024, Stelona |
//|                                       https://www.stelona.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Stelona"
#property link      "https://www.stelona.com"
#property version   "9.0"
#property script_show_inputs

#include "../src/modules/Lotsize_v90_Enhanced.mqh"

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "=== Test Configuration ==="
input bool run_jpy_tests = true;        // Run JPY-pair tests
input bool run_forex_tests = true;      // Run standard Forex tests
input bool run_gold_tests = true;       // Run Gold/XAU tests
input bool run_validation_tests = true; // Run validation tests
input bool run_edge_case_tests = true;  // Run edge case tests

//+------------------------------------------------------------------+
//| Test Results Structure                                           |
//+------------------------------------------------------------------+
struct TestResult {
    string test_name;
    bool passed;
    string details;
    double expected;
    double actual;
    double tolerance;
};

TestResult test_results[];

//+------------------------------------------------------------------+
//| Test Helper Functions                                            |
//+------------------------------------------------------------------+
void AddTestResult(string test_name, bool passed, string details, double expected = 0, double actual = 0, double tolerance = 0.01) {
    int size = ArraySize(test_results);
    ArrayResize(test_results, size + 1);
    
    test_results[size].test_name = test_name;
    test_results[size].passed = passed;
    test_results[size].details = details;
    test_results[size].expected = expected;
    test_results[size].actual = actual;
    test_results[size].tolerance = tolerance;
}

bool IsWithinTolerance(double actual, double expected, double tolerance) {
    return MathAbs(actual - expected) <= tolerance;
}

void LogTestResult(string test_name, bool passed, string details = "") {
    string status = passed ? "✅ PASS" : "❌ FAIL";
    Print("[TEST] ", status, " - ", test_name);
    if(details != "") Print("       ", details);
}

//+------------------------------------------------------------------+
//| JPY-Pair Tests                                                   |
//+------------------------------------------------------------------+
void RunJPYTests() {
    Print("🇯🇵 Running JPY-Pair Tests...");
    
    // Test 1: JPY-Pair Detection
    bool usdjpy_detected = IsJPYPair("USDJPY");
    LogTestResult("JPY Detection - USDJPY", usdjpy_detected, "Should detect USDJPY as JPY pair");
    AddTestResult("JPY Detection - USDJPY", usdjpy_detected, "USDJPY detection");
    
    bool eurjpy_detected = IsJPYPair("EURJPY");
    LogTestResult("JPY Detection - EURJPY", eurjpy_detected, "Should detect EURJPY as JPY pair");
    AddTestResult("JPY Detection - EURJPY", eurjpy_detected, "EURJPY detection");
    
    bool eurusd_not_detected = !IsJPYPair("EURUSD");
    LogTestResult("JPY Detection - EURUSD (negative)", eurusd_not_detected, "Should NOT detect EURUSD as JPY pair");
    AddTestResult("JPY Detection - EURUSD (negative)", eurusd_not_detected, "EURUSD should not be JPY");
    
    // Test 2: JPY-Pair with Broker Suffixes
    bool usdjpy_suffix = IsJPYPair("USDJPYs");
    LogTestResult("JPY Detection - Suffix", usdjpy_suffix, "Should detect USDJPYs as JPY pair");
    AddTestResult("JPY Detection - Suffix", usdjpy_suffix, "USDJPYs with suffix detection");
    
    // Test 3: JPY Loss Calculation
    string error_msg = "";
    double jpy_loss = CalculateJPYLossPerLot_v90("USDJPY", 148.000, 148.400, error_msg);
    bool jpy_calc_success = (jpy_loss > 0 && error_msg == "");
    LogTestResult("JPY Loss Calculation", jpy_calc_success, 
                  "Entry: 148.000, SL: 148.400, Result: " + DoubleToString(jpy_loss, 2));
    AddTestResult("JPY Loss Calculation", jpy_calc_success, "JPY loss calculation success", 0, jpy_loss);
    
    // Test 4: JPY Pip Value Validation
    if(jpy_loss > 0) {
        double distance = 0.400; // 148.400 - 148.000
        double pips = distance / 0.01; // Should be 40 pips
        double expected_range_min = pips * 0.5; // Conservative: 0.5 EUR per pip
        double expected_range_max = pips * 5.0;  // Liberal: 5 EUR per pip
        
        bool pip_value_realistic = (jpy_loss >= expected_range_min && jpy_loss <= expected_range_max);
        LogTestResult("JPY Pip Value Realistic", pip_value_realistic,
                      "Loss: " + DoubleToString(jpy_loss, 2) + " EUR, Expected: " + 
                      DoubleToString(expected_range_min, 2) + "-" + DoubleToString(expected_range_max, 2) + " EUR");
        AddTestResult("JPY Pip Value Realistic", pip_value_realistic, "JPY pip value within realistic range");
    }
}

//+------------------------------------------------------------------+
//| Standard Forex Tests                                             |
//+------------------------------------------------------------------+
void RunForexTests() {
    Print("💱 Running Standard Forex Tests...");
    
    // Test 1: EURUSD Calculation
    string message = "";
    double eurusd_lots = CalculateLots_v90_Enhanced("EURUSD", 1.0950, 1.0900, 2.0, ORDER_TYPE_BUY, message);
    bool eurusd_success = (eurusd_lots > 0);
    LogTestResult("EURUSD Lotsize Calculation", eurusd_success,
                  "Entry: 1.0950, SL: 1.0900, Risk: 2%, Result: " + DoubleToString(eurusd_lots, 3) + " lots");
    AddTestResult("EURUSD Lotsize Calculation", eurusd_success, message, 0, eurusd_lots);
    
    // Test 2: GBPUSD Calculation
    double gbpusd_lots = CalculateLots_v90_Enhanced("GBPUSD", 1.2500, 1.2450, 1.5, ORDER_TYPE_BUY, message);
    bool gbpusd_success = (gbpusd_lots > 0);
    LogTestResult("GBPUSD Lotsize Calculation", gbpusd_success,
                  "Entry: 1.2500, SL: 1.2450, Risk: 1.5%, Result: " + DoubleToString(gbpusd_lots, 3) + " lots");
    AddTestResult("GBPUSD Lotsize Calculation", gbpusd_success, message, 0, gbpusd_lots);
    
    // Test 3: Risk Validation
    if(eurusd_lots > 0) {
        // Calculate actual risk
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        if(balance > 0) {
            // This is a simplified risk check - in real scenario we'd need the actual loss per lot
            bool risk_reasonable = (eurusd_lots <= balance * 0.001); // Very conservative check
            LogTestResult("EURUSD Risk Reasonable", risk_reasonable,
                          "Lotsize: " + DoubleToString(eurusd_lots, 3) + ", Balance: " + DoubleToString(balance, 2));
            AddTestResult("EURUSD Risk Reasonable", risk_reasonable, "Risk appears reasonable");
        }
    }
}

//+------------------------------------------------------------------+
//| Gold Tests                                                       |
//+------------------------------------------------------------------+
void RunGoldTests() {
    Print("🥇 Running Gold/XAU Tests...");
    
    // Test 1: XAUUSD Calculation
    string message = "";
    double gold_lots = CalculateLots_v90_Enhanced("XAUUSD", 2000.00, 1980.00, 3.0, ORDER_TYPE_BUY, message);
    bool gold_success = (gold_lots > 0);
    LogTestResult("XAUUSD Lotsize Calculation", gold_success,
                  "Entry: 2000.00, SL: 1980.00, Risk: 3%, Result: " + DoubleToString(gold_lots, 3) + " lots");
    AddTestResult("XAUUSD Lotsize Calculation", gold_success, message, 0, gold_lots);
    
    // Test 2: Alternative Gold Symbol
    double gold_alt_lots = CalculateLots_v90_Enhanced("GOLD", 2000.00, 1980.00, 3.0, ORDER_TYPE_BUY, message);
    bool gold_alt_success = (gold_alt_lots > 0);
    LogTestResult("GOLD Symbol Calculation", gold_alt_success,
                  "Entry: 2000.00, SL: 1980.00, Risk: 3%, Result: " + DoubleToString(gold_alt_lots, 3) + " lots");
    AddTestResult("GOLD Symbol Calculation", gold_alt_success, message, 0, gold_alt_lots);
}

//+------------------------------------------------------------------+
//| Validation Tests                                                 |
//+------------------------------------------------------------------+
void RunValidationTests() {
    Print("🔍 Running Validation Tests...");
    
    // Test 1: Validation Function - Valid Value
    string validation_msg = "";
    bool valid_forex = ValidateLossPerLot_v90("EURUSD", 10.0, 0.0050, validation_msg);
    LogTestResult("Validation - Valid Forex", valid_forex, validation_msg);
    AddTestResult("Validation - Valid Forex", valid_forex, validation_msg);
    
    // Test 2: Validation Function - Invalid Value (too small)
    bool invalid_small = !ValidateLossPerLot_v90("EURUSD", 0.001, 0.0050, validation_msg);
    LogTestResult("Validation - Too Small", invalid_small, validation_msg);
    AddTestResult("Validation - Too Small", invalid_small, validation_msg);
    
    // Test 3: Validation Function - Invalid Value (too large)
    bool invalid_large = !ValidateLossPerLot_v90("EURUSD", 10000.0, 0.0050, validation_msg);
    LogTestResult("Validation - Too Large", invalid_large, validation_msg);
    AddTestResult("Validation - Too Large", invalid_large, validation_msg);
    
    // Test 4: JPY Validation
    bool valid_jpy = ValidateLossPerLot_v90("USDJPY", 40.0, 0.400, validation_msg);
    LogTestResult("Validation - Valid JPY", valid_jpy, validation_msg);
    AddTestResult("Validation - Valid JPY", valid_jpy, validation_msg);
}

//+------------------------------------------------------------------+
//| Edge Case Tests                                                  |
//+------------------------------------------------------------------+
void RunEdgeCaseTests() {
    Print("⚠️ Running Edge Case Tests...");
    
    // Test 1: Zero Risk
    string message = "";
    double zero_risk_lots = CalculateLots_v90_Enhanced("EURUSD", 1.0950, 1.0900, 0.0, ORDER_TYPE_BUY, message);
    bool zero_risk_handled = (zero_risk_lots <= 0);
    LogTestResult("Zero Risk Handling", zero_risk_handled, "Should reject zero risk: " + message);
    AddTestResult("Zero Risk Handling", zero_risk_handled, message);
    
    // Test 2: Negative Risk
    double negative_risk_lots = CalculateLots_v90_Enhanced("EURUSD", 1.0950, 1.0900, -1.0, ORDER_TYPE_BUY, message);
    bool negative_risk_handled = (negative_risk_lots <= 0);
    LogTestResult("Negative Risk Handling", negative_risk_handled, "Should reject negative risk: " + message);
    AddTestResult("Negative Risk Handling", negative_risk_handled, message);
    
    // Test 3: Same Entry and SL
    double same_price_lots = CalculateLots_v90_Enhanced("EURUSD", 1.0950, 1.0950, 2.0, ORDER_TYPE_BUY, message);
    bool same_price_handled = (same_price_lots <= 0);
    LogTestResult("Same Entry/SL Handling", same_price_handled, "Should reject same entry/SL: " + message);
    AddTestResult("Same Entry/SL Handling", same_price_handled, message);
    
    // Test 4: Very High Risk
    double high_risk_lots = CalculateLots_v90_Enhanced("EURUSD", 1.0950, 1.0900, 50.0, ORDER_TYPE_BUY, message);
    bool high_risk_result = (high_risk_lots > 0); // Should still work but with warnings
    LogTestResult("High Risk Handling", high_risk_result, "50% risk: " + message);
    AddTestResult("High Risk Handling", high_risk_result, message);
    
    // Test 5: Invalid Symbol
    double invalid_symbol_lots = CalculateLots_v90_Enhanced("INVALID", 1.0000, 0.9950, 2.0, ORDER_TYPE_BUY, message);
    bool invalid_symbol_handled = (invalid_symbol_lots <= 0);
    LogTestResult("Invalid Symbol Handling", invalid_symbol_handled, "Should reject invalid symbol: " + message);
    AddTestResult("Invalid Symbol Handling", invalid_symbol_handled, message);
}

//+------------------------------------------------------------------+
//| Test Summary                                                     |
//+------------------------------------------------------------------+
void PrintTestSummary() {
    Print("📊 TEST SUMMARY");
    Print("================");
    
    int total_tests = ArraySize(test_results);
    int passed_tests = 0;
    int failed_tests = 0;
    
    for(int i = 0; i < total_tests; i++) {
        if(test_results[i].passed) {
            passed_tests++;
        } else {
            failed_tests++;
            Print("❌ FAILED: ", test_results[i].test_name, " - ", test_results[i].details);
        }
    }
    
    double success_rate = (total_tests > 0) ? (double)passed_tests / total_tests * 100.0 : 0.0;
    
    Print("Total Tests: ", total_tests);
    Print("Passed: ", passed_tests);
    Print("Failed: ", failed_tests);
    Print("Success Rate: ", DoubleToString(success_rate, 1), "%");
    
    if(failed_tests == 0) {
        Print("🎉 ALL TESTS PASSED! v9.0 Lotsize Module is working correctly.");
    } else {
        Print("⚠️ Some tests failed. Please review the failed tests above.");
    }
    
    Print("================");
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
    Print("🧪 Starting Lotsize v9.0 Test Suite");
    Print("====================================");
    
    // Initialize test results array
    ArrayResize(test_results, 0);
    
    // Run test suites based on input parameters
    if(run_jpy_tests) {
        RunJPYTests();
        Print("");
    }
    
    if(run_forex_tests) {
        RunForexTests();
        Print("");
    }
    
    if(run_gold_tests) {
        RunGoldTests();
        Print("");
    }
    
    if(run_validation_tests) {
        RunValidationTests();
        Print("");
    }
    
    if(run_edge_case_tests) {
        RunEdgeCaseTests();
        Print("");
    }
    
    // Print summary
    PrintTestSummary();
    
    Print("🧪 Test Suite Completed");
}
