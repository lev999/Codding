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


struct Level{
   int id;
   double price;
   datetime time;
};

class ResistanceLevelManager{
 
 double MIN_WORKING_CHANNEL;
 bool hasValidChannel;
 Shared2 *shared;
  int INITIAL_SHIFT;
  int MA_PERIOD;
 int currentBar;
 
 public:   
   ResistanceLevelManager(double MIN_WORKING_CHANNEL_local,Shared2* &shared_){
      shared=shared_;
      MIN_WORKING_CHANNEL=MIN_WORKING_CHANNEL_local;
      isNewBar();
      INITIAL_SHIFT=1;
      MA_PERIOD=3;
   }
   
   bool isBidCloseToLevel(){
      if(isNewBar()){
            updatePeaks();      
         }         
      return isPriceCloseToOneOfLevels();
   }
      
   double getSimetricLevelPrice(){   
      double targetPrice=getSimetricLevelPrice(activeLevel);
      return targetPrice;
   }
  
  

    
 private:
 
    void updatePeaks(){
    
    }
   
   Level activeLevel;
   bool isPriceCloseToOneOfLevels(){
      return true;
   }
   
   
   double getSimetricLevelPrice(Level &level){
   
      return 0;
   }

  int getMagicNumber(){
      int num = 1 + 1000*MathRand()/32768;
      return num;   
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