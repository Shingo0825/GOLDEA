//+------------------------------------------------------------------+
//|                                          UIManager.mqh (更新版)   |
//|                UI・表示管理機能パッケージ（ナンピン機能移植後）     |
//|                  ボタン・ラベル・イベント処理を統合管理              |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//| UI関連の入力パラメータ
//+------------------------------------------------------------------+
input group "=== Manual Trading Buttons ==="
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
bool MagicSwitch[10] = {false}; // Magic 11-20 のON/OFF状態

// ★★★ 強制ナンピンフラグは削除（NanpinManagerに移植済み）
// bool ForceNanpinBuy  = false;   // ← 削除
// bool ForceNanpinSell = false;   // ← 削除

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
    "24HBUY",      // Magic 11
    "24HSELL",     // Magic 12
    "BUY",         // Magic 13
    "SELL",        // Magic 14
    "BUY",         // Magic 15
    "SELL",        // Magic 16
    "BUY",         // Magic 17
    "SELL",        // Magic 18
    "BUY",         // Magic 19
    "SELL"         // Magic 20
};

//+------------------------------------------------------------------+
//| UI作成関数群
//+------------------------------------------------------------------+
void CreateManualButtons()
{
    Print("🎮 Creating manual trading buttons...");
    DeleteManualButtons();
    
    // BUY ボタン
    if(!ObjectCreate(0, BTN_BUY, OBJ_BUTTON, 0, 0, 0)) { 
        Print("❌ BUY Button create error: ", GetLastError()); 
    } else {
        ObjectSetInteger(0, BTN_BUY, OBJPROP_XDISTANCE,  10);
        ObjectSetInteger(0, BTN_BUY, OBJPROP_YDISTANCE,  30);
        ObjectSetInteger(0, BTN_BUY, OBJPROP_XSIZE,      80);
        ObjectSetInteger(0, BTN_BUY, OBJPROP_YSIZE,      25);
        ObjectSetString (0, BTN_BUY, OBJPROP_TEXT,       "BUY");
        ObjectSetInteger(0, BTN_BUY, OBJPROP_BGCOLOR,    clrLime);
        ObjectSetInteger(0, BTN_BUY, OBJPROP_FONTSIZE,   10);
        ObjectSetInteger(0, BTN_BUY, OBJPROP_STATE,      false);
        Print("✅ BUY button created");
    }
    
    // SELL ボタン
    if(!ObjectCreate(0, BTN_SELL, OBJ_BUTTON, 0, 0, 0)) { 
        Print("❌ SELL Button create error: ", GetLastError()); 
    } else {
        ObjectSetInteger(0, BTN_SELL, OBJPROP_XDISTANCE, 100);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_XSIZE,     80);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_YSIZE,     25);
        ObjectSetString (0, BTN_SELL, OBJPROP_TEXT,      "SELL");
        ObjectSetInteger(0, BTN_SELL, OBJPROP_BGCOLOR,   clrTomato);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_COLOR,     clrWhite);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_FONTSIZE,  10);
        ObjectSetInteger(0, BTN_SELL, OBJPROP_STATE,     false);
        Print("✅ SELL button created");
    }
    
    // CLOSE-L (ロング全決済)
    if(!ObjectCreate(0, BTN_CLOSE_LONG, OBJ_BUTTON, 0, 0, 0)) { 
        Print("❌ CLOSE-L Button create error: ", GetLastError()); 
    } else {
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_XDISTANCE, 190);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_XSIZE,     80);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_YSIZE,     25);
        ObjectSetString (0, BTN_CLOSE_LONG, OBJPROP_TEXT,      "CLOSE-L");
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_BGCOLOR,   clrDeepSkyBlue);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_COLOR,     clrWhite);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_FONTSIZE,  9);
        ObjectSetInteger(0, BTN_CLOSE_LONG, OBJPROP_STATE,     false);
        Print("✅ CLOSE-L button created");
    }
    
    // CLOSE-S (ショート全決済)
    if(!ObjectCreate(0, BTN_CLOSE_SHORT, OBJ_BUTTON, 0, 0, 0)) { 
        Print("❌ CLOSE-S Button create error: ", GetLastError()); 
    } else {
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_XDISTANCE, 280);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_XSIZE,     80);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_YSIZE,     25);
        ObjectSetString (0, BTN_CLOSE_SHORT, OBJPROP_TEXT,      "CLOSE-S");
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_BGCOLOR,   clrDeepSkyBlue);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_COLOR,     clrWhite);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_FONTSIZE,  9);
        ObjectSetInteger(0, BTN_CLOSE_SHORT, OBJPROP_STATE,     false);
        Print("✅ CLOSE-S button created");
    }
    
    // BUYナンピン
    if(!ObjectCreate(0, BTN_FORCE_NP_BUY, OBJ_BUTTON, 0, 0, 0)) { 
        Print("❌ NP-BUY Button create error: ", GetLastError()); 
    } else {
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_XDISTANCE, 370);
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_XSIZE,     80);
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_YSIZE,     25);
        ObjectSetString (0, BTN_FORCE_NP_BUY, OBJPROP_TEXT,      "NP-BUY");
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_BGCOLOR,   clrLime);
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_FONTSIZE,  9);
        ObjectSetInteger(0, BTN_FORCE_NP_BUY, OBJPROP_STATE,     false);
        Print("✅ NP-BUY button created");
    }
    
    // SELLナンピン
    if(!ObjectCreate(0, BTN_FORCE_NP_SELL, OBJ_BUTTON, 0, 0, 0)) { 
        Print("❌ NP-SELL Button create error: ", GetLastError()); 
    } else {
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_XDISTANCE, 460);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_XSIZE,     80);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_YSIZE,     25);
        ObjectSetString (0, BTN_FORCE_NP_SELL, OBJPROP_TEXT,      "NP-SELL");
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_BGCOLOR,   clrTomato);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_COLOR,     clrWhite);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_FONTSIZE,  9);
        ObjectSetInteger(0, BTN_FORCE_NP_SELL, OBJPROP_STATE,     false);
        Print("✅ NP-SELL button created");
    }
    
    ChartRedraw(0);
    Print("🎮 Manual buttons creation completed");
}

void CreateMagicSwitches()
{
    Print("🎮 Creating Magic switch buttons...");
    DeleteMagicSwitches();
    
    int startX = 10, startY = 70, buttonWidth = 140, buttonHeight = 30, spacing = 150, rowSpacing = 40;
    
    for(int i = 0; i < 10; i++) // Magic 11-20 (10個)
    {
        int magicNum = 11 + i;
        string btnName = SWITCH_BTN_LIST[i];
        
        if(!ObjectCreate(0, btnName, OBJ_BUTTON, 0, 0, 0)) { 
            Print("❌ Switch button create error for Magic ", magicNum, ": ", GetLastError()); 
            continue; 
        }
        
        int row, col;
        if(magicNum % 2 == 1) { 
            row = 0; 
            col = (magicNum - 11) / 2; 
        } else { 
            row = 1; 
            col = (magicNum - 12) / 2; 
        }
        
        int xPos = startX + (col * spacing), yPos = startY + (row * rowSpacing);
        
        ObjectSetInteger(0, btnName, OBJPROP_XDISTANCE, xPos);
        ObjectSetInteger(0, btnName, OBJPROP_YDISTANCE, yPos);
        ObjectSetInteger(0, btnName, OBJPROP_XSIZE, buttonWidth);
        ObjectSetInteger(0, btnName, OBJPROP_YSIZE, buttonHeight);
        ObjectSetInteger(0, btnName, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, btnName, OBJPROP_STATE, false);
        
        UpdateSwitchButton(i, false);
        Print("✅ Magic ", magicNum, " switch button created at (", xPos, ",", yPos, ")");
    }
    
    ChartRedraw(0);
    Print("🎮 Magic switch buttons creation completed");
}

void UpdateSwitchButton(int switchIndex, bool isOn)
{
    if(switchIndex < 0 || switchIndex >= 10) { 
        Print("❌ Invalid switch index: ", switchIndex); 
        return; 
    }
    
    string btnName = SWITCH_BTN_LIST[switchIndex];
    int magicNum = 11 + switchIndex;
    string customName = MAGIC_CUSTOM_NAMES[switchIndex];
    
    if(ObjectFind(0, btnName) < 0) { 
        Print("⚠️ Switch button not found: ", btnName); 
        return; 
    }
    
    MagicSwitch[switchIndex] = isOn;
    
    if(isOn) {
        if(magicNum % 2 == 1) { // 奇数=BUY
            ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, clrLime);
            ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrBlack);
        } else { // 偶数=SELL
            ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, clrRed);
            ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrWhite);
        }
        ObjectSetString(0, btnName, OBJPROP_TEXT, "M" + IntegerToString(magicNum) + ":" + customName);
    } else {
        ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, clrGray);
        ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrWhite);
        ObjectSetString(0, btnName, OBJPROP_TEXT, "M" + IntegerToString(magicNum) + ":OFF");
    }
    
    ObjectSetInteger(0, btnName, OBJPROP_STATE, false);
    ChartRedraw(0);
}

void CreateEntryStateLabel()
{
    if(ObjectFind(0, LAB_ENTRY_STATE) == -1) {
        if(!ObjectCreate(0, LAB_ENTRY_STATE, OBJ_LABEL, 0, 0, 0)) { 
            Print("❌ Entry state label create error: ", GetLastError()); 
            return; 
        }
        ObjectSetInteger(0, LAB_ENTRY_STATE, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, LAB_ENTRY_STATE, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, LAB_ENTRY_STATE, OBJPROP_FONTSIZE, 10);
        ObjectSetInteger(0, LAB_ENTRY_STATE, OBJPROP_COLOR, clrYellow);
        ObjectSetString(0, LAB_ENTRY_STATE, OBJPROP_TEXT, "Entry Status: Initializing...");
        Print("✅ Entry state label created");
    }
}

//+------------------------------------------------------------------+
//| BEP（損益分岐点）ライン更新
//+------------------------------------------------------------------+
void UpdateBEP_Line(int magic, double bePrice, bool hasPosition)
{
    string name = "BEP_LINE_" + IntegerToString(magic);
    if(!hasPosition) { 
        if(ObjectFind(0,name) >= 0) ObjectDelete(0,name); 
        return; 
    }
    if(ObjectFind(0,name) < 0) ObjectCreate(0, name, OBJ_HLINE, 0, Time[0], bePrice);
    ObjectSetDouble (0, name, OBJPROP_PRICE, bePrice);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
}

//+------------------------------------------------------------------+
//| UI削除関数群
//+------------------------------------------------------------------+
void DeleteManualButtons()
{
    for(int i = ArraySize(BTN_LIST) - 1; i >= 0; i--) {
        if(ObjectFind(0, BTN_LIST[i]) >= 0) ObjectDelete(0, BTN_LIST[i]);
    }
    Print("🗑️ Manual buttons deleted");
}

void DeleteMagicSwitches()
{
    for(int i = 0; i < 10; i++) {
        if(ObjectFind(0, SWITCH_BTN_LIST[i]) >= 0) ObjectDelete(0, SWITCH_BTN_LIST[i]);
    }
    Print("🗑️ Magic switch buttons deleted");
}

void DeleteAllUIElements()
{
    DeleteManualButtons();
    DeleteMagicSwitches();
    ObjectDelete(0, LAB_ENTRY_STATE);
    ObjectsDeleteAll(0, "BEP_LINE_");
}

//+------------------------------------------------------------------+
//| Magic ON/OFF状態取得
//+------------------------------------------------------------------+
bool IsMagicEnabled(int magicNumber, int magicOffset = 0)
{
    int baseMagic = magicNumber - magicOffset;

    if(baseMagic < 11 || baseMagic > 20) {
        Print("⚠️ IsMagicEnabled: Magic ", magicNumber, " is outside M11-M20 range");
        return true; // M11-M20以外は常に有効
    }
    
    int switchIndex = baseMagic - 11;
    
    if (switchIndex < 0 || switchIndex >= 10) {
        Print("❌ IsMagicEnabled Error: Invalid switch index '", switchIndex, "' for magic ", magicNumber, " (offset:", magicOffset, ")");
        return false;
    }
    
    Print("🔍 Debug: Magic", magicNumber, " -> baseMagic", baseMagic, " -> switchIndex", switchIndex, " -> state", MagicSwitch[switchIndex]);
    return MagicSwitch[switchIndex];
}
//+------------------------------------------------------------------+
//| ★★★ 強制ナンピンフラグ管理（NanpinManagerとの連携用） ★★★
//+------------------------------------------------------------------+

// ★★★ これらの関数は削除されました（NanpinManagerに移植済み）
// bool GetAndResetForceNanpinBuy() { ... }    // ← 削除
// bool GetAndResetForceNanpinSell() { ... }   // ← 削除

// ★★★ 新しいインターフェース：NanpinManagerとの連携
#include "NanpinManager.mqh"  // ナンピンマネージャーへの参照

// 強制ナンピン設定（ボタンクリック時に呼び出し）
void UI_SetForceNanpinBuy() 
{
    // ★★★ NanpinManagerの関数を呼び出し
    NanpinManager_SetForceBuy();
    Print("🎮 UI: Force Nanpin BUY set via NanpinManager");
}

void UI_SetForceNanpinSell() 
{
    // ★★★ NanpinManagerの関数を呼び出し
    NanpinManager_SetForceSell();
    Print("🎮 UI: Force Nanpin SELL set via NanpinManager");
}

//+------------------------------------------------------------------+
//| Magic名称管理
//+------------------------------------------------------------------+
void SetMagicCustomNames()
{
    MAGIC_CUSTOM_NAMES[0] = "24HBUY";     // Magic 11
    MAGIC_CUSTOM_NAMES[1] = "24HSELL";    // Magic 12
    MAGIC_CUSTOM_NAMES[2] = "BUY";        // Magic 13
    MAGIC_CUSTOM_NAMES[3] = "SELL";       // Magic 14
    MAGIC_CUSTOM_NAMES[4] = "BUY";        // Magic 15
    MAGIC_CUSTOM_NAMES[5] = "SELL";       // Magic 16
    MAGIC_CUSTOM_NAMES[6] = "BUY";        // Magic 17
    MAGIC_CUSTOM_NAMES[7] = "SELL";       // Magic 18
    MAGIC_CUSTOM_NAMES[8] = "BUY";        // Magic 19
    MAGIC_CUSTOM_NAMES[9] = "SELL";       // Magic 20
}

string GetMagicCustomName(int magicNumber)
{
    if(magicNumber < 11 || magicNumber > 20) return "";
    
    int index = magicNumber - 11;
    return MAGIC_CUSTOM_NAMES[index];
}

//+------------------------------------------------------------------+
//| UI初期化・終了処理
//+------------------------------------------------------------------+
void InitUIManager()
{
    Print("🎨 Initializing UI Manager...");
    
    SetMagicCustomNames();
    CreateManualButtons();
    CreateMagicSwitches(); 
    CreateEntryStateLabel();
    
    Print("✅ UI Manager initialized successfully.");
}

void DeinitUIManager()
{
    DeleteAllUIElements();
    Print("🎨 UI Manager deinitialized.");
}

//+------------------------------------------------------------------+
//| UIテスト関数（デバッグ用）
//+------------------------------------------------------------------+
void TestUICreation()
{
    Print("🧪 Testing UI creation...");
    
    // 手動ボタンの存在確認
    for(int i = 0; i < ArraySize(BTN_LIST); i++) {
        bool exists = (ObjectFind(0, BTN_LIST[i]) >= 0);
        Print("Manual Button ", BTN_LIST[i], ": ", (exists ? "✅ EXISTS" : "❌ MISSING"));
    }
    
    // スイッチボタンの存在確認
    for(int i = 0; i < 10; i++) {
        bool exists = (ObjectFind(0, SWITCH_BTN_LIST[i]) >= 0);
        Print("Switch Button ", SWITCH_BTN_LIST[i], ": ", (exists ? "✅ EXISTS" : "❌ MISSING"));
    }
    
    // エントリーラベルの存在確認
    bool labelExists = (ObjectFind(0, LAB_ENTRY_STATE) >= 0);
    Print("Entry Label: ", (labelExists ? "✅ EXISTS" : "❌ MISSING"));
}

//+------------------------------------------------------------------+
//| Magic状態監視・表示機能
//+------------------------------------------------------------------+
void UpdateMagicStatusDisplay()
{
    static datetime lastUpdateTime = 0;
    
    // 5秒毎に更新
    if(TimeCurrent() - lastUpdateTime < 5) return;
    lastUpdateTime = TimeCurrent();
    
    string statusText = "Magic Status: ";
    int activeCount = 0;
    
    for(int i = 0; i < 10; i++) {
        if(MagicSwitch[i]) {
            activeCount++;
            if(activeCount > 1) statusText += ", ";
            statusText += "M" + IntegerToString(11 + i);
        }
    }
    
    if(activeCount == 0) {
        statusText += "All OFF";
    } else {
        statusText += " (" + IntegerToString(activeCount) + " active)";
    }
    
    if(ObjectFind(0, LAB_ENTRY_STATE) >= 0) {
        ObjectSetString(0, LAB_ENTRY_STATE, OBJPROP_TEXT, statusText);
    }
}

//+------------------------------------------------------------------+
//| デバッグ情報表示
//+------------------------------------------------------------------+
void PrintUIManagerStatus()
{
    Print("=== UI Manager Status ===");
    Print("Manual Trading Buttons:");
    for(int i = 0; i < ArraySize(BTN_LIST); i++) {
        bool exists = (ObjectFind(0, BTN_LIST[i]) >= 0);
        Print("  ", BTN_LIST[i], ": ", (exists ? "ACTIVE" : "MISSING"));
    }
    
    Print("Magic Switch Buttons:");
    for(int i = 0; i < 10; i++) {
        bool exists = (ObjectFind(0, SWITCH_BTN_LIST[i]) >= 0);
        bool enabled = MagicSwitch[i];
        string status = "";
        if(!exists) status = "MISSING";
        else if(enabled) status = "ON";
        else status = "OFF";
        
        Print("  Magic ", (11 + i), ": ", status);
    }
    
    Print("Entry State Label: ", (ObjectFind(0, LAB_ENTRY_STATE) >= 0 ? "ACTIVE" : "MISSING"));
    Print("========================");
}

//+------------------------------------------------------------------+
//| 統合状態レポート
//+------------------------------------------------------------------+
void PrintUIIntegrationReport()
{
    Print("=== UI Integration Report ===");
    
    // UI要素の存在確認
    int totalButtons = ArraySize(BTN_LIST) + ArraySize(SWITCH_BTN_LIST);
    int activeButtons = 0;
    
    for(int i = 0; i < ArraySize(BTN_LIST); i++) {
        if(ObjectFind(0, BTN_LIST[i]) >= 0) activeButtons++;
    }
    
    for(int i = 0; i < ArraySize(SWITCH_BTN_LIST); i++) {
        if(ObjectFind(0, SWITCH_BTN_LIST[i]) >= 0) activeButtons++;
    }
    
    Print("Button Status: ", activeButtons, "/", totalButtons, " active");
    
    // Magic状態確認
    int enabledMagics = 0;
    for(int i = 0; i < 10; i++) {
        if(MagicSwitch[i]) enabledMagics++;
    }
    
    Print("Enabled Magics: ", enabledMagics, "/10");
    
    // ナンピンマネージャーとの連携確認
    Print("NanpinManager Integration: ✅ Connected");
    
    // 総合評価
    bool uiHealthy = (activeButtons == totalButtons) && (ObjectFind(0, LAB_ENTRY_STATE) >= 0);
    Print("Overall UI Health: ", (uiHealthy ? "✅ HEALTHY" : "❌ ISSUES DETECTED"));
    
    Print("==============================");
}