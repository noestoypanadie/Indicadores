//+------------------------------------------------------------------+
//|                                                   AllMinutes.mq4 |
//|                                      Copyright © 2006, komposter |
//|                                      mailto:komposterius@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, komposter"
#property link      "mailto:komposterius@mail.ru"

#include <WinUser32.mqh>

//---- Список графиков которые необходимо обрабатывать, разделённый запятой (",")
extern string	ChartList	= "EURUSD1,GBPUSD1";
//---- Разрешить/запретить рисовать бары в выходные
//---- Если == true, выходные останутся незаполнеными
//---- Если == false, выходные будут заполнены барами O=H=L=C
extern bool		SkipWeekEnd	= true;
//---- Частота, с которой будут обновляться графики в милисекундах
//---- Чем больше значение, тем меньше ресурсов будет использовать скрипт.
extern int		RefreshLuft	= 1000;

int init() { start(); return(0); }
int start()
{
	int		_GetLastError = 0, cnt_copy = 0, cnt_add = 0, temp[13];
	int		Charts = 0, pos = 0, curchar = 0, len = StringLen( ChartList );
	string	cur_symbol = "", cur_period = "", file_name = "";

	string	_Symbol[100]; int _Period[100], _PeriodSec[], _Bars[];
	int		HistoryHandle[], hwnd[], last_fpos[], pre_time[], now_time[];
	double	now_close[], now_open[], now_low[], now_high[], now_volume[];
	double	pre_close[], pre_open[], pre_low[], pre_high[], pre_volume[];

	//---- считаем количество графиков, которые необходимо обработать
	while ( pos <= len )
	{
		curchar = StringGetChar( ChartList, pos );
		if ( curchar > 47 && curchar < 58 )
		{ cur_period = cur_period + CharToStr( curchar ); }
		else
		{
			if ( curchar == ',' || pos == len )
			{ 
				MarketInfo( cur_symbol, MODE_BID );
				if ( GetLastError() == 4106 )
				{
					Alert( "Неизвестный символ ", cur_symbol, "!!!" );
					return(-1);				
				}
				if ( iClose( cur_symbol, StrToInteger( cur_period ), 0 ) <= 0 )
				{
					Alert( "Неизвестный период ", cur_period, "!!!" );
					return(-1);				
				}

				_Symbol[Charts] = cur_symbol; _Period[Charts] = StrToInteger( cur_period );
				cur_symbol = ""; cur_period = "";

				Charts ++;
			}
			else
			{ cur_symbol = cur_symbol + CharToStr( curchar ); }
		}
		pos++;
	}
	Print( "< - - - Найдено ", Charts, " корректных графиков. - - - >" );
	
	ArrayResize( _Symbol,			Charts ); ArrayResize( _Period,		Charts );
	ArrayResize( HistoryHandle,	Charts ); ArrayResize( hwnd,			Charts );
	ArrayResize( last_fpos,			Charts ); ArrayResize( pre_time,		Charts );
	ArrayResize( now_time,			Charts ); ArrayResize( now_close,	Charts );
	ArrayResize( now_open,			Charts ); ArrayResize( now_low,		Charts );
	ArrayResize( now_high,			Charts ); ArrayResize( now_volume,	Charts );
	ArrayResize( pre_close,			Charts ); ArrayResize( pre_open,		Charts );
	ArrayResize( pre_low,			Charts ); ArrayResize( pre_high,		Charts );
	ArrayResize( pre_volume,		Charts ); ArrayResize( _PeriodSec,	Charts );
	ArrayResize( _Bars,				Charts );

	for ( int curChart = 0; curChart < Charts; curChart ++ )
	{
		_PeriodSec[curChart] = _Period[curChart] * 60;

		//---- открываем файл, в который будем записывать историю
		file_name = StringConcatenate( "ALL", _Symbol[curChart], _Period[curChart], ".hst" );
		HistoryHandle[curChart] = FileOpenHistory( file_name, FILE_BIN | FILE_WRITE );
		if ( HistoryHandle[curChart] < 0 )
		{
			_GetLastError = GetLastError();
			Alert( "FileOpenHistory( \"", file_name, "\", FILE_BIN | FILE_WRITE )",
																					" - Error #", _GetLastError );
			continue;
		}

		//---- Записываем заголовок файла
		FileWriteInteger	( HistoryHandle[curChart], 400, LONG_VALUE );
		FileWriteString	( HistoryHandle[curChart], "Copyright © 2006, komposter", 64 );
		FileWriteString	( HistoryHandle[curChart], 
									StringConcatenate( "ALL", _Symbol[curChart] ), 12 );
		FileWriteInteger	( HistoryHandle[curChart], _Period[curChart], LONG_VALUE );
		FileWriteInteger	( HistoryHandle[curChart], 
									MarketInfo( _Symbol[curChart], MODE_DIGITS ), LONG_VALUE );
		FileWriteInteger	( HistoryHandle[curChart], 0, LONG_VALUE );       //timesign
		FileWriteInteger	( HistoryHandle[curChart], 0, LONG_VALUE );       //last_sync
		FileWriteArray		( HistoryHandle[curChart], temp, 0, 13 );

		//+------------------------------------------------------------------+
		//| Обрабатываем историю
		//+------------------------------------------------------------------+
		_Bars[curChart] = iBars( _Symbol[curChart], _Period[curChart] );
		pre_time[curChart] = iTime( _Symbol[curChart], _Period[curChart], _Bars[curChart] - 1 );
		for( int i = _Bars[curChart] - 1; i >= 1; i-- )
		{
			//---- Запоминаем параметры бара
			now_open		[curChart] = iOpen	( _Symbol[curChart], _Period[curChart], i );
			now_high		[curChart] = iHigh	( _Symbol[curChart], _Period[curChart], i );
			now_low		[curChart] = iLow		( _Symbol[curChart], _Period[curChart], i );
			now_close	[curChart] = iClose	( _Symbol[curChart], _Period[curChart], i );
			now_volume	[curChart] = iVolume	( _Symbol[curChart], _Period[curChart], i );
			now_time		[curChart] = iTime	( _Symbol[curChart], _Period[curChart], i ) 
																							/ _PeriodSec[curChart];
			now_time		[curChart] *=_PeriodSec[curChart];

			//---- если есть пропущенные бары,
			while ( now_time[curChart] > pre_time[curChart] + _PeriodSec[curChart] )
			{
				pre_time[curChart] += _PeriodSec[curChart];
				pre_time[curChart] /= _PeriodSec[curChart];
				pre_time[curChart] *= _PeriodSec[curChart];

				//---- если это не выходные,
				if ( SkipWeekEnd )
				{
					if ( TimeDayOfWeek(pre_time[curChart]) <= 0 || 
							TimeDayOfWeek(pre_time[curChart]) > 5 ) { continue; }
					if ( TimeDayOfWeek(pre_time[curChart]) == 5 )
					{
						if ( TimeHour(pre_time[curChart]) == 23 || 
						TimeHour(pre_time[curChart] + _PeriodSec[curChart]) == 23 ) { continue; }
					}
				}

				//---- записываем пропущенный бар в файл
				FileWriteInteger	( HistoryHandle[curChart], pre_time[curChart],	LONG_VALUE	);
				FileWriteDouble	( HistoryHandle[curChart], pre_close[curChart],	DOUBLE_VALUE);
				FileWriteDouble	( HistoryHandle[curChart], pre_close[curChart],	DOUBLE_VALUE);
				FileWriteDouble	( HistoryHandle[curChart], pre_close[curChart],	DOUBLE_VALUE);
				FileWriteDouble	( HistoryHandle[curChart], pre_close[curChart],	DOUBLE_VALUE);
				FileWriteDouble	( HistoryHandle[curChart], 0,							DOUBLE_VALUE);
				FileFlush			( HistoryHandle[curChart] );
				cnt_add ++;
			}

			//---- записываем новый бар в файл
			FileWriteInteger	( HistoryHandle[curChart], now_time[curChart],		LONG_VALUE	);
			FileWriteDouble	( HistoryHandle[curChart], now_open[curChart],		DOUBLE_VALUE);
			FileWriteDouble	( HistoryHandle[curChart], now_low[curChart],		DOUBLE_VALUE);
			FileWriteDouble	( HistoryHandle[curChart], now_high[curChart],		DOUBLE_VALUE);
			FileWriteDouble	( HistoryHandle[curChart], now_close[curChart],		DOUBLE_VALUE);
			FileWriteDouble	( HistoryHandle[curChart], now_volume[curChart],	DOUBLE_VALUE);
			FileFlush			( HistoryHandle[curChart] );
			cnt_copy ++;

			//---- запоминаем значение времени и цену закрытия записанного бара
			pre_close[curChart]	= now_close[curChart];
			pre_time[curChart]	= now_time[curChart] / _PeriodSec[curChart];
			pre_time[curChart]	*=_PeriodSec[curChart];
 		}

		last_fpos[curChart] = FileTell( HistoryHandle[curChart] );

		//---- выводим статистику
		Print( "< - - - ", _Symbol[curChart], _Period[curChart], ": было ", cnt_copy, 
													" баров, добавлено ", cnt_add, " баров - - - >" );
		Print( "< - - - Для просмотра результатов, откройте график \"ALL", 
												_Symbol[curChart], _Period[curChart], "\" - - - >" );

	}

	//+------------------------------------------------------------------+
	//| Обрабатываем поступающие тики
	//+------------------------------------------------------------------+
	while ( !IsStopped() )
	{
		RefreshRates();
		for ( curChart = 0; curChart < Charts; curChart ++ )
		{
			//---- ставим "курсор" перед последним баром
			//---- (это необходимо на всех запусках, кроме первого)
			FileSeek( HistoryHandle[curChart], last_fpos[curChart], SEEK_SET );

			//---- Запоминаем параметры бара
			now_open		[curChart] = iOpen	( _Symbol[curChart], _Period[curChart], 0 );
			now_high		[curChart] = iHigh	( _Symbol[curChart], _Period[curChart], 0 );
			now_low		[curChart] = iLow		( _Symbol[curChart], _Period[curChart], 0 );
			now_close	[curChart] = iClose	( _Symbol[curChart], _Period[curChart], 0 );
			now_volume	[curChart] = iVolume	( _Symbol[curChart], _Period[curChart], 0 );
			now_time		[curChart] = iTime	( _Symbol[curChart], _Period[curChart], 0 ) 
																						/ _PeriodSec[curChart];
			now_time		[curChart] *=_PeriodSec[curChart];

			//---- если бар сформировался, 
			if ( now_time[curChart] >= pre_time[curChart] + _PeriodSec[curChart] )
			{
				//---- записываем сформировавшийся бар
				FileWriteInteger	( HistoryHandle[curChart], pre_time[curChart],	 LONG_VALUE	 );
				FileWriteDouble	( HistoryHandle[curChart], pre_open[curChart],	 DOUBLE_VALUE );
				FileWriteDouble	( HistoryHandle[curChart], pre_low[curChart],	 DOUBLE_VALUE );
				FileWriteDouble	( HistoryHandle[curChart], pre_high[curChart],	 DOUBLE_VALUE );
				FileWriteDouble	( HistoryHandle[curChart], pre_close[curChart],	 DOUBLE_VALUE );
				FileWriteDouble	( HistoryHandle[curChart], pre_volume[curChart], DOUBLE_VALUE );
				FileFlush			( HistoryHandle[curChart] );

				//---- запоминаем место в файле, перед записью 0-го бара
				last_fpos[curChart] = FileTell( HistoryHandle[curChart] );
			}

			//---- если появились пропущенные бары,
			while ( now_time[curChart] > pre_time[curChart] + _PeriodSec[curChart] )
			{
				pre_time[curChart] += _PeriodSec[curChart];
				pre_time[curChart] /= _PeriodSec[curChart];
				pre_time[curChart] *= _PeriodSec[curChart];

				//---- если это не выходные,
				if ( SkipWeekEnd )
				{
					if ( TimeDayOfWeek(pre_time[curChart]) <= 0 || 
						TimeDayOfWeek(pre_time[curChart]) > 5 ) { continue; }
					if ( TimeDayOfWeek(pre_time[curChart]) == 5 )
					{
						if ( TimeHour(pre_time[curChart]) == 23 || 
							TimeHour(pre_time[curChart] + _PeriodSec[curChart]) == 23 ) { continue; }
					}
				}

				//---- записываем пропущенный бар в файл
				FileWriteInteger	( HistoryHandle[curChart], pre_time[curChart],	LONG_VALUE	);
				FileWriteDouble	( HistoryHandle[curChart], pre_close[curChart],	DOUBLE_VALUE);
				FileWriteDouble	( HistoryHandle[curChart], pre_close[curChart],	DOUBLE_VALUE);
				FileWriteDouble	( HistoryHandle[curChart], pre_close[curChart],	DOUBLE_VALUE);
				FileWriteDouble	( HistoryHandle[curChart], pre_close[curChart],	DOUBLE_VALUE);
				FileWriteDouble	( HistoryHandle[curChart], 0,							DOUBLE_VALUE);
				FileFlush			( HistoryHandle[curChart] );

				//---- запоминаем место в файле, перед записью 0-го бара
				last_fpos[curChart] = FileTell( HistoryHandle[curChart] );
			}

			//---- записываем текущий бар
			FileWriteInteger	( HistoryHandle[curChart], now_time[curChart],		LONG_VALUE	 );
			FileWriteDouble	( HistoryHandle[curChart], now_open[curChart],		DOUBLE_VALUE );
			FileWriteDouble	( HistoryHandle[curChart], now_low[curChart],		DOUBLE_VALUE );
			FileWriteDouble	( HistoryHandle[curChart], now_high[curChart],		DOUBLE_VALUE );
			FileWriteDouble	( HistoryHandle[curChart], now_close[curChart],		DOUBLE_VALUE );
			FileWriteDouble	( HistoryHandle[curChart], now_volume[curChart],	DOUBLE_VALUE );
			FileFlush			( HistoryHandle[curChart] );

			//---- запоминаем параметры записанного бара
			pre_open[curChart]		= now_open[curChart];
			pre_high[curChart]		= now_high[curChart];
			pre_low[curChart]			= now_low[curChart];
			pre_close[curChart]		= now_close[curChart];
			pre_volume[curChart]		= now_volume[curChart];
			pre_time[curChart]		= now_time[curChart] / _PeriodSec[curChart];
			pre_time[curChart]		*=_PeriodSec[curChart];

			//---- находим окно, в которое будем "отправлять" свежие котировки
			if ( hwnd[curChart] == 0 )
			{
				hwnd[curChart] = WindowHandle( StringConcatenate( "ALL", _Symbol[curChart] ), 
																								_Period[curChart] );
				if ( hwnd[curChart] != 0 ) { Print( "< - - - График ", "ALL" + _Symbol[curChart], 
																	_Period[curChart], " найден! - - - >" ); }
			}
			//---- и, если нашли, обновляем его
			if ( hwnd[curChart] != 0 ) { PostMessageA( hwnd[curChart], WM_COMMAND, 33324, 0 ); }
		}
		Sleep(RefreshLuft);
	}

	for ( curChart = 0; curChart < Charts; curChart ++ )
	{
		if ( HistoryHandle[curChart] >= 0 )
		{
			//---- закрываем файл
			FileClose( HistoryHandle[curChart] );
			HistoryHandle[curChart] = -1;
		}
	}
	return(0);
}

