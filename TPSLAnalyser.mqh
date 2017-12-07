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
#include <Logger.mqh>

class TPSLAnalyser{ 
 Shared2 *shared;
 public:   
   TPSLAnalyser(double defaultSL_,double defaultTP_, Shared2* &shared_){
      shared=shared_;
      defaultTPSL.SL=defaultSL_;
      defaultTPSL.TP=defaultTP_;
      idealTPSL.SL=0;
      idealTPSL.TP=0;   
   }
   
  void update(double targetPrice_,double openPrice_,datetime start_,datetime finish_ ){
      if(start!=start_){
         start=start_;
         finish=finish_;
         openPrice=openPrice_;
         targetPrice=targetPrice_;
         updateIdealTPLS();      
      }   
   };
   
  TPSL getIdealTPSL(){
   
     printf("ideal: SL="+DoubleToStr(idealTPSL.SL,2)+" TP="+DoubleToStr(idealTPSL.TP,2));
      if((idealTPSL.SL==0)||
         (idealTPSL.TP==0)||
         (idealTPSL.TP<idealTPSL.SL)
         ){         
            printf("TPSL: applied default values");
            return defaultTPSL;
      }

   TPSL finalValues;
   finalValues.SL=idealTPSL.SL;
   finalValues.TP=idealTPSL.TP;
      
      if(
         (idealTPSL.TP>1)||
         (idealTPSL.TP<0.3)
         ){
         finalValues.TP=defaultTPSL.TP;
         printf("TPSL: default TP");       
      }
      
     if(
         (idealTPSL.SL>1)||
         (idealTPSL.SL<0.3)
         ){
         finalValues.SL=defaultTPSL.SL;
         printf("TPSL: default SL");
      }
      
            
      return finalValues;
   }
   
   
 private:
 
 TPSL idealTPSL;
 TPSL defaultTPSL;
 datetime start, finish;
 double openPrice,targetPrice;
 
 void updateIdealTPLS(){
   int extreamShift,appositeExtreameShift;
   double appositeExtreame,appositeExtreamPips;
   
   double lowestPips=getDeltaPips(true);   
   double highestPips=getDeltaPips(false);
   
   if(highestPips>lowestPips){
       extreamShift=getExtreameShiftInAllDomain(false);
       appositeExtreameShift=getRelativeExtreameShift(true,extreamShift); 
       appositeExtreame=iLow(NULL,0,appositeExtreameShift);   
       appositeExtreamPips=MathAbs(appositeExtreame-openPrice)*shared.getKoef();
     
      fillIdealTPSL(highestPips,appositeExtreamPips);
      
   }else{
       extreamShift=getExtreameShiftInAllDomain(true);
       appositeExtreameShift=getRelativeExtreameShift(false,extreamShift); 
       appositeExtreame=iHigh(NULL,0,appositeExtreameShift);   
       appositeExtreamPips=MathAbs(appositeExtreame-openPrice)*shared.getKoef();
     
       fillIdealTPSL(lowestPips,appositeExtreamPips);   
   }      
 }
 
 void fillIdealTPSL(double TPpips,double SLpips){
  double targetPips=MathAbs(targetPrice-openPrice)*shared.getKoef();
  idealTPSL.TP=TPpips/targetPips;
  idealTPSL.SL=SLpips/targetPips; 
 }
 
 int getRelativeExtreameShift(bool calcLow,int shift){   
   int startShift=iBarShift(NULL,0,start);
   if(calcLow){
       return iLowest(NULL,0,MODE_LOW,(startShift-shift),shift);   
   }else{
       return iHighest(NULL,0,MODE_HIGH,(startShift-shift),shift);    
   }
 }
 
 int getExtreameShiftInAllDomain(bool calcLow){ 
   int finishShift=iBarShift(NULL,0,finish);
   return getRelativeExtreameShift(calcLow,finishShift);
 }
 
 
 double getDeltaPips(bool calcLow){
   double extream;
   int peakShiftClosest;
   peakShiftClosest=getExtreameShiftInAllDomain(calcLow); 
   if(calcLow){ 
      extream=iLow(NULL,0,peakShiftClosest);   
      return MathAbs(extream-openPrice)*shared.getKoef();   
   }else{         
      extream=iHigh(NULL,0,peakShiftClosest);   
      return MathAbs(extream-openPrice)*shared.getKoef();
   }
 }
 
 
};