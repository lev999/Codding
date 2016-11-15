
input int         FlashThreshold=16;
input double      LossToBodyRate=2.4;
input double      ProfitToBodyRate=0.8;
input double      MinusNonLossRate=0.9;
input double      PlusNonLossRate=1.0;
input double      HeightToBodyRate=0.4;
input double      AvgLossValueInDollars=20;
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
        printf("Flash, start working!");
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
         if(wasTrendValue>0){         
               //--- buy 
               sendOrder(Ask,MathAbs(wasTrendValue),true,99999);
 
         }else{          
               //--- sell 
               sendOrder(Bid,MathAbs(wasTrendValue),false,99998);                               
         }
         
      }
      
   }
 
 private:
 
         int orderLifeTimeMinutes;
         int orderDeactivationPeriod;
         int KOEF;
         int delayCounterForSell;
         int currentBar;
         int delayCounterLimit;
         double profitLevel;

  void init(){
  
      delayCounterLimit=3;
      currentBar=iBars(NULL,PERIOD_M5);
      delayCounterForSell=0;
      KOEF=getKoef();
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
    int koefLocal=1; 
    for (int i=1;i<Digits;i=i+1){
         koefLocal=koefLocal*10;
      }
      return koefLocal;
  }
  
  double wasTrend(){
   
     double body=(iClose(NULL,0,1)-iOpen(NULL,0,1))*KOEF;
     double fullHeight=(iHigh(NULL,0,1)-iLow(NULL,0,1))*KOEF;
      
      if(MathAbs(fullHeight)>FlashThreshold&&MathAbs(body)>=MathAbs(fullHeight)*HeightToBodyRate){
        if(body<0){
 			   return -(iHigh(NULL,0,1)-iClose(NULL,0,1))*KOEF; 
 	   	} 
		   else{
		      return (iClose(NULL,0,1)-iLow(NULL,0,1))*KOEF;
			}      
            
	       
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
                 double profit=OrderProfit();
                 
                 double NonLossLevel=MathAbs(PlusNonLossRate*(OrderTakeProfit()-OrderOpenPrice())*KOEF);
                 
                if(profit>0&&OrderOpenPrice()!=OrderStopLoss()){
                     
                     double pips=profit/OrderLots()/10;
                     if(pips>=NonLossLevel){
                     
                           double SL    =OrderOpenPrice();    // SL of the selected order
                           double TP    =OrderTakeProfit();    // TP of the selected order
                           double Price =OrderOpenPrice();     // Price of the selected order
                           int    Ticket=OrderTicket();        // Ticket of the selected order         
                           bool res=OrderModify(Ticket,Price,SL,TP,0);//Modify it!                            
                           if(!res){
                              if(GetLastError()!=1){
                                  Print("Error in OrderModify. Error code=",GetLastError()); 
                              }                              
                           }                                 
                           else {
                              Print("Order modified successfully."); 
                           }                 
                     }
                
                 }else{
                     NonLossLevel=MathAbs(MinusNonLossRate*(OrderStopLoss()-OrderOpenPrice())*KOEF);
                     if(profit<0&&MathAbs(profit)>=NonLossLevel){
                            SL    =OrderStopLoss();    // SL of the selected order
                            TP    =OrderOpenPrice();    // TP of the selected order
                            Price =OrderOpenPrice();     // Price of the selected order
                            Ticket=OrderTicket();        // Ticket of the selected order         
                            res=OrderModify(Ticket,Price,SL,TP,0);//Modify it!  
                            
                           if(!res){
                              if(GetLastError()!=1){
                                  Print("Error in OrderModify. Error code=",GetLastError()); 
                              }                              
                           }                                 
                           else {
                              Print("Order modified successfully."); 
                           }
                                 
                             
                    
                     }
                     
                 }             
             }
       
         }
   }

 double getLot(double stopLossValue, double openPrice){
   double pips=MathAbs(stopLossValue-openPrice)*KOEF;
   double lot=NormalizeDouble(AvgLossValueInDollars/(10*pips), 2);
   if(lot<0.01){
      return 0;
   }else{
      return lot;
   }   
 }

 void sendOrder(double price,double profitValue, bool isBuy,int MyMagicNumber ){
 
      double takeprofitFinal=0; 
      double stoplossFinal=0;
      int ticket=0;
      double volume=0;
      double spreadCorrection=getSpreadCorrection();
      
      if (isBuy==true){
            takeprofitFinal=NormalizeDouble(price+(profitValue+spreadCorrection)*ProfitToBodyRate/KOEF,Digits); 
            stoplossFinal=NormalizeDouble(price-(profitValue-spreadCorrection)/KOEF*LossToBodyRate,Digits);
            volume=getLot(stoplossFinal,price);
            ticket=OrderSend(Symbol(),OP_BUY,volume,price,3,stoplossFinal,takeprofitFinal,"My order",MyMagicNumber,0,Blue);//,clrNONE);      
       }else{
            takeprofitFinal=NormalizeDouble(price-(profitValue-spreadCorrection)*ProfitToBodyRate/KOEF,Digits); 
            stoplossFinal=NormalizeDouble(price+(profitValue+spreadCorrection)/KOEF*LossToBodyRate,Digits);
            volume=getLot(stoplossFinal,price);
            ticket=OrderSend(Symbol(),OP_SELL,volume,price,3,stoplossFinal,takeprofitFinal,"My order",MyMagicNumber,0,Red); 
      }
      if(ticket<0) 
      { 
         Print("Order open failed with error #",GetLastError(),", profit:",takeprofitFinal,", loss:",stoplossFinal,", Lot:"+volume); 
      } 
      else 
      {
         Print("OrderSend placed successfully"); 
      }     
  } 
  
  double getSpreadCorrection(){
   
   const double avgRealSpread=2.0;
   double testerSpread=NormalizeDouble(MathAbs(Ask-Bid),Digits)*KOEF;
   
   if(testerSpread>avgRealSpread){   
      return testerSpread-avgRealSpread;
   }else{
      return 0;
   }
  }  
};

Flash worker; 
