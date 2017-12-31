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
#include <Logger.mqh>

 const string NAME="RegressionChannel"; 

class TrendDetector{
 
 int WORK_PERIOD;
 int currentBar;
 
 public:   
   TrendDetector(int WORK_PERIOD_local){
      WORK_PERIOD=WORK_PERIOD_local;
      isNewBar();
   }
   
   int getOrderType(){
      ObjectDelete(0,NAME);         
      return type;
   }
   
   void update(){
      if(isNewBar()){
         setOrderType();        
         ObjectDelete(0,NAME); 
         createChannel();
      } 
   }
   
 private:
 
 int type;
 
 void createChannel(){
 
    datetime currTime=TimeCurrent();
    datetime time2=Time[WORK_PERIOD]; 
      
   if(!ObjectCreate(0,NAME,OBJ_REGRESSION,0,currTime,0,time2,0)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create linear regression channel! Error code = ",GetLastError()); 
     }
     ObjectSetInteger(0,NAME,OBJPROP_COLOR, C'37,37,37');
     ChartRedraw();  
 
 }

 void setOrderType(){ 
   double priceEnd=ObjectGetValueByTime(0,NAME,Time[1],0);
   double priceStart=ObjectGetValueByTime(0,NAME,Time[WORK_PERIOD],0);
           
    if(priceStart<priceEnd){
     type=OP_BUY;
    }
    else{
     type=OP_SELL;
    }
 }
  
 bool isNewBar(){
      int bar=iBars(NULL,PERIOD_CURRENT);
      if(currentBar!=bar){
         currentBar=bar;
         return true;
      }else{
         return false;
      }
  }
 
};