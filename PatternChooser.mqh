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
#include <LabelManager.mqh>


class PatternChooser{
   Pattern pattern;
   GlobalVarManager *globalVarManager;
   LabelManager *labelManager;
  public:

   PatternChooser(){
      globalVarManager =new GlobalVarManager ();
      labelManager = new LabelManager();  
   }


   void choosePatternAndPublish(){
      double max=0;
      double tp_max=0;
      double sl_max=0;
      
      for(double profit=0.3;profit<=1.5;profit=profit+0.1){
       for(double loss=-0.3;loss>=-1.5;loss=loss-0.1){ 
          if(profit>=MathAbs(loss))  {
             double result=getEquity(profit,loss);             
             if(result>max){
               max=NormalizeDouble(result, 2);
               sl_max=NormalizeDouble(loss, 2);
               tp_max=NormalizeDouble(profit, 2);
             } 
             printf("current:"+"equity="+result+", profit="+profit+", loss="+loss);     
            }  

         }
      }  
      string msg="Optimal:"+"equity="+max+", tp_max="+tp_max+", sl_max="+sl_max;
      printf(msg); 
      Comment(msg);
      labelManager.updateLabelValues(tp_max,sl_max);
   }
   

   double getEquity(double tp,double sl){       
       double result=iCustom(NULL,0,"trendIndicator",tp,sl,50,false,6,1)*100;
       if(result!=2147483647){
         return  result;
        
       }else{
         return -100;
       }
    
   }
};