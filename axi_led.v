module axi4_lite_slave (
    input wire clk,
    input wire rst_n,
    output wire led,

    // Write address channel
    input wire [3:0]  AWADDR,
    input wire        AWVALID,
    output reg        AWREADY,

    // Write data channel
    input wire [31:0] WDATA,
    input wire        WVALID,
    output reg        WREADY,

    // Write response
    output reg        BVALID,
    input wire        BREADY,

    // Read address
    input wire [3:0]  ARADDR,
    input wire        ARVALID,
    output reg        ARREADY,

    // Read data
    output reg [31:0] RDATA,
    output reg        RVALID,
    input wire        RREADY
);

// Registers
reg [31:0] reg0, reg1, reg2, reg3;

// LED connection
assign led = reg0[0];

// WRITE
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        AWREADY <= 0; WREADY <= 0; BVALID <= 0;
        reg0 <= 0; reg1 <= 0; reg2 <= 0; reg3 <= 0;
    end else begin
        if (AWVALID && WVALID && !BVALID) begin
            AWREADY <= 1;
            WREADY  <= 1;

            case (AWADDR[3:2])
                2'b00: reg0 <= WDATA;
                2'b01: reg1 <= WDATA;
                2'b10: reg2 <= WDATA;
                2'b11: reg3 <= WDATA;
            endcase

            BVALID <= 1;
        end else begin
            AWREADY <= 0;
            WREADY  <= 0;
        end

        if (BVALID && BREADY)
            BVALID <= 0;
    end
end

// READ
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ARREADY <= 0; RVALID <= 0; RDATA <= 0;
    end else begin
        if (ARVALID && !RVALID) begin
            ARREADY <= 1;

            case (ARADDR[3:2])
                2'b00: RDATA <= reg0;
                2'b01: RDATA <= reg1;
                2'b10: RDATA <= reg2;
                2'b11: RDATA <= reg3;
            endcase

            RVALID <= 1;
        end else begin
            ARREADY <= 0;
        end

        if (RVALID && RREADY)
            RVALID <= 0;
    end
end

endmodule


// ================= TESTBENCH =================

module tb;

reg clk = 0;
always #5 clk = ~clk;

reg rst_n;

// AXI signals
reg [3:0] AWADDR;
reg AWVALID;
wire AWREADY;

reg [31:0] WDATA;
reg WVALID;
wire WREADY;

wire BVALID;
reg BREADY;

reg [3:0] ARADDR;
reg ARVALID;
wire ARREADY;

wire [31:0] RDATA;
wire RVALID;
reg RREADY;

wire led;

// DUT
axi4_lite_slave dut (
    .clk(clk), .rst_n(rst_n), .led(led),
    .AWADDR(AWADDR), .AWVALID(AWVALID), .AWREADY(AWREADY),
    .WDATA(WDATA), .WVALID(WVALID), .WREADY(WREADY),
    .BVALID(BVALID), .BREADY(BREADY),
    .ARADDR(ARADDR), .ARVALID(ARVALID), .ARREADY(ARREADY),
    .RDATA(RDATA), .RVALID(RVALID), .RREADY(RREADY)
);

initial begin
    $dumpfile("axi_led.vcd");
    $dumpvars(0, tb);

    rst_n = 0;
    AWVALID = 0; WVALID = 0; BREADY = 0;
    ARVALID = 0; RREADY = 0;

    #20 rst_n = 1;

    // LED ON
    #10;
    AWADDR = 4'h0;
    WDATA  = 32'h1;
    AWVALID = 1; WVALID = 1;
    #10 AWVALID = 0; WVALID = 0;

    BREADY = 1; #10 BREADY = 0;

    #10;
    $display("LED = %b (should be 1)", led);

    // LED OFF
    #20;
    AWADDR = 4'h0;
    WDATA  = 32'h0;
    AWVALID = 1; WVALID = 1;
    #10 AWVALID = 0; WVALID = 0;

    BREADY = 1; #10 BREADY = 0;

    #10;
    $display("LED = %b (should be 0)", led);

    #20 $finish;
end

endmodule
