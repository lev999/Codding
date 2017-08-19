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
 
 public:

   Shared(){
   
   }

   double getBarBody(int i){
      double barBody=MathAbs(iOpen(NULL,0,i)-iClose(NULL,0,i))*getKoef();
      printf("body:"+barBody);
      return barBody;
   }
   
   int getKoef(){
      int koefLocal=1; 
      for (int i=1;i<Digits;i=i+1){
         koefLocal=koefLocal*10;
      }
      return koefLocal;
  }


};