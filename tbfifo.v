`timescale 1ns/1ps

module async_fifo_tb;

parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 4;

reg wclk;
reg rclk;
reg wrst_n;
reg rrst_n;

reg w_en;
reg r_en;

reg  [DATA_WIDTH-1:0] wdata;
wire [DATA_WIDTH-1:0] rdata;

wire full;
wire empty;


// Instantiate FIFO

async_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) dut (
    .wclk(wclk),
    .rclk(rclk),
    .wrst_n(wrst_n),
    .rrst_n(rrst_n),
    .w_en(w_en),
    .r_en(r_en),
    .wdata(wdata),
    .rdata(rdata),
    .full(full),
    .empty(empty)
);



// Write clock (10ns period)

initial
begin
    wclk = 0;
    forever #5 wclk = ~wclk;
end



// Read clock (14ns period)

initial
begin
    rclk = 0;
    forever #7 rclk = ~rclk;
end



// Reset block

initial
begin
    wrst_n = 0;
    rrst_n = 0;
    w_en = 0;
    r_en = 0;
    wdata = 0;

    #20;

    wrst_n = 1;
    rrst_n = 1;
end



// WRITE PROCESS

integer i;

initial
begin

    #30;

    for(i = 0; i < 20; i = i + 1)
    begin

        @(posedge wclk);

        if(!full)
        begin
            w_en = 1;
            wdata = i;
            $display("WRITE : %d at time %t", i, $time);
        end
        else
        begin
            w_en = 0;
        end

        @(posedge wclk);
        w_en = 0;

    end

end




// READ PROCESS

integer j;

initial
begin

    #120;

    for(j = 0; j < 21; j = j + 1)
    begin

        @(posedge rclk);

        if(!empty)
        begin
            r_en = 1;
        end

        @(posedge rclk);

        if(r_en)
            $display("READ  : %d at time %t", rdata, $time);

        r_en = 0;

    end

end



// Finish Simulation

initial
begin
    #1000;
    $finish;
end


endmodule