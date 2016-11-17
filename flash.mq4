
input int         FlashThreshold=16;
input double      LossToBodyRate=2.4;
input double      ProfitToBodyRate=0.8;
input double      MinusNonLossRate=0.9;
input double      PlusNonLossRate=1.0;
input double      HeightToBodyRate=0.4;
input double      AvgLossValueInDollars=20;
input double      OrderLifeTimeInUnits=20;

const int         delayCounterLimit=3;
const int         heartRatePeriod=100;

    
void OnTick() 
  { 
      worker.heartRate(); 
      worker.onTick();
  } 
  
class Flash 
  { 
  
 public:
    
   Flash() {        
        printf("Flash, start working!");
        init();
       } 
 
 
 
 void onTick(){
 
      bool haveOpenedOrdersLocal=haveOpenedOrders();
      
      if(!haveOpenedOrdersLocal&&delayCounterForSell!=-1){     
         moveDelayCounter();
      }
      
      if(haveOpenedOrdersLocal){
         setStopLossOnZero();
         return;
      }
      
 //     if(haveOpenedOrdersLocal){
 //        checkLifeTime();
 //        return;
 //     }
 
      double trendValue=getTrendValue();
      if(trendValue!=0&&!haveOpenedOrdersLocal&&!isDelayActive()){
         delayCounterForSell=0;
         if(trendValue>0){
            sendOrder(true,trendValue); //--- buy
         }else{ 
            sendOrder(false,trendValue); //--- sell                               
         }         
      }
      
   }
   
 void heartRate(){
     heartRateCounter=heartRateCounter+1;
     if(heartRateCounter==heartRatePeriod){
           printf("still alive..."); 
           return;   
     }   
     if(heartRateCounter>heartRatePeriod){
         heartRateCounter=0;
         return;
     } 
 }
 private:
 
         int heartRateCounter;         
         int orderLifeTimeMinutes;
         int orderDeactivationPeriod;
         int KOEF;
         int delayCounterForSell;
         int delayBarCounter;         
         double profitLevel;
         int lifeTimeCursor;
         int lifeTimeCounter;
         

  void init(){
      heartRateCounter=0;
      KOEF=getKoef();
      
      delayBarCounter=iBars(NULL,PERIOD_M5);      
      delayCounterForSell=0;       
          
      lifeTimeCursor=iBars(NULL,PERIOD_M5);
      lifeTimeCounter=0;
  }
  
  void checkLifeTime(){
    int newBar=iBars(NULL,PERIOD_M5);

      if(lifeTimeCursor!=newBar){
         lifeTimeCursor=newBar;
         lifeTimeCounter=lifeTimeCounter+1;
      }
      
      if(lifeTimeCounter>delayCounterLimit){
         closeAllOrders();
         lifeTimeCounter=0;
      }  
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
      if(delayBarCounter!=newBar){
         delayBarCounter=newBar;
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
  
  double getTrendValue(){   
     double body=(iClose(NULL,0,1)-iOpen(NULL,0,1))*KOEF;
     double fullHeight=(iHigh(NULL,0,1)-iLow(NULL,0,1))*KOEF;
      
      if(MathAbs(fullHeight)>FlashThreshold&&MathAbs(body)>=MathAbs(fullHeight)*HeightToBodyRate){
        if(body<0){
 			   return -(iHigh(NULL,0,1)-iClose(NULL,0,1))*KOEF; 
 	   	}else{
		      return (iClose(NULL,0,1)-iLow(NULL,0,1))*KOEF;
			}   
      }else{
         return 0;
      }      
  }
 
  void closeAllOrders(){
      bool runFlag=true;
      while(runFlag){
        if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)){
            tryToCloseOrder();
         }else{
            runFlag=false;
         }         
      }            
  }
  
  void tryToCloseOrder(){
      int ticket=OrderClose(OrderTicket(),OrderLots(),Ask,100,Red);
      if(ticket<0) 
      { 
         Print("Order close try1 failed with error #",GetLastError()); 
         ticket=OrderClose(OrderTicket(),OrderLots(),Bid,100,Red);
         if(ticket<0){
          Print("Order close try2 failed with error #",GetLastError()); 
         }
      }else{
         Print("Order closed successfully"); 
      }
  }
  
   bool haveOpenedOrders(){
      if(OrdersTotal()>0){
         return true;
      }else{
         return false;
      }
  }
 void setStopLossOnZero(){
      double profit=0;
      double nonLossLevel=0;
      for(int i=0;i<=OrdersTotal();i++) 
       {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
            profit=OrderProfit(); 
            if(profit>0&&OrderOpenPrice()!=OrderStopLoss()){ 
               nonLossLevel=MathAbs(PlusNonLossRate*(OrderTakeProfit()-OrderOpenPrice())*KOEF);                    
               double pips=profit/OrderLots()/10;
               if(pips>=nonLossLevel){
                  modifyOrder();       
               }                
            }else{
               nonLossLevel=MathAbs(MinusNonLossRate*(OrderStopLoss()-OrderOpenPrice())*KOEF);
               if(profit<0&&MathAbs(profit)>=nonLossLevel){
                  modifyOrder();
               }               
            }             
          }       
        }
   }


 void modifyOrder(){      
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

 double getLot(double stopLossValue,bool isBuy ){
   double openPrice=0;
   if(isBuy){
      openPrice=Ask;
   }else{
      openPrice=Bid;
   }
   
   double pips=MathAbs(stopLossValue-openPrice)*KOEF;
   double lot=NormalizeDouble(AvgLossValueInDollars/(10*pips), 2);
   
   if(lot<0.01){
      return 0;
   }else{
      return lot;
   }   
 }

 double getTP(bool isBuy,double trendValue){
   if(isBuy){
      return   NormalizeDouble(Bid+(trendValue)*ProfitToBodyRate/KOEF,Digits);        
   }else{
      double  spreadCorrection=getSpreadCorrection();
      return  NormalizeDouble(Bid-(trendValue+spreadCorrection)*ProfitToBodyRate/KOEF,Digits);    
   }
 }

 double getSL(bool isBuy,double trendValue){
   if(isBuy){
      return  NormalizeDouble(Bid-(trendValue)/KOEF*LossToBodyRate,Digits);     
   }else{
      double  spreadCorrection=getSpreadCorrection();
      return  NormalizeDouble(Bid+(trendValue+spreadCorrection)/KOEF*LossToBodyRate,Digits);     
   }
 }

 void sendOrder(bool isBuy,double trendValue){
      int ticket=0;
 
      double    tp=getTP(isBuy,trendValue);
      double    sl=getSL(isBuy,trendValue);
      double    volume=getLot(sl,isBuy);
      if (isBuy==true){        
            ticket=OrderSend(Symbol(),OP_BUY,volume,Ask,3,sl,tp,"My order",99999,0,Blue);//,clrNONE);      
       }else{//sell
            ticket=OrderSend(Symbol(),OP_SELL,volume,Bid,3,sl,tp,"My order",99998,0,Red); 
      }
      printResult(ticket,tp,sl,volume);
  } 
  
  double getSpreadCorrection(){
         // ? need to fix!
         const double avgRealSpread=2.0;
         double testerSpread=NormalizeDouble(MathAbs(Ask-Bid),Digits)*KOEF;      
         return testerSpread-avgRealSpread;
        
      
  } 
  
   void printResult(int ticket,double tp, double sl,double volume){      
        if(ticket<0) 
      { 
         Print("Order open failed with error #",GetLastError(),", profit:",tp,", loss:",sl,", Lot:"+volume); 
      } 
      else 
      {
         Print("OrderSend placed successfully"); 
      }     

  }
 
};

Flash worker; 
