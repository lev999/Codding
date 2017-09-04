//+------------------------------------------------------------------+
//|                                                      Include.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <GlobalVarManager.mqh>
#include <Shared.mqh>


class PatternChooser{
   Pattern pattern;
   GlobalVarManager *globalVarManager;
  public:

   PatternChooser(){
      globalVarManager =new GlobalVarManager ();
   }

   void choosePatternAndPublish(){
      
      //for(int i=0;i<7;i++){
      
        printf("getEquity(1.0,-0.6)="+getEquity(1.0,-0.6));
        printf("getEquity(0.1,-0.6)="+getEquity(0.1,-0.6));
          
      
      //}
      printf("finished");      
   }
   

   double getEquity(double tp,double sl){       
       double result=iCustom(NULL,0,"trendIndicator",tp,sl,6,1)*100;
       if(result!=2147483647){
         return  NormalizeDouble(result, 2);
        
       }else{
         return -100;
       }
    
   }
};