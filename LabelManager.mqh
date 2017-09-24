//+------------------------------------------------------------------+
//|                                                    userInput.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <GlobalVarManager.mqh>

class LabelManager{
string LABEL_TP_SL;
string LABEL_TIME_OUT;
string LABEL_WORK_LIMIT;
string LABEL_STOP_TRADING;
GlobalVarManager *globalVarManager;
public:
   LabelManager(){
      LABEL_TP_SL="LABEL_TP_SL";
      LABEL_TIME_OUT="LABEL_TIME_OUT";
      LABEL_WORK_LIMIT="LABEL_WORK_LIMIT";
      LABEL_STOP_TRADING="LABEL_STOP_TRADING";
      
      globalVarManager=new GlobalVarManager();
 
      createLabel(LABEL_TP_SL,32,"1.0_-0.6");
     // createLabel(LABEL_TIME_OUT,52,"3");
      //createLabel(LABEL_WORK_LIMIT,72,"10");
      createLabel(LABEL_STOP_TRADING,92,"0");
   }
   
   
void updateLabels(double equity){
     Pattern pattern= globalVarManager.getPattern();
     updateLabelValues(equity,pattern.tp,pattern.sl);
     
     ObjectSetString(0,LABEL_STOP_TRADING,OBJPROP_TEXT,DoubleToStr(pattern.blockTrading,0));
   }
  
void parseValues(){

   SL_TP sl_tp=parseSL_TP();
   double timeOut= parse_OneValue(LABEL_TIME_OUT);
   double workLimit= parse_OneValue(LABEL_WORK_LIMIT);
   double stopTrading= parse_OneValue(LABEL_STOP_TRADING);
       
  }
  

  
private:

  void updateLabelValues(double equity,double tp, double sl){
   string text= DoubleToStr(equity,1)+": "+DoubleToStr(tp,1)+"_-"+DoubleToStr(sl,1);  
   ObjectSetString(0,LABEL_TP_SL,OBJPROP_TEXT,text);
  }
  
  double  parse_OneValue(string labelName){
      string str_value=ObjectGetString(0,labelName,OBJPROP_TEXT,0);
      return StringToDouble(str_value);
   }
   
   struct SL_TP{
      double 
      SL,
      TP;  
   };
   
  SL_TP parseSL_TP(){
      string to_split=ObjectGetString(0,LABEL_TP_SL,OBJPROP_TEXT,0);
      string sep="_";                // A separator as a character 
      ushort u_sep;                  // The code of the separator character 
      string result[];               // An array to get strings
      double resultDouble[2]; 
      u_sep=StringGetCharacter(sep,0); 
      StringSplit(to_split,u_sep,result);
      SL_TP sl_tp;
      sl_tp.TP=StringToDouble( result[0]);
      sl_tp.SL=MathAbs(StringToDouble( result[1]));
      return sl_tp;

  }

   
void createLabel(string name,int height,string initValue){
       
  color
   clrBrdBtn=clrWhite,
   clrBrdFonMsg=clrDarkOrange,clrFonMsg=C'15,15,15',
   clrChoice=clrWhiteSmoke,clrHdrBtn=clrDarkOrange,
   clrFonHdrBtn=clrGainsboro,clrFonStr=C'22,39,38';

   long corner=CORNER_RIGHT_UPPER;
   string bsc_fnt="Calibri";
   int
   fonW=200,fonH=100;
    int   
    width_chart=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0),
    height_chart=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);

   int
   FnHdrX=(width_chart/2)-(fonW/2),
   FnHdrY=(height_chart/2)-(fonH/2);
   
   int
   fln=16, // First line
   hln=12; // Line height
  
   createEdit(0,0,name,initValue,corner,"Arial",14,clrBrdFonMsg,100,20,367,height,2,clrFonMsg,0); 

}


void createEdit(long   chrt_id,   // chart id
                int    nmb_win,   // (sub)window number
                string lable_nm,  // object name
                string text,      // displayed text
                long   corner,    // anchor corner
                string font_bsc,  // font
                int    font_size, // font size
                color  font_clr,  // font color
                int    xsize,     // width
                int    ysize,     // height
                int    x_dist,    // coordinate along the X-axis
                int    y_dist,    // coordinate along the Y-axis
                long   zorder,    // Z order
                color  clr,       // background color
                bool   flgORead)  // Read Only flag
  {
   if(ObjectCreate(chrt_id,lable_nm,OBJ_LABEL,nmb_win,0,0)) // create the object
     {
     
      ObjectSetString(chrt_id,lable_nm,OBJPROP_TEXT,text);            // set the name
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_CORNER,corner);       // set the anchor corner
      ObjectSetString(chrt_id,lable_nm,OBJPROP_FONT,font_bsc);        // set the font
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_FONTSIZE,font_size);  // set the font size
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_COLOR,font_clr);      // font color
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_BGCOLOR,clr);         // background color
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_XSIZE,xsize);         // width
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_YSIZE,ysize);         // height
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_XDISTANCE,x_dist);    // set the X-coordinate
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_YDISTANCE,y_dist);    // set the Y-coordinate
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_SELECTABLE,true);    // cannot select the object if FALSE
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_ZORDER,zorder);       // Higher/lower Z order
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_READONLY,flgORead);   // Read Only
      ObjectSetInteger(chrt_id,lable_nm,OBJPROP_ALIGN,ALIGN_LEFT);    // Align left
      ObjectSetString(chrt_id,lable_nm,OBJPROP_TOOLTIP,"\n");         // no tooltip if "\n"
     }
  
  }

};



  
  