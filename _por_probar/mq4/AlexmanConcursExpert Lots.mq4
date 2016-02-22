//+------------------------------------------------------------------+
//|                                         AlexmanConcursExpert.mq4 |
//|                      Copyright © 2006, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#define copyright "Copyright © 2006, AlexMan Studio"
#define link "mailto:alexgomel@tut.by"

#import  "AlexConcursLibrary.ex4"
//Некоторые функции для работы эксперта  
 // double StopValue(int i);
  bool IsByeTrade(int i);
  bool IsSellTrade(int i);
  bool IsStopByeTrade(int i);
  bool IsStopSellTrade(int i);
  double EmaStop(int PeriodEMA, int i);  
#import



//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   GlobalVariableSet( "AlexmanConcursExpert", 0); 
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }

extern int  _MagicNumber = 1440;    // Уникальный магический номер ордера
extern int PeriodEMA  = 15;         // Период ЕМА для расчета стоп-лоса
extern int Zazor = 7;               // буфферный запас на стоп-лосс
extern double Lots = 0.1;           //<----Ben added this extern input and put it in OrderSend's below
 

// Так как по условиям конкурса включаемые файлы не разрешены, используемый файл
// OneOrderControl.mq4 вставлен в тело эксперта непосредственно.
// Спасибо за систему управления ордерами Андрею Хатимлянскому!

//+------------------------------------------------------------------+
//|                                              OneOrderControl.mq4 |
//|                                      Copyright © 2006, komposter |
//|                                      mailto:komposterius@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, komposter"
#property link      "mailto:komposterius@mail.ru"

int _Ticket = 0, _Type = 0; double _Lots = 0.0, _OpenPrice = 0.0, _StopLoss = 0.0;
double _TakeProfit = 0.0; datetime _OpenTime = -1; double _Profit = 0.0, _Swap = 0.0;
double _Commission = 0.0; string _Comment = ""; datetime _Expiration = -1;

void OneOrderInit( int magic )
{
	int _GetLastError, _OrdersTotal = OrdersTotal();

	_Ticket = 0; _Type = 0; _Lots = 0.0; _OpenPrice = 0.0; _StopLoss = 0.0;
	_TakeProfit = 0.0; _OpenTime = -1; _Profit = 0.0; _Swap = 0.0;
	_Commission = 0.0; _Comment = ""; _Expiration = -1;

	for ( int z = _OrdersTotal - 1; z >= 0; z -- )
	{
		if ( !OrderSelect( z, SELECT_BY_POS ) )
		{
			_GetLastError = GetLastError();
			Print( "OrderSelect( ", z, ", SELECT_BY_POS ) - Error #", _GetLastError );
			continue;
		}
		if ( OrderMagicNumber() == magic && OrderSymbol() == Symbol() )
		{
			_Ticket		= OrderTicket();
			_Type			= OrderType();
			_Lots			= OrderLots(); //<--- Ben took normalize out
			_OpenPrice	= NormalizeDouble( OrderOpenPrice(), Digits );
			_StopLoss	= NormalizeDouble( OrderStopLoss(), Digits );
			_TakeProfit	= NormalizeDouble( OrderTakeProfit(), Digits );
			_OpenTime	= OrderOpenTime();
			_Profit		= NormalizeDouble( OrderProfit(), 2 );
			_Swap			= NormalizeDouble( OrderSwap(), 2 );
			_Commission	= NormalizeDouble( OrderCommission(), 2 );
			_Comment		= OrderComment();
			_Expiration	= OrderExpiration();
			return(0);
		}
	}
}


int Shift=1;
 
int start()
{
 //   if (CurTime() < D'2006.07.01 00:00') return(0);
    
    int _GetLastError = 0;
    double spraid = Ask-Bid;
    double EmaStopValue = EmaStop(PeriodEMA,Shift); // вынес в переменную для разгрузки проца
 
    
    //---- Запоминаем параметры открытой позиции (если она есть)
    OneOrderInit( _MagicNumber );
  
    //---- А теперь смотрим, есть ли открытая позиция:
    if ( _Ticket > 0 )
    {
        //---- если открыта БАЙ-позиция,
        if ( _Type == OP_BUY )
        {
            //---- если ee закрывать,
            if ( IsStopByeTrade(Shift) )
            {
                //---- закрываем позицию
                if ( !OrderClose( _Ticket, _Lots, Bid, 5, Green ) )
                {
                    _GetLastError = GetLastError();
                    Print( "Ошибка OrderClose № ", _GetLastError );
                    return(-1);
                }
            }
            //---- если сигнал не изменился, выходим - пока рано открывать новую позицию
            else 
            {   // кстати, может пора двигать стоп-лосс?
              if ((_StopLoss==0 || _StopLoss < (EmaStopValue-(Zazor+5)*Point )) && (EmaStopValue-Zazor*Point ) < Bid)
              {
                if (!OrderModify(_Ticket,_OpenPrice,EmaStopValue-Zazor*Point,_TakeProfit,0,Blue))
                  {
                    _GetLastError = GetLastError();
                    Print( "Ошибка -0- OrderModify № ", _GetLastError );
                    return(-1);
                  }
                  GlobalVariableSet( "AlexmanConcursExpert", 1);
              }      

              if ((_StopLoss==0 || _StopLoss < _OpenPrice) && _Profit>500 )
              {
                if (!OrderModify(_Ticket,_OpenPrice,_OpenPrice,_TakeProfit,0,Blue))
                  {
                    _GetLastError = GetLastError();
                    Print( "Ошибка OrderModify № ", _GetLastError );
                    return(-1);
                  }
                  GlobalVariableSet( "AlexmanConcursExpert", 1);
              }      


              return(0);
            }
         }    
        //---- если открыта СЕЛЛ-позиция,
        if ( _Type == OP_SELL )
        {
            //---- если ее закрывать,
            if ( IsStopSellTrade(Shift) )
            {
                //---- закрываем позицию
                if ( !OrderClose( _Ticket, _Lots, Ask, 5, Red ) )
                {
                    _GetLastError = GetLastError();
                    Print( "Ошибка OrderClose № ", _GetLastError );
                    return(-1);
                }
            }
            //---- если сигнал не изменился, выходим - пока рано открывать новую позицию
            else
            {   // кстати, может пора двигать стоп-лосс?
              if ((_StopLoss==0 || _StopLoss > (EmaStopValue+spraid+(Zazor+5)*Point )) && (EmaStopValue+Zazor*Point ) > Bid)
              {
                if (!OrderModify(_Ticket,_OpenPrice,EmaStopValue+spraid+Zazor*Point,_TakeProfit,0,Blue))
                  {
                    _GetLastError = GetLastError();
                    Print( "Ошибка -1- OrderModify № ", _GetLastError );
                    return(-1);
                  }
                  GlobalVariableSet( "AlexmanConcursExpert", 1);
              }      

              if ((_StopLoss==0 || _StopLoss > _OpenPrice) && _Profit>500 )
              {
                if (!OrderModify(_Ticket,_OpenPrice,_OpenPrice,_TakeProfit,0,Blue))
                  {
                    _GetLastError = GetLastError();
                    Print( "Ошибка OrderModify № ", _GetLastError );
                    return(-1);
                  }
                  GlobalVariableSet( "AlexmanConcursExpert", 1);
              }      


              return(0);
            }
            
        }
    }
    //---- если нет позиции, открытой экспертом ( _Ticket == 0 )
    
   
        //- торгуем только если кончился старый сигнал   
      if ((IsByeTrade(Shift+5) && IsStopByeTrade(Shift)) || (IsSellTrade(Shift+5) && IsStopSellTrade(Shift)) )  
                 GlobalVariableSet( "AlexmanConcursExpert", 0);
   
    
    
    //-- Отдыхаем, если в этот час сработал стоплосс
    
    if(GlobalVariableGet("AlexmanConcursExpert") ==1) return(0);
    
    
    //---- Неплохо бы открыть позицию, например купить
    if ( IsByeTrade(Shift) && EmaStopValue<=Low[Shift] && EmaStopValue < Bid)
    {
        //---- открываем БАЙ позицию
        if ( OrderSend( Symbol(), OP_BUY, Lots, Ask, 5, 0.0, 0.0, "by AlexmanConcursExpert.mq4", 
              _MagicNumber, 0, Green ) < 0 )
        {
            _GetLastError = GetLastError();
            Print( "Ошибка OrderSend № ", _GetLastError );
            return(-1);
        }
        return(0);
    }
    //---- Или может продать?,
    if ( IsSellTrade(Shift)  && EmaStopValue>=High[Shift] && EmaStopValue> Ask)
    {
        //---- открываем СЕЛЛ позицию
        if ( OrderSend( Symbol(), OP_SELL, Lots, Bid, 5, 0.0, 0.0, "by AlexmanConcursExpert.mq4", 
              _MagicNumber, 0, Red ) < 0 )
        {
            _GetLastError = GetLastError();
            Print( "Ошибка OrderSend № ", _GetLastError );
            return(-1);
        }
        return(0);
    }

    return(0);
}