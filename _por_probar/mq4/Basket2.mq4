//+------------------------------------------------------------------+
//|                                                      Basket2.mq4 |
//|                                    Copyright © 2006, MQL Service |
//|                                        http://www.mqlservice.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, MQL Service"
#property link      "http://www.mqlservice.com"
#property show_inputs
#include <WinUser32.mqh>

extern int ExtPeriodMultiplier=2; // new period multiplier factor
extern string Symbol2 = "GBPUSD";
extern double Weight2 = 0.5;
extern string FileName = "BASKET";

/*
  This script makes a new symbol called BASKET according to formula:
  
  Attached_chart_symbol*(1-Weigth2) + Symbol2*Weight2;
  
  In order to make different symbol one needs to edit functions below.
*/
//+------------------------------------------------------------------+
double volume(int idx)
{
  return((1.0-Weight2)*Volume[idx]+Weight2*iVolume(Symbol2, Period(), idx));
}
double open(int idx)
{
  return((1.0-Weight2)*Open[idx]+Weight2*iOpen(Symbol2, Period(), idx));
}
double close(int idx)
{
  return((1.0-Weight2)*Close[idx]+Weight2*iClose(Symbol2, Period(), idx));
}
double high(int idx)
{
  return((1.0-Weight2)*High[idx]+Weight2*iHigh(Symbol2, Period(), idx));
}
double low(int idx)
{
  return((1.0-Weight2)*Low[idx]+Weight2*iLow(Symbol2, Period(), idx));
}
//+------------------------------------------------------------------+

int        ExtHandle=-1;
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
   int    i, start_pos, i_time, time0, last_fpos, periodseconds;
   double d_open, d_low, d_high, d_close, d_volume, last_volume;
   int    hwnd=0,cnt=0;
//---- History header
   int    version=400;
   string c_copyright;
   int    i_period=Period()*ExtPeriodMultiplier;
   int    i_digits=Digits;
   int    i_unused[13];
//----  
   ExtHandle=FileOpenHistory(FileName+i_period+".hst", FILE_BIN|FILE_WRITE);
   if(ExtHandle < 0) return(-1);
//---- write history file header
   c_copyright="(C)opyright 2003, MetaQuotes Software Corp.";
   FileWriteInteger(ExtHandle, version, LONG_VALUE);
   FileWriteString(ExtHandle, c_copyright, 64);
   FileWriteString(ExtHandle, FileName, 12);
   FileWriteInteger(ExtHandle, i_period, LONG_VALUE);
   FileWriteInteger(ExtHandle, i_digits, LONG_VALUE);
   FileWriteInteger(ExtHandle, 0, LONG_VALUE);       //timesign
   FileWriteInteger(ExtHandle, 0, LONG_VALUE);       //last_sync
   FileWriteArray(ExtHandle, i_unused, 0, 13);
//---- write history file
   periodseconds=i_period*60;
   start_pos=Bars-1;
   d_open=open(start_pos);
   d_low=low(start_pos);
   d_high=high(start_pos);
   d_volume=volume(start_pos);
   
   //---- normalize open time
   i_time=Time[start_pos]/periodseconds;
   i_time*=periodseconds;
   for(i=start_pos-1;i>=0; i--)
     {
      time0=Time[i];
      if(time0>=i_time+periodseconds || i==0)
        {
         if(i==0 && time0<i_time+periodseconds)
           {
            d_volume+=volume(0);
            if (low(0)<d_low)   d_low=low(0);
            if (high(0)>d_high) d_high=high(0);
            d_close=close(0);
          
           }
         last_fpos=FileTell(ExtHandle);
         last_volume=volume(i);
         FileWriteInteger(ExtHandle, i_time, LONG_VALUE);
         FileWriteDouble(ExtHandle, d_open, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_low, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_high, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_close, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_volume, DOUBLE_VALUE);
         FileFlush(ExtHandle);
         cnt++;
         if(time0>=i_time+periodseconds)
           {
            i_time=time0/periodseconds;
            i_time*=periodseconds;
            d_open=open(i);
            d_low=low(i);
            d_high=high(i);
            d_close=close(i);
            d_volume=last_volume;
           }
        }
       else
        {
         d_volume+=volume(i);
         if (low(i)<d_low)   d_low=low(i);
         if (high(i)>d_high) d_high=high(i);
         d_close=close(i);
        }
     } 
   FileFlush(ExtHandle);
   Print(cnt," record(s) written");
//---- collect incoming ticks
   int last_time=LocalTime()-5;
   while(IsStopped()==false)
     {
      int cur_time=LocalTime();
      //---- check for new rates
      if(RefreshRates())
        {
         time0=Time[0];
         FileSeek(ExtHandle,last_fpos,SEEK_SET);
         //---- is there current bar?
         if(time0<i_time+periodseconds)
           {
            d_volume+=volume(0)-last_volume;
            last_volume=volume(0); 
            if (low(0)<d_low) d_low=low(0);
            if (high(0)>d_high) d_high=high(0);
            d_close=close(0);
           }
         else
           {
           //Print("New bar");
            //---- no, there is new bar
            d_volume+=volume(1)-last_volume;
            if (low(1)<d_low) d_low=low(1);
            if (high(1)>d_high) d_high=high(1);
            //---- write previous bar remains
            FileWriteInteger(ExtHandle, i_time, LONG_VALUE);
            FileWriteDouble(ExtHandle, d_open, DOUBLE_VALUE);
            FileWriteDouble(ExtHandle, d_low, DOUBLE_VALUE);
            FileWriteDouble(ExtHandle, d_high, DOUBLE_VALUE);
            FileWriteDouble(ExtHandle, d_close, DOUBLE_VALUE);
            FileWriteDouble(ExtHandle, d_volume, DOUBLE_VALUE);
            last_fpos=FileTell(ExtHandle);
            //----
            i_time=time0/periodseconds;
            i_time*=periodseconds;
            d_open=open(0);
            d_low=low(0);
            d_high=high(0);
            d_close=close(0);
            d_volume=volume(0);
            last_volume=d_volume;
           }
         //----
         FileWriteInteger(ExtHandle, i_time, LONG_VALUE);
         FileWriteDouble(ExtHandle, d_open, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_low, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_high, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_close, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_volume, DOUBLE_VALUE);
         FileFlush(ExtHandle);
         //----
         if(hwnd==0)
           {
            hwnd=WindowHandle(FileName,i_period);
            if(hwnd!=0) Print("Chart window detected");
           }
         //---- refresh window not frequently than 1 time in 2 seconds
         if(hwnd!=0 && cur_time-last_time>=2)
           {
            PostMessageA(hwnd,WM_COMMAND,33324,0);
            last_time=cur_time;
           }
        } 
     }      
//----
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deinit()
  {
   if(ExtHandle>=0) { FileClose(ExtHandle); ExtHandle=-1; }
  }
//+--------Coded by Michal Rutka-------------------------------------+