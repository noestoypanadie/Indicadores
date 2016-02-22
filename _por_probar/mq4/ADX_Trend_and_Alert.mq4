int start()
{   
   double lastsignal=0, signal;   
   
   double Adx=iADX(NULL,0,14,PRICE_HIGH,MODE_MAIN,0);
   double PlusDi=iADX(NULL,0,14,PRICE_HIGH,MODE_PLUSDI,0);
   double MinusDi=iADX(NULL,0,14,PRICE_HIGH,MODE_MINUSDI,0);
 
   if     (Adx >= 25 && PlusDi  >= 25 && MinusDi <= 15) { 	signal = +1; }
   else if(Adx >= 25 && MinusDi >= 25 && PlusDi  <= 15) {   		signal = -1; }
   else {                                               	signal =  0; }
		    

   if (signal!=0) {
      if (signal!=lastsignal) {
         Alert("ADX signal on ", Symbol(),"/",Period());
         lastsignal= signal;   
      }
   } else { lastsignal= 0; }

}

