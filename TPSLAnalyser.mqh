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



class TPSLAnalyser{
 
 Shared2 *shared;
 
 public:   
   TPSLAnalyser(double defaultSL_,double defaultTP_, Shared2* &shared_){
      shared=shared_;
      defaultTPSL.SL=defaultSL_;
      defaultTPSL.TP=defaultTP_;
     
   }
   
  TPSL getTPSL(int orderTicket_, double targetPrice_){     
      forceAnalyse(orderTicket_,targetPrice_);
      return currentTPSL;
   }
   
   void forceAnalyse(int orderTicket_, double targetPrice_){ 
      orderTicket=orderTicket_;
      targetPrice=targetPrice_;  
      updateCurrentTPSL();
   }
   
 private:
 
 TPSL currentTPSL;
 TPSL defaultTPSL;
 int orderTicket;
 double targetPrice;
 
 void updateCurrentTPSL(){
 
   if(selectOrder()){
      analyse();
   
   }else{
      printf("Error! TPSLAnalyser: order was not found by ticket:"+orderTicket);
   }   
 }
 
 void analyse(){
   int openShift=iBarShift(NULL,0,OrderOpenTime(),true); 
   //int closeShift=iBarShift(NULL,0,OrderCloseTime(),true); 
   
   printf("openShift:"+openShift+" closeShift:"+closeShift);
   
   highestPeakPrice=iHigh(NULL,0,iHighest(NULL,0,MODE_HIGH,openShift,0));
   lowestPeakPrice=iLow(NULL,0,iLowest(NULL,0,MODE_LOW,openShift,0)); 
   
   if(OrderType()==OP_BUY){                       
      
   }else{
             
   }

 }
 
 
 bool selectOrder(){
    if(OrderSelect(orderTicket, SELECT_BY_TICKET,MODE_HISTORY )){      
      return true;     
     }else{
      return false;
     }
 }
 
};