//+------------------------------------------------------------------+
//| RiskManager.mqhのTrailingStop関連パラメータ削除版
//+------------------------------------------------------------------+
#property strict
#include "TradingUtils.mqh";

//+------------------------------------------------------------------+
//| リスク管理関連の入力パラメータ
//+------------------------------------------------------------------+
input group "=== Risk Management Settings ==="
input double BaseLots = 0.01;                           // 基本ロット数
input double BalanceThreshold = 10000.0;                // 証拠金残高の閾値
input bool isCompoundingEnabled = false;                // 複利機能のON/OFF
input bool isMicroAccount = false;                      // マイクロ口座を使用するかどうか

input group "=== Stop Loss Settings ==="
input bool EnableStopLoss = true;                       // 損切り機能を有効にするかどうか
input double StopLossAmount = 300000.0;                 // 損切り金額

// ★★★ Trailing Stop設定はNanpinManagerに移動済みのため削除 ★★★
// input group "=== Trailing Stop Settings ==="
// input bool EnableTrailingStop = true;                // ← NanpinManagerで定義済み
// input double trailingStopPips = 3.0;                 // ← NanpinManagerで定義済み

//+------------------------------------------------------------------+
//| グローバル変数
//+------------------------------------------------------------------+
double maxLotSize;                                       // 最大ロット数

//+------------------------------------------------------------------+
//| リスク管理初期化
//+------------------------------------------------------------------+
void InitRiskManager()
{
    Print("💰 Initializing Risk Manager...");
    
    // 口座の種類に応じたロットサイズ設定
    maxLotSize = isMicroAccount ? 100.0 : 50.0;
    
    Print("💰 Account Type: ", (isMicroAccount ? "Micro" : "Standard"));
    Print("💰 Max Lot Size: ", maxLotSize);
    Print("💰 Base Lots: ", BaseLots);
    Print("💰 Compounding: ", (isCompoundingEnabled ? "ON" : "OFF"));
    Print("💰 Stop Loss: ", (EnableStopLoss ? "ON" : "OFF"));
    // ★★★ Trailing Stop表示はNanpinManagerの管轄 ★★★
    
    Print("✅ Risk Manager initialized successfully.");
}

// [他の関数はそのまま...]
//+------------------------------------------------------------------+
//| 証拠金残高に基づいてロットサイズを計算する関数
//+------------------------------------------------------------------+
double CalculateLots() 
{
    double equity = AccountEquity(); // 純資産額を取得
    double lots = BaseLots;
    
    if (isCompoundingEnabled) {
        lots = BaseLots * MathFloor(equity / BalanceThreshold);
    }
    
    return CheckLots(lots);
}

//+------------------------------------------------------------------+
//| ロット数調整用関数
//+------------------------------------------------------------------+
double CheckLots(double lots)
{
    double min_lots = MarketInfo(Symbol(), MODE_MINLOT);
    double max_lots = MarketInfo(Symbol(), MODE_MAXLOT);
    double step = MarketInfo(Symbol(), MODE_LOTSTEP);

    if(lots < min_lots) lots = min_lots;
    if(lots > max_lots) lots = max_lots;

    if(step == 1) {
        lots = NormalizeDouble(lots, 0);
    }
    else if(step == 0.1) {
        lots = NormalizeDouble(lots, 1);
    }
    else {
        lots = NormalizeDouble(lots, 2);
    }

    return lots;
}

//+------------------------------------------------------------------+
//| 証拠金チェック関数
//+------------------------------------------------------------------+
bool MarginCheck(int type, double lots, double price)
{
   // 必要証拠金をチェック
   if (AccountFreeMarginCheck(Symbol(), type, lots) <= 0)
   {
      // 静かに失敗を返す（Alertは出さない）
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| 取引可能性の総合チェック
//+------------------------------------------------------------------+
bool IsTradingPossible(double lots)
{
    double freeMargin = AccountFreeMargin();
    double requiredMargin = MarketInfo(Symbol(), MODE_MARGINREQUIRED) * lots;
    
    if(freeMargin < requiredMargin)
    {
        Print("💰 Insufficient Margin: Required=", DoubleToString(requiredMargin,2),
              " / Available=", DoubleToString(freeMargin,2));
        return false;
    }
    
    return true;
}
//+------------------------------------------------------------------+
//| マジックナンバーごとにポジションの損益を取得する関数 (★修正版)
//+------------------------------------------------------------------+
double GetOrderProfitByMagic(int magic)
{
    double totalProfit = 0;
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS) == false) continue;
        
        // ★★★ 以下の行で通貨ペアのチェックを追加 ★★★
        if(OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
        
        totalProfit += OrderProfit();
    }
    return totalProfit;
}

//+------------------------------------------------------------------+
//| 損切り金額チェック
//+------------------------------------------------------------------+
bool IsStopLossHit(int magic)
{
    if(!EnableStopLoss) return false;
    
    double currentLoss = GetOrderProfitByMagic(magic);
    return (currentLoss <= -StopLossAmount);
}

//+------------------------------------------------------------------+
//| 分割エントリーの最大ロット制限チェック
//+------------------------------------------------------------------+
bool NeedsLotSplit(double requestedLots)
{
    return (requestedLots > maxLotSize);
}

//+------------------------------------------------------------------+
//| 分割エントリー用のロット配列を計算
//+------------------------------------------------------------------+
void CalculateSplitLots(double totalLots, double &lotArray[], int &arraySize)
{
    arraySize = 0;
    double remainingLots = totalLots;
    
    // 配列をクリア
    ArrayResize(lotArray, 0);
    
    while(remainingLots > 0) {
        double lotToAdd = MathMin(remainingLots, maxLotSize);
        lotToAdd = CheckLots(lotToAdd);
        
        ArrayResize(lotArray, arraySize + 1);
        lotArray[arraySize] = lotToAdd;
        arraySize++;
        
        remainingLots -= lotToAdd;
        
        // 無限ループ防止
        if(arraySize > 10) {
            Print("⚠️ Split lot calculation exceeded maximum iterations");
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| リスク情報表示
//+------------------------------------------------------------------+
void DisplayRiskInfo()
{
    double currentLots = CalculateLots();
    double equity = AccountEquity();
    double freeMargin = AccountFreeMargin();
    double requiredMargin = MarketInfo(Symbol(), MODE_MARGINREQUIRED) * currentLots;
    
    string riskInfo = StringConcatenate(
        "💰 Risk Info:\n",
        "Equity: $", DoubleToString(equity, 2), "\n",
        "Free Margin: $", DoubleToString(freeMargin, 2), "\n",
        "Current Lots: ", DoubleToString(currentLots, 2), "\n",
        "Required Margin: $", DoubleToString(requiredMargin, 2)
    );
    
    Comment(riskInfo);
}

//+------------------------------------------------------------------+
//| リスクレベル評価
//+------------------------------------------------------------------+
string EvaluateRiskLevel()
{
    double equity = AccountEquity();
    double balance = AccountBalance();
    double freeMarginPercent = (AccountFreeMargin() / equity) * 100;
    
    string riskLevel;
    color riskColor;
    
    if(freeMarginPercent > 80) {
        riskLevel = "LOW";
        riskColor = clrGreen;
    }
    else if(freeMarginPercent > 50) {
        riskLevel = "MEDIUM";
        riskColor = clrYellow;
    }
    else if(freeMarginPercent > 30) {
        riskLevel = "HIGH";
        riskColor = clrOrange;
    }
    else {
        riskLevel = "CRITICAL";
        riskColor = clrRed;
    }
    
    return riskLevel;
}

//+------------------------------------------------------------------+
//| ドローダウン計算
//+------------------------------------------------------------------+
double CalculateDrawdown()
{
    double balance = AccountBalance();
    double equity = AccountEquity();
    
    if(balance == 0) return 0;
    
    double drawdown = ((balance - equity) / balance) * 100;
    return MathMax(drawdown, 0); // 負の値は0にクリップ
}

//+------------------------------------------------------------------+
//| 最大推奨ロット計算（リスク率ベース） (★改善版)
//+------------------------------------------------------------------+
double CalculateMaxRecommendedLots(double riskPercent = 2.0, double stopLossPips = 20.0)
{
    // 口座残高から許容損失額を計算
    double equity = AccountEquity();
    double riskAmount = equity * (riskPercent / 100.0);

    // --- ここから計算ロジックを改善 ---

    // 1. 1ロットあたりの1pipの価値を計算する
    //    ティックサイズからではなく、実際の価格差から計算することで、より多くの銘柄で正確に動作する
    double one_pip_price = Utils_PipsToPrice(1.0); // 1pipがいくらの価格変動かを取得
    
    // 1ロットあたりの1pipの価値 = (1ロットあたりの契約サイズ * 1pipの価格変動) / 現在価格(対USDの場合)
    // MQL4では AccountCurrency() と SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT) の比較が必要だが
    // XAUUSDや標準的な通貨ペアでは、以下の TickValue を使った計算が最もシンプルで堅牢
    double value_per_lot_per_pip = MarketInfo(Symbol(), MODE_TICKVALUE) / MarketInfo(Symbol(), MODE_TICKSIZE) * one_pip_price;

    // 2. 指定したSL幅(pips)での1ロットあたりの損失額を計算
    double loss_per_lot = stopLossPips * value_per_lot_per_pip;

    // 3. 許容損失額を1ロットあたりの損失額で割り、最大ロットを算出
    double maxLots = 0;
    if (loss_per_lot > 0) // ゼロ除算を防止
    {
        maxLots = riskAmount / loss_per_lot;
    }
    // --- ここまで改善 ---

    // ロット数を丸めて返す
    return CheckLots(maxLots);
}
//+------------------------------------------------------------------+
//| 証拠金使用率計算
//+------------------------------------------------------------------+
double CalculateMarginUsagePercent()
{
    double equity = AccountEquity();
    double usedMargin = AccountMargin();
    
    if(equity == 0) return 0;
    
    return (usedMargin / equity) * 100;
}

//+------------------------------------------------------------------+
//| リスク統計の表示
//+------------------------------------------------------------------+
void PrintRiskStatistics()
{
    Print("=== Risk Manager Statistics ===");
    Print("Account Equity: $", DoubleToString(AccountEquity(), 2));
    Print("Account Balance: $", DoubleToString(AccountBalance(), 2));
    Print("Free Margin: $", DoubleToString(AccountFreeMargin(), 2));
    Print("Used Margin: $", DoubleToString(AccountMargin(), 2));
    Print("Margin Level: ", DoubleToString((AccountEquity()/AccountMargin())*100, 2), "%");
    Print("Current Drawdown: ", DoubleToString(CalculateDrawdown(), 2), "%");
    Print("Risk Level: ", EvaluateRiskLevel());
    Print("Recommended Max Lots (2%): ", DoubleToString(CalculateMaxRecommendedLots(2.0), 2));
    Print("Current Calculated Lots: ", DoubleToString(CalculateLots(), 2));
    Print("Max Single Position Size: ", DoubleToString(maxLotSize, 2));
}

//+------------------------------------------------------------------+
//| エラー処理用：重要なエラーかどうか判定
//+------------------------------------------------------------------+
bool IsCriticalTradingError(int errorCode)
{
    switch(errorCode) {
        case 134: // Not enough money
        case 4: // Trade server is busy
        case 6: // No connection with trade server
        case 64: // Account disabled
        case 65: // Invalid account
        case 133: // Trade is disabled
            return true;
        default:
            return false;
    }
}

//+------------------------------------------------------------------+
//| 口座安全性チェック
//+------------------------------------------------------------------+
bool IsAccountSafe()
{
    double marginLevel = (AccountEquity() / AccountMargin()) * 100;
    double drawdown = CalculateDrawdown();
    
    // 証拠金維持率が200%以下、またはドローダウンが20%以上なら危険
    if(marginLevel < 200 || drawdown > 20) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 緊急停止判定
//+------------------------------------------------------------------+
bool ShouldEmergencyStop()
{
    double marginLevel = (AccountEquity() / AccountMargin()) * 100;
    double drawdown = CalculateDrawdown();
    
    // 証拠金維持率が120%以下、またはドローダウンが30%以上なら緊急停止
    if(marginLevel < 120 || drawdown > 30) {
        Alert("🚨 EMERGENCY STOP: Account at risk! Margin Level: ", 
              DoubleToString(marginLevel, 1), "% / Drawdown: ", 
              DoubleToString(drawdown, 1), "%");
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| リスクアラート
//+------------------------------------------------------------------+
void CheckRiskAlerts()
{
    static datetime lastRiskAlertTime = 0;  // 変数名を変更
    const int ALERT_INTERVAL = 300; // 5分間隔
    
    if(TimeCurrent() - lastRiskAlertTime < ALERT_INTERVAL) return;
    
    double marginLevel = (AccountEquity() / AccountMargin()) * 100;
    double drawdown = CalculateDrawdown();
    
    string alertMsg = "";
    
    if(marginLevel < 150) {
        alertMsg = "⚠️ Low Margin Level: " + DoubleToString(marginLevel, 1) + "%";
    }
    else if(drawdown > 15) {
        alertMsg = "⚠️ High Drawdown: " + DoubleToString(drawdown, 1) + "%";
    }
    
    if(alertMsg != "") {
        Alert(alertMsg);
        Print(alertMsg);
        lastRiskAlertTime = TimeCurrent();  // 変数名を変更
    }
}

//+------------------------------------------------------------------+
//| デバッグ情報表示
//+------------------------------------------------------------------+
void PrintRiskManagerStatus()
{
    Print("=== Risk Manager Status ===");
    Print("Base Lots: ", BaseLots);
    Print("Compounding Enabled: ", (isCompoundingEnabled ? "YES" : "NO"));
    Print("Stop Loss Enabled: ", (EnableStopLoss ? "YES" : "NO"));
    Print("Stop Loss Amount: $", StopLossAmount);
    // ★★★ TrailingStopはNanpinManagerで管理 ★★★
    Print("Account Type: ", (isMicroAccount ? "Micro" : "Standard"));
    Print("Max Lot Size: ", maxLotSize);
    Print("Current Risk Level: ", EvaluateRiskLevel());
    Print("Account Safe: ", (IsAccountSafe() ? "YES" : "NO"));
}