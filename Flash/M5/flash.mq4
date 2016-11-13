
input int         FlashThreathhold=20;
input double      Lot=0.1;
input double profitPercent=0.9;

int j=0;     
void OnTick() 
  { 
  if(Month()==6&&Day()==24){
  return ;
 }
     // updateCounter(); 
      worker.onTick();
  } 
  
  
void updateCounter(){
     j=j+1;
     if(j==100){
            worker.PrintMe(j);    
     }   
     if(j>100){
         j=0;
     } 
}



 class Flash 
  { 
  
 public:
    
   Flash() {           
        init();
        printf("ManyNewsWorker, start working!");
       } 
 
 
  void PrintMe(string msg){
      printf(msg);
 }
 
 void onTick(){
 
      bool haveOpenOrdersLocal=haveOpenOrders();
      
      if(!haveOpenOrdersLocal&&delayCounterForSell!=-1){     
         moveDelayCounter();
      }
      
      if(haveOpenOrdersLocal){
         setStopLossOnZero();
         return;
      }
 
      double wasTrendValue=wasTrend();
      if(wasTrendValue!=0&&!haveOpenOrdersLocal&&!isDelayActive()){
         delayCounterForSell=0;
         if(wasTrendValue<0){         
               //--- buy 
               sendOrder(Ask,koef,MathAbs(wasTrendValue),false,99999);
 
         }else{          
               //--- sell 
               sendOrder(Bid,koef,MathAbs(wasTrendValue),true,99998); 
                              
         }
         
      }
      
   }
 
 private:
 
         int orderLifeTimeMinutes;
         int orderDeactivationPeriod;
         int koef;
         int delayCounterForSell;
         int currentBar;
         int delayCounterLimit;
         double profitLevel;

  void init(){
  
      delayCounterLimit=3;
      currentBar=iBars(NULL,PERIOD_M5);
      delayCounterForSell=0;
      koef=getKoef();
  }
  
  bool isDelayActive(){
      if(delayCounterForSell<delayCounterLimit){         
         return true;
      }else{
         delayCounterForSell=-1;
         return false;
      }
  
  }
  
  void moveDelayCounter(){
      int newBar=iBars(NULL,PERIOD_M5);

      if(currentBar!=newBar){
         currentBar=newBar;
         delayCounterForSell=delayCounterForSell+1;
      }
  }
  
  
  int getKoef(){
    int koef=1; 
    for (int i=1;i<Digits;i=i+1){
         koef=koef*10;
      }
      return koef;
  }
  
  double wasTrend(){
   
      double value=(iOpen(NULL,0,1)-iClose(NULL,0,1))*koef;//(iHigh(NULL,0,1)-iLow(NULL,0,1))*koef;
      
      if(MathAbs(value)>FlashThreathhold){
         return value;       
         
      }else{
         return 0;
      }
      
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
                     double NonLossLevel=MathAbs(0.8*(OrderTakeProfit()-OrderOpenPrice())*koef);
                     if(pips>=NonLossLevel){
                     
                           double SL    =OrderOpenPrice();    // SL of the selected order
                           double TP    =OrderTakeProfit();    // TP of the selected order
                           double Price =OrderOpenPrice();     // Price of the selected order
                           int    Ticket=OrderTicket();        // Ticket of the selected order         
                           bool Ans=OrderModify(Ticket,Price,SL,TP,0);//Modify it!  
                           printf("Order modified:"+Ans);
                     
                     }
                
                 }             
             }
       
         }
   }


 void sendOrder(double price, int koef,double profitValue, bool isSell,int MyMagicNumber ){
  
      
      double takeprofitFinal=0; 
      double stoplossFinal=0;
      int ticket=0;
      double spreadCorrection=getSpreadCorrection();
      if (isSell==true){
      
          takeprofitFinal=NormalizeDouble(price-(profitValue-spreadCorrection)*profitPercent/koef,Digits); 
          stoplossFinal=NormalizeDouble(price+(profitValue+spreadCorrection)/koef*2,Digits);
          ticket=OrderSend(Symbol(),OP_SELL,Lot,price,3,stoplossFinal,takeprofitFinal,"My order",MyMagicNumber,0,Red); 
         
      }else{
          takeprofitFinal=NormalizeDouble(price+(profitValue+spreadCorrection)*profitPercent/koef,Digits); 
          stoplossFinal=NormalizeDouble(price-(profitValue-spreadCorrection)/koef*2,Digits);
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
  
  double getSpreadCorrection(){
   
   const double avgRealSpread=2.0;
   double testerSpread=NormalizeDouble(MathAbs(Ask-Bid),Digits)*koef;
   
   if(testerSpread>avgRealSpread){   
      return testerSpread-avgRealSpread;
   }else{
      return 0;
   }
  }  
};

Flash worker; 
