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

struct ChannelLines{
   LineId upper;
   LineId lower;
};

class ChannelManager{
 
 ChannelParams params;
 double MIN_WORKING_CHANNEL;
 int currentBar;
 bool hasValidChannel;
 Shared2 *shared;

 public:   
   ChannelManager(double MIN_WORKING_CHANNEL_local,Shared2* &shared_){
      shared=shared_;
      MIN_WORKING_CHANNEL=MIN_WORKING_CHANNEL_local;
      checkForNewChannel();
      isNewBar();
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
    return hasValidChannel;
    }
    
 private:
 
 ChannelLines tmpChannel;
 ChannelLines lastValidChannel;
 
   void checkForNewChannel(){
   
      tmpChannel.upper=getUpperLine();
      tmpChannel.lower=getLowerLine();
      
      if(isChannelValid(tmpChannel)){
          hasValidChannel=true; 
          drawNewChannel();
          tmpChannel=lastValidChannel;       
      }
   }
      
  bool isChannelValid(ChannelLines &channel){
      
      if(channel.lower.id==-1 || channel.upper.id==-1)return false;   
      if(MathAbs(channel.lower.price-channel.upper.price)*shared.getKoef()<MIN_WORKING_CHANNEL )return false;   
      return true;
  }
  
   
  void drawNewChannel(){
 
      if(shared.isPriceNear(tmpChannel.upper.price,lastValidChannel.upper.price)){
          ObjectDelete(0,DoubleToStr(lastValidChannel.upper.id) );
          printf("deleted upper");
      } 
      printf("before:tmpChannel.upper.price"+tmpChannel.upper.price);
      createObject(tmpChannel.upper);
 
      if(shared.isPriceNear(tmpChannel.lower.price,lastValidChannel.lower.price)){
          ObjectDelete(0,DoubleToStr(lastValidChannel.lower.id));
          printf("deleted lower");
      } 
      
      printf("before:tmpChannel.lower.price"+tmpChannel.lower.price);
      createObject(tmpChannel.lower);
  }
  
  
  
  void createObject(const LineId& line){
     printf("line.price="+line.price);
  
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
      printf("UPPER BORDER:"+shift);
      if(shift==-1) return line;
      
      line.id=getMagicNumber();
      line.price=High[shift];     
      line.timeShift=Time[shift]; 
      line.time=Time[0];
  
      return line;
    }
   
    
   int getUpperPickShift(){
      int i=1;
      double val1=0,val2=0,val3=0;
      
      while(i<50){
       val1=iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i);
       val2=iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i+1);
       val3=iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i+2);
       if(val1<val2&&val3<val2){
         if(High[i+1]>Bid||shared.isPriceNear(Bid,High[i+1])){
            return i+1;
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
       printf("LOWER BORDER:"+shift);
     if(shift==-1) return line;
       
      line.id = getMagicNumber();
      line.price = Low[shift];
      line.timeShift=Time[shift];   
      line.time = Time[0];
      return line;
   }
   
   
   int getLowerPickShift(){
      int i=1;
      double val1=0,val2=0,val3=0;
      
      while(i<50){
       val1=iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i);
       val2=iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i+1);
       val3=iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i+2);
       if(val1>val2&&val3>val2){
         if(Low[i+1]<Bid||shared.isPriceNear(Bid,Low[i+1])){
            return i+1;
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