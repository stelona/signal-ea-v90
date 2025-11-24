//+------------------------------------------------------------------+
//|                                                   ChartSetup.mq5 |
//|                                          Copyright 2024, Stelona |
//|                                      https://github.com/stelona/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Stelona"
#property link      "https://github.com/stelona/"
#property version   "1.00"
#property description "Bootstrap EA - Finds BTCUSD with broker suffix and loads signal.ex5"
#property description "Run this EA on any safe symbol (EURUSD, GBPUSD, etc.)"
#property strict

//--- Input Parameters
input string TargetSymbolBase = "BTCUSD";        // Base symbol to search for
input string TargetEA = "signal.ex5";            // EA to load on target chart
input ENUM_TIMEFRAMES TargetTimeframe = PERIOD_H1; // Timeframe for target chart
input bool RemoveSelfAfterSetup = true;          // Remove this EA after successful setup
input int SetupDelaySeconds = 5;                 // Delay before setup (wait for MT5 to fully load)

//--- Global Variables
bool g_SetupCompleted = false;
datetime g_SetupTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════════");
   Print("  ChartSetup EA - Broker-Neutral Chart Loader");
   Print("  Version 1.0 - Stelona");
   Print("═══════════════════════════════════════════════════════════");

   // Schedule setup to run after delay
   g_SetupTime = TimeCurrent() + SetupDelaySeconds;

   Print("Setup will run in ", SetupDelaySeconds, " seconds...");
   Print("Target Symbol: ", TargetSymbolBase);
   Print("Target EA: ", TargetEA);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("ChartSetup EA stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Run setup only once and after delay
   if(!g_SetupCompleted && TimeCurrent() >= g_SetupTime)
   {
      g_SetupCompleted = true;
      PerformChartSetup();
   }
}

//+------------------------------------------------------------------+
//| Find symbol with any suffix                                      |
//+------------------------------------------------------------------+
string FindSymbolWithSuffix(string baseSymbol)
{
   Print("═══════════════════════════════════════════════════════════");
   Print("  Searching for symbol: ", baseSymbol);
   Print("═══════════════════════════════════════════════════════════");

   int totalSymbols = SymbolsTotal(true);
   Print("Total symbols available: ", totalSymbols);

   string foundSymbols[];
   int foundCount = 0;

   // Search for symbols containing the base name
   for(int i = 0; i < totalSymbols; i++)
   {
      string symbolName = SymbolName(i, true);

      // Check if symbol contains base name
      if(StringFind(symbolName, baseSymbol) >= 0)
      {
         // Check if symbol is available for trading
         if(SymbolInfoInteger(symbolName, SYMBOL_SELECT))
         {
            ArrayResize(foundSymbols, foundCount + 1);
            foundSymbols[foundCount] = symbolName;
            foundCount++;
            Print("  Found: ", symbolName);
         }
      }
   }

   if(foundCount == 0)
   {
      Print("✗ ERROR: Symbol '", baseSymbol, "' not found!");
      return "";
   }

   // Prioritize exact match
   for(int i = 0; i < foundCount; i++)
   {
      if(foundSymbols[i] == baseSymbol)
      {
         Print("✓ Using exact match: ", baseSymbol);
         return baseSymbol;
      }
   }

   // Use first found variant
   string selectedSymbol = foundSymbols[0];
   Print("✓ Using symbol: ", selectedSymbol);

   // Extract suffix
   string suffix = "";
   if(StringLen(selectedSymbol) > StringLen(baseSymbol))
   {
      suffix = StringSubstr(selectedSymbol, StringLen(baseSymbol));
      Print("  Detected suffix: '", suffix, "'");
   }

   return selectedSymbol;
}

//+------------------------------------------------------------------+
//| Check if chart already exists for symbol                         |
//+------------------------------------------------------------------+
bool ChartAlreadyExists(string symbol, ENUM_TIMEFRAMES timeframe)
{
   long chartId = ChartFirst();

   while(chartId >= 0)
   {
      string chartSymbol = ChartSymbol(chartId);
      ENUM_TIMEFRAMES chartTF = (ENUM_TIMEFRAMES)ChartPeriod(chartId);

      if(chartSymbol == symbol && chartTF == timeframe)
      {
         Print("ℹ Chart already exists: ", symbol, " ", EnumToString(timeframe));
         return true;
      }

      chartId = ChartNext(chartId);
   }

   return false;
}

//+------------------------------------------------------------------+
//| Perform the chart setup                                          |
//+------------------------------------------------------------------+
void PerformChartSetup()
{
   Print("═══════════════════════════════════════════════════════════");
   Print("  Starting Chart Setup");
   Print("═══════════════════════════════════════════════════════════");

   // Step 1: Find target symbol with suffix
   string targetSymbol = FindSymbolWithSuffix(TargetSymbolBase);

   if(targetSymbol == "")
   {
      Print("✗ Setup FAILED: Target symbol not found");
      return;
   }

   // Step 2: Check if chart already exists
   if(ChartAlreadyExists(targetSymbol, TargetTimeframe))
   {
      Print("✓ Setup SKIPPED: Chart already exists");

      if(RemoveSelfAfterSetup)
      {
         Print("Removing ChartSetup EA from current chart...");
         ExpertRemove();
      }

      return;
   }

   // Step 3: Open new chart
   Print("═══════════════════════════════════════════════════════════");
   Print("  Opening new chart");
   Print("═══════════════════════════════════════════════════════════");
   Print("Symbol: ", targetSymbol);
   Print("Timeframe: ", EnumToString(TargetTimeframe));

   long newChartId = ChartOpen(targetSymbol, TargetTimeframe);

   if(newChartId == 0)
   {
      Print("✗ ERROR: Failed to open chart for ", targetSymbol);
      return;
   }

   Print("✓ Chart opened successfully (ID: ", newChartId, ")");

   // Step 4: Apply EA to new chart (via template)
   Print("═══════════════════════════════════════════════════════════");
   Print("  Loading EA on chart");
   Print("═══════════════════════════════════════════════════════════");

   // Create a template file with EA configuration
   string templateContent = CreateEATemplate(targetSymbol, TargetEA);
   string templatePath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Profiles\\Templates\\AutoEA.tpl";

   // Write template file
   int fileHandle = FileOpen("..\\Profiles\\Templates\\AutoEA.tpl", FILE_WRITE|FILE_TXT);

   if(fileHandle != INVALID_HANDLE)
   {
      FileWriteString(fileHandle, templateContent);
      FileClose(fileHandle);

      Print("✓ Template created: AutoEA.tpl");

      // Apply template to chart
      Sleep(1000); // Wait for file to be written

      if(ChartApplyTemplate(newChartId, "AutoEA.tpl"))
      {
         Print("✓ EA template applied successfully");
      }
      else
      {
         Print("⚠ WARNING: Failed to apply template");
         Print("  Please manually add ", TargetEA, " to the chart");
      }
   }
   else
   {
      Print("✗ ERROR: Failed to create template file");
      Print("  Error code: ", GetLastError());
   }

   // Step 5: Cleanup
   Print("═══════════════════════════════════════════════════════════");
   Print("  ✓ SETUP COMPLETED!");
   Print("═══════════════════════════════════════════════════════════");
   Print("Chart: ", targetSymbol, " ", EnumToString(TargetTimeframe));
   Print("EA: ", TargetEA);

   if(RemoveSelfAfterSetup)
   {
      Print("Removing ChartSetup EA from bootstrap chart...");
      Sleep(2000); // Wait before removal
      ExpertRemove();
   }
}

//+------------------------------------------------------------------+
//| Create template content for EA                                   |
//+------------------------------------------------------------------+
string CreateEATemplate(string symbol, string eaName)
{
   string template = "<chart>\n";
   template += "symbol=" + symbol + "\n";
   template += "period=" + IntegerToString(TargetTimeframe) + "\n";
   template += "<expert>\n";
   template += "name=" + eaName + "\n";
   template += "path=Experts\\\\" + eaName + "\n";
   template += "expertmode=1\n";
   template += "</expert>\n";
   template += "</chart>\n";

   return template;
}
//+------------------------------------------------------------------+
