//+------------------------------------------------------------------+
//|                                           Send_Pending_Order.mq4 |
//|                                                        komposter |
//|                                      mailto:komposterius@mail.ru |
//+------------------------------------------------------------------+
#property copyright "komposter"
#property link      "mailto:komposterius@mail.ru"
/*
-----------------------------�-�-�-�-�-�-�-�---------------------------------
����� �������� ������� ������������ ���������� ������� ��������� �����������:

������ ������������ ��� ��������� ����������� ������.
��� ����� ����������:
 1) ������������ � ������ ������������ =), !���������� �������� �� ���������! (��������� ��� ���������,
 	 ���������� � ������������� ������� //+----------------------------------------------+ ),
 	 ��������� ������ ������� ��������� ����� ����
 	 "������" -> "���������" -> "���������" -> "��������� �������������� ������� ���������"
 	 (���������� ��� �������� ������, ������� ����� ���������� ��� ��������� ������)
 2) ���������� ������ �� ������. ��� ���� ���������, ��� ����� ������������ - ��� �������
 	 ���� �������� (OpenPrice). � �������� ��������� � ����� ����� ������, �� ��� ���������
 	 ������ ���������� ������������� ������ ����� �� ������ �������.
 3) ����������� ��� ����� �� ����������� ������:
		- Open_Price_Line (�� ��������� - �����) - ���� ��������  (������������ �����)
		- Stop_Loss_Line (�������) - ������� ���� ���� (������������)
		- Take_Profit_Line (������) - ������� ���� ������ (��������������)
		- Expiration_Line (�����) - ����� ��������� (��������������)
		(�������������� ����� ����� �������)
		- "````" - ������ �������. ���������� ���������� �������� ������� �������� (�� 0,1 �� 10 �����)
	� ����������� �� ������������ ����� Open_Price � Stop_Loss ���������� ��� ������:
	Open_Price  >  Bid � Open_Price  >  Stop_Loss  -  BUYSTOP-�����,
	Open_Price  >  Bid � Open_Price  <  Stop_Loss  -  SELLLIMIT-�����,
	Open_Price  <  Ask � Open_Price  >  Stop_Loss  -  BUYLIMIT-�����,
	Open_Price  <  Ask � Open_Price  <  Stop_Loss  -  SELLSTOP-�����.
 4) ����� �� ����� ������, � ����������� ���� ������ ������ "��".
 
 
 ��� ����������� ������ ������� � ����� ������ ����� ��������������� ������� "������".
 ���� ���� ����� ������� ������ � ����, ��� � ������ ������ �������, ������� �������� �� komposterius@mail.ru
*/
//+------------------------------------------------------------------+
// ��� ������������� ���������� ����� ����� �������� � ���� ������� �������,
// ������� ��������� ��� ������������. ��� �������, ��������, ��� ������������� �������
// ���������������� � ������ "Lots" ������ �������. ��� �����, ������� ������ ����� � ���� ������� (��������, 1.5),
// �� �������� ��������� ������� ���� ( "````" ).
// ���� ���� ������� �� �����, ���� ���������������� ��������� ������ (��������� � ������ //)
#property show_inputs


// ��� ������ �� ��������� (������ �� ��������� ������������ ����� ����-���� � ����-������)
extern int _OrderType = 1; //( "1" - BUYSTOP ��� BUYLIMIT, "-1" - SELLSTOP ��� SELLLIMIT )

// ����� ������ �� ��������� (����� ������ � �������� ������)
// �� 0.1 �� 1.0 � ����� 0.1, �� 1 �� 10 � ����� 1
extern double Lots = 0.1;

// ���������� ����� ������ Take_Profit/Stop_Loss � ������ Open_Price � ������� �� ���������.
// ���� Take_Profit �������������� �� �����, ���������� 0
extern int Stop_Loss = 50;
extern int Take_Profit = 50;

// ������������ ���������� �� ����������� ����
extern int Slippage = 5;

// ����������� � ������
extern string _Comment = "Opened by script";

// Order ID
extern int MagicNumber = 0;

// ����� ��������� ������, ���������� � ������
// ��� ������� ������� H4 � Expiration_Shift = 3 ����� ��������� �������� ����� 12 ����� ����� ���������
// ���� ���������� ����������� ����� ��������� ��� ���� �������� �������, ������� "0" (��� �������), � ���������� � ��������� ���������
// ���� ����� ��������� ������ �������������� �� �����, ���������� 0
extern int Expiration_Shift = 0;
// ����� ��������� ������, ���������� � �����
// ��� ����, ���� ������������ ��� ���������, ���������� ���������� Expiration_Shift (��. ���� �� 2 ������) "0" (��� �������)
// ���� ����� ��������� ������ �������������� �� �����, ���������� 0
extern int Expiration_Shift_H = 0;

extern string Order_Color = "----------------------------------------------------------------------------------------";
// ����� ����������� ������� �� �������
extern color Buy_Color = Lime; //( ��� ������� BUYSTOP � BUYLIMIT )
extern color Sell_Color = Red; //( ��� ������� SELLLIMIT � SELLSTOP )

extern string Line_Color = "----------------------------------------------------------------------------------------";
// ����� �����:
extern color Open_Price_Line_Color = White;
extern color Stop_Loss_Line_Color = Red;
extern color Take_Profit_Line_Color = Lime;
extern color Expiration_Line_Color = Yellow;

//+------------------------------------------------------------------+

#include <stdlib.mqh>
int first = 1;
int start()
{
// ��������� ��������� ��������:
double Open_Price_Level, Stop_Loss_Level, Take_Profit_Level;
datetime Expiration_Time;
// ---Open_Price_Level
	Open_Price_Level = PriceOnDropped();
	if ( Open_Price_Level <= 0 )
		{ Open_Price_Level = Bid + MarketInfo( Symbol(), MODE_STOPLEVEL )*Point; }
// ---Stop_Loss_Level
	Stop_Loss_Level = Open_Price_Level - Stop_Loss * Point;
// ---Take_Profit_Level
	if ( Take_Profit > 0 )
	{ Take_Profit_Level = Open_Price_Level + Take_Profit * Point; }

if ( _OrderType == -1 )
{
// ---Open_Price_Level
	Open_Price_Level = PriceOnDropped();
	if ( Open_Price_Level <= 0 )
		{ Open_Price_Level = Ask - MarketInfo( Symbol(), MODE_STOPLEVEL )*Point; }
// ---Stop_Loss_Level
	Stop_Loss_Level = Open_Price_Level + Stop_Loss * Point;
// ---Take_Profit_Level
	if ( Take_Profit > 0 )
	{ Take_Profit_Level = Open_Price_Level - Take_Profit * Point; }
}

// ---Expiration_Time
	if ( Expiration_Shift > 0 )
	{ Expiration_Time = CurTime() + Period()*60*Expiration_Shift; }
	else
	{
		if ( Expiration_Shift_H > 0 )
			{ Expiration_Time = CurTime() + 3600*Expiration_Shift_H; }
	}
// �������� �����:
if ( first == 1 )
{
	ObjectCreate( "Open_Price_Line", OBJ_HLINE, 0, 0, Open_Price_Level, 0, 0, 0, 0 );
	ObjectSet( "Open_Price_Line", OBJPROP_COLOR, Open_Price_Line_Color );
	ObjectSetText( "Open_Price_Line", "Open_Price_Line", 6, "Arial", Open_Price_Line_Color );

	ObjectCreate( "Stop_Loss_Line", OBJ_HLINE, 0, 0, Stop_Loss_Level, 0, 0, 0, 0 );
	ObjectSet( "Stop_Loss_Line", OBJPROP_COLOR, Stop_Loss_Line_Color );
	ObjectSetText( "Stop_Loss_Line", "Stop_Loss_Line", 6, "Arial", Stop_Loss_Line_Color );

	if ( Take_Profit_Level > 0 )
	{
		ObjectCreate( "Take_Profit_Line", OBJ_HLINE, 0, 0, Take_Profit_Level, 0, 0, 0, 0 );
		ObjectSet( "Take_Profit_Line", OBJPROP_COLOR, Take_Profit_Line_Color );
		ObjectSetText( "Take_Profit_Line", "Take_Profit_Line", 6, "Arial", Take_Profit_Line_Color );
	}

	if ( Expiration_Time > 0 )
	{
		ObjectCreate( "Expiration_Line", OBJ_VLINE, 0, Expiration_Time, 0, 0, 0, 0, 0 );
		ObjectSet( "Expiration_Line", OBJPROP_COLOR, Expiration_Line_Color );
		ObjectSetText( "Expiration_Line", "Expiration_Line", 6, "Arial", Expiration_Line_Color );
	}
// �������� "����� ������� ����" � ��������� �� �������� �� ���������
	int Lots_value_y = 30;
	switch ( Lots )
	{
		case 0.2: Lots_value_y = 45; break;
		case 0.3: Lots_value_y = 60; break;
		case 0.4: Lots_value_y = 75; break;
		case 0.5: Lots_value_y = 90; break;
		case 0.6: Lots_value_y = 105; break;
		case 0.7: Lots_value_y = 120; break;
		case 0.8: Lots_value_y = 135; break;
		case 0.9: Lots_value_y = 150; break;
		case 1.0: Lots_value_y = 165; break;
		case 2.0: Lots_value_y = 180; break;
		case 3.0: Lots_value_y = 195; break;
		case 4.0: Lots_value_y = 210; break;
		case 5.0: Lots_value_y = 225; break;
		case 6.0: Lots_value_y = 240; break;
		case 7.0: Lots_value_y = 255; break;
		case 8.0: Lots_value_y = 270; break;
		case 9.0: Lots_value_y = 285; break;
		case 10.0: Lots_value_y = 300; break;
	}
	if ( Lots > 10.0 ) Lots_value_y = 315;
	int Lots_value_y_start_position = Lots_value_y;
	
	ObjectCreate( "Lots", OBJ_LABEL, 0,0,0,0,0,0,0);
	ObjectSet( "Lots", OBJPROP_CORNER, 1);
	ObjectSet( "Lots", OBJPROP_XDISTANCE, 1);
	ObjectSet( "Lots", OBJPROP_YDISTANCE, 10);
	ObjectSetText(  "Lots", "Lots", 10, "Arial", Open_Price_Line_Color);

	ObjectCreate( "Lots_value", OBJ_LABEL, 0,0,0,0,0,0,0);
	ObjectSet( "Lots_value", OBJPROP_CORNER, 1);
	ObjectSet( "Lots_value", OBJPROP_XDISTANCE, 25);
	ObjectSet( "Lots_value", OBJPROP_YDISTANCE, Lots_value_y);
	ObjectSetText(  "Lots_value", "`````", 10, "Arial", Open_Price_Line_Color);

	int y = 25;
	for ( double z = 0.1; z <= 1; z += 0.1 )
	{
		ObjectCreate( DoubleToStr( z, 1 ), OBJ_LABEL, 0,0,0,0,0,0,0);
		ObjectSet( DoubleToStr( z, 1 ), OBJPROP_CORNER, 1);
		ObjectSet( DoubleToStr( z, 1 ), OBJPROP_XDISTANCE, 1);
		ObjectSet( DoubleToStr( z, 1 ), OBJPROP_YDISTANCE, y);
		ObjectSetText(  DoubleToStr( z, 1 ), DoubleToStr( z, 1 ), 10, "Arial", Open_Price_Line_Color);
		y += 15;
	}
	y = 160;
	for ( z = 1; z <= 10; z ++ )
	{
		ObjectCreate( DoubleToStr( z, 1 ), OBJ_LABEL, 0,0,0,0,0,0,0);
		ObjectSet( DoubleToStr( z, 1 ), OBJPROP_CORNER, 1);
		ObjectSet( DoubleToStr( z, 1 ), OBJPROP_XDISTANCE, 1);
		ObjectSet( DoubleToStr( z, 1 ), OBJPROP_YDISTANCE, y);
		ObjectSetText(  DoubleToStr( z, 1 ), DoubleToStr( z, 1 ), 10, "Arial", Open_Price_Line_Color);
		y += 15;
	}
	ObjectCreate( ">", OBJ_LABEL, 0,0,0,0,0,0,0);
	ObjectSet( ">", OBJPROP_CORNER, 1);
	ObjectSet( ">", OBJPROP_XDISTANCE, 1);
	ObjectSet( ">", OBJPROP_YDISTANCE, 310);
	ObjectSetText(  ">", ">10", 10, "Arial", Open_Price_Line_Color);

// ����� ������������
	string Question = "��� ��������� ������ ����������� ����� �� ����������� ������ � ������� \"��\".\n" + 
							"���� ���������� �� ���������, ������� \"������\".";
	int  Answer = MessageBox( Question, "��������� ����������� ������", 0x00000001 | 0x00000040 | 0x00040000 );
	first = 0;
	// ���� ������ ����� ����� "��" ������ - �������
	if ( Answer != 1 ) { deinit(); return(0); }
}

// ��������� �������� � �������� � �����������:

// ������ ����
	Lots_value_y = ObjectGet( "Lots_value", OBJPROP_YDISTANCE );
	if ( Lots_value_y_start_position != Lots_value_y )
	{
		Lots = 0.1;
		if ( Lots_value_y >= 35  && Lots_value_y < 50  ) Lots = 0.2;
		if ( Lots_value_y >= 50  && Lots_value_y < 65  ) Lots = 0.3;
		if ( Lots_value_y >= 65  && Lots_value_y < 80  ) Lots = 0.4;
		if ( Lots_value_y >= 80  && Lots_value_y < 95  ) Lots = 0.5;
		if ( Lots_value_y >= 95  && Lots_value_y < 110 ) Lots = 0.6;
		if ( Lots_value_y >= 110 && Lots_value_y < 125 ) Lots = 0.7;
		if ( Lots_value_y >= 125 && Lots_value_y < 140 ) Lots = 0.8;
		if ( Lots_value_y >= 140 && Lots_value_y < 155 ) Lots = 0.9;
		if ( Lots_value_y >= 155 && Lots_value_y < 170 ) Lots = 1.0;
		if ( Lots_value_y >= 170 && Lots_value_y < 185 ) Lots = 2.0;
		if ( Lots_value_y >= 185 && Lots_value_y < 200 ) Lots = 3.0;
		if ( Lots_value_y >= 200 && Lots_value_y < 215 ) Lots = 4.0;
		if ( Lots_value_y >= 215 && Lots_value_y < 230 ) Lots = 5.0;
		if ( Lots_value_y >= 230 && Lots_value_y < 245 ) Lots = 6.0;
		if ( Lots_value_y >= 245 && Lots_value_y < 260 ) Lots = 7.0;
		if ( Lots_value_y >= 260 && Lots_value_y < 275 ) Lots = 8.0;
		if ( Lots_value_y >= 275 && Lots_value_y < 290 ) Lots = 9.0;
		if ( Lots_value_y >= 290 							  ) Lots = 10.0;
	}
	Lots = NormalizeDouble( Lots, 1 );
// Open_Price
	Open_Price_Level = NormalizeDouble( ObjectGet( "Open_Price_Line", OBJPROP_PRICE1 ), MarketInfo( Symbol(), MODE_DIGITS ) );
// Stop_Loss
	Stop_Loss_Level = NormalizeDouble( ObjectGet( "Stop_Loss_Line", OBJPROP_PRICE1 ), MarketInfo( Symbol(), MODE_DIGITS ) );
// Take_Profit
	Take_Profit_Level = NormalizeDouble( ObjectGet( "Take_Profit_Line", OBJPROP_PRICE1 ), MarketInfo( Symbol(), MODE_DIGITS ) );
// Expiration_Time
	Expiration_Time = ObjectGet( "Expiration_Line", OBJPROP_TIME1 );
	
// ���������� ��� ������
	if ( Open_Price_Level - Bid >= 0 )
	{
		if ( Open_Price_Level - Stop_Loss_Level > 0 )
		{ _OrderType = OP_BUYSTOP; }
		else
		{ _OrderType = OP_SELLLIMIT; }
	}
	else
	{
		if ( Open_Price_Level - Stop_Loss_Level > 0 )
		{ _OrderType = OP_BUYLIMIT; }
		else
		{ _OrderType = OP_SELLSTOP; }
	}

color _Color;
// ��������� ��� ��������
	if ( _OrderType == OP_BUYLIMIT || _OrderType == OP_BUYSTOP )
	{
		_Color = Buy_Color;
		if ( Open_Price_Level - Stop_Loss_Level < MarketInfo( Symbol(), MODE_STOPLEVEL )*Point )
		{
			Answer = MessageBox(  "����������� ����������� Stop_Loss_Line (������� �����)!\n" + 
					 		 			 "\n" +
					 		 			 "��� BuyLimit � BuyStop - ������� ��� ������ ���� ���� ����� Open_Price_Line.	\n" + 
					 		 			 "����������� ������ (" + Symbol() + ") - " + DoubleToStr( MarketInfo( Symbol(), MODE_STOPLEVEL ), 0 ) + " �������.\n" + 
					 		 			 "\n\n" +
					 		 			 "����� ������ ��������� � ������, ������� \"������\".\n" +
					 		 			 "���� ���������� �� ���������, ������� \"������\".", "��������� ����������� ������", 0x00000005 | 0x00000030 | 0x00040000 );
			if ( Answer == 4 ) { ObjectsRedraw(); start(); }
			deinit();
			return(-1);
		}
		if ( Take_Profit_Level - Open_Price_Level < MarketInfo( Symbol(), MODE_STOPLEVEL )*Point && Take_Profit_Level > 0 )
		{
			Answer = MessageBox(  "����������� ����������� Take_Profit_Line (������ �����)!\n" + 
					 		 			 "\n" +
					 		 			 "��� BuyLimit � BuyStop - ������� ��� ������ ���� ���� ����� Open_Price_Line.	\n" + 
					 		 			 "����������� ������ (" + Symbol() + ") - " + DoubleToStr( MarketInfo( Symbol(), MODE_STOPLEVEL ), 0 ) + " �������.\n" + 
					 		 			 "\n\n" +
					 		 			 "����� ������ ��������� � ������, ������� \"������\".\n" +
					 		 			 "���� ���������� �� ���������, ������� \"������\".", "��������� ����������� ������", 0x00000005 | 0x00000030 | 0x00040000 );
			if ( Answer == 4 ) { ObjectsRedraw(); start(); }
			deinit();
			return(-1);
		}
		if ( _OrderType == OP_BUYSTOP )
		{
			if ( Open_Price_Level - Bid < MarketInfo( Symbol(), MODE_STOPLEVEL )*Point )
			{
				Answer = MessageBox( "����������� ����������� Open_Price_Line (����� �����)!\n" + 
					 		 			 	"\n" +
					 		 			 	"��� BuyStop - ������ ��� ������ ���� ���� ������� ����.	\n" + 
					 		 			 	"����������� ������ (" + Symbol() + ") - " + DoubleToStr( MarketInfo( Symbol(), MODE_STOPLEVEL ), 0 ) + " �������.\n" + 
					 		 			 	"\n\n" +
					 		 			 	"����� ������ ��������� � ������, ������� \"������\".\n" +
					 		 			 	"���� ���������� �� ���������, ������� \"������\".", "��������� ����������� ������", 0x00000005 | 0x00000030 | 0x00040000 );
				if ( Answer == 4 ) { ObjectsRedraw(); start(); }
				deinit();
				return(-1);
			}
		}
		else
		{
			if ( Bid - Open_Price_Level < MarketInfo( Symbol(), MODE_STOPLEVEL )*Point )
			{
				Answer = MessageBox( "����������� ����������� Open_Price_Line (����� �����)!\n" + 
					 		 			 	"\n" +
					 		 			 	"��� BuyLimit - ������ ��� ������ ���� ���� ������� ����.	\n" + 
					 		 			 	"����������� ������ (" + Symbol() + ") - " + DoubleToStr( MarketInfo( Symbol(), MODE_STOPLEVEL ), 0 ) + " �������.\n" + 
					 		 			 	"\n\n" +
					 		 			 	"����� ������ ��������� � ������, ������� \"������\".\n" +
					 		 			 	"���� ���������� �� ���������, ������� \"������\".", "��������� ����������� ������", 0x00000005 | 0x00000030 | 0x00040000 );
				if ( Answer == 4 ) { ObjectsRedraw(); start(); }
				deinit();
				return(-1);
			}
		}
	}
	if ( _OrderType == OP_SELLLIMIT || _OrderType == OP_SELLSTOP )
	{
		_Color = Sell_Color;
		if ( Stop_Loss_Level - Open_Price_Level < MarketInfo( Symbol(), MODE_STOPLEVEL )*Point )
		{
			Answer = MessageBox(  "����������� ����������� Stop_Loss_Line (������� �����)!\n" + 
					 		 			 "\n" +
					 		 			 "��� SellLimit � SellStop - ������� ��� ������ ���� ���� ����� Open_Price_Line.	\n" + 
					 		 			 "����������� ������ (" + Symbol() + ") - " + DoubleToStr( MarketInfo( Symbol(), MODE_STOPLEVEL ), 0 ) + " �������.\n" + 
					 		 			 "\n\n" +
					 		 			 "����� ������ ��������� � ������, ������� \"������\".\n" +
					 		 			 "���� ���������� �� ���������, ������� \"������\".", "��������� ����������� ������", 0x00000005 | 0x00000030 | 0x00040000 );
			if ( Answer == 4 ) { ObjectsRedraw(); start(); }
			deinit();
			return(-1);
		}
		if ( Open_Price_Level - Take_Profit_Level < MarketInfo( Symbol(), MODE_STOPLEVEL )*Point && Take_Profit_Level > 0 )
		{
			Answer = MessageBox(  "����������� ����������� Take_Profit_Line (������ �����)!\n" + 
					 		 			 "\n" +
					 		 			 "��� SellLimit � SellStop - ������� ��� ������ ���� ���� ����� Open_Price_Line.	\n" + 
					 		 			 "����������� ������ (" + Symbol() + ") - " + DoubleToStr( MarketInfo( Symbol(), MODE_STOPLEVEL ), 0 ) + " �������.\n" + 
					 		 			 "\n\n" +
					 		 			 "����� ������ ��������� � ������, ������� \"������\".\n" +
					 		 			 "���� ���������� �� ���������, ������� \"������\".", "��������� ����������� ������", 0x00000005 | 0x00000030 | 0x00040000 );
			if ( Answer == 4 ) { ObjectsRedraw(); start(); }
			deinit();
			return(-1);
		}
		if ( _OrderType == OP_SELLLIMIT )
		{
			if ( Open_Price_Level - Ask < MarketInfo( Symbol(), MODE_STOPLEVEL )*Point )
			{
				Answer = MessageBox( "����������� ����������� Open_Price_Line (����� �����)!\n" + 
					 		 			 	"\n" +
					 		 			 	"��� SellLimit - ������ ��� ������ ���� ���� ������� ����.	\n" + 
					 		 			 	"����������� ������ (" + Symbol() + ") - " + DoubleToStr( MarketInfo( Symbol(), MODE_STOPLEVEL ), 0 ) + " �������.\n" + 
					 		 			 	"\n\n" +
					 		 			 	"����� ������ ��������� � ������, ������� \"������\".\n" +
					 		 			 	"���� ���������� �� ���������, ������� \"������\".", "��������� ����������� ������", 0x00000005 | 0x00000030 | 0x00040000 );
				if ( Answer == 4 ) { ObjectsRedraw(); start(); }
				deinit();
				return(-1);
			}
		}
		else
		{
			if ( Ask - Open_Price_Level < MarketInfo( Symbol(), MODE_STOPLEVEL )*Point )
			{
				Answer = MessageBox( "����������� ����������� Open_Price_Line (����� �����)!\n" + 
					 		 			 	"\n" +
					 		 			 	"��� SellStop - ������ ��� ������ ���� ���� ������� ����.	\n" + 
					 		 			 	"����������� ������ (" + Symbol() + ") - " + DoubleToStr( MarketInfo( Symbol(), MODE_STOPLEVEL ), 0 ) + " �������.\n" + 
					 		 			 	"\n\n" +
					 		 			 	"����� ������ ��������� � ������, ������� \"������\".\n" +
					 		 			 	"���� ���������� �� ���������, ������� \"������\".", "��������� ����������� ������", 0x00000005 | 0x00000030 | 0x00040000 );
				if ( Answer == 4 ) { ObjectsRedraw(); start(); }
				deinit();
				return(-1);
			}
		}
	}

	if ( Expiration_Time <= CurTime() && Expiration_Time > 0 )
	{
			Answer = MessageBox(  "����������� ����������� Expiration_Line (����� �����)!\n" + 
					 		 			 "\n" +
					 		 			 "���� ��������� ������ �� ����� ���� � ��������� �������!		\n" + 
					 		 			 "\n\n" +
					 		 			 "����� ������ ��������� � ������, ������� \"������\".\n" +
					 		 			 "���� ���������� �� ���������, ������� \"������\".", "��������� ����������� ������", 0x00000005 | 0x00000030 | 0x00040000 );
			if ( Answer == 4 ) { ObjectsRedraw(); start(); }
			deinit();
			return(-1);
	}
	
// ������� ���� � ������� � �������� ���������� �����
	Print( "Symbol=",Symbol(), ",_OrderType=",_OrderType, ",Lots=",Lots, ",Open_Price_Level=",Open_Price_Level, ",Slippage=", Slippage, ",Stop_Loss_Level=", Stop_Loss_Level, ",Take_Profit_Level=", Take_Profit_Level, ",_Comment=", _Comment, ",MagicNumber=", MagicNumber, ",Expiration_Time=", Expiration_Time, ",_Color=", _Color );
	int ordersend = OrderSend( Symbol(), _OrderType, Lots, Open_Price_Level, Slippage, Stop_Loss_Level, Take_Profit_Level, _Comment, MagicNumber, Expiration_Time, _Color );
	if ( ordersend > 0 )
	{
// ���� �� ��, ������� ��� � �������
		OrderPrint();
		Print( "����� �", ordersend, " ���������� �������!");
		return(0);
	}
// ���� ������ - ������� ��������� � �������
	int error = GetLastError();
	Print("Alignment Error! GetLastError = ", error, ", ErrorDescription =  \"", ErrorDescription( error ), "\"" );
	MessageBox( "������ ��� ���������! GetLastError = " + error + ", ErrorDescription = \"" + ErrorDescription( error ) + "\"", 
             	 	"������ ��������� ������", 0x00000000 | 0x00000010 | 0x00040000 ); 
return(-1);
}

int deinit()
{
// �������� ���� ��������, ��������� ��������
	ObjectDelete( "Open_Price_Line" );
	ObjectDelete( "Stop_Loss_Line" );
	ObjectDelete( "Take_Profit_Line" );
	ObjectDelete( "Expiration_Line" );

	for ( double z = 0.1; z <= 1; z += 0.1 )
	{ ObjectDelete( DoubleToStr( z, 1 )); }
	for ( z = 1; z <= 10; z ++ )
	{ ObjectDelete( DoubleToStr( z, 1 )); }
	ObjectDelete( "Lots" );
	ObjectDelete( "Lots_value" );
	ObjectDelete( ">" );
return(0);
}



