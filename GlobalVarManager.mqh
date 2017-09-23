//+------------------------------------------------------------------+
//|                                                      Include.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <Shared.mqh>; 



class GlobalVarManager{
   Pattern pattern;
   string   pattern_sl_name;
   string   pattern_tp_name;
   string   pattern_bodyWorkLimit_name;
   string   pattern_orderTimeOut_name;
   string   pattern_blockTrading_name;
   string   pattern_historyDepth_name;
   string   pattern_SlTpLimit_name;

  public:

   GlobalVarManager(){
      pattern_sl_name="pattern_sl";
      pattern_tp_name="pattern_tp";
      pattern_bodyWorkLimit_name="pattern_bodyWorkLimit";
      pattern_orderTimeOut_name="pattern_orderTimeOut"; 
      pattern_blockTrading_name = "pattern_blockTrading" ; 
      pattern_historyDepth_name = "pattern_historyDepth" ; 
      pattern_SlTpLimit_name = "pattern_SlTpLimit" ; 
   }

   Pattern getPattern(){
      pattern.sl=GlobalVariableGet(pattern_sl_name);
      pattern.tp=GlobalVariableGet(pattern_tp_name);
      pattern.bodyWorkLimit=GlobalVariableGet(pattern_bodyWorkLimit_name);
      pattern.orderTimeOut=GlobalVariableGet(pattern_orderTimeOut_name);
      pattern.blockTrading=GlobalVariableGet(pattern_blockTrading_name);
      pattern.history_depth=GlobalVariableGet(pattern_historyDepth_name);
      pattern.sl_tp_limit=GlobalVariableGet(pattern_SlTpLimit_name);
      return pattern;
   }
   
   void updateSlTp(double sl, double tp){
      GlobalVariableSet(pattern_sl_name,sl);
      GlobalVariableSet(pattern_tp_name,tp);  
   }
   
   void unBlockTrading(){
      GlobalVariableSet(pattern_blockTrading_name,0);
   }
  void blockTrading(){
      GlobalVariableSet(pattern_blockTrading_name,1);
   }
   
   void publishPattern(double pattern_tp,double pattern_sl, double pattern_bodyWorkLimit,double orderTimeOut, double blockTrading,double historyDepth, double sl_tp_limit){
   
      GlobalVariableSet(pattern_sl_name,pattern_sl);
      GlobalVariableSet(pattern_tp_name,pattern_tp);
      GlobalVariableSet(pattern_bodyWorkLimit_name,pattern_bodyWorkLimit);
      GlobalVariableSet(pattern_orderTimeOut_name,orderTimeOut);
      GlobalVariableSet(pattern_blockTrading_name,blockTrading);
      GlobalVariableSet(pattern_historyDepth_name,historyDepth);
      GlobalVariableSet(pattern_SlTpLimit_name,sl_tp_limit);
      
      //printf("PUBLISHED NEW PATTERN:" +"sl="+pattern_sl+",tp="+pattern_tp+",bodyWorkLimi="+pattern_bodyWorkLimit+",orderTimeOut="+orderTimeOut);
   }

};