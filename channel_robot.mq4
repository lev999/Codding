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
      if(!isTradingBlocked()){
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
 
 
 bool isTradingBlocked(){
   
   if(currentOrderTicket==-1){
      printf("1");
    return false;
   }
   
   if(wasTimeOut()){            
       printf("2");
     return false;
   }
   
   if(OrderSelect(currentOrderTicket, SELECT_BY_TICKET)){
         
         int openShift=iBarShift(NULL,0,OrderOpenTime(),true); 
                  
         double highestPeakPrice=iHigh(NULL,0,iHighest(NULL,0,MODE_HIGH,openShift,0));
         double lowestPeakPrice=iLow(NULL,0,iLowest(NULL,0,MODE_LOW,openShift,0)); 
      printf("highestPeakPrice:"+highestPeakPrice);

      printf("lowestPeakPrice:"+lowestPeakPrice);

        if(targetLevel.targetPrice>OrderOpenPrice()){
        //buy                               
              if (targetLevel.targetPrice<highestPeakPrice||shared.isPriceNear(targetLevel.targetPrice,Bid)){
              printf("3");
                  return false;
              }else{
              printf("4");
                  return true;
              }            
         }else{
         //sell
            if (targetLevel.targetPrice>lowestPeakPrice||shared.isPriceNear(targetLevel.targetPrice,Bid)){
                  printf("5");
                  return false;
              }else{
                  printf("6");
                  return true;
              }                   
         }               
      }else{      
         printf("Failed to select order by ticket.CurrentOrderTicket:"+currentOrderTicket);
      }   
 
   return NULL;
 }
 
 void openOrder(double targetPrice){
   double sl_pips,tp_pips;
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
         double orderTime = OrderOpenTime();
         double currentTime=TimeCurrent();
         double orderAgeHours=(currentTime-orderTime)/60/60;
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