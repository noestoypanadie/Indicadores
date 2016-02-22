//+-----------------------------------------------------------------------------+
//|                              FireStats v0.5 - Output data for stat analysis |
//+-----------------------------------------------------------------------------+
#property copyright "Copyright © 2005, TraderSeven"
#property link      "TraderSeven@gmx.net"

//----------------------- USER INPUT
extern int MA_length = 4;	 
extern double Percent = 2.0;
extern int RetraceBars =2;


string FileName = "";
FileName=StringConcatenate(Symbol()," - ",MA_length);
Comment(FileName);

//-----

int handle;
double MyUpperMA;
double MyLowerMA;
double MaxPipMove;
int previous1;
int previous2;
int previous3;
int init()

{
handle=FileOpen(FileName, FILE_CSV|FILE_WRITE, ',');
}

//----------------------- MAIN PROGRAM LOOP
int start()
{
// ---------- Lower band
MyLowerMA=iMA(NULL,0,MA_length,0,MODE_SMA,PRICE_OPEN,RetraceBars)*(1-(Percent/100));
if(MyLowerMA>=Low[RetraceBars])// detect x-over
  {
  MaxPipMove=MyLowerMA-Low[Lowest(NULL,0,MODE_LOW,RetraceBars,0)];
  MaxPipMove=MathCeil(MathAbs(MaxPipMove*10000));
  if(MaxPipMove!=previous1 && MaxPipMove!=previous2 && MaxPipMove!=previous3)
    {
    FileWrite(handle,TimeToStr(CurTime())," - ",MaxPipMove);      
    }
    previous1=previous2;
    previous2=previous3; 
    previous3=MaxPipMove;    
  }

MyUpperMA=iMA(NULL,0,MA_length,0,MODE_SMA,PRICE_OPEN,RetraceBars)*(1+(Percent/100)); 
if(MyUpperMA>=High[RetraceBars])// detect x-over
   {
  MaxPipMove=MyUpperMA-High[Highest(NULL,0,MODE_HIGH,RetraceBars,0)];
  MaxPipMove=MathCeil(MathAbs(MaxPipMove*10000));
  if(MaxPipMove!=previous1 && MaxPipMove!=previous2 && MaxPipMove!=previous3)
    {
    FileWrite(handle,TimeToStr(CurTime())," - ",MaxPipMove);       
    }
    previous1=previous2;
    previous2=previous3; 
    previous3=MaxPipMove;  
    }



}

int deinit()                           
{                                      
   FileClose(handle);
   return(0);
}