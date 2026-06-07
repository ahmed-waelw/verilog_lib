module I2C #(
    parameter CLK_HZ = 50_000_000,
    parameter I2C_HZ = 100_000
)(
    input            clk,
    input            reset,
    input            start,
    input            rw,
    input      [6:0] addr,
    input      [7:0] tx_data,
    output reg [7:0] rx_data,
    output           busy,
    output reg       ack_error,
    inout            sda,
    inout            scl   
);

    // ---- Open-drain tristate drivers ----
    reg sda_drive_low;
    reg scl_drive_low;
    assign sda = sda_drive_low ? 1'b0 : 1'bz;
    assign scl = scl_drive_low ? 1'b0 : 1'bz;

    // ---- FSM state encoding ----
    localparam [3:0] IDLE = 4'd0;       //Waiting for enable signal
    localparam [3:0] START = 4'd1;      //Sending the start condition
    localparam [3:0] ADDRESS = 4'd2;    //Sending the address and read/write bit 
    localparam [3:0] READ_ACK = 4'd3;   //Reading the acknowledgment bit from the slave.
    localparam [3:0] WRITE_DATA = 4'd4; //Writing data to the slave.
    localparam [3:0] WRITE_ACK = 4'd5;  //Sending acknowledgment bit to the slave.
    localparam [3:0] READ_DATA = 4'd6;  //Reading data from the slave.
    localparam [3:0] READ_ACK2 = 4'd7;  //Reading the acknowledgment bit after data read
    localparam [3:0] STOP = 4'd8;       //Sending the stop condition.
    
    reg [3:0] state, next_state;

    // ---- Bit-timing tick generator (quarter-bit for START/STOP timing) ----
    // 4 ticks per I2C bit period gives setup time before SCL edges.

    localparam integer DIVIDER = CLK_HZ / (I2C_HZ * 4);
    reg [$clog2(DIVIDER)-1:0] tick_cnt;
    wire tick = (tick_cnt == DIVIDER - 1);

    always @(posedge clk or posedge reset) begin
        if (reset)
            tick_cnt <= 0;
        else if (tick)
            tick_cnt <= 0;
        else
            tick_cnt <= tick_cnt + 1;
    end
    
    // ---- Sequential: register state on each tick ----

    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else if (tick)
            state <= next_state;
    end

    // ---- Combinational: next-state + output decode (defaults first!) ----

    always @(*) begin
        next_state = state;
        sda_drive_low = 1'b0;
        scl_drive_low = 1'b0;
case (state)
            IDLE: begin
                if (start) next_state = START;
            end

            START: begin
                sda_drive_low = 1'b1;     // SDA low while SCL still high → START
                next_state    = ADDRESS;
            end

            ADDRESS: begin
                // TODO: shift {addr, rw} MSB-first over 8 SCL pulses.
                // Needs a bit counter (3 bits) and a quarter-bit phase counter
                // to sequence: SCL low → set SDA → SCL high (sample) → SCL low.
                next_state = READ_ACK;
            end

            READ_ACK: begin
                // TODO: release SDA, sample on rising SCL edge.
                // If sampled sda == 1, set ack_error and go to STOP.
                next_state = rw ? READ_DATA : WRITE_DATA;
            end

            WRITE_DATA: begin
                // TODO: shift tx_data MSB-first over 8 SCL pulses (same pattern as ADDRESS)
                next_state = WRITE_ACK;
            end

            WRITE_ACK: begin
                // TODO: release SDA, sample for slave ACK
                next_state = STOP;
            end

            READ_DATA: begin
                // TODO: release SDA, shift in 8 bits sampled on rising SCL into rx_data
                next_state = READ_ACK2;
            end

            READ_ACK2: begin
                // TODO: master drives SDA low for ACK (more bytes) or high for NACK (last byte)
                next_state = STOP;
            end

            STOP: begin
                // TODO: needs phased timing — SDA low → SCL high → SDA high.
                // For now, single-tick approximation:
                sda_drive_low = 1'b1;
                next_state    = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // ---- Status outputs ----
    assign busy = (state != IDLE);

endmodule