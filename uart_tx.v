module uart_tx (
                 input       I_CLK,
                 input       I_RSTF,
                 input       I_TX_START,
                 input       I_BAUD_TICK,
                 input [7:0] I_DATA,
                 output reg  O_TX_DONE,
                 output      O_TX) ;

   
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
   reg       tx, n_tx; // transmit bit register
   

   // FSMD state & data registers
   always @ (posedge I_CLK, negedge I_RSTF ) begin
      if (!I_RSTF) begin
         st <= idle;
         s  <= 0;
         b  <= 0;
         d  <= 0;
         tx <= 1; // (idle)
      end
      else begin
         st <= n_st;
         s  <= n_s;
         b  <= n_b;
         d  <= n_d;
         tx <= n_tx;
      end
   end

   // FSMD next-state logic & function units
   always @* begin
      // defaults
      n_st      = st; // state
      n_s       = s;  // sample count
      n_b       = b;  // bit count
      n_d       = d;  // data reg
      n_tx      = tx; // tx out reg
      O_TX_DONE = 0;  // tx done
      
      case (st)
        idle: begin
           n_tx = 1;
           if (I_TX_START) begin
              n_st = start;
              n_s  = 0;
              n_b  = 0;
              n_d  = I_DATA;
           end
        end

        start: begin
           n_tx = 0;
           if (I_BAUD_TICK)
             if (s==15) begin
                n_st = data;
                n_s  = 0;
                n_b  = 0;
             end
             else
               n_s = s+1;
        end

        data: begin
           n_tx = d[0];
           if (I_BAUD_TICK)
             if (s==15) begin
                n_s = 0;
                n_d = d >> 1;
                if (b==7)
                  n_st = stop;
                else
                  n_b = b+1;
             end
             else
               n_s = s+1;
        end
        
        stop: begin 
           n_tx = 1;
           if (I_BAUD_TICK)
             if (s==15) begin
                n_st = idle;
                O_TX_DONE = 1;
             end
             else
               n_s = s+1;
        end
      endcase // case (st)
   end
   
   // output
   assign O_TX = tx;
   
endmodule // rs232_tx
