
input double  MaxLossDollar=50;

const int         timeFrame=PERIOD_H4;

 
  
class Trend_robot { 
  
 public:
   
   int KOEF;         
   int lastOrderMagicNumber;
 
 Trend_robot() {        
      KOEF=getKoef();   
      lastOrderMagicNumber=-9999;          
 } 
   
 void onTick(){      
      if(OrdersTotal()==0){
        evaluateNewOrder();        
      }else {
        evaluateNewOrder();
      }
 }
 
 void evaluateNewOrder(){
   printf("Hi ");
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
            tp=NormalizeDouble(Bid+getHeightPips()/KOEF,Digits);
            
            volume=getLot(sl,orderType);
            colorOrder=Blue;            
             
     }else{//sell-
            //sl=NormalizeDouble(Bid+lossPips/KOEF,Digits); 
            sl=NormalizeDouble(Bid+getHeightPips()/KOEF,Digits);
            tp=NormalizeDouble(Ask-getHeightPips()/KOEF,Digits);
 
            volume=getLot(sl,orderType);
            colorOrder=Red;
     }
      ticket=OrderSend(Symbol(),orderType,volume,Bid,300,sl,tp,"My order",lastOrderMagicNumber,0,colorOrder); 
      alertResult(ticket,tp,sl,volume);
   } 
  
  
 double getHeightPips(){
   return 0;
 }  

 int getMagicNumber(){
   int num = 1 + 1000*MathRand()/32768;
   printf("magic:"+num);
   return num;   
 }

 void alertResult(int ticket,double tp, double sl,double volume){      
   if(ticket<0) { 
      Print("Order open failed with error #",GetLastError(),", price:",Bid,", TP:",tp,", SL:",sl,", Lot:"+volume); 
   } 
   else{
      Print("OrderSend placed successfully"); 
   }
 }
  
};

Trend_robot worker; 
 void OnTick() { 
   worker.onTick();         
 }