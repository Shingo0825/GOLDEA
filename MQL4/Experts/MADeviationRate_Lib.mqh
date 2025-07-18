//+------------------------------------------------------------------+
//|                                        MADeviationRate_Lib.mqh   |
//|      移動平均線乖離率の計算ライブラリ (★EA本体からのシグマ値受け取り版)      |
//+------------------------------------------------------------------+
#property strict

#ifndef __MADEVIATIONRATE_LIB_MQH__
#define __MADEVIATIONRATE_LIB_MQH__



//+------------------------------------------------------------------+
//| 移動平均線乖離率と、その標準偏差バンドを計算する関数
//+------------------------------------------------------------------+
int CalculateMADeviationRate(
   string symbol,
   int    tf,
   int    ma_period,
   double std_dev_multiplier, // ★★★ この引数で渡されたシグマ値を直接使用する
   int    shift,
   double &rate_out,
   double &upper_band_out,
   double &lower_band_out
) {
   // 初期化
   rate_out       = EMPTY_VALUE;
   upper_band_out = EMPTY_VALUE;
   lower_band_out = EMPTY_VALUE;

   if (ma_period <= 0) return 0;

   // ★★★【変更点】★★★
   // 渡されたシグマ値が不正な場合は計算を中断する
   if (std_dev_multiplier <= 0.0) return 0;

   // 内部でシグマ値を取得するロジックを削除
   // if (std_dev_multiplier <= 0.0) std_dev_multiplier = GetSigmaForSymbol(symbol);

   int bands_period  = MathMax(1, (int)MathRound(ma_period * std_dev_multiplier));
   int required_bars = shift + ma_period + bands_period;
   if (iBars(symbol, tf) < required_bars) return 0;

   double sma = iMA(symbol, tf, ma_period, 0, MODE_SMA, PRICE_CLOSE, shift);
   if (sma <= 0) return 0;
   double closePrice = iClose(symbol, tf, shift);
   rate_out = (closePrice / sma) * 100.0 - 100.0;

   // 履歴乖離率
   double history[];
   ArrayResize(history, bands_period);
   ArraySetAsSeries(history, true);
   for (int i = 0; i < bands_period; i++) {
      int idx = shift + i;
      double hma = iMA(symbol, tf, ma_period, 0, MODE_SMA, PRICE_CLOSE, idx);
      if (hma <= 0) return 0;
      double hcl = iClose(symbol, tf, idx);
      history[i] = (hcl / hma) * 100.0 - 100.0;
   }

   int total = ArraySize(history);
   double center = iMAOnArray(history, total, bands_period, 0, MODE_SMA, 0);
   double stdv   = iStdDevOnArray(history, total, bands_period, 0, MODE_SMA, 0);
   if (center == EMPTY_VALUE || stdv == EMPTY_VALUE) return 0;

   upper_band_out = center + stdv * std_dev_multiplier;
   lower_band_out = center - stdv * std_dev_multiplier;

   if (rate_out > upper_band_out) return 1;
   if (rate_out < lower_band_out) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//| 簡易ラッパー: 現在シンボルで乖離率計算 (この関数は変更不要)
//+------------------------------------------------------------------+
int MADeviationRateTF(
   int tf,
   int ma_period,
   double std_dev_multiplier,
   int shift,
   double &rate,
   double &upper,
   double &lower
) {
   return CalculateMADeviationRate(Symbol(), tf, ma_period, std_dev_multiplier, shift,
                                 rate, upper, lower);
}

//+------------------------------------------------------------------+
//| バンド回帰シグナル判定
//+------------------------------------------------------------------+
int CheckDeviationReversalSignal(
   string symbol, // ★★★【変更点】★★★ 引数を必須にするため、デフォルト値を削除
   int    tf,
   int    ma_period,
   double sigma_multiplier // ★★★【変更点】★★★ 引数を必須にするため、デフォルト値を削除
) {
   // 内部でシンボルやシグマを取得するロジックを削除
   // if (symbol == "") symbol = Symbol();
   // if (sigma_multiplier <= 0.0) sigma_multiplier = GetSigmaForSymbol(symbol);

   // ★★★【追加】★★★ 引数が不正な場合は0を返す
   if (sigma_multiplier <= 0.0 || symbol == "") return 0;

   double p_rate, p_ub, p_lb;
   double c_rate, c_ub, c_lb;
   CalculateMADeviationRate(symbol, tf, ma_period, sigma_multiplier, 2, p_rate, p_ub, p_lb);
   CalculateMADeviationRate(symbol, tf, ma_period, sigma_multiplier, 1, c_rate, c_ub, c_lb);

   if (p_rate == EMPTY_VALUE || c_rate == EMPTY_VALUE) return 0;
   if (p_rate < p_lb && c_rate >= c_lb) return 1;
   if (p_rate > p_ub && c_rate <= c_ub) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//| シグナル矢印描画
//+------------------------------------------------------------------+
void CheckAndDrawDeviationSignal(
   bool   debug, // ★★★【変更点】★★★ 引数を必須にするため、デフォルト値を削除
   string symbol,
   int    tf,
   int    ma_period,
   double sigma_multiplier // ★★★【変更点】★★★ 引数を必須にするため、デフォルト値を削除
) {
   if (!debug) return;
   
   // ★★★【追加】★★★ 引数が不正な場合は処理しない
   if (sigma_multiplier <= 0.0 || symbol == "") return;

   double p_rate, p_ub, p_lb;
   double c_rate, c_ub, c_lb;
   CalculateMADeviationRate(symbol, tf, ma_period, sigma_multiplier, 2, p_rate, p_ub, p_lb);
   CalculateMADeviationRate(symbol, tf, ma_period, sigma_multiplier, 1, c_rate, c_ub, c_lb);
   if (p_rate == EMPTY_VALUE || c_rate == EMPTY_VALUE) return;

   datetime t = iTime(symbol, tf, 1); // Time[] -> iTime() に変更し、堅牢性を向上
   double off = MarketInfo(symbol, MODE_ASK) * 0.0005;
   string name;
   if (p_rate < p_lb && c_rate >= c_lb) {
      name = "DeviationArrow_" + TimeToString(t,TIME_DATE|TIME_SECONDS);
      if (ObjectFind(0,name)==-1) {
         ObjectCreate(0,name,OBJ_ARROW,0,t,iLow(symbol, tf, 1)-off);
         ObjectSetInteger(0,name,OBJPROP_ARROWCODE,SYMBOL_ARROWUP);
         ObjectSetInteger(0,name,OBJPROP_COLOR,clrDodgerBlue);
      }
      Print("🟢 BUY Dev @",TimeToString(t)," σ=",DoubleToString(sigma_multiplier,1));
   }
   if (p_rate > p_ub && c_rate <= c_ub) {
      name = "DeviationArrow_" + TimeToString(t,TIME_DATE|TIME_SECONDS);
      if (ObjectFind(0,name)==-1) {
         ObjectCreate(0,name,OBJ_ARROW,0,t,iHigh(symbol, tf, 1)+off);
         ObjectSetInteger(0,name,OBJPROP_ARROWCODE,SYMBOL_ARROWDOWN);
         ObjectSetInteger(0,name,OBJPROP_COLOR,clrTomato);
      }
      Print("🔴 SELL Dev @",TimeToString(t)," σ=",DoubleToString(sigma_multiplier,1));
   }
}





#endif // __MADEVIATIONRATE_LIB_MQH__
