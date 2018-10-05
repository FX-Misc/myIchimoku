#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Black
#property indicator_color4 Black

extern int CCPeriod = 50;
extern int ATRPeriod = 5;

double buy[];
double sell[];
int ICCTolerance = 0;

int init() {
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexBuffer(0, buy);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexBuffer(1, sell);
   return (0);
}

int deinit() {
   return (0);
}

int start() {
   {
   double ICCCurrent;
   double ICCPrevious;
   int NUnchangedBarsSinceLastRun = IndicatorCounted();
   if (NUnchangedBarsSinceLastRun < 0) return (-1);
   if (NUnchangedBarsSinceLastRun > 0) NUnchangedBarsSinceLastRun--;
   int li_0 = Bars - NUnchangedBarsSinceLastRun;
   for (int i = li_0; i >= 0; i--) {
      ICCCurrent = iCCI(NULL, 0, CCPeriod, PRICE_TYPICAL, i);
      ICCPrevious = iCCI(NULL, 0, CCPeriod, PRICE_TYPICAL, i + 1);
      if (ICCCurrent >= ICCTolerance && ICCPrevious < ICCTolerance) {
         buy[i + 1] = sell[i + 1];
      }
      if (ICCCurrent <= ICCTolerance && ICCPrevious > ICCTolerance) {
         sell[i + 1] = buy[i + 1];
      }
      if (ICCCurrent >= ICCTolerance) {
         // BUY
         buy[i] = Low[i] - iATR(NULL, 0, ATRPeriod, i);
         if (buy[i] < buy[i + 1]){
            buy[i] = buy[i + 1];
         }
      } else {
         if (ICCCurrent <= ICCTolerance) {
            // SELL
            sell[i] = High[i] + iATR(NULL, 0, ATRPeriod, i);
            if (sell[i] > sell[i + 1]) {
               sell[i] = sell[i + 1];
            }
         }
      }
   }
   }
   return (0);
}