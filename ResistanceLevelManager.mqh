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
            updatePeaks();      
         }         
      return isPriceCloseToOneOfLevels();
   }
      
   double getSimetricLevelPrice(){
      if(activePeak.price!=-1){
         double apositePeakPrice;
         int shift=iBarShift(NULL,0,activePeak.time,true); 
         if(activePeak.price==lowerPeak.price){                       
            apositePeakPrice=iHigh(NULL,0,iHighest(NULL,0,MODE_HIGH,shift+1,1));
         }else{
             apositePeakPrice=iLow(NULL,0,iLowest(NULL,0,MODE_HIGH,shift+1,1));          
         }
         return apositePeakPrice;
      }else{
         return -1;      
      }            
   }
   void removeActiveLevel(){
      
      
      bool answer=ObjectDelete(0,DoubleToStr(lowerPeak.price));
      printf("removed active level2 "+DoubleToStr(lowerPeak.price+1)+", "+answer);
      answer = ObjectDelete(0,DoubleToStr(lowerPeak.price+1));
      printf("removed active level2 "+DoubleToStr(lowerPeak.price+1)+", "+answer);
      lowerPeak.price=-1;
   }
 private:
 
  void updatePeaks(){  
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
      
      printf("created new level: "+lowerPeak.price);
      
   }
  }
  
  void createObjectLine(const Peak& line){
      if(!ObjectCreate(0,DoubleToStr(line.price+1),OBJ_HLINE,0,0,line.price)){       
            Print(__FUNCTION__,   ": failed to create \"Arrow Up\" sign! Error code = ",GetLastError()); 
            return; 
        }
        else{        
            int width=3;//size
            int chart_ID=0;
            string name=DoubleToStr(line.price);            
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
      if(!ObjectCreate(0,DoubleToStr(line.price),OBJ_ARROW_UP,0,line.time,line.price)){ 
            Print(__FUNCTION__,   ": failed to create \"Arrow Up\" sign! Error code = ",GetLastError()); 
            return; 
        }
        else{        
            int width=3;//size
            int chart_ID=0;
            string name=DoubleToStr(line.price);            
            ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_TOP); 
            ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrRed);
            ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,STYLE_SOLID); 
            ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);         
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
   
   
   Peak activePeak;
   bool isPriceCloseToOneOfLevels(){
      if(lowerPeak.price!=-1&&shared.isPriceNear(lowerPeak.price)){
         activePeak=lowerPeak;
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