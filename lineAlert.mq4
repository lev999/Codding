//+------------------------------------------------------------------+
//|                                                    lineAlert.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//--- input parameters
input int      desiredProfit=15;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  ChartSetInteger(0,CHART_EVENT_OBJECT_CREATE,1);
//---
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      setStopLossOnProfit();
      // int Error=GetLastError();
      // Alert("Error:"+Error);
  
  
      
   }

void setStopLossOnProfit(){
          if(OrderSelect(OrdersTotal()-1,SELECT_BY_POS,MODE_TRADES)){
               if(OrderProfit()>=desiredProfit&&OrderOpenPrice()!=OrderStopLoss()){
                  double SL    =OrderOpenPrice();    // SL of the selected order
                  double TP    =OrderTakeProfit();    // TP of the selected order
                  double Price =OrderOpenPrice();     // Price of the selected order
                  int    Ticket=OrderTicket();        // Ticket of the selected order         
                  bool Ans=OrderModify(Ticket,Price,SL,TP,0);//Modify it!  
                  printf("Order modified:"+Ans);
                  Alert("Stop Loss changed!");
               }
          }
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
