//+------------------------------------------------------------------+
//|                                                        StDev.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property version   "1.00"
#property strict


input bool STDEV_GO = false;
input bool STDEV_STOP = false;
input ENUM_TIMEFRAMES StDevTimeframe = PERIOD_H1;
//input double StDevTolerance = 0.0001;

#include "Indicator.mqh";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class StDev : public Indicator
  {
private:


      double StDevCurrent, StDevPrevious;
      double stdevM;
      double StDevAvg, StDevMax, StDevMin;
      double _goShort, _goLong;

public:
                     StDev(bool goEnabled=true, bool stopEnabled=true) :
                         Indicator(goEnabled,stopEnabled){
                     };
                    ~StDev(){};
           
                    string getName(){
                        return "StDev";
                     };        
                    
            void setup(int shift=0, int previousShift=1){
                  _goShort=false;
                  _goLong=false;
                  
                  StDevCurrent = iStdDev(NULL,StDevTimeframe, 14, PERIOD_CURRENT,MODE_SMA,PRICE_MEDIAN,shift);
                  StDevPrevious = iStdDev(NULL,StDevTimeframe, 14, PERIOD_CURRENT, MODE_SMA,PRICE_MEDIAN,previousShift+shift);
                  if (StDevMin>StDevCurrent){
                        StDevMin=StDevCurrent;
                  }
                  if (StDevMax<StDevCurrent){
                     StDevMax=StDevCurrent;
                  }
                     
                  StDevAvg=(StDevMax+StDevMin)/2;
                  if (StDevAvg < StDevCurrent) {
                     // STOP ALL
                     // not in trend???
                     if (_goLong && StDevCurrent < StDevPrevious) {
                        // going LONG, inversion may occur: stop
                        _goLong=false;
                        _goShort=false;
                        
                     } else if (_goShort && StDevCurrent > StDevPrevious) {
                        // going SHORT, inversion may occur: stop
                        _goLong=false;
                        _goShort=false;
                     }
                     return;
                  }
                     
                  if (StDevCurrent < StDevPrevious) {
                     // LONG
                     _goLong=true;
                     _goShort=false;
                     
                  } else if (StDevCurrent > StDevPrevious) {
                     // SHORT
                     _goLong=false;
                     _goShort=true;
                     
                  }
                  
                  
                  //stdevM=angle(StDevPrevious,StDevCurrent,previousShift);
                  //Comment("                                                    StdevM: ",stdevM);
                  //Print("Stdev m: ", stdevM, " StDevPrevious: ", StDevPrevious," StDevCurrent: ", StDevCurrent, " x: ",StDevTolerance);
                  
            }
            
   
   
   bool goLong(){
      return _goLong;
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