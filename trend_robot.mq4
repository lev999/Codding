#include <PatternBuilder.mqh>
#include <Shared.mqh>
#include <CreateLabel.mqh>

input double  MaxLossDollar=50;
const int   timeFrame=PERIOD_H4;
  
class Trend_robot { 
  
 public:
   
   int KOEF;         
   int lastOrderMagicNumber;
   int currentBar;
   int currentOrderTicket;
   PatternBuilder *patternBuilder; 
   Shared *shared; 
   LabelManager *labelManager;
   
 Trend_robot() {  
      currentBar=0;
      patternBuilder = new PatternBuilder(); 
      shared = new Shared(); 
      KOEF=shared.getKoef();   
      lastOrderMagicNumber=-9999;  
      currentOrderTicket=-1;
      patternBuilder.publishPattern(1.0,1.0,10,3,0); 
      labelManager = new LabelManager();
             
 } 
   
 void onTick(){
 
      Pattern pattern=patternBuilder.getPattern();           
      checkOrderTimeOut(pattern.orderTimeOut);
      labelManager.parseAndPublishLabelValues();
            
      shared.setIsNewBarFalse();
      if(!isNewBar())return;
      shared.setIsNewBarTrue();

      if(pattern.blockTrading==1){
         closeAllOrders();
         currentBar=currentBar-1;//to start trading immidiatly
         return;
         };
      
      if(OrdersTotal()!=0)return;

      if(shared.getBarBody(1)<pattern.bodyWorkLimit)return;
      
      if(wasLastClosedOrderInThisBar())return;
      
      evaluateNewOrder(pattern.sl,pattern.tp,pattern.bodyWorkLimit); 
 }
 
 void checkOrderTimeOut(double orderTimeOut){
   if(OrdersTotal()!=0){
      if(OrderSelect(currentOrderTicket, SELECT_BY_TICKET)){
       
          int openedOrderHour=TimeHour(OrderOpenTime());
          int currentHour=TimeHour(TimeCurrent());

          if(currentHour<openedOrderHour){openedOrderHour=openedOrderHour-24;}
          
          if((currentHour-openedOrderHour)>orderTimeOut*4){          
            printf("Order closing by timeOut");
            closeOrder();
          }else{
            return ;
          }        
      }   
   }   
 }
  
 bool wasLastClosedOrderInThisBar(){
   int i=OrdersHistoryTotal()-1;
   if(OrderSelect(i, SELECT_BY_POS,MODE_HISTORY)){
      
   
       int closedOrderHour=TimeHour(OrderCloseTime());
       int currentHour=TimeHour(TimeCurrent());
       
       int closedOrderDay=TimeDay(OrderCloseTime());
       int currentDay=TimeDay(TimeCurrent());
       
       if(closedOrderHour==currentHour&&closedOrderDay==currentDay){
         return true;
       }else{
         return false;
       }        
   }   
   else{
      if(OrdersTotal()==0){
         printf("first order, empty history");
         return false;  
      }
   
      printf("Error!!! FAILED to take order from history:"+GetLastError());
      return true;
   }
 
 }
  

    int getMagicNumber(){
      int num = 1 + 1000*MathRand()/32768;
      printf("magic:"+num);
      return num;
   
   }

 void evaluateNewOrder(double pattern_sl,double pattern_tp,double bodyWorkLimit){
 
   double extream;
   double sl=-1;
   double tp=-1;
   int orderType;
   color    colorOrder;   
   
      
   if((iOpen(NULL,0,1)<iClose(NULL,0,1))){
      // buy     
      extream=iLow(NULL,0,1);
      printf("extream:"+extream);
      printf("Bid:"+Bid);
      printf("Ask:"+Ask);
      
      if((MathAbs(Bid-extream)/2)*KOEF<bodyWorkLimit)return;
      orderType=OP_BUY;
      colorOrder=Blue;
      
      sl=Ask-(Ask-extream)*pattern_sl;
      tp=Bid+(Bid-extream)*pattern_tp;
     
   }else{
   // sell
      extream=iHigh(NULL,0,1);

      if((MathAbs(Bid-extream)/2)*KOEF<bodyWorkLimit)return;
      orderType=OP_SELL;
      colorOrder=Red;
      sl=Bid+(extream-Bid)*pattern_sl;
      tp=Ask-(extream-Ask)*pattern_tp;
      
   }
   double volume=getLot(sl,orderType);
   currentOrderTicket=OrderSend(Symbol(),orderType,volume,Bid,300,sl,tp,"My order",getMagicNumber(),0,colorOrder); 
   alertResult(currentOrderTicket,tp,sl,volume);
 }
 
 
   double getLot(double stopLossValue,int orderType ){
      double openPrice=0;
      if(orderType==OP_BUY){
         openPrice=Ask;
      }else{
         openPrice=Bid;
      }
      
      double pips=MathAbs(stopLossValue-openPrice)*KOEF;
      double lot=NormalizeDouble(MaxLossDollar/(10*pips), 2);
      
      if(lot<0.01){
         printf("Error: lot <0.01");
         return 0;
      }else{
         return lot;
      }   
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

 bool isNewBar(){
      int bar=iBars(NULL,PERIOD_CURRENT);
      if(currentBar!=bar){
         currentBar=bar;
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
  int ticket;
   if(OrderType()==OP_BUY){
       ticket=OrderClose(OrderTicket(),OrderLots(),Bid,100,Red);
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
   
};



Trend_robot worker; 
 void OnTick() { 
   worker.onTick();         
 }