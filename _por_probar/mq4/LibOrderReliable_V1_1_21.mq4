//=============================================================================
//                        LibOrderReliable_V1_1_2.mq4
//
//                      Copyright © 2006, Matthew Kennel 
//                            mbkennelfx@gmail.com
//
//
//  A library for MT4 expert advisors, intended to give more reliable 
//  order handling.	This library only concerns the mechanics of sending 
//  orders to the Metatrader server, dealing with transient connectivity 
//  problems better than the standard order sending functions.  It is 
//  essentially an error-checking wrapper around the existing transaction 
//  functions. This library provides nothing to help actual trade strategies, 
//  but ought to be valuable for nearly all expert advisors which trade 'live'. 
//
//						  Instructions:
//
//  Put this file in the experts/libraries directory.  Put the header
//  file (OrderReliable_V?_?_?.mqh) in the experts/include directory
//
//  Include the line:
//
//     #include <LibOrderReliable_V?_?_?.mqh>
// 
//  ...in the beginning of your EA with the question marks replaced by the 
//  actual version number (in file name) of the header file.
// 
//  YOU MUST EDIT THE EA MANUALLY IN ORDER TO USE THIS LIBRARY, BY BOTH 
//  SPECIFYING THE INCLUDE FILE AND THEN MODIFYING THE EA CODE TO USE 
//  THE FUNCTIONS.  
//
//  In particular you must change, in the EA, OrderSend() commands to 
//  OrderSendReliable() and OrderModify() commands to OrderModifyReliable(), 
//  or any others which are appropriate.
//
//=============================================================================
//
//  Version:	1.1.2
//
//  Contents:
//
//		OrderSendReliable()  
//			This is intended to be a drop-in replacement for OrderSend() 
//			which, one hopes is more resistant to various forms of errors 
//			prevalent with MetaTrader.
//
//		OrderSendReliableMKT()
//			This function is intended for immediate market-orders ONLY, 
//			the principal difference that in its internal retry-loop,
//			it uses the new "Bid" and "Ask" real-time variables as opposed
//			to the OrderSendReliable() which uses only the price given upon
//			entry to the routine.  More likely to get off orders, and more
//			likely they are further from desired price. 
//    
//		OrderModifyReliable()
//			A replacement for OrderModify with more error handling, similar 
//			to OrderSendReliable()
//
//		OrderModifyReliableSymbol()
//			Adds a "symbol" field to OrderModifyReliable (not drop in any 
//			more) so that it can fix problems with stops/take profits which 
//			are too close to market, as well as normalization problems.
// 
//		OrderCloseReliable()
//			A replacement for OrderClose with more error handling, similar 
//			to OrderSendReliable()
//
//		OrderReliableLastErr()
//			Returns the last error seen by an Order*Reliable() call.
//			NOTE: GetLastError()  WILL NOT WORK to return the error
//			after a call to most of the OrderReliable libraries.
//				This is a flaw in Metatrader design, in that
//			GetLastError(), used by OrderReliable to check the error, 
//			also clears it.  Hence in this waw this library cannot be a
//			total drop-in replacement.
// 
//===========================================================================

// 
//  UPDATE THIS STRING FOR EACH NEW VERSION!! 
//  MUST CORRELATE WITH FILE NAME.

string OrderReliableVersion = "V1_1_2"; 

//  History:
// 2006-11-26: 1.1.2    Mods by Derk:  Changed from an include file into a proper library.  Steps:
//                      - Create lib flie and transfer all comments and code into new .mq4 file
//                      - Create new companion include file, LibOrderReliable_V1_1_2.mqh
//                      - Tidy up comments (removed all tabs from comments and replaced with spaces)
//
// 2006-09-27: 1.1.1    Fixed Normalize problem in OrderSendReliableMKT() so that backtesting works on non-normalized data
//                      Commented out IsTradeAllowed() in OrderCloseReliable due to a bug in MT4 that sometimes 
//                      incorrectly returns IsTradeAllowed() = false
//                      Added MarketInfo retrieval of Bid and Ask in OrderCloseReliable for every retry
//                      Replaced RefreshRates with MarketInfo in OrderSendReliableMKT
//
// 2006-08-16: 1.1.0    Added OrderSendReliableMKT()
//
// 2006-08-16: 1.0.1    Fixed dumb factor-of-ten misrepresentation in sleep. 
//
// 2006-07-31: 1.0.0:   Graduated to 1.0.0 status.  
//                      Functionality the same as 0.2.5.  Added additional comments,
//                      updated version string properly. 
//
// 2006-07-19: 0.2.5:   Modified by Derk Wehler
//                      Cleaned up commenting and code, to make more 
//                      readable; added additional comments
//                      Added OrderCloseReliable(), modeling largely 
//                      after OrderModifyReliable()
//
// 2006-07-14: 0.2.4:   ERR_TRADE_TIMEOUT now a retryable error for modify	
//                      only.  Unclear about what to do for send because that
//                      may result in duplicate trades.  
//                      Adds OrderReliableLastErr()
//
// 2006-06-07: 0.2.3:   Version number now in log comments.  Docs updated.	
//                      OP_BUYLIMIT/OP_SELLLIMIT added. Increase retry time
//
// 2006-06-07: 0.2.2:   Fixed int/bool type mismatch compiler ignored
//
// 2006-06-06: 0.2.1:   Returns success if modification is redundant
//
// 2006-06-06: 0.2.0:   Added OrderModifyReliable
//
// 2006-06-05: 0.1.2:   Fixed idiotic typographical bug.
//
// 2006-06-05: 0.1.1:   Added ERR_TRADE_CONTEXT_BUSY to retryable errors.
//
// 2006-05-29: 0.1:     Created.  Only OrderSendReliable() implemented.
//		 
// LICENSING:  This is free, open source software, licensed under
//				Version 2 of the GNU General Public License (GPL). 
// 
// In particular, this means that distribution of this software in a binary 
// format, e.g. as compiled in as part of a .ex4 format, must be accompanied
// by the non-obfuscated source code of both this file, AND the .mq4 source 
// files which it is compiled with, or you must make such files available at 
// no charge to binary recipients.	If you do not agree with such terms you 
// must not use this code.  Detailed terms of the GPL are widely available 
// on the Internet.  The Library GPL (LGPL) was intentionally not used, 
// therefore the source code of files which link to this are subject to
// terms of the GPL if binaries made from them are publicly distributed or 
// sold. 
//  
// Copyright (2006), Matthew Kennel, mbkennelfx@gmail.com
//===========================================================================

//===========================================================================
/*                
            ADDITIONAL TIPS FOR RELIABLE EXPERT ADVISORS
            (mbk, 7-31-06)
            
   Here are some "good practices" which some people have found by experience
   to be a good idea for EA programming.
   
   The first thing to remember is that programming EA's, which work in
   an unreliable client-server environment, is not like ordinary software 
   development.  In "regular" programming you can be pretty sure that 
   operations will work as long as the computer is functioning.   This is 
   not the case with transactions over the network, and you have to be 
   quite careful and almost "paranoid" in the sense of checking for 
   anything which might go wrong.  You must assume a possibility that all 
   transactions might fail, and that much information may become unavailable, 
   often transiently so. These failure modes will NOT be visible on a 
   back-test, and are significantly more severe in a live "real-money" 
   account than even real-time demo accounts.
   
   The problem is that many EA's use the existence, or nonexistence thereof
   of orders as a trigger for additional events, like setting up additional 
   trades, in same direction or not.   If you assume that trades will be 
   successful, or otherwise instantly visible to OrderSelect(), for example, 
   you may be in for a shock as this information may be unavailable during a 
   trade, or during the interval the dealing desk is 'holding' the order.  
   This may result in duplicate trades which shouldn't be there, in bad 
   circumstances, a loop of a sequence of zillions of trades placed 
   inappropriately.  If this is real money this could mean inappropriate 
   risk to a catastrophe and the dealers will NOT bail you out as your 
   bugs are your own problem. 
   
   Other problem is that Metatrader is somewhat amateurish in its design, 
   and a real "pro" level financial system would have transaction-oriented 
   multiple-phase commits and event queues.  On the downside this would be 
   significantly more difficult to program.
   
   Unfortunately if you want to use Metatrader EA's there is no real 
   alternative to learning how to write software fairly well.  A little bit 
   of knowledge and over-confidence (and a buggy EA) is a very quick way to 
   go bankrupt.   If you have never or almost never written software before, 
   please go learn on something which will not cost you money.
   
   Specific suggestions:
   
     *  Learn how to use the "MagicNumber" function in your EA's.  Remember
        that multiple EA's on the same symbol (perhaps even if different 
        chart time frame's) will have ALL their orders visible to one another.  
        This is not the case in back-testing.   Many EA's which work fine in 
        backtesting will totally get fried when there are multiple EA's 
        working at once. Hence, if you want to see if an order is "owned"
        by an EA---which is ESSENTIAL!!!---you must check the MagicNumber 
        variable in addition to the OrderSymbol() to ensure it is one of 
        "yours". 
        
     *  Manage your existing orders with the *ticket number*, i.e. the value
        returned by OrderSend() (and OrderSendReliable()).   This has proven
        by people's experience to be more reliable, in terms of getting
        status of existing orders with OrderSelect(), i.e. SELECT_BY_TICKET.  
        Sometimes people have found that orders have become invisible
        to SELECT_BY_POS for a short time, perhaps while the dealing desk has
        them, but remain visible to SELECT_BY_TICKET.  The ticket number is,
        by definition, the truly unique identifier of the order in the 
        server's data base.  Use it.
        
     *  Often you may combine the use of ticket numbers and magic numbers. 
        For instance, suppose you have potentially four different order kinds 
        in your EA, two long orders (i.e. for scaling out), and two short 
        orders. You would then define that each had a magic number *offset* 
        from the magic number base.  E.g. you may have something like this:
        
            extern int MN = 123456;
            int Magic_long1, int Magic_long2, int Magic_short1, int Magic_short2         
            int Ticket_long1, int Ticket_long2, int Ticket_short1, int Ticket_short2;

        and in the init() function:
         
            init() {
                Magic_long1 = MN;
                Magic_long2 = MN+1;
                Magic_short1 = MN+2;
                Magic_short2 = MN+3; 
            }
          
        And then when you send the order you use the appropriate magic number---and
        you save the ticket value in the appropriate variable.  When you see if an
        order is owned by you then you have to check the range of magic numbers.
        
        Of course this can be generalized to arrays of each. 
 
     *  Put the magic number in the "Comment" field so you can see it on the
        Metatrader terminal.  This way you can figure out what is what as magic
        numbers are not available in the user-interface. For example:
        
            string overall_comment = "My_EA_name"

            void foo() {
      
                yadda yadda
                int my_MN = MN + k;
                string cstr = overall_comment + " magic:"+my_mn; 
    
                OrderSendReliable(  yadda yadda yadda,   my_MN, cstr,   yadda yadda ) 
            }                        
          
        
        If you are in a loop checking existing orders with an OrderSelect() 
        and a SELECT_BY_POS,  if you delete an order or close an order, then 
        all other entries may become invalid!  By deleting then you have 
        totally changed the list, and you ought to start over with a new 
        loop once you have executed one client-server transaction.  For 
        instance the OrdersTotal() can change.
         
        Generally hence do loops with OrdersTotal() like this,
         
            int i;
            bool do_again = false; 
            for (i = OrdersTotal()-1; (do_again == false) && (i>= 0); i--) {
                if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES) {
                    if (condition) {
                        if {OrderDelete(OrderTicket()) {
                            Print("Successful delete")
                        } else {
                            Print("Failed delete")
                        }
                        do_again = true; 
                        break; // VERY IMPORTANT TO QUIT ENTIRE FOR LOOP IF ORDER IS DELETED
                    }
                    if (othercondition) {
                        OrderCloseReliable( yadda yadda ) //
                       
                        do_again = true;
                        break; 
                    }
                }  
            }
          
        and if "do_again == true" then there is a possibility that more may yet
        remain in the list for processing so you ought to restart the loop over. 
        One way to do that is to have something like a "delete_one_order()" function
        which has that core loop, and returns the "do_again" variable.  And then
        the calling function will keep on calling it until do_again is false---
        and of course you will also have a maximum loop count in case something
        gets screwed up.
        
        Not good:
        
            for (i=0; i<OrdersTotal(); i++) {
                // 
                // maybe delete an order in here
                //             
            }

     *  Note also the error checking of the return value of OrderSelect().
        Most people forget to do that.  I am not sure what it means if
        an OrderSelect() fails, whether to continue or to abort. 
          
     *  Put time-outs between the time you send an order, and you
        later query them to let it "settle". 
         
     *  If you have a condition that you think specifies a new order, then
        ensure that it stays "OK" for a certain number of seconds/minutes.  You
        do this by saving in a static or global int variable, the "CurTime()" 
        when it last occurred (and setting that to zero if the condition is 
        false) and then only if it has remained true until 
        (CurTime() - saved_time) >= some_interval of seconds. 
               
     *  Try to query orders to check their status, using ticket numbers, if you
        have them before assuming they have executed. 
         
     *  Orders can go from pending to active any time during the execution
        of your EA and you might not know it unless you check. 

     *  Check to see that there are not an excessive number of 'open orders'
        'owned' by the EA, either active or pending.  THIS CAN BE A KEY
        SANITY CHECK WHICH PREVENTS A FINANCIAL MELTDOWN!!! 
         
        And if there are, do not open more, there is probably
        a bug, and you do not want to send too many real-money orders.   Here
        you will probably do a SELECT_BY_POS and not SELECT_BY_TICKET because
        you have to account for the possibility that due to a bug (or restart
        of the EA!) you have "forgotten" some of the ticket numbers.
        
     *  Do not assume that in a real-money EA that a stop or take profit will actually
        be executed if the price has gone through that value.  Yes, they are 
        unethical and mean.
         
     *  Assume that the EA could be stopped and restarted at any time due to
        external factors, like a power failure.  In other words, do not
        assume in the init() that there are no orders outstanding owned
        by the EA!!!     If your EA depends on this to be true, then
        check first, and if it isn't the case, put up a big Alert
        box or something and tell the human to delete them.
         
        Or, better, if you are able to 'pick up where you left off' then do so
        and write your EA with that possibility in mind.

     *  Write your EA's with a "SetNewOrders" type of boolean variable
        which, if false, means that the EA will not set new orders, but
        will continue to manage open orders and close them.  This variable
        may be changed "in flight" by the user to allow him to
        'safely' go flat.         

     *  Use global variables---i.e. the ones you set with GlobalVariableSet()
        as these can stay persistent over restarts of the trading station,
        and maybe even upgrades of the Metatrader software version. 
        Here you may want to store ticket numbers or other vital information
        to enable a "warm restart" of the strategy after an EA is stopped
        or started.

     *  In a more advanced usage, you can approximate some kinds of 
        "semaphores" and lock-outs which are the computer-science
        ways of dealing with the multithreading problems.
        See GlobalVariableSetOnCondition() documentation. 
         
        This OrderReliable library may preclude the need for *some* of that
        but don't necessarily count on it. 
        

*/
//===========================================================================
#property copyright "Copyright © 2006, Derk Wehler"
#property link      "no site"
#property library

#include <stdlib.mqh>
#include <stderror.mqh> 

int retry_attempts 		= 10; 
double sleep_time 		= 4.0;
double sleep_maximum 	= 25.0;  // in seconds

string OrderReliable_Fname = "OrderReliable fname unset";

static int _OR_err = 0;


//=============================================================================
//							 OrderSendReliable()
//
//  This is intended to be a drop-in replacement for OrderSend() which, 
//  one hopes, is more resistant to various forms of errors prevalent 
//  with MetaTrader.
//			  
//	RETURN VALUE: 
//
//  Ticket number or -1 under some error conditions.  Check
//  final error returned by Metatrader with OrderReliableLastErr().
//  This will reset the value from GetLastError(), so in that sense it cannot
//  be a total drop-in replacement due to Metatrader flaw. 
//
//  FEATURES:
//
//     * Re-trying under some error conditions, sleeping a random 
//       time defined by an exponential probability distribution.
//
//     * Automatic normalization of Digits
//
//     * Automatically makes sure that stop levels are more than
//       the minimum stop distance, as given by the server. If they
//       are too close, they are adjusted.
//
//     * Automatically converts stop orders to market orders 
//       when the stop orders are rejected by the server for 
//       being to close to market.  NOTE: This intentionally
//       applies only to OP_BUYSTOP and OP_SELLSTOP, 
//       OP_BUYLIMIT and OP_SELLLIMIT are not converted to market
//       orders and so for prices which are too close to current
//       this function is likely to loop a few times and return
//       with the "invalid stops" error message. 
//       Note, the commentary in previous versions erroneously said
//       that limit orders would be converted.  Note also
//       that entering a BUYSTOP or SELLSTOP new order is distinct
//       from setting a stoploss on an outstanding order; use
//       OrderModifyReliable() for that. 
//
//     * Displays various error messages on the log for debugging.
//
//
//	Matt Kennel, 2006-05-28 and following
//
//=============================================================================
int OrderSendReliable(string symbol, int cmd, double volume, double price,
					  int slippage, double stoploss, double takeprofit,
					  string comment, int magic, datetime expiration = 0, 
					  color arrow_color = CLR_NONE) 
{

	// ------------------------------------------------
	// Check basic conditions see if trade is possible. 
	// ------------------------------------------------
	OrderReliable_Fname = "OrderSendReliable";
	OrderReliablePrint(" attempted " + OrderReliable_CommandString(cmd) + " " + volume + 
						" lots @" + price + " sl:" + stoploss + " tp:" + takeprofit); 
						
	if (!IsConnected()) 
	{
		OrderReliablePrint("error: IsConnected() == false");
		_OR_err = ERR_NO_CONNECTION; 
		return(-1);
	}
	
	if (IsStopped()) 
	{
		OrderReliablePrint("error: IsStopped() == true");
		_OR_err = ERR_COMMON_ERROR; 
		return(-1);
	}
	
	int cnt = 0;
	while(!IsTradeAllowed() && cnt < retry_attempts) 
	{
		OrderReliable_SleepRandomTime(sleep_time, sleep_maximum); 
		cnt++;
	}
	
	if (!IsTradeAllowed()) 
	{
		OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
		_OR_err = ERR_TRADE_CONTEXT_BUSY; 

		return(-1);  
	}

	// Normalize all price / stoploss / takeprofit to the proper # of digits.
	int digits = MarketInfo(symbol, MODE_DIGITS);
	if (digits > 0) 
	{
		price = NormalizeDouble(price, digits);
		stoploss = NormalizeDouble(stoploss, digits);
		takeprofit = NormalizeDouble(takeprofit, digits); 
	}
	
	if (stoploss != 0) 
		OrderReliable_EnsureValidStop(symbol, price, stoploss); 

	int err = GetLastError(); // clear the global variable.  
	err = 0; 
	_OR_err = 0; 
	bool exit_loop = false;
	bool limit_to_market = false; 
	
	// limit/stop order. 
	int ticket=-1;

	if ((cmd == OP_BUYSTOP) || (cmd == OP_SELLSTOP) || (cmd == OP_BUYLIMIT) || (cmd == OP_SELLLIMIT)) 
	{
		cnt = 0;
		while (!exit_loop) 
		{
			if (IsTradeAllowed()) 
			{
				ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss, 
									takeprofit, comment, magic, expiration, arrow_color);
				err = GetLastError();
				_OR_err = err; 
			} 
			else 
			{
				cnt++;
			} 
			
			switch (err) 
			{
				case ERR_NO_ERROR:
					exit_loop = true;
					break;
				
				// retryable errors
				case ERR_SERVER_BUSY:
				case ERR_NO_CONNECTION:
				case ERR_INVALID_PRICE:
				case ERR_OFF_QUOTES:
				case ERR_BROKER_BUSY:
				case ERR_TRADE_CONTEXT_BUSY: 
					cnt++; 
					break;
					
				case ERR_PRICE_CHANGED:
				case ERR_REQUOTE:
					RefreshRates();
					continue;	// we can apparently retry immediately according to MT docs.
					
				case ERR_INVALID_STOPS:
					double servers_min_stop = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT); 
					if (cmd == OP_BUYSTOP) 
					{
						// If we are too close to put in a limit/stop order so go to market.
						if (MathAbs(Ask - price) <= servers_min_stop)	
							limit_to_market = true; 
							
					} 
					else if (cmd == OP_SELLSTOP) 
					{
						// If we are too close to put in a limit/stop order so go to market.
						if (MathAbs(Bid - price) <= servers_min_stop)
							limit_to_market = true; 
					}
					exit_loop = true; 
					break; 
					
				default:
					// an apparently serious error.
					exit_loop = true;
					break; 
					
			}  // end switch 

			if (cnt > retry_attempts) 
				exit_loop = true; 
			 	
			if (exit_loop) 
			{
				if (err != ERR_NO_ERROR) 
				{
					OrderReliablePrint("non-retryable error: " + OrderReliableErrTxt(err)); 
				}
				if (cnt > retry_attempts) 
				{
					OrderReliablePrint("retry attempts maxed at " + retry_attempts); 
				}
			}
			 
			if (!exit_loop) 
			{
				OrderReliablePrint("retryable error (" + cnt + "/" + retry_attempts + 
									"): " + OrderReliableErrTxt(err)); 
				OrderReliable_SleepRandomTime(sleep_time, sleep_maximum); 
				RefreshRates(); 
			}
		}
		 
		// We have now exited from loop. 
		if (err == ERR_NO_ERROR) 
		{
			OrderReliablePrint("apparently successful OP_BUYSTOP or OP_SELLSTOP order placed, details follow.");
			OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
			OrderPrint(); 
			return(ticket); // SUCCESS! 
		} 
		if (!limit_to_market) 
		{
			OrderReliablePrint("failed to execute stop or limit order after " + cnt + " retries");
			OrderReliablePrint("failed trade: " + OrderReliable_CommandString(cmd) + " " + symbol + 
								"@" + price + " tp@" + takeprofit + " sl@" + stoploss); 
			OrderReliablePrint("last error: " + OrderReliableErrTxt(err)); 
			return(-1); 
		}
	}  // end	  
  
	if (limit_to_market) 
	{
		OrderReliablePrint("going from limit order to market order because market is too close.");
		if ((cmd == OP_BUYSTOP) || (cmd == OP_BUYLIMIT)) 
		{
			cmd = OP_BUY;
			price = Ask;
		} 
		else if ((cmd == OP_SELLSTOP) || (cmd == OP_SELLLIMIT)) 
		{
			cmd = OP_SELL;
			price = Bid;
		}	
	}
	
	// we now have a market order.
	err = GetLastError(); // so we clear the global variable.  
	err = 0; 
	_OR_err = 0; 
	ticket = -1;

	if ((cmd == OP_BUY) || (cmd == OP_SELL)) 
	{
		cnt = 0;
		while (!exit_loop) 
		{
			if (IsTradeAllowed()) 
			{
				ticket = OrderSend(symbol, cmd, volume, price, slippage, 
									stoploss, takeprofit, comment, magic, 
									expiration, arrow_color);
				err = GetLastError();
				_OR_err = err; 
			} 
			else 
			{
				cnt++;
			} 
			switch (err) 
			{
				case ERR_NO_ERROR:
					exit_loop = true;
					break;
					
				case ERR_SERVER_BUSY:
				case ERR_NO_CONNECTION:
				case ERR_INVALID_PRICE:
				case ERR_OFF_QUOTES:
				case ERR_BROKER_BUSY:
				case ERR_TRADE_CONTEXT_BUSY: 
					cnt++; // a retryable error
					break;
					
				case ERR_PRICE_CHANGED:
				case ERR_REQUOTE:
					RefreshRates();
					continue; // we can apparently retry immediately according to MT docs.
					
				default:
					// an apparently serious, unretryable error.
					exit_loop = true;
					break; 
					
			}  // end switch 

			if (cnt > retry_attempts) 
			 	exit_loop = true; 
			 	
			if (!exit_loop) 
			{
				OrderReliablePrint("retryable error (" + cnt + "/" + 
									retry_attempts + "): " + OrderReliableErrTxt(err)); 
				OrderReliable_SleepRandomTime(sleep_time,sleep_maximum); 
				RefreshRates(); 
			}
			
			if (exit_loop) 
			{
				if (err != ERR_NO_ERROR) 
				{
					OrderReliablePrint("non-retryable error: " + OrderReliableErrTxt(err)); 
				}
				if (cnt > retry_attempts) 
				{
					OrderReliablePrint("retry attempts maxed at " + retry_attempts); 
				}
			}
		}
		
		// we have now exited from loop. 
		if (err == ERR_NO_ERROR) 
		{
			OrderReliablePrint("apparently successful OP_BUY or OP_SELL order placed, details follow.");
			OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
			OrderPrint(); 
			return(ticket); // SUCCESS! 
		} 
		OrderReliablePrint("failed to execute OP_BUY/OP_SELL, after " + cnt + " retries");
		OrderReliablePrint("failed trade: " + OrderReliable_CommandString(cmd) + " " + symbol + 
							"@" + price + " tp@" + takeprofit + " sl@" + stoploss); 
		OrderReliablePrint("last error: " + OrderReliableErrTxt(err)); 
		return(-1); 
	}
}
	
//=============================================================================
//							 OrderSendReliableMKT()
//
//  This is intended to be an alternative for OrderSendReliable() which
//  will update market-orders in the retry loop with the current Bid or Ask.
//  Hence with market orders there is a greater likelihood that the trade will
//  be executed versus OrderSendReliable(), and a greater likelihood it will
//  be executed at a price worse than the entry price due to price movement. 
//			  
//  RETURN VALUE: 
//
//  Ticket number or -1 under some error conditions.  Check
//  final error returned by Metatrader with OrderReliableLastErr().
//  This will reset the value from GetLastError(), so in that sense it cannot
//  be a total drop-in replacement due to Metatrader flaw. 
//
//  FEATURES:
//
//     * Most features of OrderSendReliable() but for market orders only. 
//       Command must be OP_BUY or OP_SELL, and specify Bid or Ask at
//       the time of the call.
//
//     * If price moves in an unfavorable direction during the loop,
//       e.g. from requotes, then the slippage variable it uses in 
//       the real attempt to the server will be decremented from the passed
//       value by that amount, down to a minimum of zero.   If the current
//       price is too far from the entry value minus slippage then it
//       will not attempt an order, and it will signal, manually,
//       an ERR_INVALID_PRICE (displayed to log as usual) and will continue
//       to loop the usual number of times. 
//
//     * Displays various error messages on the log for debugging.
//
//
//	Matt Kennel, 2006-08-16
//
//=============================================================================
int OrderSendReliableMKT(string symbol, int cmd, double volume, double price,
					  int slippage, double stoploss, double takeprofit,
					  string comment, int magic, datetime expiration = 0, 
					  color arrow_color = CLR_NONE) 
{

	// ------------------------------------------------
	// Check basic conditions see if trade is possible. 
	// ------------------------------------------------
	OrderReliable_Fname = "OrderSendReliableMKT";
	OrderReliablePrint(" attempted " + OrderReliable_CommandString(cmd) + " " + volume + 
						" lots @" + price + " sl:" + stoploss + " tp:" + takeprofit); 

   if ((cmd != OP_BUY) && (cmd != OP_SELL)) {
      OrderReliablePrint("Improper non market-order command passed.  Nothing done.");
      _OR_err = ERR_MALFUNCTIONAL_TRADE; 
      return(-1);
   }

	if (!IsConnected()) 
	{
		OrderReliablePrint("error: IsConnected() == false");
		_OR_err = ERR_NO_CONNECTION; 
		return(-1);
	}
	
	if (IsStopped()) 
	{
		OrderReliablePrint("error: IsStopped() == true");
		_OR_err = ERR_COMMON_ERROR; 
		return(-1);
	}
	
	int cnt = 0;
	while(!IsTradeAllowed() && cnt < retry_attempts) 
	{
		OrderReliable_SleepRandomTime(sleep_time, sleep_maximum); 
		cnt++;
	}
	
	if (!IsTradeAllowed()) 
	{
		OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
		_OR_err = ERR_TRADE_CONTEXT_BUSY; 

		return(-1);  
	}

	// Normalize all price / stoploss / takeprofit to the proper # of digits.
	int digits = MarketInfo(symbol, MODE_DIGITS);
	if (digits > 0) 
	{
		price = NormalizeDouble(price, digits);
		stoploss = NormalizeDouble(stoploss, digits);
		takeprofit = NormalizeDouble(takeprofit, digits); 
	}
	
	if (stoploss != 0) 
		OrderReliable_EnsureValidStop(symbol, price, stoploss); 

	int err = GetLastError(); // clear the global variable.  
	err = 0; 
	_OR_err = 0; 
	bool exit_loop = false;
	
	// limit/stop order. 
	int ticket=-1;

	// we now have a market order.
	err = GetLastError(); // so we clear the global variable.  
	err = 0; 
	_OR_err = 0; 
	ticket = -1;

	if ((cmd == OP_BUY) || (cmd == OP_SELL)) 
	{
		cnt = 0;
		while (!exit_loop) 
		{
			if (IsTradeAllowed()) 
			{
            double pnow = price;
            int slippagenow = slippage;
            if (cmd == OP_BUY) {
            	// modification by Paul Hampton-Smith to replace RefreshRates()
               pnow = NormalizeDouble(MarketInfo(symbol,MODE_ASK),MarketInfo(symbol,MODE_DIGITS)); // we are buying at Ask
               if (pnow > price) {
                  slippagenow = slippage - (pnow-price)/Point; 
               }
            } else if (cmd == OP_SELL) {
            	// modification by Paul Hampton-Smith to replace RefreshRates()
               pnow = NormalizeDouble(MarketInfo(symbol,MODE_BID),MarketInfo(symbol,MODE_DIGITS)); // we are buying at Ask
               if (pnow < price) {
                  // moved in an unfavorable direction
                  slippagenow = slippage - (price-pnow)/Point;
               }
            }
            if (slippagenow > slippage) slippagenow = slippage; 
            if (slippagenow >= 0) {
            
				   ticket = OrderSend(symbol, cmd, volume, pnow, slippagenow, 
									stoploss, takeprofit, comment, magic, 
									expiration, arrow_color);
			   	err = GetLastError();
			   	_OR_err = err; 
			  } else {
			      // too far away, manually signal ERR_INVALID_PRICE, which
			      // will result in a sleep and a retry. 
			      err = ERR_INVALID_PRICE;
			      _OR_err = err; 
			  }
			} 
			else 
			{
				cnt++;
			} 
			switch (err) 
			{
				case ERR_NO_ERROR:
					exit_loop = true;
					break;
					
				case ERR_SERVER_BUSY:
				case ERR_NO_CONNECTION:
				case ERR_INVALID_PRICE:
				case ERR_OFF_QUOTES:
				case ERR_BROKER_BUSY:
				case ERR_TRADE_CONTEXT_BUSY: 
					cnt++; // a retryable error
					break;
					
				case ERR_PRICE_CHANGED:
				case ERR_REQUOTE:
					// Paul Hampton-Smith removed RefreshRates() here and used MarketInfo() above instead
					continue; // we can apparently retry immediately according to MT docs.
					
				default:
					// an apparently serious, unretryable error.
					exit_loop = true;
					break; 
					
			}  // end switch 

			if (cnt > retry_attempts) 
			 	exit_loop = true; 
			 	
			if (!exit_loop) 
			{
				OrderReliablePrint("retryable error (" + cnt + "/" + 
									retry_attempts + "): " + OrderReliableErrTxt(err)); 
				OrderReliable_SleepRandomTime(sleep_time,sleep_maximum); 
			}
			
			if (exit_loop) 
			{
				if (err != ERR_NO_ERROR) 
				{
					OrderReliablePrint("non-retryable error: " + OrderReliableErrTxt(err)); 
				}
				if (cnt > retry_attempts) 
				{
					OrderReliablePrint("retry attempts maxed at " + retry_attempts); 
				}
			}
		}
		
		// we have now exited from loop. 
		if (err == ERR_NO_ERROR) 
		{
			OrderReliablePrint("apparently successful OP_BUY or OP_SELL order placed, details follow.");
			OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
			OrderPrint(); 
			return(ticket); // SUCCESS! 
		} 
		OrderReliablePrint("failed to execute OP_BUY/OP_SELL, after " + cnt + " retries");
		OrderReliablePrint("failed trade: " + OrderReliable_CommandString(cmd) + " " + symbol + 
							"@" + price + " tp@" + takeprofit + " sl@" + stoploss); 
		OrderReliablePrint("last error: " + OrderReliableErrTxt(err)); 
		return(-1); 
	}
}
		
	
//=============================================================================
//							 OrderModifyReliable()
//
//  This is intended to be a drop-in replacement for OrderModify() which, 
//  one hopes, is more resistant to various forms of errors prevalent 
//  with MetaTrader.
//			  
//  RETURN VALUE: 
//
//       TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//
//     * Re-trying under some error conditions, sleeping a random 
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//
//  Matt Kennel, 	2006-05-28
//
//=============================================================================
bool OrderModifyReliable(int ticket, double price, double stoploss, 
						 double takeprofit, datetime expiration, 
						 color arrow_color = CLR_NONE) 
{
	OrderReliable_Fname = "OrderModifyReliable";

	OrderReliablePrint(" attempted modify of #" + ticket + " price:" + price + 
						" sl:" + stoploss + " tp:" + takeprofit); 

	if (!IsConnected()) 
	{
		OrderReliablePrint("error: IsConnected() == false");
		_OR_err = ERR_NO_CONNECTION; 
		return(false);
	}
	
	if (IsStopped()) 
	{
		OrderReliablePrint("error: IsStopped() == true");
		return(false);
	}
	
	int cnt = 0;
	while(!IsTradeAllowed() && cnt < retry_attempts) 
	{
		OrderReliable_SleepRandomTime(sleep_time,sleep_maximum); 
		cnt++;
	}
	if (!IsTradeAllowed()) 
	{
		OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
		_OR_err = ERR_TRADE_CONTEXT_BUSY; 
		return(false);  
	}


	
	if (false) {
		 // This section is 'nulled out', because
		 // it would have to involve an 'OrderSelect()' to obtain
		 // the symbol string, and that would change the global context of the
		 // existing OrderSelect, and hence would not be a drop-in replacement
		 // for OrderModify().
		 //
		 // See OrderModifyReliableSymbol() where the user passes in the Symbol 
		 // manually.
		 
		 OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
		 string symbol = OrderSymbol();
		 int digits = MarketInfo(symbol,MODE_DIGITS);
		 if (digits > 0) {
			 price = NormalizeDouble(price,digits);
			 stoploss = NormalizeDouble(stoploss,digits);
			 takeprofit = NormalizeDouble(takeprofit,digits); 
		 }
		 if (stoploss != 0) OrderReliable_EnsureValidStop(symbol,price,stoploss); 
	}



	int err = GetLastError(); // so we clear the global variable.  
	err = 0; 
	_OR_err = 0; 
	bool exit_loop = false;
	cnt = 0;
	bool result = false;
	
	while (!exit_loop) 
	{
		if (IsTradeAllowed()) 
		{
			result = OrderModify(ticket, price, stoploss, 
								 takeprofit, expiration, arrow_color);
			err = GetLastError();
			_OR_err = err; 
		} 
		else 
			cnt++;

		if (result == true) 
			exit_loop = true;

		switch (err) 
		{
			case ERR_NO_ERROR:
				exit_loop = true;
				break;
				
			case ERR_NO_RESULT:
				// modification without changing a parameter. 
				// if you get this then you may want to change the code.
				exit_loop = true;
				break;
				
			case ERR_SERVER_BUSY:
			case ERR_NO_CONNECTION:
			case ERR_INVALID_PRICE:
			case ERR_OFF_QUOTES:
			case ERR_BROKER_BUSY:
			case ERR_TRADE_CONTEXT_BUSY: 
			case ERR_TRADE_TIMEOUT:		// for modify this is a retryable error, I hope. 
				cnt++; 	// a retryable error
				break;
				
			case ERR_PRICE_CHANGED:
			case ERR_REQUOTE:
				RefreshRates();
				continue; 	// we can apparently retry immediately according to MT docs.
				
			default:
				// an apparently serious, unretryable error.
				exit_loop = true;
				break; 
				
		}  // end switch 

		if (cnt > retry_attempts) 
			exit_loop = true; 
			
		if (!exit_loop) 
		{
			OrderReliablePrint("retryable error (" + cnt + "/" + retry_attempts + 
								"): "  +  OrderReliableErrTxt(err)); 
			OrderReliable_SleepRandomTime(sleep_time,sleep_maximum); 
			RefreshRates(); 
		}
		
		if (exit_loop) 
		{
			if ((err != ERR_NO_ERROR) && (err != ERR_NO_RESULT)) 
				OrderReliablePrint("non-retryable error: "  + OrderReliableErrTxt(err)); 

			if (cnt > retry_attempts) 
				OrderReliablePrint("retry attempts maxed at " + retry_attempts); 
		}
	}  
	
	// we have now exited from loop. 
	if ((result == true) || (err == ERR_NO_ERROR)) 
	{
		OrderReliablePrint("apparently successful modification order, updated trade details follow.");
		OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
		OrderPrint(); 
		return(true); // SUCCESS! 
	} 
	
	if (err == ERR_NO_RESULT) 
	{
		OrderReliablePrint("Server reported modify order did not actually change parameters.");
		OrderReliablePrint("redundant modification: "  + ticket + " " + symbol + 
							"@" + price + " tp@" + takeprofit + " sl@" + stoploss); 
		OrderReliablePrint("Suggest modifying code logic to avoid."); 
		return(true);
	}
	
	OrderReliablePrint("failed to execute modify after " + cnt + " retries");
	OrderReliablePrint("failed modification: "  + ticket + " " + symbol + 
						"@" + price + " tp@" + takeprofit + " sl@" + stoploss); 
	OrderReliablePrint("last error: " + OrderReliableErrTxt(err)); 
	
	return(false);  
}
 
 
//=============================================================================
//                         OrderModifyReliableSymbol()
//
//  This has the same calling sequence as OrderModify() except that the 
//  user must provide the symbol.
//
//  This function will then be able to ensure proper normalization and 
//  stop levels.
//
//=============================================================================
bool OrderModifyReliableSymbol(string symbol, int ticket, double price, 
							   double stoploss, double takeprofit, 
							   datetime expiration, color arrow_color = CLR_NONE) 
{
	int digits = MarketInfo(symbol, MODE_DIGITS);
	
	if (digits > 0) 
	{
		price = NormalizeDouble(price, digits);
		stoploss = NormalizeDouble(stoploss, digits);
		takeprofit = NormalizeDouble(takeprofit, digits); 
	}
	
	if (stoploss != 0) 
		OrderReliable_EnsureValidStop(symbol, price, stoploss); 
		
	return(OrderModifyReliable(ticket, price, stoploss, 
								takeprofit, expiration, arrow_color)); 
	
}
 
 
//=============================================================================
//                            OrderCloseReliable()
//
//  This is intended to be a drop-in replacement for OrderClose() which, 
//  one hopes, is more resistant to various forms of errors prevalent 
//  with MetaTrader.
//			  
//  RETURN VALUE: 
//
//       TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//
//     * Re-trying under some error conditions, sleeping a random 
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//
//  Derk Wehler, ashwoods155@yahoo.com | 2006-07-19
//
//=============================================================================
bool OrderCloseReliable(int ticket, double lots, double price, 
						int slippage, color arrow_color = CLR_NONE) 
{
	int nOrderType;
	string strSymbol;
	OrderReliable_Fname = "OrderCloseReliable";
	
	OrderReliablePrint(" attempted close of #" + ticket + " price:" + price + 
						" lots:" + lots + " slippage:" + slippage); 

	// collect details of order so that we can use GetMarketInfo later if needed
	if (!OrderSelect(ticket,SELECT_BY_TICKET))
	{
		_OR_err = GetLastError();		
		OrderReliablePrint("error: " + ErrorDescription(_OR_err));
		return(false);
	}
	else
	{
		nOrderType = OrderType();
		strSymbol = Symbol();
	}

	if (nOrderType != OP_BUY && nOrderType != OP_SELL)
	{
		_OR_err = ERR_INVALID_TICKET;
		OrderReliablePrint("error: trying to close ticket #" + ticket + ", which is " + OrderReliable_CommandString(nOrderType) + ", not OP_BUY or OP_SELL");
		return(false);
	}

	if (!IsConnected()) 
	{
		OrderReliablePrint("error: IsConnected() == false");
		_OR_err = ERR_NO_CONNECTION; 
		return(false);
	}
	
	if (IsStopped()) 
	{
		OrderReliablePrint("error: IsStopped() == true");
		return(false);
	}

	
	int cnt = 0;
/*	
	Commented out by Paul Hampton-Smith due to a bug in MT4 that sometimes incorrectly returns IsTradeAllowed() = false
	while(!IsTradeAllowed() && cnt < retry_attempts) 
	{
		OrderReliable_SleepRandomTime(sleep_time,sleep_maximum); 
		cnt++;
	}
	if (!IsTradeAllowed()) 
	{
		OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
		_OR_err = ERR_TRADE_CONTEXT_BUSY; 
		return(false);  
	}
*/

	int err = GetLastError(); // so we clear the global variable.  
	err = 0; 
	_OR_err = 0; 
	bool exit_loop = false;
	cnt = 0;
	bool result = false;
	
	while (!exit_loop) 
	{
		if (IsTradeAllowed()) 
		{
			result = OrderClose(ticket, lots, price, slippage, arrow_color);
			err = GetLastError();
			_OR_err = err; 
		} 
		else 
			cnt++;

		if (result == true) 
			exit_loop = true;

		switch (err) 
		{
			case ERR_NO_ERROR:
				exit_loop = true;
				break;
				
			case ERR_SERVER_BUSY:
			case ERR_NO_CONNECTION:
			case ERR_INVALID_PRICE:
			case ERR_OFF_QUOTES:
			case ERR_BROKER_BUSY:
			case ERR_TRADE_CONTEXT_BUSY: 
			case ERR_TRADE_TIMEOUT:		// for modify this is a retryable error, I hope. 
				cnt++; 	// a retryable error
				break;
				
			case ERR_PRICE_CHANGED:
			case ERR_REQUOTE:
				continue; 	// we can apparently retry immediately according to MT docs.
				
			default:
				// an apparently serious, unretryable error.
				exit_loop = true;
				break; 
				
		}  // end switch 

		if (cnt > retry_attempts) 
			exit_loop = true; 
			
		if (!exit_loop) 
		{
			OrderReliablePrint("retryable error (" + cnt + "/" + retry_attempts + 
								"): "  +  OrderReliableErrTxt(err)); 
			OrderReliable_SleepRandomTime(sleep_time,sleep_maximum); 
			// Added by Paul Hampton-Smith to ensure that price is updated for each retry
			if (nOrderType == OP_BUY)  price = NormalizeDouble(MarketInfo(strSymbol,MODE_BID),MarketInfo(strSymbol,MODE_DIGITS));
			if (nOrderType == OP_SELL) price = NormalizeDouble(MarketInfo(strSymbol,MODE_ASK),MarketInfo(strSymbol,MODE_DIGITS));
		}
		
		if (exit_loop) 
		{
			if ((err != ERR_NO_ERROR) && (err != ERR_NO_RESULT)) 
				OrderReliablePrint("non-retryable error: "  + OrderReliableErrTxt(err)); 

			if (cnt > retry_attempts) 
				OrderReliablePrint("retry attempts maxed at " + retry_attempts); 
		}
	}  
	
	// we have now exited from loop. 
	if ((result == true) || (err == ERR_NO_ERROR)) 
	{
		OrderReliablePrint("apparently successful modification order, updated trade details follow.");
		OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
		OrderPrint(); 
		return(true); // SUCCESS! 
	} 
	
	OrderReliablePrint("failed to execute close after " + cnt + " retries");
	OrderReliablePrint("failed close: Ticket #" + ticket + ", Price: " + 
						price + ", Slippage: " + slippage); 
	OrderReliablePrint("last error: " + OrderReliableErrTxt(err)); 
	
	return(false);  
}
 
 

//=============================================================================
//=============================================================================
//								Utility Functions
//=============================================================================
//=============================================================================



int OrderReliableLastErr() 
{
	return (_OR_err); 
}


string OrderReliableErrTxt(int err) 
{
	return ("" + err + ":" + ErrorDescription(err)); 
}


void OrderReliablePrint(string s) 
{
	// Print to log prepended with stuff;
	if (!(IsTesting() || IsOptimization())) Print(OrderReliable_Fname + " " + OrderReliableVersion + ":" + s);
}


string OrderReliable_CommandString(int cmd) 
{
	if (cmd == OP_BUY) 
		return("OP_BUY");

	if (cmd == OP_SELL) 
		return("OP_SELL");

	if (cmd == OP_BUYSTOP) 
		return("OP_BUYSTOP");

	if (cmd == OP_SELLSTOP) 
		return("OP_SELLSTOP");

	if (cmd == OP_BUYLIMIT) 
		return("OP_BUYLIMIT");

	if (cmd == OP_SELLLIMIT) 
		return("OP_SELLLIMIT");

	return("(CMD==" + cmd + ")"); 
}


//=============================================================================
//                        OrderReliable_EnsureValidStop()
//
//  Adjust stop loss so that it is legal.
//
//  Matt Kennel 
//
//=============================================================================
void OrderReliable_EnsureValidStop(string symbol, double price, double& sl) 
{
	// Return if no S/L
	if (sl == 0) 
		return;
	
	double servers_min_stop = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT); 
	
	if (MathAbs(price - sl) <= servers_min_stop) 
	{
		// we have to adjust the stop.
		if (price > sl)
			sl = price - servers_min_stop;	// we are long
			
		else if (price < sl)
			sl = price + servers_min_stop;	// we are short
			
		else
			OrderReliablePrint("EnsureValidStop: error, passed in price == sl, cannot adjust"); 
			
		sl = NormalizeDouble(sl, MarketInfo(symbol, MODE_DIGITS)); 
	}
}


//=============================================================================
//                      OrderReliable_SleepRandomTime()
//
//  This sleeps a random amount of time defined by an exponential 
//  probability distribution. The mean time, in Seconds is given 
//  in 'mean_time'.
//
//  This is the back-off strategy used by Ethernet.  This will 
//  quantize in tenths of seconds, so don't call this with a too 
//  small a number.  This returns immediately if we are backtesting
//  and does not sleep.
//
//  Matt Kennel mbkennelfx@gmail.com.
//
//=============================================================================
void OrderReliable_SleepRandomTime(double mean_time, double max_time) 
{
	if (IsTesting()) 
		return; 	// return immediately if backtesting.

	double tenths = MathCeil(mean_time / 0.1);
	if (tenths <= 0) 
		return; 
	 
	int maxtenths = MathRound(max_time/0.1); 
	double p = 1.0 - 1.0 / tenths; 
	  
	Sleep(100); 	// one tenth of a second PREVIOUS VERSIONS WERE STUPID HERE. 
	
	for(int i=0; i < maxtenths; i++)  
	{
		if (MathRand() > p*32768) 
			break; 
			
		// MathRand() returns in 0..32767
		Sleep(100); 
	}
}  




