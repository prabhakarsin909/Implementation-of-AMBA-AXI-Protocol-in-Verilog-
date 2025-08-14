`timescale 1ns / 1ps
module axis_arb (
  input  wire        aclk,
  input  wire        aresetn,
  output wire        s_axis_tready1,
  output wire        s_axis_tready2,
  input  wire        s_axis_tvalid1,
  input  wire        s_axis_tvalid2,
  input  wire [7:0]  s_axis_tdata1,
  input  wire [7:0]  s_axis_tdata2,
  input  wire        s_axis_tlast1,
  input  wire        s_axis_tlast2,
  input  wire        m_axis_tready,
  output wire        m_axis_tvalid,
  output wire [7:0]  m_axis_tdata,
  output wire        m_axis_tlast
);

parameter IDLE = 2'b00, S1 = 2'b01, S2 = 2'b10;
reg [1:0] state, next_state;

assign s_axis_tready1 = 1'b1;
assign s_axis_tready2 = 1'b1;

always @(posedge aclk) begin
  if (aresetn == 1'b0)
    state <= IDLE;
  else
    state <= next_state;
end

reg [7:0] reg_tdata;
reg       reg_tlast;

always @(*) begin
  case (state)
    IDLE: begin
      if (s_axis_tvalid1 && s_axis_tready1) begin
        next_state = S1;
        reg_tdata  = s_axis_tdata1;
        reg_tlast  = s_axis_tlast1;
      end else if (s_axis_tvalid2 && s_axis_tready2) begin
        next_state = S2;
        reg_tdata  = s_axis_tdata2;
        reg_tlast  = s_axis_tlast2;
      end else begin
        next_state = IDLE;
      end
    end

    S1: begin
      if (m_axis_tready == 1'b1) begin
        if (s_axis_tlast1) begin
          reg_tdata  = s_axis_tdata1;
          reg_tlast  = s_axis_tlast1;
          if (s_axis_tvalid2 && s_axis_tready2)
            next_state = S2;
          else
            next_state = IDLE;
        end else begin
          next_state = S1;
          reg_tdata  = s_axis_tdata1;
          reg_tlast  = s_axis_tlast1;
        end
      end else begin
        next_state  = S1;
      end
    end

    S2: begin
      if (m_axis_tready == 1'b1) begin
        if (s_axis_tlast2) begin
          reg_tdata  = s_axis_tdata2;
          reg_tlast  = s_axis_tlast2;
          if (s_axis_tvalid1 && s_axis_tready1)
            next_state = S1;
          else
            next_state = IDLE;
        end else begin
          next_state = S2;
          reg_tdata  = s_axis_tdata2;
          reg_tlast  = s_axis_tlast2;
        end
      end else begin
        next_state  = S2;
      end
    end

    default: next_state = IDLE;
  endcase
end

assign m_axis_tdata  = ((s_axis_tvalid1 && s_axis_tready1)||(s_axis_tvalid2 && s_axis_tready2)) ? reg_tdata : 8'h00;  
assign m_axis_tlast  = ((s_axis_tvalid1 && s_axis_tready1)||(s_axis_tvalid2 && s_axis_tready2)) ? reg_tlast : 1'b0;
assign m_axis_tvalid = ((s_axis_tvalid1 && s_axis_tready1)||(s_axis_tvalid2 && s_axis_tready2)) ? 1'b1 : 1'b0;

endmodule
