module setup (
    input clk,
    input rst,
    input [2:0] coin,
    input [2:0] selezione,
    output setup_done,

    // Output verso il datapath
    output [5:0] qt1, price1,
    output [5:0] qt2, price2,
    output [5:0] qt3, price3,
    output [5:0] qt4, price4,
    output [5:0] coin01, coin02, coin05, coin10
);

    // Cavi interni
    wire [11:0] enable_wire;
    wire [3:0] count;
    wire [5:0] data_wire;
    wire [5:0] reg_out [0:11];
    wire not_setup_done;

    assign data_wire = {coin, selezione};

    // Se i bit 3 e 2 sono a 1, il numero è >= 12
    and (setup_done, count[3], count[2]);
    not (not_setup_done, setup_done);

    // Istanziazione del contatore strutturale
    counter #(.N(4)) setup_counter (
        .clk(clk),
        .rst(rst),
        .enable(not_setup_done),
        .count(count)
    );

    // Istanziazione del decoder
    decoder setup_decoder (
        .in(count),
        .out(enable_wire)
    );

    // Mapping delle uscite ai registri
    registro reg_qt1    (.clk(clk), .rst(rst), .enable(enable_wire[0]),  .d(data_wire), .q(qt1));
    registro reg_price1 (.clk(clk), .rst(rst), .enable(enable_wire[1]),  .d(data_wire), .q(price1));
    
    registro reg_qt2    (.clk(clk), .rst(rst), .enable(enable_wire[2]),  .d(data_wire), .q(qt2));
    registro reg_price2 (.clk(clk), .rst(rst), .enable(enable_wire[3]),  .d(data_wire), .q(price2));
    
    registro reg_qt3    (.clk(clk), .rst(rst), .enable(enable_wire[4]),  .d(data_wire), .q(qt3));
    registro reg_price3 (.clk(clk), .rst(rst), .enable(enable_wire[5]),  .d(data_wire), .q(price3));
    
    registro reg_qt4    (.clk(clk), .rst(rst), .enable(enable_wire[6]),  .d(data_wire), .q(qt4));
    registro reg_price4 (.clk(clk), .rst(rst), .enable(enable_wire[7]),  .d(data_wire), .q(price4));
    
    registro reg_c01    (.clk(clk), .rst(rst), .enable(enable_wire[8]),  .d(data_wire), .q(coin01));
    registro reg_c02    (.clk(clk), .rst(rst), .enable(enable_wire[9]),  .d(data_wire), .q(coin02));
    registro reg_c05    (.clk(clk), .rst(rst), .enable(enable_wire[10]), .d(data_wire), .q(coin05));
    registro reg_c10    (.clk(clk), .rst(rst), .enable(enable_wire[11]), .d(data_wire), .q(coin10));
    
endmodule