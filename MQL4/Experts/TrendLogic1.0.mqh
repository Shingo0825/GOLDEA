//+------------------------------------------------------------------+
//|                                              TrendLogic1.0.mqh |
//|                      Copyright 2025, MetaQuotes Ltd.             |
//|                          https://www.mql5.com/ja/users/shingo0825|
//+------------------------------------------------------------------+
#property strict

#include "SuperTrendManager.mqh"
#include "EntryRestrictions.mqh"

//+------------------------------------------------------------------+
//| 設定パラメータ
//+------------------------------------------------------------------+
input group "=== Trend Display Settings ==="
input bool EnableTrendChangeAlerts = false;  // トレンド変化アラート
input bool EnableUpdateMonitor = false;      // 更新監視レポート  
input bool OptimizeForPerformance = true;    // パフォーマンス最適化

//+------------------------------------------------------------------+
//| オブジェクト名定義
//+------------------------------------------------------------------+
#define OBJ_TREND_H4  "Trend_H4"
#define OBJ_TREND_H1  "Trend_H1"
#define OBJ_TREND_M15 "Trend_M15"
#define OBJ_TREND_M5  "Trend_M5"
#define OBJ_TREND_M1  "Trend_M1"

//+------------------------------------------------------------------+
//| グローバル変数
//+------------------------------------------------------------------+
// 各時間足のトレンド状態を保持する
bool g_isH4Long, g_isH4Short;
bool g_isH1Long, g_isH1Short;
bool g_isM15Long, g_isM15Short;
bool g_isM5Long, g_isM5Short;
bool g_isM1Long, g_isM1Short;

//+------------------------------------------------------------------+
//| トレンド表示用の文字列を取得するヘルパー関数
//+------------------------------------------------------------------+
string GetTrendString(bool isLong, bool isShort)
{
    if (isLong && !isShort)  return "▲UP";   // 明確に上昇
    if (!isLong && isShort)  return "▼DOWN"; // 明確に下降
    if (isLong && isShort)   return "◆MIX";  // 混在状態（エラー状態）
    return "◇NONE";                          // トレンドなし
}

//+------------------------------------------------------------------+
//| トレンド状態を更新・取得する関数
//+------------------------------------------------------------------+
void UpdateLocalTrendState()
{
    // SuperTrendManagerから最新のトレンド状態を取得
    g_isH4Long   = IsTrend(PERIOD_H4,  TREND_UP);
    g_isH4Short  = IsTrend(PERIOD_H4,  TREND_DOWN);
    g_isH1Long   = IsTrend(PERIOD_H1,  TREND_UP);
    g_isH1Short  = IsTrend(PERIOD_H1,  TREND_DOWN);
    g_isM15Long  = IsTrend(PERIOD_M15, TREND_UP);
    g_isM15Short = IsTrend(PERIOD_M15, TREND_DOWN);
    g_isM5Long   = IsTrend(PERIOD_M5,  TREND_UP);
    g_isM5Short  = IsTrend(PERIOD_M5,  TREND_DOWN);
    g_isM1Long   = IsTrend(PERIOD_M1,  TREND_UP);
    g_isM1Short  = IsTrend(PERIOD_M1,  TREND_DOWN);
    
    // トレンド変化をチェック
    if(EnableTrendChangeAlerts) {
        CheckTrendChanges();
    }
}

//+------------------------------------------------------------------+
//| トレンド変化検出とアラート
//+------------------------------------------------------------------+
void CheckTrendChanges()
{
    static bool prevH4Long = false, prevH4Short = false;
    static bool prevH1Long = false, prevH1Short = false;
    static bool prevM15Long = false, prevM15Short = false;
    
    // H4のトレンド変化をチェック
    if((g_isH4Long != prevH4Long) || (g_isH4Short != prevH4Short)) {
        string newTrend = GetTrendString(g_isH4Long, g_isH4Short);
        Print("📈 H4 Trend Changed: ", newTrend);
        
        prevH4Long = g_isH4Long;
        prevH4Short = g_isH4Short;
    }
    
    // H1のトレンド変化をチェック
    if((g_isH1Long != prevH1Long) || (g_isH1Short != prevH1Short)) {
        string newTrend = GetTrendString(g_isH1Long, g_isH1Short);
        Print("📈 H1 Trend Changed: ", newTrend);
        
        prevH1Long = g_isH1Long;
        prevH1Short = g_isH1Short;
    }
    
    // M15のトレンド変化をチェック（重要な短期変化）
    if((g_isM15Long != prevM15Long) || (g_isM15Short != prevM15Short)) {
        string newTrend = GetTrendString(g_isM15Long, g_isM15Short);
        Print("📈 M15 Trend Changed: ", newTrend);
        
        prevM15Long = g_isM15Long;
        prevM15Short = g_isM15Short;
    }
}

//+------------------------------------------------------------------+
//| チャート上のトレンド表示を初期化
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| チャート上のトレンド表示を初期化 (位置修正版)
//+------------------------------------------------------------------+
void InitTrendDisplay()
{
    Print("🎨 Initializing Trend Display...");
    
    // 既存のオブジェクトを削除
    CleanupTrendDisplay();
    
    string labels[] = {OBJ_TREND_H4, OBJ_TREND_H1, OBJ_TREND_M15, OBJ_TREND_M5, OBJ_TREND_M1};
    string texts[]  = {"H4 : ", "H1 : ", "M15: ", "M5 : ", "M1 : "};
    
    // ★★★ 表示位置を大幅に下に移動 ★★★
    int startY = 250;  // ボタンエリアから十分離す
    int spacing = 20;  // 行間を広げる
    
    for(int i = 0; i < ArraySize(labels); i++)
    {
        if(ObjectCreate(0, labels[i], OBJ_LABEL, 0, 0, 0))
        {
            ObjectSetInteger(0, labels[i], OBJPROP_XDISTANCE, 10);
            ObjectSetInteger(0, labels[i], OBJPROP_YDISTANCE, startY + i * spacing);
            ObjectSetInteger(0, labels[i], OBJPROP_CORNER, 0);
            ObjectSetString(0, labels[i], OBJPROP_FONT, "Consolas");
            ObjectSetInteger(0, labels[i], OBJPROP_FONTSIZE, 10); // フォントサイズを少し大きく
            ObjectSetString(0, labels[i], OBJPROP_TEXT, texts[i] + "◇NONE");
            ObjectSetInteger(0, labels[i], OBJPROP_COLOR, clrSilver);
            
            Print("✅ Created trend label: ", labels[i], " at Y:", startY + i * spacing);
        }
        else
        {
            Print("❌ Failed to create trend label: ", labels[i], " Error: ", GetLastError());
        }
    }
    
    // 初期状態でトレンド情報を更新
    UpdateLocalTrendState();
    UpdateTrendDisplayNow();
    
    ChartRedraw();
    Print("✅ Trend Display initialized successfully at lower position.");
}

//+------------------------------------------------------------------+
//| OnDeinit時にトレンド表示をクリーンアップ
//+------------------------------------------------------------------+
void CleanupTrendDisplay()
{
    string labels[] = {OBJ_TREND_H4, OBJ_TREND_H1, OBJ_TREND_M15, OBJ_TREND_M5, OBJ_TREND_M1};
    
    for(int i = 0; i < ArraySize(labels); i++)
    {
        if(ObjectFind(0, labels[i]) >= 0)
        {
            ObjectDelete(0, labels[i]);
            Print("🗑️ Deleted trend label: ", labels[i]);
        }
    }
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| 単一時間足のトレンド表示更新
//+------------------------------------------------------------------+
void UpdateSingleTrendDisplay(string objName, string prefix, bool isLong, bool isShort)
{
    if(ObjectFind(0, objName) < 0) return; // オブジェクトが存在しない場合はスキップ
    
    string trendText = GetTrendString(isLong, isShort);
    string fullText = prefix + trendText;
    
    // テキストを更新
    ObjectSetString(0, objName, OBJPROP_TEXT, fullText);
    
    // 色を設定
    color textColor = clrSilver; // デフォルト
    if(isLong && !isShort) {
        textColor = clrDeepSkyBlue; // 上昇トレンド
    }
    else if(!isLong && isShort) {
        textColor = clrOrangeRed;   // 下降トレンド
    }
    else if(isLong && isShort) {
        textColor = clrYellow;      // 混在状態（要注意）
    }
    
    ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
}

//+------------------------------------------------------------------+
//| 即座に表示を更新する関数
//+------------------------------------------------------------------+
void UpdateTrendDisplayNow()
{
    // トレンド状態を最新に更新
    RefreshAllTrends(); // SuperTrendManagerの更新
    UpdateLocalTrendState(); // ローカル変数の更新

    // 表示を更新
    UpdateSingleTrendDisplay(OBJ_TREND_H4, "H4 : ", g_isH4Long, g_isH4Short);
    UpdateSingleTrendDisplay(OBJ_TREND_H1, "H1 : ", g_isH1Long, g_isH1Short);
    UpdateSingleTrendDisplay(OBJ_TREND_M15, "M15: ", g_isM15Long, g_isM15Short);
    UpdateSingleTrendDisplay(OBJ_TREND_M5, "M5 : ", g_isM5Long, g_isM5Short);
    UpdateSingleTrendDisplay(OBJ_TREND_M1, "M1 : ", g_isM1Long, g_isM1Short);
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| 新バー検出によるトレンド表示更新
//+------------------------------------------------------------------+
void UpdateTrendDisplayOnTick()
{
    static datetime lastBarTimes[5] = {0}; // M1, M5, M15, H1, H4
    bool hasNewBar = false;
    
    // 新バーが形成された時間足があるかチェック
    ENUM_TIMEFRAMES timeframes[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4};
    
    for(int i = 0; i < 5; i++) {
        datetime currentBarTime = iTime(NULL, timeframes[i], 0);
        if(currentBarTime != lastBarTimes[i]) {
            lastBarTimes[i] = currentBarTime;
            hasNewBar = true;
            
            // デバッグ：どの時間足で新バーが形成されたかログ出力
            static bool debugEnabled = false; // 必要に応じてtrueに
            if(debugEnabled) {
                string tfName = "";
                switch(timeframes[i]) {
                    case PERIOD_M1:  tfName = "M1";  break;
                    case PERIOD_M5:  tfName = "M5";  break;
                    case PERIOD_M15: tfName = "M15"; break;
                    case PERIOD_H1:  tfName = "H1";  break;
                    case PERIOD_H4:  tfName = "H4";  break;
                }
                Print("🕒 New bar formed on ", tfName, " - Updating trend display");
            }
        }
    }
    
    // 新バーが形成された場合のみ表示を更新
    if(hasNewBar) {
        UpdateTrendDisplayNow();
    }
}

//+------------------------------------------------------------------+
//| SuperTrend更新状況の監視
//+------------------------------------------------------------------+
void MonitorSuperTrendUpdates()
{
    static datetime lastMonitorTime = 0;
    
    // 5分毎に監視レポート
    if(TimeCurrent() - lastMonitorTime < 300) return;
    lastMonitorTime = TimeCurrent();
    
    Print("=== SuperTrend Update Monitor ===");
    
    ENUM_TIMEFRAMES timeframes[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4};
    string tfNames[] = {"M1", "M5", "M15", "H1", "H4"};
    
    for(int i = 0; i < 5; i++) {
        datetime currentBarTime = iTime(NULL, timeframes[i], 0);
        int minutesSinceUpdate = (int)((TimeCurrent() - currentBarTime) / 60);
        
        Print(tfNames[i], " | Current Bar: ", TimeToString(currentBarTime, TIME_MINUTES),
              " | Minutes Since: ", minutesSinceUpdate);
    }
    Print("================================");
}

//+------------------------------------------------------------------+
//| 最適化されたメイン更新関数
//+------------------------------------------------------------------+
void UpdateTrendDisplayOptimized()
{
    // パフォーマンス最適化が有効な場合、新バー時のみ更新
    if(OptimizeForPerformance) {
        UpdateTrendDisplayOnTick(); // 新バー検出方式
    } else {
        // 従来方式（1分間隔）
        static datetime lastDrawTime = 0;
        if(TimeCurrent() - lastDrawTime < 60) return;
        lastDrawTime = TimeCurrent();
        UpdateTrendDisplayNow();
    }
    
    // オプション機能
    if(EnableUpdateMonitor) {
        MonitorSuperTrendUpdates();
    }
}

//+------------------------------------------------------------------+
//| デバッグ用：SuperTrend値の直接確認
//+------------------------------------------------------------------+
void DebugSuperTrendValues()
{
    Print("=== SuperTrend Debug Values ===");
    
    ENUM_TIMEFRAMES timeframes[] = {PERIOD_H4, PERIOD_H1, PERIOD_M15, PERIOD_M5, PERIOD_M1};
    string tfNames[] = {"H4", "H1", "M15", "M5", "M1"};
    
    for(int i = 0; i < ArraySize(timeframes); i++)
    {
        ENUM_TIMEFRAMES tf = timeframes[i];
        string tfName = tfNames[i];
        
        // SuperTrendManagerから状態を取得
        bool trendUp = IsTrend(tf, TREND_UP);
        bool trendDown = IsTrend(tf, TREND_DOWN);
        
        // 直接的なインジケーター値も取得してみる
        double stLong = iCustom(NULL, tf, "SuperTrend", 10, 3.0, 0, 1);
        double stShort = iCustom(NULL, tf, "SuperTrend", 10, 3.0, 1, 1);
        double currentPrice = iClose(NULL, tf, 1);
        
        Print(tfName, " | UP:", (trendUp ? "YES" : "NO"), 
              " DOWN:", (trendDown ? "YES" : "NO"),
              " | Price:", DoubleToString(currentPrice, Digits),
              " Long:", DoubleToString(stLong, Digits),
              " Short:", DoubleToString(stShort, Digits));
    }
    Print("===============================");
}

//+------------------------------------------------------------------+
//| トレンド表示システムの状態確認
//+------------------------------------------------------------------+
void CheckTrendDisplayStatus()
{
    Print("=== Trend Display Status Check ===");
    
    string labels[] = {OBJ_TREND_H4, OBJ_TREND_H1, OBJ_TREND_M15, OBJ_TREND_M5, OBJ_TREND_M1};
    string tfNames[] = {"H4", "H1", "M15", "M5", "M1"};
    
    for(int i = 0; i < ArraySize(labels); i++)
    {
        bool exists = (ObjectFind(0, labels[i]) >= 0);
        string currentText = "";
        if(exists) {
            currentText = ObjectGetString(0, labels[i], OBJPROP_TEXT);
        }
        
        Print(tfNames[i], " Label: ", (exists ? "✅ EXISTS" : "❌ MISSING"),
              exists ? (" | Text: " + currentText) : "");
    }
    
    Print("================================");
}

//+------------------------------------------------------------------+
//| Trading Allowed コメントを制御する修正版
//+------------------------------------------------------------------+
void ManageEntryRestrictionsComment()
{
    static datetime lastCommentTime = 0;
    static bool showComment = true;
    
    // ★★★ 10秒毎にコメント表示/非表示を切り替え ★★★
    if(TimeCurrent() - lastCommentTime >= 10) {
        lastCommentTime = TimeCurrent();
        
        if(showComment) {
            bool tradingAllowed = IsTradingAllowedNow();
            string status = tradingAllowed ? "O Trading Allowed" : "x Trading Restricted";
            
            // ★★★ 位置を指定してコメント表示 ★★★
            string commentText = StringConcatenate(
                "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",  // 改行で下に押し下げ
                "Entry Status: ", status, "\n",
                "", TimeToString(TimeCurrent(), TIME_SECONDS)
            );
            Comment(commentText);
            
            showComment = false; // 次回は非表示
        } else {
            Comment(""); // コメントクリア
            showComment = true;  // 次回は表示
        }
    }
}