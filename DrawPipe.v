module DrawPipe(Clk,Reset,CounterX,CounterY,addr,R,G,B);
input Clk,Reset;
input [18:0] addr;
input [9:0]CounterX;
input [8:0]CounterY;

output  R,G,B;

wire Button,Status;
assign Button = 0;
wire [15:0] Pattern1;
wire [15:0] Pattern2;
wire [15:0] PipesPosition1;
wire [15:0] PipesPosition2;
wire [15:0] R_Pipes_off;
wire [15:0] R_Bird_off;

SlowClock s1 (Clk,Reset,Clks);

StatusChecker s7 (Reset,CounterX,R_Pipes_off,R_Pipes2_off,R_Bird_off,Status);
DrawPipes s4 (Clks,Reset,CounterX,CounterY,Button,Status,Pattern1,R_Pipes_on,G_Pipes_on,B_Pipes_on,R_Pipes_off,G_Pipes_off,B_Pipes_off,PipesPosition1);
DrawPipes2 s44 (Clks,Reset,CounterX,CounterY,Button,Status,Pattern2,R_Pipes2_on,G_Pipes2_on,B_Pipes2_on,R_Pipes2_off,G_Pipes2_off,B_Pipes2_off,PipesPosition2);

Pattern p (Clks,Reset,PipesPosition1,PipesPosition2,Button,Pattern1,Pattern2);


assign R = (~R_Pipes_off) & ~R_Pipes2_off;
assign G = ((G_Pipes_on | G_Pipes2_on) & ~G_Pipes_off) & ~G_Pipes2_off;
assign B = (~B_Pipes_off) & ~B_Pipes2_off;
endmodule
