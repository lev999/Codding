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


struct Peak{
   double price;
   datetime time;
   double oppositePrice;
};

class ResistanceLevelManager{
 
 double MIN_WORKING_CHANNEL;
 int SEARCH_HISTORY_PERIOD,SLIP_PIPS;
 bool hasValidChannel;
  Shared2 *shared;
  Logger *logger;
  int INITIAL_SHIFT;
 int currentBar;
 int STEPS,START_SHIFT;
 
 public:   
   ResistanceLevelManager(double MIN_WORKING_CHANNEL_local,int SEARCH_HISTORY_PERIOD_local,int SLIP_PIPS_local,Shared2* &shared_){
      shared=shared_;
      SLIP_PIPS=SLIP_PIPS_local;
      MIN_WORKING_CHANNEL=MIN_WORKING_CHANNEL_local;
      SEARCH_HISTORY_PERIOD=SEARCH_HISTORY_PERIOD_local;
      isNewBar();
      INITIAL_SHIFT=1;
      STEPS=3;
      logger = new Logger(false);
      lowerPeak.price=-1;
      START_SHIFT=2;
   }
   
   bool isBidCloseToLevel(){
      removeOutDatedLevels();
      if(isNewBar()){
         logger.print("isBidCloseToLevel 0");
         updateLowerPeak();
         logger.print("isBidCloseToLevel 1");
         updateUpperPeak();                 
         logger.print("isBidCloseToLevel 2");       
      }
      logger.print("isBidCloseToLevel 3");
      
      return isPriceCloseToOneOfLevels();
   }
      
   double getSimetricLevelPrice(){
   logger.print("getSimetricLevel");
      if(activePeak.price!=-1){
         double opositePeakPrice; 
         if(activePeak.price==lowerPeak.price){
            opositePeakPrice=lowerPeak.oppositePrice;
            logger.print("lower");
         }else{
            opositePeakPrice=upperPeak.oppositePrice;
            logger.print("upper");
         }
         removeAllLevels();
         logger.print("opositePeakPrice="+DoubleToStr(opositePeakPrice));
         return opositePeakPrice;
      }else{
         return -1;      
      }            
   }
   
   void removeAllLevels(){        
     removePeak(upperPeak);
     removePeak(lowerPeak);
     removePeak(activePeak);     
   }
   
 private:
 
 void removeOutDatedLevels(){   
   double closeDelta=(SLIP_PIPS/shared.getKoef());
   if(lowerPeak.price!=-1&&Bid<(lowerPeak.price-closeDelta)){
       removePeak(lowerPeak);        
   }else
   if(upperPeak.price!=-1&&Bid>(upperPeak.price+closeDelta)){
      removePeak(upperPeak);               
   }
   removeOldPeaks(); 
 }
 
 void removeOldPeaks(){
   int upperPeakShift=iBarShift(NULL,0,upperPeak.time);
   if(upperPeakShift>=SEARCH_HISTORY_PERIOD*2){            
      removePeak(upperPeak);
   }
 
   int lowerPeakShift=iBarShift(NULL,0,lowerPeak.time);
   if(lowerPeakShift>=SEARCH_HISTORY_PERIOD*2){            
      removePeak(lowerPeak);
   }  
 }
 
 
 void removePeak(Peak& peak ){
      //ObjectDelete(0,DoubleToStr(peak.price));
      ObjectDelete(0,DoubleToStr(peak.price+1));
      peak.price=-1;
 }
 
 
//+------------------------------------------------------------------+
//|  LOWER PEAK                                                      |
//+------------------------------------------------------------------+
  Peak lowerPeak; 
  void updateLowerPeak(){
      logger.print("updateLowerPeak 0");
   
      int shift=getLowestShift();
      if(shift==NULL){return;}
      logger.print("updateLowerPeak 1");
      double price=iLow(NULL,0,shift);     
      int oppositeShift=iHighest(NULL,0,MODE_HIGH,shift-STEPS,START_SHIFT);
      double oppositePrice=iHigh(NULL,0,oppositeShift);
      logger.print("updateLowerPeak:oppositePrice="+DoubleToStr(oppositePrice));
      lowerPeak.oppositePrice=oppositePrice;
      if(lowerPeak.price!=price){
            ObjectDelete(0,DoubleToStr(lowerPeak.price));
            ObjectDelete(0,DoubleToStr(lowerPeak.price+1));            
            lowerPeak.price=price;
            lowerPeak.time=iTime(NULL,0,shift);
            createObjectSymbol(lowerPeak);
            createObjectLine(lowerPeak);
      }
 }
   
int getLowestShift(){ 
   logger.print("getLowestShift 0");      
      logger.print("getLowestShift 1");          
      int lowShift=iLowest(NULL,0,MODE_LOW,SEARCH_HISTORY_PERIOD,START_SHIFT);
      double lowPrice=iLow(NULL,0,lowShift);  
      logger.print("getLowestShift 2");
      logger.print("getLowestShift lowShift "+DoubleToString(lowShift));
      logger.print("getLowestShift lowPrice "+DoubleToString(lowPrice));
                
      if(lowShift-STEPS>START_SHIFT&&lowShift+STEPS<SEARCH_HISTORY_PERIOD&&lowPrice<Bid-MIN_WORKING_CHANNEL/shared.getKoef()){
         logger.print("getLowestShift 3");          
         return lowShift;         
      }  
   
  return NULL;
}

//+------------------------------------------------------------------+
//|  Upper PEAK                                                      |
//+------------------------------------------------------------------+
  Peak upperPeak; 
  void updateUpperPeak(){   
      logger.print("updateUpperPeak");
      int shift=getHighestShift();
      logger.print("shift="+DoubleToStr(shift));
      if(shift==NULL){return;}
      double price=iHigh(NULL,0,shift);
      logger.print("price="+DoubleToStr(price));  
      int oppositeShift=iLowest(NULL,0,MODE_LOW,shift-STEPS,START_SHIFT);
      double oppositePrice=iLow(NULL,0,oppositeShift);
      logger.print("updateUpperPeak:oppositePrice="+DoubleToStr(oppositePrice));
      upperPeak.oppositePrice=oppositePrice; 
      if(upperPeak.price!=price){
            ObjectDelete(0,DoubleToStr(upperPeak.price));
            ObjectDelete(0,DoubleToStr(upperPeak.price+1));
            
            upperPeak.price=price;
            upperPeak.time=iTime(NULL,0,shift);
     
            createObjectSymbol(upperPeak);
            createObjectLine(upperPeak);
      }
 }
   
int getHighestShift(){           
   int searchPeriod=SEARCH_HISTORY_PERIOD;
      int highShift=iHighest(NULL,0,MODE_HIGH,searchPeriod,START_SHIFT);
      double highestPrice=iHigh(NULL,0,highShift);  
   
      if(highShift-STEPS>START_SHIFT&&highShift+STEPS<searchPeriod&&highestPrice>Bid+MIN_WORKING_CHANNEL/shared.getKoef()){
         return highShift;
      }        
   return NULL;
}
//------------------------------------------
   
  void createObjectLine(const Peak& line){
      string name=DoubleToStr(line.price+1);  
      if(!ObjectCreate(0,name,OBJ_HLINE,0,0,line.price)){       
            Print(__FUNCTION__,   ": failed to create \"Arrow Up\" sign! Error code = ",GetLastError()); 
            return; 
        }
        else{        
            int chart_ID=0;                      
            ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_TOP); 
         //--- set line color 
            ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrGold); 
         //--- set line display style 
            ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,STYLE_DASH); 
         //--- set line width 
            ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,1); 
           } 
  }
  
  void createObjectSymbol(const Peak& line){
      string name=DoubleToStr(line.price);
      ENUM_OBJECT arrow;
      long anchor;
      if(Bid<line.price){
         arrow=OBJ_ARROW_DOWN;
         anchor=ANCHOR_BOTTOM;
      }else{
         arrow=OBJ_ARROW_UP;
         anchor=ANCHOR_TOP; 
      }
     
      if(!ObjectCreate(0,name,arrow,0,line.time,line.price)){ 
            Print(__FUNCTION__,   ": failed to create \"Arrow Up\" sign! Error code = ",GetLastError()); 
            return; 
        }
        else{        
            int chart_ID=0;                        
            ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor); 
            ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrRed);
            ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,STYLE_SOLID); 
            ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,3);         
        } 
  }   
   Peak activePeak;
   bool isPriceCloseToOneOfLevels(){   
      double slipDelta=(SLIP_PIPS/shared.getKoef());
      
      if(lowerPeak.price!=-1){
         if((shared.isPriceNear(lowerPeak.price))||
            ((Bid<lowerPeak.price)&&(Bid>(lowerPeak.price-slipDelta)))         
         ){         
            activePeak=lowerPeak;
            return true;
         }        
      }
      if(upperPeak.price!=-1){      
         if((shared.isPriceNear(upperPeak.price))||
            ((Bid>upperPeak.price)&&(Bid<(upperPeak.price+slipDelta)))     
         ){         
            activePeak=upperPeak;
            return true;         
         }      
      }
       return false;     
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