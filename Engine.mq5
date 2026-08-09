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

enum ENUM_HEDGE_STATE
{
   HSTATE_NORMAL = 0,
   HSTATE_WARNING,
   HSTATE_PARTIAL_HEDGE,
   HSTATE_FULL_HEDGE,
   HSTATE_RECOVERY
};

input group "=== General Settings ==="
input string          Minimal_Deposit      = "$200";
input string          Time_Frame           = "Time Frame M1";
input string          Pairs                = "EurUsd";
input int             MagicNumber         = 222;
input bool            Use_MultiPair        = true;     // Enable Multi-Pair Dashboard
input string          MultiPairs           = "BTCUSDm, EURUSDm, XAUUSD"; // Pairs: comma-separated

input group "=== Lot Settings ==="
input bool            Use_Fixed_Lot       = false;
input double          Lot                  = 0.01;
input double          LotMultiplikator    = 1.21;
input int             LotMode             = 1;        // 0=Fixed, 1=Multiplier, 2=Recovery

input group "=== Trade Settings ==="
input double          TakeProfit          = 80000;
input double          Step                = 21000.0;
input double          MinEntryDistancePips = 0.5; // added: minimum distance (pips) between consecutive entries
input double          Averaging           = 1.21;
input int             MaxTrades           = 31;
input int             MinTradeDelaySec    = 60;       // Min seconds between trades

input group "=== TP Multiplier ==="
input bool            Use_TP_Multiplier   = true;     // Use TP Multiplier
input double          TP_Multiplier       = 1.21;     // TP Multiplier per averaging level
input int             TP_Max_Level        = 80000;    // Max averaging level for TP calc
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
input bool            UseRangeFilter      = false;
input double          RangeMinPips        = 10;
input double          RangeMaxPips        = 200;

// ... rest of inputs unchanged ...

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

// Hedge lock/unlock variables
double   g_hedgePeakProfit;
datetime g_lastUnlockBar;
datetime g_lastHedgeAction;
int      g_hedgeCycles;
ENUM_HEDGE_STATE g_hedgeState;
double   g_bestBasketProfit;
double   g_initialBasketEquity;
int      g_hedgeAtrHandle;

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

     // Hedge lock/unlock
     g_hedgePeakProfit = 0;
     g_lastUnlockBar = 0;
     g_lastHedgeAction = 0;
     g_hedgeCycles = 0;
     g_hedgeState = HSTATE_NORMAL;
     g_bestBasketProfit = -DBL_MAX;
     g_initialBasketEquity = AccountInfoDouble(ACCOUNT_EQUITY);
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
void ManageTrailingStop()
{
   // SAFER ManageTrailingStop implementation (throttled and step-guarded)
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!PositionSelectByIndex(i))
         continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      if(sym != _Symbol)
         continue;
      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic != g_magic)
         continue;

      int posType = (int)PositionGetInteger(POSITION_TYPE);
      ulong ticket = (ulong)PositionGetInteger(POSITION_TICKET);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double curPrice = (posType==POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double curSL = PositionGetDouble(POSITION_SL);
      double curTP = PositionGetDouble(POSITION_TP);

      double profitPips = (posType==POSITION_TYPE_BUY) ? ((curPrice - openPrice)/_Point) : ((openPrice - curPrice)/_Point);
      if(profitPips < TrailingStartPips)
         continue;

      double trailPoints = TrailingDistancePips * g_pointDivider; // pips -> points
      double stepPoints  = TrailingStepPips * g_pointDivider;     // pips -> points
      double desiredSL = 0.0;
      if(posType==POSITION_TYPE_BUY)
         desiredSL = curPrice - trailPoints * _Point;
      else
         desiredSL = curPrice + trailPoints * _Point;

      double improvementPoints = 0.0;
      if(posType==POSITION_TYPE_BUY)
         improvementPoints = (desiredSL - curSL)/_Point; // positive if SL moved up
      else
         improvementPoints = (curSL - desiredSL)/_Point; // positive if SL moved down

      if(improvementPoints < stepPoints)
         continue;

      if(TimeCurrent() - g_lastTrailingTime < MinSecondsBetweenMods)
         continue;

      // safety: don't set SL past current price
      if(posType==POSITION_TYPE_BUY && desiredSL >= curPrice - _Point) continue;
      if(posType==POSITION_TYPE_SELL && desiredSL <= curPrice + _Point) continue;

      bool ok = trade.PositionModify(ticket, NormalizeDouble(desiredSL, _Digits), curTP);
      if(ok)
      {
         g_lastTrailingTime = TimeCurrent();
         Print("Trailing updated ticket=", ticket, " newSL=", DoubleToString(desiredSL, _Digits));
      }
      else
      {
         Print("Trailing modify failed ticket=", ticket, " err=", GetLastError());
      }
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   // Skip everything when market is closed
   double _chkAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double _chkBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(_chkAsk <= 0 || _chkBid <= 0)
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

     // TRAILING STOP — trail each position independently
     if(Use_Trailing_Stop && g_totalCount > 0)
     {
        ManageTrailingStop();
     }

     // SMART TRAIL — trail each position independently
     if(Use_SmartTrail && g_totalCount > 0)
     {
        ManageSmartTrail();
     }

     // PRICE % TRAIL — trail each position independently
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
        ManageHedgeProfitLock();
        ManageStagedUnlock();
     }

     // SAFETY CHECKS
     UpdateHedgeState();
     HardDDCheck();
     if(!AccountSafetyOK())
     {
        if(g_totalCount > 0)
           CloseAllPositions();
        return;
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

          // Reserve the trade slot before attempting the order to avoid duplicate submissions
          if(TimeCurrent() - g_lastTradeTime < MinTradeDelaySec)
          {
             Print("Blocked attempt: MinTradeDelaySec not passed");
          }
          else
          {
             g_lastTradeTime = TimeCurrent(); // reserve
             if(!OpenBuy())
             {
                g_lastModifyFailTime = TimeCurrent();
                Print("OpenBuy failed");
             }
             else
             {
                g_timeoutTime = TimeCurrent() + (TimeOut_Hours * 3600);
                g_averagingCount = 0;
                g_buyAveragingCount = 0;
                g_sellAveragingCount = 0;
             }
          }
       }
       else if(close2 < close1)
       {
          g_lot = GetFirstLot();
          Print("TRYING SELL: lot=", DoubleToString(g_lot, 2), " bid=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits));

          if(TimeCurrent() - g_lastTradeTime < MinTradeDelaySec)
          {
             Print("Blocked attempt: MinTradeDelaySec not passed");
          }
          else
          {
             g_lastTradeTime = TimeCurrent();
             if(!OpenSell())
             {
                g_lastModifyFailTime = TimeCurrent();
                Print("OpenSell failed");
             }
             else
             {
                g_timeoutTime = TimeCurrent() + (TimeOut_Hours * 3600);
                g_averagingCount = 0;
                g_buyAveragingCount = 0;
                g_sellAveragingCount = 0;
             }
          }
       }

}
