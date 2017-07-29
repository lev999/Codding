
input bool    UpBorder=true;
input bool    LowBorder=true;
input double  MaxLossDollar=50;


const int         delayCounterLimit=1;
const string      channelName="Channel";
const int         timeFrame=PERIOD_H4;


void OnChartEvent(const int id,  const long& lparam, const double& dparam,   const string& sparam ){
 
   if(sparam==channelName){
      worker.updateChannelParams();
   }
}



double OnTester()
{
   if (TesterStatistics(STAT_EQUITY_DD)>0){  
      return  NormalizeDouble(TesterStatistics(STAT_PROFIT) / TesterStatistics(STAT_EQUITY_DD),2);
   }else{
      return 0;
   }
}
    
void OnTick() 
  { 
      worker.onTick();         
  } 
  
class Channel 
  { 
  
 public:
    
   Channel() {        
        printf("Channel, start working!");
        init();
       } 
       
  void updateChannelParams(){
 
   double pr1=ObjectGetDouble(0,channelName,OBJPROP_PRICE,0);
   double pr2=ObjectGetDouble(0,channelName,OBJPROP_PRICE,1);
   double pr3=ObjectGetDouble(0,channelName,OBJPROP_PRICE,2);
   
   datetime t1=ObjectGet(channelName,OBJPROP_TIME1);
   datetime t2=ObjectGet(channelName,OBJPROP_TIME2);
   datetime t3=ObjectGet(channelName,OBJPROP_TIME3);
   
   if((t2-t1)!=0){
      channelA=(pr2-pr1)/(t2-t1);
   }
   
   b_lowBorder=(pr2-channelA*t2);
   b_highBorder=(pr3-channelA*t3);
   lossPips=MathAbs(pr1-pr3)*KOEF;
   
 //  if(Bid>channelA*TimeCurrent()+b_highBorder){
 //     printf("apper than H_border"); 
 //  }  
   
//   if(Bid>channelA*TimeCurrent()+b_lowBorder){
 //     printf("apper than L_border"); 
//   }  
 //  if(Bid<channelA*TimeCurrent()+b_highBorder){
//      printf("lower than H_border"); 
//   }  
   
 //  if(Bid<channelA*TimeCurrent()+b_lowBorder){
//      printf("lower than L_border"); 
//   }
}      
 bool isTradeAlowded(){
   datetime t1=ObjectGet(channelName,OBJPROP_TIME1);
   datetime t3=ObjectGet(channelName,OBJPROP_TIME3);

   if(t1!=t3){
      
      return false;
   }
   else{
      return true;
   }
     
 }
 
 void onTick(){
 
    //---for testing
    updateChannelParams();
    //---
    ticksDelay=ticksDelay+1;
    if(ticksDelay<5){
      return;
    }
    plotIMA();
    
    if(!isTradeAlowded()){
      lastOrderType=-10;
      return;
    }
 
      bool haveOpenedOrders=(OrdersTotal()>0);
      if(!haveOpenedOrders){
         if(Bid>getUpperBorderPrice()&& UpBorder){// && lastOrderType!=OP_SELL){
            openedOrderType=OP_SELL;
            lastOrderType=OP_SELL;            
            sendOrder(openedOrderType);
         }
         if(Ask<getLowerBorderPrice()&&LowBorder){// && lastOrderType!=OP_BUY){
            openedOrderType=OP_BUY;
            lastOrderType=OP_BUY;
            sendOrder(openedOrderType);
         }
         
      }else{
            if(doesBorderCrossed(openedOrderType)){
               closeAllOrders();
               openedOrderType=0;               
            }      
      }
      
 }
   


 private:
        
         int KOEF;
         double b_lowBorder;
         double b_highBorder;
         double channelA;
         int openedOrderType;
         int lastOrderType;
         int currentBar;
         double  lossPips;
         int ticksDelay;


  void init(){
      ticksDelay=0;
      openedOrderType=0;
      KOEF=getKoef();
      updateChannelParams();
      lastOrderType=-10;      
      currentBar=iBars(NULL,timeFrame);      
  }
 
 bool doesBorderCrossed(double orderType){
 
   if(orderType==OP_BUY&&Bid>getUpperBorderPrice()){
      printf("price crossed upper border");
      return true;
   }
   if(orderType==OP_SELL&&Ask<getLowerBorderPrice()){
       printf("price crossed lower border");
       return true;
   }
   return false;
 }
  
  double getChannelHeight(){
   return MathAbs(b_highBorder-b_lowBorder)*KOEF;
  }
  
  double getUpperBorderPrice(){
      return channelA*TimeCurrent()+b_highBorder;
  }
  double getLowerBorderPrice(){
      return channelA*TimeCurrent()+b_lowBorder;
  }
 
  int getKoef(){
      int koefLocal=1; 
      for (int i=1;i<Digits;i=i+1){
         koefLocal=koefLocal*10;
      }
      return koefLocal;
  }
  
 
  double getSpread(){
      return NormalizeDouble(MathAbs(Ask-Bid),Digits);
  }
  
  void closeAllOrders(){
      ticksDelay=-1;
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
  
   if(OrderType()==OP_BUY){
      int ticket=OrderClose(OrderTicket(),OrderLots(),Bid,100,Red);
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
 
 void sendOrder(int orderType){
      int ticket=0;
 
      double    tp;//=getTP(trendValue);
      double    sl;//=getSL(trendValue);
      double    volume;//=getLot(sl,trendValue; 
      color    colorOrder;   

     if (orderType==OP_BUY){ //buy       
            sl=NormalizeDouble(Ask-lossPips/KOEF,Digits); 
            volume=getLot(sl,orderType);
            tp=0;
            colorOrder=Blue;      
        }else{//sell-
            sl=NormalizeDouble(Bid+lossPips/KOEF,Digits); 
            volume=getLot(sl,orderType);
            tp=0;   
            colorOrder=Red;
      }
      ticket=OrderSend(Symbol(),orderType,volume,Bid,300,sl,tp,"My order",99998,0,colorOrder); 
      alertResult(ticket,tp,sl,volume);
  } 
  
  void alertResult(int ticket,double tp, double sl,double volume){      
        if(ticket<0) 
      { 
         Print("Order open failed with error #",GetLastError(),", profit:",tp,", loss:",sl,", Lot:"+volume); 
      } 
      else 
      {
         Print("OrderSend placed successfully"); 
      }
  }
  
  
  double nDiff;
  void summDiff(double diff){
      if(diff>0&&nDiff>=0){
         nDiff=nDiff+1;
         
      }
      else if(diff<0&&nDiff<=0){
         nDiff=nDiff-1;
         
      }
      else{
         nDiff=0;
      }  
      
  }
  
  double prevValue;
  double prevDiff;
  void plotIMA(){
      
      if(isNewBar()){
         double value; 
         value=iMA(NULL,PERIOD_CURRENT,2,0,MODE_SMA,PRICE_MEDIAN,1);
         double diff=(value-prevValue)*KOEF;
         diff= NormalizeDouble(diff,1);
         
         
         printf("diff:"+diff+" prevDiff:"+prevDiff +" ndiff:"+nDiff );
         
         summDiff(diff);
         prevValue=value;
         prevDiff=diff;
      }
  }
  
  void createStar(datetime time, double price, bool isUp){
      string name=time;      
      int code;
      double shiftKoef=0.0005;
      printf("star:"+name);
      
      if(isUp){
         price=price+shiftKoef;
         code=72;
      }else{
         price=price-shiftKoef;
         code=71;
      }
      
      ObjectCreate(name,OBJ_ARROW, 0, time, price);
      ObjectSet(name, OBJPROP_COLOR, Red);
      ObjectSet(name, OBJPROP_ARROWCODE,code); 

  }
  
  bool isNewBar(){
      int bar=iBars(NULL,PERIOD_CURRENT);
      if(currentBar!=bar){
         currentBar=bar;
         return true;
      }else{
         return false;
      }
  }
  
};

Channel worker; 
