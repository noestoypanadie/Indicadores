//+------------------------------------------------------------------+
//|                                                     MultiWpr.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#property indicator_separate_window
#property indicator_buffers 6

#property indicator_color1 White
#property indicator_color2 Red
#property indicator_color3 LimeGreen
#property indicator_color4 LightBlue
#property indicator_color5 Yellow
#property indicator_color6 Red

extern int Williams_Period = 14;
extern double Williams_Threshold = 50;
extern bool Show_WPR_Lines=True;

#define GPB 0
#define EUR 1
#define CHF 2
#define JPY 3
#define up  4
#define dn  5




#define Gpb "GBPUSD"
#define Eur "EURUSD"
#define Chf "USDCHF"
#define Jpy "USDJPY"


/*
#define Gpb "AUDUSD"
#define Eur "AUDCAD"
#define Chf "USDJPY"
#define Jpy "GBPJPY"
*/


double GPBBuffer[];
double EURBuffer[];
double CHFbuffer[];
double JPYbuffer[];
double upbuffer[];
double dnbuffer[];



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   IndicatorShortName("Multi WPR - ONLY ON MAJORS!!!!");

   IndicatorBuffers(6);

   SetIndexBuffer( GPB, GPBBuffer );
   SetIndexLabel( GPB, Gpb );
   SetIndexStyle( GPB, DRAW_LINE, STYLE_SOLID, 1 );

   SetIndexBuffer( EUR, EURBuffer );
   SetIndexLabel( EUR, Eur );
   SetIndexStyle( EUR, DRAW_LINE, STYLE_SOLID, 1 );

   SetIndexBuffer( CHF, CHFbuffer );
   SetIndexLabel( CHF, Chf );
   SetIndexStyle( CHF, DRAW_LINE, STYLE_SOLID, 1 );

   SetIndexBuffer( JPY, JPYbuffer);
   SetIndexLabel( JPY, Jpy );
   SetIndexStyle( JPY, DRAW_LINE, STYLE_SOLID, 1 );
   
   SetIndexBuffer( up, upbuffer);
   SetIndexStyle( up, DRAW_HISTOGRAM, STYLE_SOLID, 1 );
   
   SetIndexBuffer( dn, dnbuffer);
   SetIndexStyle( dn, DRAW_HISTOGRAM, STYLE_SOLID, 1 );
   
   
   IndicatorDigits( MarketInfo( Symbol() ,MODE_DIGITS ) );
   
   return(0);
}

double WPR( string Currency, int Shift, int & Trig )
{
double Result = iWPR( Currency, Period(), Williams_Period, Shift );

   if( Result < -Williams_Threshold )
  	   Trig = -1;
  	else
      Trig = 1;
      
   return( 50 + Result );
}


int start()
{
static int PrevBars = 0,
           NameC = 0;

   if( Bars > PrevBars )
   {
   int J = 0, 
       I = Bars - PrevBars;

      for( ; I > 0; I--, J++ )
      {
      int GPB_Trig, EUR_Trig, CHF_Trig, JPY_Trig;
      double tempgbp,tempeur,tempchf,tempjpy;
         
         tempgbp = WPR( Gpb, J, GPB_Trig );
         tempeur = WPR( Eur, J, EUR_Trig );
         tempchf = WPR( Chf, J, CHF_Trig );
         tempjpy = WPR( Jpy, J, JPY_Trig );
         
         if (Show_WPR_Lines)
         {
         GPBBuffer[ J ] = tempgbp;
         EURBuffer[ J ] = tempeur;
         CHFbuffer[ J ] = tempchf;
         JPYbuffer[ J ] = tempjpy;
         }
      int Trig = GPB_Trig + EUR_Trig - CHF_Trig - JPY_Trig,
          Bsi;
      
         if( Trig > 2 )
            Bsi = 1;
         else if( Trig < -2 )
            Bsi = -1;
         else
            Bsi = 0;

         if( Symbol() > "USD" )		// Any USD based Currency
            Bsi = -Bsi;

         upbuffer[ J ] = 0;
         dnbuffer[ J ] = 0;
         
         if( Bsi != 0 )
         {
            if( Bsi > 0 )
			   {
               upbuffer[ J ] = 55;
				}
            else
			   {
               dnbuffer[ J ] = -55;
			   }
			   NameC++;
         }			
      }      
      PrevBars = Bars;
   }
	return(0);
}

