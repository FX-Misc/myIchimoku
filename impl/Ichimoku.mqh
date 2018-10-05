//+------------------------------------------------------------------+
//|          Ichimoku.mqh |
//|          Copyright 2018, Carlo Cancellieri |
//|          ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property version   "1.00"
#property strict


input bool ICHIMOKU_GO = false;
input bool ICHIMOKU_STOP = false;
input ENUM_TIMEFRAMES ICHITimeframe = PERIOD_H1;

#include "Indicator.mqh";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Ichimoku : public Indicator
  {
private:
struct _Ichimoku {
   double ts; // Tenkan-sen
   double ks; // Kijun-sen
   double ssa; // Senkou Span A
   double ssb; // Senkou Span B
};
   
   _Ichimoku ICHICurrent,ICHIPrevious,ICHIFuture;
   _Ichimoku ICHI_NTFCurrent; // next time frame
   bool CloudSize, PriceOverTheCloud, PriceUnderTheCloud, IsGreenCloud, IntoTheCloud,WillBeGreenCloud;
   bool TsAboveKs;
   bool ICHI_NTF_IsGreenCloud;
   bool NTFTsAboveKs;
   double CloudSizeCoef;
   
   ENUM_TIMEFRAMES ICHITimeframe;
   ENUM_TIMEFRAMES ICHI_NTimeFrame;
   
   
   void setup(int shift=0, int previousShift=1){
   
      double Price =  (Bid+Ask)/2;
   
      ICHICurrent.ks = iIchimoku(NULL,ICHITimeframe,9,26,52,MODE_KIJUNSEN,shift);
      ICHICurrent.ts = iIchimoku(NULL,ICHITimeframe,9,26,52,MODE_TENKANSEN,shift);
      ICHICurrent.ssa = iIchimoku(NULL,ICHITimeframe,9,26,52,MODE_SENKOUSPANA,shift);
      ICHICurrent.ssb = iIchimoku(NULL,ICHITimeframe,9,26,52,MODE_SENKOUSPANB,shift);
      ICHIPrevious.ks = iIchimoku(NULL,ICHITimeframe,9,26,52,MODE_KIJUNSEN,previousShift+shift);
      ICHIPrevious.ts = iIchimoku(NULL,ICHITimeframe,9,26,52,MODE_TENKANSEN,previousShift+shift);//9,26,52
      ICHIPrevious.ssa = iIchimoku(NULL,ICHITimeframe,9,26,52,MODE_SENKOUSPANA,previousShift+shift);
      ICHIPrevious.ssb = iIchimoku(NULL,ICHITimeframe,9,26,52,MODE_SENKOUSPANB,previousShift+shift);
      
      ICHIFuture.ssa = iIchimoku(NULL,ICHITimeframe,9,26,52,MODE_SENKOUSPANA,previousShift+shift-26);
      ICHIFuture.ssb = iIchimoku(NULL,ICHITimeframe,9,26,52,MODE_SENKOUSPANB,previousShift+shift-26);
      
      
      ICHI_NTFCurrent.ks = iIchimoku(NULL,ICHI_NTimeFrame,9,26,52,MODE_KIJUNSEN,shift);
      ICHI_NTFCurrent.ts = iIchimoku(NULL,ICHI_NTimeFrame,9,26,52,MODE_TENKANSEN,shift);
      ICHI_NTFCurrent.ssa = iIchimoku(NULL,ICHI_NTimeFrame,9,26,52,MODE_SENKOUSPANA,shift);
      ICHI_NTFCurrent.ssb = iIchimoku(NULL,ICHI_NTimeFrame,9,26,52,MODE_SENKOUSPANB,shift);
      
      //Comment("compare with: ", CloudSizeCoef/STDEVCurrent, " < CloudSize: ", MathAbs(ICHICurrent.ssa-ICHICurrent.ssb));
      
      double StDevCurrent = iStdDev(NULL,ICHITimeframe, 52, ICHITimeframe,MODE_SMA,PRICE_MEDIAN,shift);
      CloudSize = MathAbs(ICHIFuture.ssa-ICHIFuture.ssb)>StDevCurrent/2;
     // Comment("                                                                           isCloudSize:", CloudSize ,"cloudSize: ",
     //  MathAbs(ICHIFuture.ssa-ICHIFuture.ssb), " Test: ",StDevCurrent/2,  "StDev: ",StDevCurrent);
      PriceOverTheCloud = Price > ICHICurrent.ssa;
      PriceUnderTheCloud = Price < ICHICurrent.ssa;
      IntoTheCloud = (Price > ICHICurrent.ssa && Price < ICHICurrent.ssb) || (Price < ICHICurrent.ssa && Price > ICHICurrent.ssb);
      IsGreenCloud = ICHICurrent.ssa > ICHICurrent.ssb;
      ICHI_NTF_IsGreenCloud = ICHI_NTFCurrent.ssa > ICHI_NTFCurrent.ssb;
      WillBeGreenCloud= ICHIFuture.ssa > ICHIFuture.ssb;
      TsAboveKs= ICHICurrent.ts > ICHICurrent.ks;
      NTFTsAboveKs= ICHI_NTFCurrent.ts > ICHI_NTFCurrent.ks;
      
   };
   
   
public:


                     string getName(){
                        return "Ichimoku";
                     };

   
                     Ichimoku(ENUM_TIMEFRAMES _ICHITimeframe = PERIOD_H1, bool goEnabled=true, bool stopEnabled=true) :
                         Indicator(goEnabled,stopEnabled){
                         
                        ICHITimeframe = _ICHITimeframe;
                        
                        int timeframe;
                        if (ICHITimeframe==PERIOD_CURRENT)
                          timeframe=Period();
                        else
                          timeframe=ICHITimeframe;
                        switch (timeframe){
                        case PERIOD_M1:
                        case PERIOD_M5:
                           ICHI_NTimeFrame=PERIOD_M15;
                           CloudSizeCoef=0.00006;
                           break;
                           
                        case PERIOD_M15:
                        case PERIOD_M30:
                           ICHI_NTimeFrame=PERIOD_H1;
                           CloudSizeCoef=0.0000006;
                           break;
                           
                        case PERIOD_H1:
                           ICHI_NTimeFrame=PERIOD_H4;
                           CloudSizeCoef=0.3;
                           break;
                           
                        case PERIOD_H4:
                           ICHI_NTimeFrame=PERIOD_D1;
                           CloudSizeCoef=3;
                           break;
                        
                        case PERIOD_D1:
                           ICHI_NTimeFrame=PERIOD_W1;
                           CloudSizeCoef=3;
                           break;
                           
                        case PERIOD_W1:
                           Print("Too hi level for ICHIMOKU timeframe");
                           return;
                              
                         default:
                           ICHI_NTimeFrame=PERIOD_D1;
                           CloudSizeCoef=3;
                           break;
                        }
                              
                     };
                     ~Ichimoku(){};
  
  
  
   bool goLong(){
      bool isLong = !IntoTheCloud && PriceOverTheCloud && (IsGreenCloud || WillBeGreenCloud)
      && CloudSize
      && TsAboveKs
      //&& NTFTsAboveKs
      //&& ICHI_NTF_IsGreenCloud
      ;
      
      /**
      CommentLab(1, StringConcatenate("ICHI GL: ", isLong, 
         " CSize:",CloudSize,
         " !inC:",!IntoTheCloud,
         " igC:",IsGreenCloud,
          " wbgC: ", WillBeGreenCloud,
          " ntGC:", ICHI_NTF_IsGreenCloud));
          **/
      return isLong ;
                              
   }
   
   
   bool stopLong(){
   bool isStopLong = PriceUnderTheCloud || IntoTheCloud
      || !TsAboveKs
      //|| !CloudSize
      //||  !NTFTsAboveKs
      ;//!CloudSize || 
      
   //CommentLab(2, StringConcatenate("ICHI: SL:", isStopLong, " TSKS:", !NTFTsAboveKs));
      return isStopLong;
      
   }
   bool goShort(){
   
      bool isShort = !IntoTheCloud && PriceUnderTheCloud && (!IsGreenCloud || !WillBeGreenCloud)
      && CloudSize
      && !TsAboveKs
     // && !ICHI_NTF_IsGreenCloud
    //  && !NTFTsAboveKs
      ;
      /**
            CommentLab(3, StringConcatenate("ICHI GS: ", isShort, 
         " CSize:",CloudSize,
         " !inC:",!IntoTheCloud,
         //" unC:",PriceUnderTheCloud,
         " iRC:", !IsGreenCloud && !ICHI_NTF_IsGreenCloud,
          " wbRC: ", !WillBeGreenCloud,
          " KSTS:",  !TsAboveKs && !NTFTsAboveKs));
          **/
      return isShort;
               
   }
   bool stopShort(){
      bool isStopShort = PriceOverTheCloud || IntoTheCloud
      //|| !CloudSize
      || TsAboveKs
      //|| NTFTsAboveKs
      ;
      /**
      CommentLab(4, StringConcatenate("ICHI: SS:", isStopShort, " KSTS:",  NTFTsAboveKs));
      **/
   return isStopShort;
      
   }
   
};