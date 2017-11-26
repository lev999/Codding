//+------------------------------------------------------------------+
//|                                                      Include.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <Shared2.mqh>


class MinMaxTracker{
 
 double minLevel;
 double maxLevel;
 
 public:   
   MinMaxTracker(){
      minLevel=100;
      maxLevel=0;
   }
   
   void update(){   
      if(minLevel>Bid){
         minLevel=Bid;
      }
      if(maxLevel<Bid){
         maxLevel=Bid;
      }
   }
   
   void reset(){
      minLevel=100;
      maxLevel=0;   
   }
   
   double getMinLevel(){   
      return minLevel;
   }
   
   double getMaxLevel(){   
      return maxLevel;
   }
      
 private:
 
 
};