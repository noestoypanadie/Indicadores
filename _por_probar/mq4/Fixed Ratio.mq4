//+------------------------------------------------------------------+
//|                                                  Fixed Ratio.mq4 |
//|                           Copyright © 2006, Renato P. dos Santos |
//|                            http://www.reniza.com/forex/sureshot/ |
//| based on Ryan Jones' Fixed Ratio MM                              | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Renato P. dos Santos"
#property link      "http://www.reniza.com/forex/sureshot/"

//---- Name for DataWindow label
string short_name="yourexpertname";

//---- Input parameters
extern int StopLoss=50; 
extern int TakeProfit=100;
extern double RiskLevel=0.03;
extern double InitialBalance=0.0;
extern bool UseSound=False;
extern bool WriteLog=True;

//---- Internal variables
color clOpenBuy=DodgerBlue;
color clModiBuy=Cyan;
color clCloseBuy=Cyan;
color clOpenSell=Red;
color clModiSell=Yellow;
color clCloseSell=Yellow;
color clDelete=White;
string NameFileSound="expert.wav";
double LotPrecision;

//---- Static variables
static int MagicNumber;
static int handle;
static double LastLot;
static double LastBalance;
static int Delta; 
static double MyMinLot;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----

   MagicNumber=MagicfromSymbol(); 
   
   if ( WriteLog ) handle=FileOpen(LogFileName(),FILE_CSV|FILE_WRITE);   

   InitializeLot();

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
   if ( WriteLog ) FileClose(handle);

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----

   OpenBuy(Ask);

   OpenSell(Bid);
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
// Auxiliary functions go here
//+------------------------------------------------------------------+

int MagicfromSymbol() {  
   int MagicNumber=0;  
   for (int i=0; i<5; i++) {  
      MagicNumber=MagicNumber*3+StringGetChar(Symbol(),i);  
   }  
   MagicNumber=MagicNumber*3+Period();  
   return(MagicNumber);  
}  

void InitializeLot() {
// based on Ryan Jones' Fixed Ratio MM
// to be called once on init() section
   if ( InitialBalance==0 ) {
      int dathandle=FileOpen(DatFileName(),FILE_CSV|FILE_READ,";"); 
      if (dathandle>0) {
         InitialBalance=FileReadNumber(dathandle);
         if ( WriteLog ) WritetoLog("InitialBalance(stored)=$"+DoubleToStr(InitialBalance,2));
         FileClose(dathandle);
      }
      else {
         InitialBalance=AccountFreeMargin();
         if ( WriteLog ) WritetoLog("InitialBalance=$"+DoubleToStr(InitialBalance,2));
         dathandle=FileOpen(DatFileName(),FILE_CSV|FILE_WRITE,";"); 
         FileWrite(dathandle,InitialBalance); 
         FileClose(dathandle);
      }
   }
   else {
      if ( WriteLog ) WritetoLog("InitialBalance(configured)=$"+DoubleToStr(InitialBalance,2));
      dathandle=FileOpen(DatFileName(),FILE_CSV|FILE_WRITE,";"); 
      FileWrite(dathandle,InitialBalance); 
      FileClose(dathandle);
   }
   LastBalance=InitialBalance;
   Delta=MathRound(InitialBalance*RiskLevel);
   if ( WriteLog ) WritetoLog("Delta=$"+DoubleToStr(Delta,0));
   double DeltaPrecision=MathRound(MathLog(Delta)/MathLog(10));
   if ( WriteLog ) WritetoLog("DeltaPrecision="+DoubleToStr(DeltaPrecision,0));
   double DeltaPower=MathPow(10,DeltaPrecision-1);
   if ( WriteLog ) WritetoLog("DeltaPower="+DoubleToStr(DeltaPower,0));
   Delta=MathRound(Delta/DeltaPower)*DeltaPower;
   if ( WriteLog ) WritetoLog("Delta(normalized)=$"+DoubleToStr(Delta,0));    
   double LotSize=MarketInfo(Symbol(),MODE_LOTSIZE)/100;
   if ( WriteLog ) WritetoLog("LotSize=$"+DoubleToStr(LotSize,0));
   MyMinLot=Delta/LotSize;
   if ( WriteLog ) WritetoLog("MyMinLot="+DoubleToStr(MyMinLot,2));
   double LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);
   LotPrecision=MathRound(-MathLog(LotStep)/MathLog(10));
   if ( WriteLog ) WritetoLog("LotStep="+DoubleToStr(LotStep,LotPrecision));
   if ( WriteLog ) WritetoLog("Precision="+DoubleToStr(LotPrecision,0));
   MyMinLot=NormalizeDouble(MyMinLot,LotPrecision);
   if ( MyMinLot<MarketInfo(Symbol(),MODE_MINLOT) ) MyMinLot=MarketInfo(Symbol(),MODE_MINLOT);
   if ( WriteLog ) WritetoLog("MyMinLot(normalized)="+DoubleToStr(MyMinLot,LotPrecision));
   LastLot=MyMinLot;
}

double GetSizeLot() { 
// based on Ryan Jones' Fixed Ratio MM
// to be called each time an order is to be sent
   double OptLots=LastLot;
   if ( WriteLog ) WritetoLog("Balance=$"+DoubleToStr(AccountBalance(),0));
   if ( WriteLog ) WritetoLog("OptLots(initial)="+DoubleToStr(OptLots,LotPrecision));
   for ( OptLots=OptLots; AccountFreeMargin()>=InitialBalance+(OptLots/MyMinLot)*(OptLots/MyMinLot+1)/2*MyMinLot*Delta; OptLots=OptLots+MyMinLot ) {}
   if ( WriteLog ) WritetoLog("OptLots(increased)="+DoubleToStr(OptLots,LotPrecision));
   for ( OptLots=OptLots; AccountFreeMargin()<InitialBalance+(OptLots/MyMinLot)*(OptLots/MyMinLot-1)/2*MyMinLot*Delta && OptLots>MyMinLot; OptLots=OptLots-MyMinLot ) {}
   if ( WriteLog ) WritetoLog("OptLots(decreased)="+DoubleToStr(OptLots,LotPrecision));
   if ( OptLots<MyMinLot ) OptLots=MyMinLot; 
   if ( OptLots<MarketInfo(Symbol(),MODE_MINLOT) ) OptLots=MarketInfo(Symbol(),MODE_MINLOT);
   if ( OptLots>100 ) OptLots=100;
   if ( WriteLog ) WritetoLog("OptLots(normalized)="+DoubleToStr(OptLots,LotPrecision));
   return(OptLots); 
} 

double GetSpread() { 
   return(MarketInfo(Symbol(),MODE_SPREAD)); 
}

double GetStopLossBuy(double BuyPrice) { 
   if (StopLoss==0) return(0); 
   else return(BuyPrice-StopLoss*Point); 
} 

double GetStopLossSell(double SellPrice) { 
   if (StopLoss==0) return(0); 
   else return(SellPrice+StopLoss*Point); 
} 

double GetTakeProfitBuy(double BuyPrice) { 
   if (TakeProfit==0) return(0); 
   else return(BuyPrice+TakeProfit*Point); 
} 

double GetTakeProfitSell(double SellPrice) { 
   if (TakeProfit==0) return(0); 
   else return(SellPrice-TakeProfit*Point); 
} 

string GetCommentForOrder() { 
   return(short_name); 
} 

bool WritetoLog(string text) {
   if ( handle>0 && WriteLog ) {
      FileWrite(handle,text+"\r"); 
      return(True);
   }
   else return(False); 
}

string LogFileName() {
    string stryear = DoubleToStr(Year(),0);
    stryear=StringSubstr(stryear,2,2);
    string strmonth = DoubleToStr(Month(),0);
    if (StringLen(strmonth)<2) strmonth = "0"+strmonth;
    string strday = DoubleToStr(Day(),0);
    if (StringLen(strday)<2) strday = "0"+strday;
    return(short_name+"-"+stryear+strmonth+strday+".log");
}

string DatFileName() {
    return(short_name+"-"+Symbol()+TimeFrame()+".dat");
}

string TimeFrame() {
   string TF;
   switch(Period()) {
      case 1: TF="M1"; break;
      case 5: TF="M5"; break;
      case 15: TF="M15"; break;
      case 30: TF="M30"; break;
      case 60: TF="H1"; break;
      case 240: TF="H4"; break;
      case 1440: TF="D1"; break;
      case 10080: TF="W1"; break;
      case 43200: TF="MN"; break;
   }
   return(TF);
}

void OpenBuy(double lPrice) { 
   double ldLot=GetSizeLot();
   double lSlip=GetSpread();
   double ldStop=GetStopLossBuy(lPrice); 
   double ldTake=GetTakeProfitBuy(lPrice); 
   string lsComm=GetCommentForOrder(); 
   int lMagic=MagicfromSymbol();
   LastBalance=AccountFreeMargin();
   LastLot=ldLot;
   OrderSend(Symbol(),OP_BUY,ldLot,lPrice,lSlip,ldStop,ldTake,lsComm,lMagic,0,clOpenBuy); 
   if ( UseSound ) PlaySound(NameFileSound);
} 

void OpenSell(double lPrice) { 
   double ldLot=GetSizeLot();
   double lSlip=GetSpread();
   double ldStop=GetStopLossSell(lPrice); 
   double ldTake=GetTakeProfitSell(lPrice); 
   string lsComm=GetCommentForOrder(); 
   int lMagic=MagicfromSymbol();
   LastBalance=AccountFreeMargin();
   LastLot=ldLot;
   OrderSend(Symbol(),OP_SELL,ldLot,lPrice,lSlip,ldStop,ldTake,lsComm,lMagic,0,clOpenSell); 
   if ( UseSound ) PlaySound(NameFileSound); 
} 




