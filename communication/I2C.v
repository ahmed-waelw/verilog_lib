// ----------------------------------------------------------------------------
// Module:      I2C
// Description: I2C master controller. Single-master, supports 7-bit
//              addressing and basic read/write byte transactions.
//              Open-drain SDA/SCL — drive '0' actively, release for '1'.
// Parameters:  CLK_HZ   - system clock frequency in Hz (default 50_000_000)
//              I2C_HZ   - target I2C clock frequency in Hz (default 100_000)
// Ports:       clk        - system clock
//              reset      - asynchronous reset, active high
//              start      - begin a transaction
//              rw         - 0 = write, 1 = read
//              addr       - 7-bit slave address
//              tx_data    - 8-bit data to write (when rw == 0)
//              rx_data    - 8-bit data read (when rw == 1)
//              busy       - high while transaction in progress
//              ack_error  - asserted if slave did not ACK
//              sda        - I2C SDA line (inout — open-drain)
//              scl        - I2C SCL line (output — open-drain)
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module I2C #(
    parameter CLK_HZ = 50_000_000,
    parameter I2C_HZ = 100_000
)(
    input        clk,
    input        reset,
    input        start,
    input        rw,
    input  [6:0] addr,
    input  [7:0] tx_data,
    output [7:0] rx_data,
    output       busy,
    output       ack_error,
    inout        sda,
    output       scl
);

    
    // TODO: implement I2C master
    // - Generate scl by dividing clk to 4 * I2C_HZ (need quarter-bit timing for
    //   start/stop generation and SDA setup before SCL rising edge)
    // - FSM: IDLE -> START -> ADDR(7) -> RW(1) -> ACK -> DATA(8) -> ACK -> STOP
    // - SDA is tristate: drive low for '0', release (high-Z) for '1'.
    //   Use:  assign sda = sda_drive_low ? 1'b0 : 1'bz;
    // - Sample ACK on the 9th SCL pulse; if SDA is high, set ack_error

endmodule
