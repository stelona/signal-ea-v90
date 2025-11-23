//+------------------------------------------------------------------+
//|                                              MT5_Auto_Login.mq5  |
//|                                    Copyright 2024, Stelona       |
//|                                     https://www.stelona.com      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Stelona"
#property link      "https://www.stelona.com"
#property version   "1.00"
#property description "Automatisches Login-Script für MetaTrader 5"
#property description "Liest Login-Daten aus lokaler Datei und validiert den Login-Status"
#property script_show_inputs

//--- Input Parameter
input string ConfigFileName = "mt5_login_config.txt";  // Konfigurationsdatei Name
input bool   DebugMode = true;                         // Debug-Modus aktivieren

//--- Struktur für Login-Daten
struct LoginData
{
   long     account;        // Account-Nummer
   string   password;       // Passwort
   string   server;         // Server-Name
   bool     isValid;        // Validierungsstatus
};

//+------------------------------------------------------------------+
//| Script program start function                                     |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("═══════════════════════════════════════════════════════════");
   Print("     MT5 Auto-Login Script v1.0 - Stelona");
   Print("═══════════════════════════════════════════════════════════");

   //--- Login-Daten aus Datei lesen
   LoginData loginData;
   if(!ReadLoginConfig(ConfigFileName, loginData))
   {
      Alert("FEHLER: Konfigurationsdatei konnte nicht gelesen werden!");
      Print("Bitte stellen Sie sicher, dass die Datei existiert:");
      Print("Pfad: ", TerminalInfoString(TERMINAL_DATA_PATH), "\\MQL5\\Files\\", ConfigFileName);
      return;
   }

   //--- Aktuelle Account-Informationen abrufen
   long currentAccount = AccountInfoInteger(ACCOUNT_LOGIN);
   string currentServer = AccountInfoString(ACCOUNT_SERVER);

   Print("\n--- AKTUELLE VERBINDUNG ---");
   Print("Account: ", currentAccount);
   Print("Server:  ", currentServer);
   Print("Broker:  ", AccountInfoString(ACCOUNT_COMPANY));

   Print("\n--- KONFIGURIERTE DATEN ---");
   Print("Account: ", loginData.account);
   Print("Server:  ", loginData.server);

   //--- Broker/Server-Suche
   Print("\n--- BROKER-SUCHE ---");
   if(!SearchAndValidateBroker(loginData.server))
   {
      Alert("WARNUNG: Server '", loginData.server, "' konnte nicht gefunden werden!");
      Print("Verfügbare Server werden gesucht...");
      ListAvailableServers();
   }

   //--- Login-Status prüfen
   Print("\n--- LOGIN-STATUS ---");
   if(currentAccount == loginData.account && StringCompare(currentServer, loginData.server, false) == 0)
   {
      Print("✓ SIE SIND BEREITS MIT DEM KORREKTEN ACCOUNT EINGELOGGT!");
      Print("✓ Account: ", currentAccount);
      Print("✓ Server:  ", currentServer);

      //--- Verbindungsstatus prüfen
      if(TerminalInfoInteger(TERMINAL_CONNECTED))
      {
         Print("✓ Verbindung aktiv");
      }
      else
      {
         Alert("⚠ Verbindung zum Server unterbrochen!");
         Print("Bitte prüfen Sie Ihre Internetverbindung");
      }
   }
   else
   {
      Print("✗ SIE SIND MIT EINEM ANDEREN ACCOUNT EINGELOGGT");
      Print("\nUm sich mit dem konfigurierten Account einzuloggen:");
      Print("1. Öffnen Sie MetaTrader 5");
      Print("2. Gehen Sie zu: Datei → Bei Handelskonto anmelden");
      Print("3. Geben Sie folgende Daten ein:");
      Print("   - Login:  ", loginData.account);
      Print("   - Server: ", loginData.server);
      Print("   - Passwort: [aus Konfigurationsdatei]");
      Print("\nODER verwenden Sie das generierte Login-Script:");
      GenerateLoginScript(loginData);
   }

   //--- Zusätzliche Account-Informationen
   Print("\n--- ACCOUNT-INFORMATIONEN ---");
   Print("Name:           ", AccountInfoString(ACCOUNT_NAME));
   Print("Balance:        ", AccountInfoDouble(ACCOUNT_BALANCE), " ", AccountInfoString(ACCOUNT_CURRENCY));
   Print("Eigenkapital:   ", AccountInfoDouble(ACCOUNT_EQUITY), " ", AccountInfoString(ACCOUNT_CURRENCY));
   Print("Hebel:          1:", AccountInfoInteger(ACCOUNT_LEVERAGE));
   Print("Handelserlaubt: ", (AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ? "Ja" : "Nein"));
   Print("Expert Advisors:", (AccountInfoInteger(ACCOUNT_TRADE_EXPERT) ? "Erlaubt" : "Nicht erlaubt"));

   Print("\n═══════════════════════════════════════════════════════════");
   Print("     Auto-Login Check abgeschlossen");
   Print("═══════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Liest Login-Konfiguration aus Datei                              |
//+------------------------------------------------------------------+
bool ReadLoginConfig(string fileName, LoginData &data)
{
   //--- Struktur initialisieren
   data.account = 0;
   data.password = "";
   data.server = "";
   data.isValid = false;

   //--- Datei öffnen
   int fileHandle = FileOpen(fileName, FILE_READ|FILE_TXT|FILE_ANSI);

   if(fileHandle == INVALID_HANDLE)
   {
      Print("FEHLER: Konfigurationsdatei '", fileName, "' konnte nicht geöffnet werden");
      Print("Error Code: ", GetLastError());
      return false;
   }

   if(DebugMode)
      Print("Lese Konfigurationsdatei: ", fileName);

   //--- Datei zeilenweise lesen
   while(!FileIsEnding(fileHandle))
   {
      string line = FileReadString(fileHandle);

      //--- Kommentare und leere Zeilen überspringen
      if(StringLen(line) == 0 || StringSubstr(line, 0, 1) == "#" || StringSubstr(line, 0, 2) == "//")
         continue;

      //--- Zeile parsen (Format: KEY=VALUE)
      int separatorPos = StringFind(line, "=");
      if(separatorPos > 0)
      {
         string key = StringSubstr(line, 0, separatorPos);
         string value = StringSubstr(line, separatorPos + 1);

         //--- Whitespace entfernen
         StringTrimLeft(key);
         StringTrimRight(key);
         StringTrimLeft(value);
         StringTrimRight(value);

         //--- Werte zuweisen
         if(StringCompare(key, "ACCOUNT", false) == 0 || StringCompare(key, "LOGIN", false) == 0)
         {
            data.account = StringToInteger(value);
            if(DebugMode)
               Print("  Account: ", data.account);
         }
         else if(StringCompare(key, "PASSWORD", false) == 0 || StringCompare(key, "PASS", false) == 0)
         {
            data.password = value;
            if(DebugMode)
               Print("  Passwort: ******* (versteckt)");
         }
         else if(StringCompare(key, "SERVER", false) == 0 || StringCompare(key, "BROKER", false) == 0)
         {
            data.server = value;
            if(DebugMode)
               Print("  Server: ", data.server);
         }
      }
   }

   FileClose(fileHandle);

   //--- Validierung
   if(data.account > 0 && StringLen(data.password) > 0 && StringLen(data.server) > 0)
   {
      data.isValid = true;
      Print("✓ Konfigurationsdatei erfolgreich gelesen");
      return true;
   }
   else
   {
      Print("✗ FEHLER: Unvollständige Konfigurationsdaten!");
      if(data.account <= 0)
         Print("  - Account-Nummer fehlt oder ungültig");
      if(StringLen(data.password) == 0)
         Print("  - Passwort fehlt");
      if(StringLen(data.server) == 0)
         Print("  - Server fehlt");
      return false;
   }
}

//+------------------------------------------------------------------+
//| Sucht und validiert Broker/Server                                |
//+------------------------------------------------------------------+
bool SearchAndValidateBroker(string serverName)
{
   //--- Aktuellen Server prüfen
   string currentServer = AccountInfoString(ACCOUNT_SERVER);

   if(StringCompare(currentServer, serverName, false) == 0)
   {
      Print("✓ Server gefunden: ", serverName);
      Print("  Dies ist Ihr aktueller Server");
      return true;
   }

   //--- Server-Name-Varianten prüfen (manche Broker haben Suffixe)
   string serverVariants[];
   ArrayResize(serverVariants, 5);
   serverVariants[0] = serverName;
   serverVariants[1] = serverName + "-Demo";
   serverVariants[2] = serverName + "-Live";
   serverVariants[3] = serverName + "-Real";
   serverVariants[4] = serverName + "-Server";

   for(int i = 0; i < ArraySize(serverVariants); i++)
   {
      if(StringCompare(currentServer, serverVariants[i], false) == 0)
      {
         Print("✓ Server gefunden (Variante): ", serverVariants[i]);
         return true;
      }
   }

   //--- Teilstring-Suche
   if(StringFind(currentServer, serverName, 0) >= 0)
   {
      Print("✓ Server teilweise gefunden in: ", currentServer);
      return true;
   }

   Print("✗ Server '", serverName, "' nicht gefunden");
   Print("  Aktueller Server: ", currentServer);
   return false;
}

//+------------------------------------------------------------------+
//| Listet verfügbare Server auf                                     |
//+------------------------------------------------------------------+
void ListAvailableServers()
{
   Print("\nHINWEIS: Verfügbare Server können nur in der Terminal-UI eingesehen werden.");
   Print("Öffnen Sie: Datei → Bei Handelskonto anmelden → Server-Liste");
   Print("\nAktuell verbundener Server:");
   Print("  - ", AccountInfoString(ACCOUNT_SERVER));
   Print("  - Broker: ", AccountInfoString(ACCOUNT_COMPANY));
}

//+------------------------------------------------------------------+
//| Generiert externes Login-Script                                  |
//+------------------------------------------------------------------+
void GenerateLoginScript(LoginData &data)
{
   string scriptContent = "";

   //--- Batch-Script für Windows generieren
   #ifdef __WIN32__
   string batchFile = "mt5_auto_login.bat";
   int fileHandle = FileOpen(batchFile, FILE_WRITE|FILE_TXT|FILE_ANSI);

   if(fileHandle != INVALID_HANDLE)
   {
      scriptContent = "@echo off\n";
      scriptContent += "echo ========================================\n";
      scriptContent += "echo MT5 Auto-Login Script\n";
      scriptContent += "echo ========================================\n";
      scriptContent += "echo.\n";
      scriptContent += "echo Account: " + IntegerToString(data.account) + "\n";
      scriptContent += "echo Server:  " + data.server + "\n";
      scriptContent += "echo.\n";
      scriptContent += "echo Starte MetaTrader 5 mit Login-Parametern...\n";
      scriptContent += "echo.\n";
      scriptContent += "\n";
      scriptContent += "REM MetaTrader 5 Terminal-Pfad (bitte anpassen falls nötig)\n";
      scriptContent += "set MT5_PATH=\"C:\\Program Files\\MetaTrader 5\\terminal64.exe\"\n";
      scriptContent += "\n";
      scriptContent += "REM Login mit Parametern\n";
      scriptContent += "start \"\" %MT5_PATH% /login:" + IntegerToString(data.account) +
                       " /server:\"" + data.server + "\" /password:\"" + data.password + "\"\n";
      scriptContent += "\n";
      scriptContent += "echo.\n";
      scriptContent += "echo MetaTrader 5 wurde gestartet.\n";
      scriptContent += "echo Bitte warten Sie auf die Verbindung...\n";
      scriptContent += "pause\n";

      FileWriteString(fileHandle, scriptContent);
      FileClose(fileHandle);

      string fullPath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + batchFile;
      Print("\n✓ Login-Script generiert:");
      Print("  Pfad: ", fullPath);
      Print("\nFühren Sie dieses Script aus, um sich automatisch einzuloggen.");
   }
   #endif

   //--- Informationen für manuellen Login
   Print("\n--- MANUELLE LOGIN-ANLEITUNG ---");
   Print("Falls das automatische Script nicht funktioniert:");
   Print("1. Schließen Sie MetaTrader 5");
   Print("2. Starten Sie MT5 mit folgenden Parametern:");
   Print("   terminal64.exe /login:", data.account, " /server:\"", data.server, "\" /password:\"****\"");
}

//+------------------------------------------------------------------+
//| String Trim-Funktionen (Helper)                                  |
//+------------------------------------------------------------------+
void StringTrimLeft(string &str)
{
   StringReplace(str, " ", "");
   StringReplace(str, "\t", "");
   StringReplace(str, "\r", "");
   StringReplace(str, "\n", "");
}

void StringTrimRight(string &str)
{
   StringTrimLeft(str); // Vereinfachte Version
}
//+------------------------------------------------------------------+
