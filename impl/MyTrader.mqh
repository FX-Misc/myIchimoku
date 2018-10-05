//+------------------------------------------------------------------+
//|                                                     MyTrader.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property version   "1.00"
#property strict


//--- input parameters
input bool _debug = false;

input double Lots          =0.5;

input int ConcurrentOpenPositions = 1;

input int CheckWindow = 1;

input int PreviousShift = 1;
/*
#include "MACD.mqh"
#include "Ichimoku.mqh"
#include "RSI.mqh"
#include "SAR.mqh"
#include "StDev.mqh"

#include "FF.mqh"
*/
#include "ICC_ATR.mqh"

input const USE CombineGoSignals = MAJOR;
input const USE CombineStopSignals = OR;


#include "TradeExecutor.mqh"
//+------------------------------------------------------------------+
class MyTrader : public TradeExecutor {

 public:
 
                        void Trade(){  
                           
                 //          Print("=========CheckStoppedSignals======================= long: ",goLong()," short: ",goShort());
                        
                           CheckStoppedSignals();
                           
                 //          Print("=========InitSignals======================= long: ",goLong()," short: ",goShort());
         
                           initSignals(CombineGoSignals,CombineStopSignals);
                              
                 //          Print("=========Trade======================= long: ",goLong()," short: ",goShort());
                     
                           TradeExecutor::Trade(ConcurrentOpenPositions,Lots);
                        }
   
                        MyTrader() :  TradeExecutor()
                        { 
                        
                           int Nindicators=0;
                        /*
                           if (ICHIMOKU_GO || ICHIMOKU_STOP){
                              ArrayResize(indicators,++Nindicators);
                              this.indicators[Nindicators-1]=new Ichimoku(ICHITimeframe,ICHIMOKU_GO,ICHIMOKU_STOP);
                           }
                           if (MACD_GO || MACD_STOP){
                              ArrayResize(indicators,++Nindicators);
                              this.indicators[Nindicators-1]=new MACD(MACD_GO,MACD_STOP);
                           }
                           if (RSI_GO || RSI_STOP){
                              ArrayResize(indicators,++Nindicators);
                              this.indicators[Nindicators-1]=new RSI(RSITimeframe,RSI_GO,RSI_STOP);
                           }
                           if (SAR_GO || SAR_GO){
                              ArrayResize(indicators,++Nindicators);
                              this.indicators[Nindicators-1]=new SAR(SARTimeframe,SAR_GO,SAR_STOP);
                           }
                           if (STDEV_GO || STDEV_STOP){
                              ArrayResize(indicators,++Nindicators);
                              this.indicators[Nindicators-1]=new StDev(STDEV_GO,STDEV_STOP);
                           }
                           */
                           if (ICC_ATR_GO || ICC_ATR_STOP){
                              ArrayResize(indicators,++Nindicators);
                              this.indicators[Nindicators-1]=new ICC_ATR(ICC_ATR_GO,ICC_ATR_STOP);
                           }
                           /*
                           if (FF_GO || FF_STOP){
                              ArrayResize(indicators,++Nindicators);
                              this.indicators[Nindicators-1]=new FF(FF_GO,FF_STOP);
                           }
                           */
                         };
                         ~MyTrader(){
                              int len=ArraySize(indicators);
                              for (int i=0; i<len; i++)
                                 delete(indicators[i]);
                         }

private:

    Indicator *indicators[];
    
    // to initialize look at Trade()
    Signals signals;
    
    
    void initSignals(USE goAggregateCond, USE stopAggregateCond){
      
         int len=ArraySize(this.indicators);
         
         Signals _signals[];
         ArrayResize(_signals,len);
         for (int i=0; i<len; i++){
            Signals _sw[];
            ArrayResize(_sw,CheckWindow);
            for (int c=0; c<CheckWindow; c++){
               _sw[c] = indicators[i].getSignals(c,PreviousShift);
            }
            //ArrayFree(_sw);
            _signals[i] = Signals::aggregate(_sw, OR, OR);
            _signals[i].go_enabled=indicators[i].go_enabled;
            _signals[i].stop_enabled=indicators[i].stop_enabled;
           
            
            CommentLab(i,StringConcatenate(
               indicators[i].getName(),": ",
              _signals[i].isGoEnabled() && _signals[i].isGoLong()?"| LONG ":"",
              _signals[i].isGoEnabled() && _signals[i].isGoShort()?"| SHORT ":"",
               _signals[i].isStopEnabled() && _signals[i].isStopShort()?"| STOP SHORT ":"",
               _signals[i].isStopEnabled() && _signals[i].isStopLong()?"| STOP LONG ":""));
             
         }
         
         this.signals=Signals::aggregate(_signals, goAggregateCond, stopAggregateCond);
         ArrayFree(_signals);
               
                  
         CommentLab(len,StringConcatenate(
               "AGGREGATED: ",
               this.goLong()?"| LONG ":"",
               this.goShort()?"| SHORT ":"",
               this.stopShort()?"| STOP SHORT ":"",
               this.stopLong()?"| STOP LONG ":""));
   }
   
   
 virtual void closeSignal(int ticket){
   // cycle all the indicators and callback
    int len=ArraySize(this.indicators);
         
         for (int i=0; i<len; i++){
               
            this.indicators[i].closeSignal(ticket);
         }
 }
         
   OrderDetails orderDetails(){
      
         int len=ArraySize(this.indicators);
         
         //OrderDetails _orders[];
         //ArrayResize(_orders,len);
         OrderDetails finalOrder;
         for (int i=0; i<len; i++){
            OrderDetails order=this.indicators[i].orderDetails();
            if (order.TrailingProfit<1 || order.TrailingStop<1)
               continue;
            
            //Print("================================Indicator: ",this.indicators[i].getName()," order.profit: ", order.TrailingProfit, " TrailingStop: ", order.TrailingStop);
            
             /*
               Order operation type of the currently selected order. It can be any of the following values:
            
               OP_BUY - buy order,
               OP_SELL - sell order,
               OP_BUYLIMIT - buy limit pending order,
               OP_BUYSTOP - buy stop pending order,
               OP_SELLLIMIT - sell limit pending order,
               OP_SELLSTOP - sell stop pending order.
               */
            if (signals.isGoLong()){
               
               finalOrder.Type=OP_BUY;
               if (finalOrder.TrailingProfit<order.TrailingProfit)
                  finalOrder.TrailingProfit=order.TrailingProfit;
               if (finalOrder.TrailingStop>order.TrailingStop)
                  finalOrder.TrailingStop=order.TrailingStop;
               
            } else if (signals.isGoShort()){
            
               finalOrder.Type=OP_SELL;
               if (finalOrder.TrailingProfit<order.TrailingProfit)
                  finalOrder.TrailingProfit=order.TrailingProfit;
               if (finalOrder.TrailingStop>order.TrailingStop)
                  finalOrder.TrailingStop=order.TrailingStop;
                  
               //Print( "SELL: profit:", finalOrder.TrailingProfit, " stop:", finalOrder.TrailingStop );
               
            } else {
               
               //Print( "NO ORDER TO PERFORM");
            }
        //    Print("================================FINALLY: "," finalOrder.profit: ", finalOrder.TrailingProfit, " finalOrder.TrailingStop: ", finalOrder.TrailingStop);
         }
         
         return finalOrder;
   };
   
   bool goLong(){
      return signals.isGoLong();// && !signals.isStopLong();//  && !signals.isGoShort()
   }
   bool goShort(){
      return signals.isGoShort();// && !signals.isStopShort();//  && !signals.isGoLong();
   }
   bool stopLong(){
      return signals.isStopLong();
   }
   bool stopShort(){
      return signals.isStopShort();
      
   }
   
   
    
 };