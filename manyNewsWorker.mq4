//+------------------------------------------------------------------+ 
//|                                                   TestExpert.mq5 | 
//|                        Copyright 2009, MetaQuotes Software Corp. | 
//|                                              https://www.mql5.com | 
//+------------------------------------------------------------------+ 
#property copyright "2009, MetaQuotes Software Corp." 
#property link      "https://www.mql5.com" 
#property version   "1.00" 

input int         TakeProfit=200;
input int         StopLoss=10;
input double      Lot=0.15;
input int         orderLifeTimeMinutes=-10;

input datetime  NewsTime_1;
input datetime  NewsTime_2;
input datetime  NewsTime_3;

int j=0;     
void OnTick() 
  { 
      updateCounter(); 
      worker.onTick();
        
     
  } 
  

class ManyNewsWorker 
  { 
  
public:
    
   ManyNewsWorker() {           
        init();
        printf("Constructor, done!");
       } 
 
 
 void onTick(){
 
     if(haveOpenOrders()){
         setStopLossOnZero();
         closeOrdersByLifeTime();
     }
     else{
 
        if(NewsArrayIndex>=arraySize){return;}
        int newsHour=NewsTimeArrayHours[NewsArrayIndex];
        int newsMinute=NewsTimeArrayMinutes[NewsArrayIndex];
       
        if(isTimeToAct(newsHour,newsMinute) && !NewsWasOrderClosedByTimeFlag[NewsArrayIndex])
          {
             int koef=1; 
             for (int i=1;i<Digits;i=i+1){
                  koef=koef*10;
               }
               printSpread();
               //--- buy 
               sendOrder(Ask,koef,false,99999);
               //--- sell 
               sendOrder(Bid,koef,true,99998);
                
               printf("finished working for News "+NewsTimeArrayHours[NewsArrayIndex]+":"+NewsTimeArrayMinutes[NewsArrayIndex]);
               moveNewsArrayIndex();
          } 
     }    
     
 }
   void printSpread(){
  
   double spread=NormalizeDouble(MathAbs(Ask-Bid),Digits);
   printf("spread:"+spread);
  }
  void PrintMe(string msg){
      printf(msg);
 }
   ~ManyNewsWorker() { Print("CTestClass destructor"); } 
  
 private:
         int         NewsArrayIndex;
         int         NewsTimeArrayHours[3];
         int         NewsTimeArrayMinutes[3];
         bool        NewsWasOrderClosedByTimeFlag[3];
         double      TakeProfitInput;
         double      StopLossInput;
         int arraySize;
         
        void init(){
            arraySize = sizeof(NewsTimeArrayHours) / sizeof(int);
            TakeProfitInput=TakeProfit;
            StopLossInput=StopLoss;
            NewsArrayIndex=0;
            NewsTimeArrayHours[0]=TimeHour(NewsTime_1);
            NewsTimeArrayHours[1]=TimeHour(NewsTime_2);
            NewsTimeArrayHours[2]=TimeHour(NewsTime_3);
            
            NewsTimeArrayMinutes[0]=TimeMinute(NewsTime_1);
            NewsTimeArrayMinutes[1]=TimeMinute(NewsTime_2);
            NewsTimeArrayMinutes[2]=TimeMinute(NewsTime_3);
            
            
            NewsWasOrderClosedByTimeFlag[0]=false;
            NewsWasOrderClosedByTimeFlag[1]=false;
            NewsWasOrderClosedByTimeFlag[2]=false;
            
            checkEmptyNews();
            string msg="News Time set to : ";
            msg=msg+NewsTimeArrayHours[0]+":"+NewsTimeArrayMinutes[0]+", ";
            msg=msg+NewsTimeArrayHours[1]+":"+NewsTimeArrayMinutes[1]+", ";
            msg=msg+NewsTimeArrayHours[2]+":"+NewsTimeArrayMinutes[2];
            printf(msg);
       
    }
   
    void checkEmptyNews(){
      for(int i=0;i<3;i++){
         if(NewsTimeArrayHours[i]==0&&NewsTimeArrayMinutes[i]==0){
            NewsWasOrderClosedByTimeFlag[i]=true;
         }
      }
    
    }
 
 void moveNewsArrayIndex(){
     if(NewsArrayIndex<arraySize){
             
         NewsArrayIndex=NewsArrayIndex+1;
         if(NewsArrayIndex==arraySize){
             printf("Expert to exit");        
            return;
         }
         printf("Next News "+NewsTimeArrayHours[NewsArrayIndex]+":"+NewsTimeArrayMinutes[NewsArrayIndex]);
     }
  }
       
  bool isTimeToAct(int newsHour,int newsMinute){
     int currentHour=TimeHour(TimeCurrent());
     int currentMinute=TimeMinute(TimeCurrent());
     
         if(newsHour>currentHour){
            return false;
         }
         if(newsHour<currentHour){
            return true;
         }
         if(newsHour==currentHour){
            if(newsMinute<=currentMinute){
               return true;
            }else{
               return false;
            }
         }
         
  }
  
  
  void closeOrdersByLifeTime(){
  
     int activeNewsMin=NewsTimeArrayMinutes[NewsArrayIndex-1];
     int activeNewsHour=NewsTimeArrayHours[NewsArrayIndex-1];
     bool activeNewsFlag=NewsWasOrderClosedByTimeFlag[NewsArrayIndex-1];
     datetime currentMinutes = TimeMinute(TimeCurrent());     
            
      if(( isTimeToActWithSlipInterval(activeNewsHour,activeNewsMin))&& !activeNewsFlag){
         NewsWasOrderClosedByTimeFlag[NewsArrayIndex-1]=true;
         
         if(!wasTrend()){
           closeAllOrders();
           printf("Closed orders of News "+activeNewsHour+":"+activeNewsMin);
   
         }else{
            string message="Detected trend by news at time:"+activeNewsHour+":"+activeNewsMin;
            SendNotification(message);
            printf(message);
         }
     } 
  }
  
  bool isTimeToActWithSlipInterval(int activeNewsHour,int activeNewsMin){
  
     if(orderLifeTimeMinutes<0){
         return false;
     }
    
     int slipMin=activeNewsMin+orderLifeTimeMinutes;
     if(slipMin>=60){
         slipMin=slipMin-60;
         activeNewsHour=activeNewsHour+1;
     }
     return isTimeToAct(activeNewsHour,slipMin);
     
  }
  
  
  void closeAllOrders(){
  int i=1;
       while(i<=2){
           i=i+1;
           if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)){
            int ticket=OrderClose(OrderTicket(),OrderLots(),Ask,100,Red);
                if(ticket<0) 
               { 
                  Print("Order close try1 failed with error #",GetLastError()); 
                  ticket=OrderClose(OrderTicket(),OrderLots(),Bid,100,Red);
                  if(ticket<0){
                   Print("Order close try2 failed with error #",GetLastError()); 
                  }
 
               } 
               else 
               {
                  Print("Order closed successfully"); 
               }
            }
            
       }
         
  }
  
  bool wasTrend()
   {
      for(int i=0;i<=OrdersTotal();i++) 
       {
           if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
                   
                 if(OrderProfit()>0){
                     double profit=OrderProfit();
                     double pips=profit/Lot/10;
                     if(pips>=StopLoss*2){
                        return true;                                                                                 
                     }
                
                 }             
             }
       
         }
    return false;
   }

  bool haveOpenOrders(){
  
     if(OrdersTotal()>0){
         return true;
     }else{
         return false;
     }
  }
  
  void setStopLossOnZero(){
  
      for(int i=0;i<=OrdersTotal();i++) 
       {
           if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
                   
                 if(OrderProfit()>0&&OrderOpenPrice()!=OrderStopLoss()){
                     double profit=OrderProfit();
                     double pips=profit/Lot/10;
                     if(pips>=StopLoss){
                     
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
       
         }
   }

  
 void sendOrder(double price, int koef, bool isSell,int MyMagicNumber ){
  
      double takeprofitFinal=0; 
      double stoplossFinal=0;
      int ticket=0;
      double spread=NormalizeDouble(MathAbs(Ask-Bid),Digits);
       
      if (isSell==true){
      
          takeprofitFinal=NormalizeDouble(price-TakeProfitInput/koef,Digits)-spread; 
          stoplossFinal=NormalizeDouble(price+StopLossInput/koef,Digits);

          ticket=OrderSend(Symbol(),OP_SELL,Lot,price,3,stoplossFinal,takeprofitFinal,"My order",MyMagicNumber,0,Red); 
      }else{
          takeprofitFinal=NormalizeDouble(price+TakeProfitInput/koef,Digits)+spread; 
          stoplossFinal=NormalizeDouble(price-StopLossInput/koef,Digits);

         ticket=OrderSend(Symbol(),OP_BUY,Lot,price,3,stoplossFinal,takeprofitFinal,"My order",MyMagicNumber,0,Blue);//,clrNONE);      
      }
      if(ticket<0) 
      { 
         Print("OrderSend failed with error #",GetLastError()); 
      } 
      else 
      {
         Print("OrderSend placed successfully"); 
      }
     
  }   

}; 
  
  
  
ManyNewsWorker worker; 

void updateCounter(){
     j=j+1;
     if(j==100){
            worker.PrintMe(j);    
     }   
     if(j>100){
         j=0;
     } 
}

  
