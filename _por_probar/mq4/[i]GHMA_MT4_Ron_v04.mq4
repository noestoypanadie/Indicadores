//-----------------------
// HMA modified by Ron
//-----------------------

// H4 chart, EURUSD 24/7


// variables declared here are GLOBAL in scope

#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex/"
#property indicator_separate_window
#property indicator_minimum -6
#property indicator_maximum 6
#property indicator_buffers 2
#property indicator_color1 White
#property indicator_color2 DodgerBlue

//User Input
extern int    _maPrice=1;
extern int    Trigger=3;
extern int    smoothing=16;

// naming and numbering
string   TradeComment = "GHMA_04_";

// indicator stuff
double Buffer1[1505];
double Buffer2[1505];


// moving average arrays

int largeArray=1500;
int mediumArray=1400;

double _hma[1505];
ArraySetAsSeries(_hma,true);
double _wma1[1505];
ArraySetAsSeries(_wma1,true);
double _wma2[1505];
ArraySetAsSeries(_wma2,true);
double _wma3[1505];
ArraySetAsSeries(_wma3,true);
double _wma4[1505];
ArraySetAsSeries(_wma4,true);
double _wma5[1505];
ArraySetAsSeries(_wma5,true);
double _wma6[1505];
ArraySetAsSeries(_wma6,true);

// object counting
int uniq=0;


//-----------------------
// Startup stuff
//-----------------------
int init() 
  {
   int i;
   //remove the old objects 
   for(i=0; i<Bars; i++) 
     {
      ObjectDelete("myx0"+DoubleToStr(i,0));
      ObjectDelete("mySB"+DoubleToStr(i,0));
      ObjectDelete("myWW"+DoubleToStr(i,0));
     }

   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0, Buffer1);
   
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1, Buffer2);
   
   Print("Indicator Init happened ",CurTime());
   Comment(TradeComment);
  } //init
  


//-----------------------
// Shutdown stuff
//-----------------------
int deinit()
  {
   int i;
   //remove the old objects 
   for(i=0; i<Bars; i++) 
     {
      ObjectDelete("myx0"+DoubleToStr(i,0));
      ObjectDelete("mySB"+DoubleToStr(i,0));
      ObjectDelete("myWW"+DoubleToStr(i,0));
     }
   Print("Indicator DE-Init happened ",CurTime());
   Comment(" ");
  }



//-----------------------
// Tick stuff
//-----------------------
int start()
  {
   int pos=0;
   
   uniq=0;
   
   double fullMA;
   double halfMA;
   
   double sqrtMA0;
   double sqrtMA1;
   

   for(pos=largeArray; pos>=0; pos--) 
     {
      fullMA=iMA(Symbol(), 0,  4  , 0, MODE_LWMA, _maPrice, pos);
      halfMA=iMA(Symbol(), 0,  4/2, 0, MODE_LWMA, _maPrice, pos);
      _wma1[pos]=(2*halfMA)-fullMA;
     }

   for(pos=largeArray; pos>=0; pos--) 
     {
      fullMA=iMA(Symbol(), 0,  8  , 0, MODE_LWMA, _maPrice, pos);
      halfMA=iMA(Symbol(), 0,  8/2, 0, MODE_LWMA, _maPrice, pos);
      _wma2[pos]=(2*halfMA)-fullMA;
     }

   for(pos=largeArray; pos>=0; pos--) 
     {
      fullMA=iMA(Symbol(), 0, 16  , 0, MODE_LWMA, _maPrice, pos);
      halfMA=iMA(Symbol(), 0, 16/2, 0, MODE_LWMA, _maPrice, pos);
      _wma3[pos]=(2*halfMA)-fullMA;
     }

   for(pos=largeArray; pos>=0; pos--) 
     {
      fullMA=iMA(Symbol(), 0, 32  , 0, MODE_LWMA, _maPrice, pos);
      halfMA=iMA(Symbol(), 0, 32/2, 0, MODE_LWMA, _maPrice, pos);
      _wma4[pos]=(2*halfMA)-fullMA;
     }

   for(pos=largeArray; pos>=0; pos--) 
     {
      fullMA=iMA(Symbol(), 0, 64  , 0, MODE_LWMA, _maPrice, pos);
      halfMA=iMA(Symbol(), 0, 64/2, 0, MODE_LWMA, _maPrice, pos);
      _wma5[pos]=(2*halfMA)-fullMA;
     }

   for(pos=largeArray; pos>=0; pos--) 
     {
      fullMA=iMA(Symbol(), 0, 128  , 0, MODE_LWMA, _maPrice, pos);
      halfMA=iMA(Symbol(), 0, 128/2, 0, MODE_LWMA, _maPrice, pos);
      _wma6[pos]=(2*halfMA)-fullMA;
     }



   for(pos=mediumArray; pos>=0; pos--) 
     {
      _hma[pos]=0;
     }

     
   for(pos=mediumArray; pos>=0; pos--) 
     {
      sqrtMA0=iMAOnArray(_wma1,0,2,0,MODE_LWMA,pos+0);
      sqrtMA1=iMAOnArray(_wma1,0,2,0,MODE_LWMA,pos+1);
      if (sqrtMA1<sqrtMA0){_hma[pos]=_hma[pos]+1;} else {_hma[pos]=_hma[pos]-1;}         
     }

   for(pos=mediumArray; pos>=0; pos--) 
     {
      sqrtMA0=iMAOnArray(_wma2,0,3,0,MODE_LWMA,pos+0);
      sqrtMA1=iMAOnArray(_wma2,0,3,0,MODE_LWMA,pos+1);
      if (sqrtMA1<sqrtMA0){_hma[pos]=_hma[pos]+1;} else {_hma[pos]=_hma[pos]-1;}         
     }

   for(pos=mediumArray; pos>=0; pos--) 
     {
      sqrtMA0=iMAOnArray(_wma3,0,4,0,MODE_LWMA,pos+0);
      sqrtMA1=iMAOnArray(_wma3,0,4,0,MODE_LWMA,pos+1);
      if (sqrtMA1<sqrtMA0){_hma[pos]=_hma[pos]+1;} else {_hma[pos]=_hma[pos]-1;}         
     }

   for(pos=mediumArray; pos>=0; pos--) 
     {
      sqrtMA0=iMAOnArray(_wma4,0,6,0,MODE_LWMA,pos+0);
      sqrtMA1=iMAOnArray(_wma4,0,6,0,MODE_LWMA,pos+1);
      if (sqrtMA1<sqrtMA0){_hma[pos]=_hma[pos]+1;} else {_hma[pos]=_hma[pos]-1;}         
     }

   for(pos=mediumArray; pos>=0; pos--) 
     {
      sqrtMA0=iMAOnArray(_wma5,0,8,0,MODE_LWMA,pos+0);
      sqrtMA1=iMAOnArray(_wma5,0,8,0,MODE_LWMA,pos+1);
      if (sqrtMA1<sqrtMA0){_hma[pos]=_hma[pos]+1;} else {_hma[pos]=_hma[pos]-1;}         
     }

   for(pos=mediumArray; pos>=0; pos--) 
     {
      sqrtMA0=iMAOnArray(_wma6,0,11,0,MODE_LWMA,pos+0);
      sqrtMA1=iMAOnArray(_wma6,0,11,0,MODE_LWMA,pos+1);
      if (sqrtMA1<sqrtMA0){_hma[pos]=_hma[pos]+1;} else {_hma[pos]=_hma[pos]-1;}         
     }

   for(pos=mediumArray; pos>=0; pos--) 
     {
      fullMA=iMAOnArray(_hma,0,smoothing  ,0,MODE_LWMA,pos);
      halfMA=iMAOnArray(_hma,0,smoothing/2,0,MODE_LWMA,pos);
      Buffer1[pos]=(2*halfMA)-fullMA;

      Buffer2[pos]=iMAOnArray(_hma,0,smoothing/2  ,0,MODE_LWMA,pos);
 

      if(_hma[pos]<0)
        {
         ObjectCreate("myx0"+DoubleToStr(pos,0), OBJ_TEXT, 0, Time[pos], Low[pos]);
         ObjectSetText("myx0"+DoubleToStr(pos,0),DoubleToStr(_hma[pos],0),14,"Arial",Red);
         //ObjectSetText("myx0"+DoubleToStr(pos,0),".",32,"Arial",Red);
        }
      
      if(_hma[pos]>0)
        {
         ObjectCreate("myx0"+DoubleToStr(pos,0), OBJ_TEXT, 0, Time[pos], High[pos]);
         ObjectSetText("myx0"+DoubleToStr(pos,0),DoubleToStr(_hma[pos],0),14,"Arial",White);
         //ObjectSetText("myx0"+DoubleToStr(pos,0),".",32,"Arial",White);
        }

      // crossover indicators on chart for visual help        
      if(Buffer2[pos]<Buffer1[pos] && Buffer2[pos+1]>Buffer1[pos+1] )
        {
         ObjectCreate("myWW"+DoubleToStr(pos,0), OBJ_TEXT, 0, Time[pos], High[pos]+(8*Point));
         ObjectSetText("myWW"+DoubleToStr(pos,0),"#",14,"Arial",DodgerBlue);
        }
      if(Buffer2[pos]>Buffer1[pos] && Buffer2[pos+1]<Buffer1[pos+1] )
        {
         ObjectCreate("myWW"+DoubleToStr(pos,0), OBJ_TEXT, 0, Time[pos], High[pos]+(8*Point));
         ObjectSetText("myWW"+DoubleToStr(pos,0),"#",14,"Arial",DodgerBlue);
        }
        
        

     }//for

  }//start       