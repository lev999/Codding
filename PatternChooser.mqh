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
#include <LabelManager.mqh>
#include <Shared.mqh>

  
  
class PatternChooser{
   Pattern pattern;
   GlobalVarManager *globalVarManager;
   Shared *shared; 
   LabelManager *labelManager; 
  public:

   PatternChooser(){
      shared = new Shared();
      globalVarManager =new GlobalVarManager ();
      pattern=globalVarManager.getPattern(); 
      labelManager= new LabelManager();
   }


   void choosePatternAndPublish(){
      double max=0;
      double tp_max=0;
      double sl_max=0;
      
      for(double profit=0.3;profit<=1.5;profit=profit+0.1){
       for(double loss=-0.3;loss>=-1.5;loss=loss-0.1){ 
          if(profit>MathAbs(loss))  {
             double result=NormalizeDouble(getEquity(profit,loss), 2);           
             if(result>max){
               max=NormalizeDouble(result, 2);
               sl_max=NormalizeDouble(loss, 2);
               tp_max=NormalizeDouble(profit, 2);
             } 
             //printf("current:"+"equity="+result+", profit="+profit+", loss="+loss);     
            }  

         }
      }  
      if(max>0&&tp_max!=0&&sl_max!=0){
         string msg="Optimal: "+"equity="+DoubleToStr(max)+", tp_max="+DoubleToStr(tp_max)+", sl_max="+DoubleToStr(sl_max);
         printf(msg); 
         //Comment(msg);
         globalVarManager.updateSlTp(-sl_max,tp_max);
         globalVarManager.unBlockTrading(); 
         labelManager.updateLabels(max);
      }else{
         globalVarManager.blockTrading();
         labelManager.updateLabels(max);  
      //   printf("trading blocked");
      }
   }
   

   double getEquity(double tp,double sl){       
       double result=iCustom(NULL,0,"trendIndicator",tp,sl,pattern.history_depth,false,pattern.sl_tp_limit,pattern.spread,6,1)*100;
       if(result!=2147483647){
         return  result;        
       }else{
         return -100;
       }
    
   }
};