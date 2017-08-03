//--------------------------------------------------------------------
// separatewindow.mq4 
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
#property indicator_separate_window // Drawing in a separate window
#property indicator_buffers 1       // Number of buffers
#property indicator_color1 Blue     // Color of the 1st line
#property indicator_color2 Red      // Color of the 2nd line
#property indicator_color3 Green      // Color of the 2nd line
#property indicator_color4 Green      // Color of the 2nd line
 
extern int History  =1500;            // Amount of bars in calculation history
extern int Aver_Bars=5;             // Amount of bars for calculation
 
double Buf_0[],Buf_1[],Buf_3[],Buf_4[];                     // Declaring an indicator array
 double KOEF;
//--------------------------------------------------------------------
int init()                          // Special function init()
  {
   SetIndexBuffer(0,Buf_0);         // Assigning an array to a buffer
   SetIndexBuffer(1,Buf_1);
   SetIndexBuffer(2,Buf_3); 
   SetIndexBuffer(3,Buf_4); 
 //  SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2);// line style
    SetIndexStyle (0,DRAW_HISTOGRAM);// Line style
    SetIndexStyle (1,DRAW_HISTOGRAM);// Line style
    SetIndexStyle (2,DRAW_HISTOGRAM);// Line style
    SetIndexStyle (3,DRAW_HISTOGRAM);// Line style
    
    KOEF=getKoef();
    return;                          // Exit the special funct. init()
  }
//--------------------------------------------------------------------
int start()                         // Special function start()
  {
   int i,y, Counted_bars;                        
//--------------------------------------------------------------------
   Counted_bars=IndicatorCounted();
   i=Bars-Counted_bars-1;        
   if (i>History-1)              
      i=History-1;               
   while(i>=0)                   
     {
      double Hp,Hs,T;
         
      Buf_3[i]=getSLValue(i);
      Buf_4[i]=-getSLValue(i);
      int SL=getSLValue(i) ;         
      double MainstartPrice=iClose(NULL,0,i);
      bool isMainbull=isBullBar(i);
      if(SL!=0){
            i--;
           
              int plus=MathAbs((iHigh(NULL,0,i)-MainstartPrice)*KOEF);          
              int minus=MathAbs((iLow(NULL,0,i)-MainstartPrice)*KOEF);
              if(isMainbull){
                  Buf_0[i]=plus;
                  Buf_1[i]=-minus;
              }else{
                  Buf_0[i]=minus;
                  Buf_1[i]=-plus;               
              }
              
         
      
      }
      for(y=i;y<=i-Aver_Bars-1;y--)
        {
            
            
        }
      i--;                    
     }
//--------------------------------------------------------------------
   return;                          // Exit the special funct. start()
  }
  
  bool isBullBar(int i){
   return (iOpen(NULL,0,i)<iClose(NULL,0,i));
  }
  
  int getSLValue(int i){
 
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