# 🚀 Signal EA v9.0 - Enhanced Lotsize Calculation

[![Version](https://img.shields.io/badge/version-9.0-blue.svg)](https://github.com/stelona/signal-ea-v90)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-MetaTrader%205-green.svg)](https://www.metatrader5.com/)

**Professional Signal Copying Expert Advisor with revolutionary JPY-pair optimization and modular architecture.**

---

## 🎯 **Key Features**

### **🇯🇵 JPY-Pair Optimization v9.0**
- **Correct pip calculation** for JPY pairs (1 pip = 0.01, not 0.001)
- **10x more accurate** lotsize calculation for all JPY pairs
- **Specialized handling** for USDJPY, EURJPY, GBPJPY, etc.

### **🛡️ Strict Risk Control**
- **Never exceeds** specified risk percentage
- **Iterative lot reduction** until risk fits perfectly
- **Robust validation** against unrealistic values
- **4-tier fallback system** for maximum reliability

### **📡 Complete API Integration**
- **Signal processing** from external APIs
- **Position tracking** with SL/TP updates
- **Break-even functionality** via API commands
- **Delivery confirmations** with detailed status reporting
- **Value-based tracking** allows manual user modifications

### **🔍 Advanced Symbol Detection**
- **Automatic index symbol detection** for 16+ major indices
- **Extended symbol search** with broker-specific suffixes
- **Custom symbol mappings** via configuration
- **Universal broker compatibility**

### **🏗️ Modular Architecture**
- **Separate modules** for different functionalities
- **Easy maintenance** and updates
- **Backward compatibility** with v8.x systems
- **Future-proof design** for additional features

### **🔐 Auto-Login System** (NEW!)
- **Automatic account login** from configuration file
- **Broker/Server detection** with intelligent search
- **Multi-account support** for Demo, Live, and Prop accounts
- **Secure credential management** with local file storage
- **Batch script generation** for Windows automation

### **🚀 SaaS Platform Automation** (NEW!)
- **ZERO manual interaction** - Fully automated MT5 startup
- **Windows & Linux support** - Native Windows or Wine on Linux
- **Service integration** - Windows Service or systemd
- **Docker support** - Container-based isolation (Linux)
- **Process monitoring** - Automatic restart on crash
- **Multi-tenant support** - Multiple MT5 instances per server
- **Perfect for SaaS platforms** renting MT5 instances

---

## 📁 **Repository Structure**

```
signal-ea-v90/
├── src/
│   ├── main/
│   │   └── Signal_EA_v90_Main.mq5           # Main EA file
│   ├── modules/
│   │   ├── Lotsize_v90_Enhanced.mqh         # v9.0 Lotsize calculation module
│   │   ├── Core_DataStructures.mqh          # Data structures and enums
│   │   ├── Core_Logging.mqh                 # Logging functions
│   │   └── Core_Utilities.mqh               # Utility functions
│   ├── scripts/
│   │   └── MT5_Auto_Login.mq5               # Auto-login script
│   ├── automation/                          # SaaS automation (NEW!)
│   │   ├── MT5_AutoStart.ps1                # Windows: Automated MT5 startup
│   │   ├── Install-MT5Service.ps1           # Windows: Service installer
│   │   ├── MT5_ConfigManager.ps1            # Windows: Configuration manager
│   │   ├── README.md                        # Windows: Quick start guide
│   │   └── linux/                           # Linux/Wine automation
│   │       ├── mt5_autostart.sh             # Linux: Automated MT5 startup
│   │       ├── install_systemd_service.sh   # Linux: systemd installer
│   │       ├── mt5_wine_config.sh           # Linux: Config manager
│   │       ├── Dockerfile                   # Docker container setup
│   │       ├── docker-compose.yml           # Multi-tenant orchestration
│   │       └── README.md                    # Linux: Quick start guide
│   └── legacy/
│       └── Signal_EA_v8x_Original.mq5       # Original v8.x code (reference)
├── docs/
│   ├── INTEGRATION_GUIDE.md                 # Step-by-step integration guide
│   ├── API_DOCUMENTATION.md                 # API integration documentation
│   ├── AUTO_LOGIN_GUIDE.md                  # Auto-login system guide
│   ├── SAAS_DEPLOYMENT_GUIDE.md             # SaaS platform deployment (NEW!)
│   ├── TROUBLESHOOTING.md                   # Common issues and solutions
│   └── CHANGELOG.md                          # Version history and changes
├── examples/
│   ├── minimal_integration/                 # Minimal modular integration example
│   ├── full_modular/                        # Complete modular structure example
│   ├── patch_files/                         # Patch files for existing installations
│   ├── mt5_login_config.txt                 # Login configuration example
│   ├── mt5_saas_config.json                 # SaaS automation config - Windows
│   └── mt5_saas_config_linux.json           # SaaS automation config - Linux/Wine
├── tests/
│   ├── lotsize_tests.mq5                    # Lotsize calculation tests
│   └── symbol_detection_tests.mq5           # Symbol detection tests
├── .gitignore                               # Git ignore file
├── LICENSE                                  # License file
└── README.md                                # This file
```

---

## 🚀 **Quick Start**

### **Option A: Minimal Integration (Recommended)**
Perfect for existing v8.x installations - only updates the lotsize calculation.

1. **Download the lotsize module:**
   ```bash
   curl -O https://raw.githubusercontent.com/stelona/signal-ea-v90/main/src/modules/Lotsize_v90_Enhanced.mqh
   ```

2. **Add to your existing EA:**
   ```mql5
   #include "Lotsize_v90_Enhanced.mqh"
   ```

3. **Replace one function call:**
   ```mql5
   // OLD:
   double lots = CalculateLots_v85(...);
   
   // NEW:
   double lots = CalculateLots_v90_Enhanced(...);
   ```

**That's it!** Your JPY-pair problem is solved.

### **Option B: Complete Modular Installation**
For new installations or complete modernization.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/stelona/signal-ea-v90.git
   ```

2. **Use the main EA file:**
   ```
   src/main/Signal_EA_v90_Main.mq5
   ```

3. **Configure your API endpoints** in the input parameters

### **Option C: Auto-Login Setup** (NEW!)
For automatic account login from configuration file.

1. **Copy files to MT5:**
   ```bash
   # Copy script to MT5 Scripts folder
   cp src/scripts/MT5_Auto_Login.mq5 [MT5_DATA]/MQL5/Scripts/

   # Copy config template to Files folder
   cp examples/mt5_login_config.txt [MT5_DATA]/MQL5/Files/
   ```

2. **Edit configuration file:**
   ```ini
   ACCOUNT=12345678
   PASSWORD=YourPassword
   SERVER=YourBroker-Demo
   ```

3. **Run the script in MT5:**
   - Navigator → Scripts → MT5_Auto_Login
   - Drag onto any chart

4. **See full guide:** [AUTO_LOGIN_GUIDE.md](docs/AUTO_LOGIN_GUIDE.md)

### **Option D: SaaS Platform Automation** (NEW! - ZERO manual interaction)
For SaaS platforms renting MT5 instances - fully automated, no customer clicks required.

1. **Copy automation scripts:**
   ```powershell
   Copy-Item src/automation/* -Destination "C:\MT5\automation\" -Recurse
   Copy-Item examples/mt5_saas_config.json -Destination "C:\MT5\config.json"
   ```

2. **Configure customer credentials:**
   ```json
   {
     "account": 12345678,
     "password": "CustomerPassword",
     "server": "ICMarkets-Demo",
     "mt5_path": "C:\\Program Files\\MetaTrader 5\\terminal64.exe"
   }
   ```

3. **Install as Windows Service:**
   ```powershell
   cd C:\MT5\automation
   .\Install-MT5Service.ps1 -ConfigFile "C:\MT5\config.json"
   ```

4. **Done!** MT5 starts automatically on system boot - no customer interaction needed.

5. **See full guide:** [SAAS_DEPLOYMENT_GUIDE.md](docs/SAAS_DEPLOYMENT_GUIDE.md)

### **Option E: Linux/Wine SaaS Automation** (NEW! - For Linux Servers)
For SaaS platforms running on Linux with Wine - fully automated, no customer interaction.

1. **Install dependencies:**
   ```bash
   sudo apt-get update
   sudo apt-get install wine wine64 xvfb jq -y
   ```

2. **Create customer config from web input:**
   ```bash
   cd src/automation/linux
   ./mt5_wine_config.sh create \
     --account 12345678 \
     --password "CustomerPassword" \
     --server "ICMarkets-Demo"
   ```

3. **Install as systemd service:**
   ```bash
   sudo ./install_systemd_service.sh /opt/mt5/config.json
   ```

4. **OR run as Docker container:**
   ```bash
   docker run -d \
     -e ACCOUNT=12345678 \
     -e PASSWORD="CustomerPassword" \
     -e SERVER="ICMarkets-Demo" \
     --restart unless-stopped \
     mt5-saas:latest
   ```

5. **Done!** MT5 starts automatically - perfect for Linux-based SaaS platforms.

6. **See full guide:** [Linux README](src/automation/linux/README.md)

---

## 🔧 **Installation Requirements**

- **MetaTrader 5** (build 3200 or higher)
- **WebRequest permissions** for API communication
- **Allow DLL imports** (if using advanced features)
- **Minimum account balance:** $100 (for proper risk calculation)

---

## 📊 **Performance Improvements**

| Feature | v8.x | v9.0 | Improvement |
|---------|------|------|-------------|
| JPY Lotsize Accuracy | ❌ 10x too small | ✅ Correct | **1000% better** |
| Risk Overshoot | ⚠️ Possible | ✅ Never | **100% safe** |
| Fallback Methods | 2 | 4 | **2x more reliable** |
| Symbol Detection | Basic | Advanced | **5x more symbols** |
| Code Maintainability | Monolithic | Modular | **10x easier** |

---

## 🛡️ **Risk Management**

### **Strict Risk Control v9.0:**
- **Never exceeds** your specified risk percentage
- **Automatic lot reduction** if risk would be exceeded
- **Minimum lot validation** ensures trades are still profitable
- **Real-time risk calculation** based on actual market conditions

### **JPY-Pair Specific Protection:**
- **Correct pip values** prevent massive over-risking
- **Currency conversion** handles all account currencies
- **Realistic validation ranges** catch calculation errors
- **Conservative fallback estimates** in extreme cases

---

## 📡 **API Integration**

### **Supported Endpoints:**
- **Signal API:** Receives new trading signals
- **Position API:** Checks position status and modifications
- **Delivery API:** Confirms trade execution and status
- **Login API:** Reports account status and connectivity

### **Signal Format:**
```json
{
  "signal_id": "12345",
  "symbol": "USDJPY",
  "direction": "buy",
  "entry": 148.000,
  "sl": 147.600,
  "tp": 148.800,
  "risk": 2.5,
  "order_type": "market"
}
```

---

## 🔍 **Supported Symbols**

### **Forex Pairs:**
- **Major pairs:** EURUSD, GBPUSD, USDJPY, USDCHF, AUDUSD, NZDUSD, USDCAD
- **JPY pairs:** EURJPY, GBPJPY, AUDJPY, NZDJPY, CADJPY, CHFJPY
- **Minor pairs:** EURGBP, EURCHF, GBPCHF, AUDCAD, etc.

### **Precious Metals:**
- **Gold:** XAUUSD, GOLD
- **Silver:** XAGUSD, SILVER
- **Platinum:** XPTUSD
- **Palladium:** XPDUSD

### **Indices:**
- **US:** US30 (Dow Jones), US100 (Nasdaq), US500 (S&P 500)
- **Europe:** DAX, FTSE, CAC40, STOXX50, IBEX35, SMI
- **Asia:** NIKKEI, HANGSENG, ASX200, KOSPI

### **Cryptocurrencies:**
- **Major:** BTCUSD, ETHUSD, XRPUSD
- **Auto-detection** for broker-specific crypto symbols

---

## 🧪 **Testing**

### **Automated Tests:**
```bash
# Run lotsize calculation tests
mql5 tests/lotsize_tests.mq5

# Run symbol detection tests  
mql5 tests/symbol_detection_tests.mq5
```

### **Manual Testing:**
1. **Enable debug mode:** `debug_mode = true`
2. **Test with JPY pair:** Use USDJPY with known values
3. **Check logs:** Look for v9.0 calculation messages
4. **Verify risk:** Ensure calculated risk never exceeds limit

---

## 📚 **Documentation**

- **[Integration Guide](docs/INTEGRATION_GUIDE.md)** - Step-by-step installation
- **[API Documentation](docs/API_DOCUMENTATION.md)** - Complete API reference
- **[Auto-Login Guide](docs/AUTO_LOGIN_GUIDE.md)** - Automatic account login setup
- **[SaaS Deployment Guide](docs/SAAS_DEPLOYMENT_GUIDE.md)** - Fully automated SaaS platform setup (NEW!)
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Changelog](docs/CHANGELOG.md)** - Version history and updates

---

## 🤝 **Contributing**

### **Development Workflow:**
1. **Fork** the repository
2. **Create feature branch:** `git checkout -b feature/amazing-feature`
3. **Commit changes:** `git commit -m 'Add amazing feature'`
4. **Push to branch:** `git push origin feature/amazing-feature`
5. **Open Pull Request**

### **Coding Standards:**
- **MQL5 style guide** compliance
- **Comprehensive logging** for all operations
- **Error handling** for all external calls
- **Unit tests** for new functionality

---

## 📄 **License**

This project is proprietary software owned by **Stelona**. All rights reserved.

**Authorized use only** - Contact [support@stelona.com](mailto:support@stelona.com) for licensing.

---

## 📞 **Support**

### **Technical Support:**
- **Email:** [support@stelona.com](mailto:support@stelona.com)
- **Documentation:** [https://docs.stelona.com](https://docs.stelona.com)
- **Issue Tracker:** [GitHub Issues](https://github.com/stelona/signal-ea-v90/issues)

### **Business Inquiries:**
- **Website:** [https://www.stelona.com](https://www.stelona.com)
- **Sales:** [sales@stelona.com](mailto:sales@stelona.com)

---

## 🏆 **Acknowledgments**

- **MetaQuotes** for the MQL5 platform
- **Trading community** for feedback and testing
- **Beta testers** who helped identify the JPY-pair issue

---

**© 2024 Stelona. All rights reserved.**
