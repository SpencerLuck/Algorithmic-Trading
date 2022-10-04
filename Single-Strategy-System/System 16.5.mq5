//+------------------------------------------------------------------+
//|                                                   System16.5.mq5 |
//|                                                     Spencer Luck |
//+------------------------------------------------------------------+

// Importing files to use methods
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

// Object CTrade as trade
CTrade trade;
// Object CPositionInfo as pos_info
CPositionInfo pos_info;

// Inputs
input int JTPO_period = 27;
input int JTPO_price = 0;
input int Wad_fast_MA = 22;
input int Wad_slow_MA = 35;
input int Wad_bollinger = 20;
input int Wad_bollinger_dev = 2;
input int Wad_sens = 150;
input int Wad_DZP = 3000;
input int Schaff_period = 50;
input int Schaff_fast_EMA = 10;
input int Schaff_slow_EMA = 15;
input int Schaff_smooth = 3;
input int Schaff_price = 0;
input int MA_period = 6;
input ENUM_MA_METHOD MA_mode=MODE_SMA;
input int Oscar_period = 7;
input int Oscar_signal_period = 11;

// position modifier count
int positionmodifiercount = 0;

int OnInit()
  {
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  {

// Restrict code to process only once per bar
   static datetime timestamp;
   datetime time = iTime(_Symbol,PERIOD_CURRENT,0); // Time of current candle
   if(timestamp != time)
     {
      timestamp = time;


      //ATR
      static int HandleAtr = iATR(_Symbol, PERIOD_CURRENT,14);
      double AtrArray[];
      CopyBuffer(HandleAtr,0,1,2,AtrArray);
      ArraySetAsSeries(AtrArray,true);
      //J_TPO
      static int HandleJTPO = iCustom(_Symbol,PERIOD_CURRENT,"j_tpo",JTPO_period,JTPO_price);
      double JTPOArray[];
      CopyBuffer(HandleJTPO,0,1,2,JTPOArray);
      ArraySetAsSeries(JTPOArray,true);
      //Waddah Attar Explosion
      static int handleWAD = iCustom(_Symbol,PERIOD_CURRENT,"waddah_attar_explosion",Wad_fast_MA,Wad_slow_MA,Wad_bollinger,Wad_bollinger_dev,Wad_sens,Wad_DZP,15,15,false,500,false,false,false,false);
      //waddah - MACD
      double MACDWADarray[];
      CopyBuffer(handleWAD,0,1,2,MACDWADarray);
      ArraySetAsSeries(MACDWADarray,true);
      //waddah - Signal Line
      double SLWADarray[];
      CopyBuffer(handleWAD,2,1,2,SLWADarray);
      ArraySetAsSeries(SLWADarray,true);
      //waddah - Dead Zone Pip
      double DZPWADarray[];
      CopyBuffer(handleWAD,3,1,2,DZPWADarray);
      ArraySetAsSeries(DZPWADarray,true);
      // Candle Ratio
      static int HandleSchaff = iCustom(_Symbol,PERIOD_CURRENT,"Schaff Trend Cycle",Schaff_period,Schaff_fast_EMA,Schaff_slow_EMA,Schaff_smooth,Schaff_price);
      double SchaffArray[];
      CopyBuffer(HandleSchaff,1,1,2,SchaffArray);
      ArraySetAsSeries(SchaffArray,true);
      // Simple Moving Average
      static int HandleMA = iMA(_Symbol,PERIOD_CURRENT,MA_period,0,MA_mode,PRICE_CLOSE);
      double ArrayMA [];
      CopyBuffer(HandleMA,0,1,2,ArrayMA);
      ArraySetAsSeries(ArrayMA,true);
      //Oscar
      static int HandleOscar = iCustom(_Symbol,PERIOD_CURRENT,"Oscar",Oscar_period,Oscar_signal_period);
      //Oscar - Ratio
      double OscarArray[];
      CopyBuffer(HandleOscar,0,1,2,OscarArray);
      ArraySetAsSeries(OscarArray,true);
      //Oscar - Signal
      double SignalArray[];
      CopyBuffer(HandleOscar,1,1,2,SignalArray);
      ArraySetAsSeries(SignalArray,true);


      // Getting the close price of candle
      double CloseArray[];
      CopyClose(_Symbol,PERIOD_CURRENT,1,2,CloseArray);
      ArraySetAsSeries(CloseArray,true);

      // Buy conditions
      bool JTPO_buy = (JTPOArray[0] > 0 && JTPOArray[1] < 0);
      bool Schaff_buy = (SchaffArray[0] == 1);
      bool MA_buy = (ArrayMA[0] < CloseArray[0]);
      bool Oscar_buy = (OscarArray[0] > SignalArray[0]);


      // Volume condition
      bool Wad_vol = (MACDWADarray[0] > SLWADarray[0] && MACDWADarray [0] > DZPWADarray[0]);

      // Sell conditions
      bool JTPO_sell = (JTPOArray[0] < 0 && JTPOArray[1] > 0);
      bool Schaff_sell = (SchaffArray[0] == 2);
      bool MA_sell = (ArrayMA[0] > CloseArray[0]);
      bool Oscar_sell = (OscarArray[0] < SignalArray[0]);


      // Exit conditions
      bool Oscar_sell_exit = (OscarArray[0] > SignalArray[0] && OscarArray[1] < SignalArray[1]);
      bool Oscar_buy_exit = (OscarArray[0] < SignalArray[0] && OscarArray[1] > SignalArray[1]);


      bool Buy_opened=false;  // variable to hold the result of Buy opened position
      bool Sell_opened=false; // variables to hold the result of Sell opened position

      if(PositionSelect(_Symbol)==true)
        {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
           {
            Buy_opened=true;  
           }
         else
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               Sell_opened=true; 
              }
        }


      // Managing positions, modifying second trade (moving SL)
      // Checking how many positions are open

      int current_open_positions = PositionsTotal(); // Might cause a problem with live testing.
       
      if (current_open_positions == 0 && positionmodifiercount == 1)
      {
      positionmodifiercount -= 1 ;
      }
       
      if(Buy_opened && current_open_positions == 1)
        {
         double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
         double AtrFactor = NormalizeDouble(AtrArray[0] * 1.5,_Digits);
         CheckTrailingStopBuy(Ask,AtrFactor);
        }

      if(Sell_opened && current_open_positions == 1)
        {
         double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
         double AtrFactor = NormalizeDouble(AtrArray[0] * 1.5,_Digits);
         CheckTrailingStopSell(Bid,AtrFactor);
        }


      // Exit conditions

      if(Buy_opened && Oscar_buy_exit)
        {
         if(pos_info.Symbol()==Symbol())
            CloseAllPositions();
        }

      if(Sell_opened && Oscar_sell_exit)
        {
         if(pos_info.Symbol()==Symbol())
            CloseAllPositions();
        }

      if(Buy_opened && JTPO_sell)
        {
         if(pos_info.Symbol()==Symbol())
            CloseAllPositions();
        }

      if(Sell_opened && JTPO_buy)
        {
         if(pos_info.Symbol()==Symbol())
            CloseAllPositions();
        }

      if(Buy_opened && MA_sell)
        {
         if(pos_info.Symbol()==Symbol())
            CloseAllPositions();
        }

      if(Sell_opened && MA_buy)
        {
         if(pos_info.Symbol()==Symbol())
            
          CloseAllPositions();
        }


      // Placing Buy orders
      if(JTPO_buy  && Wad_vol && Schaff_buy && MA_buy && Oscar_buy)
        {
         Print("System 16.5 indicates a buy signal");
         
         // Closing open sell positions
         if(Sell_opened)
           {
            if(pos_info.Symbol()==Symbol())
               trade.PositionClose(pos_info.Ticket());
           }

         double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double AtrFactorSl = AtrArray[0] * 1.5;
         double AtrFactorTP = AtrArray[0] * 1;
         double Acc_risk = AccountInfoDouble(ACCOUNT_BALANCE) * 0.01;
         double Volume = Acc_risk/(AtrFactorSl/Point());
         double Lots = NormalizeDouble(Volume,2);
         double sl = ask - AtrFactorSl;
         double tp = ask + AtrFactorTP;
         trade.Buy(Lots,_Symbol,ask,sl,tp,"Buy1");
         trade.Buy(Lots,_Symbol,ask,sl,NULL,"Buy2");

        }

      // Placing Sell orders
      if(JTPO_sell && Wad_vol && Schaff_sell && MA_sell && Oscar_sell)
        {
         Print("System 16.5 indicates a sell signal");


         // Closing open buy positions
         if(Buy_opened)
           {
            if(pos_info.Symbol()==Symbol())
               trade.PositionClose(pos_info.Ticket());
           }

         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double AtrFactorSl = AtrArray[0] * 1.5;
         double AtrFactorTP = AtrArray[0] * 1;
         double Acc_risk = AccountInfoDouble(ACCOUNT_BALANCE) * 0.01;
         double Volume = Acc_risk/(AtrFactorSl/Point());
         double Lots = NormalizeDouble(Volume,2);
         double sl = bid + AtrFactorSl;
         double tp = bid - AtrFactorTP;
         trade.Sell(Lots,_Symbol,bid,sl,tp,"Sell1");
         trade.Sell(Lots,_Symbol,bid,sl,NULL,"Sell2");

        }

     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTrailingStopBuy(double ask, double AtrFactor)
  {

// set the stop loss to 150 points
   double SL=NormalizeDouble(ask-AtrFactor,_Digits);

// go through all positions
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      string symbol=PositionGetSymbol(i); // get the symbol of the position


      if(_Symbol == symbol) // if the current symbol of the pair is equal
        {
         if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_BUY)
           {
            // get the ticket number
            ulong PositionTicket = PositionGetInteger(POSITION_TICKET);

            // get position open price
            double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),_Digits);

            // calculate the current stop loss
            double CurrentStopLoss = PositionGetDouble(POSITION_SL);
            
            // Assume a min of 2pips 
            double MinTradeStops = 20*_Point;
               
   
            // Check if stop loss is too close to price or if price has moved back past the open price
            if((ask - PositionOpen) <= MinTradeStops || ask < PositionOpen)
              {
               CloseAllPositions();
              }  
               
               
            else
               {
                  // move stop loss to open price, therefore zero loss
                  if(CurrentStopLoss < PositionOpen && positionmodifiercount == 0)
                    {
                     trade.PositionModify(PositionTicket,PositionOpen,NULL);
                     
                    }
                  // if current stop loss is more than 150 points
                  if(CurrentStopLoss < SL && positionmodifiercount == 1)
                    {
                     // move the stop loss
                     trade.PositionModify(PositionTicket,SL,NULL);
                    }
                    
                  if(positionmodifiercount == 0){
                     positionmodifiercount += 1;
                    }

               }
               
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTrailingStopSell(double bid, double AtrFactor)
  {

// set the stop loss to ATR points
   double SL=NormalizeDouble(bid+AtrFactor,_Digits);

// go through all positions
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      string symbol=PositionGetSymbol(i); // get the symbol of the position


      if(_Symbol == symbol) // if the current symbol of the pair is equal
        {

         if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_SELL)
           {
            // get the ticket number
            ulong PositionTicket = PositionGetInteger(POSITION_TICKET);

            // get position open price
            double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),_Digits);

            // calculate the current stop loss
            double CurrentStopLoss = PositionGetDouble(POSITION_SL); //works
            
            // Assume a min of 2pips. Run SymbolInfoInteger(SYMBOL_TRADE_STOPS_LEVEL) other brokers 
             double MinTradeStops = 20*_Point;
               
   
            // Check if stop loss is too close to price or if price has moved back past the open price
            if((PositionOpen - bid) <= MinTradeStops || bid > PositionOpen)
              {
                  CloseAllPositions();
              }

            
            else
               {
            
               // move stop loss to open price, therefore zero loss
               if(CurrentStopLoss > PositionOpen && positionmodifiercount == 0)
                 {
                 //Print(CurrentStopLoss);
                  trade.PositionModify(PositionTicket,PositionOpen,NULL);
                  
                 }
               // if current stop loss is more than ATR points
               if(CurrentStopLoss > SL && positionmodifiercount == 1)
                 {
                  // move the stop loss
                  trade.PositionModify(PositionTicket,SL,NULL);
                 }
                 
               if(positionmodifiercount == 0){
                 positionmodifiercount += 1;
                 }

               }
 
           }
        }
     }
  }





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {

// Count down until there are no positions left
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
     string symbol=PositionGetSymbol(i); // get the symbol of the position
     if(_Symbol == symbol)
     
     { 
      // Get the position number
      ulong ticket = PositionGetTicket(i);

      // Close the position
      trade.PositionClose(ticket);
      }
     }


  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
