extern bool 
   auto=true;

extern double
   lots=0.1,
   stop=0.75;   
   
extern int 
   mgod=2005,
   start=1,
   depth=12,
   deviation=5,
   backstep=3,
   TP=150,
   SL=30,
   SL2=1,
   ttime=15,
   eaID=735345;

int del;
del = MarketInfo(Symbol(),MODE_STOPLEVEL);

int 
   i,
   cnt,
   LTT,
   j,
   s,b,
   os,ob,
   mods,
   top,
   dblok;

double 
   MaxH,
   MinL,
   MidL,
   mtp,
   MH,LH,
   mlot,
   MidLine,
   summa,
   ssum,
   bsum,
   slot,
   blot,
   kr,
   kz,
   zz,
   zz0,
   TSumm[10000],
   MaxS;
      
string    
   reg;

// EXPERT RUN ---------------------------------------------------------------

int start()
   {
   Initialize();
   RangeCalculation();
   Order_inventory();
   DataDisplay();
   SecureProfit();
   Order_modify();
   Order_close();
   Order_delete();
   Order_place();
   }

// FUNCTION DUMP ------------------------------------------------------------

void Initialize()
   {
   // Main switches
   if (start==0)  return;
   if (Year()!=mgod)  return;
      
   // Money management & sizing
   if (lots>=1 && AccountBalance()>=10000) 
      kr=NormalizeDouble((AccountBalance()/10000),0);
   if (lots<1 && AccountBalance()<10000) kr=1; 
   if (lots<1 && AccountBalance()>=1000)   
      kr=NormalizeDouble((AccountBalance()/1000),0); 
   if (lots<1 && AccountBalance()<1000) kr=1;      
   if (kr>100) kr=100;
   mlot=kr*lots;
   
   j++;      
   if (Minute()==0)  j=0;
         
   if (auto==1)  reg="Auto";
   if (auto==0)  reg="Manual";
   } 

void RangeCalculation()
   {   
   if (((High[0]-Low[0])/Point)>=10 && Hour()==23 && Minute()>55)
      {
      MaxH=High[0];
      MinL=Low[0];
      } else { 
      MaxH=High[1];
      MinL=Low[1];
      }
   
   MidL=NormalizeDouble((MaxH+MinL)/2,Digits);
   mtp=(MaxH-MinL)/2;
      
   zz  = iCustom(Symbol(),0,"ZigZag",depth,deviation,backstep,0,3);
   zz0 = iCustom(Symbol(),0,"ZigZag",depth,deviation,backstep,0,0);
   
   if (zz!=0 && zz>Close[0] && Hour()==23 && Minute()>=55) top=1;     
   if (zz!=0 && zz<Close[0] && Hour()==23 && Minute()>=55) top=-1; 
   if (zz0>0) top=0;
   
   if (ObjectFind("MaxH")<0) 
      ObjectCreate("MaxH",OBJ_HLINE,0,Time[0],MaxH);
   ObjectSet("MaxH",OBJPROP_PRICE1,MaxH);
   ObjectSet("MaxH",OBJPROP_COLOR,GreenYellow);
   
   if (ObjectFind("MinL")<0) 
      ObjectCreate("MinL",OBJ_HLINE,0,Time[0],MinL);
   ObjectSet("MinL",OBJPROP_PRICE1,MinL);
   ObjectSet("MinL",OBJPROP_COLOR,Red);
   } 

//----------------------------------------Подсчёт активных и пассивных ордеров----------------------------------------

void Order_inventory()
   {
   s=0; b=0;
   os=0; ob=0;
   summa=0; 
   slot=0; blot=0;
   ssum=0; bsum=0;
   
   for (int cnt=0; cnt<OrdersTotal(); cnt++)
      {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber()==eaID && OrderSymbol()==Symbol())
         {
         if (OrderType()==OP_SELL || OrderType()==OP_BUY) 
            summa=summa+OrderProfit();
         if (OrderType()==OP_SELL) { 
            ssum=ssum+OrderProfit();
            slot=slot+OrderLots();
            s++;
            }
         if (OrderType()==OP_BUY) {
            bsum=bsum+OrderProfit();
            blot=blot+OrderLots();
            b++;
            }
         if (OrderType()==OP_SELLSTOP) os++;
         if (OrderType()==OP_BUYSTOP)  ob++;
         }
      }   
   
   if (s+b==0) {
      for (int i=1; i<10000; i++) {
         TSumm[i]=0;
         }
      i=0;
      mods=0;
      MaxS=0;
      kz=0;
      }
      
   }

//---------------------------------------------------Комментарии------------------------------------------------------

void DataDisplay()
   {  
   if (!IsTesting()) Comment("Data: ",Year(),".",Month(),".",Day(),"  Time ",Hour(),":",Minute(),"   JInd=",j,"  APoz=",s+b,"  Ords=",os+ob,"  Mod=",mods,
        "  Top=",top,"  ZZ0=",MathRound(zz0),"  ZZ3=",MathRound(zz),"  Kz=",kz,"  MaxS=",MathRound(MaxS),"  MidL=",MidL,
        "  Profit=",MathRound(summa),"  Режим: ",reg); 

   //if (!IsTesting()) Print("Data: ",Year(),".",Month(),".",Day(),"  Time ",Hour(),":",Minute(),"   JInd=",j,"  Ords=",os+ob,"  APoz=",s+b,"  Mod=",mods,
   //   "  Top=",top,"  Mlot=",mlot,"  ZZ0=",MathRound(zz0),"  ZZ3=",MathRound(zz),"  Kz=",kz,"  MaxS=",MathRound(MaxS),
   //   "  Profit=",MathRound(summa));
   
   //if (CurTime()-LTT<ttime) return;
   }
   
//----------------------------------Процедура отъёма профита по его динамике------------------------------------------
void SecureProfit()
   {
   if (summa>=100*mlot) 
      { 
		i++; 
		TSumm[i]=summa;
		MaxS=0;
		if (i>1)
			{
			for (cnt=0; cnt<i; cnt++)
				{
				if (MaxS<TSumm[cnt])MaxS=TSumm[cnt];
				}
			kz=NormalizeDouble((TSumm[i]/MaxS),1);
			}
		if (kz<=stop && kz!=0)
			{
			for (cnt=0; cnt<OrdersTotal(); cnt++)
				{
				OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
            if (OrderMagicNumber()==eaID && OrderSymbol()==Symbol())
               {
               if (OrderType()==OP_SELL && ssum>0 &&
                  OrderOpenPrice()==MidL)
                  {
                  OrderClose(OrderTicket(),OrderLots(),Ask,5,Red);
                  return;
                  }
               if (OrderType()==OP_BUY && bsum>0  &&
                  OrderOpenPrice()==MidL) 
                  {
                  OrderClose(OrderTicket(),OrderLots(),Bid,5,Red);
                  return;
                  }
               }
            }
         }
      }
   }

//--------------------------------Процедура модификации стопа профитной позиции--------------------------------------

void Order_modify()
   {
   if (summa>100*mlot && mods==0)
      {
      for (cnt=0; cnt<OrdersTotal(); cnt++)
         {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber()==eaID && OrderSymbol()==Symbol())
            {
            if (OrderType()==OP_SELL && s>0) 
               {
               OrderModify(OrderTicket(),OrderOpenPrice(),
			         OrderOpenPrice()-SL2*Point,OrderTakeProfit(),0,Maroon);
			      mods=1;
			      return;
			      }
			   if (OrderType()==OP_BUYSTOP && b>0)
			      {
			      OrderModify(OrderTicket(),OrderOpenPrice(),
			         OrderOpenPrice()+SL2*Point,OrderTakeProfit(),0,OliveDrab);
			      mods=1;
			      return;
			      }
			   }
			}
		}
   }

//-------------------------------------------Закрытие активных позиций ----------------------------------------------

void Order_close()
   {
   if (Hour()==23 && Minute()>=50 && s+b>0) 
      {      
   for (cnt=0; cnt<OrdersTotal(); cnt++)
      {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber()==eaID && OrderSymbol()==Symbol())
         {
         if (OrderType()==OP_SELL)  
            {
            OrderClose(OrderTicket(),OrderLots(),Ask,5,Red);
            //LTT = CurTime();
            return;
            }
         if (OrderType()==OP_BUY)
            {
            OrderClose(OrderTicket(),OrderLots(),Bid,5,Red);
            //LTT = CurTime();
            return;
            }
         }
      }
      }
   }

//-----------------------------------------Удаление неиспользованных одеров-------------------------------------------

void Order_delete()
   {
   if (Hour()==23 && Minute()<50) dblok=0;   
   if (Hour()==23 && Minute()>=50 && dblok==0)
      {
      if (os+ob==1) dblok=1;
      for (cnt=0; cnt<OrdersTotal(); cnt++)
         {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if (OrderMagicNumber()==eaID && OrderSymbol()==Symbol())
            {
            if (OrderType()==OP_BUYSTOP) 
               {
               OrderDelete(OrderTicket());
               //LTT = CurTime();
               return;
               } 
            if (OrderType()==OP_SELLSTOP) 
               {
               OrderDelete(OrderTicket());
               //LTT = CurTime();
               return;
               }
            }
         } 
      }
   }

//------------------------------------------Выставление канальных ордеров---------------------------------------------

void Order_place()
   {
   if ((Hour()==23 && Minute()>=55) || s+b+os+ob<2)
      {
   
   if (auto==1 && MaxH!=0 && MinL!=0 && os+ob<=1 && s+b==0) 
      {
      if (os==0 && ((Close[0]-MinL)/Point)>=3 && (top==1 || top==0))  
         {
         OrderSend(Symbol(),OP_SELLSTOP,mlot,
            MinL-del*Point,5,MinL-del*Point+SL*Point,MinL-del*Point-TP*Point,
            NULL,eaID,0,Red);
         //LTT = CurTime();
         return;
         }
         
      if (os==0 && ((Close[0]-MinL)/Point)<=0 && (top==1 || top==0))
         {
         OrderSend(Symbol(),OP_SELLSTOP,mlot,
            Bid-del*Point,5,Bid-del*Point+SL*Point,Bid-del*Point-TP*Point,
            NULL,eaID,0,Red);
         //LTT = CurTime();
         return;
         }
         
      if (ob==0 && ((MaxH-Close[0])/Point)>=3 && (top==-1 || top==0)) 
         {
         OrderSend(Symbol(),OP_BUYSTOP,mlot,
            MaxH+del*Point,5,MaxH+del*Point-SL*Point,MaxH+del*Point+TP*Point,
            NULL,eaID,0,GreenYellow);
         //LTT = CurTime();
         return;
         }
         
      if (ob==0 && ((MaxH-Close[0])/Point)<=0 && (top==-1 || top==0)) 
         {
         OrderSend(Symbol(),OP_BUYSTOP,mlot,
            Ask+del*Point,5,Ask+del*Point-SL*Point,Ask+del*Point+TP*Point,
            NULL,eaID,0,GreenYellow);
         //LTT = CurTime();
         return;
         }
      }
      
   if (auto==1 && os==1 && ob==1 && s+b==0 && Hour()>0 && Minute()<55)
      {
      if (((MidL-Close[0])/Point)>=del) 
         { 
         OrderSend(Symbol(),OP_BUYSTOP,mlot,
            MidL,5,MidL-SL*Point,MidL+mtp,
            NULL,eaID,0,GreenYellow);
         return;
         }
      
      if (((Close[0]-MidL)/Point)>=del) 
         { 
         OrderSend(Symbol(),OP_BUYSTOP,mlot,
            MidL,5,MidL+SL*Point,MidL-mtp,
            NULL,eaID,0,GreenYellow);
         return;
         }
      }
         
   if (auto==0)
      Comment("УСТАНОВИТЕ ДВА ОРДЕРА ЗА ПРЕДЕЛАМИ КАНАЛА (В РЕЖИМЕ АВТО ЭТОГО ДЕЛАТЬ НЕ НАДО), А ОСТАЛЬНОЕ СДЕЛАЮ Я");
   
   }
   } 