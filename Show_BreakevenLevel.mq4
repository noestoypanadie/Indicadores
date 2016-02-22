
#property copyright "© 2007 RickD"
#property link      "www.e2e-fx.net"

#define major   1
#define minor   0

#property indicator_chart_window
#property indicator_buffers 0

extern bool DrawSymbolChart = true;
extern bool DrawBreakeven = true;
extern int Corner = 0;
extern int FontSize = 8;
extern int dy = 40;

extern color _Header = OrangeRed;
extern color _Text = DodgerBlue;
extern color _Data = Black;
extern color _Separator = MediumPurple;
extern color _Breakeven = MediumBlue;



string prefix = "capital_";
string sepstr = "---------------------------------------------------------------";

void init() 
{
  //Comment("");
  clear();
}

void deinit() 
{
  //Comment("");
  clear();
}

void clear() 
{
  string name;
  int obj_total = ObjectsTotal();
  for (int i=obj_total-1; i>=0; i--)
  {
    name = ObjectName(i);
    if (StringFind(name, prefix) == 0) ObjectDelete(name);
  }
}

void start()
{
  clear();

  string Sym[];
  double Equity[];
  double Lots[];
  ArrayResize(Sym, 0);
  ArrayResize(Equity, 0);
  ArrayResize(Lots, 0);
  
  string eq;
  
  int cnt = OrdersTotal();
  for (int i=0; i<cnt; i++)
  {
    if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
    
    int type = OrderType();
    if (type != OP_BUY && type != OP_SELL) continue;
    
    bool found = false;
    
    int size = ArraySize(Sym);
    for (int k=0; k<size; k++)
    {
      if (Sym[k] == OrderSymbol()) {
        Equity[k] += OrderProfit() + OrderCommission() + OrderSwap();
        if (type == OP_BUY) Lots[k] += OrderLots();
        if (type == OP_SELL) Lots[k] -= OrderLots();
        found = true;
        break;
      }
    }
    
    if (found) continue;
    
    int ind = ArraySize(Sym);
    ArrayResize(Sym, ind+1);
    Sym[ind] = OrderSymbol();
    
    ArrayResize(Equity, ind+1);
    Equity[ind] = OrderProfit() + OrderCommission() + OrderSwap();
    
    ArrayResize(Lots, ind+1);
    if (type == OP_BUY) Lots[k] = OrderLots();
    if (type == OP_SELL) Lots[k] = -OrderLots();
  }
  
  if (DrawSymbolChart==true){
    nb_drawLabel("symbols",  "Symbol",   30+FontSize, dy,   _Header);
    nb_drawLabel("equities",  "Equity",   130+FontSize,dy,   _Header);
    nb_drawLabel("breakeven","Breakeven",220+FontSize,dy,   _Header);
    nb_drawLabel("tmp1",     sepstr,     20+FontSize, dy+FontSize+2,_Separator);
  }
  
  double sum = 0;
  string level0 = "";
  
  size = ArraySize(Sym);
  for (i=0; i<size; i++)
  {
    if (Lots[i] == 0) {
      level0 = "Lock";
    }
    else {
      int dig = MarketInfo(Sym[i], MODE_DIGITS);
      double point = MarketInfo(Sym[i], MODE_POINT);
      
      double COP = Lots[i]*MarketInfo(Sym[i], MODE_TICKVALUE);
      double val = MarketInfo(Sym[i], MODE_BID) - point*Equity[i]/COP;
      level0 = DoubleToStr(val, dig);
    }
    
    if (Equity[i] > 0) eq = "+$"+DoubleToStr(MathAbs(Equity[i]),2);
    else               eq = "-$"+DoubleToStr(MathAbs(Equity[i]),2);
    
    if (DrawSymbolChart==true){     
      nb_drawLabel("symbol"+i,   Sym[i],30+FontSize, (i+1)*(FontSize*2)+2+dy,_Text);
      nb_drawLabel("equity"+i,   eq,    120+FontSize,(i+1)*(FontSize*2)+2+dy,_Data);
      nb_drawLabel("breakeven"+i,level0,230+FontSize,(i+1)*(FontSize*2)+2+dy,_Data);
    }
    
    if (Sym[0]==Symbol())
    	if (DrawBreakeven==true){
    		ObjectCreate(prefix+"breakevenline",OBJ_HLINE,0,0,StrToDouble(level0));
    		ObjectSet(prefix+"breakevenline",OBJPROP_COLOR,_Breakeven);
    		ObjectSet(prefix+"breakevenline",OBJPROP_STYLE,STYLE_DASH);
    	}
    
    sum += Equity[i];
  }
	
  if (sum > 0) eq = "+$"+DoubleToStr(MathAbs(sum),2);
  else         eq = "-$"+DoubleToStr(MathAbs(sum),2);
  
  if (DrawSymbolChart==true){
    nb_drawLabel("tmp2",  sepstr, 20+FontSize,  (i+0.6)*(FontSize*2)+dy, _Separator);
    nb_drawLabel("total", "Total",30+FontSize,  (i+1.2)*(FontSize*2)+dy, _Text);
    nb_drawLabel("equity", eq,    120+FontSize, (i+1.2)*(FontSize*2)+dy, _Data);
  }
  
}

void nb_drawLabel(string name, string text,
                  int xdistance, int ydistance,
                  color fontcolor)
{
	string n = prefix + name;
	if (ObjectFind(n) == -1)
		ObjectCreate(n,OBJ_LABEL,0,0,0);
	ObjectSet(n,OBJPROP_XDISTANCE,xdistance);
	ObjectSet(n,OBJPROP_YDISTANCE,ydistance);
	ObjectSet(n,OBJPROP_CORNER,Corner);
	ObjectSetText(n,text,FontSize,"Tahoma",fontcolor);
}

