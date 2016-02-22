/*+------------------------------------------------------------------+
 | FileName: i_Hull_MA.mq4
 | Description: This indicator calculates the Hull Moving Average
 |  
 | Original equation is:
 | ---------------------
 | waverage(2*waverage(close,period/2)-waverage(close,period), SquareRoot(Period)
	 Implementation below is more efficient with lengthy Weighted Moving Averages.
	 In addition, the length needs to be converted to an integer value after it is halved and
	 its square root is obtained in order for this to work with Weighted Moving Averaging

 | Version: 000 20050903 17:06 GMT
 +------------------------------------------------------------------------------------------+*/
#property link      "http://www.justdata.com.au/Journals/AlanHull/hull_ma.htm"

#property indicator_separate_window
#property indicator_buffers 1

#property indicator_color1 Silver

//---- External parameters
extern int _maPeriod=120;
extern int price = PRICE_OPEN;
/*
PRICE_CLOSE 0 Close price. 
PRICE_OPEN 1 Open price. 
PRICE_HIGH 2 High price. 
PRICE_LOW 3 Low price. 
PRICE_MEDIAN 4 Median price, (high+low)/2. 
PRICE_TYPICAL 5 Typical price, (high+low+close)/3. 
PRICE_WEIGHTED 6 Weighted close price, (high+low+close+close)/4. 
*/

//---- indicator buffers
double _hma[];
double _wma[];

//----
int ExtCountedBars=0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init() {
	int    draw_begin;
	string short_name;
	IndicatorBuffers(2);

	//---- indicator buffers mapping
	SetIndexBuffer(0, _hma);
	SetIndexEmptyValue(0, 0.0);
	SetIndexStyle(0, DRAW_LINE);
	
	SetIndexBuffer(1, _wma);
	SetIndexEmptyValue(1, 0.0);
	
	IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));

	//---- initialization done
	return(0);
}

int start() {
	int i, shift, countedBars=IndicatorCounted();
	int maxBars=_maPeriod*2;
	int period=_maPeriod;
	double sqrtPeriod = MathSqrt(period*1.00);
	int halfPeriod=period/2;

	if(Bars<_maPeriod) return(-1);
   if(countedBars == 0) countedBars = maxBars;
	int limit=Bars-countedBars+maxBars;
	//---- moving average
	double wma1;
	double wma2;
	for(i=limit; i>=0; i--) {
	  wma1 = iMA(Symbol(), 60, period, 0, MODE_LWMA, price, i);
	  wma2 = iMA(Symbol(), 60, halfPeriod, 0, MODE_LWMA, price, i);
	  _wma[i] = 2*wma2-wma1;
	} 
	
	for(i=limit; i>=0; i--) {
	  _hma[i]=iMAOnArray(_wma, 60, sqrtPeriod, 0, MODE_LWMA, i);
	} 

	return(0);
}


