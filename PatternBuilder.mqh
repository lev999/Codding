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
   double lot; 
};

class PatternBuilder{
Pattern pattern;
public:

   PatternBuilder(){}

   Pattern getPattern(){
   
   
   return pattern;
   }


};