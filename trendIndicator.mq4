//--------------------------------------------------------------------
// separatewindow.mq4 
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
#property indicator_separate_window // Drawing in a separate window
#property indicator_buffers 6       // Number of buffers
#property indicator_color1 Blue     // Color of the 1st line
#property indicator_color2 Red      // Color of the 2nd line
#property indicator_color3 Green      // Color of the 2nd line
#property indicator_color4 Green      // Color of the 2nd line
#property indicator_color5 Red      // Color of the 2nd line
#property indicator_color6 Green      // Color of the 2nd line
 
extern int HISTORY_DEPTH=5;             // Amount of bars for calculation
 
double Buf_0[],Buf_1[],Buf_3[],Buf_4[],Buf_5[],Buf_6[];                     // Declaring an indicator array
double KOEF;
//--------------------------------------------------------------------
int init()                          // Special function init()
  {
   SetIndexBuffer(0,Buf_0);         // Assigning an array to a buffer
   SetIndexBuffer(1,Buf_1);
   SetIndexBuffer(2,Buf_3); 
   SetIndexBuffer(3,Buf_4); 
   SetIndexBuffer(4,Buf_5); 
   SetIndexBuffer(5,Buf_6); 
   SetIndexStyle (0,DRAW_HISTOGRAM);// Line style
   SetIndexStyle (1,DRAW_HISTOGRAM);// Line style
   SetIndexStyle (2,DRAW_HISTOGRAM);// Line style
   SetIndexStyle (3,DRAW_HISTOGRAM);// Line style
   SetIndexStyle (4,DRAW_ARROW,STYLE_SOLID,2);// line style
   SetIndexStyle (5,DRAW_ARROW,STYLE_SOLID,2);// line style
   SetLevelValue(0,0.0);
    KOEF=getKoef();
    return;                          // Exit the special funct. init()
  }
//--------------------------------------------------------------------
int start()                         // Special function start()
  {
  
   int i,y, Counted_bars; 
                          
//--------------------------------------------------------------------

//   int History  =1500;            // Amount of bars in calculation history
//   Counted_bars=IndicatorCounted();
//   i=Bars-Counted_bars-1;        
//   if (i>History-1)              
//      i=History-1;  
      i=HISTORY_DEPTH;       
   while(i>0)                   
     {
      double Hp,Hs,T;
      double SL=getSLValue(i) ;  
      if(SL!=0){
         Buf_3[i]=SL/SL;
         Buf_4[i]=-SL/SL;      
      }else{
         Buf_3[i]=Buf_3[i]=0;
      }
               
      double MainBarClosePrice=iClose(NULL,0,i);
      bool isMainbull=isBullBar(i);
      if(SL!=0){
      
         for (int j=1;j<=3;j=j+1){
           i--;           
           int plus;         
           int minus;
           if(isMainbull){
               plus=(iHigh(NULL,0,i)-MainBarClosePrice)*KOEF;
               minus=(iLow(NULL,0,i)-MainBarClosePrice)*KOEF;
            }else{           
               plus=-(iLow(NULL,0,i)-MainBarClosePrice)*KOEF;
               minus=-(iHigh(NULL,0,i)-MainBarClosePrice)*KOEF;            
           }
           if (MathAbs(minus)>SL&&minus<0){Buf_5[i]=-1.1;i++;break;} 
           if (MathAbs(plus)>SL&&plus>0){Buf_6[i]=1.1;i++;break;} 
           if(plus>0){Buf_0[i]=plus/SL;}
           if(minus<0){Buf_1[i]=minus/SL;}
         }
           
      }      
      i--;                    
     }
//--------------------------------------------------------------------
   return;                          // Exit the special funct. start()
  }
  
  bool isBullBar(int i){
   return (iOpen(NULL,0,i)<iClose(NULL,0,i));
  }
  
  double getSLValue(int i){
 
   double extream,sl;  
  
      
   if(isBullBar(i)){      // buy     
      extream=iLow(NULL,0,i);  
   }else{   // sell
      extream=iHigh(NULL,0,i);      
   }
    sl= (MathAbs(iClose(NULL,0,i)-extream))*KOEF;
    if(sl<10)return 0;
    
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