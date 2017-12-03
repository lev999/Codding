#include <Shared2.mqh>
#include <ResistanceLevelManager.mqh>
#include <TargetLevelBreakManager.mqh>
#include <MinMaxTracker.mqh>
#include <Logger.mqh>
#include <TPSLAnalyser.mqh>

input double  MAX_LOSS_DOLLARS=50;
input int     MIN_WORKING_CHANNEL=20; 
input double PATTERN_SL=1.0;
input double PATTERN_TP=1.0;

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
   MinMaxTracker *minMaxTracker;
   TargetLevel targetLevel;
   TargetLevelBreakManager *targetLevelBreakManager;
   Logger *logger;
   TPSLAnalyser *tpslAnalyzer;
public:  
 Channel_robot() {
      
      shared = new Shared2(MAX_LOSS_DOLLARS); 
      KOEF = shared.getKoef();   
      currentOrderTicket = -1; 
      levelManager = new ResistanceLevelManager(MIN_WORKING_CHANNEL,WORK_PERIOD,shared);
      minMaxTracker = new MinMaxTracker();
      targetLevelBreakManager = new TargetLevelBreakManager(shared);
      logger = new Logger(false);
      tpslAnalyzer = new TPSLAnalyser(PATTERN_SL,PATTERN_TP,shared);
 } 
   
 void onTick(){               
    minMaxTracker.update();
    if(OrdersTotal()==0){    
      if(isTradingAlowed()){
         if(levelManager.isBidCloseToLevel()){
            double targetPrice=levelManager.getSimetricLevelPrice();
            targetLevel.targetPrice=targetPrice;
            targetLevel.initBidPrice=Bid;
            openOrder(targetPrice);
            minMaxTracker.reset();
            targetLevelBreakManager.resetTargetBreakShift(currentOrderTicket);
            levelManager.removeAllLevels();
         }
      }
    }
    else if(wasTimeOut()){
         logger.printf("Order closing/nonLoss by timeOut");
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
     updateSLTPAnalyser();       
     return true;
   }
   logger.printf("isTradingAlowed:0");   
   if(!targetLevelBreakManager.wasTargetLevelReached()){
      logger.printf("isTradingAlowed:1");   
      updateTargetBreak();
      return false;   
   }else{
      logger.printf("isTradingAlowed:2");   
      if(!targetLevelBreakManager.isOneBarDelayActive()){
         logger.printf("isTradingAlowed:3");            
         return true;      
      }   
   } 
   
   return false;
 }
 

 
 void updateTargetBreak(){
   if(!shared.selectLastOrder(currentOrderTicket)){
      printf("BUG:Failed to select order by ticket.CurrentOrderTicket:"+DoubleToStr(currentOrderTicket));
   }
   logger.printf("updateTargetBreak: 0");
  
   double targetPips=MathAbs(targetLevel.targetPrice-targetLevel.initBidPrice)*KOEF;
   double upperTargetLevel=OrderOpenPrice()+targetPips/KOEF;
   double lowerTargetLevel=OrderOpenPrice()-targetPips/KOEF;
   logger.printf("updateTargetBreak:upperTargetLevel "+DoubleToStr(upperTargetLevel));  
   logger.printf("updateTargetBreak:minMaxTracker.getMaxLevel() "+DoubleToStr((minMaxTracker.getMaxLevel()-shared.getSpread()/KOEF))); 

   if (upperTargetLevel<minMaxTracker.getMaxLevel()-shared.getSpread()/KOEF){
      logger.printf("updateTargetBreak: 1");
      targetLevelBreakManager.updateTargetBreakShift();
      updateSLTPAnalyser();
   }

   logger.printf("updateTargetBreak:lowerTargetLevel "+DoubleToStr(lowerTargetLevel));  
   logger.printf("updateTargetBreak:minMaxTracker.getMinLevel() "+DoubleToStr((minMaxTracker.getMinLevel()+shared.getSpread()/KOEF))); 
                        
   if (lowerTargetLevel>minMaxTracker.getMinLevel()+shared.getSpread()/KOEF){
      logger.printf("updateTargetBreak: 2");
      targetLevelBreakManager.updateTargetBreakShift();
      updateSLTPAnalyser();
   }         
 }
 
 void updateSLTPAnalyser(){

   if(!shared.selectLastOrder(currentOrderTicket)){
      printf("BUG(updateSLTPAnalyser):Failed to select order by ticket.CurrentOrderTicket:"+DoubleToStr(currentOrderTicket));
   }
   tpslAnalyzer.update(targetLevel.targetPrice,OrderOpenPrice(),OrderOpenTime(),TimeCurrent());
 }
  
 void openOrder(double targetPrice){
   double sl=-1;
   double tp=-1;
   int orderType;
   color    colorOrder; 
   TPSL tpsl=tpslAnalyzer.getIdealTPSL();
   
   double pattern_sl=tpsl.SL;
   double pattern_tp=tpsl.TP;   
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