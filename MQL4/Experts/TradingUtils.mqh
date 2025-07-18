//+------------------------------------------------------------------+
//|                                                 TradingUtils.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//|                                            TradingUtils.mqh       |
//|                        汎用ユーティリティ関数パッケージ             |
//|                        価格変換・ポジション情報・時間関数を統合     |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 価格・pips変換関数群
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| 価格 -> Pips 変換 & 逆変換  ---- GOLD 対応版                      |
//+------------------------------------------------------------------+
double Utils_PipsToPrice(double pips_value, string symbol = NULL)
{
   string sym           = (symbol == NULL) ? Symbol() : symbol;
   int    digits        = (int)MarketInfo(sym, MODE_DIGITS);
   double point_size    = MarketInfo(sym, MODE_POINT);
   double contract_size = MarketInfo(sym, MODE_LOTSIZE);

   // --- 金属 CFD 判定
   bool is_metal_cfd = (contract_size <= 100 &&
                        MarketInfo(sym, MODE_BID) > 100 &&
                        digits <= 3);

   // ---- 金属 CFD（Gold／Silver 等）は 1 pip = 0.10 (=10points)
   if(is_metal_cfd)
   {
      const int  METAL_POINTS_PER_PIP = 10;          // ←★ 固定
      return pips_value * METAL_POINTS_PER_PIP * point_size;
   }

   // ---- 通貨ペア
   int points_per_pip = (digits == 3 || digits == 5) ? 10 : 1;
   return pips_value * points_per_pip * point_size;
}

double Utils_PriceToPips(double price_value, string symbol = NULL)
{
   string sym           = (symbol == NULL) ? Symbol() : symbol;
   int    digits        = (int)MarketInfo(sym, MODE_DIGITS);
   double point_size    = MarketInfo(sym, MODE_POINT);
   double contract_size = MarketInfo(sym, MODE_LOTSIZE);

   if(point_size == 0) return 0;

   bool is_metal_cfd = (contract_size <= 100 &&
                        MarketInfo(sym, MODE_BID) > 100 &&
                        digits <= 3);

   if(is_metal_cfd)
   {
      const int METAL_POINTS_PER_PIP = 10;
      return price_value / (METAL_POINTS_PER_PIP * point_size);
   }

   int points_per_pip = (digits == 3 || digits == 5) ? 10 : 1;
   return price_value / (points_per_pip * point_size);
}

//+------------------------------------------------------------------+
//| 指定通貨ペアでのpips換算
//+------------------------------------------------------------------+
double Utils_PriceToPipsWithSymbol(double value, string symbol)
{
    int Symbol_Digits = (int)MarketInfo(symbol, MODE_DIGITS);
    double pointSize = (double)MarketInfo(symbol, MODE_POINT);
    
    if (Symbol_Digits == 2) {
        return value / 0.1; // 小数点2桁の通貨ペアは 1.0 ドル = 10 pips
    }
    
    int mult = (Symbol_Digits == 3 || Symbol_Digits == 5) ? 10 : 1;
    return value / pointSize / (double)mult;
}

//+------------------------------------------------------------------+
//| ポイント換算用関数
//+------------------------------------------------------------------+
double Utils_PointToPrice(int value)
{
    return (double)(value * Point);
}

//+------------------------------------------------------------------+
//| ポジション情報取得関数群
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ロット数取得関数
//+------------------------------------------------------------------+
double Utils_GetOpenLots(int magic, int type = -1)
{
    double lots = 0;

    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS) == false) return(-1);
        if(OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;

        if(type == -1 || OrderType() == type) lots += OrderLots();
    }

    return(lots);
}

//+------------------------------------------------------------------+
//| ポジション数取得関数 (★最終修正版)
//+------------------------------------------------------------------+
int Utils_GetOpenPositions(int magic, int type = -1)
{
    int positions = 0;

    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS) == false) continue;
        
        // ★★★ 修正箇所：通貨ペア(Symbol)でのフィルタリングを追加 ★★★
        if(OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;

        if(type == -1 || OrderType() == type) positions++;
    }

    return(positions);
}
//+------------------------------------------------------------------+
//| 最終エントリーしたバー数取得処理
//+------------------------------------------------------------------+
int Utils_GetBars(int magic)
{
    datetime open_time = 0, close_time = 0, time;
    int barsCount = Bars, i;

    for(i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS) == false) continue;
        if(OrderMagicNumber() != magic || OrderSymbol() != Symbol()) continue;

        if(open_time < OrderOpenTime()) {
            open_time = OrderOpenTime();
        }
    }

    for(i = OrdersHistoryTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) continue;
        if(OrderMagicNumber() != magic || OrderSymbol() != Symbol()) continue;

        if(close_time < OrderOpenTime()) {
            close_time = OrderOpenTime();
        }
    }

    if(close_time == 0 && open_time == 0) return(0);

    time = (close_time > open_time) ? close_time : open_time;

    for(i = 0; i < Bars; i++) {
        if(time < Time[i]) {
            barsCount = Bars - i;
        }
        else {
            break;
        }
    }

    return(barsCount);
}

//+------------------------------------------------------------------+
//| エントリー制限時間を確認する関数
//+------------------------------------------------------------------+
bool Utils_EntryLimitBySeconds(int seconds, int magic)
{
    int i;
    for(i = OrdersHistoryTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) continue;
        if(OrderMagicNumber() != magic || OrderSymbol() != Symbol()) continue;

        if(OrderType() == OP_BUY || OrderType() == OP_SELL) {
            if(OrderCloseTime() + seconds >= TimeCurrent()) return(true);
        }
    }
    return(false);
}

//+------------------------------------------------------------------+
//| マジックナンバー比較用関数（パラメータ名修正）
//+------------------------------------------------------------------+
bool Utils_CheckMagicNumbers(string& magics[], int OrderMagic, int& magic_numbers_array[])
{
    for(int i = ArraySize(magics) - 1; i >= 0; i--) {
        if(OrderMagic == magic_numbers_array[StrToInteger(magics[i])-1]) return (true);
    }
    return (false);
}

//+------------------------------------------------------------------+
//| 時間・日付関連ユーティリティ
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 時間帯チェック関数
//+------------------------------------------------------------------+
bool Utils_IsTimeInRange(datetime currentTime, int startHour, int startMinute, int endHour, int endMinute)
{
    int currentHour = TimeHour(currentTime);
    int currentMinute = TimeMinute(currentTime);
    int currentTimeMinutes = currentHour * 60 + currentMinute;
    
    int startTimeMinutes = startHour * 60 + startMinute;
    int endTimeMinutes = endHour * 60 + endMinute;
    
    // 日をまたぐ場合の処理
    if(startTimeMinutes > endTimeMinutes) {
        return (currentTimeMinutes >= startTimeMinutes || currentTimeMinutes < endTimeMinutes);
    } else {
        return (currentTimeMinutes >= startTimeMinutes && currentTimeMinutes < endTimeMinutes);
    }
}

//+------------------------------------------------------------------+
//| 営業日判定
//+------------------------------------------------------------------+
bool Utils_IsBusinessDay(datetime checkTime)
{
    int dayOfWeek = TimeDayOfWeek(checkTime);
    return (dayOfWeek >= 1 && dayOfWeek <= 5); // 月曜〜金曜
}

//+------------------------------------------------------------------+
//| 週末判定
//+------------------------------------------------------------------+
bool Utils_IsWeekend(datetime checkTime)
{
    int dayOfWeek = TimeDayOfWeek(checkTime);
    return (dayOfWeek == 0 || dayOfWeek == 6); // 土曜・日曜
}

//+------------------------------------------------------------------+
//| 文字列操作ユーティリティ
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 数値を文字列に変換（小数点以下指定）
//+------------------------------------------------------------------+
string Utils_DoubleToString(double value, int digits = 2)
{
    return DoubleToString(value, digits);
}

//+------------------------------------------------------------------+
//| 整数を文字列に変換
//+------------------------------------------------------------------+
string Utils_IntegerToString(int value)
{
    return IntegerToString(value);
}

//+------------------------------------------------------------------+
//| パーセント表示用文字列変換
//+------------------------------------------------------------------+
string Utils_ToPercentString(double value, int digits = 1)
{
    return DoubleToString(value, digits) + "%";
}

//+------------------------------------------------------------------+
//| 金額表示用文字列変換
//+------------------------------------------------------------------+
string Utils_ToCurrencyString(double value, int digits = 2)
{
    return "$" + DoubleToString(value, digits);
}

//+------------------------------------------------------------------+
//| 計算ユーティリティ
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 平均値計算
//+------------------------------------------------------------------+
double Utils_CalculateAverage(double &values[], int count = -1)
{
    int arraySize = ArraySize(values);
    if(arraySize == 0) return 0;
    
    int calcCount = (count == -1) ? arraySize : MathMin(count, arraySize);
    double sum = 0;
    
    for(int i = 0; i < calcCount; i++) {
        sum += values[i];
    }
    
    return sum / calcCount;
}

//+------------------------------------------------------------------+
//| 最大値取得
//+------------------------------------------------------------------+
double Utils_GetMaxValue(double &values[], int count = -1)
{
    int arraySize = ArraySize(values);
    if(arraySize == 0) return 0;
    
    int calcCount = (count == -1) ? arraySize : MathMin(count, arraySize);
    double maxVal = values[0];
    
    for(int i = 1; i < calcCount; i++) {
        if(values[i] > maxVal) maxVal = values[i];
    }
    
    return maxVal;
}

//+------------------------------------------------------------------+
//| 最小値取得
//+------------------------------------------------------------------+
double Utils_GetMinValue(double &values[], int count = -1)
{
    int arraySize = ArraySize(values);
    if(arraySize == 0) return 0;
    
    int calcCount = (count == -1) ? arraySize : MathMin(count, arraySize);
    double minVal = values[0];
    
    for(int i = 1; i < calcCount; i++) {
        if(values[i] < minVal) minVal = values[i];
    }
    
    return minVal;
}

//+------------------------------------------------------------------+
//| パーセンテージ計算
//+------------------------------------------------------------------+
double Utils_CalculatePercentage(double part, double whole)
{
    if(whole == 0) return 0;
    return (part / whole) * 100.0;
}

//+------------------------------------------------------------------+
//| 範囲内値クリッピング
//+------------------------------------------------------------------+
double Utils_ClampValue(double value, double minVal, double maxVal)
{
    return MathMax(minVal, MathMin(value, maxVal));
}

//+------------------------------------------------------------------+
//| ログ・デバッグ用ユーティリティ
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| フォーマット済みログ出力
//+------------------------------------------------------------------+
void Utils_LogInfo(string message, string prefix = "INFO")
{
    Print("[", prefix, "] ", TimeToString(TimeCurrent(), TIME_SECONDS), " - ", message);
}

//+------------------------------------------------------------------+
//| エラーログ出力
//+------------------------------------------------------------------+
void Utils_LogError(string message, int errorCode = -1)
{
    string logMsg = "[ERROR] " + TimeToString(TimeCurrent(), TIME_SECONDS) + " - " + message;
    if(errorCode >= 0) {
        logMsg += " (Error Code: " + IntegerToString(errorCode) + ")";
    }
    Print(logMsg);
}

//+------------------------------------------------------------------+
//| 警告ログ出力
//+------------------------------------------------------------------+
void Utils_LogWarning(string message)
{
    Print("[WARNING] ", TimeToString(TimeCurrent(), TIME_SECONDS), " - ", message);
}

//+------------------------------------------------------------------+
//| デバッグログ出力（開発時のみ）
//+------------------------------------------------------------------+
void Utils_LogDebug(string message, bool enableDebug = false)
{
    if(enableDebug) {
        Print("[DEBUG] ", TimeToString(TimeCurrent(), TIME_SECONDS), " - ", message);
    }
}

//+------------------------------------------------------------------+
//| 市場情報ユーティリティ
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| スプレッド取得（pips単位）
//+------------------------------------------------------------------+
double Utils_GetSpreadInPips()
{
    double spread = Ask - Bid;
    return Utils_PriceToPips(spread);
}

//+------------------------------------------------------------------+
//| 現在の価格情報を文字列で取得
//+------------------------------------------------------------------+
string Utils_GetPriceInfo()
{
    return StringConcatenate(
        "Bid: ", DoubleToString(Bid, Digits),
        " / Ask: ", DoubleToString(Ask, Digits),
        " / Spread: ", DoubleToString(Utils_GetSpreadInPips(), 1), " pips"
    );
}

//+------------------------------------------------------------------+
//| ボラティリティ計算（簡易版）
//+------------------------------------------------------------------+
double Utils_CalculateVolatility(int period = 20)
{
    double sum = 0;
    for(int i = 1; i <= period; i++) {
        double range = High[i] - Low[i];
        sum += range;
    }
    return sum / period;
}

//+------------------------------------------------------------------+
//| ユーティリティ初期化
//+------------------------------------------------------------------+
void InitTradingUtils()
{
    Utils_LogInfo("Trading Utils initialized successfully", "UTILS");
}

//+------------------------------------------------------------------+
//| デバッグ情報表示
//+------------------------------------------------------------------+
void Utils_PrintSystemInfo()
{
    Print("=== Trading Utils System Info ===");
    Print("Symbol: ", Symbol());
    Print("Digits: ", Digits);
    Print("Point: ", Point);
    Print("Spread: ", DoubleToString(Utils_GetSpreadInPips(), 1), " pips");
    Print("Server Time: ", TimeToString(TimeCurrent(), TIME_SECONDS));
    Print("Current Volatility (20): ", DoubleToString(Utils_CalculateVolatility(20), Digits));
    Print("Min Lot: ", MarketInfo(Symbol(), MODE_MINLOT));
    Print("Max Lot: ", MarketInfo(Symbol(), MODE_MAXLOT));
    Print("Lot Step: ", MarketInfo(Symbol(), MODE_LOTSTEP));
}

// TradingUtils.mqh の一番下などに追加

//+------------------------------------------------------------------+
//| ポジション開設関数 (★引数名を修正)
//+------------------------------------------------------------------+
bool Utils_OpenPosition(int signal, double lots, double tp_pips, double sl_pips, int magic, string order_comment = "") { // ★★★ 引数名を "comment" から "order_comment" に変更 ★★★
    int type = 0, ticket = 0;
    double price = 0, sl = 0, tp = 0;
    
    switch(signal) {
        case 1:
            type = OP_BUY;
            price = Ask;
            if(tp_pips > 0) tp = Ask + Utils_PipsToPrice(tp_pips);
            if(sl_pips > 0) sl = Ask - Utils_PipsToPrice(sl_pips);
            break;
        case -1:
            type = OP_SELL;
            price = Bid;
            if(tp_pips > 0) tp = Bid - Utils_PipsToPrice(tp_pips);
            if(sl_pips > 0) sl = Bid + Utils_PipsToPrice(sl_pips);
            break;
        default:
            return false;
    }
    
    for(int i = 0; i < 3; i++) {
        if(IsTradeAllowed()) {
            RefreshRates();
            // ★★★ OrderSendで使う変数名も変更 ★★★
            ticket = OrderSend(Symbol(), type, lots, price, 10, sl, tp, order_comment, magic, 0, (type==OP_BUY?clrBlue:clrRed));

            if(GetLastError() == 0) return true;
            Sleep(200);
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| 分割エントリー関数 (汎用化のためここに移動)
//+------------------------------------------------------------------+
bool Utils_OpenSplitPositions(int signal, double lots, double tp_pips, double sl_pips, int magic) {
    bool result = true;
    double max_lot_per_order = 50.0; // 例：最大ロット
    
    while (lots > 0) {
        double lotSizeToOpen = MathMin(lots, max_lot_per_order);
        if (!Utils_OpenPosition(signal, lotSizeToOpen, tp_pips, sl_pips, magic)) {
            result = false;
        }
        lots -= lotSizeToOpen;
    }
    return result;
}

// TradingUtils.mqh の一番下などに追加

//+------------------------------------------------------------------+
//| ポジション決済関数 (汎用化のためここに移動)
//+------------------------------------------------------------------+
bool Utils_ClosePosition(int magic, int type = -1) {
    bool allClosedSuccessfully = true;

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) continue;

        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (type == -1 || OrderType() == type) {
                bool closed = false;
                for (int retry = 0; retry < 3; retry++) {
                    RefreshRates();
                    if (OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 10)) { // Slippageを直接記述
                        closed = true;
                        break;
                    }
                    Sleep(200);
                }
                if (!closed) {
                    Print("[Utils_ClosePosition Error]: Failed to close order. Ticket=", OrderTicket(), " Error:", GetLastError());
                    allClosedSuccessfully = false;
                }
            }
        }
    }
    return allClosedSuccessfully;
}

//+------------------------------------------------------------------+
//| 方向別全決済関数 (汎用化のためここに移動)
//+------------------------------------------------------------------+
void Utils_CloseAllByDirection(int dir) {
    RefreshRates();
    int needType = (dir > 0) ? OP_BUY : OP_SELL;
    double closePrice = (dir > 0) ? Bid : Ask;

    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderType() == needType) {
            if(!OrderClose(OrderTicket(), OrderLots(), closePrice, 10)) // Slippageを直接記述
                Print("[Utils_CloseAllByDirection Error]: Close error:", GetLastError());
        }
    }
}