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

struct ChannelParams{
   double height,low,high,active;
   int id;

};

struct Line{
   int id;
   double price;
   datetime timeStart;
   datetime timeEnd;
};

struct Channel{
   Line upper;
   Line lower;
   bool exists;
};

class ChannelManager{
 
 ChannelParams params;
 double MIN_WORKING_CHANNEL;
 int currentBar;
 bool hasValidChannel;
 Shared2 *shared;
  int INITIAL_SHIFT;
  int MA_PERIOD;

 public:   
   ChannelManager(double MIN_WORKING_CHANNEL_local,Shared2* &shared_){
      shared=shared_;
      MIN_WORKING_CHANNEL=MIN_WORKING_CHANNEL_local;
      checkForNewChannel();
      isNewBar();
      INITIAL_SHIFT=1;
      MA_PERIOD=3;
      lastValidChannel.exists=false;

   }
   

   
   ChannelParams getChannelParams(){   
      if(hasValidChannel){      
       params.height=MathAbs(lastValidChannel.lower.price-lastValidChannel.upper.price)*shared.getKoef();
       params.high=lastValidChannel.upper.price;
       params.low=lastValidChannel.lower.price;
       params.id=lastValidChannel.lower.id+lastValidChannel.upper.id;       
       params.active=getFirstMarkedBorder(lastValidChannel);
      }else{
         printf("Error. Recieved request for params of invalid channel");
         params.height=-1;
         params.high=-1;
         params.low=-1;
         params.id=-1;
      }   
   return params;
   }
 
    bool existsValidChannel(){
    
       if(isNewBar()){
         checkForNewChannel();
        } 
        if(lastValidChannel.exists){
          hasValidChannel=true;
        }else{
          hasValidChannel=false;
        }
    return hasValidChannel;
    }
    
 private:
 
 Channel tmpChannel;
 Channel lastValidChannel;
 
   double getFirstMarkedBorder(Channel &channel){
      if(channel.lower.timeStart<channel.upper.timeStart){
         return channel.lower.price;
      }else{
         return channel.upper.price;
      }   
   }
   
   void checkForNewChannel(){
   
      tmpChannel.upper=getUpperLine();
      tmpChannel.lower=getLowerLine();
      
      if(isNewChannelValid(tmpChannel)){
          drawNewChannel();
          lastValidChannel=tmpChannel;
          lastValidChannel.exists=true;
      }
   }
      
  bool isNewChannelValid(Channel &channel){
      
      if(channel.lower.id==-1 || channel.upper.id==-1){
         printf("channel is not valid because no one/two borders");
         return false;         
      }
      double realHeight=NormalizeDouble(MathAbs(channel.lower.price-channel.upper.price)*shared.getKoef(),2);   
      if(realHeight<MIN_WORKING_CHANNEL){
         printf("channel is not valid because height: "+DoubleToStr(realHeight)+" < "+DoubleToStr(MIN_WORKING_CHANNEL));        
         return false;
      }
      
      if(channel.lower.timeStart==channel.upper.timeStart){
         printf("channel is not valid because upper and lower borders start at the same time");        
         return false;
     
      }   
      return true;
  }
  
   
  void drawNewChannel(){
 
      if(shared.isPriceNear(tmpChannel.upper.price,lastValidChannel.upper.price)){
          ObjectDelete(0,DoubleToStr(lastValidChannel.upper.id));
      } 
      createObject(tmpChannel.upper);
 
      if(shared.isPriceNear(tmpChannel.lower.price,lastValidChannel.lower.price)){
          ObjectDelete(0,DoubleToStr(lastValidChannel.lower.id));
      } 
      
      createObject(tmpChannel.lower);
  }
  
  
  
  void createObject(const Line& line){
     ObjectCreate(DoubleToStr(line.id), OBJ_TREND, 0,line.timeStart, line.price, line.timeEnd, line.price);
     ObjectSet(DoubleToStr(line.id), OBJPROP_RAY, false); 
  }
 
  
   
   //+------------------------------------------------------------------+
   //|                 UPPER BORDER                                                 |
   //+------------------------------------------------------------------+
   
   Line getUpperLine(){      
      Line line;
      line.id=-1;
      int shift=getUpperPickShift(); 
      if(shift==-1) return line;
      
      line.id=getMagicNumber();
      line.price=High[shift];     
      line.timeStart=Time[shift]; 
      line.timeEnd=Time[0];
  
      if(shared.isPriceNear(lastValidChannel.upper.price,line.price)){
          line.timeStart=lastValidChannel.upper.timeStart;
      } 
      return line;
    }
   
    int getUpperPickShift(){
      
      int peakShiftMA=getHighPickShiftMA(Bid);
      if(peakShiftMA==-1){return peakShiftMA;}      
      int peakShiftClosest=iHighest(NULL,0,MODE_HIGH,peakShiftMA+MA_PERIOD+1,0);   
      int finalpeakShift;
      if(High[peakShiftClosest]>High[peakShiftMA]){
         finalpeakShift=getHighPickShiftMA(High[peakShiftClosest]);
      }else{
         finalpeakShift=peakShiftMA;
      }
         
      return finalpeakShift;
   } 
   
   int getHighPickShiftMA(double initialPrice){
      int i=INITIAL_SHIFT;
      double val1=0,val2=0,val3=0;
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
   
   //+------------------------------------------------------------------+
   //|                 LOWER BORDER                                                 |
   //+------------------------------------------------------------------+
    
   Line getLowerLine(){ 
      Line line;
      line.id=-1;
      int shift=getLowerPickShift(); 
     if(shift==-1) return line;
       
      line.id = getMagicNumber();
      line.price = Low[shift];
      line.timeStart=Time[shift];   
      line.timeEnd = Time[0];
      
      if(shared.isPriceNear(lastValidChannel.lower.price,line.price)){
          line.timeStart=lastValidChannel.lower.timeStart;
      } 

      return line;
   }
   
   int getLowerPickShift(){      
      int peakShiftMA=getLowPeakShift(Bid);
      if(peakShiftMA==-1){return peakShiftMA;}      

      int peakShiftClosest=iLowest(NULL,0,MODE_LOW,peakShiftMA+MA_PERIOD+1,0);   
      int finalpeakShift;
      if(Low[peakShiftClosest]<Low[peakShiftMA]){
         finalpeakShift=getLowPeakShift(Low[peakShiftClosest]);
      }else{
         finalpeakShift=peakShiftMA;
      }
      return finalpeakShift;
   }   
  
  int getLowPeakShift(double initialPrice){
      int i=INITIAL_SHIFT;
      double val1=0,val2=0,val3=0;
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
   
  bool isNewBar(){
      int bar=iBars(NULL,PERIOD_CURRENT);
      if(currentBar!=bar){
         currentBar=bar;
         return true;
      }else{
         return false;
      }
  }
  
  int getMagicNumber(){
      int num = 1 + 1000*MathRand()/32768;
      return num;   
   }
};