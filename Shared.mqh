//+------------------------------------------------------------------+
//|                                                      Include.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

class Shared{
 
  string   isNewBar_name;
 public:

   Shared(){   
      isNewBar_name="isNewBar";
   }

   double getBarBody(int i){
      double barBody=MathAbs(iOpen(NULL,0,i)-iClose(NULL,0,i))*getKoef();
      return barBody;
   }
   
   int getKoef(){
      int koefLocal=1; 
      for (int i=1;i<Digits;i=i+1){
         koefLocal=koefLocal*10;
      }
      return koefLocal;
  }

   bool isNewBar(){
   
         if( GlobalVariableGet(isNewBar_name)==0){
            return false;
         }else{
            return true;
         }
   }
   void setIsNewBarTrue(){
         GlobalVariableSet(isNewBar_name,1);
   }
  void setIsNewBarFalse(){
         GlobalVariableSet(isNewBar_name,0);
   }


};