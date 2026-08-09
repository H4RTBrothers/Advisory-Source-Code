//+------------------------------------------------------------------+
//|                                         EuroScalperHedge.mq5      |
//|                                         Copyright 2024            |
//+------------------------------------------------------------------+
#property copyright "Euro Scalper with Hedge"
#property link      ""
#property version   "5.40"
#property strict

#include <Trade\Trade.mqh>

enum ENUM_ATR_MULT_START
{
   ATR_MULT_1_0 = 10,  // 1.0x
   ATR_MULT_1_5 = 15,  // 1.5x
   ATR_MULT_2_0 = 20,  // 2.0x
   ATR_MULT_2_5 = 25,  // 2.5x
   ATR_MULT_3_0 = 30   // 3.0x
};

enum ENUM_ATR_MULT_CLOSE
{
   ATR_CLOSE_1_5 = 15, // 1.5x
   ATR_CLOSE_2_0 = 20, // 2.0x
   ATR_CLOSE_2_5 = 25, // 2.5x
   ATR_CLOSE_3_0 = 30, // 3.0x
   ATR_CLOSE_4_0 = 40, // 4.0x
   ATR_CLOSE_5_0 = 50  // 5.0x
};

input group "=== General Settings ==="
input string          Minimal_Deposit      = "$200";
input string          Time_Frame           = "Time Frame M1";
input string          Pairs                = "EurUsd";
input int             MagicNumber         = 1111111;
input bool            Use_MultiPair        = true;     // Enable Multi-Pair Dashboard
input string          MultiPairs           = "BTCUSDm,EURUSDm,XAUUSDm"; // Pairs: comma-separated

input group "=== Lot Settings ==="
input bool            Use_Fixed_Lot       = false;
input double          Lot                  = 0.01;
input double          LotMultiplikator    = 1.21;
input int             LotMode             = 1;  // 0=Fixed, 1=Multiplier, 2=Recovery

input group "=== Trade Settings ==="
input double          TakeProfit          = 300;
input double          Step                = 21.0;
input double          Averaging           = 1.0;
input int             MaxTrades           = 31;
input int             MinTradeDelaySec    = 60;       // Min seconds between trades

input group "=== TP Multiplier ==="
input bool            Use_TP_Multiplier   = true;    // Use TP Multiplier
input double          TP_Multiplier       = 1.21;      // TP Multiplier per averaging level
input int             TP_Max_Level        = 300;       // Max averaging level for TP calc
input bool            Use_SeparateTP      = true;     // Show separate TP per side when hedged

input group "=== Hidden TP & Daily Target ==="
input bool            Use_Daily_Target    = false;
input double          Daily_Target        = 100;
input bool            Hidden_TP           = false;
input double          Hiden_TP            = 500;

input group "=== Equity Protection ==="
input bool            UseEquityStop       = false;
input double          TotalEquityRisk     = 20;

input group "=== Time Filter ==="
input int             Open_Hour           = 0;
input int             Close_Hour          = 24;
input bool            TradeOnThursday     = true;
input int             Thursday_Hour       = 24;
input bool            TradeOnFriday       = true;
input int             Friday_Hour         = 24;

input group "=== Sideway Filter ==="
input bool            Filter_Sideway      = true;
input bool            invisible_mode      = true;
input double          OpenRangePips       = 1;
input double          MaxDailyRange       = 20000;
input bool            UseVolatilityFilter = true;
input int             ATR_Period          = 14;
input double          ATR_Multiplier      = 2.0;
input bool            UseRangeFilter      = true;
input double          RangeMinPips        = 10;
input double          RangeMaxPips        = 200;

input group "------======<<[  News Management  ]>>======------ "
input bool            Filter_News         = true;     // Enable News Filter
input string          info1               = " "; //---=== News Settings ===---
input string          news_link           = "https://nfs.faireconomy.media/"; //--- News URL
input int             min_before          = 5;    // Minutes Before News to close
input int             min_before_zero     = 60;   // Minutes Before News to close with zero profit
input int             min_after           = 45;   // Minutes After News to halt
input bool            include_high        = true;     // Include high impact
input bool            include_medium      = false;    // Include medium impact
input bool            include_low         = false;    // Include low impact
input bool            use_title           = true;     // Filter News based on title
input string          title_phrase        = "Non-Farm,Unemployment,ISM,PMI,CPI,FOMC,Retail Sales,Final GDP q/q,Core PCE Price Index m/m,Empire State Manufacturing Index,Advance GDP q/q,JOLTS"; // Title keywords (comma separated)
input int             news_update_hour    = 2;    // Update time interval (in hours)
input int             symbol_type         = 0;    // 0=Use chart symbol, 1=Custom currencies
input string          news_symbols        = "USD,EUR,GBP,JPY,CAD,CHF"; // Custom Currencies
input bool            close_only_news_pair = false; // Only close orders of the event currency
input bool            draw_news_lines     = true;     // Draw News Lines on chart
input color           Line_Color          = clrRed;   // Lines Color
input ENUM_LINE_STYLE Line_Style          = STYLE_DOT;// Lines Style
input int             Line_Width          = 1;        // Line Width

input group "------======<<[  Order Management  ]>>======------ "
input string          info2               = " "; //---=== Order Management ===---
input bool            stop_algo           = true;     // Stop Auto trading during news
input bool            close_open          = true;     // Close all open trades
input bool            close_pending       = true;     // Delete all Pending orders
input bool            close_zero          = false;    // Close all trades with profit
input double          close_profit        = 1;        // Profit for closing all trades (in $)
input bool            close_charts        = false;    // Close all Charts

input group "------======<<[  Settings  ]>>======------ "
input string          info3               = " "; //---=== Settings ===---
input bool            send_notif          = true;     // Send notification
input bool            send_alert          = true;     // Send Alert
input int             delay               = 5;        // Delay if something goes wrong (in seconds)

input group "=== HEDGE SETTINGS ==="
input bool            Use_Hedging         = true;
input double          HedgeDistancePips   = 30;
input double          HedgeLotMultiplier  = 1.21;
input double          HedgeProfitTarget   = 300.0;
input int             MaxHedgeCount       = 3;
input double          HedgeStepPips       = 30;
input bool            Use_Hedge_TP        = true;
input double          HedgeTakeProfit     = 300.0;

input group "=== TRAILING STOP SETTINGS ==="
input bool            Use_Trailing_Stop   = false;
input int             TrailingMode        = 0;         // 0=Fixed Pips, 1=ATR Based
input double          TrailingStartPips   = 20;
input double          TrailingStepPips    = 5;
input double          TrailingDistancePips = 15;
input int             Trail_ATR_Period     = 14;        // Trail ATR Period
input double          Trail_ATR_Multiplier = 1.5;       // Trail ATR Multiplier for distance
input ENUM_TIMEFRAMES Trail_ATR_Timeframe  = PERIOD_H1; // Trail ATR Timeframe
input bool            Use_Breakeven       = false;
input double          BreakevenStartPips  = 15;
input double          BreakevenProfitPips = 5;

input group "=== SMART TRAIL SETTINGS ==="
input bool            Use_SmartTrail      = false;      // Enable Smart Trail
input bool            SmartTrail_BreakEven = true;      // Stage 2: Break-even
input double          SmartTrail_BE_R     = 0.8;        // Break-even at +X R
input double          SmartTrail_BE_Buffer = 5;         // BE buffer in points
input bool            SmartTrail_ProfitLock = true;     // Stage 3: Profit lock
input double          SmartTrail_PL_R     = 1.2;        // Profit lock activates at +X R
input double          SmartTrail_Locked_R = 0.4;        // Locked profit in R
input bool            SmartTrail_ATR      = true;       // Stage 4: ATR trailing
input int             SmartTrail_ATR_Period = 14;       // ATR period
input double          SmartTrail_ATR_Normal = 2.0;      // Normal trend ATR multiplier
input double          SmartTrail_ATR_Strong = 2.5;      // Strong trend ATR multiplier
input double          SmartTrail_ATR_Weak = 1.3;        // Weak trend ATR multiplier
input bool            SmartTrail_Structure = true;      // Stage 7: Structure trail
input int             SmartTrail_SwingLookback = 10;    // Swing lookback bars
input double          SmartTrail_StructureBuf = 5;      // Structure buffer points
input bool            SmartTrail_Chandelier = true;     // Stage 8: Extreme profit
input double          SmartTrail_ChandelierR = 2.5;     // Chandelier ATR multiplier
input double          SmartTrail_MinStep  = 10;         // Minimum trail step points
input int             SmartTrail_ADX_Period = 14;       // ADX period for trend strength
input double          SmartTrail_ADX_Strong = 25;       // ADX threshold for strong trend
input double          SmartTrail_ADX_Weak = 20;         // ADX threshold for weak trend

input group "=== PRICE % TRAIL SETTINGS ==="
input bool            Use_PctTrail          = true;     // Enable Price % Trail
input double          PctTrail_ActivateR    = 0.8;      // Activate trail at +X R
input double          PctTrail_Trail_Normal = 0.30;     // Normal market trail %
input double          PctTrail_Trail_Strong = 0.45;     // Strong trend trail %
input double          PctTrail_Trail_Choppy = 0.15;     // Choppy market trail %
input double          PctTrail_ADX_Strong   = 25;       // ADX > = strong trend
input double          PctTrail_ADX_Choppy   = 20;       // ADX < = choppy
input double          PctTrail_Lock_R1      = 1.0;      // Profit lock tier 1 R
input double          PctTrail_Lock_P1      = 30;       // Profit lock tier 1 %
input double          PctTrail_Lock_R2      = 1.5;      // Profit lock tier 2 R
input double          PctTrail_Lock_P2      = 50;       // Profit lock tier 2 %
input double          PctTrail_Lock_R3      = 2.0;      // Profit lock tier 3 R
input double          PctTrail_Lock_P3      = 65;       // Profit lock tier 3 %
input double          PctTrail_Lock_R4      = 3.0;      // Profit lock tier 4 R
input double          PctTrail_Lock_P4      = 80;       // Profit lock tier 4 %
input double          PctTrail_MinStep      = 10;       // Min trail step (points)
input int             PctTrail_ADX_Period   = 14;       // ADX period for trend

input group "=== EQUITY ATR TRAIL ==="
input bool                  Use_EquityATRTrail  = false;   // Enable Equity ATR Trail
input ENUM_ATR_MULT_START   EquityATR_StartMult = ATR_MULT_2_0; // Start trail after equity drops ATR × this from peak
input ENUM_ATR_MULT_CLOSE   EquityATR_CloseMult = ATR_CLOSE_3_0; // Close when equity drops ATR × this from peak
input int                   EquityATR_CloseSide = 3;        // 0=All, 1=Buys, 2=Sells, 3=Profitable side
input bool                  EquityATR_CloseOnNewPeak = true; // Close all when equity makes new peak after trail
input ENUM_TIMEFRAMES       EquityATR_Timeframe = PERIOD_H1; // ATR Timeframe for equity trail
input int                   EquityATR_Period    = 14;        // ATR Period for equity trail

input group "=== TIMEFRAME SWITCH ON DRAWDOWN ==="
input bool            Use_DrawdownSwitch  = false;
input double          DD_Low              = 5;        // DD% → switch to Mid TF
input double          DD_High             = 10;       // DD% → switch to High TF
input ENUM_TIMEFRAMES Timeframe_Low       = PERIOD_CURRENT;
input ENUM_TIMEFRAMES Timeframe_Mid       = PERIOD_M5;
input ENUM_TIMEFRAMES Timeframe_High      = PERIOD_M15;
input bool            Auto_Switch_Back    = true;

input group "=== TimeOut Settings ==="
input bool            Use_TimeOut         = false;
input int             TimeOut_Hours       = 48;

input group "=== SMC DASHBOARD ==="
input bool            ShowSMCDashboard    = true;     // Show SMC Dashboard
input int             SMC_Lookback        = 20;       // Bars to analyze
input bool            ShowOrderBlocks     = true;     // Show Order Blocks
input bool            ShowFVG             = true;     // Show Fair Value Gaps
input bool            ShowBOS             = true;     // Show Break of Structure
input bool            ShowLiquidity       = true;     // Show Liquidity Levels
input bool            ShowMarketStructure = true;     // Show Market Structure

input group "=== ICT DASHBOARD ==="
input bool            ShowICTDashboard    = true;     // Show ICT Dashboard
input int             ICT_Lookback        = 50;       // ICT Bars to analyze
input bool            ShowKillZones       = true;     // Show Kill Zone Status
input bool            ShowPremiumDiscount = true;     // Show Premium/Discount Zone
input bool            ShowOTE             = true;     // Show Optimal Trade Entry
input bool            ShowMSS             = true;     // Show Market Structure Shift
input bool            ShowICTOrderBlocks  = true;     // Show ICT Order Blocks
input bool            ShowICTFVG          = true;     // Show ICT Fair Value Gaps
input bool            ShowICTLiquidity    = true;     // Show ICT Liquidity Levels
input bool            ShowLiquiditySweep  = true;     // Show Liquidity Sweep Detection
input bool            ShowDailyBias       = true;     // Show Daily Bias
input bool            ShowDisplacement    = true;     // Show Displacement Detection
input double          OTE_FibHigh         = 0.79;     // OTE Fibonacci High (0.79)
input double          OTE_FibLow          = 0.618;    // OTE Fibonacci Low (0.618)
input double          LiquidityTolerance  = 10;       // Liquidity Tolerance (pips)
input double          DisplacementRatio   = 1.5;      // Displacement Body Ratio

input group "=== ICT CHART DRAWINGS ==="
input bool            DrawICTOnChart      = true;     // Draw ICT Concepts on Chart
input bool            DrawOB_OnChart      = true;     // Draw Order Blocks on Chart
input bool            DrawFVG_OnChart     = true;     // Draw Fair Value Gaps on Chart
input bool            DrawLiq_OnChart     = true;     // Draw Liquidity Levels on Chart
input bool            DrawPDZ_OnChart     = true;     // Draw Premium/Discount Zone
input bool            DrawOTE_OnChart     = true;     // Draw OTE Zone
input bool            DrawKZ_OnChart      = true;     // Draw Kill Zone Lines
input bool            DrawMSS_OnChart     = true;     // Draw MSS/BOS Labels
input color           OB_BullColor        = C'0,100,200';   // Bullish OB Color
input color           OB_BearColor        = C'200,50,50';    // Bearish OB Color
input color           FVG_BullColor       = C'0,150,100';    // Bullish FVG Color
input color           FVG_BearColor       = C'180,60,60';    // Bearish FVG Color
input color           LiqColor            = C'255,200,0';    // Liquidity Line Color
input color           OTE_Color           = C'120,80,200';   // OTE Zone Color
input color           PDZ_PremiumColor    = C'180,50,50';    // Premium Zone Color
input color           PDZ_DiscountColor   = C'50,150,50';    // Discount Zone Color
input color           KZ_LineColor        = C'0,180,220';    // Kill Zone Line Color
input int             ICT_LineWidth       = 1;        // ICT Line Width

//--- News Event Structure
struct NewsEvent
{
   datetime time;
   string   currency;
   string   title;
   string   impact;
};

CTrade trade;

int      g_magic;
double   g_lot;
double   g_lotMultiplier;
double   g_takeProfit;
double   g_step;
double   g_lastBuyPrice;
double   g_lastSellPrice;
int      g_buyCount;
int      g_sellCount;
int      g_totalCount;
bool     g_hasBuy;
bool     g_hasSell;
double   g_avgPrice;
double   g_totalProfit;
bool     g_needModify;
double   g_newTP;
double   g_buyTP;
double   g_sellTP;
double   g_buyAvgPrice;
double   g_sellAvgPrice;
double   g_newSL;
bool     g_canTrade;
datetime g_timeoutTime;
datetime g_lastModifyFailTime;  // Throttle modify retries after failure
datetime g_lastServerFailTime;  // Global throttle for ALL server requests
double   g_initialBalance;
bool     g_firstRun;
int      g_averagingCount;
int      g_buyAveragingCount;
int      g_sellAveragingCount;

// Symbol type detection
bool     g_isCrypto;
double   g_pipMultiplier;
int      g_pointDivider;

// Trailing stop variables
double   g_bestProfit;
datetime g_lastTrailingTime;
datetime g_lastTradeTime;

// Timeframe switch variables
ENUM_TIMEFRAMES g_currentTimeframe;
bool     g_timeframeChanged;
double   g_peakBalance;

// News variables
datetime g_lastNewsUpdate;
NewsEvent g_newsEvents[];
int      g_newsCount;
bool     g_newsActive;
bool     g_newsCloseDone;
string   g_lastNewsAlert;
int      g_atrHandle;
int      g_trailAtrHandle;
int      g_equityAtrHandle;

// Equity ATR trail variables
double   g_peakEquity;
bool     g_equityTrailActive;

// Smart trail variables
int      g_smartTrailAtrHandle;
int      g_smartTrailAdxHandle;

// Manual ATR calculation
double   g_manualATR;
double   g_manualATR_prev;

// Multi-pair variables
#define MAX_PAIRS 10
string   g_pairList[MAX_PAIRS];
int      g_pairCount;
double   g_pairProfit[MAX_PAIRS];
double   g_pairMaxDD[MAX_PAIRS];
double   g_pairPeak[MAX_PAIRS];
int      g_pairBuyCount[MAX_PAIRS];
int      g_pairSellCount[MAX_PAIRS];
double   g_pairLots[MAX_PAIRS];

// Multi-pair trading state
struct PairTradeState
{
   string   symbol;
   CTrade   trade;
   bool     isCrypto;
   int      pointDivider;
   double   pipMultiplier;
   int      atrHandle;
   // Position state
   int      buyCount;
   int      sellCount;
   int      totalCount;
   bool     hasBuy;
   bool     hasSell;
   double   lastBuyPrice;
   double   lastSellPrice;
   double   avgPrice;
   double   buyAvgPrice;
   double   sellAvgPrice;
   double   totalProfit;
   double   buyTP;
   double   sellTP;
   double   newTP;
   bool     needModify;
   int      averagingCount;
   double   lot;
   bool     canTrade;
   datetime lastTradeTime;
   datetime timeoutTime;
   datetime freshBarTime;  // Track fresh bar for multi-pair
};

PairTradeState g_pts[MAX_PAIRS];

// GUI state
bool     g_manualPaused;

//+------------------------------------------------------------------+
int OnInit()
{
   g_magic = MagicNumber;

   Print("INIT START: Use_MultiPair=", Use_MultiPair, " MultiPairs=", MultiPairs,
         " MagicNumber=", MagicNumber, " Lot=", Lot);

   g_lot = Lot;
   g_lotMultiplier = LotMultiplikator;
   g_takeProfit = TakeProfit;
   g_step = Step;
   g_lastBuyPrice = 0;
   g_lastSellPrice = 0;
   g_buyCount = 0;
   g_sellCount = 0;
   g_totalCount = 0;
   g_hasBuy = false;
   g_hasSell = false;
   g_avgPrice = 0;
   g_totalProfit = 0;
   g_needModify = false;
   g_newTP = 0;
   g_buyTP = 0;
   g_sellTP = 0;
   g_buyAvgPrice = 0;
   g_sellAvgPrice = 0;
   g_newSL = 0;
   g_canTrade = false;
   g_timeoutTime = 0;
   g_initialBalance = 0;
   g_firstRun = true;
   g_averagingCount = -2;
   g_buyAveragingCount = 0;
   g_sellAveragingCount = 0;

   // Detect symbol type (crypto vs forex)
   string sym = _Symbol;
   StringToUpper(sym);
   g_isCrypto = (StringFind(sym, "BTC") >= 0 || StringFind(sym, "ETH") >= 0 ||
                 StringFind(sym, "XRP") >= 0 || StringFind(sym, "DOGE") >= 0 ||
                 StringFind(sym, "ADA") >= 0 || StringFind(sym, "SOL") >= 0 ||
                 StringFind(sym, "BNB") >= 0 || StringFind(sym, "LTC") >= 0 ||
                 StringFind(sym, "DASH") >= 0 || StringFind(sym, "XMR") >= 0 ||
                 StringFind(sym, "USDT") >= 0 || StringFind(sym, "CRYPTO") >= 0);

   // Set pip multiplier based on symbol type
   if(g_isCrypto)
   {
      g_pipMultiplier = 1.0;    // Crypto uses points directly
      g_pointDivider = 1;       // No pip conversion
      Print("Symbol detected as CRYPTO: ", _Symbol);
   }
   else
   {
      g_pipMultiplier = 10.0;   // Forex uses pips (10 points = 1 pip)
      g_pointDivider = 10;      // Convert points to pips
      Print("Symbol detected as FOREX: ", _Symbol);
   }

   // Trailing
   g_bestProfit = 0;
   g_lastTrailingTime = 0;
   g_lastTradeTime = 0;

   // Timeframe switch
   g_currentTimeframe = Timeframe_Low;
   g_timeframeChanged = false;
   g_peakBalance = 0;

   // News
   g_lastNewsUpdate = 0;
   g_newsCount = 0;
   g_newsActive = false;
   g_newsCloseDone = false;
   g_lastNewsAlert = "";
   g_atrHandle = INVALID_HANDLE;
   g_manualPaused = false;

   trade.SetExpertMagicNumber(g_magic);
   trade.SetDeviationInPoints(100); // Higher deviation for crypto

   // Detect fill policy from symbol
   long fillPolicy = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((fillPolicy & SYMBOL_FILLING_FOK) != 0)
      trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((fillPolicy & SYMBOL_FILLING_IOC) != 0)
      trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      trade.SetTypeFilling(ORDER_FILLING_RETURN);

   // Initialize ATR - try current timeframe, fallback to M5
   g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
   if(g_atrHandle == INVALID_HANDLE)
   {
      g_atrHandle = iATR(_Symbol, PERIOD_M5, ATR_Period);
      if(g_atrHandle == INVALID_HANDLE)
         Print("ATR INIT FAILED on both PERIOD_CURRENT and PERIOD_M5");
      else
         Print("ATR INIT OK (fallback M5): handle=", g_atrHandle);
   }
   else
      Print("ATR INIT OK: handle=", g_atrHandle);

   // Manual ATR fallback - always works regardless of indicator handles
   g_manualATR = 0;
   g_manualATR_prev = 0;
   CalculateManualATR();
   Print("MANUAL ATR: cur=", DoubleToString(g_manualATR, _Digits),
         " prev=", DoubleToString(g_manualATR_prev, _Digits),
         " point=", DoubleToString(_Point, _Digits));

   // Initialize Trail ATR
   g_trailAtrHandle = iATR(_Symbol, Trail_ATR_Timeframe, Trail_ATR_Period);
   if(g_trailAtrHandle == INVALID_HANDLE)
      Print("TRAIL ATR INIT FAILED");
   else
      Print("TRAIL ATR INIT OK: handle=", g_trailAtrHandle, " tf=", EnumToString(Trail_ATR_Timeframe));
   
   // Initialize Equity ATR Trail
   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_equityTrailActive = false;
   g_equityAtrHandle = iATR(_Symbol, EquityATR_Timeframe, EquityATR_Period);
    if(g_equityAtrHandle == INVALID_HANDLE)
       Print("EQUITY ATR INIT FAILED");
    else
       Print("EQUITY ATR INIT OK: handle=", g_equityAtrHandle, " tf=", EnumToString(EquityATR_Timeframe));

    // Initialize Smart Trail ATR + ADX
    g_smartTrailAtrHandle = iATR(_Symbol, PERIOD_CURRENT, SmartTrail_ATR_Period);
    g_smartTrailAdxHandle = iADX(_Symbol, PERIOD_CURRENT, SmartTrail_ADX_Period);
    if(g_smartTrailAtrHandle == INVALID_HANDLE)
       Print("SMART TRAIL ATR INIT FAILED");
    else
       Print("SMART TRAIL ATR INIT OK: handle=", g_smartTrailAtrHandle);
    if(g_smartTrailAdxHandle == INVALID_HANDLE)
       Print("SMART TRAIL ADX INIT FAILED");
    else
       Print("SMART TRAIL ADX INIT OK: handle=", g_smartTrailAdxHandle);

    // Parse multi-pair list
   g_pairCount = 0;
   if(Use_MultiPair)
   {
      string parts[];
      int count = StringSplit(MultiPairs, ',', parts);
      for(int i = 0; i < count && i < MAX_PAIRS; i++)
      {
         string s = parts[i];
         StringTrimLeft(s);
         StringTrimRight(s);
         if(StringLen(s) > 0)
         {
            // Ensure symbol is in Market Watch
            if(!SymbolSelect(s, true))
            {
               Print("MULTI-PAIR: WARNING - SymbolSelect failed for ", s, " (may not exist)");
               continue;
            }
            if(!SymbolInfoDouble(s, SYMBOL_ASK) && !SymbolInfoDouble(s, SYMBOL_BID))
            {
               Print("MULTI-PAIR: WARNING - No price data for ", s, " (waiting...)");
            }

            g_pairList[g_pairCount] = s;
            g_pairProfit[g_pairCount] = 0;
            g_pairMaxDD[g_pairCount] = 0;
            g_pairPeak[g_pairCount] = 0;
            g_pairBuyCount[g_pairCount] = 0;
            g_pairSellCount[g_pairCount] = 0;
            g_pairLots[g_pairCount] = 0;

            int pi = g_pairCount;
            g_pts[pi].symbol = s;
            g_pts[pi].trade.SetExpertMagicNumber(g_magic);
            g_pts[pi].trade.SetDeviationInPoints(100);
            long fillPolicy = SymbolInfoInteger(s, SYMBOL_FILLING_MODE);
            if((fillPolicy & SYMBOL_FILLING_FOK) != 0)
               g_pts[pi].trade.SetTypeFilling(ORDER_FILLING_FOK);
            else if((fillPolicy & SYMBOL_FILLING_IOC) != 0)
               g_pts[pi].trade.SetTypeFilling(ORDER_FILLING_IOC);
            else
               g_pts[pi].trade.SetTypeFilling(ORDER_FILLING_RETURN);

            string symUpper = s;
            StringToUpper(symUpper);
            g_pts[pi].isCrypto = (StringFind(symUpper, "BTC") >= 0 || StringFind(symUpper, "ETH") >= 0 ||
                           StringFind(symUpper, "XRP") >= 0 || StringFind(symUpper, "DOGE") >= 0 ||
                           StringFind(symUpper, "ADA") >= 0 || StringFind(symUpper, "SOL") >= 0 ||
                           StringFind(symUpper, "BNB") >= 0 || StringFind(symUpper, "LTC") >= 0 ||
                           StringFind(symUpper, "CRYPTO") >= 0);
            if(g_pts[pi].isCrypto)
            {
               g_pts[pi].pipMultiplier = 1.0;
               g_pts[pi].pointDivider = 1;
            }
            else
            {
               g_pts[pi].pipMultiplier = 10.0;
               g_pts[pi].pointDivider = 10;
            }

            g_pts[pi].atrHandle = iATR(s, PERIOD_CURRENT, ATR_Period);
            g_pts[pi].buyCount = 0;
            g_pts[pi].sellCount = 0;
            g_pts[pi].totalCount = 0;
            g_pts[pi].hasBuy = false;
            g_pts[pi].hasSell = false;
            g_pts[pi].lastBuyPrice = 0;
            g_pts[pi].lastSellPrice = 0;
            g_pts[pi].avgPrice = 0;
            g_pts[pi].totalProfit = 0;
            g_pts[pi].buyAvgPrice = 0;
            g_pts[pi].sellAvgPrice = 0;
            g_pts[pi].buyTP = 0;
            g_pts[pi].sellTP = 0;
            g_pts[pi].newTP = 0;
            g_pts[pi].needModify = false;
            g_pts[pi].averagingCount = 0;
            g_pts[pi].lot = Lot;
            g_pts[pi].canTrade = true;
             g_pts[pi].lastTradeTime = 0;
             g_pts[pi].timeoutTime = 0;
             g_pts[pi].freshBarTime = 0;

             double ask = SymbolInfoDouble(s, SYMBOL_ASK);
            double bid = SymbolInfoDouble(s, SYMBOL_BID);
            double pt  = SymbolInfoDouble(s, SYMBOL_POINT);
            int    dg  = (int)SymbolInfoInteger(s, SYMBOL_DIGITS);

            Print("MULTI-PAIR INIT [", g_pairCount, "]: ", s,
                  " crypto=", g_pts[pi].isCrypto,
                  " point=", DoubleToString(pt, dg),
                  " ask=", DoubleToString(ask, dg),
                  " bid=", DoubleToString(bid, dg),
                  " filling=", EnumToString((ENUM_ORDER_TYPE_FILLING)fillPolicy));

            g_pairCount++;
         }
      }
      Print("MULTI-PAIR: Loaded ", g_pairCount, " pairs | magic=", g_magic);
   }

   // Initial news update
   UpdateNewsCalendar();

   // Clean chart appearance
   if(CleanChart)
   {
      // Remove grid
      ChartSetInteger(0, CHART_SHOW_GRID, false);
      // Set candle colors
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, C'0,180,100');
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, C'220,50,50');
      ChartSetInteger(0, CHART_COLOR_CHART_UP, C'0,180,100');
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, C'220,50,50');
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, C'18,18,24');
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, C'160,160,170');
      // Remove volume
      ChartSetInteger(0, CHART_SHOW_VOLUMES, false);
      // Remove period separators
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);
      ChartRedraw(0);
   }

   Print("EA initialized on ", _Symbol, " | Point: ", _Point, " | Digits: ", _Digits, " | magic=", g_magic, " | v5.43-MULTI-DEBUG");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
   if(g_trailAtrHandle != INVALID_HANDLE)
      IndicatorRelease(g_trailAtrHandle);
    if(g_equityAtrHandle != INVALID_HANDLE)
       IndicatorRelease(g_equityAtrHandle);
    if(g_smartTrailAtrHandle != INVALID_HANDLE)
       IndicatorRelease(g_smartTrailAtrHandle);
    if(g_smartTrailAdxHandle != INVALID_HANDLE)
       IndicatorRelease(g_smartTrailAdxHandle);

   // Remove all objects
   ObjectsDeleteAll(0, "NEWS_");
   ObjectsDeleteAll(0, "TRADE_");
   ObjectsDeleteAll(0, "ICT_");
   ObjectsDeleteAll(0, "GUI_BTN_");
   ObjectsDeleteAll(0, "GUI_lbl_");
   ObjectsDeleteAll(0, "GUI_hdr_smc");
   ObjectsDeleteAll(0, "GUI_val_smc");
   ObjectsDeleteAll(0, "GUI_sep_smc");
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
void OnTick()
{
   // Skip everything when market is closed
   double _chkAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double _chkBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(_chkAsk <= 0 || _chkBid <= 0)
      return;

   // Global cooldown after ANY server failure (60 seconds)
   if(g_lastServerFailTime > 0 && TimeCurrent() - g_lastServerFailTime < 60)
      return;

   // Recalculate manual ATR every tick
   CalculateManualATR();

   AnalyzePositions();

   // Periodic status every 60 seconds
   static datetime lastStatus = 0;
   if(TimeCurrent() - lastStatus >= 60)
   {
      lastStatus = TimeCurrent();
      Print("STATUS: pos=", g_totalCount, " buy=", g_buyCount, " sell=", g_sellCount,
            " canTrade=", g_canTrade, " paused=", g_manualPaused,
            " magic=", g_magic, " tf=", EnumToString(g_currentTimeframe),
            " MP=", Use_MultiPair, " pairs=", g_pairCount);
   }

   // Draw TP/SL/Trail lines on chart
   DrawTradeLines();

   // Draw ICT concepts on chart
   if(DrawICTOnChart)
      DrawICTChartObjects();

   // Reset on balance change
   if(g_totalCount == 0 && g_initialBalance != AccountInfoDouble(ACCOUNT_BALANCE))
   {
      g_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_firstRun = true;
      g_peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_newsCloseDone = false;
   }

   if(AccountInfoDouble(ACCOUNT_BALANCE) > g_peakBalance)
      g_peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   // Update news calendar periodically
   if(TimeCurrent() - g_lastNewsUpdate > news_update_hour * 3600)
   {
      UpdateNewsCalendar();
   }

   // Check news status
   CheckNewsStatus();

   // Update news line labels with countdown
   if(draw_news_lines && g_newsCount > 0)
   {
      UpdateNewsLines();
   }

   // NEWS MANAGEMENT - Close positions before news
   if(g_newsActive)
   {
      static datetime lastNewsLog = 0;
      if(TimeCurrent() - lastNewsLog >= 120)
      {
         lastNewsLog = TimeCurrent();
         Print("TRADING BLOCKED BY NEWS FILTER - g_newsActive=true, events=", g_newsCount);
      }
      ManageNewsClose();
      DisplayInfo();
      return; // Skip all trading during news
   }

   // Daily target
   if(Use_Daily_Target && CheckDailyTarget())
   {
      CloseAllPositions();
      Print("Daily target reached!");
      return;
   }

   // Hidden TP
   if(Hidden_TP && g_totalProfit >= Hiden_TP)
   {
      CloseAllPositions();
      Print("Hidden TP reached: ", g_totalProfit);
      return;
   }

   // Equity stop
   if(UseEquityStop && g_totalProfit < 0)
   {
      double risk = MathAbs(g_totalProfit);
      double maxRisk = (TotalEquityRisk / 100.0) * AccountInfoDouble(ACCOUNT_EQUITY);
      if(risk > maxRisk)
      {
         CloseAllPositions();
         Print("Equity stop triggered");
         return;
      }
   }

   // Time out
   if(Use_TimeOut && g_timeoutTime > 0 && TimeCurrent() >= g_timeoutTime)
   {
      CloseAllPositions();
      Print("Timeout closed all");
      return;
   }

    // TRAILING STOP
    if(Use_Trailing_Stop && g_totalCount > 0)
    {
       ManageTrailingStop();
    }

    // SMART TRAIL
    if(Use_SmartTrail && g_totalCount > 0)
    {
       ManageSmartTrail();
    }

    // PRICE % TRAIL
    if(Use_PctTrail && g_totalCount > 0)
    {
       ManagePctTrail();
    }
   
   // EQUITY ATR TRAIL (CLOSE ALL)
   if(Use_EquityATRTrail && g_totalCount > 0)
   {
      ManageEquityATRTrail();
   }

   // TIMEFRAME SWITCH ON DRAWDOWN
   if(Use_DrawdownSwitch)
   {
      ManageTimeframeSwitch();
   }

    // Calculate lot for next trade
    CalculateNextLot();

    // HEDGE LOGIC
    if(Use_Hedging)
    {
       ManageHedge();
    }

    // Modify TP for all positions - only when market is open, throttle after failure
    // Only on new bar to stop TP jumping every tick
    if(g_needModify && g_totalCount > 0)
    {
       static datetime lastTpBar = 0;
       datetime curTpBar = iTime(_Symbol, PERIOD_CURRENT, 0);
       bool tpNewBar = (curTpBar != lastTpBar);
       lastTpBar = curTpBar;

       // Don't retry modifications for 30 seconds after a failure
       if(g_lastModifyFailTime > 0 && TimeCurrent() - g_lastModifyFailTime < 30)
       {
          g_needModify = false;
       }
       else if(tpNewBar)
       {
          double _ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
          double _bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
          if(_ask > 0 && _bid > 0)
          {
             ModifyAllTP();
          }
          g_needModify = false;
       }
    }

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      // === ORIGINAL ALGORITHM: FIRST ENTRY (no positions) ===
      if(g_totalCount == 0)
      {
         if(!g_canTrade)
         {
            static datetime logCanTrade = 0;
            if(TimeCurrent() - logCanTrade >= 120) { logCanTrade = TimeCurrent(); Print("BLOCKED: canTrade=false"); }
            return;
         }
         if(g_manualPaused)
         {
            static datetime logPaused = 0;
            if(TimeCurrent() - logPaused >= 120) { logPaused = TimeCurrent(); Print("BLOCKED: manualPaused=true"); }
            return;
         }
         if(!CheckTimeFilter())
         {
            static datetime logTime = 0;
            if(TimeCurrent() - logTime >= 120) { logTime = TimeCurrent(); Print("BLOCKED: TimeFilter (check trading hours)"); }
            return;
         }
         if(!CheckVolatilityFilter())
        {
           static datetime lastAtrBlockLog = 0;
           if(TimeCurrent() - lastAtrBlockLog >= 60) { lastAtrBlockLog = TimeCurrent(); Print("BLOCKED by Volatility Filter (ATR spike)"); }
           return;
        }
        if(!CheckRangeFilter())
        {
           static datetime lastRangeBlockLog = 0;
           if(TimeCurrent() - lastRangeBlockLog >= 60) { lastRangeBlockLog = TimeCurrent(); Print("BLOCKED by Range Filter (daily range out of bounds)"); }
           return;
        }

        // Minimum delay between ANY trades
        if(TimeCurrent() - g_lastTradeTime < MinTradeDelaySec)
           return;

        // Fresh bar check - log every tick for first few to debug
       if(iVolume(_Symbol, g_currentTimeframe, 0) > 1)
          return;

       double close2 = iClose(_Symbol, g_currentTimeframe, 2);
       double close1 = iClose(_Symbol, g_currentTimeframe, 1);

       Print("SIGNAL CHECK: close[2]=", DoubleToString(close2, _Digits),
             " close[1]=", DoubleToString(close1, _Digits),
             " TF=", EnumToString(g_currentTimeframe),
             " Volume=", iVolume(_Symbol, g_currentTimeframe, 0));

       // ORIGINAL: close[2] > close[1] → BUY, close[2] < close[1] → SELL
       if(close2 > close1)
       {
          g_lot = GetFirstLot();
          Print("TRYING BUY: lot=", DoubleToString(g_lot, 2), " ask=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits));
          if(OpenBuy())
          {
             g_lastTradeTime = TimeCurrent();
             g_timeoutTime = TimeCurrent() + (TimeOut_Hours * 3600);
             g_averagingCount = 0;
             g_buyAveragingCount = 0;
             g_sellAveragingCount = 0;
          }
       }
       else if(close2 < close1)
       {
          g_lot = GetFirstLot();
          Print("TRYING SELL: lot=", DoubleToString(g_lot, 2), " bid=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits));
          if(OpenSell())
          {
             g_lastTradeTime = TimeCurrent();
             g_timeoutTime = TimeCurrent() + (TimeOut_Hours * 3600);
             g_averagingCount = 0;
             g_buyAveragingCount = 0;
             g_sellAveragingCount = 0;
          }
       }
       else
       {
          Print("No signal: close[2] == close[1]");
       }
    }
     else
     {
        // === ORIGINAL ALGORITHM: AVERAGING (has positions) ===
        if(g_totalCount < MaxTrades && !g_manualPaused)
        {
           bool shouldOpen = false;
           int direction = 0; // 0=none, 1=buy averaging, 2=sell averaging

            bool volumeOK = true;
            if(invisible_mode && iVolume(_Symbol, g_currentTimeframe, 0) >= 5)
               volumeOK = false;

            if(volumeOK)
            {
               // Original: check if price moved Step points from LAST order
               // BUY-only: if ask dropped Step points from last buy → open BUY again
               if(g_hasBuy && !g_hasSell)
               {
                  double dist = (g_lastBuyPrice - ask) / _Point;
                  if(dist >= g_step)
                  {
                     shouldOpen = true;
                     direction = 1; // Buy averaging
                  }
               }
               // SELL-only: if bid rose Step points from last sell → open SELL again
               else if(g_hasSell && !g_hasBuy)
               {
                  double dist = (bid - g_lastSellPrice) / _Point;
                  if(dist >= g_step)
                  {
                     shouldOpen = true;
                     direction = 2; // Sell averaging
                  }
               }
               // HEDGED (both buy and sell): run both algorithms independently
               else if(g_hasBuy && g_hasSell)
               {
                  // Check buy side: price dropped from last buy → add buy
                  double distBuy = (g_lastBuyPrice - ask) / _Point;
                  if(distBuy >= g_step && g_buyCount < MaxTrades)
                  {
                     shouldOpen = true;
                     direction = 1; // Buy averaging
                  }
                  // Check sell side: price rose from last sell → add sell
                  double distSell = (bid - g_lastSellPrice) / _Point;
                  if(distSell >= g_step && g_sellCount < MaxTrades)
                  {
                     shouldOpen = true;
                     direction = 2; // Sell averaging
                  }
               }
           }

            bool timeOK = (TimeCurrent() - g_lastTradeTime >= MinTradeDelaySec);

             if(shouldOpen && CheckTimeFilter() && !g_newsActive && timeOK
                && CheckVolatilityFilter() && CheckRangeFilter())
            {
               // Use per-side averaging count for lot multiplier
               if(direction == 1)
               {
                  g_buyAveragingCount++;
                  g_averagingCount = g_buyAveragingCount;
                  g_lot = GetAveragingLot();
                  if(OpenBuy())
                  {
                     g_lastTradeTime = TimeCurrent();
                     Print("AVERAGING BUY #", g_buyAveragingCount, " lot=", DoubleToString(g_lot, 2));
                  }
               }
               else if(direction == 2)
               {
                  g_sellAveragingCount++;
                  g_averagingCount = g_sellAveragingCount;
                  g_lot = GetAveragingLot();
                  if(OpenSell())
                  {
                     g_lastTradeTime = TimeCurrent();
                     Print("AVERAGING SELL #", g_sellAveragingCount, " lot=", DoubleToString(g_lot, 2));
                  }
               }
            }
         }
      }

    // MULTI-PAIR TRADING
    if(Use_MultiPair && g_pairCount > 0)
    {
       ManageMultiPair();
    }

    DisplayInfo();
}

//+------------------------------------------------------------------+
void UpdateNewsCalendar()
{
   // Reset news array
   ArrayResize(g_newsEvents, 0);
   g_newsCount = 0;

   // Correct URL format for Faireconomy media
   string url = news_link;

   // Try different URL formats
   string urls[];
   ArrayResize(urls, 3);
   urls[0] = url + "ff_calendar_thisweek.json";
   urls[1] = url + "ff_calendar_nextweek.json";
   urls[2] = url;

   bool success = false;

   for(int u = 0; u < ArraySize(urls) && !success; u++)
   {
      string currentUrl = urls[u];

      // Web request to fetch news
      char   postData[];
      char   resultData[];
      string resultHeaders;

      ResetLastError();

      int res = WebRequest("GET", currentUrl, NULL, 5000, postData, resultData, resultHeaders);

      if(res == 200)
      {
         string result = CharArrayToString(resultData);
         if(StringLen(result) > 10) // Valid response
         {
            ParseNewsJSON(result);
            success = true;
            Print("News fetched from: ", currentUrl, " (", g_newsCount, " events)");
         }
      }
   }

   if(!success)
   {
      Print("News fetch failed from all URLs. Using manual news times.");
      LoadDefaultNewsTimes();
   }

   // Draw news lines
   if(draw_news_lines && g_newsCount > 0)
   {
      DrawNewsLines();
   }

   g_lastNewsUpdate = TimeCurrent();
}

//+------------------------------------------------------------------+
void LoadDefaultNewsTimes()
{
   // Load common high-impact news times (UTC)
   // These are approximate recurring times for major news events

   MqlDateTime dt;
   TimeCurrent(dt);

   // Define common news times (hour in UTC)
   int newsHours[];
   string newsTitles[];
   string newsCurrencies[];
   string newsImpacts[];

   // Monday - no major news typically
   // Tuesday
   if(dt.day_of_week == 2)
   {
      ArrayResize(newsTitles, 2);
      ArrayResize(newsCurrencies, 2);
      ArrayResize(newsImpacts, 2);
      ArrayResize(newsHours, 2);

      newsTitles[0] = "JOLTS Job Openings";
      newsCurrencies[0] = "USD";
      newsImpacts[0] = "high";
      newsHours[0] = 14; // 10:00 EST = 14:00 UTC

      newsTitles[1] = "CB Consumer Confidence";
      newsCurrencies[1] = "USD";
      newsImpacts[1] = "high";
      newsHours[1] = 14;
   }
   // Wednesday
   else if(dt.day_of_week == 3)
   {
      ArrayResize(newsTitles, 2);
      ArrayResize(newsCurrencies, 2);
      ArrayResize(newsImpacts, 2);
      ArrayResize(newsHours, 2);

      newsTitles[0] = "ADP Non-Farm Employment";
      newsCurrencies[0] = "USD";
      newsImpacts[0] = "high";
      newsHours[0] = 12; // 08:00 EST = 12:00 UTC

      newsTitles[1] = "FOMC Statement";
      newsCurrencies[1] = "USD";
      newsImpacts[1] = "high";
      newsHours[1] = 18; // 14:00 EST = 18:00 UTC
   }
   // Thursday
   else if(dt.day_of_week == 4)
   {
      ArrayResize(newsTitles, 2);
      ArrayResize(newsCurrencies, 2);
      ArrayResize(newsImpacts, 2);
      ArrayResize(newsHours, 2);

      newsTitles[0] = "Unemployment Claims";
      newsCurrencies[0] = "USD";
      newsImpacts[0] = "high";
      newsHours[0] = 12; // 08:00 EST = 12:00 UTC

      newsTitles[1] = "Core PCE Price Index";
      newsCurrencies[1] = "USD";
      newsImpacts[1] = "high";
      newsHours[1] = 12;
   }
   // Friday - NFP day (first Friday of month)
   else if(dt.day_of_week == 5)
   {
      ArrayResize(newsTitles, 2);
      ArrayResize(newsCurrencies, 2);
      ArrayResize(newsImpacts, 2);
      ArrayResize(newsHours, 2);

      newsTitles[0] = "Non-Farm Payrolls";
      newsCurrencies[0] = "USD";
      newsImpacts[0] = "high";
      newsHours[0] = 12; // 08:00 EST = 12:00 UTC

      newsTitles[1] = "Unemployment Rate";
      newsCurrencies[1] = "USD";
      newsImpacts[1] = "high";
      newsHours[1] = 12;
   }
   else
   {
      // No default news for other days
      return;
   }

   // Create news events for today
   datetime dayStart = iTime(_Symbol, PERIOD_D1, 0);

   for(int i = 0; i < ArraySize(newsTitles); i++)
   {
      datetime eventTime = dayStart + newsHours[i] * 3600;

      // Only add future events
      if(eventTime > TimeCurrent())
      {
         g_newsCount++;
         ArrayResize(g_newsEvents, g_newsCount);
         g_newsEvents[g_newsCount-1].time = eventTime;
         g_newsEvents[g_newsCount-1].currency = newsCurrencies[i];
         g_newsEvents[g_newsCount-1].impact = newsImpacts[i];
         g_newsEvents[g_newsCount-1].title = newsTitles[i];
      }
   }
}

//+------------------------------------------------------------------+
void ParseNewsJSON(string json)
{
   // Simple JSON parser for news events
   // Format: [{"date":"...","time":"...","currency":"...","impact":"...","title":"..."},...]

   int pos = 0;
   int len = StringLen(json);

   while(pos < len)
   {
      // Find next event object
      int objStart = StringFind(json, "{", pos);
      if(objStart == -1) break;

      int objEnd = StringFind(json, "}", objStart);
      if(objEnd == -1) break;

      string eventStr = StringSubstr(json, objStart, objEnd - objStart + 1);

      // Parse fields
      string timeStr = ExtractJSONValue(eventStr, "date") + " " + ExtractJSONValue(eventStr, "time");
      string currency = ExtractJSONValue(eventStr, "currency");
      string impact = ExtractJSONValue(eventStr, "impact");
      string title = ExtractJSONValue(eventStr, "title");

      // Convert time
      datetime eventTime = ParseDateTime(timeStr);

      if(eventTime > 0)
      {
         // Add to array
         g_newsCount++;
         ArrayResize(g_newsEvents, g_newsCount);
         g_newsEvents[g_newsCount-1].time = eventTime;
         g_newsEvents[g_newsCount-1].currency = currency;
         g_newsEvents[g_newsCount-1].impact = impact;
         g_newsEvents[g_newsCount-1].title = title;
      }

      pos = objEnd + 1;
   }
}

//+------------------------------------------------------------------+
string ExtractJSONValue(string json, string key)
{
   string searchKey = "\"" + key + "\"";
   int keyPos = StringFind(json, searchKey);
   if(keyPos == -1) return "";

   int colonPos = StringFind(json, ":", keyPos);
   if(colonPos == -1) return "";

   int valueStart = StringFind(json, "\"", colonPos);
   if(valueStart == -1) return "";

   int valueEnd = StringFind(json, "\"", valueStart + 1);
   if(valueEnd == -1) return "";

   return StringSubstr(json, valueStart + 1, valueEnd - valueStart - 1);
}

//+------------------------------------------------------------------+
datetime ParseDateTime(string dtStr)
{
   // Parse "YYYY-MM-DD HH:MM" format
   if(StringLen(dtStr) < 16) return 0;

   int year = (int)StringToInteger(StringSubstr(dtStr, 0, 4));
   int mon  = (int)StringToInteger(StringSubstr(dtStr, 5, 2));
   int day  = (int)StringToInteger(StringSubstr(dtStr, 8, 2));
   int hour = (int)StringToInteger(StringSubstr(dtStr, 11, 2));
   int min  = (int)StringToInteger(StringSubstr(dtStr, 14, 2));

   if(year < 2000 || mon < 1 || mon > 12 || day < 1 || day > 31) return 0;

   return StringToTime(IntegerToString(year) + "." + IntegerToString(mon) + "." + IntegerToString(day) + " " + IntegerToString(hour) + ":" + IntegerToString(min));
}

//+------------------------------------------------------------------+
void CheckNewsStatus()
{
   g_newsActive = false;

   if(!Filter_News) return;

   datetime now = TimeCurrent();

   for(int i = 0; i < g_newsCount; i++)
   {
      datetime eventTime = g_newsEvents[i].time;
      string currency = g_newsEvents[i].currency;
      string impact = g_newsEvents[i].impact;
      string title = g_newsEvents[i].title;

      // Check impact level
      if(impact == "high" && !include_high) continue;
      if(impact == "medium" && !include_medium) continue;
      if(impact == "low" && !include_low) continue;

      // Check currency filter
      if(!CheckCurrencyFilter(currency)) continue;

      // Check title filter
      if(use_title && !CheckTitleFilter(title)) continue;

      // Check time windows
      int secondsUntil = (int)(eventTime - now);
      int secondsAfter = (int)(now - eventTime);

      // Before news - close with zero profit
      if(secondsUntil > 0 && secondsUntil <= min_before_zero * 60)
      {
         g_newsActive = true;
         if(secondsUntil <= min_before * 60 && !g_newsCloseDone)
         {
            SendNewsAlert("News in " + IntegerToString(secondsUntil/60) + " min: " + title);
         }
      }

      // After news - halt trading
      if(secondsAfter >= 0 && secondsAfter <= min_after * 60)
      {
         g_newsActive = true;
      }
   }
}

//+------------------------------------------------------------------+
bool CheckCurrencyFilter(string newsCurrency)
{
   if(symbol_type == 0) // Use chart symbol
   {
      string symbolUpper = _Symbol;
      StringToUpper(symbolUpper);
      return (StringFind(symbolUpper, newsCurrency) >= 0);
   }
   else // Custom currencies
   {
      return (StringFind(news_symbols, newsCurrency) >= 0);
   }
}

//+------------------------------------------------------------------+
bool CheckTitleFilter(string title)
{
   if(!use_title) return true;
   if(title_phrase == "") return true;

   string titleUpper = title;
   StringToUpper(titleUpper);

   // Parse comma-separated keywords
   string keywords[];
   int count = StringSplit(title_phrase, ',', keywords);

   for(int i = 0; i < count; i++)
   {
      string kw = keywords[i];
      StringTrimLeft(kw);
      StringTrimRight(kw);
      StringToUpper(kw);

      if(StringFind(titleUpper, kw) >= 0)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
void ManageNewsClose()
{
   if(!g_newsActive) return;

   datetime now = TimeCurrent();

   for(int i = 0; i < g_newsCount; i++)
   {
      datetime eventTime = g_newsEvents[i].time;
      string title = g_newsEvents[i].title;

      int secondsUntil = (int)(eventTime - now);

      // Close positions before news
      if(secondsUntil > 0 && secondsUntil <= min_before * 60 && !g_newsCloseDone)
      {
         if(close_open)
         {
            CloseAllPositions();
            Print("Closed all positions before news: ", title);
         }

         if(close_pending)
         {
            DeleteAllPendingOrders();
            Print("Deleted all pending orders before news");
         }

         g_newsCloseDone = true;
      }

      // Close with zero profit (closer to news)
      if(secondsUntil > 0 && secondsUntil <= min_before_zero * 60 && close_zero)
      {
         CloseProfitablePositions();
      }
   }
}

//+------------------------------------------------------------------+
void CloseProfitablePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

      if(close_only_news_pair)
      {
         // Only close if position currency matches news
         string posSymbol = PositionGetString(POSITION_SYMBOL);
         // Check if any news currency matches
         bool matchFound = false;
         for(int j = 0; j < g_newsCount; j++)
         {
            if(StringFind(posSymbol, g_newsEvents[j].currency) >= 0)
            {
               matchFound = true;
               break;
            }
         }
         if(!matchFound) continue;
      }

      if(profit >= close_profit)
      {
         trade.PositionClose(ticket);
         Print("Closed profitable position before news: ", profit);
         Sleep(delay * 1000);
      }
   }
}

//+------------------------------------------------------------------+
void DeleteAllPendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if(OrderGetInteger(ORDER_MAGIC) != g_magic) continue;

      trade.OrderDelete(ticket);
      Sleep(100);
   }
}

//+------------------------------------------------------------------+
void SendNewsAlert(string message)
{
   if(message == g_lastNewsAlert) return;
   g_lastNewsAlert = message;

   if(send_alert)
      Alert(message);

   if(send_notif)
      SendNotification(message);

   Print(message);
}

//+------------------------------------------------------------------+
color GetImpactColor(string impact)
{
   if(impact == "high")   return clrRed;
   if(impact == "medium") return clrOrange;
   if(impact == "low")    return clrGold;
   return Line_Color;
}

//+------------------------------------------------------------------+
void DrawNewsLines()
{
   ObjectsDeleteAll(0, "NEWS_");

   if(!draw_news_lines) return;

   datetime now = TimeCurrent();
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double high = iHigh(_Symbol, PERIOD_CURRENT, 0);
   double low = iLow(_Symbol, PERIOD_CURRENT, 0);

   int drawn = 0;

   for(int i = 0; i < g_newsCount && drawn < 20; i++)
   {
      datetime eventTime = g_newsEvents[i].time;
      string impact = g_newsEvents[i].impact;
      string title = g_newsEvents[i].title;
      string currency = g_newsEvents[i].currency;

      if(eventTime <= now) continue;

      if(impact == "high" && !include_high) continue;
      if(impact == "medium" && !include_medium) continue;
      if(impact == "low" && !include_low) continue;

      color lineClr = GetImpactColor(impact);

      // Time until news
      int minsUntil = (int)((eventTime - now) / 60);
      string timeStr;
      if(minsUntil >= 60)
         timeStr = IntegerToString(minsUntil/60) + "h" + IntegerToString(minsUntil%60) + "m";
      else
         timeStr = IntegerToString(minsUntil) + "m";

      string prefix = "NEWS_" + IntegerToString(i) + "_";

      // === VERTICAL LINE ===
      string lineName = prefix + "VLINE";
      ObjectCreate(0, lineName, OBJ_VLINE, 0, eventTime, 0);
      ObjectSetInteger(0, lineName, OBJPROP_COLOR, lineClr);
      ObjectSetInteger(0, lineName, OBJPROP_STYLE, Line_Style);
      ObjectSetInteger(0, lineName, OBJPROP_WIDTH, Line_Width + 1);
      ObjectSetInteger(0, lineName, OBJPROP_BACK, true);
      ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, lineName, OBJPROP_HIDDEN, true);

      // === PRE-NEWS ZONE (before_close to event) ===
      string zoneName = prefix + "ZONE";
      datetime zoneStart = eventTime - min_before_zero * 60;
      datetime zoneEnd = eventTime;

      // Draw rectangle zone
      ObjectCreate(0, zoneName, OBJ_RECTANGLE, 0, zoneStart, high * 1.001, zoneEnd, low * 0.999);
      ObjectSetInteger(0, zoneName, OBJPROP_COLOR, lineClr);
      ObjectSetInteger(0, zoneName, OBJPROP_FILL, true);
      ObjectSetInteger(0, zoneName, OBJPROP_BACK, true);
      ObjectSetInteger(0, zoneName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, zoneName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, zoneName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, zoneName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, zoneName, OBJPROP_BGCOLOR, lineClr);

      // === TOP LABEL (Time + Impact) ===
      string topLabel = prefix + "TOP";
      string impactUpper = impact;
      StringToUpper(impactUpper);
      string topText = timeStr + " | " + impactUpper + " | " + currency;
      ObjectCreate(0, topLabel, OBJ_TEXT, 0, eventTime, high * 1.002);
      ObjectSetString(0, topLabel, OBJPROP_TEXT, topText);
      ObjectSetInteger(0, topLabel, OBJPROP_COLOR, lineClr);
      ObjectSetInteger(0, topLabel, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, topLabel, OBJPROP_ANCHOR, ANCHOR_CENTER);
      ObjectSetString(0, topLabel, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, topLabel, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, topLabel, OBJPROP_HIDDEN, true);

      // === EVENT TITLE LABEL ===
      string titleLabel = prefix + "TITLE";
      string titleText = title;
      if(StringLen(titleText) > 35)
         titleText = StringSubstr(titleText, 0, 32) + "...";
      ObjectCreate(0, titleLabel, OBJ_TEXT, 0, eventTime, high * 1.004);
      ObjectSetString(0, titleLabel, OBJPROP_TEXT, titleText);
      ObjectSetInteger(0, titleLabel, OBJPROP_COLOR, lineClr);
      ObjectSetInteger(0, titleLabel, OBJPROP_FONTSIZE, 7);
      ObjectSetInteger(0, titleLabel, OBJPROP_ANCHOR, ANCHOR_CENTER);
      ObjectSetInteger(0, titleLabel, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, titleLabel, OBJPROP_HIDDEN, true);

      // === CLOSE ZONE LINE (min_before) ===
      string closeLineName = prefix + "CLOSE";
      datetime closeTime = eventTime - min_before * 60;
      ObjectCreate(0, closeLineName, OBJ_VLINE, 0, closeTime, 0);
      ObjectSetInteger(0, closeLineName, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, closeLineName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, closeLineName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, closeLineName, OBJPROP_BACK, true);
      ObjectSetInteger(0, closeLineName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, closeLineName, OBJPROP_HIDDEN, true);

      // === POST-NEWS ZONE LINE (min_after) ===
      string afterLineName = prefix + "AFTER";
      datetime afterTime = eventTime + min_after * 60;
      ObjectCreate(0, afterLineName, OBJ_VLINE, 0, afterTime, 0);
      ObjectSetInteger(0, afterLineName, OBJPROP_COLOR, clrGray);
      ObjectSetInteger(0, afterLineName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, afterLineName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, afterLineName, OBJPROP_BACK, true);
      ObjectSetInteger(0, afterLineName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, afterLineName, OBJPROP_HIDDEN, true);

      drawn++;
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
void UpdateNewsLines()
{
   datetime now = TimeCurrent();
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double high = iHigh(_Symbol, PERIOD_CURRENT, 0);

   for(int i = 0; i < g_newsCount; i++)
   {
      datetime eventTime = g_newsEvents[i].time;
      string prefix = "NEWS_" + IntegerToString(i) + "_";
      string topLabel = prefix + "TOP";

      if(ObjectFind(0, topLabel) < 0) continue;
      if(eventTime <= now) continue;

      int minsUntil = (int)((eventTime - now) / 60);
      string timeStr;
      if(minsUntil >= 60)
         timeStr = IntegerToString(minsUntil/60) + "h" + IntegerToString(minsUntil%60) + "m";
      else
         timeStr = IntegerToString(minsUntil) + "m";

      string impact = g_newsEvents[i].impact;
      string currency = g_newsEvents[i].currency;

      string impactUp = impact;
      StringToUpper(impactUp);
      string topText = timeStr + " | " + impactUp + " | " + currency;
      ObjectSetString(0, topLabel, OBJPROP_TEXT, topText);
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
void AnalyzePositions()
{
   g_buyCount = 0;
   g_sellCount = 0;
   g_hasBuy = false;
   g_hasSell = false;
   g_lastBuyPrice = 0;
   g_lastSellPrice = 0;
   g_avgPrice = 0;
   g_totalProfit = 0;
   g_needModify = false;
   g_buyTP = 0;
   g_sellTP = 0;
   g_buyAvgPrice = 0;
   g_sellAvgPrice = 0;

   double totalLots = 0;
   double totalPrice = 0;
   double buyLots = 0;
   double buyPriceSum = 0;
   double sellLots = 0;
   double sellPriceSum = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double lots = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

      g_totalProfit += profit;

      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         g_buyCount++;
         g_hasBuy = true;
         if(price < g_lastBuyPrice || g_lastBuyPrice == 0)
            g_lastBuyPrice = price;
         totalLots += lots;
         totalPrice += price * lots;
         buyLots += lots;
         buyPriceSum += price * lots;
      }
      else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
      {
         g_sellCount++;
         g_hasSell = true;
         if(price > g_lastSellPrice || g_lastSellPrice == 0)
            g_lastSellPrice = price;
         totalLots += lots;
         totalPrice += price * lots;
         sellLots += lots;
         sellPriceSum += price * lots;
      }
   }

   g_totalCount = g_buyCount + g_sellCount;
   if(totalLots > 0)
      g_avgPrice = totalPrice / totalLots;
   if(buyLots > 0)
      g_buyAvgPrice = buyPriceSum / buyLots;
   if(sellLots > 0)
      g_sellAvgPrice = sellPriceSum / sellLots;

    // Calculate TP
    if(g_totalCount > 0)
     {
        double effectiveTP = g_takeProfit;
        if(Use_TP_Multiplier && g_averagingCount > 0)
        {
           int lvl = MathMin(g_averagingCount, TP_Max_Level);
           effectiveTP = g_takeProfit * MathPow(TP_Multiplier, lvl);
        }

        if(g_hasBuy && g_hasSell && Use_SeparateTP)
        {
           // Hedged with separate TP: calculate TP for each side using per-side counts
           if(g_buyCount > 0)
           {
              double buyTP = g_takeProfit;
              if(Use_TP_Multiplier && g_buyAveragingCount > 0)
              {
                 int lvl = MathMin(g_buyAveragingCount, TP_Max_Level);
                 buyTP = g_takeProfit * MathPow(TP_Multiplier, lvl);
              }
              g_buyTP = g_buyAvgPrice + (buyTP * _Point);
           }
           if(g_sellCount > 0)
           {
              double sellTP = g_takeProfit;
              if(Use_TP_Multiplier && g_sellAveragingCount > 0)
              {
                 int lvl = MathMin(g_sellAveragingCount, TP_Max_Level);
                 sellTP = g_takeProfit * MathPow(TP_Multiplier, lvl);
              }
              g_sellTP = g_sellAvgPrice - (sellTP * _Point);
           }
           g_newTP = 0;
        }
        else if(g_hasBuy && g_hasSell && !Use_SeparateTP)
        {
           // Hedged without separate TP: clear TP (original behavior)
           g_newTP = 0;
        }
        else
        {
           // Single side
           if(g_hasBuy)
              g_newTP = g_avgPrice + (effectiveTP * _Point);
           else if(g_hasSell)
              g_newTP = g_avgPrice - (effectiveTP * _Point);
        }

       g_needModify = true;

      // Update averaging count based on position count
      g_buyAveragingCount = (g_buyCount > 0) ? g_buyCount - 1 : 0;
      g_sellAveragingCount = (g_sellCount > 0) ? g_sellCount - 1 : 0;
      g_averagingCount = g_totalCount - 1;
   }

   // Original: can trade when no positions or first run
   g_canTrade = (g_totalCount == 0);
}

//+------------------------------------------------------------------+
//| ORIGINAL LOT CALCULATION FUNCTIONS                               |
//+------------------------------------------------------------------+
double GetFirstLot()
{
   double lot = Lot;
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(lot < minLot) lot = minLot;
   return lot;
}

//+------------------------------------------------------------------+
double GetAveragingLot()
{
   double lot = Lot;

   switch(LotMode)
   {
      case 0: // Fixed lot
         lot = Lot;
         break;

      case 1: // Multiplier: lot = base * multiplier^level
         lot = NormalizeDouble(Lot * MathPow(g_lotMultiplier, g_averagingCount), 2);
         break;

      case 2: // Recovery: based on last losing trade
         lot = GetRecoveryLot();
         break;
   }

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(lot < minLot) lot = minLot;

   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(lot > maxLot) lot = maxLot;

   return lot;
}

//+------------------------------------------------------------------+
double GetRecoveryLot()
{
   // Find last closed losing trade for this symbol
   HistorySelect(0, TimeCurrent());

   double lastLot = Lot;
   datetime lastTime = 0;

   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != g_magic) continue;

      // Check if it's an exit deal
      int entry = (int)HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT) continue;

      datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      if(dealTime <= lastTime) continue;

      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);

      // Original: if last trade was loss, multiply lot
      if(profit < 0)
      {
         lastLot = HistoryDealGetDouble(ticket, DEAL_VOLUME);
         lastTime = dealTime;
      }
   }

   // If found a losing trade, multiply its lot
   if(lastTime > 0 && lastLot > 0)
   {
      return NormalizeDouble(lastLot * g_lotMultiplier, 2);
   }

   return Lot;
}

//+------------------------------------------------------------------+
void CalculateNextLot()
{
   // Legacy function - now handled by GetFirstLot and GetAveragingLot
   if(g_totalCount == 0)
      g_lot = GetFirstLot();
   else
      g_lot = GetAveragingLot();
}

//+------------------------------------------------------------------+
bool OpenBuy()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   string comment = _Symbol + "-" + IntegerToString(g_magic) + "-" + IntegerToString(g_averagingCount + 1);

   if(trade.Buy(g_lot, _Symbol, ask, 0, 0, comment))
   {
      Print("BUY opened: ", g_lot, " lots at ", ask);
      return true;
   }
    else
    {
       g_lastServerFailTime = TimeCurrent();
       Print("BUY error: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
       return false;
    }
}

//+------------------------------------------------------------------+
bool OpenSell()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   string comment = _Symbol + "-" + IntegerToString(g_magic) + "-" + IntegerToString(g_averagingCount + 1);

   if(trade.Sell(g_lot, _Symbol, bid, 0, 0, comment))
   {
      Print("SELL opened: ", g_lot, " lots at ", bid);
      return true;
   }
    else
    {
       g_lastServerFailTime = TimeCurrent();
       Print("SELL error: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
       return false;
    }
}

//+------------------------------------------------------------------+
void ManageHedge()
{
   if(g_totalCount == 0) return;

   if(g_hasBuy && g_hasSell)
   {
      if(Use_Hedge_TP && g_totalProfit >= HedgeTakeProfit)
      {
         CloseAllPositions();
         Print("Hedge TP reached: ", g_totalProfit);
      }
      return;
   }

   if(g_hasBuy && !g_hasSell)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double distPips = (g_lastBuyPrice - ask) / _Point / 10.0;

      if(distPips >= HedgeDistancePips && g_sellCount < MaxHedgeCount)
      {
         double hedgeLot = NormalizeDouble(Lot * HedgeLotMultiplier, 2);
         double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         if(hedgeLot < minLot) hedgeLot = minLot;

         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         string comment = _Symbol + "-HEDGE-SELL-" + IntegerToString(g_sellCount + 1);

         if(trade.Sell(hedgeLot, _Symbol, bid, 0, 0, comment))
            Print("HEDGE SELL: ", hedgeLot, " at ", bid);
         else
         {
            g_lastServerFailTime = TimeCurrent();
            Print("HEDGE SELL FAILED: lot=", hedgeLot, " bid=", bid, " err=", trade.ResultRetcode(), " msg=", trade.ResultRetcodeDescription());
         }
      }
      else
      {
         static datetime hedgeSkipBuyLog = 0;
         if(TimeCurrent() - hedgeSkipBuyLog > 30)
         {
            hedgeSkipBuyLog = TimeCurrent();
            Print("HEDGE SKIP BUY: distPips=", DoubleToString(distPips, 1), " need=", DoubleToString(HedgeDistancePips, 1), " sellCount=", g_sellCount, " max=", MaxHedgeCount);
         }
      }
   }
   else if(g_hasSell && !g_hasBuy)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double distPips = (ask - g_lastSellPrice) / _Point / 10.0;

      if(distPips >= HedgeDistancePips && g_buyCount < MaxHedgeCount)
      {
         double hedgeLot = NormalizeDouble(Lot * HedgeLotMultiplier, 2);
         double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         if(hedgeLot < minLot) hedgeLot = minLot;

         string comment = _Symbol + "-HEDGE-BUY-" + IntegerToString(g_buyCount + 1);

         if(trade.Buy(hedgeLot, _Symbol, ask, 0, 0, comment))
            Print("HEDGE BUY: ", hedgeLot, " at ", ask);
         else
         {
            g_lastServerFailTime = TimeCurrent();
            Print("HEDGE BUY FAILED: lot=", hedgeLot, " ask=", ask, " err=", trade.ResultRetcode(), " msg=", trade.ResultRetcodeDescription());
         }
      }
      else
      {
         static datetime hedgeSkipSellLog = 0;
         if(TimeCurrent() - hedgeSkipSellLog > 30)
         {
            hedgeSkipSellLog = TimeCurrent();
            Print("HEDGE SKIP SELL: distPips=", DoubleToString(distPips, 1), " need=", DoubleToString(HedgeDistancePips, 1), " buyCount=", g_buyCount, " max=", MaxHedgeCount);
         }
      }
   }
}

//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   if(g_totalCount == 0) return;

   if(g_totalProfit > g_bestProfit)
      g_bestProfit = g_totalProfit;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      long posType = PositionGetInteger(POSITION_TYPE);

      if(posType == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double profitPips = (bid - openPrice) / _Point;

         // Breakeven
         if(Use_Breakeven && profitPips >= BreakevenStartPips)
         {
            double bePrice = NormalizeDouble(openPrice + (BreakevenProfitPips * _Point), _Digits);
            if(currentSL < bePrice || currentSL == 0)
            {
               if(trade.PositionModify(ticket, bePrice, currentTP))
                  Print("BREAKEVEN BUY #", ticket, " SL=", bePrice);
            }
         }

         // Trailing stop
         if(Use_Trailing_Stop && profitPips >= TrailingStartPips)
         {
            // Calculate trailing distance
            double trailDistPoints = TrailingDistancePips * _Point;
            if(TrailingMode == 1)
            {
               // ATR based trailing
               double atrVal[];
               if(CopyBuffer(g_trailAtrHandle, 0, 0, 1, atrVal) == 1)
                  trailDistPoints = atrVal[0] * Trail_ATR_Multiplier;
            }

            double newSL = NormalizeDouble(bid - trailDistPoints, _Digits);

            // Only snap to step grid if step is meaningful relative to price
            double stepSize = TrailingStepPips * _Point;
            if(stepSize > 0 && stepSize < trailDistPoints * 0.5)
               newSL = NormalizeDouble(newSL - MathMod(newSL - openPrice, stepSize), _Digits);

            // Ensure SL is above entry (for BUY)
            if(newSL <= openPrice)
               newSL = NormalizeDouble(openPrice + trailDistPoints * 0.1, _Digits);

            if(newSL > currentSL || currentSL == 0)
            {
               if(trade.PositionModify(ticket, newSL, currentTP))
                  Print("TRAIL BUY #", ticket, " SL=", newSL, " profit=", DoubleToString(profitPips, 0), " pts");
               else
                  Print("TRAIL BUY FAILED #", ticket, " newSL=", newSL, " bid=", bid, " err=", trade.ResultRetcode());
            }
            else
            {
               // Debug: show why trail didn't move
               static datetime lastTrailDbg = 0;
               if(TimeCurrent() - lastTrailDbg >= 30)
               {
                  lastTrailDbg = TimeCurrent();
                  Print("TRAIL BUY SKIP #", ticket, " newSL=", newSL, " <= currentSL=", currentSL,
                        " profit=", DoubleToString(profitPips, 0), " pts",
                        " dist=", DoubleToString(trailDistPoints, _Digits));
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double profitPips = (openPrice - ask) / _Point;

         // Breakeven
         if(Use_Breakeven && profitPips >= BreakevenStartPips)
         {
            double bePrice = NormalizeDouble(openPrice - (BreakevenProfitPips * _Point), _Digits);
            if(currentSL > bePrice || currentSL == 0)
            {
               if(trade.PositionModify(ticket, bePrice, currentTP))
                  Print("BREAKEVEN SELL #", ticket, " SL=", bePrice);
            }
         }

         // Trailing stop
         if(Use_Trailing_Stop && profitPips >= TrailingStartPips)
         {
            // Calculate trailing distance
            double trailDistPoints = TrailingDistancePips * _Point;
            if(TrailingMode == 1)
            {
               // ATR based trailing
               double atrVal[];
               if(CopyBuffer(g_trailAtrHandle, 0, 0, 1, atrVal) == 1)
                  trailDistPoints = atrVal[0] * Trail_ATR_Multiplier;
            }

            double newSL = NormalizeDouble(ask + trailDistPoints, _Digits);

            // Only snap to step grid if step is meaningful relative to price
            double stepSize = TrailingStepPips * _Point;
            if(stepSize > 0 && stepSize < trailDistPoints * 0.5)
               newSL = NormalizeDouble(newSL + MathMod(openPrice - newSL, stepSize), _Digits);

            // Ensure SL is below entry (for SELL)
            if(newSL >= openPrice)
               newSL = NormalizeDouble(openPrice - trailDistPoints * 0.1, _Digits);

            if(newSL < currentSL || currentSL == 0)
            {
               if(trade.PositionModify(ticket, newSL, currentTP))
                  Print("TRAIL SELL #", ticket, " SL=", newSL, " profit=", DoubleToString(profitPips, 0), " pts");
               else
                  Print("TRAIL SELL FAILED #", ticket, " newSL=", newSL, " ask=", ask, " err=", trade.ResultRetcode());
            }
            else
            {
               // Debug: show why trail didn't move
               static datetime lastTrailDbgS = 0;
               if(TimeCurrent() - lastTrailDbgS >= 30)
               {
                  lastTrailDbgS = TimeCurrent();
                  Print("TRAIL SELL SKIP #", ticket, " newSL=", newSL, " >= currentSL=", currentSL,
                        " profit=", DoubleToString(profitPips, 0), " pts",
                        " dist=", DoubleToString(trailDistPoints, _Digits));
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| SMART TRAIL - Multi-stage adaptive trailing stop                  |
//+------------------------------------------------------------------+
double GetSmartATR()
{
   double atrVal[];
   if(CopyBuffer(g_smartTrailAtrHandle, 0, 0, 1, atrVal) == 1)
      return atrVal[0];
   return 0;
}

//+------------------------------------------------------------------+
double GetSmartADX()
{
   double adxVal[];
   if(CopyBuffer(g_smartTrailAdxHandle, 0, 0, 1, adxVal) == 1)
      return adxVal[0];
   return 0;
}

//+------------------------------------------------------------------+
double GetSwingLow(int lookback)
{
   double low[];
   ArraySetAsSeries(low, true);
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, lookback, low) < lookback)
      return 0;

   double swingLow = low[0];
   for(int i = 1; i < lookback; i++)
   {
      if(low[i] < low[i+1] && low[i] < low[i-1])
      {
         if(low[i] < swingLow)
            swingLow = low[i];
      }
   }
   return swingLow;
}

//+------------------------------------------------------------------+
double GetSwingHigh(int lookback)
{
   double high[];
   ArraySetAsSeries(high, true);
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, lookback, high) < lookback)
      return 0;

   double swingHigh = high[0];
   for(int i = 1; i < lookback; i++)
   {
      if(high[i] > high[i+1] && high[i] > high[i-1])
      {
         if(high[i] > swingHigh)
            swingHigh = high[i];
      }
   }
   return swingHigh;
}

//+------------------------------------------------------------------+
double GetRValue(double entryPrice, bool isBuy)
{
   double atr = GetSmartATR();
   if(atr <= 0) atr = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 100;
   return atr * SmartTrail_ATR_Normal;
}

//+------------------------------------------------------------------+
void ManageSmartTrail()
{
   if(!Use_SmartTrail || g_totalCount == 0) return;

   double atr = GetSmartATR();
   if(atr <= 0) return;

   double adx = GetSmartADX();
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(bid <= 0 || ask <= 0) return;

   // Determine ATR multiplier based on ADX trend strength
   double atrMult = SmartTrail_ATR_Normal;
   if(adx >= SmartTrail_ADX_Strong)
      atrMult = SmartTrail_ATR_Strong;
   else if(adx < SmartTrail_ADX_Weak)
      atrMult = SmartTrail_ATR_Weak;

   double trailDist = atr * atrMult;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      long posType = PositionGetInteger(POSITION_TYPE);

      if(posType != POSITION_TYPE_BUY && posType != POSITION_TYPE_SELL) continue;

      // Calculate R value (risk = entry to initial SL distance)
      double R = atr * SmartTrail_ATR_Normal;
      if(R <= 0) continue;

      double newSL = 0;

      if(posType == POSITION_TYPE_BUY)
      {
         double profitPts = (bid - openPrice) / _Point;

         // Stage 8: Extreme profit - Chandelier exit
         if(SmartTrail_Chandelier && profitPts >= SmartTrail_ChandelierR * R / _Point)
         {
            double highestHigh = GetSwingHigh(SmartTrail_SwingLookback);
            if(highestHigh <= 0) highestHigh = bid;
            newSL = NormalizeDouble(highestHigh - atr * SmartTrail_ChandelierR, _Digits);
         }
         // Stage 7: Structure trail - swing low based
         else if(SmartTrail_Structure && profitPts >= SmartTrail_ATR_Normal * R / _Point)
         {
            double swingLow = GetSwingLow(SmartTrail_SwingLookback);
            double structureSL = NormalizeDouble(swingLow - SmartTrail_StructureBuf * _Point, _Digits);
            double atrSL = NormalizeDouble(bid - trailDist, _Digits);
            newSL = MathMax(structureSL, atrSL);
         }
         // Stage 4: Adaptive ATR trailing
         else if(SmartTrail_ATR && profitPts >= SmartTrail_PL_R * R / _Point)
         {
            newSL = NormalizeDouble(bid - trailDist, _Digits);
         }
         // Stage 3: Profit lock
         else if(SmartTrail_ProfitLock && profitPts >= SmartTrail_PL_R * R / _Point)
         {
            double lockedPrice = openPrice + (SmartTrail_Locked_R * R);
            newSL = NormalizeDouble(lockedPrice, _Digits);
         }
         // Stage 2: Break-even
         else if(SmartTrail_BreakEven && profitPts >= SmartTrail_BE_R * R / _Point)
         {
            newSL = NormalizeDouble(openPrice + SmartTrail_BE_Buffer * _Point, _Digits);
         }

         // Enforce minimum step
         if(newSL > 0 && currentSL > 0)
         {
            if(newSL - currentSL < SmartTrail_MinStep * _Point)
               continue;
         }

         // Only move SL up, never down
         if(newSL > 0 && newSL > currentSL)
         {
            if(trade.PositionModify(ticket, newSL, currentTP))
            {
               static datetime lastSmartTrailLog = 0;
               if(TimeCurrent() - lastSmartTrailLog >= 30)
               {
                  lastSmartTrailLog = TimeCurrent();
                  Print("SMART TRAIL BUY #", ticket, " SL=", newSL,
                        " ADX=", DoubleToString(adx, 1),
                        " ATR=", DoubleToString(atr, _Digits),
                        " mult=", DoubleToString(atrMult, 1));
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double profitPts = (openPrice - ask) / _Point;

         // Stage 8: Extreme profit - Chandelier exit
         if(SmartTrail_Chandelier && profitPts >= SmartTrail_ChandelierR * R / _Point)
         {
            double lowestLow = GetSwingLow(SmartTrail_SwingLookback);
            if(lowestLow <= 0) lowestLow = ask;
            newSL = NormalizeDouble(lowestLow + atr * SmartTrail_ChandelierR, _Digits);
         }
         // Stage 7: Structure trail - swing high based
         else if(SmartTrail_Structure && profitPts >= SmartTrail_ATR_Normal * R / _Point)
         {
            double swingHigh = GetSwingHigh(SmartTrail_SwingLookback);
            double structureSL = NormalizeDouble(swingHigh + SmartTrail_StructureBuf * _Point, _Digits);
            double atrSL = NormalizeDouble(ask + trailDist, _Digits);
            newSL = MathMin(structureSL, atrSL);
         }
         // Stage 4: Adaptive ATR trailing
         else if(SmartTrail_ATR && profitPts >= SmartTrail_PL_R * R / _Point)
         {
            newSL = NormalizeDouble(ask + trailDist, _Digits);
         }
         // Stage 3: Profit lock
         else if(SmartTrail_ProfitLock && profitPts >= SmartTrail_PL_R * R / _Point)
         {
            double lockedPrice = openPrice - (SmartTrail_Locked_R * R);
            newSL = NormalizeDouble(lockedPrice, _Digits);
         }
         // Stage 2: Break-even
         else if(SmartTrail_BreakEven && profitPts >= SmartTrail_BE_R * R / _Point)
         {
            newSL = NormalizeDouble(openPrice - SmartTrail_BE_Buffer * _Point, _Digits);
         }

         // Enforce minimum step
         if(newSL > 0 && currentSL > 0)
         {
            if(currentSL - newSL < SmartTrail_MinStep * _Point)
               continue;
         }

         // Only move SL down, never up
         if(newSL > 0 && (newSL < currentSL || currentSL == 0))
         {
            if(trade.PositionModify(ticket, newSL, currentTP))
            {
               static datetime lastSmartTrailLogS = 0;
               if(TimeCurrent() - lastSmartTrailLogS >= 30)
               {
                  lastSmartTrailLogS = TimeCurrent();
                  Print("SMART TRAIL SELL #", ticket, " SL=", newSL,
                        " ADX=", DoubleToString(adx, 1),
                        " ATR=", DoubleToString(atr, _Digits),
                        " mult=", DoubleToString(atrMult, 1));
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| PRICE % TRAIL - Price-distance percentage trailing                |
//|  BUY:  SL = HighestPriceSinceEntry x (1 - Trail%)                 |
//|  SELL: SL = LowestPriceSinceEntry  x (1 + Trail%)                 |
//+------------------------------------------------------------------+
double GetHighestSinceEntry(datetime entryTime, double fallback)
{
   int shift = iBarShift(_Symbol, PERIOD_CURRENT, entryTime);
   if(shift < 1) return fallback;

   double high[];
   ArraySetAsSeries(high, true);
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, shift + 1, high) < shift + 1)
      return fallback;

   double maxH = high[0];
   for(int k = 1; k <= shift; k++)
   {
      if(high[k] > maxH) maxH = high[k];
   }
   return maxH;
}

//+------------------------------------------------------------------+
double GetLowestSinceEntry(datetime entryTime, double fallback)
{
   int shift = iBarShift(_Symbol, PERIOD_CURRENT, entryTime);
   if(shift < 1) return fallback;

   double low[];
   ArraySetAsSeries(low, true);
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, shift + 1, low) < shift + 1)
      return fallback;

   double minL = low[0];
   for(int k = 1; k <= shift; k++)
   {
      if(low[k] < minL) minL = low[k];
   }
   return minL;
}

//+------------------------------------------------------------------+
void ManagePctTrail()
{
   if(!Use_PctTrail || g_totalCount == 0) return;

   double atr = GetATRValue();
   if(atr <= 0) return;

   double adx = GetSmartADX();
   if(adx <= 0) adx = PctTrail_Trail_Normal; // no ADX data, use normal

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(bid <= 0 || ask <= 0) return;

   // R = risk per trade (entry to initial SL). Use ATR as risk proxy
   double R = atr;

   // Choose trail % based on trend strength
   double trailPct = PctTrail_Trail_Normal;
   if(adx >= PctTrail_ADX_Strong)
      trailPct = PctTrail_Trail_Strong;
   else if(adx < PctTrail_ADX_Choppy)
      trailPct = PctTrail_Trail_Choppy;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      long posType = PositionGetInteger(POSITION_TYPE);
      datetime entryTime = (datetime)PositionGetInteger(POSITION_TIME);

      double newSL = 0;

      if(posType == POSITION_TYPE_BUY)
      {
         double highest = GetHighestSinceEntry(entryTime, bid);
         double profitR = (bid - openPrice) / R;
         if(profitR < PctTrail_ActivateR) continue;

         double maxProfitR = (highest - openPrice) / R;

         // Determine lock % based on max profit reached
         double lockPct = 0;
         if(maxProfitR >= PctTrail_Lock_R4) lockPct = PctTrail_Lock_P4;
         else if(maxProfitR >= PctTrail_Lock_R3) lockPct = PctTrail_Lock_P3;
         else if(maxProfitR >= PctTrail_Lock_R2) lockPct = PctTrail_Lock_P2;
         else if(maxProfitR >= PctTrail_Lock_R1) lockPct = PctTrail_Lock_P1;
         else if(profitR >= 0.5)
         {
            // BE protection below tier 1 - use a real buffer, not 2 points
            double beBuffer = MathMax(_Point * 20, atr * 0.05);
            newSL = NormalizeDouble(openPrice + beBuffer, _Digits);
         }

         // Locked profit SL: openPrice + (maxProfit x lockPct)
         double slLock = openPrice + (highest - openPrice) * (lockPct / 100.0);

         // Price % trailing SL: highest x (1 - trail%)
         double slTrail = NormalizeDouble(highest * (1.0 - trailPct / 100.0), _Digits);

         // Take the more protective (higher) of the two
         newSL = MathMax(slLock, slTrail);

         // Ensure SL is not too close to current price (avoid noise stop-outs)
         double minDist = MathMax(atr * 0.10, _Point * 20);
         if(bid - newSL < minDist)
            newSL = NormalizeDouble(bid - minDist, _Digits);

         // Enforce minimum step
         if(currentSL > 0 && newSL - currentSL < PctTrail_MinStep * _Point)
            continue;

         // Never move SL down
         if(newSL > currentSL)
         {
            if(trade.PositionModify(ticket, newSL, currentTP))
            {
               static datetime lastPctLogB = 0;
               if(TimeCurrent() - lastPctLogB >= 30)
               {
                  lastPctLogB = TimeCurrent();
                  Print("PCT TRAIL BUY #", ticket, " SL=", newSL,
                        " high=", DoubleToString(highest, _Digits),
                        " trail%=", DoubleToString(trailPct, 2),
                        " lock%=", DoubleToString(lockPct, 0));
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double lowest = GetLowestSinceEntry(entryTime, ask);
         double profitR = (openPrice - ask) / R;
         if(profitR < PctTrail_ActivateR) continue;

         double maxProfitR = (openPrice - lowest) / R;

         double lockPct = 0;
         if(maxProfitR >= PctTrail_Lock_R4) lockPct = PctTrail_Lock_P4;
         else if(maxProfitR >= PctTrail_Lock_R3) lockPct = PctTrail_Lock_P3;
         else if(maxProfitR >= PctTrail_Lock_R2) lockPct = PctTrail_Lock_P2;
         else if(maxProfitR >= PctTrail_Lock_R1) lockPct = PctTrail_Lock_P1;
         else if(profitR >= 0.5)
         {
            // BE protection below tier 1 - use a real buffer, not 2 points
            double beBuffer = MathMax(_Point * 20, atr * 0.05);
            newSL = NormalizeDouble(openPrice - beBuffer, _Digits);
         }

         // Locked profit SL: openPrice - (maxProfit x lockPct)
         double slLock = openPrice - (openPrice - lowest) * (lockPct / 100.0);

         // Price % trailing SL: lowest x (1 + trail%)
         double slTrail = NormalizeDouble(lowest * (1.0 + trailPct / 100.0), _Digits);

         newSL = MathMin(slLock, slTrail);

         // Ensure SL is not too close to current price (avoid noise stop-outs)
         double minDist = MathMax(atr * 0.10, _Point * 20);
         if(newSL - ask < minDist)
            newSL = NormalizeDouble(ask + minDist, _Digits);

         // Enforce minimum step
         if(currentSL > 0 && currentSL - newSL < PctTrail_MinStep * _Point)
            continue;

         // Never move SL up
         if(newSL < currentSL || currentSL == 0)
         {
            if(trade.PositionModify(ticket, newSL, currentTP))
            {
               static datetime lastPctLogS = 0;
               if(TimeCurrent() - lastPctLogS >= 30)
               {
                  lastPctLogS = TimeCurrent();
                  Print("PCT TRAIL SELL #", ticket, " SL=", newSL,
                        " low=", DoubleToString(lowest, _Digits),
                        " trail%=", DoubleToString(trailPct, 2),
                        " lock%=", DoubleToString(lockPct, 0));
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| CHART DRAWING FUNCTIONS                                          |
//+------------------------------------------------------------------+
input group "=== CHART DRAWING SETTINGS ==="
input bool            DrawTP_SL            = true;     // Draw TP/SL Lines
input bool            DrawTrailLine        = true;     // Draw Trailing Stop Line
input bool            DrawEntryLine        = true;     // Draw Entry/Avg Price Line
input bool            DrawProfitBox        = true;     // Draw Profit Info Box
input bool            CleanChart           = true;     // Remove grid, set candle colors
input color           TP_Color             = C'0,200,100';   // Take Profit Color
input color           SL_Color             = C'220,50,50';    // Stop Loss Color
input color           Trail_Color          = C'255,200,0';    // Trailing Stop Color
input color           Entry_Color          = C'0,150,255';    // Entry Price Color
input color           Avg_Color            = C'200,200,200';  // Average Price Color
input int             LineWidth            = 2;        // Line Width
input int             LabelFontSize        = 8;        // Label Font Size
input int             InfoBoxX             = 10;       // Info Box X Position
input int             InfoBoxY             = 30;       // Info Box Y Position

//+------------------------------------------------------------------+
void DrawTradeLines()
{
   ObjectsDeleteAll(0, "TRADE_");

   if(!DrawTP_SL && !DrawTrailLine && !DrawEntryLine && !DrawProfitBox) return;
   if(g_totalCount == 0) return;

   datetime now = TimeCurrent();
   datetime barTime = iTime(_Symbol, g_currentTimeframe, 0);

   // Get current SL/TP from positions
   double currentSL = 0;
   double currentTP = 0;
   double firstEntry = 0;
   long firstType = -1;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      long posType = PositionGetInteger(POSITION_TYPE);

      if(firstEntry == 0)
      {
         firstEntry = openPrice;
         firstType = posType;
      }

      // Use the SL/TP from position, fallback to calculated
      if(sl != 0) currentSL = sl;
      if(tp != 0) currentTP = tp;
   }

   // Use calculated TP if position TP is 0
   if(currentTP == 0 && g_newTP > 0)
      currentTP = g_newTP;

   // === ENTRY / AVERAGE PRICE LINE ===
   if(DrawEntryLine && g_avgPrice > 0)
   {
      string entryName = "TRADE_ENTRY";
      ObjectCreate(0, entryName, OBJ_HLINE, 0, 0, g_avgPrice);
      ObjectSetInteger(0, entryName, OBJPROP_COLOR, Entry_Color);
      ObjectSetInteger(0, entryName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, entryName, OBJPROP_WIDTH, LineWidth);
      ObjectSetInteger(0, entryName, OBJPROP_BACK, false);
      ObjectSetInteger(0, entryName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, entryName, OBJPROP_HIDDEN, true);

      // Entry label
      string entryLabel = "TRADE_ENTRY_LABEL";
      string entryDir = g_hasBuy ? "BUY" : (g_hasSell ? "SELL" : "MIX");
      double entryPips = 0;
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      if(g_hasBuy && !g_hasSell)
         entryPips = (bid - g_avgPrice) / _Point;
      else if(g_hasSell && !g_hasBuy)
         entryPips = (g_avgPrice - ask) / _Point;

      string entryText = entryDir + " AVG: " + DoubleToString(g_avgPrice, _Digits) +
                         " (" + DoubleToString(entryPips, 1) + " pips)";

      ObjectCreate(0, entryLabel, OBJ_TEXT, 0, barTime, g_avgPrice);
      ObjectSetString(0, entryLabel, OBJPROP_TEXT, entryText);
      ObjectSetInteger(0, entryLabel, OBJPROP_COLOR, Entry_Color);
      ObjectSetInteger(0, entryLabel, OBJPROP_FONTSIZE, LabelFontSize);
      ObjectSetInteger(0, entryLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetString(0, entryLabel, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, entryLabel, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, entryLabel, OBJPROP_HIDDEN, true);
   }

   // === TAKE PROFIT LINE ===
   if(DrawTP_SL && g_hasBuy && g_hasSell && Use_SeparateTP)
   {
      // Hedged with separate TP: draw both buy TP and sell TP
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      if(g_buyTP > 0)
      {
         string buyTpName = "TRADE_BUY_TP";
         ObjectCreate(0, buyTpName, OBJ_HLINE, 0, 0, g_buyTP);
         ObjectSetInteger(0, buyTpName, OBJPROP_COLOR, clrDodgerBlue);
         ObjectSetInteger(0, buyTpName, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, buyTpName, OBJPROP_WIDTH, LineWidth);
         ObjectSetInteger(0, buyTpName, OBJPROP_BACK, false);
         ObjectSetInteger(0, buyTpName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, buyTpName, OBJPROP_HIDDEN, true);

         string buyTpLabel = "TRADE_BUY_TP_LABEL";
         double buyTpPips = (g_buyTP - ask) / _Point;
         string buyTpText = "BUY TP: " + DoubleToString(g_buyTP, _Digits) +
                           " (" + DoubleToString(buyTpPips, 1) + " pips)";
         ObjectCreate(0, buyTpLabel, OBJ_TEXT, 0, barTime, g_buyTP);
         ObjectSetString(0, buyTpLabel, OBJPROP_TEXT, buyTpText);
         ObjectSetInteger(0, buyTpLabel, OBJPROP_COLOR, clrDodgerBlue);
         ObjectSetInteger(0, buyTpLabel, OBJPROP_FONTSIZE, LabelFontSize);
         ObjectSetInteger(0, buyTpLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetString(0, buyTpLabel, OBJPROP_FONT, "Arial Bold");
         ObjectSetInteger(0, buyTpLabel, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, buyTpLabel, OBJPROP_HIDDEN, true);
      }

      if(g_sellTP > 0)
      {
         string sellTpName = "TRADE_SELL_TP";
         ObjectCreate(0, sellTpName, OBJ_HLINE, 0, 0, g_sellTP);
         ObjectSetInteger(0, sellTpName, OBJPROP_COLOR, clrOrangeRed);
         ObjectSetInteger(0, sellTpName, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, sellTpName, OBJPROP_WIDTH, LineWidth);
         ObjectSetInteger(0, sellTpName, OBJPROP_BACK, false);
         ObjectSetInteger(0, sellTpName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, sellTpName, OBJPROP_HIDDEN, true);

         string sellTpLabel = "TRADE_SELL_TP_LABEL";
         double sellTpPips = (bid - g_sellTP) / _Point;
         string sellTpText = "SELL TP: " + DoubleToString(g_sellTP, _Digits) +
                            " (" + DoubleToString(sellTpPips, 1) + " pips)";
         ObjectCreate(0, sellTpLabel, OBJ_TEXT, 0, barTime, g_sellTP);
         ObjectSetString(0, sellTpLabel, OBJPROP_TEXT, sellTpText);
         ObjectSetInteger(0, sellTpLabel, OBJPROP_COLOR, clrOrangeRed);
         ObjectSetInteger(0, sellTpLabel, OBJPROP_FONTSIZE, LabelFontSize);
         ObjectSetInteger(0, sellTpLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetString(0, sellTpLabel, OBJPROP_FONT, "Arial Bold");
         ObjectSetInteger(0, sellTpLabel, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, sellTpLabel, OBJPROP_HIDDEN, true);
      }
   }
   else if(DrawTP_SL && currentTP > 0)
   {
      string tpName = "TRADE_TP";
      ObjectCreate(0, tpName, OBJ_HLINE, 0, 0, currentTP);
      ObjectSetInteger(0, tpName, OBJPROP_COLOR, TP_Color);
      ObjectSetInteger(0, tpName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, tpName, OBJPROP_WIDTH, LineWidth);
      ObjectSetInteger(0, tpName, OBJPROP_BACK, false);
      ObjectSetInteger(0, tpName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, tpName, OBJPROP_HIDDEN, true);

      // TP label
      string tpLabel = "TRADE_TP_LABEL";
      double tpPips = 0;
      double tpMoney = 0;
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      if(g_hasBuy && !g_hasSell)
      {
         tpPips = (currentTP - ask) / _Point;
         tpMoney = (currentTP - g_avgPrice) / _Point * g_totalCount * 10;
      }
      else if(g_hasSell && !g_hasBuy)
      {
         tpPips = (bid - currentTP) / _Point;
         tpMoney = (g_avgPrice - currentTP) / _Point * g_totalCount * 10;
      }

      string tpText = "TP: " + DoubleToString(currentTP, _Digits) +
                      " (" + DoubleToString(tpPips, 1) + " pips = $" + DoubleToString(tpMoney, 2) + ")";

      ObjectCreate(0, tpLabel, OBJ_TEXT, 0, barTime, currentTP);
      ObjectSetString(0, tpLabel, OBJPROP_TEXT, tpText);
      ObjectSetInteger(0, tpLabel, OBJPROP_COLOR, TP_Color);
      ObjectSetInteger(0, tpLabel, OBJPROP_FONTSIZE, LabelFontSize);
      ObjectSetInteger(0, tpLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetString(0, tpLabel, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, tpLabel, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, tpLabel, OBJPROP_HIDDEN, true);
   }

   // === STOP LOSS LINE ===
   if(DrawTP_SL && currentSL > 0)
   {
      string slName = "TRADE_SL";
      ObjectCreate(0, slName, OBJ_HLINE, 0, 0, currentSL);
      ObjectSetInteger(0, slName, OBJPROP_COLOR, SL_Color);
      ObjectSetInteger(0, slName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, slName, OBJPROP_WIDTH, LineWidth);
      ObjectSetInteger(0, slName, OBJPROP_BACK, false);
      ObjectSetInteger(0, slName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, slName, OBJPROP_HIDDEN, true);

      // SL label
      string slLabel = "TRADE_SL_LABEL";
      double slPips = 0;
      double slMoney = 0;
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      if(g_hasBuy && !g_hasSell)
      {
         slPips = (currentSL - ask) / _Point;
         slMoney = (currentSL - g_avgPrice) / _Point * g_totalCount * 10;
      }
      else if(g_hasSell && !g_hasBuy)
      {
         slPips = (bid - currentSL) / _Point;
         slMoney = (g_avgPrice - currentSL) / _Point * g_totalCount * 10;
      }

      string slText = "SL: " + DoubleToString(currentSL, _Digits) +
                      " (" + DoubleToString(slPips, 1) + " pips = $" + DoubleToString(slMoney, 2) + ")";

      ObjectCreate(0, slLabel, OBJ_TEXT, 0, barTime, currentSL);
      ObjectSetString(0, slLabel, OBJPROP_TEXT, slText);
      ObjectSetInteger(0, slLabel, OBJPROP_COLOR, SL_Color);
      ObjectSetInteger(0, slLabel, OBJPROP_FONTSIZE, LabelFontSize);
      ObjectSetInteger(0, slLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetString(0, slLabel, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, slLabel, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, slLabel, OBJPROP_HIDDEN, true);
   }

    // === TRAILING STOP LINE ===
    if(DrawTrailLine && Use_Trailing_Stop && g_totalCount > 0)
    {
       double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
       double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

       // Draw trail for BUY positions - use actual SL from position
       if(g_hasBuy)
       {
          double bestBuySL = 0;
          double bestBuyOpen = 0;
          int buyCnt = 0;
          for(int i = PositionsTotal() - 1; i >= 0; i--)
          {
             ulong t = PositionGetTicket(i);
             if(t == 0) continue;
             if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
             if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
             if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
             {
                double sl = PositionGetDouble(POSITION_SL);
                double op = PositionGetDouble(POSITION_PRICE_OPEN);
                if(sl > bestBuySL) bestBuySL = sl;
                bestBuyOpen += op;
                buyCnt++;
             }
          }
          if(buyCnt > 0) bestBuyOpen /= buyCnt;

          // If position has an SL set, use it; otherwise calculate theoretical trail
          double trailSL = 0;
          if(bestBuySL > 0)
          {
             trailSL = bestBuySL;  // Use actual SL from position
          }
          else
          {
             // Calculate theoretical trail level
             double trailDistPoints = TrailingDistancePips * _Point;
             if(TrailingMode == 1)
             {
                double atrVal[];
                if(CopyBuffer(g_trailAtrHandle, 0, 0, 1, atrVal) == 1)
                   trailDistPoints = atrVal[0] * Trail_ATR_Multiplier;
             }
             trailSL = NormalizeDouble(bid - trailDistPoints, _Digits);
             if(trailSL < bestBuyOpen) trailSL = NormalizeDouble(bestBuyOpen + _Point, _Digits);
          }

          if(trailSL > 0 && bestBuyOpen > 0)
          {
             double profitPts = (bid - bestBuyOpen) / _Point;

             string trailName = "TRADE_TRAIL_BUY";
             ObjectCreate(0, trailName, OBJ_HLINE, 0, 0, trailSL);
             ObjectSetInteger(0, trailName, OBJPROP_COLOR, clrDodgerBlue);
             ObjectSetInteger(0, trailName, OBJPROP_STYLE, STYLE_DASHDOT);
             ObjectSetInteger(0, trailName, OBJPROP_WIDTH, LineWidth + 1);
             ObjectSetInteger(0, trailName, OBJPROP_BACK, false);
             ObjectSetInteger(0, trailName, OBJPROP_SELECTABLE, false);
             ObjectSetInteger(0, trailName, OBJPROP_HIDDEN, true);

             string trailLabel = "TRADE_TRAIL_BUY_LBL";
             string trailText = "BUY TRAIL: " + DoubleToString(trailSL, _Digits) +
                               " (" + DoubleToString(profitPts, 0) + " pts)";
             ObjectCreate(0, trailLabel, OBJ_TEXT, 0, barTime, trailSL);
             ObjectSetString(0, trailLabel, OBJPROP_TEXT, trailText);
             ObjectSetInteger(0, trailLabel, OBJPROP_COLOR, clrDodgerBlue);
             ObjectSetInteger(0, trailLabel, OBJPROP_FONTSIZE, LabelFontSize);
             ObjectSetInteger(0, trailLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
             ObjectSetString(0, trailLabel, OBJPROP_FONT, "Arial Bold");
             ObjectSetInteger(0, trailLabel, OBJPROP_SELECTABLE, false);
             ObjectSetInteger(0, trailLabel, OBJPROP_HIDDEN, true);
          }
       }

       // Draw trail for SELL positions - use actual SL from position
       if(g_hasSell)
       {
          double bestSellSL = 999999;
          double bestSellOpen = 0;
          int sellCnt = 0;
          for(int i = PositionsTotal() - 1; i >= 0; i--)
          {
             ulong t = PositionGetTicket(i);
             if(t == 0) continue;
             if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
             if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
             if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
             {
                double sl = PositionGetDouble(POSITION_SL);
                double op = PositionGetDouble(POSITION_PRICE_OPEN);
                if(sl > 0 && sl < bestSellSL) bestSellSL = sl;
                bestSellOpen += op;
                sellCnt++;
             }
          }
          if(sellCnt > 0) bestSellOpen /= sellCnt;

          // If position has an SL set, use it; otherwise calculate theoretical trail
          double trailSL = 0;
          if(bestSellSL < 999999 && bestSellSL > 0)
          {
             trailSL = bestSellSL;  // Use actual SL from position
          }
          else
          {
             // Calculate theoretical trail level
             double trailDistPoints = TrailingDistancePips * _Point;
             if(TrailingMode == 1)
             {
                double atrVal[];
                if(CopyBuffer(g_trailAtrHandle, 0, 0, 1, atrVal) == 1)
                   trailDistPoints = atrVal[0] * Trail_ATR_Multiplier;
             }
             trailSL = NormalizeDouble(ask + trailDistPoints, _Digits);
             if(trailSL > bestSellOpen) trailSL = NormalizeDouble(bestSellOpen - _Point, _Digits);
          }

          if(trailSL > 0 && bestSellOpen > 0)
          {
             double profitPts = (bestSellOpen - ask) / _Point;

             string trailName = "TRADE_TRAIL_SELL";
             ObjectCreate(0, trailName, OBJ_HLINE, 0, 0, trailSL);
             ObjectSetInteger(0, trailName, OBJPROP_COLOR, clrCoral);
             ObjectSetInteger(0, trailName, OBJPROP_STYLE, STYLE_DASHDOT);
             ObjectSetInteger(0, trailName, OBJPROP_WIDTH, LineWidth + 1);
             ObjectSetInteger(0, trailName, OBJPROP_BACK, false);
             ObjectSetInteger(0, trailName, OBJPROP_SELECTABLE, false);
             ObjectSetInteger(0, trailName, OBJPROP_HIDDEN, true);

             string trailLabel = "TRADE_TRAIL_SELL_LBL";
             string trailText = "SELL TRAIL: " + DoubleToString(trailSL, _Digits) +
                               " (" + DoubleToString(profitPts, 0) + " pts)";
             ObjectCreate(0, trailLabel, OBJ_TEXT, 0, barTime, trailSL);
             ObjectSetString(0, trailLabel, OBJPROP_TEXT, trailText);
             ObjectSetInteger(0, trailLabel, OBJPROP_COLOR, clrCoral);
             ObjectSetInteger(0, trailLabel, OBJPROP_FONTSIZE, LabelFontSize);
             ObjectSetInteger(0, trailLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
             ObjectSetString(0, trailLabel, OBJPROP_FONT, "Arial Bold");
             ObjectSetInteger(0, trailLabel, OBJPROP_SELECTABLE, false);
             ObjectSetInteger(0, trailLabel, OBJPROP_HIDDEN, true);
          }
       }
    }

   // === PROFIT INFO BOX ===
   if(DrawProfitBox)
   {
      string boxName = "TRADE_INFO_BOX";
      string boxText = "";

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double currentPrice = (g_hasBuy) ? bid : ask;

      // Calculate pips to TP
      double pipsToTP = 0;
      if(currentTP > 0)
      {
         if(g_hasBuy)
            pipsToTP = (currentTP - currentPrice) / _Point;
         else if(g_hasSell)
            pipsToTP = (currentPrice - currentTP) / _Point;
      }

      // Calculate pips to SL
      double pipsToSL = 0;
      if(currentSL > 0)
      {
         if(g_hasBuy)
            pipsToSL = (currentSL - currentPrice) / _Point;
         else if(g_hasSell)
            pipsToSL = (currentPrice - currentSL) / _Point;
      }

      // Calculate pips from entry
      double pipsFromEntry = 0;
      if(g_avgPrice > 0)
      {
         if(g_hasBuy)
            pipsFromEntry = (currentPrice - g_avgPrice) / _Point;
         else if(g_hasSell)
            pipsFromEntry = (g_avgPrice - currentPrice) / _Point;
      }

      // Risk:Reward ratio
      double rr = 0;
      if(pipsToSL != 0 && pipsToTP != 0)
         rr = MathAbs(pipsToTP / pipsToSL);

      // Build info text
      boxText += "=== TRADE INFO ===\n";
      boxText += "Positions: " + IntegerToString(g_buyCount) + "B / " + IntegerToString(g_sellCount) + "S\n";
      boxText += "Total Lots: " + DoubleToString(g_totalCount * g_lot, 2) + "\n";
      boxText += "-------------------\n";
      boxText += "Entry: " + DoubleToString(g_avgPrice, _Digits) + "\n";
      boxText += "Price: " + DoubleToString(currentPrice, _Digits) + "\n";
      boxText += "P/L From Entry: " + DoubleToString(pipsFromEntry, 1) + " pips\n";
      boxText += "-------------------\n";

      if(currentTP > 0)
         boxText += "TP: " + DoubleToString(currentTP, _Digits) + " (" + DoubleToString(pipsToTP, 1) + " pips)\n";
      else
         boxText += "TP: OFF\n";

      if(currentSL > 0)
         boxText += "SL: " + DoubleToString(currentSL, _Digits) + " (" + DoubleToString(pipsToSL, 1) + " pips)\n";
      else
         boxText += "SL: OFF\n";

      if(Use_Trailing_Stop && !(g_hasBuy && g_hasSell))
      {
         double profitPips = 0;
         if(g_hasBuy) profitPips = (bid - g_avgPrice) / _Point;
         else if(g_hasSell) profitPips = (g_avgPrice - ask) / _Point;

         boxText += "Trail: " + DoubleToString(TrailingStartPips, 0) + " start / " +
                    DoubleToString(TrailingDistancePips, 0) + " dist\n";
         boxText += "Trail Active: " + (profitPips >= TrailingStartPips ? "YES" : "NO") + "\n";
      }

      boxText += "R:R: 1:" + DoubleToString(rr, 1) + "\n";
      boxText += "-------------------\n";
      boxText += "Profit: $" + DoubleToString(g_totalProfit, 2) + "\n";

      if(g_newsActive)
         boxText += "NEWS: PAUSED\n";

      // Create label as text object
      string infoLabel = "TRADE_INFO_LABEL";
      ObjectCreate(0, infoLabel, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, infoLabel, OBJPROP_XDISTANCE, InfoBoxX);
      ObjectSetInteger(0, infoLabel, OBJPROP_YDISTANCE, InfoBoxY);
      ObjectSetInteger(0, infoLabel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, infoLabel, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetString(0, infoLabel, OBJPROP_TEXT, boxText);
      ObjectSetString(0, infoLabel, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, infoLabel, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, infoLabel, OBJPROP_COLOR, clrLightGray);
      ObjectSetInteger(0, infoLabel, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, infoLabel, OBJPROP_HIDDEN, true);
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
void ManageEquityATRTrail()
{
   double atrVal[];
   ArraySetAsSeries(atrVal, true);
   if(CopyBuffer(g_equityAtrHandle, 0, 0, 1, atrVal) < 1) return;
   if(atrVal[0] <= 0) return;
   
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Close all when equity recovers to new peak after trail was activated
   if(g_equityTrailActive && EquityATR_CloseOnNewPeak && equity > g_peakEquity)
   {
      Print("EQUITY ATR TRAIL: New peak ", DoubleToString(equity, 2),
            " > old peak ", DoubleToString(g_peakEquity, 2), " - Closing all");
      CloseAllPositions();
      g_peakEquity = equity;
      g_equityTrailActive = false;
      return;
   }
   
   // Update peak equity
   if(equity > g_peakEquity)
      g_peakEquity = equity;
   
   // Calculate equity drop from peak in ATR units
   double dropFromPeak = (g_peakEquity - equity) / atrVal[0];
   
   // Convert enum to actual multiplier (enum values are 10x)
   double startMult = EquityATR_StartMult / 10.0;
   double closeMult = EquityATR_CloseMult / 10.0;
   
   // Activate trail when drop exceeds start multiplier
   if(dropFromPeak >= startMult)
      g_equityTrailActive = true;
   
   // Close when drop exceeds close multiplier
   if(g_equityTrailActive && dropFromPeak >= closeMult)
   {
      string sideStr = "All";
      if(EquityATR_CloseSide == 0)
      {
         CloseAllPositions();
         sideStr = "All";
      }
      else if(EquityATR_CloseSide == 1)
      {
         ClosePositionsByType(POSITION_TYPE_BUY);
         sideStr = "Buys";
      }
      else if(EquityATR_CloseSide == 2)
      {
         ClosePositionsByType(POSITION_TYPE_SELL);
         sideStr = "Sells";
      }
      else if(EquityATR_CloseSide == 3)
      {
         ClosePositionsByProfit(true); // close profitable
         sideStr = "Profitable";
      }
      
      Print("EQUITY ATR TRAIL: Closing ", sideStr, " - drop ", DoubleToString(dropFromPeak, 1),
            " ATR from peak ", DoubleToString(g_peakEquity, 2),
            " (threshold: ", DoubleToString(closeMult, 1), " ATR)");
      
      // Reset
      g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_equityTrailActive = false;
   }
}

//+------------------------------------------------------------------+
void ManageTimeframeSwitch()
{
   if(g_peakBalance == 0) g_peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   // Only check once per new bar to prevent flip-flopping
   static datetime lastTfCheck = 0;
   datetime currentBarTime = iTime(_Symbol, g_currentTimeframe, 0);
   if(currentBarTime == lastTfCheck) return;
   lastTfCheck = currentBarTime;

   double drawdown = 0;
   if(g_peakBalance > 0)
      drawdown = ((g_peakBalance - AccountInfoDouble(ACCOUNT_EQUITY)) / g_peakBalance) * 100.0;

   ENUM_TIMEFRAMES newTimeframe = Timeframe_Low;

   if(drawdown >= DD_High)
      newTimeframe = Timeframe_High;
   else if(drawdown >= DD_Low)
      newTimeframe = Timeframe_Mid;
   else if(Auto_Switch_Back)
      newTimeframe = Timeframe_Low;

   if(newTimeframe != g_currentTimeframe)
   {
      g_currentTimeframe = newTimeframe;
      g_timeframeChanged = true;
      Print("Timeframe switched: ", EnumToString(g_currentTimeframe), " (DD: ", DoubleToString(drawdown, 1), "%)");
   }

   if(Auto_Switch_Back && g_timeframeChanged && AccountInfoDouble(ACCOUNT_EQUITY) >= g_peakBalance)
   {
      g_currentTimeframe = Timeframe_Low;
      g_timeframeChanged = false;
      g_peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      Print("Timeframe back to M1 (profit recovered)");
   }
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Calculate ATR manually from price data - always works             |
//+------------------------------------------------------------------+
void CalculateManualATR()
{
   double tr[];
   ArraySetAsSeries(tr, true);
   int copied = CopyHigh(_Symbol, PERIOD_CURRENT, 0, ATR_Period + 1, tr);
   if(copied < ATR_Period + 1) return;

   double high[], low[], close[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   CopyHigh(_Symbol, PERIOD_CURRENT, 0, ATR_Period + 1, high);
   CopyLow(_Symbol, PERIOD_CURRENT, 0, ATR_Period + 1, low);
   CopyClose(_Symbol, PERIOD_CURRENT, 0, ATR_Period + 1, close);

   // Calculate True Range for each bar
   double trValues[];
   ArrayResize(trValues, ATR_Period + 1);
   for(int i = 0; i < ATR_Period && i < copied - 1; i++)
   {
      double hl = high[i] - low[i];
      double hc = MathAbs(high[i] - close[i+1]);
      double lc = MathAbs(low[i] - close[i+1]);
      trValues[i] = MathMax(hl, MathMax(hc, lc));
   }

   // Current ATR = average of last ATR_Period true ranges
   double sum = 0;
   for(int i = 0; i < ATR_Period; i++)
      sum += trValues[i];
   g_manualATR = sum / ATR_Period;

   // Previous ATR
   sum = 0;
   for(int i = 1; i <= ATR_Period; i++)
      sum += trValues[i];
   g_manualATR_prev = sum / ATR_Period;
}

//+------------------------------------------------------------------+
double GetATRValue()
{
   // Try indicator handle first
   if(g_atrHandle != INVALID_HANDLE)
   {
      double atrBuf[];
      ArraySetAsSeries(atrBuf, true);
      if(CopyBuffer(g_atrHandle, 0, 0, 1, atrBuf) == 1 && atrBuf[0] > 0)
         return atrBuf[0];
   }
   // Fallback to manual calculation
   CalculateManualATR();
   return g_manualATR;
}

//+------------------------------------------------------------------+
double GetATRPrevValue()
{
   if(g_atrHandle != INVALID_HANDLE)
   {
      double atrBuf[];
      ArraySetAsSeries(atrBuf, true);
      if(CopyBuffer(g_atrHandle, 0, 0, 2, atrBuf) == 2 && atrBuf[1] > 0)
         return atrBuf[1];
   }
   return g_manualATR_prev;
}

//+------------------------------------------------------------------+
bool CheckVolatilityFilter()
{
   if(!UseVolatilityFilter) return true;

   double curATR = GetATRValue();
   double prevATR = GetATRPrevValue();

   if(curATR <= 0 || prevATR <= 0)
      return true;

   double ratio = curATR / prevATR;

   // Throttle debug prints - only log once per 60 seconds per symbol
   static string lastAtrSymbol = "";
   static datetime lastAtrLog = 0;
   if(_Symbol != lastAtrSymbol || TimeCurrent() - lastAtrLog >= 60)
   {
      lastAtrSymbol = _Symbol;
      lastAtrLog = TimeCurrent();
      Print("ATR FILTER: cur=", DoubleToString(curATR, _Digits),
            " prev=", DoubleToString(prevATR, _Digits),
            " ratio=", DoubleToString(ratio, 2),
            " threshold=", DoubleToString(ATR_Multiplier, 1),
            (ratio > ATR_Multiplier ? " BLOCKED" : " PASSED"));
   }

   if(curATR > prevATR * ATR_Multiplier) return false;
   return true;
}

//+------------------------------------------------------------------+
bool CheckRangeFilter()
{
   if(!UseRangeFilter) return true;

   double high = iHigh(_Symbol, PERIOD_D1, 0);
   double low = iLow(_Symbol, PERIOD_D1, 0);

   // For crypto: range in price points (e.g. BTC 200-3000 points/day)
   // For forex: range in pips (e.g. EURUSD 50-200 pips/day)
   double rangeDisplay;
   double minRange;
   double maxRange;

   if(g_isCrypto)
   {
      rangeDisplay = (high - low) / _Point;  // range in points
      minRange = RangeMinPips * 100;   // scale user input for crypto
      maxRange = RangeMaxPips * 100;
   }
   else
   {
      rangeDisplay = (high - low) / _Point / (double)g_pointDivider;  // range in pips
      minRange = RangeMinPips;
      maxRange = RangeMaxPips;
   }

    // Debug print - throttle to once per 60 seconds per symbol
    static string lastRangeSymbol = "";
    static datetime lastRangeLog = 0;
    if(_Symbol != lastRangeSymbol || TimeCurrent() - lastRangeLog >= 60)
    {
       lastRangeSymbol = _Symbol;
       lastRangeLog = TimeCurrent();
       Print("RANGE FILTER: range=", DoubleToString(rangeDisplay, 1),
             " min=", DoubleToString(minRange, 1),
             " max=", DoubleToString(maxRange, 1),
             " high=", DoubleToString(high, _Digits),
             " low=", DoubleToString(low, _Digits),
             " point=", DoubleToString(_Point, _Digits));
       if(rangeDisplay < minRange || rangeDisplay > maxRange)
          Print("RANGE FILTER: BLOCKED (out of range)");
       else
          Print("RANGE FILTER: PASSED");
    }

    if(rangeDisplay < minRange || rangeDisplay > maxRange)
       return false;
    return true;
}

//+------------------------------------------------------------------+
void ModifyAllTP()
{
   if(g_totalCount == 0) return;

   g_lastModifyFailTime = 0;  // Reset at start
   g_lastServerFailTime = 0;  // Reset at start

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double currentTP = PositionGetDouble(POSITION_TP);
      long posType = PositionGetInteger(POSITION_TYPE);
      double pointVal = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      long stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double minTPDist = stopLevel * pointVal;

      if(g_hasBuy && g_hasSell)
      {
         if(Use_SeparateTP)
         {
            double targetTP = 0;
            if(posType == POSITION_TYPE_BUY)
               targetTP = g_buyTP;
            else if(posType == POSITION_TYPE_SELL)
               targetTP = g_sellTP;

            if(posType == POSITION_TYPE_BUY && targetTP > 0)
            {
               double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               if(targetTP - bid < minTPDist) targetTP = NormalizeDouble(bid + minTPDist, _Digits);
            }
            if(posType == POSITION_TYPE_SELL && targetTP > 0)
            {
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               if(ask - targetTP < minTPDist) targetTP = NormalizeDouble(ask - minTPDist, _Digits);
            }

            if(targetTP > 0 && MathAbs(currentTP - targetTP) > _Point)
            {
               if(!trade.PositionModify(ticket, 0, targetTP))
               {
                  g_lastModifyFailTime = TimeCurrent();
                  g_lastServerFailTime = TimeCurrent();
                  Print("SEPARATE TP FAIL #", ticket, " tp=", targetTP, " err=", trade.ResultRetcode());
               }
               else
                  Print("SEPARATE TP SET #", ticket, " tp=", targetTP);
            }
         }
         else
         {
            if(currentTP != 0)
            {
               if(!trade.PositionModify(ticket, 0, 0))
               {
                  g_lastModifyFailTime = TimeCurrent();
                  g_lastServerFailTime = TimeCurrent();
               }
            }
         }
      }
      else
      {
         if(g_newTP > 0)
         {
            if(posType == POSITION_TYPE_BUY)
            {
               double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               if(g_newTP - bid < minTPDist) g_newTP = NormalizeDouble(bid + minTPDist, _Digits);
            }
            else if(posType == POSITION_TYPE_SELL)
            {
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               if(ask - g_newTP < minTPDist) g_newTP = NormalizeDouble(ask - minTPDist, _Digits);
            }
            if(MathAbs(currentTP - g_newTP) > _Point)
            {
               if(!trade.PositionModify(ticket, 0, g_newTP))
               {
                  g_lastModifyFailTime = TimeCurrent();
                  g_lastServerFailTime = TimeCurrent();
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      if(!trade.PositionClose(ticket))
         g_lastServerFailTime = TimeCurrent();
      Sleep(100);
   }
}

//+------------------------------------------------------------------+
bool CheckDailyTarget()
{
   double todayProfit = 0;
   datetime dayStart = iTime(_Symbol, PERIOD_D1, 0);

   HistorySelect(0, TimeCurrent());

   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != g_magic) continue;
      if(HistoryDealGetInteger(ticket, DEAL_TIME) < dayStart) continue;

      int entry = (int)HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry == DEAL_ENTRY_IN || entry == DEAL_ENTRY_OUT)
      {
         todayProfit += HistoryDealGetDouble(ticket, DEAL_PROFIT)
                      + HistoryDealGetDouble(ticket, DEAL_COMMISSION)
                      + HistoryDealGetDouble(ticket, DEAL_SWAP);
      }
   }

   return (todayProfit >= Daily_Target);
}

//+------------------------------------------------------------------+
bool CheckTimeFilter()
{
   MqlDateTime dt;
   TimeCurrent(dt);

   if(!TradeOnThursday && dt.day_of_week == 4) return false;
   if(TradeOnThursday && dt.day_of_week == 4 && dt.hour > Thursday_Hour) return false;
   if(!TradeOnFriday && dt.day_of_week == 5) return false;
   if(TradeOnFriday && dt.day_of_week == 5 && dt.hour > Friday_Hour) return false;

   int openH = Open_Hour;
   int closeH = Close_Hour;

   if(openH == 24) openH = 0;
   if(closeH == 24) closeH = 0;

   if(openH < closeH)
   {
      if(dt.hour < openH || dt.hour >= closeH) return false;
   }
   else if(openH > closeH)
   {
      if(dt.hour < openH && dt.hour >= closeH) return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| SMC (Smart Money Concepts) FUNCTIONS                              |
//+------------------------------------------------------------------+
struct SMCDATA
{
   string structure;    // BULLISH, BEARISH, RANGING
   string bias;         // BUY, SELL, NEUTRAL
   int    obCount;      // Order Block count
   int    fvgCount;     // Fair Value Gap count
   int    bosCount;     // Break of Structure count
   int    eqhCount;     // Equal Highs (liquidity)
   int    eqlCount;     // Equal Lows (liquidity)
   double obSupport;    // Nearest OB support
   double obResistance; // Nearest OB resistance
   double fvgHigh;      // Nearest FVG high
   double fvgLow;       // Nearest FVG low
};

//--- ICT Data Structure
struct ICTDATA
{
   string killZone;          // ASIAN, LONDON, NY, LONDON_CLOSE, NONE
   string killZoneStatus;    // ACTIVE, UPCOMING, CLOSED
   int    killZoneMinsLeft;  // Minutes until kill zone ends
   string pdZone;            // PREMIUM, DISCOUNT, EQUILIBRIUM
   double pdLevel;           // Current price position in zone (0-100%)
   double equilibrium;       // 50% level of range
   double premiumTop;        // Top of premium zone
   double discountBottom;    // Bottom of discount zone
   string oteStatus;         // IN_OTE, ABOVE_OTE, BELOW_OTE
   double oteHigh;           // OTE zone high (79%)
   double oteLow;            // OTE zone low (61.8%)
   string mss;               // BULLISH_MSS, BEARISH_MSS, NONE
   int    ictOBCount;        // ICT Order Block count
   double ictOBHigh;         // Nearest ICT OB high
   double ictOBLow;          // Nearest ICT OB low
   string ictOBType;         // BULLISH_OB, BEARISH_OB, NONE
   int    ictFVGCount;       // ICT FVG count
   double ictFVGHigh;        // Nearest ICT FVG high
   double ictFVGLow;         // Nearest ICT FVG low
   string ictFVGType;        // BULLISH_FVG, BEARISH_FVG, NONE
   string ictLiquidity;      // BSL, SSL, BOTH, NONE (Buy-Side/Sell-Side Liquidity)
   int    ictLiqSweep;       // Liquidity sweep count
   string dailyBias;         // BULLISH, BEARISH, NEUTRAL
   string displacement;      // BULLISH_DISP, BEARISH_DISP, NONE
   double swingHigh;         // Recent swing high
   double swingLow;          // Recent swing low
   double rangeHigh;         // Range high
   double rangeLow;          // Range low
};

//+------------------------------------------------------------------+
SMCDATA AnalyzeSMC()
{
   SMCDATA smc;
   smc.structure = "RANGING";
   smc.bias = "NEUTRAL";
   smc.obCount = 0;
   smc.fvgCount = 0;
   smc.bosCount = 0;
   smc.eqhCount = 0;
   smc.eqlCount = 0;
   smc.obSupport = 0;
   smc.obResistance = 0;
   smc.fvgHigh = 0;
   smc.fvgLow = 0;

   int lookback = SMC_Lookback;
   if(lookback < 10) lookback = 10;

   double high[], low[], close[], open[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);

   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, lookback, high) < lookback) return smc;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, lookback, low) < lookback) return smc;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, lookback, close) < lookback) return smc;
   if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, lookback, open) < lookback) return smc;

   // Detect Swing Highs and Lows
   double swingHighs[], swingLows[];
   int swingHighCount = 0, swingLowCount = 0;
   ArrayResize(swingHighs, lookback);
   ArrayResize(swingLows, lookback);

   for(int i = 2; i < lookback - 2; i++)
   {
      if(high[i] > high[i-1] && high[i] > high[i-2] && high[i] > high[i+1] && high[i] > high[i+2])
      {
         swingHighs[swingHighCount] = high[i];
         swingHighCount++;
      }
      if(low[i] < low[i-1] && low[i] < low[i-2] && low[i] < low[i+1] && low[i] < low[i+2])
      {
         swingLows[swingLowCount] = low[i];
         swingLowCount++;
      }
   }

   // Market Structure Analysis
   if(swingHighCount >= 2 && swingLowCount >= 2)
   {
      bool higherHigh = swingHighs[0] > swingHighs[1];
      bool higherLow = swingLows[0] > swingLows[1];
      bool lowerHigh = swingHighs[0] < swingHighs[1];
      bool lowerLow = swingLows[0] < swingLows[1];

      if(higherHigh && higherLow)
      {
         smc.structure = "BULLISH";
         smc.bias = "BUY";
      }
      else if(lowerHigh && lowerLow)
      {
         smc.structure = "BEARISH";
         smc.bias = "SELL";
      }
      else
      {
         smc.structure = "RANGING";
         smc.bias = "NEUTRAL";
      }
   }

   // Order Block Detection (last opposing candle before strong move)
   if(ShowOrderBlocks)
   {
      for(int i = 3; i < lookback - 1; i++)
      {
         double bodySize = MathAbs(close[i] - open[i]);
         double nextBody = MathAbs(close[i-1] - open[i-1]);

         // Bullish OB: bearish candle followed by strong bullish move
         if(close[i] < open[i] && close[i-1] > open[i-1] && nextBody > bodySize * 1.5)
         {
            smc.obCount++;
            if(smc.obSupport == 0 || low[i] > smc.obSupport)
               smc.obSupport = low[i];
         }
         // Bearish OB: bullish candle followed by strong bearish move
         if(close[i] > open[i] && close[i-1] < open[i-1] && nextBody > bodySize * 1.5)
         {
            smc.obCount++;
            if(smc.obResistance == 0 || high[i] < smc.obResistance)
               smc.obResistance = high[i];
         }
      }
   }

   // Fair Value Gap Detection (3-candle imbalance)
   if(ShowFVG)
   {
      for(int i = 2; i < lookback - 1; i++)
      {
         // Bullish FVG: gap between candle[i+1] high and candle[i-1] low
         if(low[i+1] > high[i-1])
         {
            smc.fvgCount++;
            if(smc.fvgHigh == 0 || high[i+1] > smc.fvgHigh)
               smc.fvgHigh = high[i+1];
            if(smc.fvgLow == 0 || low[i-1] < smc.fvgLow)
               smc.fvgLow = low[i-1];
         }
         // Bearish FVG: gap between candle[i-1] low and candle[i+1] high
         if(high[i+1] < low[i-1])
         {
            smc.fvgCount++;
            if(smc.fvgHigh == 0 || high[i-1] > smc.fvgHigh)
               smc.fvgHigh = high[i-1];
            if(smc.fvgLow == 0 || low[i+1] < smc.fvgLow)
               smc.fvgLow = low[i+1];
         }
      }
   }

   // Break of Structure Detection
   if(ShowBOS && swingHighCount >= 2 && swingLowCount >= 2)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      // BOS Bullish: price breaks above previous swing high
      if(bid > swingHighs[1])
         smc.bosCount++;
      // BOS Bearish: price breaks below previous swing low
      if(bid < swingLows[1])
         smc.bosCount++;
   }

   // Liquidity Detection (Equal Highs/Lows)
   if(ShowLiquidity)
   {
      double tolerance = _Point * 100; // 10 pips tolerance

      for(int i = 0; i < swingHighCount - 1; i++)
      {
         if(MathAbs(swingHighs[i] - swingHighs[i+1]) < tolerance)
            smc.eqhCount++;
      }
      for(int i = 0; i < swingLowCount - 1; i++)
      {
         if(MathAbs(swingLows[i] - swingLows[i+1]) < tolerance)
            smc.eqlCount++;
      }
   }

   return smc;
}

//+------------------------------------------------------------------+
//| ICT (Inner Circle Trader) ANALYSIS                                |
//+------------------------------------------------------------------+
ICTDATA AnalyzeICT()
{
   ICTDATA ict;
   ict.killZone = "NONE";
   ict.killZoneStatus = "CLOSED";
   ict.killZoneMinsLeft = 0;
   ict.pdZone = "EQUILIBRIUM";
   ict.pdLevel = 50;
   ict.equilibrium = 0;
   ict.premiumTop = 0;
   ict.discountBottom = 0;
   ict.oteStatus = "NONE";
   ict.oteHigh = 0;
   ict.oteLow = 0;
   ict.mss = "NONE";
   ict.ictOBCount = 0;
   ict.ictOBHigh = 0;
   ict.ictOBLow = 0;
   ict.ictOBType = "NONE";
   ict.ictFVGCount = 0;
   ict.ictFVGHigh = 0;
   ict.ictFVGLow = 0;
   ict.ictFVGType = "NONE";
   ict.ictLiquidity = "NONE";
   ict.ictLiqSweep = 0;
   ict.dailyBias = "NEUTRAL";
   ict.displacement = "NONE";
   ict.swingHigh = 0;
   ict.swingLow = 0;
   ict.rangeHigh = 0;
   ict.rangeLow = 0;

   // === KILL ZONE DETECTION (UTC times) ===
   MqlDateTime dt;
   TimeCurrent(dt);
   int utcHour = dt.hour;
   int utcMin = dt.min;
   int currentMins = utcHour * 60 + utcMin;

   // Asian Kill Zone: 00:00 - 03:00 UTC
   int asianStart = 0;
   int asianEnd = 180;
   // London Kill Zone: 07:00 - 10:00 UTC
   int londonStart = 420;
   int londonEnd = 600;
   // New York Kill Zone: 12:00 - 15:00 UTC
   int nyStart = 720;
   int nyEnd = 900;
   // London Close: 15:00 - 17:00 UTC
   int lonCloseStart = 900;
   int lonCloseEnd = 1020;

   if(currentMins >= asianStart && currentMins < asianEnd)
   {
      ict.killZone = "ASIAN";
      ict.killZoneStatus = "ACTIVE";
      ict.killZoneMinsLeft = asianEnd - currentMins;
   }
   else if(currentMins >= londonStart && currentMins < londonEnd)
   {
      ict.killZone = "LONDON";
      ict.killZoneStatus = "ACTIVE";
      ict.killZoneMinsLeft = londonEnd - currentMins;
   }
   else if(currentMins >= nyStart && currentMins < nyEnd)
   {
      ict.killZone = "NY";
      ict.killZoneStatus = "ACTIVE";
      ict.killZoneMinsLeft = nyEnd - currentMins;
   }
   else if(currentMins >= lonCloseStart && currentMins < lonCloseEnd)
   {
      ict.killZone = "LDN_CLOSE";
      ict.killZoneStatus = "ACTIVE";
      ict.killZoneMinsLeft = lonCloseEnd - currentMins;
   }
   else
   {
      // Find next upcoming kill zone
      if(currentMins < asianStart)
      {
         ict.killZone = "ASIAN";
         ict.killZoneStatus = "UPCOMING";
         ict.killZoneMinsLeft = asianStart - currentMins;
      }
      else if(currentMins < londonStart)
      {
         ict.killZone = "LONDON";
         ict.killZoneStatus = "UPCOMING";
         ict.killZoneMinsLeft = londonStart - currentMins;
      }
      else if(currentMins < nyStart)
      {
         ict.killZone = "NY";
         ict.killZoneStatus = "UPCOMING";
         ict.killZoneMinsLeft = nyStart - currentMins;
      }
      else if(currentMins < lonCloseStart)
      {
         ict.killZone = "LDN_CLOSE";
         ict.killZoneStatus = "UPCOMING";
         ict.killZoneMinsLeft = lonCloseStart - currentMins;
      }
      else
      {
         ict.killZone = "ASIAN";
         ict.killZoneStatus = "UPCOMING";
         ict.killZoneMinsLeft = (1440 - currentMins) + asianStart;
      }
   }

   // === DATA COLLECTION ===
   int lookback = ICT_Lookback;
   if(lookback < 20) lookback = 20;

   double high[], low[], close[], open[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);

   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, lookback, high) < lookback) return ict;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, lookback, low) < lookback) return ict;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, lookback, close) < lookback) return ict;
   if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, lookback, open) < lookback) return ict;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double currentPrice = (bid + ask) / 2.0;

   // === SWING HIGH/LOW DETECTION ===
   double swingHighs[], swingLows[];
   int swingHighCount = 0, swingLowCount = 0;
   ArrayResize(swingHighs, lookback);
   ArrayResize(swingLows, lookback);

   for(int i = 2; i < lookback - 2; i++)
   {
      if(high[i] > high[i-1] && high[i] > high[i-2] && high[i] > high[i+1] && high[i] > high[i+2])
      {
         swingHighs[swingHighCount] = high[i];
         swingHighCount++;
      }
      if(low[i] < low[i-1] && low[i] < low[i-2] && low[i] < low[i+1] && low[i] < low[i+2])
      {
         swingLows[swingLowCount] = low[i];
         swingLowCount++;
      }
   }

   // Use most recent swing high/low for range
   if(swingHighCount > 0) ict.swingHigh = swingHighs[0];
   if(swingLowCount > 0) ict.swingLow = swingLows[0];

   // Use daily range for premium/discount
   double dailyHigh = iHigh(_Symbol, PERIOD_D1, 0);
   double dailyLow = iLow(_Symbol, PERIOD_D1, 0);
   ict.rangeHigh = dailyHigh;
   ict.rangeLow = dailyLow;

   // === PREMIUM / DISCOUNT ZONE ===
   double range = dailyHigh - dailyLow;
   if(range > 0)
   {
      ict.equilibrium = dailyLow + (range * 0.5);
      ict.premiumTop = dailyLow + (range * 0.5);
      ict.discountBottom = dailyLow + (range * 0.5);

      ict.pdLevel = ((currentPrice - dailyLow) / range) * 100.0;

      if(currentPrice > ict.equilibrium)
         ict.pdZone = "PREMIUM";
      else if(currentPrice < ict.equilibrium)
         ict.pdZone = "DISCOUNT";
      else
         ict.pdZone = "EQUILIBRIUM";
   }

   // === OTE (Optimal Trade Entry) ===
   if(swingHighCount > 0 && swingLowCount > 0)
   {
      double oteRange = ict.swingHigh - ict.swingLow;
      if(oteRange > 0)
      {
         ict.oteHigh = ict.swingHigh - (oteRange * (1.0 - OTE_FibHigh));
         ict.oteLow = ict.swingHigh - (oteRange * (1.0 - OTE_FibLow));

         if(currentPrice >= ict.oteLow && currentPrice <= ict.oteHigh)
            ict.oteStatus = "IN_OTE";
         else if(currentPrice > ict.oteHigh)
            ict.oteStatus = "ABOVE_OTE";
         else
            ict.oteStatus = "BELOW_OTE";
      }
   }

   // === MARKET STRUCTURE SHIFT (MSS) ===
   if(swingHighCount >= 3 && swingLowCount >= 3)
   {
      // Bullish MSS: Higher Low formed after break of previous structure
      bool hlFormation = swingLows[0] > swingLows[1] && swingLows[1] > swingLows[2];
      bool hhFormation = swingHighs[0] > swingHighs[1] && swingHighs[1] > swingHighs[2];

      // Bearish MSS: Lower High formed after break of previous structure
      bool lhFormation = swingHighs[0] < swingHighs[1] && swingHighs[1] < swingHighs[2];
      bool llFormation = swingLows[0] < swingLows[1] && swingLows[1] < swingLows[2];

      if(hlFormation && hhFormation)
         ict.mss = "BULLISH_MSS";
      else if(lhFormation && llFormation)
         ict.mss = "BEARISH_MSS";

      // Also detect BOS-based MSS
      if(bid > swingHighs[1] && bid > swingHighs[2])
      {
         if(ict.mss == "NONE")
            ict.mss = "BULLISH_MSS";
      }
      if(bid < swingLows[1] && bid < swingLows[2])
      {
         if(ict.mss == "NONE")
            ict.mss = "BEARISH_MSS";
      }
   }

   // === ICT ORDER BLOCKS ===
   if(ShowICTOrderBlocks)
   {
      for(int i = 3; i < lookback - 1; i++)
      {
         double bodySize = MathAbs(close[i] - open[i]);
         double nextBody = MathAbs(close[i-1] - open[i-1]);

         // Bullish OB: Last bearish candle before strong bullish displacement
         if(close[i] < open[i] && close[i-1] > open[i-1] && nextBody > bodySize * DisplacementRatio)
         {
            ict.ictOBCount++;
            ict.ictOBHigh = high[i];
            ict.ictOBLow = low[i];
            ict.ictOBType = "BULLISH_OB";
         }
         // Bearish OB: Last bullish candle before strong bearish displacement
         if(close[i] > open[i] && close[i-1] < open[i-1] && nextBody > bodySize * DisplacementRatio)
         {
            ict.ictOBCount++;
            ict.ictOBHigh = high[i];
            ict.ictOBLow = low[i];
            ict.ictOBType = "BEARISH_OB";
         }
      }
   }

   // === ICT FAIR VALUE GAPS ===
   if(ShowICTFVG)
   {
      for(int i = 2; i < lookback - 1; i++)
      {
         // Bullish FVG: gap between candle[i+1] high and candle[i-1] low
         if(low[i+1] > high[i-1])
         {
            ict.ictFVGCount++;
            ict.ictFVGHigh = high[i+1];
            ict.ictFVGLow = high[i-1];
            ict.ictFVGType = "BULLISH_FVG";
         }
         // Bearish FVG: gap between candle[i-1] low and candle[i+1] high
         if(high[i+1] < low[i-1])
         {
            ict.ictFVGCount++;
            ict.ictFVGHigh = low[i-1];
            ict.ictFVGLow = low[i+1];
            ict.ictFVGType = "BEARISH_FVG";
         }
      }
   }

   // === ICT LIQUIDITY LEVELS ===
   if(ShowICTLiquidity)
   {
      double tolerance = _Point * LiquidityTolerance * 10.0;
      int bslCount = 0; // Buy-side liquidity (equal highs)
      int sslCount = 0; // Sell-side liquidity (equal lows)

      for(int i = 0; i < swingHighCount - 1; i++)
      {
         if(MathAbs(swingHighs[i] - swingHighs[i+1]) < tolerance)
            bslCount++;
      }
      for(int i = 0; i < swingLowCount - 1; i++)
      {
         if(MathAbs(swingLows[i] - swingLows[i+1]) < tolerance)
            sslCount++;
      }

      if(bslCount > 0 && sslCount > 0)
         ict.ictLiquidity = "BOTH";
      else if(bslCount > 0)
         ict.ictLiquidity = "BSL";
      else if(sslCount > 0)
         ict.ictLiquidity = "SSL";

      // Detect liquidity sweeps (price took out swing high/low and reversed)
      for(int i = 1; i < lookback - 1; i++)
      {
         // Sweep highs: price went above swing high then closed below
         if(high[i] > swingHighs[0] && close[i] < swingHighs[0] && swingHighCount > 0)
            ict.ictLiqSweep++;
         // Sweep lows: price went below swing low then closed above
         if(low[i] < swingLows[0] && close[i] > swingLows[0] && swingLowCount > 0)
            ict.ictLiqSweep++;
      }
   }

   // === DAILY BIAS ===
   if(ShowDailyBias)
   {
      // Use previous day's close vs open for bias
      double prevClose = iClose(_Symbol, PERIOD_D1, 1);
      double prevOpen = iOpen(_Symbol, PERIOD_D1, 1);

      // ICT: Daily bias based on previous day's price action
      if(prevClose > prevOpen)
         ict.dailyBias = "BULLISH";
      else if(prevClose < prevOpen)
         ict.dailyBias = "BEARISH";
      else
         ict.dailyBias = "NEUTRAL";

      // Also consider current day's opening
      double todayOpen = iOpen(_Symbol, PERIOD_D1, 0);
      if(currentPrice > todayOpen && ict.dailyBias == "BEARISH")
         ict.dailyBias = "BULLISH";
      else if(currentPrice < todayOpen && ict.dailyBias == "BULLISH")
         ict.dailyBias = "BEARISH";
   }

   // === DISPLACEMENT DETECTION ===
   if(ShowDisplacement)
   {
      for(int i = 1; i < lookback - 1 && ict.displacement == "NONE"; i++)
      {
         double bodySize = MathAbs(close[i] - open[i]);
         double avgRange = 0;
         int count = 0;

         // Calculate average range of nearby candles
         for(int j = MathMax(0, i-5); j < i; j++)
         {
            avgRange += MathAbs(close[j] - open[j]);
            count++;
         }
         if(count > 0) avgRange /= count;

         // Displacement: body is significantly larger than average
         if(avgRange > 0 && bodySize > avgRange * DisplacementRatio)
         {
            if(close[i] > open[i])
               ict.displacement = "BULLISH_DISP";
            else
               ict.displacement = "BEARISH_DISP";
         }
      }
   }

   return ict;
}

//+------------------------------------------------------------------+
//| DRAW ICT CONCEPTS ON CHART                                        |
//+------------------------------------------------------------------+
void DrawICTChartObjects()
{
   ObjectsDeleteAll(0, "ICT_");

   ICTDATA ict = AnalyzeICT();

   int lookback = ICT_Lookback;
   if(lookback < 20) lookback = 20;

   double high[], low[], close[], open[];
   datetime time[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(time, true);

   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, lookback, high) < lookback) return;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, lookback, low) < lookback) return;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, lookback, close) < lookback) return;
   if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, lookback, open) < lookback) return;
   if(CopyTime(_Symbol, PERIOD_CURRENT, 0, lookback, time) < lookback) return;

   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // === ORDER BLOCKS ===
   if(DrawOB_OnChart)
   {
      for(int i = 3; i < lookback - 1; i++)
      {
         double bodySize = MathAbs(close[i] - open[i]);
         double nextBody = MathAbs(close[i-1] - open[i-1]);

         // Bullish OB
         if(close[i] < open[i] && close[i-1] > open[i-1] && nextBody > bodySize * DisplacementRatio)
         {
            string name = "ICT_OB_BULL_" + IntegerToString(i);
            datetime t1 = time[i+1];
            datetime t2 = time[i-1];
            double obHigh = high[i];
            double obLow = low[i];

            ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, obHigh, t2, obLow);
            ObjectSetInteger(0, name, OBJPROP_COLOR, OB_BullColor);
            ObjectSetInteger(0, name, OBJPROP_FILL, true);
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

            // Label
            string lbl = name + "_LBL";
            ObjectCreate(0, lbl, OBJ_TEXT, 0, t1, obHigh);
            ObjectSetString(0, lbl, OBJPROP_TEXT, "OB");
            ObjectSetInteger(0, lbl, OBJPROP_COLOR, OB_BullColor);
            ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
            ObjectSetString(0, lbl, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lbl, OBJPROP_HIDDEN, true);
         }
         // Bearish OB
         if(close[i] > open[i] && close[i-1] < open[i-1] && nextBody > bodySize * DisplacementRatio)
         {
            string name = "ICT_OB_BEAR_" + IntegerToString(i);
            datetime t1 = time[i+1];
            datetime t2 = time[i-1];
            double obHigh = high[i];
            double obLow = low[i];

            ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, obHigh, t2, obLow);
            ObjectSetInteger(0, name, OBJPROP_COLOR, OB_BearColor);
            ObjectSetInteger(0, name, OBJPROP_FILL, true);
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

            // Label
            string lbl = name + "_LBL";
            ObjectCreate(0, lbl, OBJ_TEXT, 0, t1, obHigh);
            ObjectSetString(0, lbl, OBJPROP_TEXT, "OB");
            ObjectSetInteger(0, lbl, OBJPROP_COLOR, OB_BearColor);
            ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
            ObjectSetString(0, lbl, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lbl, OBJPROP_HIDDEN, true);
         }
      }
   }

   // === FAIR VALUE GAPS ===
   if(DrawFVG_OnChart)
   {
      for(int i = 2; i < lookback - 1; i++)
      {
         // Bullish FVG
         if(low[i+1] > high[i-1])
         {
            string name = "ICT_FVG_BULL_" + IntegerToString(i);
            datetime t1 = time[i+1];
            datetime t2 = time[i-1];
            double fvgHigh = low[i+1];
            double fvgLow = high[i-1];

            ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, fvgHigh, t2, fvgLow);
            ObjectSetInteger(0, name, OBJPROP_COLOR, FVG_BullColor);
            ObjectSetInteger(0, name, OBJPROP_FILL, true);
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

            string lbl = name + "_LBL";
            ObjectCreate(0, lbl, OBJ_TEXT, 0, t1, fvgHigh);
            ObjectSetString(0, lbl, OBJPROP_TEXT, "FVG");
            ObjectSetInteger(0, lbl, OBJPROP_COLOR, FVG_BullColor);
            ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 7);
            ObjectSetString(0, lbl, OBJPROP_FONT, "Arial");
            ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lbl, OBJPROP_HIDDEN, true);
         }
         // Bearish FVG
         if(high[i+1] < low[i-1])
         {
            string name = "ICT_FVG_BEAR_" + IntegerToString(i);
            datetime t1 = time[i+1];
            datetime t2 = time[i-1];
            double fvgHigh = low[i-1];
            double fvgLow = high[i+1];

            ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, fvgHigh, t2, fvgLow);
            ObjectSetInteger(0, name, OBJPROP_COLOR, FVG_BearColor);
            ObjectSetInteger(0, name, OBJPROP_FILL, true);
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

            string lbl = name + "_LBL";
            ObjectCreate(0, lbl, OBJ_TEXT, 0, t1, fvgHigh);
            ObjectSetString(0, lbl, OBJPROP_TEXT, "FVG");
            ObjectSetInteger(0, lbl, OBJPROP_COLOR, FVG_BearColor);
            ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 7);
            ObjectSetString(0, lbl, OBJPROP_FONT, "Arial");
            ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lbl, OBJPROP_HIDDEN, true);
         }
      }
   }

   // === LIQUIDITY LEVELS ===
   if(DrawLiq_OnChart)
   {
      double tolerance = _Point * LiquidityTolerance * 10.0;

      // Detect swing highs/lows
      double swingHighs[], swingLows[];
      int shCount = 0, slCount = 0;
      ArrayResize(swingHighs, lookback);
      ArrayResize(swingLows, lookback);

      for(int i = 2; i < lookback - 2; i++)
      {
         if(high[i] > high[i-1] && high[i] > high[i-2] && high[i] > high[i+1] && high[i] > high[i+2])
         {
            swingHighs[shCount] = high[i];
            shCount++;
         }
         if(low[i] < low[i-1] && low[i] < low[i-2] && low[i] < low[i+1] && low[i] < low[i+2])
         {
            swingLows[slCount] = low[i];
            slCount++;
         }
      }

      // Buy-Side Liquidity (Equal Highs)
      for(int i = 0; i < shCount - 1; i++)
      {
         if(MathAbs(swingHighs[i] - swingHighs[i+1]) < tolerance)
         {
            string name = "ICT_BSL_" + IntegerToString(i);
            ObjectCreate(0, name, OBJ_HLINE, 0, 0, swingHighs[i]);
            ObjectSetInteger(0, name, OBJPROP_COLOR, LiqColor);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, ICT_LineWidth);
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

            string lbl = name + "_LBL";
            ObjectCreate(0, lbl, OBJ_TEXT, 0, barTime, swingHighs[i]);
            ObjectSetString(0, lbl, OBJPROP_TEXT, "BSL");
            ObjectSetInteger(0, lbl, OBJPROP_COLOR, LiqColor);
            ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 7);
            ObjectSetString(0, lbl, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, lbl, OBJPROP_ANCHOR, ANCHOR_LEFT);
            ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lbl, OBJPROP_HIDDEN, true);
         }
      }

      // Sell-Side Liquidity (Equal Lows)
      for(int i = 0; i < slCount - 1; i++)
      {
         if(MathAbs(swingLows[i] - swingLows[i+1]) < tolerance)
         {
            string name = "ICT_SSL_" + IntegerToString(i);
            ObjectCreate(0, name, OBJ_HLINE, 0, 0, swingLows[i]);
            ObjectSetInteger(0, name, OBJPROP_COLOR, LiqColor);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, ICT_LineWidth);
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

            string lbl = name + "_LBL";
            ObjectCreate(0, lbl, OBJ_TEXT, 0, barTime, swingLows[i]);
            ObjectSetString(0, lbl, OBJPROP_TEXT, "SSL");
            ObjectSetInteger(0, lbl, OBJPROP_COLOR, LiqColor);
            ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 7);
            ObjectSetString(0, lbl, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, lbl, OBJPROP_ANCHOR, ANCHOR_LEFT);
            ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lbl, OBJPROP_HIDDEN, true);
         }
      }
   }

   // === PREMIUM / DISCOUNT ZONE ===
   if(DrawPDZ_OnChart)
   {
      double dailyHigh = iHigh(_Symbol, PERIOD_D1, 0);
      double dailyLow = iLow(_Symbol, PERIOD_D1, 0);
      double eq = dailyLow + (dailyHigh - dailyLow) * 0.5;

      // Equilibrium line
      string eqName = "ICT_EQ";
      ObjectCreate(0, eqName, OBJ_HLINE, 0, 0, eq);
      ObjectSetInteger(0, eqName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, eqName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, eqName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, eqName, OBJPROP_BACK, true);
      ObjectSetInteger(0, eqName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, eqName, OBJPROP_HIDDEN, true);

      string eqLbl = "ICT_EQ_LBL";
      ObjectCreate(0, eqLbl, OBJ_TEXT, 0, barTime, eq);
      ObjectSetString(0, eqLbl, OBJPROP_TEXT, "EQ " + DoubleToString(eq, _Digits));
      ObjectSetInteger(0, eqLbl, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, eqLbl, OBJPROP_FONTSIZE, 7);
      ObjectSetString(0, eqLbl, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, eqLbl, OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetInteger(0, eqLbl, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, eqLbl, OBJPROP_HIDDEN, true);

      // Premium zone background
      datetime dayStart = iTime(_Symbol, PERIOD_D1, 0);
      string premName = "ICT_PREMIUM";
      ObjectCreate(0, premName, OBJ_RECTANGLE, 0, dayStart, dailyHigh, barTime, eq);
      ObjectSetInteger(0, premName, OBJPROP_COLOR, PDZ_PremiumColor);
      ObjectSetInteger(0, premName, OBJPROP_FILL, true);
      ObjectSetInteger(0, premName, OBJPROP_BACK, true);
      ObjectSetInteger(0, premName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, premName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, premName, OBJPROP_STYLE, STYLE_SOLID);

      // Discount zone background
      string discName = "ICT_DISCOUNT";
      ObjectCreate(0, discName, OBJ_RECTANGLE, 0, dayStart, eq, barTime, dailyLow);
      ObjectSetInteger(0, discName, OBJPROP_COLOR, PDZ_DiscountColor);
      ObjectSetInteger(0, discName, OBJPROP_FILL, true);
      ObjectSetInteger(0, discName, OBJPROP_BACK, true);
      ObjectSetInteger(0, discName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, discName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, discName, OBJPROP_STYLE, STYLE_SOLID);
   }

   // === OTE ZONE ===
   if(DrawOTE_OnChart && ict.swingHigh > 0 && ict.swingLow > 0)
   {
      double oteRange = ict.swingHigh - ict.swingLow;
      if(oteRange > 0)
      {
         double oteHi = ict.swingHigh - (oteRange * (1.0 - OTE_FibHigh));
         double oteLo = ict.swingHigh - (oteRange * (1.0 - OTE_FibLow));

         string oteName = "ICT_OTE";
         datetime oteStart = time[lookback - 1];
         ObjectCreate(0, oteName, OBJ_RECTANGLE, 0, oteStart, oteHi, barTime, oteLo);
         ObjectSetInteger(0, oteName, OBJPROP_COLOR, OTE_Color);
         ObjectSetInteger(0, oteName, OBJPROP_FILL, true);
         ObjectSetInteger(0, oteName, OBJPROP_BACK, true);
         ObjectSetInteger(0, oteName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, oteName, OBJPROP_HIDDEN, true);

         // OTE labels
         string hiLbl = "ICT_OTE_HI";
         ObjectCreate(0, hiLbl, OBJ_TEXT, 0, barTime, oteHi);
         ObjectSetString(0, hiLbl, OBJPROP_TEXT, "OTE " + DoubleToString(OTE_FibHigh * 100, 0) + "%");
         ObjectSetInteger(0, hiLbl, OBJPROP_COLOR, OTE_Color);
         ObjectSetInteger(0, hiLbl, OBJPROP_FONTSIZE, 7);
         ObjectSetString(0, hiLbl, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, hiLbl, OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetInteger(0, hiLbl, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, hiLbl, OBJPROP_HIDDEN, true);

         string loLbl = "ICT_OTE_LO";
         ObjectCreate(0, loLbl, OBJ_TEXT, 0, barTime, oteLo);
         ObjectSetString(0, loLbl, OBJPROP_TEXT, "OTE " + DoubleToString(OTE_FibLow * 100, 0) + "%");
         ObjectSetInteger(0, loLbl, OBJPROP_COLOR, OTE_Color);
         ObjectSetInteger(0, loLbl, OBJPROP_FONTSIZE, 7);
         ObjectSetString(0, loLbl, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, loLbl, OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetInteger(0, loLbl, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, loLbl, OBJPROP_HIDDEN, true);
      }
   }

   // === KILL ZONE LINES ===
   if(DrawKZ_OnChart)
   {
      MqlDateTime dt;
      TimeCurrent(dt);
      int utcHour = dt.hour;
      int utcMin = dt.min;
      int currentMins = utcHour * 60 + utcMin;

      struct KZDef { int start; int end; string name; };
      KZDef kz[4];
      kz[0].start = 0;    kz[0].end = 180;  kz[0].name = "ASIAN";
      kz[1].start = 420;  kz[1].end = 600;  kz[1].name = "LONDON";
      kz[2].start = 720;  kz[2].end = 900;  kz[2].name = "NY";
      kz[3].start = 900;  kz[3].end = 1020; kz[3].name = "LDN_CLOSE";

      for(int k = 0; k < 4; k++)
      {
         // Current bar's kill zone
         datetime kzStart = iTime(_Symbol, PERIOD_D1, 0) + kz[k].start * 60;
         datetime kzEnd = iTime(_Symbol, PERIOD_D1, 0) + kz[k].end * 60;

         // Only draw if in range of visible bars
         if(kzEnd >= time[lookback - 1] && kzStart <= barTime)
         {
            string kzName = "ICT_KZ_" + kz[k].name;
            double kzHigh = iHigh(_Symbol, PERIOD_D1, 0);
            double kzLow = iLow(_Symbol, PERIOD_D1, 0);

            ObjectCreate(0, kzName, OBJ_RECTANGLE, 0, kzStart, kzHigh, kzEnd, kzLow);
            ObjectSetInteger(0, kzName, OBJPROP_COLOR, KZ_LineColor);
            ObjectSetInteger(0, kzName, OBJPROP_FILL, true);
            ObjectSetInteger(0, kzName, OBJPROP_BACK, true);
            ObjectSetInteger(0, kzName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, kzName, OBJPROP_HIDDEN, true);
            ObjectSetInteger(0, kzName, OBJPROP_STYLE, STYLE_SOLID);

            // KZ label
            string kzLbl = kzName + "_LBL";
            datetime lblTime = kzStart + (kzEnd - kzStart) / 2;
            ObjectCreate(0, kzLbl, OBJ_TEXT, 0, lblTime, kzHigh);
            ObjectSetString(0, kzLbl, OBJPROP_TEXT, kz[k].name);
            ObjectSetInteger(0, kzLbl, OBJPROP_COLOR, KZ_LineColor);
            ObjectSetInteger(0, kzLbl, OBJPROP_FONTSIZE, 7);
            ObjectSetString(0, kzLbl, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, kzLbl, OBJPROP_ANCHOR, ANCHOR_CENTER);
            ObjectSetInteger(0, kzLbl, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, kzLbl, OBJPROP_HIDDEN, true);
         }
      }
   }

   // === MSS / BOS LABELS ===
   if(DrawMSS_OnChart)
   {
      // Detect swing points
      double swingHighs[], swingLows[];
      datetime swingHighTimes[], swingLowTimes[];
      int shCount = 0, slCount = 0;
      ArrayResize(swingHighs, lookback);
      ArrayResize(swingLows, lookback);
      ArrayResize(swingHighTimes, lookback);
      ArrayResize(swingLowTimes, lookback);

      for(int i = 2; i < lookback - 2; i++)
      {
         if(high[i] > high[i-1] && high[i] > high[i-2] && high[i] > high[i+1] && high[i] > high[i+2])
         {
            swingHighs[shCount] = high[i];
            swingHighTimes[shCount] = time[i];
            shCount++;
         }
         if(low[i] < low[i-1] && low[i] < low[i-2] && low[i] < low[i+1] && low[i] < low[i+2])
         {
            swingLows[slCount] = low[i];
            swingLowTimes[slCount] = time[i];
            slCount++;
         }
      }

      // BOS / MSS detection
      if(shCount >= 2 && slCount >= 2)
      {
         // Bullish BOS: price breaks above recent swing high
         if(bid > swingHighs[1])
         {
            string name = "ICT_BOS_BULL";
            ObjectCreate(0, name, OBJ_TEXT, 0, swingHighTimes[1], swingHighs[1]);
            ObjectSetString(0, name, OBJPROP_TEXT, "BOS");
            ObjectSetInteger(0, name, OBJPROP_COLOR, C'0,200,150');
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
            ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LOWER);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         }

         // Bearish BOS: price breaks below recent swing low
         if(bid < swingLows[1])
         {
            string name = "ICT_BOS_BEAR";
            ObjectCreate(0, name, OBJ_TEXT, 0, swingLowTimes[1], swingLows[1]);
            ObjectSetString(0, name, OBJPROP_TEXT, "BOS");
            ObjectSetInteger(0, name, OBJPROP_COLOR, C'230,80,80');
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
            ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         }

         // MSS: Higher High + Higher Low = Bullish MSS
         if(shCount >= 3 && slCount >= 3)
         {
            bool hlFormation = swingLows[0] > swingLows[1] && swingLows[1] > swingLows[2];
            bool hhFormation = swingHighs[0] > swingHighs[1] && swingHighs[1] > swingHighs[2];

            if(hlFormation && hhFormation)
            {
               string name = "ICT_MSS_BULL";
               ObjectCreate(0, name, OBJ_TEXT, 0, swingLowTimes[0], swingLows[0]);
               ObjectSetString(0, name, OBJPROP_TEXT, "MSS");
               ObjectSetInteger(0, name, OBJPROP_COLOR, C'0,200,150');
               ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
               ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
               ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
               ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
               ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
            }

            bool lhFormation = swingHighs[0] < swingHighs[1] && swingHighs[1] < swingHighs[2];
            bool llFormation = swingLows[0] < swingLows[1] && swingLows[1] < swingLows[2];

            if(lhFormation && llFormation)
            {
               string name = "ICT_MSS_BEAR";
               ObjectCreate(0, name, OBJ_TEXT, 0, swingHighTimes[0], swingHighs[0]);
               ObjectSetString(0, name, OBJPROP_TEXT, "MSS");
               ObjectSetInteger(0, name, OBJPROP_COLOR, C'230,80,80');
               ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
               ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
               ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LOWER);
               ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
               ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
            }
         }
      }
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| GUI SYSTEM - Professional Dark Theme                              |
//+------------------------------------------------------------------+
#define PANEL_X     8
#define PANEL_Y     24
#define BTN_W       96
#define BTN_H       20
#define BTN_GAP     3
#define COL_W       100
#define LINE_H      13

// Color scheme
#define CLR_PANEL   C'18,18,24'    // Dark panel bg
#define CLR_BORDER  C'60,60,80'    // Panel border - brighter
#define CLR_HEADER  C'0,170,120'   // Green header
#define CLR_TEXT    C'180,180,190'  // Normal text
#define CLR_DIM     C'100,100,120'  // Dim text
#define CLR_BUY     C'0,150,255'   // Blue for buys
#define CLR_SELL    C'230,80,80'   // Red for sells
#define CLR_PROFIT  C'0,190,100'   // Green profit
#define CLR_LOSS    C'230,60,60'   // Red loss
#define CLR_ACCENT  C'255,180,0'   // Gold accent

//+------------------------------------------------------------------+
void MakeLabel(string name, string text, int x, int y, color clr, int size=8, string font="Consolas")
{
   string objName = "GUI_" + name;
   ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetString(0, objName, OBJPROP_FONT, font);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 2000);
}

//+------------------------------------------------------------------+
void MakePanel(string name, int x, int y, int w, int h)
{
   string objName = "GUI_" + name;
   ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, C'15,15,20');
   ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, C'50,50,70');
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 1000);
}

//+------------------------------------------------------------------+
void MakeButton(string name, string text, int x, int y, int w, color bgClr)
{
   string objName = "GUI_BTN_" + name;
   ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, BTN_H);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgClr);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 7);
   ObjectSetString(0, objName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, C'40,40,50');
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 2000);
}

//+------------------------------------------------------------------+
void CalculateMultiPairStats()
{
   if(!Use_MultiPair || g_pairCount == 0) return;

   for(int p = 0; p < g_pairCount; p++)
   {
      string sym = g_pairList[p];
      g_pairProfit[p] = 0;
      g_pairBuyCount[p] = 0;
      g_pairSellCount[p] = 0;
      g_pairLots[p] = 0;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != sym) continue;
         if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

         double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         double lot = PositionGetDouble(POSITION_VOLUME);
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         g_pairProfit[p] += profit;
         g_pairLots[p] += lot;

         if(type == POSITION_TYPE_BUY)
            g_pairBuyCount[p]++;
         else
            g_pairSellCount[p]++;
      }

      double pairEq = g_pairProfit[p];
      if(pairEq > g_pairPeak[p])
         g_pairPeak[p] = pairEq;

      if(g_pairPeak[p] > 0)
      {
         double dd = g_pairPeak[p] - pairEq;
         if(dd > g_pairMaxDD[p])
            g_pairMaxDD[p] = dd;
      }
   }
}

//+------------------------------------------------------------------+
//| Helper: Draw separator line                                        |
//+------------------------------------------------------------------+
void DrawSeparator(string name, int x, int y, int width, color clr)
{
   ObjectCreate(0, "GUI_" + name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "GUI_" + name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "GUI_" + name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, "GUI_" + name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, "GUI_" + name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, "GUI_" + name, OBJPROP_YSIZE, 1);
   ObjectSetInteger(0, "GUI_" + name, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(0, "GUI_" + name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "GUI_" + name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, "GUI_" + name, OBJPROP_ZORDER, 2000);
}

//+------------------------------------------------------------------+
void DisplayInfo()
{
   ObjectsDeleteAll(0, "GUI_");

   int panelW = 204;
   int contentW = panelW - 12;
   int chartH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);

   int lx = 6;
   int rx = lx + 90;

   // ======== PASS 1: Calculate Panel 1 height ========
   int y1 = 6;
   y1 += 16 + 14 + 6;  // Header
   y1 += LINE_H * 4 + 5;  // Account (4 lines + sep)
   y1 += (LINE_H + 1) + LINE_H * 4 + (LINE_H + 2) + 5;  // Positions (6 lines + sep)
   y1 += LINE_H + 1;  // STATUS header
   if(Use_Trailing_Stop) y1 += LINE_H;
   if(Use_DrawdownSwitch) y1 += LINE_H;
   if(Use_Hedging) y1 += LINE_H;
   if(Use_EquityATRTrail) y1 += LINE_H;
   y1 += LINE_H;  // ATR
   y1 += LINE_H;  // Range
   if(Filter_News)
   {
      y1 += LINE_H;  // news status line
      y1 += LINE_H * 3;  // up to 3 upcoming events
      y1 += LINE_H;  // fallback message
   }
   y1 += LINE_H + 4;  // Trading status
   y1 += (BTN_H + BTN_GAP) * 5 + BTN_H;  // 5 button rows + last button height
   y1 += 8;  // bottom padding
   int p1H = y1;

   // ======== PASS 2: Calculate Panel 2 height ========
   int y2 = 6;
   if(Use_MultiPair && g_pairCount > 0)
   {
      y2 += 5 + LINE_H + 1;  // sep + header
      y2 += (LINE_H * 3) * g_pairCount;  // per pair: name+lots, bs, profit+dd
      y2 += 2;
   }
   if(ShowSMCDashboard) y2 += 5 + LINE_H + 1 + LINE_H * 6 + 2;
   if(ShowICTDashboard) y2 += 5 + LINE_H + 1 + LINE_H * 14 + 2;
   int p2H = y2;

   // Layout decision
   bool sideBySide = (panelW * 2 + 20 < chartW);
   int p1x = PANEL_X;
   int p1y = PANEL_Y;
   int p2x, p2y;

   if(sideBySide)
   {
      p2x = p1x + panelW + 10;
      p2y = p1y;
      if(p2H > chartH - 60) p2H = chartH - 60;
   }
   else
   {
      p2x = p1x;
      p2y = p1y + p1H + 5;
      if(p2y + p2H > chartH - 30)
      {
         p2H = chartH - 30 - p2y;
         if(p2H < 40) p2H = 40;
      }
   }
   if(p1H > chartH - 30) p1H = chartH - 30;

   // ======== DRAW PANEL 1 ========
   MakePanel("BG1", p1x, p1y, panelW, p1H);
   int y = p1y + 6;

   // Header
   MakeLabel("hdr1", "EURO SCALPER HEDGE", lx, y, CLR_HEADER, 9, "Arial Bold");
   y += 16;
   MakeLabel("hdr2", "v5.43  |  " + _Symbol, lx, y, CLR_DIM, 7);
   y += 14;
   DrawSeparator("sep1", lx, y, contentW, CLR_BORDER);
   y += 6;

   // Account
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   color profitClr = g_totalProfit >= 0 ? CLR_PROFIT : CLR_LOSS;
   MakeLabel("lbl_bal", "Balance", lx, y, CLR_DIM); MakeLabel("val_bal", DoubleToString(bal, 2), rx, y, CLR_TEXT); y += LINE_H;
   MakeLabel("lbl_eq", "Equity", lx, y, CLR_DIM);   MakeLabel("val_eq", DoubleToString(eq, 2), rx, y, CLR_TEXT);   y += LINE_H;
   MakeLabel("lbl_pnl", "Profit", lx, y, CLR_DIM);  MakeLabel("val_pnl", DoubleToString(g_totalProfit, 2), rx, y, profitClr); y += LINE_H;
   MakeLabel("lbl_magic", "Magic", lx, y, CLR_DIM); MakeLabel("val_magic", IntegerToString(g_magic), rx, y, CLR_DIM); y += LINE_H;
   DrawSeparator("sep2", lx, y, contentW, CLR_BORDER);
   y += 5;

   // Positions
   color buyClr = g_hasBuy ? CLR_BUY : CLR_DIM;
   color sellClr = g_hasSell ? CLR_SELL : CLR_DIM;
   MakeLabel("hdr_pos", "POSITIONS", lx, y, CLR_ACCENT, 7, "Arial Bold"); y += LINE_H + 1;
   MakeLabel("lbl_buys", "Buys", lx, y, CLR_DIM);   MakeLabel("val_buys", IntegerToString(g_buyCount), rx, y, buyClr);   y += LINE_H;
   MakeLabel("lbl_sells", "Sells", lx, y, CLR_DIM);  MakeLabel("val_sells", IntegerToString(g_sellCount), rx, y, sellClr); y += LINE_H;
   MakeLabel("lbl_avg", "Avg", lx, y, CLR_DIM);      MakeLabel("val_avg", DoubleToString(g_avgPrice, _Digits), rx, y, CLR_TEXT); y += LINE_H;
   MakeLabel("lbl_lot", "Lot", lx, y, CLR_DIM);      MakeLabel("val_lot", DoubleToString(g_lot, 2), rx, y, CLR_TEXT);   y += LINE_H;
   MakeLabel("lbl_tf", "TF", lx, y, CLR_DIM);        MakeLabel("val_tf", EnumToString(g_currentTimeframe), rx, y, CLR_TEXT); y += LINE_H + 2;
   DrawSeparator("sep3", lx, y, contentW, CLR_BORDER);
   y += 5;

   // Status
   MakeLabel("hdr_stat", "STATUS", lx, y, CLR_ACCENT, 7, "Arial Bold"); y += LINE_H + 1;

   if(Use_Trailing_Stop)
   {
      string trailMode = (TrailingMode == 0) ? "Fixed" : "ATR";
      double bestPip = 0;
      for(int ti = PositionsTotal() - 1; ti >= 0; ti--)
      {
         ulong tt = PositionGetTicket(ti);
         if(tt == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         double op = PositionGetDouble(POSITION_PRICE_OPEN);
         long tp = PositionGetInteger(POSITION_TYPE);
         double bid2 = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double ask2 = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double pp = 0;
         if(tp == POSITION_TYPE_BUY)  pp = (bid2 - op) / _Point;
         if(tp == POSITION_TYPE_SELL) pp = (op - ask2) / _Point;
         if(pp > bestPip) bestPip = pp;
      }
      bool trailReady = (bestPip >= TrailingStartPips);
      string trailSt = trailReady ? "ACTIVE " + trailMode : "WAIT (" + DoubleToString(TrailingStartPips, 0) + ")";
      MakeLabel("lbl_trail", "Trail", lx, y, CLR_DIM);
      MakeLabel("val_trail", trailSt, rx, y, trailReady ? CLR_PROFIT : CLR_DIM);
      y += LINE_H;
   }

   if(Use_DrawdownSwitch)
   {
      double dd = 0;
      if(g_peakBalance > 0) dd = ((g_peakBalance - eq) / g_peakBalance) * 100.0;
      MakeLabel("lbl_dd", "DD%", lx, y, CLR_DIM);
      MakeLabel("val_dd", DoubleToString(dd, 1) + "%", rx, y, dd > DD_High ? CLR_LOSS : CLR_PROFIT);
      y += LINE_H;
   }

   if(Use_Hedging)
   {
      bool hedged = g_hasBuy && g_hasSell;
      MakeLabel("lbl_hedge", "Hedge", lx, y, CLR_DIM);
      MakeLabel("val_hedge", hedged ? "ACTIVE" : "OFF", rx, y, hedged ? CLR_ACCENT : CLR_DIM);
      y += LINE_H;
   }

   if(Use_EquityATRTrail)
   {
      MakeLabel("lbl_eqtrail", "EqATR", lx, y, CLR_DIM);
      MakeLabel("val_eqtrail", g_equityTrailActive ? "ON" : "OFF", rx, y, g_equityTrailActive ? CLR_LOSS : CLR_DIM);
      y += LINE_H;
   }

   // ATR + Range
   double atrVal = GetATRValue();
   MakeLabel("lbl_atr", "ATR", lx, y, CLR_DIM);
   MakeLabel("val_atr", atrVal > 0 ? DoubleToString(atrVal, _Digits) : "N/A", rx, y, CLR_ACCENT);
   y += LINE_H;

   double dHigh = iHigh(_Symbol, PERIOD_D1, 0);
   double dLow = iLow(_Symbol, PERIOD_D1, 0);
   double dayRangeDisp = (dHigh - dLow) / _Point / (double)g_pointDivider;
   MakeLabel("lbl_range", "Range", lx, y, CLR_DIM);
   MakeLabel("val_range", DoubleToString(dayRangeDisp, 1), rx, y, CLR_ACCENT);
   y += LINE_H;

   if(Filter_News)
   {
      MakeLabel("lbl_news", "News", lx, y, CLR_DIM);
      string newsStatus = g_newsActive ? "BLOCKED" : "OK";
      MakeLabel("val_news", newsStatus + " (" + IntegerToString(g_newsCount) + ")", rx, y, g_newsActive ? CLR_LOSS : CLR_PROFIT);
      y += LINE_H;

      datetime now = TimeCurrent();
      bool foundNews = false;
      for(int i = 0; i < g_newsCount && i < 3; i++)
      {
         if(g_newsEvents[i].time > now)
         {
            int mins = (int)((g_newsEvents[i].time - now) / 60);
            string timeStr;
            if(mins >= 60)
               timeStr = IntegerToString(mins/60) + "h" + IntegerToString(mins%60) + "m";
            else
               timeStr = IntegerToString(mins) + "m";
            MakeLabel("lbl_nws" + IntegerToString(i), ">" + timeStr + " " + g_newsEvents[i].title, lx, y, CLR_DIM, 7);
            y += LINE_H;
            foundNews = true;
         }
      }
      if(!foundNews && g_newsCount > 0)
      {
         MakeLabel("lbl_nws_none", "No upcoming news", lx, y, CLR_DIM, 7);
         y += LINE_H;
      }
      else if(g_newsCount == 0)
      {
         MakeLabel("lbl_nws_none", "News not loaded", lx, y, CLR_DIM, 7);
         y += LINE_H;
      }
   }

   MakeLabel("lbl_pause", "Trading", lx, y, CLR_DIM);
   MakeLabel("val_pause", g_manualPaused ? "PAUSED" : "ACTIVE", rx, y, g_manualPaused ? CLR_LOSS : CLR_PROFIT);
   y += LINE_H + 4;

   // Buttons in Panel 1
   int btnW = contentW;
   int halfW = (btnW - BTN_GAP) / 2;

   if(g_manualPaused)
      MakeButton("Pause", "RESUME TRADING", lx, y, btnW, C'0,140,70');
   else
      MakeButton("Pause", "PAUSE TRADING", lx, y, btnW, C'180,70,30');
   y += BTN_H + BTN_GAP;

   MakeButton("ClosePair", "CLOSE PAIR", lx, y, halfW, C'180,40,40');
   MakeButton("CloseAll", "CLOSE ALL", lx + halfW + BTN_GAP, y, halfW, C'140,30,30');
   y += BTN_H + BTN_GAP;

   MakeButton("CloseBuys", "CLOSE BUYS", lx, y, halfW, C'30,100,180');
   MakeButton("CloseSells", "CLOSE SELLS", lx + halfW + BTN_GAP, y, halfW, C'180,60,60');
   y += BTN_H + BTN_GAP;

   MakeButton("CloseProf", "CLOSE PROFIT", lx, y, halfW, C'30,130,60');
   MakeButton("CloseLoss", "CLOSE LOSS", lx + halfW + BTN_GAP, y, halfW, C'160,40,40');
   y += BTN_H + BTN_GAP;

   MakeButton("DeletePending", "DELETE PENDING", lx, y, btnW, C'80,80,90');

   // ========== DRAW PANEL 2 (if needed) ==========
   if(p2H > 40)
   {
      MakePanel("BG2", p2x, p2y, panelW, p2H);
      int lx2 = p2x + 6;
      int rx2 = lx2 + 90;
      int y2 = p2y + 6;

      // Multi-Pair
      if(Use_MultiPair && g_pairCount > 0)
      {
         CalculateMultiPairStats();
         DrawSeparator("sep_mp", lx2, y2, contentW, CLR_BORDER);
         y2 += 5;
         MakeLabel("hdr_mp", "MULTI-PAIR", lx2, y2, CLR_ACCENT, 7, "Arial Bold");
         y2 += LINE_H + 1;

         for(int p = 0; p < g_pairCount; p++)
         {
            MakeLabel("mp_name" + IntegerToString(p), g_pairList[p], lx2, y2, CLR_DIM, 7);
            MakeLabel("mp_lots" + IntegerToString(p), DoubleToString(g_pairLots[p], 2) + "L", rx2, y2, CLR_TEXT, 7);
            y2 += LINE_H;

            string bsStr = IntegerToString(g_pairBuyCount[p]) + "B/" + IntegerToString(g_pairSellCount[p]) + "S";
            MakeLabel("mp_bs" + IntegerToString(p), bsStr, lx2, y2, CLR_DIM, 7);
            y2 += LINE_H;

            color pairPrClr = g_pairProfit[p] >= 0 ? CLR_PROFIT : CLR_LOSS;
            MakeLabel("mp_pr" + IntegerToString(p), DoubleToString(g_pairProfit[p], 2), lx2, y2, pairPrClr, 7);
            MakeLabel("mp_dd" + IntegerToString(p), "DD:" + DoubleToString(g_pairMaxDD[p], 2), rx2, y2, CLR_DIM, 7);
            y2 += LINE_H;
         }
         y2 += 2;
      }

      // SMC
      if(ShowSMCDashboard)
      {
         SMCDATA smc = AnalyzeSMC();
         DrawSeparator("sep_smc", lx2, y2, contentW, CLR_BORDER);
         y2 += 5;
         MakeLabel("hdr_smc", "SMC ANALYSIS", lx2, y2, C'100,200,255', 7, "Arial Bold");
         y2 += LINE_H + 1;

         if(ShowMarketStructure)
         {
            color structClr = smc.structure == "BULLISH" ? CLR_PROFIT : smc.structure == "BEARISH" ? CLR_LOSS : CLR_DIM;
            MakeLabel("lbl_struct", "Structure", lx2, y2, CLR_DIM);
            MakeLabel("val_struct", smc.structure, rx2, y2, structClr);
            y2 += LINE_H;

            color biasClr = smc.bias == "BUY" ? CLR_BUY : smc.bias == "SELL" ? CLR_SELL : CLR_DIM;
            MakeLabel("lbl_bias", "Bias", lx2, y2, CLR_DIM);
            MakeLabel("val_bias", smc.bias, rx2, y2, biasClr);
            y2 += LINE_H;
         }
         if(ShowOrderBlocks)
         {
            MakeLabel("lbl_ob", "OB", lx2, y2, CLR_DIM);
            string obText = IntegerToString(smc.obCount);
            if(smc.obSupport > 0) obText += " (S:" + DoubleToString(smc.obSupport, _Digits) + ")";
            MakeLabel("val_ob", obText, rx2, y2, smc.obCount > 0 ? CLR_ACCENT : CLR_DIM);
            y2 += LINE_H;
         }
         if(ShowFVG)
         {
            MakeLabel("lbl_fvg", "FVG", lx2, y2, CLR_DIM);
            string fvgText = IntegerToString(smc.fvgCount);
            if(smc.fvgHigh > 0) fvgText += " (H:" + DoubleToString(smc.fvgHigh, _Digits) + ")";
            MakeLabel("val_fvg", fvgText, rx2, y2, smc.fvgCount > 0 ? CLR_ACCENT : CLR_DIM);
            y2 += LINE_H;
         }
         if(ShowBOS)
         {
            MakeLabel("lbl_bos", "BOS", lx2, y2, CLR_DIM);
            MakeLabel("val_bos", IntegerToString(smc.bosCount), rx2, y2, smc.bosCount > 0 ? CLR_ACCENT : CLR_DIM);
            y2 += LINE_H;
         }
         if(ShowLiquidity)
         {
            MakeLabel("lbl_liq", "Liquidity", lx2, y2, CLR_DIM);
            string liqText = "";
            if(smc.eqhCount > 0) liqText += IntegerToString(smc.eqhCount) + "EQH";
            if(smc.eqlCount > 0) liqText += (liqText != "" ? " " : "") + IntegerToString(smc.eqlCount) + "EQL";
            if(liqText == "") liqText = "NONE";
            MakeLabel("val_liq", liqText, rx2, y2, (smc.eqhCount + smc.eqlCount) > 0 ? CLR_ACCENT : CLR_DIM);
            y2 += LINE_H;
         }
         y2 += 2;
      }

      // ICT
      if(ShowICTDashboard)
      {
         ICTDATA ict = AnalyzeICT();
         DrawSeparator("sep_ict", lx2, y2, contentW, C'80,160,220');
         y2 += 5;
         MakeLabel("hdr_ict", "ICT ANALYSIS", lx2, y2, C'80,180,255', 7, "Arial Bold");
         y2 += LINE_H + 1;

         if(ShowKillZones)
         {
            color kzClr = ict.killZoneStatus == "ACTIVE" ? C'0,200,150' : CLR_DIM;
            string kzText = ict.killZone;
            if(ict.killZoneStatus == "ACTIVE")
               kzText += " (" + IntegerToString(ict.killZoneMinsLeft) + "m)";
            else if(ict.killZoneStatus == "UPCOMING")
               kzText += " (>" + IntegerToString(ict.killZoneMinsLeft) + "m)";
            MakeLabel("lbl_kz", "KillZone", lx2, y2, CLR_DIM);
            MakeLabel("val_kz", kzText, rx2, y2, kzClr);
            y2 += LINE_H;
         }
         if(ShowDailyBias)
         {
            color biasClr = ict.dailyBias == "BULLISH" ? CLR_PROFIT : ict.dailyBias == "BEARISH" ? CLR_LOSS : CLR_DIM;
            MakeLabel("lbl_dbias", "DailyBias", lx2, y2, CLR_DIM);
            MakeLabel("val_dbias", ict.dailyBias, rx2, y2, biasClr);
            y2 += LINE_H;
         }
         if(ShowMSS)
         {
            color mssClr = ict.mss == "BULLISH_MSS" ? CLR_PROFIT : ict.mss == "BEARISH_MSS" ? CLR_LOSS : CLR_DIM;
            string mssText = ict.mss;
            if(ict.mss == "NONE") mssText = "---";
            MakeLabel("lbl_mss", "MSS", lx2, y2, CLR_DIM);
            MakeLabel("val_mss", mssText, rx2, y2, mssClr);
            y2 += LINE_H;
         }
         if(ShowPremiumDiscount)
         {
            color pdClr = ict.pdZone == "PREMIUM" ? CLR_SELL : ict.pdZone == "DISCOUNT" ? CLR_BUY : CLR_DIM;
            string pdText = ict.pdZone + " " + DoubleToString(ict.pdLevel, 0) + "%";
            MakeLabel("lbl_pd", "P/D Zone", lx2, y2, CLR_DIM);
            MakeLabel("val_pd", pdText, rx2, y2, pdClr);
            y2 += LINE_H;

            if(ict.equilibrium > 0)
            {
               MakeLabel("lbl_eq_ict", "Equil", lx2, y2, CLR_DIM, 7);
               MakeLabel("val_eq_ict", DoubleToString(ict.equilibrium, _Digits), rx2, y2, CLR_DIM, 7);
               y2 += LINE_H;
            }
         }
         if(ShowOTE)
         {
            color oteClr = ict.oteStatus == "IN_OTE" ? CLR_ACCENT : CLR_DIM;
            string oteText = ict.oteStatus;
            if(ict.oteStatus == "IN_OTE") oteText = "IN ZONE";
            MakeLabel("lbl_ote", "OTE", lx2, y2, CLR_DIM);
            MakeLabel("val_ote", oteText, rx2, y2, oteClr);
            y2 += LINE_H;

            if(ict.oteHigh > 0)
            {
               string oteRange = DoubleToString(ict.oteLow, _Digits) + " - " + DoubleToString(ict.oteHigh, _Digits);
               MakeLabel("lbl_ote_range", "", lx2, y2, CLR_DIM, 7);
               MakeLabel("val_ote_range", oteRange, rx2, y2, CLR_DIM, 7);
               y2 += LINE_H;
            }
         }
         if(ShowICTOrderBlocks)
         {
            color obClr = ict.ictOBType == "BULLISH_OB" ? CLR_BUY : ict.ictOBType == "BEARISH_OB" ? CLR_SELL : CLR_DIM;
            string obText = IntegerToString(ict.ictOBCount);
            if(ict.ictOBType != "NONE") obText += " " + ict.ictOBType;
            MakeLabel("lbl_ict_ob", "OB", lx2, y2, CLR_DIM);
            MakeLabel("val_ict_ob", obText, rx2, y2, obClr);
            y2 += LINE_H;
         }
         if(ShowICTFVG)
         {
            color fvgClr = ict.ictFVGType == "BULLISH_FVG" ? CLR_BUY : ict.ictFVGType == "BEARISH_FVG" ? CLR_SELL : CLR_DIM;
            string fvgText = IntegerToString(ict.ictFVGCount);
            if(ict.ictFVGType != "NONE") fvgText += " " + ict.ictFVGType;
            MakeLabel("lbl_ict_fvg", "FVG", lx2, y2, CLR_DIM);
            MakeLabel("val_ict_fvg", fvgText, rx2, y2, fvgClr);
            y2 += LINE_H;
         }
         if(ShowICTLiquidity)
         {
            color liqClr = ict.ictLiquidity != "NONE" ? CLR_ACCENT : CLR_DIM;
            string liqText = ict.ictLiquidity;
            if(liqText == "NONE") liqText = "---";
            MakeLabel("lbl_ict_liq", "Liquidity", lx2, y2, CLR_DIM);
            MakeLabel("val_ict_liq", liqText, rx2, y2, liqClr);
            y2 += LINE_H;
         }
         if(ShowLiquiditySweep)
         {
            color sweepClr = ict.ictLiqSweep > 0 ? CLR_LOSS : CLR_DIM;
            MakeLabel("lbl_sweep", "Sweeps", lx2, y2, CLR_DIM);
            MakeLabel("val_sweep", IntegerToString(ict.ictLiqSweep), rx2, y2, sweepClr);
            y2 += LINE_H;
         }
         if(ShowDisplacement)
         {
            color dispClr = ict.displacement == "BULLISH_DISP" ? CLR_PROFIT : ict.displacement == "BEARISH_DISP" ? CLR_LOSS : CLR_DIM;
            string dispText = ict.displacement;
            if(dispText == "NONE") dispText = "---";
            MakeLabel("lbl_disp", "Displace", lx2, y2, CLR_DIM);
            MakeLabel("val_disp", dispText, rx2, y2, dispClr);
            y2 += LINE_H;
         }
         if(ict.swingHigh > 0)
         {
            MakeLabel("lbl_sh", "SwingHi", lx2, y2, CLR_DIM, 7);
            MakeLabel("val_sh", DoubleToString(ict.swingHigh, _Digits), rx2, y2, CLR_DIM, 7);
            y2 += LINE_H;
         }
         if(ict.swingLow > 0)
         {
            MakeLabel("lbl_sl", "SwingLo", lx2, y2, CLR_DIM, 7);
            MakeLabel("val_sl", DoubleToString(ict.swingLow, _Digits), rx2, y2, CLR_DIM, 7);
            y2 += LINE_H;
         }
      }
   }

    ChartRedraw(0);
}

//+------------------------------------------------------------------+
void CreateButtons()
{
   DisplayInfo();
}

//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      string objName = sparam;

      if(objName == "GUI_BTN_Pause")
      {
         g_manualPaused = !g_manualPaused;
         CreateButtons();
         Print("Manual pause: ", (g_manualPaused ? "ON" : "OFF"));
      }
      else if(objName == "GUI_BTN_ClosePair")
      {
         ClosePositionsThisPair();
         Print("Close This Pair clicked");
      }
      else if(objName == "GUI_BTN_CloseAll")
      {
         CloseAllPositionsAllSymbols();
         Print("Close All Pairs clicked");
      }
      else if(objName == "GUI_BTN_CloseBuys")
      {
         ClosePositionsByType(POSITION_TYPE_BUY);
         Print("Close Buys clicked");
      }
      else if(objName == "GUI_BTN_CloseSells")
      {
         ClosePositionsByType(POSITION_TYPE_SELL);
         Print("Close Sells clicked");
      }
      else if(objName == "GUI_BTN_CloseProf")
      {
         ClosePositionsByProfit(true);
         Print("Close Profit clicked");
      }
      else if(objName == "GUI_BTN_CloseLoss")
      {
         ClosePositionsByProfit(false);
         Print("Close Loss clicked");
      }
      else if(objName == "GUI_BTN_DeletePending")
      {
         DeletePendingOrders();
         Print("Delete Pending clicked");
      }

      // Reset button state
      ObjectSetInteger(0, objName, OBJPROP_STATE, false);
      ChartRedraw(0);
   }
}

//+------------------------------------------------------------------+
void ClosePositionsByType(ENUM_POSITION_TYPE type)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      if(PositionGetInteger(POSITION_TYPE) != type) continue;

      trade.PositionClose(ticket);
      Sleep(100);
   }
}

//+------------------------------------------------------------------+
void ClosePositionsByProfit(bool closeProfitable)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

      if(closeProfitable && profit >= 0)
         trade.PositionClose(ticket);
      else if(!closeProfitable && profit < 0)
         trade.PositionClose(ticket);

      Sleep(100);
   }
}

//+------------------------------------------------------------------+
void DeletePendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if(OrderGetInteger(ORDER_MAGIC) != g_magic) continue;

      trade.OrderDelete(ticket);
      Sleep(100);
   }
}

//+------------------------------------------------------------------+
//| Close positions for THIS symbol + magic only                      |
//+------------------------------------------------------------------+
void ClosePositionsThisPair()
{
   int closed = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      Print("Closing ticket #", ticket, " ", PositionGetString(POSITION_SYMBOL),
            " magic=", PositionGetInteger(POSITION_MAGIC),
            " type=", PositionGetInteger(POSITION_TYPE),
            " lot=", PositionGetDouble(POSITION_VOLUME));

      if(!trade.PositionClose(ticket))
         Print("FAILED to close #", ticket, " error: ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      else
         closed++;

      Sleep(200);
   }
   Print("CloseThisPair: closed ", closed, " positions");
}

//+------------------------------------------------------------------+
//| Close positions for ALL symbols matching magic                     |
//+------------------------------------------------------------------+
void CloseAllPositionsAllSymbols()
{
   int closed = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      Print("Closing ticket #", ticket, " ", PositionGetString(POSITION_SYMBOL),
            " magic=", PositionGetInteger(POSITION_MAGIC),
            " type=", PositionGetInteger(POSITION_TYPE),
            " lot=", PositionGetDouble(POSITION_VOLUME));

      if(!trade.PositionClose(ticket))
         Print("FAILED to close #", ticket, " error: ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      else
         closed++;

      Sleep(200);
   }
    Print("CloseAllPairs: closed ", closed, " positions");
}

//+------------------------------------------------------------------+
//| MULTI-PAIR TRADING SYSTEM                                         |
//+------------------------------------------------------------------+
bool CheckPairDataReady(int idx)
{
   MqlTick tick;
   if(!SymbolInfoTick(g_pts[idx].symbol, tick)) return false;
   if(tick.ask == 0 || tick.bid == 0) return false;
   double vol = (double)iVolume(g_pts[idx].symbol, g_currentTimeframe, 0);
   double c1  = iClose(g_pts[idx].symbol, g_currentTimeframe, 1);
   double c2  = iClose(g_pts[idx].symbol, g_currentTimeframe, 2);
   if(vol == 0 && c1 == 0 && c2 == 0) return false;
   return true;
}

//+------------------------------------------------------------------+
void AnalyzePairPositions(int idx)
{
   g_pts[idx].buyCount = 0;
   g_pts[idx].sellCount = 0;
   g_pts[idx].hasBuy = false;
   g_pts[idx].hasSell = false;
   g_pts[idx].lastBuyPrice = 0;
   g_pts[idx].lastSellPrice = 0;
   g_pts[idx].avgPrice = 0;
   g_pts[idx].totalProfit = 0;
   g_pts[idx].buyAvgPrice = 0;
   g_pts[idx].sellAvgPrice = 0;
   g_pts[idx].needModify = false;
   g_pts[idx].buyTP = 0;
   g_pts[idx].sellTP = 0;
   g_pts[idx].newTP = 0;

   double totalLots = 0, totalPrice = 0;
   double buyLots = 0, buyPriceSum = 0;
   double sellLots = 0, sellPriceSum = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != g_pts[idx].symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double lots = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

      g_pts[idx].totalProfit += profit;

      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         g_pts[idx].buyCount++;
         g_pts[idx].hasBuy = true;
         if(price < g_pts[idx].lastBuyPrice || g_pts[idx].lastBuyPrice == 0)
            g_pts[idx].lastBuyPrice = price;
         totalLots += lots;
         totalPrice += price * lots;
         buyLots += lots;
         buyPriceSum += price * lots;
      }
      else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
      {
         g_pts[idx].sellCount++;
         g_pts[idx].hasSell = true;
         if(price > g_pts[idx].lastSellPrice || g_pts[idx].lastSellPrice == 0)
            g_pts[idx].lastSellPrice = price;
         totalLots += lots;
         totalPrice += price * lots;
         sellLots += lots;
         sellPriceSum += price * lots;
      }
   }

   g_pts[idx].totalCount = g_pts[idx].buyCount + g_pts[idx].sellCount;
   if(totalLots > 0) g_pts[idx].avgPrice = totalPrice / totalLots;
   if(buyLots > 0) g_pts[idx].buyAvgPrice = buyPriceSum / buyLots;
   if(sellLots > 0) g_pts[idx].sellAvgPrice = sellPriceSum / sellLots;

   double pointVal = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_POINT);
   if(g_pts[idx].totalCount > 0)
   {
      double effectiveTP = TakeProfit;
      if(Use_TP_Multiplier && g_pts[idx].averagingCount > 0)
      {
         int lvl = (int)MathMin(g_pts[idx].averagingCount, TP_Max_Level);
         effectiveTP = TakeProfit * MathPow(TP_Multiplier, lvl);
      }

      if(g_pts[idx].hasBuy && g_pts[idx].hasSell && Use_SeparateTP)
      {
         if(g_pts[idx].buyCount > 0) g_pts[idx].buyTP = g_pts[idx].buyAvgPrice + (effectiveTP * pointVal);
         if(g_pts[idx].sellCount > 0) g_pts[idx].sellTP = g_pts[idx].sellAvgPrice - (effectiveTP * pointVal);
         g_pts[idx].newTP = 0;
      }
      else if(g_pts[idx].hasBuy && g_pts[idx].hasSell && !Use_SeparateTP)
      {
         g_pts[idx].newTP = 0;
      }
      else
      {
         if(g_pts[idx].hasBuy) g_pts[idx].newTP = g_pts[idx].avgPrice + (effectiveTP * pointVal);
         else if(g_pts[idx].hasSell) g_pts[idx].newTP = g_pts[idx].avgPrice - (effectiveTP * pointVal);
      }

      g_pts[idx].needModify = true;
      g_pts[idx].averagingCount = g_pts[idx].totalCount - 1;
   }

   g_pts[idx].canTrade = (g_pts[idx].totalCount == 0);
}

//+------------------------------------------------------------------+
void ManagePairModifyTP(int idx)
{
   if(g_pts[idx].totalCount == 0 || !g_pts[idx].needModify) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != g_pts[idx].symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double currentTP = PositionGetDouble(POSITION_TP);

      if(g_pts[idx].hasBuy && g_pts[idx].hasSell && Use_SeparateTP)
      {
         long posType = PositionGetInteger(POSITION_TYPE);
         double targetTP = 0;
         if(posType == POSITION_TYPE_BUY) targetTP = g_pts[idx].buyTP;
         else if(posType == POSITION_TYPE_SELL) targetTP = g_pts[idx].sellTP;
         if(targetTP > 0 && MathAbs(currentTP - targetTP) > SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_POINT))
         {
            if(!g_pts[idx].trade.PositionModify(ticket, 0, targetTP))
               g_lastServerFailTime = TimeCurrent();
         }
      }
      else if(g_pts[idx].hasBuy && g_pts[idx].hasSell && !Use_SeparateTP)
      {
         if(currentTP != 0)
         {
            if(!g_pts[idx].trade.PositionModify(ticket, 0, 0))
               g_lastServerFailTime = TimeCurrent();
         }
      }
      else
      {
         if(g_pts[idx].newTP > 0 && MathAbs(currentTP - g_pts[idx].newTP) > SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_POINT))
         {
            if(!g_pts[idx].trade.PositionModify(ticket, 0, g_pts[idx].newTP))
               g_lastServerFailTime = TimeCurrent();
         }
      }
   }
   g_pts[idx].needModify = false;
}

//+------------------------------------------------------------------+
bool OpenPairBuy(int idx)
{
   double ask = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_ASK);
   if(ask == 0) { Print("MP OPEN FAIL: ", g_pts[idx].symbol, " ask=0"); return false; }
   string comment = g_pts[idx].symbol + "-" + IntegerToString(g_magic) + "-" + IntegerToString(g_pts[idx].averagingCount + 1);
   if(g_pts[idx].trade.Buy(g_pts[idx].lot, g_pts[idx].symbol, ask, 0, 0, comment))
   {
      Print("MP BUY OK: ", g_pts[idx].symbol, " ", DoubleToString(g_pts[idx].lot, 2), " @ ", DoubleToString(ask, (int)SymbolInfoInteger(g_pts[idx].symbol, SYMBOL_DIGITS)));
      return true;
   }
   else
   {
      g_lastServerFailTime = TimeCurrent();
      Print("MP BUY FAIL: ", g_pts[idx].symbol, " err=", g_pts[idx].trade.ResultRetcode(), " msg=", g_pts[idx].trade.ResultRetcodeDescription());
   }
   return false;
}

//+------------------------------------------------------------------+
bool OpenPairSell(int idx)
{
   double bid = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_BID);
   if(bid == 0) { Print("MP OPEN FAIL: ", g_pts[idx].symbol, " bid=0"); return false; }
   string comment = g_pts[idx].symbol + "-" + IntegerToString(g_magic) + "-" + IntegerToString(g_pts[idx].averagingCount + 1);
   if(g_pts[idx].trade.Sell(g_pts[idx].lot, g_pts[idx].symbol, bid, 0, 0, comment))
   {
      Print("MP SELL OK: ", g_pts[idx].symbol, " ", DoubleToString(g_pts[idx].lot, 2), " @ ", DoubleToString(bid, (int)SymbolInfoInteger(g_pts[idx].symbol, SYMBOL_DIGITS)));
      return true;
   }
   else
   {
      g_lastServerFailTime = TimeCurrent();
      Print("MP SELL FAIL: ", g_pts[idx].symbol, " err=", g_pts[idx].trade.ResultRetcode(), " msg=", g_pts[idx].trade.ResultRetcodeDescription());
   }
   return false;
}

//+------------------------------------------------------------------+
void ManagePairTrading(int idx)
{
   if(idx < 0 || idx >= g_pairCount) return;

   AnalyzePairPositions(idx);

   g_pairProfit[idx] = g_pts[idx].totalProfit;
   g_pairBuyCount[idx] = g_pts[idx].buyCount;
   g_pairSellCount[idx] = g_pts[idx].sellCount;
   g_pairLots[idx] = g_pts[idx].totalCount * g_pts[idx].lot;

   double pairEq = g_pts[idx].totalProfit;
   if(pairEq > g_pairPeak[idx]) g_pairPeak[idx] = pairEq;
   if(g_pairPeak[idx] > 0)
   {
      double dd = g_pairPeak[idx] - pairEq;
      if(dd > g_pairMaxDD[idx]) g_pairMaxDD[idx] = dd;
   }

   if(g_pts[idx].needModify && g_pts[idx].totalCount > 0)
      ManagePairModifyTP(idx);

   double pointVal = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_BID);
   int symDigits = (int)SymbolInfoInteger(g_pts[idx].symbol, SYMBOL_DIGITS);

   if(pointVal == 0 || ask == 0 || bid == 0)
   {
      static datetime mpNoData = 0;
      if(TimeCurrent() - mpNoData > 60)
      {
         mpNoData = TimeCurrent();
         Print("MP[", idx, "] ", g_pts[idx].symbol, " NO DATA: ask=", DoubleToString(ask, 2),
               " bid=", DoubleToString(bid, 2), " point=", DoubleToString(pointVal, 6));
      }
      return;
   }

   // === FIRST ENTRY (no positions) ===
   if(g_pts[idx].totalCount == 0)
   {
      if(!g_pts[idx].canTrade)
      {
         static datetime mpLog1 = 0;
         if(TimeCurrent() - mpLog1 > 60) { mpLog1 = TimeCurrent(); Print("MP[", idx, "] ", g_pts[idx].symbol, " canTrade=FALSE"); }
         return;
      }

      MqlDateTime dt;
      TimeCurrent(dt);
      if(!TradeOnThursday && dt.day_of_week == 4) return;
      if(TradeOnThursday && dt.day_of_week == 4 && dt.hour > Thursday_Hour) return;
      if(!TradeOnFriday && dt.day_of_week == 5) return;
      if(TradeOnFriday && dt.day_of_week == 5 && dt.hour > Friday_Hour) return;

      if(!CheckPairDataReady(idx))
      {
         static datetime mpNoData2 = 0;
         if(TimeCurrent() - mpNoData2 > 60)
         {
            mpNoData2 = TimeCurrent();
            Print("MP[", idx, "] ", g_pts[idx].symbol, " DATA NOT READY iVol=",
                  IntegerToString(iVolume(g_pts[idx].symbol, g_currentTimeframe, 0)),
                  " c1=", DoubleToString(iClose(g_pts[idx].symbol, g_currentTimeframe, 1), symDigits),
                  " c2=", DoubleToString(iClose(g_pts[idx].symbol, g_currentTimeframe, 2), symDigits));
         }
         return;
      }

       // Fresh bar check using time-based approach for multi-pair
       datetime barTime = iTime(g_pts[idx].symbol, g_currentTimeframe, 0);
       if(g_pts[idx].freshBarTime == barTime) return;  // Same bar, skip
       g_pts[idx].freshBarTime = barTime;

       double close2 = iClose(g_pts[idx].symbol, g_currentTimeframe, 2);
      double close1 = iClose(g_pts[idx].symbol, g_currentTimeframe, 1);

      g_pts[idx].lot = Lot;
      double minLot = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_VOLUME_MIN);
      if(g_pts[idx].lot < minLot) g_pts[idx].lot = minLot;

      Print("MP[", idx, "] ", g_pts[idx].symbol, " SIGNAL: close[2]=",
            DoubleToString(close2, symDigits), " close[1]=",
            DoubleToString(close1, symDigits), " ask=", DoubleToString(ask, symDigits),
            " bid=", DoubleToString(bid, symDigits), " lot=", DoubleToString(g_pts[idx].lot, 2));

      if(close2 > close1)
      {
         if(OpenPairBuy(idx))
         {
            g_pts[idx].timeoutTime = TimeCurrent() + (TimeOut_Hours * 3600);
            g_pts[idx].averagingCount = 0;
         }
      }
      else if(close2 < close1)
      {
         if(OpenPairSell(idx))
         {
            g_pts[idx].timeoutTime = TimeCurrent() + (TimeOut_Hours * 3600);
            g_pts[idx].averagingCount = 0;
         }
      }
      else
      {
         Print("MP[", idx, "] ", g_pts[idx].symbol, " NO SIGNAL: close[2] == close[1]");
      }
   }
   else
   {
      // === AVERAGING ===
      if(g_pts[idx].totalCount < MaxTrades)
      {
         bool shouldOpen = false;
         int direction = 0;

         bool volumeOK = true;
         if(invisible_mode && iVolume(g_pts[idx].symbol, g_currentTimeframe, 0) >= 5)
            volumeOK = false;

         if(volumeOK)
         {
            if(g_pts[idx].hasBuy && !g_pts[idx].hasSell)
            {
               double dist = (g_pts[idx].lastBuyPrice - ask) / pointVal;
               if(dist >= Step) { shouldOpen = true; direction = 1; }
            }
            else if(g_pts[idx].hasSell && !g_pts[idx].hasBuy)
            {
               double dist = (bid - g_pts[idx].lastSellPrice) / pointVal;
               if(dist >= Step) { shouldOpen = true; direction = 2; }
            }
            else if(g_pts[idx].hasBuy && g_pts[idx].hasSell)
            {
               double distBuy = (g_pts[idx].lastBuyPrice - ask) / pointVal;
               if(distBuy >= Step && g_pts[idx].buyCount < MaxTrades) { shouldOpen = true; direction = 1; }
               double distSell = (bid - g_pts[idx].lastSellPrice) / pointVal;
               if(distSell >= Step && g_pts[idx].sellCount < MaxTrades) { shouldOpen = true; direction = 2; }
            }
         }

         bool timeOK = (TimeCurrent() - g_pts[idx].lastTradeTime >= MinTradeDelaySec);

         if(shouldOpen && timeOK && !g_newsActive)
         {
            g_pts[idx].lot = Lot;
            switch(LotMode)
            {
               case 0: g_pts[idx].lot = Lot; break;
               case 1: g_pts[idx].lot = NormalizeDouble(Lot * MathPow(LotMultiplikator, g_pts[idx].averagingCount + 1), 2); break;
               case 2: g_pts[idx].lot = Lot; break;
            }
            double minLot = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_VOLUME_MIN);
            if(g_pts[idx].lot < minLot) g_pts[idx].lot = minLot;
            double maxLot = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_VOLUME_MAX);
            if(g_pts[idx].lot > maxLot) g_pts[idx].lot = maxLot;

            Print("MP[", idx, "] ", g_pts[idx].symbol, " LOT: avgCnt=", g_pts[idx].averagingCount,
                  " lot=", DoubleToString(g_pts[idx].lot, 2),
                  " mult=", DoubleToString(MathPow(LotMultiplikator, g_pts[idx].averagingCount + 1), 4));

            if(direction == 1)
            {
               if(OpenPairBuy(idx))
               {
                  g_pts[idx].lastTradeTime = TimeCurrent();
                  g_pts[idx].averagingCount++;
               }
            }
            else if(direction == 2)
            {
               if(OpenPairSell(idx))
               {
                  g_pts[idx].lastTradeTime = TimeCurrent();
                  g_pts[idx].averagingCount++;
               }
            }
         }
      }

      // === TRAILING STOP ===
      if(Use_Trailing_Stop && g_pts[idx].totalCount > 0)
      {
         long stopLevel = SymbolInfoInteger(g_pts[idx].symbol, SYMBOL_TRADE_STOPS_LEVEL);
         double minStopDist = stopLevel * pointVal;

         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;
            if(PositionGetString(POSITION_SYMBOL) != g_pts[idx].symbol) continue;
            if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentSL = PositionGetDouble(POSITION_SL);
            long posType = PositionGetInteger(POSITION_TYPE);

            double trailDist = TrailingDistancePips * pointVal;
            if(TrailingMode == 1)
            {
               if(g_pts[idx].atrHandle != INVALID_HANDLE)
               {
                  double atrBuf[];
                  if(CopyBuffer(g_pts[idx].atrHandle, 0, 0, 1, atrBuf) > 0)
                     trailDist = atrBuf[0] * Trail_ATR_Multiplier;
               }
               else if(g_trailAtrHandle != INVALID_HANDLE)
               {
                  double atrBuf[];
                  if(CopyBuffer(g_trailAtrHandle, 0, 0, 1, atrBuf) > 0)
                     trailDist = atrBuf[0] * Trail_ATR_Multiplier;
               }
            }
            if(trailDist < minStopDist) trailDist = minStopDist;

            if(posType == POSITION_TYPE_BUY)
            {
               double profitPips = (bid - openPrice) / pointVal;
               if(Use_Breakeven && profitPips >= BreakevenStartPips)
               {
                  double bePrice = NormalizeDouble(openPrice + MathMax(BreakevenProfitPips * pointVal, minStopDist), symDigits);
                  if(currentSL < bePrice || currentSL == 0)
                  {
                     if(!g_pts[idx].trade.PositionModify(ticket, bePrice, PositionGetDouble(POSITION_TP)))
                        Print("MP TRAIL BE FAIL: ", g_pts[idx].symbol, " err=", g_pts[idx].trade.ResultRetcode(),
                              " be=", DoubleToString(bePrice, symDigits), " minDist=", DoubleToString(minStopDist, symDigits));
                  }
               }
               if(profitPips >= TrailingStartPips)
               {
                  double newSL = NormalizeDouble(bid - trailDist, symDigits);
                  if(newSL <= openPrice) newSL = NormalizeDouble(openPrice + minStopDist, symDigits);
                  if(newSL > currentSL || currentSL == 0)
                  {
                     if(!g_pts[idx].trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
                        Print("MP TRAIL BUY FAIL: ", g_pts[idx].symbol, " err=", g_pts[idx].trade.ResultRetcode(),
                              " sl=", DoubleToString(newSL, symDigits), " bid=", DoubleToString(bid, symDigits),
                              " trail=", DoubleToString(trailDist, symDigits));
                     else
                        Print("MP TRAIL BUY SET: ", g_pts[idx].symbol, " sl=", DoubleToString(newSL, symDigits));
                  }
               }
            }
            else if(posType == POSITION_TYPE_SELL)
            {
               double profitPips = (openPrice - ask) / pointVal;
               if(Use_Breakeven && profitPips >= BreakevenStartPips)
               {
                  double bePrice = NormalizeDouble(openPrice - MathMax(BreakevenProfitPips * pointVal, minStopDist), symDigits);
                  if(currentSL > bePrice || currentSL == 0)
                  {
                     if(!g_pts[idx].trade.PositionModify(ticket, bePrice, PositionGetDouble(POSITION_TP)))
                        Print("MP TRAIL BE FAIL: ", g_pts[idx].symbol, " err=", g_pts[idx].trade.ResultRetcode(),
                              " be=", DoubleToString(bePrice, symDigits), " minDist=", DoubleToString(minStopDist, symDigits));
                  }
               }
               if(profitPips >= TrailingStartPips)
               {
                  double newSL = NormalizeDouble(ask + trailDist, symDigits);
                  if(newSL >= openPrice) newSL = NormalizeDouble(openPrice - minStopDist, symDigits);
                  if(newSL < currentSL || currentSL == 0)
                  {
                     if(!g_pts[idx].trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
                        Print("MP TRAIL SELL FAIL: ", g_pts[idx].symbol, " err=", g_pts[idx].trade.ResultRetcode(),
                              " sl=", DoubleToString(newSL, symDigits), " ask=", DoubleToString(ask, symDigits),
                              " trail=", DoubleToString(trailDist, symDigits));
                     else
                        Print("MP TRAIL SELL SET: ", g_pts[idx].symbol, " sl=", DoubleToString(newSL, symDigits));
                  }
               }
            }
         }
      }

      // === HEDGE ===
      if(Use_Hedging)
      {
         if(g_pts[idx].hasBuy && g_pts[idx].hasSell)
         {
            if(Use_Hedge_TP && g_pts[idx].totalProfit >= HedgeTakeProfit)
            {
               for(int i = PositionsTotal() - 1; i >= 0; i--)
               {
                  ulong ticket = PositionGetTicket(i);
                  if(ticket == 0) continue;
                  if(PositionGetString(POSITION_SYMBOL) != g_pts[idx].symbol) continue;
                  if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
                  g_pts[idx].trade.PositionClose(ticket);
               }
            }
         }
         else if(g_pts[idx].hasBuy && !g_pts[idx].hasSell)
         {
            double distPips = (g_pts[idx].lastBuyPrice - ask) / pointVal / (double)g_pts[idx].pointDivider;
            if(g_pts[idx].isCrypto) distPips = (g_pts[idx].lastBuyPrice - ask) / pointVal;
            if(distPips >= HedgeDistancePips && g_pts[idx].sellCount < MaxHedgeCount)
            {
               double hedgeLot = NormalizeDouble(Lot * HedgeLotMultiplier, 2);
               double minLot = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_VOLUME_MIN);
               if(hedgeLot < minLot) hedgeLot = minLot;
               string cmt = g_pts[idx].symbol + "-HEDGE-SELL-" + IntegerToString(g_pts[idx].sellCount + 1);
               g_pts[idx].trade.Sell(hedgeLot, g_pts[idx].symbol, bid, 0, 0, cmt);
            }
         }
         else if(g_pts[idx].hasSell && !g_pts[idx].hasBuy)
         {
            double distPips = (ask - g_pts[idx].lastSellPrice) / pointVal / (double)g_pts[idx].pointDivider;
            if(g_pts[idx].isCrypto) distPips = (ask - g_pts[idx].lastSellPrice) / pointVal;
            if(distPips >= HedgeDistancePips && g_pts[idx].buyCount < MaxHedgeCount)
            {
               double hedgeLot = NormalizeDouble(Lot * HedgeLotMultiplier, 2);
               double minLot = SymbolInfoDouble(g_pts[idx].symbol, SYMBOL_VOLUME_MIN);
               if(hedgeLot < minLot) hedgeLot = minLot;
               string cmt = g_pts[idx].symbol + "-HEDGE-BUY-" + IntegerToString(g_pts[idx].buyCount + 1);
               g_pts[idx].trade.Buy(hedgeLot, g_pts[idx].symbol, ask, 0, 0, cmt);
            }
         }
      }

      // === TIMEOUT CLOSE ===
      if(Use_TimeOut && g_pts[idx].timeoutTime > 0 && TimeCurrent() >= g_pts[idx].timeoutTime)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;
            if(PositionGetString(POSITION_SYMBOL) != g_pts[idx].symbol) continue;
            if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
            g_pts[idx].trade.PositionClose(ticket);
         }
         Print("PAIR TIMEOUT: closed all ", g_pts[idx].symbol);
      }
   }
}

//+------------------------------------------------------------------+
void ManageMultiPair()
{
   if(!Use_MultiPair || g_pairCount == 0) return;

   // Global cooldown after ANY server failure (60 seconds)
   if(g_lastServerFailTime > 0 && TimeCurrent() - g_lastServerFailTime < 60)
      return;

   static datetime mpTickLog = 0;
   if(TimeCurrent() - mpTickLog > 30)
   {
      mpTickLog = TimeCurrent();
      string info = "MP PROGRESS: pairs=" + IntegerToString(g_pairCount) + " magic=" + IntegerToString(g_magic) + " tf=" + EnumToString(g_currentTimeframe);
      for(int p = 0; p < g_pairCount; p++)
      {
         bool dataOK = CheckPairDataReady(p);
         MqlTick tick;
         SymbolInfoTick(g_pts[p].symbol, tick);
         info += "\n  [" + IntegerToString(p) + "] " + g_pts[p].symbol +
                 " pos=" + IntegerToString(g_pts[p].totalCount) +
                 " buy=" + IntegerToString(g_pts[p].buyCount) +
                 " sell=" + IntegerToString(g_pts[p].sellCount) +
                 " avg=" + IntegerToString(g_pts[p].averagingCount) +
                 " PnL=" + DoubleToString(g_pts[p].totalProfit, 2) +
                 " data=" + (dataOK ? "OK" : "NO") +
                 " ask=" + DoubleToString(tick.ask, (int)SymbolInfoInteger(g_pts[p].symbol, SYMBOL_DIGITS)) +
                 " bid=" + DoubleToString(tick.bid, (int)SymbolInfoInteger(g_pts[p].symbol, SYMBOL_DIGITS)) +
                 " vol=" + IntegerToString(iVolume(g_pts[p].symbol, g_currentTimeframe, 0));
      }
      Print(info);
   }

   for(int p = 0; p < g_pairCount; p++)
   {
      ManagePairTrading(p);
   }
}
//+------------------------------------------------------------------+
