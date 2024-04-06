`define FREQ (20000000 * 5)

module top(input CLK, RXD, output TXD, LED0, LED1, LED2, LED3, LED4, LED5);
                      //    a               b           c       //ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
   reg  [0:23]  data = {8'b01100001, 8'b01100010, 8'b01100011};
                      //               zeros    len    
   wire [0:511] msg  = {data, 1'b1, 423'b0, 64'd24};
   //reg  [0:7]  data = {8'b01100001};
   //wire [0:511] msg  = {data, 1'b1, 439'b0, 64'd8};

   wire [0:255] hash;

   sha256 _sha256(.clk(CLK), .reset(1'b1), .M(msg), .hash(hash));

   wire reset = 1;
   reg  start, send;
   wire busy;

   reg  [6:0] pos;
   wire [7:0] ascii [0:15];

   wire [7:0] char = ascii[hash[(pos * 4) +: 4]];
   //wire [7:0] char = (pos < 64) ? ascii[hash[(pos * 4) +: 4]] : (pos == 65) ? 8'h0a : 8'h0d;
   //reg [7:0] char = 48;//inicio dos numeros  01234... na tabela asc

   reg [31:0] sec_clk;
   
  always @(negedge reset or posedge CLK) 
  begin
   if(!reset)
	begin
	   pos   = 0;
	   send  = 0;
	   start = 0;
	   LED0  = 1;
	end
   else 
   begin
      if(busy)
         send = 0;

      if(!busy && !send && start)
         begin
            if(pos < 64)
            begin
               //char = char + 1;
               pos   = pos + 1;
               send  = 1;
            end
            else
                start = 0;
         end

      if(!start && sec_clk == (`FREQ))
         begin
            //char  = 48;
            LED0  = ~LED0;
            pos   = 0;
            send  = 1;
            start = 1;

            sec_clk <= 0;
         end
      else
         sec_clk <= sec_clk + 1;

   end

  end

  uart_tx tx(.clk(CLK), .tx(TXD), .send(send), .data(char), .busy(busy));

   assign LED1 = 1;
   assign LED2 = 1;
   assign LED3 = 1;
   assign LED4 = 1;
   assign LED5 = 1;

   assign ascii[ 0] = 8'h30;
   assign ascii[ 1] = 8'h31;
   assign ascii[ 2] = 8'h32;
   assign ascii[ 3] = 8'h33;
   assign ascii[ 4] = 8'h34;
   assign ascii[ 5] = 8'h35;
   assign ascii[ 6] = 8'h36;
   assign ascii[ 7] = 8'h37;
   assign ascii[ 8] = 8'h38;
   assign ascii[ 9] = 8'h39;
   assign ascii[10] = 8'h61;
   assign ascii[11] = 8'h62;
   assign ascii[12] = 8'h63;
   assign ascii[13] = 8'h64;
   assign ascii[14] = 8'h65;
   assign ascii[15] = 8'h66;
endmodule

`define ROTR(x,n) ((x >> n) | (x << (32 - n)))

`define Cha(x,y,z) ((x & y) ^ ((~x) & z))
`define Maj(x,y,z) ((x & y) ^ (x & z) ^ (y & z))

`define S0(x) (`ROTR(x, 2) ^ `ROTR(x, 13) ^ `ROTR(x, 22))
`define S1(x) (`ROTR(x, 6) ^ `ROTR(x, 11) ^ `ROTR(x, 25))

`define Si0(x) (`ROTR(x,  7) ^ `ROTR(x, 18) ^ (x >>  3))
`define Si1(x) (`ROTR(x, 17) ^ `ROTR(x, 19) ^ (x >> 10))

module sha256(input clk, reset, input wire [0:511] M, output wire [0:255] hash);
   genvar i;

   wire [0:31] h   [0:7];
   wire [0:31] k   [0:63];
   wire [0:31] w   [0:63];
   wire [0:31] r   [0:64][0:7];
   wire [0:31] tmp [0:64];

   generate
      for(i = 0; i < 16; i = i+1)
	assign w[i] = M[ (i*32) +: 32 ];

      for(i = 16; i < 64; i = i+1)
	assign w[i] = `Si0(w[i-15]) + w[i-7] + `Si1(w[i- 2]) + w[i-16];

      sha256_r4 r0(.a0(h[0]), .b0(h[1]), .c0(h[2]), .d0(h[3]),
		   .e0(h[4]), .f0(h[5]), .g0(h[6]), .h0(h[7]),

		   .k1(k[0]), .k2(k[1]), .k3(k[2]), .k4(k[3]),
		   .w1(w[0]), .w2(w[1]), .w3(w[2]), .w4(w[3]),

		   .a4(r[0][0]), .b4(r[0][1]), .c4(r[0][2]), .d4(r[0][3]),
		   .e4(r[0][4]), .f4(r[0][5]), .g4(r[0][6]), .h4(r[0][7]));

      for(i = 1; i < 16; i = i+1) 
      begin
	         sha256_r4 rI(.a0(r[i-1][0]), .b0(r[i-1][1]), .c0(r[i-1][2]), .d0(r[i-1][3]),
		      .e0(r[i-1][4]), .f0(r[i-1][5]), .g0(r[i-1][6]), .h0(r[i-1][7]),

		      .k1(k[(i*4)+0]), .k2(k[(i*4)+1]), .k3(k[(i*4)+2]), .k4(k[(i*4)+3]),
		      .w1(w[(i*4)+0]), .w2(w[(i*4)+1]), .w3(w[(i*4)+2]), .w4(w[(i*4)+3]),

		      .a4(r[i][0]), .b4(r[i][1]), .c4(r[i][2]), .d4(r[i][3]),
		      .e4(r[i][4]), .f4(r[i][5]), .g4(r[i][6]), .h4(r[i][7]));
      end

      for(i = 0; i < 8; i = i+1)
	      assign hash[ (i*32) +: 32 ] = h[i] + r[15][i];

   endgenerate

   assign h[0] = 32'h6a09e667;
   assign h[1] = 32'hbb67ae85;
   assign h[2] = 32'h3c6ef372;
   assign h[3] = 32'ha54ff53a;
   assign h[4] = 32'h510e527f;
   assign h[5] = 32'h9b05688c;
   assign h[6] = 32'h1f83d9ab;
   assign h[7] = 32'h5be0cd19;

   assign k[ 0] = 32'h428a2f98;
   assign k[ 1] = 32'h71374491;
   assign k[ 2] = 32'hb5c0fbcf;
   assign k[ 3] = 32'he9b5dba5;
   assign k[ 4] = 32'h3956c25b;
   assign k[ 5] = 32'h59f111f1;
   assign k[ 6] = 32'h923f82a4;
   assign k[ 7] = 32'hab1c5ed5;
   assign k[ 8] = 32'hd807aa98;
   assign k[ 9] = 32'h12835b01;
   assign k[10] = 32'h243185be;
   assign k[11] = 32'h550c7dc3;
   assign k[12] = 32'h72be5d74;
   assign k[13] = 32'h80deb1fe;
   assign k[14] = 32'h9bdc06a7;
   assign k[15] = 32'hc19bf174;
   assign k[16] = 32'he49b69c1;
   assign k[17] = 32'hefbe4786;
   assign k[18] = 32'h0fc19dc6;
   assign k[19] = 32'h240ca1cc;
   assign k[20] = 32'h2de92c6f;
   assign k[21] = 32'h4a7484aa;
   assign k[22] = 32'h5cb0a9dc;
   assign k[23] = 32'h76f988da;
   assign k[24] = 32'h983e5152;
   assign k[25] = 32'ha831c66d;
   assign k[26] = 32'hb00327c8;
   assign k[27] = 32'hbf597fc7;
   assign k[28] = 32'hc6e00bf3;
   assign k[29] = 32'hd5a79147;
   assign k[30] = 32'h06ca6351;
   assign k[31] = 32'h14292967;
   assign k[32] = 32'h27b70a85;
   assign k[33] = 32'h2e1b2138;
   assign k[34] = 32'h4d2c6dfc;
   assign k[35] = 32'h53380d13;
   assign k[36] = 32'h650a7354;
   assign k[37] = 32'h766a0abb;
   assign k[38] = 32'h81c2c92e;
   assign k[39] = 32'h92722c85;
   assign k[40] = 32'ha2bfe8a1;
   assign k[41] = 32'ha81a664b;
   assign k[42] = 32'hc24b8b70;
   assign k[43] = 32'hc76c51a3;
   assign k[44] = 32'hd192e819;
   assign k[45] = 32'hd6990624;
   assign k[46] = 32'hf40e3585;
   assign k[47] = 32'h106aa070;
   assign k[48] = 32'h19a4c116;
   assign k[49] = 32'h1e376c08;
   assign k[50] = 32'h2748774c;
   assign k[51] = 32'h34b0bcb5;
   assign k[52] = 32'h391c0cb3;
   assign k[53] = 32'h4ed8aa4a;
   assign k[54] = 32'h5b9cca4f;
   assign k[55] = 32'h682e6ff3;
   assign k[56] = 32'h748f82ee;
   assign k[57] = 32'h78a5636f;
   assign k[58] = 32'h84c87814;
   assign k[59] = 32'h8cc70208;
   assign k[60] = 32'h90befffa;
   assign k[61] = 32'ha4506ceb;
   assign k[62] = 32'hbef9a3f7;
   assign k[63] = 32'hc67178f2;
endmodule

module sha256_r4
  (input  wire [0:31] a0, b0, c0, d0, e0, f0, g0, h0,
   input  wire [0:31] k1, k2, k3, k4, w1, w2, w3, w4,
   output wire [0:31] a4, b4, c4, d4, e4, f4, g4, h4);

   wire [0:31] tmp1 = h0 + k1 + w1 + `Cha(e0, f0, g0) + `S1(e0);
   wire [0:31] a1 = tmp1 + `Maj(a0, b0, c0) + `S0(a0);
   wire [0:31] e1 = tmp1 + d0;

   wire [0:31] tmp2 = g0 + k2 + w2 + `Cha(e1, e0, f0) + `S1(e1);
   wire [0:31] a2 = tmp2 + `Maj(a1, a0, b0) + `S0(a1);
   wire [0:31] e2 = tmp2 + c0;

   wire [0:31] tmp3 = f0 + k3 + w3 + `Cha(e2, e1, e0) + `S1(e2);
   wire [0:31] a3 = tmp3 + `Maj(a2, a1, a0) + `S0(a2);
   wire [0:31] e3 = tmp3 + b0;

   wire [0:31] tmp4 = e0 + k4 + w4 + `Cha(e3, e2, e1) + `S1(e3);

   assign a4 = tmp4 + `Maj(a3, a2, a1) + `S0(a3);
   assign b4 = a3;
   assign c4 = a2;
   assign d4 = a1;

   assign e4 = a0 + tmp4;
   assign f4 = e3;
   assign g4 = e2;
   assign h4 = e1;

endmodule
