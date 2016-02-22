
/*»»» MetaQuote [ MQ 4 ] »»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»    IDENTIFICATION DIVISION    ««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««

                    Program Name            ~~~  GAMMA BREAK OUT
                    System Symbol           ~~~  GBO
                    Author                  ~~~  Keit Thomas Largo
                    Produced For            ~~~  WinSoft Technology ®
                    Module Type             ~~~  Expert Advisor
                    Date Writen             ~~~  11/23/2005
                    Last UpDate             ~~~  12/21/2005
                    Version	Number     		~~~  1.22b {Beta}
                    Program Language		~~~  MetaQuote ® MQL v4.00
                    Script Language 		~~~  Lore Language ® v2.60
                    Security Level     		~~~  {none}
                    Documentation           ~~~  see Documentation Division


// 	««« COPYRIGHT NOTICE: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»


                   This program is the rewriten and reorginized script of an
                   existing code found on the StrategyBuilderFX Forum, writen
                   by Fukinagashi. An Expert entitled Hans123Trader Versions
                   1 through 8. Credit for this system goes to both Hans123 and 
                   Fukinagashi. The name was changed as a means to distinguish
                   it from the other series of EAs posted on the thread.Check
                   out the following link for more details on the system.

                     www.strategybuilderfx.com/forums/showthread.php?t=15439


                                  ~~~ Keit Thomas Largo ~~~


//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»    ENVIRONMENT DIVISION    ««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««*/

    // ««« FILE LINKAGE SECTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

            #include     <Append File/Lore Language v2.60>
            #import      "MetaQuote RunTime Module"
            #import      "MetaQuote Communications Module"
            #import      "GAMMA System Module"
            #import      "GAMMA GUI Module"


    // ««« SYSTEM DEFINED CONSTANT SECTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

            #define      Warning          "Warning ..... THIS IS A BETA TEST VERSION"
            #define      ProgramName      "GAMMA BREAK OUT"
            #define      SystemSymbol     "GBO"


    // ««« EXTERN INPUT PARAMETER SECTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

        extern bool
            ExitLossingTrades    = False,      ExitAllTrades       = True,
            ProtectInvestments   = True,       ExitOnStopsOnly     = False;

        extern string
            TradeTimeSession1    = "09:00",    TradeTimeSession2   = "13:00",     
            TradeEndTime         = "22:00";

        extern double
            ChannelDataWindow    =  Four;

        extern int
            DealerTimeOffSet     =  Zero,      ScreenInformation   = EntireList;


    // ««« SYSTEM DEFAULT PARAMETER SECTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        // Changing the system's default parameters will alter the system's functionality.

        bool
            MarketOrderPermitted =     True,   // Permits market orders if pending at market.

            TradeOneSessionOnly  =     False,  // RD!{Remove when the three markets are defined}:

            TradeAsianMarket     =     False,  // RD!{will trade during the Asian markets}:

            TradeEuropeMarket    =     True,   // RD!{will trade the London market time}:

            TradeUSAMarket       =     True,   // RD!{Will trade the US markets}:

            SpreadAdjusted       =    False,   // Adjusts the high range for the Bid Ask spread.

            MainChartGraphics    =     True,   // Display real time graphics on main chart plain.

            HeadgeDisallowed     =     False,  // RD!{adjust system for broker rules on headging}:

            UseTrailingStops     =     False,  // RD!{addition of Gamma trailing stop function}:

            EmailAlerts          =     False;  // RD!{ add functionality of email alerts}:


        int
            PauseInterval        =      10000, // Pause interval between order placements (10sec).

     //     ScreenInformation    = EntireList, // Switches system debug information. MOVED UP

            MaximumAttempts      =        Two; // repeats order execution on failed attempt.


        datetime
            OrderWindowLength    =      Three; // The order placment Window size, in minutes.


    // ««« GLOBAL SCOPE VARIABLE SECTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

        int
            Leverage          =   Empty,       PipsForEntry      =   Empty,
            DataWindowAdjust  =   Empty,       LocalTimeOffSet   =   Empty,
            CurrentGMTime     =   Empty,       OrderID           =   Empty,
            ShowGraphics      =   Empty;

        double
            InitialStopLoss   =   Empty,       StopLoss          =   Empty,
            SetBreakEvenStop  =   Empty,       BreakEvenStop     =   Empty,
            SetTrailingStop   =   Empty,       TrailingStop      =   Empty,
            TakeProfitLevel   =   Empty,       TakeProfit        =   Empty,
            Slippage          =   Empty,       Lots              =   Empty,
            OpeningPrice      =   Empty,       DealerSpread      =   Empty,
            LowestPrice       =   Empty,       HighestPrice      =   Empty,
            HighRange1        =   Empty,       LowRange1         =   Empty,
            HighRange2        =   Empty,       LowRange2         =   Empty;

        string
            OrderDesk         =   Clear,       SystemStartTime   =   Clear;

        datetime
            OrderTimeSession1 =   Empty,       OrderTimeSession2 =   Empty,
            LocalTimeSession1 =   Empty,       LocalTimeSession2 =   Empty,
            StartDataWindow1  =   Empty,       StartDataWindow2  =   Empty,
            LocalQuitingTime  =   Empty,       TradeQuitingTime  =   Empty,
            OrderExpires      =   Empty,       TradersLocalTime  =   Empty,
            OrderWindow       =   Empty;

        bool
            AccountAvailable  =  False,        Pattern           =   False;

        color
            NumberColor       =  Empty,         BulletColor       =   Empty;


    // ««« GLOBAL SCOPE ARRAYS SECTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

        int
            Order[ Five ];                   ArrayInitialize( Order, False );

        double
            AccountRegister[ Five, Ten ];    ArrayInitialize( AccountRegister, Empty );


//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»    CONFIGURATION DIVISION    «««««««««««««««««««««««««««««««««««
void init(){//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««

    // ««« DATA LINKAGE SECTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

        DefaultColor   = CLR_NONE;

        CurrencySymbol =  GetSymbolID( Symbol() ); 

        ShowGraphics   =  ( One | Two | Four | Eight | Sixteen );

        Leverage       =  AccountLeverage(); // RD!{Part of future MM}:

        OrderDesk      =  DoubleToStr( AccountNumber(), Zero );


        //«« <<<< Time Initialization >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

            OrderWindow       = ( OrderWindowLength * seconds );
            DealerTimeOffSet  = ( DealerTimeOffSet * hour );
            SystemStartTime   = ( TimeToStr( LocalTime(), TIME_MINUTES ));
            LocalTimeOffSet   = ( LocalTime() - ( CurTime() - DealerTimeOffSet )); 
            DataWindowAdjust  = ( -One * ( DealerTimeOffSet + ( ChannelDataWindow * hour )));

            StartDataWindow1  = InitializeTime( TradeTimeSession1, DataWindowAdjust );
            OrderTimeSession1 = InitializeTime( TradeTimeSession1, DealerTimeOffSet );
            LocalTimeSession1 = InitializeTime( TradeTimeSession1, LocalTimeOffSet  );

            StartDataWindow2  = InitializeTime( TradeTimeSession2, DataWindowAdjust );
            OrderTimeSession2 = InitializeTime( TradeTimeSession2, DealerTimeOffSet );
            LocalTimeSession2 = InitializeTime( TradeTimeSession2, LocalTimeOffSet  );

            TradeQuitingTime  = InitializeTime( TradeEndTime );
            OrderExpires      = InitializeTime( TradeEndTime, DealerTimeOffSet );
            LocalQuitingTime  = InitializeTime( TradeEndTime, LocalTimeOffSet  );


    // ««« DATA VALIDATION SECTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        // RD!{temp coding block; Rights To Trade and Initialized code}:

        if(  ! ExitLossingTrades && ! ExitAllTrades ) {
            Print( "System Trading Rights DENIED. The two Exits strategies are both " +
                    "OFF [must turn one on]" );
        } else if( Period() >= ( ChannelDataWindow * minutes )) {
            Print( "System Trading Rights DENIED. The Data Period Used In " +
                    "Chart Is Too Large For This System Parameters." );
        } else if( TradeQuitingTime  < ( CurTime() - DealerTimeOffSet )) {
            Print( "System Trading Rights DENIED. The setting of TradeQuitingTime " +
                    "is out of range, [must be set higher then the current time]" );
        } else if( ! IsTradeAllowed() ){
            Print( "System Trading Rights DENIED. Expert Trading not allowed. Set the " +
                    "Trade switch ON in Expert Property Dialog Box." );
        } else if( ! IsDllsAllowed() || ! IsLibrariesAllowed() ) {
            Print( "System Trading Rights DENIED. You must switch ON to allow external " +
                    "DLLs and libraries imports in the Expert Property Dialog box.");
        } else {
            RightsToTrading = Granted;
            Print( "System Trading Rights GRANTED. Trading " + Symbol() +
                    " will start at Set GMT time" );
        } // End If:

        // RD!{have to check for experaition time has to be more then xx minutes form orders}:


    // ««« FILTERS, RESTRAINS AND DEVIATIONS SECTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

            switch( CurrencySymbol ) {  
                case EURUSD:
                    PipsForEntry     =   5;
                    SetBreakEvenStop =  30;
                    TakeProfitLevel  =  80;
                    InitialStopLoss  =  50;
                    SetTrailingStop  =   0;
                    Slippage         =   3;
                    break;
                case GBPUSD:
                    PipsForEntry     =   5;
                    SetBreakEvenStop =  40;
                    TakeProfitLevel  = 120;
                    InitialStopLoss  =  70;
                    SetTrailingStop  =   0;
                    Slippage         =   3;
                    break;
                case USDCHF:
                    PipsForEntry     =  10;
                    SetBreakEvenStop =  30;
                    TakeProfitLevel  = 100;
                    InitialStopLoss  =  50;
                    SetTrailingStop  =   0;
                    Slippage         =   3;
                    break;
                case OTHERS:
                    PipsForEntry     =   5;
                    SetBreakEvenStop =  40;
                    TakeProfitLevel  = 120;
                    InitialStopLoss  =  50;
                    SetTrailingStop  =   0;
                    Slippage         =   3;
                    break;
            } // End Switch, CurrencySymbol:


            if( RightsToTrading == Granted ) {
                SystemTag       =  GetTagNumber();
                SystemMode      =  StandBy;
                SystemIdentity  =  ( SystemTag + Dash + SystemSymbol + Dash +
                                     CurrencySymbol + Dash + SystemStartTime );
            } // End If, RightsToTrading:


            if( SpreadAdjusted ) {
                DealerSpread = ( MarketInfo( Symbol(), BidAskSpread ) * Point );
            } else {
                DealerSpread = Zero;
            } // End If, SpreadAdjusted:


            ObjectsDeleteAll( MainPriceGraph );


    // RD!{add Initialized Stage Failure will disable expert}: 
    // RD!{add check for possible system restart error and resum the existing Identity profile}:


return;}//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»    CODING DIVISION    «««««««««««««««««««««««««««««««««««««««
void start(){//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««

//«« LABEL 100 »» LOCAL SCOPE DATA ASSIGNMENT: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

        int 
            Counter       =  Zero,           Index         =  Zero,
            Total         =  Zero,           Record        =  Zero;


        string
            TitleLine     =  Clear,          BiLine        =  Clear;


            TradersLocalTime  = LocalTime();

            CurrentGMTime     = ( CurTime() - DealerTimeOffSet );


//«« LABEL 200 »» TRADING RIGHTS CONCEDED: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
    // RD!{version requires manual startup / reboot each day, no continual trade feather}:

        if( RightsToTrading && ! IsDemo() ) { // RD!{temperary code block}:
            RightsToTrading = Halted;
            Print( "v 1.22b: This code has not been fully beta tested and should not " +
                    " be traded on a live account. Trading Rights Halted" );
            return;
         } // End If:


//«« LABEL 300 »» LOT SIZING AND MONEY MANAGMENT: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
    // RD!{this version has no MM strategy}:

        Lots = One;

        if( AccountFreeMargin() < ( 1000 * Lots )) return;


//«« LABEL 400 »» TRADE SIGNAL DEVELOPMENT: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»


//«« LABEL 500 »» POSITIONS ASSESSMENT: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

    //«« <<<< Segment 510 >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        // Code to close open market orders based on Gamma greek trailing stop.

            // RD!{feather not included in version 1.2x}:


    //«« <<<< Segment 520 >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        // Code to close open market orders and repeal pending orders at closing time.

        if( ! OrdersTotal() == Empty && CurrentGMTime > TradeQuitingTime ) {
            for( Counter = Zero; Counter <= OrdersTotal(); Counter = Counter + One ) {
                if( OrderSelect( Counter, SELECT_BY_POS, MODE_TRADES ) == False ) continue;
                for( Record = Zero; Record <= Four; Record = Record + One ) {
                    if( OrderMagicNumber() == (( SystemTag * Ten ) + Record )) {
                        switch( OrderType() ) {
                            case BuyLong:
                                if( ExitAllTrades ) {
                                    TerminatePoistion( OrderTicket(), Bid );
                                } else if( ExitLossingTrades ) {
                                    if( OrderOpenPrice() > Bid ) {
                                        TerminatePoistion( OrderTicket(), Bid );
                                    } // End If, Bid:
                                } else { // RD!{add ErrorHandler}:
                                } // End If, ExitAllTrades:
                                break;
                            case SellShort:
                                if( ExitAllTrades ) {
                                    TerminatePoistion( OrderTicket(), Ask );
                                } else if( ExitLossingTrades ) {
                                    if( OrderOpenPrice() < Ask ) {
                                        TerminatePoistion( OrderTicket(), Ask );
                                    } // End If, Ask:
                                } else { // RD!{add ErrorHandler}:
                                } // End If, ExitAllTrades:
                                break;
                            default: // RD!{Pending orders expire, add ErrorHandler}:
                                DeletePosition( OrderTicket() );
                        } // End Switch Case, OrderType:
                    } // End If, OrderMagicNumber:
                } // End For Loop, Record:
            } // End For Loop, Counter:
        } // End If, OrdersTotal:


    //«« <<<< Segment 530 >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        //   Code to manage and modify trailing stop to break even on profitable orders.

        if( ! OrdersTotal() == Empty && CurrentGMTime >= OrderTimeSession1 ) {
            for( Counter = Zero; Counter <= OrdersTotal(); Counter = Counter + One ) {
                if( OrderSelect( Counter, SELECT_BY_POS, MODE_TRADES ) == False ) continue;
                for( Record = Zero; Record <= Four; Record = Record + One ) {
                    if( OrderMagicNumber() == ( SystemTag * Ten ) + Record ) {
                        if( ProtectInvestments && ( OrderStopLoss() != OrderOpenPrice())) {
                            if( OrderType() == BuyLong && ( Bid - OrderOpenPrice() ) >
                                    ( SetBreakEvenStop * Point )) {
                                BreakEvenStop = OrderOpenPrice();
                                UpDatePosition( OrderTicket(), BreakEvenStop );
                            } else if( OrderType() == SellShort && ( OrderOpenPrice() - Ask ) >
                                    ( SetBreakEvenStop * Point )) {
                                BreakEvenStop = OrderOpenPrice();
                                UpDatePosition( OrderTicket(), BreakEvenStop );
                            } // End If, OrderType:
                        } // End If, ProtectInvestments:
                    } // End If, OrderMagicNumber:
                } // End For Loop, Record:
            } // End For Loop, Counter:
        } // End If, OrdersTotal:


    //«« <<<< Segment 540 >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        // Code to place all Pending orders.

            if( OrderWindowOpen( OrderTimeSession1, OrderWindow )) {
                if( ! Order[ One ] ) {
                    OrderID      =  (( SystemTag * Ten ) + One );
                    InstituteTradeParameters( BuyStop );
                    HighRange1   =  OpeningPrice;
                    OpeningPrice =  ( OpeningPrice + DealerSpread );
                    EstablishPosition( BuyStop );
                } // End If, Order[ One ]:
                if( ! Order[ Two ] ) {
                    OrderID    =  (( SystemTag * Ten ) + Two );
                    InstituteTradeParameters( SellStop );
                    LowRange1  =   OpeningPrice;
                    EstablishPosition( SellStop );
                } // End If, Order[ Two ]:
            } else if( OrderWindowOpen( OrderTimeSession2, OrderWindow )) {
                if( ! Order[ Three ] ) {
                    OrderID      =  (( SystemTag * Ten ) + Three );
                    InstituteTradeParameters( BuyStop );
                    HighRange2   =  OpeningPrice;
                    OpeningPrice =  ( OpeningPrice + DealerSpread );
                    EstablishPosition( BuyStop );
                } // End If, Order[ Three ]:
                if( ! Order[ Four ] ) {
                    OrderID    =  (( SystemTag * Ten ) + Four );
                    InstituteTradeParameters( SellStop );
                    LowRange2  =   OpeningPrice;
                    EstablishPosition( SellStop );
                } // End If, Order[ Four ]:
            } // End If, OrderWindowOpen:


//«« LABEL 600 »» TRADE TRACKING REGISTER: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

        if( ! OrdersTotal() == Empty ) {
            for( Index = Zero; Index <= OrdersTotal(); Index = Index + One ) {
                if( OrderSelect( Index, SELECT_BY_POS, MODE_TRADES ) == False ) continue;
                    for( Counter = Zero; Counter <= Four; Counter = Counter + One ) {
                        if( OrderMagicNumber() == ( SystemTag * Ten ) + Counter ) {
                            Order[ Counter ] = OrderTicket();
                            break;
                        } // End If, OrderMagicNumber:
                    } // End For Loop, Counter:
            } // End For Loop, Index:
            ForwardToBackOffice( AccountRegister );
        } // End If, OrdersTotal():


//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»    OUTPUT DIVISION    ««««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««

//«« LABEL 700 »» FINANCIAL LEDGER ENTRIES: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»


//«« LABEL 800 »» COMMUNICATIONS AND LOGS TRANSMITTAL: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»


//«« LABEL 900 »» GRAPH DISPLAY AND COMMENTARY: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

    //«« <<<< Segment 910 >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        // Display Graph's title lines and any screen information selected.

        TitleLine = ( FillerLine( Eight ) + Author + FillerLine( Sixteen, Dot ) + ProducedFor +
                        NewLine + FillerLine( ThirtyTwo ) + eMail );
        BiLine    = ( SkipLine + Tab + Warning + NewLine + "System\'s RunTime Serial Number" +
                        FillerLine( Six ) + SystemIdentity );
            switch( Alternate( ScreenInformation, Four ) ){
                case Zero:
                    ExposeScreen( TitleLine, BiLine );                       break;
                case One:
                    ExposeScreen( TitleLine, BiLine, RunTimeInfo() );        break;
                case Two:
                    ExposeScreen( TitleLine, BiLine, TimeSchedule() );       break;
                case Three:
                    ExposeScreen( TitleLine, BiLine, SystemTradeInfo() );    break;
                case Four:
                    ExposeScreen( TitleLine, BiLine, FinancialTracking() );  break;
                default:
                    ExposeScreen( TitleLine );                               break;
            } // End Switch, Alternate:


    //«« <<<< Segment 920 >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        // Starts the screen graphic engine.

            if( ObjectFind( "NewDay" ) != MainPriceGraph ) {
                ExposeObject( "NewDay" );
            } else {
                if( ObjectFind( "FirstSessionGraphics" ) != MainPriceGraph ) {
                    if( CurrentGMTime >= ( OrderTimeSession1 + OrderWindow )) {
                        ExposeObject( "FirstSessionGraphics" );
                    } // End If, CurrentGMTime:
                } else if( ObjectFind( "SecondSessionGraphics" ) != MainPriceGraph ) {
                    if( CurrentGMTime >= ( OrderTimeSession2 + OrderWindow )) {
                        ExposeObject( "SecondSessionGraphics" );
                    } // End If, CurrentGMTime:
                } // End If, ObjectFind:
            } // End If, NewDay:


    //«« <<<< Segment 930 >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        // Changes display colors in real time with changes in positons.

            for( Index = Zero; Index <= Four; Index = Index + One ) {
                Record = Order[ Index ];
                if( Record == Empty ) continue;
                    NumberColor = WhiteSmoke;
                    BulletColor = WhiteSmoke;
                if( OrderSelect( Record, SELECT_BY_TICKET, MODE_TRADES ) == True ) {
                    if( OrderType() == BuyLong || OrderType() == SellShort ) {
                        if( OrderProfit() < Zero ) {
                            BulletColor = Red;
                        } else if( OrderProfit() > Zero ) {
                            BulletColor = Lime;
                            if( OrderStopLoss() == OrderOpenPrice() ) BulletColor = MediumSeaGreen;
                        } else if( OrderProfit() == Zero ) {
                            BulletColor = Yellow;
                            if( OrderStopLoss() == OrderOpenPrice() ) BulletColor = Goldenrod;
                        } // End If, OrderProfit:
                    } // End If, OrderType:
                    if( OrderCloseTime() != Empty ) {
                        NumberColor = LightSlateGray;
                        if( OrderClosePrice() != OrderOpenPrice() && OrderProfit() == Zero ) {
                            BulletColor = LightSlateGray;
                        } // End If, OrderClosePrice:
                    } // End If, OrderCloseTime:
                } else {
                    // RD!{Install ErrorHanler}:
                } // End If, OrderSelect:
                UpDateGraphics( Index, Record );
            } // End For Loop, Record:


return;}//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»    TERMINATION DIVISION     «««««««««««««««««««««««««««««««««««
void deinit(){//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««

// ««« CODE TERMINATION SECTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

            GlobalVariableDel( OrderDesk ); 


    // RD!{systemtag and global variable, reason for deInt(), ErrorHandler() to restart profile}:


return;}//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»    FUNCTION DEFINITION DIVISION    ««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««

    // All Function and Procedural Definitions are located in the "GAMMA System or GUI Modules"


//«« <<<< Routine Procedural Section >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»


//«« <<<< Function Procedures Section >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»


/*--End-Code--//»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»    DOCUMENTATION DIVISION    ««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««««««««««««««««««««««

    ««« PURPOSE, SCOPE, AND FUNCTION: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»


        NOTE
            The purpose of this version is for beta testing only, NOT to be used for trading
            on a funded account! I repeat, for use on DEMO accounts only. The author takes no
            responsiblity for use of this code. My testing so far has been to alpha testing
            the code functions only. Not in testing the system for profitablility. This system
            now can be tested on data for its profit potentials as the code appears to do what
            it should do.

        This doesnot contain a full and functional system, as no money management strategy is
        included, just a flat 1 lot wager is established on each position. There is no means
        to protect your profits in this version, protecting profits is a must on any operational
        system, here I'm not taling about BE stops but open profits.


        This version follows Hans123 rules with no deviations if your broker platform is in the
        GMT time zone then the defaults inputs can be used. If your broker is in a different zone
        then you will have to change the Dealer OffSet Variable to match that time difference of
        your dealer to that of GMT.


        Hans 123 settings in GMT time not CET.
        

            ExitLossingTrades   =   False    Will exit lossing trades but others will stay.
            ExitAllTrades       =   True     Will exit all trades at session close time.
            ProtectInvestments  =   True     Will use break even stop loss function.
            ExitOnStopsOnly     =   False    Will not close orders out except on stops

            OrderTimeSession1   =  "09:00"   This is the end of the first channel 
            OrderTimeSession2   =  "13:00"   This is the end of the second channel
            SessionCloseTime    =  "23:00"   This is the closing time for both channels
            ChannelDataWindow   =      4     This is the length of both channels.
            DealerTimeOffSet    =      0     Time off set of the dealer.



    Things to consider:
        taken from the forum;
        Lud isn't suggesting a TS from the start, only once you reach your target. He's saying,
        don't just TP there and stop the trade. Enter a TS of 10 and see if it runs some more.
        You won't hurt profits at all and might pick up some additional pips. I think it's a
        good idea. 

        My testing has shown that from Feb-May, a 60 pip limit worked quite well. More interesting
        is time in trade. Average win is 4.7 hours total all trades, 4.08 for winners. I believe
        the original system calls for a 1700 EST close. Again, I can't do this so I prefer using
        the limits. However, June-Aug required the limit to be 40-45 pips to make money. The key
        to this system, imo, is getting to break even asap. But, that's true for every system,
        isn't it?

        I beleave that the closeing time of all positions should be 18:30 GMT as almost all 
        positions turn around and reverase the trend of the day at this time.


    ««« DESCRIPTION OF PROGRAM USAGE: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

    Taken for Hans123's first post:
 
        Discription of the Hans123 BreakOut System

        Simple Combined Breakout System for EUR/USD and GBP/USD
        Determine the 06.00 CET – 10.00 CET High Low on EUR/USD and GBP/USD
        Determine the 10.00 CET – 14.00 CET High Low on EUR/USD and GBP/USD
        Set BuyStop at High + 5 pips and SellStop at Low - 5 pips for both timeframes and both
            currencies
        Set Target Price at entry + 80 pips for EUR/USD and entry + 120 pips for GBP/USD
            Set StopLoss at entry - 50 pips for EUR/USD and entry - 70 pips for GBP/USD. If the
            other side of the Breakout is within 50 pips for EUR/USD or within 70 pips for GBP/USD
            then the StopLoss will be that level (Longtrade: SL = Low range - 5 pips = SellStop;
            Shorttrade: SL = High range + 5 pips = BuyStop)
        Use a trailing stop of 30 pips for EUR/USD and a trailing stop of 40 pips for GBP/USD
        At 24.00 CET all orders expiring and close all trades at market. On Friday we do the same
            at 23.00 CET.
        I am using CET time (Amsterdam, Frankfurt).



    Time settings:

        Session times were changed to GMT. First session....6:00 am to 10:00am in Amsterdam is
        5:00 am and 9:00 am GMT and  the second session 10:00am to 14:00 pm Amsterdam time is
        9:00 am and 13:00 (1:00pm) GMT. The Session Variables reflict GMT. The session time
        inputs are the time of 'opening' the buystop and sellstop orders and not the start
        of the data channel period. Only one session length variable is used as both sessions
        have the same time data window length. This input can be parts of an hour but you must
        take in to consideration of the chart timefram in used. You don't want to put tenths of
        an hour if your useing M15 charts.

        To enter all time variables for the sessions start times and trade end time as you would
        regularly on a 24 hour clock that is 07:00 for 7am and 19:00 for 7pm. Any minute can be
        selected as in 07:12 will work.
        
        A Session Close Time Variable was added to input the time to terminate the unfilled pending
        orders, the lossing orders, and or all orders depending on other input varitables.

        The only thing left to calculate is your ( broker's ) offset to GMT. The Dealer Time
        OffSet is how meny hours the dealer platform is from GMT as in the case of
        StrategyBuilderFX its Zero. As SBFX is on GMT time. If your BROKER is on EST (NY Time)
        then you would input -5 hours as the offset. DO NOT USE YOUR LOCAL TIME HERE!
        
        Your local time is calculated from your computer clock and needs NO INPUT. If your
        computer time is wrong then the local time variables will be wrong.



    Screen Print Information:

        The printing of the screen information is for debuging purposes. There is no run time
        screen created at this time. If you want to turn off the screen print activity change
        the input variable    ScreenInformation   = 999 ( EntireList );  to  one will
        turn off the screen displays, EntireList shows all the debug screens. A number from
        zero to four here will activate different debuging screens. the run time screen is not
        completed in this version.



    Graphic out put:

        When you start the EA you will see nothing as it deletes all of the existing graphics
        when you stop, start, or compile the EA. You will know if the graphic engine is active
        by a short RED line which will appear at 00:00 hours this is a temperary indicator of
        the start of the new day, you can look to your EA Log tab also to see that the graphic
        engine has started.

        The trading range graphics ( session graphics ) donot show up till after the
        TRADE WINDOW CLOSES, for the given session time, in the case of this EA its 3 minutes
        after the order time is triggered.  This is to give serveral ticks to pass so all the
        orders are in and bookeeping is done before graphics are displayed. The shadowed areas
        (boxes) are the trade zones within the given time inputs. The numbers above and below
        the boxes are the trade TICKET numbes of your positions. (see your trade tab). The
        ones above the box is the BuyStop order and the one below is the SellStop. The BULLET
        after the the ticket number gives you the indication of the current condition of
        the order;
        
            When the TICKET number is WHITE:
                This indicates the order is still active with a bullet color of ......
                    WHITE        == active pending order which is not triggered yet.
                    Light GREEN  == order active and in the money. profitable.
                    Light Red    == order active currently at a loss. unprofitable.
                    Light YELLOW == order active and at break even.
                If the Green or Yellow are DARK in color it indicates that your Break
                    Even Stop has been moved to BE for that order. Red would not apply
                    as this would trigger the stop.

            When the TICKET number is GEAY:
                This indicates the order is closed and the bullet color is........
                    GRAY   == Pending order was closed, cancelled, or exparied, Un-Trigged.
                    GREEN  == Order is closed with a profit for the day.
                    RED    == Order is closed with a loss for the day.
                    Yellow == order is closed at Break Evern, your BE stop was hit.
                If the Green or Yellow are dark it indicates that the BE stop was
                    triggered on that order. Again no dark red.



    limitation:
        This system must be restart daily to run for any given day. It will not restart itself
        on the following day, after the current days close of trading. Future versions may have
        the ability to use script files to instruct the EA to trade for a week or more at a
        time with out interventions.

        The email icon is for the email function which is not completed in this version.


    This EA will clean up ( delete ) the graphic objects and global variables that it creates
    with the exception of a global variable called PullTab do not delete this variable as it is
    used by the system to generate a different number to track its orders and other functions.
    If you open your trade platform and go to >> Tools >> Global Variables a dialog box will
    display the global variables there you will see "PullTab (Do Not Delete)". This variable is
    like the take a number and wait in line till its called machine that you see at the dell
    case at your local food store. Each time you start the EA it pulls the next number from
    this machine, It is the first 3 numbers of the system serial number that appears on the
    screen. The number starts at 100 and goes to 999 to restart at 100 again if you delete
    it the systems will start with 100 each time.



    ««« FILES DISCRIPTIONS: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

        Do not recompile this EA, use the ex4 file supplied with the source code, This file
        doesnot contain any of the Library Modules needed for compileing the code. It is the
        low level code only. 


    ««« TESTING AND SCRIP DEBUGING: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

        Four debuging screens,
            1 = RuntimeScreen;
            2 = TimeVariables;
            3 = orderOutCome;
            4 = SystemParameterSettings;


        if(  ! ExitLossingTrades && ! ExitAllTrades ) { one has to be true or the system will
            not exit except on stoploss or takeprofits. The ExitAllTrades is the default. This
            will change with the addtion of the Gamma exit trailing stops.



    ««« VERSION UPDATES: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

    Current Revisions:

        Version 1.00a 		KTL		11-23-2005
            *	This is the original code of this expert a take from the Hans123 break out
                system, see Hans123trader_v8.
            *   Removed the 3 different Trailing Stops from the code. only trail stop to
                Break Even was left as the original rules states.
            *   Changed the sessions times to reflect GMT and Added an external variable
                to input different closeing times. This was done for uniformity, every
                ting defaults to Hans123 original system.
        Version 1.10        KTL     11-29-2005
            *   The complete rewriting of system file as there were too meny fixes to rely
                on the code. Code v1.00 was abandon.
        Version 1.15a       KTL     12-02-2005
            *   First alpha code version for testing.
            *   Wrote code block to prevent orders from being stack and not filled.
            *   Other minor bugs fixes.
        Version 1.20b 		KTL		12-12-2005
            *   The first beta version for testing. Real time graphics was included to do
                with out the need of indicator attachments.
            *   Installed the Lore Language feathers to aid in future development.
        Version 1.22b       KTL     12-21-2005
            *   This is the code released to the Strategy Builder FX Forum posted on
                Hans123 thread. code is restricted for testing only. 


    Future Enhancement:
            -   If this trade method proves to be profitable then testing as to MM and the 
                protection of trading gains should be done before any time is spend making
                this in to a finished system.
            -	Add the run time log files
            -   add the  complete ErrorHanlder Module to control errors and apply a recovery
                routine to resum the system on error.
            -   add in the the MessageCenter Module to communicate system operations to trader.
            -   introduce a ATR % price movement at the current price bar see
                BarTime() function to determine if channel is too large and a reverse
                strategy would be profitable.
            -   include the Fixed Fractional Money Management Strategy
            -   the Gamma based trailing stop Strategy.
            -   safty check for system crash and restart to resum with the exsiting
                profile on record. 
            -   if broker accepts headged orders as defaults and very operations accordinly.
            -   check on the brokers points from market to place opening order successfully
                and on the points for stops and take profits. There is a limit to when the
                order expiration can be set. to eleminate the possiblity of getting 
                ERR_INVALID_TRADE_PARAMETERS from occouring.
            -   Construct a script file to control system trading for weekly operations.
            -   add light and dark green red and yellow to indicate when the BE is treggered.



    ««« CODING, SCRIPT NOTES: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»



    ««« CODE STORAGE AREA: »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»


        //<<<--------------

        //«« <<<< Initialize >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

        //«« <<<<  >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        //«« <<<<  >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

    //«« <<<<  >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
    //«« <<<<  >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

        //«« <<<< Segment 110 >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
        //«« <<<< Segment 210 >>>> »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»


        // test data

                    HighRange1 = 1.2023;
                    LowRange1  = 1.1978;
                    HighRange2 = 1.2035;
                    LowRange2  = 1.2002;
                    Order[ 1 ] = 248204;
                    Order[ 2 ] = 248202;
                    Order[ 3 ] = 248827;
                    Order[ 4 ] = 248830;
                    OrderTimeSession1 = StrToTime( "2005.12.14 07:30" );
                    OrderTimeSession2 = StrToTime( "2005.12.14 12:30" );
                    StartDataWindow1  = OrderTimeSession1 - ( 3 * hour );
                    StartDataWindow2  = OrderTimeSession2 - ( 3 * hour );
                    TradeQuitingTime  = StrToTime( "2005.12.14 16:30" );


    Code for the three types of exits that were removed.

        if( OrderType() == LongBuy ) {
            if( TrailingStopType == 1 ) {
                TrailingStop = Bid - ( Point * SetTrailingStop );
            } else if( TrailingStopType == 2 ) {
                TrailingStop = Low[ 0 ] - FactorTSCalculation * iATR( NULL, 0, 14, 0 );
            } else if( TrailingStopType == 3 ) {
                TrailingStop = Low[ 0 ] - ( FactorTSCalculation * ( High[ 0 ] - Low[ 0 ] ));
            } // End If, TrailingStopType:
            if( OrderStopLoss() < TrailingStop && Bid - OrderOpenPrice() >
                Point * SetTrailingStop ) UpDateOrder( OrderTicket(), TrailingStop );
        } else if( OrderType() ==  ShortSell ) {
            if( TrailingStopType == 1 ) {
                TrailingStop = Ask + ( Point * SetTrailingStop );
            } else if( TrailingStopType == 2 ) {
                TrailingStop = High[ 0 ] + FactorTSCalculation * iATR( NULL, 0, 14, 0 );
            } else if( TrailingStopType == 3 ) {
                TrailingStop = High[ 0 ] + ( FactorTSCalculation * ( High[ 0 ] - Low[ 0 ] ));
            } // End If, TrailingStopType:
            if( OrderStopLoss() > TrailingStop && OrderOpenPrice() - Ask >
                Point * SetTrailingStop ) UpDateOrder( OrderTicket(), TrailingStop );
        } // End If, OrderType:


        int OrderSendExtended(string symbol, int cmd, double volume, double price, int slippage,
                 double stoploss, double takeprofit, string comment, int magic,
                 datetime expiration=0, color arrow_color=CLR_NONE) {
           datetime OldCurTime;
           int timeout=5;
           int ticket;
           if (!IsTesting()) {
              MathSrand(LocalTime());
              Sleep(MathRand()/6);
           }
           OldCurTime=CurTime();
           while (GlobalVariableCheck("InTrade") && !IsTradeAllowed()) {
              if(OldCurTime+timeout<=CurTime()) {
                 Print("Error in OrderSendExtended(): Timeout encountered");
                 return(0); 
              }
              Sleep(1000);
           }
           GlobalVariableSet("InTrade", CurTime());  // set lock indicator
           ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss, takeprofit,
                 comment, magic, expiration, arrow_color);
           GlobalVariableDel("InTrade");   // clear lock indicator
           return(ticket);
        }
        ErrorFound = GetLastError();
        if( ErrorFound == 130 && MarketOrderPermitted ) { //RD!{test this!}:
            Print( "pending order to close to market" + PositionType + SystemID +
                    " (" + ErrorFound + ") " + ErrorDescription( ErrorFound ));
        } else if( ErrorFound > 1 || Waiting + TimeOut <= CurTime() ) {
            Print( "Error in EstablishPosition(): Unanticipated error " +
                    " or a Timeout was encountered. Error " + ErrorFound );
            break;
        } else {
        if( OrdersTotal() > 0 ) {
            Record = OrdersTotal();
            for( Index = Zero; Index <= OrdersTotal(); Index++ ) {
           if( OrderSelect( Index, SELECT_BY_POS, MODE_TRADES ) == False ) continue;
            Print( OrderMagicNumber() + "   " + Index + "  " + OrderTicket() );


                if( OrderMagicNumber()== (( SystemTag * 10 ) + 1 ) ) {
                    Order[ 1 ] = OrderTicket();
                    Counter++;
                    Print( Index );
                } else if( OrderMagicNumber()== (( SystemTag * 10 ) + 2 ) ) {
                    Order[ 2 ] = OrderTicket();
                    Counter++;
                    Print( Index );
                } else if( OrderMagicNumber()== (( SystemTag * 10 ) + 3 ) ) {
                    Order[ 3 ] = OrderTicket();
                    Counter++;
                    Print( Index );
                } else if( OrderMagicNumber()== (( SystemTag * 10 ) + 4 ) ) {
                    Order[ 4 ] = OrderTicket();
                    Counter++;
                    Print( Index );
                } else {
                    Print( "Iam in an area Iam dont have rights to be" );
                }//end if:

        }// end loop



//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»«««««««««««««««««««««««««««««««««««««««««««««««««««««
//»»»»»»»»»»»»»»»»»    END PROGRAM SCRIPT;        MetaQuote Source Code [ mq4 ]    ««««««««««««««««
//»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»««««««««««««««««««««««««««««««««« [rev.09-20-05] «««*/

