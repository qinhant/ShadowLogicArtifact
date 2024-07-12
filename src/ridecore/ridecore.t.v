`include "topsim.v"

module ridecore_test;

reg clk;
reg rst;

topsim inst(.clk(clk), .reset_x(~rst));

integer i = 0;
initial begin
    $dumpfile("ridecore_test.vcd");
    $dumpvars;
    for (i = 0; i < `IMEM_SIZE; i = i + 1) begin
        $dumpvars(0, inst.instmemory.mem[i]);
    end
    for (i = 0; i < `DMEM_SIZE; i = i + 1) begin
        $dumpvars(0, inst.datamemory.mem[i]);
    end

    clk = 0;
    rst = 1;
    for (i = 0; i < 100; i = i + 1) begin
        #5 
        clk = ~clk;
        if (i == 10) begin
            rst = 0;
        end
    end
    $finish;
    
end
endmodule