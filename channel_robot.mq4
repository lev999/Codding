#include <Shared2.mqh>
#include <ResistanceLevelManager.mqh>

input double  MAX_LOSS_DOLLARS=50;
input int     MIN_WORKING_CHANNEL=20; 

const double  SPREAD=1;
const int ORDER_TIMEOUT=10;
//+------------------------------------------------------------------+
//|                  SET SPREAD FOR TESTING to 1, NOT USE 0!!!                                                
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|   startOneHourDelay  is valid only for 1 hour period                          
//+------------------------------------------------------------------+



struct Order{
   double sl_pips,tp_pips,openPrice;
   int type;
};

struct PendingOrders{
   Order buy,sell;
   bool areValid;
   int channelId;
};
  
class Channel_robot { 
   double KOEF;         
   int currentOrderTicket;
   Shared2 *shared;
   ResistanceLevelManager *levelManager;
    
public:  
 Channel_robot() {
      shared = new Shared2(SPREAD,MAX_LOSS_DOLLARS); 
      KOEF=shared.getKoef();   
      currentOrderTicket=-1; 
      levelManager= new ResistanceLevelManager(MIN_WORKING_CHANNEL,shared);

 } 
   
 void onTick(){               
 
    if(OrdersTotal()==0){
      if(levelManager.isBidCloseToLevel()){
         double targetPrice=levelManager.getSimetricLevelPrice();
         openOrder(targetPrice);
         levelManager.removeActiveLevel();
      }
    }else{
      checkOrderTimeOut();
    }      
 }
 
 void openOrder(double targetPrice){
   double sl_pips,tp_pips;
   double sl=-1;
   double tp=-1;
   int orderType;
   color    colorOrder; 
   double pattern_sl=0.75;
   double pattern_tp=1;   
   
   if(targetPrice>Bid){
      // buy          
      orderType=OP_BUY;
      colorOrder=Blue;
      sl_pips=(targetPrice-Ask)*pattern_sl+SPREAD/KOEF;
      sl=Ask-sl_pips;
      tp_pips=(targetPrice-Bid)*pattern_tp-SPREAD/KOEF;
      tp=Bid+tp_pips;     
   }else{
      // sell
      orderType=OP_SELL;
      colorOrder=Red;
      sl_pips=(Bid-targetPrice)*pattern_sl+SPREAD/KOEF;
      sl=Bid+sl_pips;
      tp_pips=(Ask-targetPrice)*pattern_tp-SPREAD/KOEF;
      tp=Ask-tp_pips;   
   }      
   double volume=shared.getLot(sl,orderType);  
   currentOrderTicket=OrderSend(Symbol(),orderType,volume,Bid,300,sl,tp,"My order",shared.getMagicNumber(),0,colorOrder); 
   shared.alertResult(currentOrderTicket,tp,sl,volume); 
 }
 
  void checkOrderTimeOut(){  
   if(OrdersTotal()!=0){
      if(OrderSelect(currentOrderTicket, SELECT_BY_TICKET)){
         int orderTime = OrderOpenTime();
         int currentTime=TimeCurrent();
         double orderAgeHours=(currentTime-orderTime)/60/60;
         if(orderAgeHours>=ORDER_TIMEOUT){
            printf("Order closing by timeOut");
            if(shared.isPriceNear(Bid,OrderOpenPrice())||shared.isPriceNear(Ask,OrderOpenPrice())){
               closeOrder();
            }else{
               setNonLoss();
               currentOrderTicket=-1;
            }            
         }      
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
 
 void setNonLoss(){   
   int ticket=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0);           
   if(ticket<0) 
   { 
      Print("Order non_loss failed with error #",GetLastError());          
   }else{
      Print("Order set to non_loss successfully"); 
   } 
 }
 
};




Channel_robot worker; 
 void OnTick() { 
   worker.onTick();         
 }