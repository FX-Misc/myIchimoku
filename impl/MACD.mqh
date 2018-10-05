//+------------------------------------------------------------------+
//|                                                         MACD.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property version   "1.00"
#property strict


input bool MACD_GO = false;
input bool MACD_STOP = false;
input ENUM_TIMEFRAMES MACDTimeframe = PERIOD_CURRENT;

//input int MACDFast = 12;
//input int MACDSlow = 26;
//input double MACDThreshold =2;

#include "Indicator.mqh";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MACD : public Indicator
  {
   ENUM_TIMEFRAMES MACDTimeframe;
   
 double MacdCurrent,MacdPrevious;
 double SignalCurrent,SignalPrevious;
 double MaCurrent,MaPrevious;
 
   int MACDFast;
   int MACDSlow;
   double MACDThreshold;
   
public:

                     MACD( bool goEnabled=true, bool stopEnabled=true) :
                         Indicator(goEnabled,stopEnabled){
                        
                           MACDFast = 12;
                           MACDSlow = 26;
                           MACDThreshold =2;
                                                      
                     };
                     ~MACD(){};
  
                     string getName(){
                        return "MACD";
                     };
  
   void setup(int shift=0, int previousShift=1){
   
   
      //i==0
      MacdCurrent=iMACD(NULL,PERIOD_CURRENT,MACDFast,MACDSlow,9,PRICE_TYPICAL,MODE_MAIN,shift);
      MacdPrevious=iMACD(NULL,PERIOD_CURRENT,MACDFast,MACDSlow,9,PRICE_TYPICAL,MODE_MAIN,previousShift+shift);
      SignalCurrent=iMACD(NULL,PERIOD_CURRENT,MACDFast,MACDSlow,9,PRICE_TYPICAL,MODE_SIGNAL,shift);
      SignalPrevious=iMACD(NULL,PERIOD_CURRENT,MACDFast,MACDSlow,9,PRICE_TYPICAL,MODE_SIGNAL,previousShift+shift);
   };
  
   bool goLong(){
      bool isLong =SignalPrevious < SignalCurrent && MacdPrevious < MacdCurrent // tendence
                  && MacdPrevious < SignalPrevious && MacdCurrent > SignalCurrent // signal crosses MACD
                  && SignalCurrent < 0 && MacdCurrent < 0 // IMPORTANT // position
                  //&& MathAbs(MacdCurrent) > (MaCurrent/2) // threshold
                  ;
      return isLong ;
                              
   }
   
   
   bool stopLong(){
   bool isStopLong  = 
                  ( 
                  MacdCurrent > SignalCurrent && MacdPrevious < SignalPrevious
                  && MathAbs(MacdCurrent) < MACDThreshold
                  )
                  ||
                  (
                  (SignalPrevious>0 && SignalCurrent<0) // cross from up to down
                  && MathAbs(MacdCurrent) > MACDThreshold // threshold
                  );
   
      return isStopLong;
      
   }
   bool goShort(){
   
      bool isShort = SignalPrevious > SignalCurrent && MacdPrevious > MacdCurrent // tendence
                  && MacdPrevious > SignalPrevious && MacdCurrent < SignalCurrent // signal crosses MACD
                  && SignalCurrent > 0 && MacdCurrent > 0 // IMPORTANT // position
                 // && MathAbs(MacdCurrent) > MACDThreshold // threshold
      
      ;    
      return isShort;
               
   }
   bool stopShort(){
   
      return (
               MacdCurrent<SignalCurrent && MacdPrevious>SignalPrevious
          //     && MathAbs(MacdCurrent) < MACDThreshold
               )
               ||
               ( 
               (SignalPrevious<0 && SignalCurrent>0) // cross from down to up
          //     && MathAbs(MacdCurrent) < MACDThreshold // threshold
               );
   }
   
};