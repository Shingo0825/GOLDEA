//+------------------------------------------------------------------+
//|                                        EntryRestrictions.mqh |
//|                                Copyright 2025, MetaQuotes Ltd. |
//|                                              https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

#include "NanpinManager.mqh"

//+------------------------------------------------------------------+
//|                     改善版EntryRestrictions.mqh                  |
//|                 エントリー制限機能パッケージ（最終FIX版）        |
//|                 正確な市場時間・営業日ベース制限を実装           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 入力パラメータ群
//+------------------------------------------------------------------+

// === ブローカーの時間設定（最重要） ===
input group "=== Broker Time Settings (IMPORTANT!) ===";
input int  Broker_GMTOffset_Winter = 2; // ブローカーのサーバー時間（冬時間）のGMTオフセット
input int  Broker_GMTOffset_Summer = 3; // ブローカーのサーバー時間（夏時間）のGMTオフセット
enum enum_DST_Scheme {
    USA,    // アメリカ式 (3月第2日曜〜11月第1日曜)
    Europe  // ヨーロッパ式 (3月最終日曜〜10月最終日曜)
};
input enum_DST_Scheme DST_Scheme = USA; // 採用する夏時間ルール

// === 経済指標制限設定 ===
input group "=== Economic Events Settings ==="
input bool   enableEconomicEvents = true;           // 経済指標カレンダーのON/OFF
input string EconomicEvents_FileName = "economic_events.csv"; // 経済指標ファイル名
input bool   EnableS_RankFilter = true;             // Sランクの指標停止を有効にする
input bool   EnableA_RankFilter = false;            // Aランクの指標停止を有効にする
input bool   EnableB_RankFilter = false;            // Bランクの指標停止を有効にする
input bool   EnableC_RankFilter = false;            // Cランクの指標停止を有効にする
input int    EventCheckInterval = 3600;             // 経済指標チェックの間隔（秒）

// === 市場時間制限設定 ===
input group "=== Market Hours Settings ==="
input bool EnableMarketSessionFilter = true;        // 市場セッション制限を有効にする
input bool StopDuringMarketOpen = true;             // 主要市場開始時の1時間停止
input bool StopDuringMarketClose = true;            // 主要市場終了時の1時間停止
input int  London_Open_GMT = 8;                     // ロンドン市場開始時間(GMT)
input int  NY_Open_GMT = 13;                        // NY市場開始時間(GMT)
input bool EnableWeekendFilter = true;              // 週末制限を有効にする

// === カスタム時間制限設定 ===
input group "=== Custom Time Restriction Settings ==="
input bool EnableCustomTimeFilter = false;          // カスタム時間帯制限のON/OFF
input int CustomStopStartHour = 0;                  // カスタム停止開始時間（時）
input int CustomStopStartMinute = 0;                // カスタム停止開始時間（分）
input int CustomStopEndHour = 5;                    // カスタム停止終了時間（時）
input int CustomStopEndMinute = 0;                  // カスタム停止終了時間（分）

// === 月末・月初制限設定 ===
input group "=== Month End/Start Settings ==="
input bool EnableMonthEndFilter = false;            // 月末制限を有効にする
input bool EnableMonthStartFilter = false;          // 月初制限を有効にする
input int MonthEndStopDays = 1;                     // 月末何日前から停止するか
input int MonthStartStopDays = 1;                   // 月初何日間停止するか


//+------------------------------------------------------------------+
//| 経済指標データ構造体
//+------------------------------------------------------------------+
struct EconomicEvent {
    datetime time;
    int rank;
    string event;
};

// ★★★★★ 補助的な関数群を、呼び出し元より前に定義するため、ここに移動 ★★★★★

//+------------------------------------------------------------------+
//| 月の日数を取得する関数
//+------------------------------------------------------------------+
int TimeDaysInMonth(datetime time)
{
    int year = TimeYear(time);
    int month = TimeMonth(time);

    if (month == 2) {
        bool leapYear = ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0));
        return (leapYear ? 29 : 28);
    }

    if (month == 4 || month == 6 || month == 9 || month == 11)
        return 30;

    return 31;
}

//+------------------------------------------------------------------+
//| 営業日判定
//+------------------------------------------------------------------+
bool IsBusinessDay(datetime checkTime)
{
    return (TimeDayOfWeek(checkTime) >= 1 && TimeDayOfWeek(checkTime) <= 5); // 月曜〜金曜
}

//+------------------------------------------------------------------+
//| 月末営業日を取得
//+------------------------------------------------------------------+
int GetLastBusinessDayOfMonth(datetime currentTime)
{
    int year = TimeYear(currentTime);
    int month = TimeMonth(currentTime);
    int daysInMonth = TimeDaysInMonth(currentTime);
    
    for(int day = daysInMonth; day >= 1; day--) {
        datetime checkDate = StringToTime(IntegerToString(year) + "." + 
                                          IntegerToString(month) + "." + 
                                          IntegerToString(day) + " 12:00");
        if(IsBusinessDay(checkDate)) {
            return day;
        }
    }
    return daysInMonth;
}

//+------------------------------------------------------------------+
//| 月初営業日を取得
//+------------------------------------------------------------------+
int GetFirstBusinessDayOfMonth(datetime currentTime)
{
    int year = TimeYear(currentTime);
    int month = TimeMonth(currentTime);
    
    for(int day = 1; day <= 7; day++) {
        datetime checkDate = StringToTime(IntegerToString(year) + "." + 
                                          IntegerToString(month) + "." + 
                                          IntegerToString(day) + " 12:00");
        if(IsBusinessDay(checkDate)) {
            return day;
        }
    }
    return 1;
}

// ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
// ★★★          これより下の関数は元の順序のまま             ★★★
// ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★


// グローバル変数
EconomicEvent economicEvents[];
datetime lastEventCheckTime = 0;
bool economicEventsLoadError = false;

//+------------------------------------------------------------------+
//| 夏時間判定関数
//+------------------------------------------------------------------+
bool IsDaylightSavingTime(datetime currentTime) 
{
    int year = TimeYear(currentTime);
    
    if (DST_Scheme == Europe) {
        datetime dstStart = StringToTime(IntegerToString(year) + ".03.31 01:00");
        dstStart -= (datetime)((TimeDayOfWeek(dstStart) - 0) % 7 * 24 * 60 * 60);

        datetime dstEnd = StringToTime(IntegerToString(year) + ".10.31 01:00");
        dstEnd -= (datetime)((TimeDayOfWeek(dstEnd) - 0) % 7 * 24 * 60 * 60);

        return (currentTime >= dstStart && currentTime < dstEnd);
    }
    else {
        datetime dstStart = StringToTime(IntegerToString(year) + ".03.08 02:00");
        dstStart += (datetime)((7 - TimeDayOfWeek(dstStart)) % 7 * 24 * 60 * 60);

        datetime dstEnd = StringToTime(IntegerToString(year) + ".11.01 02:00");
        dstEnd += (datetime)((7 - TimeDayOfWeek(dstEnd)) % 7 * 24 * 60 * 60);
        
        return (currentTime >= dstStart && currentTime < dstEnd);
    }
}

//+------------------------------------------------------------------+
//| サーバー時間からGMTオフセットを自動検出
//+------------------------------------------------------------------+
int GetServerGMTOffset()
{
    if(IsDaylightSavingTime(TimeGMT())) {
        return Broker_GMTOffset_Summer;
    } else {
        return Broker_GMTOffset_Winter;
    }
}

//+------------------------------------------------------------------+
//| 市場セッション情報を取得（現在は未使用だが将来の拡張用に残置）
//+------------------------------------------------------------------+
struct MarketSession {
    int openHour;
    int openMinute;
    int closeHour;
    int closeMinute;
    string name;
};
MarketSession GetMarketSessions()
{
    MarketSession sessions;
    bool isDST = IsDaylightSavingTime(TimeGMT());
    
    if(isDST) {
        sessions.openHour = 1;
        sessions.closeHour = 1;
    } else {
        sessions.openHour = 0;
        sessions.closeHour = 0;
    }
    sessions.openMinute = 0;
    sessions.closeMinute = 0;
    sessions.name = "Global FX Market";
    return sessions;
}


//+------------------------------------------------------------------+
//| 経済イベント関連関数
//+------------------------------------------------------------------+
void LoadEconomicEvents() 
{
    string filePath = EconomicEvents_FileName;
    int handle = FileOpen(filePath, FILE_READ | FILE_CSV);
    
    if (handle < 0) {
        int error = GetLastError();
        Print("❌ Failed to open economic events CSV file: ", filePath, " Error Code: ", error);
        Print("❌ Expected Location: ", TerminalInfoString(TERMINAL_DATA_PATH), "\\MQL4\\Files\\", filePath);
        economicEventsLoadError = true;
        return;
    }

    Print("📂 Loading economic events from: ", filePath);
    FileReadString(handle); // ヘッダー行を読み飛ばす

    int loadedCount = 0;
    while (!FileIsEnding(handle)) {
        string line = FileReadString(handle);
        if(line == "") continue;
        
        string fields[];
        StringSplit(line, ',', fields);
        
        if (ArraySize(fields) < 4) {
            Print("⚠️ Invalid CSV format in line: ", line);
            continue;
        }

        datetime eventTime = StringToTime(fields[1] + " " + fields[2]);
        if(eventTime == 0) {
            Print("⚠️ Invalid date/time format: ", fields[1], " ", fields[2]);
            continue;
        }
        
        int eventRank = 0;
        if (StringFind(fields[3], "S") >= 0) eventRank = 12;
        else if (StringFind(fields[3], "A") >= 0) eventRank = 6;
        else if (StringFind(fields[3], "B") >= 0) eventRank = 3;
        else if (StringFind(fields[3], "C") >= 0) eventRank = 1;

        bool isEventEnabled = (eventRank == 12 && EnableS_RankFilter) ||
                              (eventRank == 6  && EnableA_RankFilter) ||
                              (eventRank == 3  && EnableB_RankFilter) ||
                              (eventRank == 1  && EnableC_RankFilter);

        if (eventRank > 0 && isEventEnabled) {
            ArrayResize(economicEvents, ArraySize(economicEvents) + 1);
            int last_idx = ArraySize(economicEvents) - 1;
            economicEvents[last_idx].time = eventTime;
            economicEvents[last_idx].rank = eventRank;
            economicEvents[last_idx].event = fields[0];
            loadedCount++;
        }
    }

    FileClose(handle);
    economicEventsLoadError = false;
    Print("✅ Successfully loaded ", loadedCount, " economic events from CSV");
}

void SortEconomicEvents() 
{
    int size = ArraySize(economicEvents);
    for (int i = 0; i < size - 1; i++) {
        for (int j = 0; j < size - i - 1; j++) {
            if (economicEvents[j].time > economicEvents[j + 1].time) {
                EconomicEvent temp = economicEvents[j];
                economicEvents[j] = economicEvents[j + 1];
                economicEvents[j + 1] = temp;
            }
        }
    }
}

bool CheckEconomicEventsOptimized() 
{
    if (!enableEconomicEvents) return false;
    if (economicEventsLoadError) return false;

    if (TimeCurrent() - lastEventCheckTime >= EventCheckInterval || lastEventCheckTime == 0) 
    {
       lastEventCheckTime = TimeCurrent();

       datetime now = TimeCurrent();
       for(int i = 0; i < ArraySize(economicEvents); i++) {
           datetime eventTime = economicEvents[i].time;
           
           if (now > eventTime + 24 * 3600) continue; 

           int eventRank = economicEvents[i].rank;
           string eventText = economicEvents[i].event;
           
           int impactHoursBefore = (eventRank == 12) ? 12 : (eventRank == 6) ? 6 : (eventRank == 3) ? 3 : 1;
           int impactHoursAfter = (eventRank == 12) ? 24 : (eventRank == 6) ? 6 : (eventRank == 3) ? 3 : 1;
           
           datetime startTime = eventTime - (impactHoursBefore * 3600);
           datetime endTime = eventTime + (impactHoursAfter * 3600);

           if (now >= startTime && now <= endTime) {
               string rankStr = (eventRank==12?"S":eventRank==6?"A":eventRank==3?"B":"C");
               Comment("🚨 Economic Event Active 🚨\n",
                       "📌 Rank: ", rankStr, "\n",
                       "📌 Event: ", eventText, "\n", 
                       "📌 End Time: ", TimeToString(endTime));
               return true;
           }
       }
    }
    return false;
}

bool IsCustomTimeRestricted()
{
    if(!EnableCustomTimeFilter) return false;
    
    datetime now = TimeCurrent();
    int currentHour = TimeHour(now);
    int currentMinute = TimeMinute(now);
    int currentTimeInMinutes = currentHour * 60 + currentMinute;
    
    int startTimeInMinutes = CustomStopStartHour * 60 + CustomStopStartMinute;
    int endTimeInMinutes = CustomStopEndHour * 60 + CustomStopEndMinute;
    
    if(startTimeInMinutes > endTimeInMinutes) { 
        return (currentTimeInMinutes >= startTimeInMinutes || currentTimeInMinutes < endTimeInMinutes);
    } else {
        return (currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes < endTimeInMinutes);
    }
}

bool IsMarketSessionRestricted()
{
    if(!EnableMarketSessionFilter) return false;
    
    datetime now = TimeCurrent();
    int dayOfWeek = TimeDayOfWeek(now);
    int hour = TimeHour(now);
    int serverOffset = GetServerGMTOffset();

    if(EnableWeekendFilter) {
        int marketOpenHour_Server = (0 + serverOffset) % 24; 
        int marketCloseHour_Server = (22 + serverOffset) % 24;

        if (dayOfWeek == 6 || dayOfWeek == 0) { // 土日
            Comment("🚫 Weekend - Market Closed");
            return true;
        }
        if (dayOfWeek == 1 && hour < marketOpenHour_Server) { // 月曜開始前
            Comment("⏰ Monday Market Opening Soon");
            return true;
        }
        if (dayOfWeek == 5 && hour >= marketCloseHour_Server) { // 金曜終了後
            Comment("🌙 Friday Market Closing");
            return true;
        }
    }
    
    if(StopDuringMarketOpen) {
        int londonOpen_Server = (London_Open_GMT + serverOffset) % 24;
        int nyOpen_Server = (NY_Open_GMT + serverOffset) % 24;
        
        if(hour == londonOpen_Server || hour == nyOpen_Server) {
            Comment("🚀 Major Market Opening Hour - Entry Restricted");
            return true;
        }
    }
    return false;
}

bool IsMonthEndStartRestricted()
{
    datetime now = TimeCurrent();
    int currentDay = TimeDay(now);
    
    if(EnableMonthEndFilter) {
        int lastBusinessDay = GetLastBusinessDayOfMonth(now);
        if (currentDay >= lastBusinessDay - (MonthEndStopDays - 1) && currentDay <= lastBusinessDay) {
           if (IsBusinessDay(now)) {
              Comment("📅 Month End Restriction (Last Business Day: ", lastBusinessDay, ")");
              return true;
           }
        }
    }
    
    if(EnableMonthStartFilter) {
        int firstBusinessDay = GetFirstBusinessDayOfMonth(now);
        if(currentDay >= firstBusinessDay && currentDay < (firstBusinessDay + MonthStartStopDays)) {
           if(IsBusinessDay(now)) {
              Comment("📅 Month Start Restriction (First Business Day: ", firstBusinessDay, ")");
              return true;
           }
        }
    }
    return false;
}

void DisplayEconomicEventsStatus() 
{
    if (!enableEconomicEvents) return;
    
    if (economicEventsLoadError) {
        Comment("❌ Economic Events CSV Error\nCheck MQL4\\Files\\ folder");
        return;
    }
}

//+------------------------------------------------------------------+
//| 統合エントリー制限チェック関数
//+------------------------------------------------------------------+
bool IsTradingAllowedNow() 
{
    if (CheckEconomicEventsOptimized()) {
        return false;
    }
    if (IsMarketSessionRestricted()) {
        return false;
    }
    if (IsCustomTimeRestricted()) {
        // Comment("🕐 Custom Time Restriction Active"); // ← コメント削除
        return false;
    }
    if (IsMonthEndStartRestricted()) {
        return false;
    }
    
    // ★★★ ここでのComment()呼び出しを削除 ★★★
    // Comment("✅ Trading Allowed"); // ← この行を削除またはコメントアウト
    
    return true;
}

//+------------------------------------------------------------------+
//| 初期化関数
//+------------------------------------------------------------------+
void InitEntryRestrictions()
{
    Print("🚀 Initializing Improved Entry Restrictions...");
    
    if (enableEconomicEvents) {
        LoadEconomicEvents();
        SortEconomicEvents();
    }
    
    int serverOffset = GetServerGMTOffset();
    bool isDST = IsDaylightSavingTime(TimeGMT());
    Print("🌍 Server GMT Offset: +", serverOffset, " (DST Scheme: ", EnumToString(DST_Scheme), ", DST Active: ", (isDST ? "ON" : "OFF"), ")");
    
    Print("📊 Economic Events: ", (enableEconomicEvents ? "ON" : "OFF"));
    Print("🕐 Custom Time Filter: ", (EnableCustomTimeFilter ? "ON" : "OFF"));
    Print("🏛️ Market Session Filter: ", (EnableMarketSessionFilter ? "ON" : "OFF"));
    Print("📅 Month End Filter: ", (EnableMonthEndFilter ? "ON" : "OFF"));
    Print("📅 Month Start Filter: ", (EnableMonthStartFilter ? "ON" : "OFF"));
    
    Print("✅ Improved Entry Restrictions initialized successfully.");
}

//+------------------------------------------------------------------+
//| デバッグ情報表示
//+------------------------------------------------------------------+
void PrintEntryRestrictionsStatus()
{
    Print("=== Improved Entry Restrictions Status ===");
    Print("Current Server Time: ", TimeToString(TimeCurrent(), TIME_SECONDS));
    Print("Server GMT Offset: +", GetServerGMTOffset());
    Print("Daylight Saving Time: ", (IsDaylightSavingTime(TimeGMT()) ? "YES" : "NO"));
    Print("Day of Week: ", TimeDayOfWeek(TimeCurrent()));
    Print("");
    Print("Economic Events: ", (enableEconomicEvents ? "ON" : "OFF"));
    Print("Economic Events CSV: ", (economicEventsLoadError ? "ERROR ❌" : "OK ✅"));
    Print("Loaded Events Count: ", ArraySize(economicEvents));
    Print("Market Session Filter: ", (EnableMarketSessionFilter ? "ON" : "OFF"));
    Print("Custom Time Filter: ", (EnableCustomTimeFilter ? "ON" : "OFF"));
    Print("Month End Filter: ", (EnableMonthEndFilter ? "ON" : "OFF"));
    Print("Month Start Filter: ", (EnableMonthStartFilter ? "ON" : "OFF"));
    Print("");
    // Comment関数はチャート左上にしか表示されないため、Print文に変更
    if(IsTradingAllowedNow()) {
        Print("Current Trading Status: ALLOWED ✅");
    } else {
        Print("Current Trading Status: RESTRICTED ❌");
    }
}