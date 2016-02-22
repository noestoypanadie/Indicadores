//+------------------------------------------------------------------+
//|                                             metastock_to_csv.mq4 |
//|                                                       KLeTcHATyI |
//|                                                  nowindows@nm.ru |
//+------------------------------------------------------------------+
#property copyright "KLeTcHATyI"
#property link      "nowindows@nm.ru"

/*
  This script transform metastock .txt file to metatrader .csv file
  metastock : <TICKER>,<PER>,<DTYYYYMMDD>,<TIME>,<OPEN>,<HIGH>,<LOW>,<CLOSE>,<VOL>,<OPENINT>
  see input
*/


//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//---- TODO: Add your code.
   // input
   // files must be in expert/files directory,
   string metastock_filename = "chfd.txt";
   string csv_filename = "USDCHF1440.csv";
   //int i_digits = 4;
   //string c_symbol = "USDCHF";
   

   //open metastock txt
   int metastock_file = FileOpen(metastock_filename, FILE_CSV|FILE_READ, ',');
   if(metastock_file < 0) return(-1);
   
   //save metatrader csv
   int csv_file = FileOpen(csv_filename, FILE_CSV|FILE_WRITE,',');
   if(csv_file < 0) return(-1);
   
   string yyyymmdd, hhmmss;
   string s_open, s_high, s_low, s_close, s_volume;
   string s_ticker, s_period, s_time;
   
   // skip header of metastock file <TICKER>,<PER>,<DTYYYYMMDD>,<TIME>,<OPEN>,<HIGH>,<LOW>,<CLOSE>,<VOL>,<OPENINT>
   string tmp = FileReadString(metastock_file); //ticker
   tmp = FileReadString(metastock_file); //per
   tmp = FileReadString(metastock_file);
   tmp = FileReadString(metastock_file);
   tmp = FileReadString(metastock_file);
   tmp = FileReadString(metastock_file);
   tmp = FileReadString(metastock_file);
   tmp = FileReadString(metastock_file);
   tmp = FileReadString(metastock_file);
   tmp = FileReadString(metastock_file); //openint
   
   //CHF,D,19710104,000000,4.3180,4.3180,4.3180,4.3180,0,0
   while (FileIsEnding(metastock_file) == false)
   {
     s_ticker = FileReadString(metastock_file); // last line in file may be empty
     if (s_ticker != "")
     {
       s_period = FileReadString(metastock_file);
       yyyymmdd = FileReadString(metastock_file);
       hhmmss = FileReadString(metastock_file);
       s_open = FileReadString(metastock_file);
       s_high = FileReadString(metastock_file);
       s_low = FileReadString(metastock_file);
       s_close = FileReadString(metastock_file);
       s_volume = FileReadString(metastock_file);
       tmp = FileReadString(metastock_file); //open interest
       
       s_time = StringSubstr(yyyymmdd, 0, 4)+"."+StringSubstr(yyyymmdd, 4, 2)+"."+StringSubstr(yyyymmdd, 6, 2)+" "+StringSubstr(hhmmss, 0, 2)+":"+StringSubstr(hhmmss, 2, 2);
       
       FileWrite(csv_file, s_time, s_open, s_high, s_low, s_close, s_volume);
     }
   }  
   
   FileClose(metastock_file);
   FileClose(csv_file);
   
   Print("metastock_to_csv OK");
   
//----
   return(0);
  }
//+------------------------------------------------------------------+