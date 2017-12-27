#include <Shared2.mqh>
#include <ResistanceLevelManager.mqh>
#include <TargetLevelBreakManager.mqh>
#include <MinMaxTracker.mqh>
#include <Logger.mqh>
#include <TPSLAnalyser.mqh>

input double  MAX_LOSS_DOLLARS=50;
input int     MIN_WORKING_CHANNEL=20; 

const double PATTERN_SL=0.75;
const double PATTERN_TP=0.95;
const int WORK_PERIOD=50;
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
   MinMaxTracker *minMaxTracker;
   TargetLevel targetLevel;
   TargetLevelBreakManager *targetLevelBreakManager;
   Logger *logger;
public:  
 Channel_robot() {
      
      shared = new Shared2(MAX_LOSS_DOLLARS); 
      KOEF = shared.getKoef();   
      currentOrderTicket = -1; 
      levelManager = new ResistanceLevelManager(MIN_WORKING_CHANNEL,WORK_PERIOD,shared);
      minMaxTracker = new MinMaxTracker();
      targetLevelBreakManager = new TargetLevelBreakManager(shared);
      logger = new Logger(false);
 } 
   
 void onTick(){               
    minMaxTracker.update();
    if(OrdersTotal()==0){    
     // if(isTradingAlowed()){
    //  logger.print("TradingAlowed...");
         if(levelManager.isBidCloseToLevel()){
            double targetPrice=levelManager.getSimetricLevelPrice();
            targetLevel.targetPrice=targetPrice;
            targetLevel.initBidPrice=Bid;
            openOrder(targetPrice);
            minMaxTracker.reset();
            targetLevelBreakManager.resetTargetBreakShift(currentOrderTicket);
            levelManager.removeAllLevels();
         }
      //}
    }
    else if(wasTimeOut()){
         logger.print("Order closing/nonLoss by timeOut");
         if(!setNonLoss()){
               closeOrder();
         }
      }          
 }
 
 bool isTradingAlowed(){
   
   if(targetLevelBreakManager.isFirstTrade()){
     return true;
   }
      
   if(currentOrderTicket==-1){
     return true;
   }
   
   if(wasTimeOut()){     
     return true;
   }
   logger.print("isTradingAlowed:0");   
   if(!targetLevelBreakManager.wasTargetLevelReached()){
      logger.print("isTradingAlowed:1");   
      updateTargetBreak();
      return false;   
   }else{
      logger.print("isTradingAlowed:2");   
      if(!targetLevelBreakManager.isOneBarDelayActive()){
         logger.print("isTradingAlowed:3");            
         return true;      
      }   
   } 
   
   return false;
 }
 

 
 void updateTargetBreak(){
   if(!shared.selectLastOrder(currentOrderTicket)){
      printf("BUG:Failed to select order by ticket.CurrentOrderTicket:"+DoubleToStr(currentOrderTicket));
   }
   logger.print("updateTargetBreak: 0");
  
   double targetPips=MathAbs(targetLevel.targetPrice-targetLevel.initBidPrice)*KOEF;
   double upperTargetLevel=OrderOpenPrice()+targetPips/KOEF;
   double lowerTargetLevel=OrderOpenPrice()-targetPips/KOEF;
   logger.print("updateTargetBreak:upperTargetLevel "+DoubleToStr(upperTargetLevel));  
   logger.print("updateTargetBreak:minMaxTracker.getMaxLevel() "+DoubleToStr((minMaxTracker.getMaxLevel()-shared.getSpread()/KOEF))); 

   if (upperTargetLevel<minMaxTracker.getMaxLevel()-shared.getSpread()/KOEF){
      logger.print("updateTargetBreak: 1");
      targetLevelBreakManager.updateTargetBreakShift();
   }

   logger.print("updateTargetBreak:lowerTargetLevel "+DoubleToStr(lowerTargetLevel));  
   logger.print("updateTargetBreak:minMaxTracker.getMinLevel() "+DoubleToStr((minMaxTracker.getMinLevel()+shared.getSpread()/KOEF))); 
                        
   if (lowerTargetLevel>minMaxTracker.getMinLevel()+shared.getSpread()/KOEF){
      logger.print("updateTargetBreak: 2");
      targetLevelBreakManager.updateTargetBreakShift();
   }         
 }
 
 void openOrder(double targetPrice){
   // NOTE: direction should be in the way of longer Stop==> SL always will be less TP
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
   double volume=shared.getLot(H_pips*pattern_sl);  
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