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
   string name;
   double price;
   datetime time;
   datetime timeShift;
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
       params.height=MathAbs(lowerLine.price-upperLine.price)*shared.getKoef();
       params.high=upperLine.price;
       params.low=lowerLine.price;
       params.id=lowerLine.id+upperLine.id;       
       
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
 
   void checkForNewChannel(){
      drawUpperBorder();
      drawLowerBorder();
      if(TimeHour(upperLine.time)==TimeHour(Time[0])&&TimeHour(lowerLine.time)==TimeHour(Time[0])&&MathAbs(lowerLine.price-upperLine.price)*shared.getKoef()>MIN_WORKING_CHANNEL){
         hasValidChannel=true;
      }else{
         hasValidChannel=false;      
      }
      
      
   }
   //+------------------------------------------------------------------+
   //|                 UPPER BORDER                                                 |
   //+------------------------------------------------------------------+
   
    void drawUpperBorder(){
      //double value;
      int pickShift=getUpperPickShift();         
      if(pickShift!=-1) {
         //value=High[pickShift];
         createUpperLine(pickShift);
      }       
    }
   
   LineId upperLine; 
   void createUpperLine(int shift){
      
      if(shared.isPriceNear(High[shift],upperLine.price)){
         ObjectDelete(0,upperLine.name);
         
      }else{
         upperLine.id=getMagicNumber();
         upperLine.price=High[shift];     
         upperLine.timeShift=Time[shift];     
      } 
     
      upperLine.name = DoubleToStr(upperLine.id);      
      upperLine.time=Time[0];
      
      ObjectCreate(upperLine.name, OBJ_TREND, 0,upperLine.timeShift , upperLine.price, upperLine.time, upperLine.price);
      ObjectSet(upperLine.name, OBJPROP_RAY, false);      
   }
   
   
   int getUpperPickShift(){
      int i=1;
      double val1=0,val2=0,val3=0;
      
      while(i<5){
       val1=iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i);
       val2=iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i+1);
       val3=iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i+2);
       if(val1<val2&&val3<val2){
         return i+1;
       }
      i++;
      }
      return -1;
   } 
   //+------------------------------------------------------------------+
   //|                 LOWER BORDER                                                 |
   //+------------------------------------------------------------------+
   
   LineId lowerLine; 
   void createLowerLine(int shift){     
     
      if(shared.isPriceNear(Low[shift],lowerLine.price)){
         ObjectDelete(0,lowerLine.name);
         
      }else{
         lowerLine.id = getMagicNumber();
         lowerLine.price = Low[shift];
         lowerLine.timeShift=Time[shift];     
      }
            
      lowerLine.name = DoubleToStr(lowerLine.id);      
      lowerLine.time = Time[0];
      ObjectCreate(lowerLine.name, OBJ_TREND, 0, lowerLine.timeShift, lowerLine.price,lowerLine.time, lowerLine.price);
      ObjectSet(lowerLine.name, OBJPROP_RAY, false);      
   }
   
   void drawLowerBorder(){
      int pickShift=getLowerPickShift();         
      if(pickShift!=-1) {
         createLowerLine(pickShift);
      }       
    }
   
   int getLowerPickShift(){
      int i=1;
      double val1=0,val2=0,val3=0;
      
      while(i<5){
       val1=iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i);
       val2=iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i+1);
       val3=iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i+2);
       if(val1>val2&&val3>val2){
         return i+1;
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