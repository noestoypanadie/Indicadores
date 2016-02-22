//+------------------------------------------------------------------+
//|                              Your_Choice_Hourly_Breakout_v4f.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright " Copyright © 2006 , David W Honeywell"
#include <stdlib.mqh>

//+------------------------------------------------------------------+
//| Common External variables                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| External variables                                               |
//+------------------------------------------------------------------+
extern double IAcceptTerms = 1;
extern double ShowComments = 0;
extern double Lots = 0.1;

//+------------------------------------------------------------------+
//| Special Convertion Functions                                     |
//+------------------------------------------------------------------+

int LastTradeTime;

bool MOrderDelete( int ticket )
{
LastTradeTime = CurTime();
return ( OrderDelete( ticket ) );
}

bool MOrderModify( int ticket, double price, double stoploss, double takeprofit, datetime expiration, color arrow_color=CLR_NONE)
{
LastTradeTime = CurTime();
price = MathRound(price*10000)/10000;
stoploss = MathRound(stoploss*10000)/10000;
takeprofit = MathRound(takeprofit*10000)/10000;
return ( OrderModify( ticket, price, stoploss, takeprofit, expiration, arrow_color) );
}

int MOrderSend( string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment="", int magic=0, datetime expiration=0, color arrow_color=CLR_NONE)
{
LastTradeTime = CurTime();
price = MathRound(price*10000)/10000;
stoploss = MathRound(stoploss*10000)/10000;
takeprofit = MathRound(takeprofit*10000)/10000;
return ( OrderSend( symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color ) );
}

int OrderValueTicket(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderTicket());
}	

int OrderValueType(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderType());
}

double OrderValueLots(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderLots());
}

double OrderValueOpenPrice(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderOpenPrice());
}

double OrderValueStopLoss(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderStopLoss());
}

double OrderValueTakeProfit(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderTakeProfit());
}

double OrderValueClosePrice(int index)
	{
	OrderSelect(index, SELECT_BY_POS);
	return(OrderClosePrice());
}

string OrderValueSymbol(int index)
	{
	OrderSelect(index, SELECT_BY_POS);
	return(OrderSymbol());
}

datetime OrderValueOpenTime(int index)
	{
	OrderSelect(index, SELECT_BY_POS);
	return(OrderOpenTime());
}

bool IsIndirect(string symbol)
	{
	return(False);
}

//+------------------------------------------------------------------+
//| End                                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+

int init()
	{
	return(0);
}
int start()
	{
	//+------------------------------------------------------------------+
	//| Local variables                                                  |
	//+------------------------------------------------------------------+
	
	double CheckComments = 0;
	bool first = true;
	double FrstSessHour = 0;
	double SecondSessHour = 0;
	double MaxProfit = 0;
	double MaxLoss = 0;
	double PeriodsLookback = 0;
	double CnclPndngIfActvTrd = 0;
	double DeleteOrderAfterMnts = 0;
	double DltAftr_Mnts = 0;
	double AdjustToBreakeven = 0;
	double Adj2B.E.Aftr_Pips = 0;
	double DynamicProfit = 0;
	double ProfitAtrPrds = 0;
	double FactorProf = 0;
	double AtrTrailing = 0;
	double AtrPeriods = 0;
	double TrailAt_TimesATR = 0;
	double StandardTrailAmt = 0;
	int cnt = 0;
	double opentrades = 0;
	double bought = 0;
	double sold = 0;
	double buyorder = 0;
	double sellorder = 0;
	double spread = 0;
	double rds = 0;
	double buyStop = 0;
	double sellStop = 0;
	double pips = 0;
	double stops = 0;
	double closebuyorder = 0;
	double closesellorder = 0;
	double allow = 0;
	double byok = 0;
	double slok = 0;
	double psld = 0;
	double pbht = 0;
	double deleteall = 0;
	double aa = 0;
	double ab = 0;
	double ac = 0;
	double ad = 0;
	double ae = 0;
	double af = 0;
	double ag = 0;
	double ah = 0;
	double ai = 0;
	double aj = 0;
	double ak = 0;
	double al = 0;
	double am = 0;
	double ao = 0;
	double ap = 0;
	double aq = 0;
	double ar = 0;
	double as = 0;
	double au = 0;
	double av = 0;
	double ba = 0;
	double bb = 0;
	double bc = 0;
	double bd = 0;
	double be = 0;
	double bf = 0;
	double bg = 0;
	double bh = 0;
	double bi = 0;
	double bj = 0;
	double bk = 0;
	double bl = 0;
	double bm = 0;
	double bo = 0;
	double bp = 0;
	double bq = 0;
	double br = 0;
	double bs = 0;
	double bu = 0;
	double bv = 0;
	double ca = 0;
	double cb = 0;
	double cc = 0;
	double cd = 0;
	double ce = 0;
	double cf = 0;
	double cg = 0;
	double ch = 0;
	double ci = 0;
	double cj = 0;
	double ck = 0;
	double cl = 0;
	double cm = 0;
	double co = 0;
	double cp = 0;
	double cq = 0;
	double cr = 0;
	double cs = 0;
	double cu = 0;
	double cv = 0;
	double da = 0;
	double db = 0;
	double dc = 0;
	double dd = 0;
	double de = 0;
	double df = 0;
	double dg = 0;
	double dh = 0;
	double di = 0;
	double dj = 0;
	double dk = 0;
	double dl = 0;
	double dm = 0;
	double do = 0;
	double dp = 0;
	double dq = 0;
	double dr = 0;
	double ds = 0;
	double du = 0;
	double dv = 0;
	double ea = 0;
	double eb = 0;
	double ec = 0;
	double ed = 0;
	double ee = 0;
	double ef = 0;
	double eg = 0;
	double eh = 0;
	double ei = 0;
	double ej = 0;
	double ek = 0;
	double el = 0;
	double em = 0;
	double eo = 0;
	double ep = 0;
	double eq = 0;
	double er = 0;
	double es = 0;
	double eu = 0;
	double ev = 0;
	double fa = 0;
	double fb = 0;
	double fc = 0;
	double fd = 0;
	double fe = 0;
	double ff = 0;
	double fg = 0;
	double fh = 0;
	double fi = 0;
	double fj = 0;
	double fk = 0;
	double fl = 0;
	double fm = 0;
	double fo = 0;
	double fp = 0;
	double fq = 0;
	double fr = 0;
	double fs = 0;
	double fu = 0;
	double fv = 0;
	double ga = 0;
	double gb = 0;
	double gc = 0;
	double gd = 0;
	double ge = 0;
	double gf = 0;
	double gg = 0;
	double gh = 0;
	double gi = 0;
	double gj = 0;
	double gk = 0;
	double gl = 0;
	double gm = 0;
	double go = 0;
	double gp = 0;
	double gq = 0;
	double gr = 0;
	double gs = 0;
	double gu = 0;
	double gv = 0;
	double ha = 0;
	double hb = 0;
	double hc = 0;
	double hd = 0;
	double he = 0;
	double hf = 0;
	double hg = 0;
	double hh = 0;
	double hi = 0;
	double hj = 0;
	double hk = 0;
	double hl = 0;
	double hm = 0;
	double ho = 0;
	double hp = 0;
	double hq = 0;
	double hr = 0;
	double hs = 0;
	double hu = 0;
	double hv = 0;
	double ja = 0;
	double jb = 0;
	double jc = 0;
	double jd = 0;
	double je = 0;
	double jf = 0;
	double jg = 0;
	double jh = 0;
	double ji = 0;
	double jj = 0;
	double jk = 0;
	double jl = 0;
	double jm = 0;
	double jo = 0;
	double jp = 0;
	double jq = 0;
	double jr = 0;
	double js = 0;
	double ju = 0;
	double jv = 0;
	double ka = 0;
	double kb = 0;
	double kc = 0;
	double kd = 0;
	double ke = 0;
	double kf = 0;
	double kg = 0;
	double kh = 0;
	double ki = 0;
	double kj = 0;
	double kk = 0;
	double kl = 0;
	double km = 0;
	double ko = 0;
	double kp = 0;
	double kq = 0;
	double kr = 0;
	double ks = 0;
	double ku = 0;
	double kv = 0;
	double hidiff = 0;
	double lowdiff = 0;
	double rdhidiff = 0;
	double rdlwdiff = 0;
	
	
	/*- Terms Of Use = If Any Value Other Than 0 (zero) is in the "IAcceptTerms" defined value ,
	"You" ( the user ) , "Accept Full Unlimited Responsibility Of The Operation And Results
	Obtained From The Use Of This Expert Advisor" , "Use At Your Own Risk" .
	*/
	
	//- This version will operate on multiple currency pairs
	
	if( TimeYear(Time) < 2030 ) return(0);
	
	// Default=0
	
	if( (IAcceptTerms == 0) ) return(0);
	if( (IAcceptTerms != 0) )
		{
		
		//- Comment Check and prevent this expert from removing comments applied by other experts or indicators ------------------
		
		// 1 = Yes  ,  0 = No .
		
		
		
		if( (CheckComments != (Time[0] + ShowComments)) ) { first = true; CheckComments = (Time[0] + ShowComments); }
		if( (first && ShowComments ==  0) ) { Comment(""); CheckComments = (Time[0] + ShowComments); first = false; }
		if( (first && ShowComments ==  1) ) { CheckComments = (Time[0] + ShowComments); first = false; }
		
		//------------------------------------------------------------------------------------------------------------------------
		
		//   Do Not Change The Settings Here , Read The Code Below .
		
		//- Set Defined Values ---------------------------------------------------------------------------------------------------
		
		/* Adjust These Values To Your Liking Below These Explainations .
		--------------------------------------------------------------------------------------------------------------------------
		FrstSessHour          The Chart Hour You Want The Orders To Be Set And/Or Modified
		SecondSessHour        The Chart Hour You Want The Orders To Be Set And/Or Modified
		--------------------------------------------------------------------------------------------------------------------------
		MaxProfit             TakeProfit Amount (pips)
		MaxLoss               StopLoss Amount (pips)
		--------------------------------------------------------------------------------------------------------------------------
		PeriodsLookback       Chart Periods back to monitor HH/LL
		--------------------------------------------------------------------------------------------------------------------------
		CnclPndngIfActvTrd    Set this to 1 if you want pending order cancelled after 1 pending becomes active
		--------------------------------------------------------------------------------------------------------------------------
		DeleteOrderAfterMnts  Set this to 1 if you want the orders deleted using DltAftr_Mnts
		Set to 0 if you do Not want to delete orders after (n) minutes (DltAftr_Mnts)
		DltAftr_Mnts          Delete Pending Orders After This Many Minutes
		--------------------------------------------------------------------------------------------------------------------------
		AdjustToBreakeven     Set this to 1 if you want to adjust stop to breakeven after (n) pips profit
		Set to 0 if you do Not want to adjust stop to breakeven after (n) pips profit
		Adj2B.E.Aftr_Pips     Adjust StopLoss to breakeven after this many pips profit
		--------------------------------------------------------------------------------------------------------------------------
		DynamicProfit         Set this to 1 if you want to use the ATR as a TakeProfit
		ProfitAtrPrds         ATR Periods to use for the Atr TakeProfit (DynamicProfit)
		FactorProf            Multiple of the ATR reading to calculate the final TakeProfit (DynamicProfit) amount
		--------------------------------------------------------------------------------------------------------------------------
		AtrTrailing           Set this to 1 if you want to use the ATR TrailingStop
		Set to 0 if you do not want to use the ATR TrailingStop
		When Set to 0 , the TrailingStop will Default to a standard TrailingStop
		AtrPeriods            Atr Periods to calculate the ATR TrailingStop
		TrailAt_TimesATR      Multiple of the ATR reading to calculate the final TrailingStop amount
		--------------------------------------------------------------------------------------------------------------------------
		If AtrTrailing is 0 , this TrailingStop amount Will Be Used
		StandardTrailAmt      Set this as you would for a standard TrailingStop
		--------------------------------------------------------------------------------------------------------------------------
		*/
		
		//  Here Is Where You Set Your Settings .
		

			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "USDCHF"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "GBPUSD"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "USDJPY"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "EURUSD"){ 
			FrstSessHour         =    8;
			SecondSessHour       =    12;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   13;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   37;
			DynamicProfit        =    1;
			ProfitAtrPrds        =    2;
			FactorProf           = 2.25;
			AtrTrailing          =    1;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  2.25;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "AUDUSD"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "USDCAD"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "EURGBP"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "EURCHF"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "EURJPY"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "GBPJPY"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "NZDUSD"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "GBPCHF"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "CHFJPY"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "AUDJPY"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "EURCAD"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "EURAUD"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "AUDCAD"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "AUDNZD"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			//------------------------------------------------------------------------------------------------------------------------
			if (Symbol() == "NZDJPY"){ 
			FrstSessHour         =    0;
			SecondSessHour       =    0;
			MaxProfit            =  125;
			MaxLoss              =  125;
			PeriodsLookback      =   24;
			CnclPndngIfActvTrd   =    0;
			DeleteOrderAfterMnts =    0;
			DltAftr_Mnts         =   60;
			AdjustToBreakeven    =    0;
			Adj2B.E.Aftr_Pips    =   27;
			DynamicProfit        =    0;
			ProfitAtrPrds        =    2;
			FactorProf           = 1.75;
			AtrTrailing          =    0;
			AtrPeriods           =    2;
			TrailAt_TimesATR     =  1.5;
			StandardTrailAmt     =   50;
			}
			
		
		//------------------------------------------------------------------------------------------------------------------------
		
		if( TimeYear(Time)<2005 ) return(0);
		if( IsIndirect(Symbol()) ) return(0);
		
		//- Check for open trades and pending orders per symbol ------------------------------------------------------------------
		
		opentrades=0;
		bought=0;
		sold=0;
		buyorder=0;
		sellorder=0;
		closebuyorder=0;
		closesellorder=0;
		
			for(cnt=1;cnt<=OrdersTotal();cnt++){
			if( (OrderValueSymbol(cnt) == Symbol()) )
				{ opentrades++;
				}
			if( ((OrderValueSymbol(cnt) == Symbol()) && (OrderValueType(cnt) == OP_BUY)) )
				{ bought++;
				}
			if( ((OrderValueSymbol(cnt) == Symbol()) && (OrderValueType(cnt) == OP_SELL)) )
				{ sold++;
				}
			if( ((OrderValueSymbol(cnt) == Symbol()) && (OrderValueType(cnt) == OP_BUYSTOP)) )
				{ buyorder++;
				}
			if( ((OrderValueSymbol(cnt) == Symbol()) && (OrderValueType(cnt) == OP_SELLSTOP)) )
				{ sellorder++;
				}
			}
		
		//- Reset allow , deleteall ----------------------------------------------------------------------------------------------
		
		if( ((allow != Time[0]) && (Hour() == FrstSessHour || Hour() ==  SecondSessHour)) )
			{ deleteall = 10;
			byok = -10;
			slok = -10;
			allow = Time[0];
			}
		
		//- Reset deleteall , byok , slok ----------------------------------------------------------------------------------------
		
		if( ((buyorder ==  0) && (sellorder ==  0)) )
			{ deleteall = -10;
			}
		
		//- Reset byok -----------------------------------------------------------------------------------------------------------
		
			for(cnt=1;cnt<=OrdersTotal();cnt++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (OrderValueType(cnt) == OP_BUYSTOP)) )
				{ byok = 10;
				}
			}
		
		//- Reset slok -----------------------------------------------------------------------------------------------------------
		
			for(cnt=1;cnt<=OrdersTotal();cnt++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (OrderValueType(cnt) == OP_SELLSTOP)) )
				{ slok = 10;
				}
			}
		
		//- Set Variable Values --------------------------------------------------------------------------------------------------
		
		aa=MathAbs(High[101]-High[100]);ab=MathAbs(High[100]-High[99]);ac=MathAbs(High[99]-High[98]);ad=MathAbs(High[98]-High[97]);ae=MathAbs(High[97]-High[96]);
		af=MathAbs(High[96]-High[95]);ag=MathAbs(High[95]-High[94]);ah=MathAbs(High[94]-High[93]);ai=MathAbs(High[93]-High[92]);aj=MathAbs(High[92]-High[91]);
		ak=MathAbs(High[91]-High[90]);al=MathAbs(High[90]-High[89]);am=MathAbs(High[89]-High[88]);ao=MathAbs(High[88]-High[87]);ap=MathAbs(High[87]-High[86]);
		aq=MathAbs(High[86]-High[85]);ar=MathAbs(High[85]-High[84]);as=MathAbs(High[84]-High[83]);au=MathAbs(High[83]-High[82]);av=MathAbs(High[82]-High[81]);
		
		ba=MathAbs(High[81]-High[80]);bb=MathAbs(High[80]-High[79]);bc=MathAbs(High[79]-High[78]);bd=MathAbs(High[78]-High[77]);be=MathAbs(High[77]-High[76]);
		bf=MathAbs(High[76]-High[75]);bg=MathAbs(High[75]-High[74]);bh=MathAbs(High[74]-High[73]);bi=MathAbs(High[73]-High[72]);bj=MathAbs(High[72]-High[71]);
		bk=MathAbs(High[71]-High[70]);bl=MathAbs(High[70]-High[69]);bm=MathAbs(High[69]-High[68]);bo=MathAbs(High[68]-High[67]);bp=MathAbs(High[67]-High[66]);
		bq=MathAbs(High[66]-High[65]);br=MathAbs(High[65]-High[64]);bs=MathAbs(High[64]-High[63]);bu=MathAbs(High[63]-High[62]);bv=MathAbs(High[62]-High[61]);
		
		ca=MathAbs(High[61]-High[60]);cb=MathAbs(High[60]-High[59]);cc=MathAbs(High[59]-High[58]);cd=MathAbs(High[58]-High[57]);ce=MathAbs(High[57]-High[56]);
		cf=MathAbs(High[56]-High[55]);cg=MathAbs(High[55]-High[54]);ch=MathAbs(High[54]-High[53]);ci=MathAbs(High[53]-High[52]);cj=MathAbs(High[52]-High[51]);
		ck=MathAbs(High[51]-High[50]);cl=MathAbs(High[50]-High[49]);cm=MathAbs(High[49]-High[48]);co=MathAbs(High[48]-High[47]);cp=MathAbs(High[47]-High[46]);
		cq=MathAbs(High[46]-High[45]);cr=MathAbs(High[45]-High[44]);cs=MathAbs(High[44]-High[43]);cu=MathAbs(High[43]-High[42]);cv=MathAbs(High[42]-High[41]);
		
		da=MathAbs(High[41]-High[40]);db=MathAbs(High[40]-High[39]);dc=MathAbs(High[39]-High[38]);dd=MathAbs(High[38]-High[37]);de=MathAbs(High[37]-High[36]);
		df=MathAbs(High[36]-High[35]);dg=MathAbs(High[35]-High[34]);dh=MathAbs(High[34]-High[33]);di=MathAbs(High[33]-High[32]);dj=MathAbs(High[32]-High[31]);
		dk=MathAbs(High[31]-High[30]);dl=MathAbs(High[30]-High[29]);dm=MathAbs(High[29]-High[28]);do=MathAbs(High[28]-High[27]);dp=MathAbs(High[27]-High[26]);
		dq=MathAbs(High[26]-High[25]);dr=MathAbs(High[25]-High[24]);ds=MathAbs(High[24]-High[23]);du=MathAbs(High[23]-High[22]);dv=MathAbs(High[22]-High[21]);
		
		ea=MathAbs(High[21]-High[20]);eb=MathAbs(High[20]-High[19]);ec=MathAbs(High[19]-High[18]);ed=MathAbs(High[18]-High[17]);ee=MathAbs(High[17]-High[16]);
		ef=MathAbs(High[16]-High[15]);eg=MathAbs(High[15]-High[14]);eh=MathAbs(High[14]-High[13]);ei=MathAbs(High[13]-High[12]);ej=MathAbs(High[12]-High[11]);
		ek=MathAbs(High[11]-High[10]);el=MathAbs(High[10]-High[9]);em=MathAbs(High[9]-High[8]);eo=MathAbs(High[8]-High[7]);ep=MathAbs(High[7]-High[6]);
		eq=MathAbs(High[66]-High[5]);er=MathAbs(High[5]-High[4]);es=MathAbs(High[4]-High[3]);eu=MathAbs(High[3]-High[2]);ev=MathAbs(High[2]-High[1]);
		
		fa=MathAbs(Low[101]-Low[100]);fb=MathAbs(Low[100]-Low[99]);fc=MathAbs(Low[99]-Low[98]);fd=MathAbs(Low[98]-Low[97]);fe=MathAbs(Low[97]-Low[96]);
		ff=MathAbs(Low[96]-Low[95]);fg=MathAbs(Low[95]-Low[94]);fh=MathAbs(Low[94]-Low[93]);fi=MathAbs(Low[93]-Low[92]);fj=MathAbs(Low[92]-Low[91]);
		fk=MathAbs(Low[91]-Low[90]);fl=MathAbs(Low[90]-Low[89]);fm=MathAbs(Low[89]-Low[88]);fo=MathAbs(Low[88]-Low[87]);fp=MathAbs(Low[87]-Low[86]);
		fq=MathAbs(Low[86]-Low[85]);fr=MathAbs(Low[85]-Low[84]);fs=MathAbs(Low[84]-Low[83]);fu=MathAbs(Low[83]-Low[82]);fv=MathAbs(Low[82]-Low[81]);
		
		ga=MathAbs(Low[81]-Low[80]);gb=MathAbs(Low[80]-Low[79]);gc=MathAbs(Low[79]-Low[78]);gd=MathAbs(Low[78]-Low[77]);ge=MathAbs(Low[77]-Low[76]);
		gf=MathAbs(Low[76]-Low[75]);gg=MathAbs(Low[75]-Low[74]);gh=MathAbs(Low[74]-Low[73]);gi=MathAbs(Low[73]-Low[72]);gj=MathAbs(Low[72]-Low[71]);
		gk=MathAbs(Low[71]-Low[70]);gl=MathAbs(Low[70]-Low[69]);gm=MathAbs(Low[69]-Low[68]);go=MathAbs(Low[68]-Low[67]);gp=MathAbs(Low[67]-Low[66]);
		gq=MathAbs(Low[66]-Low[65]);gr=MathAbs(Low[65]-Low[64]);gs=MathAbs(Low[64]-Low[63]);gu=MathAbs(Low[63]-Low[62]);gv=MathAbs(Low[62]-Low[61]);
		
		ha=MathAbs(Low[61]-Low[60]);hb=MathAbs(Low[60]-Low[59]);hc=MathAbs(Low[59]-Low[58]);hd=MathAbs(Low[58]-Low[57]);he=MathAbs(Low[57]-Low[56]);
		hf=MathAbs(Low[56]-Low[55]);hg=MathAbs(Low[55]-Low[54]);hh=MathAbs(Low[54]-Low[53]);hi=MathAbs(Low[53]-Low[52]);hj=MathAbs(Low[52]-Low[51]);
		hk=MathAbs(Low[51]-Low[50]);hl=MathAbs(Low[50]-Low[49]);hm=MathAbs(Low[49]-Low[48]);ho=MathAbs(Low[48]-Low[47]);hp=MathAbs(Low[47]-Low[46]);
		hq=MathAbs(Low[46]-Low[45]);hr=MathAbs(Low[45]-Low[44]);hs=MathAbs(Low[44]-Low[43]);hu=MathAbs(Low[43]-Low[42]);hv=MathAbs(Low[42]-Low[41]);
		
		ja=MathAbs(Low[41]-Low[40]);jb=MathAbs(Low[40]-Low[39]);jc=MathAbs(Low[39]-Low[38]);jd=MathAbs(Low[38]-Low[37]);je=MathAbs(Low[37]-Low[36]);
		jf=MathAbs(Low[36]-Low[35]);jg=MathAbs(Low[35]-Low[34]);jh=MathAbs(Low[34]-Low[33]);ji=MathAbs(Low[33]-Low[32]);jj=MathAbs(Low[32]-Low[31]);
		jk=MathAbs(Low[31]-Low[30]);jl=MathAbs(Low[30]-Low[29]);jm=MathAbs(Low[29]-Low[28]);jo=MathAbs(Low[28]-Low[27]);jp=MathAbs(Low[27]-Low[26]);
		jq=MathAbs(Low[26]-Low[25]);jr=MathAbs(Low[25]-Low[24]);js=MathAbs(Low[24]-Low[23]);ju=MathAbs(Low[23]-Low[22]);jv=MathAbs(Low[22]-Low[21]);
		
		ka=MathAbs(Low[21]-Low[20]);kb=MathAbs(Low[20]-Low[19]);kc=MathAbs(Low[19]-Low[18]);kd=MathAbs(Low[18]-Low[17]);ke=MathAbs(Low[17]-Low[16]);
		kf=MathAbs(Low[16]-Low[15]);kg=MathAbs(Low[15]-Low[14]);kh=MathAbs(Low[14]-Low[13]);ki=MathAbs(Low[13]-Low[12]);kj=MathAbs(Low[12]-Low[11]);
		kk=MathAbs(Low[11]-Low[10]);kl=MathAbs(Low[10]-Low[9]);km=MathAbs(Low[9]-Low[8]);ko=MathAbs(Low[8]-Low[7]);kp=MathAbs(Low[7]-Low[6]);
		kq=MathAbs(Low[66]-Low[5]);kr=MathAbs(Low[5]-Low[4]);ks=MathAbs(Low[4]-Low[3]);ku=MathAbs(Low[3]-Low[2]);kv=MathAbs(Low[2]-Low[1]);
		
		//----------------------------------
		
		hidiff=(aa+ab+ac+ad+ae+af+ag+ah+ai+aj+ak+al+am+ao+ap+aq+ar+as+au+av+
		ba+bb+bc+bd+be+bf+bg+bh+bi+bj+bk+bl+bm+bo+bp+bq+br+bs+bu+bv+
		ca+cb+cc+cd+ce+cf+cg+ch+ci+cj+ck+cl+cm+co+cp+cq+cr+cs+cu+cv+
		da+db+dc+dd+de+df+dg+dh+di+dj+dk+dl+dm+do+dp+dq+dr+ds+du+dv+
		ea+eb+ec+ed+ee+ef+eg+eh+ei+ej+ek+el+em+eo+ep+eq+er+es+eu+ev)/100;
		
		rdhidiff=(MathRound(hidiff/Point))*Point;
		
		lowdiff=(fa+fb+fc+fd+fe+ff+fg+fh+fi+fj+fk+fl+fm+fo+fp+fq+fr+fs+fu+fv+
		ga+gb+gc+gd+ge+gf+gg+gh+gi+gj+gk+gl+gm+go+gp+gr+gs+gu+gv+
		ha+hb+hc+hd+he+hf+hg+hh+hi+hj+hk+hl+hm+ho+hp+hr+hs+hu+hv+
		ja+jb+jc+jd+je+jf+jg+jh+ji+jj+jk+jl+jm+jo+jp+jq+jr+js+ju+jv+
		ka+kb+kc+kd+ke+kf+kg+kh+ki+kj+kk+kl+km+ko+kp+kq+kr+ks+ku+kv)/100;
		
		rdlwdiff=(MathRound(lowdiff/Point))*Point;
		
		spread = (MathRound((Ask-Bid)/Point))*Point;
		
		buyStop  = (((MathRound((High[Highest(MODE_HIGH,PeriodsLookback,PeriodsLookback)])/Point))*Point)+(rdhidiff))+spread;
		sellStop = (((MathRound((Low[Lowest(NULL, 0, MODE_LOW,PeriodsLookback,PeriodsLookback)])/Point))*Point)-(rdlwdiff))-spread;
		
		pips = ((MathRound((iATR(NULL, 0, ProfitAtrPrds,0)*FactorProf)/Point))*Point);
		stops = ((MathRound((iATR(NULL, 0, AtrPeriods,0)*TrailAt_TimesATR)/Point))*Point);
		
		//- Place Comments on Chart Window ---------------------------------------------------------------------------------------
		
      if( (ShowComments != 0) )
			{ Comment("'#10'","  Chart Hour:  =  ",Hour()," ,  FrstSessHour:  =  ",FrstSessHour,
			" ,  SecondSessHour:  =  ",SecondSessHour,
			"'#10'",
		"'#10'","  pbht:  =  ",pbht," ,  psld:  =  ",psld," ,  deleteall:  =  ",deleteall,
			" ,  byok:  =  ",byok," ,  slok:  =  ",slok,
			"'#10'","  Symbol:  =  ",Symbol()," ,  MaxProfit:  =  ",MaxProfit," ,  MaxLoss:  =  ",MaxLoss,
			"'#10'","  Open Buys:  =  ",bought," ,  Open Sells:  =  ",sold,
			"'#10'","  Buy Stops:  =  ",buyorder," ,  Sell Stops:  =  ",sellorder,
			"'#10'","  All Positions:  =  ",opentrades,
			"'#10'",
			"'#10'","  PeriodsLookback:  =  ",PeriodsLookback,
			"'#10'","  Spread:  =  ",spread,
			"'#10'","  rdhidiff:  =  ",rdhidiff," ,  rdlwdiff:  =  ",rdlwdiff,
			"'#10'","  BuyStop ( Highest High of PeriodsLookback + Spread + rdhidiff ) :  =  ",buyStop,
			"'#10'","  SellStop  ( Lowest Low  of PeriodsLookback  - Spread  - rdlwdiff ) :  =  ",sellStop,
			"'#10'",
			"'#10'","  CnclPndngIfActvTrd:  =  ",CnclPndngIfActvTrd);
		Comment(
			"'#10'","  DeleteOrderAfterMnts:  =  ",DeleteOrderAfterMnts,"  DltAftr_Mnts:  =  ",DltAftr_Mnts,
			"'#10'",
			"'#10'","  AdjustToBreakeven:  =  ",AdjustToBreakeven," ,  Adj2B.E.Aftr_Pips:  =  ",Adj2B.E.Aftr_Pips,
			"'#10'",
			"'#10'","  DynamicProfit:  =  ",DynamicProfit,
			"'#10'","  ProfitAtrPrds:  =  ",ProfitAtrPrds," ,  FactorProf:  =  ",FactorProf,
			"'#10'","  ATR Profit Amount:  =  ",pips,
			"'#10'",
			"'#10'","  AtrTrailing:  =  ",AtrTrailing,
			"'#10'","  AtrPeriods:  =  ",AtrPeriods," ,  TrailAt_TimesATR:  =  ",TrailAt_TimesATR,
			"'#10'","  Atr TrailingStop Amount:  =  ",stops,
			"'#10'",
			"'#10'","  StandardTrailAmt:  =  ",StandardTrailAmt);
			}
		
		if( (CurTime()-LastTradeTime) < 10 ) return(0); 
		
		//- Delete Previous Pending Orders ---------------------------------------------------------------------------------------
		
		if( (deleteall > 0) )
			{
				for(cnt =1;cnt <=OrdersTotal();cnt ++){
				if( ((OrderValueSymbol(cnt) == Symbol()) && (Hour() == FrstSessHour || Hour() ==  SecondSessHour))
				&& ((OrderValueType(cnt) == OP_SELLSTOP)||(OrderValueType(cnt) == OP_BUYSTOP)) )
					{ byok = -10;
					slok = -10;
					pbht = bought;
					psld = sold;
					MOrderDelete(OrderValueTicket(cnt));
					Print("Deleted Order For New Session Trade  ",Symbol());return(0);
					}
				}
			}
		
		//- If a trade closes , reset pbht / psld --------------------------------------------------------------------------------
		
		if( (bought < pbht) ) { pbht = bought; }
		if( (sold < psld) ) { psld = sold; }
		
		//- If pending order becomes active Set Flag to delete opposing stop order -----------------------------------------------
		
			for(cnt=1;cnt<=OrdersTotal();cnt++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (CnclPndngIfActvTrd == 1)) )
				{
				if( ((buyorder ==  0) && (pbht != bought)) )
					{ closesellorder = 1;
					}
				}
			}
			for(cnt=1;cnt<=OrdersTotal();cnt++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (CnclPndngIfActvTrd == 1)) )
				{
				if( ((sellorder ==  0) && (psld != sold)) )
					{ closebuyorder = 1;
					}
				}
			}
		
		//- If active order flag , Delete Opposing Stop Order --------------------------------------------------------------------
		
			for(cnt=1;cnt<=OrdersTotal();cnt++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (closesellorder == 1) && (OrderValueType(cnt) == OP_SELLSTOP)) )
				{ MOrderDelete(OrderValueTicket(cnt));
				pbht = bought;
				Print("Deleted Due To Active Buy Order  ",Symbol());return(0);
				}
			}
			for(cnt=1;cnt<=OrdersTotal();cnt++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (closebuyorder == 1) && (OrderValueType(cnt) == OP_BUYSTOP)) )
				{ MOrderDelete(OrderValueTicket(cnt));
				psld = sold;
				Print("Deleted Due To Active Sell Order  ",Symbol());return(0);
				}
			}
		
		//- Delete Pending Orders when DltAftr_Mnts has elapsed ------------------------------------------------------------------
		
			for(cnt =1;cnt <=OrdersTotal();cnt ++){
			if( (((OrderValueType(cnt) == OP_BUYSTOP)||(OrderValueType(cnt) == OP_SELLSTOP))&&(DeleteOrderAfterMnts == 1)) )
				{
				if( (CurTime()-OrderValueOpenTime(cnt))>(DltAftr_Mnts*60) )
					{ MOrderDelete(OrderValueTicket(cnt));
					Print("Delete after minutes  ",Symbol());return(0);
					}
				}
			}
		
		//- Set BuyStop and SellStop ---------------------------------------------------------------------------------------------
		
		if( (Hour() == FrstSessHour) || (Hour() ==  SecondSessHour) )
			{
			if( ((buyorder ==  0) && (byok <= 0) && (deleteall < 0)) )
				{ MOrderSend(Symbol(),OP_BUYSTOP,Lots,buyStop,0,(buyStop)-MaxLoss*Point,(buyStop)+MaxProfit*Point,"",16384,0,Blue);
				Print("New Session BuyStop  ",Symbol());return(0);
				}
			}
		if( (Hour() ==  FrstSessHour) || (Hour() ==  SecondSessHour) )
			{
			if( ((sellorder ==  0) && (slok <= 0) && (deleteall < 0)) )
				{ MOrderSend(Symbol(),OP_SELLSTOP,Lots,sellStop,0,(sellStop)+MaxLoss*Point,(sellStop)-MaxProfit*Point,"",16384,0,Red);
				Print("New Session SellStop  ",Symbol());return(0);
				}
			}
		
		//- Adjust StopLoss to breakeven if in profit more than Adj2B.E.Aftr_Pips ------------------------------------------------
		
			for(cnt =1;cnt <=OrdersTotal();cnt ++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (AdjustToBreakeven == 1) && (OrderValueType(cnt) == OP_BUY)) )
				{
				if( (OrderValueStopLoss(cnt) == (OrderValueOpenPrice(cnt)-MaxLoss*Point))
				&&
				(OrderValueClosePrice(cnt)-(OrderValueOpenPrice(cnt))>Adj2B.E.Aftr_Pips*Point) )
					{ MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
					OrderValueClosePrice(cnt)-(Adj2B.E.Aftr_Pips*Point),OrderValueTakeProfit(cnt),0,Blue);
					Print("Adjusted To Breakeven  ",Symbol());return(0);
					}
				}
			}
			for(cnt =1;cnt <=OrdersTotal();cnt ++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (AdjustToBreakeven == 1) && (OrderValueType(cnt) == OP_SELL)) )
				{
				if( (OrderValueStopLoss(cnt) == (OrderValueOpenPrice(cnt)+MaxLoss*Point))
				&&
				(OrderValueOpenPrice(cnt)-OrderValueClosePrice(cnt)>Adj2B.E.Aftr_Pips*Point) )
					{ MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
					OrderValueClosePrice(cnt)+(Adj2B.E.Aftr_Pips*Point),OrderValueTakeProfit(cnt),0,Red);
					Print("Adjusted To Breakeven  ",Symbol());return(0);
					}
				}
			}
		
		//- ATR TP ---------------------------------------------------------------------------------------------------------------
		
			for(cnt=1;cnt<=OrdersTotal();cnt++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (DynamicProfit == 1) && (OrderValueType(cnt) == OP_SELL)) )
				{
				if( ((OrderValueOpenPrice(cnt)-OrderValueClosePrice(cnt)) > pips) )
					{ OrderClose(OrderValueTicket(cnt),OrderValueLots(cnt),
					OrderValueClosePrice(cnt),0,SandyBrown);
					Print("ATR TakeProfit  ",Symbol());return(0);
					}
				}
			}
			for(cnt =1;cnt <=OrdersTotal();cnt ++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (DynamicProfit == 1) && (OrderValueType(cnt) == OP_BUY)) )
				{
				if( ((OrderValueClosePrice(cnt)-OrderValueOpenPrice(cnt)) > pips) )
					{ OrderClose(OrderValueTicket(cnt),OrderValueLots(cnt),
					OrderValueClosePrice(cnt),0,SandyBrown);
					Print("ATR TakeProfit  ",Symbol());return(0);
					}
				}
			}
		
		//- ATR TrailingStop -----------------------------------------------------------------------------------------------------
		
			for(cnt =1;cnt <=OrdersTotal();cnt ++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (AtrTrailing == 1) && (OrderValueType(cnt) == OP_BUY)) )
				{
				if( ((OrderValueClosePrice(cnt)-OrderValueOpenPrice(cnt))>(stops)
				&&
				(OrderValueClosePrice(cnt)-stops)>OrderValueStopLoss(cnt))
				|| (OrderValueStopLoss(cnt) == 0) )
					{ MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
					(OrderValueClosePrice(cnt)-stops),OrderValueTakeProfit(cnt),0,White);
					Print("ATR TrailingStop  ",Symbol());return(0);
					}
				}
			}
			for(cnt =1;cnt <=OrdersTotal();cnt ++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (AtrTrailing == 1) && (OrderValueType(cnt) == OP_SELL)) )
				{
				if( ((OrderValueOpenPrice(cnt)-OrderValueClosePrice(cnt))>(stops)
				&&
				(OrderValueClosePrice(cnt)+stops)<OrderValueStopLoss(cnt))
				|| (OrderValueStopLoss(cnt) == 0) )
					{ MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
					(OrderValueClosePrice(cnt)+stops),OrderValueTakeProfit(cnt),0,DodgerBlue);
					Print("ATR TrailingStop  ",Symbol());return(0);
					}
				}
			}
		
		//- Standard TrailingStop ------------------------------------------------------------------------------------------------
		
			for(cnt =1;cnt <=OrdersTotal();cnt ++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (AtrTrailing == 0) && (OrderValueType(cnt) == OP_BUY)) )
				{
				if( ((OrderValueClosePrice(cnt)-OrderValueOpenPrice(cnt))>(StandardTrailAmt*Point)
				&&
				(OrderValueClosePrice(cnt)-(StandardTrailAmt*Point))>OrderValueStopLoss(cnt))
				|| (OrderValueStopLoss(cnt) == 0) )
					{ MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
					(OrderValueClosePrice(cnt)-(StandardTrailAmt*Point)),OrderValueTakeProfit(cnt),0,White);
					Print("Standard TrailingStop  ",Symbol());return(0);
					}
				}
			}
			for(cnt =1;cnt <=OrdersTotal();cnt ++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (AtrTrailing == 0) && (OrderValueType(cnt) == OP_SELL)) )
				{
				if( ((OrderValueOpenPrice(cnt)-OrderValueClosePrice(cnt))>(StandardTrailAmt*Point)
				&&
				(OrderValueClosePrice(cnt)+(StandardTrailAmt*Point))<OrderValueStopLoss(cnt))
				|| (OrderValueStopLoss(cnt) == 0) )
					{ MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
					(OrderValueClosePrice(cnt)+(StandardTrailAmt*Point)),OrderValueTakeProfit(cnt),0,DodgerBlue);
					Print("Standard TrailingStop  ",Symbol());return(0);
					}
				}
			}
		
		//- Set StopLoss If You Have Manually Placed A BuyStop Or SellStop @ The Experts BuyStop/SellStop Level ------------------
		
			for(cnt =1;cnt <=OrdersTotal();cnt ++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (OrderValueType(cnt) == OP_BUYSTOP)) )
				{
				if( (((OrderValueStopLoss(cnt) == 0) || (OrderValueTakeProfit(cnt) == 0)) && (OrderValueOpenPrice(cnt) == buyStop)) )
					{ MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
					((buyStop)-MaxLoss*Point),((buyStop)+MaxProfit*Point),0,White);
					Print("Manual BuyStop TakeProfit and StopLoss has been set  ",Symbol());return(0);
					}
				}
			}
			for(cnt =1;cnt <=OrdersTotal();cnt ++){
			if( ((OrderValueSymbol(cnt) == Symbol()) && (OrderValueType(cnt) == OP_SELLSTOP)) )
				{
				if( (((OrderValueStopLoss(cnt) == 0) || (OrderValueTakeProfit(cnt) == 0)) && (OrderValueOpenPrice(cnt) == sellStop)) )
					{ MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
					((sellStop)+MaxLoss*Point),((sellStop)-MaxProfit*Point),0,DodgerBlue);
					Print("Manual SellStop TakeProfit and StopLoss has been set  ",Symbol());return(0);
					}
}
}

}}
		//- End ------------------------------------------------------------------------------------------------------------------