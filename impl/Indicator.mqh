//+------------------------------------------------------------------+
//|                                                    Indicator.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

input int Trailing_Profit    = 5000 ;
input int Trailing_Stop  = 1000;

class Indicator {

   private:
   
      virtual void setup(int shift=0, int previousShift=1)=NULL;
      
      protected:
      
         
     public:
      bool go_enabled;
      bool stop_enabled;
     
         virtual bool goLong()=NULL;
         virtual bool goShort()=NULL;
         virtual bool stopLong()=NULL;
         virtual bool stopShort()=NULL;
         
         // callback called by tradeExecutor when an order is closed by stop loss or profit
         virtual void closeSignal(int ticket){};
 
   enum USE {
         AND=0,
         OR=1,
         MAJOR=2
   };


struct Signals {

public:
   bool goLong;
   bool stopLong;
   bool goShort;
   bool stopShort;
   
   bool go_enabled;
   bool stop_enabled;
   
   ~Signals(){};
   /**Signals(){
      this.go_enabled=true;
      this.stop_enabled=true;
      this.goLong=false;
      this.goShort=false;
      this.stopLong=false;
      this.stopShort=false;
   };**/
   Signals(bool _go_enabled=true, bool _stop_enabled=true){
      this.go_enabled=_go_enabled;
      this.stop_enabled=_stop_enabled;
   }
   Signals(Signals &s){
      this.go_enabled=s.go_enabled;
      this.stop_enabled=s.stop_enabled;
      this.goLong=s.goLong;
      this.goShort=s.goShort;
      this.stopLong=s.stopLong;
      this.stopShort=s.stopShort;
   };
   
   
   bool isGoEnabled(){return go_enabled;};
   bool isStopEnabled(){return stop_enabled;};
   
    bool isGoLong(){
      return goLong;// && !stopLong && !goShort;// && !stopShort;
      //return calc(_goLong,CombineSignals) && !calc(_stopLong) && !calc(_goShort);
   }
   bool isGoShort(){
      return goShort;// && !stopShort && !goLong; //&& !stopLong;
      //return calc(_goShort,CombineSignals) && !calc(_stopShort) && !calc(_goLong);
   }
   bool isStopLong(){
      // stop conditions must be calculated using && otherwise we
      // will close a position for conditions verified in the past (window)
      return stopLong;// && !goShort && !stopShort && !goLong;
      
   }
   bool isStopShort(){
      // stop conditions must be calculated using && otherwise we
      // will close a position for conditions verified in the past (window)
      return stopShort;// && !goShort && !stopLong && !goLong;
      
   }
   
   
   
   static Signals aggregate(Signals &s1[],  USE go_cond=AND, USE stop_cond=AND){
      
      Signals ret();
      ret.goLong=go_cond==AND?true:false;
      ret.goShort=go_cond==AND?true:false;
      
      int len=ArraySize(s1);
      switch (go_cond){
            case AND:{
                  for (int i=0; i<len; i++){
                     if (!s1[i].isGoEnabled())
                        continue;
                     ret.goLong=s1[i].isGoLong() && ret.isGoLong();
                     ret.goShort=s1[i].isGoShort() && ret.isGoShort();
                  }
                  break;
               }
            case OR:{
                  for (int i=0; i<len; i++){
                     if (!s1[i].isGoEnabled())
                        continue;
                     ret.goLong=s1[i].isGoLong() || ret.isGoLong();
                     ret.goShort=s1[i].isGoShort() || ret.isGoShort();
                  }
                  break;
               }
             case MAJOR:
             default:
             {
                     bool _goLong[];
                     bool _goShort[];
                     int enabled=0;
                     for (int i=0; i<len; i++){
                        if (!s1[i].isGoEnabled())
                           continue;
                        enabled++;
                     }
                     ArrayResize(_goLong,enabled);
                     ArrayResize(_goShort,enabled);
                     for (int i=0,k=0; i<len && k<enabled; i++){
                        if (!s1[i].isGoEnabled())
                           continue;
                        _goLong[k]=s1[i].isGoLong();
                        _goShort[k]=s1[i].isGoShort();
                         k++;
                     }
                     ret.goLong=major(_goLong);
                     ret.goShort=major(_goShort);
                     //delete(_goLong);
                     //delete(_goShort);
                     break;
             }
       }
       
      ret.stopLong=stop_cond==AND?true:false;
      ret.stopShort=stop_cond==AND?true:false;
      
      switch (stop_cond){
            case AND:{
                  for (int i=0; i<len; i++){
                     if (!s1[i].isStopEnabled())
                        continue;
                     ret.stopLong=s1[i].isStopLong() && ret.isStopLong();
                     ret.stopShort=s1[i].isStopShort() && ret.isStopShort();
                  }
                  break;
               }
            case OR:{
            
                  for (int i=0; i<len; i++){
                     if (!s1[i].isStopEnabled())
                        continue;
                     ret.stopLong=s1[i].isStopLong() || ret.isStopLong();
                     ret.stopShort=s1[i].isStopShort() || ret.isStopShort();

                  }
                  break;
               }
             case MAJOR:
             default:
             {
                     bool _stopLong[];
                     bool _stopShort[];
                     int enabled=0;
                     for (int i=0; i<len; i++){
                        if (!s1[i].isStopEnabled())
                           continue;
                        enabled++;
                     }
                     ArrayResize(_stopLong,enabled);
                     ArrayResize(_stopShort,enabled);
                     for (int i=0,k=0; i<len && k<enabled; i++){
                        if (!s1[i].isStopEnabled())
                           continue;
                        _stopLong[k]=s1[i].isStopLong();
                        _stopShort[k]=s1[i].isStopShort();
                         k++;
                     }
                     ret.stopLong=major(_stopLong);
                     ret.stopShort=major(_stopShort);
                    // delete(_stopLong);
                    // delete(_stopShort);
                    break;
             }
       }
       return ret;
   }
   
  
   static bool major(bool &a[]){
         int len=ArraySize(a);
         int nFalse=0,nTrue=0;
         for (int i=0; i<len; i++){
            if (a[i])
               nTrue++;
            else
               nFalse++;
         }
         return nFalse>nTrue?false:true;
   }
   
};

      virtual string getName()=NULL;
   
      Signals getSignals(int shift=0, int previousShift=1){
         
         Signals signals(go_enabled,stop_enabled);
         if (go_enabled || stop_enabled)
            this.setup(shift,previousShift);
         signals.goLong=goLong();
         signals.goShort=goShort();
         signals.stopLong=stopLong();
         signals.stopShort=stopShort();
         return signals;
      }
     
      struct OrderDetails {
         int TrailingProfit;
         int TrailingStop;
         /*
         Order operation type of the currently selected order. It can be any of the following values:
      
         OP_BUY - buy order,
         OP_SELL - sell order,
         OP_BUYLIMIT - buy limit pending order,
         OP_BUYSTOP - buy stop pending order,
         OP_SELLLIMIT - sell limit pending order,
         OP_SELLSTOP - sell stop pending order.
         */
         int Type;
         OrderDetails(){
            this.TrailingProfit=Trailing_Profit;
            this.TrailingStop=Trailing_Stop;
         }
         OrderDetails(OrderDetails &od){
            this.TrailingProfit=od.TrailingProfit;
            this.TrailingStop=od.TrailingStop;
            this.Type=od.Type;
         }
      };
      
      virtual OrderDetails orderDetails(){
         OrderDetails order;
         if(order.TrailingProfit<1 || order.TrailingStop<1){
            Print("TrailingProfit or TrailingStop less than 1");
         }
         return order;
      }
     
         Indicator(){
         };
         
         Indicator(Indicator &i){
            this.go_enabled=i.go_enabled;
            this.stop_enabled=i.stop_enabled;
         }
         Indicator(bool _go_enabled=true, bool _stop_enabled=true){
            this.go_enabled=_go_enabled;
            this.stop_enabled=_stop_enabled;
         };
         
          ~Indicator(){};
          
          
   
   static double angle1(double first, double second, int shift){
                  
                  int y1,y2;
                  int x1,x2;
                  
                  ChartTimePriceToXY(0,0,Time[shift],Close[shift],x1,y1);
                  ChartTimePriceToXY(0,0,Time[0],Close[0],x2,y2);
                  if (y2-y1!=0){
//                     Print("Arctg(DEG): ", ((MathArctan((x2-x1)/(y2-y1)))*180)/M_PI);
                     return ((MathArctan((x2-x1)/(y2-y1)))*180)/M_PI;
                  }
                  return 0;
                  }
                  
                  
   static double angle(double first, double second, double shift){
                     double q=first;
                     double y=second;
                     double x=shift;
                     return (y-q)/x;
                  }
                                 
   }  ;