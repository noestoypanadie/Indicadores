#property  copyright "Copyright 2005, Alberto Mengozzi - Menalbi"
#property  link "alberto.mengozzi@gmail.com"
#property  show_inputs

extern double Lots=0.1;
extern bool   AccountIsReal = False;
int    var_80 = 0;
int    var_84 = 327142;
extern int    PassWord = 1111;
extern int    ProfileFactor = 2;
extern bool   CloseOpenCycle = False;
extern bool   CloseOpenFriday = False;
extern int    ToHourFriday = 10;
double var_108 = 15;
int    var_116 = 31;
bool   var_120 = False;
double var_124 = 20;
double var_132 = 70;
int    var_140 = -1;
int    var_144 = -1;
int    var_148 = -1;
int    var_152 = -1;
int    var_156 = -1;
int    var_160 = -1;
string var_164 = "0123Patterns";
string var_172 = "Version 3.12";
string var_180 = "";
string var_188 = "DEMO";
string var_196 = "REAL-TIME";
string var_204 = "Copyright © 2005, Alberto Mengozzi";
string var_212 = "alberto.mengozzi@gmail.com";
string var_220 = "http://br.groups.yahoo.com/group/0123PatternsBRA/";
string var_228 = "StrategyBuilder FX, LLC";
int    var_236 = 3;
bool   var_240 = True;
int    var_244 = 0;
int    var_248 = 23;
bool   var_252 = True;
string var_256 = "good.wav";
bool   var_264 = True;
double var_268 = 0;
bool   var_276 = True;
bool   var_280 = True;
double var_284 = 5;
double var_292 = 6;
double var_300 = 20;
double var_308 = 0;
double var_316 = 1;
double var_324 = 0;
double var_332 = 0;
double var_340 = 0;
double var_348 = 0;
double var_356 = 0;
bool   var_364 = True;
int    var_368 = 21;
int    var_372 = 105;
double var_376;
double var_384;
double var_392;
double var_400;
double var_408;
double var_416;
double var_424;
double var_432;

//+------------------------------------------------------------------+

int init()
{
return(0);
}

//+------------------------------------------------------------------+

int deinit()
{
return(0);
}

//+------------------------------------------------------------------+

int start()
{
int    var_start_0;
double var_start_4;
double var_start_12;
double var_start_20;
double var_start_28;
double var_start_36;
double var_start_44;
double var_start_52;
double var_start_60;
double var_start_68;
double var_start_76;
double var_start_84;
int    var_start_92;
int    var_start_96;
int    var_start_100;
int    var_start_104;
int    var_start_108;
int    var_start_112;
double var_start_116;
double var_start_124;
double arr_start_132[];
int    var_start_136;
int    var_start_140;
int    var_start_144;
double var_start_148;
double var_start_156;
double var_start_164;
int    var_start_172;
int    var_start_176;
bool   var_start_180;
bool   var_start_184;
double var_start_188;
/*[
if (!AccountIsReal)
   {
   if (var_84 != AccountNumber())
      {
      Alert("ERROR: Operações na conta: " + AccountNumber() + "","\n","NÃO ESTÃO HABILITADAS!","\n","Tecle F7 e insira o número correto.");
      return(0);
      }
   if (!IsDemo())
      {
      Alert("ERROR: Este TS ",var_164," não está habilitado ","\n","para a conta REAL: " + AccountNumber() + "","\n","Informações: " + var_212 + "");
      return(0);
      }
   var_180 = var_188;
   }

if (AccountIsReal)
   {
   if (var_80 != AccountNumber())
      {
      Alert("ERROR: Operações na conta: " + AccountNumber() + "","\n","NÃO ESTÃO HABILITADAS!","\n","Tecle F7 e insira o número correto.");
      return(0);
      }
   if (IsDemo())
      {
      Alert("ERROR: Este TS ",var_164," não está habilitado ","\n","para a conta DEMO: " + AccountNumber() + "","\n","Informações: " + var_212 + "");
      return(0);
      }
   var_180 = var_196;
   }

if (PassWord != 1011)
   {
   Alert("ERROR: Você não inseriu o PASSWORD correto!!!","\n","Solicite-o no Grupo Yahoo! - ",var_220,"","\n","ou pelo e-mail - ",var_212,"");
   return(0);
   }

if (var_228 != AccountCompany())
   {
   Alert("ERROR: Este TS ",var_164," só trabalha com ","\n","",var_228,".");
   return(0);
   }

if (var_120)
   {
   if (ProfileFactor == 1923)
      {
      var_392 = 1.0;
      if (MathAbs(CurTime() - var_332) > var_316 * 43200.0)
         {
         var_332 = CurTime();
         Alert("ATENÇÃO: ProfileFactor = 1923 \n Voce pode PERDER ate \n 80% do SALDO INICIAL.\n Voce esta operando no \n ProfileFactor SUPER-AGRESSIVO!!!","\n","Tenha em mente que ele e \n TREMENDAMENTE ARRISCADO!!!");
         }
      }
   }

if (ProfileFactor == 0)
   {
   if (MathAbs(CurTime() - var_332) > var_316 * 86400.0)
      {
      var_332 = CurTime();
      Alert("ATENÇÃO: ProfileFactor = 0\n Você está operando no ProfileFactor AGRESSIVO!!!","\n","Tenha em mente que ele é muito ARRISCADO!!!");
      }
   }

if (Period() != 240)
   {
   Alert("ERROR: O TS ",var_164," está habilitado somente para gráficos de 4 HORAS.");
   return(0);
   }

if (var_264)
   {
   var_start_0 = var_116 - DayOfYear();
   if ((var_start_0 <= 5) && (var_start_0 > 0))
      {
      if (MathAbs(CurTime() - var_324) > var_316 * var_start_0 * 3600.0)
         {
         var_324 = CurTime();
         Alert("ATENÇÃO: Falta(m) ",var_start_0," dia(s)","\n"," para encerrar o TS ",var_164,".");
         }
      }
   if (var_start_0 == 0)
      {
      if (MathAbs(CurTime() - var_324) > var_316 * 900.0)
         {
         var_324 = CurTime();
         Alert("ATENÇÃO: O seu TS ",var_164," EXPIRA HOJE.");
         }
      }
   if (var_start_0 < 0)
      {
      if (!ExistPositions())
         {
         Comment("ATENÇÃO!!!\n O TS " + var_164 + " - " + var_172 + " - " + var_180 + " - EXPIROU!!!!!");
         return(0);
         }
      if (ExistPositions())
         {
         if (MathAbs(CurTime() - var_324) > var_316 * 600.0)
            {
            var_324 = CurTime();
            Alert("ATENÇÃO: \n O TS " + var_164 + " - " + var_172 + " - " + var_180 + " - EXPIROU!!!!! \n Agora encerrando todas as operações \n para que possa REMOVER \n O TS " + var_164 + " - " + var_172 + " - " + var_180 + ".");
            }
         }
      }
   }

if (Symbol() != "EURUSD")
   {
   if (Symbol() != "EURUSDm")
      {
      Alert("ERROR: O TS ",var_164," está habilitado\n somente para as paridades EURUSD ou EURUSDm!!!");
      return(0);
      }
   }
]*/
if (!(((((var_108 == 1000) || (var_108 == 10)) || (var_108 == 15)) || (var_108 == 20)) || (var_108 == 25)))
   {
   Alert("ERROR: INVÁLIDO o valor do TakeProfit que você escolheu.","\n","Valores VÁLIDOS (10, 15, 20, 25 ou 1000).","\n","Aperte a tecla F7 e coloque um dos três valores citados acima.");
   return(0);
   }

if (ProfileFactor == 0) var_392 = 0.7;
if (ProfileFactor == 1) var_392 = 0.5;
if (ProfileFactor == 2) var_392 = 0.3;
if (ProfileFactor == 3) var_392 = 0.2;

if (!(((((ProfileFactor == 1923) || (ProfileFactor == 0)) || (ProfileFactor == 1)) || (ProfileFactor == 2)) || (ProfileFactor == 3)))
   {
   Alert("ERROR: Valores VÁLIDOS para o PROFILEFACTOR:","\n","(Agressivo = 0; Moderado = 1; Conservador = 2; Super-Conservador = 3)");
   return(0);
   }

if (AccountLeverage() == 100) var_400 = 0.003;
if (AccountLeverage() == 200) var_400 = 0.05;
if (!(AccountLeverage() == 200))
   {
   Alert("ERROR: Leverage VÁLIDA, somente 1:200 Conta Mini");
   return(0);
   }

if (Bars < 200)
   {
   Alert("ERROR: Número de barras menor que 200");
   return(0);
   }

if (MathAbs(CurTime() - var_356) > var_316 * 900.0)
   {
   var_356 = CurTime();
   RefreshRates();
   Print("ATENÇÃO: Fiz um RefreshRates() na conta.");
   }

if (CloseOpenCycle)
   {
   if (!ExistPositions())
      {
      Comment("ATENÇÃO!!!\n Fechamos todas as operações.\n Você já pode desligar o TS.\n E se quiser, também fechar a plataforma MT4.\n Para continuar operando, mude o \n CloseOpenCycle para False.");
      return(0);
      }
   if (ExistPositions())
      {
      if (MathAbs(CurTime() - var_340) > var_316 * 3600.0)
         {
         var_340 = CurTime();
         Alert("ATENÇÃO: \n Encerrando todas as operações \n para que possa desligar \n o TS e fechar a plataforma.");
         }
      }
   }

if (CloseOpenFriday && (DayOfWeek() == 5) && (Hour() >= ToHourFriday))
   {
   if (!ExistPositions())
      {
      Comment("ATENÇÃO!!!\n Fechamos todas as operações.\n Você já pode desligar o TS.\n E se quiser, também fechar a plataforma MT4.\n Bom final de semana!!!");
      return(0);
      }
   if (ExistPositions())
      {
      if (MathAbs(CurTime() - var_348) > var_316 * 3600.0)
         {
         var_348 = CurTime();
         Alert("ATENÇÃO: \n Encerrando todas as operações \n para que possa desligar \n o TS e fechar a plataforma \n no final de semana.");
         }
      }
   }

if (!AccountIsReal)
   {
   if (!ExistPositions())
      {
      var_376 = MathRound(AccountEquity());
      var_384 = MathRound(AccountBalance());
      var_376 = var_376;
      var_416 = FileOpen("initialdata.dat",FILE_BIN|FILE_WRITE);
      if (var_416 < 1.0)
         {
         Comment("can't open file error-",GetLastError());
         return(0);
         }
      FileWriteDouble(var_416,var_376,8);
      FileClose(var_416);
      }
   if (ExistPositions())
      {
      var_416 = FileOpen("initialdata.dat",FILE_BIN);
      if (var_416 > 0.0)
         {
         var_376 = FileReadDouble(var_416,8);
         FileClose(var_416);
         }
      }
   }

if (AccountIsReal)
   {
   if (!ExistPositions())
      {
      var_376 = MathRound(AccountEquity());
      var_384 = MathRound(AccountBalance());
      var_376 = var_376;
      var_416 = FileOpen("initialdatareal.dat",FILE_BIN|FILE_WRITE);
      if (var_416 < 1.0)
         {
         Comment("can't open file error-",GetLastError());
         return(0);
         }
      FileWriteDouble(var_416,var_376,8);
      FileClose(var_416);
      }
   if (ExistPositions())
      {
      var_416 = FileOpen("initialdatareal.dat",FILE_BIN);
      if (var_416 > 0.0)
         {
         var_376 = FileReadDouble(var_416,8);
         FileClose(var_416);
         }
      }
   }

//var_408 = NormalizeDouble(var_376 * 0.01 * var_400 * var_392,2);
var_start_4 = (Ask - Bid) / Point;
if (iClose(NULL,PERIOD_M5,0) >= iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,0))
   var_start_12 = MathRound((iHigh(NULL,PERIOD_M5,0) - iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,0)) / Point);
      else
   var_start_12 = MathRound((iLow(NULL,PERIOD_M5,0) - iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,0)) / Point);

if (iClose(NULL,PERIOD_M5,1) >= iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,1))
   var_start_20 = MathRound((iHigh(NULL,PERIOD_M5,1) - iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,1)) / Point);
      else
   var_start_20 = MathRound((iLow(NULL,PERIOD_M5,1) - iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,1)) / Point);

if (iClose(NULL,PERIOD_M5,2) >= iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,2))
   var_start_28 = MathRound((iHigh(NULL,PERIOD_M5,2) - iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,2)) / Point);
      else
   var_start_28 = MathRound((iLow(NULL,PERIOD_M5,2) - iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,2)) / Point);

if (iClose(NULL,PERIOD_M5,3) >= iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,3))
   var_start_36 = MathRound((iHigh(NULL,PERIOD_M5,3) - iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,3)) / Point);
      else
   var_start_36 = MathRound((iLow(NULL,PERIOD_M5,3) - iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,3)) / Point);

if (iClose(NULL,PERIOD_M5,4) >= iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,4))
   var_start_44 = MathRound((iHigh(NULL,PERIOD_M5,4) - iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,4)) / Point);
      else
   var_start_44 = MathRound((iLow(NULL,PERIOD_M5,4) - iMA(NULL,PERIOD_M5,var_368,0,MODE_EMA,PRICE_CLOSE,4)) / Point);

if (iClose(NULL,PERIOD_M5,0) >= iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,0))
   var_start_52 = MathRound((iHigh(NULL,PERIOD_M5,0) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,0)) / Point);
      else
   var_start_52 = MathRound((iLow(NULL,PERIOD_M5,0) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,0)) / Point);

if (iClose(NULL,PERIOD_M5,1) >= iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,1))
   var_start_60 = MathRound((iHigh(NULL,PERIOD_M5,1) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,1)) / Point);
      else
   var_start_60 = MathRound((iLow(NULL,PERIOD_M5,1) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,1)) / Point);

if (iClose(NULL,PERIOD_M5,2) >= iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,2))
   var_start_68 = MathRound((iHigh(NULL,PERIOD_M5,2) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,2)) / Point);
      else
   var_start_68 = MathRound((iLow(NULL,PERIOD_M5,2) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,2)) / Point);

if (iClose(NULL,PERIOD_M5,3) >= iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,3))
   var_start_76 = MathRound((iHigh(NULL,PERIOD_M5,3) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,3)) / Point);
      else
   var_start_76 = MathRound((iLow(NULL,PERIOD_M5,3) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,3)) / Point);

if (iClose(NULL,PERIOD_M5,4) >= iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,4))
   var_start_84 = MathRound((iHigh(NULL,PERIOD_M5,4) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,4)) / Point);
      else
   var_start_84 = MathRound((iLow(NULL,PERIOD_M5,4) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,4)) / Point);

var_start_136 = IndicatorCounted();
var_start_140 = 1;
for (var_start_92 = 300; var_start_92 >= 0; var_start_92--)
   {
   if (iClose(NULL,PERIOD_M5,var_start_92) >= iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,var_start_92))
      arr_start_132[var_start_92] = MathRound((iHigh(NULL,PERIOD_M5,var_start_92) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,var_start_92)) / Point);
         else
      arr_start_132[var_start_92] = MathRound((iLow(NULL,PERIOD_M5,var_start_92) - iMA(NULL,PERIOD_M5,var_372,0,MODE_EMA,PRICE_CLOSE,var_start_92)) / Point);
   }

var_start_144 = Bars - 50;
var_start_148 = MathAbs(var_start_52);
for (var_start_92 = 0; var_start_92 < OrdersTotal(); var_start_92++)
   {
   if (OrderSelect(var_start_92,SELECT_BY_POS))
      {
      if (OrderSymbol() == Symbol()) var_start_164 = var_start_164 + OrderProfit();
      }
   }

if (AccountLeverage() == 100) var_start_176 = NormalizeDouble(var_300 * Lots * 10.0,0);
if (AccountLeverage() == 200) var_start_176 = NormalizeDouble(var_300 * Lots,0);
var_start_172 = var_376 + var_start_176 + var_236;

if (AccountEquity() > var_start_172)
   {
   CloseOpenOrders();
   CloseAllPendingOrders();
   if (var_252) PlaySound(var_256);
   return(0);
   }

if (MathAbs(CurTime() - var_308) > var_316 * 20.0)
   {
   var_308 = CurTime();
   var_start_116 = (Ask + Point * var_284 / 2) / Point / var_284;
   var_start_100 = var_start_116;
   var_start_100 = var_start_100 * var_284;
   var_start_116 = var_start_100 * Point - var_284 * var_292 / 2 * Point;
   var_start_180 = 0;
   var_start_184 = 0;
   if (((var_start_52 >= var_124) && (var_start_52 <= var_132)) || (var_start_52 <= -var_132)) var_start_180 = 1;
   if (((var_start_52 <= -var_124) && (var_start_52 >= -var_132)) || (var_start_52 >= var_132)) var_start_184 = 1;
   var_424 = iHigh(NULL,PERIOD_M5,0) + (MathRound(var_284 * var_292 / 2) + var_284) * Point;
   var_432 = iLow(NULL,PERIOD_M5,0) - (MathRound(var_284 * var_292 / 2) + var_284) * Point;
   if (ExistPositions()) CloseOrdersfromEXTREME();
   for (var_start_92 = 0; var_start_92 < var_292; var_start_92++)
      {
      var_start_124 = var_start_116 + var_start_92 * Point * var_284;
      if (var_start_180)
         {
         if (IsPosition(var_start_124,Point * var_284,1) == 0)
            {
            var_start_188 = 0;
            if (var_268 > 0.0) var_start_188 = var_start_124 - Point * var_268;
            if (var_start_124 > Ask) var_start_108 = 4; else var_start_108 = 2;
            if (((var_start_124 > Ask) && var_276) || ((var_start_124 <= Ask) && var_280))
               {
               var_start_104 = OrderSend(Symbol(),var_start_108,Lots,var_start_124,0,var_start_188,var_start_124 + Point * var_108,var_164,23112005,0,var_140);
               }
            }
         }
      if (var_start_184)
         {
         if (IsPosition(var_start_124,Point * var_284,0) == 0)
            {
            var_start_188 = 0;
            if (var_268 > 0.0) var_start_188 = var_start_124 + Point * var_268;
            if (var_start_124 > Bid) var_start_108 = 3; else var_start_108 = 5;
            if (((var_start_124 < Bid) && var_276) || ((var_start_124 >= Bid) && var_280))
               {
               var_start_104 = OrderSend(Symbol(),var_start_108,Lots,var_start_124,0,var_start_188,var_start_124 - Point * var_108,var_164,23112005,0,var_148);
               }
            }
         }
      }
   }
Comment("",var_204," - ",var_212,"    -    ",var_164," - ",var_172," - " + var_180 + "\n","Grupo Yahoo! - ",var_220,"\n","Saldo inicial = ",var_376,"\n","Saldo projetado = ",var_start_172,"\n","Lotes em negociacao = ",Lots);
return(0);
}

//+------------------------------------------------------------------+

bool IsPosition(double inp_IsPosition_0, double inp_IsPosition_8, int inp_IsPosition_16)
{
int ordtotal;
int cnt;
int ordtype;

ordtotal = OrdersTotal();
for (cnt = 0; cnt < ordtotal; cnt++)
   {
   OrderSelect(cnt,SELECT_BY_POS);
   if ((OrderSymbol() == Symbol()) && ((OrderMagicNumber() == 23112005) || (OrderComment() == var_164)))
      {
      ordtype = OrderType();
      if (MathAbs(OrderOpenPrice() - inp_IsPosition_0) < inp_IsPosition_8 * 0.9)
         {
         if ((inp_IsPosition_16 && (((ordtype == OP_BUY) || (ordtype == OP_BUYLIMIT)) || (ordtype == OP_BUYSTOP))) || (!inp_IsPosition_16 && (((ordtype == OP_SELL) || (ordtype == OP_SELLLIMIT)) || (ordtype == OP_SELLSTOP)))) return(True);
         }
      }
   }
return(False);
}
//+------------------------------------------------------------------+

bool ExistPositions()
{
int cnt;

for (cnt = 0; cnt < OrdersTotal(); cnt++)
   {
   if (OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
      {
      if ((OrderSymbol() == Symbol()) && (OrderMagicNumber() == 23112005)) return(True);
      }
   }
return(False);
}

//+------------------------------------------------------------------+

void CloseAllPendingOrders()
{
int ordtotal;
int cnt;
int ordtype;
int result;

ordtotal = OrdersTotal();
for (cnt = ordtotal - 1; cnt >= 0; cnt--)
   {
   OrderSelect(cnt,SELECT_BY_POS);
   if ((OrderSymbol() == Symbol()) && ((OrderMagicNumber() == 23112005) || (OrderComment() == var_164)))
      {
      ordtype = OrderType();
      if (ordtype > OP_SELL) result = OrderDelete(OrderTicket());
      }
   }
return;
}

//+------------------------------------------------------------------+

void CloseOpenOrders()
{
int ordtotal;
int cnt;
int ordtype;
int result;

ordtotal = OrdersTotal();
for (cnt = ordtotal - 1; cnt >= 0; cnt--)
   {
   OrderSelect(cnt,SELECT_BY_POS);
   ordtype = OrderType();
   result = 0;
   if ((OrderSymbol() == Symbol()) && ((OrderMagicNumber() == 23112005) || (OrderComment() == var_164)))
      {
      if (ordtype == OP_BUY)  result = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),5,var_144);
      if (ordtype == OP_SELL) result = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),5,var_152);
      if (ordtype > OP_SELL)  result = OrderDelete(OrderTicket());
      }
   }
return;
}

//+------------------------------------------------------------------+

void CloseOrdersfromEXTREME()
{
int ordtotal;
int cnt;
int ordtype;
int result;

ordtotal = OrdersTotal();
for (cnt = ordtotal - 1; cnt >= 0; cnt--)
   {
   OrderSelect(cnt,SELECT_BY_POS);
   if ((OrderSymbol() == Symbol()) && ((OrderMagicNumber() == 23112005) || (OrderComment() == var_164)))
      {
      ordtype = OrderType();
      result = 0;
      if ((ordtype == OP_BUYLIMIT)  && (OrderOpenPrice() <= var_432)) result = OrderDelete(OrderTicket());
      if ((ordtype == OP_BUYSTOP)   && (OrderOpenPrice() >= var_424)) result = OrderDelete(OrderTicket());
      if ((ordtype == OP_SELLLIMIT) && (OrderOpenPrice() >= var_424)) result = OrderDelete(OrderTicket());
      if ((ordtype == OP_SELLSTOP)  && (OrderOpenPrice() <= var_432)) result = OrderDelete(OrderTicket());
      }
   }
return;
}