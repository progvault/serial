module uart_rx (
                input        I_CLK,
                input        I_RSTF,
                input        I_RX,
                input        I_BAUD_TICK,
                output [7:0] O_DATA,
                output reg   O_RX_DONE
                );

   // symbolic state declaration
   localparam [1:0] idle  = 2'b00,
                    start = 2'b01,
                    data  = 2'b10,
                    stop  = 2'b11;

   // signal declaration
   reg [1:0] st, n_st; // state
   reg [3:0] s,  n_s;  // sample count
   reg [2:0] b,  n_b;  // bit count
   reg [7:0] d,  n_d;  // data reg
   reg       mrx, rx0, rx; // receive sync
   

   // FSMD state & data registers
   always @ (posedge I_CLK, negedge I_RSTF ) begin
      if (!I_RSTF) begin
         st  <= idle;
         s   <= 0;
         b   <= 0;
         d   <= 0;
         mrx <= 0;
         rx0 <= 0;
         rx  <= 0;
      end
      else begin
         st  <= n_st;
         s   <= n_s;
         b   <= n_b;
         d   <= n_d;
         mrx <= I_RX;
         rx0 <= mrx;
         rx  <= rx0;
      end
   end


   // FSMD next-state logic
   always @* begin
      // defaults
      n_st      = st; // state
      n_s       = s;  // sample count
      n_b       = b;  // bit count
      n_d       = d;  // data reg
      O_RX_DONE = 0;  // rx done

      case (st)
        idle: 
          if (~rx) begin
             n_st <= start;
          end

        start: 
          if (I_BAUD_TICK)
            if (s==7) begin
               n_st = data;
               n_s  = 0;
               n_b  = 0;
            end
            else
              n_s = s+1;
               
        data:
          if (I_BAUD_TICK)
            if (s==15) begin
               n_s  = 0;
               n_d  = {I_RX, d[7:1]};
               if (b == 7)
                 n_st = stop;
               else
                 n_b  = b+1;
            end
            else
              n_s = s+1;

        stop:
          if (I_BAUD_TICK)
            if (s==15) begin
               n_st = idle;
               O_RX_DONE  = 1;
            end
            else
              n_s = s+1;
      endcase
   end

   // output
   assign O_DATA = d;
   
endmodule // uart_rx
