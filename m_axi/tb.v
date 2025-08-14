`timescale 1ns / 1ps
module tb;
 
  reg clk = 0;
  reg resetn = 0;
  reg wr;
  reg [31:0] din;
  reg [3:0] strbin;
  reg [31:0] addrin;
 
  wire awvalid, awready, wvalid, wready, bvalid, bready;
  wire [31:0] awaddr, wdata;
  wire [3:0] strb;
  wire [1:0] resp;
 integer i =0;
 
 
 
  m_axi dut_m_axi (
      .i_clk   (clk),
      .i_resetn(resetn),
      .i_wr    (wr),
      .i_din   (din),
      .i_strb  (strbin),
      .i_addrin(addrin),
 
      .m_axi_awvalid(awvalid),
      .m_axi_awready(awready),
      .m_axi_awaddr (awaddr),
 
      .m_axi_wvalid(wvalid),
      .m_axi_wready(wready),
      .m_axi_wdata (wdata),
      .m_axi_wstrb (strb),
 
      .m_axi_bvalid(bvalid),
      .m_axi_bready(bready),
      .m_axi_bresp (resp)
  );
 
 
 
  s_axi dut_s_axi (
      .i_clk(clk),
      .i_resetn(resetn),
 
      .s_axi_awvalid(awvalid),
      .s_axi_awready(awready),
      .s_axi_awaddr (awaddr),
 
      .s_axi_wvalid(wvalid),
      .s_axi_wready(wready),
      .s_axi_wdata (wdata),
      .s_axi_wstrb (strb),
 
      .s_axi_bvalid(bvalid),
      .s_axi_bready(bready),
      .s_axi_bresp (resp)
  );
 
  always #10 clk = ~clk;
 
  initial begin
    resetn = 0;
    #20;
    resetn = 1;
  end
 
  initial begin
    @(posedge resetn);
    @(posedge clk);
 
    for ( i = 0; i < 10; i=i+1) begin
      @(posedge clk);
      wr     = 1'b1;
      addrin = $urandom_range(0, 20);
      din    = $urandom_range(1, 10);
      strbin = 4'b1111;
      @(posedge bvalid);
      @(posedge clk);
    end
    $stop;
  end
 
 
endmodule
 
 