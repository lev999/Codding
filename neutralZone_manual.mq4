#include <Shared2.mqh>

input double  MaxLossDollar=50;
input int     MIN_WORKING_CHANNEL=10; 
const double  SPREAD=2;
const string flatName="Flat";
//+------------------------------------------------------------------+
//|                  SET SPREAD FOR TESTING to 1, NOT USE 0!!!                                                |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|   startOneHourDelay  is valid only for 1 hour period                           |
//+------------------------------------------------------------------+



struct OrderParams{
   double sl_pips,tp_pips;
   int type;
};

 struct ChannelParams{
   double height;
   double low;
   double high;
   bool isValid;
}; 

class Trend_robot { 
   double KOEF;         
   int currentOrderTicket;
   Shared2 *shared;
    
public:  
 Trend_robot() {
      shared = new Shared2(SPREAD); 
      KOEF=shared.getKoef();   
      currentOrderTicket=-1; 
      startDelayHour=-1;
 } 
   
 void onTick(){         
       
   updateChannelParams();
   if(channelParams.high<channelParams.low) {
      closeAllOrders();   
   }
   else
    if(OrdersTotal()==0&&channelParams.isValid){                                    
         double h=channelParams.height;
         OrderParams orderParams;             
         orderParams.sl_pips=h*0.5;
         orderParams.tp_pips=h*1.0;
         
          if(shared.isPriceNear(channelParams.low)||shared.isPriceNear(channelParams.high)){
            orderParams.type=OP_BUY;
            openOrder(orderParams);
            orderParams.type=OP_SELL;
            openOrder(orderParams);
      }      
    } 
    else if(OrdersTotal()==1&&isNearTP()){
        printf("Order was closed, because it was near TP");
        closeAllOrders();
    } 
            
 }
 
  bool isNearTP(){
     if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)){
            if(shared.isPriceNear(OrderTakeProfit())){             
             return true;
            }else{
               return false;
               printf("BUG: OrderCloseToTP");
            }
      }
      return false;
  }
   ChannelParams channelParams;
   void updateChannelParams(){
   
      double pr1=ObjectGetDouble(0,flatName,OBJPROP_PRICE,0);
      double pr2=ObjectGetDouble(0,flatName,OBJPROP_PRICE,1);
      double pr3=ObjectGetDouble(0,flatName,OBJPROP_PRICE,2);
      
      double t1=ObjectGet(flatName,OBJPROP_TIME1);
      double t2=ObjectGet(flatName,OBJPROP_TIME2);
      double t3=ObjectGet(flatName,OBJPROP_TIME3);
      
      if(pr1!=pr2){
         moveChannel(pr1,t2);
      }
      
//      ENUM_LINE_STYLE lineStyle=ObjectGet(flatName,OBJPROP_STYLE);
//      if(lineStyle==STYLE_SOLID){
//         
//      }

      if((t2-t1)!=0){
         double flatA=(pr2-pr1)/(t2-t1);
         channelParams.low=(pr2-flatA*t2);
         channelParams.high=(pr3-flatA*t3);
         channelParams.height=MathAbs(pr1-pr3)*KOEF;
         channelParams.isValid=true;
      }else{
         channelParams.isValid=false;
         channelParams.low=0;
         channelParams.high=0;
         channelParams.height=0;
      }
   }
 
   void moveChannel(double newPrice2, double t2){ 
     if(!ObjectMove(flatName,1,t2,newPrice2)) 
     { 
         Print(__FUNCTION__, 
            ": failed to move CHANNEL point! Error code = ",GetLastError()); 
     }else{
         ChartRedraw(0);
     } 
      
   }
 
 
 void setNonLoss(){
    if(OrderSelect(0,SELECT_BY_POS)){      
      OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),OrderExpiration(),Yellow);
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

 void openOrder(OrderParams &order){
 
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