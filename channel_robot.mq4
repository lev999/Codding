#include <Shared2.mqh>
#include <ResistanceLevelManager.mqh>

input double  MaxLossDollar=50;
input int     MIN_WORKING_CHANNEL=20; 
const double  SPREAD=1;
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
  
class Trend_robot { 
   double KOEF;         
   int currentOrderTicket;
   Shared2 *shared;
   ResistanceLevelManager *levelManager;
    
public:  
 Trend_robot() {
      shared = new Shared2(SPREAD); 
      KOEF=shared.getKoef();   
      currentOrderTicket=-1; 
      levelManager= new ResistanceLevelManager(MIN_WORKING_CHANNEL,shared);

 } 
   
 void onTick(){               
 
    if(OrdersTotal()==0){
      if(levelManager.isBidCloseToLevel()){
         double targetPrice=levelManager.getSimetricLevelPrice();
         openOrder(targetPrice);
      }
    }      
 }
 
 void openOrder(double targetPrice){
 
 
 }
 
};



Trend_robot worker; 
 void OnTick() { 
   worker.onTick();         
 }