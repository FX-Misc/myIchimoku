//+------------------------------------------------------------------+
//|                                                           FF.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property version   "1.00"
#property strict


input bool FF_GO = false;
input bool FF_STOP = false;
input ENUM_TIMEFRAMES FFTimeframe = PERIOD_H1;

//////////////======================
input int    FFNpast   =900;     // Past bars, to which trigonometric series is fitted
input int    FFNfut    =150;      // Predicted future bars
input int    FFNharm   =20;      // Narmonics in model
input double FFFreqTOL =0.0001; // Tolerance of frequency calculations
//////////////======================

#include "Indicator.mqh";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class FF : public Indicator
  {
private:


//////////////======================
int    FFNpast;     // Past bars, to which trigonometric series is fitted
int    FFNfut;      // Predicted future bars
int    FFNharm;      // Narmonics in model
double FFFreqTOL; // Tolerance of frequency calculations
//////////////======================

      double FFCurrent, FFPrevious, FFTolerance;
      
      double FFMax, FFMin;
      
public:
                     FF(bool goEnabled=true, bool stopEnabled=true) :
                         Indicator(goEnabled,stopEnabled){
                        
                        
    FFNpast   =900;     // Past bars, to which trigonometric series is fitted
    FFNfut    =150;      // Predicted future bars
    FFNharm   =20;      // Narmonics in model
 FFFreqTOL =0.0001; // Tolerance of frequency calculations
                        
                     };
                    ~FF(){};
                    
                    
                     string getName(){
                        return "FF";
                     };
            void setup(int shift=0, int previousShift=1){
                        
                  
      FFMax=DBL_MIN;
      FFMin = DBL_MAX;
      for (int i=0; i<FFNfut; i++){
         FFCurrent= iCustom(NULL,0,"fourier_extrapolator_of_price", FFNpast,FFNfut,FFNharm,FFFreqTOL, 0,-i);
         if (FFCurrent > FFMax)
            FFMax = FFCurrent;
         else if (FFCurrent < FFMin)
            FFMin = FFCurrent;
      }
      FFMin=NormalizeDouble( FFMin, Digits );
      FFMax=NormalizeDouble( FFMax, Digits );
      //Print(" Go from:", Bid, " FFMIN: ", FFMin, " FFMAX: ", FFMax );
            }
            
            
   bool goLong(){
   
      double Price=Bid;
      double DeltaShort = MathAbs(Price-FFMin);
      double DeltaLong = MathAbs(FFMax-Price);
      if (DeltaShort<DeltaLong && FFMax>Price) {
         /**
         double _TakeProfit = (NormalizeDouble( DeltaShort, Digits )/Point);
         double _TrailingStop = (NormalizeDouble( DeltaLong , Digits )/Point);
         TakeProfit = TakeProfit < _TakeProfit ? TakeProfit : _TakeProfit ;
         TrailingStop = TrailingStop < _TrailingStop ? TrailingStop : _TrailingStop ;
         **/
         //if (_debug) Print(" Go long from:", Price, " up to: ", FFMax, " with TP: ",TakeProfit, " and SL: ", TrailingStop );
         return true;
      }
      return false;
      //bool isLong =
                  ;
      //return isLong ;
                              
   }
   
   
   bool stopLong(){
      double Price=Bid;
      double DeltaShort = Price-FFMin;
      double DeltaLong = FFMax-Price;
      if (DeltaShort>DeltaLong)
         return true;
      return false;
   //bool isStopLong  = 
   
      //return isStopLong;
      
   }
   bool goShort(){
   
      double Price=Ask;
      double DeltaShort = MathAbs(Price-FFMin);
      double DeltaLong = MathAbs(FFMax-Price);
      if (DeltaShort>DeltaLong && FFMin<Price) {
         /**
         double _TakeProfit = (NormalizeDouble( DeltaShort, Digits )/Point);
         double _TrailingStop = (NormalizeDouble( DeltaLong , Digits )/Point);
         TakeProfit = TakeProfit < _TakeProfit ? TakeProfit : _TakeProfit ;
         TrailingStop = TrailingStop < _TrailingStop ? TrailingStop : _TrailingStop ;
         **/
         //if (_debug)
         // Print(" Go short from:", Price, " down to: ", FFMin, " with TP: ",TakeProfit, " and SL: ", TrailingStop );
         return true;
      }
      return false;
     // bool isShort =
      
      ;    
      //return isShort;
               
   }
   bool stopShort(){
   
      double Price=Ask;
      double DeltaShort = Price-FFMin;
      double DeltaLong = FFMax-Price;
      if (DeltaShort<DeltaLong)
         return true;
      return false;
     // bool stopShort = 
      
      
      //return stopShort;
   }
  };