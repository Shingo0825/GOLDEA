//+------------------------------------------------------------------+
//|                                           MagicNumberManager.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//|                                      MagicNumberManager.mqh       |
//|                   完全自動マジックナンバー管理システム              |
//|                   どの通貨ペアでも自動対応・競合回避               |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| マジックナンバー管理の入力パラメータ
//+------------------------------------------------------------------+
input group "=== Magic Number Management ===";
input bool   EnableAutoMagicManagement = true;      // 自動マジック管理を有効
input bool   UseHashBasedMethod = true;             // ハッシュベース方式を使用
input int    MagicBaseMultiplier = 1000;            // 基本オフセット間隔
input int    MaxConcurrentEAs = 20;                 // 最大同時稼働EA数
input bool   ShowMagicDebugInfo = true;             // デバッグ情報表示
input int    FallbackMagicOffset = 0;               // 自動失敗時のフォールバック

//+------------------------------------------------------------------+
//| 通貨ペア情報管理構造体
//+------------------------------------------------------------------+
struct SymbolMagicInfo {
    string symbol;           // 通貨ペア名
    int assignedOffset;      // 割り当てオフセット
    datetime firstSeen;      // 初回検出時刻
    bool isActive;          // アクティブ状態
    int hashValue;          // 計算されたハッシュ値
    bool isPredefined;      // 事前定義済みかどうか
};

//+------------------------------------------------------------------+
//| グローバル変数
//+------------------------------------------------------------------+
SymbolMagicInfo g_symbolRegistry[50];   // シンボル登録レジストリ
int g_registryCount = 0;                // 登録済みシンボル数
int g_currentSymbolOffset = -1;         // 現在のシンボルのオフセット
bool g_magicManagerInitialized = false; // 初期化フラグ

//+------------------------------------------------------------------+
//| 通貨ペア名から安定したハッシュ値を生成
//+------------------------------------------------------------------+
int CalculateSymbolHash(string symbol)
{
    int hash = 0;
    int symbolLen = StringLen(symbol);
    
    // DJB2ハッシュアルゴリズム（安定性重視）
    hash = 5381;
    for(int i = 0; i < symbolLen; i++) {
        int charCode = StringGetChar(symbol, i);
        hash = ((hash << 5) + hash) + charCode;  // hash * 33 + charCode
    }
    
    // 負の値を避け、適切な範囲に正規化
    hash = MathAbs(hash);
    return (hash % MaxConcurrentEAs) * MagicBaseMultiplier;
}

//+------------------------------------------------------------------+
//| 事前定義された通貨ペアのオフセット取得
//+------------------------------------------------------------------+
int GetPredefinedSymbolOffset(string symbol)
{
    // FX メジャー通貨ペア
    if(StringFind(symbol, "XAUUSD") >= 0 || StringFind(symbol, "GOLD") >= 0) return 0;
    if(StringFind(symbol, "USDJPY") >= 0) return 1000;
    if(StringFind(symbol, "EURUSD") >= 0) return 2000;
    if(StringFind(symbol, "GBPUSD") >= 0) return 3000;
    if(StringFind(symbol, "AUDUSD") >= 0) return 4000;
    if(StringFind(symbol, "USDCAD") >= 0) return 5000;
    if(StringFind(symbol, "USDCHF") >= 0) return 6000;
    if(StringFind(symbol, "EURJPY") >= 0) return 7000;
    if(StringFind(symbol, "GBPJPY") >= 0) return 8000;
    if(StringFind(symbol, "NZDUSD") >= 0) return 9000;
    
    // FX クロス通貨
    if(StringFind(symbol, "AUDCAD") >= 0) return 10000;
    if(StringFind(symbol, "EURGBP") >= 0) return 11000;
    if(StringFind(symbol, "USDSGD") >= 0) return 12000;
    if(StringFind(symbol, "USDHKD") >= 0) return 13000;
    if(StringFind(symbol, "EURCHF") >= 0) return 14000;
    if(StringFind(symbol, "AUDCHF") >= 0) return 15000;
    if(StringFind(symbol, "AUDJPY") >= 0) return 16000;
    if(StringFind(symbol, "CADJPY") >= 0) return 17000;
    if(StringFind(symbol, "CHFJPY") >= 0) return 18000;
    if(StringFind(symbol, "NZDJPY") >= 0) return 19000;
    
    // 仮想通貨
    if(StringFind(symbol, "BTCUSD") >= 0) return 20000;
    if(StringFind(symbol, "ETHUSD") >= 0) return 21000;
    if(StringFind(symbol, "LTCUSD") >= 0) return 22000;
    if(StringFind(symbol, "ADAUSD") >= 0) return 23000;
    if(StringFind(symbol, "DOTUSD") >= 0) return 24000;
    
    // 貴金属
    if(StringFind(symbol, "XAGUSD") >= 0 || StringFind(symbol, "SILVER") >= 0) return 30000;
    if(StringFind(symbol, "XPDUSD") >= 0) return 31000;
    if(StringFind(symbol, "XPTUSD") >= 0) return 32000;
    
    // エネルギー・コモディティ
    if(StringFind(symbol, "CRUDE") >= 0 || StringFind(symbol, "OIL") >= 0) return 40000;
    if(StringFind(symbol, "BRENT") >= 0) return 41000;
    if(StringFind(symbol, "NGAS") >= 0) return 42000;
    
    // 株価指数
    if(StringFind(symbol, "SPX") >= 0 || StringFind(symbol, "SP500") >= 0) return 50000;
    if(StringFind(symbol, "NAS") >= 0 || StringFind(symbol, "NDX") >= 0) return 51000;
    if(StringFind(symbol, "DAX") >= 0) return 52000;
    if(StringFind(symbol, "NIKKEI") >= 0 || StringFind(symbol, "JPN225") >= 0) return 53000;
    if(StringFind(symbol, "FTSE") >= 0) return 54000;
    if(StringFind(symbol, "CAC") >= 0) return 55000;
    if(StringFind(symbol, "ASX") >= 0) return 56000;
    if(StringFind(symbol, "HSI") >= 0) return 57000;
    
    // 該当なし（ハッシュベースで処理）
    return -1;
}

//+------------------------------------------------------------------+
//| シンボル登録レジストリの管理
//+------------------------------------------------------------------+
void RegisterSymbol(string symbol, int offset, bool isPredefined = false)
{
    // 既存エントリの更新
    for(int i = 0; i < g_registryCount; i++) {
        if(g_symbolRegistry[i].symbol == symbol) {
            g_symbolRegistry[i].assignedOffset = offset;
            g_symbolRegistry[i].isActive = true;
            g_symbolRegistry[i].isPredefined = isPredefined;
            return;
        }
    }
    
    // 新規エントリの追加
    if(g_registryCount < ArraySize(g_symbolRegistry)) {
        g_symbolRegistry[g_registryCount].symbol = symbol;
        g_symbolRegistry[g_registryCount].assignedOffset = offset;
        g_symbolRegistry[g_registryCount].firstSeen = TimeCurrent();
        g_symbolRegistry[g_registryCount].isActive = true;
        g_symbolRegistry[g_registryCount].hashValue = CalculateSymbolHash(symbol);
        g_symbolRegistry[g_registryCount].isPredefined = isPredefined;
        g_registryCount++;
    }
}

//+------------------------------------------------------------------+
//| 使用中のオフセット一覧を取得
//+------------------------------------------------------------------+
void GetActiveOffsets(int &activeOffsets[], int &activeCount)
{
    activeCount = 0;
    ArrayResize(activeOffsets, 0);
    
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS)) continue;
        
        string orderSymbol = OrderSymbol();
        int magic = OrderMagicNumber();
        
        // 自分以外の通貨ペアのオフセットを収集
        if(orderSymbol != Symbol()) {
            int estimatedOffset = (magic / MagicBaseMultiplier) * MagicBaseMultiplier;
            
            // 重複チェック
            bool alreadyListed = false;
            for(int j = 0; j < activeCount; j++) {
                if(activeOffsets[j] == estimatedOffset) {
                    alreadyListed = true;
                    break;
                }
            }
            
            if(!alreadyListed) {
                ArrayResize(activeOffsets, activeCount + 1);
                activeOffsets[activeCount] = estimatedOffset;
                activeCount++;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 安全なオフセットを検索
//+------------------------------------------------------------------+
int FindSafeOffset(int preferredOffset)
{
    int activeOffsets[];
    int activeCount;
    GetActiveOffsets(activeOffsets, activeCount);
    
    // 希望するオフセットが使用可能かチェック
    bool preferredSafe = true;
    for(int i = 0; i < activeCount; i++) {
        if(activeOffsets[i] == preferredOffset) {
            preferredSafe = false;
            break;
        }
    }
    
    if(preferredSafe) {
        return preferredOffset;
    }
    
    // 代替オフセットを検索
    Print("🔍 Searching for safe offset. Preferred ", preferredOffset, " is in use.");
    
    for(int candidate = 0; candidate < 100000; candidate += MagicBaseMultiplier) {
        bool candidateSafe = true;
        
        for(int i = 0; i < activeCount; i++) {
            if(activeOffsets[i] == candidate) {
                candidateSafe = false;
                break;
            }
        }
        
        if(candidateSafe) {
            Print("✅ Found safe alternative offset: ", candidate);
            return candidate;
        }
    }
    
    // 緊急フォールバック
    int emergencyOffset = 99000;
    Print("🚨 Using emergency offset: ", emergencyOffset);
    return emergencyOffset;
}

//+------------------------------------------------------------------+
//| メイン：オフセット計算
//+------------------------------------------------------------------+
int CalculateMagicOffset()
{
    if(!EnableAutoMagicManagement) {
        return FallbackMagicOffset;
    }
    
    string currentSymbol = Symbol();
    int preferredOffset;
    bool isPredefined = false;
    
    if(UseHashBasedMethod) {
        // ハッシュベース方式
        preferredOffset = CalculateSymbolHash(currentSymbol);
    } else {
        // 事前定義優先方式
        preferredOffset = GetPredefinedSymbolOffset(currentSymbol);
        if(preferredOffset >= 0) {
            isPredefined = true;
        } else {
            preferredOffset = CalculateSymbolHash(currentSymbol);
        }
    }
    
    // 安全なオフセットを確定
    int finalOffset = FindSafeOffset(preferredOffset);
    
    // レジストリに登録
    RegisterSymbol(currentSymbol, finalOffset, isPredefined);
    
    return finalOffset;
}

//+------------------------------------------------------------------+
//| デバッグ情報表示
//+------------------------------------------------------------------+
void PrintMagicNumberDebugInfo()
{
    if(!ShowMagicDebugInfo) return;
    
    Print("=== Magic Number Manager Debug Info ===");
    Print("Current Symbol: ", Symbol());
    Print("Method: ", (UseHashBasedMethod ? "Hash-based" : "Predefined-priority"));
    Print("Base Multiplier: ", MagicBaseMultiplier);
    Print("Final Offset: ", g_currentSymbolOffset);
    Print("");
    
    // 現在のシンボルの詳細
    int hash = CalculateSymbolHash(Symbol());
    int predefined = GetPredefinedSymbolOffset(Symbol());
    
    Print("Current Symbol Analysis:");
    Print("  Hash-calculated: ", hash);
    Print("  Predefined: ", (predefined >= 0 ? IntegerToString(predefined) : "N/A"));
    Print("  Selected: ", g_currentSymbolOffset);
    Print("");
    
    // レジストリ一覧
    if(g_registryCount > 0) {
        Print("Symbol Registry:");
        Print("Symbol       | Offset | Hash  | Predef | First Seen          ");
        Print("-------------|--------|-------|--------|--------------------");
        
        for(int i = 0; i < g_registryCount; i++) {
            string predefStr = (g_symbolRegistry[i].isPredefined ? "YES" : "NO");
            Print(StringFormat("%-12s | %6d | %5d | %-6s | %s", 
                  g_symbolRegistry[i].symbol,
                  g_symbolRegistry[i].assignedOffset,
                  g_symbolRegistry[i].hashValue,
                  predefStr,
                  TimeToString(g_symbolRegistry[i].firstSeen, TIME_SECONDS)));
        }
    }
    Print("========================================");
}

//+------------------------------------------------------------------+
//| 全市場の使用状況分析
//+------------------------------------------------------------------+
void AnalyzeMagicUsageAcrossMarkets()
{
    Print("=== Magic Usage Analysis Across All Markets ===");
    
    struct MarketInfo {
        string symbol;
        int minMagic;
        int maxMagic;
        int positionCount;
        int estimatedOffset;
    };
    
    MarketInfo markets[50];
    int marketCount = 0;
    
    // 全ポジションを分析
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS)) continue;
        
        string symbol = OrderSymbol();
        int magic = OrderMagicNumber();
        
        // 既存市場を検索
        int marketIndex = -1;
        for(int j = 0; j < marketCount; j++) {
            if(markets[j].symbol == symbol) {
                marketIndex = j;
                break;
            }
        }
        
        // 新規市場
        if(marketIndex == -1 && marketCount < ArraySize(markets)) {
            marketIndex = marketCount;
            markets[marketIndex].symbol = symbol;
            markets[marketIndex].minMagic = magic;
            markets[marketIndex].maxMagic = magic;
            markets[marketIndex].positionCount = 0;
            markets[marketIndex].estimatedOffset = (magic / MagicBaseMultiplier) * MagicBaseMultiplier;
            marketCount++;
        }
        
        // 統計更新
        if(marketIndex >= 0) {
            if(magic < markets[marketIndex].minMagic) markets[marketIndex].minMagic = magic;
            if(magic > markets[marketIndex].maxMagic) markets[marketIndex].maxMagic = magic;
            markets[marketIndex].positionCount++;
        }
    }
    
    // 結果表示
    if(marketCount > 0) {
        Print("Market       | Offset | Magic Range     | Positions");
        Print("-------------|--------|-----------------|----------");
        
        for(int i = 0; i < marketCount; i++) {
            Print(StringFormat("%-12s | %6d | %4d - %-4d    | %9d", 
                  markets[i].symbol,
                  markets[i].estimatedOffset,
                  markets[i].minMagic,
                  markets[i].maxMagic,
                  markets[i].positionCount));
        }
    } else {
        Print("No active positions found across markets.");
    }
    Print("===============================================");
}

//+------------------------------------------------------------------+
//| 競合監視（修正版）
//+------------------------------------------------------------------+
void MonitorMagicConflicts(int &magicArray[], int magicCount)
{
    static datetime lastConflictCheck = 0;
    
    // 2分毎に監視
    if(TimeCurrent() - lastConflictCheck < 120) return;
    lastConflictCheck = TimeCurrent();
    
    // 自分のマジック範囲での競合チェック
    bool conflictFound = false;
    string conflictDetails = "";
    
    for(int i = 0; i < magicCount; i++) {
        int myMagic = magicArray[i];
        
        for(int j = OrdersTotal() - 1; j >= 0; j--) {
            if(!OrderSelect(j, SELECT_BY_POS)) continue;
            
            if(OrderSymbol() != Symbol() && OrderMagicNumber() == myMagic) {
                conflictFound = true;
                conflictDetails += IntegerToString(myMagic) + "(" + OrderSymbol() + ") ";
            }
        }
    }
    
    if(conflictFound) {
        Alert("🚨 Magic Conflict Detected! ", Symbol(), " conflicts: ", conflictDetails);
        Print("🚨 CRITICAL: Magic number conflicts for ", Symbol());
        Print("Conflicting details: ", conflictDetails);
        AnalyzeMagicUsageAcrossMarkets();
    }
}

//+------------------------------------------------------------------+
//| 初期化関数
//+------------------------------------------------------------------+
void InitMagicNumberManager()
{
    Print("🎯 Initializing Magic Number Manager...");
    
    // 現在のシンボルのオフセットを計算
    g_currentSymbolOffset = CalculateMagicOffset();
    
    // デバッグ情報表示
    PrintMagicNumberDebugInfo();
    
    // 初期化完了フラグ
    g_magicManagerInitialized = true;
    
    Print("✅ Magic Number Manager initialized successfully.");
    Print("📊 Symbol: ", Symbol(), " | Offset: ", g_currentSymbolOffset);
}

//+------------------------------------------------------------------+
//| 終了処理
//+------------------------------------------------------------------+
void DeinitMagicNumberManager()
{
    Print("🎯 Magic Number Manager deinitialized.");
}

//+------------------------------------------------------------------+
//| 現在のオフセットを取得
//+------------------------------------------------------------------+
int GetCurrentMagicOffset()
{
    if(!g_magicManagerInitialized) {
        InitMagicNumberManager();
    }
    return g_currentSymbolOffset;
}

//+------------------------------------------------------------------+
//| マジックナンバー管理システムの状態確認
//+------------------------------------------------------------------+
bool IsMagicManagerReady()
{
    return g_magicManagerInitialized && g_currentSymbolOffset >= 0;
}

//+------------------------------------------------------------------+
//| 対応テスト関数
//+------------------------------------------------------------------+
void TestSymbolSupport()
{
    Print("=== Symbol Support Test ===");
    
    string testSymbols[] = {
        "XAUUSD", "USDJPY", "EURUSD", "GBPUSD",      // メジャーFX
        "BTCUSD", "ETHUSD",                          // 仮想通貨
        "SPX500", "NAS100", "DAX30",                 // 株価指数
        "CRUDE", "BRENT", "NGAS",                    // エネルギー
        "CUSTOMFX", "UNKNOWN", "TEST123456"          // カスタム
    };
    
    for(int i = 0; i < ArraySize(testSymbols); i++) {
        string symbol = testSymbols[i];
        int hashOffset = CalculateSymbolHash(symbol);
        int predefinedOffset = GetPredefinedSymbolOffset(symbol);
        string predefStr = (predefinedOffset >= 0) ? IntegerToString(predefinedOffset) : "Hash";
        
        Print(StringFormat("%-12s | Hash: %5d | Final: %s", 
              symbol, hashOffset, predefStr));
    }
    Print("===========================");
}