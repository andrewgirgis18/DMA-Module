module clock(cl);
output reg cl;
initial
cl=0;
always
#50 cl=~cl;
endmodule

module chip8086(input cl, HRQ, interpt,output reg HLDA,output reg [1023:0] DataC,
output reg [12:0] address,
output reg ior,
output reg iow
);

initial
begin
DataC = 10;
ior = 1'b1;
iow = 1'b0;
address = 2;
end



always @(posedge cl)
begin
if(HRQ == 1)
HLDA <= 1;
end
endmodule



module MainM(n,r,w,clock,m);



input [12:0] n; 
input clock;
inout [7:0] m;
reg [7:0] mainM[0:2047]; 
input r,w;



genvar i;
generate
for(i = 0; i < 50; i = i + 1)
always @* begin
mainM[i] = i;
end
endgenerate



assign m = (!r) ? mainM[n[10:0]] : 8'bz;

always @(posedge clock)
begin
if(!w)
mainM[n[10:0]] = m;
end
endmodule



module Dsk(address,ior,iow,cl,data,DREQ,DACK);
inout [7:0] data;
output reg DREQ;
input DACK;
input cl;
reg[7:0] DataMem[0:4095]; 
input ior, iow; 
input [12:0] address;

genvar i;
generate
for(i = 250; i < 500; i = i + 1)
always @* begin
DataMem[i] = i;
end
endgenerate

assign data = (!ior && DACK) ? DataMem[address] : 'bz;

always @(posedge cl)
begin
if(!iow && DACK)
DataMem[address] = data;
end

always @(DACK)
begin
if(DACK)
DREQ <= 0;
end

always @(ior, iow)
begin
DREQ <= 1'b1;
end
endmodule

module dma(input cl,input [12:0] BAdd,output reg [12:0] CAdd,
input [1023 : 0] DataC, 
input DREQ, 
input HLDA,
input IORP, 
input IOWP, 
output reg HRQ, 
output reg DACK, 
output reg ior, 
output reg iow, 
output reg MEMRead, 
output reg MEMWrite,
output reg intpt
);



reg [1023 : 0] dataCR;
reg [12:0] addressReg;



initial
begin
assign dataCR = DataC;
assign addressReg = BAdd;
end



always @(posedge cl)
begin
if(DREQ)
HRQ <= 1'b1;
if(!dataCR)
begin
intpt = 1'b1;
HRQ <= 1'b0;
end
if(HLDA && dataCR)
begin
DACK <= 1'b1;
MEMRead = IOWP; 
MEMWrite = IORP; 
iow = IOWP; 
ior = IORP; 
CAdd = addressReg;
assign dataCR = dataCR - 1;
assign addressReg = addressReg + 1;
end
end
endmodule



module CPUTst;
wire A;
wire cl;
wire DACK; 
wire DREQ; 
wire intpt;
wire [7:0] Data;
wire [12:0] address;
wire [12:0] BAdd;
wire HRQ; 
wire [1023 : 0] DataC;
wire MEMRead;
wire MEMWrite;
wire IORP;
wire IOWP;
wire IOW;
wire IOR;
wire HLDA; 

Clock clo(cl);

chip8086 cpu(cl,HRQ,intpt,HLDA,DataC,BAdd,IORP,IOWP);

dma dm(clk,BAdd,address,DataC,DREQ,HLDA,IORP,IOWP,HRQ,DACK,ior,iow,MEMRead,MEMWrite);


Dsk Dk(address,IORP,IOWP,cl,Data,DREQ,DACK);

MainM Mem(address,MEMRead,MEMWrite,cl,Data);

endmodule