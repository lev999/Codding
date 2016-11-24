
input int         Threshold=10;
input double      BodyToHeightRate=0.0;
input double      MinTrendToAvgCandle=1.6;
input double      LossToTrendRate=0.6;
input double      ProfitToTrendRate=0.9;
input double      NonLossMinusRate=10.0;
input double      NonLossPlusRate=0.8;
input double      OrderLifeTimeLimit=2;

input double      MaxLossDollar=50;



const int         delayCounterLimit=0;
const int         heartRatePeriod=100;


double OnTester()
{
   if (TesterStatistics(STAT_EQUITY_DD)>0){  
      return  NormalizeDouble(TesterStatistics(STAT_PROFIT) / TesterStatistics(STAT_EQUITY_DD),2);
   }else{
      return 0;
   }
}
    
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
 
      bool haveOpenedOrders=(OrdersTotal()>0);
      
      if(isNewBar()){
      
         if(!haveOpenedOrders){     
           updateDelayStatus();
         }
         
         double trendValue=getTrendValue();
         if(trendValue!=0&&!haveOpenedOrders&&!isDelayActive()){
            activateDelay();
            sendOrder(trendValue);
         }
         
         if(haveOpenedOrders)checkOrderLifeTimeLimit();
         else lifeTimeCounter=0;
                  
         return;
      }
 
       if(haveOpenedOrders){
         setStopLossOnZero();
      }    
   }
   

 private:
        
         int KOEF;
         int delayCounter;      
         int lifeTimeCounter;
         int currentBar;

  void init(){
      currentBar=iBars(NULL,PERIOD_H1);      
      KOEF=getKoef();
          
      delayCounter=-1;
      lifeTimeCounter=0;
  }
  
  void checkOrderLifeTimeLimit(){
      lifeTimeCounter=lifeTimeCounter+1;
      printf("Order life time: "+lifeTimeCounter+" ("+OrderLifeTimeLimit+")");      
      if(lifeTimeCounter>OrderLifeTimeLimit){
        printf("Order life time is over --> NonLoss");
        setNonLoss();        
        lifeTimeCounter=0;
      }
        
  }
  
  
  bool isNewBar(){
      int bar=iBars(NULL,PERIOD_H1);
      if(currentBar!=bar){
         currentBar=bar;
         return true;
      }else{
         return false;
      }
  }
  
  void setNonLoss(){
     if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)){
        if(OrderProfit()>0){
            double SL = OrderOpenPrice();
            double TP = OrderTakeProfit();
            modifyOrder(TP,SL);
        }else{
            SL = OrderStopLoss();
            TP = OrderOpenPrice(); 
            modifyOrder(TP,SL);
        }
         
     }                 

  }
  
  void updateDelayStatus(){
      
      if(delayCounter!=-1){
         if(delayCounter<delayCounterLimit){
            delayCounter=delayCounter+1;
            printf("update trading delay: "+delayCounter+" ("+delayCounterLimit+")");
         }else{
            delayCounter=-1;
            printf("trading activated");
         }         
      }
  }
  
  void activateDelay(){
      delayCounter=0;
  }
  
  bool isDelayActive(){
      if(delayCounter!=-1){ 
         printf("Trading is diabled because of delay "+delayCounter+" ("+delayCounterLimit+")");        
         return true;
      }else{
         return false;
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
      double height=(iHigh(NULL,0,1)-iLow(NULL,0,1))*KOEF;
      
      printf("last: body/height: "+ MathAbs(NormalizeDouble(body/height,2))+", height: "+height+" ("+Threshold+")");
      wasFlatBefore(height,true);//just for printing
      
      if(height>=Threshold){
          if(wasFlatBefore(height,false)&&MathAbs(body/height)>=BodyToHeightRate){
               
               if(body<0){
       			   return -(iHigh(NULL,0,1)-iClose(NULL,0,1))*KOEF; 
       	   	}else{
      		      return (iClose(NULL,0,1)-iLow(NULL,0,1))*KOEF;
      			}   
            }else{ 
               return 0;
            }      
         }
     
  }
  
  bool wasFlatBefore(double trendCandle, bool doPrints){
     double avgCandle=0;
     int maxCandleHistory=3;
     
     for(int i=2;i<=maxCandleHistory+1;i++){
           avgCandle+=(iHigh(NULL,0,i)-iLow(NULL,0,i))*KOEF/(maxCandleHistory-1);
    }

     if(doPrints)   printf("trend/avg: "+NormalizeDouble(trendCandle/avgCandle,2)+" ("+NormalizeDouble(MinTrendToAvgCandle,2)+")");
     if((trendCandle/avgCandle)>=MinTrendToAvgCandle){
         if(doPrints)  printf("Trend detected!");
         return true;
     }else{
         return false;
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
  

 void setStopLossOnZero(){
      double profitDollar=0;
      double nonLossLevelPips=0;
      double pips=0;
      for(int i=0;i<=OrdersTotal();i++) 
       {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
            profitDollar=OrderProfit(); 
            if(profitDollar>0&&OrderOpenPrice()!=OrderStopLoss()){ 
               nonLossLevelPips=MathAbs(NonLossPlusRate*(OrderTakeProfit()-OrderOpenPrice())*KOEF);                    
               pips=profitDollar/OrderLots()/10;
               if(pips>=nonLossLevelPips){
                  double SL = OrderOpenPrice();
                  double TP = OrderTakeProfit();
                  modifyOrder(TP,SL);       
               }                
            }else{
               nonLossLevelPips=MathAbs(NonLossMinusRate*(OrderStopLoss()-OrderOpenPrice())*KOEF);
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
