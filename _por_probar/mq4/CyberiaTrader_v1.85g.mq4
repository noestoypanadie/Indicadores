#property copyright "Copyright c 2006, Cyberia Decisions"
#property link      "http://cyberia.org.ru"

//+------------------------------------------------------------------------------------+
//|                                                                                    |
//|                              SPECIAL CONTRIBUTORS                                  |
//|             Alexandr A Krivoshey AKA OpenStorm -- Original Author                  |                          |
//| project1972, Igorad, Fikko, Vincent Visoiu AKA FXSpeedster -- www.brookstonefx.com |
//|                                                                                    |
//+------------------------------------------------------------------------------------+

#define DECISION_BUY 1
#define DECISION_SELL 0
#define DECISION_UNKNOWN -1

// ---- Global variables
extern bool ExitMarket = false;
extern bool ShowSuitablePeriod = false;
extern bool ShowMarketInfo = false;
extern bool ShowAccountStatus = false;
extern bool ShowStat = false;
extern bool ShowDecision = false;
extern bool ShowDirection = false;
extern bool BlockSell = false;
extern bool BlockBuy = false;
extern bool ShowLots = false;
extern bool BlockStopLoss = false;
extern bool DisableShadowStopLoss = true;
extern bool DisableExitSell = false;
extern bool DisableExitBuy = false;
extern bool EnableMACD = false;
extern bool EnableMA = false;
extern bool EnableFractals = false;
extern bool EnableCCI = true;
extern bool EnableCyberiaLogic = true;
extern bool EnableLogicTrading = true;
extern bool EnableADX = false;
extern bool EnablePivot = true;             // Use Pivot_day as filter
extern bool BlockPipsator = true;
extern bool EnableMoneyTrain = false;
extern bool EnableReverseDetector = true;
extern double ReverseIndex = 3.82;
extern double MoneyTrainLevel = 4;
extern int MACDLevel = 10;
extern bool AutoLots = True;
extern double MAXLots = 10;                   // Max lots size on AutoLots--added by project1972
extern bool AutoDirection = True;
extern double ValuesPeriodCount = 23;
extern double ValuesPeriodCountMax = 23;
extern double SlipPage = 1;                  // Slippage of the rate
extern double Lots = 0.1;                    // Quantity of the lots
extern double StopLoss = 0;
extern double TakeProfit = 0;
extern double SymbolsCount = 2;
extern double Risk = 0.7;
extern double StopLossIndex = 2.5;
extern bool AutoStopLossIndex = true;
extern double StaticStopLoss = 11;
extern double StopLevel;
extern bool EnableTrailingStop = true;       // Enable Dynamic Trailing Stop
extern double  TrailingStopFactor      = 1.0;
extern string TimeTradeHoursDisabled="";     // Example "00,01,02,03,04,05" GMT
extern int    GMT=1;                         // For North Finance GMT = 3, Alpari GMT = 1, IBFX GMT = -1 etc.
extern int MagicNumber=123000;               // Magic Number -- change for every pair traded

// ----

int    NoTradeHours1=25;                     // Time not trade
int    NoTradeHours2=25;                     // Time not trade
int    NoTradeHours3=25;                     // Time not trade
int    NoTradeHours4=25;                     // Time not trade
int    NoTradeHours5=25;                     // Time not trade
int    NoTradeHours6=25;                     // Time not trade

bool SavedBlockSell;
bool SavedBlockBuy;

bool DisableSell = false;
bool DisableBuy = false;
bool ExitSell = false;
bool ExitBuy = false;
double Disperce = 0;
double DisperceMax = 0;
bool DisableSellPipsator = false;
bool DisableBuyPipsator = false;
//----
double ValuePeriod = 1;                      // Step of period in minutes
double ValuePeriodPrev = 1;
int FoundOpenedOrder = false;
bool DisablePipsator = false;
double BidPrev = 0;
double AskPrev = 0;

// Variables for evaluating the quality of the simulation
double BuyPossibilityQuality;
double SellPossibilityQuality;
double UndefinedPossibilityQuality;
//double BuyPossibilityQualityMid;
double PossibilityQuality;
double QualityMax = 0;
//----
double BuySucPossibilityQuality;
double SellSucPossibilityQuality;
double UndefinedSucPossibilityQuality;
double PossibilitySucQuality;
//----
double ModelingPeriod;                       // Period of simulation in the minutes
double ModelingBars;                         // Quantity of steps in the period
//----
double Spread;                               // Spread
double Decision;
double DecisionValue;
double PrevDecisionValue;
//----
int ticket, total, cnt;
//----
double BuyPossibility;
double SellPossibility;
double UndefinedPossibility;
double BuyPossibilityPrev;
double SellPossibilityPrev;
double UndefinedPossibilityPrev;
//----
double BuySucPossibilityMid;                 // Average probability of the successful purchase
double SellSucPossibilityMid;                // Average probability of successful sale
double UndefinedSucPossibilityMid;           // Average successful probability of the indeterminate state
//----
double SellSucPossibilityCount;              // Count of probabilities of successful sale
double BuySucPossibilityCount;               // Count of probabilities of the successful purchase
double UndefinedSucPossibilityCount;         // Count of probabilities of the indeterminate state
//----
double BuyPossibilityMid;                    // Average probability of the purchase
double SellPossibilityMid;                   // Average probability of sale
double UndefinedPossibilityMid;              // Average probability of the indeterminate state
//----
double BuyPossibilityCount;                  // Count of probabilities of purchase
double SellPossibilityCount;                 // Count of probabilities of sale
double UndefinedPossibilityCount;            // Count of probabilities of the indeterminate state
//----

// Dynamic Trailing stop (TS) global variables
double PrevBuyStop,BuyStop;
double PrevSellStop,SellStop;

// Variables for the storage information (data) about the market
double ModeLow;
double ModeHigh;
double ModeTime;
double ModeBid;
double ModeAsk;
double ModePoint;
double ModeDigits;
double ModeSpread;
double ModeStopLevel;
double ModeLotSize;
double ModeTickValue;
double ModeTickSize;
double ModeSwapLong;
double ModeSwapShort;
double ModeStarting;
double ModeExpiration;
double ModeTradeAllowed;
double ModeMinLot;
double ModeLotStep;
//
/* System specific */
//
string SystemName = "CyberiaTrader-OS";
double version = 1.85;

//+------------------------------------------------------------------+
//| We read information about the market                                                                  |
//+------------------------------------------------------------------+

int GetMarketInfo()
  {
   ModeLow = MarketInfo(Symbol(), MODE_LOW);
   ModeHigh = MarketInfo(Symbol(), MODE_HIGH);
   ModeTime = MarketInfo(Symbol(), MODE_TIME);
   ModeBid = MarketInfo(Symbol(), MODE_BID);
   ModeAsk = MarketInfo(Symbol(), MODE_ASK);
   ModePoint = MarketInfo(Symbol(), MODE_POINT);
   ModeDigits = MarketInfo(Symbol(), MODE_DIGITS);
   ModeSpread = MarketInfo(Symbol(), MODE_SPREAD);
   ModeStopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
   ModeLotSize = MarketInfo(Symbol(), MODE_LOTSIZE);
   ModeTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   ModeTickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
   ModeSwapLong = MarketInfo(Symbol(), MODE_SWAPLONG);
   ModeSwapShort = MarketInfo(Symbol(), MODE_SWAPSHORT);
   ModeStarting = MarketInfo(Symbol(), MODE_STARTING);
   ModeExpiration = MarketInfo(Symbol(), MODE_EXPIRATION);
   ModeTradeAllowed = MarketInfo(Symbol(), MODE_TRADEALLOWED);
   ModeMinLot = MarketInfo(Symbol(), MODE_MINLOT);
   ModeLotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

   // It is concluded information about the market
   if ( ShowMarketInfo == True )
     {
       Print("ModeLow:",ModeLow);
       Print("ModeHigh:",ModeHigh);
       Print("ModeTime:",ModeTime);
       Print("ModeBid:",ModeBid);
       Print("ModeAsk:",ModeAsk);
       Print("ModePoint:",ModePoint);
       Print("ModeDigits:",ModeDigits);
       Print("ModeSpread:",ModeSpread);
       Print("ModeStopLevel:",ModeStopLevel);
       Print("ModeLotSize:",ModeLotSize);
       Print("ModeTickValue:",ModeTickValue);
       Print("ModeTickSize:",ModeTickSize);
       Print("ModeSwapLong:",ModeSwapLong);
       Print("ModeSwapShort:",ModeSwapShort);
       Print("ModeStarting:",ModeStarting);
       Print("ModeExpiration:",ModeExpiration);
       Print("ModeTradeAllowed:",ModeTradeAllowed);
       Print("ModeMinLot:",ModeMinLot);
       Print("ModeLotStep:",ModeLotStep);
     }
   return (0);
  }
  
//+------------------------------------------------------------------+
//| Calculation of lot quantity                                          |
//+------------------------------------------------------------------+

int CyberiaLots()
  {
   GetMarketInfo();
   // Sum of the calculation
   double S;
   // Cost of the lot
   double L;
   // Lot quantity
   double k;
   // Cost of one pip
   if( AutoLots == true )
     {
       if(SymbolsCount != OrdersTotal())
         {
           S = (AccountBalance()* Risk - AccountMargin()) * AccountLeverage() / 
                (SymbolsCount - OrdersTotal());
         }
       else
         {
           S = 0;
         }
       // We check, does currency appear to be EURUSD?
       if(StringFind( Symbol(), "USD") == -1)
         {
           if(StringFind( Symbol(), "EUR") == -1)
             {
               S = 0;
             }
           else
             {
               S = S / iClose ("EURUSD", 0, 0);
               if(StringFind( Symbol(), "EUR") != 0)
                  {
                  S /= Bid;
                  }
             }
         }
       else
         {
           if(StringFind(Symbol(), "USD") != 0)
             {
               S /= Bid;
             }
         }
       S /= ModeLotSize;
       S -= ModeMinLot;
       S /= ModeLotStep;
       S = NormalizeDouble(S, 0);
       S *= ModeLotStep;
       S += ModeMinLot;
       Lots = S;
       if (Lots>MAXLots){ Lots=MAXLots; }
       if(ShowLots == True)
           Print ("Lots:", Lots);
     }
   return (0);
  }
  
//+------------------------------------------------------------------+
//|   We initialize the adviser                                      |
//+------------------------------------------------------------------+

int init()
  {

   SavedBlockSell = BlockSell;
   SavedBlockBuy  = BlockBuy;

   AccountStatus();   
   GetMarketInfo();
   ModelingPeriod = ValuePeriod * ValuesPeriodCount;              // Period of simulation in minutes
   if (ValuePeriod != 0 )
       ModelingBars = ModelingPeriod / ValuePeriod;               // Quantity of steps in the period
   CalculateSpread();
   return(0);
  }
  
//+------------------------------------------------------------------+
//| We calculate the actual value of spread (returned functions on   |
//| the market can give the incorrect actual value of spread if the  |
//| broker varies the value of spread                                |
//+------------------------------------------------------------------+

int CalculateSpread()
  {
   Spread = Ask - Bid;
   return (0);
  }
  
//+------------------------------------------------------------------+
//| We make the decision                                               |
//+------------------------------------------------------------------+

int CalculatePossibility (int shift)
  {
   DecisionValue = iClose( Symbol(), 0, ValuePeriod * shift) - 
                   iOpen( Symbol(), 0, ValuePeriod * shift);
   PrevDecisionValue = iClose( Symbol(), 0, ValuePeriod * (shift+1)) - 
                       iOpen( Symbol(), 0, ValuePeriod * (shift+1));
   SellPossibility = 0;
   BuyPossibility = 0;
   UndefinedPossibility = 0;
   if(DecisionValue != 0)                                         // If the solution not definite
     {
       if(DecisionValue > 0)                                      // If the solution in favor of sale
         {
                                                                  // Suspicion to the probability of sale
           if(PrevDecisionValue < 0)                              // Confirmation of the solution in favor of sale
             {
               Decision = DECISION_SELL;
               BuyPossibility = 0;
               SellPossibility = DecisionValue;
               UndefinedPossibility = 0;
             }
           else                                                   // Otherwise the solution is not determined
             {
               Decision = DECISION_UNKNOWN;
               UndefinedPossibility = DecisionValue;
               BuyPossibility = 0;
               SellPossibility = 0;
             }
         }
       else                                                       // If the solution in favor of the purchase
         {
           if(PrevDecisionValue > 0)                              // Confirmation of the solution in favor of buy
             {
               Decision = DECISION_BUY;
               SellPossibility = 0;
               UndefinedPossibility = 0;
               BuyPossibility = -1 * DecisionValue;
             }
           else                                                   // The solution is not determined
             {
               Decision = DECISION_UNKNOWN;
               UndefinedPossibility = -1 * DecisionValue;
               SellPossibility = 0;
               BuyPossibility = 0;
             }
         }
     }
   else
     {
       Decision = DECISION_UNKNOWN;
       UndefinedPossibility = 0;
       SellPossibility = 0;
       BuyPossibility = 0;
     }
   return (Decision);
  }
  
//+------------------------------------------------------------------+
//| We calculate the statistics of the probabilities                                |
//+------------------------------------------------------------------+

int CalculatePossibilityStat()
  {
   int i;
   BuySucPossibilityCount = 0;
   SellSucPossibilityCount = 0;
   UndefinedSucPossibilityCount = 0;
//----
   BuyPossibilityCount = 0;
   SellPossibilityCount = 0;
   UndefinedPossibilityCount = 0;
// We calculate the average values of the probability
   BuySucPossibilityMid = 0;
   SellSucPossibilityMid = 0;
   UndefinedSucPossibilityMid = 0;
   BuyPossibilityQuality = 0;
   SellPossibilityQuality = 0;
   UndefinedPossibilityQuality = 0;
   PossibilityQuality = 0;
//----
   BuySucPossibilityQuality = 0;
   SellSucPossibilityQuality = 0;
   UndefinedSucPossibilityQuality = 0;
   PossibilitySucQuality = 0;
   for( i = 0 ; i < ModelingBars ; i ++ )
     {
       // We calculate the solution for this interval
       CalculatePossibility (i);
       // If the solution for value of i - was sold         
       if(Decision == DECISION_SELL )
           SellPossibilityQuality ++;           
       // If the solution for value of i - was bought
       if(Decision == DECISION_BUY )
           BuyPossibilityQuality ++;           
       // If the solution for value of i - is not determined
       if(Decision == DECISION_UNKNOWN )
           UndefinedPossibilityQuality ++;           
       // The same estimations for the successful situations                 
       //
       if((BuyPossibility > Spread) || (SellPossibility > Spread) || 
          (UndefinedPossibility > Spread))
         {
           if(Decision == DECISION_SELL)
               SellSucPossibilityQuality ++;                     
           if(Decision == DECISION_BUY)
               BuySucPossibilityQuality ++;
           if(Decision == DECISION_UNKNOWN )
               UndefinedSucPossibilityQuality ++;                   
         }  
       // We calculate the average probabilities of the events
       // Probabilities of the purchase
       BuyPossibilityMid *= BuyPossibilityCount;
       BuyPossibilityCount ++;
       BuyPossibilityMid += BuyPossibility;
       if(BuyPossibilityCount != 0 )
           BuyPossibilityMid /= BuyPossibilityCount;
       else
           BuyPossibilityMid = 0;
       // Вероятности продажи
       SellPossibilityMid *= SellPossibilityCount;
       SellPossibilityCount ++;
       SellPossibilityMid += SellPossibility;
       if(SellPossibilityCount != 0 )
           SellPossibilityMid /= SellPossibilityCount;
       else
           SellPossibilityMid = 0;
       // Probabilities of the indeterminate state
       UndefinedPossibilityMid *= UndefinedPossibilityCount;
       UndefinedPossibilityCount ++;
       UndefinedPossibilityMid += UndefinedPossibility;
       if(UndefinedPossibilityCount != 0)
           UndefinedPossibilityMid /= UndefinedPossibilityCount;
       else
           UndefinedPossibilityMid = 0;
       // We calculate the average probabilities of the successful events
       if(BuyPossibility > Spread)
         {
           BuySucPossibilityMid *= BuySucPossibilityCount;
           BuySucPossibilityCount ++;
           BuySucPossibilityMid += BuyPossibility;
           if(BuySucPossibilityCount != 0)
               BuySucPossibilityMid /= BuySucPossibilityCount;
           else
               BuySucPossibilityMid = 0;
         }
       if(SellPossibility > Spread)
         {
           SellSucPossibilityMid *= SellSucPossibilityCount;
           SellSucPossibilityCount ++;                 
           SellSucPossibilityMid += SellPossibility;
           if (SellSucPossibilityCount != 0)
              SellSucPossibilityMid /= SellSucPossibilityCount;
              else
                 SellSucPossibilityMid = 0;
         }
       if(UndefinedPossibility > Spread)
         {
           UndefinedSucPossibilityMid *= UndefinedSucPossibilityCount;
           UndefinedSucPossibilityCount ++;                 
           UndefinedSucPossibilityMid += UndefinedPossibility;
           if(UndefinedSucPossibilityCount != 0)
               UndefinedSucPossibilityMid /= UndefinedSucPossibilityCount;
           else
               UndefinedSucPossibilityMid = 0;
         }
     }
   if((UndefinedPossibilityQuality + SellPossibilityQuality + BuyPossibilityQuality)!= 0)
       PossibilityQuality = (SellPossibilityQuality + BuyPossibilityQuality) / 
       (UndefinedPossibilityQuality + SellPossibilityQuality + BuyPossibilityQuality);
   else             
       PossibilityQuality = 0;
   // Качество для успешных ситуаций
   if((UndefinedSucPossibilityQuality + SellSucPossibilityQuality + 
      BuySucPossibilityQuality)!= 0)          
       PossibilitySucQuality = (SellSucPossibilityQuality + BuySucPossibilityQuality) / 
                                (UndefinedSucPossibilityQuality + SellSucPossibilityQuality + 
                                BuySucPossibilityQuality);
   else             
       PossibilitySucQuality = 0;
   return (0);
  }
  
//+------------------------------------------------------------------+
//| We show the statistics                                           |
//+------------------------------------------------------------------+

int DisplayStat()
  {
   if(ShowStat == true)
     {
       Print ("SellPossibilityMid*SellPossibilityQuality:", SellPossibilityMid*SellPossibilityQuality);
       Print ("BuyPossibilityMid*BuyPossibilityQuality:", BuyPossibilityMid*BuyPossibilityQuality);
       Print ("UndefinedPossibilityMid*UndefinedPossibilityQuality:", UndefinedPossibilityMid*UndefinedPossibilityQuality);
       Print ("UndefinedSucPossibilityQuality:", UndefinedSucPossibilityQuality);
       Print ("SellSucPossibilityQuality:", SellSucPossibilityQuality);
       Print ("BuySucPossibilityQuality:", BuySucPossibilityQuality);
       Print ("UndefinedPossibilityQuality:", UndefinedPossibilityQuality);
       Print ("SellPossibilityQuality:", SellPossibilityQuality);
       Print ("BuyPossibilityQuality:", BuyPossibilityQuality);
       Print ("UndefinedSucPossibilityMid:", UndefinedSucPossibilityMid);
       Print ("SellSucPossibilityMid:", SellSucPossibilityMid);
       Print ("BuySucPossibilityMid:", BuySucPossibilityMid);
       Print ("UndefinedPossibilityMid:", UndefinedPossibilityMid);
       Print ("SellPossibilityMid:", SellPossibilityMid);
       Print ("BuyPossibilityMid:", BuyPossibilityMid);
     }
   return (0);
  }   // 
   
//+------------------------------------------------------------------+
//|  We analyze state for decision making                            |
//+------------------------------------------------------------------+

int CyberiaDecision()
  {
// We calculate the statistics of the period
   CalculatePossibilityStat();
// We calculate the probabilities of the accomplishment of the transactions
   CalculatePossibility(0);
   DisplayStat();
   return(Decision);     
  }
  
//+------------------------------------------------------------------+
//| We calculate the direction of the motion of the market           |
//+------------------------------------------------------------------+

int CalculateDirection()
  {
   DisableSellPipsator = false;
   DisableBuyPipsator = false;
   DisablePipsator = false;
   DisableSell = false;
   DisableBuy = false;
//----
   if(EnableCyberiaLogic == true)           
     {
       AskCyberiaLogic();
     }
   if(EnableMACD == true)
       AskMACD();
   if(EnableMA == true)
       AskMA();
   if(EnableReverseDetector == true)
       ReverseDetector();
   if (EnableFractals == true)
      AskFractals();
   if (EnableCCI == true)
      AskCCI();
   if (EnableADX ==true)
      AskADX();
   if (EnablePivot ==true)
      AskPivot();      
   return (0);
  }
  
int AskADX ()
   {
   
   if ( iADX(NULL,0,14,PRICE_HIGH,MODE_PLUSDI,0)>iADX(NULL,0,14,PRICE_HIGH,MODE_MINUSDI,0) )
      {
      DisableSell = true;
      }
      
   if ( iADX(NULL,0,14,PRICE_HIGH,MODE_PLUSDI,0)<iADX(NULL,0,14,PRICE_HIGH,MODE_MINUSDI,0) )
      {
      DisableBuy= true;
      }

   return (0);
   }

int AskPivot()
   {
   double   PrevPrice=0, PrevHigh=0, PrevLow=0, Pivot=0, Price=0;
   
   PrevPrice = iClose(NULL,PERIOD_D1,1);
   PrevHigh  = iHigh(NULL,PERIOD_D1,1);
   PrevLow   = iLow(NULL,PERIOD_D1,1);
   Pivot = (PrevHigh + PrevLow + PrevPrice)/3;
   Price = iClose(NULL,PERIOD_H1,1);

   if ( Price > Pivot )
      {
      DisableSell = true;
      }
      
   if ( Price < Pivot )
      {
      DisableBuy= true;
      }

   return (0);
   }   

int AskCCI ()
   {
   if (iCCI( NULL, 0, 13, PRICE_TYPICAL, 0) > 50)
      DisableSell = true;

   if (iCCI( NULL, 0, 13, PRICE_TYPICAL, 0) < -50)
      DisableBuy = true;
   
   return (0);
   }

//+------------------------------------------------------------------+
//| Fractal Noise Filtering                                          |
//+------------------------------------------------------------------+

int AskFractals ()
   {
   int i = 0;
   
   double F = 0;
   while (iFractals( NULL, 0, MODE_UPPER, i ) == 0  && iFractals( NULL, 0, MODE_LOWER, i ) == 0)
      {
      i ++;
      }

   
   if (iFractals( NULL, 0, MODE_UPPER, i ) != 0 ) 
      {
      BlockBuy = true;
      BlockSell = false;      
      }
      
   if (iFractals( NULL, 0, MODE_LOWER, i ) != 0 ) 
      {
      BlockSell = true;
      BlockBuy = false;
      }
      
   return (0);
   }

//+---------------------------------------------------------------------------------+
//| If probabilities exceed the thresholds of the inversion of the solution         |
//+---------------------------------------------------------------------------------+

int ReverseDetector ()
  {
   if((BuyPossibility > BuyPossibilityMid * ReverseIndex && BuyPossibility != 0 && 
      BuyPossibilityMid != 0) ||(SellPossibility > SellPossibilityMid * ReverseIndex && 
      SellPossibility != 0 && SellPossibilityMid != 0))
     {
       if(DisableSell == true)
           DisableSell = false;
       else
           DisableSell = true;
       if(DisableBuy == true)
           DisableBuy = false;
       else
           DisableBuy = true;
       //----
       if(DisableSellPipsator == true)
           DisableSellPipsator = false;
       else
           DisableSellPipsator = true;
       if(DisableBuyPipsator == true)
           DisableBuyPipsator = false;
       else
           DisableBuyPipsator = true;
     }
   return (0);
  }
  
//+------------------------------------------------------------------+
//| We interrogate the logic of the trade CyberiaLogic(C)            |
//+------------------------------------------------------------------+

int AskCyberiaLogic()
  {
   // We establish blockings with drops in the market
   /*DisableBuy = true;
   DisableSell = true;
   DisablePipsator = false;*/
   
   // If market evenly moves in the assigned direction
   if(ValuePeriod > ValuePeriodPrev)
     {
       if(SellPossibilityMid*SellPossibilityQuality > BuyPossibilityMid*BuyPossibilityQuality)
         {
           DisableSell = false;
           DisableBuy = true;
           DisableBuyPipsator = true;
           if(SellSucPossibilityMid*SellSucPossibilityQuality > 
              BuySucPossibilityMid*BuySucPossibilityQuality)
             {
               DisableSell = true;  
             }
         }
       if(SellPossibilityMid*SellPossibilityQuality < BuyPossibilityMid*BuyPossibilityQuality)
         {
           DisableSell = true;
           DisableBuy = false;
           DisableSellPipsator = true;
           if(SellSucPossibilityMid*SellSucPossibilityQuality < 
              BuySucPossibilityMid*BuySucPossibilityQuality)
             {
               DisableBuy = true;
             }
         }
     }
   // If market changes direction - never deal against the trend!!!
   if(ValuePeriod < ValuePeriodPrev)
     {
      if(SellPossibilityMid*SellPossibilityQuality > BuyPossibilityMid*BuyPossibilityQuality)
         {
           DisableSell = true;
           DisableBuy = true;
         }
      if(SellPossibilityMid*SellPossibilityQuality < BuyPossibilityMid*BuyPossibilityQuality)
        {
          DisableSell = true;
          DisableBuy = true;
        }
     }
   // If market is flat
   if(SellPossibilityMid*SellPossibilityQuality == BuyPossibilityMid*BuyPossibilityQuality)
     {
       DisableSell = true;
       DisableBuy = true;
       DisablePipsator=false;
     }
   // We block the probability of output from the market
   if(SellPossibility > SellSucPossibilityMid * 2 && SellSucPossibilityMid > 0)
     {
       DisableSell = true;
       DisableSellPipsator = true;
     }
   // We block the probability of exit from the market
   if(BuyPossibility > BuySucPossibilityMid * 2 && BuySucPossibilityMid > 0 )
     {
       DisableBuy = true;
       DisableBuyPipsator = true;
     }
   if(ShowDirection == true)
     {
       if(DisableSell == true )
         {
           Print("Sale is blocked:", SellPossibilityMid*SellPossibilityQuality);
         }
       else
         {
           Print ("Sale is permitted:", SellPossibilityMid*SellPossibilityQuality);
         }
       //----
       if(DisableBuy == true )
         {
           Print ("Purchase is blocked:", BuyPossibilityMid*BuyPossibilityQuality);
         }
       else
         {
           Print ("Purchase is permitted:", BuyPossibilityMid*BuyPossibilityQuality);
         }
     }
   if(ShowDecision == true)
     {
       if(Decision == DECISION_SELL)
           Print("Solution - to sell: ", DecisionValue);
       if(Decision == DECISION_BUY)
           Print("Solution - to buy: ", DecisionValue);
       if(Decision == DECISION_UNKNOWN)
           Print("Solution - uncertainty: ", DecisionValue);
     }
   return (0);
  }
  
//+------------------------------------------------------------------+
//| We interrogate indicator MA                                      |
//+------------------------------------------------------------------+

int AskMA()
  {
   if(iMA(Symbol(), 0, ValuePeriod, 0 , MODE_EMA, PRICE_CLOSE, 0) > 
      iMA(Symbol(), 0, ValuePeriod, 0 , MODE_EMA, PRICE_CLOSE, 1))        
     {
       DisableSell = true;
       DisableSellPipsator = true;
     }
   if(iMA(Symbol(), 0, ValuePeriod, 0 , MODE_EMA, PRICE_CLOSE, 0) < 
      iMA(Symbol(), 0, ValuePeriod, 0 , MODE_EMA, PRICE_CLOSE, 1))        
     {
       DisableBuy = true;
       DisableBuyPipsator = true;
     }
   return (0);
  }
  
//+------------------------------------------------------------------+
//| We interrogate indicator MACD                                    |
//+------------------------------------------------------------------+

int AskMACD()
  {
   double DecisionIndex = 0;
   double SellIndex = 0;
   double BuyIndex = 0;
   double BuyVector = 0;
   double SellVector = 0;
   double BuyResult = 0;
   double SellResult = 0;
   DisablePipsator = false;
   DisableSellPipsator = false;
   DisableBuyPipsator = false;
   DisableBuy = false;
   DisableSell = false;
   DisableExitSell = false;
   DisableExitBuy = false;
   // Блокируем ошибки
   for(int i = 0 ; i < MACDLevel ; i ++)
     {
       if(iMACD(Symbol(), MathPow( 2, i) , 2, 4, 1, PRICE_CLOSE, MODE_MAIN, 0) < 
          iMACD(Symbol(), MathPow( 2, i), 2, 4, 1, PRICE_CLOSE, MODE_MAIN, 1) )
         {
           SellIndex += iMACD(Symbol(), MathPow( 2, i), 2, 4, 1, PRICE_CLOSE, MODE_MAIN, 0);
         }
       if(iMACD(Symbol(), MathPow( 2, i), 2, 4, 1, PRICE_CLOSE, MODE_MAIN, 0) > 
          iMACD(Symbol(), MathPow( 2, i), 2, 4, 1, PRICE_CLOSE, MODE_MAIN, 1) )
         {
           BuyIndex += iMACD(Symbol(), MathPow( 2, i), 2, 4, 1, PRICE_CLOSE, MODE_MAIN, 0);
         }

     }
   if(SellIndex> BuyIndex)
     {
       DisableBuy = true;
       DisableBuyPipsator = true;
     }
   if(SellIndex < BuyIndex)
     {
       DisableSell = true;
       DisableSellPipsator = true;
     }
   return (0);
  }
  
//+-------------------------------------------------------------------------------+
//| We catch market GEP - it is included directly before the output of the news   |
//+-------------------------------------------------------------------------------+

int MoneyTrain()
  {
   if(FoundOpenedOrder == False)
     {
       // We count the dispersion
       Disperce = (iHigh ( Symbol(), 0, 0) - iLow ( Symbol(), 0, 0));
       if(Decision == DECISION_SELL)
         {
           // We jump into the locomotive in the direction of the motion of chaos of the market
           if((iClose( Symbol(), 0, 0) - iClose( Symbol(), 0, ValuePeriod)) / 
               MoneyTrainLevel >= SellSucPossibilityMid && SellSucPossibilityMid != 0 && EnableMoneyTrain == true)
             {
               ModeSpread = ModeSpread + 1;
               // Calculation of the stoploss
               if((Bid - SellSucPossibilityMid*StopLossIndex- ModeSpread * Point) > 
                  (Bid - ModeStopLevel* ModePoint- ModeSpread * Point))
                 {
                   StopLoss = Bid - ModeStopLevel* ModePoint- ModeSpread * Point - Disperce;
                 }
               else
                 {
                   if(SellSucPossibilityMid != 0)
                       StopLoss = Bid - SellSucPossibilityMid*StopLossIndex - ModeSpread * Point - Disperce;
                   else
                       StopLoss = Bid - ModeStopLevel* ModePoint- ModeSpread * Point - Disperce;
                 }

               if(BlockBuy == true)
                 {
                   return(0);
                 }
               StopLevel = StopLoss;
               Print ("StopLevel:", StopLevel);
               // Blocking stoploss
               if(BlockStopLoss == true)
                   StopLoss = 0;                                                                            
               ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, SlipPage, StopLoss, TakeProfit, "NeuroCluster-testing-AI-HB1", MagicNumber, 0, Blue);
               if(ticket > 0)
                 {
                   if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                   {
                       Print("Long order is opened: ",OrderOpenPrice());
                       PrevBuyStop = OrderStopLoss();
                   }
                 }
               else
                 {
                   Print("Error on the Long Entry: ",GetLastError());
                   PrintErrorValues();
                 }
               return (0);
             }
         }              
       if(Decision == DECISION_BUY)
         {
           // We jump into the locomotive in the direction of the motion of chaos of the market
           if((iClose( Symbol(), 0, ValuePeriod) - iClose( Symbol(), 0, 0)) / 
               MoneyTrainLevel >= BuySucPossibilityMid && BuySucPossibilityMid != 0 && EnableMoneyTrain == true)
             {
               ModeSpread = ModeSpread + 1;
               // Calculation of the stoploss
               if((Ask + BuySucPossibilityMid*StopLossIndex+ ModeSpread* Point) < (Ask + ModeStopLevel* ModePoint+ ModeSpread * Point))
                 {
                   StopLoss = Ask + ModeStopLevel* ModePoint+ ModeSpread * Point+ Disperce;
                 }
               else
                 {
               if(BuySucPossibilityMid != 0)
                   StopLoss = Ask + BuySucPossibilityMid*StopLossIndex+ ModeSpread*Point + 
                              Disperce;
               else
                   StopLoss = Ask + ModeStopLevel* ModePoint+ ModeSpread * Point+ Disperce;
                 }
               // If the manual blocking of sales is included
               if(BlockSell == true)
                 {
                   return(0);
                 }
               StopLevel = StopLoss;
               Print ("StopLevel:", StopLevel);
               // Blocking stoploss
               if(BlockStopLoss == true)
                   StopLoss = 0;                                                                      
               ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, SlipPage, StopLoss, TakeProfit, "NeuroCluster-testing-AI-HS1", MagicNumber, 0, Green);
               if(ticket > 0)
                 {
                   if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) 
                   {
                       Print("Short order is opened: ", OrderOpenPrice());
                       PrevSellStop = OrderStopLoss();
                   }
                 }
               else
                 {
                   Print("Error on the Short Entry: ",GetLastError());
                   PrintErrorValues();
                 }
               return (0);
             }   
         }            
     }
   return (0);
  }
  
//+------------------------------------------------------------------+
//| Entrance into the market                                         |
//+------------------------------------------------------------------+

int EnterMarket()
  {
// If there are no lots, we leave
   if(Lots == 0)
     {
       return (0);
     }
// We enter into market if there is no command of exit from the market
   if(ExitMarket == False)
     {
       // If there are no open orders - we enter into the market
       if(FoundOpenedOrder == False)
         {
           // We count the dispersion 
           Disperce = (iHigh(Symbol(), 0, 0) - iLow(Symbol(), 0, 0));
           if(Decision == DECISION_SELL)
             {
               // If the price of purchase is more than the average value of purchase in the interval being simulated
               if(SellPossibility >= SellSucPossibilityMid)
                 {
                   // Calculation of the stoploss
                   if((Ask + BuySucPossibilityMid*StopLossIndex + ModeSpread * Point) < 
                      (Ask + ModeStopLevel* ModePoint+ ModeSpread * Point))
                     {
                       StopLoss = Ask + ModeStopLevel* ModePoint+ ModeSpread * Point + Disperce;
                     }
                   else
                     {
                       if(BuySucPossibilityMid != 0)
                           StopLoss = Ask + BuySucPossibilityMid*StopLossIndex + 
                                      ModeSpread * Point+ Disperce;
                       else
                           StopLoss = Ask + ModeStopLevel* ModePoint+ ModeSpread * Point + 
                                      Disperce;
                     }
                   // If the manual blocking of sales is chosen
                   if(DisableSell == true)
                     {
                       return(0);
                     }
                   if(BlockSell == true)
                     {
                       return(0);
                     }
                   if ( StaticStopLoss != 0 )
                     {
                     StopLoss = Ask + StaticStopLoss * Point;
                     }
                   StopLevel = StopLoss;
                   Print ("StopLevel:", StopLevel);
                   // Blocking stoploss
                   if(BlockStopLoss == true)
                       StopLoss = 0;                                                                      
                   ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, SlipPage, StopLoss, TakeProfit, "NeuroCluster-testing-AI-LS1", MagicNumber, 0, Green);
                   if(ticket > 0)
                     {
                       if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) 
                       {
                           Print("Short order is opened: ",OrderOpenPrice());
                           PrevSellStop = OrderStopLoss();
                       }
                     }
                   else
                     {
                       Print("Error on the Short Entry: ",GetLastError());
                       PrintErrorValues();
                     }
                   // We preserve the previous value of the period
                   return (0);
                 }
             }
           if(Decision == DECISION_BUY)
             {
               // If the price of purchase is more than the average value of purchase in the interval being simulated
               if(BuyPossibility >= BuySucPossibilityMid)
                 {
                   // Calculation of the stoploss
                   if((Bid - SellSucPossibilityMid*StopLossIndex- ModeSpread* Point) > 
                      (Bid - ModeStopLevel* ModePoint- ModeSpread* Point))
                     {
                       StopLoss = Bid - ModeStopLevel* ModePoint- ModeSpread* Point - Disperce;
                     }
                   else
                     {
                       if(SellSucPossibilityMid != 0)
                           StopLoss = Bid - SellSucPossibilityMid*StopLossIndex- 
                                      ModeSpread* Point- Disperce;
                       else
                           StopLoss = Bid - ModeStopLevel* ModePoint- ModeSpread* Point- 
                                      Disperce;
                     }
                   // If the manual blocking of the purchases is chosen
                   if(DisableBuy == true)
                     {
                       return(0);
                     }
                   if(BlockBuy == true)
                     {
                       return(0);
                     }
                   if ( StaticStopLoss != 0 )
                     {
                     StopLoss = Bid - StaticStopLoss * Point;
                     }
                   StopLevel = StopLoss;
                   Print("StopLevel:", StopLevel);
                   // Blocking stoploss
                   if(BlockStopLoss == true)
                       StopLoss = 0;                                                                      
                   ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, SlipPage, StopLoss, TakeProfit, "NeuroCluster-testing-AI-LB1", MagicNumber, 0, Blue);
                   if(ticket > 0)
                     {
                      if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) 
                      {
                          Print("Long order is opened: ",OrderOpenPrice());
                          PrevBuyStop = OrderStopLoss();
                       }
                     }
                   else
                     {
                       Print("Error on the Long Entry: ",GetLastError());
                       PrintErrorValues();
                     }
                   return (0);
                 }
             }
         }
// ---------------- End of the entrance into the market ----------------------        
     }     
   return (0);
  }   
  
//+------------------------------------------------------------------+
//| Search for the open orders                                       |
//+------------------------------------------------------------------+

int FindSymbolOrder()
  {
   FoundOpenedOrder = false;
   total = OrdersTotal();
   for(cnt = 0; cnt < total; cnt++)
     {
       OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      // We search for order on our currency
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
           FoundOpenedOrder = True;
           break;
         }
       else
         {
           StopLevel = 0;
           StopLoss = 0;
         }
     }
   return (0);
  }
  
//+------------------------------------------------------------------+
//| Pipsator in the minute intervals                                 |
//+------------------------------------------------------------------+

int RunPipsator()
  {
   int i = 0;
   FindSymbolOrder();
   // We enter into market if there is no command of output from the market
   // We count the dispersion
   if(Lots == 0)
       return (0);
   Disperce = 0;
   if(ExitMarket == False)
     {
       // ---------- If there are no open orders - we enter into the market ----------
       if(FoundOpenedOrder == False)
         {
           Disperce = 0;
           DisperceMax = 0;
           // We count the maximum dispersion
           for(i = 0 ; i < ValuePeriod ; i ++)
             {
               Disperce = (iHigh( Symbol(), 0, i + 1) - 
                           iLow( Symbol(), 0, i + 1));                                
               if(Disperce > DisperceMax)
                   DisperceMax = Disperce;                             
             }
           Disperce = DisperceMax  * StopLossIndex;
           if( Disperce == 0 )
             {
               Disperce = ModeStopLevel * Point;
             }
           for(i = 0 ; i < ValuePeriod ; i ++)
             {
               // Pipsator of minute interval on sale
               if((Bid - iClose( Symbol(), 0, i + 1)) > 
                  SellSucPossibilityMid * (i + 1) && 
                  SellSucPossibilityMid != 0 && DisablePipsator == false && 
                  DisableSellPipsator == false)
                 {
                   // Pipsator of minute interval stoploss
                   if((Ask + ModeSpread * Point + Disperce) < 
                      (Ask + ModeStopLevel* ModePoint + ModeSpread * Point))
                     {
                       StopLoss = Ask + ModeStopLevel* ModePoint+ ModeSpread * Point + Point;
                     }
                   else
                     {
                       if(BuySucPossibilityMid != 0)
                           StopLoss = Ask + ModeSpread * Point+ Disperce + Point;
                       else
                         StopLoss = Ask + ModeStopLevel* ModePoint+ ModeSpread * Point + Point;
                     }
                   // If the manual blocking of sales is chosen
                   if(BlockSell == true)
                     {
                       return(0);
                     }
                   // If the manual blocking of sales is chosen
                   if(DisableSell == true)
                     {
                       return(0);
                     }
                     
                   if ( StaticStopLoss != 0 )
                     {
                     StopLoss = Ask + StaticStopLoss * Point;
                     }

                   StopLevel = StopLoss;
                   Print("StopLevel:", StopLevel);
                   // Blocking Stoploss
                   if(BlockStopLoss == true)
                       StopLoss = 0;
                   ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, SlipPage, StopLoss, TakeProfit, "NeuroCluster-testing-AI-PS1", MagicNumber, 0, Green);
                   if(ticket > 0)
                     {
                       if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) 
                       {
                           Print("Short order is opened: ",OrderOpenPrice());
                           PrevSellStop = OrderStopLoss();
                       }
                     }
                   else
                     {
                       Print("Error on the Short Entry: ",GetLastError());
                       PrintErrorValues();
                     }
                   return (0);
                 }
               // Pipsator of minute interval on the purchase
               if((iClose(Symbol(), 0, i + 1) - Bid) > BuySucPossibilityMid *(i + 1) && 
                   BuySucPossibilityMid != 0 && DisablePipsator == False && 
                   DisableBuyPipsator == false)
                 {
                   // Calculation of the stoploss
                   if((Bid -  ModeSpread * Point - Disperce) > 
                      (Bid - ModeStopLevel* ModePoint- ModeSpread * Point))
                     {
                       StopLoss = Bid - ModeStopLevel* ModePoint- ModeSpread * Point - Point;
                     }
                   else
                     {
                       if(SellSucPossibilityMid != 0)
                           StopLoss = Bid - ModeSpread * Point- Disperce- Point;
                       else
                           StopLoss = Bid - ModeStopLevel* ModePoint- ModeSpread * Point - Point;
                     }
                   // If the manual blocking is chosen 
                   if(DisableBuy == true)
                     {
                       return(0);
                     }
                   if(BlockBuy == true)
                     {
                       return(0);
                     }
                   if ( StaticStopLoss != 0 )
                     {
                     StopLoss = Bid - StaticStopLoss * Point;
                     }
                   StopLevel = StopLoss;
                   Print("StopLevel:", StopLevel);
                   // Blocking Stoploss
                   if(BlockStopLoss == true)
                       StopLoss = 0;                                                                            
                   ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, SlipPage, StopLoss, TakeProfit, "NeuroCluster-testing-AI-PB1", MagicNumber, 0, Blue);
                   if(ticket > 0)
                     {
                       if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) 
                       {
                           Print("Long order is opened: ",OrderOpenPrice());
                           PrevBuyStop = OrderStopLoss();
                       }
                     }
                   else
                     {
                       Print("Error on the Long Entry: ",GetLastError());
                       PrintErrorValues();
                     }
                   return (0);
                 }   
             }   // End of the pipsator cycle           
         }
     }
   return (0);
  }

//+------------------------------------------------------------------+
//| Dynamic Trailing Stop                                            |
//+------------------------------------------------------------------+

int DynamicTrailStop()
{
// Check to see if "EnableTrailingStop" is enabled..if not no need to execute
// Only Modify the "StopLevel" here, since the exits are executed on the next function ExitMarket()
// please make sure that the distance is >= 5 pips from the market, otherwise the stop order modification will be rejected.
// Thank you!

double TrailingStop = TrailingStopFactor * iATR(Symbol(), 0 , 14 , 1);

   for(int cnt = 0; cnt < OrdersTotal(); cnt++)
   {
      OrderSelect(cnt, SELECT_BY_POS);
      if(OrderMagicNumber() == MagicNumber && TrailingStop > 0)
      {
         if(OrderType() == OP_BUY)
         {
            BuyStop = Bid - TrailingStop;
            if(BuyStop < PrevBuyStop) BuyStop = PrevBuyStop;
            if(BuyStop > 0 && (Bid - BuyStop) >= 5 * Point && BuyStop > OrderStopLoss())
               OrderModify(OrderTicket(), OrderOpenPrice(), BuyStop, OrderTakeProfit(), 0);
         }
         else if(OrderType() == OP_SELL)
         {
            SellStop = Ask + TrailingStop;
            if(SellStop > PrevSellStop) SellStop = PrevSellStop;
            if(SellStop > 0 && (SellStop - Ask) >= 5 * Point && SellStop < OrderStopLoss())
               OrderModify(OrderTicket(), OrderOpenPrice(), SellStop, OrderTakeProfit(), 0);
         }
      }
   }
   PrevBuyStop = BuyStop;
   PrevSellStop = SellStop;
}

  
//+------------------------------------------------------------------+
//| Exit from the market                                             |
//+------------------------------------------------------------------+

int ExitMarket()
  {
   //FindSymbolOrder();
   // -------------------- Working the open orders -------------------
   
   if(FoundOpenedOrder == True)              // If there is the open order on this currency
     {
      if(EnableTrailingStop==true)
         DynamicTrailStop();                 // Calculate and modify the Dynamic Trailing Stop 
   
       if(OrderType()==OP_BUY)               // If the obtained order to the acquisition of the currency
         {

           // Closing order, if it reached the level of the stoploss
           if(Bid <= StopLevel && DisableShadowStopLoss == false && StopLevel != 0)
             {
               OrderClose(OrderTicket(),OrderLots(),Bid ,SlipPage,Violet); // We close the order
               return(0);
             }
             
           //long ts
           if(EnableTrailingStop==true)
              {
                   DynamicTrailStop();
                   if(BuyStop>0)
                       if((Bid-BuyStop)>=5*Point)
                           if(BuyStop>OrderStopLoss())
                              {
                                  OrderModify(OrderTicket(),OrderOpenPrice(),BuyStop,OrderTakeProfit(),0);
                              }
              }
              

           if(DisableExitBuy == true)
               return (0);

           // We do not leave from the market, if we have chaos, which works on the profit
           if((iClose( Symbol(), 0, 0) - iClose( Symbol(), 0, 1)) >= 
               SellSucPossibilityMid * 4 && SellSucPossibilityMid > 0)
               return(0);

           // Closing order on exceeding of the probability of successful sale
           if((OrderOpenPrice() < Bid) && (Bid - OrderOpenPrice() >= SellSucPossibilityMid) && (SellSucPossibilityMid > 0) )
             {
               OrderClose(OrderTicket(), OrderLots(), Bid , SlipPage, Violet); // Close the order
               return(0);
             }

           // Closing order on exceeding of the probability of the successful purchase
           if((OrderOpenPrice() < Bid) && (Bid - OrderOpenPrice() >= BuySucPossibilityMid) && (BuySucPossibilityMid > 0) )
             {
               OrderClose(OrderTicket(), OrderLots(), Bid , SlipPage, Violet); // Close the order
               return(0);
             }

           // Closing pipsator
           if((OrderOpenPrice() < Bid) &&  BuySucPossibilityMid == 0 && SellSucPossibilityMid == 0)
             {
               OrderClose(OrderTicket(), OrderLots(), Bid , SlipPage, Violet); // Close the order
               return(0);
             }


         }
       if(OrderType() == OP_SELL) // If the obtained order to the selling of the currency
         {


           // Closing order, if it reached the level of the stoploss
           if(Ask >= StopLevel && DisableShadowStopLoss == false && StopLevel != 0)
             {
               OrderClose(OrderTicket(), OrderLots(), Ask , SlipPage, Violet); // Close the order
               return(0);
             }

           if(DisableExitSell == true)
               return (0);

           // We do not leave from the market, if we have chaos, which works on the profit
           if((iClose( Symbol(), 0, 1) - iClose( Symbol(), 0, 0)) >= BuySucPossibilityMid * 4 && BuySucPossibilityMid > 0)
            return (0);

           // Closing order on the fact of the probability of the successful purchase
           if((OrderOpenPrice() > Ask) && (OrderOpenPrice() - Ask) >= BuySucPossibilityMid && BuySucPossibilityMid > 0)
             {
               OrderClose(OrderTicket(), OrderLots(), Ask, SlipPage, Violet); // Close the order 
               return(0);
             }

           // Closing order on the fact of the probability of successful sale
           if((OrderOpenPrice() > Ask) && (OrderOpenPrice() - Ask) >= SellSucPossibilityMid && SellSucPossibilityMid > 0)
             {
               OrderClose(OrderTicket(), OrderLots(), Ask, SlipPage, Violet); // Close the order 
               return(0);
             }


           // Closing pipsator
           if((OrderOpenPrice() > Ask) &&  BuySucPossibilityMid == 0 && SellSucPossibilityMid == 0)
             {
               OrderClose(OrderTicket(), OrderLots(), Ask, SlipPage, Violet); // Закрываем ордер
               return(0);
             }

         }
     }
 // --------------------- End of working the open orders ---------------------
 //  ValuePeriodPrev = ValuePeriod;
   return (0);
  }   
     
//+------------------------------------------------------------------------------------+
//| We preserve the values of rates and period of simulation for following statistics  |
//+------------------------------------------------------------------------------------+

int SaveStat()
  {
   BidPrev = Bid;
   AskPrev = Ask;
   ValuePeriodPrev = ValuePeriod;
   return (0);
  }
  
//+------------------------------------------------------------------+
//| Trading Logic                                                    |
//+------------------------------------------------------------------+

int Trade ()
  {
   // We begin to deal
   // We search for the open orders
   FindSymbolOrder();
   CalculateDirection();
   AutoStopLossIndex();
   
//---- If there are no open orders is possible the entrance into the market
//---- Attention - is important precisely this order of the examination of the technologies of the entrance into the market (MoneyTrain, LogicTrading, Pipsator)

   if(FoundOpenedOrder == false)
     {
       if(EnableMoneyTrain == true)
           MoneyTrain();
       if(EnableLogicTrading == true)
           EnterMarket();
       if(DisablePipsator == false && BlockPipsator == false)
           RunPipsator();           
     }
   else
     {
       ExitMarket();
     }
//---- End of working orders logic from the market
   return(0);
  }
  
//+------------------------------------------------------------------+
//| To derive the status of the account                              |
//+------------------------------------------------------------------+

int AccountStatus()
  {
   if(ShowAccountStatus == True )
     {
       Print ("AccountBalance:", AccountBalance());
       Print ("AccountCompany:", AccountCompany());
       Print ("AccountCredit:", AccountCredit());
       Print ("AccountCurrency:", AccountCurrency());
       Print ("AccountEquity:", AccountEquity());
       Print ("AccountFreeMargin:", AccountFreeMargin());
       Print ("AccountLeverage:", AccountLeverage());
       Print ("AccountMargin:", AccountMargin());
       Print ("AccountName:", AccountName());
       Print ("AccountNumber:", AccountNumber());
       Print ("AccountProfit:", AccountProfit());
     }    
   return ( 0 );
  }
  
//+-----------------------------------------------------------------------+
//| Most important function - selection of the period of the simulation   |
//+-----------------------------------------------------------------------+

int FindSuitablePeriod()
  {
   double SuitablePeriodQuality = -1 *ValuesPeriodCountMax*ValuesPeriodCountMax;
   double SuitablePeriod = 0;
   int i; // Variable for the analysis of the periods
   
	 // Quantity of analyzed periods. i - size of the period
   for(i = 0 ; i < ValuesPeriodCountMax ; i ++ )
     {
       ValuePeriod = i + 1;
      // Value selected experimentally and however strangely it coincided with the number in Elliott's theory
       ValuesPeriodCount = ValuePeriod * 5; 
       init();           
       CalculatePossibilityStat ();
       if(PossibilitySucQuality > SuitablePeriodQuality)
         {
           SuitablePeriodQuality = PossibilitySucQuality;
           //Print ("PossibilitySucQuality:", PossibilitySucQuality:);
           SuitablePeriod = i + 1;
         }
     }
   ValuePeriod = SuitablePeriod;
   init();
   
   // To derive the period of the simulation
   if(ShowSuitablePeriod == True)
     {
       Print("Period of the simulation:", SuitablePeriod, " minutes with the probability:", 
       SuitablePeriodQuality );
     }
   return(SuitablePeriod);
  }
  
//+------------------------------------------------------------------+
//| Automatic installation of the level of the stoploss              |
//+------------------------------------------------------------------+

int AutoStopLossIndex()
  {
   if(AutoStopLossIndex == true)
     {
       StopLossIndex = ModeSpread;
     }
   return(0);
  }
  
//+------------------------------------------------------------------+
//| Conclusion of errors with the entrance into the market           |
//+------------------------------------------------------------------+

int PrintErrorValues()
  {
   Print("ErrorValues:Symbol=", Symbol(),",Lots=",Lots, ",Bid=", Bid, ",Ask=", Ask,
         ",SlipPage=", SlipPage, "StopLoss=",StopLoss,",TakeProfit=", TakeProfit);
   return (0);
  }   
//+------------------------------------------------------------------+
//| expert start function (trading)                                  |
//+------------------------------------------------------------------+

int start()
  {
  
   GetMarketInfo();
   CyberiaLots();
   CalculateSpread();
   FindSuitablePeriod();
   CyberiaDecision();
   VerbiageAndTimeCheck();
   Trade();
   SaveStat();
 
   return(0);
  }

int VerbiageAndTimeCheck() {

   string comment_line="", comment_time="", comment_ver="";
   string sp         = "------------------------------\n";
   comment_ver=StringConcatenate(SystemName," v. ",version,"\n");
    

    if (StringLen(TimeTradeHoursDisabled) > 1) {
      NoTradeHours1 = StrToInteger(StringSubstr(TimeTradeHoursDisabled,0,2));
    }
    if (StringLen(TimeTradeHoursDisabled) > 4) {
      NoTradeHours2 = StrToInteger(StringSubstr(TimeTradeHoursDisabled,3,2));
    }
    if (StringLen(TimeTradeHoursDisabled) > 7) {
      NoTradeHours3 = StrToInteger(StringSubstr(TimeTradeHoursDisabled,6,2));
    }
    if (StringLen(TimeTradeHoursDisabled) > 10) {
      NoTradeHours4 = StrToInteger(StringSubstr(TimeTradeHoursDisabled,9,2));
    }
    if (StringLen(TimeTradeHoursDisabled) > 13) {
      NoTradeHours5 = StrToInteger(StringSubstr(TimeTradeHoursDisabled,12,2));
    }
    if (StringLen(TimeTradeHoursDisabled) > 16) {
      NoTradeHours6 = StrToInteger(StringSubstr(TimeTradeHoursDisabled,15,2));
    }

    int h=TimeHour(CurTime());
    int hadj=TimeHour(CurTime())-GMT;
    
    if (((hadj) == NoTradeHours1) || ((hadj) == NoTradeHours2) || ((hadj) == NoTradeHours3) || ((hadj) == NoTradeHours4) ||
      ((hadj) == NoTradeHours5) || ((hadj) == NoTradeHours6)) {
      
    BlockSell = true;
    BlockBuy  = true;
    
    comment_time=StringConcatenate("Bad Trading Hour: ", hadj, " GMT");  
  } else {
  
    BlockSell = false;
    BlockBuy  = false;
    comment_time=StringConcatenate("Good Trading Hour: ", hadj, " GMT");  

    }
  
  comment_line = comment_ver + sp + comment_time;
   
   if (IsTesting()==false)
      Comment(comment_line); 
  
}
  

