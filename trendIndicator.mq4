//--------------------------------------------------------------------
// separatewindow.mq4 
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
 
#property indicator_separate_window // Drawing in a separate window
#property indicator_buffers 8       // Number of buffers


#property indicator_color1 Blue     // Color of the 1st line
#property indicator_label1 "PROFIT_MAX "

#property indicator_color2 Red      // Color of the 2nd line
#property indicator_label2 "LOSS_MAX"

#property indicator_color3 Green      // Color of the 2nd line
#property indicator_label3 "TP"

#property indicator_color4 Green      // Color of the 2nd line
#property indicator_label4 "SL"

#property indicator_color5 Red      // Color of the 2nd line
#property indicator_label5 "LOSS"

#property indicator_color6 Green      // Color of the 2nd line
#property indicator_label6 "PROFIT"

#property indicator_color7 Green      // Color of the 2nd line
#property indicator_label7 "equity"

#property indicator_color8 Green      // Color of the 2nd line
#property indicator_label8 "----"

#include <GlobalVarManager.mqh>;
#include <Shared.mqh>; 
double Buf_1[],Buf_2[],Buf_3[],Buf_4[],Buf_5[],Buf_6[],Buf_7[],Buf_8[];                     // Declaring an indicator array
double KOEF,ICON_HEIGHT;

GlobalVarManager *globalVarManager;
Shared *shared; 

input double TP_LEVEL=1.0;
input double SL_LEVEL=-0.5;
input int HISTORY_DEPTH=50;
input bool isGlobalParamsValid=true;
 
//--------------------------------------------------------------------
int init()                          // Special function init()
  {
   SetIndexBuffer(0,Buf_1);         // Assigning an array to a buffer
   SetIndexBuffer(1,Buf_2);
   SetIndexBuffer(2,Buf_3); 
   SetIndexBuffer(3,Buf_4); 
   SetIndexBuffer(4,Buf_5); 
   SetIndexBuffer(5,Buf_6); 
   SetIndexBuffer(6,Buf_7); 
   SetIndexBuffer(7,Buf_8); 
   SetIndexStyle (0,DRAW_HISTOGRAM);
   SetIndexStyle (1,DRAW_HISTOGRAM);
   SetIndexStyle (2,DRAW_HISTOGRAM);
   SetIndexStyle (3,DRAW_HISTOGRAM);
   SetIndexStyle (4,DRAW_ARROW,STYLE_SOLID,2);
   SetIndexStyle (5,DRAW_ARROW,STYLE_SOLID,2);
   SetIndexStyle (6,DRAW_HISTOGRAM);
   SetIndexStyle (7,DRAW_HISTOGRAM);
   
   IndicatorSetInteger(INDICATOR_LEVELS,1); 
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,0.0); 

   KOEF=getKoef();   
   globalVarManager = new GlobalVarManager();
   shared = new Shared(); 
   
   ICON_HEIGHT=1.1;
   return 0;                          // Exit the special funct. init()
  }
void cleanOldArrays()
   {
    ArrayInitialize(Buf_1,EMPTY_VALUE);
    ArrayInitialize(Buf_2,EMPTY_VALUE);
    ArrayInitialize(Buf_3,EMPTY_VALUE);
    ArrayInitialize(Buf_4,EMPTY_VALUE);
    ArrayInitialize(Buf_5,EMPTY_VALUE);
    ArrayInitialize(Buf_6,EMPTY_VALUE);
    ArrayInitialize(Buf_7,EMPTY_VALUE);
    ArrayInitialize(Buf_8,EMPTY_VALUE);
   }



int start()                         // Special function start()
  { 
   int i, Counted_bars;
   
   //if(!shared.isNewBar())return 0;   
   //shared.setIsNewBarFalse();
   
   
   Pattern pattern=globalVarManager.getPattern(); 
   
   if(!isGlobalParamsValid){
      pattern.tp=TP_LEVEL;
      pattern.sl=MathAbs(SL_LEVEL);   
   }

     
   i=HISTORY_DEPTH; 
   cleanOldArrays(); 
   bool isTimeOut=false;
   double summ_tp=0;
   double summ_sl=0;     
   while(i>0)                   
     {
      double SL=getSLValue(i,pattern.bodyWorkLimit);  
      if(SL!=0){
         Buf_3[i]=pattern.tp;
         Buf_4[i]=-pattern.sl;      
      }else{
         Buf_3[i]=Buf_3[i]=0;
      }
               
      double MainBarClosePrice=iClose(NULL,0,i);
      bool isMainbull=isBullBar(i);
      
      if(SL!=0){
      
         for (int j=1;j<=pattern.orderTimeOut;j=j+1){
           i--;
           if(i<0){
               //printf("algorithm error i=-1");
               break;
           };         
           int plus=getPlusValue(i,isMainbull,MainBarClosePrice);
           int minus=getMinusValue(i,isMainbull,MainBarClosePrice);

           if (plus>0){setBuf1(plus/SL,i);}
           if (minus<0){Buf_2[i]=minus/SL;}
                       
           if (MathAbs(minus)>SL*pattern.sl&&minus<0){//SL
               isTimeOut=false;
               if (MathAbs(plus)>SL*pattern.tp){
                  //nothing, not TP, not SL
               } 
               else{
                  Buf_5[i]=-pattern.sl;
                  summ_sl=summ_sl+Buf_5[i];
                  Buf_2[i]=Buf_5[i];                                
               }
               i++;break;               
             } 
             
           if (MathAbs(plus)>SL*pattern.tp&&plus>0){isTimeOut=false;Buf_6[i]=pattern.tp;summ_tp=summ_tp+Buf_6[i];Buf_2[i]=minus/SL;i++;break;}   //TP
         isTimeOut=true;
         }
         if((i-1)>0&&isTimeOut){//timeOut
         
            double tmp=(iOpen(NULL,0,i-1)-MainBarClosePrice)*KOEF/SL;
            if(isMainbull){
               Buf_5[i]=tmp;
               summ_tp=summ_tp+Buf_5[i];
            }else{
               Buf_5[i]=-tmp;
               summ_sl=summ_sl+Buf_5[i];
            }           
         }           
      }      
      i--;                    
     }
     
     Buf_7[1]=(summ_tp+summ_sl)/100;
   return 0;                          // Exit the special funct. start()
  }
  
  void setBuf1(double value,const int i){
     if(value>1.5){
       Buf_1[i]=1.5;
     }else{
       Buf_1[i]=value;
     }
  }
  
  int getMinusValue(int j,bool isMainbull,double MainBarClosePrice){
  int  minus;
       if(isMainbull){//buy
          minus=(iLow(NULL,0,j)-MainBarClosePrice)*KOEF;
      }else{       //sell    
         minus=-(iHigh(NULL,0,j)-MainBarClosePrice)*KOEF;            
     }
   return minus;
  }  
  
  int getPlusValue(int j,bool isMainbull,double MainBarClosePrice){ 
   int  plus; 
       if(isMainbull){//buy
          plus=(iHigh(NULL,0,j)-MainBarClosePrice)*KOEF;
      }else{       //sell    
         plus=-(iLow(NULL,0,j)-MainBarClosePrice)*KOEF;
      }
   return plus;
  }
  
  bool isBullBar(int i){
   return (iOpen(NULL,0,i)<iClose(NULL,0,i));
  }
  
  double getSLValue(int i, double bodyLimit){
    double extream,sl;   
      
   if(isBullBar(i)){      // buy     
      extream=iLow(NULL,0,i);  
   }else{   // sell
      extream=iHigh(NULL,0,i);      
   }
   sl= (MathAbs(iClose(NULL,0,i)-extream))*KOEF;
   if(shared.getBarBody(i)<bodyLimit)return 0;   
   if(MathAbs(iClose(NULL,0,i)-iOpen(NULL,0,i))*KOEF<10)return 0;   
   return sl;
 }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   int getKoef(){
      int koefLocal=1; 
      for (int i=1;i<Digits;i=i+1){
         koefLocal=koefLocal*10;
      }
      return koefLocal;
  }
//--------------------------------------------------------------------