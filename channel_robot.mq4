#include <Shared2.mqh>
#include <ChannelManager.mqh>

input double  MaxLossDollar=50;
input int     MIN_WORKING_CHANNEL=10; 
const double  SPREAD=2;
//+------------------------------------------------------------------+
//|                  SET SPREAD FOR TESTING to 0                                                |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|   startOneHourDelay  is valid only for 1 hour period                           |
//+------------------------------------------------------------------+



struct OrderParams{
   double sl_pips,tp_pips;
   int type;
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
 void onTick(){               
 
      if(isOneHourDelayActive()){return;}
      
      if(!channelManager.existsValidChannel()){return;}  
      else{
          ChannelParams channelParams=channelManager.getChannelParams();          
          if(OrdersTotal()!=0){
             if(currentChannelId!=channelParams.id){               
               closeAllOrders();
               printf("Order was closed, because new channel created! New order can be opened after 1 hour");
               startDelayHour=Hour();         
             }
          }else{          
            currentChannelId=channelParams.id;
            double h=channelParams.height;
            OrderParams orderParams;             
            orderParams.sl_pips=getSL(h);
            orderParams.tp_pips=getTP(h);
            
            if(shared.isPriceNear(channelParams.low)){
               orderParams.type=OP_BUY;   
               openOrder(orderParams);         
            }else if(shared.isPriceNear(channelParams.high)){
               orderParams.type=OP_SELL;
               openOrder(orderParams);                 
            }
          }  
      }        
 }
 
 double getSL(double height){
   if(height>=MIN_WORKING_CHANNEL*1.5){
      return height*0.5;
   }else{
      return height+SPREAD;
   }
 }
 
  double getTP(double height){
   if(height>=MIN_WORKING_CHANNEL*1.5){
      return height*0.75;
   }else{
      return height+SPREAD;
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