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
   double height;
   double low;
   double high;
   int id;

};

struct LineId{
   int id;
   double price;
   datetime time;
   datetime timeShift;
};

struct Channel{
   LineId upper;
   LineId lower;
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
      INITIAL_SHIFT=5;
      MA_PERIOD=3;
      lastValidChannel.exists=false;

   }
   

   
   ChannelParams getChannelParams(){   
      if(hasValidChannel){      
       params.height=MathAbs(lastValidChannel.lower.price-lastValidChannel.upper.price)*shared.getKoef();
       params.high=lastValidChannel.upper.price;
       params.low=lastValidChannel.lower.price;
       params.id=lastValidChannel.lower.id+lastValidChannel.upper.id;       
       
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
         printf("channel is not valid because heigh: "+DoubleToStr(realHeight)+" < "+DoubleToStr(MIN_WORKING_CHANNEL));        
         return false;
      }   
      return true;
  }
  
   
  void drawNewChannel(){
 
      if(shared.isPriceNear(tmpChannel.upper.price,lastValidChannel.upper.price)){
          ObjectDelete(0,DoubleToStr(lastValidChannel.upper.id) );
      } 
      createObject(tmpChannel.upper);
 
      if(shared.isPriceNear(tmpChannel.lower.price,lastValidChannel.lower.price)){
          ObjectDelete(0,DoubleToStr(lastValidChannel.lower.id));
      } 
      
      createObject(tmpChannel.lower);
  }
  
  
  
  void createObject(const LineId& line){
     ObjectCreate(DoubleToStr(line.id), OBJ_TREND, 0,line.timeShift , line.price, line.time, line.price);
     ObjectSet(DoubleToStr(line.id), OBJPROP_RAY, false); 
  }
 
  
   
   //+------------------------------------------------------------------+
   //|                 UPPER BORDER                                                 |
   //+------------------------------------------------------------------+
   
   LineId getUpperLine(){      
      LineId line;
      line.id=-1;
      int shift=getUpperPickShift(); 
      if(shift==-1) return line;
      
      line.id=getMagicNumber();
      line.price=High[shift];     
      line.timeShift=Time[shift]; 
      line.time=Time[0];
  
      return line;
    }
   
    
    
    int getUpperPickShift(){
      int i=INITIAL_SHIFT;
      double val1=0,val2=0,val3=0;
      
      while(i<50){
       val1=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_HIGH,i);
       val2=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_HIGH,i+1);
       val3=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_HIGH,i+2);
       if(val1<val2&&val3<val2){
         int finalpeak=0;
         int peakShiftMA=iHighest(NULL,0,MODE_HIGH,3,i);
         int peakShiftClosest=iHighest(NULL,0,MODE_HIGH,peakShiftMA+1,0);
         
         if(peakShiftClosest<peakShiftMA){finalpeak=peakShiftClosest;}else{finalpeak=peakShiftMA;}
         
         if(High[finalpeak]>Bid||shared.isPriceNear(Bid,High[finalpeak])){
            return finalpeak;
         }         
       }
      i++;
      }
      return -1;
   } 
   //+------------------------------------------------------------------+
   //|                 LOWER BORDER                                                 |
   //+------------------------------------------------------------------+
    
   LineId getLowerLine(){ 
      LineId line;
      line.id=-1;
      int shift=getLowerPickShift(); 
     if(shift==-1) return line;
       
      line.id = getMagicNumber();
      line.price = Low[shift];
      line.timeShift=Time[shift];   
      line.time = Time[0];
      return line;
   }
   
   int getLowerPickShift(){
      int i=INITIAL_SHIFT;
      double val1=0,val2=0,val3=0;
      
      while(i<50){
       val1=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_LOW,i);
       val2=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_LOW,i+1);
       val3=iMA(NULL,0,MA_PERIOD,0,MODE_SMA,PRICE_LOW,i+2);
            
       if(val1>val2&&val3>val2){
         int finalpeak=0;
         int peakShiftMA=iLowest(NULL,0,MODE_LOW,3,i);
         int peakShiftClosest=iLowest(NULL,0,MODE_LOW,peakShiftMA+1,0);
         
         if(peakShiftClosest<peakShiftMA){finalpeak=peakShiftClosest;}else{finalpeak=peakShiftMA;}
         
         if(Low[finalpeak]<Bid||shared.isPriceNear(Bid,Low[finalpeak])){
            return finalpeak;
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