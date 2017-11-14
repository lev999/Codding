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


struct Peak{
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
      lowerPeak.price=-1;
   }
   
   bool isBidCloseToLevel(){
      if(isNewBar()){
            updateLowerPeak(); 
            updateUpperPeak();                 
         }
       removeOutDatedLevels();           
      return isPriceCloseToOneOfLevels();
   }
      
   double getSimetricLevelPrice(){
      if(activePeak.price!=-1){
         double apositePeakPrice;
         int shift=iBarShift(NULL,0,activePeak.time,true); 
         if(activePeak.price==lowerPeak.price){                       
            apositePeakPrice=iHigh(NULL,0,iHighest(NULL,0,MODE_HIGH,shift+10,1));//10 is here trend time life estimation
         }else{
             apositePeakPrice=iLow(NULL,0,iLowest(NULL,0,MODE_LOW,shift+10,1)); //10 is here trend time life estimation         
         }
         return apositePeakPrice;
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
      printf("lowerPeak was removed because price was lower than peak-delta "+(lowerPeak.price-closeDelta));
      removePeak(lowerPeak);         
   }else
   if(upperPeak.price!=-1&&Bid>(upperPeak.price+closeDelta)){
      printf("upperPeak was removed because price was higher than peak+delta "+(upperPeak.price+closeDelta));
      removePeak(upperPeak);         
   } 
 }
 
 void removePeak(Peak& peak ){
      ObjectDelete(0,DoubleToStr(peak.price));
      ObjectDelete(0,DoubleToStr(peak.price+1));
      peak.price=-1;
 }
 
 
//+------------------------------------------------------------------+
//|  LOWER PEAK                                                                |
//+------------------------------------------------------------------+
  void updateLowerPeak(){  
    int peakShift=getLowestPeakShift(MA_PERIOD);  
    while(true){
       if(peakShift!=-1){
           double highestPrice=iHigh(NULL,0,iHighest(NULL,0,MODE_HIGH,peakShift+1,1));            
           if((highestPrice-Bid)*shared.getKoef()>MIN_WORKING_CHANNEL){
               createLowerPeak(peakShift);
               return; 
           }else{
               int newPeakShift=getLowestPeakShift(peakShift); 
               if(newPeakShift==peakShift){
                  return;
               }else{
               peakShift=newPeakShift;               
               }
               
           }           
       }else {return;}       
     }    
  }
   
  Peak lowerPeak; 
  void createLowerPeak(int peakShift){     
   double price=iLow(NULL,0,peakShift);   
   if(lowerPeak.price!=price){
      ObjectDelete(0,DoubleToStr(lowerPeak.price));
      ObjectDelete(0,DoubleToStr(lowerPeak.price+1));
      
      lowerPeak.price=price;
      lowerPeak.time=iTime(NULL,0,peakShift);
      createObjectSymbol(lowerPeak);
      createObjectLine(lowerPeak);
      
      printf("created new lower level: "+lowerPeak.price);
      
   }
  }
  
  int getLowestPeakShift(int shift){      
      int peakShiftMA=getLowMAPeakShift(shift);
      if(peakShiftMA==-1){return peakShiftMA;}      

      int peakShiftClosest=iLowest(NULL,0,MODE_LOW,(peakShiftMA-shift),shift);   
      int finalpeakShift;
      if(Low[peakShiftClosest]<Low[peakShiftMA]){
         finalpeakShift=peakShiftClosest;
      }else{
         finalpeakShift=peakShiftMA;
      }
      return finalpeakShift;
   }   
   
    int getLowMAPeakShift(int shift){
      int i=shift;
      double val1=0,val2=0,val3=0,initialPrice=Bid;
      while(i<50){
       val1=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_LOW,i);
       val2=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_LOW,i+1);
       val3=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_LOW,i+2);
            
       if(val1>val2&&val3>val2){
         int tmpPeakShiftMA=iLowest(NULL,0,MODE_LOW,3,i);
         if(Low[tmpPeakShiftMA]<initialPrice||shared.isPriceNear(initialPrice,Low[tmpPeakShiftMA])){
           return tmpPeakShiftMA;           
         } 
       }
      i++;
      }
      return -1;
  }
//+------------------------------------------------------------------+
//|  Upper PEAK                                                      |
//+------------------------------------------------------------------+

  void updateUpperPeak(){  
    int peakShift=getHighestPeakShift(MA_PERIOD);  
    while(true){
       if(peakShift!=-1){
           double lowestPrice=iLow(NULL,0,iLowest(NULL,0,MODE_LOW,peakShift+1,1));            
           if((Bid-lowestPrice)*shared.getKoef()>MIN_WORKING_CHANNEL){
               createUpperPeak(peakShift);
               return; 
           }else{
               int newPeakShift=getHighestPeakShift(peakShift); 
               if(newPeakShift==peakShift){
                  return;
               }else{
                  peakShift=newPeakShift;               
               }               
           }           
       }else {return;}       
     }    
  }
   
  Peak upperPeak; 
  void createUpperPeak(int peakShift){     
   double price=iHigh(NULL,0,peakShift); 
   if(upperPeak.price!=price){
      ObjectDelete(0,DoubleToStr(upperPeak.price));
      ObjectDelete(0,DoubleToStr(upperPeak.price+1));
      
      upperPeak.price=price;
      upperPeak.time=iTime(NULL,0,peakShift);
      createObjectSymbol(upperPeak);
      createObjectLine(upperPeak);      
      printf("created new upper level: "+upperPeak.price);      
   }
  }
  
  int getHighestPeakShift(int shift){      
      int peakShiftMA=getHighMAPeakShift(shift);
      if(peakShiftMA==-1){return peakShiftMA;}      

      int peakShiftClosest=iHighest(NULL,0,MODE_HIGH,(peakShiftMA-shift),shift);   
      int finalpeakShift;
      if(High[peakShiftClosest]>High[peakShiftMA]){
         finalpeakShift=peakShiftClosest;
      }else{
         finalpeakShift=peakShiftMA;
      }
      return finalpeakShift;
   }   
   
    int getHighMAPeakShift(int shift){
      int i=shift;
      double val1=0,val2=0,val3=0,initialPrice=Bid;
      while(i<50){
       val1=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_HIGH,i);
       val2=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_HIGH,i+1);
       val3=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_HIGH,i+2);
            
       if(val1<val2&&val3<val2){
         int tmpPeakShiftMA=iHighest(NULL,0,MODE_HIGH,3,i);
         if(High[tmpPeakShiftMA]>initialPrice||shared.isPriceNear(initialPrice,High[tmpPeakShiftMA])){
           return tmpPeakShiftMA;           
         } 
       }
      i++;
      }
      return -1;
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