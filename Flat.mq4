
input double  MaxLossDollar=50;
input bool  SELL_ALLOWED=true;
input bool  BUY_ALLOWED=true;
// NOT WORKING FOR CHANNELS with ANGLE 

const int         delayCounterLimit=1;
const string      flatName="Flat";
const int         timeFrame=PERIOD_H4;
const int         TICK_DELAY_TEST_MODE=0;

void OnChartEvent(const int id,  const long& lparam, const double& dparam,   const string& sparam ){
 
   if(sparam==flatName){
      worker.updateChannelParams();
   }
}

void OnTick() 
  { 
      worker.onTick();         
  } 
  
class Flat 
  { 
  
 public:
    
   Flat() {        
        printf("Flat, start working!");
        init();
       } 
       
       
 

  void moveChannel(double newPrice2, datetime t2){ 
     if(!ObjectMove(flatName,1,t2,newPrice2)) 
     { 
         Print(__FUNCTION__, 
            ": failed to move CHANNEL point! Error code = ",GetLastError()); 
     }else{
         ChartRedraw(0);
     } 
      
 }
  void updateChannelParams(){
 
   double pr1=ObjectGetDouble(0,flatName,OBJPROP_PRICE,0);
   double pr2=ObjectGetDouble(0,flatName,OBJPROP_PRICE,1);
   double pr3=ObjectGetDouble(0,flatName,OBJPROP_PRICE,2);
   
   datetime t1=ObjectGet(flatName,OBJPROP_TIME1);
   datetime t2=ObjectGet(flatName,OBJPROP_TIME2);
   datetime t3=ObjectGet(flatName,OBJPROP_TIME3);
   
   if(pr1!=pr2){
      moveChannel(pr1,t2);
   }
   
   ENUM_LINE_STYLE lineStyle=ObjectGet(flatName,OBJPROP_STYLE);
   if(lineStyle==STYLE_SOLID){
      isTrendMode=true;
   }else{
      isTrendMode=false;
    }
   
    
   
   if((t2-t1)!=0){
      flatA=(pr2-pr1)/(t2-t1);
      b_lowBorder=(pr2-flatA*t2);
      b_highBorder=(pr3-flatA*t3);
      lossPips=MathAbs(pr1-pr3)*KOEF;
   }else{
      flatA=0;
      b_lowBorder=0;
      b_highBorder=0;
      lossPips=0;
   }
   
   
 //  if(Bid>flatA*TimeCurrent()+b_highBorder){
 //     printf("apper than H_border"); 
 //  }  
   
//   if(Bid>flatA*TimeCurrent()+b_lowBorder){
 //     printf("apper than L_border"); 
//   }  
 //  if(Bid<flatA*TimeCurrent()+b_highBorder){
//      printf("lower than H_border"); 
//   }  
   
 //  if(Bid<flatA*TimeCurrent()+b_lowBorder){
//      printf("lower than L_border"); 
//   }
}      
 bool isTradeAlowded(){

   datetime t1=ObjectGet(flatName,OBJPROP_TIME1);
   datetime t3=ObjectGet(flatName,OBJPROP_TIME3);
   
   double pr1=ObjectGet(flatName,OBJPROP_PRICE1);
   double pr3=ObjectGet(flatName,OBJPROP_PRICE3);
   
   if(t1!=t3||t1==0||pr1>=pr3){
      if(t1==0){
         printf("Trade is disabled! Object with name "+flatName+" was not found");
      }        
      return false;
   }

   if(didLastOrderGetMinus()) {
      printf("Trade is disabled! Last order was closed with minus");
      globalTradeBlock=true;
      printf("Please,reload advisor");
      return false;
  
   }
   return true;     
 }
 
 bool didLastOrderGetMinus(){
   int i=OrdersHistoryTotal()-1;
   if(OrderSelect(i, SELECT_BY_POS,MODE_HISTORY)){
      if(OrderProfit()<0&&(OrderMagicNumber()==lastOrderMagicNumber)){
         return true;
      }
      else{
         return false;
      }
   }   
   else{
     // printf("Error!!! FAILED to take order from history:"+GetLastError());
      return false;
   }
 }


 void onTick(){
 
   if(IsTesting()){
      //---for testing
        updateChannelParams();  
        if(getUpperBorderPrice()<getLowerBorderPrice()){
         closeAllOrders();
        }      
        if(globalTradeBlock&&unBlockTestTimer<TICK_DELAY_TEST_MODE){
            unBlockTestTimer=unBlockTestTimer+1;
            return;
        }else{
            if(unBlockTestTimer==TICK_DELAY_TEST_MODE){
              init();               
            }               
            if(!isTradeAlowded()){
               lastOrderType=-10;
               return;
            }           
        }                   
   }else{
      //--for production   
      if(globalTradeBlock){
         printf("Please,reload advisor");
         return;
      }
       
      if(!isTradeAlowded()){
         lastOrderType=-10;
         return;
      }
   }
   
     
   if(OrdersTotal()==0){
     evaluateNewOrder();        
   }else if(isTrendModeAllowed()){
     evaluateNewOrder();
   }
    
     
 }
 
 
double lowChannelPrice_TREND_MODE;
double upChannelPrice_TREND_MODE;
 bool isTrendModeAllowed(){
    if(!isTrendMode){
      return false;
    }
    if(lowChannelPrice_TREND_MODE==getLowerBorderPrice()&&upChannelPrice_TREND_MODE==getUpperBorderPrice()){
      return false;
    }
    
    return true;
 }
 
 void  evaluateNewOrder(){
      int openedOrderType;
      if(Bid>getUpperBorderPrice()&&SELL_ALLOWED){
         openedOrderType=OP_SELL;
         lastOrderType=OP_SELL;            
         sendOrder(openedOrderType);
      }
      if(Ask<getLowerBorderPrice()&&BUY_ALLOWED){
         openedOrderType=OP_BUY;
         lastOrderType=OP_BUY;
         sendOrder(openedOrderType);
      }
      if(isTrendMode){
         lowChannelPrice_TREND_MODE=getLowerBorderPrice();
         upChannelPrice_TREND_MODE=getUpperBorderPrice();      
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
 
   
 private:        
         int KOEF;
         double b_lowBorder;
         double b_highBorder;
         double flatA;
         
         int     lastOrderType;
         int     currentBar;
         double  lossPips;
         int     lastOrderMagicNumber;
         bool    globalTradeBlock; 
         int     unBlockTestTimer;
         bool    isTrendMode;
         
   void init(){
      KOEF=getKoef();
      updateChannelParams();
      lastOrderType=-10;      
      currentBar=iBars(NULL,timeFrame); 
      globalTradeBlock=false;
      printf("Global trade is activated!");
      unBlockTestTimer=0;
      lastOrderMagicNumber=-9999;
          
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
      return flatA*TimeCurrent()+b_highBorder;
  }
  double getLowerBorderPrice(){
      return flatA*TimeCurrent()+b_lowBorder;
  }
 
  int getKoef(){
      int koefLocal=1; 
      for (int i=1;i<Digits;i=i+1){
         koefLocal=koefLocal*10;
      }
      return koefLocal;
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
      int      ticket=0; 
      double   tp;
      double   sl;
      double   volume;
      color    colorOrder;   
      
      lastOrderMagicNumber=getMagicNumber();  
    
      
     if (orderType==OP_BUY){ //buy       
            //sl=NormalizeDouble(Ask-lossPips/KOEF,Digits);             
            sl=NormalizeDouble(Ask-getHeightPips()/KOEF,Digits);
            if(isTrendMode){
               tp=0;
            }else{
               tp=NormalizeDouble(Bid+getHeightPips()/KOEF,Digits);
            }
            
            volume=getLot(sl,orderType);
            colorOrder=Blue;            
             
     }else{//sell-
            //sl=NormalizeDouble(Bid+lossPips/KOEF,Digits); 
            sl=NormalizeDouble(Bid+getHeightPips()/KOEF,Digits);
            if(isTrendMode){
               tp=0;
            }else{
               tp=NormalizeDouble(Ask-getHeightPips()/KOEF,Digits);
            }
            
            
            volume=getLot(sl,orderType);
            colorOrder=Red;
     }
      ticket=OrderSend(Symbol(),orderType,volume,Bid,300,sl,tp,"My order",lastOrderMagicNumber,0,colorOrder); 
      alertResult(ticket,tp,sl,volume);
   } 
  
  
   double getHeightPips(){
    return lossPips;
   }
  

   int getMagicNumber(){
      int num = 1 + 1000*MathRand()/32768;
      printf("magic:"+num);
      return num;
   
   }

  void alertResult(int ticket,double tp, double sl,double volume){      
        if(ticket<0) 
      { 
         Print("Order open failed with error #",GetLastError(),", price:",Bid,", TP:",tp,", SL:",sl,", Lot:"+volume); 
      } 
      else 
      {
         Print("OrderSend placed successfully"); 
      }
  }
  
};

Flat worker; 
