//+------------------------------------------------------------------+
//|                                                        Utils.mqh |
//|                             Copyright © 2006, Paul Hampton-Smith |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Paul Hampton-Smith"
#property link      ""

// requires utils.ex4 in experts\libraries
// store this file in experts\include and do not compile
// Incorporate into EA's with command   #include <utls.mqh>

//+------------------------------------------------------------------+
//| EX4 imports                                                      |
//+------------------------------------------------------------------+
#import "Utils.ex4"
//+------------------------------------------------------------------+

bool NewBar();
int OpenOrders(int nSystemID = 0);
int OpenStopOrders(int nSystemID = 0);
void DeleteStopOrders(int nSystemID = 0);
int FindOrder(int nType, int nSystemID);
string DayOfWeekToString(int nDayOfWeek);
double ATRTrailingStop(int nOrderType, int nATRlen, double dblATRmult);
double MEMATrailingStop(int nOrderType, int nATRlen, double dblATRmult, double dblAccel);    
int CompletedOrdersSince(datetime dt, int nSystemID);
string TimeString(int hour, int minute);
double LastClosedOrderProfit(int nOrderType, int nSystemID);
double TruncatePrice(double dblPrice);
double HighLowTrailingStop(bool bLong, int nLookBack);
void CloseAllAtEndOfWeek(int nSystemID);
datetime WeeklyExpirationTime(int nExitDay, int nExitHour, int nExitMinute);
void AdjustTrailingStops(int nTrailingStop, int nSystemID = 0);
bool OrderOfTypeExists(int nOrderType, int nSystemID = 0);
datetime ServerTime(datetime UTC);
void CloseOrdersAfterDuration(int nSeconds, int nSystemID = 0);
void CloseOrdersAtTime(datetime dt, int nSystemID = 0);
void DeleteStopOrdersAtTime(datetime dt, int nSystemID = 0);
int SecureOrderSend( string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment, int magic=0, datetime expiration=0, color arrow_color=CLR_NONE);
double ClosestStopLoss(int cmd, double dblPrice);
double ClosestBuySellStopPrice(int cmd);
void CloseAfterPeak(int nTrailingStop, int nSlippage, int nSystemID = 0, datetime AfterTime = 0);


