//+------------------------------------------------------------------+
//|                                                      Include.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

struct ChannelParams{
   double height;
   double low;
   double high;

};

class ChannelManager{
 
 ChannelParams params;
 double MIN_WORKING_CHANNEL;
 int currentBar;
 bool hasValidChannel;
 
 public:   
   ChannelManager(double MIN_WORKING_CHANNEL_local){
   
      MIN_WORKING_CHANNEL=MIN_WORKING_CHANNEL_local;
      checkForNewChannel();
      isNewBar();
      lastUpperBorderTime=TimeCurrent();        
   }
   

   
   ChannelParams getChannelParams(){
   
   return params;
   }
 
    bool existsValidChannel(){
    
       if(isNewBar()){
         checkForNewChannel();
        }  
    return hasValidChannel;
    }
    
 private:
 
 int lastUpperBorderTime;
 
   void checkForNewChannel(){
      drawUpperBorder();
      drawLowerBorder();
      
      hasValidChannel=true;
   }
   
    void drawUpperBorder(){
      //double value;
      int pickShift=getUpperPickShift();         
      if(pickShift!=-1) {
         //value=High[pickShift];
         createUpperLine(pickShift);
      } 
      
    }
   
    int getMagicNumber(){
      int num = 1 + 1000*MathRand()/32768;
      return num;
   
   }
   
   string lastObjName;
   double lastObjPrice;   
   void createUpperLine(int shift){
      if(High[shift]==lastObjPrice){
         ObjectDelete(0,lastObjName);
      }
      
      string strObjectName = getMagicNumber();
      lastObjName=strObjectName;
      lastObjPrice=High[shift];
      ObjectCreate(strObjectName, OBJ_TREND, 0, Time[shift], High[shift], Time[0], High[shift]);
      ObjectSet(strObjectName, OBJPROP_RAY, false);
      
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
   
   
   
   
   string lastLowerObjName;
   double lastLowerObjPrice;   
   void createLowerLine(int shift){
      if(Low[shift]==lastLowerObjPrice){
         ObjectDelete(0,lastLowerObjName);
      }
      
      string strObjectName = getMagicNumber();
      lastLowerObjName=strObjectName;
      lastLowerObjPrice=Low[shift];
      ObjectCreate(strObjectName, OBJ_TREND, 0, Time[shift], Low[shift], Time[0], Low[shift]);
      ObjectSet(strObjectName, OBJPROP_RAY, false);
      
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
};