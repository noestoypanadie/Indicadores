int start()
  {
    int prev=0;
    int prevarrow=0,arrowtotal; // drawn on the chart
    int lastvisiblebar;    // index of it 
    int obttl,j,k,handle;
    string namearray[],name; 
    
    while (1>0) // endless loop, thanks to Sleep()....
      { 
        lastvisiblebar=WindowFirstVisibleBar()-WindowBarsPerChart();
        //======= if press F12 then =============================
        if(lastvisiblebar != prev)  
          {
            obttl=ObjectsTotal();
            arrowtotal=0;    
            //....... make arrows an Array ...................
            for (j=0,k=0; j<obttl; j++)   
              {
               name=ObjectName(j);
               Print("name",j," is " + name);  //debug. turned out empty
               
               if(ObjectType(name)==OBJ_ARROW) // rule out trendlines, etc.
                {
                  namearray[k]=name;
                  arrowtotal++;
                  Print("Object ",k," is " +ObjectType(name));//debug. turned out empty
                  k++;      
                }
              }
            //..............................................
            Comment("prevarrow=" +prevarrow +"   arrowtotal=" +arrowtotal +"    lastvisbar=" +lastvisiblebar); //debug. proved that objects and arrows counting and F12 detecting works great.                
            
            //---- if new arrows added then --------------------
                // bla bla bla             
            //-------------------------------------------------
            prev=lastvisiblebar;            
          }
        //=====================================================  
        Sleep(4000);  
      }     
    return(0);
  }  
//+------------------------------------------------------------------+

