#property copyright "Copyright © 2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern int       Order;
extern int       Max;
extern int       Min;
int isMax,isMin;

int init(){return(0);}
int deinit(){return(0);}
int start() {

OrderSelect(Order, SELECT_BY_TICKET);
int p=OrderProfit();

  if(p>=Max && isMax==0) {
     isMax=1;
     SendMail(OrderSymbol()+" maximum reached: "+p,"");
   }
   
  if(p<=Min && isMin==0) {
     SendMail(OrderSymbol()+" minimum reached: "+p,"");
     isMin=1;
  }
}

