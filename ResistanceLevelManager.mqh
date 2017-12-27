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
 int WORK_PERIOD;
 bool hasValidChannel;
  Shared2 *shared;
  Logger *logger;
  int INITIAL_SHIFT;
  int MA_PERIOD;
 int currentBar;
 int STEPS,START_SHIFT;
 
 public:   
   ResistanceLevelManager(double MIN_WORKING_CHANNEL_local,int WORK_PERIOD_local,Shared2* &shared_){
      shared=shared_;
      MIN_WORKING_CHANNEL=MIN_WORKING_CHANNEL_local;
      WORK_PERIOD=WORK_PERIOD_local;
      isNewBar();
      INITIAL_SHIFT=1;
      MA_PERIOD=3;
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
      if(activePeak.price!=-1){
         double opositePeakPrice; 
         if(activePeak.price==lowerPeak.price){
            opositePeakPrice=lowerPeak.oppositePrice;
         }else{
            opositePeakPrice=upperPeak.oppositePrice;
         }
         
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
   double closeDelta=(0.25*MIN_WORKING_CHANNEL/shared.getKoef());
   if(lowerPeak.price!=-1&&Bid<(lowerPeak.price-closeDelta)){
       removePeak(lowerPeak);        
   }else
   if(upperPeak.price!=-1&&Bid>(upperPeak.price+closeDelta)){
      removePeak(upperPeak);               
   } 
 }
 
 void removePeak(Peak& peak ){
      ObjectDelete(0,DoubleToStr(peak.price));
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
      if(lowerPeak.price!=-1&&lowerPeak.price>price){return;}      
      int oppositeShift=iHighest(NULL,0,MODE_HIGH,shift,START_SHIFT);
      double oppositePrice=iHigh(NULL,0,oppositeShift);
      
      if(lowerPeak.price!=price){
            ObjectDelete(0,DoubleToStr(lowerPeak.price));
            ObjectDelete(0,DoubleToStr(lowerPeak.price+1));
            
            lowerPeak.price=price;
            lowerPeak.time=iTime(NULL,0,shift);
            lowerPeak.oppositePrice=oppositePrice;      
            
            createObjectSymbol(lowerPeak);
            createObjectLine(lowerPeak);
      }
 }
   
int getLowestShift(){ 
   logger.print("getLowestShift 0");          
   int searchPeriod=WORK_PERIOD+1;
   while(searchPeriod<WORK_PERIOD*2){
      logger.print("getLowestShift 1");          
      int lowShift=iLowest(NULL,0,MODE_LOW,searchPeriod,START_SHIFT);
      double lowPrice=iLow(NULL,0,lowShift);  
      logger.print("getLowestShift 2");
      logger.print("getLowestShift lowShift "+DoubleToString(lowShift));
      logger.print("getLowestShift lowPrice "+DoubleToString(lowPrice));
                
      if(lowShift-STEPS>START_SHIFT&&lowShift+STEPS<searchPeriod&&lowPrice<Bid-MIN_WORKING_CHANNEL/shared.getKoef()){
         logger.print("getLowestShift 3");          
         return lowShift;         
      }else{
         searchPeriod=searchPeriod+1;
         logger.print("getLowestShift 4");          
         logger.print("searchPeriod "+ DoubleToString(searchPeriod));          
      }      
   }
   // printf("NEW LowestShift was not found in WORK_PERIOD*2: "+searchPeriod);
  return NULL;
}

//+------------------------------------------------------------------+
//|  Upper PEAK                                                      |
//+------------------------------------------------------------------+
  Peak upperPeak; 
  void updateUpperPeak(){   
      int shift=getHighestShift();
      if(shift==NULL){return;}
      double price=iHigh(NULL,0,shift); 
      if(upperPeak.price!=-1&&upperPeak.price<price){return;}      
      int oppositeShift=iLowest(NULL,0,MODE_LOW,shift,START_SHIFT);
      double oppositePrice=iLow(NULL,0,oppositeShift);
      
      if(upperPeak.price!=price){
            ObjectDelete(0,DoubleToStr(upperPeak.price));
            ObjectDelete(0,DoubleToStr(upperPeak.price+1));
            
            upperPeak.price=price;
            upperPeak.time=iTime(NULL,0,shift);
            upperPeak.oppositePrice=oppositePrice;      
            
            createObjectSymbol(upperPeak);
            createObjectLine(upperPeak);
      }
 }
   
int getHighestShift(){           
   int searchPeriod=WORK_PERIOD+1;
   while(searchPeriod<WORK_PERIOD*2){
      int highShift=iHighest(NULL,0,MODE_HIGH,searchPeriod,START_SHIFT);
      double highestPrice=iHigh(NULL,0,highShift);  
   
      if(highShift-STEPS>START_SHIFT&&highShift+STEPS<searchPeriod&&highestPrice>Bid+MIN_WORKING_CHANNEL/shared.getKoef()){
         return highShift;
         break;
      }else{
         searchPeriod=searchPeriod+1;
      }      
   }
  // printf("NEW HighestShift was not found in WORK_PERIOD*2: "+searchPeriod);
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
      if(lowerPeak.price!=-1&&shared.isPriceNear(lowerPeak.price)){
         activePeak=lowerPeak;
         return true;
      }
      else if(upperPeak.price!=-1&&shared.isPriceNear(upperPeak.price)){
         activePeak=upperPeak;
         return true;
      }
      else{
         return false;
      }      
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