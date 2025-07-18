//+------------------------------------------------------------------+
//|                                          SuperTrendManager.mqh |
//|                      Copyright 2025, MetaQuotes Ltd.             |
//|                          https://www.mql5.com/ja/users/shingo0825|
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//| 列挙型定義
//+------------------------------------------------------------------+
// トレンド方向
enum ENUM_TREND_DIRECTION {
    TREND_UP,   // 上昇トレンド
    TREND_DOWN, // 下降トレンド
    TREND_NONE  // トレンドなし
};

// SuperTrendのキャッシュ配列のインデックスを管理するための専用列挙型
enum ENUM_ST_CACHE_INDEX {
    ST_CACHE_M1,
    ST_CACHE_M5,
    ST_CACHE_M15,
    ST_CACHE_H1,
    ST_CACHE_H4,
    ST_CACHE_TOTAL // 配列のサイズを示す
};

//+------------------------------------------------------------------+
//| 構造体定義
//+------------------------------------------------------------------+
struct SuperTrendCache {
    double      long_value;
    double      short_value;
    datetime    last_update_bar;
    ENUM_TREND_DIRECTION trend;
};

//+------------------------------------------------------------------+
//| グローバル変数
//+------------------------------------------------------------------+
SuperTrendCache g_st_caches[ST_CACHE_TOTAL];

// 外部インジケーターの設定
input string InpSuperTrendIndicator = "SuperTrend";
input int    InpSuperTrendPeriod    = 10;
input double InpSuperTrendMultiplier= 3.0;

//+------------------------------------------------------------------+
//| ENUM_TIMEFRAMESをキャッシュのインデックスに変換するヘルパー関数
//+------------------------------------------------------------------+
int TimeframeToIndex(ENUM_TIMEFRAMES a_timeframe) {
    switch(a_timeframe) {
        case PERIOD_M1:  return ST_CACHE_M1;
        case PERIOD_M5:  return ST_CACHE_M5;
        case PERIOD_M15: return ST_CACHE_M15;
        case PERIOD_H1:  return ST_CACHE_H1;
        case PERIOD_H4:  return ST_CACHE_H4;
        default:         return -1; // 対応しない時間足
    }
}

//+------------------------------------------------------------------+
//| SuperTrendのキャッシュを更新する内部関数
//+------------------------------------------------------------------+
void UpdateSuperTrendCache(ENUM_TIMEFRAMES a_timeframe) {
    int cache_index = TimeframeToIndex(a_timeframe);
    if (cache_index == -1) return; // 対応しない時間足はスキップ

    datetime current_bar_time = iTime(NULL, a_timeframe, 0);

    if (current_bar_time == g_st_caches[cache_index].last_update_bar) {
        return; // 同じバーなので更新不要
    }

    g_st_caches[cache_index].last_update_bar = current_bar_time;

    g_st_caches[cache_index].long_value  = iCustom(NULL, a_timeframe, InpSuperTrendIndicator, InpSuperTrendPeriod, InpSuperTrendMultiplier, 0, 1);
    g_st_caches[cache_index].short_value = iCustom(NULL, a_timeframe, InpSuperTrendIndicator, InpSuperTrendPeriod, InpSuperTrendMultiplier, 1, 1);

    double current_price = iClose(NULL, a_timeframe, 1);
    
    if (g_st_caches[cache_index].long_value > 0 && current_price > g_st_caches[cache_index].long_value) {
        g_st_caches[cache_index].trend = TREND_UP;
    }
    else if (g_st_caches[cache_index].short_value > 0 && current_price < g_st_caches[cache_index].short_value) {
        g_st_caches[cache_index].trend = TREND_DOWN;
    }
    else {
        g_st_caches[cache_index].trend = TREND_NONE;
    }
}

//+------------------------------------------------------------------+
//| OnTickから呼び出すメインの更新関数
//+------------------------------------------------------------------+
void RefreshAllTrends() {
    UpdateSuperTrendCache(PERIOD_M1);
    UpdateSuperTrendCache(PERIOD_M5);
    UpdateSuperTrendCache(PERIOD_M15);
    UpdateSuperTrendCache(PERIOD_H1);
    UpdateSuperTrendCache(PERIOD_H4);
}

//+------------------------------------------------------------------+
//| 外部からトレンド状態を取得するための公開インターフェース関数
//+------------------------------------------------------------------+
bool IsTrend(ENUM_TIMEFRAMES a_timeframe, ENUM_TREND_DIRECTION direction) {
    int cache_index = TimeframeToIndex(a_timeframe);
    if (cache_index == -1) return false;

    return (g_st_caches[cache_index].trend == direction);
}

//+------------------------------------------------------------------+
//| SuperTrendマネージャーの初期化関数
//+------------------------------------------------------------------+
void InitializeSuperTrendManager() {
    // forループで構造体配列を初期化
    for(int i = 0; i < ST_CACHE_TOTAL; i++) {
        g_st_caches[i].long_value      = 0;
        g_st_caches[i].short_value     = 0;
        g_st_caches[i].last_update_bar = 0;
        g_st_caches[i].trend           = TREND_NONE;
    }

    Print("✅ SuperTrend Manager Initialized.");
    // 起動時に全時間足のキャッシュを強制的に初回更新
    RefreshAllTrends();
}