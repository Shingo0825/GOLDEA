//+------------------------------------------------------------------+
//| UIManager.mqh (最終版)                                           |
//| UI・表示管理機能パッケージ                                       |
//| グローバル変数による状態の永続化に対応                           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//| UI関連の入力パラメータ
//+------------------------------------------------------------------+
input group "=== Manual Trading Buttons ===";
input double ManualLots       = 0.05;  // 手動ボタンで出すロット
input int    Magic_ManualBuy  = 901;   // BUY ボタンが使う Magic
input int    Magic_ManualSell = 902;   // SELL ボタンが使う Magic
input int    SlippageBtn      = 10;    // 許容スリッページ
input double BtnSL_Pips       = 0;     // 0=付けない
input double BtnTP_Pips       = 0;     // 0=付けない

//+------------------------------------------------------------------+
//| ボタン名定義
//+------------------------------------------------------------------+
#define BTN_BUY  "BTN_MANUAL_BUY"
#define BTN_SELL "BTN_MANUAL_SELL"
#define BTN_CLOSE_LONG  "BTN_CLOSE_LONG"
#define BTN_CLOSE_SHORT "BTN_CLOSE_SHORT"
#define BTN_FORCE_NP_BUY   "BTN_FORCE_NP_BUY"
#define BTN_FORCE_NP_SELL  "BTN_FORCE_NP_SELL"

// Magic 11-20用スイッチボタン名
#define BTN_SWITCH_11  "BTN_SWITCH_MAGIC_11"
#define BTN_SWITCH_12  "BTN_SWITCH_MAGIC_12"
#define BTN_SWITCH_13  "BTN_SWITCH_MAGIC_13"
#define BTN_SWITCH_14  "BTN_SWITCH_MAGIC_14"
#define BTN_SWITCH_15  "BTN_SWITCH_MAGIC_15"
#define BTN_SWITCH_16  "BTN_SWITCH_MAGIC_16"
#define BTN_SWITCH_17  "BTN_SWITCH_MAGIC_17"
#define BTN_SWITCH_18  "BTN_SWITCH_MAGIC_18"
#define BTN_SWITCH_19  "BTN_SWITCH_MAGIC_19"
#define BTN_SWITCH_20  "BTN_SWITCH_MAGIC_20"

// エントリー状態ラベル
#define LAB_ENTRY_STATE "LAB_ENTRY_STATE"

//+------------------------------------------------------------------+
//| グローバル変数
//+------------------------------------------------------------------+
bool MagicSwitch[10] = {false}; // Magic 11-20 の現在のON/OFF状態をメモリに保持

// ボタンリスト管理用
string BTN_LIST[] = {
    BTN_BUY, BTN_SELL,
    BTN_CLOSE_LONG, BTN_CLOSE_SHORT,
    BTN_FORCE_NP_BUY, BTN_FORCE_NP_SELL
};

string SWITCH_BTN_LIST[] = {
    BTN_SWITCH_11, BTN_SWITCH_12, BTN_SWITCH_13, BTN_SWITCH_14, BTN_SWITCH_15,
    BTN_SWITCH_16, BTN_SWITCH_17, BTN_SWITCH_18, BTN_SWITCH_19, BTN_SWITCH_20
};

// Magic 11-20のカスタム名称
string MAGIC_CUSTOM_NAMES[10] = {
    "24H-BUY",   // Magic 11
    "24H-SELL",  // Magic 12
    "EMA-BUY",   // Magic 13
    "EMA-SELL",  // Magic 14
    "RSI-BUY",   // Magic 15
    "RSI-SELL",  // Magic 16
    "DEV-BUY",   // Magic 17
    "DEV-SELL",  // Magic 18
    "MFI-BUY",   // Magic 19
    "MFI-SELL"   // Magic 20
};





//+------------------------------------------------------------------+
//| UI作成関数群
//+------------------------------------------------------------------+
void CreateManualButtons()
{
    Print("🎮 Creating manual trading buttons...");
    DeleteManualButtons();
    
    // BUY ボタン
    if(ObjectCreate(0, BTN_BUY, OBJ_BUTTON, 0, 0, 0)) {
        ObjectSetInteger(0, BTN_BUY, OBJPROP_XDISTANCE,   10);
        ObjectSetInteger(0, BTN_BUY, OBJPROP_YDISTANCE,   30);
        ObjectSetInteger(0, BTN_BUY, OBJPROP_XSIZE,       80);
        ObjectSetInteger(0, BTN_BUY, OBJPROP_YSIZE,       25);
        ObjectSetString (0, BTN_BUY, OBJPROP_TEXT,        "BUY");
        ObjectSetInteger(0, BTN_BUY, OBJPROP_BGCOLOR,     clrLime);
        ObjectSetInteger(0, BTN_BUY, OBJPROP_FONTSIZE,    10);
        ObjectSetInteger(0, BTN_BUY, OBJPROP_STATE,       false);
    }
    
    // SELL ボタン
    if(ObjectCreate(0, BTN_SELL, OBJ_BUTTON, 0, 0, 0)) {
        ObjectSetInteger(0, BTN_SELL, OBJPROP_XDISTANCE, 100);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_XSIZE,     80);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_YSIZE,     25);
        ObjectSetString (0, BTN_SELL, OBJPROP_TEXT,      "SELL");
        ObjectSetInteger(0, BTN_SELL, OBJPROP_BGCOLOR,   clrTomato);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_COLOR,     clrWhite);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_FONTSIZE,  10);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_STATE,     false);
    }
    
    // CLOSE-L (ロング全決済)
    if(ObjectCreate(0, BTN_CLOSE_LONG, OBJ_BUTTON, 0, 0, 0)) {
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_XDISTANCE, 190);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_XSIZE,     80);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_YSIZE,     25);
        ObjectSetString (0, BTN_CLOSE_LONG, OBJPROP_TEXT,      "CLOSE-L");
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_BGCOLOR,   clrDeepSkyBlue);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_COLOR,     clrWhite);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_FONTSIZE,  9);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_STATE,     false);
    }
    
    // CLOSE-S (ショート全決済)
    if(ObjectCreate(0, BTN_CLOSE_SHORT, OBJ_BUTTON, 0, 0, 0)) {
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_XDISTANCE, 280);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_XSIZE,     80);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_YSIZE,     25);
        ObjectSetString (0, BTN_CLOSE_SHORT, OBJPROP_TEXT,      "CLOSE-S");
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_BGCOLOR,   clrDeepSkyBlue);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_COLOR,     clrWhite);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_FONTSIZE,  9);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_STATE,     false);
    }
    
    // BUYナンピン
    if(ObjectCreate(0, BTN_FORCE_NP_BUY, OBJ_BUTTON, 0, 0, 0)) {
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_XDISTANCE, 370);
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_XSIZE,     80);
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_YSIZE,     25);
        ObjectSetString (0, BTN_FORCE_NP_BUY, OBJPROP_TEXT,      "NP-BUY");
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_BGCOLOR,   clrLime);
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_FONTSIZE,  9);
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_STATE,     false);
    }
    
    // SELLナンピン
    if(ObjectCreate(0, BTN_FORCE_NP_SELL, OBJ_BUTTON, 0, 0, 0)) {
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_XDISTANCE, 460);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_XSIZE,     80);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_YSIZE,     25);
        ObjectSetString (0, BTN_FORCE_NP_SELL, OBJPROP_TEXT,      "NP-SELL");
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_BGCOLOR,   clrTomato);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_COLOR,     clrWhite);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_FONTSIZE,  9);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_STATE,     false);
    }
    
    ChartRedraw(0);
}

void CreateMagicSwitches()
{
    Print("🎮 Creating Magic switch buttons...");
    DeleteMagicSwitches();
    
    int startX = 10, startY = 70, buttonWidth = 140, buttonHeight = 30, spacing = 150, rowSpacing = 40;
    
    for(int i = 0; i < 10; i++)
    {
        int magicNum = 11 + i;
        string btnName = SWITCH_BTN_LIST[i];
        
        if(!ObjectCreate(0, btnName, OBJ_BUTTON, 0, 0, 0)) continue;
        
        int row, col;
        if(magicNum % 2 == 1) { row = 0; col = (magicNum - 11) / 2; }
        else { row = 1; col = (magicNum - 12) / 2; }
        
        int xPos = startX + (col * spacing);
        int yPos = startY + (row * rowSpacing);
        
        ObjectSetInteger(0, btnName, OBJPROP_XDISTANCE, xPos);
        ObjectSetInteger(0, btnName, OBJPROP_YDISTANCE, yPos);
        ObjectSetInteger(0, btnName, OBJPROP_XSIZE, buttonWidth);
        ObjectSetInteger(0, btnName, OBJPROP_YSIZE, buttonHeight);
        ObjectSetInteger(0, btnName, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, btnName, OBJPROP_STATE, false);
        
        // 初期状態としてOFFの見た目を直接設定
        string customName = MAGIC_CUSTOM_NAMES[i];
        string displayText;
        if(StringLen(customName) > 8) {
            displayText = "M" + IntegerToString(magicNum) + ":" + StringSubstr(customName, 0, 6) + "..";
        } else {
            displayText = "M" + IntegerToString(magicNum) + ":" + customName;
        }
        ObjectSetString(0, btnName, OBJPROP_TEXT, displayText);
        ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, clrGray);
        ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrWhite);
    }
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| スイッチボタンの見た目と状態を更新する
//+------------------------------------------------------------------+
void UpdateSwitchButton(int switchIndex, bool isOn)
{
    if(switchIndex < 0 || switchIndex >= 10) return;
    
    string btnName = SWITCH_BTN_LIST[switchIndex];
    int magicNum = 11 + switchIndex;
    string customName = MAGIC_CUSTOM_NAMES[switchIndex];
    
    if(ObjectFind(0, btnName) < 0) return;
    
    // メモリ上の状態を更新
    MagicSwitch[switchIndex] = isOn;
    
    string displayText;
    if(StringLen(customName) > 8) {
        displayText = "M" + IntegerToString(magicNum) + ":" + StringSubstr(customName, 0, 6) + "..";
    } else {
        displayText = "M" + IntegerToString(magicNum) + ":" + customName;
    }
    
    if(isOn) {
        if(magicNum % 2 == 1) { // 奇数=BUY系
            ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, clrLime);
            ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrBlack);
        } else { // 偶数=SELL系
            ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, clrRed);
            ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrWhite);
        }
    } else {
        ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, clrGray);
        ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrWhite);
    }
    
    ObjectSetString(0, btnName, OBJPROP_TEXT, displayText);
    ObjectSetInteger(0, btnName, OBJPROP_STATE, false);
}

void CreateEntryStateLabel()
{
    if(ObjectFind(0, LAB_ENTRY_STATE) == -1) {
        if(ObjectCreate(0, LAB_ENTRY_STATE, OBJ_LABEL, 0, 0, 0)) {
            ObjectSetInteger(0, LAB_ENTRY_STATE, OBJPROP_XDISTANCE, 10);
            ObjectSetInteger(0, LAB_ENTRY_STATE, OBJPROP_YDISTANCE, 30);
            ObjectSetInteger(0, LAB_ENTRY_STATE, OBJPROP_FONTSIZE, 10);
            ObjectSetInteger(0, LAB_ENTRY_STATE, OBJPROP_COLOR, clrYellow);
            ObjectSetString(0, LAB_ENTRY_STATE, OBJPROP_TEXT, "Entry Status: Initializing...");
        }
    }
}

void UpdateBEP_Line(int magic, double bePrice, bool hasPosition, int positionType = -1)
{
    string name = "BEP_LINE_" + IntegerToString(magic);
    
    if(!hasPosition) {
        if(ObjectFind(0,name) >= 0) {
            ObjectDelete(0,name);
        }
        return;
    }
    
    if(ObjectFind(0,name) < 0) {
        if(!ObjectCreate(0, name, OBJ_HLINE, 0, Time[0], bePrice)) return;
        
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    }
    
    ObjectSetDouble(0, name, OBJPROP_PRICE, bePrice);
    
    color lineColor = (positionType == OP_BUY) ? clrDeepSkyBlue : clrOrangeRed;
    ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
}

//+------------------------------------------------------------------+
//| UI削除関数群
//+------------------------------------------------------------------+
void DeleteManualButtons()
{
    for(int i = ArraySize(BTN_LIST) - 1; i >= 0; i--) {
        if(ObjectFind(0, BTN_LIST[i]) >= 0) ObjectDelete(0, BTN_LIST[i]);
    }
}

void DeleteMagicSwitches()
{
    for(int i = 0; i < 10; i++) {
        if(ObjectFind(0, SWITCH_BTN_LIST[i]) >= 0) ObjectDelete(0, SWITCH_BTN_LIST[i]);
    }
}

void DeleteAllUIElements()
{
    DeleteManualButtons();
    DeleteMagicSwitches();
    ObjectDelete(0, LAB_ENTRY_STATE);
    // BEPラインはEA終了時にGOLDEA.mq4のOnDeinitで削除するため、ここでは削除しない
}

//+------------------------------------------------------------------+
//| Magic ON/OFF状態取得
//+------------------------------------------------------------------+
bool IsMagicEnabled(int magicNumber, int magicOffset = 0)
{
    int baseMagic = magicNumber - magicOffset;

    if(baseMagic < 11 || baseMagic > 20) {
        // M11-M20以外は常に有効（または別のロジックで制御）
        return true; 
    }
    
    int switchIndex = baseMagic - 11;
    
    if (switchIndex < 0 || switchIndex >= 10) return false;
    
    return MagicSwitch[switchIndex];
}

//+------------------------------------------------------------------+
//| NanpinManagerとの連携用インターフェース
//+------------------------------------------------------------------+
#include "NanpinManager.mqh"

void UI_SetForceNanpinBuy() 
{
    NanpinManager_SetForceBuy();
}

void UI_SetForceNanpinSell() 
{
    NanpinManager_SetForceSell();
}

//+------------------------------------------------------------------+
//| カスタム名関連
//+------------------------------------------------------------------+
void SetMagicCustomNames()
{
    // この関数は現在、グローバル配列の初期化に依存しているため、
    // 呼び出しは不要ですが、将来の拡張のために残しておきます。
}

string GetMagicCustomName(int magicNumber)
{
    int offset = 0; // ここは実際のオフセット取得ロジックに合わせる必要があります
    int baseMagic = magicNumber - offset;
    
    if(baseMagic < 11 || baseMagic > 20) return "";
    
    int index = baseMagic - 11;
    return MAGIC_CUSTOM_NAMES[index];
}

//+------------------------------------------------------------------+
//| UI初期化・終了処理
//+------------------------------------------------------------------+
void InitUIManager()
{
    Print("🎨 Initializing UI Manager...");
    
    CreateManualButtons();
    CreateMagicSwitches(); 
    CreateEntryStateLabel();
    
    // 状態の復元はGOLDEA.mq4のOnInitで行う
    
    Print("✅ UI Manager initialized successfully.");
}

void DeinitUIManager()
{
    DeleteAllUIElements();
    Print("🎨 UI Manager deinitialized.");
}

//+------------------------------------------------------------------+
//| UIManager.mqh (最終デバッグ版)
//+------------------------------------------------------------------+

// (ファイルの他の部分は元のまま)

//+------------------------------------------------------------------+
//| ★★★ 新しい保存関数（最終デバッグ版） ★★★
//+------------------------------------------------------------------+
void SaveButtonStates()
{
    string prefix = "GOLDEA_" + Symbol() + "_MagicState_";
    Print("💾 Saving button states to Global Variables...");

    for(int i = 0; i < 10; i++)
    {
        double valueToSave = 0.0;
        if (MagicSwitch[i]) {
            valueToSave = 1.0;
        }

        string varName = prefix + IntegerToString(11 + i);
        GlobalVariableSet(varName, valueToSave);
        
        // ★★★ デバッグ用Printを追加 ★★★
        Print("  -> Saving: Name='", varName, "', Value=", valueToSave);
    }
    Print("✅ Button states saved.");
}

//+------------------------------------------------------------------+
//| ★★★ 新しい復元関数（最終デバッグ版） ★★★
//+------------------------------------------------------------------+
void RestoreButtonStates()
{
    string prefix = "GOLDEA_" + Symbol() + "_MagicState_";
    Print("📂 Restoring button states from Global Variables...");

    for(int i = 0; i < 10; i++)
    {
        string varName = prefix + IntegerToString(11 + i);
        bool newState = false;
        
        // ★★★ デバッグ用Printを追加 ★★★
        Print("  -> Attempting to restore: Name='", varName, "'");

        if(GlobalVariableCheck(varName))
        {
            double value = GlobalVariableGet(varName);
            // ★★★ デバッグ用Printを追加 ★★★
            Print("    ✅ Found! Read Value=", value);
            if(value == 1.0)
            {
                newState = true;
            }
        }
        else
        {
            // ★★★ デバッグ用Printを追加 ★★★
            Print("    ❌ Not Found.");
        }
        
        // 読み込んだ状態をボタンに反映
        UpdateSwitchButton(i, newState);
    }
    ChartRedraw(0);
    Print("✅ Button states restoration completed.");
}

// (ファイルの他の部分も元のまま)