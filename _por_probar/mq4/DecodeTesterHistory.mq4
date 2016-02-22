//+------------------------------------------------------------------+
//|                                          DecodeTesterHistory.mq4 |
//|                                                               RD |
//|                                                 marynarz15@wp.pl |
//+------------------------------------------------------------------+
#property copyright "RD"
#property link      "marynarz15@wp.pl"
#property show_inputs

extern string FileFromTester="EURCHF30_0";
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
   int FileFromTesterHandle = -1;
   int DecodedFileHeaderHandle = -1;
   int DecodedFileQuotesHandle = -1;
   
/////////////////////////////////   headers   ////////////////////////////////// 
   FileFromTesterHandle=FileOpen(FileFromTester+".fxt",FILE_BIN|FILE_READ);
   if(FileFromTesterHandle<0)
      {
         Print("FileFromTester not found.");
         return(0);
      }   
   DecodedFileHeaderHandle=FileOpen(FileFromTester+".hdr",FILE_CSV|FILE_WRITE,';');
   if(DecodedFileHeaderHandle<0)
      {
         Print("DecodedFile not opened.");
         FileClose(FileFromTesterHandle);
         Print("FileFromTester processing finished.");
         return(0);
      }   
      
////////////////////////      read header     ////////////////////////////////
	string Version=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   string COPYRIGHT=FileReadString(FileFromTesterHandle, 64);
   string FXSymbol=FileReadString(FileFromTesterHandle, 12);
   int FXPeriod=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int FXmodel=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int FXBars=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int FromDate=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int ToDate=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   FileReadInteger(FileFromTesterHandle, LONG_VALUE); //tester writes 1B before Double :(
   double ModelQuality=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   //---- common parameters
   string Currency=FileReadString(FileFromTesterHandle, 12);
   int Spread=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int FXDigits=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   FileReadInteger(FileFromTesterHandle, LONG_VALUE); //tester writes 1B before Double :(
   double FXPoint=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   int lot_min=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int lot_max=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int lot_step=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int stops_level=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int gtc_pendings=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   //---- profit calculation parameters
   FileReadInteger(FileFromTesterHandle, LONG_VALUE); //tester writes 1B before Double :(
   double contract_size=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   double tick_value=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   double tick_size=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   int profit_mode=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   //---- swaps calculation
   int swap_enable=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int swap_type=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   FileReadInteger(FileFromTesterHandle, LONG_VALUE); //tester writes 1B before Double :(
   double swap_long=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   double swap_short=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   int swap_rollover3days=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   //---- margin calculation
   int leverage=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int free_margin_mode=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int margin_mode=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int margin_stopout=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   FileReadInteger(FileFromTesterHandle, LONG_VALUE); //tester writes 1B before Double :(
   double margin_initial=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   double margin_maintenance=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   double margin_hedged=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   double margin_divider=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   string margin_currency=FileReadString(FileFromTesterHandle, 12);
   //---- commission calculation
   FileReadInteger(FileFromTesterHandle, LONG_VALUE); //tester writes 1B before Double :(
   double comm_base=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
   int comm_type=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int comm_lots=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   //---- generation info
   int from_bar=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int to_bar=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
   int start_period[6];
   FileReadArray(FileFromTesterHandle, start_period, 0, 6);
   //----
   int reserved[64];
   FileReadArray(FileFromTesterHandle, reserved, 0, 64);
   
////////////////////////      write header     ////////////////////////////////
   
	FileWrite(DecodedFileHeaderHandle,"Version "+Version);
	FileWrite(DecodedFileHeaderHandle,"COPYRIGHT "+COPYRIGHT);
	FileWrite(DecodedFileHeaderHandle,"Symbol "+FXSymbol);
	FileWrite(DecodedFileHeaderHandle,"Period "+FXPeriod);
	FileWrite(DecodedFileHeaderHandle,"Model "+FXmodel);
	FileWrite(DecodedFileHeaderHandle,"Bars "+FXBars);
	FileWrite(DecodedFileHeaderHandle,"FromDate "+TimeToStr(FromDate,TIME_DATE|TIME_MINUTES));
	FileWrite(DecodedFileHeaderHandle,"ToDate "+TimeToStr(ToDate,TIME_DATE|TIME_MINUTES));
	FileWrite(DecodedFileHeaderHandle,"ModelQuality "+DoubleToStr(ModelQuality,2));
   //---- common parameters
	FileWrite(DecodedFileHeaderHandle,"Currency "+Currency);
	FileWrite(DecodedFileHeaderHandle,"Spread "+Spread);
	FileWrite(DecodedFileHeaderHandle,"Digits "+FXDigits);
	FileWrite(DecodedFileHeaderHandle,"Point "+DoubleToStr(FXPoint,FXDigits));
	FileWrite(DecodedFileHeaderHandle,"lot_min "+lot_min);
	FileWrite(DecodedFileHeaderHandle,"lot_max "+lot_max);
	FileWrite(DecodedFileHeaderHandle,"lot_step "+lot_step);
	FileWrite(DecodedFileHeaderHandle,"stops_level "+stops_level);
	FileWrite(DecodedFileHeaderHandle,"gtc_pendings "+gtc_pendings);
   //---- profit calculation parameters
	FileWrite(DecodedFileHeaderHandle,"contract_size "+DoubleToStr(contract_size,2));
	FileWrite(DecodedFileHeaderHandle,"tick_value "+DoubleToStr(tick_value,4));
	FileWrite(DecodedFileHeaderHandle,"tick_size "+DoubleToStr(tick_size,4));
	FileWrite(DecodedFileHeaderHandle,"profit_mode "+profit_mode);
   //---- swaps calculation
	FileWrite(DecodedFileHeaderHandle,"swap_enable "+swap_enable);
	FileWrite(DecodedFileHeaderHandle,"swap_type "+swap_type);
	FileWrite(DecodedFileHeaderHandle,"swap_long "+DoubleToStr(swap_long,4));
	FileWrite(DecodedFileHeaderHandle,"swap_short "+DoubleToStr(swap_short,4));
	FileWrite(DecodedFileHeaderHandle,"swap_rollover3days "+swap_rollover3days);
   //---- margin calculation
	FileWrite(DecodedFileHeaderHandle,"leverage "+leverage);
	FileWrite(DecodedFileHeaderHandle,"free_margin_mode "+free_margin_mode);
	FileWrite(DecodedFileHeaderHandle,"margin_mode "+margin_mode);
	FileWrite(DecodedFileHeaderHandle,"margin_stopout "+margin_stopout);
	FileWrite(DecodedFileHeaderHandle,"margin_initial "+DoubleToStr(margin_initial,2));
	FileWrite(DecodedFileHeaderHandle,"margin_maintenance "+DoubleToStr(margin_maintenance,2));
	FileWrite(DecodedFileHeaderHandle,"margin_hedged "+DoubleToStr(margin_hedged,2));
	FileWrite(DecodedFileHeaderHandle,"margin_divider "+DoubleToStr(margin_divider,4));
	FileWrite(DecodedFileHeaderHandle,"margin_currency "+margin_currency);
   //---- commission calculation
	FileWrite(DecodedFileHeaderHandle,"comm_base "+DoubleToStr(comm_base,4));
	FileWrite(DecodedFileHeaderHandle,"comm_type "+comm_type);
	FileWrite(DecodedFileHeaderHandle,"comm_lots "+comm_lots);      
   //---- generation info
	FileWrite(DecodedFileHeaderHandle,"from_bar "+from_bar);
	FileWrite(DecodedFileHeaderHandle,"to_bar "+to_bar);
	string start_periods="";
	for(int i=0;i<6;i++) start_periods=start_periods+start_period[i]+" ";
	FileWrite(DecodedFileHeaderHandle,"start_periods "+start_periods);
   //----
	string reserveds="";
	for(i=0;i<64;i++) reserveds=reserveds+reserved[i]+" ";
	FileWrite(DecodedFileHeaderHandle,"reserved "+reserveds);
//////////////////////////////////////////////////////////////////////////////      
   FileClose(DecodedFileHeaderHandle);
   Print("DecodedFileHeader writing finished.");
   
/////////////////////////////////   quotes   ////////////////////////////////// 
   DecodedFileQuotesHandle=FileOpen(FileFromTester+".quo",FILE_CSV|FILE_WRITE,';');
   if(DecodedFileQuotesHandle<0)
      {
         Print("DecodedFileQuotesHandle not opened.");
         FileClose(FileFromTesterHandle);
         Print("FileFromTester processing finished.");
         return(0);
      }   
   int otm, ctm;                
   double open, low, high, close, volume;              
   int flag;               
   string quote="";
   while(!FileIsEnding(FileFromTesterHandle))
      {
         ////////////////   read quotes   /////////////////////
         otm=FileReadInteger(FileFromTesterHandle, LONG_VALUE);
         open=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);               
         low=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
         high=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
         close=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
         volume=FileReadDouble(FileFromTesterHandle, DOUBLE_VALUE);
         ctm=FileReadInteger(FileFromTesterHandle, LONG_VALUE);             
         flag=FileReadInteger(FileFromTesterHandle, LONG_VALUE); 
         if(otm==0) continue;
         ////////////////   write quotes   /////////////////////
         quote=TimeToStr(otm,TIME_DATE|TIME_MINUTES)+" "+
               DoubleToStr(open,Digits)+" "+
               DoubleToStr(high,Digits)+" "+
               DoubleToStr(low,Digits)+" "+
               DoubleToStr(close,Digits)+" "+
               DoubleToStr(volume,0)+" "+
               TimeToStr(ctm,TIME_DATE|TIME_MINUTES)+" "+
               flag;
	      FileWrite(DecodedFileQuotesHandle,quote);
      }

   FileClose(FileFromTesterHandle);
   Print("FileFromTester processing finished.");
   FileClose(DecodedFileQuotesHandle);
   Print("DecodedFileQuotes writing finished.");
   return(0);
  }
//+---------------------------------------------------------------------------+