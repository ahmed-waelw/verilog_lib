// ----------------------------------------------------------------------------
// Module:      UART
// Description: Full-duplex 8-N-1 UART (transmitter + receiver). Parameterized
//              clock and baud rates; baud divisor is computed at elaboration.
//              No flow control. Caller drives tx_start to send tx_data;
//              rx_valid pulses high for one cycle when rx_data is ready.
// Parameters:  CLK_HZ  - system clock frequency in Hz (default 50_000_000)
//              BAUD    - target baud rate (default 115200)
// Ports:       clk       - system clock
//              reset     - asynchronous reset, active high
//              tx_start  - one-cycle pulse to begin a byte transmission
//              tx_data   - 8-bit transmit data
//              tx_busy   - high while transmitter is shifting out a byte
//              tx        - UART TX line (idles high)
//              rx        - UART RX line (idles high)
//              rx_data   - 8-bit received data (valid when rx_valid is high)
//              rx_valid  - one-cycle pulse when a byte has been received
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module UART #(
    parameter CLK_HZ = 50_000_000,
    parameter BAUD   = 115_200
)(
    input        clk,
    input        reset,
    input        tx_start,
    input  [7:0] tx_data,
    output       tx_busy,
    output       tx,
    input        rx,
    output [7:0] rx_data,
    output       rx_valid
);

    // TODO: implement UART
    // - Baud-tick generator: counter that wraps at CLK_HZ / BAUD
    // - Transmitter FSM: IDLE / START / DATA(0..7) / STOP, shifts tx_data LSB first
    // - Receiver FSM: detect start bit (rx going low), sample mid-bit at baud
    //   intervals, assemble 8 bits, check stop bit, assert rx_valid for 1 cycle
    // - Idle state for tx and rx is logic-1

endmodule
