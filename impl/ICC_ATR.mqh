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

input ENUM_TIMEFRAMES ICC_ATR_Timeframe = PERIOD_CURRENT; // 6. ICC ATR Timeframe
input int ICC_ATR_Period=40; // 2. ATR Period
input int ICC_Period= 25;  // 3. ICC Period
input int ICC_Search_Window=50; // 4. Search Window Size
input int ICC_History_Size=50; // 5. History Size


input int RSI_Period=14;
input double ICC_ATR_Threshold=0;


#include "Indicator.mqh";
#include "Channel.mqh";
#include "tools.mqh";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

static double b = 0.618;

class ICC_ATR : public Indicator
  {
private:
double e1, e2, e3, e4, e5, e6;
double c1, c2, c3, c4;
double n, w1, w2, b2, b3;

Channel *PRICE;
Channel *RSI;

double smooth(int shift, double val){

       e1 = w1*val + w2*e1;
       e2 = w1*e1 + w2*e2;
       e3 = w1*e2 + w2*e3;
       e4 = w1*e3 + w2*e4;
       e5 = w1*e4 + w2*e5;
       e6 = w1*e5 + w2*e6;    
       return  c1*e6 + c2*e5 + c3*e4 + c4*e3;  
}

      bool _goLong, _goShort, _stopShort, _stopLong;
      
      
Pipe<double> *buy;
Pipe<double> *sell;

public:

/*
//--these three functions are used to extract the RGB values from the int clr
*/

            ICC_ATR(bool goEnabled=true, bool stopEnabled=true) :
                Indicator(goEnabled,stopEnabled){
               LastBarOpenAt = Time[0];
               
               buy=new Pipe<double>(2,DBL_MIN);
               sell=new Pipe<double>(2,DBL_MAX);
               iccCalc(iccLong,iccShort);
               
               strategy=NONE;
               
               
               
               PRICE=new Channel(ICC_History_Size,Close[1]);
               //iMA(NULL,ICC_ATR_Timeframe,MA_Period, 0, MODE_SMMA, PRICE_CLOSE,0));
               RSI=new Channel(ICC_History_Size,iRSI(NULL,ICC_ATR_Timeframe,RSI_Period, PRICE_CLOSE,1));
               
               if (!IsOptimization() && IsVisualMode()) {
                  if (ObjectCreate(ChartID(),"MIN",OBJ_TREND,0,PRICE.getTime(1),PRICE.avg(1),PRICE.getTime(0),PRICE.getValue(0))){
                     ObjectSetInteger(ChartID(),"MIN",OBJPROP_COLOR,rgb2int(255,0,0));
                     ObjectSetInteger(ChartID(),"MIN",OBJPROP_STYLE,STYLE_SOLID);
                  } else {
                        Print(__FUNCTION__,": failed to create a trend line! Error code = ",GetLastError());
                        return;
                  }
                  ObjectSetInteger(ChartID(),"MIN",OBJPROP_RAY_RIGHT, true);
                  
                  if (ObjectCreate(ChartID(),"MAX",OBJ_TREND,0,PRICE.getTime(1),PRICE.avg(1),PRICE.getTime(0),PRICE.getValue(0))){
                     ObjectSetInteger(ChartID(),"MAX",OBJPROP_COLOR,rgb2int(0,255,0));
                     ObjectSetInteger(ChartID(),"MAX",OBJPROP_STYLE,STYLE_SOLID);
                  } else {
                        Print(__FUNCTION__,": failed to create a trend line! Error code = ",GetLastError());
                        return;
                  }
                  ObjectSetInteger(ChartID(),"MAX",OBJPROP_RAY_RIGHT, true);
               }

               for (int i=0; i<ICC_History_Size; i++){
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
               delete(RSI);
               delete(PRICE);
               delete(buy);
               delete(sell);
               if (!IsOptimization() && IsVisualMode()) {
                  ObjectDelete("MIN");
                  ObjectDelete("MAX");
                  for (int i=0; i<ICC_History_Size; i++){
                     ObjectDelete("MIN_"+i);
                     ObjectDelete("MAX_"+i);
                  }
               }
               
           };
  
           string getName(){
               return "ICC_ATR";
            };
            
            
            
            ENUM_TIMEFRAMES NextTimeframe;
              
            datetime LastBarOpenAt;
            
      bool isBetween(double PriceWeighted){
         //double stDev=iStdDev(NULL,ICC_ATR_Timeframe,ICC_Period,0,MODE_SMA,PRICE_CLOSE,0);
         
         //return ! (PRICE.min()>High[0] || Low[0]>PRICE.max());
         return ! (PRICE.min()>PriceWeighted || PriceWeighted>PRICE.max());
      }
                  

                  

                  
      void setup(int shift=0, int previousShift=1){
            
         //Print(__FUNCTION__,"=========ICC RECALC=======================  ");
            
            PRICE.push(Close[0],Time[0]); // ??? to avoid shift ???
            
            visualization(PRICE,ICC_History_Size);
            
            double PriceWeighted=(Open[0]+Close[0]+High[0]+Low[0])/4;
                  
            bool lateral = isBetween(PriceWeighted);// ICC_ATR_Threshold);
            if (lateral){
               CommentLab(9,StringConcatenate("ICC POSITION: LATERAL" ));
               if (_goLong && iccShort)
                  _goLong=false;
                  
               if (_goShort && iccLong)
                  _goShort=false;
               
               return;
            } 
            if (iccLong){
            
                  // LONG
                  if (High[0]<PRICE.min()){
                     strategy=LONG_UNDER_CHANNEL;
                  } else if (Low[0]>PRICE.max()){
                     strategy=LONG_ABOVE_CHANNEL;
                  }
                  CommentLab(9,StringConcatenate("ICC POSITION: LONG" ));
               
            } else if (iccShort) {
               
                  // LONG
                  if (High[0]<PRICE.min()){
                     strategy=SHORT_UNDER_CHANNEL;
                  } else if (Low[0]>PRICE.max()){
                     strategy=SHORT_ABOVE_CHANNEL;
                  }
               CommentLab(9,StringConcatenate("ICC POSITION: SHORT" ));
            
            }
            
            _goLong=iccLong;
            _goShort=iccShort;
           
            int NBars = 1; // desired number of bars to wait
            int NUnchangedBarsSinceLastRun=NBarsSince(LastBarOpenAt,ICC_ATR_Timeframe);
            if(NUnchangedBarsSinceLastRun<NBars) {
               // This tick is not in new bar
               return;
            }
            LastBarOpenAt = Time[0];
            
           
            iccCalc(iccLong,iccShort);
            
            return;
            
                  
                  //PRICE.push(iMA(NULL,ICC_ATR_Timeframe,MA_Period, 0, MODE_SMMA, PRICE_CLOSE,0),Time[0]);
                  
               
                  //icc(shift,lateral);
                  
                  
                  
            
                  
}

            bool iccShort ,iccLong;

void iccCalc(bool &goLong,bool &goShort){

      double ICCTolerance = 0;
      double ICCCurrent = iCCI(NULL, ICC_ATR_Timeframe, ICC_Period, PRICE_TYPICAL, 0);
      double ICCPrevious = iCCI(NULL, ICC_ATR_Timeframe, ICC_Period, PRICE_TYPICAL, 1);
      
      if (ICCCurrent >= ICCTolerance && ICCPrevious < ICCTolerance) {
         buy.push(sell.getValue(1));
      }
      if (ICCCurrent <= ICCTolerance && ICCPrevious > ICCTolerance) {
         sell.push(buy.getValue(1));
      }
      if (ICCCurrent >= ICCTolerance) {
         // BUY
         buy.push(Low[0] - iATR(NULL, ICC_ATR_Timeframe, ICC_ATR_Period, 0));
         if (buy.getValue(0) < buy.getValue(1)){
            buy.push(buy.getValue(1));
         }
         
         goLong = buy.getValue(0)<Low[0];
         goShort = false;
         CommentLab(8,StringConcatenate("ICC buy: ", buy.getValue(0), " GO LONG" ));
      } else if (ICCCurrent <= ICCTolerance) {
         // SELL
         sell.push(High[0] + iATR(NULL, ICC_ATR_Timeframe, ICC_ATR_Period, 0));
         if (sell.getValue(0) > sell.getValue(1)) {
            sell.push(sell.getValue(1));
         }
         
         goShort = sell.getValue(0)>High[0];
         goLong = false;
         CommentLab(8,StringConcatenate("ICC sell: ", sell.getValue(0), " GO SHORT"));
      }
      
}
   
   void icc(int shift, bool lateral){
   
               
            ENUM_TIMEFRAMES ICC_Timeframe = ICC_ATR_Timeframe;
          //    ICC_Timeframe = prevTimeframe(ICC_ATR_Timeframe,1);
            //int ICC_NewPeriod = period(ICC_Timeframe);
            //double ICCCurrent = iCCI(NULL,ICC_Timeframe, ICC_Period, PRICE_MEDIAN, shift);

            bool iccShort ,iccLong;
            iccCalc(iccLong,iccShort);
            
                        
            ///=========================================================
            RSI.push(iRSI(NULL,ICC_ATR_Timeframe,RSI_Period, PRICE_CLOSE,0),Time[0]);
            double RSImin = RSI.nextMin(0);//,RSI.getSize());
            double RSImax = RSI.nextMax(0);//,RSI.getSize());
            
            bool overbought =  false;//RSI.getValue(0)>70;
            bool oversold = false;//RSI.getValue(0)<30;
            bool RSILong = RSImin != NULL ? RSI.min()<RSImin && RSImin<30 && RSI.getValue(0)>30 : false;
            bool RSIShort = RSImax != NULL ? RSI.max()>RSImax && RSImax>70 && RSI.getValue(0)<70 : false;
            ///=========================================================
            
            CommentLab(4,StringConcatenate("RSI: Long: ", RSILong, " RSIShort: ", RSIShort));
            CommentLab(7,StringConcatenate("RSI: RSI min: ", RSImin, " RSI max:", RSImax));
            CommentLab(8,StringConcatenate("RSI oversold: ", oversold, " overbought: ", overbought));
            
            if (iccLong){
               if (lateral) {
                  if (_goShort){
                     // STOP
                     _goLong=false;
                     _goShort=false;
                     
      //          Print(__FUNCTION__,"=========ICC SHORT STOP======================= happened lateral is: ", lateral, " and go short", _goShort);
                     strategy=NONE;
                     CommentLab(9,StringConcatenate("ICC POSITION: STOP" ));
                  } else {
                     if (Low[0]>PRICE.nextMin(0) && High[0]<PRICE.nextMax(0)){
                        
                        if (RSILong && !overbought){
                           //_goShort=false;
                           //_goLong=true;
                           //strategy=LONG_INTO_CHANNEL;
                        }
                     }
                  }
               } else if (!lateral && !overbought) {
                  // LONG
                  if (High[0]<PRICE.min()){
                     strategy=LONG_UNDER_CHANNEL;
                  } else if (Low[0]>PRICE.max()){
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
                     
//                Print(__FUNCTION__,"=========ICC LONG STOP======================= happened lateral is: ", lateral, " and go long", _goLong);
                  } else {
                     if (Low[0]>PRICE.nextMin(0) && High[0]<PRICE.nextMax(0)){
                        if (RSIShort && !oversold){
                           //_goShort=true;
                           //_goLong=false;
                           //strategy=SHORT_INTO_CHANNEL;   
                        }
                     }
                  }
                  
               } else if (!lateral && !oversold) {
                  // LONG
                  if (High[0]<PRICE.min()){//,PMIN.getSize())){
                     strategy=SHORT_UNDER_CHANNEL;
                  } else if (Low[0]>PRICE.max()){
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
   
   
   
   OrderDetails orderDetails(){
               OrderDetails order;
               //return order;// TODO REMOVEME
               long dig=1/Point;

            switch (strategy){
            case LONG_UNDER_CHANNEL:
            
                  CommentLab(3,StringConcatenate("Strategy: ","LONG UNDER"," (",LONG_UNDER_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case LONG_ABOVE_CHANNEL:
            
                  
                  order.TrailingStop=MathAbs(PRICE.max()-Close[0])*dig;//PMAX.min()
                  
                  CommentLab(3,StringConcatenate("Strategy: ","LONG ABOVE"," (",LONG_ABOVE_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case LONG_INTO_CHANNEL:
            
                  order.TrailingStop=MathAbs(PRICE.min()-Close[0])*dig;//PMIN.min()
                  CommentLab(3,StringConcatenate("Strategy: ","LONG INTO"," (",LONG_INTO_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case SHORT_UNDER_CHANNEL:
                  order.TrailingStop=MathAbs(PRICE.min()-Close[0])*dig;//PMIN.max()
                  
                  //CommentLab(3,StringConcatenate("Strategy: ","SHORT UNDER"," (",SHORT_UNDER_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  CommentLab(3,StringConcatenate("Strategy: ","SHORT UNDER"," (",SHORT_UNDER_CHANNEL,") Stop_loss: ", PRICE.min()));
                  break; 
            case SHORT_ABOVE_CHANNEL:
                  
                  CommentLab(3,StringConcatenate("Strategy: ","SHORT ABOVE"," (",SHORT_ABOVE_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case SHORT_INTO_CHANNEL:
                  order.TrailingStop= MathAbs(PRICE.max()-Close[0])*dig;//PMAX.max()
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

 virtual void closeSignal(int ticket){
   
         Print("=========STOP======================= Stop happened at price: ", Close[0], " Ticket: ", ticket);
            _goLong=false;
            _goShort=false;
            strategy=NONE;
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


  