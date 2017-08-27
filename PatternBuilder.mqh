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
   double bodyWorkLimit; 
   double orderTimeOut; 
   double blockTrading; 
};

class PatternBuilder{
   Pattern pattern;
   string   pattern_sl_name;
   string   pattern_tp_name;
   string   pattern_bodyWorkLimit_name;
   string   pattern_orderTimeOut_name;
   string   pattern_blockTrading_name;
   string   isNewBar_name;
 public:

   PatternBuilder(){
      pattern_sl_name="pattern_sl";
      pattern_tp_name="pattern_tp";
      pattern_bodyWorkLimit_name="pattern_bodyWorkLimit";
      isNewBar_name="isNewBar";
      pattern_orderTimeOut_name="pattern_orderTimeOut"; 
      pattern_blockTrading_name = "pattern_blockTrading_name" ; 
   }

   Pattern getPattern(){
      pattern.sl=GlobalVariableGet(pattern_sl_name);
      pattern.tp=GlobalVariableGet(pattern_tp_name);
      pattern.bodyWorkLimit=GlobalVariableGet(pattern_bodyWorkLimit_name);
      pattern.orderTimeOut=GlobalVariableGet(pattern_orderTimeOut_name);
      pattern.blockTrading=GlobalVariableGet(pattern_blockTrading_name);
      return pattern;
   }
   
   void publishPattern(double pattern_tp,double pattern_sl, double pattern_bodyWorkLimit,double orderTimeOut, double blockTrading){
   
      GlobalVariableSet(pattern_sl_name,pattern_sl);
      GlobalVariableSet(pattern_tp_name,pattern_tp);
      GlobalVariableSet(pattern_bodyWorkLimit_name,pattern_bodyWorkLimit);
      GlobalVariableSet(pattern_orderTimeOut_name,orderTimeOut);
      GlobalVariableSet(pattern_blockTrading_name,blockTrading);
      
      //printf("PUBLISHED NEW PATTERN:" +"sl="+pattern_sl+",tp="+pattern_tp+",bodyWorkLimi="+pattern_bodyWorkLimit+",orderTimeOut="+orderTimeOut);
   }


   bool isNewBar(){
   
         if( GlobalVariableGet(isNewBar_name)==0){
            return false;
         }else{
            return true;
         }
   }
   void setIsNewBar(double value){
         GlobalVariableSet(isNewBar_name,value);
   }


};