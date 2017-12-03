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


class TargetLevelBreakManager{
 
 public:    
   TargetLevelBreakManager(Shared2* &shared_){
    shared=shared_;
    targetBreakShift=-1;
   }
   
   
 bool isFirstTrade(){
   if(targetBreakShift==-1){
      return true;
   }else{
      return false;
   }
 
 }
 void updateTargetBreakShift(){
    targetBreakShift=getNewTargetBreakShift();
 }
 
 void resetTargetBreakShift(int currentOrderTicket_){ 
   currentOrderTicket=currentOrderTicket_;
   targetBreakShift=0; 
 }
 
 bool isOneBarDelayActive(){//1 BAR delay after end of targetBreak!
   if(targetBreakShift==getNewTargetBreakShift()){
      return true;
   }else{   
      return false;
   }   
 } 
 
 int wasTargetLevelReached(){
      if(targetBreakShift==0){
         return false;
      }else{
         return true;
      }
 }
   
 private:
   int targetBreakShift;   
   Shared2 *shared;
    int currentOrderTicket;
    
 int getNewTargetBreakShift(){
    if(!shared.selectLastOrder(currentOrderTicket)){
         printf("BUG(updateTargetBreakShift):Failed to select order by ticket.CurrentOrderTicket:"+DoubleToStr(currentOrderTicket));
     
      }
   return iBarShift(NULL,0,OrderOpenTime(),true);
 }
 
};