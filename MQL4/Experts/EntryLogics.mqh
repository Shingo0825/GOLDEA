//+------------------------------------------------------------------+
//|                                              EntryLogics.mqh     |
//|         各マジックナンバーのエントリーロジック集 ― オフセット対応         |
//+------------------------------------------------------------------+
#property strict

// 依存ライブラリ ----------------------------------------------------
#include "CommonStructs.mqh" 
#include "TradingUtils.mqh"
#include "TrendLogic1.0.mqh"
#include "MADeviationRate_Lib.mqh"
#include "NanpinManager.mqh"




//+------------------------------------------------------------------+
//| マーケット情報構造体（変更なし）
//+------------------------------------------------------------------+
struct MarketData
{
    int    deviationReversalSignal;
    bool   devEntryBuy_2Sigma,  devEntrySell_2Sigma;
    bool   devEntryBuy_3Sigma,  devEntrySell_3Sigma;
    bool   devEntryBuy_3_0Sigma, devEntrySell_3_0Sigma;

    double rsi1m, rsi5m, stdDev_Magic34;

    double lots, tp_pips, sl_pips;

    bool   enableTrendLogic, enableCounterTrendLogic, enableRangeLogic;
    double magic3_RSI_Threshold, magic4_RSI_Threshold, magic34_StdDev_Threshold;
};

//===================================================================
//  ■ Magic 1–10  （無効化）
//===================================================================
void Logic_Magic1 (const MarketData &data, int magic)                      { return; }
void Logic_Magic2 (const MarketData &data, int magic)                      { return; }
void Logic_Magic3 (const MarketData &data, int magic, int &sig_ref)      { return; }
void Logic_Magic4 (const MarketData &data, int magic, int &sig_ref)      { return; }
void Logic_Magic5 (const MarketData &data, int magic)                      { return; }
void Logic_Magic6 (const MarketData &data, int magic)                      { return; }
void Logic_Magic7 (const MarketData &data, int magic)                      { return; }
void Logic_Magic8 (const MarketData &data, int magic)                      { return; }
void Logic_Magic9 (const MarketData &data, int magic)                      { return; }
void Logic_Magic10(const MarketData &data, int magic)                      { return; }

//===================================================================
//  ■ Magic 11 – 20  半自動ロジック（ボタン ON 時のみ）
//===================================================================

void Logic_Magic11(const MarketData &data, int magic)
{
    if(Utils_GetOpenLots(magic) <= 0)
    {
       if(Utils_OpenPosition(+1, data.lots, data.tp_pips, data.sl_pips,
                               magic, "Magic11_AlwaysLong"))
       {
          Print("✅ ENTRY: Magic", magic, " BUY | Always Long");
          // ★★★ 直接呼び出し可能 ★★★
          UpdateNanpinState(magic, OP_BUY, Ask, data.lots);
       }
    }
}

//--- Magic 12 : 常時ショート ---------------------------------------
void Logic_Magic12(const MarketData &data, int magic)
{
    if(Utils_GetOpenLots(magic) <= 0)
    {
       if(Utils_OpenPosition(-1, data.lots, data.tp_pips, data.sl_pips,
                               magic, "Magic12_AlwaysShort"))
       {
          Print("✅ ENTRY: Magic", magic, " SELL | Always Short");
          // ★★★ 直接呼び出し可能 ★★★
          UpdateNanpinState(magic, OP_SELL, Bid, data.lots);
       }
    }
}

//--- Magic 13 : EMAパーフェクト + EMA20戻り（ロング） --------------
void Logic_Magic13(const MarketData &data, int magic, const CurrencySettings &config)
{
    double ema20      = iMA(NULL, PERIOD_M1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema75      = iMA(NULL, PERIOD_M1, 75, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema200     = iMA(NULL, PERIOD_M1, 200, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema20_prev = iMA(NULL, PERIOD_M1, 20, 0, MODE_EMA, PRICE_CLOSE, 1);

    // ★★★ EMA75の傾き計算（5本分）★★★
    double ema75_5bars_ago = iMA(NULL, PERIOD_M1, 75, 0, MODE_EMA, PRICE_CLOSE, 5);
    double slope_price = ema75 - ema75_5bars_ago;
    double slope_pips = Utils_PriceToPips(slope_price);

    bool perfect   = (ema20 > ema75 && ema75 > ema200);
    bool pullback  = (iLow(NULL, PERIOD_M1, 1) < ema20_prev &&
                       iClose(NULL, PERIOD_M1, 0) >= ema20);
    bool slopeOK = (slope_pips >= config.emaMinSlopePips);

    if(perfect && pullback && slopeOK)
    {
       if(Utils_OpenPosition(+1, data.lots, data.tp_pips, data.sl_pips,
                               magic, "Magic13_EMA_Long"))
       {
          Print("✅ ENTRY: Magic", magic, " BUY | EMA Perfect + EMA20 Pullback");
          Print("   EMA75 Slope: ", DoubleToString(slope_pips, 2), 
                " pips/5bars (Min: ", config.emaMinSlopePips, ")");
          // ★★★ 追加：ナンピン状態初期化 ★★★
          UpdateNanpinState(magic, OP_BUY, Ask, data.lots);
       }
    }
}

//--- Magic 14 : EMAパーフェクト + EMA20戻り（ショート） ------------
void Logic_Magic14(const MarketData &data, int magic, const CurrencySettings &config)
{
    double ema20      = iMA(NULL, PERIOD_M1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema75      = iMA(NULL, PERIOD_M1, 75, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema200     = iMA(NULL, PERIOD_M1, 200, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema20_prev = iMA(NULL, PERIOD_M1, 20, 0, MODE_EMA, PRICE_CLOSE, 1);

    // ★★★ EMA75の傾き計算（5本分）★★★
    double ema75_5bars_ago = iMA(NULL, PERIOD_M1, 75, 0, MODE_EMA, PRICE_CLOSE, 5);
    double slope_price = ema75 - ema75_5bars_ago;
    double slope_pips = Utils_PriceToPips(slope_price);

    bool perfect   = (ema20 < ema75 && ema75 < ema200);
    bool pullback  = (iHigh(NULL, PERIOD_M1, 1) > ema20_prev &&
                       iClose(NULL, PERIOD_M1, 0) <= ema20);
    bool slopeOK = (slope_pips <= -config.emaMinSlopePips);

    if(perfect && pullback && slopeOK)
    {
       if(Utils_OpenPosition(-1, data.lots, data.tp_pips, data.sl_pips,
                               magic, "Magic14_EMA_Short"))
       {
          Print("✅ ENTRY: Magic", magic, " SELL | EMA Perfect + EMA20 Pullback");
          Print("   EMA75 Slope: ", DoubleToString(slope_pips, 2), 
                " pips/5bars (Min: -", config.emaMinSlopePips, ")");
          // ★★★ 追加：ナンピン状態初期化 ★★★
          UpdateNanpinState(magic, OP_SELL, Bid, data.lots);
       }
    }
}

//--- Magic 15 : RSI 30/20 反発（ロング） ----------------------------
void Logic_Magic15(const MarketData &data, int magic)
{
    static double prev_rsi[100];
    static bool arm30[100], arm20[100];
    int idx = magic % 100;
    double rsi = data.rsi1m;

    bool sig30 = arm30[idx] && prev_rsi[idx] < 30 && rsi >= 30;
    bool sig20 = arm20[idx] && prev_rsi[idx] < 20 && rsi >= 20;

    if((sig30 || sig20) &&
       Utils_OpenPosition(+1, data.lots, data.tp_pips, data.sl_pips,
                          magic, "Magic15_RSI_Long"))
    {
       Print("✅ ENTRY: Magic", magic, " BUY | RSI Reversal (", (sig30?"30":"20"), ")");
       if(sig30) arm30[idx] = false;
       if(sig20) arm20[idx] = false;
       // ★★★ 追加：ナンピン状態初期化 ★★★
       UpdateNanpinState(magic, OP_BUY, Ask, data.lots);
    }

    if(rsi > 50) { arm30[idx] = arm20[idx] = true; }
    prev_rsi[idx] = rsi;
}

//--- Magic 16 : RSI 70/80 反発（ショート） --------------------------
void Logic_Magic16(const MarketData &data, int magic)
{
    static double prev_rsi[100];
    static bool arm70[100], arm80[100];
    int idx = magic % 100;
    double rsi = data.rsi1m;

    bool sig70 = arm70[idx] && prev_rsi[idx] > 70 && rsi <= 70;
    bool sig80 = arm80[idx] && prev_rsi[idx] > 80 && rsi <= 80;

    if((sig70 || sig80) &&
       Utils_OpenPosition(-1, data.lots, data.tp_pips, data.sl_pips,
                          magic, "Magic16_RSI_Short"))
    {
       Print("✅ ENTRY: Magic", magic, " SELL | RSI Reversal (", (sig70?"70":"80"), ")");
       if(sig70) arm70[idx] = false;
       if(sig80) arm80[idx] = false;
       // ★★★ 追加：ナンピン状態初期化 ★★★
       UpdateNanpinState(magic, OP_SELL, Bid, data.lots);
    }

    if(rsi < 50) { arm70[idx] = arm80[idx] = true; }
    prev_rsi[idx] = rsi;
}

//--- Magic 17 : 乖離率 -σ 戻り（ロング） --------------------------
void Logic_Magic17(const MarketData &data, int magic)
{
    // OnTickで計算済みのシグナル(devEntryBuy_2Sigma)を直接使う
    if(data.devEntryBuy_2Sigma)
    {
        if(Utils_OpenPosition(+1, data.lots, data.tp_pips, data.sl_pips,
                               magic, "Magic17_DevRev_Long"))
        {
            Print("✅ ENTRY: Magic", magic, " BUY | Dev -σ→0σ");
            // ★★★ 追加：ナンピン状態初期化 ★★★
            UpdateNanpinState(magic, OP_BUY, Ask, data.lots);
        }
    }
}

//--- Magic 18 : 乖離率 +σ 戻り（ショート） ------------------------
void Logic_Magic18(const MarketData &data, int magic)
{
    // OnTickで計算済みのシグナル(devEntrySell_2Sigma)を直接使う
    if(data.devEntrySell_2Sigma)
    {
        if(Utils_OpenPosition(-1, data.lots, data.tp_pips, data.sl_pips,
                               magic, "Magic18_DevRev_Short"))
        {
            Print("✅ ENTRY: Magic", magic, " SELL | Dev +σ→0σ");
            // ★★★ 追加：ナンピン状態初期化 ★★★
            UpdateNanpinState(magic, OP_SELL, Bid, data.lots);
        }
    }
}

//--- Magic 19 / 20 : 予備 ------------------------------------------
void Logic_Magic19(const MarketData &data, int magic) 
{ 
    // 予備のロジック - 現在は何もしない
    return; 
}

void Logic_Magic20(const MarketData &data, int magic) 
{ 
    // 予備のロジック - 現在は何もしない
    return; 
}