//+------------------------------------------------------------------+
//|                                                      Include.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

struct TPSL{
   double SL;
   double TP;      
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
  bool isPriceNear(double pr1,double pr2){
    if(MathAbs((pr1-pr2))*KOEF<SPREAD){
      return true;
    }else{
      return false;
    }  
 } 
 public:
   
 Shared2(double max_loss_dollars){         
   isNewBar_name="isNewBar";
   setKoef();
   SPREAD=(Ask-Bid)*KOEF;
   MAX_LOSS_DOLLARS=max_loss_dollars;
 }
      
 int getMagicNumber(){
   int num = 1 + 1000*MathRand()/32768;
   return num;

 }
 
 bool isPriceNear(double border){
   return(isPriceNear(Bid,border));
 }   
   
 double getKoef(){
      return KOEF;  
 }
        
 double getLot(double H_pips ){      
      double lot=NormalizeDouble(MAX_LOSS_DOLLARS/(H_pips*KOEF*10), 4);
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