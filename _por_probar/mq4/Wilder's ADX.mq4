//+------------------------------------------------------------------+

//|                                                          DMI.mq4 |

//|                                Copyright © 2006, Fernando Gomes. |

//|                                    http://www.ciavox.com/~fgomes |

//+------------------------------------------------------------------+

#property copyright "Copyright © 2006, Fernando Gomes."

#property link      "http://www.ciavox.com/~fgomes"



//---- indicator settings

#property  indicator_separate_window

#property  indicator_buffers 5

#property  indicator_color1  Lime

#property  indicator_color2  Red

#property  indicator_color3  Yellow

#property  indicator_color4  DeepSkyBlue

#property  indicator_color5  Blue



#property  indicator_minimum 0

#property  indicator_level1  20

#property  indicator_level2  25

#property  indicator_maximum 60



//---- indicator parameters

extern int Smooth   = 13;

extern bool Hide_DI_Plus  = False;

extern bool Hide_DI_Minus = False;

extern bool Hide_DX   = False;

extern bool Hide_ADX  = False;

extern bool Hide_ADXR = False;



//---- indicator buffers

double b_di_p[];     // buffer +DI

double b_di_m[];     // buffer -DI

double b_dmi[];      // buffer DMI

double b_adx[];      // buffer Average Directional indeX

double b_adxr[];     // buffer Average Directional indeX Rate



//---- non-indicator buffers

//---- NOTICE that these arrays must be included in ArraySetAsSeries()

double dm_p_avg[];

double dm_m_avg[];

double tr_avg[];





//+------------------------------------------------------------------+

//| Custom indicator initialization function                         |

//+------------------------------------------------------------------+

int init() {

   //---- indicator buffers mapping

   IndicatorBuffers(8);

   if (   !SetIndexBuffer(0,b_di_p)

       && !SetIndexBuffer(1,b_di_m)

       && !SetIndexBuffer(2,b_dmi)

       && !SetIndexBuffer(3,b_adx)

       && !SetIndexBuffer(4,b_adxr)

       && !SetIndexBuffer(5,dm_p_avg)

       && !SetIndexBuffer(6,dm_m_avg)

       && !SetIndexBuffer(7,tr_avg)

      ) { Print("cannot set indicator buffers!"); return(-1); }

   //---- name for DataWindow and indicator subwindow label

   IndicatorShortName("DMI("+Smooth+")");

   SetIndexLabel(0,"+DI");

   SetIndexLabel(1,"-DI");

   SetIndexLabel(2,"DX");

   SetIndexLabel(3,"ADX");

   SetIndexLabel(4,"ADXR");

   //----

   SetIndexStyle(0, DRAW_LINE+Hide_DI_Plus*DRAW_NONE, STYLE_SOLID, 1,
indicator_color1);

   SetIndexStyle(1, DRAW_LINE+Hide_DI_Minus*DRAW_NONE, STYLE_SOLID, 1,
indicator_color2);

   SetIndexStyle(2, DRAW_LINE+Hide_DX*DRAW_NONE, STYLE_SOLID, 1,
indicator_color3);

   SetIndexStyle(3, DRAW_LINE+Hide_ADX*DRAW_NONE, STYLE_SOLID, 1,
indicator_color4);

   SetIndexStyle(4, DRAW_LINE+Hide_ADXR*DRAW_NONE, STYLE_SOLID, 1,
indicator_color5);

  

   //----

   SetIndexDrawBegin(0,Smooth);

   SetIndexDrawBegin(1,Smooth);

   SetIndexDrawBegin(2,Smooth);

   SetIndexDrawBegin(3,2*Smooth);

   SetIndexDrawBegin(4,3*Smooth);

  

   return(0);

}

//+------------------------------------------------------------------+

//| Custor indicator deinitialization function                       |

//+------------------------------------------------------------------+

int deinit() {

   return(0);

}



//+------------------------------------------------------------------+

//| Custom indicator iteration function                              |

//+------------------------------------------------------------------+

int start() {

  int counted_bars=IndicatorCounted();

  if (counted_bars<0) return(-1);

  if (Bars < 2) return(-1);

  if (Smooth < 2) return(-1);

  int limit=Bars-1-counted_bars;

 

  double smooth = 1.0 / (Smooth * 1.0);



  int firstDMI  = Bars-1-Smooth;

  int firstADX  = Bars-1-(2*Smooth);

  int firstADXR = Bars-1-(3*Smooth);

 

  for (int i=limit; i>=0; i--) {

    double high;

    double low;

    double dm_p;

    double dm_m;

   

    if (i<firstDMI) {

      high = High[i]  - High[i+1];

      low  = Low[i+1] - Low[i];

      dm_p = 0.0;

      dm_m = 0.0;

      if ((high > low) && (high > 0.0))

        dm_p = high;

      else if ((low > high) && (low > 0.0))

        dm_m = low;

      // calculate averages (cumulative formula)

      dm_p_avg[i] = dm_p_avg[i+1] - ( smooth * dm_p_avg[i+1] ) + dm_p;

      dm_m_avg[i] = dm_m_avg[i+1] - ( smooth * dm_m_avg[i+1] ) + dm_m;

      tr_avg[i]   = tr_avg[i+1]   - ( smooth * tr_avg[i+1] )   +
calcTR(i);

    } else if (i==firstDMI) {

      double sum_dm_p = 0.0;

      double sum_dm_m = 0.0;

      double sum_tr   = 0.0;

      for (int j=i; j<i+Smooth; j++) {

        high = High[j]  - High[j+1];

        low  = Low[j+1] - Low[j];

        dm_p = 0.0 ;

        dm_m = 0.0 ;

        if ((high > low) && (high > 0.0))

          dm_p = high;

        else if ((low > high) && (low > 0.0))

          dm_m = low;

        sum_dm_p = sum_dm_p + dm_p;

        sum_dm_m = sum_dm_m + dm_m;

        sum_tr   = sum_tr   + calcTR(j);

      }

      // define current values

      dm_p_avg[i] = sum_dm_p * smooth;

      dm_m_avg[i] = sum_dm_m * smooth;

      tr_avg[i]   = sum_tr   * smooth;

    } else {

      tr_avg[i] = 0.0;

    }



    // Calculate +DI and -DI

    if (tr_avg[i] > 0.0) {

      b_di_p[i] = 100.0 * dm_p_avg[i] / tr_avg[i];

      b_di_m[i] = 100.0 * dm_m_avg[i] / tr_avg[i];

    } else {

      b_di_p[i] = 0.0;

      b_di_m[i] = 0.0;

    }



    // calcule DMI

    double sum  = b_di_p[i] + b_di_m[i];

    double diff = MathAbs( b_di_p[i] - b_di_m[i] );

    if (sum > 0.0) {

        b_dmi[i] = 100.0 *  diff / sum;

    } else {

        b_dmi[i] = 0.0 ;

    }



    // Calculate ADX

    if (i<firstADX) {  

      b_adx[i] = smooth*(b_adx[i+1]*(Smooth-1) + b_dmi[i]);

    } else if (i==firstADX) {

      double sum_dmi = 0.0;

      for (int k=i+Smooth+1; k>i; k--) {

        sum_dmi = sum_dmi + b_dmi[k];

      }

      b_adx[i] = smooth * sum_dmi;

    } else {

      b_adx[i] = 0.0;

    }

   

    // Calculate ADXR

    if (i<=firstADXR) {  

      b_adxr[i] = (b_adx[i] + b_adx[i+Smooth]) / 2;

    } else {

      b_adxr[i] = 0.0;

    }

   

  } // for



  return(0);

}



double calcTR(int bar) {

  double a = High[bar] - Low[bar];              // A = Today's High -Today's Low

  double b = MathAbs(Close[bar+1] - High[bar]); // B = Yesterday's Close - Today's High

  double c = MathAbs(Close[bar+1] - Low[bar]);  // C = Yesterday's Close - Today's Low

  return(MathMax(MathMax(a,b),c));

}



//+------------------------------------------------------------------+