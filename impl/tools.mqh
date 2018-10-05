//+------------------------------------------------------------------+
//|                                                        tools.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property strict

#include "Channel.mqh";

void CommentLab(int row, string CommentText)
{
   if (!IsOptimization() && IsVisualMode()) {   
      string key = IntegerToString(row);
      if(CommentText == NULL && ObjectFind(0,key) >= 0) {
         ObjectDelete(key);
      } else {
      
         ObjectCreate(key, OBJ_LABEL, 0, 0, 0 );
         ObjectSet(key, OBJPROP_WIDTH, StringLen(CommentText)*255);
         ObjectSet(key, OBJPROP_XDISTANCE, 5);
         ObjectSet(key, OBJPROP_YDISTANCE, 15 + (row * 15) );
         ObjectSetText(key, CommentText, 8, "Tahoma", White);
      }
   }
}

   
int NBarsSince(datetime LastRunAt, ENUM_TIMEFRAMES Timeframe=PERIOD_CURRENT){
         int PreviousBar=iBarShift(Symbol(),Timeframe,LastRunAt);
         int CurrentBar=iBarShift(Symbol(),Timeframe,Time[0]);
         if(CurrentBar == PreviousBar)
          {
            // This tick is not in new bar
            return 0;
          }
         return PreviousBar-CurrentBar;
               
   }
   
   bool NotTesting(){
      return IsOptimization() || (IsTesting() && !IsVisualMode());
   }



int rgb2int(int r, int g, int b) {
   return (b*65536 + g*256 + r);
}


int period(ENUM_TIMEFRAMES timeframe){
   if (timeframe==PERIOD_CURRENT)
     timeframe=Period();
   switch (timeframe){
      case PERIOD_M1:
         return 50;
      case PERIOD_M5:
         return 28; //TODO
      case PERIOD_M15:
         return 8; // P.F. is 2.13% while 30 has better performance but only 1.75% profit factor
      case PERIOD_M30:
         return 24;
      case PERIOD_H1:
         return 30;
      case PERIOD_H4:
         return 42;
      case PERIOD_D1:
         return 30;
      case PERIOD_W1:
            return 50; //TODO
      default:
         {
            Print("Too high level timeframe");
            return 50; //TODO
         }
   }
}



  void visualization(Channel &PRICE, int ICC_History_Size){
  
  
            if (!IsOptimization() && IsVisualMode()) {
                   
                   
                     // MIN
                     int minIdx[];
                     string min_msg="ICC MIN: ";
                     PRICE.calcMin(minIdx);
                     int minIdxSize=ArraySize(minIdx);
                     ArraySort(minIdx,WHOLE_ARRAY,0,MODE_ASCEND);
                     for (int i=0,j=0; i<ICC_History_Size; i++){
                        if (j<minIdxSize){
                           if (i == minIdx[j]){
                              ObjectMove(ChartID(),"MIN_"+i,0,PRICE.getTime(i),PRICE.getValue(i));
                              ObjectSetInteger(ChartID(),"MIN_"+i,OBJPROP_COLOR,rgb2int(255,0,0));
                              ObjectSetInteger(ChartID(),"MIN_"+i,OBJPROP_STYLE,STYLE_DOT);
                              ObjectSetInteger(ChartID(),"MIN_"+i,OBJPROP_WIDTH,1);
                              j++;
                           
                              min_msg=StringConcatenate(min_msg, " ", PRICE.getValue(i));
                           } else if  (i != minIdx[j]){
                              ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_COLOR,rgb2int(0,0,0));
                           }
                        } else {
                           ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_COLOR,rgb2int(0,0,0));
                        }
                     }
                     CommentLab(10,min_msg);
                     int minidx=PRICE.minIdx();//,Psize);
                     if (minidx>-1){
                        // extrem lines
                        ObjectSetInteger(ChartID(),"MIN_"+minidx,OBJPROP_STYLE,STYLE_SOLID);
                        ObjectSetInteger(ChartID(),"MIN_"+minidx,OBJPROP_WIDTH,2);
                        CommentLab(6,StringConcatenate("ICC Window: Value MIN ",minidx, " value: ",PRICE.getValue(minidx)));
                     }
                     TrendPointChange(ChartID(),"MIN",0,PRICE.getTime(PRICE.getSize()-1),PRICE.getValue(PRICE.getSize()-1));
                     TrendPointChange(ChartID(),"MIN",1,PRICE.getTime(0),PRICE.nextMin(0));
                     
                     
                     // MAX
                     int maxIdx[];
                     PRICE.calcMax(maxIdx);
                     string max_msg="ICC MAX: ";
                     int maxIdxSize=ArraySize(maxIdx);
                     ArraySort(maxIdx,WHOLE_ARRAY,0,MODE_ASCEND);
                     for (int i=0,j=0; i<ICC_History_Size; i++){
                        if (j<maxIdxSize){
                           if (i == maxIdx[j]){
                              ObjectMove(ChartID(),"MAX_"+i,0,PRICE.getTime(i),PRICE.getValue(i));
                              ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_COLOR,rgb2int(0,255,0));
                              ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_STYLE,STYLE_DOT);
                              ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_WIDTH,1);
                              max_msg=StringConcatenate(max_msg, " ", PRICE.getValue(i));
                              j++;
                              
                           } else if  (i != maxIdx[j]){
                              ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_COLOR,rgb2int(0,0,0));
                           }
                           
                        } else {
                           ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_COLOR,rgb2int(0,0,0));
                        }
                     }
                     CommentLab(11,max_msg);
                     int maxidx=PRICE.maxIdx();//,Psize);
                     if (maxidx>-1){
                        // extrems
                        ObjectSetInteger(ChartID(),"MAX_"+maxidx,OBJPROP_STYLE,STYLE_SOLID);
                        ObjectSetInteger(ChartID(),"MAX_"+maxidx,OBJPROP_WIDTH,2);
                        CommentLab(5,StringConcatenate("ICC Window: Value MAX ",maxidx, " value: ",PRICE.getValue(maxidx)));
                     }
                     TrendPointChange(ChartID(),"MAX",0,PRICE.getTime(PRICE.getSize()-1),PRICE.getValue(PRICE.getSize()-1));
                     TrendPointChange(ChartID(),"MAX",1,PRICE.getTime(0),PRICE.nextMax(0));
                     
                     
                     string msg="ICC PRICE: ";
                     for (int i=0; i<ICC_History_Size; i++){
                        msg=StringConcatenate(msg, " ", PRICE.getValue(i));
                     }
                     CommentLab(12,msg);
                     
                  }
  
 }

bool TrendPointChange(const long   chart_ID=0,       // chart's ID
                      const string name="TrendLine", // line name
                      const int    point_index=0,    // anchor point index
                      datetime     time=0,           // anchor point time coordinate
                      double       price=0)          // anchor point price coordinate
  {
//--- if point position is not set, move it to the current bar having Bid price
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move trend line's anchor point
   if(!ObjectMove(chart_ID,name,point_index,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  } 

ENUM_TIMEFRAMES nextTimeframe(ENUM_TIMEFRAMES timeframe, int step){
   
   if (step==0)
      return timeframe;
   ENUM_TIMEFRAMES ret=timeframe;
   for (int i=0; i<step; i++)
      ret=nextTimeframe(ret);
   return ret;
}

ENUM_TIMEFRAMES prevTimeframe(ENUM_TIMEFRAMES timeframe, int step){
   
   if (step==0)
      return timeframe;
   ENUM_TIMEFRAMES ret=timeframe;
   for (int i=0; i<step; i++)
      ret=prevTimeframe(ret);
   return ret;
}

ENUM_TIMEFRAMES prevTimeframe(ENUM_TIMEFRAMES timeframe){
   if (timeframe==PERIOD_CURRENT)
     timeframe=Period();
   switch (timeframe){
   case PERIOD_M1:
   {
         Print("Too small level timeframe");
         return PERIOD_M1;
   }
   case PERIOD_M5:
      return PERIOD_M1;
   case PERIOD_M15:
      return PERIOD_M5;
   case PERIOD_M30:
      return PERIOD_M15;
   case PERIOD_H1:
      return PERIOD_M30;
   case PERIOD_H4:
      return PERIOD_H1;
   case PERIOD_D1:
      return PERIOD_H4;
   case PERIOD_W1:
         return PERIOD_D1;
   default:
      {
         Print("Too high level timeframe");
         return PERIOD_M1;
      }
   }
}

ENUM_TIMEFRAMES nextTimeframe(ENUM_TIMEFRAMES timeframe){
   if (timeframe==PERIOD_CURRENT)
     timeframe=Period();
   switch (timeframe){
   case PERIOD_M1:
      return PERIOD_M5;
   case PERIOD_M5:
      return PERIOD_M15;
   case PERIOD_M15:
      return PERIOD_M30;
   case PERIOD_M30:
      return PERIOD_H1;
   case PERIOD_H1:
      return PERIOD_H4;
   case PERIOD_H4:
      return PERIOD_D1;
   case PERIOD_D1:
      return PERIOD_W1;
   case PERIOD_W1:
   default:
      {
         Print("Too high level timeframe");
         return PERIOD_W1;
      }
   }
}