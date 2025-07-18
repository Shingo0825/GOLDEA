//+------------------------------------------------------------------+
//|                                              CommonStructs.mqh  |
//|                                  共通構造体定義ファイル           |
//|                                  extern変数も一元管理            |
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//| シグマプリセット列挙型
//+------------------------------------------------------------------+
enum SigmaPreset {
    SIGMA_2_0 = 0,    // 2.0σ（敏感）
    SIGMA_2_5 = 1,    // 2.5σ（標準）
    SIGMA_3_0 = 2     // 3.0σ（慎重）
};

//+------------------------------------------------------------------+
//| ★★★ extern変数群（全てここで一元管理） ★★★
//+------------------------------------------------------------------+
extern int g_magicOffset;
extern double g_symbolNanpinInterval;

// トレーリング用extern変数
extern double g_singlePositionBEP;
extern double g_trailingStopPips;
extern double g_initP_TrendOK;
extern double g_initP_TrendNG;
extern double g_minP_TrendOK;
extern double g_minP_TrendNG;

extern double g_stdDevThreshold;


//+------------------------------------------------------------------+
//| 通貨ペア別設定構造体（完全版）
//+------------------------------------------------------------------+
struct CurrencySettings {
    string symbol;
    double spreadAdjust;
    double volatilityFactor;
    double lotAdjust;
    double nanpinInterval;
    double tpDefault;
    double slDefault;
    int magicOffset;
    
    double deviationSigma;
    double emaMinSlopePips;
    
    // トレーリングストップ設定群
    double singlePositionBEP;
    double trailingStopPips;
    double initP_TrendOK;
    double initP_TrendNG;
    double minP_TrendOK;
    double minP_TrendNG;
    
    // ★★★ 新規追加：標準偏差閾値 ★★★
    double stdDevThreshold;     // 低ボラティリティ判定の閾値
};

