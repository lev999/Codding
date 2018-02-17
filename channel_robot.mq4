#include <Shared2.mqh>
#include <ResistanceLevelManager.mqh>
#include <Logger.mqh>


const double PATTERN_SL=1;
const double PATTERN_TP=1;

const double MAX_LOSS_DOLLARS=50;
const int    MIN_WORKING_CHANNEL=10;//pips 
const int    SLIP_PIPS=5; 
const int    ORDER_LIFE_TIME=1000;//bars
const int    SEARCH_HISTORY_PERIOD=50;
  
class Channel_robot { 
   double KOEF;         
   int currentOrderTicket;
   Shared2 *shared;
   ResistanceLevelManager *levelManager;
   Logger *logger;
public:  
 Channel_robot() {      
      shared = new Shared2(MAX_LOSS_DOLLARS); 
      KOEF = shared.getKoef();   
      currentOrderTicket = -1; 
      levelManager = new ResistanceLevelManager(MIN_WORKING_CHANNEL,SEARCH_HISTORY_PERIOD,SLIP_PIPS,shared);
      logger = new Logger(false);
 } 
   
 void onTick(){               
    if(OrdersTotal()==0){        
         if(levelManager.isBidCloseToLevel()){
            double targetPrice=levelManager.getSimetricLevelPrice();
            openOrder(targetPrice);            
            levelManager.removeAllLevels();
         }
     
    }else if(wasTimeOut()){
         logger.print("Order closing/nonLoss by timeOut");
         if(!setNonLoss()){
               closeOrder();
         }
    }             
 }
 
 void openOrder(double targetPrice){
   double sl=-1;
   double tp=-1;
   int orderType;
   color  colorOrder;   
   double pattern_sl=PATTERN_SL;
   double pattern_tp=PATTERN_TP;     
   double H_pips=MathAbs(Bid-targetPrice);
   double openPrice;
    if(targetPrice>Bid){
       ////buy          
      orderType=OP_BUY;
      colorOrder=Blue;
      openPrice=Ask;      
      sl=openPrice-H_pips*pattern_sl;
      tp=openPrice+H_pips*pattern_tp;     
    }else{
       ////sell
      orderType=OP_SELL;
      colorOrder=Red;
      openPrice=Bid;
      sl=openPrice+H_pips*pattern_sl;
      tp=openPrice-H_pips*pattern_tp;     
    }

       
   double volume=shared.getLot(H_pips*pattern_sl);  
   currentOrderTicket=OrderSend(Symbol(),orderType,volume,openPrice,300,sl,tp,"My order",shared.getMagicNumber(),0,colorOrder); 
   shared.alertResult(currentOrderTicket,tp,sl,volume); 
 }
 
 bool wasTimeOut(){  
      if(OrderSelect(currentOrderTicket, SELECT_BY_TICKET)){
         datetime orderTime = OrderOpenTime();
         int shift=iBarShift(NULL,0,orderTime);
         if(shift>=ORDER_LIFE_TIME){            
           return true;
         }      
      }  
   return false;   
 }  
 
  bool setNonLoss(){     

   if(OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderOpenPrice(),0)) 
   { 
      Print("Order set to non_loss successfully"); 
      return true;      
   }else if(OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0)){
       Print("Order set to non_loss successfully"); 
      return true;        
   } else{
      Print("Order non_loss failed with error #",GetLastError()); 
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
 
};




Channel_robot worker; 
 void OnTick() { 
   worker.onTick();         
 }