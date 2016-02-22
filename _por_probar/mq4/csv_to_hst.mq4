//+------------------------------------------------------------------+
//|                                                   csv_to_hst.mq4 |
//|                                                       KLeTcHATyI |
//|                                                  nowindows@nm.ru |
//+------------------------------------------------------------------+
#property copyright "KLeTcHATyI"
#property link      "nowindows@nm.ru"
#property show_inputs

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//---- TODO: Add your code.
   // input
   // files must be in expert/files directory,
   string csv_filename = "USDCHF1440.csv";
   string hst_filename = "TEST.hst";
   int i_period = 1440;
   int i_digits = 4;
   string c_symbol = "USDCHF";
   
   //open csv
   int csv_file = FileOpen(csv_filename, FILE_CSV|FILE_READ, ',');
   if(csv_file < 0) return(-1);
   
   //save hst
   int hst_file = FileOpen(hst_filename, FILE_BIN|FILE_WRITE);
   if(hst_file < 0) return(-1);
   //header
   string c_copyright="(C)opyright 2003, MetaQuotes Software Corp.";
   int    version=400;
   int    i_unused[13];
   FileWriteInteger(hst_file, version, LONG_VALUE);
   FileWriteString(hst_file, c_copyright, 64);
   FileWriteString(hst_file, c_symbol, 12);
   FileWriteInteger(hst_file, i_period, LONG_VALUE);
   FileWriteInteger(hst_file, i_digits, LONG_VALUE);
   FileWriteInteger(hst_file, 0, LONG_VALUE);       //timesign
   FileWriteInteger(hst_file, 0, LONG_VALUE);       //last_sync
   FileWriteArray(hst_file, i_unused, 0, 13);
  
   
   string yyyymmdd, hhmm;
   double d_open, d_high, d_low, d_close, d_volume;
   int t_time;
   //1971.01.04,00:00,4.3180,4.3180,4.3180,4.3180,0
   while (FileIsEnding(csv_file) == false)
   {
     yyyymmdd = FileReadString(csv_file);
     if (yyyymmdd != "") // as a rule, metatrader .csv has empty line
     {
       hhmm = FileReadString(csv_file);
       d_open = FileReadNumber(csv_file);
       d_high = FileReadNumber(csv_file);
       d_low = FileReadNumber(csv_file);
       d_close = FileReadNumber(csv_file);
       d_volume = FileReadNumber(csv_file);
       
       t_time = StrToTime(yyyymmdd+' '+hhmm);
       FileWriteInteger(hst_file, t_time, LONG_VALUE);
       FileWriteDouble(hst_file, d_open, DOUBLE_VALUE);
       FileWriteDouble(hst_file, d_low, DOUBLE_VALUE);
       FileWriteDouble(hst_file, d_high, DOUBLE_VALUE);
       FileWriteDouble(hst_file, d_close, DOUBLE_VALUE);
       FileWriteDouble(hst_file, d_volume, DOUBLE_VALUE);
     }
   }  
   
   Print("csv_to_hst OK");
   
   // close
   FileClose(hst_file);
   FileClose(csv_file);
   
   
//----
   return(0);
  }
//+------------------------------------------------------------------+