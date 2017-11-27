//+------------------------------------------------------------------+
//|                                                      Include.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


class Logger{
 
 public:   
   Logger(bool isDebugMode_){
      isDebugMode=isDebugMode_;
   }
   
   void printf(string str){   
      if(isDebugMode){
         printf(str);      
      }   
   }
      
 private:
 bool isDebugMode;
 
};