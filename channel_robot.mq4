#include <Shared2.mqh>
#include <ResistanceLevelManager.mqh>

input double  MAX_LOSS_DOLLARS=50;
input int     MIN_WORKING_CHANNEL=20; 
input double PATTERN_SL=0.9;
input double PATTERN_TP=1;

const double WORK_PERIOD=50;
//+------------------------------------------------------------------+
//|                  SET SPREAD FOR TESTING to 1, NOT USE 0!!!                                                
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|   startOneHourDelay  is valid only for 1 hour period                          
//+------------------------------------------------------------------+

struct TargetLevel{   
   double targetPrice;
   double initBidPrice;
};
  
class Channel_robot { 
   double KOEF;         
   int currentOrderTicket;
   Shared2 *shared;
   ResistanceLevelManager *levelManager;
   TargetLevel targetLevel;
public:  
 Channel_robot() {
      
      shared = new Shared2(MAX_LOSS_DOLLARS); 
      KOEF=shared.getKoef();   
      currentOrderTicket=-1; 
      levelManager= new ResistanceLevelManager(MIN_WORKING_CHANNEL,WORK_PERIOD,shared);
 } 
   
 void onTick(){               
 
    if(OrdersTotal()==0){    
      if(isTradingAlowed()){
         if(levelManager.isBidCloseToLevel()){
            double targetPrice=levelManager.getSimetricLevelPrice();
            targetLevel.targetPrice=targetPrice;
            targetLevel.initBidPrice=Bid;
            openOrder(targetPrice);
            levelManager.removeAllLevels();
         }
      }
    }else if(wasTimeOut()){
         printf("Order closing/nonLoss by timeOut");
         if(!setNonLoss()){
               closeOrder();
         }
      }
          
 }
 
 
 bool isTradingAlowed(){
   
   if(currentOrderTicket==-1){
      printf("1");
    return true;
   }
   
   if(wasTimeOut()){            
       printf("2");
     return true;
   }
   
   if(!selectLastOrder()){
      printf("Failed to select order by ticket.CurrentOrderTicket:"+DoubleToStr(currentOrderTicket));
      return NULL;
   }
         
   int openShift=iBarShift(NULL,0,OrderOpenTime(),true);               
   double highestPeakPrice=iHigh(NULL,0,iHighest(NULL,0,MODE_HIGH,openShift,2));
   double lowestPeakPrice=iLow(NULL,0,iLowest(NULL,0,MODE_LOW,openShift,2)); 
   double targetPips=MathAbs(targetLevel.targetPrice-targetLevel.initBidPrice)*KOEF;
   double upperTargetLevel=OrderOpenPrice()+targetPips/KOEF;
   double lowerTargetLevel=OrderOpenPrice()-targetPips/KOEF;

   if (upperTargetLevel<highestPeakPrice){
      printf("3");
      return true;
   }
                        
   if (lowerTargetLevel>lowestPeakPrice){
      printf("4");
      return true;
   }         
   printf("5");                   
   return false;
 }
 
 bool selectLastOrder(){
   return OrderSelect(currentOrderTicket, SELECT_BY_TICKET); 
 }
 void openOrder(double targetPrice){
   double sl=-1;
   double tp=-1;
   int orderType;
   color    colorOrder; 
   double pattern_sl=PATTERN_SL;
   double pattern_tp=PATTERN_TP;   
   double H_pips=MathAbs(Bid-targetPrice);
   double openPrice;
   if(targetPrice>Bid){
      // buy          
      orderType=OP_BUY;
      colorOrder=Blue;
      openPrice=Ask;      
      sl=openPrice-H_pips*pattern_sl;
      tp=openPrice+H_pips*pattern_tp;     
    }else{
      // sell
      orderType=OP_SELL;
      colorOrder=Red;
      openPrice=Bid;
      sl=openPrice+H_pips*pattern_sl;
      tp=openPrice-H_pips*pattern_tp;     
    }
   double volume=shared.getLot(H_pips);  
   currentOrderTicket=OrderSend(Symbol(),orderType,volume,openPrice,300,sl,tp,"My order",shared.getMagicNumber(),0,colorOrder); 
   shared.alertResult(currentOrderTicket,tp,sl,volume); 
 }
 
  bool wasTimeOut(){  
      if(OrderSelect(currentOrderTicket, SELECT_BY_TICKET)){
         datetime orderTime = OrderOpenTime();
         datetime currentTime=TimeCurrent();
         datetime orderAgeHours=(currentTime-orderTime)/60/60;
         if(orderAgeHours>=WORK_PERIOD*2){
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