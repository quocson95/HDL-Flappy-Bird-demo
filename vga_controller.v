module vga_controller(SW,
							 RS,
							 LED_NOTI,
							 iRST_n,
                      iVGA_CLK,
                      oBLANK_n,
                      oHS,
                      oVS,
                      b_data,
                      g_data,
                      r_data);
input iRST_n;
input SW,RS;
input iVGA_CLK;
output reg LED_NOTI;
output oBLANK_n;
output oHS;
output oVS;
output reg [7:0] b_data;
output reg [7:0] g_data;  
output reg [7:0] r_data;                        
///////// ////   
wire[9:0] X;
wire [8:0] Y;
assign Y = ADDR/10'd640;
assign X = ADDR  - Y*10'd640;
reg [18:0] ADDR,bird_ADDR,background_ADDR;
reg [9:0] addr_pixel,add_bird;
reg [7:0] count;
reg [23:0] bgr_data;
wire VGA_CLK_n;
wire [7:0] index,bird_index;
wire [23:0] bgr_data_raw;
wire 	[23:0] bird_data_raw;
wire cBLANK_n,cHS,cVS,rst;
wire R_bird,G_bird,B_bird;
////


assign rst = ~iRST_n;
video_sync_generator LTM_ins (.vga_clk(iVGA_CLK),
                              .reset(rst),
                              .blank_n(cBLANK_n),
                              .HS(cHS),
                              .VS(cVS));
////
////Addresss generator
always@(posedge iVGA_CLK,negedge iRST_n)
begin
  if (!iRST_n)
	begin
     ADDR<=19'd0;
	  background_ADDR <= 19'd0;
	  bird_ADDR<=19'd0;
	  count <= 8'd0;
	  addr_pixel <= 10'd0;
	  add_bird<=10'd0;
	  LED_NOTI = 0;
	 end
  else if (cHS==1'b0 && cVS==1'b0)
	begin
		count <= count+1;
		//ADDR<=addr_pixel ;
		background_ADDR<=addr_pixel;
		ADDR = 19'd0;
		//if (SW) bird_ADDR<= 19'd307200 - 10'd640*add_bird; ///go down
		//if (SW) bird_ADDR<= 10'd640*(10'd480 - add_bird); ///go down
		bird_ADDR<= 10'd640*add_bird;						//go up
		if (count == 70) 
			begin
				if (addr_pixel > 10'd639) addr_pixel <= 0;
				else addr_pixel <= addr_pixel + 10'd1;
				count <=8'd0;
				if (add_bird > 10'd479) 
					begin
						add_bird<=10'd1;
						//LED_NOTI = ~LED_NOTI;
					end
				else if (add_bird < 10'd1) 
						begin
							add_bird <= 479;
						//	LED_NOTI = ~LED_NOTI;
						end
				else if (SW) 
							begin
								add_bird<=add_bird - 10'd1;
								if (add_bird == 280) 	LED_NOTI = ~LED_NOTI;
							end
						else 
							begin
								add_bird<=add_bird + 10'd1;
								if (add_bird == 200) 	LED_NOTI = ~LED_NOTI;
							end
			end
		//count <= 7'd0;
	end
  else if (cBLANK_n==1'b1)
	begin
	  background_ADDR<=background_ADDR+1;
     ADDR<=ADDR+1;
	  if (bird_ADDR > 19'd307200) bird_ADDR<=19'd0;
	  else bird_ADDR<=bird_ADDR+1;
	end
end
//////////////////////////
//DrawPipe u1(
//				.Clk(iVGA_CLK),
//				.Reset(RS),
//				.addr(ADDR),
//				.CounterX(CounterX),
//				.CounterY(CounterY),
//				.R(R_pipe),
//				.G(G_pipe),
//				.B(B_pipe)
//				);
//////INDEX addr.
assign VGA_CLK_n = ~iVGA_CLK;
img_data	img_data_inst (
	.address ( background_ADDR ),
	.clock ( VGA_CLK_n ),
	.q ( index )
	);
//////Color table output
img_index	img_index_inst (
	.address ( index ),
	.clock ( iVGA_CLK ),
	.q ( bgr_data_raw)
	);	
//////

////BIRD FLAPPY////////
bird_data bir_data_inst(
	.address ( bird_ADDR ),
	.clock ( VGA_CLK_n ),
	.q ( bird_index )
	);
bird_index bird_index_inst(
	.address ( bird_index ),
	.clock ( iVGA_CLK ),
	.q ( bird_data_raw )
	);
TopModule(
			.Clk(VGA_CLK_n),
			.Button(SW),
			.Reset(RS),
			.CounterX(X),
			.CounterY(Y),
			.vga_R(R_bird),
			.vga_G(G_bird),
			.vga_B(B_bird)
			);
////////////////////////
//////latch valid data at falling edge;
always@(posedge VGA_CLK_n) 
	begin
		//if ( 24'hffffff == bird_data_raw || 24'h000000 ) bgr_data<=bgr_data_raw;
		bgr_data <= bgr_data_raw;
		
	end


always@(posedge VGA_CLK_n or negedge iRST_n)
begin
	if (!iRST_n)
		begin
			b_data <= 0;
			g_data <= 0;
			r_data <= 0;
		end
	else if (!(R_bird | G_bird | B_bird))
			begin
				b_data <= bgr_data[23:16];
				g_data <= bgr_data[15:8];
				r_data <= bgr_data[7:0];
			end
			else 
	begin
		if (R_bird) b_data <= 8'hff;
		else b_data <= 8'h00;
		
		if (G_bird) g_data <= 8'hff;
		else g_data <= 8'h00;
		
		if (B_bird) r_data <= 8'hff;
		else r_data <= 8'h00;
	end

end

//assign b_data = bgr_data[23:16];
//assign g_data = bgr_data[15:8];
//assign r_data = bgr_data[7:0];
///////////////////
//////Delay the iHD, iVD,iDEN for one clock cycle;
//always@(negedge iVGA_CLK)
//begin
//  oHS<=cHS;
//  oVS<=cVS;
////  oBLANK_n<=cBLANK_n;
//end

reg [4:0] delay_bus;
reg [4:0] delay_busv;
reg [4:0] delay_bush;

always@(posedge VGA_CLK_n or negedge iRST_n)
begin
	if (!iRST_n)
		begin
			delay_bus <= 0;
			delay_busv <= 0;
			delay_bush <= 0;

		end
	else
		begin
			delay_bus <= {delay_bus[3:0],cBLANK_n};
			delay_bush <= {delay_bush[3:0],cHS};
			delay_busv <= {delay_busv[3:0],cVS};
			
			
		end
end

assign oBLANK_n = delay_bus[1];
assign oHS = delay_bush[1];
assign oVS = delay_busv[1];

endmodule
 	
















