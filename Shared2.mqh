//+------------------------------------------------------------------+
//|                                                      Include.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

struct Pattern{
   double sl;
   double tp;
   double history_depth;
   double sl_tp_limit;
   double orderTimeOut; 
   double blockTrading; 
   double spread; 
};

class Shared2{
 
  string    isNewBar_name;
  double    tp_sl_limit_local;
  double    KOEF,SPREAD,MAX_LOSS_DOLLARS;
  
 void setKoef(){
  int koefLocal=1; 
   for (int i=1;i<Digits;i=i+1){
      koefLocal=koefLocal*10;
   }
   KOEF=koefLocal;
  }
 public:
   
   Shared2(double spread,double max_loss_dollars){         
      isNewBar_name="isNewBar";
      setKoef();
      SPREAD=spread;
      MAX_LOSS_DOLLARS=max_loss_dollars;
   }
   
   bool isOrderValid(double tp,double sl,double limit){
      if(MathAbs(tp)<=limit||MathAbs(sl)<=limit){
         //printf("Order SL or TP is less then limit ("+TP_SL_Limit+" pips) ==> order canceled");
         return false;
      }
      else  return true;
   }
   
    int getMagicNumber(){
      int num = 1 + 1000*MathRand()/32768;
      printf("magic:"+DoubleToStr(num));
      return num;
   
   }
    bool isPriceNear(double border){
      return(isPriceNear(Bid,border));
   }   
   
    bool isPriceNear(double pr1,double pr2){
       if(MathAbs((pr1-pr2))*KOEF<SPREAD){
         return true;
       }else{
         return false;
       }  
   }   
   
   double getKoef(){
      return KOEF;
  }

   bool isNewBar(){
   
         if( GlobalVariableGet(isNewBar_name)==0){
            return false;
         }else{
            return true;
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
      double lot=NormalizeDouble(MAX_LOSS_DOLLARS/(10*pips), 2);
      
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
   
   
   
   

};