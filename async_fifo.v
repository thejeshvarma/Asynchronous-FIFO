module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input wclk,
    input rclk,
    input wrst_n,
    input rrst_n,
    input w_en,
    input r_en,

    input [DATA_WIDTH-1:0]  wdata,
    output reg  [DATA_WIDTH-1:0]  rdata,

    output  full,
    output  empty
);

localparam DEPTH = 1 << ADDR_WIDTH; //This means DEPTH = 2^ADDR_WIDTH

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];


//Below is the Write Pointer Logic 


reg [ADDR_WIDTH:0] wptr_bin;
reg [ADDR_WIDTH:0] wptr_gray;

wire [ADDR_WIDTH:0] wptr_bin_next;
wire [ADDR_WIDTH:0] wptr_gray_next;

assign wptr_bin_next  = wptr_bin + (w_en & ~full); // Write in next location if only enable is high and not full
assign wptr_gray_next = (wptr_bin_next >> 1) ^ wptr_bin_next; // bin to gray Conversion

always @(posedge wclk or negedge wrst_n)
begin
    if(!wrst_n)
    begin
        wptr_bin  <= 0;
        wptr_gray <= 0;
    end
    else
    begin
        wptr_bin  <= wptr_bin_next;
        wptr_gray <= wptr_gray_next;
    end
end



// Below is Read Pointer Logic


reg [ADDR_WIDTH:0] rptr_bin;
reg [ADDR_WIDTH:0] rptr_gray;

wire [ADDR_WIDTH:0] rptr_bin_next;
wire [ADDR_WIDTH:0] rptr_gray_next;

assign rptr_bin_next  = rptr_bin + (r_en & ~empty);// Read location if only enable is high and not Empty
assign rptr_gray_next = (rptr_bin_next >> 1) ^ rptr_bin_next; // bin to gray Conversion

always @(posedge rclk or negedge rrst_n)
begin
    if(!rrst_n)
    begin
        rptr_bin  <= 0;
        rptr_gray <= 0;
    end
    else
    begin
        rptr_bin  <= rptr_bin_next;
        rptr_gray <= rptr_gray_next;
    end
end


// FIFO Memory Writing Logic


always @(posedge wclk)
begin
    if(w_en && !full)
        mem[wptr_bin[ADDR_WIDTH-1:0]] <= wdata;
end


// FIFO Memory Reading Logic


always @(posedge rclk)
begin
    if(r_en && !empty)
        rdata <= mem[rptr_bin[ADDR_WIDTH-1:0]];
end


// Pointer Synchronization Logic


// read pointer into write clock domain
reg [ADDR_WIDTH:0] rptr_gray_sync1;
reg [ADDR_WIDTH:0] rptr_gray_sync2;

always @(posedge wclk or negedge wrst_n)
begin
    if(!wrst_n)
    begin
        rptr_gray_sync1 <= 0;
        rptr_gray_sync2 <= 0;
    end
    else
    begin
        rptr_gray_sync1 <= rptr_gray;
        rptr_gray_sync2 <= rptr_gray_sync1;
    end
end


// write pointer into read clock domain
reg [ADDR_WIDTH:0] wptr_gray_sync1;
reg [ADDR_WIDTH:0] wptr_gray_sync2;

always @(posedge rclk or negedge rrst_n)
begin
    if(!rrst_n)
    begin
        wptr_gray_sync1 <= 0;
        wptr_gray_sync2 <= 0;
    end
    else
    begin
        wptr_gray_sync1 <= wptr_gray;
        wptr_gray_sync2 <= wptr_gray_sync1;
    end
end

// FULL condition

assign full =
    (wptr_gray_next ==
     {~rptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
       rptr_gray_sync2[ADDR_WIDTH-2:0]});


// EMPTY condition

assign empty = (rptr_gray == wptr_gray_sync2);


endmodule