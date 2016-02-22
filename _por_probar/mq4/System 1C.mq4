//+------------------------------------------------------------------+
//|                                                     System 1C.mq4 |
//|                               Copyright © 2005, ForexCharity.com |
//|                                          http://forexcharity.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, ForexCharity.com"
#property link      "http://forexcharity.com"
#include <stdlib.mqh>


//----- constants
extern int       intParamATR=24;
int       intTimeFrame=30;  //swieczki 30min
int       intProfitCheckFreq=1; // czas co ile jest sprawdzany profit

string    strCommentMarketBuy="System1C-market buy";
string    strCommentMarketSell="System1C-market sell";

//---- input parameters
extern double    dblLots=2;
extern double    dblWartoscLota=1000;
extern string    strGodzinaStartAnalyzer="12:30";
extern string    strGodzinaEndAnalyzerFinish="16:00";
extern string    strGodzinaCancel="23:31";

extern int       intDebugLevel=3;   // 0 - krytyczne   1 - wazne    2 - srednie  3 - nieistotne

double intPoints;
int    intLastProfitChecked = 0;


int intTicketOpened = 0; //= sprawdz wszystkie otwarte-jesli wsrod nich jest pozycja instrument=symbol() to TRUE wpp FALSE
datetime intGodzinaSprawdzenia;
datetime intGodzinaStartAnalyzer;
datetime intGodzinaEndAnalyzerFinish;
datetime intGodzinaCancel;
datetime intCzasKolejnegoSprawdzeniaSL;
datetime intDzienOstatniegoSprawdzenia;

double dblCena1430 = 0;
double dblCena1600 = 0;
string strSygnal  = "";
string strKolorSwieczki = "";
string strArrowName = "";

double ATR = 0;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- TODO: Add your code here.

//   inicjalizacja wartosci zmiennych
  InicjujGodziny();
  
intGodzinaStartAnalyzer = StrToTime(strGodzinaStartAnalyzer);
intGodzinaEndAnalyzerFinish = StrToTime(strGodzinaEndAnalyzerFinish);
intGodzinaCancel = StrToTime(strGodzinaCancel);



  if (intGodzinaCancel < CurTime())
  // uruchomienie po 19-tej -> przesuniecie dat na nastepny dzien
  {
     intGodzinaStartAnalyzer += 60*60*24;
     intGodzinaEndAnalyzerFinish += 60*60*24;
     intGodzinaCancel += 60*60*24;
     
  }
  intGodzinaSprawdzenia = intGodzinaEndAnalyzerFinish;
  intDzienOstatniegoSprawdzenia = -1;
  intPoints = MarketInfo (Symbol(), MODE_POINT);
  intTicketOpened = DajTicketZlecenia();
  if(intTicketOpened == 0)
     intTicketOpened = DajTicketZleceniaZamkniete();

  intCzasKolejnegoSprawdzeniaSL = CurTime();
  
  
  ErrorLog("Points:" + intPoints, 3);
  if(Period() != 30) 
  {
    ErrorLog("Niewlasciwy timeframe wykresu. Ustaw na 30 minut", 0);
    deinit();
  }
  strArrowName= Symbol() + CurTime();

// testy
   ErrorLog("Init: DajKolorSwieczki=" + DajKolorSwieczkiHeiken(1), 3 );   
   ErrorLog("Init: GodzinaStartAnalyzer= " + TimeToStr(intGodzinaStartAnalyzer), 3);   
   ErrorLog("Init: GodzinaEndAnalyzerFinish= " + TimeToStr(intGodzinaEndAnalyzerFinish), 3);
   ErrorLog("Init: GodzinaCancel= " + TimeToStr(intGodzinaCancel), 3);
// koniec testow 
  
//----
   return(0);
  }

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }


//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
  if(CurTime() > intGodzinaEndAnalyzerFinish-(15*60) && CurTime() < intGodzinaEndAnalyzerFinish) 
  {
  // przygotowanie pola 
     ErrorLog("start: przygotowanie pola", 3);
     dblCena1430 = 0;
     dblCena1600 = 0;
     strSygnal = "0";
     if (intTicketOpened > 0)
     {   
         ErrorLog("start: 15minutdo16 - zamykanie pozycji ....", 3);
         CloseMyPositions();
     }    
     intTicketOpened = 0;
     strKolorSwieczki = "0";
     strArrowName= Symbol() + CurTime();
     
  }
   if(CurTime() > intGodzinaSprawdzenia && intTicketOpened == 0)
   {
      ErrorLog("start:w warunku if CurTime() > intGodzinaSprawdzenia: " + CurTime() + " > " + TimeToStr( intGodzinaSprawdzenia ) , 3);
      if(dblCena1430 ==0)
      {
// zeby nie liczyc tego wielokrotnie ...         
         dblCena1430 = DajCeneOGodzinie(strGodzinaStartAnalyzer);
         dblCena1600 = DajCeneOGodzinie(strGodzinaEndAnalyzerFinish);
         strSygnal = DajSygnal();
         if(strSygnal == "S")
         {
          //   strSygnal = "S"; // sell
             ObjectCreate(strArrowName, OBJ_ARROW, 0, StrToTime(strGodzinaEndAnalyzerFinish), dblCena1600);
             ObjectSet(strArrowName, OBJPROP_ARROWCODE , SYMBOL_ARROWDOWN);
             ObjectSet(strArrowName, OBJPROP_COLOR, Red);
             ObjectSet(strArrowName, OBJPROP_WIDTH, 3);   
         }
         if(strSygnal == "B")
         {
          //   strSygnal = "B"; // buy
             ObjectCreate(strArrowName, OBJ_ARROW, 0, StrToTime(strGodzinaEndAnalyzerFinish), dblCena1600);
             ObjectSet(strArrowName, OBJPROP_ARROWCODE , SYMBOL_ARROWUP);
             ObjectSet(strArrowName, OBJPROP_COLOR, Green);
             ObjectSet(strArrowName, OBJPROP_WIDTH, 3);   
         }
         
      }
      //ErrorLog("Start: godzina 1430:" + dblCena1430 + " 16: " + dblCena1600, 3);
      ErrorLog("Start: strSygnal = " + strSygnal, 3);
      
      strKolorSwieczki = DajKolorSwieczkiHeiken(1);
      if (strSygnal == "S" && strKolorSwieczki == "C")
      {
          intTicketOpened = MyOpenMarket(OP_SELL);
          intCzasKolejnegoSprawdzeniaSL = CurTime() + 10*60;
      }
      if(strSygnal == "B" && strKolorSwieczki == "B")
      {
          intTicketOpened = MyOpenMarket(OP_BUY);
          intCzasKolejnegoSprawdzeniaSL = CurTime() + 10*60;
      }

      if(intTicketOpened == 0)
        intGodzinaSprawdzenia = intGodzinaSprawdzenia + 30*60;
      else if (intTicketOpened < 0)
      {
        ErrorLog("start: intTickedOpened < 0 - bede probowal zaraz jeszcze raz: intTicketOpened=" + intTicketOpened, 3);  
        intTicketOpened = 0;
      }  
   }
   if(CurTime() > intGodzinaCancel)
   {
      InicjujGodziny();
   } 
   if (CurTime() >= intCzasKolejnegoSprawdzeniaSL && intTicketOpened != 0 )
   {
      // sprawdza zysk i jesli jest powyzej + 30 to przestawia SL na +5, jesli powyzej +50 to sl na 20
      OrderSelect(intTicketOpened, SELECT_BY_TICKET, MODE_TRADES);
   
      int intZysk = 0;
      double dblNewSL = OrderStopLoss();   
     if(OrderType() == OP_BUY)
      {
         intZysk = DajPipsyBezWzgledne(Bid - OrderOpenPrice());
         ErrorLog("strt:wyliczeniezysku: intZysk= " + intZysk, 3);
         
         
         if (intZysk >= 60)
            dblNewSL = OrderOpenPrice() + DajPipsyWzgledne(40);
         else if (intZysk >= 45)
            dblNewSL = OrderOpenPrice() + DajPipsyWzgledne(25);
         else if (intZysk >= 35)
            dblNewSL = OrderOpenPrice() + DajPipsyWzgledne(10);
        else if (intZysk >= 25)
            dblNewSL = OrderOpenPrice() + DajPipsyWzgledne(5);
            
            
        if (dblNewSL > OrderStopLoss())
         OrderModify(OrderTicket(), OrderOpenPrice(), dblNewSL, OrderTakeProfit(), 0, CLR_NONE);
         
      }
      if(OrderType() == OP_SELL)
      {
         intZysk = DajPipsyBezWzgledne(OrderOpenPrice()-Ask);
         ErrorLog("strt:wyliczeniezysku: intZysk= " + intZysk, 3);
         
         if (intZysk >= 60)
            dblNewSL = OrderOpenPrice() - DajPipsyWzgledne(40);
         else if (intZysk >= 45)
            dblNewSL = OrderOpenPrice() - DajPipsyWzgledne(25);
         else if (intZysk >= 35)
            dblNewSL = OrderOpenPrice() - DajPipsyWzgledne(10);
        else if (intZysk >= 25)
            dblNewSL = OrderOpenPrice() - DajPipsyWzgledne(5);
            
        if (dblNewSL < OrderStopLoss())
         OrderModify(OrderTicket(), OrderOpenPrice(), dblNewSL, OrderTakeProfit(), 0, CLR_NONE);
         
      }

      if(intDzienOstatniegoSprawdzenia != TimeDayOfWeek(CurTime()-60*35) )
      {
      // aktualizacja poziomow TP po zmianie daty
         ErrorLog("start(): sprawdzenie nowego poziomu TP", 3);      
         double dblTPconst = 0;
         double dblTP = 0;         
         if(OrderType() == OP_BUY)
         {      
            dblTPconst = OrderOpenPrice() + DajPipsyWzgledne(25);
         
            dblTP = iCustom(Symbol(), Period(), "Pivot", 2, 1) - DajPipsyWzgledne(5);
            if (dblTPconst > dblTP)
               dblTP = dblTPconst;
         } 
         else if(OrderType() == OP_SELL)
         {
            dblTPconst = OrderOpenPrice() - DajPipsyWzgledne(25);
         
            dblTP = iCustom(Symbol(), Period(), "Pivot", 2, 1) + DajPipsyWzgledne(5);
            if (dblTPconst < dblTP)
               dblTP = dblTPconst;
         
         }
         
         OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), dblTP, 0, CLR_NONE);

         intDzienOstatniegoSprawdzenia = TimeDayOfWeek(CurTime()-60*35);

                    
      }      

      intCzasKolejnegoSprawdzeniaSL += 2 * 60;
   }
   return(0);
}
//+------------------------------------------------------------------+


double DajCeneOGodzinie(string strGodzina) 
{
   datetime intGodzina;
   double dblCena;
   intGodzina = StrToTime(strGodzina);
   int i = 0;
   
   while (dblCena == 0)
   {
      if (Time[i] == intGodzina)
      {
         dblCena = Open[i];
      } else
      i += 1;
      
   }
   ErrorLog("DajCeneOGodzinie: " + TimeToStr(intGodzina) + " Cena = " + dblCena, 3);
   return(dblCena);
}

string DajKolorSwieczkiHeiken(int intShift)
{
// zwraca kolor ostatniej zamknietej swieczki (shift = 1) tj. nie aktualna tylko ostatnia zamknieta
   string strKolor = "";
   double dblWskaznik4 =  iCustom(Symbol(), 30, "Heiken Ashi", 3, intShift);
   double dblWskaznik1 =  iCustom(Symbol(), 30, "Heiken Ashi", 0, intShift); 
   if( dblWskaznik4 < dblWskaznik1)
      strKolor = "C";
   else
      strKolor = "B";   
   ErrorLog("DajKolorSwieczki: #" + intShift + "   dblWskaznik4 = " + dblWskaznik4 + " dblWskaznik1= " + dblWskaznik1 + " Kolor swieczki= " + strKolor, 3);
   
   return(strKolor);
}

/* 

 

Jesli C(14.30) < C(16.00) to Sell

Jesli C(14.30) > C(16.00) to Buy

 

na wykresie masz swieczki - od 14.30 do 16 nic nie robisz , gotowy jestes tylko 
do ustalenia sygnalu , o 16 decydujesz K lub S i teraz jezeli jest S i swieczka o 16 
skonczyla sie tak ze jest czerwona to sprzedajesz , jezeli nie to czekasz az sie 
pojawi czerwona i dopiero wtedy sprzedajesz - z kupnem odwrotnie czekasz na biala , 
chyba ze ta skonczona o 16 jest biala wiec wtedy natychmiast kupujessz


 

Pytania: co sie dzieje jesli C(14.30)=C(16.00) ?

Czy sygnal S/K jest wyliczany co pol godziny? tj. Jesli o 16.00 mamy Sell a swieczki do 17 sa biale to 



*/


int MyOpenMarket(int Oper)
{
   ErrorLog("Wchodze do Open market ...", 3);
   if(intTicketOpened==0)
   {
      ErrorLog("Open market - w warunku if", 3);
      int intTicket = 0;
      double dblSL = 0;
      double dblTP = 0;
      double dblTPconst = 0;
      double dblSLconst = 0;
      double dblEkstremum = 0;
      int intSwieczkaTMP = 0;
      if(Oper==OP_BUY)  // jesli zlecenie market jest BUY
      {
         dblTPconst = Ask + DajPipsyWzgledne(25);
         
         dblTP = iCustom(Symbol(), Period(), "Pivot", 2, 1) - DajPipsyWzgledne(5);
         if (dblTPconst > dblTP)
            dblTP = dblTPconst;
         dblEkstremum = 999;
         while (iTime(Symbol(), Period(), intSwieczkaTMP) >= intGodzinaStartAnalyzer)
         {
             if(iLow(Symbol(), Period(), intSwieczkaTMP) < dblEkstremum)
               dblEkstremum = iLow(Symbol(), Period(), intSwieczkaTMP);
             intSwieczkaTMP += 1;  
         }
         dblSLconst = Ask - DajPipsyWzgledne(StaleStopy(Symbol()));

         dblSL = dblEkstremum - DajPipsyWzgledne(10);
         
         if (dblSL > dblSLconst)
            dblSL = dblSLconst;
         
         intTicket = MyOrderSend(OP_BUY,Ask,dblSL, dblTP, strCommentMarketBuy); 
      }
      if(Oper==OP_SELL)
      {  
         dblTPconst = Bid - DajPipsyWzgledne(25);
         
         dblTP = iCustom(Symbol(), Period(), "Pivot", 1, 1) + DajPipsyWzgledne(5);
         if (dblTPconst < dblTP)
            dblTP = dblTPconst;

         dblEkstremum = 0;
         while (iTime(Symbol(), Period(), intSwieczkaTMP) >= intGodzinaStartAnalyzer)
         {
             if(iHigh(Symbol(), Period(), intSwieczkaTMP) > dblEkstremum)
               dblEkstremum = iHigh(Symbol(), Period(), intSwieczkaTMP);
             intSwieczkaTMP += 1;  
         }


         dblSLconst = Bid + DajPipsyWzgledne(StaleStopy(Symbol()));
 
         dblSL = dblEkstremum + DajPipsyWzgledne(10);
         
         
         if (dblSL < dblSLconst )
            dblSL = dblSLconst;            
         
         intTicket = MyOrderSend(OP_SELL,Bid,dblSL, dblTP, strCommentMarketSell); 
      }
      return(intTicket);
      
         
   }

}


int MyOrderSend(int CMD, double OpenPrice, double SLPrice, double TPPrice, string Comments)
{
// otwiera zlecenie typu CMD
   ErrorLog("Wchodze do MyOrderSend: Operacja=" + CMD + "; OpenPrice=" + OpenPrice + "; SL=" + SLPrice + "; TP=" + TPPrice, 3);
   int intMiejscPoPrzecinku = 4;
   if (OpenPrice > 10)
   intMiejscPoPrzecinku = 2;
   int ticket;
   color  clr;
   if(CMD==OP_BUY) 
   clr = Green;
   else 
   clr = Red;
   ticket=OrderSend(Symbol(),CMD,dblLots,NormalizeDouble(OpenPrice, intMiejscPoPrzecinku),3,NormalizeDouble(SLPrice,intMiejscPoPrzecinku), NormalizeDouble(TPPrice,intMiejscPoPrzecinku),Comments,16384,0,clr); 
   
   if(ticket<0)
       {
          int err = GetLastError();
          
          ErrorLog("OrderSend failed with error #"+err + " : " + ErrorDescription(err) + " ticket=" + ticket, 0);
          return(ticket);
       }
   else
       return(ticket);    

   
}

double DajPipsyWzgledne(int intPips)
{
   int intMiejscPoPrzecinku = 4;
   if (Ask > 10)
      intMiejscPoPrzecinku = 2;
   ErrorLog("DajPipsyWzgledne: pips="+ intPips + "wzgledne=" + NormalizeDouble(intPips / MathPow(10, intMiejscPoPrzecinku), intMiejscPoPrzecinku),3);
   return(NormalizeDouble(intPips / MathPow(10, intMiejscPoPrzecinku), intMiejscPoPrzecinku));
   
}

double DajPipsyBezWzgledne(double dblPrice)
{
   int intMiejscPoPrzecinku = 4;
   if (Ask > 10)
      intMiejscPoPrzecinku = 2;
   ErrorLog("DajPipsyBeyWzgledne: Price="+ dblPrice + "bezwzgledne=" + NormalizeDouble(dblPrice * MathPow(10, intMiejscPoPrzecinku), intMiejscPoPrzecinku),3);
   return(NormalizeDouble(dblPrice * MathPow(10, intMiejscPoPrzecinku), intMiejscPoPrzecinku));
   
}


int DajTicketZleceniaZamkniete()
// sprawdza czy od godziny strGodzinaEndAnalyzerFinish do teraz zostaly zamkniete zlecenia, jesli tak, zwraca ich ticket
{
  int total; int cnt;
  int intTicket = 0;
  total=HistoryTotal();
  
  if(total > 0) 
     {
        for(cnt=0;cnt<total;cnt++)
        {
          OrderSelect(cnt, SELECT_BY_POS, MODE_HISTORY);
            if(OrderSymbol()==Symbol() && (OrderComment() == strCommentMarketBuy || OrderComment() == strCommentMarketSell))
            {
               intTicket = OrderTicket();
               ErrorLog("DajTicketZleceniaZamkniete: " + intTicket, 3);
            }
        }
     }   


  return(intTicket);
  

}


int DajTicketZlecenia()
// Sprawdza czy sa zlecenia tego systemu i ew. zwraca ticket tego zlecenia, wpp zwaca 0
{

  int total; int cnt;
  int intTicket = 0;
  total=OrdersTotal();
  
  if(total > 0) 
     {
        for(cnt=0;cnt<total;cnt++)
        {
          OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
            if(OrderSymbol()==Symbol() && OrderCloseTime() >= intGodzinaEndAnalyzerFinish  && (OrderComment() == strCommentMarketBuy || OrderComment() == strCommentMarketSell))
            {
               intTicket = OrderTicket();
               ErrorLog("DajTicketZlecenia: " + intTicket, 3);
            }
        }
     }   


  return(intTicket);
   
}


int StaleStopy(string strPara)
{
   int intSL = 30;
   
   if(strPara == "USDJPY" || strPara == "USDCAD" || strPara == "USDCHF" || strPara == "EURAUD" || strPara == "EURCAD" || strPara == "EURJPY" || strPara == "EURUSD" ) intSL = 30; 
   if(strPara == "GBPCHF" || strPara == "GBPJPY" || strPara == "GBPUSD") intSL = 40; 
   if(strPara == "AUDUSD") intSL = 25; 
            
   return(intSL);         
}

int InicjujGodziny()
{
   intGodzinaStartAnalyzer = StrToTime(strGodzinaStartAnalyzer);
   intGodzinaEndAnalyzerFinish = StrToTime(strGodzinaEndAnalyzerFinish);
   intGodzinaCancel = StrToTime(strGodzinaCancel);

   if (intGodzinaCancel < CurTime())
   {
      intGodzinaStartAnalyzer += 60*60*24;
      intGodzinaEndAnalyzerFinish += 60*60*24;
      intGodzinaCancel += 60*60*24;
   }
  intGodzinaSprawdzenia = intGodzinaEndAnalyzerFinish;
}

int CloseMyPositions()
{
  int total; int cnt;
  if(OrdersTotal()>0) 
     {
        total=OrdersTotal();
        for(cnt=0;cnt<total;cnt++)
        {
          OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
            if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())    // OP_SEL lub OP_BUY 
            {
               if(OrderType()==OP_BUY)   
               {
                 OrderClose(OrderTicket(),OrderLots(),Bid,3,Magenta); 
                 
               }           
               else 
               {
                 OrderClose(OrderTicket(),OrderLots(),Ask,3,Magenta); 
               }
               int intErr = GetLastError();
               if(intErr == 0)
                  ErrorLog("CloseMyPositions: pozycja zamknieta ",3);
               else
                  ErrorLog("CloseMyPositions: blad przy zamykaniu: " + intErr + " (" + ErrorDescription(intErr) + ")", 3);
               
            }
        }
     }   

   return(0);
}

string DajSygnal()
{
   ErrorLog("DajSygnal: wejscie", 3);
   int intCzasAktualnejSwieczki = iTime(Symbol(), 30, 0); // poczatek aktualnej swieczki
   int intTMP = 0;
   int intSygnalB = 0;
   int intSygnalS = 0;
   string strKolorSwieczki = "";
   string strSygnal = "";
   ErrorLog("DajSygnal: warunek while poczatkowy: " + TimeToStr(intCzasAktualnejSwieczki) + " >= " + TimeToStr(intGodzinaStartAnalyzer), 3);
   while (intCzasAktualnejSwieczki >= intGodzinaStartAnalyzer) 
   {
      ErrorLog("DajSygnal: warunek while intTMP=" + intTMP + " : " + TimeToStr(intCzasAktualnejSwieczki) + " >= " + TimeToStr(intGodzinaStartAnalyzer), 3);

      if(intCzasAktualnejSwieczki < intGodzinaEndAnalyzerFinish)  // pierwsza analizowana to 15.30
      {
         ErrorLog("DajSygnal: warunek w if: intTMP=" + intTMP + " : " + TimeToStr(intCzasAktualnejSwieczki) + " < " + TimeToStr(intGodzinaEndAnalyzerFinish), 3);
         ErrorLog("DajSygnal: swieczka w if: " + TimeToStr(iTime(Symbol(), 30, intTMP)), 3);         
         ErrorLog("DajSygnal: sprawdzenie warunku ifII: " + iClose(Symbol(), 30, intTMP) + " < " + iOpen(Symbol(), 30, intTMP), 3);
         strKolorSwieczki = DajKolorSwieczkiHeiken(intTMP);
         //if(iClose(Symbol(), 30, intTMP) <  iOpen(Symbol(), 30, intTMP))
         if(strKolorSwieczki == "C")
         {
            ErrorLog("DajSygnal: zwiekszam sygnal B", 3);
            intSygnalB += 1;
         }   
         else if(strKolorSwieczki == "B")         
         {
            ErrorLog("DajSygnal: zwiekszam sygnal S", 3);
            intSygnalS += 1;   
         }   
      }
      intTMP += 1;
      intCzasAktualnejSwieczki = iTime(Symbol(), 30, intTMP);       
   }
   ErrorLog("DajSygnal: intSygnalB=" + intSygnalB + " intSygnalS= " + intSygnalS, 3);
   if (intSygnalB > intSygnalS)
      return("B");
   else if (intSygnalB < intSygnalS)
      return("S");  
   else
      {
      ErrorLog("DajSygnal: brak sygnalu, zwracam '0'", 3);
      return("0");
      }    
}

int ErrorLog(string strTresc, int intLevel )
{
   if (intLevel <= intDebugLevel)
   {
      Print(strTresc);
   }  
}