//+------------------------------------------------------------------+
//|                                            CurrencyConfig.mqh   |
//|                    XMTrading全通貨ペア対応版設定ファイル          |
//+------------------------------------------------------------------+
#property strict

// ★★★ 重要：CommonStructs.mqhを最初にインクルード ★★★
#include "CommonStructs.mqh"
#include "MagicNumberManager.mqh"

bool InitCurrencySettings(CurrencySettings &config) {
    string currentSymbol = Symbol();
    int calculatedOffset = GetCurrentMagicOffset();

    // デフォルト値設定
    config.symbol           = currentSymbol;
    config.magicOffset      = calculatedOffset;
    config.nanpinInterval   = 20.0;
    config.lotAdjust        = 1.0;
    config.spreadAdjust     = 1.0;
    config.volatilityFactor = 1.0;
    config.deviationSigma   = 2.0;
    config.tpDefault        = 0.0;
    config.slDefault        = 0.0;
    config.emaMinSlopePips  = 1.0;
    
    // ★★★ デフォルトの標準偏差閾値 ★★★
    config.stdDevThreshold  = 1.5;  // ゴールド用デフォルト

    // デフォルトのトレーリング設定
    config.singlePositionBEP = 10.0;
    config.trailingStopPips  = 3.0;
    config.initP_TrendOK     = 15.0;
    config.initP_TrendNG     = 7.0;
    config.minP_TrendOK      = 10.0;
    config.minP_TrendNG      = 3.0;

//――――――――――――――――――――――――――――――――――――――――――――――――
    // 貴金属（Precious Metals）
    //――――――――――――――――――――――――――――――――――――――――――――――――
    if (StringFind(currentSymbol, "XAUUSD") >= 0 || StringFind(currentSymbol, "GOLD") >= 0) {
        config.nanpinInterval = 20.0;
        config.lotAdjust      = 1.0;
        config.deviationSigma = 2.5;
        config.emaMinSlopePips = 5.0;
        config.stdDevThreshold = 3.0;  // ★★★ ゴールド専用閾値 ★★★
        config.singlePositionBEP = 15.0;
        config.trailingStopPips  = 3.0;
        config.initP_TrendOK     = 13.0;
        config.initP_TrendNG     = 8.0;
        config.minP_TrendOK      = 8.0;
        config.minP_TrendNG      = 5.0;
    }
    else if (StringFind(currentSymbol, "XAGUSD") >= 0 || StringFind(currentSymbol, "SILVER") >= 0) {
        config.nanpinInterval = 8.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 3.0;
        config.stdDevThreshold = 0.3;  // ★★★ シルバー用閾値 ★★★
        config.singlePositionBEP = 15.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 20.0;
        config.initP_TrendNG     = 12.0;
        config.minP_TrendOK      = 15.0;
        config.minP_TrendNG      = 8.0;
    }
    else if (StringFind(currentSymbol, "XPDUSD") >= 0 || StringFind(currentSymbol, "PALLADIUM") >= 0) {
        config.nanpinInterval = 25.0;
        config.lotAdjust      = 0.3;
        config.deviationSigma = 3.0;
        config.emaMinSlopePips = 8.0;
        config.stdDevThreshold = 15.0; // ★★★ パラジウム用閾値（高価格） ★★★
        config.singlePositionBEP = 30.0;
        config.trailingStopPips  = 8.0;
        config.initP_TrendOK     = 40.0;
        config.initP_TrendNG     = 25.0;
        config.minP_TrendOK      = 30.0;
        config.minP_TrendNG      = 15.0;
    }
    else if (StringFind(currentSymbol, "XPTUSD") >= 0 || StringFind(currentSymbol, "PLATINUM") >= 0) {
        config.nanpinInterval = 20.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 6.0;
        config.stdDevThreshold = 8.0;  // ★★★ プラチナ用閾値 ★★★
        config.singlePositionBEP = 25.0;
        config.trailingStopPips  = 6.0;
        config.initP_TrendOK     = 35.0;
        config.initP_TrendNG     = 20.0;
        config.minP_TrendOK      = 25.0;
        config.minP_TrendNG      = 12.0;
    }
    
    //――――――――――――――――――――――――――――――――――――――――――――――――
    // メジャー通貨ペア（Major Pairs）
    //――――――――――――――――――――――――――――――――――――――――――――――――
    else if (StringFind(currentSymbol, "EURUSD") >= 0) {
        config.nanpinInterval = 12.0;
        config.lotAdjust      = 1.8;
        config.deviationSigma = 3.0;
        config.emaMinSlopePips = 1.0;
        config.stdDevThreshold = 0.0005; // ★★★ EURUSD用閾値 ★★★
        config.singlePositionBEP = 8.0;
        config.trailingStopPips  = 1.5;
        config.initP_TrendOK     = 10.0;
        config.initP_TrendNG     = 7.0;
        config.minP_TrendOK      = 6.0;
        config.minP_TrendNG      = 4.0;
    }
    else if (StringFind(currentSymbol, "GBPUSD") >= 0) {
        config.nanpinInterval = 15.0;
        config.lotAdjust      = 1.3;
        config.deviationSigma = 3.5;
        config.emaMinSlopePips = 1.2;
        config.stdDevThreshold = 0.0005; // ★★★ GBPUSD用閾値 ★★★
        config.singlePositionBEP = 12.0;
        config.trailingStopPips  = 2.0;
        config.initP_TrendOK     = 10.0;
        config.initP_TrendNG     = 7.0;
        config.minP_TrendOK      = 7.0;
        config.minP_TrendNG      = 4.0;
    }
    else if (StringFind(currentSymbol, "USDJPY") >= 0) {
        config.nanpinInterval = 10.0;
        config.lotAdjust      = 1.5;
        config.deviationSigma = 2.5;
        config.emaMinSlopePips = 1.5;
        config.stdDevThreshold = 0.1;   // ★★★ USDJPY用閾値（ご指摘の値）★★★
        config.singlePositionBEP = 10.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 10.0;
        config.initP_TrendNG     = 8.0;
        config.minP_TrendOK      = 8.0;
        config.minP_TrendNG      = 5.0;
    }
    else if (StringFind(currentSymbol, "USDCHF") >= 0) {
        config.nanpinInterval = 14.0;
        config.lotAdjust      = 1.1;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 0.8;
        config.stdDevThreshold = 0.0009; // ★★★ USDCHF用閾値 ★★★
        config.singlePositionBEP = 7.0;
        config.trailingStopPips  = 2.5;
        config.initP_TrendOK     = 10.0;
        config.initP_TrendNG     = 5.0;
        config.minP_TrendOK      = 7.0;
        config.minP_TrendNG      = 3.5;
    }
    else if (StringFind(currentSymbol, "AUDUSD") >= 0) {
        config.nanpinInterval = 14.0;
        config.lotAdjust      = 1.3;
        config.deviationSigma = 2.0;
        config.emaMinSlopePips = 1.1;
        config.stdDevThreshold = 0.0007; // ★★★ AUDUSD用閾値 ★★★
        config.singlePositionBEP = 9.0;
        config.trailingStopPips  = 3.0;
        config.initP_TrendOK     = 13.0;
        config.initP_TrendNG     = 7.0;
        config.minP_TrendOK      = 9.0;
        config.minP_TrendNG      = 4.5;
    }
    else if (StringFind(currentSymbol, "NZDUSD") >= 0) {
        config.nanpinInterval = 16.0;
        config.lotAdjust      = 1.4;
        config.deviationSigma = 2.2;
        config.emaMinSlopePips = 1.0;
        config.stdDevThreshold = 0.0008; // ★★★ NZDUSD用閾値 ★★★
        config.singlePositionBEP = 10.0;
        config.trailingStopPips  = 3.5;
        config.initP_TrendOK     = 14.0;
        config.initP_TrendNG     = 8.0;
        config.minP_TrendOK      = 10.0;
        config.minP_TrendNG      = 5.0;
    }
    else if (StringFind(currentSymbol, "USDCAD") >= 0) {
        config.nanpinInterval = 18.0;
        config.lotAdjust      = 1.2;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 1.1;
        config.stdDevThreshold = 0.0009; // ★★★ USDCAD用閾値 ★★★
        config.singlePositionBEP = 11.0;
        config.trailingStopPips  = 3.5;
        config.initP_TrendOK     = 15.0;
        config.initP_TrendNG     = 8.0;
        config.minP_TrendOK      = 11.0;
        config.minP_TrendNG      = 5.5;
    }
    
    //――――――――――――――――――――――――――――――――――――――――――――――――
    // マイナー通貨ペア（Minor Pairs / Cross Currencies）
    //――――――――――――――――――――――――――――――――――――――――――――――――
    
    // --- EUR Cross Pairs ---
    else if (StringFind(currentSymbol, "EURGBP") >= 0) {
        config.nanpinInterval = 12.0;
        config.lotAdjust      = 1.1;
        config.deviationSigma = 1.9;
        config.emaMinSlopePips = 0.7;
        config.stdDevThreshold = 0.0006; // ★★★ EURGBP用閾値 ★★★
        config.singlePositionBEP = 6.0;
        config.trailingStopPips  = 2.0;
        config.initP_TrendOK     = 8.0;
        config.initP_TrendNG     = 4.0;
        config.minP_TrendOK      = 6.0;
        config.minP_TrendNG      = 3.0;
    }
    else if (StringFind(currentSymbol, "EURAUD") >= 0) {
        config.nanpinInterval = 16.0;
        config.lotAdjust      = 1.2;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 1.3;
        config.stdDevThreshold = 0.0010; // ★★★ EURAUD用閾値 ★★★
        config.singlePositionBEP = 13.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 18.0;
        config.initP_TrendNG     = 10.0;
        config.minP_TrendOK      = 13.0;
        config.minP_TrendNG      = 6.5;
    }
    else if (StringFind(currentSymbol, "EURNZD") >= 0) {
        config.nanpinInterval = 18.0;
        config.lotAdjust      = 1.3;
        config.deviationSigma = 2.2;
        config.emaMinSlopePips = 1.4;
        config.stdDevThreshold = 0.0011; // ★★★ EURNZD用閾値 ★★★
        config.singlePositionBEP = 14.0;
        config.trailingStopPips  = 4.5;
        config.initP_TrendOK     = 19.0;
        config.initP_TrendNG     = 11.0;
        config.minP_TrendOK      = 14.0;
        config.minP_TrendNG      = 7.0;
    }
    else if (StringFind(currentSymbol, "EURCAD") >= 0) {
        config.nanpinInterval = 15.0;
        config.lotAdjust      = 1.2;
        config.deviationSigma = 2.0;
        config.emaMinSlopePips = 1.2;
        config.stdDevThreshold = 0.0010; // ★★★ EURCAD用閾値 ★★★
        config.singlePositionBEP = 12.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 16.0;
        config.initP_TrendNG     = 9.0;
        config.minP_TrendOK      = 12.0;
        config.minP_TrendNG      = 6.0;
    }
    else if (StringFind(currentSymbol, "EURCHF") >= 0) {
        config.nanpinInterval = 11.0;
        config.lotAdjust      = 1.0;
        config.deviationSigma = 1.8;
        config.emaMinSlopePips = 0.6;
        config.stdDevThreshold = 0.0007; // ★★★ EURCHF用閾値 ★★★
        config.singlePositionBEP = 6.0;
        config.trailingStopPips  = 2.5;
        config.initP_TrendOK     = 8.0;
        config.initP_TrendNG     = 4.0;
        config.minP_TrendOK      = 6.0;
        config.minP_TrendNG      = 3.0;
    }
    else if (StringFind(currentSymbol, "EURSEK") >= 0) {
        config.nanpinInterval = 25.0;
        config.lotAdjust      = 0.8;
        config.deviationSigma = 2.3;
        config.emaMinSlopePips = 2.0;
        config.stdDevThreshold = 0.008;  // ★★★ EURSEK用閾値 ★★★
        config.singlePositionBEP = 20.0;
        config.trailingStopPips  = 6.0;
        config.initP_TrendOK     = 30.0;
        config.initP_TrendNG     = 18.0;
        config.minP_TrendOK      = 20.0;
        config.minP_TrendNG      = 10.0;
    }
    else if (StringFind(currentSymbol, "EURNOK") >= 0) {
        config.nanpinInterval = 30.0;
        config.lotAdjust      = 0.7;
        config.deviationSigma = 2.4;
        config.emaMinSlopePips = 2.5;
        config.stdDevThreshold = 0.010;  // ★★★ EURNOK用閾値 ★★★
        config.singlePositionBEP = 25.0;
        config.trailingStopPips  = 7.0;
        config.initP_TrendOK     = 35.0;
        config.initP_TrendNG     = 20.0;
        config.minP_TrendOK      = 25.0;
        config.minP_TrendNG      = 12.0;
    }
    else if (StringFind(currentSymbol, "EURPLN") >= 0) {
        config.nanpinInterval = 35.0;
        config.lotAdjust      = 0.6;
        config.deviationSigma = 2.7;
        config.emaMinSlopePips = 3.0;
        config.stdDevThreshold = 2.2;    // ★★★ ZARJPY用閾値 ★★★
        config.singlePositionBEP = 30.0;
        config.trailingStopPips  = 8.0;
        config.initP_TrendOK     = 40.0;
        config.initP_TrendNG     = 25.0;
        config.minP_TrendOK      = 30.0;
        config.minP_TrendNG      = 15.0;
    }
    else if (StringFind(currentSymbol, "TRYJPY") >= 0) {
        config.nanpinInterval = 40.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 3.5;
        config.stdDevThreshold = 0.28;   // ★★★ TRYJPY用閾値 ★★★
        config.singlePositionBEP = 35.0;
        config.trailingStopPips  = 10.0;
        config.initP_TrendOK     = 45.0;
        config.initP_TrendNG     = 30.0;
        config.minP_TrendOK      = 35.0;
        config.minP_TrendNG      = 18.0;
    }
    else if (StringFind(currentSymbol, "MXNJPY") >= 0) {
        config.nanpinInterval = 38.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 3.2;
        config.stdDevThreshold = 0.22;   // ★★★ MXNJPY用閾値 ★★★
        config.singlePositionBEP = 32.0;
        config.trailingStopPips  = 9.0;
        config.initP_TrendOK     = 42.0;
        config.initP_TrendNG     = 28.0;
        config.minP_TrendOK      = 32.0;
        config.minP_TrendNG      = 16.0;
    }
    
    //――――――――――――――――――――――――――――――――――――――――――――――――
    // 仮想通貨（Cryptocurrencies）
    //――――――――――――――――――――――――――――――――――――――――――――――――
    else if (StringFind(currentSymbol, "BTCUSD") >= 0) {
        config.nanpinInterval = 100.0;
        config.lotAdjust      = 0.1;
        config.deviationSigma = 3.0;
        config.emaMinSlopePips = 20.0;
        config.stdDevThreshold = 500.0;  // ★★★ BTCUSD用閾値（高価格対応） ★★★
        config.singlePositionBEP = 50.0;
        config.trailingStopPips  = 15.0;
        config.initP_TrendOK     = 80.0;
        config.initP_TrendNG     = 40.0;
        config.minP_TrendOK      = 50.0;
        config.minP_TrendNG      = 25.0;
    }
    else if (StringFind(currentSymbol, "ETHUSD") >= 0) {
        config.nanpinInterval = 10.0;
        config.lotAdjust      = 0.2;
        config.deviationSigma = 3.0;
        config.emaMinSlopePips = 15.0;
        config.stdDevThreshold = 25.0;   // ★★★ ETHUSD用閾値 ★★★
        config.singlePositionBEP = 30.0;
        config.trailingStopPips  = 10.0;
        config.initP_TrendOK     = 50.0;
        config.initP_TrendNG     = 25.0;
        config.minP_TrendOK      = 30.0;
        config.minP_TrendNG      = 15.0;
    }
    else if (StringFind(currentSymbol, "LTCUSD") >= 0) {
        config.nanpinInterval = 22.0;
        config.lotAdjust      = 0.3;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 12.0;
        config.stdDevThreshold = 8.0;    // ★★★ LTCUSD用閾値 ★★★
        config.singlePositionBEP = 25.0;
        config.trailingStopPips  = 8.0;
        config.initP_TrendOK     = 38.0;
        config.initP_TrendNG     = 20.0;
        config.minP_TrendOK      = 25.0;
        config.minP_TrendNG      = 12.0;
    }
    else if (StringFind(currentSymbol, "XRPUSD") >= 0) {
        config.nanpinInterval = 8.0;
        config.lotAdjust      = 0.4;
        config.deviationSigma = 2.9;
        config.emaMinSlopePips = 5.0;
        config.stdDevThreshold = 0.008;  // ★★★ XRPUSD用閾値 ★★★
        config.singlePositionBEP = 15.0;
        config.trailingStopPips  = 5.0;
        config.initP_TrendOK     = 20.0;
        config.initP_TrendNG     = 12.0;
        config.minP_TrendOK      = 15.0;
        config.minP_TrendNG      = 8.0;
    }
    else if (StringFind(currentSymbol, "ADAUSD") >= 0) {
        config.nanpinInterval = 6.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 3.0;
        config.stdDevThreshold = 0.005;  // ★★★ ADAUSD用閾値 ★★★
        config.singlePositionBEP = 12.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 16.0;
        config.initP_TrendNG     = 10.0;
        config.minP_TrendOK      = 12.0;
        config.minP_TrendNG      = 6.0;
    }
    else if (StringFind(currentSymbol, "DOTUSD") >= 0) {
        config.nanpinInterval = 12.0;
        config.lotAdjust      = 0.3;
        config.deviationSigma = 2.9;
        config.emaMinSlopePips = 8.0;
        config.stdDevThreshold = 0.3;    // ★★★ DOTUSD用閾値 ★★★
        config.singlePositionBEP = 18.0;
        config.trailingStopPips  = 6.0;
        config.initP_TrendOK     = 24.0;
        config.initP_TrendNG     = 15.0;
        config.minP_TrendOK      = 18.0;
        config.minP_TrendNG      = 9.0;
    }

    else if (StringFind(currentSymbol, "EURHUF") >= 0) {
        config.nanpinInterval = 40.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.6;
        config.emaMinSlopePips = 3.5;
        config.stdDevThreshold = 1.2;    // ★★★ EURHUF用閾値（高数値） ★★★
        config.singlePositionBEP = 35.0;
        config.trailingStopPips  = 10.0;
        config.initP_TrendOK     = 45.0;
        config.initP_TrendNG     = 30.0;
        config.minP_TrendOK      = 35.0;
        config.minP_TrendNG      = 18.0;
    }
    else if (StringFind(currentSymbol, "EURCZK") >= 0) {
        config.nanpinInterval = 45.0;
        config.lotAdjust      = 0.4;
        config.deviationSigma = 2.7;
        config.emaMinSlopePips = 4.0;
        config.stdDevThreshold = 0.15;   // ★★★ EURCZK用閾値 ★★★
        config.singlePositionBEP = 40.0;
        config.trailingStopPips  = 12.0;
        config.initP_TrendOK     = 50.0;
        config.initP_TrendNG     = 35.0;
        config.minP_TrendOK      = 40.0;
        config.minP_TrendNG      = 20.0;
    }
    else if (StringFind(currentSymbol, "EURDKK") >= 0) {
        config.nanpinInterval = 20.0;
        config.lotAdjust      = 0.9;
        config.deviationSigma = 2.0;
        config.emaMinSlopePips = 1.5;
        config.stdDevThreshold = 0.005;  // ★★★ EURDKK用閾値 ★★★
        config.singlePositionBEP = 15.0;
        config.trailingStopPips  = 5.0;
        config.initP_TrendOK     = 22.0;
        config.initP_TrendNG     = 12.0;
        config.minP_TrendOK      = 15.0;
        config.minP_TrendNG      = 8.0;
    }
    
    // --- GBP Cross Pairs ---
    else if (StringFind(currentSymbol, "GBPAUD") >= 0) {
        config.nanpinInterval = 18.0;
        config.lotAdjust      = 1.3;
        config.deviationSigma = 2.3;
        config.emaMinSlopePips = 1.6;
        config.stdDevThreshold = 0.0015; // ★★★ GBPAUD用閾値 ★★★
        config.singlePositionBEP = 16.0;
        config.trailingStopPips  = 5.0;
        config.initP_TrendOK     = 22.0;
        config.initP_TrendNG     = 13.0;
        config.minP_TrendOK      = 16.0;
        config.minP_TrendNG      = 8.0;
    }
    else if (StringFind(currentSymbol, "GBPNZD") >= 0) {
        config.nanpinInterval = 20.0;
        config.lotAdjust      = 1.4;
        config.deviationSigma = 2.4;
        config.emaMinSlopePips = 1.8;
        config.stdDevThreshold = 0.0018; // ★★★ GBPNZD用閾値 ★★★
        config.singlePositionBEP = 18.0;
        config.trailingStopPips  = 6.0;
        config.initP_TrendOK     = 25.0;
        config.initP_TrendNG     = 15.0;
        config.minP_TrendOK      = 18.0;
        config.minP_TrendNG      = 9.0;
    }
    else if (StringFind(currentSymbol, "GBPCAD") >= 0) {
        config.nanpinInterval = 17.0;
        config.lotAdjust      = 1.3;
        config.deviationSigma = 2.2;
        config.emaMinSlopePips = 1.5;
        config.stdDevThreshold = 0.0014; // ★★★ GBPCAD用閾値 ★★★
        config.singlePositionBEP = 15.0;
        config.trailingStopPips  = 5.0;
        config.initP_TrendOK     = 20.0;
        config.initP_TrendNG     = 12.0;
        config.minP_TrendOK      = 15.0;
        config.minP_TrendNG      = 7.5;
    }
    else if (StringFind(currentSymbol, "GBPCHF") >= 0) {
        config.nanpinInterval = 15.0;
        config.lotAdjust      = 1.2;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 1.2;
        config.stdDevThreshold = 0.0013; // ★★★ GBPCHF用閾値 ★★★
        config.singlePositionBEP = 13.0;
        config.trailingStopPips  = 4.5;
        config.initP_TrendOK     = 18.0;
        config.initP_TrendNG     = 10.0;
        config.minP_TrendOK      = 13.0;
        config.minP_TrendNG      = 6.5;
    }
    else if (StringFind(currentSymbol, "GBPSEK") >= 0) {
        config.nanpinInterval = 30.0;
        config.lotAdjust      = 0.8;
        config.deviationSigma = 2.5;
        config.emaMinSlopePips = 2.5;
        config.stdDevThreshold = 0.012;  // ★★★ GBPSEK用閾値 ★★★
        config.singlePositionBEP = 25.0;
        config.trailingStopPips  = 7.0;
        config.initP_TrendOK     = 35.0;
        config.initP_TrendNG     = 20.0;
        config.minP_TrendOK      = 25.0;
        config.minP_TrendNG      = 12.0;
    }
    else if (StringFind(currentSymbol, "GBPNOK") >= 0) {
        config.nanpinInterval = 35.0;
        config.lotAdjust      = 0.7;
        config.deviationSigma = 2.6;
        config.emaMinSlopePips = 3.0;
        config.stdDevThreshold = 0.015;  // ★★★ GBPNOK用閾値 ★★★
        config.singlePositionBEP = 30.0;
        config.trailingStopPips  = 8.0;
        config.initP_TrendOK     = 40.0;
        config.initP_TrendNG     = 25.0;
        config.minP_TrendOK      = 30.0;
        config.minP_TrendNG      = 15.0;
    }
    
    // --- USD Cross Pairs ---
    else if (StringFind(currentSymbol, "USDSEK") >= 0) {
        config.nanpinInterval = 25.0;
        config.lotAdjust      = 0.9;
        config.deviationSigma = 2.3;
        config.emaMinSlopePips = 2.0;
        config.stdDevThreshold = 0.08;   // ★★★ USDSEK用閾値 ★★★
        config.singlePositionBEP = 20.0;
        config.trailingStopPips  = 6.0;
        config.initP_TrendOK     = 28.0;
        config.initP_TrendNG     = 16.0;
        config.minP_TrendOK      = 20.0;
        config.minP_TrendNG      = 10.0;
    }
    else if (StringFind(currentSymbol, "USDNOK") >= 0) {
        config.nanpinInterval = 30.0;
        config.lotAdjust      = 0.8;
        config.deviationSigma = 2.4;
        config.emaMinSlopePips = 2.5;
        config.stdDevThreshold = 0.10;   // ★★★ USDNOK用閾値 ★★★
        config.singlePositionBEP = 25.0;
        config.trailingStopPips  = 7.0;
        config.initP_TrendOK     = 32.0;
        config.initP_TrendNG     = 18.0;
        config.minP_TrendOK      = 25.0;
        config.minP_TrendNG      = 12.0;
    }
    else if (StringFind(currentSymbol, "USDDKK") >= 0) {
        config.nanpinInterval = 20.0;
        config.lotAdjust      = 1.0;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 1.5;
        config.stdDevThreshold = 0.05;   // ★★★ USDDKK用閾値 ★★★
        config.singlePositionBEP = 15.0;
        config.trailingStopPips  = 5.0;
        config.initP_TrendOK     = 20.0;
        config.initP_TrendNG     = 11.0;
        config.minP_TrendOK      = 15.0;
        config.minP_TrendNG      = 7.0;
    }
    else if (StringFind(currentSymbol, "USDPLN") >= 0) {
        config.nanpinInterval = 35.0;
        config.lotAdjust      = 0.7;
        config.deviationSigma = 2.5;
        config.emaMinSlopePips = 3.0;
        config.stdDevThreshold = 0.012;  // ★★★ USDPLN用閾値 ★★★
        config.singlePositionBEP = 30.0;
        config.trailingStopPips  = 8.0;
        config.initP_TrendOK     = 38.0;
        config.initP_TrendNG     = 22.0;
        config.minP_TrendOK      = 30.0;
        config.minP_TrendNG      = 15.0;
    }
    else if (StringFind(currentSymbol, "USDHUF") >= 0) {
        config.nanpinInterval = 40.0;
        config.lotAdjust      = 0.6;
        config.deviationSigma = 2.6;
        config.emaMinSlopePips = 3.5;
        config.stdDevThreshold = 2.5;    // ★★★ USDHUF用閾値（高数値） ★★★
        config.singlePositionBEP = 35.0;
        config.trailingStopPips  = 10.0;
        config.initP_TrendOK     = 42.0;
        config.initP_TrendNG     = 28.0;
        config.minP_TrendOK      = 35.0;
        config.minP_TrendNG      = 18.0;
    }
    else if (StringFind(currentSymbol, "USDCZK") >= 0) {
        config.nanpinInterval = 45.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.7;
        config.emaMinSlopePips = 4.0;
        config.stdDevThreshold = 0.25;   // ★★★ USDCZK用閾値 ★★★
        config.singlePositionBEP = 40.0;
        config.trailingStopPips  = 12.0;
        config.initP_TrendOK     = 48.0;
        config.initP_TrendNG     = 32.0;
        config.minP_TrendOK      = 40.0;
        config.minP_TrendNG      = 20.0;
    }
    else if (StringFind(currentSymbol, "USDTRY") >= 0) {
        config.nanpinInterval = 60.0;
        config.lotAdjust      = 0.3;
        config.deviationSigma = 3.2;
        config.emaMinSlopePips = 5.0;
        config.stdDevThreshold = 0.40;   // ★★★ USDTRY用閾値（高ボラ） ★★★
        config.singlePositionBEP = 50.0;
        config.trailingStopPips  = 15.0;
        config.initP_TrendOK     = 70.0;
        config.initP_TrendNG     = 45.0;
        config.minP_TrendOK      = 50.0;
        config.minP_TrendNG      = 25.0;
    }
    else if (StringFind(currentSymbol, "USDZAR") >= 0) {
        config.nanpinInterval = 50.0;
        config.lotAdjust      = 0.4;
        config.deviationSigma = 3.0;
        config.emaMinSlopePips = 4.5;
        config.stdDevThreshold = 0.30;   // ★★★ USDZAR用閾値 ★★★
        config.singlePositionBEP = 45.0;
        config.trailingStopPips  = 12.0;
        config.initP_TrendOK     = 60.0;
        config.initP_TrendNG     = 35.0;
        config.minP_TrendOK      = 45.0;
        config.minP_TrendNG      = 22.0;
    }
    else if (StringFind(currentSymbol, "USDMXN") >= 0) {
        config.nanpinInterval = 55.0;
        config.lotAdjust      = 0.3;
        config.deviationSigma = 3.1;
        config.emaMinSlopePips = 5.0;
        config.stdDevThreshold = 0.35;   // ★★★ USDMXN用閾値 ★★★
        config.singlePositionBEP = 50.0;
        config.trailingStopPips  = 14.0;
        config.initP_TrendOK     = 65.0;
        config.initP_TrendNG     = 40.0;
        config.minP_TrendOK      = 50.0;
        config.minP_TrendNG      = 25.0;
    }
    else if (StringFind(currentSymbol, "USDSGD") >= 0) {
        config.nanpinInterval = 18.0;
        config.lotAdjust      = 1.1;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 1.3;
        config.stdDevThreshold = 0.0012; // ★★★ USDSGD用閾値 ★★★
        config.singlePositionBEP = 13.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 18.0;
        config.initP_TrendNG     = 10.0;
        config.minP_TrendOK      = 13.0;
        config.minP_TrendNG      = 6.5;
    }
    else if (StringFind(currentSymbol, "USDHKD") >= 0) {
        config.nanpinInterval = 12.0;
        config.lotAdjust      = 1.2;
        config.deviationSigma = 1.8;
        config.emaMinSlopePips = 0.8;
        config.stdDevThreshold = 0.0008; // ★★★ USDHKD用閾値 ★★★
        config.singlePositionBEP = 8.0;
        config.trailingStopPips  = 2.5;
        config.initP_TrendOK     = 12.0;
        config.initP_TrendNG     = 6.0;
        config.minP_TrendOK      = 8.0;
        config.minP_TrendNG      = 4.0;
    }
    
    // --- AUD Cross Pairs ---
    else if (StringFind(currentSymbol, "AUDCAD") >= 0) {
        config.nanpinInterval = 15.0;
        config.lotAdjust      = 1.2;
        config.deviationSigma = 2.0;
        config.emaMinSlopePips = 1.1;
        config.stdDevThreshold = 0.0008; // ★★★ AUDCAD用閾値 ★★★
        config.singlePositionBEP = 12.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 16.0;
        config.initP_TrendNG     = 9.0;
        config.minP_TrendOK      = 12.0;
        config.minP_TrendNG      = 6.0;
    }
    else if (StringFind(currentSymbol, "AUDNZD") >= 0) {
        config.nanpinInterval = 10.0;
        config.lotAdjust      = 1.1;
        config.deviationSigma = 1.8;
        config.emaMinSlopePips = 0.8;
        config.stdDevThreshold = 0.0005; // ★★★ AUDNZD用閾値 ★★★
        config.singlePositionBEP = 7.0;
        config.trailingStopPips  = 2.5;
        config.initP_TrendOK     = 10.0;
        config.initP_TrendNG     = 5.0;
        config.minP_TrendOK      = 7.0;
        config.minP_TrendNG      = 3.5;
    }
    else if (StringFind(currentSymbol, "AUDCHF") >= 0) {
        config.nanpinInterval = 14.0;
        config.lotAdjust      = 1.1;
        config.deviationSigma = 2.0;
        config.emaMinSlopePips = 1.0;
        config.stdDevThreshold = 0.0007; // ★★★ AUDCHF用閾値 ★★★
        config.singlePositionBEP = 10.0;
        config.trailingStopPips  = 3.5;
        config.initP_TrendOK     = 14.0;
        config.initP_TrendNG     = 8.0;
        config.minP_TrendOK      = 10.0;
        config.minP_TrendNG      = 5.0;
    }
    else if (StringFind(currentSymbol, "AUDSEK") >= 0) {
        config.nanpinInterval = 25.0;
        config.lotAdjust      = 0.8;
        config.deviationSigma = 2.3;
        config.emaMinSlopePips = 2.0;
        config.stdDevThreshold = 0.006;  // ★★★ AUDSEK用閾値 ★★★
        config.singlePositionBEP = 20.0;
        config.trailingStopPips  = 6.0;
        config.initP_TrendOK     = 28.0;
        config.initP_TrendNG     = 16.0;
        config.minP_TrendOK      = 20.0;
        config.minP_TrendNG      = 10.0;
    }
    else if (StringFind(currentSymbol, "AUDSGD") >= 0) {
        config.nanpinInterval = 16.0;
        config.lotAdjust      = 1.0;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 1.2;
        config.stdDevThreshold = 0.0009; // ★★★ AUDSGD用閾値 ★★★
        config.singlePositionBEP = 12.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 16.0;
        config.initP_TrendNG     = 9.0;
        config.minP_TrendOK      = 12.0;
        config.minP_TrendNG      = 6.0;
    }
    
    // --- NZD Cross Pairs ---
    else if (StringFind(currentSymbol, "NZDCAD") >= 0) {
        config.nanpinInterval = 16.0;
        config.lotAdjust      = 1.3;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 1.1;
        config.stdDevThreshold = 0.0009; // ★★★ NZDCAD用閾値 ★★★
        config.singlePositionBEP = 13.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 17.0;
        config.initP_TrendNG     = 10.0;
        config.minP_TrendOK      = 13.0;
        config.minP_TrendNG      = 6.5;
    }
    else if (StringFind(currentSymbol, "NZDCHF") >= 0) {
        config.nanpinInterval = 15.0;
        config.lotAdjust      = 1.2;
        config.deviationSigma = 2.0;
        config.emaMinSlopePips = 0.9;
        config.stdDevThreshold = 0.0008; // ★★★ NZDCHF用閾値 ★★★
        config.singlePositionBEP = 11.0;
        config.trailingStopPips  = 3.5;
        config.initP_TrendOK     = 15.0;
        config.initP_TrendNG     = 8.0;
        config.minP_TrendOK      = 11.0;
        config.minP_TrendNG      = 5.5;
    }
    else if (StringFind(currentSymbol, "NZDSEK") >= 0) {
        config.nanpinInterval = 28.0;
        config.lotAdjust      = 0.8;
        config.deviationSigma = 2.4;
        config.emaMinSlopePips = 2.2;
        config.stdDevThreshold = 0.007;  // ★★★ NZDSEK用閾値 ★★★
        config.singlePositionBEP = 22.0;
        config.trailingStopPips  = 6.5;
        config.initP_TrendOK     = 30.0;
        config.initP_TrendNG     = 18.0;
        config.minP_TrendOK      = 22.0;
        config.minP_TrendNG      = 11.0;
    }
    else if (StringFind(currentSymbol, "NZDSGD") >= 0) {
        config.nanpinInterval = 17.0;
        config.lotAdjust      = 1.0;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 1.3;
        config.stdDevThreshold = 0.0010; // ★★★ NZDSGD用閾値 ★★★
        config.singlePositionBEP = 13.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 17.0;
        config.initP_TrendNG     = 10.0;
        config.minP_TrendOK      = 13.0;
        config.minP_TrendNG      = 6.5;
    }
    
    // --- CAD Cross Pairs ---
    else if (StringFind(currentSymbol, "CADCHF") >= 0) {
        config.nanpinInterval = 14.0;
        config.lotAdjust      = 1.1;
        config.deviationSigma = 1.9;
        config.emaMinSlopePips = 0.8;
        config.stdDevThreshold = 0.0007; // ★★★ CADCHF用閾値 ★★★
        config.singlePositionBEP = 9.0;
        config.trailingStopPips  = 3.0;
        config.initP_TrendOK     = 12.0;
        config.initP_TrendNG     = 7.0;
        config.minP_TrendOK      = 9.0;
        config.minP_TrendNG      = 4.5;
    }
    else if (StringFind(currentSymbol, "CADSEK") >= 0) {
        config.nanpinInterval = 26.0;
        config.lotAdjust      = 0.8;
        config.deviationSigma = 2.3;
        config.emaMinSlopePips = 2.1;
        config.stdDevThreshold = 0.007;  // ★★★ CADSEK用閾値 ★★★
        config.singlePositionBEP = 21.0;
        config.trailingStopPips  = 6.0;
        config.initP_TrendOK     = 28.0;
        config.initP_TrendNG     = 16.0;
        config.minP_TrendOK      = 21.0;
        config.minP_TrendNG      = 10.5;
    }
    else if (StringFind(currentSymbol, "CADSGD") >= 0) {
        config.nanpinInterval = 17.0;
        config.lotAdjust      = 1.0;
        config.deviationSigma = 2.0;
        config.emaMinSlopePips = 1.2;
        config.stdDevThreshold = 0.0010; // ★★★ CADSGD用閾値 ★★★
        config.singlePositionBEP = 13.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 17.0;
        config.initP_TrendNG     = 10.0;
        config.minP_TrendOK      = 13.0;
        config.minP_TrendNG      = 6.5;
    }
    
    // --- CHF Cross Pairs ---
    else if (StringFind(currentSymbol, "CHFSEK") >= 0) {
        config.nanpinInterval = 24.0;
        config.lotAdjust      = 0.9;
        config.deviationSigma = 2.2;
        config.emaMinSlopePips = 1.8;
        config.stdDevThreshold = 0.007;  // ★★★ CHFSEK用閾値 ★★★
        config.singlePositionBEP = 18.0;
        config.trailingStopPips  = 5.5;
        config.initP_TrendOK     = 25.0;
        config.initP_TrendNG     = 14.0;
        config.minP_TrendOK      = 18.0;
        config.minP_TrendNG      = 9.0;
    }
    else if (StringFind(currentSymbol, "CHFNOK") >= 0) {
        config.nanpinInterval = 28.0;
        config.lotAdjust      = 0.8;
        config.deviationSigma = 2.4;
        config.emaMinSlopePips = 2.2;
        config.stdDevThreshold = 0.008;  // ★★★ CHFNOK用閾値 ★★★
        config.singlePositionBEP = 22.0;
        config.trailingStopPips  = 6.5;
        config.initP_TrendOK     = 30.0;
        config.initP_TrendNG     = 18.0;
        config.minP_TrendOK      = 22.0;
        config.minP_TrendNG      = 11.0;
    }
    else if (StringFind(currentSymbol, "CHFSGD") >= 0) {
        config.nanpinInterval = 16.0;
        config.lotAdjust      = 1.0;
        config.deviationSigma = 2.0;
        config.emaMinSlopePips = 1.1;
        config.stdDevThreshold = 0.0009; // ★★★ CHFSGD用閾値 ★★★
        config.singlePositionBEP = 12.0;
        config.trailingStopPips  = 3.5;
        config.initP_TrendOK     = 16.0;
        config.initP_TrendNG     = 9.0;
        config.minP_TrendOK      = 12.0;
        config.minP_TrendNG      = 6.0;
    }
    
    //――――――――――――――――――――――――――――――――――――――――――――――――
    // クロス円（Yen Cross Pairs）
    //――――――――――――――――――――――――――――――――――――――――――――――――
    else if (StringFind(currentSymbol, "EURJPY") >= 0) {
        config.nanpinInterval = 13.0;
        config.lotAdjust      = 1.3;
        config.deviationSigma = 2.0;
        config.emaMinSlopePips = 1.8;
        config.stdDevThreshold = 0.12;   // ★★★ EURJPY用閾値 ★★★
        config.singlePositionBEP = 12.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 17.0;
        config.initP_TrendNG     = 9.0;
        config.minP_TrendOK      = 12.0;
        config.minP_TrendNG      = 6.0;
    }
    else if (StringFind(currentSymbol, "GBPJPY") >= 0) {
        config.nanpinInterval = 20.0;
        config.lotAdjust      = 1.2;
        config.deviationSigma = 2.3;
        config.emaMinSlopePips = 2.0;
        config.stdDevThreshold = 0.15;   // ★★★ GBPJPY用閾値 ★★★
        config.singlePositionBEP = 18.0;
        config.trailingStopPips  = 5.0;
        config.initP_TrendOK     = 25.0;
        config.initP_TrendNG     = 15.0;
        config.minP_TrendOK      = 18.0;
        config.minP_TrendNG      = 10.0;
    }
    else if (StringFind(currentSymbol, "AUDJPY") >= 0) {
        config.nanpinInterval = 18.0;
        config.lotAdjust      = 1.3;
        config.deviationSigma = 2.2;
        config.emaMinSlopePips = 1.7;
        config.stdDevThreshold = 0.13;   // ★★★ AUDJPY用閾値 ★★★
        config.singlePositionBEP = 14.0;
        config.trailingStopPips  = 4.5;
        config.initP_TrendOK     = 19.0;
        config.initP_TrendNG     = 11.0;
        config.minP_TrendOK      = 14.0;
        config.minP_TrendNG      = 7.0;
    }
    else if (StringFind(currentSymbol, "NZDJPY") >= 0) {
        config.nanpinInterval = 19.0;
        config.lotAdjust      = 1.4;
        config.deviationSigma = 2.3;
        config.emaMinSlopePips = 1.6;
        config.stdDevThreshold = 0.14;   // ★★★ NZDJPY用閾値 ★★★
        config.singlePositionBEP = 15.0;
        config.trailingStopPips  = 4.5;
        config.initP_TrendOK     = 20.0;
        config.initP_TrendNG     = 12.0;
        config.minP_TrendOK      = 15.0;
        config.minP_TrendNG      = 8.0;
    }
    else if (StringFind(currentSymbol, "CADJPY") >= 0) {
        config.nanpinInterval = 17.0;
        config.lotAdjust      = 1.3;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 1.4;
        config.stdDevThreshold = 0.11;   // ★★★ CADJPY用閾値 ★★★
        config.singlePositionBEP = 13.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 18.0;
        config.initP_TrendNG     = 10.0;
        config.minP_TrendOK      = 13.0;
        config.minP_TrendNG      = 6.5;
    }
    else if (StringFind(currentSymbol, "CHFJPY") >= 0) {
        config.nanpinInterval = 16.0;
        config.lotAdjust      = 1.2;
        config.deviationSigma = 2.2;
        config.emaMinSlopePips = 1.5;
        config.stdDevThreshold = 0.12;   // ★★★ CHFJPY用閾値 ★★★
        config.singlePositionBEP = 12.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 16.0;
        config.initP_TrendNG     = 9.0;
        config.minP_TrendOK      = 12.0;
        config.minP_TrendNG      = 6.0;
    }
    else if (StringFind(currentSymbol, "SEKJPY") >= 0) {
        config.nanpinInterval = 30.0;
        config.lotAdjust      = 0.8;
        config.deviationSigma = 2.5;
        config.emaMinSlopePips = 2.5;
        config.stdDevThreshold = 0.6;    // ★★★ SEKJPY用閾値 ★★★
        config.singlePositionBEP = 25.0;
        config.trailingStopPips  = 7.0;
        config.initP_TrendOK     = 35.0;
        config.initP_TrendNG     = 20.0;
        config.minP_TrendOK      = 25.0;
        config.minP_TrendNG      = 12.0;
    }
    else if (StringFind(currentSymbol, "NOKJPY") >= 0) {
        config.nanpinInterval = 35.0;
        config.lotAdjust      = 0.7;
        config.deviationSigma = 2.6;
        config.emaMinSlopePips = 3.0;
        config.stdDevThreshold = 0.8;    // ★★★ NOKJPY用閾値 ★★★
        config.singlePositionBEP = 30.0;
        config.trailingStopPips  = 8.0;
        config.initP_TrendOK     = 40.0;
        config.initP_TrendNG     = 25.0;
        config.minP_TrendOK      = 30.0;
        config.minP_TrendNG      = 15.0;
    }
    else if (StringFind(currentSymbol, "PLNJPY") >= 0) {
        config.nanpinInterval = 40.0;
        config.lotAdjust      = 0.6;
        config.deviationSigma = 2.7;
        config.emaMinSlopePips = 3.5;
        config.stdDevThreshold = 2.8;    // ★★★ PLNJPY用閾値 ★★★
        config.singlePositionBEP = 35.0;
        config.trailingStopPips  = 10.0;
        config.initP_TrendOK     = 45.0;
        config.initP_TrendNG     = 30.0;
        config.minP_TrendOK      = 35.0;
        config.minP_TrendNG      = 18.0;
    }
    else if (StringFind(currentSymbol, "HUFJPY") >= 0) {
        config.nanpinInterval = 45.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 4.0;
        config.stdDevThreshold = 0.25;   // ★★★ HUFJPY用閾値 ★★★
        config.singlePositionBEP = 40.0;
        config.trailingStopPips  = 12.0;
        config.initP_TrendOK     = 50.0;
        config.initP_TrendNG     = 35.0;
        config.minP_TrendOK      = 40.0;
        config.minP_TrendNG      = 20.0;
    }
    else if (StringFind(currentSymbol, "CZKJPY") >= 0) {
        config.nanpinInterval = 50.0;
        config.lotAdjust      = 0.4;
        config.deviationSigma = 2.9;
        config.emaMinSlopePips = 4.5;
        config.stdDevThreshold = 1.2;    // ★★★ CZKJPY用閾値 ★★★
        config.singlePositionBEP = 45.0;
        config.trailingStopPips  = 14.0;
        config.initP_TrendOK     = 55.0;
        config.initP_TrendNG     = 40.0;
        config.minP_TrendOK      = 45.0;
        config.minP_TrendNG      = 22.0;
    }
    else if (StringFind(currentSymbol, "DKKJPY") >= 0) {
        config.nanpinInterval = 25.0;
        config.lotAdjust      = 0.9;
        config.deviationSigma = 2.3;
        config.emaMinSlopePips = 2.0;
        config.stdDevThreshold = 0.45;   // ★★★ DKKJPY用閾値 ★★★
        config.singlePositionBEP = 20.0;
        config.trailingStopPips  = 6.0;
        config.initP_TrendOK     = 28.0;
        config.initP_TrendNG     = 16.0;
        config.minP_TrendOK      = 20.0;
        config.minP_TrendNG      = 10.0;
    }
    else if (StringFind(currentSymbol, "SGDJPY") >= 0) {
        config.nanpinInterval = 22.0;
        config.lotAdjust      = 1.0;
        config.deviationSigma = 2.2;
        config.emaMinSlopePips = 1.8;
        config.stdDevThreshold = 0.10;   // ★★★ SGDJPY用閾値 ★★★
        config.singlePositionBEP = 18.0;
        config.trailingStopPips  = 5.0;
        config.initP_TrendOK     = 24.0;
        config.initP_TrendNG     = 14.0;
        config.minP_TrendOK      = 18.0;
        config.minP_TrendNG      = 9.0;
    }
    else if (StringFind(currentSymbol, "HKDJPY") >= 0) {
        config.nanpinInterval = 18.0;
        config.lotAdjust      = 1.1;
        config.deviationSigma = 2.1;
        config.emaMinSlopePips = 1.5;
        config.stdDevThreshold = 0.08;   // ★★★ HKDJPY用閾値 ★★★
        config.singlePositionBEP = 15.0;
        config.trailingStopPips  = 4.5;
        config.initP_TrendOK     = 20.0;
        config.initP_TrendNG     = 12.0;
        config.minP_TrendOK      = 15.0;
        config.minP_TrendNG      = 7.5;
    }
    else if (StringFind(currentSymbol, "ZARJPY") >= 0) {
        config.nanpinInterval = 35.0;
        config.lotAdjust      = 0.6;
        config.deviationSigma = 2.7;
        config.emaMinSlopePips = 3.0;
        config.singlePositionBEP = 30.0;
        config.trailingStopPips  = 8.0;
        config.initP_TrendOK     = 40.0;
        config.initP_TrendNG     = 25.0;
        config.minP_TrendOK      = 30.0;
        config.minP_TrendNG      = 15.0;
    }
    else if (StringFind(currentSymbol, "TRYJPY") >= 0) {
        config.nanpinInterval = 40.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 3.5;
        config.singlePositionBEP = 35.0;
        config.trailingStopPips  = 10.0;
        config.initP_TrendOK     = 45.0;
        config.initP_TrendNG     = 30.0;
        config.minP_TrendOK      = 35.0;
        config.minP_TrendNG      = 18.0;
    }
    else if (StringFind(currentSymbol, "MXNJPY") >= 0) {
        config.nanpinInterval = 38.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 3.2;
        config.singlePositionBEP = 32.0;
        config.trailingStopPips  = 9.0;
        config.initP_TrendOK     = 42.0;
        config.initP_TrendNG     = 28.0;
        config.minP_TrendOK      = 32.0;
        config.minP_TrendNG      = 16.0;
    }
    
    //――――――――――――――――――――――――――――――――――――――――――――――――
    // 仮想通貨（Cryptocurrencies）
    //――――――――――――――――――――――――――――――――――――――――――――――――
    else if (StringFind(currentSymbol, "BTCUSD") >= 0) {
        config.nanpinInterval = 100.0;
        config.lotAdjust      = 0.1;
        config.deviationSigma = 3.0;
        config.emaMinSlopePips = 20.0;
        config.singlePositionBEP = 50.0;
        config.trailingStopPips  = 15.0;
        config.initP_TrendOK     = 80.0;
        config.initP_TrendNG     = 40.0;
        config.minP_TrendOK      = 50.0;
        config.minP_TrendNG      = 25.0;
    }
    else if (StringFind(currentSymbol, "ETHUSD") >= 0) {
        config.nanpinInterval = 10.0;
        config.lotAdjust      = 0.2;
        config.deviationSigma = 3.0;
        config.emaMinSlopePips = 15.0;
        config.singlePositionBEP = 30.0;
        config.trailingStopPips  = 10.0;
        config.initP_TrendOK     = 50.0;
        config.initP_TrendNG     = 25.0;
        config.minP_TrendOK      = 30.0;
        config.minP_TrendNG      = 15.0;
    }
    else if (StringFind(currentSymbol, "LTCUSD") >= 0) {
        config.nanpinInterval = 22.0;
        config.lotAdjust      = 0.3;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 12.0;
        config.singlePositionBEP = 25.0;
        config.trailingStopPips  = 8.0;
        config.initP_TrendOK     = 38.0;
        config.initP_TrendNG     = 20.0;
        config.minP_TrendOK      = 25.0;
        config.minP_TrendNG      = 12.0;
    }
    else if (StringFind(currentSymbol, "XRPUSD") >= 0) {
        config.nanpinInterval = 8.0;
        config.lotAdjust      = 0.4;
        config.deviationSigma = 2.9;
        config.emaMinSlopePips = 5.0;
        config.singlePositionBEP = 15.0;
        config.trailingStopPips  = 5.0;
        config.initP_TrendOK     = 20.0;
        config.initP_TrendNG     = 12.0;
        config.minP_TrendOK      = 15.0;
        config.minP_TrendNG      = 8.0;
    }
    else if (StringFind(currentSymbol, "ADAUSD") >= 0) {
        config.nanpinInterval = 6.0;
        config.lotAdjust      = 0.5;
        config.deviationSigma = 2.8;
        config.emaMinSlopePips = 3.0;
        config.singlePositionBEP = 12.0;
        config.trailingStopPips  = 4.0;
        config.initP_TrendOK     = 16.0;
        config.initP_TrendNG     = 10.0;
        config.minP_TrendOK      = 12.0;
        config.minP_TrendNG      = 6.0;
    }
    else if (StringFind(currentSymbol, "DOTUSD") >= 0) {
        config.nanpinInterval = 12.0;
        config.lotAdjust      = 0.3;
        config.deviationSigma = 2.9;
        config.emaMinSlopePips = 8.0;
        config.singlePositionBEP = 18.0;
        config.trailingStopPips  = 6.0;
        config.initP_TrendOK     = 24.0;
        config.initP_TrendNG     = 15.0;
        config.minP_TrendOK      = 18.0;
        config.minP_TrendNG      = 9.0;
    }


    // 設定値の妥当性チェック
    if(config.singlePositionBEP <= 0) {
        Print("⚠️ Warning: Invalid singlePositionBEP, setting to 10.0");
        config.singlePositionBEP = 10.0;
    }
    
    if(config.trailingStopPips <= 0) {
        Print("⚠️ Warning: Invalid trailingStopPips, setting to 3.0");
        config.trailingStopPips = 3.0;
    }

    // 最終設定確認ログ
    Print("📊 Currency Settings for ", currentSymbol, ":");
    Print("  SinglePositionBEP: ", config.singlePositionBEP, " pips");
    Print("  TrailingStopPips: ", config.trailingStopPips, " pips");

    return true;
}