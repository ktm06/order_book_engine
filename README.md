# Overview

This is a order book observer written in SystemVerilog, which takes in a live market feed and tracks best spread. The current architecture connects a Windows device <=> programmed FPGA using UART. 

More specifically, we have a L2 Order Book Engine inside the FPGA, where we store memory of all Asks and Bids, and continuously track the best spread. We add orders to this FPGA through a C++ program running on Windows through UART, and the same script receives best spread. 

# Chapters

1. [Architecture](#Architecture)
2. [SV File Structure](#Sv-file-structure)
3. [Requirements](#Requirements)

# Architecture

# ISA

We use a custom format which encodes **instruction type, order side (ASK or BID), order size, and price**, in a 10 byte message, big-endian format. This is received via UART from our program to the FPGA. (big-endian first):

\[ 79 : 72 ]  \[ 71 : 64 ] \[ 63 : 32 ] \[ 31 : 0 ] <- the 80-bit message

↑ instrtype     ↑ order side   ↑ price    ↑ size

We have three instr types:

**ADD**(```00000001```): Add some order @ {price} of {size}. If pricepoint not stored in buffer, initialize in new buffer, else add {size} to existing pricepoint.

**DEL**(```00000010```): Delete some order @ {price} of {size}. Subtract from existing pricepoint the {size}. If reduced size is 0 or less, reset that memory element (aka set it to 32'b0). NEVER go below 0.

**MOD**(```00000011```):: Modify size corresponding to {price} to {size}. If {price} is not stored, do nothing.

And two sides:

**ASK**(```00000000```): Lowest price buyer is willing to accept.

**BID**(```00000001```): Highest price seller is willing to buy for.


# SV File Structure:

Files used for RTL are accordingly placed in the ```rtl``` folder:

```
\ rtl
  \ Ask_Comparator.sv  # combinational module to get the lowest Ask price in memory
  \ Bid_Comparator.sv  # combinational module to get highest Bid price in memory
  \ CDC_Input_Synchronizer.sv  # prevents metastability in UART RX
  \ Message_Decoder.sv  # decoded reconstructed message to get ordertype, side, price, and size
  \ Message_Parser.sv  # reconstructs UART RX into message format
  \ Order_Book_Engine.sv # 5-state FSM that maintains Ask and Bid memory and returns best spread
  \ Order_Book_Observer_TopLevel.sv # TopLevel of entire architecture
  \ Result_Serializer  # Serializing best_spread for UART TX 
```

For each of the unique modules, we also have a custom testbench, in ```tb``` folder. Each one was accurate and confirmed its respective module.

# Requirements
