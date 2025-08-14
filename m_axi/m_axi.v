`timescale 1ns / 1ps

////////////////////////////////////////////////////////////
// AXI Master (Write Only)
////////////////////////////////////////////////////////////
module m_axi (
    input  wire        i_clk,
    input  wire        i_resetn,

    input  wire        i_wr,
    input  wire [31:0] i_din,
    input  wire [ 3:0] i_strb,
    input  wire [31:0] i_addrin,

    // Write Address Channel
    output reg         m_axi_awvalid,
    input  wire        m_axi_awready,
    output reg  [31:0] m_axi_awaddr,

    // Write Data Channel
    output reg         m_axi_wvalid,
    input  wire        m_axi_wready,
    output reg  [31:0] m_axi_wdata,
    output reg  [ 3:0] m_axi_wstrb,

    // Write Response Channel
    input  wire        m_axi_bvalid,
    output reg         m_axi_bready,
    input  wire [ 1:0] m_axi_bresp
);

  // Reset initialization
  initial begin
    m_axi_awvalid = 0;
    m_axi_wvalid  = 0;
    m_axi_bready  = 0;
    m_axi_awaddr  = 0;
    m_axi_wdata   = 0;
    m_axi_wstrb   = 0;
  end

  // Write control signals
  always @(posedge i_clk) begin
    if (i_resetn == 1'b0) begin
      m_axi_awvalid <= 0;
      m_axi_wvalid  <= 0;
      m_axi_bready  <= 0;
    end else if (m_axi_bready) begin
      if (m_axi_awready) m_axi_awvalid <= 0;
      if (m_axi_wready)  m_axi_wvalid  <= 0;
      if (m_axi_bvalid)  m_axi_bready  <= 0;
    end else if (i_wr) begin
      m_axi_awvalid <= 1;
      m_axi_wvalid  <= 1;
      m_axi_bready  <= 1;
    end
  end

  // Write Address
  always @(posedge i_clk) begin
    if (i_resetn == 1'b0)
      m_axi_awaddr <= 0;
    else if (i_wr)
      m_axi_awaddr <= i_addrin;
    else if (m_axi_awvalid && m_axi_awready)
      m_axi_awaddr <= 0;
  end

  // Write Data
  always @(posedge i_clk) begin
    if (i_resetn == 1'b0) begin
      m_axi_wdata <= 0;
      m_axi_wstrb <= 0;
    end else if (i_wr) begin
      m_axi_wdata <= i_din;
      m_axi_wstrb <= i_strb;
    end else if (m_axi_wvalid && m_axi_wready) begin
      m_axi_wdata <= 0;
      m_axi_wstrb <= 0;
    end
  end

endmodule


////////////////////////////////////////////////////////////
// AXI Slave (Write Only)
////////////////////////////////////////////////////////////
module s_axi (
    input  wire        i_clk,
    input  wire        i_resetn,

    // Write Address Channel
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_awaddr,

    // Write Data Channel
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,

    // Write Response Channel
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    output reg  [ 1:0] s_axi_bresp
);

  // Internal registers
  reg [31:0] addr_in;
  reg        valid_a;
  reg [31:0] data_in;
  reg        valid_d;

  // Simple memory (16 words deep)
  reg [31:0] mem [0:15];
  integer j;

  initial begin
    s_axi_awready = 0;
    s_axi_wready  = 0;
    s_axi_bvalid  = 0;
    s_axi_bresp   = 0;
    addr_in       = 0;
    valid_a       = 0;
    data_in       = 0;
    valid_d       = 0;
    for (j = 0; j < 16; j = j + 1) begin
      mem[j] = 0;
    end
  end

  // Slave Write Address handshake
  always @(posedge i_clk) begin
    if (i_resetn == 1'b0)
      s_axi_awready <= 0;
    else if (s_axi_awready)
      s_axi_awready <= 0;
    else if (s_axi_awvalid)
      s_axi_awready <= 1;
  end

  // Slave Write Data handshake
  always @(posedge i_clk) begin
    if (i_resetn == 1'b0)
      s_axi_wready <= 0;
    else if (s_axi_wready)
      s_axi_wready <= 0;
    else if (s_axi_wvalid)
      s_axi_wready <= 1;
  end

  // Capture Address
  always @(posedge i_clk) begin
    if (i_resetn == 1'b0) begin
      addr_in <= 0;
      valid_a <= 0;
    end else if (s_axi_bvalid) begin
      addr_in <= 0;
      valid_a <= 0;
    end else if (s_axi_awvalid) begin
      addr_in <= s_axi_awaddr;
      valid_a <= 1;
    end
  end

  // Capture Data
  always @(posedge i_clk) begin
    if (i_resetn == 1'b0) begin
      data_in <= 0;
      valid_d <= 0;
    end else if (s_axi_bvalid) begin
      data_in <= 0;
      valid_d <= 0;
    end else if (s_axi_wvalid) begin
      data_in <= s_axi_wdata;
      valid_d <= 1;
    end
  end

  // Update Memory
  always @(posedge i_clk) begin
    if (i_resetn == 1'b0) begin
      for (j = 0; j < 16; j = j + 1) begin
        mem[j] <= 0;
      end
    end else if (valid_a && valid_d && addr_in <= 15) begin
      mem[addr_in] <= data_in;
    end
  end

  // Generate Write Response
  always @(posedge i_clk) begin
    if (i_resetn == 1'b0) begin
      s_axi_bvalid <= 0;
      s_axi_bresp  <= 0;
    end else if (valid_a && valid_d && !s_axi_bvalid) begin
      s_axi_bvalid <= 1;
      if (addr_in <= 15)
        s_axi_bresp <= 2'b00;  // OKAY
      else
        s_axi_bresp <= 2'b11;  // DECERR
    end else if (s_axi_bvalid) begin
      s_axi_bvalid <= 0;
      s_axi_bresp  <= 0;
    end
  end

endmodule
