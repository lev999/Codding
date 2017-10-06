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
  double    KOEF,SPREAD;
  
 void setKoef(){
  int koefLocal=1; 
   for (int i=1;i<Digits;i=i+1){
      koefLocal=koefLocal*10;
   }
   KOEF=koefLocal;
  }
 public:
   
   Shared2(double spread){         
      isNewBar_name="isNewBar";
      setKoef();
      SPREAD=spread;
   }
   
   bool isOrderValid(double tp,double sl,double limit){
      if(MathAbs(tp)<=limit||MathAbs(sl)<=limit){
         //printf("Order SL or TP is less then limit ("+TP_SL_Limit+" pips) ==> order canceled");
         return false;
      }
      else  return true;
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

};