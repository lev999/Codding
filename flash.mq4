
input int         FlashThreshold=16;
input double      LossToTrendRate=1.9;
input double      ProfitToTrendRate=0.8;
input double      MinusNonLossRate=0.9;
input double      PlusNonLossRate=1;
input double      BodyToHeightRate=0.5;
input double      MaxLossDollar=50;
input double      OrderLifeTime=257;


const int         delayCounterLimit=3;
const int         heartRatePeriod=100;

    
void OnTick() 
  { 
     // worker.heartRate(); 
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
      }
      
     if(haveOpenedOrdersLocal){
        checkLifeTime();
     }else{
        lifeTimeCounter=0;
     }
 
      double trendValue=getTrendValue();
      if(trendValue!=0&&!haveOpenedOrdersLocal&&!isDelayActive()){
         delayCounterForSell=0;
         sendOrder(trendValue);
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
      
      if(lifeTimeCounter>OrderLifeTime){
         printf("Closing orders by life Time limit");
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
      
      if(MathAbs(fullHeight)>FlashThreshold&&MathAbs(body/fullHeight)>=BodyToHeightRate){
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
            closeOrder();
         }else{
            runFlag=false;
         }         
      }            
  }
  
  void closeOrder(){
  
   if(OrderType()==OP_BUY){
      int ticket=OrderClose(OrderTicket(),OrderLots(),Bid,100,Red);
   }else{
      ticket=OrderClose(OrderTicket(),OrderLots(),Ask,100,Red);
   }
     
   if(ticket<0) 
   { 
      Print("Order close failed with error #",GetLastError());          
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
      double profitDollar=0;
      double nonLossLevelPips=0;
      double pips=0;
      for(int i=0;i<=OrdersTotal();i++) 
       {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
            profitDollar=OrderProfit(); 
            if(profitDollar>0&&OrderOpenPrice()!=OrderStopLoss()){ 
               nonLossLevelPips=MathAbs(PlusNonLossRate*(OrderTakeProfit()-OrderOpenPrice())*KOEF);                    
               pips=profitDollar/OrderLots()/10;
               if(pips>=nonLossLevelPips){
                  double SL = OrderOpenPrice();
                  double TP = OrderTakeProfit();
                  modifyOrder(TP,SL);       
               }                
            }else{
               nonLossLevelPips=MathAbs(MinusNonLossRate*(OrderStopLoss()-OrderOpenPrice())*KOEF);
               pips=-profitDollar/OrderLots()/10;
               if(profitDollar<0&&pips>=nonLossLevelPips){
                   SL = OrderStopLoss();
                   TP = OrderOpenPrice(); 
                   modifyOrder(TP,SL);
               }               
            }             
          }       
        }
   }


 void modifyOrder( double TP, double SL){  
 
      double Price =OrderOpenPrice();
      int    Ticket=OrderTicket();          
      bool res=OrderModify(Ticket,Price,SL,TP,0);                           
      if(!res){
         if(GetLastError()!=1){
             Print("Error in OrderModify. Error code=",GetLastError()); 
         }                              
      }                                 
      else {
         Print("Order modified successfully."); 
      }          
 }

 double getLot(double stopLossValue,double trendValue ){
   double openPrice=0;
   if(trendValue>0){
      openPrice=Ask;
   }else{
      openPrice=Bid;
   }
   
   double pips=MathAbs(stopLossValue-openPrice)*KOEF;
   double lot=NormalizeDouble(MaxLossDollar/(10*pips), 2);
   
   if(lot<0.01){
      return 0;
   }else{
      return lot;
   }   
 }

 double getTP(double trendValue){
   if(trendValue>0){
      return   NormalizeDouble(Bid+MathAbs(trendValue)*ProfitToTrendRate/KOEF,Digits);        
   }else{
      double  spreadCorrection=getSpreadCorrection();
      return  NormalizeDouble(Bid-(MathAbs(trendValue)+spreadCorrection)*ProfitToTrendRate/KOEF,Digits);    
   }
 }

 double getSL(double trendValue){
   if(trendValue>0){
      return  NormalizeDouble(Bid-MathAbs(trendValue)/KOEF*LossToTrendRate,Digits);     
   }else{
      double  spreadCorrection=getSpreadCorrection();
      return  NormalizeDouble(Bid+(MathAbs(trendValue)+spreadCorrection)/KOEF*LossToTrendRate,Digits);     
   }
 }

 void sendOrder(double trendValue){
      int ticket=0;
 
      double    tp=getTP(trendValue);
      double    sl=getSL(trendValue);
      double    volume=getLot(sl,trendValue);
      if (trendValue>0){ //buy       
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
