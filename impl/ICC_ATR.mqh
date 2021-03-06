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

         int Bottoms[],Toppers[];
         int BSize,BMaxIdx,BMinIdx;
         int TSize,TMaxIdx,TMinIdx;      
      
            void channelSetup(){
               ArrayResize(Toppers,ICC_History_Size);
               TSize=pushMax(Toppers,ICC_ATR_Timeframe, ICC_Search_Window,0);
               TMinIdx=0;
               TMaxIdx=0;
               for (int i=0; i<TSize; i++){
                  if (High[Toppers[i]]<High[Toppers[TMinIdx]])
                     TMinIdx=i;
                  if (High[Toppers[i]]>High[Toppers[TMaxIdx]])
                     TMaxIdx=i;
               }
               ArrayResize(Bottoms,ICC_History_Size);
               BSize=pushMin(Bottoms,ICC_ATR_Timeframe, ICC_Search_Window,0);
               BMinIdx=0;
               BMaxIdx=0;
               for (int i=0; i<BSize; i++){
                  if (Low[Bottoms[i]]<Low[Bottoms[BMinIdx]])
                     BMinIdx=i;
                  if (Low[Bottoms[i]]>Low[Bottoms[BMaxIdx]])
                     BMaxIdx=i;
               }
               
            }
            
public:

/*
//--these three functions are used to extract the RGB values from the int clr
*/

         

            ICC_ATR(bool goEnabled=true, bool stopEnabled=true) :
                Indicator(goEnabled,stopEnabled){
               LastBarOpenAt = Time[0];
               

               
               strategy=NONE;
               
               channelSetup();
               
               
               
               //iMA(NULL,ICC_ATR_Timeframe,MA_Period, 0, MODE_SMMA, PRICE_CLOSE,0));
               RSI=new Channel(ICC_History_Size,iRSI(NULL,ICC_ATR_Timeframe,RSI_Period, PRICE_CLOSE,1));
               
               
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
            
            
            
            
              
            datetime LastBarOpenAt;
         
            
      bool isBetween(double PriceWeighted){
         
         
         
         return Low[Bottoms[BMinIdx]]<Low[0] && High[0]<High[Toppers[TMaxIdx]];
         //double stDev=iStdDev(NULL,ICC_ATR_Timeframe,ICC_Period,0,MODE_SMA,PRICE_CLOSE,0);
         
         
         ENUM_TIMEFRAMES timeframe=nextTimeframe(ICC_ATR_Timeframe,1);
         double ATR = iATR(NULL, timeframe,period(timeframe), 0);
         //double PriceWeighted=(Open[0]+Close[0]+High[0]+Low[0])/4;
         return High[0]< PriceWeighted+ATR/2 && Low[0]> PriceWeighted+ATR/2;
         
      }
                  

                  
      void setup(int shift=0, int previousShift=1){
            
            channelSetup();
            
         //Print(__FUNCTION__,"=========ICC RECALC=======================  ");
            
            
            
             visualization(ICC_History_Size);
            
            double PriceWeighted=(Open[0]+Close[0]+High[0]+Low[0])/4;
                  
            
               iccCalc(iccLong,iccShort, 2);
            
            bool lateral = isBetween(PriceWeighted);// ICC_ATR_Threshold);
            if (lateral){
               CommentLab(9,StringConcatenate("ICC POSITION: LATERAL" ));
               /*
               if (_goLong && iccShort)
                  _goLong=false;
                  
               if (_goShort && iccLong)
                  _goShort=false;
               */
               
               
            } else {
            
               _goLong=iccLong;
               _goShort=iccShort;
            
            
               if (iccLong){
               
                     // LONG
                     if (High[0]<High[Bottoms[1]]){
                        strategy=LONG_UNDER_CHANNEL;
                     } else if (Low[0]>High[Bottoms[1]]){
                        strategy=LONG_ABOVE_CHANNEL;
                     }
                     CommentLab(9,StringConcatenate("ICC POSITION: LONG" ));
                  
               } else if (iccShort) {
                  
                     // LONG
                     if (High[0]<Low[Toppers[1]]){
                        strategy=SHORT_UNDER_CHANNEL;
                     } else if (Low[0]>High[Toppers[1]]){
                        strategy=SHORT_ABOVE_CHANNEL;
                     }
                     CommentLab(9,StringConcatenate("ICC POSITION: SHORT" ));
               
               }
            
            }
           
           /*
            int NBars = 1; // desired number of bars to wait
            int NUnchangedBarsSinceLastRun=NBarsSince(LastBarOpenAt,ICC_ATR_Timeframe);
            if(NUnchangedBarsSinceLastRun<NBars) {
               // This tick is not in new bar
               return;
            }
            LastBarOpenAt = Time[0];
            */
            
           
}

            bool iccShort ,iccLong;
            double buy;
            double sell;
void iccCalc(bool &goLong,bool &goShort, int Nbars){
               double buy[];
               double sell[];
               ArrayResize(buy,Nbars+1);
               ArrayResize(sell,Nbars+1);
               ArrayInitialize(buy,DBL_MIN);
               ArrayInitialize(sell,DBL_MAX);
//               iccCalc(iccLong,iccShort,window-1);

      
      for (int i = Nbars-1; i >= 0; i--) {
         double ICCCurrent = iCCI(NULL, ICC_ATR_Timeframe, ICC_Period, PRICE_TYPICAL, i);
         CommentLab(6,StringConcatenate(Time[0]," (",i,") ICCCurrent: ", ICCCurrent));
         double ICCPrevious = iCCI(NULL, ICC_ATR_Timeframe, ICC_Period, PRICE_TYPICAL, i+1);
         
         double ATR = iATR(NULL, ICC_ATR_Timeframe, ICC_ATR_Period, i);
         CommentLab(5,StringConcatenate(Time[0]," (",i,") ATR: ", ATR));
         
         if (ICCCurrent >= 0 && ICCPrevious < 0) {
            buy[i + 1] = sell[i + 1];
         }
         
         if (ICCCurrent <= 0 && ICCPrevious > 0) {
            sell[i + 1] = buy[i + 1];
         }
         
         if (ICCCurrent >= 0) {
            // BUY
            buy[i] = Low[i] - ATR;
            if (buy[i] < buy[i + 1]){
               buy[i] = buy[i + 1];
            }
            CommentLab(8,StringConcatenate(Time[0]," buy: ", buy[0], " (1): ", buy[1]));
            if (buy[0]<Low[0]) {
               this.buy=buy[0];
               goLong = true;
               goShort = false; 
             } else {
               goLong = false;
               goShort = false; 
             }
         } else if (ICCCurrent <= 0) {
            // SELL
            sell[i] = High[i] +ATR;
            if (sell[i] > sell[i + 1]) {
               sell[i] = sell[i + 1];
            }
            CommentLab(7,StringConcatenate(Time[0]," sell: ", sell[0], " (1): ", sell[1]));
            if (sell[0]>High[0]){
               this.sell=sell[0];
               goShort = true;
               goLong = false;
            } else {
               goLong = false;
               goShort = false; 
            }
         }
      }

   }
   
   
   
   OrderDetails orderDetails(){
               OrderDetails order;
               //return order;// TODO REMOVEME
               long dig=1/Point;
               double PriceWeighted=(Open[0]+Close[0]+High[0]+Low[0])/4;
               order.Price=_goLong?buy:sell;
               
               double ATR = iATR(NULL, ICC_ATR_Timeframe, ICC_ATR_Period, 0);
               
            switch (strategy){
            case LONG_UNDER_CHANNEL:
            
                  CommentLab(3,StringConcatenate("Strategy: ","LONG UNDER"," (",LONG_UNDER_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case LONG_ABOVE_CHANNEL:
            
                  
                  order.TrailingStop=MathAbs(High[Bottoms[1]]-Close[0])*dig;//PMAX.min()
                  
                  CommentLab(3,StringConcatenate("Strategy: ","LONG ABOVE"," (",LONG_ABOVE_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case LONG_INTO_CHANNEL:
            
                  
                  CommentLab(3,StringConcatenate("Strategy: ","LONG INTO"," (",LONG_INTO_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case SHORT_UNDER_CHANNEL:
                  order.TrailingStop=MathAbs(Low[Toppers[1]]+ATR-Close[0])*dig;//PMIN.max()
                  
                  CommentLab(3,StringConcatenate("Strategy: ","SHORT UNDER"," (",SHORT_UNDER_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  
                  break; 
            case SHORT_ABOVE_CHANNEL:
                  
                  CommentLab(3,StringConcatenate("Strategy: ","SHORT ABOVE"," (",SHORT_ABOVE_CHANNEL,") Order: profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop));
                  break;
            case SHORT_INTO_CHANNEL:
                  
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
   
   
   
  void visualization(int ICC_History_Size){
  /*
  
            int NBars = 1; // desired number of bars to wait
            int NUnchangedBarsSinceLastRun=NBarsSince(LastBarOpenAt,ICC_ATR_Timeframe);
            if(NUnchangedBarsSinceLastRun<NBars) {
               // This tick is not in new bar
               return;
            }
            LastBarOpenAt = Time[0];
            */
            
            
               
            
            if (!IsOptimization() && IsVisualMode()) {


                     // MIN
                  
                  /*
Print("Looking at Bottoms: =========");
for(int i=0; i<ArraySize(Bottoms); i++)
{
//if (Bottoms[i]!=0)
   Print("("+i+"):  "+Bottoms[i], " time: ",Time[Bottoms[i]]);
}
*/
                  if (ObjectFind(ChartID(),"MIN")<0)
                  if (ObjectCreate(ChartID(),"MIN",OBJ_TREND,0,Time[Bottoms[0]],Low[Bottoms[0]],Time[Bottoms[0]],Low[Bottoms[0]])){
                     ObjectSetInteger(ChartID(),"MIN",OBJPROP_COLOR,rgb2int(255,0,0));
                     ObjectSetInteger(ChartID(),"MIN",OBJPROP_STYLE,STYLE_SOLID);
                     ObjectSetInteger(ChartID(),"MIN",OBJPROP_RAY_RIGHT, true);
                     ObjectSetInteger(ChartID(),"MIN",OBJPROP_WIDTH,2);
                  } else {
                        Print(__FUNCTION__,": failed to create a trend line! Error code = ",GetLastError());
                        return;
                  }

                     string min_msg="ICC MIN: ";
                     //ArraySort(Bottoms,WHOLE_ARRAY,0,MODE_ASCEND);
                     for (int i=0,j=0; i<ICC_Search_Window; i++){
                        if (j<BSize){
                           if (i == Bottoms[j]){
                              j++;
                              min_msg=StringConcatenate(min_msg, " ", Low[i]);
                              
                              
                              int red = 255-(j*10);
                              red= red>-1?red:100;
                              color c = rgb2int(red,0,0);
                              
                              if (ObjectFind(ChartID(),"MIN_"+i)>-1) {
                                 ObjectMove(ChartID(),"MIN_"+i,0,Time[i],Low[i]);
                              } else if (!ObjectCreate(ChartID(),"MIN_"+i, OBJ_HLINE, 0, Time[i], Low[i], Time[0], Low[0])) {
                                 Print(__FUNCTION__,": failed to create a minimum level line! Error code = ",GetLastError());
                                 return;
                              }
                              
                              ObjectSetInteger(ChartID(),"MIN_"+i,OBJPROP_COLOR,c);
                              
                              if (i==BMinIdx){
                                 // extrems
                                 ObjectSetInteger(ChartID(),"MIN_"+BMinIdx,OBJPROP_STYLE,STYLE_SOLID);
                                 ObjectSetInteger(ChartID(),"MIN_"+BMinIdx,OBJPROP_WIDTH,2);
                                 CommentLab(5,StringConcatenate("ICC Window: Value MIN idx: ",BMinIdx, " value: ",Low[BMinIdx]));
                              } else {
                                 ObjectSetInteger(ChartID(),"MIN_"+i,OBJPROP_STYLE,STYLE_DOT);
                                 ObjectSetInteger(ChartID(),"MIN_"+i,OBJPROP_WIDTH,1);
                              }
                           
                           } else if  (i != Bottoms[j]){
                              //ObjectSetInteger(ChartID(),"MIN_"+i,OBJPROP_COLOR,rgb2int(0,0,0));
                              ObjectDelete(ChartID(),"MIN_"+i);
                           }
                        } else {
                           //ObjectSetInteger(ChartID(),"MIN_"+i,OBJPROP_COLOR,rgb2int(0,0,0));
                           ObjectDelete(ChartID(),"MIN_"+i);
                        }
                     }
                     CommentLab(10,min_msg);
                     
                     TrendPointChange(ChartID(),"MIN",0,Time[Bottoms[BSize-1]],Low[Bottoms[BSize-1]]);
                     TrendPointChange(ChartID(),"MIN",1,Time[Bottoms[0]],Low[Bottoms[0]]);
                     
                     
                     // MAX
                     
                     //ArraySort(Toppers,WHOLE_ARRAY,0,MODE_ASCEND);
                     
                     if (ObjectFind(ChartID(),"MAX")<0)
                     if (ObjectCreate(ChartID(),"MAX",OBJ_TREND,0,Time[Toppers[1]],High[Toppers[1]],Time[Toppers[0]],High[Toppers[0]])){
                        ObjectSetInteger(ChartID(),"MAX",OBJPROP_COLOR,rgb2int(0,255,0));
                        ObjectSetInteger(ChartID(),"MAX",OBJPROP_STYLE,STYLE_SOLID);
                        ObjectSetInteger(ChartID(),"MAX",OBJPROP_RAY_RIGHT, true);
                        ObjectSetInteger(ChartID(),"MAX",OBJPROP_WIDTH,2);
                     } else {
                           Print(__FUNCTION__,": failed to create a trend line! Error code = ",GetLastError());
                           return;
                     }

/*
Print("Looking at Toppers: =========");
for(int i=0; i<ArraySize(Toppers); i++)
{
//if (Toppers[i]!=0)
   Print("("+i+"):  "+Toppers[i], " time: ",Time[Toppers[i]]);
}
*/


                     string max_msg="ICC MAX: ";
                     for (int i=0,j=0; i<ICC_Search_Window; i++){
                     
//Print("printing (MAX_",i,") Toppers[",j,"]: ",Toppers[j]);
                        if (j<TSize){
                           if (i == Toppers[j]){
                              j++;
                           
                              max_msg=StringConcatenate(max_msg, " ", High[i]);
                              
                              int green = 255-(j*10);
                              green= green>-1?green:100;
                              color c = rgb2int(0,green,0);
                              
                              if (ObjectFind(ChartID(),"MAX_"+i)>-1) {
                                 ObjectMove(ChartID(),"MAX_"+i,0,Time[i],High[i]);
                              } else if (ObjectCreate(ChartID(),"MAX_"+i, OBJ_HLINE, 0, Time[i], High[i], Time[0], High[0])){
                                 Print(__FUNCTION__,": failed to create a minimum level line! Error code = ",GetLastError());
                                 return;
                              } 
                              
                              ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_COLOR,c);
                              
                              if (i==TMaxIdx){
                                 // extrems
                                 ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_STYLE,STYLE_SOLID);
                                 ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_WIDTH,2);
                                 CommentLab(5,StringConcatenate("ICC Window: Value MAX idx: ",TMaxIdx, " value: ",High[TMaxIdx]));
                              } else {
                                 ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_STYLE,STYLE_DOT);
                                 ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_WIDTH,1);
                              }
                              
                              
                           } else if  (i != Toppers[j]){
                              //ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_COLOR,rgb2int(0,0,0));
                              ObjectDelete(ChartID(),"MAX_"+i);
                           }
                           
                        } else {
                           ObjectDelete(ChartID(),"MAX_"+i);
                           //ObjectSetInteger(ChartID(),"MAX_"+i,OBJPROP_COLOR,rgb2int(0,0,0));
                        }
                     }
                     CommentLab(11,max_msg);
                     
                     
                     TrendPointChange(ChartID(),"MAX",0,Time[Toppers[TSize-1]],High[Toppers[TSize-1]]);
                     TrendPointChange(ChartID(),"MAX",1,Time[Toppers[0]],High[Toppers[0]]);
                     
                     
                  }
  
 }
                  

   
   
   
   
  };


  