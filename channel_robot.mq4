#include <Shared2.mqh>
#include <ChannelManager.mqh>

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
   ChannelManager *channelManager;
    
public:  
 Trend_robot() {
      shared = new Shared2(SPREAD); 
      KOEF=shared.getKoef();   
      currentOrderTicket=-1; 
      channelManager= new ChannelManager(MIN_WORKING_CHANNEL,shared);
      startDelayHour=-1;
 } 
   
 int currentChannelId;
 PendingOrders pendingOrders;
 void onTick(){               
 
    if(OrdersTotal()==0){
      if(channelManager.existsValidChannel()){
         ChannelParams channelParams=channelManager.getChannelParams(); 
         if(pendingOrders.channelId!=channelParams.id&&shared.isPriceNear(channelParams.active)){           
            updatePendingOrders(channelParams); 
         }
         if(pendingOrders.areValid){ 
            checkToOpenOrder(); 
         }                
      } 
      else{            
         pendingOrders.areValid=false;
         deletePendingOrderLines();
         return;
      }      
    }else{
       pendingOrders.areValid=false;
    }              
 }
 
 void updatePendingOrders(ChannelParams &channelParams){
   deletePendingOrderLines();
   pendingOrders.areValid=true;
   pendingOrders.channelId=channelParams.id;
   double halfChannelHeighPips=channelParams.height/2;
   double channelCenter=halfChannelHeighPips/KOEF+channelParams.low;
   
   double spreadCorrection=getSpreadCorrection(halfChannelHeighPips);
   Order sell;
   Order buy;
   if(Bid<channelCenter){
      sell.openPrice=channelParams.low-halfChannelHeighPips/KOEF;
      buy.openPrice=channelCenter;         
   }else{
      buy.openPrice=channelParams.high+halfChannelHeighPips/KOEF;
      sell.openPrice=channelCenter;  
   }      
   sell.sl_pips=halfChannelHeighPips+spreadCorrection;
   sell.tp_pips=halfChannelHeighPips-spreadCorrection;
   sell.type=OP_SELL;
   
   buy.sl_pips=halfChannelHeighPips+spreadCorrection; 
   buy.tp_pips=halfChannelHeighPips-spreadCorrection;
   buy.type=OP_BUY;
   
   pendingOrders.buy=buy;      
   pendingOrders.sell=sell;
   drawPendingOrderLines();
 }
 
 double getSpreadCorrection(double halfChannelHeighPips){
 //--- Spread should be less than 5% of order TP/SL. Example: if spread=2 --> if Order TP>40 --> apply correction
 
   if(halfChannelHeighPips*0.025>=SPREAD){
      double correction=halfChannelHeighPips*0.05;
      return correction;
   }else{
      return 0;
   }
 }
 
 void drawPendingOrderLines(){
      string name=DoubleToStr(pendingOrders.buy.openPrice);
     ObjectCreate(0,name,OBJ_HLINE,0,0,pendingOrders.buy.openPrice);
     ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASH);
     ObjectSetInteger(0,name,OBJPROP_COLOR,clrRosyBrown); 
     name=DoubleToStr(pendingOrders.sell.openPrice);
     ObjectCreate(0,name,OBJ_HLINE,0,0,pendingOrders.sell.openPrice);
     ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASH);      
     ObjectSetInteger(0,name,OBJPROP_COLOR,clrRosyBrown);    

 }
 
 void checkToOpenOrder(){
 
   if(shared.isPriceNear(Bid,pendingOrders.buy.openPrice)){
      openOrder(pendingOrders.buy);
      deletePendingOrderLines();
   }else if(shared.isPriceNear(Bid,pendingOrders.sell.openPrice)){
      openOrder(pendingOrders.sell);
      deletePendingOrderLines();
   } 
 }
 
 void deletePendingOrderLines(){
    ObjectDelete(0,DoubleToStr(pendingOrders.buy.openPrice) );
    ObjectDelete(0,DoubleToStr(pendingOrders.sell.openPrice) );
 }
 
 void setNonLoss(){
    if(OrderSelect(0,SELECT_BY_POS)){      
      bool resultOk=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),OrderExpiration(),Yellow);
      if(!resultOk){
          printf("setNonLoss: Order change failed");
      }
    }else{
      printf("BUG!! No active orders");
    }

 }
 
 bool lastOrderWasNotInTheSameHour(){
 
  if(OrdersHistoryTotal()==0){
      return true;
    }else{    
      for(int i=0;i<OrdersHistoryTotal();i++){
     
        if(OrderSelect(currentOrderTicket,SELECT_BY_TICKET,MODE_HISTORY)){
           if(TimeHour(OrderCloseTime())==Hour()){
            //printf("Blocked order, because of last order in the same hour");
            return false;
           }
         return true;  
        }           
      }
      printf("ERROR: lastOrderWasNotInTheSameHour has bug");
      return false; 
    }
 
 }
 
 bool isTransactionSuccess(int type){
    if(OrdersHistoryTotal()==0){
      return true;
    }else{    
      for(int i=0;i<OrdersHistoryTotal();i++){
     
        if(OrderSelect(currentOrderTicket,SELECT_BY_TICKET,MODE_HISTORY)){
           if(OrderProfit()<0&&OrderType()==type){
            //printf("Blocked order, because of last minus");
            return false;
           }
         return true;  
        }           
      }
      printf("ERROR: isTransactionSuccess has bug");
      return false; 
    }
 }
 
 
 int startDelayHour;    
 bool isOneHourDelayActive(){
    if(startDelayHour!=Hour()){       
      startDelayHour=-1;
      return false;
    }
    else{
      return true;
    }
 }
      
 int getMagicNumber(){
      int num = 1 + 1000*MathRand()/32768;
      return num;
   
   }

 void openOrder(Order &order){
 
   double sl=-1;
   double tp=-1;
   color  colorOrder;   
   
   if(order.type==OP_SELL){
   // sell     
      sl=Bid+order.sl_pips/KOEF;
      tp=Ask-order.tp_pips/KOEF;      
      colorOrder=Red;         
   }else{
    // buy
      sl=Ask-order.sl_pips/KOEF;
      tp=Bid+order.tp_pips/KOEF;
      colorOrder=Blue;
   }
   
   double volume=getLot(sl,order.type); 

   currentOrderTicket=OrderSend(Symbol(),order.type,volume,Bid,300,sl,tp,"My order",getMagicNumber(),0,colorOrder); 
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