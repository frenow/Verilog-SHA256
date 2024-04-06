module test();
  reg clk = 0;
  wire txd;
  wire [5:0] led;
  
  wire [7:0] char = 8'b10101010;
  reg  send;
  wire busy;

  uart_tx #(8'd8) tx(.clk(clk), .tx(txd), .send(send), .data(char), .busy(busy));

  always
    #1  clk = ~clk;

  initial begin
    $display("Starting UART TX");
    #100 send  = 1;
    $display("Start: ", txd);
    $monitor("TX %b", txd);

    #1000 $finish;
  end

  initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0,test);
  end
endmodule