module pulse_reg #(
   parameter int width = 3,
   parameter int pulse_len = 1_250_000  // ~25ms at 50MHz
)(
   input  logic clk,
   input  logic resetN,
   input  logic clr,
   input  logic [width-1:0] tin,
   output logic [width-1:0] qout
);

logic [width-1:0] tin_d;
logic [width-1:0] q;
logic [width*24-1:0] cnt;
logic [width-1:0] active;

always_ff @(posedge clk or negedge resetN) begin
   if (!resetN) begin
      tin_d  <= '0;
      q      <= '0;
      active <= '0;
      cnt    <= '0;
   end else if (clr) begin
      tin_d  <= '0;
      q      <= '0;
      active <= '0;
      cnt    <= '0;
   end else begin
      tin_d <= tin;
      // Rising edge detection
      for (int i = 0; i < width; i++) begin
         if (tin[i] && !tin_d[i]) begin
            active[i] <= 1'b1;
            cnt[i*24 +: 24] <= pulse_len;
         end else if (active[i]) begin
            if (cnt[i*24 +: 24] == 0) begin
               active[i] <= 1'b0;
            end else begin
               cnt[i*24 +: 24] <= cnt[i*24 +: 24] - 1;
            end
         end
      end
      q <= active;
   end
end

assign qout = q;

endmodule