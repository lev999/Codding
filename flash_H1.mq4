
input int         Threshold=10;
input double      TrendBodyToPrevRate=2;
input double      LossToTrendRate=0.3;
input double      ProfitToTrendRate=0.6;
input double      NonLossMinusRate=1;
input double      NonLossPlusRate=1;
input double      OrderLifeTimeLimit=20;
input double      MaxLossDollar=50;
input int         MaxCandleHistory=5;



const int         delayCounterLimit=1;


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
         
         double trendValue=getTrend();
         if(trendValue!=0&&!haveOpenedOrders&&!isDelayActive()){
            activateDelay();
            sendOrder(trendValue);
         }
         
         if(haveOpenedOrders)checkOrderLifeTimeLimit();
         else lifeTimeCounter=0;
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
      if(lifeTimeCounter>=OrderLifeTimeLimit){
        printf("Order life time is over --> NonLoss or close");
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
            closeAllOrders();
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
  
 
  bool isGap(){
   double spreadPips=getSpread();

   bool result=MathAbs(NormalizeDouble(iClose(NULL,0,1)-iOpen(NULL,0,0),Digits))>getSpread()*2;
   if(result)printf("was Gap!");   
   return result;
  }
  
  double getSpread(){
      return NormalizeDouble(MathAbs(Ask-Bid),Digits);
  }
  
  
  double getTrend(){
  
      if(isGap())return 0;
      
      double trendHeight=(iHigh(NULL,0,1)-iLow(NULL,0,1))*KOEF; 
      if(trendHeight<Threshold)return 0;
      
      double historyLevelMax=0;
      double historyLevelMin=100;
      double historyBodyPipsMax=0;
     
      for(int i=2;i<=MaxCandleHistory+1;i++){
         double max=iHigh(NULL,0,i);
         double min=iLow(NULL,0,i);
         double body=MathAbs(iClose(NULL,0,i)-iOpen(NULL,0,i))*KOEF;
         
         if(max>historyLevelMax)historyLevelMax=max;
         if(min<historyLevelMin)historyLevelMin=min;
         if(body>historyBodyPipsMax)historyBodyPipsMax=body;                    
      }
      
      
      double trendCandleBody=(iClose(NULL,0,1)-iOpen(NULL,0,1))*KOEF;       
      double trendToMaxBody=MathAbs(NormalizeDouble(trendCandleBody/historyBodyPipsMax,2));
      printf("trendToMaxBody:"+trendToMaxBody);      
      if(trendToMaxBody<TrendBodyToPrevRate)return 0;
      if(wasTrendSuperBig(trendCandleBody,historyLevelMax,historyLevelMin))return 0;
      
      return getTrendBasedOnHistoryAnalize(trendCandleBody,historyLevelMax,historyLevelMin);    
    
  }
  
  bool wasTrendSuperBig(double trendCandleBody, double historyLevelMax, double historyLevelMin){
      string alertMsg="Trend superBig!";
      if(trendCandleBody>0){
          double trendLow=iLow(NULL,0,1);
          if(trendLow<historyLevelMin){
            printf(alertMsg);
            return true;
          }
      }else{
          double trendHigh=iHigh(NULL,0,1);
          if(trendHigh>historyLevelMax){
            printf(alertMsg);
            return true;
          }
      }
      return false;
  }
    
  double getTrendBasedOnHistoryAnalize(double trendCandleBody,double historyLevelMax, double historyLevelMin){
      double correctedLevel;
      double trendValuePips;
      double trendCloseLevel=iClose(NULL,0,1);
      
      if(trendCandleBody>0){
         
         correctedLevel=historyLevelMax+getSpread()*2;
         trendValuePips=(trendCloseLevel-historyLevelMin)*KOEF;
         
         printf("level: "+correctedLevel+", trend:"+trendValuePips);
         if((trendCloseLevel>correctedLevel))return trendValuePips;
         else return 0;
               
      }else{
     
         correctedLevel=historyLevelMin-getSpread()*2;
         trendValuePips=(trendCloseLevel-historyLevelMax)*KOEF;
         
         printf("level: "+correctedLevel+", trend:"+trendValuePips);
         if((trendCloseLevel<correctedLevel))return trendValuePips;
         else return 0;         
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
                  printf("NonLoss by plus");
                  modifyOrder(TP,SL);       
               }                
            }else{
               nonLossLevelPips=MathAbs(NonLossMinusRate*(OrderStopLoss()-OrderOpenPrice())*KOEF);
               pips=-profitDollar/OrderLots()/10;
               if(profitDollar<0&&pips>=nonLossLevelPips){
                   SL = OrderStopLoss();
                   TP = OrderOpenPrice(); 
                   printf("NonLoss by minus");
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
      double  spreadCorrection=getSpreadCorrectionPips();
      return  NormalizeDouble(Bid-(MathAbs(trendValue)+spreadCorrection)*ProfitToTrendRate/KOEF,Digits);    
   }
 }

 double getSL(double trendValue){
   string msg="stopLoss too close --> break!";
   if(trendValue>0){
      double returnValue=NormalizeDouble(Bid-MathAbs(trendValue)/KOEF*LossToTrendRate,Digits);        
      if(MathAbs((Bid-returnValue))*KOEF<5){
         printf(msg);
         return -1;
      }
      return returnValue;
   }else{
      double  spreadCorrection=getSpreadCorrectionPips();
      returnValue=NormalizeDouble(Bid+(MathAbs(trendValue)+spreadCorrection)/KOEF*LossToTrendRate,Digits);
      if(MathAbs((Bid-returnValue))*KOEF<5){
         printf(msg);
         return -1;
      }      
      return returnValue;   
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
      alertResult(ticket,tp,sl,volume);
  } 
  
  double getSpreadCorrectionPips(){
         // ? need to fix!
         const double avgRealSpreadPips=2.0;
         double testerSpreadPips=getSpread()*KOEF; 
         return testerSpreadPips-avgRealSpreadPips;
  } 
  
  
   void alertResult(int ticket,double tp, double sl,double volume){      
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
