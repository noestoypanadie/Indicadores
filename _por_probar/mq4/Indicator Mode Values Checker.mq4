//+------------------------------------------------------------------+
//|                                Indicator Mode Values Checker.mq4 |
//|      Copyright © 2006 , David W or Renee A Honeywell , 9/17/2006 |
//|                                        transport.david@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006 , David W or Renee A Honeywell , 9/17/2006"
#property link      "transport.david@gmail.com"

// indicator extern int 's

// Solar_Wind
extern int period=10;

// Triggerlines
extern int Rperiod = 15;
extern int LSMA_Period = 5;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   Comment("");
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   
   // Solar_Wind uses 3 buffers
   double ind1_mode0 = iCustom( Symbol(), 0, "Solar_Wind", period, 0, 0)*1000; // make sure the icustom string name is exact "Solar_Wind"
   double ind1_mode1 = iCustom( Symbol(), 0, "Solar_Wind", period, 1, 0)*1000;
   double ind1_mode2 = iCustom( Symbol(), 0, "Solar_Wind", period, 2, 0)*1000;
   double ind1_mode3 = 0;
   double ind1_mode4 = 0;
   double ind1_mode5 = 0;
   double ind1_mode6 = 0;
   double ind1_mode7 = 0;
   
   // Triggerlines uses 4 buffers
   double ind2_mode0 = iCustom( Symbol(), 0, "Triggerlines", Rperiod, LSMA_Period, 0, 0)*1000; // make sure the icustom string name is exact "Triggerlines"
   double ind2_mode1 = iCustom( Symbol(), 0, "Triggerlines", Rperiod, LSMA_Period, 1, 0)*1000;
   double ind2_mode2 = iCustom( Symbol(), 0, "Triggerlines", Rperiod, LSMA_Period, 2, 0)*1000;
   double ind2_mode3 = iCustom( Symbol(), 0, "Triggerlines", Rperiod, LSMA_Period, 3, 0)*1000;
   double ind2_mode4 = 0;
   double ind2_mode5 = 0;
   double ind2_mode6 = 0;
   double ind2_mode7 = 0;
   
   
   
   Comment("\n",
           "\n","  Solar_Wind * 1000 =  ind1_mode0:  ",ind1_mode0,"  ,  ind1_mode1:  ",ind1_mode1,"  ,  ind1_mode2:  ",ind1_mode2,
           "\n",
           "\n","  Triggerlines * 1000 =  ind2_mode0:  ",ind2_mode0,"  ,  ind2_mode1:  ",ind2_mode1,"  ,  ind2_mode2:  ",ind2_mode2,"  ,  ind2_mode3:  ",ind2_mode3);
   
   
   
   
//----
   return(0);
  }
//+------------------------------------------------------------------+