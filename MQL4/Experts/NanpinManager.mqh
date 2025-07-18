//+------------------------------------------------------------------+
//|                   NanpinManager.mqh  (2025-06-25 完全統合版)      |
//|                   ナンピン機能の完全統合管理システム                |
//+------------------------------------------------------------------+
#property strict
#include "TradingUtils.mqh"
#include "CommonStructs.mqh"
#include "CurrencyConfig.mqh"
#include "SuperTrendManager.mqh"
//#include "EntryLogics.mqh"



//------------------------------------------------------------------
// 1. Inputs
//------------------------------------------------------------------
input group "=== Nanpin Settings ==="
input bool   isNanpin              = true;
input int    NanpinCount           = 100;
input double NanpinTP              = 0;
input double NanpinSL              = 0;
input int    CoolTime              = 300;
input double NanpinMult            = 1.5;
input double k                     = 400.0;

input group "=== Nanpin Control Settings ==="
input bool   EnableSingleDirectionNanpin = false;
input int    UnconditionalNanpinCount    = 0;
input double StdDevNanpinThreshold       = 1.5;



input group "=== Trailing Stop Settings ==="
input bool   EnableTrailingStop = true;                 // トレーリングストップのON/OFF
input double trailingStopPips = 3.0;                    // 標準のトレール幅

#define MAX_MAGIC_INDEX 50          // マジック最大インデックス

double g_rsiPrev[MAX_MAGIC_INDEX];
bool   g_rsiArmed[MAX_MAGIC_INDEX];

double g_stochPrev[MAX_MAGIC_INDEX];
bool   g_stochArmBuy [MAX_MAGIC_INDEX];
bool   g_stochArmSell[MAX_MAGIC_INDEX];

//------------------------------------------------------------------
// 2. グローバル変数
//------------------------------------------------------------------
struct NanpinState {
   double previousBuyPrice, previousSellPrice;
   double previousBuyLots , previousSellLots ;
   double initialBuyPrice , initialSellPrice ;
   datetime lastNanpinTime;
};
NanpinState nanpinStates[50];

double   g_currentNanpinInterval = 20.0;
datetime g_lastIntervalUpdate    = 0;

struct NanpinInfo {
   int    type;
   double entry_price, breakEvenPrice;
   int    count;
   double total;
   double lots;
};

// ★★★ 本体EAから移植する強制ナンピンフラグ ★★★
bool g_forceNanpinBuy  = false;
bool g_forceNanpinSell = false;

//------------------------------------------------------------------
// 3. 基本ヘルパー関数
//------------------------------------------------------------------
double Nanpin_GetOpenLots(int magic,int type=-1)
{
   double lots = 0;
   for(int i=OrdersTotal()-1;i>=0;i--)
      if(OrderSelect(i,SELECT_BY_POS) &&
         OrderSymbol()==Symbol() &&
         OrderMagicNumber()==magic &&
        (type==-1 || OrderType()==type))
            lots += OrderLots();
   return lots;
}

//+------------------------------------------------------------------+
//| マジックインデックス取得ヘルパー関数（NanpinManagerから）
//+------------------------------------------------------------------+
int GetMagicIndex(int magic)
{
   int base = magic - g_magicOffset;
   if(base>=1 && base<=20) return base-1;
   if(base==0)   return 20;
   if(base==901) return 21;
   if(base==902) return 22;
   return -1;
}

//------------------------------------------------------------------
// 4. 初期化
//------------------------------------------------------------------
//------------------------------------------------------------------
// 4. 初期化  ― InitNanpinManager()
//------------------------------------------------------------------
void InitNanpinManager()
{
   /*────────────────────────────────────────────
     ① ナンピン状態バッファ (NanpinState[]) をリセット
   ────────────────────────────────────────────*/
   for(int i = 0; i < ArraySize(nanpinStates); i++)
       ZeroMemory(nanpinStates[i]);

   /*────────────────────────────────────────────
     ② インジケータ用「armed / prev」配列を
        毎セッション初期化  ― 再ログイン時の
        フラグ壊れ対策
   ────────────────────────────────────────────*/
   ArrayFill(g_rsiPrev,      0, MAX_MAGIC_INDEX, 50.0);   // RSI 前回値
   ArrayFill(g_rsiArmed,     0, MAX_MAGIC_INDEX, true);   // RSI トリガー可否

   ArrayFill(g_stochPrev,    0, MAX_MAGIC_INDEX, 50.0);   // Stoch 前回値
   ArrayFill(g_stochArmBuy,  0, MAX_MAGIC_INDEX, true);   // Stoch BUY 側
   ArrayFill(g_stochArmSell, 0, MAX_MAGIC_INDEX, true);   // Stoch SELL 側

   /*────────────────────────────────────────────
     ③ 初期ナンピン間隔を決定
        - 固定間隔なら FixedNanpinInterval
        - 可変の場合は g_symbolNanpinInterval
          （本体EAから渡されるシグマ別初期値）
   ────────────────────────────────────────────*/
g_currentNanpinInterval = g_symbolNanpinInterval;


}


//------------------------------------------------------------------
// 5. 間隔計算
//------------------------------------------------------------------
double MathClamp(double v,double mn,double mx){return MathMax(mn,MathMin(v,mx));}


void UpdateNanpinInterval(double stdDev)
{
   // 通貨ペア別設定を使用するため、ボラティリティによる調整は不要
   // g_currentNanpinInterval は InitNanpinManager() で設定済み
   return;
}



void GetNanpinInfo(int magic, NanpinInfo &info_out)
{
    /*--------------------------------------
      0. 初期化
    --------------------------------------*/
    info_out.type           = -1;
    info_out.entry_price    = 0;
    info_out.breakEvenPrice = 0;
    info_out.count          = 0;
    info_out.total          = 0;
    info_out.lots           = 0;

    /*--------------------------------------
      1. ポジション走査と時系列データ収集
    --------------------------------------*/
    double totalLots      = 0.0;
    double weightedSum    = 0.0;
    
    // ★★★ 時系列順を保持するための構造体 ★★★
    struct OrderData {
        datetime time;
        double price;
        double lots;
    };
    OrderData orders[];
    int orderCount = 0;

    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(!OrderSelect(i, SELECT_BY_POS))              continue;
        if(OrderSymbol()       != Symbol())             continue;
        if(OrderMagicNumber()  != magic)                continue;

        /*--- 初回で売買方向(type)を確定 ----------------*/
        if(info_out.type == -1)
            info_out.type = OrderType();

        /*--- 異なる方向のポジションは無視 --------------*/
        if(OrderType() != info_out.type)                continue;

        /*--- 注文データを配列に格納 ----------------------------*/
        ArrayResize(orders, orderCount + 1);
        orders[orderCount].time = OrderOpenTime();
        orders[orderCount].price = OrderOpenPrice();
        orders[orderCount].lots = OrderLots();
        orderCount++;

        /*--- 加重平均計算用 ----------------------------*/
        totalLots   += OrderLots();
        weightedSum += OrderLots() * OrderOpenPrice();
    }

    /*--------------------------------------
      2. 結果セット
    --------------------------------------*/
    if(orderCount == 0) return;   // ポジション無し

    /*--- 時系列順にソート（古い順） ----------------------------*/
    for(int i = 0; i < orderCount - 1; i++) {
        for(int j = i + 1; j < orderCount; j++) {
            if(orders[i].time > orders[j].time) {
                OrderData temp = orders[i];
                orders[i] = orders[j];
                orders[j] = temp;
            }
        }
    }

    /*--- ★★★ 最初のエントリー価格を使用 ★★★ ----------------------------*/
    info_out.entry_price    = orders[0].price;  // 時系列で最も古い = 最初のエントリー
    info_out.lots           = totalLots;
    info_out.breakEvenPrice = (totalLots > 0) ? (weightedSum / totalLots) : 0.0;
    info_out.count          = orderCount;  // ★★★ 修正：-1を削除して実際のポジション数に ★★★

    /*--------------------------------------
      3. バスケット全体の平均ピプス損益を算出
    --------------------------------------*/
    double priceDiff = 0.0;

    if(info_out.type == OP_BUY)
        priceDiff = Bid - info_out.breakEvenPrice;
    else if(info_out.type == OP_SELL)
        priceDiff = info_out.breakEvenPrice - Ask;

    info_out.total = Utils_PriceToPips(priceDiff);

    /*--------------------------------------
      4. ★★★ デバッグ出力（修正確認用） ★★★
    --------------------------------------*/
    Print("📊 [GetNanpinInfo] Magic:", magic, " Type:", (info_out.type==OP_BUY?"BUY":"SELL"));
    Print("   Position count: ", orderCount, " → info.count: ", info_out.count);
    Print("   Entry price: ", DoubleToString(info_out.entry_price, Digits));
    Print("   Total lots: ", DoubleToString(info_out.lots, 2));
    Print("   Break-even: ", DoubleToString(info_out.breakEvenPrice, Digits));
    Print("   P&L: ", DoubleToString(info_out.total, 1), " pips");
}


// 修正版：CalculateNanpinLots
double CalculateNanpinLots(int magic,
                           int orderType,
                           int count,
                           double curPrice,
                           double baseLots)
{
    Print("🔧 [DEBUG] CalculateNanpinLots START (v2)");
    Print("   Magic: ", magic, " | Type: ", (orderType==OP_BUY?"BUY":"SELL"), " | Count: ", count);

    /* ① マジック index 取得 */
    int idx = GetMagicIndex(magic);
    if(idx < 0) {
        Print("❌ Invalid magic index for magic ", magic);
        return baseLots;
    }

    NanpinState st = nanpinStates[idx];
    int nanpinIndex = count - 1; // 1→0, 2→1...

    /* ② ★★★【最重要修正】常に最新のポジションから前回ロットを取得 ★★★ */
    double prevLots = 0.0;
    datetime latestTime = 0;

    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(!OrderSelect(i, SELECT_BY_POS) || OrderSymbol() != Symbol() || OrderMagicNumber() != magic || OrderType() != orderType) continue;

        if(OrderOpenTime() > latestTime) {
            latestTime = OrderOpenTime();
            prevLots = OrderLots();
        }
    }

    // ポジションが見つからない場合（＝最初のナンピン）、baseLotsを前回ロットとする
    if(prevLots == 0.0) {
        Print("   No previous position found, using baseLots.");
        prevLots = baseLots;
    }
    Print("   Previous lots (from actual position): ", DoubleToString(prevLots, 2));


    /* ③ 直前ポジとの価格差 (pips) を計算 */
    double diffPips = 0.0;
    double previousPrice = (orderType == OP_BUY) ? st.previousBuyPrice : st.previousSellPrice;
    if(previousPrice > 0) {
        diffPips = Utils_PriceToPips(MathAbs(curPrice - previousPrice));
    }
    diffPips = MathMin(diffPips, 300); // キャップ
    Print("   Price difference: ", DoubleToString(diffPips, 1), " pips");


    /* ④ ロット倍率計算 */
    double mult;
    if(nanpinIndex <= 8) {
        mult = 1.7 - ((1.7 - 1.4) / 8) * nanpinIndex;
        if(k != 0.0 && diffPips > 0) {
            mult *= MathExp(diffPips / k);
        }
    } else {
        mult = 1.4;
    }
    Print("   Multiplier: ", DoubleToString(mult, 3));


    /* ⑤ 新しいロット計算 */
    double newLots = prevLots * mult;
    Print("   Calculation: ", DoubleToString(prevLots, 2), " * ", DoubleToString(mult, 3), " = ", DoubleToString(newLots, 3));

    /* ⑥ ブローカー仕様に丸めて返す */
    double minLot = MarketInfo(Symbol(), MODE_MINLOT);
    double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    double adjustedLots = MathRound(newLots / lotStep) * lotStep;
    double finalLots = NormalizeDouble(MathMax(minLot, MathMin(maxLot, adjustedLots)), 2);
    
    Print("   Final lots: ", DoubleToString(finalLots, 2));
    Print("🔧 [DEBUG] CalculateNanpinLots END");
    Print("");

    return finalLots;
}


//------------------------------------------------------------------
// 8. ナンピン状態管理
//------------------------------------------------------------------
void UpdateNanpinState(int magic, int orderType, double price, double lots)
{
    int magicIndex = GetMagicIndex(magic);
    if(magicIndex < 0) {
        Print("❌ UpdateNanpinState: Invalid magic index for magic ", magic);
        return;
    }
    
    NanpinState state_temp = nanpinStates[magicIndex];
    
    if(orderType == OP_BUY) {
        state_temp.previousBuyPrice = price;
        state_temp.previousBuyLots = lots;  // ★★★ 実際に発注したロットを記録 ★★★
        if(state_temp.initialBuyPrice == 0) state_temp.initialBuyPrice = price;
        Print("✅ Updated BUY state: Price=", DoubleToString(price, Digits), " Lots=", DoubleToString(lots, 2));
    } else if(orderType == OP_SELL) {
        state_temp.previousSellPrice = price;
        state_temp.previousSellLots = lots;  // ★★★ 実際に発注したロットを記録 ★★★
        if(state_temp.initialSellPrice == 0) state_temp.initialSellPrice = price;
        Print("✅ Updated SELL state: Price=", DoubleToString(price, Digits), " Lots=", DoubleToString(lots, 2));
    }
    
    state_temp.lastNanpinTime = TimeCurrent();
    nanpinStates[magicIndex] = state_temp;
}

void ResetNanpinState(int magic)
{
    int magicIndex = GetMagicIndex(magic);
    if(magicIndex < 0) return;
    
    NanpinState state_temp;
    state_temp.previousBuyPrice = 0;
    state_temp.previousSellPrice = 0;
    state_temp.previousBuyLots = 0;
    state_temp.previousSellLots = 0;
    state_temp.initialBuyPrice = 0;
    state_temp.initialSellPrice = 0;
    state_temp.lastNanpinTime = 0;
    
    nanpinStates[magicIndex] = state_temp;
}

bool IsNanpinCoolTime(int magic)
{
    int magicIndex = GetMagicIndex(magic);
    if(magicIndex < 0) return false;
    
    return (TimeCurrent() - nanpinStates[magicIndex].lastNanpinTime < CoolTime);
}

//------------------------------------------------------------------
// 9. ナンピン条件チェック（RSI + ストキャスティクス）- 修正版
//------------------------------------------------------------------
bool CheckNanpinCondition(int orderType, int magic, int count)
{
    // M1 RSIの現在値を取得
    double rsi1m_current = iRSI(NULL, PERIOD_M1, 14, PRICE_CLOSE, 0);

    // magicナンバーから配列インデックスを取得
    int magicIndex = GetMagicIndex(magic);
    if(magicIndex < 0) return false;

    // --- RSI条件判定 ---
    bool okRSI = false;
    
    if(orderType == OP_BUY) {
        // グローバル変数 g_rsiArmed と g_rsiPrev を使用
        if(g_rsiArmed[magicIndex] && g_rsiPrev[magicIndex] < 20.0 && rsi1m_current >= 20.0) {
            okRSI = true;
            g_rsiArmed[magicIndex] = false; // 一度トリガーしたら再武装まで待つ
        }
        // RSIが40を超えたら、次のシグナルのために再武装
        if(rsi1m_current > 40.0) g_rsiArmed[magicIndex] = true;
    }
    else if(orderType == OP_SELL) {
        // グローバル変数 g_rsiArmed と g_rsiPrev を使用
        if(g_rsiArmed[magicIndex] && g_rsiPrev[magicIndex] > 80.0 && rsi1m_current <= 80.0) {
            okRSI = true;
            g_rsiArmed[magicIndex] = false; // 一度トリガーしたら再武装まで待つ
        }
        // RSIが60を下回ったら、次のシグナルのために再武装
        if(rsi1m_current < 60.0) g_rsiArmed[magicIndex] = true;
    }
    
    // RSIの今回値をグローバル変数に保存
    g_rsiPrev[magicIndex] = rsi1m_current;
    
    // --- ストキャスティクス条件判定 ---
    // M5 Stochasticsの%Dライン現在値を取得
    double stochD_current = iStochastic(NULL, PERIOD_M5, 14, 1, 3, MODE_SMA, 0, MODE_MAIN, 0);

    bool okStoch = false;
    
    if(orderType == OP_BUY) {
        // グローバル変数 g_stochArmBuy と g_stochPrev を使用
        if(g_stochArmBuy[magicIndex] && g_stochPrev[magicIndex] < 20.0 && stochD_current >= 20.0) {
            okStoch = true;
            g_stochArmBuy[magicIndex] = false; // トリガー後は再武装まで待つ
        }
        // %Dが40を超えたら、次のBUYシグナルのために再武装
        if(stochD_current > 40.0) g_stochArmBuy[magicIndex] = true;
    }
    else if(orderType == OP_SELL) {
        // グローバル変数 g_stochArmSell と g_stochPrev を使用
        if(g_stochArmSell[magicIndex] && g_stochPrev[magicIndex] > 80.0 && stochD_current <= 80.0) {
            okStoch = true;
            g_stochArmSell[magicIndex] = false; // トリガー後は再武装まで待つ
        }
        // %Dが60を下回ったら、次のSELLシグナルのために再武装
        if(stochD_current < 60.0) g_stochArmSell[magicIndex] = true;
    }
    
    // Stochasticsの今回値をグローバル変数に保存
    g_stochPrev[magicIndex] = stochD_current;
    
    // --- その他の条件判定 ---
    // M1 50期間の終値の標準偏差を取得
    double stdDev30 = iStdDev(NULL, PERIOD_M1, 50, 0, MODE_SMA, PRICE_CLOSE, 1);
    
    // 低ボラティリティ相場ではインジケーター条件を無視
    
    bool allowLowVol = (stdDev30 <= g_stdDevThreshold);
    
    // 指定回数までは無条件でナンピンを許可
    bool allowUnconditional = (UnconditionalNanpinCount > 0) && (count < UnconditionalNanpinCount);
    
    // 最終的な条件を返す
    // (RSIがOK または StochがOK) または 低ボラ時 または 無条件期間中
    return (okRSI || okStoch) || allowLowVol || allowUnconditional;
}

//------------------------------------------------------------------
// 10. 同一方向ナンピン制御チェック
//------------------------------------------------------------------
bool CheckSingleDirectionNanpin(int orderType, int magic, int &magicArrayRef[], int arraySize)
{
    if(!EnableSingleDirectionNanpin) return true;

    int activeBuyMagic = -1;
    int activeSellMagic = -1;

    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(!OrderSelect(i, SELECT_BY_POS) || OrderSymbol() != Symbol()) continue;
        
        bool isManagedMagic = false;
        int currentOrderMagic = OrderMagicNumber();
        for(int j = 0; j < arraySize; j++) {
            if(magicArrayRef[j] == currentOrderMagic) {
                isManagedMagic = true;
                break;
            }
        }
        
        if(!isManagedMagic) continue;
        
        if(OrderType() == OP_BUY && activeBuyMagic == -1)
        {
            activeBuyMagic = currentOrderMagic;
        }
        else if(OrderType() == OP_SELL && activeSellMagic == -1)
        {
            activeSellMagic = currentOrderMagic;
        }

        if(activeBuyMagic != -1 && activeSellMagic != -1)
        {
            break;
        }
    }

    if(orderType == OP_BUY)
    {
        return (activeSellMagic == -1) && (activeBuyMagic == -1 || activeBuyMagic == magic);
    }
    else if(orderType == OP_SELL)
    {
        return (activeBuyMagic == -1) && (activeSellMagic == -1 || activeSellMagic == magic);
    }

    return false;
}

//+------------------------------------------------------------------+
//| 11. ManageNanpinTrailingStop() (SuperTrendManager対応版)
//+------------------------------------------------------------------+
void ManageNanpinTrailingStop(int magic, double tpips)
{
    NanpinInfo info;
    GetNanpinInfo(magic, info);
    if(info.lots <= 0) return;

    double cur   = (info.type == OP_BUY) ? Bid : Ask;
    
    // ★★★ extern変数を直接使用（CommonStructsから自動で利用可能） ★★★
    double step  = Utils_PipsToPrice(g_trailingStopPips);
    double newSL = (info.type == OP_BUY) ? cur - step : cur + step;

    bool trendOK = false;
    if (info.type == OP_BUY) {
        trendOK = IsTrend(PERIOD_M15, TREND_UP);
    } else {
        trendOK = IsTrend(PERIOD_M15, TREND_DOWN);
    }
    
    // ★★★ CommonStructsで定義したextern変数を使用 ★★★
    double initP = trendOK ? g_initP_TrendOK : g_initP_TrendNG;
    double minP  = trendOK ? g_minP_TrendOK  : g_minP_TrendNG;
    
   double bepP = (info.count <= 1) ? g_singlePositionBEP
               : MathMax(initP - (info.count - 1) * 0.5, minP);
    double bepGap = Utils_PipsToPrice(bepP);

    /* ④ まだ BEP から十分離れていなければトレールしない */
    if((info.type == OP_BUY  && Bid < info.breakEvenPrice + bepGap) ||
       (info.type == OP_SELL && Ask > info.breakEvenPrice - bepGap))
        return;

    /* ⑤ 各ポジションに対して SL 更新 */
    for(int pos = OrdersTotal() - 1; pos >= 0; pos--)
    {
        if(!OrderSelect(pos, SELECT_BY_POS)) continue;
        if(OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;

        bool needUpdate = false;
        if(info.type == OP_BUY)
        {
            if((OrderStopLoss() == 0 || newSL > OrderStopLoss() + 0.5 * Point) &&
               newSL > info.breakEvenPrice + 0.5 * Point)
                needUpdate = true;
        }
        else // OP_SELL
        {
            if((OrderStopLoss() == 0 || newSL < OrderStopLoss() - 0.5 * Point) &&
               newSL < info.breakEvenPrice - 0.5 * Point)
                needUpdate = true;
        }

        if(needUpdate &&
           !OrderModify(OrderTicket(),
                        OrderOpenPrice(),
                        newSL,
                        OrderTakeProfit(),
                        0,
                        clrNONE))
        {
            Print("[TrailingError] Magic:", magic,
                  " Ticket:", OrderTicket(),
                  " Error:", GetLastError());
        }
    }
}


//------------------------------------------------------------------
// 12. バスケット決済チェック
//------------------------------------------------------------------
bool CheckBasketClose(int magic, double tpPips, double slPips)
{
    if(tpPips == 0 && slPips == 0) return false;
    
    NanpinInfo info;
    GetNanpinInfo(magic, info);
    
    if(info.lots <= 0) return false;
    
    bool shouldClose = false;
    string reason = "";
    
    if(tpPips != 0 && info.total > tpPips) {
        shouldClose = true;
        reason = "Take Profit: +" + DoubleToString(info.total, 1) + "pips";
    }
    
    if(slPips != 0 && info.total * -1 > slPips) {
        shouldClose = true;
        reason = "Stop Loss: " + DoubleToString(info.total, 1) + "pips";
    }
    
    if(shouldClose) {
        Print("🎯 BASKET CLOSE: Magic", magic, " ", (info.type == OP_BUY ? "BUY" : "SELL"), 
              " | ", reason, " | Count:", info.count);
        return true;
    }
    
    return false;
}

//------------------------------------------------------------------
// 13. ★★★ 強制ナンピン関数（UIManagerから移植） ★★★
//------------------------------------------------------------------
void SetForceNanpinBuy(bool flag) { g_forceNanpinBuy = flag; }
void SetForceNanpinSell(bool flag) { g_forceNanpinSell = flag; }

bool GetAndResetForceNanpinBuy()
{
    bool result = g_forceNanpinBuy;
    g_forceNanpinBuy = false;
    return result;
}

bool GetAndResetForceNanpinSell()
{
    bool result = g_forceNanpinSell;
    g_forceNanpinSell = false;
    return result;
}

// NanpinManager.mqh に配置してください

//+------------------------------------------------------------------+
//| 14. ★★★ メインナンピンロジック実行（本体EAから移植・改良版） ★★★
//+------------------------------------------------------------------+
// 修正版
bool ExecuteNanpinLogic(int magic, double baseLots, double baseInterval, int &magicArrayRef[], int arraySize)
{
    if(!isNanpin) return false;
    
    if(IsNanpinCoolTime(magic)) return false;
    
    NanpinInfo info;
    GetNanpinInfo(magic, info);
    
    if(info.lots <= 0) return false;
    if(info.count >= NanpinCount) return false;

    // ★★★ 追加：NanpinStateから「直前のポジション価格」を取得 ★★★
    int magicIndex = GetMagicIndex(magic);
    if(magicIndex < 0) return false;
    NanpinState state = nanpinStates[magicIndex];
    double previousPrice = (info.type == OP_BUY) ? state.previousBuyPrice : state.previousSellPrice;
    
    // 直前の価格が取得できない場合は、意図しない動作を防ぐために処理を中断
    if (previousPrice == 0) {
        Print("Error: Could not retrieve previous position price for Magic ", magic);
        return false;
    }

    double interval = g_currentNanpinInterval;
    double intervalPrice = Utils_PipsToPrice(interval);
    
    bool priceCondition = false;
    // ★★★★★★★【最重要修正ポイント】★★★★★★★
    // 基準を info.entry_price (初回価格) から previousPrice (直前価格) に変更
    if(info.type == OP_BUY && Ask <= previousPrice - intervalPrice) priceCondition = true;
    if(info.type == OP_SELL && Bid >= previousPrice + intervalPrice) priceCondition = true;
    
    if(!priceCondition) return false;
    
    // 以降の条件チェックは変更なし
    if(!CheckNanpinCondition(info.type, magic, info.count)) return false;
    if(!CheckSingleDirectionNanpin(info.type, magic, magicArrayRef, arraySize)) return false;
    
    return true;
}

//------------------------------------------------------------------
// 15. ★★★ 統合ナンピン実行関数（本体EAから完全移植）- 修正版 ★★★
//------------------------------------------------------------------
void ExecuteNanpinForAllMagics(int &magicArray[], int magic_count, double baseLots)
{
    // 強制ナンピンチェック（最優先）
    bool forceBuy = GetAndResetForceNanpinBuy();
    bool forceSell = GetAndResetForceNanpinSell();
    
    if(forceBuy || forceSell) {
        Print("🚀 Force Nanpin Triggered: ", (forceBuy ? "BUY" : "SELL"));
        
        int targetType = forceBuy ? OP_BUY : OP_SELL;
        
        // 強制ナンピンの場合は、最初にポジションを持つマジックに対して実行
        for(int idx = 0; idx < magic_count; idx++) {
            int magic = magicArray[idx];
            NanpinInfo info;
            GetNanpinInfo(magic, info);
            
            // ポジションがあり、かつ強制方向と一致する場合
            if(info.lots > 0 && info.type == targetType) {
                double currentPrice = (info.type == OP_BUY) ? Ask : Bid;
                double newLots = CalculateNanpinLots(magic, info.type, info.count, currentPrice, baseLots);
                
                // 注文が成功した場合のみ状態を更新
                if(Utils_OpenSplitPositions((targetType == OP_BUY) ? 1 : -1, newLots, 0, 0, magic)) {
                    UpdateNanpinState(magic, targetType, (targetType == OP_BUY) ? Ask : Bid, newLots);
                    Print("🚀 FORCE NANPIN EXECUTED: Magic", magic, " ", (targetType == OP_BUY ? "BUY" : "SELL"));
                } else {
                    Print("❌ FAILED TO EXECUTE FORCE NANPIN: Magic ", magic, " Error: ", GetLastError());
                }
                break; // 1つのマジックに対して実行したらループを抜ける
            }
        }
        return; // 強制ナンピンを実行したら通常の処理は行わない
    }
    
    // 通常のナンピン処理
    for(int idx = 0; idx < magic_count; idx++) {
        int magic = magicArray[idx];
        
        if(Utils_GetOpenLots(magic) <= 0) continue;
        
        if(ExecuteNanpinLogic(magic, baseLots, g_currentNanpinInterval, magicArray, magic_count)) {
            NanpinInfo info;
            GetNanpinInfo(magic, info);
            
            if(info.lots > 0) {
                double currentPrice = (info.type == OP_BUY) ? Ask : Bid;
                
                // ★★★ 重要：正しいロット計算 ★★★
                double newLots = CalculateNanpinLots(magic, info.type, info.count, currentPrice, baseLots);
                
                // ★★★ 注文成功時のみ状態更新 ★★★
                if(Utils_OpenSplitPositions((info.type == OP_BUY) ? 1 : -1, newLots, 0, 0, magic)) {
                    // 注文成功後に状態を更新
                    UpdateNanpinState(magic, info.type, currentPrice, newLots);
                    
                    string direction = (info.type == OP_BUY) ? "BUY" : "SELL";
                    Print("🚀 NANPIN SUCCESS: Magic", magic, " ", direction, 
                          " | Price:", DoubleToString(currentPrice, Digits), 
                          " | Lots:", DoubleToString(newLots, 2), 
                          " | Count:", info.count + 1);
                } else {
                    Print("❌ NANPIN FAILED: Magic", magic, " | Lots:", DoubleToString(newLots, 2));
                }
            }
        }
        
        // 利確・損切り処理（ポジションがある場合のみ実行）
        if(Utils_GetOpenLots(magic) > 0) {
            // トレーリングストップ
            if(EnableTrailingStop) {
                ManageNanpinTrailingStop(magic, trailingStopPips);
            }
            
            // バスケット決済
            if(CheckBasketClose(magic, NanpinTP, NanpinSL)) {
                if(Utils_ClosePosition(magic)) {
                    ResetNanpinState(magic);
                    Print("🎯 BASKET CLOSED: Magic", magic);
                }
            }
        }
    }
}

//------------------------------------------------------------------
// 16. 統計・デバッグ機能
//------------------------------------------------------------------
string GetNanpinStatistics(int magic)
{
    NanpinInfo info;
    GetNanpinInfo(magic, info);
    
    if(info.lots <= 0) return "No Position";
    
    string stats = StringConcatenate(
        "Magic:", magic,
        " | Type:", (info.type == OP_BUY ? "BUY" : "SELL"),
        " | Count:", info.count,
        " | Lots:", DoubleToString(info.lots, 2),
        " | P&L:", DoubleToString(info.total, 1), "pips",
        " | BEP:", DoubleToString(info.breakEvenPrice, Digits)
    );
    
    return stats;
}

void PrintAllNanpinStates(int &magicArrayRef[], int arraySize)
{
    Print("=== Nanpin States ===");
    for(int i = 0; i < arraySize; i++) {
        int magic = magicArrayRef[i];
        NanpinInfo info;
        GetNanpinInfo(magic, info);
        
        if(info.lots > 0) {
            Print(GetNanpinStatistics(magic));
        }
    }
}

void PrintDetailedNanpinStatus(int &magicArray[], int magic_count)
{
    Print("=== Detailed Nanpin Status ===");
    
    int totalNanpinPositions = 0;
    double totalNanpinLots = 0;
    double totalNanpinProfit = 0;
    
    for(int i = 0; i < magic_count; i++) {
        int magic = magicArray[i];
        NanpinInfo info;
        GetNanpinInfo(magic, info);
        
        if(info.lots > 0) {
            int positions = Utils_GetOpenPositions(magic);
            double profit = 0;
            
            // 損益計算
            for(int j = OrdersTotal() - 1; j >= 0; j--) {
                if(OrderSelect(j, SELECT_BY_POS) && 
                   OrderSymbol() == Symbol() && 
                   OrderMagicNumber() == magic) {
                    profit += OrderProfit();
                }
            }
            
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

void AnalyzeActualNanpinIntervals(int magic)
{
    Print("=== ACTUAL NANPIN INTERVALS FOR MAGIC ", magic, " ===");
    
    double prices[];
    datetime times[];
    int positions = 0;
    
    for(int i = 0; i < OrdersTotal(); i++) {
        if(OrderSelect(i, SELECT_BY_POS) && 
           OrderMagicNumber() == magic && 
           OrderSymbol() == Symbol()) {
            
            ArrayResize(prices, positions + 1);
            ArrayResize(times, positions + 1);
            prices[positions] = OrderOpenPrice();
            times[positions] = OrderOpenTime();
            positions++;
        }
    }
    
    if(positions < 2) {
        Print("ポジション数が不足（", positions, "個）");
        return;
    }
    
    // 時間順ソート
    for(int i = 0; i < positions - 1; i++) {
        for(int j = i + 1; j < positions; j++) {
            if(times[i] > times[j]) {
                double tempPrice = prices[i];
                datetime tempTime = times[i];
                prices[i] = prices[j];
                times[i] = times[j];
                prices[j] = tempPrice;
                times[j] = tempTime;
            }
        }
    }
    
    // 間隔計算
    for(int i = 1; i < positions; i++) {
        double priceDiff = MathAbs(prices[i] - prices[i-1]);
        double pipsDiff = Utils_PriceToPips(priceDiff);
        
        Print("Position ", i, " - ", i-1, ":");
        Print("  Time1: ", TimeToString(times[i-1], TIME_SECONDS));
        Print("  Time2: ", TimeToString(times[i], TIME_SECONDS));
        Print("  Price1: ", DoubleToString(prices[i-1], Digits));
        Print("  Price2: ", DoubleToString(prices[i], Digits));
        Print("  Difference: ", DoubleToString(priceDiff, Digits));
        Print("  Pips: ", DoubleToString(pipsDiff, 1));
    }
}

void TestPriceConversions()
{
    Print("=== PRICE CONVERSION TESTS ===");
    
    double testPips[] = {1.0, 5.0, 10.0, 20.0, 50.0, 100.0};
    
    for(int i = 0; i < ArraySize(testPips); i++) {
        double pips = testPips[i];
        
        double oldMethod = pips * Point;
        if(Digits == 3 || Digits == 5) oldMethod *= 10;
        
        double newMethod = Utils_PipsToPrice(pips);
        
        Print(DoubleToString(pips, 1), " pips:");
        Print("  Old Method: ", DoubleToString(oldMethod, 8));
        Print("  New Method: ", DoubleToString(newMethod, 8));
        Print("  Improvement: ", DoubleToString(newMethod / oldMethod, 2), "x");
        Print("  ----");
    }
}

void PrintNanpinManagerStatus()
{
    Print("=== Nanpin Manager Status ===");
    Print("Nanpin Enabled: ", (isNanpin ? "YES" : "NO"));
    Print("Max Nanpin Count: ", NanpinCount);
    Print("Cool Time: ", CoolTime, " seconds");
    Print("Current Interval: ", DoubleToString(g_currentNanpinInterval, 1), " pips");
    Print("Nanpin Multiplier: ", NanpinMult);
    Print("Adjustment Factor (k): ", k);
    Print("Single Direction Control: ", (EnableSingleDirectionNanpin ? "ON" : "OFF"));
    Print("Unconditional Count: ", UnconditionalNanpinCount);
    Print("StdDev Threshold: ", StdDevNanpinThreshold);
    
    
    TestPriceConversions();
}


void DiagnoseNanpinIssues(int magic)
{
    Print("=== NANPIN DIAGNOSIS FOR MAGIC ", magic, " ===");
    
    NanpinInfo info;
    GetNanpinInfo(magic, info);
    
    if(info.lots <= 0) {
        Print("❌ No positions found for Magic ", magic);
        return;
    }
    
    Print("✅ Position found:");
    Print("  Type: ", (info.type == OP_BUY ? "BUY" : "SELL"));
    Print("  Entry Price: ", DoubleToString(info.entry_price, Digits));
    Print("  Count: ", info.count);
    Print("  Total Lots: ", DoubleToString(info.lots, 2));
    
    bool coolTime = IsNanpinCoolTime(magic);
    Print("Cool Time: ", (coolTime ? "ACTIVE (blocking)" : "OK"));
    
    bool maxCount = (info.count >= NanpinCount);
    Print("Max Count: ", (maxCount ? "REACHED (blocking)" : "OK"), " (", info.count, "/", NanpinCount, ")");
    
    double currentPrice = (info.type == OP_BUY) ? Ask : Bid;
    double interval = g_currentNanpinInterval;
    double intervalPrice = Utils_PipsToPrice(interval);
    double distance = MathAbs(currentPrice - info.entry_price);
    double distancePips = Utils_PriceToPips(distance);
    
    Print("Price Analysis:");
    Print("  Current: ", DoubleToString(currentPrice, Digits));
    Print("  Entry: ", DoubleToString(info.entry_price, Digits));
    Print("  Required Interval: ", DoubleToString(interval, 1), " pips");
    Print("  Current Distance: ", DoubleToString(distancePips, 1), " pips");
    
    bool priceOK = false;
    if(info.type == OP_BUY) {
        priceOK = (Ask <= info.entry_price - intervalPrice);
        Print("  BUY Condition: Ask(", DoubleToString(Ask, Digits), 
              ") <= Entry-Interval(", DoubleToString(info.entry_price - intervalPrice, Digits), ") = ", 
              (priceOK ? "TRUE" : "FALSE"));
    } else {
        priceOK = (Bid >= info.entry_price + intervalPrice);
        Print("  SELL Condition: Bid(", DoubleToString(Bid, Digits), 
              ") >= Entry+Interval(", DoubleToString(info.entry_price + intervalPrice, Digits), ") = ", 
              (priceOK ? "TRUE" : "FALSE"));
    }
    
    bool nanpinCondition = CheckNanpinCondition(info.type, magic, info.count);
    Print("Nanpin Condition (RSI/Stoch): ", (nanpinCondition ? "OK" : "BLOCKING"));
    
    Print("Overall Status: ", 
          (!coolTime && !maxCount && priceOK && nanpinCondition ? "READY FOR NANPIN" : "BLOCKED"));
}

//------------------------------------------------------------------
// 17. ★★★ 外部インターフェース関数（本体EAとの連携用） ★★★
//------------------------------------------------------------------

// 本体EAから呼び出される統合ナンピン実行関数
void NanpinManager_ExecuteForAllMagics(int &magicArray[], int magic_count, double baseLots)
{
    ExecuteNanpinForAllMagics(magicArray, magic_count, baseLots);
}

// ボラティリティ更新（本体EAから呼び出し）
void NanpinManager_UpdateInterval(double stdDev)
{
    UpdateNanpinInterval(stdDev);
}

// 強制ナンピン設定（UIから呼び出し）
void NanpinManager_SetForceBuy() { SetForceNanpinBuy(true); }
void NanpinManager_SetForceSell() { SetForceNanpinSell(true); }

// ナンピン状態取得（デバッグ用）
void NanpinManager_GetInfo(int magic, NanpinInfo &info) { GetNanpinInfo(magic, info); }

// 状態リセット（決済時に呼び出し）
void NanpinManager_ResetState(int magic) { ResetNanpinState(magic); }

// 詳細状態表示（デバッグ用）
void NanpinManager_PrintDetailedStatus(int &magicArray[], int magic_count)
{
    PrintDetailedNanpinStatus(magicArray, magic_count);
}

// 診断機能
void NanpinManager_DiagnoseMagic(int magic) { DiagnoseNanpinIssues(magic); }

