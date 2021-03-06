//+------------------------------------------------------------------+
//|                                                        StDev.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property version   "1.00"
#property strict
/**
https://www.trendfollowingsystem.com/trend-magic-indicator-mt4/

BUY
Price action plots a bullish signaling bar
Price bar closes above the level of Trend Magic Indicator
Trend Magic Indicator turns blue
Set stop loss below the low of respective signaling bar or below the level of Trend Magic Indicator
Exit long whenever Trend Magic Indicator turns red with price closing below of its level

SELL
Price action plots a bearish signaling bar
Price bar closes below the level of Trend Magic Indicator
Trend Magic Indicator turns red
Set stop loss above the high of respective signaling bar or above the level of Trend Magic Indicator
Exit short whenever Trend Magic Indicator turns blue with price closing above of its level
**/

input bool ICC_ATR_GO = true;
input bool ICC_ATR_STOP = true;
input ENUM_TIMEFRAMES ICC_ATR_Timeframe = PERIOD_CURRENT;
input int ICC_Period= 20;
//static int ICC_Period;
//input int ATR_Period= 5;
//input double ICCTolerance = 5;

input int MA_Period=26;
input int ICC_Search_Window=100; // Search Window Size
input int ICC_History_Size=100; // History Size
input ENUM_TIMEFRAMES MA_Timeframe = PERIOD_CURRENT;

input double ICC_ATR_Threshold=0;
input ENUM_TIMEFRAMES ICC_ADX_Timeframe=PERIOD_CURRENT;
input int ICC_ADX_Next_timeframe=1;

static double b = 0.618;

#include "Indicator.mqh";
#include "Channel.mqh";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ICC_ATR : public Indicator
  {
private:
double e1, e2, e3, e4, e5, e6;
double c1, c2, c3, c4;
double n, w1, w2, b2, b3;

double smooth(int shift, double val){

       e1 = w1*val + w2*e1;
       e2 = w1*e1 + w2*e2;
       e3 = w1*e2 + w2*e3;
       e4 = w1*e3 + w2*e4;
       e5 = w1*e4 + w2*e5;
       e6 = w1*e5 + w2*e6;    
       return  c1*e6 + c2*e5 + c3*e4 + c4*e3;  
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


      bool _goLong, _goShort, _stopShort, _stopLong;
public:

/*
//--these three functions are used to extract the RGB values from the int clr
*/
int GetBlue(int clr)
{
int blue = MathFloor(clr / 65536);
return (blue);
}

int GetGreen(int clr)
{
int blue = MathFloor(clr / 65536);
int green = MathFloor((clr-(blue*65536)) / 256);
return (green);
}

int GetRed(int clr)
{
int blue = MathFloor(clr / 65536);
int green = MathFloor((clr-(blue*65536)) / 256);
int red = clr -(blue*65536) - (green*256);
return (red);
}

int rgb2int(int r, int g, int b) {
return (b*65536 + g*256 + r);
}
            ICC_ATR(bool goEnabled=true, bool stopEnabled=true) :
                Indicator(goEnabled,stopEnabled){
               LastBarOpenAt = Time[0];
               NextTimeframe=nextTimeframe(ICC_ATR_Timeframe,ICC_ADX_Next_timeframe);
              // ICC_Period=period(ICC_ATR_Timeframe);
               NBearMean=1;
               NBullMean=1;
               
               NATRMean=1;
//--- creating label object (it does not have time/price coordinates)

      
               Force_LastMax = DBL_MIN;
               Force_LastMin = DBL_MAX;
               
               Psize=ICC_History_Size;
               ArrayResize(PMAX,Psize); // TODO free!
               ArrayResize(PMIN,Psize);
               ArrayInitialize(PMAX,High[0]);
               ArrayInitialize(PMIN,Low[0]);
               
                if(!ObjectCreate(ChartID(),"MIN",OBJ_TREND,0,Time[1],0,Time[0],Close[0]))
                 {
                  Print(__FUNCTION__,
                        ": failed to create a trend line! Error code = ",GetLastError());
                  return ;
                 }
                  ObjectSetInteger(ChartID(),"MIN",OBJPROP_COLOR,rgb2int(255,0,0));
                  ObjectSetInteger(ChartID(),"MIN",OBJPROP_RAY_RIGHT,true);
                  
               if (!ObjectCreate(ChartID(),"MAX",OBJ_TREND,0,Time[1],0,Time[0],Close[0]))
                 {
                  Print(__FUNCTION__,
                        ": failed to create a trend line! Error code = ",GetLastError());
                  return ;
                 }
                  ObjectSetInteger(ChartID(),"MAX",OBJPROP_COLOR,rgb2int(0,255,0));
                  ObjectSetInteger(ChartID(),"MAX",OBJPROP_RAY_RIGHT,true);
               
               for (int i=0; i<Psize; i++){
                  ObjectCreate(ChartID(),"MAX_"+i, OBJ_HLINE, 0, Time[i], 0, 0, 0);
                  int green = 255-(i*10);
                  green= green>-1?green:100;
                  ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_COLOR,rgb2int(0,green,0));
                  ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_STYLE,STYLE_DOT);
                  
                  
                  ObjectCreate(ChartID(),"MIN_"+i, OBJ_HLINE, 0, Time[i], 0, 0, 0);
                  int red = 255-(i*10);
                  red= red>-1?red:100;
                  ObjectSetInteger(ChartID(),"MIN_"+i,OBJPROP_COLOR,rgb2int(red,0,0));
                  ObjectSetInteger(ChartID(),"MIN_"+i,OBJPROP_STYLE,STYLE_DOT);
               }
               
               
                b2 = b*b;
                b3 = b2*b;
                c1 = -b3;
                c2 = (3*(b2 + b3));
                c3 = -3*(2*b2 + b + b3);
                c4 = (1 + 3*b + b3 + 3*b2);
                n = ICC_Period;
            //----
                if(n < 1) 
                    n = 1;
                n = 1 + 0.5*(n - 1);
                w1 = 2 / (n + 1);
                w2 = 1 - w1;    
            };
           ~ICC_ATR(){
                  ObjectDelete("MIN");
                  ObjectDelete("MAX");
           
               for (int i=0; i<Psize; i++){
                  ObjectDelete("MIN_"+i);
                  ObjectDelete("MAX_"+i);
               }
           };
  
           string getName(){
               return "ICC_ATR";
            };
   /*                  
            void resetDownsideThreshold(){
               incrementalMeanUnderThreshold=ICC_ATR_Threshold;
               NMeanUnderThreshold=1;
               ICC_min=ICC_ATR_Limit;
               AD_min=DBL_MAX;
            }
            
            void resetUpsideThreshold(){
               incrementalMeanOverThreshold=ICC_ATR_Threshold;
               NMeanOverThreshold=1;
               ICC_max=ICC_ATR_Limit;
               AD_max=DBL_MIN;
            }
     */       
            double incrementalMeanUnderThreshold;
            int NMeanUnderThreshold;
            double incrementalMeanOverThreshold;
            int NMeanOverThreshold;
            
            double incrementalBearVolume;
            int NBearMean,NBullMean;
            double incrementalBullVolume;
            
            double ATRMean;
            int NATRMean;
            
            double limit;
            double threshold;
            double ICC_min;
            double ICC_max;
            double AD_min;
            double AD_max;
            
               double Force_LastMax ;
               double Force_LastMin ;
               
            double PMAX[];
            Channel PMAX2;
            double PMIN[];
            int Psize;
            
            
            ENUM_TIMEFRAMES NextTimeframe;
              
            datetime LastBarOpenAt;
            
                  bool biggerThanMax(double value){
                     int pos=ArrayMaximum(PMAX);
                     return value>PMAX[pos];
                     
                  }
                  
                  bool lowerThanMin(double value){
                  
                     int pos=ArrayMinimum(PMIN);
                     return value<PMIN[pos];
                  
                  }
                  
                  bool isBetween(double deviation){
                  
                     //return !lowerThanMin(Low[0]+deviation) && !biggerThanMax(High[0]-deviation) ;
                     // previous bar is out of range
                     bool lower = lowerThanMin(High[0]+deviation) && Low[0]<=(Close[1]+deviation);
                     bool higer = biggerThanMax(Low[0]-deviation) && High[0]>=(Close[1]-deviation);
                     
                     return !lower && !higer;
                  }
                  
                  int pushMax(double value){
                     return push(PMAX, value);
                  }
                  int pushMin(double value){
                     return push(PMIN,  value);
                  }
                  
                  int push( double &theArray[],  double  value) {
                     
                     int size = ArraySize( theArray );
                     
                      if (ArrayCopy(theArray, theArray, 1, 0, size-1) == size-1)
                        theArray[0] = value;
                      else
                        return -1;
                      return size;
                  }
                  
                  
                  class Value {
                  public:
                     int idx;
                     double value;
                     datetime time;
                     
                     Value(){
                        idx=-1;
                        value=NULL;
                        time=Time[0];
                     }
                     Value(int _idx, double _value, datetime _time){
                        idx=_idx;
                        value=_value;
                        time=_time;
                     }
                     Value(Value &v){
                        idx=v.idx;
                        value=v.value;
                        time=v.time;
                     }
                  };
                  
                  Value searchMaxInWindow(int window){
                     int idxPrev=iHighest(NULL,ICC_ADX_Timeframe,MODE_CLOSE,window,1);
                     if (idxPrev>-1){
                        Value v;
                        v.idx=idxPrev;
                        v.value=Close[idxPrev];
                        v.time=Time[idxPrev];
                        return v;
                     }
                     Value v;
                     CommentLab(7,StringConcatenate(Time[0]," ICC MA: No MAX found", v.idx));
                     return v;
                  }
                  
                   Value searchMinInWindow(int window){
                     int idxPrev=iLowest(NULL,ICC_ADX_Timeframe,MODE_CLOSE,window,1);
                     if (idxPrev>-1){
                        Value v;
                        v.idx=idxPrev;
                        v.value=Close[idxPrev];
                        v.time=Time[idxPrev];
                        return v;
                     }
                     
                     Value v;
                     CommentLab(7,StringConcatenate(Time[0]," ICC MA: No MAX found", v.idx));
                     return v;
                  }
                  
                   Value searchMinInWindow2(int window){
                     double recent=smooth(0,Close[0]);//iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMA,PRICE_MEDIAN,0);
                     //double recent = iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMMA,PRICE_CLOSE,1);
                     for (int i=1; i<window; i++){
                        //double prev= iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMMA,PRICE_CLOSE,i);
                        double prev=smooth(i,Close[i]);//iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMA,PRICE_MEDIAN,i);
                        if (prev < recent){
                           recent=prev;
                //           CommentLab(8,StringConcatenate(Time[0]," ICC MA: PREV", prev));
                        } else {
                           Value v;
                           v.idx=i-1;
                           v.value=recent;
                           v.time=Time[i-1];
                 //    CommentLab(8,StringConcatenate(Time[0]," ICC MA:  MIN found",v.idx, " value:", v.value));
                           return v;
                        }
                     }
                     
                     Value v;
                 //    CommentLab(8,StringConcatenate(Time[0]," ICC MA: No MIN found",v.idx));
                     return v;
                  }
                  
                  Value searchMaxInWindow2(int window){
                     double recent=smooth(0,Close[0]);//iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMA,PRICE_MEDIAN,0);
                     //double recent=iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMMA,PRICE_CLOSE,1);
                     for (int i=1; i<window; i++){
                        //double prev = iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMMA,PRICE_CLOSE,i);
                        double prev=smooth(i,Close[i]);//iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMA,PRICE_MEDIAN,i);
                        if (prev > recent){
                           recent=prev;
                    CommentLab(10,StringConcatenate(Time[0]," ICC MA: PREV", prev));
                        } else {
                           Value v;
                           v.idx=i-1;
                           v.value=recent;
                           v.time=Time[i-1];
                     CommentLab(7,StringConcatenate(Time[0]," ICC MA: MAX found prev:", prev, " recent:", recent));
                           return v;
                        }
                     }
                     Value v;
                     CommentLab(7,StringConcatenate(Time[0]," ICC MA: No MAX found", v.idx));
                     return v;
                  }
                  
            void setupPriceArrayIdx(){
               MAX_MaxIdx=ArrayMaximum(PMAX);
               MAX_MinIdx=ArrayMinimum(PMAX);
               MIN_MaxIdx=ArrayMaximum(PMIN);
               MIN_MinIdx=ArrayMinimum(PMIN);
            }
            void setup(int shift=0, int previousShift=1){
            
         //Print(__FUNCTION__,"=========ICC RECALC=======================  ");
            
               setupPriceArrayIdx();
               
            
               int NBars = 1; // desired number of bars to wait
               int NUnchangedBarsSinceLastRun=NBarsSince(LastBarOpenAt,ICC_ATR_Timeframe);
               if(NUnchangedBarsSinceLastRun<NBars) // This tick is not in new bar
                {
                 return;
                } 
               LastBarOpenAt = Time[0];
               
               
               //double SPriceTipical =smooth(shift,((High[shift] + Low[shift] + Close[shift])/3));
               double PriceTipical =((High[shift] + Low[shift] + Close[shift])/3);
               //double SPreviousPriceTipical =smooth(shift,((High[shift+previousShift] + Low[shift+previousShift] + Close[shift+previousShift])/3));
               //double PreviousPriceTipical =((High[shift+previousShift] + Low[shift+previousShift] + Close[shift+previousShift])/3);
               
               //double Force = iForce(NULL,ICC_ATR_Timeframe,ICC_Period,MODE_SMA,PRICE_WEIGHTED,shift);
               //double MA = iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMMA,PRICE_CLOSE,1);
               //double PMA = iMA(NULL,ICC_ADX_Timeframe,ICC_Period,0,MODE_SMMA,PRICE_CLOSE,shift+previousShift);
               //bool Force_LongStop;
               //bool Force_ShortStop;
               
                  //double stDev = iStdDev(NULL,ICC_ADX_Timeframe, ICC_Period, PERIOD_CURRENT,MODE_SMA,PRICE_MEDIAN,shift);
               //CommentLab(3,StringConcatenate("ICC MA: Value MA ",MA));
                                    
                  //ENUM_TIMEFRAMES ICC_Timeframe = lateral?prevTimeframe(ICC_ATR_Timeframe,2): ICC_ATR_Timeframe;
                  //int ICC_NewPeriod = period(ICC_Timeframe);
                    // if (stDev> (PMAX[0]-PMIN[0]) )//(pMax.value-pMin.value))
                    //    icc(shift, true);
                     //CommentLab(4,StringConcatenate("ICC_ATR_FOR at:", i, "starting from:", NUnchangedBarsSinceLastRun ));
                     //double ICCCurrent = smooth(shift,  iCCI(NULL, ICC_ATR_Timeframe, ICC_Period, PRICE_TYPICAL, shift));//
                     //double ICCPrevious = smoothICC(shift + previousShift);
                     //double ICCPrevious = iCCI(NULL, ICC_ATR_Timeframe, ICC_Period, PRICE_MEDIAN, shift + previousShift);
                   //  CommentLab(6,StringConcatenate("ICC_ATR ICCCurrent:", ICCCurrent));
                  
                     //if (MathAbs(PMAX[0] - PMIN[0])>stDev)
                        icc(shift);
                     
                     
                  Value pMax=searchMaxInWindow(ICC_Search_Window);
                  Value pMin=searchMinInWindow(ICC_Search_Window);
                  
                     CommentLab(5,StringConcatenate("ICC MA: Value MAX ",pMax.idx, " value: ",pMax.value));
                     CommentLab(6,StringConcatenate("ICC MA: Value MIN ",pMin.idx, " value: ",pMin.value));
                  
                  //if ((idx=biggerThanMax(PriceAvg))==-1){
                  if (pMax.idx!=-1){
                     int pos;
                     string msg="ICC MAX: ";
                     if ((pos=pushMax(pMax.value))<0) {
                     //if (pushMaxIf(pMax.value, stDev)<0) {
                        msg=StringConcatenate(msg, " value: ", pMax.value, " already present " );
                     } else {
                     
                        //&& i<Bars(NULL,ICC_ADX_Timeframe)
                        TrendPointChange(ChartID(),"MAX",0,Time[Psize-1],PMAX[Psize-1]);
                        TrendPointChange(ChartID(),"MAX",1,Time[0],PMAX[0]);
                        //TrendPointChange(ChartID(),"MAX",1,Time[0],PMAX[MAX_MaxIdx]);
                        
                        for (int i=0; i<ArraySize(PMAX); i++){
                        
                        //   TrendPointChange(ChartID(),"MAX",i,Time[i],PMAX[i]);
                           ObjectMove(ChartID(),"MAX_"+i,0,Time[i],PMAX[i]);
                           msg=StringConcatenate(msg, " ", PMAX[i]);
                        }
                     }
                     CommentLab(10,msg);
                  }
                  if (pMin.idx!=-1){
                     int pos;
                     string msg="ICC MIN: ";
                     if ((pos=pushMin(pMin.value))<0) {
                     //if (pushMinIf(pMin.value, stDev)<0) {
                        msg=StringConcatenate(msg, " value: ", pMin.value, " already present" );
                     } else {
                     
                        int MaxIdx=ArrayMaximum(PMIN);
                        int MinIdx=ArrayMinimum(PMIN);
                        TrendPointChange(ChartID(),"MIN",0,Time[Psize-1],PMIN[Psize-1]);
                        TrendPointChange(ChartID(),"MIN",1,Time[0],PMIN[0]);
                        //TrendPointChange(ChartID(),"MIN",1,Time[0],PMIN[MIN_MinIdx]);
                        
                        // && i<Bars(NULL,ICC_ADX_Timeframe)
                        for (int i=0; i<ArraySize(PMIN); i++){
                           //TrendPointChange(ChartID(),"MIN",i,Time[i],PMAX[i]);
                           ObjectMove(ChartID(),"MIN_"+i,0,Time[i],PMIN[i]);
                           msg=StringConcatenate(msg, " ", PMIN[i] );
                        }
                     }
                     CommentLab(11,msg);
                  }
                  return;
   }
   
   OrderDetails orderDetails(){
               OrderDetails order;
               setupPriceArrayIdx();
               long dig=1/Point;
//                  CommentLab(12,StringConcatenate("PMIN:",PMIN[MIN_MinIdx]," CLOSE:",Close[0], "Stop: ", MathAbs(PMIN[MIN_MinIdx]-Close[0])*dig," ds:", Digits, " p:",Point));
            switch (strategy){
            case LONG_UNDER_CHANNEL:
                  // Close may be under the lateral channel
                  //order.TrailingProfit=MathAbs(PMAX[MAX_MaxIdx]-Close[0])*dig;
                  //order.TrailingStop=MathAbs(PMAX[MAX_MinIdx]-Close[0])*dig; // DEFAULT
                  CommentLab(3,StringConcatenate("Strategy: ","LONG UNDER"," (",LONG_UNDER_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case LONG_ABOVE_CHANNEL:
                  //order.TrailingProfit=MathAbs(PMAX[MAX_MaxIdx]-Close[0])*dig;
                  
                  order.TrailingStop=MathAbs(PMAX[MAX_MinIdx]-Close[0])*dig;
                  //order.TrailingStop=MathAbs(PMAX[1]-Close[0])*dig;
                  
                  CommentLab(3,StringConcatenate("Strategy: ","LONG ABOVE"," (",LONG_ABOVE_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case LONG_INTO_CHANNEL:
                  //order.TrailingProfit=MathAbs(PMAX[MAX_MaxIdx]-Close[0])*dig;
                  order.TrailingStop=MathAbs(PMIN[MIN_MinIdx]-Close[0])*dig;
                  CommentLab(3,StringConcatenate("Strategy: ","LONG INTO"," (",LONG_INTO_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case SHORT_UNDER_CHANNEL:
                  //order.TrailingProfit=MathAbs(PMIN[MIN_MinIdx]-Close[0])*dig;
                  
                  order.TrailingStop=MathAbs(PMIN[MIN_MaxIdx]-Close[0])*dig;
                  //order.TrailingStop=MathAbs(PMIN[1]-Close[0])*dig;
                  
                  CommentLab(3,StringConcatenate("Strategy: ","SHORT UNDER"," (",SHORT_UNDER_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break; 
            case SHORT_ABOVE_CHANNEL:
                  // Close may be above the lateral channel
                  //order.TrailingProfit=MathAbs(PMIN[MIN_MinIdx]-Close[0])*dig; // DEFAULT
                  // order.TrailingStop=MathAbs(PMIN[MIN_MaxIdx]-Close[0])*dig; // DEFAULT
                  CommentLab(3,StringConcatenate("Strategy: ","SHORT ABOVE"," (",SHORT_ABOVE_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case SHORT_INTO_CHANNEL:
                  //order.TrailingProfit=MathAbs(PMIN[MIN_MinIdx]-Close[0])*dig;
                  order.TrailingStop=MathAbs(PMAX[MAX_MaxIdx]-Close[0])*dig;
                  CommentLab(3,StringConcatenate("Strategy: ","SHORT INTO"," (",SHORT_INTO_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case NONE:
            default:
                  CommentLab(3,StringConcatenate("Strategy: ","NONE "," (",NONE,")"));
                  break;
          }
               
         return order;
   }

enum STRATEGY {
   LONG_UNDER_CHANNEL=0,
   LONG_ABOVE_CHANNEL=1,
   LONG_INTO_CHANNEL=2,
   SHORT_UNDER_CHANNEL=3,
   SHORT_ABOVE_CHANNEL=4,
   SHORT_INTO_CHANNEL=5,
   NONE=6
};

STRATEGY strategy;

int MAX_MaxIdx;
int MAX_MinIdx;
int MIN_MaxIdx;
int MIN_MinIdx;
   
 virtual void closeSignal(int ticket){
   
         Print("=========STOP======================= Stop happened at price: ", Close[0], " Ticket: ", ticket);
            _goLong=false;
            _goShort=false;
            strategy=NONE;
 }
   
            
   void icc(int shift){
   
//        Print(__FUNCTION__,"=========ICC RECALC======================= lateral:  ", lateral, " _goShort:" ,_goShort, " _goLong:",_goLong);
   
           // double stDev = iStdDev(NULL,ICC_ATR_Timeframe, ICC_Period, 0,MODE_SMMA,PRICE_CLOSE,shift);
           // CommentLab(12,StringConcatenate("ICC MA stDev :", stDev ));
           // stDev = (_goLong || _goShort) ?     stDev/2  : stDev/2;
            //double stDev = iStdDev(NULL,ICC_ATR_Timeframe, ICC_Period, 0,MODE_SMMA,PRICE_MEDIAN,0);
            
           double PriceAvg =((High[shift] + Low[shift])/2);
               
            bool lateral = isBetween( ICC_ATR_Threshold);// ICC_ATR_Threshold);
            
               
            ENUM_TIMEFRAMES ICC_Timeframe = ICC_ATR_Timeframe;
          // if (!_goShort && !_goLong && lateral){
          //    ICC_Timeframe = prevTimeframe(ICC_ATR_Timeframe,1);
          // }
            int ICC_NewPeriod = period(ICC_Timeframe);
            double ICCCurrent = iCCI(NULL,ICC_Timeframe, ICC_Period, PRICE_CLOSE, shift);

            bool iccShort = ICCCurrent<-ICC_ATR_Threshold;// && ICCCurrent < ICCPrevious;
            bool iccLong = ICCCurrent>ICC_ATR_Threshold;// && ICCCurrent > ICCPrevious;
            
           // double rsi = iRSI(NULL,ICC_ATR_Timeframe,8, PRICE_CLOSE,shift);
            bool overbought = false;//rsi>70;
            bool oversold = false;//rsi<30;
            
            if (iccLong){
               if (lateral) {
                  if (_goShort){
                     // STOP
                     _goLong=false;
                     _goShort=false;
                     
                Print(__FUNCTION__,"=========ICC SHORT STOP======================= happened lateral is: ", lateral, " and go short", _goShort);
                     strategy=NONE;
                     CommentLab(9,StringConcatenate("ICC POSITION: STOP" ));
                     return;
                  }
                  if (Close[0]>PMIN[MIN_MinIdx] && Close[0]<PMAX[MAX_MaxIdx]){
                     strategy=LONG_INTO_CHANNEL;
                  }
               } else if (!lateral) {
                  // LONG
                  if (Close[0]<PMIN[MIN_MinIdx]){
                     strategy=LONG_UNDER_CHANNEL;
                  } else if (Close[0]>PMAX[MAX_MaxIdx]){
                     strategy=LONG_ABOVE_CHANNEL;
                  }
                  _goShort=false;
                  _goLong=true;
                  CommentLab(9,StringConcatenate("ICC POSITION: LONG" ));
               }
               
            } else if (iccShort) {
               if (lateral) {
                  if (_goLong){
                     // STOP
                     _goLong=false;
                     _goShort=false;
                     strategy=NONE;
                     CommentLab(9,StringConcatenate("ICC POSITION: STOP" ));
                     
                Print(__FUNCTION__,"=========ICC LONG STOP======================= happened lateral is: ", lateral, " and go long", _goLong);
                     return;
                  }
                  if (Close[0]>PMIN[MIN_MinIdx] && Close[0]<PMAX[MAX_MaxIdx]){
                     strategy=SHORT_INTO_CHANNEL;   
                  }
               } else if (!lateral) {
                  // LONG
                  if (Close[0]<PMIN[MIN_MinIdx]){
                     strategy=SHORT_UNDER_CHANNEL;
                  } else if (Close[0]>PMAX[MAX_MaxIdx]){
                     strategy=SHORT_ABOVE_CHANNEL;
                  }
                  // SHORT
//                Print(__FUNCTION__,"=========GOSHORT======================= happened since lateral is: ", lateral);
                  _goShort=true;
                  _goLong=false;
                  CommentLab(9,StringConcatenate("ICC POSITION: SHORT" ));
               }
            }
            
            CommentLab(2,StringConcatenate("ICC CHANNEL IS LATERAL: ",lateral, " STRATEGY: ",strategy ));
   }
   
   
   bool goLong(){
   
      return _goLong ;
                              
   }
   
   bool stopLong(){
   
      return !_goLong;
   
      
   }
   bool goShort(){
   return _goShort;
               
   }
   bool stopShort(){
      return !_goShort;
   }
  };



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
  
  /*
  
  
                  
                   Value searchMinInWindow(int window){
                     int idxPrev=iLowest(NULL,ICC_ADX_Timeframe,MODE_CLOSE,window,1);
                     if (idxPrev>-1){
                        Value v;
                        v.idx=idxPrev;
                        v.value=Close[idxPrev];
                        v.time=Time[idxPrev];
                        return v;
                     }
                     
                     Value v;
                     CommentLab(7,StringConcatenate(Time[0]," ICC MA: No MAX found", v.idx));
                     return v;
                  }
                  
                   Value searchMinInWindow2(int window){
                     double recent=smooth(0,Close[0]);//iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMA,PRICE_MEDIAN,0);
                     //double recent = iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMMA,PRICE_CLOSE,1);
                     for (int i=1; i<window; i++){
                        //double prev= iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMMA,PRICE_CLOSE,i);
                        double prev=smooth(i,Close[i]);//iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMA,PRICE_MEDIAN,i);
                        if (prev < recent){
                           recent=prev;
                //           CommentLab(8,StringConcatenate(Time[0]," ICC MA: PREV", prev));
                        } else {
                           Value v;
                           v.idx=i-1;
                           v.value=recent;
                           v.time=Time[i-1];
                 //    CommentLab(8,StringConcatenate(Time[0]," ICC MA:  MIN found",v.idx, " value:", v.value));
                           return v;
                        }
                     }
                     
                     Value v;
                 //    CommentLab(8,StringConcatenate(Time[0]," ICC MA: No MIN found",v.idx));
                     return v;
                  }
                  
                  Value searchMaxInWindow2(int window){
                     double recent=smooth(0,Close[0]);//iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMA,PRICE_MEDIAN,0);
                     //double recent=iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMMA,PRICE_CLOSE,1);
                     for (int i=1; i<window; i++){
                        //double prev = iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMMA,PRICE_CLOSE,i);
                        double prev=smooth(i,Close[i]);//iMA(NULL,MA_Timeframe,MA_Period,0,MODE_SMA,PRICE_MEDIAN,i);
                        if (prev > recent){
                           recent=prev;
                        } else {
                           Value v;
                           v.idx=i-1;
                           v.value=recent;
                           v.time=Time[i-1];
                           return v;
                        }
                     }
                     Value v;
                     return v;
                  }
                  
                  
                  
                  int populate(){
                        
                     Value pMax=searchMaxInWindow(Search_Window);
                     Value pMin=searchMinInWindow(Search_Window);
                     
                     //if ((idx=biggerThanMax(PriceAvg))==-1){
                     if (pMax.idx!=-1){
                        int pos;
                        string msg="ICC MAX: ";
                        if ((pos=pushMax(pMax.value))<0) {
                           return -1; //" already present " 
                        } else {
                        return pos;
                        }
                     }
                     if (pMin.idx!=-1){
                        int pos;
                        string msg="ICC MIN: ";
                        if ((pos=pushMin(pMin.value))<0) {
                        //if (pushMinIf(pMin.value, stDev)<0) {
                           return -1;// " already present" );
                        } else {
                           return pos;
                        }
                     }
                     return -1;
               }
               
               
                  Value searchMaxInWindow(int window){
                     int idxPrev=iHighest(NULL,ICC_ADX_Timeframe,MODE_CLOSE,window,1);
                     
                     if (idxPrev>-1){
                     //int copied=CopyRates(NULL,0,0,100,rates);
                     //if(copied<=0)
                      //  Print("Error copying price data ",GetLastError());
                        Value v;
                        v.idx=idxPrev;
                        v.value=Close[idxPrev];
                        v.time=Time[idxPrev];
                        return v;
                     }
                     Value v;
                     return v;
                  }
                  
                  
class Value {
public:
   int idx;
   double value;
   datetime time;
   
   Value(){
      idx=-1;
      value=NULL;
      time=Time[0];
   }
   Value(int _idx, double _value, datetime _time){
      idx=_idx;
      value=_value;
      time=_time;
   }
   Value(Value &v){
      idx=v.idx;
      value=v.value;
      time=v.time;
   }
};

               
               */