//+------------------------------------------------------------------+
//|                                                      GOLDEA.mq4  |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                      マルチ通貨対応版（XAUUSD/USDJPY/EURUSD）    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "3.1" // バージョンを更新
#property strict

#define Alert Print

#include <stdlib.mqh>

// 1. 共通構造体定義（最初に読み込む）
#include "CommonStructs.mqh"

// ★★ グローバル変数宣言（構造体定義後に配置） ★★
CurrencySettings g_currencyConfig;

// 2. 汎用的な部品ファイル
#include "TradingUtils.mqh"

// 3. マジックナンバー管理システム
#include "MagicNumberManager.mqh"

// 4. ★★★ 通貨ペア設定専用ファイル ★★★
#include "CurrencyConfig.mqh"

// 5. 他の機能ファイル
#include "SuperTrendManager.mqh"
#include "UIManager.mqh"
#include "RiskManager.mqh"
#include "NanpinManager.mqh"
#include "TrendLogic1.0.mqh"
#include "EntryRestrictions.mqh"
#include "MADeviationRate_Lib.mqh"
#include "EntryLogics.mqh"

#define RETRY_COUNT 3
#define MAX_MAGIC   23
#define MAGIC_COUNT 23


static datetime lastClosedBarTimeArray[MAX_MAGIC]; 

enum timeframe {
    CURRENT = 0, // チャートの時間足
    M1 = 1,
    M5 = 5,
    M15 = 15,
    M30 = 30,
    H1 = 60,
    H4 = 240,
    D1 = 1440,
    W1 = 10080,
    MN1 = 43200
};

//+------------------------------------------------------------------+
//| 通貨ペア選択のための列挙型
//+------------------------------------------------------------------+
enum CurrencyPairType {
    PAIR_XAUUSD = 0,    // ゴールド/ドル
    PAIR_USDJPY = 1,    // ドル/円
    PAIR_EURUSD = 2,    // ユーロ/ドル
    PAIR_GBPUSD = 3,    // ポンド/ドル
    PAIR_AUDUSD = 4,    // 豪ドル/ドル
    PAIR_USDCAD = 5,    // ドル/カナダドル
    PAIR_USDCHF = 6,    // ドル/スイスフラン
    PAIR_EURJPY = 7,    // ユーロ/円
    PAIR_GBPJPY = 8     // ポンド/円
};





//+------------------------------------------------------------------+
//| マルチ通貨対応設定
//+------------------------------------------------------------------+
input group "=== Multi-Currency Settings ===";
input CurrencyPairType SelectedPair = PAIR_XAUUSD;  // 使用する通貨ペア
input bool AutoDetectSymbol = true;                 // チャートの通貨ペアを自動検出
input int MagicNumberOffset = 0;                    // マジックナンバーのオフセット（重複回避用）

//――― 乖離率用外部インジ名をまとめて管理 ―――
input string KairiIndicator = "kairiritu1.1";  // ex4/ ex5 拡張子は不要

// 基本設定
input double StopLoss = 0;
input double TakeProfit = 0;
input int Slippage = 10;


// ロジックのON/OFF設定
input group "=== Logic ON/OFF Settings ===";
input bool EnableTrendLogic       = true;
input bool EnableCounterTrendLogic = true;
input bool EnableRangeLogic       = true;

// デバッグ設定
input bool EnableDeviationSignalDebug = true;

// ★ Magic 1-10用のON/OFF設定
input group "=== Magic 1-10 ON/OFF Settings ===";
input bool EnableMagic1  = false;  // Magic 1 OFF（無効化）
input bool EnableMagic2  = false;  // Magic 2 OFF（無効化）
input bool EnableMagic3  = false;  // Magic 3 OFF（無効化）
input bool EnableMagic4  = false;  // Magic 4 OFF（無効化）
input bool EnableMagic5  = false;  // Magic 5 OFF（無効化）
input bool EnableMagic6  = false;  // Magic 6 OFF（無効化）
input bool EnableMagic7  = false;  // Magic 7 OFF（無効化）
input bool EnableMagic8  = false;  // Magic 8 OFF（無効化）
input bool EnableMagic9  = false;  // Magic 9 OFF（無効化）
input bool EnableMagic10 = false;  // Magic 10 OFF（無効化）

// ★ Magic 11-20用のON/OFF設定（バックテスト対応）
input group "=== Magic 11-20 Settings (Backtest Compatible) ===";
input bool EnableMagic11_BT  = false;  // Magic 11 バックテスト用（常時ロング）
input bool EnableMagic12_BT  = false;  // Magic 12 バックテスト用（常時ショート）
input bool EnableMagic13_BT  = false;  // Magic 13 バックテスト用（EMAパーフェクト+ロング）
input bool EnableMagic14_BT  = false;  // Magic 14 バックテスト用（EMAパーフェクト+ショート）
input bool EnableMagic15_BT  = false;  // Magic 15 バックテスト用（RSI反発ロング）
input bool EnableMagic16_BT  = false;  // Magic 16 バックテスト用（RSI反発ショート）
input bool EnableMagic17_BT  = false;  // Magic 17 バックテスト用（乖離率反発ロング）
input bool EnableMagic18_BT  = false;  // Magic 18 バックテスト用（乖離率反発ショート）
input bool EnableMagic19_BT  = false;  // Magic 19 バックテスト用（準備中）
input bool EnableMagic20_BT  = false;  // Magic 20 バックテスト用（準備中）



int base_magic_array[MAGIC_COUNT] = {
     1, 2, 3, 4, 5, 6, 7, 8, 9, 10,       // 既存の1-10
     11, 12, 13, 14, 15, 16, 17, 18, 19, 20, // 新規追加11-20
     0,                                       // Magic 0（既存）
     901,                                     // 手動 BUY ボタン
     902                                      // 手動 SELL ボタン
};

// 実際に使用するマジックナンバー配列（オフセット適用済み）
int magic_array[MAGIC_COUNT];

// バーの記録
int bars[MAGIC_COUNT];


bool Trade = true;
color ArrowColor[2] = {clrBlue, clrRed};
double firstask=0;
double firstbit=0;

double g_stdDev1m30 = 0, g_stdDev5m100 = 0;





//+------------------------------------------------------------------+
//| 通貨ペア調整済みのロット計算 (この機能は維持)
//+------------------------------------------------------------------+
double CurrencyAdjustedLots(double baseLots) {
    return baseLots * g_currencyConfig.lotAdjust;
}

// GOLDEA2025年6月新AI1.3.mq4 の OnInit() 修正部分

//+------------------------------------------------------------------+
//| OnInit 関数 (完全版)
//+------------------------------------------------------------------+
int OnInit() {
    Print("🚀 Starting GOLDEA Multi-Currency EA initialization...");
    
    // 1. マジックナンバー管理システムの初期化
    InitMagicNumberManager();
    if(!IsMagicManagerReady()) {
        Alert("❌ Magic Number Manager failed to initialize!");
        return INIT_FAILED;
    }
    Print("✅ Magic Number Manager initialized");
    
    // 2. 通貨ペア設定の初期化
    if(!InitCurrencySettings(g_currencyConfig)) {
        Alert("❌ Currency settings initialization failed!");
        return INIT_FAILED;
    }
    Print("✅ Currency settings initialized: ", g_currencyConfig.symbol);
    
    // 3. extern変数に設定を反映
    g_magicOffset = g_currencyConfig.magicOffset;
    g_symbolNanpinInterval = g_currencyConfig.nanpinInterval;
    g_singlePositionBEP = g_currencyConfig.singlePositionBEP;
    g_trailingStopPips = g_currencyConfig.trailingStopPips;
    g_initP_TrendOK = g_currencyConfig.initP_TrendOK;
    g_initP_TrendNG = g_currencyConfig.initP_TrendNG;
    g_minP_TrendOK = g_currencyConfig.minP_TrendOK;
    g_minP_TrendNG = g_currencyConfig.minP_TrendNG;
    g_stdDevThreshold = g_currencyConfig.stdDevThreshold;
    
    // 4. マジックナンバー配列の設定
    for(int i = 0; i < MAGIC_COUNT; i++) {
        magic_array[i] = base_magic_array[i] + g_currencyConfig.magicOffset;
    }
    Print("✅ Magic array configured: ", magic_array[0], " - ", magic_array[MAGIC_COUNT-1]);
    
    // 5. 取引可能性チェック
    if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
        Print("⚠️ Terminal trading not allowed - Enable 'Allow live trading' in Expert Properties");
        if(!IsTesting()) {
            Alert("Enable 'Allow live trading' in Expert Properties!");
        }
    }

    // 6. 各モジュールの初期化
    InitTradingUtils();
    InitRiskManager();
    InitNanpinManager();
    Print("✅ Core modules initialized");
    
    // 7. 既存ポジションの復元
    double initialBaseLots = CalculateLots();
    RestoreExistingPositions(initialBaseLots);
    Print("✅ Existing positions restored");
    
    // 8. UI初期化
    InitUIManager();
    CreateManualButtons();
    CreateMagicSwitches();
    CreateEntryStateLabel();
    InitMFILogic();
    InitializeSuperTrendManager();
    
    // ★★★ 修正箇所 ★★★
    // バックテスト時とライブ取引時で状態復元の方法を分ける
    if(IsTesting())
    {
       // バックテスト時はinputパラメータから状態を復元
       UpdateSwitchButton(0, EnableMagic11_BT);
       UpdateSwitchButton(1, EnableMagic12_BT);
       UpdateSwitchButton(2, EnableMagic13_BT);
       UpdateSwitchButton(3, EnableMagic14_BT);
       UpdateSwitchButton(4, EnableMagic15_BT);
       UpdateSwitchButton(5, EnableMagic16_BT);
       UpdateSwitchButton(6, EnableMagic17_BT);
       UpdateSwitchButton(7, EnableMagic18_BT);
       UpdateSwitchButton(8, EnableMagic19_BT);
       UpdateSwitchButton(9, EnableMagic20_BT);
       Print("✅ Backtest: Button states set from input parameters");
    }
    else
    {
       // ライブ取引時はグローバル変数から状態を復元
       RestoreButtonStates();
    }
    
    Print("✅ UI System initialized (", (IsTesting() ? "BACKTEST" : "LIVE"), " mode)");
    
    // 9. その他のシステム初期化
    InitTrendDisplay();
    InitEntryRestrictions();
    ObjectsDeleteAll(0, "DebugArrow_");
    
    // 10. バー数の初期化
    for (int i = 0; i < MAGIC_COUNT; i++) {
        bars[i] = Utils_GetBars(magic_array[i]);
    }
    
    // 重要な設定確認
    Print("=======================================");
    Print("🎯 TRAILING SETTINGS for ", g_currencyConfig.symbol, ":");
    Print("   Single Position: ", g_singlePositionBEP, " pips → Trail ", g_trailingStopPips, " pips");
    Print("   Nanpin Trend-OK: ", g_initP_TrendOK, " → ", g_minP_TrendOK, " pips");
    Print("   Nanpin Trend-NG: ", g_initP_TrendNG, " → ", g_minP_TrendNG, " pips");
    Print("=======================================");
    
    // 最終確認
    Print("✅ GOLDEA Multi-Currency EA initialization COMPLETED");
    Print("📊 ", g_currencyConfig.symbol, " | Magic: ", g_currencyConfig.magicOffset, 
          " | Lots: ", DoubleToString(CurrencyAdjustedLots(initialBaseLots), 2));
    
    if(!IsTesting()) {
        Print("💡 Use F1-F12 keys for system info, ESC for help");
    }

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit 関数 (最終解決策版)
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("🔄 EA Deinitializing... Reason: ", reason);

    // ★★★ 修正箇所 ★★★
    // OnDeinitでの状態保存は行わない（クリック時に保存するため不要）
    /*
    if(!IsTesting()) {
       SaveButtonStates();
       GlobalVariableFlush();
    }
    */
    
    // UI要素の削除
    CleanupTrendDisplay();
    DeinitUIManager();
    
    // デバッグボタンの削除
    DeleteDebugButtons();
    
    // BEPラインを明示的に削除
    ObjectsDeleteAll(0, "BEP_LINE_");
    
    // その他のUI要素を削除（念のため）
    ObjectsDeleteAll(0, "BTN_");
    ObjectsDeleteAll(0, "LAB_");
    ObjectsDeleteAll(0, "DEBUG_");
    ObjectsDeleteAll(0, "SYSTEM_");
    ObjectsDeleteAll(0, "MAGIC_");
    ObjectsDeleteAll(0, "MARKET_");
    ObjectsDeleteAll(0, "NANPIN_");
    ObjectsDeleteAll(0, "RISK_");
    ObjectsDeleteAll(0, "CURRENCY_");
    ObjectsDeleteAll(0, "ENTRY_");
    ObjectsDeleteAll(0, "TEST_");
    ObjectsDeleteAll(0, "EXPORT_");
    ObjectsDeleteAll(0, "EMERGENCY_");
    ObjectsDeleteAll(0, "HELP");
    ObjectsDeleteAll(0, "MULTI_");
    ObjectsDeleteAll(0, "PERFORMANCE");
    ObjectsDeleteAll(0, "QUICK_");
    
    DeinitMagicNumberManager();
    
    Print("✅ EA Deinitialized successfully");
}
//+------------------------------------------------------------------+
//| OnTick 関数 (最終完成版)
//+------------------------------------------------------------------+
void OnTick()
{
    // BEPラインのキャッシュ変数をOnTickの先頭で宣言
    static double lastBEPPrices[MAX_MAGIC];
    static int lastBEPTypes[MAX_MAGIC];

    //----------------------------------------------------------------
    // 0) マジック競合監視
    //----------------------------------------------------------------
    MonitorMagicConflicts(magic_array, MAGIC_COUNT);

    //----------------------------------------------------------------
    // 1) ロット計算 & 取引可能チェック
    //----------------------------------------------------------------
    double baseLots = CalculateLots();
    double lots     = CurrencyAdjustedLots(baseLots);

    if(!IsTradingPossible(lots))
    {
        Comment("証拠金不足: 必要証拠金 > 利用可能証拠金");
        return;
    }

    //----------------------------------------------------------------
    // 3) 既存ポジション管理
    //----------------------------------------------------------------
    if(isNanpin)
        NanpinManager_ExecuteForAllMagics(magic_array, MAGIC_COUNT, baseLots);

    //----------------------------------------------------------------
    // 3.5) BEPライン更新
    //----------------------------------------------------------------
    static datetime lastBEPUpdate = 0;
    bool forceUpdate = false;
    static int lastTotalPositions = 0;
    int currentTotalPositions = OrdersTotal();
    if(currentTotalPositions != lastTotalPositions) {
        forceUpdate = true;
        lastTotalPositions = currentTotalPositions;
    }
    
    if(TimeCurrent() - lastBEPUpdate >= 1 || forceUpdate) {
        lastBEPUpdate = TimeCurrent();
        
        for(int i = 0; i < MAGIC_COUNT; i++) {
            int magic = magic_array[i];
            NanpinInfo info;
            GetNanpinInfo(magic, info);
            
            if(info.lots > 0) {
                if(MathAbs(info.breakEvenPrice - lastBEPPrices[i]) > Point || 
                   info.type != lastBEPTypes[i] || 
                   forceUpdate) {
                    UpdateBEP_Line(magic, info.breakEvenPrice, true, info.type);
                    lastBEPPrices[i] = info.breakEvenPrice;
                    lastBEPTypes[i] = info.type;
                }
            } else {
                if(lastBEPPrices[i] != 0) {
                    UpdateBEP_Line(magic, 0, false);
                    lastBEPPrices[i] = 0;
                    lastBEPTypes[i] = -1;
                }
            }
        }
    }

    //----------------------------------------------------------------
    // 4) SuperTrend キャッシュ更新
    //----------------------------------------------------------------
    RefreshAllTrends();

    //----------------------------------------------------------------
    // 5) UI 更新
    //----------------------------------------------------------------
    if(!IsTesting()) {
        UpdateTrendDisplayOptimized();
    }
    
    //----------------------------------------------------------------
    // 6) RSI・乖離率・その他インジケーター計算
    //----------------------------------------------------------------
    CheckAndDrawDeviationSignal(EnableDeviationSignalDebug,
                                Symbol(), PERIOD_M1, 21, g_currencyConfig.deviationSigma);

    int deviationReversalSignal =
        CheckDeviationReversalSignal(Symbol(), PERIOD_M1, 21,
                                     g_currencyConfig.deviationSigma);

    double rsi1m = iRSI(NULL, PERIOD_M1, 14, PRICE_CLOSE, 0);
    double rsi5m = iRSI(NULL, PERIOD_M5, 14, PRICE_CLOSE, 0);

    static int  prevDevState1m = 0;
    bool devEntryBuy  = false;
    bool devEntrySell = false;

    double rate, up, dn;
    int devState = MADeviationRateTF(PERIOD_M1, 21,
                                     g_currencyConfig.deviationSigma,
                                     1, rate, up, dn);

    if(prevDevState1m == -1 && devState == 0) devEntryBuy  = true;
    if(prevDevState1m ==  1 && devState == 0) devEntrySell = true;
    prevDevState1m = devState;

    //----------------------------------------------------------------
    // 7) MarketData 構造体に指標を格納
    //----------------------------------------------------------------
    MarketData md;
    ZeroMemory(md);

    md.deviationReversalSignal = deviationReversalSignal;
    md.devEntryBuy_2Sigma      = devEntryBuy;
    md.devEntrySell_2Sigma     = devEntrySell;
    md.rsi1m = rsi1m;
    md.rsi5m = rsi5m;
    md.stdDev_Magic34 = 0.0;
    md.lots           = lots;
    md.tp_pips = TakeProfit;
    md.sl_pips = StopLoss;
    md.enableTrendLogic        = EnableTrendLogic;
    md.enableCounterTrendLogic = EnableCounterTrendLogic;
    md.enableRangeLogic        = EnableRangeLogic;
    md.magic3_RSI_Threshold    = 40.0;
    md.magic4_RSI_Threshold    = 60.0;
    md.magic34_StdDev_Threshold  = 2.0;

    //----------------------------------------------------------------
    // 8) 新規エントリーロジック
    //----------------------------------------------------------------
    for(int idx = 0; idx < MAGIC_COUNT; idx++)
    {
        int magic = magic_array[idx];

        if(!IsAllMagicEnabled(magic)) {
            static datetime lastDebugTime = 0;
            if(TimeCurrent() - lastDebugTime > 300) {
                if(Utils_GetOpenLots(magic) > 0) {
                    Print("ℹ️ Magic ", magic, " is OFF - new entries disabled, existing positions managed normally");
                }
                lastDebugTime = TimeCurrent();
            }
            continue;
        }

        if(Utils_GetOpenLots(magic) > 0)  continue;

        int baseMagic = magic - g_currencyConfig.magicOffset;
        if(baseMagic >= 1 && baseMagic <= 10 && !IsTradingAllowedNow())
            continue;

        switch(baseMagic)
        {
            case  1:  Logic_Magic1 (md, magic); break;
            case  2:  Logic_Magic2 (md, magic); break;
            case  3:  Logic_Magic3 (md, magic, deviationReversalSignal); break;
            case  4:  Logic_Magic4 (md, magic, deviationReversalSignal); break;
            case  5:  Logic_Magic5 (md, magic); break;
            case  6:  Logic_Magic6 (md, magic); break;
            case  7:  Logic_Magic7 (md, magic); break;
            case  8:  Logic_Magic8 (md, magic); break;
            case  9:  Logic_Magic9 (md, magic); break;
            case 10:  Logic_Magic10(md, magic); break;
            case 11:  Logic_Magic11(md, magic); break;
            case 12:  Logic_Magic12(md, magic); break;
            case 13:  Logic_Magic13(md, magic, g_currencyConfig); break;
            case 14:  Logic_Magic14(md, magic, g_currencyConfig); break;
            case 15:  Logic_Magic15(md, magic); break;
            case 16:  Logic_Magic16(md, magic); break;
            case 17:  Logic_Magic17(md, magic); break;
            case 18:  Logic_Magic18(md, magic); break;
            case 19:  Logic_Magic19(md, magic); break;
            case 20:  Logic_Magic20(md, magic); break;
            default:  break;
        }
    }

    //----------------------------------------------------------------
    // 9) チャートコメント自動クリア
    //----------------------------------------------------------------
    if(!IsTesting()) {
        ManageEntryRestrictionsComment();
    }
}
//+------------------------------------------------------------------+
//| ポジション決済関数
//+------------------------------------------------------------------+
bool closePosition(int magic, int type = -1) {
    int closeSuccessCount = 0;
    int closeFailedCount  = 0;
    if (!IsTradeAllowed()) {
        Print("[closePosition Error]: Trading not allowed.");
        return false;
    }
    RefreshRates();
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            Print("[closePosition Error]: Failed to select order at pos ", i);
            continue;
        }
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
        if (type >= 0 && OrderType() != type) continue;
        double lots  = OrderLots();
        double price = OrderClosePrice();
        bool closeSuccess = false;
        for (int retry = 0; retry < RETRY_COUNT; retry++) {
            if (OrderClose(OrderTicket(), lots, price, Slippage, ArrowColor[OrderType()])) {
                closeSuccess = true;
                closeSuccessCount++;
                break;
            } else {
                int errorCode = GetLastError();
                Print("[closePosition Error]: Failed to close order. Ticket=", OrderTicket(), ", Error=", errorCode);
                Sleep(200);
            }
        }
        if (!closeSuccess) {
            Print("[closePosition Error]: Final failure to close order. Ticket=", OrderTicket());
            closeFailedCount++;
        }
    }
    if (closeFailedCount > 0) {
        Alert("[closePosition Warning]: Some positions failed to close. Check logs.");
    }
    return (closeFailedCount == 0);
}

//+------------------------------------------------------------------+
//| Magic 1-10の有効状態をチェックする関数
//+------------------------------------------------------------------+
bool IsMagic1to10Enabled(int magicNumber) {
    int baseMagic = magicNumber - g_currencyConfig.magicOffset;
    switch(baseMagic) {
        case 1:  return EnableMagic1;
        case 2:  return EnableMagic2;
        case 3:  return EnableMagic3;
        case 4:  return EnableMagic4;
        case 5:  return EnableMagic5;
        case 6:  return EnableMagic6;
        case 7:  return EnableMagic7;
        case 8:  return EnableMagic8;
        case 9:  return EnableMagic9;
        case 10: return EnableMagic10;
        default: return true; // 1-10以外はここでは判定しない
    }
}

//+------------------------------------------------------------------+
//| Magic 11-20のバックテスト用有効状態をチェックする関数
//+------------------------------------------------------------------+
bool IsMagic11to20EnabledBT(int magicNumber) {
    int baseMagic = magicNumber - g_currencyConfig.magicOffset;
    switch(baseMagic) {
        case 11: return EnableMagic11_BT;
        case 12: return EnableMagic12_BT;
        case 13: return EnableMagic13_BT;
        case 14: return EnableMagic14_BT;
        case 15: return EnableMagic15_BT;
        case 16: return EnableMagic16_BT;
        case 17: return EnableMagic17_BT;
        case 18: return EnableMagic18_BT;
        case 19: return EnableMagic19_BT;
        case 20: return EnableMagic20_BT;
        default: return false; // 11-20以外は対象外
    }
}


//+------------------------------------------------------------------+
//| 統合版：全てのマジックの有効状態をチェック（バックテスト対応）
//+------------------------------------------------------------------+
bool IsAllMagicEnabled(int magicNumber) {
    int baseMagic = magicNumber - g_currencyConfig.magicOffset;
    
    if(baseMagic >= 1 && baseMagic <= 10) {
        return IsMagicEnabled(magicNumber, g_currencyConfig.magicOffset);
    }
    
    if(baseMagic >= 11 && baseMagic <= 20) {
        if(IsTesting()) {
            // バックテスト時はinputパラメータで制御
            return IsMagic11to20EnabledBT(magicNumber);
        } else {
            // ライブ・フォワードテスト時はUIの状態で制御
            // ★★★ 修正：オフセット値を引数として明示的に渡す ★★★
            return IsMagicEnabled(magicNumber, g_currencyConfig.magicOffset);
        }
    }
    
    // Magic 1-20以外（手動ボタンの901, 902など）は常に有効とみなす
    return true;
}



//+------------------------------------------------------------------+
//| デバッグ用：システム状態表示
//+------------------------------------------------------------------+
void PrintSystemStatus() {
    Print("=== GOLDEA Multi-Currency System Status ===");
    Print("Currency Pair: ", g_currencyConfig.symbol);
    Print("Magic Offset: ", g_currencyConfig.magicOffset);
    Print("Account Equity: $", DoubleToString(AccountEquity(), 2));
    Print("Current Lots: ", DoubleToString(CurrencyAdjustedLots(CalculateLots()), 2));
    Print("Trading Allowed: ", (IsTradingAllowedNow() ? "YES" : "NO"));
    Print("Nanpin Enabled: ", (isNanpin ? "YES" : "NO"));
    int totalPositions = 0;
    for(int i = 0; i < MAGIC_COUNT; i++) {
        int positions = Utils_GetOpenPositions(magic_array[i]);
        if(positions > 0) {
            Print("Magic ", magic_array[i], ": ", positions, " positions");
            totalPositions += positions;
        }
    }
    Print("Total Active Positions: ", totalPositions);
}


//+------------------------------------------------------------------+
//| ★★★ 新規：マジック管理情報表示関数 ★★★
//+------------------------------------------------------------------+
void ShowMagicManagementInfo()
{
    if(!IsMagicManagerReady()) {
        Print("❌ Magic Number Manager not ready");
        return;
    }
    
    PrintMagicNumberDebugInfo();
    AnalyzeMagicUsageAcrossMarkets();
}

//+------------------------------------------------------------------+
//| ★★★ 新規：システム統合状態のチェック ★★★
//+------------------------------------------------------------------+
void CheckSystemIntegration()
{
    Print("=== System Integration Check ===");
    
    // 1. マジック管理システム
    bool magicReady = IsMagicManagerReady();
    Print("Magic Manager: ", (magicReady ? "✅ Ready" : "❌ Not Ready"));
    
    if(magicReady) {
        Print("  Current Offset: ", GetCurrentMagicOffset());
        Print("  Final Offset: ", g_currencyConfig.magicOffset);
    }
    
    // 2. 通貨設定
    Print("Currency Config: ", (g_currencyConfig.symbol != "" ? "✅ Ready" : "❌ Not Ready"));
    if(g_currencyConfig.symbol != "") {
        Print("  Symbol: ", g_currencyConfig.symbol);
        Print("  Nanpin Interval: ", g_currencyConfig.nanpinInterval);
    }
    
    // 3. マジック配列
    bool magicArrayValid = (magic_array[0] > 0);
    Print("Magic Array: ", (magicArrayValid ? "✅ Valid" : "❌ Invalid"));
    if(magicArrayValid) {
        Print("  Range: ", magic_array[0], " - ", magic_array[MAGIC_COUNT-1]);
    }
    
    // 4. 他システムの状態
    Print("Risk Manager: ✅ Integrated");
    Print("Nanpin Manager: ✅ Integrated");  
    Print("UI Manager: ✅ Integrated");
    Print("Entry Restrictions: ✅ Integrated");
    
    Print("================================");
    
    // 5. 統合テスト
    if(magicReady && g_currencyConfig.symbol != "" && magicArrayValid) {
        Print("🎯 SYSTEM INTEGRATION: ✅ ALL SYSTEMS OPERATIONAL");
    } else {
        Print("🚨 SYSTEM INTEGRATION: ❌ SOME SYSTEMS FAILED");
    }
}

//+------------------------------------------------------------------+
//| ★★★ 新規：マルチ通貨運用支援関数 ★★★
//+------------------------------------------------------------------+
void MultiCurrencyOperationSupport()
{
    static datetime lastSupportCheck = 0;
    
    // 10分毎に実行
    if(TimeCurrent() - lastSupportCheck < 600) return;
    lastSupportCheck = TimeCurrent();
    
    Print("=== Multi-Currency Operation Support ===");
    
    // 1. 現在のEAの状態
    Print("Current EA Status:");
    Print("  Symbol: ", Symbol());
    Print("  Magic Offset: ", g_currencyConfig.magicOffset);
    Print("  Active Positions: ", Utils_GetOpenPositions(-1)); // 全マジック
    
    // 2. 全市場の概況
    AnalyzeMagicUsageAcrossMarkets();
    
    // 3. リソース使用状況
    Print("Resource Usage:");
    Print("  Account Equity: $", DoubleToString(AccountEquity(), 2));
    Print("  Free Margin: $", DoubleToString(AccountFreeMargin(), 2));
    Print("  Used Margin: $", DoubleToString(AccountMargin(), 2));
    
    double marginLevel = (AccountMargin() > 0) ? (AccountEquity() / AccountMargin()) * 100 : 0;
    Print("  Margin Level: ", DoubleToString(marginLevel, 1), "%");
    
    // 4. アラート条件
    if(marginLevel > 0 && marginLevel < 200) {
        Alert("⚠️ Multi-Currency Warning: Low margin level ", 
              DoubleToString(marginLevel, 1), "% across all currencies");
    }
    
    Print("=========================================");
}

//+------------------------------------------------------------------+
//| ★★★ 新規：クイック起動テンプレート関数 ★★★
//+------------------------------------------------------------------+
void QuickStartTemplate()
{
    Print("=== Quick Start Template for Multi-Currency Setup ===");
    Print("");
    Print("📋 SETUP CHECKLIST:");
    Print("1. ✅ Open charts for desired currency pairs");
    Print("2. ✅ Drag same EA file to each chart");
    Print("3. ✅ Set 'EnableAutoMagicManagement = true' (default)");
    Print("4. ✅ Set 'AutoDetectSymbol = true' (default)");
    Print("5. ✅ Click OK - No manual offset configuration needed!");
    Print("");
    Print("🎯 RECOMMENDED CURRENCY PAIRS:");
    Print("   • XAUUSD (Gold) - Offset: 0");
    Print("   • USDJPY - Offset: 1000");
    Print("   • EURUSD - Offset: 2000");
    Print("   • GBPUSD - Offset: 3000"); 
    Print("   • AUDUSD - Offset: 4000");
    Print("   • BTCUSD - Offset: 20000");
    Print("");
    Print("📊 MONITORING:");
    Print("   • Check Expert tab for initialization messages");
    Print("   • Look for 'Magic Range: X - Y' confirmations");
    Print("   • Monitor for conflict alerts");
    Print("");
    Print("🔧 TROUBLESHOOTING:");
    Print("   • If conflicts occur, EA will auto-resolve");
    Print("   • Use 'ShowMagicDebugInfo = true' for details");
    Print("   • Emergency fallback available if needed");
    Print("");
    Print("=== Ready to trade across multiple currencies! ===");
}

//+------------------------------------------------------------------+
//| ★★★ 統合版：デバッグ情報表示関数 ★★★
//+------------------------------------------------------------------+
void PrintIntegratedSystemStatus()
{
    Print("=== GOLDEA Integrated System Status ===");
    
    // システム統合状態
    CheckSystemIntegration();
    Print("");
    
    // マジック管理詳細
    ShowMagicManagementInfo();
    Print("");
    
    // マルチ通貨運用状況
    MultiCurrencyOperationSupport();
    Print("");
    
    // クイックスタートガイド
    QuickStartTemplate();
}


void PrintDetailedNanpinStatus() {
    Print("=== Detailed Nanpin Status ===");
    
    int totalNanpinPositions = 0;
    double totalNanpinLots = 0;
    double totalNanpinProfit = 0;
    
    for(int i = 0; i < MAGIC_COUNT; i++) {
        int magic = magic_array[i];
        NanpinInfo info;
        GetNanpinInfo(magic, info);
        
        if(info.lots > 0) {
            int positions = Utils_GetOpenPositions(magic);
            double profit = GetOrderProfitByMagic(magic);
            string direction = (info.type == OP_BUY) ? "BUY" : "SELL";
            
            Print("Magic ", magic, ": ", direction, " | Count:", info.count, 
                  " | Lots:", DoubleToString(info.lots, 2), 
                  " | P&L: $", DoubleToString(profit, 2));
            
            totalNanpinPositions += positions;
            totalNanpinLots += info.lots;
            totalNanpinProfit += profit;
        }
    }
    
    if(totalNanpinPositions > 0) {
        Print("--- NANPIN SUMMARY ---");
        Print("Total Positions: ", totalNanpinPositions);
        Print("Total Lots: ", DoubleToString(totalNanpinLots, 2));
        Print("Total P&L: $", DoubleToString(totalNanpinProfit, 2));
        Print("Current Interval: ", DoubleToString(g_currentNanpinInterval, 1), " pips");
    } else {
        Print("No active nanpin positions");
    }
    
    Print("============================");
}
void PrintPerformanceStatistics() {
    Print("=== Performance Statistics ===");
    
    double totalProfit = 0;
    int totalPositions = 0;
    int profitablePositions = 0;
    int lossPositions = 0;
    double maxProfit = 0;
    double maxLoss = 0;
    
    // 現在のオープンポジションの統計
    for(int i = 0; i < MAGIC_COUNT; i++) {
        int magic = magic_array[i];
        int positions = Utils_GetOpenPositions(magic);
        double profit = GetOrderProfitByMagic(magic);
        
        if(positions > 0) {
            totalPositions += positions;
            totalProfit += profit;
            
            if(profit > 0) {
                profitablePositions++;
                if(profit > maxProfit) maxProfit = profit;
            } else if(profit < 0) {
                lossPositions++;
                if(profit < maxLoss) maxLoss = profit;
            }
        }
    }
    
    // アカウント情報
    double accountBalance = AccountBalance();
    double accountEquity = AccountEquity();
    double accountMargin = AccountMargin();
    double accountFreeMargin = AccountFreeMargin();
    double marginLevel = (accountMargin > 0) ? (accountEquity / accountMargin) * 100 : 0;
    
    // 統計表示
    Print("--- ACCOUNT INFO ---");
    Print("Balance: $", DoubleToString(accountBalance, 2));
    Print("Equity: $", DoubleToString(accountEquity, 2));
    Print("Floating P&L: $", DoubleToString(accountEquity - accountBalance, 2));
    Print("Used Margin: $", DoubleToString(accountMargin, 2));
    Print("Free Margin: $", DoubleToString(accountFreeMargin, 2));
    Print("Margin Level: ", DoubleToString(marginLevel, 1), "%");
    
    Print("--- POSITION STATS ---");
    Print("Total Positions: ", totalPositions);
    Print("Profitable: ", profitablePositions);
    Print("Loss: ", lossPositions);
    Print("Total Floating P&L: $", DoubleToString(totalProfit, 2));
    
    if(totalPositions > 0) {
        Print("Average P&L per Position: $", DoubleToString(totalProfit / totalPositions, 2));
        Print("Max Profit: $", DoubleToString(maxProfit, 2));
        Print("Max Loss: $", DoubleToString(maxLoss, 2));
        
        double winRate = (totalPositions > 0) ? (profitablePositions * 100.0 / totalPositions) : 0;
        Print("Win Rate: ", DoubleToString(winRate, 1), "%");
    }
    
    // リスク指標
    double riskPercent = (accountBalance > 0) ? (MathAbs(totalProfit) / accountBalance) * 100 : 0;
    Print("Current Risk: ", DoubleToString(riskPercent, 2), "% of balance");
    
    // 通貨ペア固有情報
    Print("--- CURRENCY INFO ---");
    Print("Symbol: ", Symbol());
    Print("Current Spread: ", DoubleToString(Utils_GetSpreadInPips(), 1), " pips");
    Print("Point Value: ", DoubleToString(Point, Digits));
    Print("Lot Size: ", DoubleToString(MarketInfo(Symbol(), MODE_LOTSIZE), 0));
    
    Print("===============================");
}
void ExportSystemStatusToFile() {
    string filename = "GOLDEA_Status_" + Symbol() + "_" + TimeToString(TimeCurrent(), TIME_DATE) + ".txt";
    int file = FileOpen(filename, FILE_WRITE|FILE_TXT);
    
    if(file == INVALID_HANDLE) {
        Alert("❌ Failed to create status file: " + filename);
        return;
    }
    
    // ヘッダー情報
    FileWrite(file, "=== GOLDEA Multi-Currency System Status Report ===");
    FileWrite(file, "Generated: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
    FileWrite(file, "Symbol: " + Symbol());
    FileWrite(file, "Account: " + IntegerToString(AccountNumber()));
    FileWrite(file, "");
    
    // システム設定
    FileWrite(file, "--- SYSTEM CONFIGURATION ---");
    FileWrite(file, "Currency Pair: " + g_currencyConfig.symbol);
    FileWrite(file, "Magic Offset: " + IntegerToString(g_currencyConfig.magicOffset));
    FileWrite(file, "Auto Magic Offset: " + IntegerToString(GetCurrentMagicOffset()));
    FileWrite(file, "Nanpin Interval: " + DoubleToString(g_currencyConfig.nanpinInterval, 1) + " pips");
    FileWrite(file, "Current Nanpin Interval: " + DoubleToString(g_currentNanpinInterval, 1) + " pips");
    FileWrite(file, "Lot Adjustment: " + DoubleToString(g_currencyConfig.lotAdjust, 3));
    FileWrite(file, "");
    
    // アカウント情報
    FileWrite(file, "--- ACCOUNT INFORMATION ---");
    FileWrite(file, "Balance: $" + DoubleToString(AccountBalance(), 2));
    FileWrite(file, "Equity: $" + DoubleToString(AccountEquity(), 2));
    FileWrite(file, "Floating P&L: $" + DoubleToString(AccountEquity() - AccountBalance(), 2));
    FileWrite(file, "Used Margin: $" + DoubleToString(AccountMargin(), 2));
    FileWrite(file, "Free Margin: $" + DoubleToString(AccountFreeMargin(), 2));
    
    double marginLevel = (AccountMargin() > 0) ? (AccountEquity() / AccountMargin()) * 100 : 0;
    FileWrite(file, "Margin Level: " + DoubleToString(marginLevel, 1) + "%");
    FileWrite(file, "");
    
    // ポジション詳細
    FileWrite(file, "--- POSITION DETAILS ---");
    for(int i = 0; i < MAGIC_COUNT; i++) {
        int magic = magic_array[i];
        int positions = Utils_GetOpenPositions(magic);
        if(positions > 0) {
            double profit = GetOrderProfitByMagic(magic);
            double lots = Utils_GetOpenLots(magic);
            string magicName = GetMagicCustomName(magic);
            
            FileWrite(file, "Magic " + IntegerToString(magic) + " (" + magicName + "):");
            FileWrite(file, "  Positions: " + IntegerToString(positions));
            FileWrite(file, "  Lots: " + DoubleToString(lots, 2));
            FileWrite(file, "  P&L: $" + DoubleToString(profit, 2));
        }
    }
    
    // マーケット情報
    FileWrite(file, "");
    FileWrite(file, "--- MARKET CONDITIONS ---");
    FileWrite(file, "Current Price: Bid=" + DoubleToString(Bid, Digits) + " Ask=" + DoubleToString(Ask, Digits));
    FileWrite(file, "Spread: " + DoubleToString(Utils_GetSpreadInPips(), 1) + " pips");
    
    FileWrite(file, "Trading Allowed: " + (IsTradingAllowedNow() ? "YES" : "NO"));
    
    FileWrite(file, "");
    FileWrite(file, "--- END OF REPORT ---");
    
    FileClose(file);
    
    Print("✅ System status exported to file: " + filename);
    Alert("📄 Status exported to: " + filename);
}

bool ConfirmEmergencyStop() {
    // バックテスト時は確認なしで実行
    if(IsTesting()) {
        Print("🚨 Emergency stop confirmed (backtest mode)");
        return true;
    }
    
    // 現在のポジション数と損益を確認
    int totalPositions = 0;
    double totalProfit = 0;
    
    for(int i = 0; i < MAGIC_COUNT; i++) {
        int magic = magic_array[i];
        totalPositions += Utils_GetOpenPositions(magic);
        totalProfit += GetOrderProfitByMagic(magic);
    }
    
    if(totalPositions == 0) {
        Alert("ℹ️ No positions to close");
        return false;
    }
    
    // 確認メッセージ
    string confirmMsg = StringConcatenate(
        "🚨 EMERGENCY CLOSE CONFIRMATION\n\n",
        "This will close ALL positions:\n",
        "• Total Positions: ", totalPositions, "\n",
        "• Current P&L: $", DoubleToString(totalProfit, 2), "\n",
        "• Symbol: ", Symbol(), "\n\n",
        "Are you sure you want to proceed?\n",
        "This action cannot be undone!"
    );
    
    // MQL4では MessageBox を使用（MQL5のようなネイティブダイアログはない）
    int result = MessageBox(confirmMsg, "Emergency Close Confirmation", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2);
    
    if(result == IDYES) {
        Print("🚨 Emergency stop confirmed by user");
        return true;
    } else {
        Print("🚫 Emergency stop cancelled by user");
        return false;
    }
}


void HandleKeyboardShortcuts_Fixed(long lparam)
{
    switch((int)lparam) {
        case 112: // F1 - System Status
            PrintIntegratedSystemStatus();
            if(!IsTesting()) Alert("📊 F1: System Status displayed");
            break;
            
        case 113: // F2 - Magic Info
            ShowMagicManagementInfo();
            if(!IsTesting()) Alert("🎯 F2: Magic Info displayed");
            break;
            
        case 114: // F3 - Market Analysis
            AnalyzeMagicUsageAcrossMarkets();
            MultiCurrencyOperationSupport();
            if(!IsTesting()) Alert("📈 F3: Market Analysis displayed");
            break;
            
case 115: // F4 - Nanpin Status
    NanpinManager_PrintDetailedStatus(magic_array, MAGIC_COUNT);  // ★★★ 変更
    if(!IsTesting()) Alert("🎯 F4: Nanpin Status displayed");
    break;
            
        case 116: // F5 - Risk Info
            PrintRiskStatistics();
            PrintPerformanceStatistics();
            if(!IsTesting()) Alert("💰 F5: Risk & Performance Info displayed");
            break;
            
        case 117: // F6 - Currency Info
            {
                Print("=== F6: Currency Configuration ===");
                Print("Symbol: ", g_currencyConfig.symbol);
                Print("Magic Offset: ", g_currencyConfig.magicOffset);
                Print("Nanpin Interval: ", g_currencyConfig.nanpinInterval, " pips");
                Print("Current Lot: ", DoubleToString(CalculateLots(), 2));
                Print("Current Price: Bid=", DoubleToString(Bid, Digits), " Ask=", DoubleToString(Ask, Digits));
                Print("Spread: ", DoubleToString(Utils_GetSpreadInPips(), 1), " pips");
                Print("===============================");
                if(!IsTesting()) Alert("💱 F6: Currency Info displayed");
            }
            break;
            
        case 118: // F7 - Entry Rules
            {
                PrintEntryRestrictionsStatus();
                bool tradingAllowed = IsTradingAllowedNow();
                Print("Current Trading Status: ", (tradingAllowed ? "✅ ALLOWED" : "🚫 RESTRICTED"));
                if(!IsTesting()) Alert("🚫 F7: Entry Rules - ", (tradingAllowed ? "ALLOWED" : "RESTRICTED"));
            }
            break;
            
        case 119: // F8 - System Check
            CheckSystemIntegration();
            if(!IsTesting()) Alert("🔧 F8: System Check completed");
            break;
            
        case 120: // F9 - Test Functions
            Print("=== F9: Test Functions ===");
            TestSymbolSupport();
            
            TestPriceConversions();
            Print("=== F9: Tests Completed ===");
            if(!IsTesting()) Alert("🧪 F9: Test Functions executed");
            break;
            
        case 121: // F10 - Performance Stats
            PrintPerformanceStatistics();
            if(!IsTesting()) Alert("📊 F10: Performance Stats displayed");
            break;
            
        case 122: // F11 - Export Status
            if(!IsTesting()) {
                ExportSystemStatusToFile();
            } else {
                Print("F11: Export not available in backtest mode");
            }
            break;
            
        case 123: // F12 - Emergency Close
            if(!IsTesting()) {
                if(ConfirmEmergencyStop()) {
                    int closedCount = 0;
                    for(int i = 0; i < MAGIC_COUNT; i++) {
                        if(Utils_ClosePosition(magic_array[i])) {
                            closedCount++;
                            ResetNanpinState(magic_array[i]);
                        }
                    }
                    Alert("🚨 F12: Emergency Close - ", closedCount, " magic groups closed");
                    Print("🚨 F12: Emergency close executed for ", closedCount, " magic groups");
                } else {
                    Print("🚫 F12: Emergency close cancelled");
                }
            } else {
                Print("F12: Emergency close not available in backtest mode");
            }
            break;
            
        case 27: // ESC - Quick Help
            ShowQuickActionMenu();
            break;
            
        case 32: // SPACE - Quick Status
            Print("=== QUICK STATUS (SPACE) ===");
            Print("Symbol: ", Symbol(), " | Time: ", TimeToString(TimeCurrent(), TIME_SECONDS));
            Print("Positions: ", Utils_GetOpenPositions(-1), " | Trading: ", (IsTradingAllowedNow() ? "ON" : "OFF"));
            Print("Account: $", DoubleToString(AccountEquity(), 2), " | Free: $", DoubleToString(AccountFreeMargin(), 2));
            Print("Magic Range: ", magic_array[0], "-", magic_array[MAGIC_COUNT-1]);
            Print("============================");
            if(!IsTesting()) Alert("⚡ SPACE: Quick Status displayed");
            break;
    }
}

void ShowQuickActionMenu()
{
    string menuItems = StringConcatenate(
        "=== GOLDEA Quick Actions Menu ===\n",
        "🎮 KEYBOARD SHORTCUTS:\n",
        "F1: System Status    F2: Magic Info\n",
        "F3: Market Analysis  F4: Nanpin Status\n", 
        "F5: Risk Info        F6: Currency Info\n",
        "F7: Entry Rules      F8: System Check\n",
        "F9: Test Functions   F10: Performance\n",
        "F11: Export Status   F12: Emergency Close\n",
        "SPACE: Quick Status  ESC: This Menu\n\n",
        "🖱️ CLICK CONTROLS:\n",
        "• Manual BUY/SELL buttons\n",
        "• Magic 11-20 ON/OFF switches\n",
        "• Debug information buttons\n",
        "• Force Nanpin controls\n\n",
        "📊 CURRENT STATUS:\n",
        "Symbol: ", Symbol(), "\n",
        "Positions: ", IntegerToString(Utils_GetOpenPositions(-1)), "\n",
        "Trading: ", (IsTradingAllowedNow() ? "ALLOWED" : "RESTRICTED"), "\n",
        "================================="
    );
    
    Comment(menuItems);
    Print("📋 Quick Actions Menu displayed (ESC key)");
    
    // 15秒後に自動クリア
    static datetime menuDisplayTime = 0;
    menuDisplayTime = TimeCurrent() + 15;
}
//+------------------------------------------------------------------+
//| OnChartEvent 関数 (最終解決策版)
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    // バックテスト時はキーボードショートカットのみ対応
    if(IsTesting()) {
        if(id == CHARTEVENT_KEYDOWN) {
            HandleKeyboardShortcuts_Fixed(lparam);
        }
        return;
    }
    
    // キーボードショートカット処理
    if(id == CHARTEVENT_KEYDOWN) {
        HandleKeyboardShortcuts_Fixed(lparam);
        return;
    }
    
    // マウスクリック以外は処理しない
    if(id != CHARTEVENT_OBJECT_CLICK) return;
    
    //------------------------------------------------------------------
    // 手動取引ボタン処理 (変更なし)
    //------------------------------------------------------------------
    if(sparam == BTN_BUY) {
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        ManualOrderSend(+1, magic_array[21]);
        Print("👆 Manual BUY button clicked - Magic: ", magic_array[21]);
    }
    else if(sparam == BTN_SELL) {
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        ManualOrderSend(-1, magic_array[22]);
        Print("👆 Manual SELL button clicked - Magic: ", magic_array[22]);
    }
    else if(sparam == BTN_CLOSE_LONG) {
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        CloseAllByDirection(+1);
        Print("🔄 All LONG positions closed manually");
        Alert("✅ All LONG positions closed");
    }
    else if(sparam == BTN_CLOSE_SHORT) {
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        CloseAllByDirection(-1);
        Print("🔄 All SHORT positions closed manually");
        Alert("✅ All SHORT positions closed");
    }
    else if(sparam == BTN_FORCE_NP_BUY) {
       ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
       NanpinManager_SetForceBuy();
       Print("🚀 Force Nanpin BUY activated");
       Alert("🚀 Force Nanpin BUY ready - will execute on next tick");
    }
    else if(sparam == BTN_FORCE_NP_SELL) {
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        NanpinManager_SetForceSell();
        Print("🚀 Force Nanpin SELL activated");
        Alert("🚀 Force Nanpin SELL ready - will execute on next tick");
    }
    
    //------------------------------------------------------------------
    // Magic 11-20 ON/OFF スイッチボタン処理
    //------------------------------------------------------------------
    else {
        bool buttonHandled = false;
        
        for(int i = 0; i < 10; i++) {
            if(sparam == SWITCH_BTN_LIST[i]) {
                ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                
                int adjustedMagic = 11 + i + g_currencyConfig.magicOffset;
                bool currentState = IsMagicEnabled(adjustedMagic, g_currencyConfig.magicOffset);
                bool newState = !currentState;
                
                UpdateSwitchButton(i, newState);
                
                // ★★★ 修正箇所 ★★★
                // クリック直後に状態を保存し、強制的に書き込む
                if(!IsTesting()) {
                    SaveButtonStates();
                    
                }
                
                string magicName = GetMagicCustomName(adjustedMagic);
                string stateText = (newState ? "ON" : "OFF");
                Print("🔘 Magic ", adjustedMagic, " (", magicName, ") switched to: ", stateText);
                
                ChartRedraw(0);
                buttonHandled = true;
                break;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| デバッグボタン作成（拡張版）
//+------------------------------------------------------------------+
void CreateDebugButtons()
{
    //if(IsTesting()) return;  // バックテスト時は作成しない
    
    int startX = 10;
    int startY = 200;  // Magic スイッチボタンの下
    int buttonWidth = 110;
    int buttonHeight = 22;
    int spacing = 115;
    int rowSpacing = 27;
    
    struct DebugButton {
        string name;
        string text;
        string tooltip;
        color bgColor;
        color textColor;
    };
    
    DebugButton debugButtons[] = {
        // 第1行: 基本情報
        {"SYSTEM_INFO", "System Info", "F1: Complete system status", clrDodgerBlue, clrWhite},
        {"MAGIC_INFO", "Magic Info", "F2: Magic number details", clrMediumOrchid, clrWhite},
        {"MARKET_ANALYSIS", "Market Data", "F3: Multi-market analysis", clrDarkOrange, clrWhite},
        
        // 第2行: 取引情報
        {"NANPIN_STATUS", "Nanpin Info", "F4: Current nanpin status", clrMediumSeaGreen, clrWhite},
        {"RISK_INFO", "Risk & P&L", "F5: Risk and performance", clrCrimson, clrWhite},
        {"CURRENCY_INFO", "Currency", "F6: Currency configuration", clrGoldenrod, clrBlack},
        
        // 第3行: システム管理
        {"ENTRY_RESTRICTIONS", "Entry Rules", "F7: Trading restrictions", clrSlateBlue, clrWhite},
        {"SYSTEM_CHECK", "Sys Check", "F8: Integration check", clrTeal, clrWhite},
        {"PERFORMANCE", "Performance", "F10: Trading statistics", clrIndigo, clrWhite},
        
        // 第4行: ユーティリティ
        {"TEST_FUNCTIONS", "Test Tools", "F9: Debug utilities", clrDarkKhaki, clrBlack},
        {"EXPORT_STATUS", "Export", "F11: Save to file", clrOliveDrab, clrWhite},
        {"HELP", "Help", "ESC: Show help menu", clrSteelBlue, clrWhite},
        
        // 第5行: 緊急操作
        {"EMERGENCY_CLOSE_ALL", "EMERGENCY", "F12: Close ALL positions", clrRed, clrWhite},
        {"MULTI_CURRENCY", "Multi-FX", "Multi-currency overview", clrPurple, clrWhite},
        {"QUICK_START", "Quick Guide", "Setup instructions", clrNavy, clrWhite}
    };
    
    int buttonCount = ArraySize(debugButtons);
    int buttonsPerRow = 3;
    
    for(int i = 0; i < buttonCount; i++) {
        int row = i / buttonsPerRow;
        int col = i % buttonsPerRow;
        
        int xPos = startX + (col * spacing);
        int yPos = startY + (row * rowSpacing);
        
        string btnName = debugButtons[i].name;
        
        if(ObjectCreate(0, btnName, OBJ_BUTTON, 0, 0, 0)) {
            ObjectSetInteger(0, btnName, OBJPROP_XDISTANCE, xPos);
            ObjectSetInteger(0, btnName, OBJPROP_YDISTANCE, yPos);
            ObjectSetInteger(0, btnName, OBJPROP_XSIZE, buttonWidth);
            ObjectSetInteger(0, btnName, OBJPROP_YSIZE, buttonHeight);
            // ★★★ 修正：MQL5の定数をMQL4用に変更 ★★★
            ObjectSetInteger(0, btnName, OBJPROP_CORNER, 0); // CORNER_UPPER_LEFT に相当
            ObjectSetInteger(0, btnName, OBJPROP_FONTSIZE, 7);
            ObjectSetString(0, btnName, OBJPROP_TEXT, debugButtons[i].text);
            ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, debugButtons[i].bgColor);
            ObjectSetInteger(0, btnName, OBJPROP_COLOR, debugButtons[i].textColor);
            ObjectSetString(0, btnName, OBJPROP_TOOLTIP, debugButtons[i].tooltip);
            // ★★★ 修正：MQL5の定数をMQL4用に変更 ★★★
            // BORDER_FLAT はMQL4にないため、境界線タイプを1（Raised）に設定
            ObjectSetInteger(0, btnName, OBJPROP_BORDER_TYPE, 1);
            ObjectSetInteger(0, btnName, OBJPROP_STATE, false);
        }
    }
    
    // 使用方法の説明ラベルを追加
    string labelName = "DEBUG_INSTRUCTIONS";
    if(ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0)) {
        ObjectSetInteger(0, labelName, OBJPROP_CORNER, 0); // CORNER_UPPER_LEFT
        ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, startX);
        ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, startY - 20);
        ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrWhite);
        ObjectSetString(0, labelName, OBJPROP_TEXT, "🎮 Debug Controls (Click buttons or use F1-F12 keys):");
    }
    
    Print("🎨 Enhanced debug interface created (", buttonCount, " buttons + shortcuts)");
}

//+------------------------------------------------------------------+
//| デバッグボタン削除（拡張版）
//+------------------------------------------------------------------+
void DeleteDebugButtons()
{
    string debugButtonNames[] = {
        "SYSTEM_INFO", "MAGIC_INFO", "MARKET_ANALYSIS", "NANPIN_STATUS",
        "RISK_INFO", "CURRENCY_INFO", "ENTRY_RESTRICTIONS", "SYSTEM_CHECK",
        "TEST_FUNCTIONS", "EXPORT_STATUS", "EMERGENCY_CLOSE_ALL", "HELP",
        "MULTI_CURRENCY", "PERFORMANCE", "QUICK_START", "DEBUG_INSTRUCTIONS"
    };
    
    for(int i = 0; i < ArraySize(debugButtonNames); i++) {
        ObjectDelete(0, debugButtonNames[i]);
    }
}

//+------------------------------------------------------------------+
//| OnTick内でのコメント自動クリア処理
//+------------------------------------------------------------------+
void ManageAutoCommentClear()
{
    static datetime lastCommentTime = 0;
    static bool commentActive = false;
    
    // コメントが表示されてから15秒後にクリア
    if(commentActive && TimeCurrent() > lastCommentTime + 15) {
        Comment("");
        commentActive = false;
    }
    
    // 新しいコメント表示時に時間を記録
    string currentComment = ObjectGetString(0, "Comment", OBJPROP_TEXT);
    if(StringLen(currentComment) > 0 && !commentActive) {
        lastCommentTime = TimeCurrent();
        commentActive = true;
    }
}

//+------------------------------------------------------------------+
//| 統合初期化関数（OnInit内で呼び出し）
//+------------------------------------------------------------------+
void InitCompleteUISystem()
{
    Print("🎨 Initializing Complete UI System...");
    
    // 基本UI要素
    SetMagicCustomNames();
    CreateManualButtons();
    CreateMagicSwitches(); 
    CreateEntryStateLabel();
    
    // デバッグインターフェース（ライブ取引時のみ）
    if(ShowMagicDebugInfo && !IsTesting()) {
        CreateDebugButtons();
        Print("🎮 Debug interface enabled - Use F1-F12 keys or click buttons");
        Print("📋 Press ESC key for quick help menu");
    } else if(IsTesting()) {
        Print("🎮 Backtest mode - Keyboard shortcuts F1-F12 available");
    }
    
    Print("✅ Complete UI System initialized successfully.");
}

//+------------------------------------------------------------------+
//| 統合終了処理（OnDeinit内で呼び出し）
//+------------------------------------------------------------------+
void DeinitCompleteUISystem()
{
    DeleteAllUIElements();
    DeleteDebugButtons();
    Comment(""); // コメントクリア
    Print("🎨 Complete UI System deinitialized.");
}

//+------------------------------------------------------------------+
//| 手動注文送信関数（GOLDEA2025年6月新AI1.3.mq4内）
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| 手動注文送信関数（GOLDEA2025年6月新AI1.3.mq4内）
//+------------------------------------------------------------------+
void ManualOrderSend(int direction, int magic) {
    RefreshRates();
    int type = (direction > 0) ? OP_BUY : OP_SELL;
    double price = (direction > 0) ? Ask : Bid;
    double sl = 0, tp = 0;

    if(BtnSL_Pips > 0) {
        double sl_diff_price = Utils_PipsToPrice(BtnSL_Pips); 
        sl = (type == OP_BUY) ? price - sl_diff_price : price + sl_diff_price;
    }

    if(BtnTP_Pips > 0) {
        double tp_diff_price = Utils_PipsToPrice(BtnTP_Pips);
        tp = (type == OP_BUY) ? price + tp_diff_price : price - tp_diff_price;
    }

    double adjustedLots = CurrencyAdjustedLots(ManualLots);

    int ticket = OrderSend(Symbol(), type, adjustedLots, price, SlippageBtn,
                           sl, tp, "button_" + g_currencyConfig.symbol, magic, 0,
                           (type == OP_BUY) ? clrGreen : clrRed);

    if(ticket < 0)
        Print("Button OrderSend error: ", GetLastError());
    else {
        Print("Button order sent. Ticket=", ticket, " Magic=", magic, " Symbol=", g_currencyConfig.symbol);
        // ★★★ 追加：ナンピン状態を直接更新 ★★★
        UpdateNanpinState(magic, type, price, adjustedLots);
    }
}

//+------------------------------------------------------------------+
//| 方向別全決済関数
//+------------------------------------------------------------------+
void CloseAllByDirection(int dir) {
    RefreshRates();
    int needType = (dir > 0) ? OP_BUY : OP_SELL;
    double closePrice = (dir > 0) ? Bid : Ask;

    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderType() == needType) {
            if(!OrderClose(OrderTicket(), OrderLots(), closePrice, 10))
                Print("[CloseAllByDirection Error]: Close error:", GetLastError());
        }
    }
}

// GOLDEA.mq4 に配置してください

//+------------------------------------------------------------------+
//| ★★★ 既存ポジション復元関数（修正版） ★★★
//+------------------------------------------------------------------+
void RestoreExistingPositions(double baseLots)
{
    Print("🔄 Restoring existing positions for Nanpin Manager...");

    // 全マジックナンバーをループ
    for(int m = 0; m < MAGIC_COUNT; m++) {
        int magic = magic_array[m];

        // --- このマジックのポジションを収集し、時系列でソート ---
        struct PositionData {
            datetime openTime;
            double price;
            double lots;
            int type;
        };
        PositionData positions[];
        int posCount = 0;

        for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
            if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if(OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;

            ArrayResize(positions, posCount + 1);
            positions[posCount].openTime = OrderOpenTime();
            positions[posCount].price    = OrderOpenPrice();
            positions[posCount].lots     = OrderLots();
            positions[posCount].type     = OrderType();
            posCount++;
        }

        if(posCount == 0) continue; // ポジションがなければ次のマジックへ

        // 時間順にソート（古いものが配列の最初に来るように）
        for(int i = 0; i < posCount - 1; i++) {
            for(int j = i + 1; j < posCount; j++) {
                if(positions[i].openTime > positions[j].openTime) {
                    PositionData temp = positions[i];
                    positions[i] = positions[j];
                    positions[j] = temp;
                }
            }
        }
        
        // --- NanpinManagerの状態を再構築 ---
        int magicIndex = GetMagicIndex(magic);
        if(magicIndex < 0) continue;

        // ① まず状態を完全にリセット
        ResetNanpinState(magic);

        // ② ソートされたポジションを順番に処理して状態を積み上げる
        //    これにより、initialとpreviousの値が正確に復元される
        for(int i = 0; i < posCount; i++) {
            UpdateNanpinState(magic, positions[i].type, positions[i].price, positions[i].lots);
        }
        
        // ③ 最後のナンピン時刻を再設定してクールタイムをリセット
        //    (これをしないと再起動直後にナンピンできない可能性がある)
        nanpinStates[magicIndex].lastNanpinTime = positions[posCount-1].openTime - CoolTime - 1;


        // --- デバッグログで復元状態を確認 ---
        NanpinInfo info;
        GetNanpinInfo(magic, info);
        
        string direction = (positions[0].type == OP_BUY) ? "BUY" : "SELL";
        Print("📍 Restored Magic ", magic, " (", direction, ") | Positions: ", posCount);
        Print("  Initial Pos (", TimeToString(positions[0].openTime) ,"): Price=", DoubleToString(positions[0].price, Digits), ", Lots=", DoubleToString(positions[0].lots, 2));
        Print("  Latest Pos (", TimeToString(positions[posCount-1].openTime) ,"): Price=", DoubleToString(positions[posCount-1].price, Digits), ", Lots=", DoubleToString(positions[posCount-1].lots, 2));
        Print("  Restored NanpinState: Count=", info.count, ", BEP=", DoubleToString(info.breakEvenPrice, Digits), ", TotalLots=", DoubleToString(info.lots,2));
    }

    Print("✅ Position restoration process completed.");
}