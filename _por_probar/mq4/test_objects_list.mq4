//+------------------------------------------------------------------+
//|                                            test_objects_list.mq4 |
//|                                     Copyright © 2006, MQLService |
//|                                        http://www.mqlservice.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, MQLService"
#property link      "http://www.mqlservice.com"

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
  // writing the chart objects list to the file
  int    handle, total;
  string obj_name,fname;
  // file name
  fname="objlist_"+Symbol()+".txt";
  handle=FileOpen(fname,FILE_CSV|FILE_WRITE);
  if(handle!=false)
    {
     total=ObjectsTotal();
     for(int i=0;i<total;i++)
       {
        obj_name=ObjectName(i);
        FileWrite(handle,TimeToStr(ObjectGet(obj_name, OBJPROP_TIME1))+", "+obj_name+", "+ObjectDescription(obj_name));
       }
     FileClose(handle);
    }

//----
   return(0);
  }
//+------------------------------------------------------------------+