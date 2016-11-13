//+------------------------------------------------------------------+
//|                                               trend_detector.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//--- input parameters
input int      porogTrend=10;
input int      k=10000;
input int      desiredProfit=15;
input bool     borderPassAlert=true;
input bool     trendAlert=true;

bool canSendMessage=true;
bool isPriceHigher=false;
int h=0;
double priceForAlert=-1;
string note;

void init(){
  ChartSetInteger(0,CHART_EVENT_OBJECT_CREATE,1);
  h=TimeHour(TimeCurrent());
}

void OnTick(){
  //     setStopLossOnProfit();
  
   if(borderPassAlert)
   {
      borderPassAlert();
   }
   if(trendAlert)
   {
      trendAlert();
   }
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
//---
      if(id==CHARTEVENT_OBJECT_DRAG){
         priceForAlert=ObjectGetDouble(ObjectFind(0,sparam),sparam,OBJPROP_PRICE,0);
         note=ObjectGetString(0,sparam, OBJPROP_TEXT,0);
        string message=": New alert! Note: "+note;
             
         if((priceForAlert-Bid)>0){
            isPriceHigher=true;
         }else{
            isPriceHigher=false;
         }
            printf(message);
      }
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

void borderPassAlert(){

   if(isPriceHigher&&Bid>priceForAlert&&priceForAlert!=-1){
   
            string message=_Symbol+": " +note;
            Alert(message);
            SendNotification( message );
            priceForAlert=-1;
    }
    if(!isPriceHigher&&Bid<priceForAlert&&priceForAlert!=-1){
    
            string message=_Symbol+": " +note;
            Alert(message);
            SendNotification( message );
            priceForAlert=-1;
    }

}

void trendAlert(){

 int currentHour=TimeHour(TimeCurrent());
  if(currentHour!=h){
     h=currentHour;
     double lastPeriodHigh=iHigh(_Symbol,_Period,1);
     double lastPeriodLow=iLow(_Symbol,_Period,1);
     int lastHeight=(lastPeriodHigh-lastPeriodLow)*k;
   
     double beforeLastPeriodHigh=iHigh(_Symbol,_Period,2);
     double beforeLastPeriodLow=iLow(_Symbol,_Period,2);
     int beforeLastHeight=(beforeLastPeriodHigh-beforeLastPeriodLow)*k;
    
     if((beforeLastHeight<lastHeight )&& (lastHeight>porogTrend))
      {
         string message=_Symbol+": "+beforeLastHeight +", "+lastHeight;
         Alert(message);
         SendNotification( message );
       } 
  }  
}

 