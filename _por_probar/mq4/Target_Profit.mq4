                            //---------------------------------------------//
                            //                    Target Profit script
                            //                Copyright     Jacob Yego    //
                            //---------------------------------------------//

#property copyright "Jacob Yego"
#property link      ""

extern int TargetProfit = 10; // Your Profit target
bool loswitch=false;  //switch to true for losslimit
double CurProfit;
int Slippage=5;
int cnt,laser;
int ls=0;
int start()
{
  if (loswitch==true) {ls=-1;} else {ls=1;}
  int total = OrdersTotal();
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() )
        {
        
         if(OrderType()==OP_BUY)
           {
            CurProfit=Bid-OrderOpenPrice() ;

              if (loswitch && CurProfit<= (TargetProfit*ls*Point) || CurProfit>=(TargetProfit*ls*Point))
              {
               OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,White);
               laser=GetLastError();
               if(laser==0)
                 {
      Alert(" Order : ", OrderTicket() , "Closed Succesfully" );
      Sleep(1000);
                }
      else 
                 {
                  Print("--ERROR-- Closing BUY  Bid=",Bid,OrderTicket()," error=",laser);
                 }            
           }
       }
  if(OrderType()==OP_SELL)
           {

            CurProfit=OrderOpenPrice()-Ask;            
            if (loswitch && CurProfit<= (TargetProfit*ls*Point) || CurProfit>=(TargetProfit*ls*Point))
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,White);
               laser=GetLastError();
               if(laser==0)
                 {
      Alert( " Order :", OrderTicket() ,"  Closed Succesfully" );
      Sleep(1000);      
              }
               else 
                 {
                  Print("--ERROR-- Closing SELL  Ask=",Ask,OrderTicket()," error=",laser);
                 }
          }
       }
   }
 }
  return(0);
}




