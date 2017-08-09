#include <PatternBuilder.mqh>

input double  MaxLossDollar=50;

const int   timeFrame=PERIOD_H4;

 
  
class Trend_robot { 
  
 public:
   
   int KOEF;         
   int lastOrderMagicNumber;
   int currentBar;
   int currentOrderTicket;

 Trend_robot() {  
      currentBar=0;
       
      KOEF=getKoef();   
      lastOrderMagicNumber=-9999;  
      currentOrderTicket=-1;        
 } 
   
 void onTick(){      
     
      PatternBuilder *patternBuilder = new PatternBuilder();
      
      Pattern pat=patternBuilder.getPattern();
      checkOrderTimeOut();
      
      if(OrdersTotal()!=0)return;
      
      if(!isNewBar())return;
      
      if(getBarBody()<10)return;
      
      if(wasLastClosedOrderInThisBar())return;
      
      evaluateNewOrder(); 
 }
 
 void checkOrderTimeOut(){
   if(OrdersTotal()!=0){
      if(OrderSelect(currentOrderTicket, SELECT_BY_TICKET)){
       
          int openedOrderHour=TimeHour(OrderOpenTime());
          int currentHour=TimeHour(TimeCurrent());
          int openedOrderDay=TimeDay(OrderOpenTime());
          int currentDay=TimeDay(TimeCurrent());

          if(openedOrderDay!=currentDay|| (currentHour>=openedOrderHour+8)){          
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
  
 double getBarBody(){
   double barBody=MathAbs(iOpen(NULL,0,1)-iClose(NULL,0,1))*KOEF;
   printf("body:"+barBody);
   return barBody;
 }
 
    int getMagicNumber(){
      int num = 1 + 1000*MathRand()/32768;
      printf("magic:"+num);
      return num;
   
   }

 void evaluateNewOrder(){
 
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
      
      if((MathAbs(Bid-extream)/2)*KOEF<10)return;
      orderType=OP_BUY;
      colorOrder=Blue;
      
      sl=Ask-(Ask-extream)/2;
      tp=Bid+(Bid-extream);
     
   }else{
   // sell
      extream=iHigh(NULL,0,1);
      printf("extream:"+extream);
      printf("Bid:"+Bid);
      printf("Ask:"+Ask);

      if((MathAbs(Bid-extream)/2)*KOEF<10)return;
      orderType=OP_SELL;
      colorOrder=Red;
      sl=Bid+(extream-Bid)/2;
      tp=Ask-(extream-Ask);
      
   }
   double volume=getLot(sl,orderType);
   currentOrderTicket=OrderSend(Symbol(),orderType,volume,Bid,300,sl,tp,"My order",getMagicNumber(),0,colorOrder); 
   alertResult(currentOrderTicket,tp,sl,volume);
   printf("evaluateNewOrder");   
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
 
       
 
  int getKoef(){
      int koefLocal=1; 
      for (int i=1;i<Digits;i=i+1){
         koefLocal=koefLocal*10;
      }
      return koefLocal;
  }
  
};

Trend_robot worker; 
 void OnTick() { 
   worker.onTick();         
 }