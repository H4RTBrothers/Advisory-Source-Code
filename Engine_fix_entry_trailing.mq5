// Engine_fix_entry_trailing.mq5
// Helper patch file containing safer entry & trailing implementations for Engine.mq5
// Apply these changes into Engine.mq5 in the indicated places, or use this file as reference.

/*
1) Add this input (place in "=== Trade Settings ===" right after Step):

input double          Step                = 21000.0;
input double          MinEntryDistancePips = 0.5;   // minimum distance in pips between consecutive entries

2) Replace the averaging/step-check block where Engine computes shouldOpen/direction.
   Search for the block that contains: double dist = (g_lastBuyPrice - ask) / _Point; and similar.
   Replace that whole inner block with the following code:
*/

// === SAFER STEP / AVERAGING CHECKS (paste into Engine.mq5) ===
{
   int direction = 0; // 0=none, 1=buy averaging, 2=sell averaging

   bool volumeOK = true;
   if(invisible_mode && iVolume(_Symbol, g_currentTimeframe, 0) >= 5)
      volumeOK = false;

   if(volumeOK)
   {
      // Convert Step (pips) into points for comparisons
      double stepPoints = Step * g_pointDivider;           // Step (pips) → points
      double minEntryPoints = MinEntryDistancePips * g_pointDivider; // min-entry in points

      // BUY-only: if ask dropped Step pips from last buy → open BUY again
      if(g_hasBuy && !g_hasSell && g_lastBuyPrice > 0)
      {
         bool hedgePending = false;
         if(HedgeMode == 1)
         {
            double ask2 = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            hedgePending = (ask2 < g_buyAvgPrice);
         }

         if(!hedgePending)
         {
            double distPoints = (g_lastBuyPrice - ask) / _Point; // distance in points
            // ensure both minimum step and minimum entry distance are satisfied
            if(distPoints >= stepPoints && MathAbs((ask - g_lastBuyPrice) / _Point) > minEntryPoints)
            {
               shouldOpen = true;
               direction = 1; // Buy averaging
            }
         }
      }
      // SELL-only: if bid rose Step pips from last sell → open SELL again
      else if(g_hasSell && !g_hasBuy && g_lastSellPrice > 0)
      {
         bool hedgePending = false;
         if(HedgeMode == 1)
         {
            hedgePending = (bid > g_sellAvgPrice);
         }

         if(!hedgePending)
         {
            double distPoints = (bid - g_lastSellPrice) / _Point;
            if(distPoints >= stepPoints && MathAbs((bid - g_lastSellPrice) / _Point) > minEntryPoints)
            {
               shouldOpen = true;
               direction = 2; // Sell averaging
            }
         }
      }
      // Hedged (both buy and sell): check both sides independently
      else if(g_hasBuy && g_hasSell)
      {
         double distBuy = (g_lastBuyPrice - ask) / _Point;
         if(distBuy >= stepPoints && g_buyCount < MaxTrades && MathAbs((ask - g_lastBuyPrice) / _Point) > minEntryPoints)
         {
            shouldOpen = true;
            direction = 1; // Buy averaging
         }
         double distSell = (bid - g_lastSellPrice) / _Point;
         if(distSell >= stepPoints && g_sellCount < MaxTrades && MathAbs((bid - g_lastSellPrice) / _Point) > minEntryPoints)
         {
            shouldOpen = true;
            direction = 2; // Sell averaging
         }
      }
   }
}

/*
3) Reserve g_lastTradeTime immediately before attempting any order. Replace order attempts like:

if(OpenBuy())
{
   g_lastTradeTime = TimeCurrent();
   ...
}

with the pattern:

if(TimeCurrent() - g_lastTradeTime < MinTradeDelaySec)
{
   Print("Blocked attempt: MinTradeDelaySec not passed");
}
else
{
   g_lastTradeTime = TimeCurrent(); // reserve the slot
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

Apply the symmetric change for OpenSell() and averaging OpenBuy/OpenSell calls.

4) Replace the ManageTrailingStop() implementation with throttling.
   Find ManageTrailingStop() and replace its body with the following function (the signature should match your file):
*/

// === SAFER ManageTrailingStop implementation (paste into Engine.mq5, replacing existing) ===
void ManageTrailingStop()
{
   // loop through positions for this symbol + magic
   for(int p = PositionsTotal() - 1; p >= 0; p--)
   {
      ulong ticket = PositionGetTicket(p);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      int posType = (int)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double curPrice = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double curSL = PositionGetDouble(POSITION_SL);
      double curTP = PositionGetDouble(POSITION_TP);

      // require a minimum floating profit (in pips) before trailing starts
      double profitPips = (posType == POSITION_TYPE_BUY) ? ((curPrice - openPrice) / _Point) : ((openPrice - curPrice) / _Point);
      if(profitPips < TrailingStartPips)
         continue; // not profitable enough to trail yet

      // compute desired SL (distance from current price)
      double trailPoints = TrailingDistancePips * g_pointDivider; // pips -> points
      double stepPoints  = TrailingStepPips * g_pointDivider;     // pips -> points
      double desiredSL = 0.0;
      if(posType == POSITION_TYPE_BUY)
         desiredSL = curPrice - trailPoints * _Point;
      else
         desiredSL = curPrice + trailPoints * _Point;

      // improvement check: only change SL if improvement >= step threshold
      double improvementPoints = 0.0;
      if(posType == POSITION_TYPE_BUY)
         improvementPoints = (desiredSL - curSL) / _Point; // positive if SL moved up (improvement)
      else
         improvementPoints = (curSL - desiredSL) / _Point; // positive if SL moved down (improvement)

      if(improvementPoints < stepPoints)
         continue; // not enough improvement

      // throttle modifications across the EA
      if(TimeCurrent() - g_lastTrailingTime < MinSecondsBetweenMods)
         continue;

      // safety: don't set SL past the current price
      if(posType == POSITION_TYPE_BUY && desiredSL >= curPrice - _Point) continue;
      if(posType == POSITION_TYPE_SELL && desiredSL <= curPrice + _Point) continue;

      // perform modify
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

/*
End of helper patch file. After you or I apply these edits to Engine.mq5, compile and test as described in the PR notes.
*/
