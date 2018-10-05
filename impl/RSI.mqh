//+------------------------------------------------------------------+
//|                                                          RSI.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property version   "1.00"
#property strict


input bool RSI_GO = false;
input bool RSI_STOP = false;
input ENUM_TIMEFRAMES RSITimeframe = PERIOD_H4;
//input double RSITolerance = 0.0001;

#include "Indicator.mqh";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class RSI : public Indicator
  {
private:


      double RSICurrent, RSIPrevious, RsiM;
      ENUM_TIMEFRAMES RSITimeframe;

public:
                     RSI(ENUM_TIMEFRAMES _RSITimeframe = PERIOD_H1, bool goEnabled=true, bool stopEnabled=true):
                         Indicator(goEnabled,stopEnabled){
                        RSITimeframe = _RSITimeframe;
                     };
                    ~RSI(){};
                    
                    string getName(){
                        return "RSI";
                     };
                     
            void setup(int shift=0, int previousShift=1){
                        
                  //i==1
                  RSICurrent = iRSI(NULL,RSITimeframe,13,PRICE_MEDIAN,shift);
                  RSIPrevious = iRSI(NULL,RSITimeframe,13,PRICE_MEDIAN,previousShift+shift);
                  //Print("RSIC: ",RSICurrent);
                  //Print("RSIP: ",RSIPrevious);
                  //RsiM=angle(RSIPrevious,RSICurrent,previousShift);
                  
            }
            
            
   bool goLong(){
      bool isLong =RSICurrent>30;// && RsiM>0;
                  //Print("isLong: ",isLong);
      return isLong ;
                              
   }
   
   
   bool stopLong(){
   bool isStopLong  =  
               RSICurrent>70;// || RsiM<=0;
   
                  //Print("isStopLong: ",isStopLong);
      return isStopLong;
      
   }
   bool goShort(){
   
      bool isShort = RSICurrent>70;// && RsiM<0;
      
      ;    
                  //Print("isShort: ",isShort);
      return isShort;
               
   }
   bool stopShort(){
   
      bool stopShort =  
               RSICurrent<30;// || RsiM>=0;
      
                  //Print("stopShort: ",stopShort);
      
      return stopShort;
   }
  };