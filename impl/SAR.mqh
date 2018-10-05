//+------------------------------------------------------------------+
//|                                                          SAR.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property version   "1.00"
#property strict


input bool SAR_GO = false;
input bool SAR_STOP = false;
input ENUM_TIMEFRAMES SARTimeframe = PERIOD_CURRENT;

#include "Indicator.mqh";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class SAR : public Indicator
  {
private:


      double SARCurrent, SARPrevious, SARTolerance, SarM;
      ENUM_TIMEFRAMES SARTimeframe;

public:
                     SAR(ENUM_TIMEFRAMES _SARTimeframe = PERIOD_H1, bool goEnabled=true, bool stopEnabled=true, double tol=0) :
                         Indicator(goEnabled,stopEnabled){
                        SARTimeframe = _SARTimeframe;
                        SARTolerance= tol;
                     };
                    ~SAR(){};
                    
                    
                    string getName(){
                        return "SAR";
                     };
            void setup(int shift=0, int previousShift=1){
                        
                  //i==1
                  SARCurrent = iSAR(NULL,SARTimeframe,0.02,0.2,shift);
                  SARPrevious = iSAR(NULL,SARTimeframe,0.02,0.2,previousShift+shift);
                  
                  //SarM=angle(SARPrevious,SARCurrent,previousShift);
            }
   
   bool goLong(){
      double Price=MathAbs(Bid+Ask)/2;
      bool isLong = SARCurrent < Price;// && SarM >0;// Price < SARPrevious && 
      ;
      //
      return isLong ;
                              
   }
   
   
   bool stopLong(){
      double Price=MathAbs(Bid+Ask)/2;
//Print("StopLong: sar current: ", SARCurrent, " Price:",Price);
      bool isStopLong  =  SARCurrent > Price;// || SarM <=0;
   ;
    //  || stdevM <0;
   
      return isStopLong;
      
   }
   bool goShort(){
      double Price=MathAbs(Bid+Ask)/2;
   
      bool isShort = SARCurrent > Price;// && SarM <0;//&& SARCurrent > Price;
      //&& stdevM >=0
      
      ;    
      return isShort;
               
   }
   bool stopShort(){
      double Price=MathAbs(Bid+Ask)/2;
 //     Print("StopShort: sar current: ", SARCurrent, " Price:",Price);
      bool stopShort = SARCurrent < Price;//  || SarM >=0;
      ;
      //|| stdevM >0;
      
      
      return stopShort;
   }
  };