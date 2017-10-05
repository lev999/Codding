#include <GlobalVarManager.mqh>
#include <Shared.mqh>
#include <PatternChooser.mqh>

input double  MaxLossDollar=50;
input double  TP_SL_Limit=5.0;
input int     ORDER_TIME_OUT=40;//in hours
input int     HISTORY_DEPTH=5;
const int     timeFrame=PERIOD_H1;
const double  initSL=1;
const double  initTP=-0.5;
const double  SPREAD=2;
//+------------------------------------------------------------------+
//|                  SET SPREAD FOR TESTING to 0                                                |
//+------------------------------------------------------------------+


  
class Trend_robot { 
  
 public:
   
   int KOEF;         
   int lastOrderMagicNumber;
   int currentBar;
   int currentOrderTicket;
   GlobalVarManager *globalVarManager; 
   Shared *shared; 
   PatternChooser *patternChooser; 
   
 Trend_robot() {
      currentBar=0;
      globalVarManager = new GlobalVarManager(); 
      globalVarManager.publishPattern(initTP,MathAbs(initSL),ORDER_TIME_OUT,0,HISTORY_DEPTH,TP_SL_Limit,SPREAD);
      shared = new Shared(); 
      KOEF=shared.getKoef();   
      lastOrderMagicNumber=-9999;  
      currentOrderTicket=-1; 
      patternChooser = new PatternChooser();
 } 
   
 void onTick(){
 
      
      checkOrderTimeOut(globalVarManager.getOrderTimeOut());
      
            
      shared.setIsNewBarFalse();
      if(!isNewBar())return;   
      shared.setIsNewBarTrue();
      
      patternChooser.choosePatternAndPublish();
      Pattern pattern=globalVarManager.getPattern();
            
      if(pattern.blockTrading==1){
        // closeAllOrders();
         //currentBar=currentBar-1;//to start trading immidiatly
         return;
         };
      
      if(OrdersTotal()!=0)return;

      //if(shared.getBarBody(1)<pattern.bodyWorkLimit)return;
      
      if(wasLastClosedOrderInThisBar())return;
      
      evaluateNewOrder(pattern.sl,pattern.tp,pattern.sl_tp_limit); 
 }
 
 void checkOrderTimeOut(double orderTimeOut){
  
   if(OrdersTotal()!=0){
      if(OrderSelect(currentOrderTicket, SELECT_BY_TICKET)){
         int orderTime = OrderOpenTime();
         int currentTime=TimeCurrent();
         double orderAgeHours=(currentTime-orderTime)/60/60;
         if(orderAgeHours>=orderTimeOut){
            printf("Order closing by timeOut");
            closeOrder();
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
   
      printf("Error!!! FAILED to take order from history:"+DoubleToStr(GetLastError()));
      return true;
   }
 
 }
  

    int getMagicNumber(){
      int num = 1 + 1000*MathRand()/32768;
      printf("magic:"+DoubleToStr(num));
      return num;
   
   }

 void evaluateNewOrder(double pattern_sl,double pattern_tp, double tp_sl_limit){
 
   double extream,sl_pips,tp_pips;
   double sl=-1;
   double tp=-1;
   int orderType;
   color    colorOrder;   
   
      
   if((iOpen(NULL,0,1)<iClose(NULL,0,1))){
      // buy     
      extream=iLow(NULL,0,1);
      
      orderType=OP_BUY;
      colorOrder=Blue;
      sl_pips=(Ask-extream)*pattern_sl+SPREAD/KOEF;
      sl=Ask-sl_pips;
      tp_pips=(Bid-extream)*pattern_tp-SPREAD/KOEF;
      tp=Bid+tp_pips;
     
   }else{
   // sell
      extream=iHigh(NULL,0,1);

      orderType=OP_SELL;
      colorOrder=Red;
      sl_pips=(extream-Bid)*pattern_sl+SPREAD/KOEF;
      sl=Bid+sl_pips;
      tp_pips=(extream-Ask)*pattern_tp-SPREAD/KOEF;
      tp=Ask-tp_pips;
    }
   double volume=getLot(sl,orderType);
   if(!shared.isOrderValid(tp_pips*KOEF,sl_pips*KOEF,tp_sl_limit))return;      

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
         Print("Order open failed with error #",DoubleToStr(GetLastError()),", profit:",DoubleToStr(tp),", loss:",DoubleToStr(sl),", Lot:"+DoubleToStr(volume)); 
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