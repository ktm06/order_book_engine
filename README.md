**System Overview**

This is a order book observer written in SystemVerilog, which takes in a live market feed and tracks best spread. The current architecture connects a Windows device <=> programmed FPGA using UART. 

More specifically, we have a L2 Order Book Engine inside the FPGA, where we store memory of all Asks and Bids, and continuously track the best spread. We add orders to this FPGA through a C++ program running on Windows through UART, and the same script receives best spread. 

**SV File Structure**

```
\ rtl
  \ Ask_Comparator.sv  # combinational module to get the lowest Ask price in memory
  \ Bid_Comparator.sv  # combinational module to get highest Bid price in memory
  \ CDC_Input_Synchronizer.sv  # prevents metastability in UART RX
  \ Message_Decoder.sv  # decoded reconstructed message to get ordertype, side, price, and size
  \ Message_Parser.sv  # reconstructs UART RX into message format
  \ Order_Book_Engine.sv # 5-state FSM that maintains Ask and Bid memory and returns best spread
  \ Order_Book_Observe_TopLevel.sv # TopLevel of entire architecture
  \ Result_Serializer  # Serializing best_spread for UART TX 
```
