//+------------------------------------------------------------------+
//|                                                TradeExecutor.mqh |
//|                                Copyright 2018, Carlo Cancellieri |
//|                                         ccancellieri@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Carlo Cancellieri"
#property link      "ccancellieri@hotmail.com"
#property version   "1.00"
#property strict

#include <stderror.mqh>
#include <stdlib.mqh>

#include "Indicator.mqh";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class TradeExecutor
  {
  
  
public:
     TradeExecutor()
     {
     }
     
     ~TradeExecutor()
     {
         ObjectDelete("Buy");
         ObjectDelete("Sell");
     }
private:

protected:
       int orders[];
      
      // util: check last error, printing and returning it
      string  printLastError(){
                  int check=GetLastError();
                  if(check!=ERR_NO_ERROR)
                     return ErrorDescription(check);
                  else
                     return "no error";
      }
      
      void DrawArrow(string name,double value, const uchar  code, int _color,string text){
         ObjectCreate(name,OBJ_ARROW,0,TimeCurrent(),value);
         ObjectSet(name,OBJPROP_COLOR,_color);
         ObjectSet(name,OBJPROP_STYLE,STYLE_SOLID);
         ObjectSet(name, OBJPROP_ARROWCODE, code);
         ObjectSet(name,OBJPROP_BACK,false);
         ObjectSetText(name, text, 6);
      }
      
      double getTrailingStop(int _TrailingStop){
          // TODO: use also freeze
         // https://book.mql4.com/appendix/limits
         double   freezeLevel = NormalizeDouble(  MarketInfo(Symbol(),MODE_FREEZELEVEL)* Point, Digits );
         //--- get minimum stop level   
         double minstoplevel=NormalizeDouble( MarketInfo(Symbol(),MODE_STOPLEVEL )* Point, Digits );
         
         minstoplevel=minstoplevel>freezeLevel?freezeLevel:minstoplevel;
         
         double trailingStop = NormalizeDouble(_TrailingStop * Point, Digits );
         //if (_debug)Print( "Minimum Stop Level=", minstoplevel,  " Trailing Stop =", trailingStop );
         if (trailingStop < minstoplevel)                  // If less than allowed
            return minstoplevel;                     // New value of TS
         return trailingStop;
      }
      
      double getTrailingProfit(int _TakeProfit){
          // TODO: use also freeze
         // https://book.mql4.com/appendix/limits
         double   freezeLevel = NormalizeDouble(  MarketInfo(Symbol(),MODE_FREEZELEVEL)* Point, Digits );
         //--- get minimum stop level   
         double minstoplevel=NormalizeDouble( MarketInfo(Symbol(),MODE_STOPLEVEL )* Point, Digits );
         
         minstoplevel=minstoplevel>freezeLevel?freezeLevel:minstoplevel;
         
         double trailingProfit = NormalizeDouble(_TakeProfit * Point, Digits );
         //if (_debug)Print( "Maximum Profit Stop Level=", minstoplevel,  " Trailing profit =", trailingProfit );
         if (trailingProfit < minstoplevel)                  // If less than allowed
            return minstoplevel;                     // New value of TS
         return trailingProfit;
      }

      // orders
      void Trade(int ConcurrentOpenPositions = 2,
                              double Lots =0.1) {
      
         if (ArraySize(orders)!=ConcurrentOpenPositions){
            ArrayResize(orders, ConcurrentOpenPositions);
            ArrayInitialize(orders, -1);
         }
            
         
         if(Bars<100) {
            Print("bars less than 100");
            return;
         }
      
         if(AccountFreeMargin()<(1000*Lots)){
            Print("We have no money. Free Margin = ",AccountFreeMargin());
            return;
         }
         
         if(OrdersTotal()<ConcurrentOpenPositions){
            
            if (goLong() && goShort()){
               Print("ERROR: Unable to proceed: both LONG and SHORT signal detected! Pls, check your indicators");
               return;
            }
            OrderDetails order = orderDetails();
            int Type=order.Type;
            double stop=getTrailingStop(order.TrailingStop);
            double profit=getTrailingProfit(order.TrailingProfit);
               
            //--- check for long position (BUY) possibility
            if(goLong()) {
            
               //--- calculated SL and TP prices must be normalized
               double stoploss   = Bid - stop;
               double takeprofit = Bid + profit;
               //if (_debug)Print( "Going Long: Price(", Ask,") TP(",takeprofit,"), SL(",stoploss,")");
               int ticket = OrderSend( Symbol(), OP_BUY, Lots, Ask, 3, stoploss, takeprofit, "My order", 16384, 0, Green );
               if(ticket>0 && push(orders,ticket)){
                  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                     DrawArrow("Buy",OrderOpenPrice(),SYMBOL_ARROWUP,Green,"Open Buy");
               } else {
                  
                  Print("Unable to open BUY order: ", printLastError());
                  return;
               }
            }
            if (goShort()) {
               //--- check for short position (SELL) possibility
               //--- calculated SL and TP prices must be normalized
               double stoploss   = Ask + stop;
               double takeprofit = Ask - profit;
               int ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, stoploss, takeprofit, "My order", 16384, 0, Red );
               if(ticket>0 && push(orders,ticket)) {
                  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                     DrawArrow("Sell",OrderOpenPrice(),SYMBOL_ARROWDOWN,Red,"Open Sell");
               } else {
                  Print("Error opening SELL order : ", printLastError());
                  return;
               }
           }
         }
         
         // check for open orders to close
         CheckOpenOrders();
       }
       
       
       void CheckOpenOrders(){
          //if (_debug)Print("Checking open orders");
            
            string Symb=Symbol();                        // Symbol
            //------------------------------------------------------------------------------- 2 --
            for(int i=0; i<OrdersTotal(); ++i) {
               // Cycle searching in orders
               if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
                  Print("Unable to select the next order to check: ", printLastError());
                  continue;
               }
               // If the next is available
               // Analysis of orders:
               
               if(OrderSymbol()!=Symb)
                  continue; // The order is not "ours"
                  
               int Type=OrderType();                   // Order type
               switch (Type){
                  case OP_BUY:
                  case OP_BUYLIMIT:
                  case OP_BUYSTOP:
                     //--- long position is opened //--- should it be closed?
                     if(stopLong()) {
                        //--- close order and exit
                        if(OrderClose(OrderTicket(),OrderLots(),Bid,3,Green)){
                           DrawArrow("Buy",OrderClosePrice(),SYMBOL_ARROWDOWN,Green,"Close Buy");
                           return;
                        } else {
                           Print("OrderClose error ",printLastError());
                        }
                     }
                     break;
                case OP_SELL:
                case OP_SELLLIMIT:
                case OP_SELLSTOP:
                     // short position is opened      
                     //--- we should close it?
                     if(stopShort()) {
                        //--- close order and exit
                        if(OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet)){
                           DrawArrow("Sell",OrderClosePrice(),SYMBOL_ARROWUP,Red,"Close Short");
                           return;
                        } else {
                           Print("OrderClose error ",printLastError());
                        }
                     }
                     break;
               }
               //--- update trailing stops
               trailingStop();
            } // for orders
       }
       
      void trailingStop(){
         //int Type=order.Type;
         int Type=OrderType();                   // Order type
         //--- modify order and exit
         
         double StopLoss=OrderStopLoss();             // SL of the selected order
         double SL=StopLoss; // stop loss
         
         double TakeProfit    =OrderTakeProfit();    // TP of the selected order
         double SP = TakeProfit; // stop profit
         double Price =OrderOpenPrice();     // Price of the selected order
         int    Ticket=OrderTicket();        // Ticket of the selected order
         
         
         // Modification cycle
         OrderDetails order = orderDetails();
         double TS= getTrailingStop(order.TrailingStop);
         double TP= getTrailingProfit(order.TrailingProfit);
         //Print("================================Trader: order.profit: ", TP, " TrailingStop: ", TS);
         //------------------------------------------------------------------- 4 --
         switch(Type) {
            case OP_BUY:
            case OP_BUYLIMIT:
            case OP_BUYSTOP:
            {
               double newSL = Bid-TS;
               if (StopLoss < newSL) {
                  SL=newSL;           // then modify it
                  if (!IsTesting()) Alert ("Modification Buy ",Ticket,". Awaiting response..");
              }
              double newTP = Bid+TP;
              if (TakeProfit < newTP) {
                  SP=newTP;           // then modify it
                  if (!IsTesting()) Alert ("Modification Buy ",Ticket,". Awaiting response..");
              }
               break;                        // Exit 'switch'
            }
            case OP_SELL:
            case OP_SELLLIMIT:
            case OP_SELLSTOP:
            {
               double newSL = Ask+TS;
               if (StopLoss > newSL) {
                  SL=newSL;           // then modify it
                  if (!IsTesting()) Alert ("Modification Sell ",Ticket,". Awaiting response..");
               }
               double newTP = Ask-TP;
               if (TakeProfit > newTP) {
                  SP=newTP;           // then modify it
                  if (!IsTesting()) Alert ("Modification Buy ",Ticket,". Awaiting response..");
               }
            }
            break;
         } // End of 'switch'
         //if (TakeProfit!=SP || StopLoss!=SL)
         //   return;
         if (SP==OrderTakeProfit() && SL==OrderStopLoss()) {
            // no changes
            return;
         }
         
         bool mod=false;
         int retry=0;
         while (!mod && retry++<3) {
               mod = OrderModify(Ticket,Price,SL,SP,0,clrYellow);
               //DrawArrow(Type==OP_SELL?"ModifySell":"ModifyBuy",Price,SYMBOL_CHECKSIGN,Yellow,Type==OP_SELL?"Sell":"Buy");
               /**
               string name = Type==OP_SELL?"ModifySell":"ModifyBuy";
               ObjectCreate(0,name,OBJ_CHART,0,TimeCurrent(),Price);
               ObjectSet(name,OBJPROP_COLOR,Yellow);
               ObjectSet(name,OBJPROP_STYLE,STYLE_SOLID);
               ObjectSetText(name, "Modify", 6);
               **/
                // Failed :(
               switch(GetLastError()) {
               // Overcomable errors
                  case 130:Alert("Wrong stops. Retrying.");
                     RefreshRates();               // Update data
                     continue;                     // At the next iteration
                  case 136:Alert("No prices. Waiting for a new tick..");
                     while(RefreshRates()==false)  // To the new tick
                        Sleep(1);                  // Cycle delay
                     continue;                     // At the next iteration
                  case 146:Alert("Trading subsystem is busy. Retrying ");
                     Sleep(500);                   // Simple solution
                     RefreshRates();               // Update data
                     continue;                     // At the next iteration
                     // Critical errors
                  case 2 : Alert("Common error.");
                     mod=true;
                     break;                        // Exit 'switch'
                  case 5 : Alert("Old version of the client terminal.");
                     mod=true;
                     break;                        // Exit 'switch'
                  case 64: Alert("Account is blocked.");
                     mod=true;
                     break;                        // Exit 'switch'
                  case 133:Alert("Trading is prohibited");
                     mod=true;
                     break;                        // Exit 'switch'
                  case 1: Alert("Unable to modify order with no changes");
                     mod=true;
                     break;
               }
         } // while
      };
      
       
       void CheckStoppedSignals(){
         string Symb=Symbol();                        // Symbol
        
         for(int i=0;i<ArraySize(orders); i++) {
               int order=orders[i];
               if (order!=-1){
               
  //        Print("============ looking fo order :", order);
                  for (int j=0; j<OrdersHistoryTotal();j++){
                     if (OrderSelect(j,SELECT_BY_POS,MODE_HISTORY)){
  //                   Print("=============Selecting order from history  : ", OrderTicket());
                        if (OrderTicket()==order){
                           closeSignal(order);
                           orders[i]=-1;
          
          
                        }
                     }
                  }
               }
            }
       }
       
       bool push(int &orders[], int value){
         for (int j=0; j<ArraySize(orders); j++){
            if (orders[j]==-1){
               orders[j]=value;
               return true;
            }
         }
         return false;
       }
       
       virtual void closeSignal(int ticket)=NULL;
      virtual OrderDetails orderDetails() = NULL; 
      virtual bool goLong()=NULL;
      virtual bool stopLong()=NULL;
      virtual bool goShort()=NULL;
      virtual bool stopShort()=NULL;
};
 
//+------------------------------------------------------------------+
