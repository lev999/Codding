#include <Shared2.mqh>
#include <ResistanceLevelManager.mqh>
#include <TrendDetector.mqh>
#include <Logger.mqh>


input double PATTERN_SL=0.75;
input double PATTERN_TP=0.95;

const double MAX_LOSS_DOLLARS=50;
const int    MIN_WORKING_CHANNEL=20;//pips 
const int    SLIP_PIPS=20; 
const int    WORK_PERIOD=50;//bars
  
class Channel_robot { 
   double KOEF;         
   int currentOrderTicket;
   Shared2 *shared;
   ResistanceLevelManager *levelManager;
   Logger *logger;
   TrendDetector *trendDetector;
public:  
 Channel_robot() {      
      shared = new Shared2(MAX_LOSS_DOLLARS); 
      KOEF = shared.getKoef();   
      currentOrderTicket = -1; 
      levelManager = new ResistanceLevelManager(MIN_WORKING_CHANNEL,WORK_PERIOD,SLIP_PIPS,shared);
      logger = new Logger(false);
      trendDetector = new TrendDetector(WORK_PERIOD);
 } 
   
 void onTick(){               
    if(OrdersTotal()==0){    
         trendDetector.update();
         if(levelManager.isBidCloseToLevel()){
            double targetPrice=levelManager.getSimetricLevelPrice();
            openOrder(targetPrice,trendDetector.getOrderType());
            levelManager.removeAllLevels();
         }
    }
    else if(wasTimeOut()){
         logger.print("Order closing/nonLoss by timeOut");
         if(!setNonLoss()){
               closeOrder();
         }
    }          
 }
 
 void openOrder(double targetPrice,int orderType){
   double sl=-1;
   double tp=-1;
   color  colorOrder;   
   double pattern_sl=PATTERN_SL;
   double pattern_tp=PATTERN_TP;     
   double H_pips=MathAbs(Bid-targetPrice);
   double openPrice;
   
   if(orderType==OP_BUY){
      // buy     
      colorOrder=Blue;
      openPrice=Ask;      
      sl=openPrice-H_pips*pattern_sl;
      tp=openPrice+H_pips*pattern_tp;     
    }else{
      // sell
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
         if(shift>=WORK_PERIOD){            
           return true;
         }      
      }  
   return false;   
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
 
};




Channel_robot worker; 
 void OnTick() { 
   worker.onTick();         
 }