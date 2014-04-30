module rs232_top (
                  input  I_CLK,   // System Clock (50MHz)
                  input  I_RSTF,  // Async Reset (active low)
                  input  I_RX,    // Serial Receive
                  output O_TX     // Serial Transmit
                  );

   // signal declaration
   reg  [7:0] baud_cnt;
   reg        baud_tick;
   wire [7:0] data;
   wire       rx_done;

   uart_rx rx ( .I_CLK        (I_CLK     ), 
                .I_RSTF       (I_RSTF    ), 
                .I_RX         (I_RX      ), 
                .I_BAUD_TICK  (baud_tick ), 
                .O_DATA       (data      ), 
                .O_RX_DONE    (rx_done   ));

   uart_tx tx ( .I_CLK        (I_CLK     ), 
                .I_RSTF       (I_RSTF    ), 
                .I_TX_START   (rx_done   ), 
                .I_BAUD_TICK  (baud_tick ), 
                .I_DATA       (data      ), 
                .O_TX_DONE    (          ), 
                .O_TX         (O_TX      )) ;

   // baud rate gen
   always @ (posedge I_CLK, negedge I_RSTF) begin
      if (!I_RSTF)
        baud_cnt  <= 0;
        baud_tick <= 1;
      else
        if (baud_cnt == 26) begin
           baud_cnt  <= 0;
           baud_tick <= 1;
        end
        else begin
           baud_cnt  <= baud_cnt+1 ;
           baud_tick <= 0;
        end
   end
      
endmodule

   
   
