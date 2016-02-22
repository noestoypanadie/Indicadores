extern double Stop 					= 15;
extern string phase="buy";

int start() {
   int cnt;

   if(OrdersTotal()<1) {
      if (phase=="buy") OrderSend(Symbol(),OP_BUY,1,Ask,3,0,0,NULL,0,0,Green);
      if (phase=="sell") OrderSend(Symbol(),OP_SELL,1,Bid,3,0,0,NULL,0,0,Red);
   }

   for(cnt=OrdersTotal();cnt>=0;cnt--) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      
      if(OrderType()==OP_BUY) {
      	if(Bid-OrderOpenPrice()>=Point*Stop) {
				OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); 
			}
		} else if(OrderType()==OP_SELL) {
			if(OrderOpenPrice()-Ask>=Point*Stop) {
				OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
			}
		}
	}
}

return(0);

//--------------------------------------------------------------------------------------+