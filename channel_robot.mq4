#include <Shared2.mqh>
#include <ResistanceLevelManager.mqh>
#include <Logger.mqh>


const double PATTERN_SL=0.75;
const double PATTERN_TP=0.95;

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
public:  
 Channel_robot() {      
      shared = new Shared2(MAX_LOSS_DOLLARS); 
      KOEF = shared.getKoef();   
      currentOrderTicket = -1; 
      levelManager = new ResistanceLevelManager(MIN_WORKING_CHANNEL,WORK_PERIOD,SLIP_PIPS,shared);
      logger = new Logger(false);
 } 
   
 void onTick(){               
    if(OrdersTotal()==0){        
         if(levelManager.isBidCloseToLevel()){
            double targetPrice=levelManager.getSimetricLevelPrice();
            openOrder(targetPrice);
            levelManager.removeAllLevels();
         }
    }         
 }
 
 void openOrder(double targetPrice){
   double sl=-1;
   double tp=-1;
   color  colorOrder;   
   double pattern_sl=PATTERN_SL;
   double pattern_tp=PATTERN_TP;     
   double H_pips=MathAbs(Bid-targetPrice);
   double openPrice;
   
   int orderType=OP_SELL;

      // sell
      colorOrder=Red;
      openPrice=Bid;
      sl=openPrice+H_pips*pattern_sl;
      tp=openPrice-H_pips*pattern_tp;     
       
   double volume=shared.getLot(H_pips*pattern_sl);  
   currentOrderTicket=OrderSend(Symbol(),orderType,volume,openPrice,300,sl,tp,"My order",shared.getMagicNumber(),0,colorOrder); 
   shared.alertResult(currentOrderTicket,tp,sl,volume); 
 }
  
};




Channel_robot worker; 
 void OnTick() { 
   worker.onTick();         
 }