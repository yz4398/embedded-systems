/*
 * Avalon memory-mapped peripheral that generates VGA
 *
 * Stephen A. Edwards
 * Columbia University
 */

module vga_ball(input logic        clk,
	        input logic 	   reset,
		input logic [15:0]  writedata,
		input logic 	   write,
		input 		   chipselect,
		input logic [2:0]  address,

		output logic [7:0] VGA_R, VGA_G, VGA_B,
		output logic 	   VGA_CLK, VGA_HS, VGA_VS,
		                   VGA_BLANK_n,
		output logic 	   VGA_SYNC_n);

   logic [10:0]	   hcount;
   logic [9:0]     vcount;
   
   logic [20:0]   dis;
   logic [15:0] 	   background_r, background_g, background_b;
   logic [15:0] 	   pos_x[5:0];
   logic [15:0] 	   pos_y[5:0];
   logic [15:0]      head_x,head_y;
   logic [15:0]      snake_length=2;
   logic [9:0]      sim_time = 0;
   
   
   
	
   vga_counters counters(.clk50(clk), .*);

   always_ff @(posedge clk)
     if (reset) begin
	background_r <= 8'h0;
	background_g <= 8'h0;
	background_b <= 8'h80;
        
     end else if (chipselect && write)
       case (address)
         3'h0 : head_x <= writedata;
         3'h1 : head_y <= writedata;
	       3'h2 : snake_length <= writedata;
       endcase

   always_ff @(posedge clk)
     if(reset)begin
        pos_x[0] <= 50;
        pos_y[0] <= 40;
        pos_x[1] <= 51;
        pos_y[1] <= 40;
     end
     else begin
     if(pos_x[0] != head_x||pos_y[0] != head_y )begin
       for (int j=snake_length-1; j>0;j--)begin
         pos_x[j]=pos_x[j-1];
         pos_y[j]=pos_y[j-1];
       end
       pos_x[0]=head_x;
       pos_y[0]=head_y;
       /*if(pos_x[1]>30&&pos_y[1]<=40&&pos_x[1]<70)begin pos_x[0]=pos_x[1]-1; pos_y[0]=pos_y[1];end
        else if(pos_x[1]<=30&&pos_y[1]<60) begin pos_x[0]=pos_x[1]; pos_y[0]=pos_y[1]+1;end
         else if(pos_x[1]>30&&pos_y[1]>=60&&pos_x[1]<70) begin pos_x[0]=pos_x[1]+1; pos_y[0]=pos_y[1];end
          else if(pos_x[1]>=70) begin pos_x[0]=pos_x[1]; pos_y[0]=pos_y[1]-1;end
       sim_time = 0;*/
     end
     end

     always_comb begin
     {VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'h0};
     if (VGA_BLANK_n )begin
      {VGA_R, VGA_G, VGA_B} ={8'h0, 8'h0, 8'h80};
      for(int i=0; i<snake_length;i++) begin
        if (hcount > 12*pos_x[i] && hcount < 12*(pos_x[i]+1)
	        && vcount > 6*pos_y[i] && vcount < 6*(pos_y[i]+1))
         {VGA_R, VGA_G, VGA_B} = {8'hff, 8'hff, 8'hff};
         
      
	   /*else if (hcount[10:6] == 5'd3 &&
	    vcount[9:5] == 5'd3)
	   {VGA_R, VGA_G, VGA_B} = {8'hff, 8'hff, 8'hff};*/
	   
      end 
     end
     end
   /*always_comb begin
      {VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'h0};
      dis= (hcount-pos_x[10:0])*(hcount-pos_x[10:0])/4+(vcount-pos_y[10:0])*(vcount-pos_y[10:0]);
      if (VGA_BLANK_n )
        if (hcount > 6*pos_x && hcount < 6*(pos_x+1)
	    && vcount > 3*pos_y && vcount < 3*(pos_y+1))
        if (dis < 2501) {VGA_R, VGA_G, VGA_B} = {8'hff, 8'hff, 8'hff};
	/*else if (hcount[10:6] == 5'd3 &&
	    vcount[9:5] == 5'd3)
	  {VGA_R, VGA_G, VGA_B} = {8'hff, 8'hff, 8'hff};
	else
	  {VGA_R, VGA_G, VGA_B} =
             {8'h0, 8'h0, 8'h80};
   end*/
	       
endmodule

module vga_counters(
 input logic 	     clk50, reset,
 output logic [10:0] hcount,  // hcount[10:1] is pixel column
 output logic [9:0]  vcount,  // vcount[9:0] is pixel row
 output logic 	     VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n);

/*
 * 640 X 480 VGA timing for a 50 MHz clock: one pixel every other cycle
 * 
 * HCOUNT 1599 0             1279       1599 0
 *             _______________              ________
 * ___________|    Video      |____________|  Video
 * 
 * 
 * |SYNC| BP |<-- HACTIVE -->|FP|SYNC| BP |<-- HACTIVE
 *       _______________________      _____________
 * |____|       VGA_HS          |____|
 */
   // Parameters for hcount
   parameter HACTIVE      = 11'd 1280,
             HFRONT_PORCH = 11'd 32,
             HSYNC        = 11'd 192,
             HBACK_PORCH  = 11'd 96,   
             HTOTAL       = HACTIVE + HFRONT_PORCH + HSYNC +
                            HBACK_PORCH; // 1600
   
   // Parameters for vcount
   parameter VACTIVE      = 10'd 480,
             VFRONT_PORCH = 10'd 10,
             VSYNC        = 10'd 2,
             VBACK_PORCH  = 10'd 33,
             VTOTAL       = VACTIVE + VFRONT_PORCH + VSYNC +
                            VBACK_PORCH; // 525

   logic endOfLine;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          hcount <= 0;
     else if (endOfLine) hcount <= 0;
     else  	         hcount <= hcount + 11'd 1;

   assign endOfLine = hcount == HTOTAL - 1;
       
   logic endOfField;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          vcount <= 0;
     else if (endOfLine)
       if (endOfField)   vcount <= 0;
       else              vcount <= vcount + 10'd 1;

   assign endOfField = vcount == VTOTAL - 1;

   // Horizontal sync: from 0x520 to 0x5DF (0x57F)
   // 101 0010 0000 to 101 1101 1111
   assign VGA_HS = !( (hcount[10:8] == 3'b101) &
		      !(hcount[7:5] == 3'b111));
   assign VGA_VS = !( vcount[9:1] == (VACTIVE + VFRONT_PORCH) / 2);

   assign VGA_SYNC_n = 1'b0; // For putting sync on the green signal; unused
   
   // Horizontal active: 0 to 1279     Vertical active: 0 to 479
   // 101 0000 0000  1280	       01 1110 0000  480
   // 110 0011 1111  1599	       10 0000 1100  524
   assign VGA_BLANK_n = !( hcount[10] & (hcount[9] | hcount[8]) ) &
			!( vcount[9] | (vcount[8:5] == 4'b1111) );

   /* VGA_CLK is 25 MHz
    *             __    __    __
    * clk50    __|  |__|  |__|
    *        
    *             _____       __
    * hcount[0]__|     |_____|
    */
   assign VGA_CLK = hcount[0]; // 25 MHz clock: rising edge sensitive
   
endmodule
